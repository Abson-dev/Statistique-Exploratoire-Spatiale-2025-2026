# Identification des Terres Arables au Kenya

## Description du Projet

Ce projet analyse et identifie les terres arables disponibles et appropriées au Kenya en combinant plusieurs sources de données géospatiales. L'analyse intègre des critères environnementaux, topographiques et réglementaires pour déterminer les zones adaptées à l'agriculture.

## Équipe

- **DIOP Marème**
- **RIRADJIM Trésor**
- **SECK Mouhamet**
- **TEVOEDJRE Michel**

## Structure du Projet

```
TP4_DIOPMAREME_RIRADJIM_SECK_TEVOEDJRE/
│
├── data/                          
│   ├── Protected_areas/           
│   │   ├── protected_areas_kenya_polygons.shp
│   │   └── protected_areas_kenya_points.shp
│   │
│   ├── Terres_cultivees/          
│   │   ├── GFSAD30AFCE_2015_N00E30_001_2017261090100.tif
│   │   ├── GFSAD30AFCE_2015_N00E40_001_2017261090100.tif
│   │   └── GFSAD30AFCE_2015_S10E30_001_2017261090100.tif
│   │
│   ├── Surfaces_impermeables/     
│   │   ├── KEN_36M_gmis_impervious_surface_percentage_utm_30m.tif
│   │   ├── KEN_36N_gmis_impervious_surface_percentage_utm_30m.tif
│   │   ├── KEN_37M_gmis_impervious_surface_percentage_utm_30m.tif
│   │   └── KEN_37N_gmis_impervious_surface_percentage_utm_30m.tif  
│   │
│   ├── Hansen_forestation/     
│   │   └── Hansen_Loss_2001_2015_Kenya.tif
│   │
│   ├── Eaux_permanentes/     
│   │   └── JRC_PermanentWater_Kenya.tif
│   │   
│   ├── Pente_relief/                   
│   │   └── kenya_slope_le15pct_uint8.tif
│   │
│   └── Gadm/                      
│       ├── gadm41_KEN_0.shp
│       ├── gadm41_KEN_1.shp
│       ├── gadm41_KEN_2.shp
│       └── gadm41_KEN_3.shp
│
├── script.R
│
├── Sauvegarde.RData
│
├── TP4_DIOPMAREME_RIRADJIM_SECK_TEVOEDJRE.Rproj 
│
├── outputs/                       
│
└── README.md
```

## Données Utilisées

### Données Raster

- **GFSAD30 (2015)** : Terres actuellement cultivées à 30m de résolution
- **Hansen Forest Loss (2001-2015)** : Zones de forêt perdues/déboisées
- **JRC Permanent Water** : Eaux permanentes
- **GMIS** : Surfaces imperméables (pourcentage) à 30m de résolution
- **Pente** : Données topographiques de pente

### Données Vectorielles

- **GADM** : Frontières administratives du Kenya (niveaux 0 à 3)
- **WDPA** : Aires protégées (polygones et points)

## Technologies et Outils

- **R / RStudio** : Environnement de développement principal
- **Principaux packages R utilisés :**
  - `sf` : Manipulation de données vectorielles
  - `terra` : Manipulation de données raster
  - `tmap` : Création de cartes thématiques
  - `ggplot2` : Visualisations
  - `dplyr` : Manipulation de données

## Méthodologie

### 1. Détermination du Potentiel Initial

Identification des zones pouvant potentiellement servir de terres arables :
- Zones actuellement cultivées (GFSAD30)
- Zones de forêt perdues/déboisées entre 2001 et 2015 (Hansen Loss)
- Combinaison des deux couches pour former les terres potentielles

### 2. Application des Masques d'Exclusion

Application de critères environnementaux et d'aménagement du territoire :

| Masque | Critère d'Exclusion | Justification |
|--------|---------------------|---------------|
| **Pente** | Pente supérieure à 15% | Prévenir l'érosion et faciliter la culture |
| **Eaux Permanentes** | Zones classées comme Eau Permanente (JRC) | Exclure les plans d'eau non cultivables |
| **Imperméabilité** | Surface imperméable supérieure ou égale à 10% | Exclure les zones fortement urbanisées |
| **Aires Protégées** | Toutes les zones WDPA | Respecter les zones réservées |

### 3. Quantification des Résultats

- Calcul de la superficie totale des terres arables disponibles
- Ventilation par région (GADM Niveau 1)
- Ventilation par comté (GADM Niveau 2)
- Production de tableaux statistiques et de cartes de visualisation

## Résultat Final

Le raster binaire **terres_arables_final** indique l'emplacement des terres arables jugées disponibles et appropriées selon l'ensemble des critères appliqués.

## Reproduction des Analyses

1. Ouvrir le projet RStudio (`.Rproj`)
2. Exécuter le script `script.R`
3. Les résultats seront générés dans le dossier `outputs/`
4. L'environnement peut être sauvegardé dans `Sauvegarde.RData`

## Références

- **GADM**
- **GFSAD30**
- **Hansen Global Forest Change**
- **JRC Global Surface Water**
- **GMIS**
- **WDPA**