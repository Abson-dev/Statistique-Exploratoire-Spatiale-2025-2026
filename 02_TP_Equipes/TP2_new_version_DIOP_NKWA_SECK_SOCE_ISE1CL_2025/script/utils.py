# ==============================================================================
# utils.py
# Fonctions utilitaires pour les opérations spatiales
# ==============================================================================

import numpy as np
import geopandas as gpd
from shapely.geometry import Point
import warnings
warnings.filterwarnings('ignore')

def create_buffer(gdf, distance=100, crs="EPSG:4326", verbose=True):
    """
    Crée un buffer autour des géométries
    
    Parameters:
    -----------
    gdf : GeoDataFrame
    distance : float
        Distance en mètres
    crs : str
        CRS source (pour conversion)
    verbose : bool
        
    Returns:
    --------
    GeoDataFrame avec buffers
    """
    if gdf is None or len(gdf) == 0:
        if verbose:
            print("  ⚠ GeoDataFrame vide - impossible de créer un buffer")
        return None
    
    # Reprojeter en mètres pour buffer précis (UTM Zone 31N pour le Bénin)
    gdf_m = gdf.to_crs("EPSG:32631")
    gdf_m['geometry'] = gdf_m.geometry.buffer(distance)
    
    # Reprojeter vers CRS d'origine
    gdf_buffer = gdf_m.to_crs(crs)
    
    if verbose:
        print(f"  ✓ Buffer de {distance}m créé pour {len(gdf_buffer)} entités")
    
    return gdf_buffer


def calculate_distances(gdf_from, gdf_to, verbose=True):
    """
    Calcule les distances minimales entre deux GeoDataFrames
    
    Parameters:
    -----------
    gdf_from : GeoDataFrame
        Points de départ (ex: localités)
    gdf_to : GeoDataFrame
        Points d'arrivée (ex: infrastructures)
    verbose : bool
        
    Returns:
    --------
    numpy.ndarray
        Vecteur des distances minimales (en mètres)
    """
    if gdf_from is None or gdf_to is None:
        if verbose:
            print("  ⚠ GeoDataFrame(s) vide(s) - impossible de calculer les distances")
        return None
    
    if len(gdf_from) == 0 or len(gdf_to) == 0:
        if verbose:
            print("  ⚠ Aucune entité - distances non calculées")
        return np.array([])
    
    # Reprojeter en mètres
    gdf_from_m = gdf_from.to_crs("EPSG:32631")
    gdf_to_m = gdf_to.to_crs("EPSG:32631")
    
    distances = []
    for idx, geom_from in enumerate(gdf_from_m.geometry):
        # Calculer la distance à toutes les infrastructures
        dists = gdf_to_m.geometry.distance(geom_from)
        # Prendre la distance minimale
        min_dist = dists.min()
        distances.append(min_dist)
        
        # Afficher la progression pour les gros datasets
        if verbose and len(gdf_from_m) > 100 and (idx + 1) % 100 == 0:
            print(f"    Progression : {idx+1}/{len(gdf_from_m)}", end='\r')
    
    if verbose and len(gdf_from_m) > 100:
        print()  # Nouvelle ligne après la progression
    
    return np.array(distances)


def extract_raster_values(raster_src, gdf, band=1, verbose=True):
    """
    Extrait les valeurs d'un raster aux positions d'un GeoDataFrame
    
    Parameters:
    -----------
    raster_src : rasterio.DatasetReader
    gdf : GeoDataFrame
    band : int
        Numéro de bande à extraire
    verbose : bool
        
    Returns:
    --------
    numpy.ndarray
    """
    from rasterio.sample import sample_gen
    
    if gdf is None or len(gdf) == 0:
        if verbose:
            print("  ⚠ GeoDataFrame vide - extraction impossible")
        return None
    
    # Reprojeter vers le CRS du raster
    gdf_reproj = gdf.to_crs(raster_src.crs)
    
    # Extraire coordonnées des centroides
    coords = [(geom.centroid.x, geom.centroid.y) for geom in gdf_reproj.geometry]
    
    # Échantillonner le raster
    values = np.array([val[band-1] for val in sample_gen(raster_src, coords)])
    
    if verbose:
        n_valid = np.sum(~np.isnan(values))
        print(f"  ✓ Valeurs extraites : {n_valid}/{len(values)} valides")
    
    return values


def spatial_join_nearest(gdf_left, gdf_right, max_distance=None, verbose=True):
    """
    Jointure spatiale basée sur la proximité
    
    Parameters:
    -----------
    gdf_left : GeoDataFrame
        GeoDataFrame de gauche
    gdf_right : GeoDataFrame
        GeoDataFrame de droite
    max_distance : float, optional
        Distance maximale en mètres
    verbose : bool
        
    Returns:
    --------
    GeoDataFrame
    """
    if gdf_left is None or gdf_right is None:
        if verbose:
            print("  ⚠ GeoDataFrame(s) vide(s) - jointure impossible")
        return None
    
    # Reprojeter en mètres
    left_m = gdf_left.to_crs("EPSG:32631")
    right_m = gdf_right.to_crs("EPSG:32631")
    
    # Jointure spatiale
    joined = gpd.sjoin_nearest(
        left_m, 
        right_m, 
        how="left", 
        max_distance=max_distance,
        distance_col="distance_m"
    )
    
    # Reprojeter au CRS d'origine
    joined = joined.to_crs(gdf_left.crs)
    
    if verbose:
        n_matched = joined['distance_m'].notna().sum()
        print(f"  ✓ Jointure effectuée : {n_matched}/{len(gdf_left)} appariements")
    
    return joined


def calculate_area(gdf, unit='km2', verbose=True):
    """
    Calcule la superficie des géométries
    
    Parameters:
    -----------
    gdf : GeoDataFrame
    unit : str
        'km2', 'm2', ou 'ha'
    verbose : bool
        
    Returns:
    --------
    pandas.Series
    """
    if gdf is None or len(gdf) == 0:
        if verbose:
            print("  ⚠ GeoDataFrame vide - calcul impossible")
        return None
    
    # Reprojeter en mètres
    gdf_m = gdf.to_crs("EPSG:32631")
    
    # Calculer l'aire en m²
    areas = gdf_m.geometry.area
    
    # Convertir selon l'unité
    if unit == 'km2':
        areas = areas / 1_000_000
    elif unit == 'ha':
        areas = areas / 10_000
    
    if verbose:
        print(f"  ✓ Superficies calculées en {unit}")
        print(f"    - Totale : {areas.sum():.2f} {unit}")
        print(f"    - Moyenne : {areas.mean():.2f} {unit}")
    
    return areas


def calculate_length(gdf, unit='km', verbose=True):
    """
    Calcule la longueur des géométries linéaires
    
    Parameters:
    -----------
    gdf : GeoDataFrame
    unit : str
        'km' ou 'm'
    verbose : bool
        
    Returns:
    --------
    pandas.Series
    """
    if gdf is None or len(gdf) == 0:
        if verbose:
            print("  ⚠ GeoDataFrame vide - calcul impossible")
        return None
    
    # Reprojeter en mètres
    gdf_m = gdf.to_crs("EPSG:32631")
    
    # Calculer la longueur en m
    lengths = gdf_m.geometry.length
    
    # Convertir selon l'unité
    if unit == 'km':
        lengths = lengths / 1_000
    
    if verbose:
        print(f"  ✓ Longueurs calculées en {unit}")
        print(f"    - Totale : {lengths.sum():.2f} {unit}")
        print(f"    - Moyenne : {lengths.mean():.2f} {unit}")
    
    return lengths


def get_centroid_coordinates(gdf, verbose=True):
    """
    Extrait les coordonnées des centroides
    
    Parameters:
    -----------
    gdf : GeoDataFrame
    verbose : bool
        
    Returns:
    --------
    tuple of arrays (x, y)
    """
    if gdf is None or len(gdf) == 0:
        if verbose:
            print("  ⚠ GeoDataFrame vide")
        return None, None
    
    centroids = gdf.geometry.centroid
    x = centroids.x.values
    y = centroids.y.values
    
    if verbose:
        print(f"  ✓ Centroides extraits : {len(x)} points")
    
    return x, y


def clip_to_boundary(gdf, boundary_gdf, verbose=True):
    """
    Découpe un GeoDataFrame selon une frontière
    
    Parameters:
    -----------
    gdf : GeoDataFrame
        Données à découper
    boundary_gdf : GeoDataFrame
        Frontière de découpage
    verbose : bool
        
    Returns:
    --------
    GeoDataFrame
    """
    if gdf is None or boundary_gdf is None:
        if verbose:
            print("  ⚠ GeoDataFrame(s) vide(s) - découpage impossible")
        return None
    
    # S'assurer que les CRS correspondent
    if gdf.crs != boundary_gdf.crs:
        boundary_gdf = boundary_gdf.to_crs(gdf.crs)
    
    # Découper
    clipped = gpd.clip(gdf, boundary_gdf)
    
    if verbose:
        print(f"  ✓ Découpage effectué : {len(gdf)} → {len(clipped)} entités")
    
    return clipped


# ==============================================================================
# EXEMPLE D'UTILISATION
# ==============================================================================

if __name__ == "__main__":
    from pathlib import Path
    import sys
    
    # Ajouter le répertoire parent au path
    sys.path.insert(0, str(Path(__file__).parent))
    
    try:
        from data_loader import DataLoader
        from preprocessing import DataPreprocessor
    except ImportError:
        print("⚠ Impossible d'importer les modules nécessaires")
        print("  Assurez-vous que data_loader.py et preprocessing.py sont présents")
        sys.exit(1)
    
    print("\n" + "="*70)
    print("TEST DU MODULE utils.py".center(70))
    print("="*70 + "\n")
    
    # Charger des données
    loader = DataLoader(data_dir="data")
    preprocessor = DataPreprocessor()
    
    try:
        # Charger couches
        boundaries = loader.load_boundaries(level=1)
        places = loader.load_osm_layer('places', geometry_type='free')
        pois = loader.load_osm_layer('pois', geometry_type='free')
        
        # Harmoniser CRS
        [boundaries, places, pois] = preprocessor.harmonize_crs([boundaries, places, pois])
        
        # Nettoyer
        places = preprocessor.clean_geometries(places, verbose=False)
        pois = preprocessor.clean_geometries(pois, verbose=False)
        
        # Extraire infrastructures
        health = preprocessor.extract_health_facilities(pois, verbose=False)
        hospitals = health.get('hospitals')
        
        if hospitals is not None and places is not None:
            print("\n" + "-"*70)
            print("TEST DES FONCTIONS UTILITAIRES")
            print("-"*70 + "\n")
            
            # Test 1 : Créer un buffer
            print("1. Création de buffer...")
            buffer = create_buffer(hospitals, distance=100)
            
            # Test 2 : Calculer des distances
            print("\n2. Calcul des distances...")
            distances = calculate_distances(places[:10], hospitals)  # Limiter à 10 pour le test
            if distances is not None:
                print(f"   - Distance min : {distances.min():.0f} m")
                print(f"   - Distance max : {distances.max():.0f} m")
                print(f"   - Distance moy : {distances.mean():.0f} m")
            
            # Test 3 : Jointure spatiale
            print("\n3. Jointure spatiale...")
            joined = spatial_join_nearest(places[:10], hospitals)
            
            # Test 4 : Calcul de superficie
            print("\n4. Calcul de superficie...")
            areas = calculate_area(boundaries, unit='km2')
            
            # Test 5 : Centroides
            print("\n5. Extraction des centroides...")
            x, y = get_centroid_coordinates(places)
            
            print("\n✓ Tous les tests réussis !")
        else:
            print("\n⚠ Données insuffisantes pour les tests")
        
    except Exception as e:
        print(f"\n⚠ Erreur : {e}")
        import traceback
        traceback.print_exc()
    
    print("\n" + "="*70)