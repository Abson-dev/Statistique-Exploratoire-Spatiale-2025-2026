# -*- coding: utf-8 -*-
"""
================================================================================
PROJET: IDENTIFICATION DES TERRES ARABLES EN ETHIOPIE
ETAPE 3 & 4: VERSION RAPIDE ET SIMPLIFIÉE
================================================================================
"""

import numpy as np
import rasterio
import rasterio.windows
from rasterio.features import rasterize
from rasterio.windows import Window
from pathlib import Path
import geopandas as gpd
import pandas as pd
import folium
from folium.raster_layers import ImageOverlay
import matplotlib.pyplot as plt
from pyproj import Transformer
import gc

# ===========================================================================
# CONFIGURATION
# ===========================================================================

BASE_DIR = Path(r"C:\Users\HP\Desktop\LESLYE\ISEP3\SES\TP4-SES")
DATA_DIR = BASE_DIR / "data"
OUTPUT_DIR = BASE_DIR / "output"
PREP = OUTPUT_DIR / "01_preprocessed"
MAPS = OUTPUT_DIR / "02_maps"
STATS = OUTPUT_DIR / "03_statistics"

MAPS.mkdir(parents=True, exist_ok=True)
STATS.mkdir(parents=True, exist_ok=True)

print("=" * 80)
print("ETAPE 3 & 4: VERSION RAPIDE")
print("=" * 80)
print()

# ===========================================================================
# CHARGER LES DONNÉES
# ===========================================================================

print("1. CHARGEMENT DES RASTERS")
print("-" * 80)

# Carte de base
base_path = MAPS / "base_potential_cultivable_binary.tif"
with rasterio.open(base_path) as src:
    base_arr = src.read(1)
    meta = src.meta.copy()
    transform = src.transform
    crs = src.crs
    bounds = src.bounds

print(f"   Base: {base_arr.shape}")

# Eau
water_path = PREP / "water_occurrence_ethiopia.tif"
with rasterio.open(water_path) as src:
    water_arr = src.read(1)
print(f"   Eau: {water_arr.shape}")

# Impervious
impervious_path = PREP / "impervious_ethiopia.tif"
with rasterio.open(impervious_path) as src:
    impervious_arr = src.read(1)
print(f"   Impervious: {impervious_arr.shape}")

# Aires protégées - RASTERISER DIRECTEMENT
protected_shp = PREP / "protected_areas_ethiopia.shp"
protected_gdf = gpd.read_file(protected_shp)
protected_gdf = protected_gdf.to_crs(crs)

print(f"   Rasterisation WDPA (méthode rapide)...")
# Utiliser rasterize au lieu de geometry_mask (plus rapide)
shapes = [(geom, 1) for geom in protected_gdf.geometry]
protected_arr = rasterize(
    shapes,
    out_shape=base_arr.shape,
    transform=transform,
    fill=0,
    dtype=np.uint8
)
print(f"   WDPA: {protected_arr.shape}")

print()

# ===========================================================================
# FONCTION: SAUVEGARDER + CARTE HTML
# ===========================================================================

def save_and_map(arr, name, title, color="YlGn"):
    """Sauvegarde raster + crée carte HTML"""
    
    # Sauvegarder GeoTIFF
    tif_path = MAPS / f"{name}.tif"
    out_meta = meta.copy()
    out_meta.update({"dtype": "uint8", "compress": "lzw"})
    with rasterio.open(tif_path, "w", **out_meta) as dst:
        dst.write(arr.astype(np.uint8), 1)
    
    # Créer HTML
    step = 100
    arr_small = arr[::step, ::step]
    
    tmp_png = MAPS / f"tmp_{name}.png"
    plt.imsave(tmp_png, arr_small, cmap=color, vmin=0, vmax=1)
    
    transformer = Transformer.from_crs("EPSG:32637", "EPSG:4326", always_xy=True)
    left, bottom = transformer.transform(bounds.left, bounds.bottom)
    right, top = transformer.transform(bounds.right, bounds.top)
    
    m = folium.Map(location=[(top+bottom)/2, (left+right)/2], zoom_start=6, tiles="CartoDB positron")
    
    ImageOverlay(
        name=title,
        image=str(tmp_png),
        bounds=[[bottom, left], [top, right]],
        opacity=0.8
    ).add_to(m)
    
    legend_html = f"""
    <div style="position: fixed; bottom: 50px; right: 50px; width: 280px; 
                background-color: white; border:2px solid #333; z-index:9999; 
                font-size:13px; padding: 12px; border-radius: 5px;">
    <b style="color: #333;">{title}</b><br><br>
    <i style="background: #228B22; width: 22px; height: 22px; 
       float: left; margin-right: 10px; border-radius: 3px;"></i> 
       <b>Terres arables</b><br><br>
    <i style="background: #E8E8E8; width: 22px; height: 22px; 
       float: left; margin-right: 10px; border: 1px solid #999; border-radius: 3px;"></i> 
       Non cultivables<br><br>
    <small style="color: #666;">Résolution: 30m</small>
    </div>
    """
    m.get_root().html.add_child(folium.Element(legend_html))
    
    folium.LayerControl().add_to(m)
    
    html_path = MAPS / f"{name}.html"
    m.save(str(html_path))
    tmp_png.unlink()
    
    print(f"   [OK] {name}: {np.sum(arr==1):,} pixels = {np.sum(arr==1)*0.09:,.0f} ha")

# ===========================================================================
# FONCTION: STATS RAPIDES
# ===========================================================================

def quick_stats(arr, boundaries, level_name):
    """Calcule stats zone par zone PAR BLOCS (ultra optimisé mémoire)"""
    
    pixel_area = 0.09
    total_ha = np.sum(arr == 1) * pixel_area
    
    results = []
    
    # Traiter chaque zone séparément
    for idx, row in boundaries.iterrows():
        name = row.get('NAME_1') or row.get('NAME_2') or f"Zone_{idx}"
        geom = row.geometry
        
        # Compter pixels par blocs de 5000x5000
        zone_pixels = 0
        block_size = 5000
        height, width = arr.shape
        
        for i in range(0, height, block_size):
            for j in range(0, width, block_size):
                h = min(block_size, height - i)
                w = min(block_size, width - j)
                
                # Bloc des terres arables
                arr_block = arr[i:i+h, j:j+w]
                
                # Transformation pour ce bloc
                from rasterio.windows import Window
                block_transform = rasterio.windows.transform(
                    Window(j, i, w, h), transform
                )
                
                # Rasteriser la zone pour ce bloc
                zone_block = rasterize(
                    [(geom, 1)],
                    out_shape=(h, w),
                    transform=block_transform,
                    fill=0,
                    dtype=np.uint8
                )
                
                # Compter (bloc par bloc = petite taille mémoire)
                zone_pixels += np.sum((arr_block == 1) & (zone_block == 1))
        
        zone_ha = zone_pixels * pixel_area
        zone_pct = (zone_ha / total_ha * 100) if total_ha > 0 else 0
        
        results.append({
            'Zone': name,
            'Superficie_ha': round(zone_ha, 2),
            'Pourcentage': round(zone_pct, 2)
        })
    
    df = pd.DataFrame(results)
    df = df.sort_values('Superficie_ha', ascending=False)
    
    return total_ha, df

# ===========================================================================
# ETAPE 3: CRÉER LES 3 SCÉNARIOS
# ===========================================================================

print("2. CRÉATION DES 3 SCÉNARIOS")
print("-" * 80)

scenarios = {
    "90pct": 90,
    "40pct": 40,
    "10pct": 10
}

results = {}

for name, threshold in scenarios.items():
    print(f"\n   Scénario EAU {threshold}% (tous masques appliqués)")
    
    # Créer le résultat
    result = base_arr.copy()
    result[water_arr > threshold] = 0      # Masque eau
    result[impervious_arr > 0] = 0         # Masque impervious
    result[protected_arr > 0] = 0          # Masque WDPA
    
    # Sauvegarder + carte
    color = "Greens" if name == "90pct" else "YlGn" if name == "40pct" else "RdYlGn"
    save_and_map(result, f"arable_final_{name}", f"Terres arables - Scénario {threshold}%", color)
    
    results[name] = result
    
    # Libérer mémoire
    gc.collect()

print()

# ===========================================================================
# ETAPE 4: CALCULS STATISTIQUES
# ===========================================================================

print("3. CALCULS DE SUPERFICIES")
print("-" * 80)

boundaries_regions = gpd.read_file(DATA_DIR / "boundaries" / "gadm41_ETH_1.shp").to_crs(crs)
boundaries_zones = gpd.read_file(DATA_DIR / "boundaries" / "gadm41_ETH_2.shp").to_crs(crs)

summary = []

for name, arr in results.items():
    threshold = scenarios[name]
    print(f"\n   Scénario {threshold}%")
    
    # Stats régions
    print(f"      Régions...")
    total_reg, df_reg = quick_stats(arr, boundaries_regions, "Région")
    csv_reg = STATS / f"superficies_regions_{name}.csv"
    df_reg.to_csv(csv_reg, index=False, encoding='utf-8')
    
    # Stats zones
    print(f"      Zones...")
    total_zone, df_zone = quick_stats(arr, boundaries_zones, "Zone")
    csv_zone = STATS / f"superficies_zones_{name}.csv"
    df_zone.to_csv(csv_zone, index=False, encoding='utf-8')
    
    # Résumé
    country_total_ha = 110_000_000
    pct_national = (total_reg / country_total_ha * 100)
    
    summary.append({
        'Scenario': f"{threshold}%",
        'Seuil_eau': threshold,
        'Superficie_ha': round(total_reg, 2),
        'Pourcentage_national': round(pct_national, 2)
    })
    
    print(f"      Total: {total_reg:,.0f} ha ({pct_national:.2f}%)")
    print(f"      CSV: {csv_reg.name}, {csv_zone.name}")

# ===========================================================================
# RAPPORT FINAL
# ===========================================================================

print("\n" + "=" * 80)
print("COMPARAISON DES SCENARIOS")
print("=" * 80)

df_summary = pd.DataFrame(summary)
print("\n" + df_summary.to_string(index=False))

summary_csv = STATS / "comparaison_scenarios.csv"
df_summary.to_csv(summary_csv, index=False, encoding='utf-8')

print("\n" + "=" * 80)
print("FICHIERS GÉNÉRÉS:")
print("   CARTES HTML: 3")
print("   FICHIERS CSV: 7")
print("=" * 80)
print("\n TERMINÉ!")
print("=" * 80)