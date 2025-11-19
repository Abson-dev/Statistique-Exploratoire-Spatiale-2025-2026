#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Generate per-year malaria indicator maps for Chad (adm1) from 2000 to 2021,
and composite PNGs (3 indicators horizontally) using local GADM shapefile and
MalariaAtlas subnational TSV (tab-separated) data.
[...truncated in this comment: full code is below in this variable...]
"""
import os, unicodedata, math, zipfile
import numpy as np, pandas as pd, fiona
from shapely.geometry import shape
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.colors import Normalize
from matplotlib.cm import get_cmap
from PIL import Image

BASE = "../data"
SHAPEFILE = os.path.join(BASE, "gadm41_TCD_1.shp")
CSV_PATH  = os.path.join(BASE, "Subnational Unit-data.csv")
OUT_DIR_INDIV = os.path.join(BASE, "TCD_Maps_2000_2021_indiv")
OUT_DIR_COMP  = os.path.join(BASE, "TCD_Maps_2000_2021_composite_png")
ZIP_COMP_PATH = os.path.join(BASE, "TCD_Maps_2000_2021_composite_png.zip")
YEARS = list(range(2000, 2022))
METRICS = ["Incidence Rate", "Infection Prevalence", "Mortality Rate"]

def normalize_key(s):
    if s is None:
        return None
    s = unicodedata.normalize("NFKD", str(s))
    s = "".join(ch for ch in s if not unicodedata.combining(ch))
    return (s.lower().replace("-", " ").replace("’", "'").strip())

def read_gadm_polys(shp_path):
    regions = []
    with fiona.open(shp_path) as src:
        for feat in src:
            props = feat["properties"]
            geom  = shape(feat["geometry"])
            name1 = props.get("NAME_1")
            key   = normalize_key(name1)
            parts = []
            if geom.geom_type == "Polygon":
                parts.append(np.asarray(geom.exterior.coords))
            else:
                for poly in geom:
                    parts.append(np.asarray(poly.exterior.coords))
            regions.append({"name": name1, "key": key, "parts": parts, "bounds": geom.bounds})
    return regions

def load_malaria_tcd(csv_path):
    df = pd.read_csv(csv_path, sep="\t")
    df.columns = [c.strip().lower().replace(" ", "_") for c in df.columns]
    df = df[df["iso3"]=="TCD"].copy()
    df["adm1_name"] = df["name"]
    df["key"] = df["adm1_name"].apply(normalize_key)
    df = df[["adm1_name","key","metric","units","year","value"]]
    df = df[(df["year"]>=2000) & (df["year"]<=2021)].copy()
    return df

def compute_global_ranges(df, metrics):
    mm = {}
    for met in metrics:
        vals = df[df["metric"]==met]["value"].dropna().values
        if vals.size == 0:
            mm[met] = (0.0, 1.0)
        else:
            vmin = float(np.nanpercentile(vals, 2))
            vmax = float(np.nanpercentile(vals, 98))
            if vmin == vmax:
                vmax = vmin + 1.0
            mm[met] = (vmin, vmax)
    return mm

def draw_metric_map(regions, bbox, df, mm, metric, year, save_path, dpi=120):
    minx, miny, maxx, maxy = bbox
    sub = df[(df["year"]==year) & (df["metric"]==metric)]
    value_by_key = dict(zip(sub["key"], sub["value"]))
    vmin, vmax = mm[metric]
    norm = Normalize(vmin=vmin, vmax=vmax)
    cmap = get_cmap(None)
    fig, ax = plt.subplots(figsize=(3.8, 4.4))
    ax.set_aspect('equal'); ax.set_xlim(minx, maxx); ax.set_ylim(miny, maxy)
    for r in regions:
        val = value_by_key.get(r["key"], np.nan)
        facecolor = cmap(norm(val)) if (isinstance(val, (int,float)) and not math.isnan(val)) else (0.9,0.9,0.9,1.0)
        for pts in r["parts"]:
            ax.fill(pts[:,0], pts[:,1], facecolor=facecolor, edgecolor='black', linewidth=0.3)
    sm = plt.cm.ScalarMappable(cmap=cmap, norm=norm); sm.set_array([])
    cbar = plt.colorbar(sm, ax=ax, fraction=0.035, pad=0.015)
    unit_vals = sub['units'].dropna().unique(); unit_lbl = unit_vals[0] if len(unit_vals) else ''
    cbar.set_label(f"{metric} ({unit_lbl})", fontsize=8)
    ax.set_title(f"Tchad — {metric} — {year}", fontsize=10); ax.axis('off'); plt.tight_layout()
    fig.savefig(save_path, dpi=dpi); plt.close(fig)

def stitch_year_horizontal(images_paths, out_path_png):
    imgs = [Image.open(p).convert("RGB") for p in images_paths]
    widths, heights = zip(*(im.size for im in imgs))
    total_width = sum(widths); max_height = max(heights)
    from PIL import Image as _Image
    composite = _Image.new('RGB', (total_width, max_height), (255,255,255))
    xoff = 0
    for im in imgs:
        composite.paste(im, (xoff, 0)); xoff += im.size[0]
    composite.save(out_path_png, format="PNG", optimize=True)

def main():
    os.makedirs(OUT_DIR_INDIV, exist_ok=True); os.makedirs(OUT_DIR_COMP, exist_ok=True)
    regions = read_gadm_polys(SHAPEFILE)
    all_bounds = [r["bounds"] for r in regions]
    bbox = (min(b[0] for b in all_bounds), min(b[1] for b in all_bounds),
            max(b[2] for b in all_bounds), max(b[3] for b in all_bounds))
    df = load_malaria_tcd(CSV_PATH)
    mm = compute_global_ranges(df, METRICS)
    for yr in YEARS:
        per_metric_paths = []
        for met in METRICS:
            out_jpg = os.path.join(OUT_DIR_INDIV, f"TCD_{yr}_{met.replace(' ','_')}.jpg")
            draw_metric_map(regions, bbox, df, mm, met, yr, out_jpg, dpi=120)
            per_metric_paths.append(out_jpg)
        out_png = os.path.join(OUT_DIR_COMP, f"TCD_{yr}_three_indicators.png")
        stitch_year_horizontal(per_metric_paths, out_png)
        print(f"[OK] Year {yr}: {out_png}")
    with zipfile.ZipFile(ZIP_COMP_PATH, 'w', zipfile.ZIP_DEFLATED) as zf:
        for root, _, files in os.walk(OUT_DIR_COMP):
            for f in files:
                fp = os.path.join(root, f)
                arc = os.path.relpath(fp, start=OUT_DIR_COMP)
                zf.write(fp, arcname=os.path.join("TCD_Maps_2000_2021_composite_png", arc))
    print("Done:", ZIP_COMP_PATH)

if __name__ == "__main__":
    main()
