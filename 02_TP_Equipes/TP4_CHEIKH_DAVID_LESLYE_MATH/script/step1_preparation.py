"""
================================================================================
PROJET: IDENTIFICATION DES TERRES ARABLES EN ETHIOPIE (30m)
ETAPE 1: PREPARATION SPATIALE - MOSAIQUAGE ET CLIPPING
================================================================================
"""

import os
import glob
import numpy as np
import pandas as pd
import geopandas as gpd
import rasterio
from rasterio.merge import merge
from rasterio.mask import mask
from rasterio.warp import calculate_default_transform, reproject, Resampling
from rasterio.io import MemoryFile
from rasterio.windows import Window
from rasterio.plot import show
import matplotlib.pyplot as plt
from pathlib import Path
from shapely.geometry import box
import warnings
warnings.filterwarnings('ignore')

# Configuration des chemins
BASE_DIR = Path(r"C:\Users\HP\Desktop\LESLYE\ISEP3\SES\TP4-SES")
DATA_DIR = BASE_DIR / "data"
OUTPUT_DIR = BASE_DIR / "output"

# Creation des dossiers de sortie
(OUTPUT_DIR / "01_preprocessed").mkdir(parents=True, exist_ok=True)
(OUTPUT_DIR / "logs").mkdir(parents=True, exist_ok=True)

print("=" * 80)
print("ETAPE 1: PREPARATION SPATIALE - MOSAIQUAGE ET CLIPPING")
print("=" * 80)
print(f"\nRepertoire de travail: {BASE_DIR}")
print(f"Repertoire de sortie: {OUTPUT_DIR / '01_preprocessed'}")
print("\n")

# ===========================================================================
# UTIL: Clipper un grand raster par blocs pour economiser la memoire
# ===========================================================================

def clip_large_raster_by_blocks(src_path, boundary_gdf, output_path, block_size=1024):
    """
    Clippe un grand raster par petits blocs pour eviter les problemes de memoire.
    """
    print(f"   Clipping par blocs (taille bloc: {block_size}x{block_size})...")
    
    with rasterio.open(src_path) as src:
        # Reprojeter boundary si necessaire
        if boundary_gdf.crs != src.crs:
            boundary_reproj = boundary_gdf.to_crs(src.crs)
        else:
            boundary_reproj = boundary_gdf
        
        # Obtenir la fenetre du raster qui intersecte la geometrie
        geom_bounds = boundary_reproj.total_bounds
        window = src.window(*geom_bounds)
        
        # Arrondir la fenetre
        window = window.round_lengths(pixel_precision=0)
        window = window.round_offsets(pixel_precision=0)
        
        # Dimensions de la fenetre
        win_height = int(window.height)
        win_width = int(window.width)
        win_transform = src.window_transform(window)
        
        # Preparer le raster de sortie
        out_meta = src.meta.copy()
        out_meta.update({
            "height": win_height,
            "width": win_width,
            "transform": win_transform,
            "compress": "lzw"
        })
        
        # Creer le fichier de sortie
        with rasterio.open(output_path, "w", **out_meta) as dst:
            # Traiter par petits blocs
            for i in range(0, win_height, block_size):
                for j in range(0, win_width, block_size):
                    # Dimensions du bloc actuel
                    h = min(block_size, win_height - i)
                    w = min(block_size, win_width - j)
                    
                    # Lire le bloc
                    block_window = Window(
                        col_off=window.col_off + j,
                        row_off=window.row_off + i,
                        width=w,
                        height=h
                    )
                    
                    block_data = src.read(window=block_window)
                    block_transform = src.window_transform(block_window)
                    
                    # Creer le masque pour ce bloc
                    from rasterio.features import geometry_mask
                    block_mask = geometry_mask(
                        boundary_reproj.geometry,
                        transform=block_transform,
                        out_shape=(h, w),
                        invert=True
                    )
                    
                    # Appliquer le masque
                    nodata_value = src.nodata if src.nodata is not None else 0
                    block_data[:, ~block_mask] = nodata_value
                    
                    # Ecrire le bloc
                    dst.write(block_data, window=Window(j, i, w, h))
            
            print(f"   [OK] Clipping termine: {win_width}x{win_height} pixels")
    
    return output_path

# ===========================================================================
# UTIL: Reprojeter un raster
# ===========================================================================

def reproject_raster(src_path, target_crs="EPSG:32637", out_dir=None, resolution=30):
    """Reprojette un raster vers target_crs."""
    if out_dir is None:
        out_dir = src_path.parent
    out_dir.mkdir(parents=True, exist_ok=True)

    with rasterio.open(src_path) as src:
        transform, width, height = calculate_default_transform(
            src.crs, target_crs, src.width, src.height, *src.bounds, resolution=resolution
        )
        kwargs = src.meta.copy()
        kwargs.update({
            "crs": target_crs,
            "transform": transform,
            "width": width,
            "height": height,
            "compress": "lzw"
        })

        out_path = out_dir / f"{src_path.stem}_reproj.tif"
        with rasterio.open(out_path, "w", **kwargs) as dst:
            for i in range(1, src.count + 1):
                reproject(
                    source=rasterio.band(src, i),
                    destination=rasterio.band(dst, i),
                    src_transform=src.transform,
                    src_crs=src.crs,
                    dst_transform=transform,
                    dst_crs=target_crs,
                    resampling=Resampling.nearest
                )
    return out_path

# ===========================================================================
# 1. CHARGEMENT DES LIMITES ADMINISTRATIVES
# ===========================================================================

print("1. CHARGEMENT DES LIMITES ADMINISTRATIVES")
print("-" * 80)

boundary_files = {
    "pays": DATA_DIR / "boundaries" / "gadm41_ETH_0.shp",
    "regions": DATA_DIR / "boundaries" / "gadm41_ETH_1.shp",
    "zones": DATA_DIR / "boundaries" / "gadm41_ETH_2.shp"
}

boundaries = {}
for level, filepath in boundary_files.items():
    if filepath.exists():
        gdf = gpd.read_file(filepath)
        boundaries[level] = gdf
        print(f"[OK] {level.upper()}: {len(gdf)} entites chargees")
        print(f"     CRS: {gdf.crs}")
    else:
        print(f"[ERREUR] {level.upper()}: Fichier non trouve")

if "pays" not in boundaries:
    raise FileNotFoundError("Limite du pays introuvable")

ethiopia_boundary = boundaries["pays"]
ethiopia_geom = ethiopia_boundary.geometry

print(f"\nEmprise de l'Ethiopie: {ethiopia_boundary.total_bounds}")
print()

# ===========================================================================
# 2. MOSAIQUAGE DES 4 TUILES D'EAU (JRC OCCURRENCE)
# ===========================================================================

print("2. MOSAIQUAGE DES 4 TUILES D'EAU (JRC OCCURRENCE)")
print("-" * 80)

water_files = [
    DATA_DIR / "water" / "occurrence_30E_10Nv1_4_2021.tif",
    DATA_DIR / "water" / "occurrence_30E_20Nv1_4_2021.tif",
    DATA_DIR / "water" / "occurrence_40E_10Nv1_4_2021.tif",
    DATA_DIR / "water" / "occurrence_40E_20Nv1_4_2021.tif"
]

water_files_existing = [f for f in water_files if f.exists()]
print(f"Tuiles trouvees: {len(water_files_existing)}/4")

mosaic_path = None
water_clipped_path = None

if len(water_files_existing) == 0:
    print("[ERREUR] Aucune tuile d'eau trouvee")
else:
    water_tiles = []
    try:
        for i, filepath in enumerate(water_files_existing, 1):
            src = rasterio.open(filepath)
            water_tiles.append(src)
            print(f"   Tuile {i}: {filepath.name}")
            print(f"      Resolution: {src.res}")
            print(f"      CRS: {src.crs}")

        print("\n   Fusion des tuiles en cours...")
        mosaic, mosaic_transform = merge(water_tiles)

        mosaic_meta = water_tiles[0].meta.copy()
        mosaic_meta.update({
            "driver": "GTiff",
            "height": mosaic.shape[1],
            "width": mosaic.shape[2],
            "transform": mosaic_transform,
            "compress": "lzw",
            "crs": water_tiles[0].crs
        })

        mosaic_path = OUTPUT_DIR / "01_preprocessed" / "water_occurrence_mosaic.tif"
        with rasterio.open(mosaic_path, "w", **mosaic_meta) as dest:
            dest.write(mosaic)

        print(f"   [OK] Mosaique creee: {mosaic_path.name}")
        print(f"        Shape: {mosaic.shape}")

    finally:
        for t in water_tiles:
            try:
                t.close()
            except:
                pass

    # Reprojection vers EPSG:32637
    print("\n   Reprojection vers EPSG:32637...")
    ethiopia_reproj = ethiopia_boundary.to_crs("EPSG:32637")
    
    mosaic_32637_path = OUTPUT_DIR / "01_preprocessed" / "water_occurrence_mosaic_32637.tif"
    
    with rasterio.open(mosaic_path) as src:
        transform, width, height = calculate_default_transform(
            src.crs, "EPSG:32637", src.width, src.height, *src.bounds, resolution=30
        )

        reproj_meta = src.meta.copy()
        reproj_meta.update({
            "crs": "EPSG:32637",
            "transform": transform,
            "width": width,
            "height": height,
            "compress": "lzw"
        })

        with rasterio.open(mosaic_32637_path, "w", **reproj_meta) as dst:
            for i in range(1, src.count + 1):
                reproject(
                    source=rasterio.band(src, i),
                    destination=rasterio.band(dst, i),
                    src_transform=src.transform,
                    src_crs=src.crs,
                    dst_transform=transform,
                    dst_crs="EPSG:32637",
                    resampling=Resampling.nearest
                )

    print(f"   [OK] Fichier reprojete: {mosaic_32637_path.name}")

    # Clipping par blocs pour economiser la memoire
    print("\n   Clipping avec les limites de l'Ethiopie...")
    water_clipped_path = OUTPUT_DIR / "01_preprocessed" / "water_occurrence_ethiopia.tif"
    
    clip_large_raster_by_blocks(
        mosaic_32637_path, 
        ethiopia_reproj, 
        water_clipped_path,
        block_size=2048
    )
    
    print(f"   [OK] Eau clippee: {water_clipped_path.name}")
    
    with rasterio.open(water_clipped_path) as src:
        print(f"        Resolution: {src.res[0]:.2f}m x {src.res[1]:.2f}m")
        print(f"        CRS: {src.crs}")
        print(f"        Shape: {src.width}x{src.height}")

print()

# ===========================================================================
# 3. FONCTION: Mosaïquer et clipper un dossier de rasters
# ===========================================================================

def mosaic_and_clip_rasters(folder_path, output_name, boundary_gdf, prefix=None):
    """
    Mosaique et clippe les rasters d'un dossier.
    """
    raster_files = sorted([f for f in folder_path.glob("*.tif") 
                          if (prefix is None or f.name.startswith(prefix))])
    
    if len(raster_files) == 0:
        print(f"[ERREUR] Aucun raster trouve dans {folder_path} (prefix={prefix})")
        return None

    print(f"[TRAITEMENT] {folder_path.name}")
    print(f"   {len(raster_files)} fichiers trouves (prefix={prefix})")
    
    src_list = [rasterio.open(f) for f in raster_files]
    try:
        mosaic, mosaic_transform = merge(src_list)
        mosaic_meta = src_list[0].meta.copy()
        mosaic_meta.update({
            "driver": "GTiff",
            "height": mosaic.shape[1],
            "width": mosaic.shape[2],
            "transform": mosaic_transform,
            "compress": "lzw",
            "crs": src_list[0].crs
        })

        # Reprojeter boundary vers le CRS de la mosaique
        boundary_reproj = boundary_gdf.to_crs(mosaic_meta["crs"])

        # Verifier intersection
        raster_bounds = box(*src_list[0].bounds)
        country_union = boundary_reproj.unary_union
        if not raster_bounds.intersects(country_union):
            print("   [AVERTISSEMENT] Pas d'intersection - clipping ignore")
            return None

        # Sauvegarder mosaique temporaire
        temp_path = OUTPUT_DIR / "01_preprocessed" / f"temp_{output_name}"
        with rasterio.open(temp_path, "w", **mosaic_meta) as dest:
            dest.write(mosaic)
        
        # Clipper par blocs
        output_path = OUTPUT_DIR / "01_preprocessed" / output_name
        clip_large_raster_by_blocks(temp_path, boundary_reproj, output_path)
        
        # Supprimer le fichier temporaire
        if temp_path.exists():
            temp_path.unlink()

        print(f"   [OK] {output_name}")
        return output_path

    finally:
        for ds in src_list:
            try:
                ds.close()
            except:
                pass

# ===========================================================================
# 4. FONCTION: Fusionner les shapefiles WDPA
# ===========================================================================

def merge_protected_areas_shapefiles(base_folder):
    """Fusionne les 3 shapefiles WDPA."""
    parts = ["_shp_0", "_shp_1", "_shp_2"]
    gdfs = []
    
    for part in parts:
        shp_folder = base_folder / f"WDPA_WDOECM_Dec2025_Public_ETH{part}"
        shp_files = list(shp_folder.glob("*.shp"))
        
        if len(shp_files) > 0:
            shp_path = shp_files[0]
            gdf = gpd.read_file(shp_path)
            gdfs.append(gdf)
            print(f"   [OK] {shp_path.name} ({len(gdf)} entites)")
        else:
            print(f"   [AVERTISSEMENT] Aucun shapefile dans {shp_folder.name}")

    if not gdfs:
        print("   [ERREUR] Aucun shapefile WDPA charge")
        return None

    merged = gpd.GeoDataFrame(pd.concat(gdfs, ignore_index=True), crs=gdfs[0].crs)
    output_path = OUTPUT_DIR / "01_preprocessed" / "protected_areas_merged.shp"
    merged.to_file(output_path)
    print(f"   [OK] Fusion enregistree: {output_path.name}")
    return merged

# ===========================================================================
# 5. CLIPPING DES AUTRES COUCHES
# ===========================================================================

print("3. CLIPPING DES AUTRES COUCHES RASTER")
print("-" * 80)

clipped_files = {}

# FOREST
print( """ ------------------------ [FOREST HANSEN]

Les fichiers GeoTIFF Hansen correspondent bien à la zone géographique de l’Éthiopie.
   
-Les bounds du shapefile de l’Éthiopie vont de longitude ~33°E à ~48°E et de latitude ~3.4°N à ~14.8°N.

-Les bounds des rasters Hansen (treecover et lossyear) couvrent quasiment la même zone : ~33°E à ~48°E et ~3.4°N à ~14.9°N.

-Les deux sont en EPSG:4326 (WGS84), donc dans le même système de coordonnées.

Le test d’intersection = True qui a été fait montre que l’emprise des rasters recouvre bien l’emprise du shapefile de l’Éthiopie.--------------

""")

# GFSAD
print("\n[GFSAD]")
gfsad_path = DATA_DIR / "gfsad"
gfsad_output = mosaic_and_clip_rasters(gfsad_path, "cropland_ethiopia.tif", ethiopia_boundary)
if gfsad_output:
    clipped_files["gfsad"] = gfsad_output

# GFSAD
print("\n[GFSAD]")
gfsad_src = DATA_DIR / "gfsad"
gfsad_reproj_dir = gfsad_src / "reproj_epsg32637"
gfsad_reproj_dir.mkdir(parents=True, exist_ok=True)

# 1) Reprojection de tous les .tif GFSAD vers EPSG:32637, résolution 30 m
tif_list_gfsad = sorted(list(gfsad_src.glob("*.tif")))
if len(tif_list_gfsad) > 0:
    print(f"   Reprojection de {len(tif_list_gfsad)} fichiers GFSAD vers EPSG:32637...")
    for tif_file in tif_list_gfsad:
        outp = reproject_raster(
            tif_file,
            target_crs="EPSG:32637",
            out_dir=gfsad_reproj_dir,
            resolution=30
        )
        print(f"      {tif_file.name} -> {outp.name}")

    # 2) Mosaïque + clip à partir des rasters reprojetés
    gfsad_output = mosaic_and_clip_rasters(
        gfsad_reproj_dir,
        "cropland_ethiopia.tif",
        ethiopia_boundary
    )
    if gfsad_output:
        clipped_files["gfsad"] = gfsad_output
else:
    print("   [ERREUR] Aucun fichier GFSAD trouvé dans", gfsad_src)


# IMPERVIOUS
print("\n[IMPERVIOUS]")
impervious_src = DATA_DIR / "impervious"
impervious_reproj_dir = impervious_src / "reproj_epsg32637"
impervious_reproj_dir.mkdir(parents=True, exist_ok=True)

tif_list = sorted(list(impervious_src.glob("*.tif")))
if len(tif_list) > 0:
    print(f"   Reprojection de {len(tif_list)} fichiers vers EPSG:32637...")
    for tif_file in tif_list:
        outp = reproject_raster(tif_file, target_crs="EPSG:32637", out_dir=impervious_reproj_dir)

    impervious_output = mosaic_and_clip_rasters(impervious_reproj_dir, 
                                                "impervious_ethiopia.tif", ethiopia_boundary)
    if impervious_output:
        clipped_files["impervious"] = impervious_output
else:
    print("   [ERREUR] Aucun fichier impervious trouve")

# PENTE
print("\n[PENTE]")
pente_path = DATA_DIR / "pente"
pente_output = mosaic_and_clip_rasters(pente_path, "slope_ethiopia.tif", ethiopia_boundary)
if pente_output:
    clipped_files["pente"] = pente_output

# PROTECTED AREAS
print("\n[PROTECTED AREAS]")
protected_path = DATA_DIR / "protected_areas"
protected_gdf = merge_protected_areas_shapefiles(protected_path)
if protected_gdf is not None:
    output_shp = OUTPUT_DIR / "01_preprocessed" / "protected_areas_ethiopia.shp"
    protected_gdf.to_file(output_shp)

print()

# ===========================================================================
# 6. VERIFICATION DE L'ALIGNEMENT SPATIAL
# ===========================================================================

print("4. VERIFICATION DE L'ALIGNEMENT SPATIAL")
print("-" * 80)

all_clipped = [water_clipped_path] if water_clipped_path else []
all_clipped += [p for p in clipped_files.values() if p and p.exists()]

verification_log = []
verification_log.append("VERIFICATION DE L'ALIGNEMENT SPATIAL\n")
verification_log.append("=" * 100)
verification_log.append(f"{'Fichier':<40} {'Resolution':<20} {'CRS':<25} {'Shape':<20}")
verification_log.append("=" * 100)

print(f"{'Fichier':<40} {'Resolution':<20} {'CRS':<25} {'Shape':<20}")
print("-" * 100)

for filepath in all_clipped:
    with rasterio.open(filepath) as src:
        res_x = abs(src.transform.a)
        res_y = abs(src.transform.e)
        unit = "m" if src.crs and src.crs.is_projected else "deg"
        prec = 2 if unit == "m" else 5
        res_str = f"{res_x:.{prec}f} x {res_y:.{prec}f} {unit}"

        crs = str(src.crs)[:22]
        shape = f"{src.width} x {src.height}"
        
        line = f"{filepath.name:<40} {res_str:<20} {crs:<25} {shape:<20}"
        print(line)
        verification_log.append(line)

verification_log.append("=" * 100)

log_path = OUTPUT_DIR / "logs" / "01_alignement_spatial.txt"
with open(log_path, "w", encoding="utf-8") as f:
    f.write("\n".join(verification_log))

print(f"\n[OK] Log sauvegarde: {log_path}")

# ===========================================================================
# 7. RESUME FINAL
# ===========================================================================

print("\n" + "=" * 80)
print("ETAPE 1 TERMINEE: PREPARATION SPATIALE")
print("=" * 80)
print("\nFICHIERS DE SORTIE:")
print("-" * 80)

output_files = list((OUTPUT_DIR / "01_preprocessed").glob("*.tif"))
for i, filepath in enumerate(sorted(output_files), 1):
    size_mb = filepath.stat().st_size / 1e6
    print(f"{i}. {filepath.name:<50} {size_mb:>8.2f} MB")

print("\n" + "=" * 80)
print("PROCHAINE ETAPE: Creation de la carte de base (forets + cultures)")
print("=" * 80)