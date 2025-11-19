# Projet Analyse Spatiale du Cameroun

## Participants

- AGNANGMA SANAM David Landry
- DIOP Astou
- DIOP Mareme
- NGAKE YAMAHA Herman Parfait

**Encadrant :** M. HEMA

---

## 1. Description générale

Ce projet vise à réaliser une **analyse spatiale du Cameroun** en utilisant diverses sources de données géospatiales. L'objectif principal est de générer des visualisations thématiques, statiques et interactives sur les infrastructures sociales, les localités, les aires protégées, la population, les réseaux d'eau et les reseaux de transport. Les données proviennent essentiellement de **OpenStreetMap (OSM)** et de **Protected Planet**, avec une utilisation complémentaire des shapefiles GADM pour les limites administratives.

Le projet comprend plusieurs scripts R pour le traitement et la visualisation des données ainsi que des applications interactives Shiny. Les analyses permettent de visualiser la distribution des écoles, hôpitaux, grandes villes, etc. et de produire des cartes stratégiques pour la planification et la prise de décision.

---

## 2. Installation et packages nécessaires

### Installation des packages R

```r
install.packages(c("sf", "ggplot2", "dplyr", "tidyr", "tmap", "leaflet", "shiny",
                   "rnaturalearth", "rnaturalearthdata", "ggspatial", "here", "osmextract", "mapview", "units", "nngeo", "webshot2", "plotly", "cowplot", "RColorBrewer"))

```

### Chargement des librairies

```r
library(sf)
library(ggplot2)
library(dplyr)
library(tidyr)
library(tmap)
library(leaflet)
library(shiny)
library(rnaturalearth)
library(rnaturalearthdata)
library(ggspatial)
library(here)
library(osmextract)
library(mapview)
library(units)
library(nngeo)
library(webshot2)
library(plotly)
library(cowplot)
library(RColorBrewer)
```

---

## 3. Structure du projet

```
Projet_Analyse_Spatiale_Cameroun/
│
├── Donnees/
│   ├── shapefiles_limites_administratives_GADM_Cameroun/
│   ├── points_habitables_OSM/
│   ├── equipements_sociaux_OSM/
│   └── protected_area/
│
├── outputs/
│   └── cartes et rapports générés (PNG, HTML, CSV)
│
└── Scripts/
    ├── charger_donnees_osm.R
    ├── visualiser.R
    ├── Visualisation_Grandes_villes.R
    ├── Visualisation_Hopitaux.R
    ├── Visualisation_ecoles_pharmacies.R
    └── tableau_bord_interactif.R
```

---

## 4. Description des scripts

### 4.1 `charger_donnees_osm.R`

**Objectif :**
Charger des données OSM (points habitables et infrastructures sociales) dans R pour traitement et visualisation.

**Données utilisées :**

- Points de peuplement : villes, villages, hameaux, banlieues
- Infrastructures sociales : hôpitaux, cliniques, pharmacies, écoles
- Limites administratives GADM pour l'affichage de fond

**Fonctionnalités :**

- Lecture des fichiers shapefiles
- Création d'une liste `donnees_cameroun` regroupant toutes les couches
- Nettoyage et harmonisation des noms

**Output :**

- Liste `donnees_cameroun` prête pour visualisation

---

### 4.2 `visualiser.R`

**Objectif :**
Produire des cartes thématiques statiques pour chaque couche spatiale.

**Fonctionnalités :**

- Affichage sur fond des limites administratives de niveau 1 (régions)
- Utilisation de `ggplot2` et `tmap` pour générer les cartes
- Distinction des différentes couches avec couleurs et symboles

**Outputs :**

- Cartes PNG enregistrées dans `outputs/`
- Thèmes : écoles, hôpitaux, pharmacies, villages, villes, aires protégées, rivières, voies ferrées

---

### 4.3 `Visualisation_Grandes_villes.R`

**Objectif :**
Visualiser la répartition des grandes villes du Cameroun en statique et en dynamique.

**Données utilisées :**

- Shapefile des villes OSM (`national_capital` et `city`)
- Shapefile des régions GADM

**Fonctionnalités :**

1. **Visualisation statique :**

   - Carte `ggplot2` avec fond des limites régionales
   - Points représentant les grandes villes
   - Affichage du nombre total de grandes villes et source des données

2. **Préparation des données pour la visualisation dynamique :**

   - Projection en coordonnées métriques
   - Comptage du nombre de villes par région
   - Création de pop-ups pour chaque ville et chaque région

3. **Visualisation dynamique :**
   - Carte interactive `tmap` ou `leaflet`
   - Clic sur la région : affiche le nom et le nombre de grandes villes
   - Clic sur une ville : affiche le nom, population, région, nombre de villes dans la région

**Packages utilisés :**
`sf`, `ggplot2`, `tmap`, `dplyr`, `tidyr`

**Outputs :**

- Carte statique (carte_statique_grande_ville.png)
- Carte interactive (carte_grande_ville.html)

---

### 4.4 `Visualisation_Hopitaux.R`

**Objectif :**
Analyser la répartition des hôpitaux et leur accessibilité.

**Données utilisées :**

- Shapefile des hôpitaux OSM
- Limites administratives GADM (niveaux 1 et 3)

**Fonctionnalités :**

1. **Visualisation statique :**

   - Carte avec tampon (buffer de 25km) autour de chaque hôpital

2. **Visualisation dynamique avec Shiny :**
   - Slider pour ajuster la distance des tampons
   - Affichage interactif des hôpitaux et des régions
   - Pop-ups détaillés pour chaque hôpital (nom, arrondissement, département, région, nombre d'hôpitaux dans la région)

**Packages utilisés :**
`sf`, `ggplot2`, `tmap`, `shiny`, `leaflet`, `dplyr`

**Output :**

- Application Shiny interactive permettant d'explorer l'accessibilité aux soins

---

### 4.5 `analyse_ecoles_pharmacies.R`

**Objectif :**
Extraction et visualisation des écoles et pharmacies à partir de fichiers OSM PBF.

**Données utilisées :**

- Fichier OSM Cameroun (PBF)

  **cameroon-251115.osm.pbf** : Fichier binaire OSM contenant les données brutes pour le Cameroun.

  - **Obtention** : Téléchargé depuis un site comme Geofabrik (https://download.geofabrik.de/africa/cameroon.html) ou un miroir OSM. Le script suppose qu'il est placé dans le dossier `data3/`.
    Ce fichier contient des points, lignes et polygones OSM.

**Fonctionnalités :**

- Extraction des couches spécifiques (`school`, `pharmacy`) via `osmextract`
- Filtrage, nettoyage et traitement avec `sf` et `dplyr`
- Création de cartes thématiques des infrastructures
- Combinaison avec les routes et localités pour analyser l'accessibilité

**Outputs :**

- Fichiers GeoPackage des écoles et pharmacies
- Cartes PNG des distributions et visualisations combinées

---

### 4.6 `tableau_bord_interactif.R`

**Objectif :**
Fournir un tableau de bord interactif pour la planification stratégique.

**Données utilisées :**

- Couches OSM : villages, villes, équipements sociaux, voies ferrées
- Aires protégées (Protected Planet)
- Population estimée par type de localité

**Fonctionnalités :**

- Cartes interactives avec `leaflet` et `tmap` : accessibilité aux services, connectivité ferroviaire, potentiel écotouristique, biodiversité
- Indicateurs stratégiques : distances aux hôpitaux et écoles, villages isolés, infrastructures recensées, superficie des aires protégées
- Tableaux et graphiques interactifs

**Output :**

- Fichiers HTML interactifs
- CSV des indicateurs clés
- Cartes thématiques consultables dans un navigateur

---

## 5. Sources des données

- **Limites administratives** : GADM
- **Aires protégées** : Protected Planet
- **Points habitables et infrastructures sociales** : OpenStreetMap (OSM)

**Remarques :**

- Les shapefiles OSM peuvent contenir des incohérences ou des éléments hors frontières nationales.
- L'utilisation de GADM permet d'avoir des limites administratives harmonisées.

---

## 6. Utilisation du projet

1. Définir le répertoire de travail dans RStudio.
2. Installer et charger les packages requis.
3. Charger les données avec `charger_donnees_osm.R`.
4. Lancer les visualisations statiques avec `visualiser.R`.
5. Explorer les grandes villes avec `Visualisation_Grandes_villes.R`.
6. Explorer la couverture sanitaire avec `Visualisation_Hopitaux.R`.
7. Analyser écoles et pharmacies avec `analyse_ecoles_pharmacies.R`.
8. Accéder au tableau de bord interactif via `tableau_bord_interactif.R`.

---
