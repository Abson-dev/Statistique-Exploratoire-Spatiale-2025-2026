# ==============================================================================
# departmental_analysis.py
# Analyses statistiques par département
# ==============================================================================

import geopandas as gpd
import pandas as pd
import numpy as np
from shapely.ops import unary_union

class DepartmentalAnalyzer:
    """Classe pour les analyses statistiques par département"""
    
    def __init__(self, departments_gdf, dept_col='shapeName'):
        """
        Parameters:
        -----------
        departments_gdf : GeoDataFrame
            Limites des départements
        dept_col : str
            Nom de la colonne contenant les noms de départements
        """
        self.departments = departments_gdf.copy()
        self.dept_col = dept_col
        self.stats = self.departments[[dept_col, 'geometry']].copy()
        
        # Calculer les superficies
        dept_utm = self.departments.to_crs("EPSG:32631")
        self.stats['area_km2'] = dept_utm.geometry.area / 1e6
    
    def count_infrastructures_by_dept(self, infrastructure_gdf, infra_name):
        """
        Compte les infrastructures par département
        
        Parameters:
        -----------
        infrastructure_gdf : GeoDataFrame
        infra_name : str
            Nom pour la colonne (ex: 'n_hospitals')
            
        Returns:
        --------
        self (pour chaînage)
        """
        if infrastructure_gdf is None or len(infrastructure_gdf) == 0:
            self.stats[infra_name] = 0
            return self
        
        print(f"  Comptage : {infra_name}...")
        
        # Jointure spatiale
        joined = gpd.sjoin(
            infrastructure_gdf,
            self.departments[[self.dept_col, 'geometry']],
            how='left',
            predicate='within'
        )
        
        # Compter par département
        counts = joined.groupby(self.dept_col).size()
        
        # Intégrer dans stats
        self.stats[infra_name] = self.stats[self.dept_col].map(counts).fillna(0).astype(int)
        
        print(f"    ✓ Total : {self.stats[infra_name].sum()}")
        
        return self
    
    def compute_population_by_dept(self, pop_raster_path):
        """
        Calcule la population par département depuis un raster
        
        Parameters:
        -----------
        pop_raster_path : str or Path
            
        Returns:
        --------
        self
        """
        print(f"  Extraction population par département...")
        
        import rasterio
        from rasterio.mask import mask as rio_mask
        
        pop_by_dept = []
        
        with rasterio.open(pop_raster_path) as src:
            for idx, row in self.departments.iterrows():
                try:
                    # Extraire le raster pour ce département
                    out_image, out_transform = rio_mask(
                        src,
                        [row.geometry],
                        crop=True,
                        nodata=np.nan
                    )
                    
                    # Sommer la population
                    data = out_image[0]
                    data = data[data > 0]  # Ignorer les valeurs nulles/négatives
                    pop_total = np.sum(data) if len(data) > 0 else 0
                    
                    pop_by_dept.append(pop_total)
                    
                except Exception as e:
                    print(f"    ⚠ Erreur pour {row[self.dept_col]}: {e}")
                    pop_by_dept.append(0)
        
        self.stats['population'] = pop_by_dept
        print(f"    ✓ Population totale : {self.stats['population'].sum():,.0f}")
        
        return self
    
    def compute_protected_areas(self, protected_gdf):
        """
        Calcule la surface d'aires protégées par département
        
        Parameters:
        -----------
        protected_gdf : GeoDataFrame
            
        Returns:
        --------
        self
        """
        if protected_gdf is None or len(protected_gdf) == 0:
            self.stats['protected_km2'] = 0
            return self
        
        print(f"  Calcul des aires protégées par département...")
        
        # Reprojeter en métrique
        dept_utm = self.departments.to_crs("EPSG:32631")
        prot_utm = protected_gdf.to_crs("EPSG:32631")
        
        protected_areas = []
        
        for idx, row in dept_utm.iterrows():
            # Intersection
            intersect = prot_utm.intersection(row.geometry)
            intersect = [g for g in intersect if g and not g.is_empty]
            
            # Surface totale
            area = sum([g.area for g in intersect]) / 1e6
            protected_areas.append(area)
        
        self.stats['protected_km2'] = protected_areas
        print(f"    ✓ Surface protégée totale : {sum(protected_areas):.2f} km²")
        
        return self
    
    def compute_density(self, value_col, area_col='area_km2', result_col=None):
        """
        Calcule une densité (valeur / superficie)
        
        Parameters:
        -----------
        value_col : str
        area_col : str
        result_col : str, optional
            
        Returns:
        --------
        self
        """
        if result_col is None:
            result_col = f"{value_col}_per_km2"
        
        self.stats[result_col] = self.stats[value_col] / self.stats[area_col]
        
        return self
    
    def compute_ratio(self, numerator_col, denominator_col, result_col):
        """
        Calcule un ratio entre deux colonnes
        
        Parameters:
        -----------
        numerator_col : str
        denominator_col : str
        result_col : str
            
        Returns:
        --------
        self
        """
        self.stats[result_col] = (
            self.stats[numerator_col] / self.stats[denominator_col]
        ).replace([np.inf, -np.inf], np.nan)
        
        return self
    
    def export_stats(self, output_file):
        """
        Exporte les statistiques en CSV
        
        Parameters:
        -----------
        output_file : str
        """
        # Version sans géométrie
        df = self.stats.drop(columns='geometry') if 'geometry' in self.stats.columns else self.stats
        df.to_csv(output_file, index=False)
        print(f"  ✓ Statistiques exportées → {output_file}")
    
    def get_geodataframe(self):
        """Retourne les stats en tant que GeoDataFrame"""
        return gpd.GeoDataFrame(self.stats, geometry='geometry', crs=self.departments.crs)
    
    def summary(self):
        """Affiche un résumé des statistiques"""
        print("\n" + "="*70)
        print("RÉSUMÉ DES STATISTIQUES DÉPARTEMENTALES".center(70))
        print("="*70 + "\n")
        
        # Exclure les colonnes non numériques
        numeric_cols = self.stats.select_dtypes(include=[np.number]).columns
        
        print(f"Nombre de départements : {len(self.stats)}")
        print(f"\nSuperficie totale : {self.stats['area_km2'].sum():.2f} km²")
        
        if 'population' in self.stats.columns:
            print(f"Population totale : {self.stats['population'].sum():,.0f}")
        
        # Infrastructures
        infra_cols = [col for col in numeric_cols if col.startswith('n_')]
        if infra_cols:
            print(f"\nInfrastructures :")
            for col in infra_cols:
                total = self.stats[col].sum()
                mean = self.stats[col].mean()
                print(f"  • {col:20} : {int(total):6} total ({mean:.1f} par dépt)")
        
        # Top 3 départements par superficie
        print(f"\nTop 3 départements par superficie :")
        top_area = self.stats.nlargest(3, 'area_km2')
        for idx, row in top_area.iterrows():
            print(f"  {idx+1}. {row[self.dept_col]:20} : {row['area_km2']:8.2f} km²")
        
        # Top 3 départements par population (si disponible)
        if 'population' in self.stats.columns:
            print(f"\nTop 3 départements par population :")
            top_pop = self.stats.nlargest(3, 'population')
            for idx, row in top_pop.iterrows():
                print(f"  {idx+1}. {row[self.dept_col]:20} : {row['population']:10,.0f}")
        
        print("\n" + "="*70 + "\n")


# ==============================================================================
# TEST DU MODULE
# ==============================================================================

if __name__ == "__main__":
    print("\n" + "="*70)
    print("TEST DU MODULE departmental_analysis.py".center(70))
    print("="*70)
    print("\nCe module nécessite des données chargées pour fonctionner.")
    print("Utilisez-le depuis run_all.py ou un script personnalisé.")
    print("="*70)