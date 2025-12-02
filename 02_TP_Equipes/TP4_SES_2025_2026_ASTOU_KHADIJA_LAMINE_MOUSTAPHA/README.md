# TP4 :  Analyse des données géospatiales portant sur les différentes catégories de terres en Ouguanda

## Membres de l'équipe : 
- DIOP Astou
- GUEBEDIANG Khadija
- NDIAYE Moustapha
- DIABANG Lamine

**Superviseur :** M. HEMA

**Année académique : 2025 - 2026**

---


## 1. Description générale

Ce travail pratique a pour objectif d’identifier les terres arables en Ouganda à partir de données géospatiales disponibles sous Google Earth Engine (GEE).
L’analyse repose sur la création, le traitement et la visualisation de plusieurs rasters thématiques permettant de filtrer progressivement les zones impropres à l’agriculture.

L’ensemble du projet est réalisé en Python, en utilisant les bibliothèques :

**earthengine-api** : permet d’accéder aux données satellitaires et de traiter les rasters directement dans Google Earth Engine.

**folium** : sert à afficher les résultats sur une carte interactive.

**os** : gère les dossiers et fichiers pour sauvegarder les sorties.

**matplotlib.pyplot** : crée les graphiques, notamment le camembert final.

**numpy** : manipule les données numériques des rasters.

**pandas** : organise les résultats sous forme de tableaux et permet l’export.
---


## 2. Structure du projet

```
TP4_SES_2025_2026_ASTOU_KHADIJA_LAMINE_MOUSTAPHA/
│
│
├── TP4_SES.ipynb
│    
├── output/
|    ├── terres_cultivees_uganda.html
|    ├── forest_cover_2000_uganda.html
|    ├── forest_layers_uganda.html
|    ├── terres_impermeables_uganda.html
|    ├── pentes_uganda.html
|    ├── eaux_permanentes_uganda.html
|    ├── surfaces_protegees_uganda.html
|    └── toutes_les_couches_uganda.html
|    └── terres_arables_ouguanda
|    └── terres_arables_4_regions.csv
|    └── terres_arables_4_regions.png
|    └── camembert_terres_arables.png
|    └── superficies_terres_ouganda.png
|
│─── README.md
```
---

**NB :**
Le dossier **data** n’a pas été créé dans le dépôt Git, car toutes les données utilisées dans ce projet proviennent directement des collections de Google Earth Engine (GEE).
Elles ont donc été chargées et traitées en ligne, sans être téléchargées localement.

La seule exception concerne le raster des terres cultivées, issu d’une source externe (ESSD – Earth System Science Data).
Ce fichier, après découpe sur l’Ouganda, a une taille d’environ 407 Mo.
Étant donné que cette taille dépasse largement la limite autorisée par GitHub, il n’a pas été ajouté au dépôt.

Le processus complet d’obtention, de découpe et d’importation de ce raster dans GEE sera expliqué lors de la présentation.
--- 

## 3. Description du script


Ce script a pour objectif de cartographier les terres arables en Ouganda à une résolution de 30 m. Pour cela, il agrège **les terres cultivées** et les **zones déboisées**, puis exclut successivement :

**les surfaces imperméables**,

**les zones de forte pente (≥ 15 %)**,

**les eaux permanentes**,

**et les aires protégées**.

Le script permet ensuite de :

- calculer la superficie de chaque catégorie de terres(cultivées, déboisées, imperméables, pentues, protégées et arables) en ouguanda

- mesurer la surface totale des terres arables dans chaque région,

- déterminer la part des terres cultivées dans les terres arables, au niveau national et régional.

Pour y parvenir, Python est connecté à Google Earth Engine (GEE) afin de charger et traiter directement les collections de données spatiales.
Le raster des terres cultivées (résolution 30 m, année 2022) provient du site Earth System Science Data (ESSD). Comme le fichier couvre toute l’Afrique, son importation directe dans GEE est très lourde ; il a donc été pré-découpé dans QGIS sur l’emprise de l’Ouganda avant d’être importé dans GEE.

Les autres données sont chargées directement depuis les collections GEE suivantes :

déforestation : UMD/hansen/global_forest_change_2024_v1_12

terres imperméables : projects/sat-io/open-datasets/GISA_1972_2021

pentes : USGS/SRTMGL1_003

eaux permanentes : JRC/GSW1_3/GlobalSurfaceWater

aires protégées : WCMC/WDPA/current/polygons

limites administratives : FAO/GAUL/2015

L’ensemble du processus permet d’obtenir une carte finale des terres arables, ainsi que des statistiques régionales et nationales exploitables pour l’analyse.\
---


## 4. Références des données

- **eaux permanentes** : https://developers.google.com/earth-engine/datasets/catalog/JRC_GSW1_4_GlobalSurfaceWater?hl=fr
- **déforestation** : https://developers.google.com/earth-engine/datasets/catalog/UMD_hansen_global_forest_change_2024_v1_12?hl=fr
- **terres cultivées** : https://essd.copernicus.org/articles/17/3777/2025/
- **pentes** : https://developers.google.com/earth-engine/datasets/catalog/USGS_SRTMGL1_003?hl=fr
- **aires protégées** : https://developers.google.com/earth-engine/datasets/catalog/WCMC_WDPA_current_polygons?hl=fr
- **limites administratives** : https://developers.google.com/earth-engine/datasets/catalog/FAO_GAUL_2015_level0?hl=fr
- **terres imperméables** : https://gee-community-catalog.org/projects/gisa/

---

