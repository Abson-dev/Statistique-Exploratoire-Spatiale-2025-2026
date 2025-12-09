# TP5 – Calcul de l'Indicateur ODD 11.3.1 pour la RDC
## Ratio du taux de consommation des terres au taux de croissance démographique (2017-2020)

## Description du Projet
Ce TP5 vise à calculer l'indicateur ODD 11.3.1 pour la République Démocratique du Congo selon la méthodologie DEGURBA stricte des Nations Unies. L'objectif est d'évaluer l'efficacité de la croissance urbaine en comparant le taux de consommation des terres (expansion spatiale) au taux de croissance démographique sur la période 2017-2020.

## Équipe
- **Math SOCE**
  - **Cheikh Ahmadou Bamba FALL**
  - **Cheikh Mouhamadou Moustapha NDIAYE**
  - **Joe Young Veridique Gabriel DIOP**
  
  **Classe :** ISE1 CL
**Année académique :** 2025-2026

## Structure du Projet
```
TP5_RDC_ODD_1131_DEGURBA/
  │
├── data/
  │   ├── population/                     # Données démographiques WorldPop
  │   │   ├── rdc_pop_2017_1km.tif       # Population 2017 - résolution 1km
│   │   └── rdc_pop_2020_1km.tif       # Population 2020 - résolution 1km
│   │
│   ├── lulc/                           # Occupation du sol (Land Use/Land Cover)
  │   │   ├── ESA_2020_S06E015.tif       # Tuile ESA WorldCover Kinshasa 2020
│   │   ├── ESA_2020_S12E027.tif       # Tuile ESA WorldCover Lubumbashi 2020
│   │   ├── ESA_2020_S09E024.tif       # Tuile ESA WorldCover Mbuji-Mayi 2020
│   │   ├── ESA_2020_S06E021.tif       # Tuile ESA WorldCover Kananga 2020
│   │   └── ESA_2020_N00E024.tif       # Tuile ESA WorldCover Kisangani 2020
│   │
│   ├── boundaries/                     # Limites administratives de la RDC
  │   │   ├── rdc_country.shp            # Limite nationale
│   │   └── rdc_provinces.shp          # Limites provinciales
│   │
│   ├── urban_areas/                    # Zones urbaines définies
  │   │   └── zones_urbaines_rdc.shp     # Polygones des principales villes
│   │
│   └── temp/                           # Fichiers temporaires
  │
├── script/
  │   ├── code_complet.r                  # Script principal d'analyse complète
│   └── méthodologie_complete.r        # Guide détaillé méthodologique
│
├── output/
  │   ├── rasters/                        # Rasters intermédiaires générés
  │   │   ├── densite_population_2017.tif
│   │   ├── densite_population_2020.tif
│   │   ├── cellules_haute_densite_2017.tif
│   │   ├── cellules_haute_densite_2020.tif
│   │   ├── grappes_urbaines_2017.tif
│   │   ├── grappes_urbaines_2020.tif
│   │   ├── zones_urbaines_degurba_2017.tif
│   │   ├── zones_urbaines_degurba_2020.tif
│   │   ├── lulc_2017_1km.tif
│   │   └── lulc_2020_1km.tif
│   │
│   ├── degurba/                        # Résultats classification DEGURBA
  │   │   ├── classification_grappes_2017.csv
│   │   ├── classification_grappes_2020.csv
│   │   ├── odd_11_3_1_par_centre.csv
│   │   └── resume_odd_11_3_1.csv
│   │
│   └── resultats_finaux/               # Résultats agrégés
  │       ├── population_2017_par_zone.csv
│       ├── population_2020_par_zone.csv
│       ├── surfaces_baties_par_zone.csv
│       └── resultats_odd_1131_complets.csv
│
└── figures/
  ├── cartes/                         # Cartes thématiques
  │   ├── densite_2017.png
│   ├── densite_2020.png
│   ├── centres_urbains_2017.png
│   ├── centres_urbains_2020.png
│   ├── comparaison_urbain_2017_2020.png
│   └── comparaison_cote_a_cote.png
│
└── graphiques/                     # Graphiques statistiques
  ├── evolution_surface_urbaine.png
└── evolution_population_urbaine.png
```

## Données Utilisées
### Données Raster
**WorldPop (2017-2020) – Population**
  - Résolution 1 km × 1 km
- Valeurs : nombre de personnes par pixel
- Ajustées aux estimations démographiques des Nations Unies

**ESA WorldCover (2020) – Occupation du sol**
  - Résolution 10 m × 10 m
- Classes : zones bâties (classe 50), végétation, eau, etc.
- Couverture : tuiles sélectionnées pour les principales zones urbaines

### Données Vectorielles
**Limites administratives :**
  - Limite nationale de la RDC (GADM)
- Limites provinciales (26 provinces)

**Zones urbaines :**
  - Délimitation des principales villes selon critères DEGURBA
- Polygones centrés sur les villes principales avec buffers adaptés

## Technologies et Outils
 **R avec packages spécialisés :**
  - `terra` : traitement des données raster
- `sf` : manipulation des données vectorielles
- `tidyverse` : manipulation et analyse des données
- `exactextractr` : statistiques zonales précises
- `ggplot2` : visualisation cartographique

 **Méthodologie appliquée :**
  - DEGURBA (Degree of Urbanisation) stricte
- Calcul ODD 11.3.1 conforme aux spécifications ONU-Habitat
- Reprojection UTM pour des calculs métriques précis

 **Export des résultats :**
  - Cartes thématiques en PNG haute résolution
- Tableaux de résultats en CSV et Excel
- Rasters intermédiaires en format GeoTIFF

## Tâches Réalisées
### 1. Classification DEGURBA des zones urbaines
- Calcul de la densité de population à 1 km²
- Identification des cellules ≥1500 hab/km²
- Formation de grappes contiguës de cellules denses
- Classification selon la population des grappes :
  - **Centres urbains** : grappes ≥50,000 habitants
- **Grappes urbaines** : grappes ≥5,000 habitants
- **Zones rurales** : population <5,000 habitants

### 2. Calcul des surfaces bâties
- Chargement et mosaïquage des données LULC haute résolution
- Ré-échantillonnage à la résolution 1 km pour cohérence
- Extraction des zones bâties (classe Built-up)
- Calcul de la surface totale bâtie par zone urbaine

### 3. Calcul de l'indicateur ODD 11.3.1
**Formules appliquées :**
  - **LCR (Land Consumption Rate)** = [Ln(Surface_t1 / Surface_t0) / y] × 100
- **PGR (Population Growth Rate)** = [Ln(Population_t1 / Population_t0) / y] × 100
- **LCRPGR (ODD 11.3.1)** = LCR / PGR

**Interprétation des résultats :**
  - **LCRPGR < 1** : Croissance efficace (densification)
- **LCRPGR = 1** : Croissance proportionnelle
- **LCRPGR > 1** : Étalement urbain (inefficace)

### 4. Cartographie et visualisation
- Cartes de densité de population (2017 et 2020)
- Cartes des centres urbains DEGURBA
- Cartes comparatives d'évolution urbaine
- Graphiques statistiques d'évolution des surfaces et populations

## Résultats Principaux
Les résultats complets sont disponibles dans les fichiers CSV du dossier `output/resultats_finaux/` :
  - `population_2017_par_zone.csv` : Population par ville en 2017
- `population_2020_par_zone.csv` : Population par ville en 2020
- `surfaces_baties_par_zone.csv` : Surfaces bâties par ville
- `resultats_odd_1131_complets.csv` : Valeurs LCR, PGR et LCRPGR pour chaque ville

## Références
- **ONU-Habitat** : [SDG Indicator 11.3.1 Guidelines](https://unhabitat.org/sdg-indicator-1131-training-module)
- **WorldPop** : [https://www.worldpop.org/](https://www.worldpop.org/)
- **ESA WorldCover** : [https://worldcover2020.esa.int/](https://worldcover2020.esa.int/)
- **GADM** : [https://gadm.org/](https://gadm.org/)
- **DEGURBA Methodology** : [Eurostat Degree of Urbanisation](https://ec.europa.eu/eurostat/web/degree-of-urbanisation)

## Licence
Projet académique réalisé dans le cadre du cours de Statistique Spatiale à l'ENSAE-ISEP. Les données utilisées sont sous licences ouvertes (WorldPop, ESA, GADM).