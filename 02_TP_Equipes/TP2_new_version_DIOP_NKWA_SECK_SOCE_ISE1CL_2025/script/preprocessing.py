# ==============================================================================
# preprocessing.py
# Prétraitement et harmonisation des données géospatiales
# ==============================================================================

import geopandas as gpd
import numpy as np
from shapely.geometry import Point, box

class DataPreprocessor:
    """Classe pour le prétraitement des données géospatiales"""
    
    @staticmethod
    def harmonize_crs(gdf_list, target_crs="EPSG:4326"):
        """
        Harmonise le CRS de plusieurs GeoDataFrames
        
        Parameters:
        -----------
        gdf_list : list of GeoDataFrame
        target_crs : str
            
        Returns:
        --------
        list of GeoDataFrame
        """
        print(f"\n{'HARMONISATION DES CRS':^70}")
        print("-" * 70)
        
        harmonized = []
        for i, gdf in enumerate(gdf_list):
            if gdf is None:
                harmonized.append(None)
                continue
                
            if gdf.crs != target_crs:
                print(f"  [{i}] Reprojection : {gdf.crs} → {target_crs}")
                gdf = gdf.to_crs(target_crs)
            else:
                print(f"  [{i}] CRS déjà correct : {target_crs}")
            
            harmonized.append(gdf)
        
        print(f"✓ Harmonisation terminée\n")
        return harmonized
    
    @staticmethod
    def clean_geometries(gdf, verbose=True):
        """
        Nettoie les géométries invalides
        
        Parameters:
        -----------
        gdf : GeoDataFrame
        verbose : bool
            
        Returns:
        --------
        GeoDataFrame
        """
        if gdf is None or len(gdf) == 0:
            return gdf
        
        if verbose:
            print(f"\nNettoyage des géométries...")
        
        # Identifier les géométries invalides
        invalid = ~gdf.geometry.is_valid
        n_invalid = invalid.sum()
        
        if n_invalid > 0:
            if verbose:
                print(f"  ⚠ {n_invalid} géométries invalides détectées")
            
            # Tenter de corriger avec buffer(0)
            gdf.loc[invalid, 'geometry'] = gdf.loc[invalid, 'geometry'].buffer(0)
            
            # Vérifier à nouveau
            still_invalid = ~gdf.geometry.is_valid
            n_still_invalid = still_invalid.sum()
            
            if n_still_invalid > 0:
                if verbose:
                    print(f"  ⚠ {n_still_invalid} géométries toujours invalides - suppression")
                gdf = gdf[gdf.geometry.is_valid].copy()
            
            if verbose:
                print(f"  ✓ Géométries corrigées : {n_invalid - n_still_invalid}/{n_invalid}")
        else:
            if verbose:
                print(f"  ✓ Toutes les géométries sont valides")
        
        return gdf
    
    @staticmethod
    def filter_by_category(gdf, column, values, verbose=True):
        """
        Filtre un GeoDataFrame par catégorie
        
        Parameters:
        -----------
        gdf : GeoDataFrame
        column : str
            Nom de la colonne
        values : list
            Valeurs à conserver
        verbose : bool
            
        Returns:
        --------
        GeoDataFrame
        """
        if gdf is None or column not in gdf.columns:
            if verbose:
                print(f"  ⚠ Colonne '{column}' non trouvée")
            return gdf
        
        filtered = gdf[gdf[column].isin(values)].copy()
        
        if verbose:
            print(f"  Filtrage sur '{column}' : {len(gdf)} → {len(filtered)} entités")
        
        return filtered
    
    @staticmethod
    def extract_health_facilities(pois_gdf, verbose=True):
        """
        Extrait les infrastructures de santé depuis les POIs
        
        Parameters:
        -----------
        pois_gdf : GeoDataFrame
            Couche des points d'intérêt
        verbose : bool
            
        Returns:
        --------
        dict of GeoDataFrame
        """
        if pois_gdf is None or 'fclass' not in pois_gdf.columns:
            if verbose:
                print("  ⚠ Impossible d'extraire les infrastructures de santé")
            return {}
        
        if verbose:
            print(f"\n{'EXTRACTION DES INFRASTRUCTURES DE SANTÉ':^70}")
            print("-" * 70)
        
        health_types = {
            'hospitals': ['hospital'],
            'clinics': ['clinic', 'doctors'],
            'pharmacies': ['pharmacy']
        }
        
        health_facilities = {}
        for key, values in health_types.items():
            filtered = pois_gdf[pois_gdf['fclass'].isin(values)].copy()
            if len(filtered) > 0:
                health_facilities[key] = filtered
                if verbose:
                    print(f"  ✓ {key.capitalize():15} : {len(filtered):4} entités")
        
        if verbose:
            print()
        
        return health_facilities
    
    @staticmethod
    def extract_education(pois_gdf, verbose=True):
        """
        Extrait les infrastructures éducatives depuis les POIs
        
        Parameters:
        -----------
        pois_gdf : GeoDataFrame
        verbose : bool
            
        Returns:
        --------
        GeoDataFrame
        """
        if pois_gdf is None or 'fclass' not in pois_gdf.columns:
            if verbose:
                print("  ⚠ Impossible d'extraire les infrastructures éducatives")
            return None
        
        if verbose:
            print(f"\n{'EXTRACTION DES INFRASTRUCTURES ÉDUCATIVES':^70}")
            print("-" * 70)
        
        education_values = ['school', 'kindergarten', 'college', 'university']
        schools = pois_gdf[pois_gdf['fclass'].isin(education_values)].copy()
        
        if verbose:
            if len(schools) > 0:
                print(f"  ✓ Écoles : {len(schools)} entités")
                # Distribution par type
                print(f"\n  Distribution par type :")
                for edu_type in education_values:
                    count = len(schools[schools['fclass'] == edu_type])
                    if count > 0:
                        print(f"    - {edu_type:15} : {count:4}")
            else:
                print(f"  ⚠ Aucune infrastructure éducative trouvée")
            print()
        
        return schools if len(schools) > 0 else None
    
    @staticmethod
    def extract_localities(places_gdf, locality_types=None, verbose=True):
        """
        Extrait et filtre les localités
        
        Parameters:
        -----------
        places_gdf : GeoDataFrame
        locality_types : list, optional
            Types de localités à conserver (ex: ['city', 'town', 'village'])
        verbose : bool
            
        Returns:
        --------
        GeoDataFrame
        """
        if places_gdf is None:
            if verbose:
                print("  ⚠ Pas de données de localités")
            return None
        
        if verbose:
            print(f"\n{'EXTRACTION DES LOCALITÉS':^70}")
            print("-" * 70)
        
        # Si pas de filtre spécifié, prendre toutes les localités
        if locality_types is None:
            localities = places_gdf.copy()
        else:
            if 'fclass' not in places_gdf.columns:
                localities = places_gdf.copy()
            else:
                localities = places_gdf[places_gdf['fclass'].isin(locality_types)].copy()
        
        if verbose:
            print(f"  ✓ Localités extraites : {len(localities)}")
            
            # Distribution par type
            if 'fclass' in localities.columns:
                print(f"\n  Distribution par type :")
                type_counts = localities['fclass'].value_counts()
                for loc_type, count in type_counts.items():
                    print(f"    - {loc_type:15} : {count:4}")
            print()
        
        return localities
    
    @staticmethod
    def remove_duplicates(gdf, subset=None, verbose=True):
        """
        Supprime les entités dupliquées
        
        Parameters:
        -----------
        gdf : GeoDataFrame
        subset : list, optional
            Colonnes à utiliser pour détecter les doublons
        verbose : bool
            
        Returns:
        --------
        GeoDataFrame
        """
        if gdf is None or len(gdf) == 0:
            return gdf
        
        n_before = len(gdf)
        
        if subset:
            gdf = gdf.drop_duplicates(subset=subset).copy()
        else:
            # Suppression basée sur la géométrie
            gdf = gdf.drop_duplicates(subset=['geometry']).copy()
        
        n_removed = n_before - len(gdf)
        
        if verbose and n_removed > 0:
            print(f"  ✓ Doublons supprimés : {n_removed}")
        
        return gdf


# ==============================================================================
# EXEMPLE D'UTILISATION
# ==============================================================================

if __name__ == "__main__":
    from pathlib import Path
    import sys
    
    # Ajouter le répertoire parent au path pour importer data_loader
    sys.path.insert(0, str(Path(__file__).parent))
    
    try:
        from data_loader import DataLoader
    except ImportError:
        print("⚠ Impossible d'importer data_loader.py")
        print("  Assurez-vous que data_loader.py est dans le même répertoire")
        sys.exit(1)
    
    print("\n" + "="*70)
    print("TEST DU MODULE preprocessing.py".center(70))
    print("="*70 + "\n")
    
    # Charger des données
    loader = DataLoader(data_dir="data")
    preprocessor = DataPreprocessor()
    
    try:
        # Charger plusieurs couches
        boundaries = loader.load_boundaries(level=1)
        places = loader.load_osm_layer('places', geometry_type='free')
        pois = loader.load_osm_layer('pois', geometry_type='free')
        
        # Harmoniser les CRS
        [boundaries, places, pois] = preprocessor.harmonize_crs(
            [boundaries, places, pois],
            target_crs="EPSG:4326"
        )
        
        # Nettoyer les géométries
        places = preprocessor.clean_geometries(places)
        pois = preprocessor.clean_geometries(pois)
        
        # Extraire les infrastructures
        health = preprocessor.extract_health_facilities(pois)
        schools = preprocessor.extract_education(pois)
        localities = preprocessor.extract_localities(places)
        
        print("\n✓ Prétraitement réussi !")
        
    except Exception as e:
        print(f"\n⚠ Erreur : {e}")
        import traceback
        traceback.print_exc()
    
    print("\n" + "="*70)