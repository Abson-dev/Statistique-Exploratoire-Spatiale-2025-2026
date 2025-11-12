# Projet Google Earth Engine : Analyse spatiale du paludisme et de la population au Cameroun

## IMPORTANT

Il est utile de noter qu'il faut pour execution importer l'ensemble des données sur Google Earth Engine, puis modifier les différents chemins d'accès pour tous les fichiers js.

## 1. Description du projet

Ce projet constitue un travail pratique d'initiation à Google Earth Engine (GEE) avec JavaScript, réalisé dans le cadre du cours de Statistiques Exploratoire et Spatiale. Il vise à importer, manipuler et visualiser des données rasters et vectorielles pour analyser la distribution spatiale et temporelle de phénomènes (paludisme et population). L'étude est réalisée pour le Cameroun.

### Équipe de réalisation :

- AGNANGMA SANAM David Landry
- DIOP Astou
- DIOP Mareme
- NGAKE YAMAHA Herman Parfait

**Encadrant :** M. HEMA

## 1. Les sources des données

- Les données de paludisme proviennent du Malaria Atlas Project.
- Les shapefiles sont téléchargés via GADM.
- Les données sur la population sont prises sur WorldPop.

### Télécharger les données :

#### Shapefile (GADM) :


Pour ce faire, cliquer sur le lien [GADM](https://gadm.org/) ou alors taper « GADM » sur votre moteur de recherche et cliquer sur le premier lien de site qui apparait. Dans la page d'accueil qui se présente, cliquer sur « DATA ». Dans la page qui va suivre, cliquer sur country qui se trouve à la fin de la phrase : « You can download the spatial data by country. » pour télécharger le shapefile du pays que vous souhaitez. Dans la liste déroulante qui va se présenter dans la page qui va suivre, choisissez le pays dont vous souhaitez avoir le shapefile. Ensuite, cliquer sur « shapefile » et vous téléchargerez le fichier zippé contenant tout le nécessaire.

#### Raster (World Pop) récent :

Pour ce faire, cliquer sur le lien [WorldPop](https://www.worldpop.org/) ou alors taper « worldpop » sur votre moteur de recherche et cliquer sur le premier lien du site qui apparait. Dans la page d'accueil qui se présente, pointer sur « DATA » et cliquer sur « ADMINISTRATIVE AREAS ». Ensuite choisissez successivement le type de données que vous voulez et le pays qui vous intéresse. Appuyer enfin sur « Data and Resources », puis sur « Doawload Entire Dataset » et vous téléchargerez le fichier zippé contenant tout le nécessaire.

#### Malaria (2000-2021) :

Pour ce faire, cliquer sur le lien [MAP – Malaria Atlas Project](https://data.malariaatlas.org/maps?layers=Malaria) ou alors taper « malaria atlas project » sur votre moteur de recherche et cliquer sur le premier lien du site qui apparait. Dans la page qui se présente, vous aurez une vue globale sur un ensemble de données chronologiques téléchargeables. 

Navigation dans l'interface :

Une fois sur la page, vous verrez une carte mondiale interactive
Sur le côté gauche, localisez le panneau de sélection des couches ("Layers")
Développez la section "Malaria" pour voir les indicateurs disponibles

Sélection des données :

Choisissez l'indicateur souhaité (ex: PfPR₂₋₁₀ - Prévalence du parasite)
Sélectionnez la période temporelle (2000-2021)
Zoomez sur la région d'intérêt ou utilisez la recherche par pays

Téléchargement :

Cliquez sur l'icône de téléchargement
Sélectionnez le format souhaité (GeoTIFF, CSV, etc.)
Choisissez l'échelle géographique :
Données nationales (par pays)
Données subnationales (première subdivision administrative)
Définissez la période temporelle exacte

Lancez le téléchargement


## 2. Structure du projet

```
TP1_SES_2025_2026_ASTOU_MAREME_LANDRY_YAMAHA/
│
├── Données/
│   ├── shapefiles_limites_administratives_GADM_Cameroun/
│   ├── rasters_malaria_2000_2021_Cameroun/
│   └── worldpop_cameroun/
│
├── sorties/
│
└── Scripts/
    ├── Application1.js
    ├── Application2.js
    ├── Application3.js
    └── Propriété.js
```

### 2.1 Script de propriétés (Proprietes.js)

Ce script d'exploration affiche les caractéristiques des données utilisées dans le projet.

**Fonctionnalités :**

- Chargement et inspection des shapefiles GADM (niveaux 0 à 3) du Cameroun
- Affichage des métadonnées des données rasters
- Calcul des dimensions spatiales (superficie, périmètre, centroïde)
- Détermination du système de projection, de la résolution, du nombre de pixels pour les rasters

**Données utilisées :**

- gadm41_CMR_0 à gadm41_CMR_3 : Limites administratives du Cameroun
- cmr_level0_100m_2000_2020 : Raster de données paludisme
- Raster WorldPop

### 2.2 Application1.js

Interface interactive permettant de visualiser et d'identifier les différents niveaux administratifs du Cameroun.

**Fonctionnalités :**

- Affichage des contours des 10 régions, 58 départements et 360 arrondissements
- Contrôles de visibilité pour chaque niveau administratif
- Système d'identification au clic affichant le nom de la région, du département ou de l'arrondissement
- Légende de couleurs pour différencier les niveaux

**Données utilisées :**

- gadm41_CMR_1 : Régions
- gadm41_CMR_2 : Départements
- gadm41_CMR_3 : Arrondissements

### 2.3 Application2.js

Visualisation temporelle du taux de parasites Plasmodium falciparum (Pf) chez les enfants de 2 à 10 ans au Cameroun.

**Fonctionnalités :**

- Slider temporel pour explorer les années 2000 à 2024
- Affichage des statistiques nationales (moyenne, minimum, maximum régional)
- Classement des régions par taux de prévalence
- Bouton de lecture automatique pour animation temporelle
- Palette de couleurs dégradée pour visualiser l'intensité

**Données utilisées :**

- 202508_Global_Pf_Parasite_Rate_CMR_YYYY : Rasters annuels de prévalence Pf (2000-2024)
- gadm41_CMR_1 : Régions pour les calculs statistiques
- Taux nationaux officiels intégrés dans le code

### 2.4 Application3.js

Affichage interactif combinant données de population et de paludisme.

**Fonctionnalités :**

- Visualisation simultanée de la densité de population (WorldPop 2020)
- Couche de paludisme avec sélection d'année (2000-2021)
- Superposition des limites administratives (pays, régions, départements, arrondissements)
- Slider interactif pour changer l'année de paludisme
- Légendes distinctes pour population et paludisme

**Données utilisées :**

- Shapefiles : pays, régions, départements, arrondissements du Cameroun
- tiff_Worldpop : Densité de population 2020
- 202508_Global_Pf_Incidence_Count_CMR_YYYY : Incidence paludisme (2000-2021)

## 4. Utilisation

1. Ouvrir Google Earth Engine Code Editor (https://code.earthengine.google.com/)
2. Copier le contenu d'un script dans l'éditeur
3. S'assurer d'avoir accès aux assets du projet (projects/formationgee/assets/ ou projects/initiation-476717/assets/)
4. Exécuter le script avec le bouton 'Run'
5. Interagir avec l'interface dans le panneau de carte

## 6. Objectifs pédagogiques atteints

✓ Chargement et manipulation de FeatureCollections (vecteurs)
✓ Importation et visualisation d'Images (rasters)
✓ Création d'interfaces utilisateur interactives avec GEE
✓ Calculs de statistiques zonales (reduceRegions)


## Limites du projet

Les principales difficultés rencontrées sont relatives à l'export des données sous les différents formats, notamment HTML pour les cartes interactives depuis GEE. C'est ce qui explique d'ailleurs le fait que le dossier "outputs" de l'arborescence du projet soit vide. Il est également utile de préciser ici qu'il n'est pas possible avec GEE de rendre les chemins d'accès dynamiques pour des utilisations ultérieures depuis d'autres appareils. L'utilisateur doit donc importer les données disponibles dans le dossier "Data" sur GEE puis modifier les chemins d'accès manuellement.
