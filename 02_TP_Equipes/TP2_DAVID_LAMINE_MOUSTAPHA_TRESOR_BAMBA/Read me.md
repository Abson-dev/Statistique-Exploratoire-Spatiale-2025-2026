# Analyse de la repartition spatiale des services Sociaux de Base au Tchad

## Description du ProjetS
Ce projet analyse la répartition spatiale des infrastructures essentielles au Tchad.
L’objectif est de cartographier et d’étudier la localisation des cliniques, des pharmacies, 
des écoles, du réseau routier et des principaux points d’intérêt afin de comprendre 
l’organisation territoriale et l’accessibilité des services sociaux.
L’approche repose sur l’exploitation systématique des données géospatiales pour produire des 
indicateurs régionaux tels que les distances aux routes, la densité des équipements, et la 
proportion de superficie réservée selon les différents usages du sol.

## Équipe
- **David NGUEAJIO**
- **Cheikh Mouhamadou Moustapha NDIAYE **
- **Mamadou Lamine DIABANG **
- **Cheikh Ahmadou Bamba FALL **

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
│   ├── cartes/
│   │   ├── carte_aires_protegees_tchad.html
│   │   ├── carte_reseau_routier_tchad.html
│   │   └── carte_routes_Mayo-Kebbi_Ouest.html
│   └── donnees_analysees/
│       ├── services_sociaux_par_region.csv
│       ├── services_sociaux_par_region.xlsx
│       ├── wdpa_par_region.csv
│       └── wdpa_par_region.xlsx
└── docs/
    └── README.md


```

## Données Utilisées
### Données Raster
### Données Vectorielles

## Technologies et Outils
Le traitement géospatial a été réalisé avec Google Earth Engine via l’API Python.
Les bibliothèques Python essentielles utilisées sont :

*earthengine-api* pour accéder aux données et fonctions GEE
*geemap* pour la visualisation cartographique interactive
*folium* pour les cartes HTML interactives
*pandas* pour les tableaux de données,etc

## Taches Réalisées
*visualisation* de la distribution spatiale des zones protégées et 
analyser leur répartition territoriale.
*analyse* de la connectivité du territoire et la densité du réseau routier.
*mise en évidence* du reseau routier de la région de Mayo-Kebbi .
*analyse* de la répartition des infrastructures sociales selon les régions et 
identifier les zones sous-équipées.

## Références
*GADM* : [https://gadm.org/](https://gadm.org/)
*OSM* : [https://download.geofabrik.de/](https://download.geofabrik.de/)
*WDPA* : [https://www.protectedplanet.net/](https://www.protectedplanet.net/)
*Google Earth Engine* : [https://earthengine.google.com/](https://earthengine.google.com/)

## Licence
Projet académique.
```
