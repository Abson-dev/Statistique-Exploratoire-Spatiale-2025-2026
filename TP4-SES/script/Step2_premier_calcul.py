# -*- coding: utf-8 -*-
import numpy as np
import rasterio
from pathlib import Path
from rasterio.warp import reproject, Resampling
import folium
from folium.raster_layers import ImageOverlay
from folium.raster_layers import ImageOverlay
from pyproj import Transformer

# Répertoires
BASE_DIR = Path(r"C:\Users\HP\Desktop\LESLYE\ISEP3\SES\TP4-SES")
DATA_DIR = BASE_DIR / "data"
OUTPUT_DIR = BASE_DIR / "output"
PREP = OUTPUT_DIR / "01_preprocessed"
MAPS = OUTPUT_DIR / "02_maps"
MAPS.mkdir(parents=True, exist_ok=True)

# Entrées
loss_path   = PREP / "forest_loss_ethiopia.tif"        # Hansen lossyear clippé
gfsad_path  = PREP / "cropland_ethiopia.tif"           # GFSAD clippé (EPSG:32637)

# Sorties
base_binary_tif   = MAPS / "base_potential_cultivable_binary.tif"
base_binary_html  = MAPS / "base_potential_cultivable_binary.html"

# Harmoniser: on prend la grille de cropland_ethiopia.tif comme référence
with rasterio.open(gfsad_path) as ref:
    ref_meta = ref.meta.copy()
    ref_arr = ref.read(1)
    ref_crs = ref.crs
    ref_transform = ref.transform
    ref_height, ref_width = ref.shape

# Charger/adapter loss (Hansen)
with rasterio.open(loss_path) as src_loss:
    loss_reproj = np.empty((ref_height, ref_width), dtype=src_loss.dtypes[0])
    reproject(
        source=rasterio.band(src_loss, 1),
        destination=loss_reproj,
        src_transform=src_loss.transform,
        src_crs=src_loss.crs,
        dst_transform=ref_transform,
        dst_crs=ref_crs,
        resampling=Resampling.nearest
    )

# Interprétation des couches:
gfsad_bin = (ref_arr > 0).astype(np.uint8)       # cultivé
loss_bin  = (loss_reproj > 0).astype(np.uint8)   # défriché

# Base: si (défriché OU cultivé) -> 1, sinon 0
base_bin = ((gfsad_bin == 1) | (loss_bin == 1)).astype(np.uint8)

# Écriture GeoTIFF
out_meta = ref_meta.copy()
out_meta.update({"count": 1, "dtype": "uint8", "compress": "lzw"})
with rasterio.open(base_binary_tif, "w", **out_meta) as dst:
    dst.write(base_bin, 1)

# Carte HTML (Leaflet via Folium)
with rasterio.open(base_binary_tif) as src:
    bounds = src.bounds

# Pour éviter la saturation mémoire, on réduit la taille avant overlay
step = 50  # garde 1 pixel sur 50
arr_small = base_bin[::step, ::step]

# Infos sur le raster réduit

print(f"Valeurs min/max du raster réduit : {np.nanmin(arr_small)} / {np.nanmax(arr_small)}")
print(f"Taille du raster réduit : {arr_small.shape}")
print(f"Bounds du raster : {bounds}")

if np.count_nonzero(arr_small) == 0:
    print(" Aucun pixel cultivable détecté dans la vignette — la carte sera vide.")
arr_small[0:10, 0:10] = 1  # juste pour test

 
# Sauvegarde temporaire pour overlay
import matplotlib.pyplot as plt
tmp_png = MAPS / "tmp_overlay.png"
plt.imsave(tmp_png, arr_small, cmap="YlGn", vmin=0, vmax=1)

# Reprojeter les bounds EPSG:32637 → EPSG:4326
transformer = Transformer.from_crs("EPSG:32637", "EPSG:4326", always_xy=True)
left, bottom = transformer.transform(bounds.left, bounds.bottom)
right, top = transformer.transform(bounds.right, bounds.top)

# Carte Folium
center_lat = (top + bottom) / 2
center_lon = (left + right) / 2
m = folium.Map(location=[center_lat, center_lon], zoom_start=6, tiles="CartoDB positron")

ImageOverlay(
    name="Terres potentiellement cultivables",
    image=str(tmp_png),
    bounds=[[bottom, left], [top, right]],
    opacity=0.9
).add_to(m)

folium.LayerControl().add_to(m)
m.save(str(base_binary_html))

# Nettoyage du PNG temporaire
tmp_png.unlink()


print ( #------ Grand commentaire: 
       
 """
On a une première estimation des zones agricoles possibles

Elle inclut les terres déjà utilisées + celles récemment ouvertes

Mais elle ne filtre pas encore les zones non exploitables (pentes, eau, villes, parcs…)

Ainsi, nous allons affiner la carte en éliminant les zones non cultivables ( eau, surfaces GMIS , WDPA )

""" 
) 