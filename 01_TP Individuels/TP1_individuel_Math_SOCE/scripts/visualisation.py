# ==============================================================================
# SCRIPT DE VISUALISATION DES DONNÉES SPATIALES - OUGANDA
# Objectif : Générer toutes les cartes, histogrammes et analyses temporelles
# ==============================================================================
import os
import re
import warnings
from glob import glob
import numpy as np
import pandas as pd
import geopandas as gpd
import rasterio
from rasterio.mask import mask
import matplotlib.pyplot as plt
import seaborn as sns
import gc

# Désactiver les warnings
warnings.filterwarnings('ignore')

# -------------------------
# 0. PARAMÈTRES & CHEMINS
# -------------------------
print("=" * 80)
print("VISUALISATION DES DONNÉES SPATIALES - OUGANDA".center(80))
print("=" * 80)

out_dir = "outputs"
os.makedirs(f"{out_dir}/maps", exist_ok=True)
os.makedirs(f"{out_dir}/maps_labels", exist_ok=True)
os.makedirs(f"{out_dir}/histogrammes", exist_ok=True)
os.makedirs(f"{out_dir}/statistiques", exist_ok=True)

gadm_dir = "data/gadm41_UGA_shp"
rast_dir = "data/rasters"

print("\n✓ Dossiers de sortie créés")

# -------------------------
# 1. CHARGER LES SHAPEFILES
# -------------------------
print("\n" + "─" * 80)
print("Chargement des données administratives...")

shp0_path = os.path.join(gadm_dir, "gadm41_UGA_0.shp")
shp1_path = os.path.join(gadm_dir, "gadm41_UGA_1.shp")

gadm0 = gpd.read_file(shp0_path) if os.path.exists(shp0_path) else None
gadm1 = gpd.read_file(shp1_path) if os.path.exists(shp1_path) else None

if gadm0 is None or gadm1 is None:
    raise FileNotFoundError("Shapefiles GADM non trouvés. Vérifiez le chemin.")

print(f"✓ Niveau 0 (Pays) : {len(gadm0)} entité(s)")
print(f"✓ Niveau 1 (Régions) : {len(gadm1)} région(s)")

# -------------------------
# 2. LISTER LES RASTERS
# -------------------------
print("\n" + "─" * 80)
print("Indexation des rasters...")

raster_files = sorted(glob(os.path.join(rast_dir, "*.tif")) +
                      glob(os.path.join(rast_dir, "*.tiff")))

if len(raster_files) == 0:
    raise FileNotFoundError(f"Aucun raster trouvé dans {rast_dir}")

def extract_year(filename):
    nm = os.path.basename(filename)
    m = re.search(r"(\d{4})(?=\.(tif|tiff)$)", nm, flags=re.IGNORECASE)
    if m:
        return int(m.group(1))
    all4 = re.findall(r"\d{4}", nm)
    return int(all4[-1]) if all4 else None

years = [extract_year(f) for f in raster_files]

print(f"✓ {len(raster_files)} rasters détectés")
print(f"✓ Période : {min(years)} - {max(years)}")

# -------------------------
# 3. HARMONISER LES CRS
# -------------------------
print("\n" + "─" * 80)
print("Harmonisation des systèmes de coordonnées...")

with rasterio.open(raster_files[0]) as src:
    raster_crs = src.crs

if gadm0.crs != raster_crs:
    print(f"→ Reprojection : {gadm0.crs} → {raster_crs}")
    gadm0 = gadm0.to_crs(raster_crs)
    gadm1 = gadm1.to_crs(raster_crs)
else:
    print(f"✓ CRS cohérent : {raster_crs}")

# -------------------------
# 4. CALCUL DES STATISTIQUES GLOBALES
# -------------------------
print("\n" + "=" * 80)
print("CALCUL DES STATISTIQUES GLOBALES".center(80))
print("=" * 80)

stats_data = []
val_min_global = float('inf')
val_max_global = float('-inf')

for idx, (fichier, an) in enumerate(zip(raster_files, years)):
    print(f"  [{idx+1}/{len(years)}] Traitement {an}...", end="\r")
    
    with rasterio.open(fichier) as src:
        arr = src.read(1).astype(float)
        arr[arr == src.nodata] = np.nan
        
        stats_data.append({
            "annee": an,
            "moyenne": np.nanmean(arr),
            "min": np.nanmin(arr),
            "max": np.nanmax(arr),
            "mediane": np.nanmedian(arr),
            "ecart_type": np.nanstd(arr)
        })
        
        val_min_global = min(val_min_global, np.nanmin(arr))
        val_max_global = max(val_max_global, np.nanmax(arr))
        
        del arr
        gc.collect()

df_stats = pd.DataFrame(stats_data)
df_stats.to_csv(f"{out_dir}/statistiques/stats_globales.csv", index=False)

print(f"\n✓ Statistiques calculées")
print(f"✓ Range globale : [{val_min_global:.4f}, {val_max_global:.4f}]")

# -------------------------
# 5. GÉNÉRATION DES CARTES ET HISTOGRAMMES
# -------------------------
print("\n" + "=" * 80)
print("GÉNÉRATION DES CARTES ET HISTOGRAMMES".center(80))
print("=" * 80)

bounds = gadm0.total_bounds

for idx, (fichier, an) in enumerate(zip(raster_files, years)):
    print(f"\n→ Année {an} ({idx+1}/{len(years)})")
    
    # Ouvrir et masquer le raster
    with rasterio.open(fichier) as src:
        out_image, out_transform = mask(
            src, 
            gadm0.geometry, 
            crop=True,
            nodata=np.nan,
            filled=True
        )
        
        raster_masked = out_image[0].astype(float)
        raster_masked[raster_masked == src.nodata] = np.nan
        
        height, width = raster_masked.shape
        xs = np.arange(width) * out_transform.a + out_transform.c
        ys = np.arange(height) * out_transform.e + out_transform.f
        xb = np.concatenate([xs, [xs[-1] + out_transform.a]])
        yb = np.concatenate([ys, [ys[-1] + out_transform.e]])
    
    # ──────────────────────────────────────────────────────────────────
    # 5.1 CARTE SIMPLE (sans labels)
    # ──────────────────────────────────────────────────────────────────
    fig, ax = plt.subplots(figsize=(14, 10))
    
    pcm = ax.pcolormesh(
        xb, yb, raster_masked,
        cmap='plasma',
        vmin=val_min_global,
        vmax=val_max_global,
        shading='flat'
    )
    
    gadm1.boundary.plot(ax=ax, edgecolor="red", linewidth=1.2, alpha=0.8, zorder=3)
    gadm0.boundary.plot(ax=ax, edgecolor="darkred", linewidth=2.5, zorder=4)
    
    cbar = fig.colorbar(pcm, ax=ax, fraction=0.046, pad=0.04, extend='both')
    cbar.set_label('Incidence du paludisme', fontsize=11, fontweight='bold')
    cbar.ax.tick_params(labelsize=10)
    
    ax.set_title(f'Incidence du paludisme - {an}', fontsize=14, fontweight='bold', pad=15)
    ax.set_xlabel('Longitude', fontsize=11)
    ax.set_ylabel('Latitude', fontsize=11)
    ax.grid(True, linestyle='--', alpha=0.3)
    ax.set_xlim(bounds[0], bounds[2])
    ax.set_ylim(bounds[1], bounds[3])
    
    plt.savefig(f"{out_dir}/maps/carte_{an}.png", dpi=200, bbox_inches='tight', facecolor='white')
    plt.close()
    
    print(f"  ✓ Carte simple générée")
    
    # ──────────────────────────────────────────────────────────────────
    # 5.2 CARTE AVEC LABELS DES RÉGIONS
    # ──────────────────────────────────────────────────────────────────
    fig, ax = plt.subplots(figsize=(16, 14))
    
    pcm = ax.pcolormesh(xb, yb, raster_masked, cmap='plasma', vmin=val_min_global, vmax=val_max_global)
    
    gadm1.boundary.plot(ax=ax, edgecolor="white", linewidth=1.2, alpha=0.9, zorder=3)
    gadm0.boundary.plot(ax=ax, edgecolor="black", linewidth=2.5, zorder=4)
    
    # Ajouter les labels
    for _, row in gadm1.iterrows():
        centroid = row.geometry.centroid
        region_name = row.get('NAME_1', 'Région')
        
        ax.text(
            centroid.x, centroid.y, region_name,
            fontsize=7, fontweight='bold',
            ha='center', va='center',
            color='white',
            bbox=dict(boxstyle='round,pad=0.3', facecolor='black', alpha=0.7, edgecolor='none'),
            zorder=5
        )
    
    cbar = fig.colorbar(pcm, ax=ax, fraction=0.046, pad=0.04, extend='both')
    cbar.set_label('Incidence du paludisme', fontsize=12, fontweight='bold')
    
    ax.set_title(f'Incidence du paludisme par région - {an}', fontsize=16, fontweight='bold', pad=20)
    ax.set_xlabel('Longitude', fontsize=12)
    ax.set_ylabel('Latitude', fontsize=12)
    ax.grid(True, linestyle=':', alpha=0.3, color='white', linewidth=0.5)
    ax.set_xlim(bounds[0], bounds[2])
    ax.set_ylim(bounds[1], bounds[3])
    
    # Flèche Nord
    ax.annotate('N', xy=(0.95, 0.95), xytext=(0.95, 0.88),
                xycoords='axes fraction',
                fontsize=20, fontweight='bold', ha='center',
                arrowprops=dict(arrowstyle='->', lw=2, color='black'))
    
    plt.savefig(f"{out_dir}/maps_labels/carte_labels_{an}.png", dpi=200, bbox_inches='tight', facecolor='white')
    plt.close()
    
    print(f"  ✓ Carte avec labels générée")
    
    # ──────────────────────────────────────────────────────────────────
    # 5.3 HISTOGRAMME
    # ──────────────────────────────────────────────────────────────────
    vals = raster_masked[~np.isnan(raster_masked)]
    moyenne = np.mean(vals)
    mediane = np.median(vals)
    
    fig, ax = plt.subplots(figsize=(10, 6))
    
    ax.hist(vals, bins=40, color='#4B0082', edgecolor='black', alpha=0.7, linewidth=0.8)
    ax.axvline(moyenne, color='red', linestyle='--', linewidth=2.5, 
               label=f'Moyenne: {moyenne:.3f}', alpha=0.9)
    ax.axvline(mediane, color='orange', linestyle=':', linewidth=2.5, 
               label=f'Médiane: {mediane:.3f}', alpha=0.9)
    
    ax.set_title(f'Distribution de l\'incidence du paludisme - {an}', 
                 fontsize=13, fontweight='bold', pad=15)
    ax.set_xlabel('Incidence', fontsize=11)
    ax.set_ylabel('Fréquence', fontsize=11)
    ax.legend(fontsize=10, loc='upper right')
    ax.grid(True, axis='y', linestyle='--', alpha=0.3)
    
    plt.savefig(f"{out_dir}/histogrammes/hist_{an}.png", dpi=150, bbox_inches='tight')
    plt.close()
    
    print(f"  ✓ Histogramme généré")
    
    del raster_masked, vals
    gc.collect()

print("\n✓ Toutes les visualisations individuelles générées")

# -------------------------
# 6. COURBE TEMPORELLE
# -------------------------
print("\n" + "=" * 80)
print("GÉNÉRATION DES ANALYSES TEMPORELLES".center(80))
print("=" * 80)

# 6.1 Évolution temporelle avec range
fig, ax = plt.subplots(figsize=(12, 6))

ax.plot(df_stats['annee'], df_stats['moyenne'], marker='o', color='#4B0082', 
        linewidth=2.5, markersize=6, markerfacecolor='white', 
        markeredgewidth=2, markeredgecolor='#4B0082', label='Moyenne')

ax.fill_between(df_stats['annee'], df_stats['min'], df_stats['max'], 
                alpha=0.2, color='#4B0082', label='Range (min-max)')

ax.set_title('Évolution de l\'incidence moyenne du paludisme', 
             fontsize=14, fontweight='bold', pad=15)
ax.set_xlabel('Année', fontsize=11)
ax.set_ylabel('Incidence moyenne', fontsize=11)
ax.grid(True, linestyle='--', alpha=0.3)
ax.legend(fontsize=10)

plt.xticks(rotation=45)
plt.savefig(f"{out_dir}/statistiques/evolution_temporelle.png", dpi=200, bbox_inches='tight')
plt.close()

print("✓ Courbe temporelle générée")

# 6.2 Analyse de tendance (2 sous-graphiques)
fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(16, 6))

# Sous-graphique 1 : Statistiques temporelles
ax1.plot(df_stats['annee'], df_stats['moyenne'], 'o-', label='Moyenne', 
         linewidth=2, markersize=5)
ax1.plot(df_stats['annee'], df_stats['min'], 's--', label='Minimum', 
         linewidth=1.5, markersize=4, alpha=0.7)
ax1.plot(df_stats['annee'], df_stats['max'], '^--', label='Maximum', 
         linewidth=1.5, markersize=4, alpha=0.7)
ax1.set_title('Statistiques temporelles', fontsize=12, fontweight='bold')
ax1.set_xlabel('Année')
ax1.set_ylabel('Incidence')
ax1.legend()
ax1.grid(True, alpha=0.3)
plt.setp(ax1.xaxis.get_majorticklabels(), rotation=45)

# Sous-graphique 2 : Variation annuelle
variation = df_stats['moyenne'].diff()
couleurs = ['green' if x < 0 else 'red' for x in variation]
ax2.bar(df_stats['annee'][1:], variation[1:], color=couleurs, alpha=0.6, edgecolor='black')
ax2.axhline(0, color='black', linewidth=0.8, linestyle='-')
ax2.set_title('Variation annuelle de l\'incidence moyenne', fontsize=12, fontweight='bold')
ax2.set_xlabel('Année')
ax2.set_ylabel('Variation')
ax2.grid(True, alpha=0.3, axis='y')
plt.setp(ax2.xaxis.get_majorticklabels(), rotation=45)

plt.tight_layout()
plt.savefig(f"{out_dir}/statistiques/analyse_tendance.png", dpi=200, bbox_inches='tight')
plt.close()

print("✓ Analyse de tendance générée")

# 6.3 Boxplot par année
fig, ax = plt.subplots(figsize=(14, 6))

bp = ax.boxplot([df_stats['min'], df_stats['moyenne'], df_stats['max']], 
                 labels=['Minimum', 'Moyenne', 'Maximum'],
                 patch_artist=True, notch=True)

for patch in bp['boxes']:
    patch.set_facecolor('#4B0082')
    patch.set_alpha(0.5)

ax.set_title('Distribution des statistiques sur la période', 
             fontsize=14, fontweight='bold', pad=15)
ax.set_ylabel('Incidence', fontsize=11)
ax.grid(True, axis='y', linestyle='--', alpha=0.3)

plt.savefig(f"{out_dir}/statistiques/boxplot_stats.png", dpi=200, bbox_inches='tight')
plt.close()

print("✓ Boxplot généré")

# -------------------------
# 7. RÉSUMÉ FINAL
# -------------------------
print("\n" + "=" * 80)
print("VISUALISATION TERMINÉE".center(80))
print("=" * 80)

print(f"\n📁 Fichiers générés :")
print(f"   • {len(years)} cartes simples → {out_dir}/maps/")
print(f"   • {len(years)} cartes avec labels → {out_dir}/maps_labels/")
print(f"   • {len(years)} histogrammes → {out_dir}/histogrammes/")
print(f"   • Statistiques globales → {out_dir}/statistiques/stats_globales.csv")
print(f"   • Courbe temporelle → {out_dir}/statistiques/evolution_temporelle.png")
print(f"   • Analyse de tendance → {out_dir}/statistiques/analyse_tendance.png")
print(f"   • Boxplot → {out_dir}/statistiques/boxplot_stats.png")

print(f"\n📊 Résumé de l'analyse :")
print(f"   • Période : {min(years)} - {max(years)}")
print(f"   • Range d'incidence : {val_min_global:.4f} - {val_max_global:.4f}")
print(f"   • Incidence moyenne : {df_stats['moyenne'].mean():.4f}")
print(f"   • Incidence médiane : {df_stats['mediane'].mean():.4f}")
print(f"   • Écart-type temporel : {df_stats['moyenne'].std():.4f}")

pente = np.polyfit(range(len(df_stats)), df_stats['moyenne'], 1)[0]
tendance = "hausse" if pente > 0 else "baisse"
print(f"   • Tendance générale : {tendance} ({pente:.6f}/an)")

print("\n" + "=" * 80)
print("✓ Script terminé avec succès !".center(80))
print("=" * 80)