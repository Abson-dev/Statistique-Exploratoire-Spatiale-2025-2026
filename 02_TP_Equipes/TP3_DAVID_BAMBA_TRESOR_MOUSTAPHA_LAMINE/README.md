# TP3 – Analyse Spatiale de la Population et de l'Accessibilité aux Services Sociaux de Base au Tchad

## Description du Projet
Ce TP3 constitue la suite directe du TP2, en intégrant cette fois les données démographiques issues de WorldPop afin d'évaluer la distribution spatiale de la population et son accessibilité aux services sociaux de base au Tchad.

## Équipe
- David NGUEAJIO
- Cheikh Mouhamadou Moustapha NDIAYE
- Mamadou Lamine DIABANG
- Cheikh Ahmadou Bamba FALL

**Classe :** ISE1 CL  
**Année académique :** 2025-2026

## Structure du Projet
```
TP1_DAVID_MOUSTAPHA_LAMINE_BAMBA_ISE1_CL_2025_2026/
│
├── data/
│   ├── gadm/                    # Limites administratives du Tchad (GADM)
│   │   └── gadm41_TCD_shp/
│   │       ├── gadm41_TCD_0.*   # Pays entier
│   │       ├── gadm41_TCD_1.*   # Régions
│   │       ├── gadm41_TCD_2.*   # Départements
│   │       └── gadm41_TCD_3.*   # Sous-préfectures
│   │
│   ├── WorldPop/
│   │   ├── RASTERS_1KM  ─ tcd_pop_2025_CN_1km_R2025A_UA_v1.tif      # Population 1 km × 1 km
│   │   └── RASTERS_100M ─ tcd_pop_2025_CN_100m_R2025A_UA_v1.tif     # Population 100 m × 100 m
│   ├── osm/
│   │   └── chad-251114-free/    # Données OpenStreetMap pour le Tchad
│   │       │
│   │       ├── buildings/
│   │       │   └── gis_osm_buildings_a_free_1.* 
│   │       │        # Bâtiments : maisons, écoles, hôpitaux, commerces…
│   │       │
│   │       ├── landuse/
│   │       │   └── gis_osm_landuse_a_free_1.*
│   │       │        # Occupation du sol : zones urbaines, agricoles, forêts…
│   │       │
│   │       ├── natural/
│   │       │   ├── gis_osm_natural_a_free_1.*   # Polygones : lacs, marais, dunes…
│   │       │   └── gis_osm_natural_free_1.*      # Lignes/points : falaises, crêtes…
│   │       │
│   │       ├── places/
│   │       │   ├── gis_osm_places_a_free_1.*     # Polygones : villes/villages
│   │       │   └── gis_osm_places_free_1.*        # Points : localités, villages
│   │       │
│   │       ├── pois/
│   │       │   ├── gis_osm_pois_a_free_1.*        # Campus, parcs, zones publiques
│   │       │   └── gis_osm_pois_free_1.*          # Écoles, pharmacies, banques…
│   │       │
│   │       ├── pofw/                              # Lieux de culte
│   │       │   ├── gis_osm_pofw_a_free_1.*        # Mosquées/églises (polygones)
│   │       │   └── gis_osm_pofw_free_1.*          # Points des lieux de culte
│   │       │
│   │       ├── railways/
│   │       │   └── gis_osm_railways_free_1.*      # Voies ferrées
│   │       │
│   │       ├── roads/
│   │       │   └── gis_osm_roads_free_1.*         # Routes : primary / secondary / tertiary
│   │       │
│   │       ├── traffic/
│   │       │   ├── gis_osm_traffic_a_free_1.*     # Parkings, échangeurs
│   │       │   └── gis_osm_traffic_free_1.*        # Stops, feux, signalisations
│   │       │
│   │       ├── transport/
│   │       │   ├── gis_osm_transport_a_free_1.*   # Aéroports, gares, terminaux
│   │       │   └── gis_osm_transport_free_1.*      # Arrêts de bus, stations, quais
│   │       │
│   │       └── waterways/
│   │           ├── gis_osm_waterways_free_1.*      # Cours d’eau (rivières, canaux)
│   │           └── gis_osm_waterways_a_free_1.*    # Zones fluviales (polygones)
│   │
│   └── protected_areas/                          # Aires protégées du Tchad (WDPA)
│       └── WDPA_WDOECM_Nov2025_Public_TCD_shp/
│           ├── WDPA_WDOECM_Nov2025_Public_TCD.*  
│           │      # Aires protégées : parcs nationaux, réserves, zones naturelles
│           │      # Source : WDPA (World Database on Protected Areas)
│           └── README.txt                        # Informations officielles WDPA
│
├── scripts/
│   ├── /manip.visualisations.ipynb
│   │  
│   └── /merge.ipynb
│       
│
├── outputs/
│   ├── buffer_culte.html
│   ├── buffer_ecoles.html
│   ├── buffer_sante.html
│   ├── map_population100.html
│   ├── map_population1000.html
│   │
│   ├── pop_buffer_culte.csv
│   ├── pop_buffer_culte.xlsx
│   ├── pop_buffer_ecoles.csv
│   ├── pop_buffer_ecoles.xlsx
│   ├── pop_buffer_sante.csv
│   ├── pop_buffer_sante.xlsx
│   ├── pop_protected_areas.csv
│   └── pop_protected_areas.xlsx
└── docs/
    └── README.md


```

## Données Utilisées

### Données Raster
**WorldPop (2025) – Population**
- Résolution 100 m × 100 m
- Résolution 1 km × 1 km
- Valeurs : nombre de personnes par pixel

### Données Vectorielles
- **OSM** : cliniques, hôpitaux, écoles, lieux de culte, routes, bâtiments…
- **GADM** : niveaux administratifs 0, 1, 2, 3 du Tchad
- **WDPA** : aires protégées (parcs, réserves)

## Technologies et Outils

- Google Earth Engine (API Python)
- Librairies Python :
  - earthengine-api
  - geemap
  - folium
  - pandas
  - numpy
  - geopandas (local)
- Visualisation en HTML interactive
- Export des résultats en Excel et CSV

## Tâches Réalisées

### Cartographie de la population
- Raster 100 m × 100 m : densité très fine
- Raster 1 km × 1 km : vue globale
- Visualisation dans GEE avec palette de couleurs
- Export en cartes HTML interactives

### Calcul des buffers autour des services

| Service | Distances utilisées |
|---------|---------------------|
| Cliniques & Hôpitaux | 1 km, 5 km, 10 km |
| Écoles | 1 km, 5 km, 10 km |
| Lieux de culte | 1 km, 5 km, 10 km |

Chaque buffer a servi à calculer la population totale dans la zone (population desservie)

### Population à l'intérieur des aires protégées (WDPA)
- Extraction des aires protégées
- Intersection raster population × polygones WDPA
- Calcul du nombre de personnes dans chaque aire protégée
- Export des tableaux en Excel et CSV

## Références

- **WorldPop** : https://www.worldpop.org/datacatalog/
- **GADM** : https://gadm.org/
- **OSM** : https://download.geofabrik.de/
- **WDPA** : https://www.protectedplanet.net/
- **Google Earth Engine** : https://earthengine.google.com/

## Licence
Projet académique.
