# Analyse Spatiale du Paludisme en Ouganda (2000-2024)

## Description du Projet

Ce projet analyse l'évolution spatio-temporelle du taux d'incidence du paludisme à *Plasmodium falciparum* en Ouganda sur une période de 25 ans (2000-2024).
L'analyse utilise des données géospatiales pour cartographier et comprendre la distribution du paludisme sur le territoire ougandais.

## Auteur

-Math SOCE

**Classe :** ISE1 CL  
**Année académique :** 2025-2026

## Structure du Projet

```
Projet_Paludisme_Ouganda/
│
├── data/
│   ├── rasters/                    # Couches raster 
│   │   ├── incidence_2000.tif      # 25 fichiers (2000-2024)
│   │   ├── incidence_2001.tif
│   │   ├── incidence_2002.tif
│   │   ├── incidence_2003.tif
│   │   ├── incidence_2004.tif
│   │   ├── incidence_2005.tif
│   │   ├── incidence_2006.tif
│   │   ├── incidence_2007.tif
│   │   ├── incidence_2008.tif
│   │   ├── incidence_2009.tif
│   │   ├── incidence_2010.tif
│   │   ├── incidence_2011.tif
│   │   ├── incidence_2012.tif
│   │   ├── incidence_2013.tif
│   │   ├── incidence_2014.tif
│   │   ├── incidence_2015.tif
│   │   ├── incidence_2016.tif
│   │   ├── incidence_2017.tif
│   │   ├── incidence_2018.tif
│   │   ├── incidence_2019.tif
│   │   ├── incidence_2020.tif
│   │   ├── incidence_2021.tif
│   │   ├── incidence_2022.tif
│   │   ├── incidence_2023.tif
│   │   └── incidence_2024.tif
│   │
│   └── gadm41_UGA_shp/             # Données administratives de l'Ouganda
│       ├── gadm41_UGA_0.shp        # Niveau national
│       ├── gadm41_UGA_0.dbf
│       ├── gadm41_UGA_0.shx
│       ├── gadm41_UGA_0.prj
│       ├── gadm41_UGA_1.shp        # Niveau régional
│       ├── gadm41_UGA_1.dbf
│       ├── gadm41_UGA_1.shx
│       ├── gadm41_UGA_1.prj
│       ├── gadm41_UGA_2.shp        # Niveau départemental
│       ├── gadm41_UGA_2.dbf
│       ├── gadm41_UGA_2.shx
│       ├── gadm41_UGA_2.prj
│       ├── gadm41_UGA_3.shp        # Niveau arrondissement
│       ├── gadm41_UGA_3.dbf
│       ├── gadm41_UGA_3.shx
│       ├── gadm41_UGA_3.prj
│       ├── gadm41_UGA_4.shp        # Niveau communal
│       ├── gadm41_UGA_4.dbf
│       ├── gadm41_UGA_4.shx
│       └── gadm41_UGA_4.prj
│
├── outputs/                        # Résultats de l'analyse
│   ├── diagnostic/
│   │   ├── shapefiles_diagnostic.csv
│   │   └── rasters_metadata_complet.csv
│   │
│   ├── maps/
│   │   ├── carte_2000.png
│   │   ├── carte_2001.png
│   │   ├── carte_2002.png
│   │   ├── carte_2003.png
│   │   ├── carte_2004.png
│   │   ├── carte_2005.png
│   │   ├── carte_2006.png
│   │   ├── carte_2007.png
│   │   ├── carte_2008.png
│   │   ├── carte_2009.png
│   │   ├── carte_2010.png
│   │   ├── carte_2011.png
│   │   ├── carte_2012.png
│   │   ├── carte_2013.png
│   │   ├── carte_2014.png
│   │   ├── carte_2015.png
│   │   ├── carte_2016.png
│   │   ├── carte_2017.png
│   │   ├── carte_2018.png
│   │   ├── carte_2019.png
│   │   ├── carte_2020.png
│   │   ├── carte_2021.png
│   │   ├── carte_2022.png
│   │   ├── carte_2023.png
│   │   └── carte_2024.png
│   │
│   ├── maps_labels/
│   │   ├── carte_labels_2000.png
│   │   ├── carte_labels_2001.png
│   │   ├── carte_labels_2002.png
│   │   ├── carte_labels_2003.png
│   │   ├── carte_labels_2004.png
│   │   ├── carte_labels_2005.png
│   │   ├── carte_labels_2006.png
│   │   ├── carte_labels_2007.png
│   │   ├── carte_labels_2008.png
│   │   ├── carte_labels_2009.png
│   │   ├── carte_labels_2010.png
│   │   ├── carte_labels_2011.png
│   │   ├── carte_labels_2012.png
│   │   ├── carte_labels_2013.png
│   │   ├── carte_labels_2014.png
│   │   ├── carte_labels_2015.png
│   │   ├── carte_labels_2016.png
│   │   ├── carte_labels_2017.png
│   │   ├── carte_labels_2018.png
│   │   ├── carte_labels_2019.png
│   │   ├── carte_labels_2020.png
│   │   ├── carte_labels_2021.png
│   │   ├── carte_labels_2022.png
│   │   ├── carte_labels_2023.png
│   │   └── carte_labels_2024.png
│   │
│   ├── histogrammes/
│   │   ├── hist_2000.png
│   │   ├── hist_2001.png
│   │   ├── hist_2002.png
│   │   ├── hist_2003.png
│   │   ├── hist_2004.png
│   │   ├── hist_2005.png
│   │   ├── hist_2006.png
│   │   ├── hist_2007.png
│   │   ├── hist_2008.png
│   │   ├── hist_2009.png
│   │   ├── hist_2010.png
│   │   ├── hist_2011.png
│   │   ├── hist_2012.png
│   │   ├── hist_2013.png
│   │   ├── hist_2014.png
│   │   ├── hist_2015.png
│   │   ├── hist_2016.png
│   │   ├── hist_2017.png
│   │   ├── hist_2018.png
│   │   ├── hist_2019.png
│   │   ├── hist_2020.png
│   │   ├── hist_2021.png
│   │   ├── hist_2022.png
│   │   ├── hist_2023.png
│   │   └── hist_2024.png
│   │
│   └── statistiques/
│       ├── stats_globales.csv
│       ├── evolution_temporelle.png
│       ├── analyse_tendance.png
│       └── boxplot_stats.png
│
├── diagnostic.py                   # Script de diagnostic des données
├── visualisation.py                # Script de visualisation
└── README.md                       # Ce fichier
```

## Données Utilisées

### Données Raster

- **Source :** Malaria Atlas Project
- **Format :** GeoTIFF (.tif)
- **Contenu :** Taux d'incidence du paludisme à *Plasmodium falciparum*
- **Période :** 2000-2024 (25 fichiers annuels)

### Données Vectorielles

- **Source :** GADM (Database of Global Administrative Areas)
- **Format :** Shapefile (.shp)
- **Niveaux administratifs :**
  - Niveau 0 : Frontière nationale
  - Niveau 1 : Régions
  - Niveau 2 : Départements
  - Niveau 3 : Arrondissements
  - Niveau 4 : Communes

## Technologies et Outils

- **Python 3.8+** : Langage de programmation principal
- **Principaux packages Python utilisés :**
  - 'geopandas' : Manipulation de données vectorielles
  - 'rasterio' : Manipulation de données raster
  - 'matplotlib' : Création de visualisations
  - 'numpy' : Calculs numériques
  - 'pandas' : Manipulation de données
  - 'seaborn' : Visualisations statistiques

## Analyses Réalisées

### 1. Diagnostic des Données

- Vérification des propriétés des shapefiles
- Analyse des métadonnées des rasters
- Validation de la cohérence spatiale

### 2. Cartographie Statique

- Visualisation du taux d'incidence pour chaque année (2000-2024)
- Production de cartes thématiques avec légende et échelle
- Cartes masquées par les frontières nationales

### 3. Cartographie avec Labels

- Cartes avec noms des régions administratives
- Identification spatiale des zones

### 4. Analyse de Distribution

- Histogrammes de fréquence par année
- Statistiques descriptives (moyenne, médiane)

### 5. Évolution Temporelle

- Analyse de tendances sur 25 ans (2000-2024)
- Visualisation de l'évolution du paludisme en Ouganda
- Graphiques de variations annuelles

## Résultats Principaux

Les analyses ont permis de :
- Cartographier la distribution spatiale du paludisme en Ouganda
- Identifier les zones à forte endémie
- Observer l'évolution temporelle de la maladie
- Comparer les tendances entre différentes régions administratives

## Références

- **GADM :** https://gadm.org/
- **Données sur le paludisme :** https://data.malariaatlas.org/

## Licence

Projet académique.