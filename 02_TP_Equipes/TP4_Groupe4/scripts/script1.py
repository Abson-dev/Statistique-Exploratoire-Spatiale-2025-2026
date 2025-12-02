"""
SCRIPT 1: ANALYSE SEUILS D'EAU PERMANENTE
Teste différents seuils d'occurrence pour identifier les eaux permanentes
VERSION COMPLÈTEMENT RÉVISÉE - Gestion robuste des erreurs
"""

import rasterio
from rasterio.merge import merge
from rasterio.windows import from_bounds
from rasterio.features import geometry_mask
from rasterio.warp import Resampling
import geopandas as gpd
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from pathlib import Path
from shapely.geometry import mapping
import warnings
import traceback
import sys

# ============================================================================
# CONFIGURATION
# ============================================================================

BASE_DIR = Path(r"C:\Users\HP\Documents\ISEP3\Semestre 1_CT\Stat\Stat_Spatiale\TP4\data")
WATER_DIR = BASE_DIR / "Water"
BOUNDARIES_DIR = BASE_DIR / "Boundaries"
RESULTS_DIR = BASE_DIR.parent / "Results_Script1"
RESULTS_DIR.mkdir(exist_ok=True)

THRESHOLDS = [75, 85, 90, 95]  # Seuils à tester (%)
OFFICIAL_ARABLE = 15.0  # millions ha (FAO)

# Supprimer tous les avertissements
warnings.filterwarnings('ignore')

# ============================================================================
# FONCTIONS UTILITAIRES - CALCULS PRÉCIS
# ============================================================================

def calculate_pixel_area_ha(transform, crs, latitude=9.0):
    """
    Calcule l'aire d'un pixel en hectares de manière précise
    """
    # Vérifier si le CRS est géographique (degrés)
    if crs.is_geographic:
        # Taille du pixel en degrés
        pixel_width_deg = abs(transform[0])
        pixel_height_deg = abs(transform[4])
        
        # Conversion en mètres
        lat_rad = np.radians(latitude)
        pixel_width_m = pixel_width_deg * 111132 * np.cos(lat_rad)  # Longitude
        pixel_height_m = pixel_height_deg * 111132  # Latitude
        
        # Aire en hectares
        pixel_area_m2 = pixel_width_m * pixel_height_m
        pixel_area_ha = pixel_area_m2 / 10000
        
        return pixel_area_ha
    else:
        # CRS projeté (en mètres)
        pixel_width_m = abs(transform[0])
        pixel_height_m = abs(transform[4])
        pixel_area_m2 = pixel_width_m * pixel_height_m
        pixel_area_ha = pixel_area_m2 / 10000
        return pixel_area_ha

def get_ethiopia_area_mha(ethiopia_gdf):
    """
    Calcule l'aire exacte de l'Éthiopie à partir du shapefile
    """
    # Reprojection en UTM (système métrique)
    utm_crs = 'EPSG:32637'  # UTM zone 37N pour l'Éthiopie
    
    if ethiopia_gdf.crs.to_string() != utm_crs:
        ethiopia_utm = ethiopia_gdf.to_crs(utm_crs)
    else:
        ethiopia_utm = ethiopia_gdf
    
    # Calcul en hectares puis millions d'hectares
    area_m2 = ethiopia_utm.geometry.area.sum()
    area_ha = area_m2 / 10000
    area_mha = area_ha / 1_000_000
    
    return area_mha

# ============================================================================
# FONCTIONS DE TRAITEMENT DES DONNÉES - VERSION ROBUSTE
# ============================================================================

def check_data_type_compatibility(data, nodata_value):
    """
    Vérifie et ajuste le type de données pour la compatibilité avec la valeur nodata
    """
    if data.dtype == np.uint8:
        # uint8 ne supporte pas les valeurs négatives
        if nodata_value is not None and (nodata_value < 0 or nodata_value > 255):
            print(f"  Conversion nécessaire: uint8 -> float32 (nodata={nodata_value})")
            return data.astype(np.float32), np.nan
        else:
            # Utiliser 0 comme nodata pour uint8
            return data, 0
    elif data.dtype in [np.int8, np.int16, np.int32, np.int64]:
        # Types signés - vérifier les limites
        dtype_info = np.iinfo(data.dtype)
        if nodata_value is not None and (nodata_value < dtype_info.min or nodata_value > dtype_info.max):
            print(f"  Conversion nécessaire: {data.dtype} -> float32")
            return data.astype(np.float32), np.nan
        else:
            return data, nodata_value if nodata_value is not None else dtype_info.min
    else:
        # Types flottants - utiliser NaN comme nodata
        return data, np.nan

def create_mosaic_simple(input_files, output_path):
    """
    Crée une mosaïque simple à partir de fichiers raster
    """
    print(f"Création de la mosaïque à partir de {len(input_files)} fichiers...")
    
    try:
        # Lire tous les fichiers
        src_files = [rasterio.open(f) for f in input_files]
        
        # Créer la mosaïque
        mosaic, transform = merge(src_files)
        
        # Métadonnées de sortie
        out_meta = src_files[0].meta.copy()
        out_meta.update({
            "height": mosaic.shape[1],
            "width": mosaic.shape[2],
            "transform": transform,
            "compress": "lzw",
            "bigtiff": "YES"  # Pour les fichiers > 4GB
        })
        
        # Écrire la mosaïque
        with rasterio.open(output_path, 'w', **out_meta) as dst:
            dst.write(mosaic)
        
        print(f"✓ Mosaïque créée: {output_path}")
        print(f"  Dimensions: {mosaic.shape[2]}x{mosaic.shape[1]} pixels")
        print(f"  Type de données: {mosaic.dtype}")
        
        return True
        
    except Exception as e:
        print(f"❌ Erreur lors de la création de la mosaïque: {e}")
        return False
    finally:
        # Fermer tous les fichiers
        for src in src_files:
            try:
                src.close()
            except:
                pass

def clip_raster_safely(raster_path, shapefile_path, output_path, target_dtype=np.float32):
    """
    Découpe un raster de manière sûre avec gestion de mémoire
    """
    print("Découpage du raster selon les limites...")
    
    try:
        # Charger le shapefile
        gdf = gpd.read_file(shapefile_path)
        print(f"  Shapefile chargé: {len(gdf)} polygones")
        
        # Ouvrir le raster source
        with rasterio.open(raster_path) as src:
            print(f"  Raster source: {src.width}x{src.height}")
            print(f"  CRS source: {src.crs}")
            print(f"  Type de données source: {src.dtypes[0]}")
            
            # Reprojection si nécessaire
            if gdf.crs != src.crs:
                print(f"  Reprojection: {gdf.crs} -> {src.crs}")
                gdf = gdf.to_crs(src.crs)
            
            # Calculer la bounding box
            minx, miny, maxx, maxy = gdf.total_bounds
            print(f"  Bounding box: {minx:.2f}, {miny:.2f}, {maxx:.2f}, {maxy:.2f}")
            
            # Calculer la fenêtre
            win = from_bounds(minx, miny, maxx, maxy, transform=src.transform)
            win = win.round_offsets().round_lengths()
            
            window_height, window_width = win.height, win.width
            print(f"  Taille de fenêtre: {window_width}x{window_height}")
            
            # Vérifier si la fenêtre est trop grande
            max_dimension = 5000  # Limite pour éviter les problèmes de mémoire
            if window_width > max_dimension or window_height > max_dimension:
                scale_factor = max(window_width // max_dimension, window_height // max_dimension) + 1
                new_height = window_height // scale_factor
                new_width = window_width // scale_factor
                print(f"  Réduction par facteur {scale_factor} -> {new_width}x{new_height}")
                
                # Lire avec redimensionnement
                data = np.empty((src.count, new_height, new_width), dtype=target_dtype)
                for i in range(src.count):
                    data[i] = src.read(
                        i+1,
                        window=win,
                        out_shape=(new_height, new_width),
                        resampling=Resampling.bilinear
                    ).astype(target_dtype)
                
                # Ajuster la transformation
                new_transform = src.window_transform(win)
                new_transform = rasterio.Affine(
                    new_transform.a * scale_factor,
                    new_transform.b,
                    new_transform.c,
                    new_transform.d,
                    new_transform.e * scale_factor,
                    new_transform.f
                )
            else:
                # Lire sans redimensionnement
                data = src.read(window=win).astype(target_dtype)
                new_transform = src.window_transform(win)
                scale_factor = 1
            
            print(f"  Données lues: {data.shape}, type: {data.dtype}")
            
            # Créer le masque géométrique
            geoms = [mapping(geom) for geom in gdf.geometry]
            mask = geometry_mask(
                geoms,
                out_shape=(data.shape[1], data.shape[2]),
                transform=new_transform,
                invert=True,
                all_touched=False
            )
            
            # Appliquer le masque
            # Pour les float, utiliser NaN; pour les int, utiliser une valeur spécifique
            if np.issubdtype(data.dtype, np.floating):
                for i in range(data.shape[0]):
                    data[i][~mask] = np.nan
                nodata_value = np.nan
            else:
                # Pour les entiers, utiliser la valeur minimale
                dtype_info = np.iinfo(data.dtype)
                nodata_value = dtype_info.min
                for i in range(data.shape[0]):
                    data[i][~mask] = nodata_value
            
            # Métadonnées de sortie
            out_meta = src.meta.copy()
            out_meta.update({
                "height": data.shape[1],
                "width": data.shape[2],
                "transform": new_transform,
                "dtype": str(data.dtype),
                "nodata": nodata_value,
                "compress": "lzw"
            })
            
            # Écrire le résultat
            with rasterio.open(output_path, 'w', **out_meta) as dst:
                dst.write(data)
            
            print(f"✓ Raster découpé: {output_path}")
            return output_path, scale_factor, data.shape, new_transform, gdf
            
    except Exception as e:
        print(f"❌ Erreur lors du découpage: {e}")
        raise

# ============================================================================
# FONCTIONS D'ANALYSE PRINCIPALES
# ============================================================================

def prepare_data():
    """
    Prépare les données: mosaïque et découpage
    """
    print("\n" + "="*70)
    print("ÉTAPE 1: PRÉPARATION DES DONNÉES")
    print("="*70)
    
    # Vérifier les fichiers
    water_files = list(WATER_DIR.glob("occurrence_*.tif"))
    if not water_files:
        raise FileNotFoundError(f"Aucun fichier trouvé dans {WATER_DIR}")
    print(f"Fichiers d'eau trouvés: {len(water_files)}")
    
    boundaries = list(BOUNDARIES_DIR.glob("*.shp"))
    if not boundaries:
        raise FileNotFoundError(f"Aucun shapefile dans {BOUNDARIES_DIR}")
    
    shapefile_path = boundaries[0]
    print(f"Shapefile utilisé: {shapefile_path.name}")
    
    # Étape 1: Créer la mosaïque
    mosaic_path = RESULTS_DIR / "water_mosaic_full.tif"
    if not mosaic_path.exists() or mosaic_path.stat().st_size == 0:
        print("\nCréation de la mosaïque...")
        success = create_mosaic_simple(water_files, mosaic_path)
        if not success:
            raise RuntimeError("Échec de la création de la mosaïque")
    else:
        print(f"\nMosaïque existante trouvée: {mosaic_path}")
    
    # Étape 2: Découper
    clipped_path = RESULTS_DIR / "water_ethiopia_final.tif"
    if not clipped_path.exists() or clipped_path.stat().st_size == 0:
        print("\nDécoupage selon les limites...")
        clipped_path, scale_factor, clipped_shape, transform, ethiopia = clip_raster_safely(
            mosaic_path, shapefile_path, clipped_path
        )
    else:
        print(f"\nRaster découpé existant: {clipped_path}")
        # Charger les métadonnées
        with rasterio.open(clipped_path) as src:
            transform = src.transform
            clipped_shape = src.shape
        ethiopia = gpd.read_file(shapefile_path)
        scale_factor = 1
    
    print(f"\n✓ Données préparées avec succès")
    print(f"  Fichier final: {clipped_path}")
    print(f"  Dimensions: {clipped_shape}")
    
    return clipped_path, ethiopia, transform

def analyze_thresholds(water_raster_path, ethiopia_gdf):
    """
    Analyse les différents seuils d'eau permanente
    """
    print("\n" + "="*70)
    print("ÉTAPE 2: ANALYSE DES SEUILS")
    print("="*70)
    
    results = []
    
    with rasterio.open(water_raster_path) as src:
        # Lire les données
        data = src.read(1)
        print(f"Données chargées: {data.shape}, type: {data.dtype}")
        
        # Vérifier les valeurs
        if np.issubdtype(data.dtype, np.floating):
            valid_mask = ~np.isnan(data)
        else:
            valid_mask = data != src.nodata
        
        valid_data = data[valid_mask]
        
        if len(valid_data) == 0:
            raise ValueError("Aucune donnée valide dans le raster!")
        
        print(f"Valeurs min/max: {valid_data.min():.1f} / {valid_data.max():.1f}")
        print(f"Pixels valides: {valid_mask.sum():,}")
        
        # Calcul de l'aire d'un pixel
        try:
            pixel_area_ha = calculate_pixel_area_ha(src.transform, src.crs, latitude=9.0)
            print(f"Aire par pixel: {pixel_area_ha:.8f} ha")
        except Exception as e:
            print(f"⚠ Erreur calcul aire pixel: {e}")
            # Valeur par défaut approximative
            pixel_area_ha = 0.0081  # ~90m x 90m en ha
        
        # Superficie de l'Éthiopie
        ethiopia_area_mha = get_ethiopia_area_mha(ethiopia_gdf)
        print(f"Superficie Éthiopie (shapefile): {ethiopia_area_mha:.2f} Mha")
        
        # Calcul de la superficie couverte par les pixels valides
        valid_pixels = valid_mask.sum()
        covered_area_mha = (valid_pixels * pixel_area_ha) / 1_000_000
        coverage_percent = (covered_area_mha / ethiopia_area_mha) * 100
        print(f"Zone couverte par les données: {covered_area_mha:.2f} Mha ({coverage_percent:.1f}%)")
        
        # Analyse pour chaque seuil
        for threshold in THRESHOLDS:
            print(f"\n  Analyse seuil {threshold}%:")
            
            # Masque d'eau permanente
            if np.issubdtype(data.dtype, np.floating):
                water_mask = (data >= threshold) & (data > 0) & ~np.isnan(data)
            else:
                water_mask = (data >= threshold) & (data > 0) & (data != src.nodata)
            
            water_pixels = water_mask.sum()
            water_mha = (water_pixels * pixel_area_ha) / 1_000_000
            
            # Terres disponibles (total - eau)
            available_land_mha = ethiopia_area_mha - water_mha
            
            #  terres arables (coefficient à ajuster)
            arable_coefficient = 0.155  # 15.5% des terres disponibles
            l_arable_mha = available_land_mha * arable_coefficient
            
            # Écart avec données FAO
            diff_pct = ((l_arable_mha - OFFICIAL_ARABLE) / OFFICIAL_ARABLE) * 100
            
            # Stocker les résultats
            results.append({
                'Seuil (%)': threshold,
                'Eau permanente (Mha)': round(water_mha, 4),
                'Pourcentage eau': round((water_mha / ethiopia_area_mha * 100), 3),
                'Terres disponibles (Mha)': round(available_land_mha, 3),
                'Terres arables ls (Mha)': round(l_arable_mha, 3),
                'Écart vs FAO (%)': round(diff_pct, 3),
                'Coefficient arable': arable_coefficient
            })
            
            print(f"    • Eau: {water_mha:.4f} Mha ({water_mha/ethiopia_area_mha*100:.3f}%)")
            print(f"    • Terres arables ls: {l_arable_mha:.3f} Mha")
            print(f"    • Écart FAO: {diff_pct:+.3f}%")
            
            # Sauvegarder le masque
            mask_path = RESULTS_DIR / f"water_mask_{threshold:02d}.tif"
            with rasterio.open(mask_path, 'w', 
                             driver='GTiff',
                             height=data.shape[0],
                             width=data.shape[1],
                             count=1,
                             dtype='uint8',
                             crs=src.crs,
                             transform=src.transform,
                             compress='lzw',
                             nodata=255) as dst:
                dst.write(water_mask.astype(np.uint8), 1)
    
    # Créer DataFrame
    df_results = pd.DataFrame(results)
    
    # Trouver le meilleur seuil
    df_results['Écart absolu'] = df_results['Écart vs FAO (%)'].abs()
    best_idx = df_results['Écart absolu'].idxmin()
    best_threshold = df_results.loc[best_idx, 'Seuil (%)']
    
    print(f"\n✓ Analyse terminée")
    print(f"  Meilleur seuil: {best_threshold}%")
    print(f"  Écart minimal: {df_results.loc[best_idx, 'Écart vs FAO (%)']:.3f}%")
    
    # Sauvegarder les résultats
    df_results.to_csv(RESULTS_DIR / "resultats_complets.csv", index=False, encoding='utf-8-sig')
    df_results[['Seuil (%)', 'Eau permanente (Mha)', 'Terres arables ls (Mha)', 'Écart vs FAO (%)']].to_csv(
        RESULTS_DIR / "resultats_simples.csv", index=False, encoding='utf-8-sig'
    )
    
    return df_results, best_threshold, ethiopia_area_mha

def create_visualizations(df_results, ethiopia_area_mha):
    """
    Crée les visualisations des résultats
    """
    print("\n" + "="*70)
    print("ÉTAPE 3: CRÉATION DES VISUALISATIONS")
    print("="*70)
    
    # Configuration
    plt.style.use('default')
    plt.rcParams['figure.figsize'] = [12, 8]
    plt.rcParams['font.size'] = 10
    
    # Graphique 1: Comparaison des seuils
    fig, axes = plt.subplots(2, 2, figsize=(14, 10))
    
    # 1. Eau permanente par seuil
    axes[0, 0].bar(df_results['Seuil (%)'].astype(str), 
                   df_results['Eau permanente (Mha)'],
                   color='blue', alpha=0.7)
    axes[0, 0].set_xlabel('Seuil (%)')
    axes[0, 0].set_ylabel('Eau permanente (Mha)')
    axes[0, 0].set_title('Surface d\'eau détectée par seuil')
    axes[0, 0].grid(True, alpha=0.3)
    
    # Ajouter les valeurs
    for i, val in enumerate(df_results['Eau permanente (Mha)']):
        axes[0, 0].text(i, val + 0.01, f'{val:.3f}', 
                       ha='center', va='bottom', fontsize=9)
    
    # 2. Pourcentage d'eau
    water_pct = (df_results['Eau permanente (Mha)'] / ethiopia_area_mha) * 100
    axes[0, 1].plot(df_results['Seuil (%)'], water_pct, 
                   marker='o', linewidth=2, color='cyan')
    axes[0, 1].set_xlabel('Seuil (%)')
    axes[0, 1].set_ylabel('Pourcentage du territoire (%)')
    axes[0, 1].set_title('Eau permanente en % du territoire')
    axes[0, 1].grid(True, alpha=0.3)
    
    # 3. Terres arables ls
    axes[1, 0].bar(df_results['Seuil (%)'].astype(str),
                   df_results['Terres arables ls (Mha)'],
                   color='green', alpha=0.7, label='')
    axes[1, 0].axhline(y=OFFICIAL_ARABLE, color='red', linestyle='--',
                      linewidth=2, label=f'FAO ({OFFICIAL_ARABLE} Mha)')
    axes[1, 0].set_xlabel('Seuil (%)')
    axes[1, 0].set_ylabel('Terres arables (Mha)')
    axes[1, 0].set_title(' des terres arables')
    axes[1, 0].legend()
    axes[1, 0].grid(True, alpha=0.3)
    
    # 4. Écart avec FAO
    colors = ['green' if x >= 0 else 'red' for x in df_results['Écart vs FAO (%)']]
    bars = axes[1, 1].bar(df_results['Seuil (%)'].astype(str),
                         df_results['Écart vs FAO (%)'],
                         color=colors, alpha=0.7)
    axes[1, 1].axhline(y=0, color='black', linestyle='-', alpha=0.5)
    axes[1, 1].set_xlabel('Seuil (%)')
    axes[1, 1].set_ylabel('Écart (%)')
    axes[1, 1].set_title('Écart par rapport aux données FAO')
    axes[1, 1].grid(True, alpha=0.3)
    
    # Ajouter les valeurs d'écart
    for bar, val in zip(bars, df_results['Écart vs FAO (%)']):
        height = bar.get_height()
        axes[1, 1].text(bar.get_x() + bar.get_width()/2, 
                       height + (1 if height >= 0 else -2),
                       f'{val:.2f}%', ha='center', va='bottom' if height >= 0 else 'top',
                       fontsize=9, fontweight='bold')
    
    plt.suptitle('Analyse des seuils d\'eau permanente - Éthiopie', 
                fontsize=14, fontweight='bold', y=1.02)
    plt.tight_layout()
    
    # Sauvegarder
    plt.savefig(RESULTS_DIR / "visualisation_complete.png", dpi=300, bbox_inches='tight')
    plt.savefig(RESULTS_DIR / "visualisation_complete.pdf", bbox_inches='tight')
    
    # Graphique simple pour présentation
    plt.figure(figsize=(10, 6))
    plt.plot(df_results['Seuil (%)'], df_results['Terres arables ls (Mha)'],
            marker='s', linewidth=2, markersize=8, color='darkgreen',
            label='Terres arables ls')
    plt.axhline(y=OFFICIAL_ARABLE, color='red', linestyle='--', 
               linewidth=2, label=f'Données FAO ({OFFICIAL_ARABLE} Mha)')
    
    # Marquer le meilleur seuil
    best_idx = df_results['Écart vs FAO (%)'].abs().idxmin()
    best_seuil = df_results.loc[best_idx, 'Seuil (%)']
    best_value = df_results.loc[best_idx, 'Terres arables ls (Mha)']
    
    plt.plot(best_seuil, best_value, 'ro', markersize=12, 
            label=f'Seuil optimal ({best_seuil}%)')
    
    plt.xlabel('Seuil d\'occurrence d\'eau (%)', fontsize=12, fontweight='bold')
    plt.ylabel('Terres arables (millions ha)', fontsize=12, fontweight='bold')
    plt.title('Impact du seuil d\'eau sur l\' des terres arables\nÉthiopie', 
             fontsize=14, fontweight='bold', pad=15)
    plt.legend(loc='best')
    plt.grid(True, alpha=0.3)
    plt.tight_layout()
    
    plt.savefig(RESULTS_DIR / "graphique_principal.png", dpi=300, bbox_inches='tight')
    
    print("✓ Visualisations créées et sauvegardées")
    plt.close('all')

def generate_comprehensive_report(df_results, best_threshold, ethiopia_area_mha):
    """
    Génère un rapport complet des résultats
    """
    print("\n" + "="*70)
    print("ÉTAPE 4: GÉNÉRATION DU RAPPORT")
    print("="*70)
    
    # Trouver la ligne du meilleur seuil
    best_row = df_results[df_results['Seuil (%)'] == best_threshold].iloc[0]
    
    # Rapport détaillé
    report_path = RESULTS_DIR / "rapport_analyse_detaille.md"
    
    with open(report_path, 'w', encoding='utf-8') as f:
        f.write("# RAPPORT D'ANALYSE: SEUILS D'EAU PERMANENTE EN ÉTHIOPIE\n\n")
        
        f.write("## 1. CONTEXTE ET OBJECTIFS\n")
        f.write("Cette analyse vise à déterminer le seuil optimal d'occurrence d'eau pour identifier ")
        f.write("les eaux permanentes en Éthiopie. L'objectif est de calculer les terres arables disponibles ")
        f.write("en excluant ces zones d'eau permanente.\n\n")
        
        f.write(f"- **Référence FAO**: {OFFICIAL_ARABLE} millions d'hectares de terres arables\n")
        f.write(f"- **Superficie de l'Éthiopie**: {ethiopia_area_mha:.2f} Mha\n")
        f.write(f"- **Seuils testés**: {', '.join(map(str, THRESHOLDS))}%\n\n")
        
        f.write("## 2. MÉTHODOLOGIE\n")
        f.write("1. **Mosaïquage** des données d'occurrence d'eau annuelle\n")
        f.write("2. **Découpage** selon les frontières de l'Éthiopie\n")
        f.write("3. **Analyse par seuil** des eaux permanentes\n")
        f.write("4. **** des terres arables disponibles\n")
        f.write("5. **Validation** par comparaison avec les données FAO\n\n")
        
        f.write("## 3. RÉSULTATS DÉTAILLÉS\n\n")
        f.write("| Seuil (%) | Eau permanente (Mha) | % Territoire | Terres arables ls (Mha) | Écart vs FAO (%) |\n")
        f.write("|-----------|----------------------|--------------|-------------------------------|------------------|\n")
        
        for _, row in df_results.iterrows():
            f.write(f"| {row['Seuil (%)']} | {row['Eau permanente (Mha)']:.4f} | {row['Pourcentage eau']:.3f}% | ")
            f.write(f"{row['Terres arables ls (Mha)']:.3f} | {row['Écart vs FAO (%)']:+.3f}% |\n")
        
        f.write("\n## 4. ANALYSE ET CONCLUSION\n\n")
        
        f.write(f"### Seuil optimal: **{best_threshold}%**\n\n")
        f.write(f"**Justification**: Ce seuil minimise l'écart avec les données FAO ({best_row['Écart vs FAO (%)']:.3f}%)\n\n")
        
        f.write(f"**Caractéristiques pour {best_threshold}%**:\n")
        f.write(f"- **Eau permanente détectée**: {best_row['Eau permanente (Mha)']:.4f} Mha ")
        f.write(f"({best_row['Pourcentage eau']:.3f}% du territoire)\n")
        f.write(f"- **Terres disponibles**: {best_row['Terres disponibles (Mha)']:.3f} Mha\n")
        f.write(f"- **Terres arables ls**: {best_row['Terres arables ls (Mha)']:.3f} Mha\n")
        f.write(f"- **Coefficient arable utilisé**: {best_row['Coefficient arable']*100:.1f}%\n\n")
        
        f.write("### Interprétation\n")
        
        if best_row['Écart vs FAO (%)'] < -5:
            f.write("- L' est **inférieure** aux données FAO\n")
            f.write("- Suggestions: Augmenter le coefficient arable ou vérifier les données d'entrée\n")
        elif best_row['Écart vs FAO (%)'] > 5:
            f.write("- L' est **supérieure** aux données FAO\n")
            f.write("- Suggestions: Réduire le coefficient arable ou ajuster le seuil\n")
        else:
            f.write("- L' est **en accord** avec les données FAO (écart < 5%)\n")
            f.write("- Le modèle est bien calibré pour ce seuil\n")
        
        f.write("\n## 5. RECOMMANDATIONS\n")
        f.write("1. **Validation terrain**: Vérifier la détection d'eau sur le terrain\n")
        f.write("2. **Calibration fine**: Ajuster le coefficient arable avec des données locales\n")
        f.write("3. **Sensibilité**: Tester d'autres seuils (60%, 70%, 80%)\n")
        f.write("4. **Données complémentaires**: Intégrer les données d'utilisation des sols\n\n")
        
        f.write("## 6. FICHIERS GÉNÉRÉS\n")
        f.write("- `water_mosaic_full.tif`: Mosaïque complète des données\n")
        f.write("- `water_ethiopia_final.tif`: Données découpées pour l'Éthiopie\n")
        f.write("- `water_mask_XX.tif`: Masques d'eau par seuil\n")
        f.write("- `resultats_complets.csv`: Résultats détaillés\n")
        f.write("- `visualisation_complete.png`: Graphiques d'analyse\n")
        f.write("- `graphique_principal.png`: Graphique de synthèse\n")
        f.write("- `rapport_analyse_detaille.md`: Ce rapport\n")
    
    # Rapport synthèse (texte simple)
    summary_path = RESULTS_DIR / "synthese_resultats.txt"
    
    with open(summary_path, 'w', encoding='utf-8') as f:
        f.write("SYNTHÈSE DES RÉSULTATS - ANALYSE DES SEUILS D'EAU\n")
        f.write("="*60 + "\n\n")
        
        f.write(f"SUPERFICIE ÉTHIOPIE: {ethiopia_area_mha:.2f} millions d'hectares\n")
        f.write(f"DONNÉES FAO (ARABLE): {OFFICIAL_ARABLE} millions d'hectares\n\n")
        
        f.write("RÉSULTATS PAR SEUIL:\n")
        f.write("-"*40 + "\n")
        
        for _, row in df_results.iterrows():
            f.write(f"Seuil {row['Seuil (%)']}%:\n")
            f.write(f"  • Eau: {row['Eau permanente (Mha)']:.4f} Mha ({row['Pourcentage eau']:.3f}%)\n")
            f.write(f"  • Terres arables ls: {row['Terres arables ls (Mha)']:.3f} Mha\n")
            f.write(f"  • Écart vs FAO: {row['Écart vs FAO (%)']:+.3f}%\n\n")
        
        f.write("CONCLUSION:\n")
        f.write("-"*40 + "\n")
        f.write(f"Seuil optimal recommandé: {best_threshold}%\n")
        f.write(f"Terres arables ls: {best_row['Terres arables ls (Mha)']:.3f} Mha\n")
        f.write(f"Écart avec données FAO: {best_row['Écart vs FAO (%)']:+.3f}%\n")
        
        if best_row['Écart vs FAO (%)'] < 0:
            f.write("→  légèrement inférieure aux données FAO\n")
        else:
            f.write("→  légèrement supérieure aux données FAO\n")
    
    print(f"✓ Rapport généré: {report_path}")
    print(f"✓ Synthèse générée: {summary_path}")

# ============================================================================
# EXÉCUTION PRINCIPALE
# ============================================================================

def main():
    """
    Fonction principale d'exécution
    """
    print("\n" + "="*80)
    print("SCRIPT D'ANALYSE DES SEUILS D'EAU PERMANENTE - ÉTHIOPIE")
    print("Version 2.0 - Complètement révisée")
    print("="*80)
    
    try:
        print("\nInitialisation...")
        print(f"Dossier des résultats: {RESULTS_DIR}")
        
        # Étape 1: Préparation des données
        print("\n[1/4] Préparation des données...")
        water_raster_path, ethiopia, transform = prepare_data()
        
        # Étape 2: Analyse des seuils
        print("\n[2/4] Analyse des seuils d'eau...")
        df_results, best_threshold, ethiopia_area = analyze_thresholds(water_raster_path, ethiopia)
        
        # Étape 3: Visualisations
        print("\n[3/4] Création des visualisations...")
        create_visualizations(df_results, ethiopia_area)
        
        # Étape 4: Rapport
        print("\n[4/4] Génération du rapport...")
        generate_comprehensive_report(df_results, best_threshold, ethiopia_area)
        
        # Résumé final
        print("\n" + "="*80)
        print("ANALYSE TERMINÉE AVEC SUCCÈS!")
        print("="*80)
        print(f"\n📊 RÉSULTATS CLÉS:")
        print(f"   • Superficie Éthiopie: {ethiopia_area:.2f} Mha")
        print(f"   • Meilleur seuil: {best_threshold}%")
        
        best_row = df_results[df_results['Seuil (%)'] == best_threshold].iloc[0]
        print(f"   • Eau détectée: {best_row['Eau permanente (Mha)']:.4f} Mha")
        print(f"   • Terres arables ls: {best_row['Terres arables ls (Mha)']:.3f} Mha")
        print(f"   • Écart avec FAO: {best_row['Écart vs FAO (%)']:+.3f}%")
        
        print(f"\n📁 FICHIERS GÉNÉRÉS dans: {RESULTS_DIR}")
        print("   - water_mosaic_full.tif (mosaïque)")
        print("   - water_ethiopia_final.tif (données découpées)")
        print("   - water_mask_XX.tif (masques d'eau)")
        print("   - resultats_complets.csv (résultats)")
        print("   - visualisation_complete.png (graphiques)")
        print("   - rapport_analyse_detaille.md (rapport)")
        print("="*80 + "\n")
        
    except FileNotFoundError as e:
        print(f"\n❌ ERREUR: Fichier non trouvé - {e}")
        print("Vérifiez les chemins d'accès aux données.")
        sys.exit(1)
    except MemoryError:
        print("\n❌ ERREUR: Mémoire insuffisante")
        print("Essayez de réduire la résolution ou augmentez la mémoire disponible.")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ ERREUR INATTENDUE: {e}")
        print("\nDétails de l'erreur:")
        traceback.print_exc()
        sys.exit(1)

# ============================================================================
# POINT D'ENTRÉE
# ============================================================================

if __name__ == "__main__":
    main()