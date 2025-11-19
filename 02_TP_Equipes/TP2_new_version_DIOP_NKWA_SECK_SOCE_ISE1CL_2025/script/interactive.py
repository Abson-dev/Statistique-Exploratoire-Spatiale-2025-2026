# ==============================================================================
# interactive.py
# Cartographie interactive avec Folium
# ==============================================================================

import folium
from folium import plugins
import geopandas as gpd
import numpy as np
import warnings
warnings.filterwarnings('ignore')

class InteractiveMapper:
    """Classe pour créer des cartes interactives"""
    
    def __init__(self, boundaries, center=None, zoom_start=7):
        """
        Parameters:
        -----------
        boundaries : GeoDataFrame
            Limites administratives
        center : list [lat, lon], optional
        zoom_start : int
        """
        self.boundaries = boundaries
        
        if center is None:
            bounds = boundaries.total_bounds
            center = [(bounds[1] + bounds[3]) / 2, (bounds[0] + bounds[2]) / 2]
        
        self.center = center
        self.zoom_start = zoom_start
    
    def create_base_map(self, tiles='CartoDB positron'):
        """
        Crée une carte de base Folium
        
        Parameters:
        -----------
        tiles : str
            Style de fond de carte
            Options: 'OpenStreetMap', 'CartoDB positron', 'CartoDB dark_matter'
            
        Returns:
        --------
        folium.Map
        """
        m = folium.Map(
            location=self.center,
            zoom_start=self.zoom_start,
            tiles=tiles
        )
        
        # Ajouter les limites administratives
        folium.GeoJson(
            self.boundaries.__geo_interface__,
            style_function=lambda x: {
                'fillColor': 'transparent',
                'color': 'black',
                'weight': 2,
                'fillOpacity': 0
            },
            name='Limites administratives'
        ).add_to(m)
        
        return m
    
    def add_infrastructure_layer(self, m, infrastructure_gdf, infra_name, color='blue'):
        """
        Ajoute une couche d'infrastructure à la carte avec clustering
        
        Parameters:
        -----------
        m : folium.Map
        infrastructure_gdf : GeoDataFrame
        infra_name : str
        color : str
        
        Returns:
        --------
        folium.Map
        """
        if infrastructure_gdf is None or len(infrastructure_gdf) == 0:
            return m
        
        # Créer un groupe de markers avec clustering
        marker_cluster = plugins.MarkerCluster(name=infra_name).add_to(m)
        
        for idx, row in infrastructure_gdf.iterrows():
            # Récupérer les coordonnées du centroïde
            coords = row.geometry.centroid
            lat, lon = coords.y, coords.x
            
            # Informations du popup
            name = row.get('name', 'Inconnu')
            fclass = row.get('fclass', infra_name)
            
            popup_html = f"""
            <div style="font-family: Arial; font-size: 12px;">
                <b style="font-size: 14px;">{name}</b><br>
                <hr style="margin: 5px 0;">
                <b>Type:</b> {fclass}<br>
                <b>Infrastructure:</b> {infra_name}
            </div>
            """
            
            folium.Marker(
                location=[lat, lon],
                popup=folium.Popup(popup_html, max_width=250),
                icon=folium.Icon(color=color, icon='info-sign')
            ).add_to(marker_cluster)
        
        return m
    
    def add_heatmap(self, m, localities_gdf, weight_column='distance_m', invert=True):
        """
        Ajoute une carte de chaleur (heatmap)
        
        Parameters:
        -----------
        m : folium.Map
        localities_gdf : GeoDataFrame
        weight_column : str
            Colonne utilisée comme poids
        invert : bool
            Inverser les poids (distance élevée = chaleur élevée)
        
        Returns:
        --------
        folium.Map
        """
        if localities_gdf is None or len(localities_gdf) == 0:
            return m
        
        # Préparer les données pour la heatmap
        heat_data = []
        for idx, row in localities_gdf.iterrows():
            coords = row.geometry.centroid
            lat, lon = coords.y, coords.x
            
            weight = row.get(weight_column, 1)
            if invert and weight_column == 'distance_m':
                # Pour les distances: plus c'est loin, plus c'est "chaud" (mal desservi)
                weight = weight / 1000  # Normaliser
            
            heat_data.append([lat, lon, weight])
        
        # Ajouter la heatmap
        plugins.HeatMap(
            heat_data,
            name='Carte de chaleur - Accessibilité',
            min_opacity=0.3,
            radius=15,
            blur=20,
            gradient={
                0.0: 'green',
                0.5: 'yellow',
                1.0: 'red'
            }
        ).add_to(m)
        
        return m
    
    def create_accessibility_map(self, analyzer_results, infra_name, output_file=None):
        """
        Crée une carte interactive d'accessibilité complète
        
        Parameters:
        -----------
        analyzer_results : dict
            Résultats de InfrastructureAnalyzer
        infra_name : str
        output_file : str, optional
        
        Returns:
        --------
        folium.Map
        """
        if infra_name not in analyzer_results:
            print(f"⚠ Pas de résultats pour {infra_name}")
            return None
        
        result = analyzer_results[infra_name]
        localities = result['localities_with_distances']
        buffers = result['buffers']
        
        # Carte de base
        m = self.create_base_map()
        
        # Ajouter les buffers (zones de couverture)
        folium.GeoJson(
            buffers.__geo_interface__,
            style_function=lambda x: {
                'fillColor': 'lightblue',
                'color': 'blue',
                'weight': 1,
                'fillOpacity': 0.3
            },
            name='Zone de couverture (100m)'
        ).add_to(m)
        
        # Ajouter les localités avec code couleur selon accessibilité
        for idx, row in localities.iterrows():
            coords = row.geometry.centroid
            lat, lon = coords.y, coords.x
            
            dist = row['distance_m']
            name = row.get('name', 'Inconnu')
            
            # Déterminer la couleur selon la distance
            if dist < 100:
                color = 'green'
                status = 'Très bien desservi'
                icon = 'ok-sign'
            elif dist < 1000:
                color = 'lightgreen'
                status = 'Bien desservi'
                icon = 'info-sign'
            elif dist < 5000:
                color = 'orange'
                status = 'Moyennement desservi'
                icon = 'warning-sign'
            else:
                color = 'red'
                status = 'Mal desservi'
                icon = 'remove-sign'
            
            # Popup informatif
            popup_html = f"""
            <div style="font-family: Arial; font-size: 12px;">
                <b style="font-size: 14px;">{name}</b><br>
                <hr style="margin: 5px 0;">
                <b>Distance:</b> {dist:.0f} m ({dist/1000:.2f} km)<br>
                <b>Statut:</b> <span style="color: {color}; font-weight: bold;">{status}</span><br>
                <b>Infrastructure:</b> {infra_name}
            </div>
            """
            
            folium.CircleMarker(
                location=[lat, lon],
                radius=6,
                popup=folium.Popup(popup_html, max_width=250),
                color=color,
                fill=True,
                fillColor=color,
                fillOpacity=0.7,
                weight=2
            ).add_to(m)
        
        # Ajouter une légende
        legend_html = f'''
        <div style="position: fixed; 
                    bottom: 50px; right: 50px; width: 200px; height: auto;
                    background-color: white; border:2px solid grey; z-index:9999;
                    font-size:12px; padding: 10px; border-radius: 5px;">
            <p style="margin: 0; font-weight: bold; text-align: center; border-bottom: 1px solid grey; padding-bottom: 5px;">
                Légende - Accessibilité
            </p>
            <p style="margin: 5px 0;"><span style="background-color: green; width: 20px; height: 10px; display: inline-block; margin-right: 5px;"></span>< 100m : Très bien</p>
            <p style="margin: 5px 0;"><span style="background-color: lightgreen; width: 20px; height: 10px; display: inline-block; margin-right: 5px;"></span>< 1km : Bien</p>
            <p style="margin: 5px 0;"><span style="background-color: orange; width: 20px; height: 10px; display: inline-block; margin-right: 5px;"></span>< 5km : Moyen</p>
            <p style="margin: 5px 0;"><span style="background-color: red; width: 20px; height: 10px; display: inline-block; margin-right: 5px;"></span>> 5km : Mauvais</p>
        </div>
        '''
        m.get_root().html.add_child(folium.Element(legend_html))
        
        # Contrôle des couches
        folium.LayerControl().add_to(m)
        
        # Ajouter une mini-carte
        plugins.MiniMap(toggle_display=True).add_to(m)
        
        # Ajouter un outil de mesure
        plugins.MeasureControl(position='topleft').add_to(m)
        
        # Sauvegarder
        if output_file:
            m.save(output_file)
            print(f"  ✓ Carte interactive sauvegardée → {output_file}")
        
        return m


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
    print("TEST DU MODULE interactive.py".center(70))
    print("="*70 + "\n")
    
    # Créer dossier de sortie
    os.makedirs("outputs/test_interactive", exist_ok=True)
    
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
        
        # Créer cartes interactives
        print("\n" + "-"*70)
        print("GÉNÉRATION DES CARTES INTERACTIVES")
        print("-"*70 + "\n")
        
        mapper = InteractiveMapper(boundaries)
        
        for infra_name in analyzer.results.keys():
            print(f"Carte interactive : {infra_name}")
            mapper.create_accessibility_map(
                analyzer.results,
                infra_name,
                output_file=f"outputs/test_interactive/{infra_name.lower().replace(' ', '_')}.html"
            )
        
        print("\n✓ Cartes interactives générées avec succès !")
        print(f"  Fichiers dans : outputs/test_interactive/")
        print(f"  Ouvrez les fichiers .html dans un navigateur web")
        
    except Exception as e:
        print(f"\n⚠ Erreur : {e}")
        import traceback
        traceback.print_exc()
    
    print("\n" + "="*70)