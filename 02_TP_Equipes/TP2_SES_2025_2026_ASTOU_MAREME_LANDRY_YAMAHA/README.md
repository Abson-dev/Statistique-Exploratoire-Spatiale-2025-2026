# TP2 d'analyse spatiale du Cameroun

## Membres de l'équipe : 
- AGNANGMA SANAM David Landry
- DIOP Astou
- DIOP Mareme
- NGAKE YAMAHA Herman Parfait

**Superviseur :** M. HEMA

**Année académique : 2025 - 2026**

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
TP2_SES_2025_2026_ASTOU_MAREME_LANDRY_YAMAHA/
│
│
├── scripts/
│    ├── script1.R
│    ├── script2.R
│    ├── visualisation_Aires protégées.R
│    ├── Visualisation_Grandes_villes.R
│    ├── Visualisation_Hopitaux.R
│    ├── Visualisation_Fleuves et rivières.R
│    ├── Visualisation_Cours d'eau.R
│    └── tableau_bord_interactif.R
│   
│─── main.R
│
│─── TP1_SES_2025_2026_ASTOU_MAREME_LANDRY_YAMAHA.Rproj
│
│─── README.md
```

**NB :**

- **TP1_SES_2025_2026_ASTOU_MAREME_LANDRY_YAMAHA.Rproj** est le projet R que nous avons créé pour l'ensemble des travaux de notre équipe.
- Le dossier **outputs** contient l'ensemble de nos cartes statiques et dynamiques, un tableau de bord et un fichier csv récapitulant l'ensemble de nos analyses.
- Le dossier **data** qui contient l'ensemble des données que nous avons utilisé pour nos analyses.
- Ces deux dossiers sont contenus dans un drive dont le lien est le suivant : https://drive.google.com/drive/my-drive), du fait de leur taille, qui excède la limite de GitHub. Cependant, vous pouvez les télécharger et les mettre dans le dossier **TP1_SES_2025_2026_ASTOU_MAREME_LANDRY_YAMAHA** pour exécuter les codes.
---

## 4. Description des scripts


### 4.1 `main.R` 

**Objectif :** 
Importer et charger l'ensemble des packages nécessaires, définir le répertoire de travail et exécuter les autres scripts : c'est le script principal.

### 4.2 `Visualisation_Cours d'eau.R` 

**Objectif :**
Visualiser les lignes des cours d'eau secondaires et des ruisseaux pour évaluer la densité du réseau hydrographique local.

**Données utilisées :**

- Shapefile des Cours d'eau (lignes) OSM, filtré pour les classes secondaires (stream, drain, canal de petite taille).

- Shapefile des régions GADM.

**Fonctionnalités :**

**Visualisation statique :**

- Carte tmap avec fond des limites régionales.

- Représentation des lignes en couleur bleue, avec une épaisseur fine pour distinguer les flux secondaires.

- Affichage de la longueur totale du réseau secondaire.


**Packages utilisés :** sf, ggplot2, tmap, dplyr

**Outputs :**

- Carte statique (carte_statique_cours_eau.png)

---

### 4.3 `Visualisation_Fleuves et rivières.R`

**Objectif :** 
Visualiser le réseau hydrographique principal (fleuves et grandes rivières) et les bassins versants majeurs du Cameroun.

**Données utilisées :**

- Shapefile des Fleuves et rivières (lignes) OSM, filtré pour les classes principales (river, waterway, canal de grande taille).

- Shapefile des régions GADM.

**Fonctionnalités :**


Carte ggplot2 pour mettre en évidence les principaux axes fluviaux (ex : le fleuve Sanaga, la Bénoué).


**Packages utilisés :** sf, ggplot2, tmap, dplyr

**Output :**

Carte statique (carte_statique_fleuves_rivieres.png)

---

### 4.4 `Visualisation_Grandes_villes.R`

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

### 4.5 `Visualisation_Hopitaux.R`

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


### 4.6 `script1.R`

**Objectif :**
Centraliser le chargement initial de toutes les couches géographiques OSM et GADM du Cameroun et générer les six premières cartes thématiques statiques du projet. Ce script combine les fonctionnalités de chargement des données et de visualisation de base.

**Données utilisées :**

- Limites administratives : Niveaux 0, 1 (régions), et 2 (départements).

- Aires protégées : Polygones à trois niveaux.

- Points habitables : Villes, villages, hameaux, banlieues.

- Équipements sociaux : Hôpitaux, cliniques, pharmacies, écoles.

- Hydrographie : Lignes (fleuves/rivières) et polygones (lacs/réservoirs).

- Voies ferrées.

**Fonctionnalité :**

- Génération de six cartes statiques distinctes (ggplot2) pour représenter l'ensemble des données (infrastructure, population, aires protégées, eau, chemins de fer).


---


### 4.7 `script2.R`

**Objectif :**
Ce script R permet d'analyser et visualiser les infrastructures du Cameroun à partir de données OpenStreetMap, en produisant des cartes thématiques professionnelles.


**Données utilisées :**

- Couches OSM : villages, villes, équipements sociaux
- Limites administratives : Niveaux 0, 1 (régions), et 2 (départements).


**Fonctionnalités : **

**1. Extraction des données OSM :**

Pharmacies, écoles, routes, villes/villages

Régions administratives et limites du pays

Sauvegarde au format GPKG


**2. Production de cartes thématiques :**

Carte 1 : Vue d'ensemble complète (routes, localités, services)

Carte 2 : Distribution des écoles

Carte 3 : Distribution des pharmacies

Carte 4 : Réseau routier détaillé

Carte 5 : Hiérarchie urbaine

Carte 6 : Écoles + localités

Carte 7 : Accessibilité routière aux écoles

Carte 8 : Accessibilité routière aux pharmacies

Carte 9 : Synthèse écoles/pharmacies/villes

---

### 4.8 `tableau_bord_interactif.R`

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

**Outputs :**

- Fichiers HTML interactifs
- CSV des indicateurs clés
- Cartes thématiques consultables dans un navigateur

---


## 5. Sources des données

- **Limites administratives** : GADM
- **Aires protégées** : Protected Planet
- **Points habitables et infrastructures sociales** : OpenStreetMap (OSM)

**Remarques :**

- Les shapefiles OSM contiennent des éléments hors frontières nationales.
- L'utilisation de GADM a permis d'avoir des limites administratives harmonisées.

---


---







