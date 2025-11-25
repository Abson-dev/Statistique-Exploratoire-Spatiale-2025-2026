# TP3 :  Analyse des données géospatiales portant sur les infrastructures, les aires protégées et la population du Cameroun

## Membres de l'équipe : 
- AGNANGMA SANAM David Landry
- DIOP Astou
- DIOP Mareme
- NGAKE YAMAHA Herman Parfait

**Superviseur :** M. HEMA

**Année académique : 2025 - 2026**

---

## 1. Description générale

Ce projet vise à réaliser une **analyse spatiale au Cameroun** en utilisant diverses sources de données géospatiales. L'objectif principal est de générer des cartes thématiques et interactives pour créer des zones tampon autour des infrastructures sociales, des localités, du réseau ferroviaire et de visualiser la répartition de la population à l'intérieur des ces buffers et des aires protégées. Les données proviennent essentiellement de **OpenStreetMap (OSM)** pour les infrastructures, de **Worldpop** pour la population et de **Protected Planet** pour les aires protégées , avec une utilisation complémentaire des shapefiles GADM pour les limites administratives.

Le projet comprend plusieurs scripts R pour le traitement et la visualisation des données ainsi qu'une application interactive Shiny et un tableau de bord pour produire des cartes stratégiques pour la planification et la prise de décision.

---

## 2. Installation et packages nécessaires


```r
install.packages(c("sf", "ggplot2", "dplyr", "tidyr", "tmap", "leaflet", "shiny","raster","exactextractr","htmltools","readr","htmlwidgets","tibble",
                   "rnaturalearth", "rnaturalearthdata", "ggspatial", "here", "osmextract", "mapview", "units", "nngeo", "webshot2", "plotly", "cowplot", 			"RColorBrewer"))

```

---

## 3. Structure du projet

```
TP3_SES_2025_2026_ASTOU_MAREME_LANDRY_YAMAHA/
│
│
├── scripts/
│    ├── visualisation_aires_protégées_chemin_de_fer.R
│    ├── Buffers_railways.R
│    ├── Repartition_hopitaux_entites_territoriales.R
│    ├── API.R
│    ├── Tableau de bord.R
|
│─── TP2_SES_2025_2026_ASTOU_MAREME_LANDRY_YAMAHA.Rproj
│
│─── README.md
```

**NB :**

- **TP3_SES_2025_2026_ASTOU_MAREME_LANDRY_YAMAHA.Rproj** est le projet R que nous avons créé pour l'ensemble des travaux de notre équipe.
- Le dossier **outputs** contient l'ensemble de nos cartes statiques et dynamiques, un tableau de bord et un fichier csv récapitulant l'ensemble de nos analyses.
- Le dossier **data** qui contient l'ensemble des données que nous avons utilisé pour nos analyses.
- Ces deux dossiers sont contenus dans des drives (les liens sont les suivants : **https://drive.google.com/drive/folders/19dvhqhjQfoQLReCqo6gnTfsSBgkVBD1Q?usp=sharing** pour **outputs** et **https://drive.google.com/drive/folders/1NM9mwP-4gmgUnahl2Ohy0MvVcVxBTP7c?usp=sharing** pour **data**) du fait de leur taille, qui excède la limite de GitHub. Cependant, vous pouvez les télécharger et les mettre dans le dossier **TP3_SES_2025_2026_ASTOU_MAREME_LANDRY_YAMAHA** pour exécuter les codes.
---

## 4. Description des scripts


### 4.1 `visualisation_aires_protégées_chemin_de_fer.R` et `Buffers_railways.R`

**Objectif :** 

- Créer des zones tampon de rayons 1km, 5km et 10km autour des voies ferrées et visualiser le nombre de personnes et d'autres infrastructures(écoles,         villes,villages,hopitaux, pharmacies,etc.) à l'intérieur de ces buffers
 
- Visualiser la distribution des aires protégées dans l'espace camerounais ainsi que le nombre de personnes et d'infrastructures sur chaque surface.
  
**Données utilisées :**

- Shapefile du réseau ferroviaire(OSM).

- Shapefile des régions (GADM).

- Shapefile des aires protégées (protected planet).

- raster de la population (worldpop).


**Fonctionnalités :**

**Visualisation dynamique du chemin de fer :**

- Carte interactive delimitée au niveau du cameroun.

- Représentation du chemin de fer en couleur noir, de la zone tampon de rayon 1km en vert, de rayon 5km en jaune et de rayon 10km en rouge.

- Affichage du nombre de personnes,d'écoles, d'hopitaux, de villes, de villages,... sur chaque rayon.

- Affichage de la légende.

**Visualisation dynamique des aires protégées :**

- Carte interactive delimitée au niveau du cameroun.

- Représentation de la répartiton des surfaces protégées sur le territoire.

- Affichage du nombre de personnes,d'écoles, d'hopitaux, de villes, de villages,... sur chaque aire protégée .

**Outputs :**

- chemin_de_fer.html

- aires_proteges.html

---

### 4.2 `Repartition_hopitaux_entites_territoriales.R` 


**Objectif :** 

Ce script génère une carte interactive montrant la répartition des hôpitaux et des entités territoriales au Cameroun, avec analyse de la couverture sanitaire et calcul des distances aux infrastructures médicales.

**Données utilisées :**

- **Hôpitaux** : OSM2IGEO Cameroun (2023) - `PAI_SANTE.shp`
- **Limites administratives** : GADM Cameroun Niveau 3 - `gadm41_CMR_3.shp`
- **Entités territoriales** : OpenStreetMap - `gis_osm_places_free_1.shp`
- **Population** : WorldPop 2025 - `cmr_pop_2025_CN_100m_R2024B_v1.tif`

**Fonctionnalités principales:**

La carte interactive offre une exploration avancée de la couverture sanitaire du Cameroun. Elle affiche la répartition des hôpitaux, de la population et met en évidence les zones prioritaires grâce à un système intelligent de hiérarchisation. Une fonction de recherche permet de localiser instantanément n’importe quelle localité ou hôpital, avec zoom automatique et informations détaillées. La visibilité des zones rurales est renforcée grâce à un affichage en clusters de localités. La carte fournit aussi la distance de chaque territoire au centre de santé le plus proche et propose un outil permettant de mesurer le périmètre et la surface d’un territoire d’intérêt.


**Fonctionnalités détaillées:**

###  Analyse Spatiale
- Extraction de la population par région (somme des pixels WorldPop)
- Calcul des densités de population réelles
- Détection de l'hôpital le plus proche pour chaque entité territoriale
- Calcul des distances en kilomètres

###  Données Hospitalières
- Localisation précise des hôpitaux
- Statistiques par région (nombre d'hôpitaux)
- Informations détaillées : nom, région, département

### 🏘️ Hiérarchie des Entités Territoriales
- **Capitale Nationale** ️
- **Ville Principale** 
- **Ville Secondaire** ️
- **Quartier Périphérique** 
- **Village** 
- **Localité** 
- **Hameau** 

###  Fonction de Recherche
- **Recherche en temps réel** dans la barre en haut à gauche
- **Support des deux groupes** : Hôpitaux et Entités Territoriales
- **Zoom automatique** sur le résultat avec popup d'information
- **Auto-complétion** pour une navigation rapide
- **Interface intuitive** de type "search box"

### Visualisation
- Couleurs dégressives (rouge → vert) selon l'importance
- Taille des points proportionnelle à l'importance
- Clustering intelligent des marqueurs
- Légendes interactives


### Fonction de Recherche
- **Recherche en temps réel** dans la barre en haut à gauche
- **Support des deux groupes** : Hôpitaux et Entités Territoriales
- **Zoom automatique** sur le résultat avec popup d'information
- **Auto-complétion** pour une navigation rapide
- **Interface intuitive** de type "search box"

### Visualisation
- Couleurs dégressives (rouge → vert) selon l'importance
- Taille des points proportionnelle à l'importance
- Clustering intelligent des marqueurs
- Légendes interactives

**Outputs :**

### Output : carte_couverture_reelle_cameroun.html
- **Couches superposables** : Hôpitaux, Entités Territoriales, Régions
- **Recherche avancée** avec auto-complétion
- **Mesures** de distances et surfaces
- **Infobulles détaillées** avec statistiques

### Statistiques Globales
- Population totale et superficie
- Densité moyenne nationale
- Nombre total d'hôpitaux et d'entités territoriales

### Export
- Fichier HTML autonome
- Carte responsive et interactive

##  Métriques Calculées

### Par Région
- Population totale
- Superficie (km²)
- Densité (hab/km²)
- Nombre d'hôpitaux

### Par Entité Territoriale
- Type et nom
- Hôpital le plus proche
- Distance à l'hôpital (km)
- Priorité hiérarchique

---


### 4.3 `API.R` 

**Objectif :** 

Cette application Shiny offre une plateforme interactive pour analyser la répartition des hôpitaux et évaluer l'accessibilité aux soins de santé au Cameroun. Elle combine visualisation cartographique avancée et analyses statistiques en temps réel avec un **système de tampon modulable unique** qui révolutionne l'analyse de couverture sanitaire.

**Données utilisées :**

- **Hôpitaux** : OSM2IGEO Cameroun (2023) - `PAI_SANTE.shp`
- **Limites administratives** : GADM Cameroun Niveau 3 - `gadm41_CMR_3.shp`
- **Entités territoriales** : OpenStreetMap - `gis_osm_places_free_1.shp`
- **Population** : WorldPop 2025 - `cmr_pop_2025_CN_100m_R2024B_v1.tif`

**Fonctionnalités principales:**

Notre API vous permet d'explorer la couverture sanitaire avec une précision inédite grâce à son **tampon modulable en temps réel** de 0 à 100 km. Visualisez instantanément comment la zone d'influence d'un hôpital évolue selon la distance choisie : observez la population couverte passer de quelques milliers à des centaines de milliers d'habitants, et voyez les localités desservies se multiplier au fur et à mesure que vous étendez le rayon d'action. Cliquez sur n'importe quel hôpital et ajustez le slider pour découvrir **immédiatement** combien de personnes vivent dans sa zone d'influence actuelle et quelles localités il peut desservir. Cette interactivité sans précédent transforme la planification sanitaire en une expérience dynamique où chaque ajustement de distance révèle de nouvelles insights stratégiques.

##  Le Tampon Modulable : Cœur de l'Application

###  Fonctionnalité Unique
- **Slider interactif** : 0 à 100 km
- **Mise à jour en temps réel** : Les calculs s'ajustent instantanément
- **Visualisation dynamique** : Les zones de tampon apparaissent/disparaissent selon la distance
- **Analyses contextuelles** : Tous les rapports s'adaptent automatiquement

###  Ce qui change avec le tampon
| Distance | Impact sur l'Analyse |
|----------|---------------------|
| **0 km** | Aucun tampon - analyse individuelle de l'hôpital |
| **5 km** | Couverture locale - villages proches |
| **20 km** | Zone d'influence moyenne - plusieurs localités |
| **50 km** | Couverture étendue - impact régional |
| **100 km** | Influence maximale - analyse stratégique |

###  Cas d'Usage du Tampon Modulable
- **Planification urbaine** : Quel rayon couvre optimalement une ville ?
- **Zones rurales** : Quelle distance est acceptable pour l'accès aux soins ?
- **Urgences** : Quel hôpital peut intervenir rapidement ?
- **Investissements** : Où construire pour maximiser la couverture ?


**Fonctionnalités détaillées:**

### ️ Visualisation Cartographique
- **Carte Leaflet interactive** avec 4 couches superposées
- **Régions administratives** colorées par densité de population
- **Hôpitaux** en points rouges avec informations détaillées
- **Localités** classées par type avec codes couleur
- **Zones de tampon** dynamiques autour des hôpitaux

###  Interactions Utilisateur

#### Clic sur Hôpital 
- Calcul **automatique** de la population dans la zone de tampon actuelle
- Liste **dynamique** des localités desservies selon la distance choisie
- Statistiques qui s'**actualisent** en temps réel avec le slider
- Analyse de couverture qui **évolue** avec vos paramètres

#### Clic sur Localité ️
- Identification de l'hôpital le plus proche
- Distance en kilomètres (vol d'oiseau)
- Informations détaillées sur la localité

#### Clic sur Région 
- Statistiques démographiques régionales
- Nombre d'hôpitaux dans la région
- Informations contextuelles

###  Paramètres d'Analyse
- **Distance de tampon** : 0-100 km (slider interactif)
- **Filtrage des localités** : 7 types disponibles
- **Capitale nationale** incluse par défaut

##  Calculs Spatiaux Avancés

### Méthodologie de Calcul de Population
L'application utilise les **données raster WorldPop 2025** (résolution 100m) pour calculer les populations avec une précision exceptionnelle :

1. **Pour les régions** : Somme de tous les pixels dans les limites administratives
2. **Pour les tampons** : Extraction en temps réel de la population dans les cercles autour des hôpitaux
3. **Méthodes redondantes** : `mask()` + `global()` et `extract()` pour robustesse

---


### 4.4 `Tableau de bord.R` 

**Objectif :** 

Fournir un tableau de bord interactif pour la planification stratégique.

**Données utilisées :**

Couches OSM : villages, villes, équipements sociaux, voies ferrées
Aires protégées (Planète Protégée)
Population estimée par type de localité
Caractéristiques :

**Outputs :**

Cartes interactives avec leafletet tmap: accessibilité aux services, connectivité ferroviaire, potentiel écotouristique, biodiversité
Indicateurs stratégiques : distances aux hôpitaux et écoles, villages isolés, infrastructures recensées, superficie des aires protégées
Tableaux et graphiques interactifs
Sorties :

Fichiers HTML interactifs
CSV des indicateurs clés
Cartes thématiques consultables dans un navigateur

---


## 5. Sources des données

- **Limites administratives** : GADM
- **Aires protégées** : Protected Planet
- **Points habitables et infrastructures sociales** : OpenStreetMap (OSM)
- **population** : worldpop


**Remarques :**

- Les shapefiles OSM contiennent des éléments hors frontières nationales.
- L'utilisation de GADM a permis d'avoir des limites administratives harmonisées.

---

