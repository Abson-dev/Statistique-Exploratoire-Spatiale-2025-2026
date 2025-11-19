# Cartographie Administrative de l'Angola

## Description du projet

Ce projet réalise une analyse cartographique complète de la structure administrative de l'Angola en utilisant R. L'Angola (AGO_0) est subdivisé en **18 provinces** (AGO_1), elles-mêmes divisées en **163 municipalités** (AGO_2) et **527 communes** (AGO_3).

Le projet permet d'importer, manipuler et visualiser les données géospatiales à différents niveaux administratifs à travers des cartes statiques et interactives.

## Structure du projet

```
projet-angola/
│
├── data/                          # Dossier contenant les fichiers shapefile
│   ├── gadm41_AGO_0.shp          # Niveau national
│   ├── gadm41_AGO_1.shp          # Provinces
│   ├── gadm41_AGO_2.shp          # Municipalités
│   └── gadm41_AGO_3.shp          # Communes
│
├── outputs/                       # Dossier pour les cartes générées
│   ├── angola_map.png
│   ├── angola_provinces_map.png
│   ├── angola_municipalités_map.png
│   ├── angola_communes_map.png
│   └── carte_angola_interactive.html
│
└── script.R                       # Script principal
```

## Packages R utilisés

### Installation des bibliothèques

```r
install.packages("stars")        # Manipulation des données raster et vecteur
install.packages("sf")           # Manipulation des objets géospatiaux
install.packages("ggplot2")      # Visualisations graphiques
install.packages("ggspatial")    # Éléments cartographiques (flèche nord, échelle)
install.packages("raster")       # Manipulation des données raster
install.packages("cowplot")      # Extraction de légende et affichage
install.packages("leaflet")      # Cartes interactives
install.packages("viridis")      # Palette de couleurs
install.packages("RColorBrewer") # Palettes de couleurs supplémentaires
install.packages("dplyr")        # Manipulation de données
install.packages("here")         # Gestion des chemins de fichiers
install.packages("htmlwidgets")  # Sauvegarde des cartes interactives
```

## Fonctionnalités principales

### 1. Importation des données géospatiales

Le projet utilise la fonction `st_read()` du package **sf** pour importer les fichiers shapefile :

```r
angola <- st_read(here("data", "gadm41_AGO_0.shp"))        # Niveau national
region_ang <- st_read(here("data", "gadm41_AGO_1.shp"))   # 18 Provinces
province_ang <- st_read(here("data", "gadm41_AGO_2.shp")) # 163 Municipalités
commune_ang <- st_read(here("data", "gadm41_AGO_3.shp"))  # 527 Communes
```

### 2. Exploration des données

Le script fournit des informations détaillées sur chaque niveau administratif :

- Nombre d'entités (pays, provinces, municipalités, communes)
- Noms des colonnes (variables)
- Aperçu des données clés
- Vérification des valeurs uniques

### 3. Visualisation statique

Création de cartes statiques avec **ggplot2** et **ggspatial** :

- **Carte nationale** : Contour de l'Angola
- **Carte des provinces** : 18 provinces avec palette Viridis et étiquettes
- **Carte des municipalités** : 163 municipalités avec contours provinciaux
- **Carte des communes** : 527 communes avec superposition des provinces

Chaque carte inclut :

- Flèche du Nord (style orienteering)
- Échelle graphique
- Titre centré et mis en forme
- Export PNG haute résolution (300 dpi)

### 4. Visualisation interactive

Création d'une carte interactive avec **Leaflet** permettant de :

- Basculer entre les trois niveaux administratifs
- Afficher des informations au survol (popups)
- Zoomer et naviguer librement
- Utiliser différentes palettes de couleurs par niveau

La carte est sauvegardée en format HTML avec `htmlwidgets::saveWidget()`.

## Utilisation

### Prérequis

- R version 4.0 ou supérieure
- RStudio (recommandé)
- Fichiers shapefile GADM pour l'Angola

### Exécution

1. Cloner ou télécharger le projet
2. Placer les fichiers shapefile dans le dossier `data/`
3. Créer un dossier `outputs/` à la racine
4. Ouvrir le script dans RStudio
5. Exécuter le script complet

### Résultats

Le script génère :

- 4 cartes statiques PNG dans `outputs/`
- 1 carte interactive HTML dans `outputs/`
- Des informations statistiques affichées dans la console

## Bibliothèques clés et leurs rôles

| Package       | Utilisation principale                                         |
| ------------- | -------------------------------------------------------------- |
| **sf**        | Import et manipulation de données vectorielles (shapefiles)    |
| **ggplot2**   | Création de cartes statiques avec syntaxe layered grammar      |
| **ggspatial** | Ajout d'éléments cartographiques (nord, échelle)               |
| **leaflet**   | Création de cartes interactives web                            |
| **dplyr**     | Manipulation et transformation de données                      |
| **viridis**   | Palettes de couleurs accessibles et perceptuellement uniformes |
| **here**      | Gestion robuste des chemins de fichiers relatifs               |

## Auteur

Projet académique - Travaux pratiques de cartographie avec R

## Source des données

Données administratives GADM (Global Administrative Areas)

- Version : GADM 4.1
- Pays : Angola (AGO)
- Niveaux : 0 (national), 1 (provinces), 2 (municipalités), 3 (communes)

---
