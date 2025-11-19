# Analyse spatiale du paludisme au Bénin (2000-2024)

## Description du projet
Ce projet analyse l'évolution spatio-temporelle du taux d'incidence du paludisme à *Plasmodium falciparum* au Bénin sur une période de 25 ans (2000-2024).
L'analyse utilise des données géospatiales pour cartographier et comprendre la distribution du paludisme sur le territoire béninois.

**Réalisation de :** Herman YAMAHA

**Sous la supervision de :** M. HEMA

**Classe :** ISE1 CL

**Année académique :** 2025-2026

## Structure du projet
```
TP1_Individuel_Herman_YAMAHA/
│
├── data/
│   ├── clippedlayers/              # Couches raster 
│   │   └── 202508_Global_Pf_Incidence_Rate_BEN_YYYY.tiff  # 25 fichiers (2000-2024)
│   │
│   └── gadm/                       # Données administratives du Bénin
│       └── gadm41_BEN_shp/         # Shapefiles GADM niveau 0-4
│           ├── gadm41_BEN_0.*      # Niveau national
│           ├── gadm41_BEN_1.*      # Niveau départemental
│           ├── gadm41_BEN_2.*      # Niveau communal
│           └── gadm41_SEN_3.*      # Niveau arrondissement
│
└── outputs/                        # Résultats de l'analyse
    ├── carte_2010.png              # Carte statique pour l'année 2010
    ├── carte_interactive_2010.html # Carte interactive pour l'année 2010
    ├── comparaison_multi_annees.png # Comparaison entre plusieurs années
    ├── evolution_temporelle.png    # Évolution temporelle du paludisme
    ├── rasters_metadata_summary.csv # Métadonnées des rasters
    └── statistiques_annuelles.csv   # Taux d'incidence moyenne par année
```

## Données utilisées
### Données raster
### Données vectorielles

## Technologies et outils
- **R / RStudio** : Environnement de développement principal
- **Principaux packages R utilisés  :**
  - `sf` : Manipulation de données vectorielles
  - `terra` ou `raster` : Manipulation de données raster
  - `tmap` : Création de cartes thématiques
  - `ggplot2` : Visualisations
  - `leaflet` : Cartes interactives
  - `dplyr` : Manipulation de données

## Analyses ééalisées
### 1. Cartographie statique
- Visualisation du taux d'incidence pour l'année 2010
- Production de cartes thématiques avec légende et échelle

### 2. Cartographie interactive
- Carte interactive HTML permettant l'exploration des données
- Zoom, pan et affichage d'informations au survol

### 3. Comparaison multi-annuelle
- Analyse comparative entre plusieurs années clés
- Identification des zones à forte/faible incidence

### 4. Évolution temporelle
- Analyse de tendances sur 25 ans (2000-2024)
- Visualisation de l'évolution du paludisme au Bénin
```
```
### Reproduction des analyses
1. Ouvrir le projet RStudio (`.Rproj`)
2. Exécuter les scripts dans l'ordre chronologique
3. Les résultats seront générés dans le dossier `outputs/`

## Résultats principaux
Les analyses ont permis de :
- Cartographier la distribution spatiale du paludisme au Bénin
- Identifier les zones à forte endémie
- Observer l'évolution temporelle de la maladie
- Comparer les tendances entre différentes régions administratives

## Références
- **GADM :** https://gadm.org/
- **Données sur le paludisme :** https://data.malariaatlas.org/

```
