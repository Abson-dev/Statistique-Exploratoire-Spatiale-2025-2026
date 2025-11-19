# ==============================================================================
# analyses.py
# Analyses spatiales des infrastructures
# ==============================================================================

import geopandas as gpd
import numpy as np
import pandas as pd
import os

# Import des fonctions utilitaires
try:
    from utils import create_buffer, calculate_distances, spatial_join_nearest
except ImportError:
    print("⚠ Impossible d'importer utils.py - Assurez-vous qu'il est dans le même répertoire")

class InfrastructureAnalyzer:
    """Classe pour l'analyse de proximité aux infrastructures"""
    
    def __init__(self, boundaries, localities):
        """
        Parameters:
        -----------
        boundaries : GeoDataFrame
            Limites administratives
        localities : GeoDataFrame
            Localités (villes, villages)
        """
        self.boundaries = boundaries
        self.localities = localities
        self.results = {}
    
    def analyze_proximity(self, infrastructure_gdf, infra_name, buffer_distance=100):
        """
        Analyse la proximité entre localités et infrastructure
        
        Parameters:
        -----------
        infrastructure_gdf : GeoDataFrame
            Couche d'infrastructure
        infra_name : str
            Nom de l'infrastructure
        buffer_distance : float
            Distance du buffer en mètres
            
        Returns:
        --------
        dict
            Résultats de l'analyse
        """
        if infrastructure_gdf is None or len(infrastructure_gdf) == 0:
            print(f"⚠ Pas de données pour {infra_name}")
            return None
        
        print(f"\n{'='*70}")
        print(f"ANALYSE : {infra_name.upper()}".center(70))
        print(f"{'='*70}")
        
        # 1. Créer les buffers
        print(f"\n1. Création des buffers ({buffer_distance}m)...")
        buffers = create_buffer(infrastructure_gdf, distance=buffer_distance, verbose=False)
        
        # 2. Intersection avec les localités
        print(f"2. Intersection spatiale...")
        localities_in_buffer = gpd.overlay(
            self.localities,
            buffers,
            how='intersection',
            keep_geom_type=False
        )
        
        n_localities_served = len(localities_in_buffer)
        pct_served = (n_localities_served / len(self.localities)) * 100
        print(f"   ✓ Localités dans buffer : {n_localities_served}/{len(self.localities)} ({pct_served:.1f}%)")
        
        # 3. Calculer les distances minimales
        print(f"3. Calcul des distances...")
        distances = calculate_distances(self.localities, infrastructure_gdf, verbose=False)
        
        # 4. Jointure pour identifier la plus proche infrastructure
        print(f"4. Jointure spatiale...")
        joined = spatial_join_nearest(self.localities, infrastructure_gdf, verbose=False)
        
        # Ajouter la colonne de distance si elle n'existe pas
        if 'distance_m' not in joined.columns:
            joined['distance_m'] = distances
        
        # 5. Statistiques
        stats = {
            'infrastructure': infra_name,
            'n_infrastructures': len(infrastructure_gdf),
            'n_localities_total': len(self.localities),
            'n_localities_in_buffer': n_localities_served,
            'pct_localities_served': round(pct_served, 2),
            'distance_mean_m': round(distances.mean(), 2),
            'distance_median_m': round(np.median(distances), 2),
            'distance_min_m': round(distances.min(), 2),
            'distance_max_m': round(distances.max(), 2),
            'distance_std_m': round(distances.std(), 2)
        }
        
        # 6. Stocker les résultats
        result = {
            'stats': stats,
            'buffers': buffers,
            'localities_served': localities_in_buffer,
            'localities_with_distances': joined
        }
        
        self.results[infra_name] = result
        
        # Afficher résumé
        print(f"\n{'RÉSULTATS':^70}")
        print(f"{'-'*70}")
        print(f"  • Nombre d'infrastructures : {stats['n_infrastructures']}")
        print(f"  • Localités dans buffer : {n_localities_served}/{len(self.localities)} ({pct_served:.1f}%)")
        print(f"  • Distance moyenne : {stats['distance_mean_m']:.0f} m")
        print(f"  • Distance médiane : {stats['distance_median_m']:.0f} m")
        print(f"  • Distance max : {stats['distance_max_m']:.0f} m")
        print(f"{'='*70}\n")
        
        return result
    
    def identify_underserved_areas(self, threshold_distance=5000):
        """
        Identifie les zones sous-desservies
        
        Parameters:
        -----------
        threshold_distance : float
            Distance seuil en mètres
            
        Returns:
        --------
        dict of GeoDataFrame
            Localités sous-desservies par infrastructure
        """
        print(f"\n{'IDENTIFICATION DES ZONES SOUS-DESSERVIES':^70}")
        print(f"{'-'*70}")
        print(f"Seuil : {threshold_distance}m\n")
        
        underserved = {}
        
        for infra_name, result in self.results.items():
            localities = result['localities_with_distances']
            underserved_localities = localities[localities['distance_m'] > threshold_distance]
            
            n_underserved = len(underserved_localities)
            pct_underserved = (n_underserved / len(localities)) * 100
            
            underserved[infra_name] = underserved_localities
            
            print(f"{infra_name.upper()}")
            print(f"  • Localités > {threshold_distance}m : {n_underserved} ({pct_underserved:.1f}%)")
            
            if n_underserved > 0:
                top5 = underserved_localities.nlargest(5, 'distance_m')
                print(f"  • Top 5 plus éloignées :")
                for idx, row in top5.iterrows():
                    name = row.get('name', 'Inconnu')
                    dist = row['distance_m']
                    print(f"      - {name:30} : {dist:>8.0f} m")
            print()
        
        print(f"{'='*70}\n")
        return underserved
    
    def export_results(self, output_dir="outputs/analyses"):
        """
        Export les résultats en CSV et shapefile
        
        Parameters:
        -----------
        output_dir : str
        """
        os.makedirs(output_dir, exist_ok=True)
        
        print(f"\n{'EXPORT DES RÉSULTATS':^70}")
        print(f"{'-'*70}")
        
        # Export statistiques globales
        stats_list = [result['stats'] for result in self.results.values()]
        stats_df = pd.DataFrame(stats_list)
        stats_csv = f"{output_dir}/statistiques_infrastructures.csv"
        stats_df.to_csv(stats_csv, index=False)
        print(f"  ✓ Statistiques → {stats_csv}")
        
        # Export localités avec distances
        for infra_name, result in self.results.items():
            localities = result['localities_with_distances']
            
            # Nettoyer le nom pour les fichiers
            clean_name = infra_name.lower().replace(' ', '_').replace('é', 'e').replace('è', 'e')
            
            # CSV
            csv_file = f"{output_dir}/distances_{clean_name}.csv"
            localities.drop(columns='geometry').to_csv(csv_file, index=False)
            
            # Shapefile
            shp_file = f"{output_dir}/distances_{clean_name}.shp"
            localities.to_file(shp_file)
            
            print(f"  ✓ {infra_name:20} → CSV + SHP")
        
        print(f"{'='*70}\n")


# ==============================================================================
# EXEMPLE D'UTILISATION
# ==============================================================================

if __name__ == "__main__":
    from pathlib import Path
    import sys
    
    sys.path.insert(0, str(Path(__file__).parent))
    
    try:
        from data_loader import DataLoader
        from preprocessing import DataPreprocessor
    except ImportError:
        print("⚠ Impossible d'importer les modules nécessaires")
        sys.exit(1)
    
    print("\n" + "="*70)
    print("TEST DU MODULE analyses.py".center(70))
    print("="*70 + "\n")
    
    # Charger des données
    loader = DataLoader(data_dir="data")
    preprocessor = DataPreprocessor()
    
    try:
        # Charger couches
        boundaries = loader.load_boundaries(level=1)
        places = loader.load_osm_layer('places', geometry_type='free')
        pois = loader.load_osm_layer('pois', geometry_type='free')
        
        # Prétraiter
        [boundaries, places, pois] = preprocessor.harmonize_crs([boundaries, places, pois])
        places = preprocessor.clean_geometries(places, verbose=False)
        pois = preprocessor.clean_geometries(pois, verbose=False)
        
        # Extraire infrastructures
        health = preprocessor.extract_health_facilities(pois, verbose=False)
        schools = preprocessor.extract_education(pois, verbose=False)
        
        # Analyser
        analyzer = InfrastructureAnalyzer(boundaries, places)
        
        if 'hospitals' in health:
            analyzer.analyze_proximity(health['hospitals'], 'Hôpitaux', buffer_distance=100)
        
        if schools is not None:
            analyzer.analyze_proximity(schools, 'Écoles', buffer_distance=100)
        
        # Identifier zones sous-desservies
        underserved = analyzer.identify_underserved_areas(threshold_distance=5000)
        
        # Exporter
        analyzer.export_results(output_dir="outputs/analyses")
        
        print("\n✓ Analyse terminée avec succès !")
        
    except Exception as e:
        print(f"\n⚠ Erreur : {e}")
        import traceback
        traceback.print_exc()
    
    print("\n" + "="*70)