# ==============================================================================
# viz.py
# Visualisation cartographique et graphique
# ==============================================================================

import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
import pandas as pd
import geopandas as gpd
from matplotlib.patches import Patch
import warnings
warnings.filterwarnings('ignore')

# Configuration de seaborn
sns.set_style("whitegrid")

class InfrastructureVisualizer:
    """Classe pour la visualisation des résultats d'analyse"""
    
    def __init__(self, boundaries, analyzer_results):
        """
        Parameters:
        -----------
        boundaries : GeoDataFrame
            Limites administratives
        analyzer_results : dict
            Résultats de InfrastructureAnalyzer
        """
        self.boundaries = boundaries
        self.results = analyzer_results
    
    def plot_infrastructure_map(self, infra_name, output_file=None, figsize=(14, 10)):
        """
        Cartographie d'une infrastructure avec buffers et gradient de distance
        
        Parameters:
        -----------
        infra_name : str
        output_file : str, optional
        figsize : tuple
        """
        if infra_name not in self.results:
            print(f"⚠ Pas de résultats pour {infra_name}")
            return
        
        result = self.results[infra_name]
        localities = result['localities_with_distances']
        buffers = result['buffers']
        
        # Créer la figure
        fig, ax = plt.subplots(figsize=figsize)
        
        # Fond : limites administratives
        self.boundaries.boundary.plot(
            ax=ax,
            edgecolor='black',
            linewidth=1.5,
            zorder=1
        )
        
        # Buffers (zones de couverture)
        buffers.plot(
            ax=ax,
            color='lightblue',
            alpha=0.3,
            edgecolor='blue',
            linewidth=0.5,
            zorder=2
        )
        
        # Localités avec gradient de couleur selon distance
        localities.plot(
            ax=ax,
            column='distance_m',
            cmap='RdYlGn_r',  # Rouge = loin, Vert = proche
            markersize=30,
            legend=True,
            legend_kwds={
                'label': 'Distance à l\'infrastructure (m)',
                'shrink': 0.8,
                'orientation': 'horizontal',
                'pad': 0.05
            },
            zorder=3
        )
        
        # Mise en forme
        ax.set_title(
            f'Accessibilité aux {infra_name}',
            fontsize=16,
            fontweight='bold',
            pad=20
        )
        ax.set_xlabel('Longitude', fontsize=12)
        ax.set_ylabel('Latitude', fontsize=12)
        ax.grid(True, alpha=0.3, linestyle='--')
        
        # Légende personnalisée
        legend_elements = [
            Patch(facecolor='lightblue', edgecolor='blue', alpha=0.3,
                  label=f'Zone de couverture (100m)'),
            plt.Line2D([0], [0], marker='o', color='w', markerfacecolor='green',
                      markersize=8, label='Bien desservi (<1km)'),
            plt.Line2D([0], [0], marker='o', color='w', markerfacecolor='red',
                      markersize=8, label='Mal desservi (>5km)')
        ]
        ax.legend(handles=legend_elements, loc='upper right', fontsize=10)
        
        plt.tight_layout()
        
        if output_file:
            plt.savefig(output_file, dpi=300, bbox_inches='tight')
            print(f"  ✓ Carte sauvegardée → {output_file}")
        else:
            plt.show()
        
        plt.close()
    
    def plot_distance_distribution(self, infra_name, output_file=None, figsize=(12, 6)):
        """
        Histogramme de distribution des distances
        
        Parameters:
        -----------
        infra_name : str
        output_file : str, optional
        figsize : tuple
        """
        if infra_name not in self.results:
            print(f"⚠ Pas de résultats pour {infra_name}")
            return
        
        result = self.results[infra_name]
        distances = result['localities_with_distances']['distance_m']
        
        fig, ax = plt.subplots(figsize=figsize)
        
        # Histogramme
        n, bins, patches = ax.hist(
            distances / 1000,  # Convertir en km
            bins=30,
            color='#4B0082',
            edgecolor='black',
            alpha=0.7,
            linewidth=0.8
        )
        
        # Lignes de référence
        mean_dist = distances.mean() / 1000
        median_dist = distances.median() / 1000
        
        ax.axvline(
            mean_dist,
            color='red',
            linestyle='--',
            linewidth=2.5,
            label=f'Moyenne: {mean_dist:.2f} km',
            alpha=0.9
        )
        ax.axvline(
            median_dist,
            color='orange',
            linestyle='--',
            linewidth=2.5,
            label=f'Médiane: {median_dist:.2f} km',
            alpha=0.9
        )
        
        # Mise en forme
        ax.set_title(
            f'Distribution des distances aux {infra_name}',
            fontsize=14,
            fontweight='bold',
            pad=15
        )
        ax.set_xlabel('Distance (km)', fontsize=12)
        ax.set_ylabel('Nombre de localités', fontsize=12)
        ax.legend(fontsize=10, loc='upper right')
        ax.grid(True, axis='y', alpha=0.3)
        
        plt.tight_layout()
        
        if output_file:
            plt.savefig(output_file, dpi=300, bbox_inches='tight')
            print(f"  ✓ Histogramme sauvegardé → {output_file}")
        else:
            plt.show()
        
        plt.close()
    
    def plot_comparison_barplot(self, output_file=None, figsize=(16, 6)):
        """
        Graphique comparatif de toutes les infrastructures
        
        Parameters:
        -----------
        output_file : str, optional
        figsize : tuple
        """
        stats_list = [result['stats'] for result in self.results.values()]
        stats_df = pd.DataFrame(stats_list)
        
        fig, (ax1, ax2) = plt.subplots(1, 2, figsize=figsize)
        
        # Sous-graphique 1 : Pourcentage de couverture
        bars1 = ax1.barh(
            stats_df['infrastructure'],
            stats_df['pct_localities_served'],
            color='#4B0082',
            alpha=0.7,
            edgecolor='black'
        )
        ax1.set_xlabel('% de localités desservies (<100m)', fontsize=11)
        ax1.set_title('Taux de couverture par infrastructure', fontsize=13, fontweight='bold')
        ax1.grid(True, axis='x', alpha=0.3)
        
        # Ajouter les valeurs sur les barres
        for bar in bars1:
            width = bar.get_width()
            ax1.text(
                width + 1,
                bar.get_y() + bar.get_height() / 2,
                f'{width:.1f}%',
                ha='left',
                va='center',
                fontsize=9
            )
        
        # Sous-graphique 2 : Distance moyenne
        bars2 = ax2.barh(
            stats_df['infrastructure'],
            stats_df['distance_mean_m'] / 1000,  # Convertir en km
            color='#FF6347',
            alpha=0.7,
            edgecolor='black'
        )
        ax2.set_xlabel('Distance moyenne (km)', fontsize=11)
        ax2.set_title('Distance moyenne aux infrastructures', fontsize=13, fontweight='bold')
        ax2.grid(True, axis='x', alpha=0.3)
        
        # Ajouter les valeurs sur les barres
        for bar in bars2:
            width = bar.get_width()
            ax2.text(
                width + 0.1,
                bar.get_y() + bar.get_height() / 2,
                f'{width:.2f} km',
                ha='left',
                va='center',
                fontsize=9
            )
        
        plt.tight_layout()
        
        if output_file:
            plt.savefig(output_file, dpi=300, bbox_inches='tight')
            print(f"  ✓ Graphique comparatif sauvegardé → {output_file}")
        else:
            plt.show()
        
        plt.close()
    
    def plot_summary_dashboard(self, output_file=None, figsize=(18, 12)):
        """
        Tableau de bord résumant toutes les analyses
        
        Parameters:
        -----------
        output_file : str, optional
        figsize : tuple
        """
        n_infras = len(self.results)
        
        if n_infras == 0:
            print("⚠ Aucun résultat à afficher")
            return
        
        # Créer la grille de subplots
        nrows = (n_infras + 1) // 2
        fig, axes = plt.subplots(nrows, 2, figsize=figsize)
        axes = axes.flatten()
        
        for idx, (infra_name, result) in enumerate(self.results.items()):
            ax = axes[idx]
            distances = result['localities_with_distances']['distance_m'] / 1000
            
            # Boîte à moustaches + violin plot
            parts = ax.violinplot(
                [distances],
                positions=[0],
                showmeans=True,
                showmedians=True,
                widths=0.7
            )
            
            # Couleurs
            for pc in parts['bodies']:
                pc.set_facecolor('#4B0082')
                pc.set_alpha(0.6)
            
            # Statistiques textuelles
            stats = result['stats']
            textstr = f"""
Infrastructures: {stats['n_infrastructures']}
Couverture: {stats['pct_localities_served']:.1f}%
Dist. moy: {stats['distance_mean_m']/1000:.2f} km
Dist. max: {stats['distance_max_m']/1000:.2f} km
            """.strip()
            
            ax.text(
                0.95, 0.95,
                textstr,
                transform=ax.transAxes,
                fontsize=9,
                verticalalignment='top',
                horizontalalignment='right',
                bbox=dict(boxstyle='round', facecolor='wheat', alpha=0.5)
            )
            
            ax.set_title(infra_name, fontsize=12, fontweight='bold')
            ax.set_ylabel('Distance (km)', fontsize=10)
            ax.set_xticks([])
            ax.grid(True, alpha=0.3)
        
        # Masquer les axes inutilisés
        for idx in range(n_infras, len(axes)):
            axes[idx].axis('off')
        
        fig.suptitle(
            'Tableau de bord - Accessibilité aux infrastructures',
            fontsize=16,
            fontweight='bold',
            y=0.995
        )
        
        plt.tight_layout()
        
        if output_file:
            plt.savefig(output_file, dpi=300, bbox_inches='tight')
            print(f"  ✓ Tableau de bord sauvegardé → {output_file}")
        else:
            plt.show()
        
        plt.close()


# ==============================================================================
# EXEMPLE D'UTILISATION
# ==============================================================================

if __name__ == "__main__":
    from pathlib import Path
    import sys
    import os
    
    sys.path.insert(0, str(Path(__file__).parent))
    
    try:
        from data_loader import DataLoader
        from preprocessing import DataPreprocessor
        from analyses import InfrastructureAnalyzer
    except ImportError:
        print("⚠ Impossible d'importer les modules nécessaires")
        sys.exit(1)
    
    print("\n" + "="*70)
    print("TEST DU MODULE viz.py".center(70))
    print("="*70 + "\n")
    
    # Créer dossier de sortie
    os.makedirs("outputs/test_viz", exist_ok=True)
    
    # Charger et préparer les données
    loader = DataLoader(data_dir="data")
    preprocessor = DataPreprocessor()
    
    try:
        boundaries = loader.load_boundaries(level=1)
        places = loader.load_osm_layer('places', geometry_type='free')
        pois = loader.load_osm_layer('pois', geometry_type='free')
        
        [boundaries, places, pois] = preprocessor.harmonize_crs([boundaries, places, pois])
        places = preprocessor.clean_geometries(places, verbose=False)
        pois = preprocessor.clean_geometries(pois, verbose=False)
        
        health = preprocessor.extract_health_facilities(pois, verbose=False)
        schools = preprocessor.extract_education(pois, verbose=False)
        
        # Analyser
        analyzer = InfrastructureAnalyzer(boundaries, places)
        
        if 'hospitals' in health:
            analyzer.analyze_proximity(health['hospitals'], 'Hôpitaux')
        
        if schools is not None:
            analyzer.analyze_proximity(schools, 'Écoles')
        
        # Visualiser
        print("\n" + "-"*70)
        print("GÉNÉRATION DES VISUALISATIONS")
        print("-"*70 + "\n")
        
        visualizer = InfrastructureVisualizer(boundaries, analyzer.results)
        
        for infra_name in analyzer.results.keys():
            print(f"\nVisualisation : {infra_name}")
            
            # Carte
            visualizer.plot_infrastructure_map(
                infra_name,
                output_file=f"outputs/test_viz/carte_{infra_name.lower().replace(' ', '_')}.png"
            )
            
            # Histogramme
            visualizer.plot_distance_distribution(
                infra_name,
                output_file=f"outputs/test_viz/hist_{infra_name.lower().replace(' ', '_')}.png"
            )
        
        # Comparaison
        print(f"\nGénération du graphique comparatif...")
        visualizer.plot_comparison_barplot(
            output_file="outputs/test_viz/comparaison.png"
        )
        
        # Dashboard
        print(f"\nGénération du tableau de bord...")
        visualizer.plot_summary_dashboard(
            output_file="outputs/test_viz/dashboard.png"
        )
        
        print("\n✓ Visualisations terminées avec succès !")
        print(f"  Fichiers dans : outputs/test_viz/")
        
    except Exception as e:
        print(f"\n⚠ Erreur : {e}")
        import traceback
        traceback.print_exc()
    
    print("\n" + "="*70)