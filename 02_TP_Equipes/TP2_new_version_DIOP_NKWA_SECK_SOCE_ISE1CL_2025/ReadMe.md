# Analyse Spatiale des Infrastructures Essentielles au Bénin

## Description du Projet

Ce projet analyse la disposition des infrastructures et services essentiels au Bénin en utilisant des données géospatiales issues d'OpenStreetMap (OSM). L'analyse permet d'évaluer la distribution spatiale des infrastructures de santé, d'éducation, de transport et d'identifier les zones sous-desservies nécessitant des interventions prioritaires.

## Auteurs

**Leslye Patricia NKWA**

**Mouhamet SECK**

**Joo Young Véridique Gabriel DIOP**

**Math SOCE**

**Classe :** ISE1 CL  

**Année académique :** 2025-2026

## Structure du Projet

```
Projet_Infrastructures_Benin/
│
├── data/
│   ├── shapefiles/                         # Couches vectorielles OSM
│   │   ├── gis_osm_buildings_a_free_1.shp
│   │   ├── gis_osm_landuse_a_free_1.shp
│   │   ├── gis_osm_natural_a_free_1.shp
│   │   ├── gis_osm_natural_free_1.shp
│   │   ├── gis_osm_places_a_free_1.shp
│   │   ├── gis_osm_places_free_1.shp
│   │   ├── gis_osm_pofw_a_free_1.shp
│   │   ├── gis_osm_pofw_free_1.shp
│   │   ├── gis_osm_pois_a_free_1.shp
│   │   ├── gis_osm_pois_free_1.shp
│   │   ├── gis_osm_railways_free_1.shp
│   │   ├── gis_osm_roads_free_1.shp
│   │   ├── gis_osm_traffic_a_free_1.shp
│   │   ├── gis_osm_traffic_free_1.shp
│   │   ├── gis_osm_transport_a_free_1.shp
│   │   ├── gis_osm_transport_free_1.shp
│   │   ├── gis_osm_water_a_free_1.shp
│   │   ├── gis_osm_waterways_free_1.shp
│   │   └── protected_areas.shp
│   │
│   └── tif_geojson/                        # Limites administratives et population
│       ├── geoBoundaries-BEN-ADM0.geojson  # Niveau national
│       ├── geoBoundaries-BEN-ADM1.geojson  # Niveau départemental
│       ├── geoBoundaries-BEN-ADM2.geojson  # Niveau communal
│       ├── ben_pop_2024_CN_1km_R2025A_UA_v1.tif
│       └── ben_pop_2024_CN_100m_R2025A_v1.tif
│
├── script/                                 # Scripts Python
│   ├── data_loader.py  # Charge toutes les données géospatiales depuis les fichiers sources: Shapefiles, OSM, WDPA
│   ├── preprocessing.py  # Prépare et nettoie les données avant analyse en harmonisant les systèmes de projection
│   ├── utils.py  # Fournit une boîte à outils de fonctions géospatiales réutilisables comme la création de buffers etc
│   ├── analyses.py  # Effectue les analyses spatiales de proximité et d'accessibilité aux infrastructures.
│   ├── viz.py  # Génère les visualisations statiques
│   ├── interactive.py  # Crée des cartes web interactives(HTML)permettant zoom et navigation et exploration dynamique
│   ├── advanced_viz.py  # Produit des visualisations spécialisées:cartes de population, infrastructures de santé/éducation etc
│   ├── departmental_analysis.py  # Calcule les statistiques agrégées par départemen
│   ├── run_all.py  # Script main orchestrant lensemble du travail
│   └── check_environment.py  # Script de diagnostic vérifiant que l'environnement est correctement configuré 
│
├── outputs/                                # Résultats de l'analyse
│   ├── analyses/
│   │   ├── statistiques_infrastructures.csv
│   │   ├── stats_departements.csv
│   │   ├── distances_hopitaux.csv
│   │   ├── distances_hopitaux.shp
│   │   ├── distances_cliniques.csv
│   │   ├── distances_cliniques.shp
│   │   ├── distances_pharmacies.csv
│   │   ├── distances_pharmacies.shp
│   │   ├── distances_ecoles.csv
│   │   └── distances_ecoles.shp
│   │
│   ├── maps/
│   │   ├── carte_hopitaux.png
│   │   ├── hist_hopitaux.png
│   │   ├── carte_cliniques.png
│   │   ├── hist_cliniques.png
│   │   ├── carte_pharmacies.png
│   │   ├── hist_pharmacies.png
│   │   ├── carte_ecoles.png
│   │   ├── hist_ecoles.png
│   │   └── comparaison_infrastructures.png
│   │
│   ├── interactive/
│   │   ├── carte_hopitaux.html
│   │   ├── carte_cliniques.html
│   │   ├── carte_pharmacies.html
│   │   └── carte_ecoles.html
│   │
│   └── advanced/
│       ├── population_benin.png
│       ├── localites_benin.png
│       ├── sante_education_benin.png
│       ├── aires_protegees_benin.png
│       ├── hydrographie_benin.png
│       ├── transport_benin.png
│       ├── choropleth_n_ecoles.png
│       └── barplot_n_ecoles.png
│
└── README.md                               # Ce fichier
```

## Données Utilisées

### Données Vectorielles

- **Source :** OpenStreetMap via Geofabrik
- **Format :** Shapefile (.shp)
- **Contenu :** Infrastructures de santé, éducation, transport, hydrographie, aires protégées
- **Téléchargement :** https://download.geofabrik.de/africa/benin.html

### Données Administratives

- **Source :** geoBoundaries
- **Format :** GeoJSON
- **Niveaux administratifs :**
  - Niveau 0 : Frontière nationale
  - Niveau 1 : Départements (12)
  - Niveau 2 : Communes (77)

### Données de Population

- **Source :** WorldPop
- **Format :** GeoTIFF (.tif)
- **Résolutions :** 1 km et 100 m
- **Année :** 2024

## Technologies et Outils

- **Principaux packages Python utilisés :**
  - geopandas : Manipulation de données vectorielles
  - rasterio : Manipulation de données raster
  - matplotlib : Création de visualisations
  - numpy : Calculs numériques
  - pandas : Manipulation de données
  - seaborn : Visualisations statistiques
  - folium : Cartes interactives

## Analyses Réalisées

### 1. Analyse de Proximité

- Calcul des distances minimales entre localités et infrastructures
- Création de buffers de couverture (100 m)
- Identification des zones desservies et sous-desservies

### 2. Cartographie Statique

- Visualisation de l'accessibilité pour chaque infrastructure
- Production de cartes thématiques avec gradient de couleur
- Histogrammes de distribution des distances

### 3. Cartographie Interactive

- Cartes web zoomables avec clustering
- Popups informatifs par infrastructure
- Code couleur selon l'accessibilité

### 4. Visualisations Thématiques

- Carte de densité de population
- Carte des localités par type
- Cartes des infrastructures de santé et éducation
- Carte des aires protégées
- Carte hydrographique
- Carte du réseau de transport

### 5. Analyses Départementales

- Comptage des infrastructures par département
- Calcul de densités et ratios
- Cartes choroplèthes et graphiques comparatifs

## Comment utiliser le projet

- Télécharger le dossier sur Github
- Exécuter le script `run_all.py` qui exécutera tout les sous-scripts du fichier et vous aurez les sorites dans le dossier outpu
## Résultats Principaux

Les analyses ont permis de :
- Cartographier la distribution spatiale des infrastructures au Bénin
- Identifier les zones à forte et faible accessibilité
- Calculer les distances moyennes aux services essentiels
- Comparer l'accessibilité entre départements
- Identifier les zones prioritaires pour de nouvelles infrastructures

## Références

- **OpenStreetMap :** https://www.openstreetmap.org/
- **Geofabrik :** https://download.geofabrik.de/
- **geoBoundaries :** https://www.geoboundaries.org/
- **WorldPop :** https://www.worldpop.org/


## Licence


Projet académique.

