# ==============================================================================
# advanced_viz.py
# Visualisations avancées - Population, infrastructures, statistiques départementales
# ==============================================================================

import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
import pandas as pd
import geopandas as gpd
import rasterio
from matplotlib.lines import Line2D
from mpl_toolkits.axes_grid1 import make_axes_locatable
import warnings
warnings.filterwarnings('ignore')

# Configuration
sns.set_style("whitegrid")
CRS_UTM31N = "EPSG:32631"

class AdvancedVisualizer:
    """Classe pour les visualisations avancées et thématiques"""
    
    def __init__(self, boundaries, output_dir="outputs/advanced"):
        """
        Parameters:
        -----------
        boundaries : GeoDataFrame
            Limites administratives
        output_dir : str
        """
        self.boundaries = boundaries
        self.output_dir = output_dir
        
        import os
        os.makedirs(output_dir, exist_ok=True)
    
    def plot_population_raster(self, raster_path, output_file=None):
        """
        Visualise le raster de population WorldPop
        
        Parameters:
        -----------
        raster_path : str or Path
        output_file : str, optional
        """
        print("\nGénération de la carte de population...")
        
        with rasterio.open(raster_path) as src:
            # Lire les données
            data = src.read(1)
            data = np.ma.masked_where(data <= 0, data)
            
            # Affichage
            fig, ax = plt.subplots(figsize=(12, 10))
            im = ax.imshow(data, cmap='plasma', origin='upper')
            
            # Colorbar
            cbar = plt.colorbar(im, ax=ax, shrink=0.8, pad=0.02)
            cbar.set_label("Population estimée par pixel (1 km × 1 km)", fontsize=12)
            
            ax.set_title("Population au Bénin (2024) – WorldPop", 
                        fontsize=16, fontweight='bold', pad=15)
            ax.set_xlabel("Colonne (pixels)", fontsize=11)
            ax.set_ylabel("Ligne (pixels)", fontsize=11)
            
            plt.tight_layout()
            
            if output_file:
                plt.savefig(output_file, dpi=300, bbox_inches='tight')
                print(f"  ✓ Carte de population → {output_file}")
            else:
                plt.show()
            
            plt.close()
    
    def plot_localities_map(self, places_gdf, output_file=None):
        """
        Carte des localités par type (villes, villages, hameaux)
        
        Parameters:
        -----------
        places_gdf : GeoDataFrame
        output_file : str, optional
        """
        print("\nGénération de la carte des localités...")
        
        # Filtrer par type
        town = places_gdf[places_gdf['fclass'] == 'town'] if 'fclass' in places_gdf.columns else gpd.GeoDataFrame()
        village = places_gdf[places_gdf['fclass'] == 'village'] if 'fclass' in places_gdf.columns else gpd.GeoDataFrame()
        hamlet = places_gdf[places_gdf['fclass'] == 'hamlet'] if 'fclass' in places_gdf.columns else gpd.GeoDataFrame()
        island = places_gdf[places_gdf['fclass'] == 'island'] if 'fclass' in places_gdf.columns else gpd.GeoDataFrame()
        
        fig, ax = plt.subplots(figsize=(13, 10))
        
        # Fond blanc
        fig.patch.set_facecolor('white')
        ax.set_facecolor('white')
        
        # Tracer les localités
        if not town.empty:
            town.plot(ax=ax, color='#d32f2f', marker='o', markersize=20, 
                     alpha=0.85, edgecolor='white', linewidth=0.2, 
                     zorder=4, label='Villes')
        
        if not village.empty:
            village.plot(ax=ax, color='#64b5f6', marker='o', markersize=10, 
                        alpha=0.85, zorder=1, label='Villages')
        
        if not hamlet.empty:
            hamlet.plot(ax=ax, color='#81c784', marker='o', markersize=6, 
                       alpha=0.85, zorder=2, label='Hameaux')
        
        if not island.empty:
            island.plot(ax=ax, color='#ffb74d', marker='D', markersize=50, 
                       alpha=0.85, zorder=3, label='Îles')
        
        # Frontière
        self.boundaries.boundary.plot(ax=ax, color='#424242', linewidth=1.2, zorder=4)
        
        # Style
        ax.set_title("Localités – Bénin", fontsize=15, weight='bold', 
                    pad=12, color='#333333')
        ax.set_xlabel("Longitude", fontsize=11, color='#555555')
        ax.set_ylabel("Latitude", fontsize=11, color='#555555')
        
        # Légende
        ax.legend(loc='upper left', bbox_to_anchor=(1.01, 1), fontsize=10,
                 frameon=True, fancybox=True, framealpha=0.9,
                 facecolor='white', edgecolor='#dddddd')
        
        plt.tight_layout()
        
        if output_file:
            plt.savefig(output_file, dpi=300, bbox_inches='tight')
            print(f"  ✓ Carte des localités → {output_file}")
        else:
            plt.show()
        
        plt.close()
    
    def plot_health_education_map(self, pois_gdf, output_file=None):
        """
        Carte des infrastructures de santé et d'éducation
        
        Parameters:
        -----------
        pois_gdf : GeoDataFrame
        output_file : str, optional
        """
        print("\nGénération de la carte santé/éducation...")
        
        # Extraire les infrastructures
        hospitals = pois_gdf[pois_gdf['fclass'] == 'hospital'] if 'fclass' in pois_gdf.columns else gpd.GeoDataFrame()
        clinics = pois_gdf[pois_gdf['fclass'] == 'clinic'] if 'fclass' in pois_gdf.columns else gpd.GeoDataFrame()
        pharmacies = pois_gdf[pois_gdf['fclass'] == 'pharmacy'] if 'fclass' in pois_gdf.columns else gpd.GeoDataFrame()
        schools = pois_gdf[pois_gdf['fclass'] == 'school'] if 'fclass' in pois_gdf.columns else gpd.GeoDataFrame()
        
        fig, ax = plt.subplots(figsize=(13, 10))
        ax.set_facecolor('#fafafa')
        
        # Tracer les infrastructures
        if not hospitals.empty:
            hospitals.plot(ax=ax, color='#d32f2f', marker='o', markersize=25, 
                          zorder=4, alpha=0.85, edgecolor='white', linewidth=0.8)
        
        if not clinics.empty:
            clinics.plot(ax=ax, color='#4caf50', marker='s', markersize=20, 
                        zorder=3, alpha=0.85, edgecolor='white', linewidth=0.6)
        
        if not pharmacies.empty:
            pharmacies.plot(ax=ax, color='#ffeb3b', marker='^', markersize=20, 
                           zorder=2, alpha=0.85, edgecolor='black', linewidth=0.6)
        
        if not schools.empty:
            schools.plot(ax=ax, color='#2196f3', marker='D', markersize=20, 
                        zorder=1, alpha=0.85, edgecolor='white', linewidth=0.6)
        
        # Frontière
        self.boundaries.boundary.plot(ax=ax, color='black', linewidth=1.8, zorder=2)
        
        # Légende personnalisée
        legend_elements = [
            Line2D([0], [0], marker='o', color='w', markerfacecolor='#d32f2f',
                   markersize=10, markeredgecolor='black', linewidth=0, label='Hôpitaux'),
            Line2D([0], [0], marker='s', color='w', markerfacecolor='#4caf50',
                   markersize=8, markeredgecolor='black', linewidth=0, label='Cliniques'),
            Line2D([0], [0], marker='^', color='w', markerfacecolor='#ffeb3b',
                   markersize=8, markeredgecolor='black', linewidth=0, label='Pharmacies'),
            Line2D([0], [0], marker='D', color='w', markerfacecolor='#2196f3',
                   markersize=8, markeredgecolor='black', linewidth=0, label='Écoles')
        ]
        
        legend = ax.legend(handles=legend_elements, loc='upper left', 
                          bbox_to_anchor=(1.02, 1), fontsize=11, 
                          title='LÉGENDE', title_fontsize=12,
                          frameon=True, fancybox=True, shadow=True, 
                          framealpha=0.95, edgecolor='#2c3e50', facecolor='white')
        
        legend.get_frame().set_linewidth(1.5)
        legend.get_title().set_fontweight('bold')
        
        # Style
        ax.set_title("Infrastructures sanitaires et écoles – Bénin",
                    fontsize=16, weight='bold', pad=20)
        ax.set_xlabel("Longitude", fontsize=12, labelpad=10)
        ax.set_ylabel("Latitude", fontsize=12, labelpad=10)
        ax.grid(True, alpha=0.2, linestyle='--', color='gray')
        
        plt.tight_layout()
        plt.subplots_adjust(right=0.85)
        
        if output_file:
            plt.savefig(output_file, dpi=300, bbox_inches='tight')
            print(f"  ✓ Carte santé/éducation → {output_file}")
        else:
            plt.show()
        
        plt.close()
    
    def plot_protected_areas_map(self, protected_gdf, output_file=None):
        """
        Carte des aires protégées avec noms
        
        Parameters:
        -----------
        protected_gdf : GeoDataFrame
        output_file : str, optional
        """
        print("\nGénération de la carte des aires protégées...")
        
        fig, ax = plt.subplots(figsize=(12, 10))
        
        # Aires protégées
        protected_gdf.plot(ax=ax, facecolor='lightgreen', edgecolor='darkgreen',
                          linewidth=0.7, alpha=0.7, label='Aires protégées')
        
        # Frontière
        self.boundaries.boundary.plot(ax=ax, color='black', linewidth=2,
                                     label='Frontière du Bénin')
        
        # Ajouter les noms
        for idx, row in protected_gdf.iterrows():
            if row.geometry is not None and not row.geometry.is_empty:
                centroid = row.geometry.centroid
                name = row.get('NAME', row.get('name', ''))
                
                ax.annotate(text=name, xy=(centroid.x, centroid.y),
                           xytext=(2, 2), textcoords="offset points",
                           fontsize=8, color='darkgreen',
                           weight='bold', alpha=1)
        
        # Style
        ax.set_title("Aires protégées – Bénin", fontsize=16, weight='bold')
        ax.set_xlabel("Longitude")
        ax.set_ylabel("Latitude")
        ax.legend(loc='upper right')
        
        plt.tight_layout()
        
        if output_file:
            plt.savefig(output_file, dpi=300, bbox_inches='tight')
            print(f"  ✓ Carte aires protégées → {output_file}")
        else:
            plt.show()
        
        plt.close()
    
    def plot_hydrography_map(self, water_gdf, waterways_gdf, output_file=None):
        """
        Carte de l'hydrographie (plans d'eau + cours d'eau)
        
        Parameters:
        -----------
        water_gdf : GeoDataFrame (plans d'eau)
        waterways_gdf : GeoDataFrame (rivières)
        output_file : str, optional
        """
        print("\nGénération de la carte hydrographique...")
        
        fig, ax = plt.subplots(figsize=(13, 10))
        ax.set_facecolor('#fafafa')
        
        # Plans d'eau
        if water_gdf is not None and not water_gdf.empty:
            water_gdf.plot(ax=ax, color='#e3f2fd', edgecolor='#bbdefb',
                          linewidth=0.3, alpha=0.9, zorder=1,
                          label='Plans d\'eau')
        
        # Cours d'eau
        if waterways_gdf is not None and not waterways_gdf.empty:
            waterways_gdf.plot(ax=ax, color='#0288d1', linewidth=1.1,
                              alpha=0.85, zorder=2,
                              label='Rivières & cours d\'eau')
        
        # Frontière
        self.boundaries.boundary.plot(ax=ax, color='black', linewidth=2,
                                     label='Frontière du Bénin')
        
        # Style
        ax.set_title("Hydrographie du Bénin", fontsize=16, weight='bold', pad=15)
        ax.set_xlabel("Longitude", fontsize=11)
        ax.set_ylabel("Latitude", fontsize=11)
        ax.legend(loc='upper left', bbox_to_anchor=(1.01, 1), fontsize=10)
        
        plt.tight_layout()
        
        if output_file:
            plt.savefig(output_file, dpi=300, bbox_inches='tight')
            print(f"  ✓ Carte hydrographique → {output_file}")
        else:
            plt.show()
        
        plt.close()
    
    def plot_transport_map(self, roads_gdf, railways_gdf, output_file=None):
        """
        Carte des infrastructures de transport
        
        Parameters:
        -----------
        roads_gdf : GeoDataFrame
        railways_gdf : GeoDataFrame
        output_file : str, optional
        """
        print("\nGénération de la carte des transports...")
        
        fig, ax = plt.subplots(figsize=(13, 10))
        ax.set_facecolor('#fafafa')
        
        # Routes par catégorie
        if roads_gdf is not None and not roads_gdf.empty and 'fclass' in roads_gdf.columns:
            # Principales
            main = roads_gdf[roads_gdf['fclass'].isin(['motorway', 'trunk', 'primary'])]
            if not main.empty:
                main.plot(ax=ax, color='#d32f2f', linewidth=1.6, alpha=0.9,
                         zorder=2, label='Routes principales')
            
            # Secondaires
            secondary = roads_gdf[roads_gdf['fclass'].isin(['secondary', 'tertiary'])]
            if not secondary.empty:
                secondary.plot(ax=ax, color='#f57c00', linewidth=1.0, alpha=0.8,
                              zorder=1, label='Routes secondaires')
            
            # Locales
            minor = roads_gdf[roads_gdf['fclass'].isin(['residential', 'track', 'path', 'footway'])]
            if not minor.empty:
                minor.plot(ax=ax, color='#5d4037', linewidth=0.5, alpha=0.6,
                          zorder=0, label='Pistes & chemins')
        
        # Voies ferrées
        if railways_gdf is not None and not railways_gdf.empty:
            railways_gdf.plot(ax=ax, color='#1a237e', linewidth=1.8,
                             alpha=0.9, zorder=3, label='Voies ferrées')
        
        # Frontière
        self.boundaries.boundary.plot(ax=ax, color='black', linewidth=2,
                                     label='Frontière du Bénin')
        
        # Style
        ax.set_title("Infrastructures de transport – Bénin",
                    fontsize=16, weight='bold', pad=15)
        ax.set_xlabel("Longitude", fontsize=11)
        ax.set_ylabel("Latitude", fontsize=11)
        ax.legend(loc='upper left', bbox_to_anchor=(1.01, 1), fontsize=10)
        
        plt.tight_layout()
        
        if output_file:
            plt.savefig(output_file, dpi=300, bbox_inches='tight')
            print(f"  ✓ Carte des transports → {output_file}")
        else:
            plt.show()
        
        plt.close()


def plot_choropleth_department(dept_stats, dept_col, value_col, output_file=None):
    """
    Carte choroplèthe par département avec valeurs et noms
    
    Parameters:
    -----------
    dept_stats : GeoDataFrame
        Statistiques par département
    dept_col : str
        Nom de la colonne contenant les noms de départements
    value_col : str
        Nom de la colonne à cartographier
    output_file : str, optional
    """
    print(f"\nGénération de la carte choroplèthe ({value_col})...")
    
    fig, ax = plt.subplots(figsize=(10, 10))
    fig.patch.set_facecolor("white")
    
    # Carte choroplèthe
    dept_stats.plot(column=value_col, cmap="OrRd", linewidth=0.8,
                    edgecolor="grey", legend=False, ax=ax)
    
    ax.set_title(f"Répartition de {value_col} par département\nRépublique du Bénin",
                fontsize=16, fontweight="bold", pad=15)
    ax.set_axis_off()
    
    # Colorbar
    divider = make_axes_locatable(ax)
    cax = divider.append_axes("right", size="4%", pad=0.5)
    dept_stats.plot(column=value_col, cmap="OrRd", legend=True, cax=cax, ax=ax)
    cax.set_ylabel(value_col.replace("_", " ").capitalize(), rotation=90, fontsize=12)
    
    # Labels
    for idx, row in dept_stats.iterrows():
        centroid = row.geometry.centroid
        dept_name = row[dept_col]
        val = row[value_col]
        
        # Nom
        ax.text(centroid.x, centroid.y + 0.1, dept_name,
               ha='center', fontsize=9, fontweight='bold', color='black')
        
        # Valeur
        ax.text(centroid.x, centroid.y - 0.1, str(val),
               ha='center', fontsize=9, color='black')
    
    # Source
    ax.text(0.01, 0.03, "Source : OSM + geoBoundaries",
           transform=fig.transFigure, fontsize=9, color="dimgray")
    
    plt.tight_layout()
    
    if output_file:
        plt.savefig(output_file, dpi=300, bbox_inches='tight')
        print(f"  ✓ Carte choroplèthe → {output_file}")
    else:
        plt.show()
    
    plt.close()


def plot_bar_department(dept_stats, dept_col, value_col, output_file=None, color="#33a02c"):
    """
    Diagramme en barres par département
    
    Parameters:
    -----------
    dept_stats : DataFrame or GeoDataFrame
    dept_col : str
    value_col : str
    output_file : str, optional
    color : str
    """
    print(f"\nGénération du graphique en barres ({value_col})...")
    
    df = dept_stats[[dept_col, value_col]].copy()
    
    fig, ax = plt.subplots(figsize=(10, 5))
    fig.patch.set_facecolor("white")
    
    bars = ax.bar(df[dept_col], df[value_col], color=color)
    
    ax.set_title(f"{value_col.replace('n_', '').replace('_', ' ').capitalize()} par département – Bénin",
                fontsize=14, fontweight="bold", pad=10)
    ax.set_xlabel("Département")
    ax.set_ylabel("Nombre")
    plt.xticks(rotation=45, ha="right")
    
    # Valeurs sur les barres
    max_val = df[value_col].max()
    for bar in bars:
        height = bar.get_height()
        ax.text(bar.get_x() + bar.get_width()/2, height + (0.02 * max_val),
               f"{int(height)}", ha="center", va="bottom", fontsize=9)
    
    plt.tight_layout()
    
    if output_file:
        plt.savefig(output_file, dpi=300, bbox_inches='tight')
        print(f"  ✓ Graphique en barres → {output_file}")
    else:
        plt.show()
    
    plt.close()


# ==============================================================================
# TEST DU MODULE
# ==============================================================================

if __name__ == "__main__":
    print("\n" + "="*70)
    print("TEST DU MODULE advanced_viz.py".center(70))
    print("="*70)
    print("\nCe module nécessite des données chargées pour fonctionner.")
    print("Utilisez-le depuis run_all.py ou un script personnalisé.")
    print("="*70)