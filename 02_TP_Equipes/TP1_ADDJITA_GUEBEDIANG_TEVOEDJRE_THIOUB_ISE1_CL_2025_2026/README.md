# Analyse Spatiale du Paludisme au Sénégal (2000-2024)

## Description du Projet
Ce projet analyse l'évolution spatio-temporelle du taux d'incidence du paludisme à *Plasmodium falciparum* au Sénégal sur une période de 25 ans (2000-2024).
L'analyse utilise des données géospatiales pour cartographier et comprendre la distribution du paludisme sur le territoire sénégalais.

## Équipe
- **ADDJITA Gérald**
- **GUEBEDIANG Kadidja**
- **TEVOEDJRE Michel**
- **THIOUB Cheikh**

**Classe :** ISE1 CL
**Année académique :** 2025-2026

## Structure du Projet
```
TP1_ADDJITA_GUEBEDIANG_TEVOEDJRE_THIOUB_ISE1_CL_2025_2026/
│
├── data/
│   ├── clippedlayers/              # Couches raster 
│   │   └── 202508_Global_Pf_Incidence_Rate_SEN_YYYY.tiff  # 25 fichiers (2000-2024)
│   │
│   └── gadm/                       # Données administratives du Sénégal
│       └── gadm41_SEN_shp/         # Shapefiles GADM niveau 0-4
│           ├── gadm41_SEN_0.*      # Niveau national
│           ├── gadm41_SEN_1.*      # Niveau régional
│           ├── gadm41_SEN_2.*      # Niveau départemental
│           ├── gadm41_SEN_3.*      # Niveau arrondissement
│           └── gadm41_SEN_4.*      # Niveau communal
│
└── outputs/                        # Résultats de l'analyse
    ├── carte_2010.png              # Carte statique pour l'année 2010
    ├── carte_interactive_2010.html # Carte interactive pour l'année 2010
    ├── comparaison_multi_annees.png # Comparaison entre plusieurs années
    └── evolution_temporelle.png    # Évolution temporelle du paludisme
```

## Données Utilisées
### Données Raster
### Données Vectorielles

## Technologies et Outils
- **R / RStudio** : Environnement de développement principal
- **Principaux packages R utilisés  :**
  - `sf` : Manipulation de données vectorielles
  - `terra` ou `raster` : Manipulation de données raster
  - `tmap` : Création de cartes thématiques
  - `ggplot2` : Visualisations
  - `leaflet` : Cartes interactives
  - `dplyr` : Manipulation de données

## Analyses Réalisées
### 1. Cartographie Statique
- Visualisation du taux d'incidence pour l'année 2010
- Production de cartes thématiques avec légende et échelle

### 2. Cartographie Interactive
- Carte interactive HTML permettant l'exploration des données
- Zoom, pan et affichage d'informations au survol

### 3. Comparaison Multi-Annuelle
- Analyse comparative entre plusieurs années clés
- Identification des zones à forte/faible incidence

### 4. Évolution Temporelle
- Analyse de tendances sur 25 ans (2000-2024)
- Visualisation de l'évolution du paludisme au Sénégal
```
```
### Reproduction des Analyses
1. Ouvrir le projet RStudio (`.Rproj`)
2. Exécuter les scripts dans l'ordre chronologique
3. Les résultats seront générés dans le dossier `outputs/`

## Résultats Principaux
Les analyses ont permis de :
- Cartographier la distribution spatiale du paludisme au Sénégal
- Identifier les zones à forte endémie
- Observer l'évolution temporelle de la maladie
- Comparer les tendances entre différentes régions administratives

## Références
- **GADM :** https://gadm.org/
- **Données sur le paludisme :** https://data.malariaatlas.org/

## Licence
Projet académique.
```
