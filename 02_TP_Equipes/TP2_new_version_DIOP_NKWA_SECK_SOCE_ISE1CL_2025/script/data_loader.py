# ==============================================================================
# data_loader.py
# Chargement et validation des données géospatiales
# ==============================================================================

import os
import geopandas as gpd
import rasterio
from pathlib import Path
import warnings
warnings.filterwarnings('ignore')

class DataLoader:
    """Classe pour charger et valider les données OSM et population"""
    
    def __init__(self, data_dir="data"):
        # Obtenir le chemin absolu du répertoire de données
        script_dir = Path(__file__).parent
        project_dir = script_dir.parent
        self.data_dir = project_dir / data_dir
        
        self.shp_dir = self.data_dir / "shapefiles"
        self.tif_dir = self.data_dir / "tif_geojson"
        
        print(f"Répertoire de données : {self.data_dir}")
        
    def load_boundaries(self, level=0):
        """
        Charge les limites administratives du Bénin
        
        Parameters:
        -----------
        level : int (0, 1, ou 2)
            Niveau administratif à charger
            
        Returns:
        --------
        geopandas.GeoDataFrame
        """
        file_path = self.tif_dir / f"geoBoundaries-BEN-ADM{level}.geojson"
        
        if not file_path.exists():
            raise FileNotFoundError(f"Fichier non trouvé : {file_path}")
            
        gdf = gpd.read_file(file_path)
        print(f"✓ Limites ADM{level} chargées : {len(gdf)} entités")
        return gdf
    
    def load_osm_layer(self, category, geometry_type='free'):
        """
        Charge une couche OSM
        
        Parameters:
        -----------
        category : str
            Type de couche (ex: 'roads', 'buildings', 'waterways', etc.)
        geometry_type : str
            'free' (points/lignes) ou 'polygon' (polygones)
            
        Returns:
        --------
        geopandas.GeoDataFrame or None
        """
        suffix = '_a_free_1' if geometry_type == 'polygon' else '_free_1'
        file_path = self.shp_dir / f"gis_osm_{category}{suffix}.shp"
        
        if not file_path.exists():
            print(f"⚠ Fichier non trouvé : {file_path}")
            return None
            
        try:
            gdf = gpd.read_file(file_path)
            print(f"✓ Couche {category} chargée : {len(gdf)} entités")
            return gdf
        except Exception as e:
            print(f"⚠ Erreur lors du chargement de {category} : {e}")
            return None
    
    def load_population_raster(self, resolution='1km'):
        """
        Charge le raster de population
        
        Parameters:
        -----------
        resolution : str
            '1km' ou '100m'
            
        Returns:
        --------
        rasterio.DatasetReader or None
        """
        res = '1km' if resolution == '1km' else '100m'
        
        if res == '1km':
            file_path = self.tif_dir / f"ben_pop_2024_CN_{res}_R2025A_UA_v1.tif"
        else:
            file_path = self.tif_dir / f"ben_pop_2024_CN_{res}_R2025A_v1.tif"
        
        if not file_path.exists():
            print(f"⚠ Raster non trouvé : {file_path}")
            return None
            
        try:
            src = rasterio.open(file_path)
            print(f"✓ Raster population {resolution} chargé : {src.width}x{src.height}")
            return src
        except Exception as e:
            print(f"⚠ Erreur lors du chargement du raster : {e}")
            return None
    
    def load_protected_areas(self):
        """Charge la couche des zones protégées"""
        file_path = self.shp_dir / "protected_areas.shp"
        
        if not file_path.exists():
            print(f"⚠ Zones protégées non trouvées : {file_path}")
            return None
            
        try:
            gdf = gpd.read_file(file_path)
            print(f"✓ Zones protégées chargées : {len(gdf)} entités")
            return gdf
        except Exception as e:
            print(f"⚠ Erreur lors du chargement des zones protégées : {e}")
            return None
    
    def list_available_layers(self):
        """Liste toutes les couches disponibles"""
        print("\n" + "="*70)
        print("COUCHES DISPONIBLES".center(70))
        print("="*70)
        
        # Vérifier que les dossiers existent
        if not self.shp_dir.exists():
            print(f"\n⚠ Dossier shapefiles introuvable : {self.shp_dir}")
        else:
            # Shapefiles OSM
            print("\n📁 SHAPEFILES OSM:")
            shp_files = sorted(self.shp_dir.glob("*.shp"))
            if shp_files:
                for shp in shp_files:
                    print(f"  • {shp.stem}")
            else:
                print("  (aucun fichier)")
        
        if not self.tif_dir.exists():
            print(f"\n⚠ Dossier tif_geojson introuvable : {self.tif_dir}")
        else:
            # GeoJSON
            print("\n📁 GEOJSON (Limites administratives):")
            json_files = sorted(self.tif_dir.glob("*.geojson"))
            if json_files:
                for json_file in json_files:
                    print(f"  • {json_file.stem}")
            else:
                print("  (aucun fichier)")
            
            # Rasters
            print("\n📁 RASTERS (Population):")
            tif_files = sorted(self.tif_dir.glob("*.tif"))
            if tif_files:
                for tif in tif_files:
                    print(f"  • {tif.stem}")
            else:
                print("  (aucun fichier)")
        
        print("="*70 + "\n")


# ==============================================================================
# TEST DU MODULE
# ==============================================================================

if __name__ == "__main__":
    print("\n" + "="*70)
    print("TEST DU MODULE data_loader.py".center(70))
    print("="*70 + "\n")
    
    # Initialiser le loader
    loader = DataLoader(data_dir="data")
    
    # Lister les couches disponibles
    loader.list_available_layers()
    
    # Tenter de charger quelques couches
    print("\nTEST DE CHARGEMENT DES COUCHES")
    print("-"*70 + "\n")
    
    try:
        print("Chargement des limites administratives...")
        boundaries = loader.load_boundaries(level=1)
        
        print("\nChargement des localités...")
        places = loader.load_osm_layer('places', geometry_type='free')
        
        print("\nChargement des POIs...")
        pois = loader.load_osm_layer('pois', geometry_type='free')
        
        print("\n✓ Tests de chargement terminés !")
        
    except Exception as e:
        print(f"\n⚠ Erreur lors du test : {e}")
        import traceback
        traceback.print_exc()
    
    print("\n" + "="*70)