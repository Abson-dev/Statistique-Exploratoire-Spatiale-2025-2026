

## TP5 - Analyse spatiale et développement urbain durable: cas du RWANDA

---
## Équipe
- **DIOP Astou**
- **GUEBEDIANG Kadidja**
- **RIRADJIM Trésor**
- **TEVOEDJRE Michel**

**Classe :** ISE1 CL  
**Année académique :** 2025-2026

## RÉSUMÉ EXÉCUTIF

Ce projet  présente le développement d'un dashboard web interactif pour l'analyse de l'indicateur LCRPGR (Land Consumption Rate to Population Growth Rate) au Rwanda entre 2015 et 2025. L'outil développé permet une visualisation multi-échelle et une analyse comparative de l'étalement urbain et de la densification à travers différents niveaux administratifs (national, provinces, districts, secteurs).

**Indicateur étudié** : LCRPGR (ODD 11.3.1 - UN-Habitat)  
**Période d'analyse** : 2015-2025  
**Zone d'étude** : République du Rwanda  
**Technologies** : Python, Dash, Plotly, GeoPandas, Rasterio  

---
## Structure du dossier

```
project/
│
├── Script_global.ipynb          
├── README.md                    
│
├── Data/                        
│   ├── rwa_pop_2015_CN_100m_R2025A_v1.tif
│   ├── rwa_pop_2025_CN_100m_R2025A_v1.tif
│   ├── Rwanda_BuiltUp_2015.tif
│   ├── Rwanda_BuiltUp_2025.tif
│   ├── gadm41_RWA_1.shp        
│   ├── gadm41_RWA_2.shp        
│   └── gadm41_RWA_3.shp        
│
├── Output/                     
    
```
**NB :**

- Le dossier **data** qui contient l'ensemble des données que nous avons utilisé pour nos analyses.
- Ce dossier est contenu dans un drive (le lien est le suivant : **https://drive.google.com/drive/folders/1QpaAfoaHITds5T_ced6_O-f7Id8oV3i3?usp=drive_link**) du fait de sa taille, qui excède la limite de GitHub. Cependant, vous pouvez les télécharger et les mettre dans le dossier pour exécuter les codes.
---


## TABLE DES MATIÈRES

1. [Introduction et Contexte](#1-introduction-et-contexte)
2. [Objectifs du Projet](#2-objectifs-du-projet)
3. [Cadre Théorique](#3-cadre-théorique)
4. [Méthodologie](#4-méthodologie)
5. [Architecture Technique](#5-architecture-technique)
6. [Données et Sources](#6-données-et-sources)
7. [Implémentation](#7-implémentation)
8. [Résultats et Analyses](#8-résultats-et-analyses)
9. [Guide d'Installation](#9-guide-dinstallation)
10. [Guide d'Utilisation](#10-guide-dutilisation)
11. [Limitations et Perspectives](#11-limitations-et-perspectives)
12. [Contributions des Membres](#12-contributions-des-membres)
13. [Références Bibliographiques](#13-références-bibliographiques)
14. [Annexes](#14-annexes)

---

## 1. INTRODUCTION ET CONTEXTE

### 1.1 Contexte général

L'urbanisation rapide en Afrique subsaharienne pose des défis majeurs en matière d'aménagement du territoire et de développement durable. Le Rwanda, avec un taux de croissance urbaine parmi les plus élevés d'Afrique de l'Est, nécessite une surveillance continue de son expansion urbaine pour garantir un développement harmonieux et durable.

### 1.2 Problématique

Comment mesurer et visualiser efficacement la relation entre la croissance démographique et l'expansion spatiale des zones urbaines au Rwanda ? Comment identifier les zones d'étalement urbain excessif ou de densification intense nécessitant des interventions en matière de planification urbaine ?

### 1.3 Pertinence académique

Ce projet s'inscrit dans le cadre des Objectifs de Développement Durable (ODD), particulièrement l'ODD 11.3.1 qui vise à "renforcer l'urbanisation durable pour tous". Le LCRPGR est l'indicateur officiel recommandé par UN-Habitat pour mesurer cet objectif.

---

## 2. OBJECTIFS DU PROJET

### 2.1 Objectif principal

Développer un outil interactif de visualisation et d'analyse du LCRPGR permettant d'évaluer les dynamiques d'urbanisation au Rwanda à différentes échelles administratives.

### 2.2 Objectifs spécifiques

1. **Calculer le LCRPGR** pour le Rwanda aux niveaux national, provincial, district et sectoriel
2. **Développer un dashboard web interactif** permettant la visualisation dynamique des résultats
3. **Identifier les zones critiques** d'étalement urbain ou de densification excessive
4. **Comparer les performances** entre différentes entités administratives
5. **Fournir un outil d'aide à la décision** pour les planificateurs urbains
6. **Démontrer la maîtrise** des techniques de traitement de données géospatiales et de développement web

---

## 3. CADRE THÉORIQUE

### 3.1 Le concept de LCRPGR

Le **Land Consumption Rate to Population Growth Rate (LCRPGR)** est défini comme le ratio entre le taux de croissance de l'occupation des terres urbaines et le taux de croissance de la population.

**Formule mathématique** :

```
LCRPGR = LCR / PGR

où :
LCR = [(Urbt+n-Urbt) / Urbt)) / n] × 100
PGR = [(Ln(Popt+n / Popt)) / n] × 100

Ln = Logarithme neperien
Urbt = Surface urbaine à l'année t (km²)
Popt = Population à l'année t
n = Nombre d'années
```

### 3.2 Interprétation du LCRPGR

| Valeur LCRPGR | Interprétation | Implications urbaines |
|---------------|----------------|----------------------|
| **< 1** | Densification | La population croît plus rapidement que l'espace urbain. Urbanisation verticale, augmentation de la densité. |
| **= 1** | Équilibre | Croissance proportionnelle entre population et espace urbain. |
| **> 1** | Étalement urbain | L'espace urbain s'étend plus rapidement que la population. Urbanisation horizontale, faible densité. |

### 3.3 Cadre de référence : ODD 11.3.1

L'indicateur 11.3.1 des ODD mesure : "Ratio entre le taux de consommation des terres et le taux de croissance démographique". UN-Habitat préconise un LCRPGR proche de 1 pour un développement urbain durable.

### 3.4 État de l'art

Des études similaires ont été menées dans plusieurs pays africains (Éthiopie, Kenya, Tanzanie) montrant des LCRPGR variant de 0.8 à 2.5 selon les régions. Les recherches antérieures ont démontré l'importance d'une analyse multi-échelle pour comprendre les dynamiques locales.

---

## 4. MÉTHODOLOGIE

### 4.1 Approche générale

Notre méthodologie suit une approche en quatre phases :

1. **Acquisition et prétraitement des données** géospatiales
2. **Calcul des indicateurs** (taux de croissance, LCRPGR)
3. **Agrégation spatiale** par entités administratives
4. **Développement du dashboard** de visualisation

### 4.2 Traitement des données raster

#### 4.2.1 Extraction spatiale

Les données raster mondiales ont été extraites pour la zone d'étude du Rwanda en utilisant les limites administratives officielles.

```python
from rasterio.mask import mask

# Extraction par masque géographique
data_masked, transform = mask(raster, geometries, crop=True)
```

#### 4.2.2 Nettoyage des données

Les valeurs NoData (-99999) ont été systématiquement remplacées par NaN pour éviter les biais dans les calculs statistiques.

```python
data_clean = data.astype(float)
data_clean[data_clean == -99999.0] = np.nan
data_clean[data_clean < 0] = np.nan
```


### 4.3 Calculs statistiques

#### 4.3.1 Taux de croissance démographique annuel

Utilisation de la méthode du taux de croissance exponentiel :

```python
T = 10  # années
pop_growth_rate = (np.log(pop_2025 / pop_2015) / T) * 100
```

#### 4.3.2 Taux de croissance de la surface bâtie

Calcul du taux de croissance linéaire annualisé :

```python
urban_growth_rate = ((built_2025 - built_2015) / built_2015 / T) * 100
```

#### 4.3.3 Calcul du LCRPGR

```python
LCRPGR = urban_growth_rate / pop_growth_rate
```

### 4.4 Agrégation par entités administratives

Pour chaque province, district et secteur :

1. Extraction des pixels contenus dans la géométrie
2. Calcul de la somme des populations
3. Calcul de la médiane du LCRPGR
4. Calcul de la densité de population

```python
from rasterio.features import geometry_mask

mask_array = ~geometry_mask([geometry], transform, shape)
stats = {
    'population': np.nansum(pop_data[mask_array]),
    'lcrpgr': np.nanmedian(lcrpgr_data[mask_array]),
    'density': population / area_km2
}
```

---

## 5. ARCHITECTURE TECHNIQUE

### 5.1 Stack technologique

Le projet utilise une architecture web basée sur Python avec les composants suivants :

**Backend et traitement de données** :
- Python 3.9+ (langage principal)
- NumPy 1.24+ (calculs numériques)
- Pandas 2.0+ (manipulation de données tabulaires)
- GeoPandas 0.14+ (données géospatiales vectorielles)
- Rasterio 1.3+ (données géospatiales raster)
- Shapely 2.0+ (opérations géométriques)

**Frontend et visualisation** :
- Dash 2.14+ (framework web interactif)
- Plotly 5.18+ (graphiques interactifs)
- HTML/CSS (mise en forme)


### 5. Modèle de données

#### 5.2 Données raster

**Format** : GeoTIFF  
**Projection** : EPSG:4326 (WGS84)  
**Structure** :

```
Raster {
    width: integer
    height: integer
    transform: Affine transformation matrix
    crs: Coordinate Reference System
    nodata: float
    data: numpy.ndarray[height, width]
}
```

#### 5.3.2 Données vectorielles

**Format** : Shapefile  
**Projection** : EPSG:4326  
**Attributs GADM** :

```
Administrative Unit {
    GID_0: Country code (RWA)
    NAME_0: Country name (Rwanda)
    GID_1/2/3: Administrative unit codes
    NAME_1/2/3: Administrative unit names
    geometry: Polygon/MultiPolygon
}
```

### 5.4 Flux de données

```
Input Data → Preprocessing → Computation → Aggregation → Visualization

1. Rasters (TIF) ──┐
2. Shapefiles ─────┼→ Cleaning → LCRPGR Calc → Stats by Admin → Dashboard
3. Parameters ─────┘
```

---

## 6. DONNÉES ET SOURCES

### 6.1 Données démographiques

**Source** : WorldPop / LandScan Global  
**Type** : Raster de population  
**Résolution spatiale** : 3 arc-secondes (~90 mètres à l'équateur)  
**Résolution temporelle** : 2015, 2025  
**Unité** : Nombre d'habitants par pixel  
**Format** : GeoTIFF  
**Système de projection** : EPSG:4326 (WGS84)  

**Méthodologie de production** : Désagrégation spatiale de données de recensement combinée à des données d'occupation du sol, d'imagerie satellite et de bâtiments.

### 6.2 Données de surface bâtie

**Source** : Global Human Settlement Layer (GHSL) / World Settlement Footprint (WSF)  
**Type** : Raster d'occupation du sol bâti  
**Résolution spatiale** : 30 arc-secondes (~1 kilomètre)  
**Résolution temporelle** : 2015, 2025  
**Unité** : Surface bâtie en m² ou pourcentage par pixel  
**Format** : GeoTIFF  
**Système de projection** : EPSG:4326  

**Méthodologie de production** : Classification d'images Landsat combinée à des algorithmes de machine learning pour détecter les zones bâties.

### 6.3 Limites administratives

**Source** : GADM (Database of Global Administrative Areas) version 4.1  
**Niveaux disponibles** :
- **Niveau 0** : Frontières nationales (Rwanda)
- **Niveau 1** : Provinces (5 entités)
- **Niveau 2** : Districts (30 entités)
- **Niveau 3** : Secteurs (416 entités)

**Format** : Shapefile (.shp, .shx, .dbf, .prj)  
**Système de projection** : EPSG:4326  
**URL de téléchargement** : https://gadm.org/download_country.html

**Attributs clés** :
- NAME_1 : Nom de la province
- NAME_2 : Nom du district
- NAME_3 : Nom du secteur

### 6.4 Validation et qualité des données

#### 6.4.1 Contrôles de qualité effectués

1. **Vérification de la cohérence spatiale** : Superposition des différentes couches
2. **Validation des valeurs** : Détection des valeurs aberrantes
3. **Complétude** : Vérification de l'absence de données manquantes
4. **Précision géométrique** : Validation des limites administratives

#### 6.4.2 Limitations identifiées

- Décalage temporel entre données de population et de surface bâtie
- Incertitudes dans les projections 2025
- Résolutions spatiales différentes entre les datasets

---

## 7. IMPLÉMENTATION


### 7.1 Fonctionnalités du dashboard

#### 7.1.1 Interface utilisateur

**Composants principaux** :

1. **En-tête** : Titre et description du projet
2. **KPIs** : 4 cartes statistiques (population, surface bâtie, LCRPGR, densité)
3. **Contrôles** : Dropdowns pour niveau administratif, indicateur, filtrage
4. **Carte interactive** : Visualisation spatiale principale
5. **Panneau d'information** : Détails au survol
6. **Graphiques analytiques** : Top 10, scatter plot, histogramme, évolution temporelle
7. **Tableau de données** : Vue tabulaire avec tri et filtrage

#### 7.1.2 Interactivité

**Callbacks Dash implémentés** :

- `update_entity_options()` : Met à jour la liste des entités selon le niveau
- `update_main_map()` : Rafraîchit la carte selon les sélections
- `display_hover_info()` : Affiche les informations au survol
- `update_ranking()` : Génère le classement Top 10
- `update_scatter()` : Crée le scatter plot LCRPGR vs croissance
- `update_table()` : Actualise le tableau de données
- `update_histogram()` : Met à jour la distribution du LCRPGR
- `update_evolution()` : Trace l'évolution temporelle

#### 7.1.3 Visualisations

**Types de graphiques** :

1. **Heatmap** : Pour la vue nationale (raster)
2. **Choroplèthe** : Pour les vues administratives
3. **Bar chart** : Pour les classements Top 10
4. **Scatter plot** : Pour les analyses de corrélation
5. **Histogram** : Pour les distributions statistiques
6. **Line chart** : Pour les évolutions temporelles

---





