# ==============================================================================
# SCRIPT DE DIAGNOSTIC DES DONNÉES SPATIALES - OUGANDA
# Objectif : Analyser les propriétés des rasters et shapefiles
# ==============================================================================
import os
import re
from glob import glob
import numpy as np
import pandas as pd
import geopandas as gpd
import rasterio
from rasterio.mask import mask

# -------------------------
# 0. PARAMÈTRES & CHEMINS
# -------------------------
print("=" * 80)
print("DIAGNOSTIC DES DONNÉES SPATIALES".center(80))
print("=" * 80)

out_dir = "outputs/diagnostic"
os.makedirs(out_dir, exist_ok=True)

gadm_dir = "data/gadm41_UGA_shp"
rast_dir = "data/rasters"

print(f"\n✓ Dossier de diagnostic créé : {out_dir}\n")

# -------------------------
# 1. DIAGNOSTIC DES SHAPEFILES
# -------------------------
print("=" * 80)
print("ANALYSE DES DONNÉES ADMINISTRATIVES".center(80))
print("=" * 80)

shp0_path = os.path.join(gadm_dir, "gadm41_UGA_0.shp")
shp1_path = os.path.join(gadm_dir, "gadm41_UGA_1.shp")

shapefile_info = []

# Niveau 0 (Pays)
if os.path.exists(shp0_path):
    gadm0 = gpd.read_file(shp0_path)
    bounds = gadm0.total_bounds
    
    print("\n┌─ NIVEAU 0 : FRONTIÈRE NATIONALE ─────────────────────────────────────┐")
    print(f"│ Fichier           : {os.path.basename(shp0_path):<50} │")
    print(f"│ Nombre d'entités  : {len(gadm0):<50} │")
    print(f"│ Système de coord. : {str(gadm0.crs):<50} │")
    print(f"│ Type de géométrie : {gadm0.geometry.type.unique()[0]:<50} │")
    print(f"│ Emprise (bounds)  : [{bounds[0]:.4f}, {bounds[1]:.4f}, {bounds[2]:.4f}, {bounds[3]:.4f}] │")
    print(f"│ Colonnes          : {', '.join(gadm0.columns[:5])}... │")
    print("└───────────────────────────────────────────────────────────────────────┘")
    
    shapefile_info.append({
        "niveau": 0,
        "fichier": os.path.basename(shp0_path),
        "nb_entites": len(gadm0),
        "crs": str(gadm0.crs),
        "type_geometrie": gadm0.geometry.type.unique()[0],
        "minx": bounds[0],
        "miny": bounds[1],
        "maxx": bounds[2],
        "maxy": bounds[3]
    })
else:
    print("\n⚠ Niveau 0 non trouvé")
    gadm0 = None

# Niveau 1 (Régions)
if os.path.exists(shp1_path):
    gadm1 = gpd.read_file(shp1_path)
    bounds = gadm1.total_bounds
    
    print("\n┌─ NIVEAU 1 : SUBDIVISIONS ADMINISTRATIVES ────────────────────────────┐")
    print(f"│ Fichier           : {os.path.basename(shp1_path):<50} │")
    print(f"│ Nombre d'entités  : {len(gadm1):<50} │")
    print(f"│ Système de coord. : {str(gadm1.crs):<50} │")
    print(f"│ Type de géométrie : {gadm1.geometry.type.unique()[0]:<50} │")
    print(f"│ Emprise (bounds)  : [{bounds[0]:.4f}, {bounds[1]:.4f}, {bounds[2]:.4f}, {bounds[3]:.4f}] │")
    
    if 'NAME_1' in gadm1.columns:
        regions = gadm1['NAME_1'].tolist()
        print(f"│ Régions ({len(regions)})     : {', '.join(regions[:3])}... │")
    
    print("└───────────────────────────────────────────────────────────────────────┘")
    
    shapefile_info.append({
        "niveau": 1,
        "fichier": os.path.basename(shp1_path),
        "nb_entites": len(gadm1),
        "crs": str(gadm1.crs),
        "type_geometrie": gadm1.geometry.type.unique()[0],
        "minx": bounds[0],
        "miny": bounds[1],
        "maxx": bounds[2],
        "maxy": bounds[3]
    })
else:
    print("\n⚠ Niveau 1 non trouvé")
    gadm1 = None

# Exporter les infos shapefiles
if shapefile_info:
    df_shp = pd.DataFrame(shapefile_info)
    df_shp.to_csv(f"{out_dir}/shapefiles_diagnostic.csv", index=False)
    print(f"\n✓ Diagnostic shapefiles exporté : {out_dir}/shapefiles_diagnostic.csv")

# -------------------------
# 2. DIAGNOSTIC DES RASTERS
# -------------------------
print("\n" + "=" * 80)
print("ANALYSE DES RASTERS".center(80))
print("=" * 80)

raster_files = sorted(glob(os.path.join(rast_dir, "*.tif")) +
                      glob(os.path.join(rast_dir, "*.tiff")))

if len(raster_files) == 0:
    raise FileNotFoundError(f"Aucun raster .tif/.tiff trouvé dans {rast_dir}")

def extract_year(filename):
    nm = os.path.basename(filename)
    m = re.search(r"(\d{4})(?=\.(tif|tiff)$)", nm, flags=re.IGNORECASE)
    if m:
        return int(m.group(1))
    all4 = re.findall(r"\d{4}", nm)
    return int(all4[-1]) if all4 else None

years = [extract_year(f) for f in raster_files]

print(f"\n📊 Résumé général :")
print(f"   • Nombre de rasters : {len(raster_files)}")
print(f"   • Période couverte  : {min(years)} - {max(years)}")
print(f"   • Répertoire source : {rast_dir}")

# Analyse détaillée de chaque raster
print("\n" + "-" * 80)
print("PROPRIÉTÉS DÉTAILLÉES PAR RASTER".center(80))
print("-" * 80)

raster_metadata = []

for idx, (fichier, an) in enumerate(zip(raster_files, years)):
    with rasterio.open(fichier) as src:
        # Lecture du premier band pour statistiques
        band1 = src.read(1, masked=True)
        na_pct = float(np.mean(band1.mask) * 100) if hasattr(band1, 'mask') else 0.0
        
        print(f"\n╔═══ Raster {idx+1}/{len(raster_files)} : Année {an} ═══════════════════════════════════════════╗")
        print(f"║ Fichier         : {os.path.basename(fichier):<55} ║")
        print(f"║ Dimensions      : {src.height} lignes × {src.width} colonnes × {src.count} bande(s){'':<23} ║")
        print(f"║ Résolution      : {src.res[0]:.8f} × {src.res[1]:.8f} (degrés){'':<23} ║")
        print(f"║ Emprise (BBOX)  : ({src.bounds.left:.4f}, {src.bounds.bottom:.4f}, {src.bounds.right:.4f}, {src.bounds.top:.4f}){'':<10} ║")
        print(f"║ Projection (CRS): {str(src.crs):<55} ║")
        print(f"║ Type de données : {src.dtypes[0]:<55} ║")
        print(f"║ Valeur NoData   : {src.nodata if src.nodata is not None else 'Non définie':<55} ║")
        print(f"║ Pixels NoData   : {na_pct:.2f}%{'':<53} ║")
        
        # Statistiques par bande
        print(f"║ {'─' * 76} ║")
        for i in range(1, min(src.count + 1, 4)):  # Max 3 bandes affichées
            band = src.read(i, masked=True)
            print(f"║ Bande {i}        : min={float(band.min()):.4f}  max={float(band.max()):.4f}  mean={float(band.mean()):.4f}  std={float(band.std()):.4f}{'':<5} ║")
        
        print(f"╚{'═' * 78}╝")
        
        # Stocker les métadonnées
        raster_metadata.append({
            "annee": an,
            "fichier": os.path.basename(fichier),
            "hauteur": src.height,
            "largeur": src.width,
            "nb_bandes": src.count,
            "resolution_x": src.res[0],
            "resolution_y": src.res[1],
            "projection": str(src.crs),
            "type_donnees": str(src.dtypes[0]),
            "nodata": src.nodata,
            "pct_nodata": round(na_pct, 2),
            "min_valeur": float(band1.min()),
            "max_valeur": float(band1.max()),
            "moyenne": float(band1.mean()),
            "ecart_type": float(band1.std()),
            "bbox_minx": src.bounds.left,
            "bbox_miny": src.bounds.bottom,
            "bbox_maxx": src.bounds.right,
            "bbox_maxy": src.bounds.top
        })

# Exporter les métadonnées complètes
df_meta = pd.DataFrame(raster_metadata)
meta_csv = f"{out_dir}/rasters_metadata_complet.csv"
df_meta.to_csv(meta_csv, index=False, encoding="utf-8-sig")

print(f"\n✓ Métadonnées complètes exportées : {meta_csv}")

# -------------------------
# 3. VÉRIFICATION DE LA COHÉRENCE CRS
# -------------------------
print("\n" + "=" * 80)
print("VÉRIFICATION DE LA COHÉRENCE DES SYSTÈMES DE COORDONNÉES".center(80))
print("=" * 80)

if gadm0 is not None:
    with rasterio.open(raster_files[0]) as src:
        raster_crs = src.crs
    
    print(f"\n📍 Système de coordonnées :")
    print(f"   • Shapefiles : {gadm0.crs}")
    print(f"   • Rasters    : {raster_crs}")
    
    if gadm0.crs != raster_crs:
        print(f"\n⚠  ATTENTION : Les systèmes de coordonnées diffèrent !")
        print(f"   → Reprojection nécessaire pour les shapefiles")
    else:
        print(f"\n✓ Les systèmes de coordonnées sont cohérents")

# -------------------------
# 4. TEST DE MASQUAGE
# -------------------------
if gadm0 is not None:
    print("\n" + "=" * 80)
    print("TEST DE MASQUAGE PAR LES FRONTIÈRES".center(80))
    print("=" * 80)
    
    # Harmoniser les CRS si nécessaire
    if gadm0.crs != raster_crs:
        print(f"\n→ Reprojection : {gadm0.crs} → {raster_crs}")
        gadm0_proj = gadm0.to_crs(raster_crs)
    else:
        gadm0_proj = gadm0
    
    # Tester le masquage sur le premier raster
    print(f"\n🔬 Test de masquage sur : {os.path.basename(raster_files[0])}")
    
    with rasterio.open(raster_files[0]) as src:
        print(f"   • Dimensions originales : {src.height} × {src.width}")
        
        out_image, out_transform = mask(
            src, 
            gadm0_proj.geometry, 
            crop=True,
            nodata=np.nan,
            filled=True
        )
        
        arr_masked = out_image[0].astype(float)
        arr_masked[arr_masked == src.nodata] = np.nan
        
        nb_pixels_total = arr_masked.size
        nb_pixels_valides = np.sum(~np.isnan(arr_masked))
        pct_valides = (nb_pixels_valides / nb_pixels_total) * 100
        
        print(f"   • Dimensions masquées   : {arr_masked.shape[0]} × {arr_masked.shape[1]}")
        print(f"   • Pixels valides        : {nb_pixels_valides:,} / {nb_pixels_total:,} ({pct_valides:.2f}%)")
        print(f"   • Range après masquage  : [{np.nanmin(arr_masked):.4f}, {np.nanmax(arr_masked):.4f}]")
        print(f"\n✓ Test de masquage réussi")

# -------------------------
# 5. RÉSUMÉ STATISTIQUE
# -------------------------
print("\n" + "=" * 80)
print("RÉSUMÉ STATISTIQUE GLOBAL".center(80))
print("=" * 80)

print(f"\n📈 Statistiques sur l'ensemble des rasters :")
print(f"   • Valeur minimale globale : {df_meta['min_valeur'].min():.6f}")
print(f"   • Valeur maximale globale : {df_meta['max_valeur'].max():.6f}")
print(f"   • Moyenne des moyennes    : {df_meta['moyenne'].mean():.6f}")
print(f"   • Écart-type moyen        : {df_meta['ecart_type'].mean():.6f}")
print(f"   • Taux NoData moyen       : {df_meta['pct_nodata'].mean():.2f}%")

print(f"\n📐 Homogénéité spatiale :")
unique_heights = df_meta['hauteur'].nunique()
unique_widths = df_meta['largeur'].nunique()
unique_resolutions = df_meta['resolution_x'].nunique()

if unique_heights == 1 and unique_widths == 1 and unique_resolutions == 1:
    print(f"   ✓ Tous les rasters ont les mêmes dimensions et résolution")
    print(f"     → {df_meta['hauteur'].iloc[0]} × {df_meta['largeur'].iloc[0]} pixels")
    print(f"     → Résolution : {df_meta['resolution_x'].iloc[0]:.8f}°")
else:
    print(f"   ⚠ Dimensions ou résolutions variables détectées :")
    print(f"     → Hauteurs uniques : {unique_heights}")
    print(f"     → Largeurs uniques : {unique_widths}")
    print(f"     → Résolutions uniques : {unique_resolutions}")

# -------------------------
# 6. RAPPORT FINAL
# -------------------------
print("\n" + "=" * 80)
print("DIAGNOSTIC TERMINÉ".center(80))
print("=" * 80)

print(f"\nFichiers générés :")
print(f"   • {out_dir}/shapefiles_diagnostic.csv")
print(f"   • {out_dir}/rasters_metadata_complet.csv")

print(f"\nLe diagnostic est complet. Vous pouvez maintenant lancer le script de visualisation.")
print("=" * 80)