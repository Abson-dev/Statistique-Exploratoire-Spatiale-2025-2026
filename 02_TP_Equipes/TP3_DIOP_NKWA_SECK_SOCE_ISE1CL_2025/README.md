# Analyse géospatiale de la couverture sanitaire, des zones protégées et des corridors de transport au Bénin

## 1. Objet du projet

Ce projet constitue un travail complet de Statistique Exploratoire Spatiale, réalisé entièrement sur Python.
L’objectif est d’intégrer et d’analyser plusieurs sources géospatiales pour produire une vision détaillée du territoire béninois selon :

- les infrastructures sanitaires (hôpitaux, pharmacies),

- les localités,

- les routes et les voies ferrées,

- les zones protégées,

- la population issue de WorldPop (100 m).

- L’analyse est centrée sur l’accessibilité, la population desservie, les zones d’influence, et la répartition spatiale.

---

## 2. Données utilisées
### 2.1 Données géographiques (vecteur)

- Sources principales :

geoBoundaries : limites administratives du Bénin (pays, départements).

OpenStreetMap (OSM) :

hôpitaux

pharmacies

localités (village, town, hamlet…)

réseau routier

réseau ferroviaire

aires protégées

### 2.2 Données populationnelles (raster)

WorldPop 2024, résolution 100 m, résolution 1km.
Format : .tif.

Les fichiers sont organisés dans le répertoire data/.

---

## 3. Méthodologie générale

L’ensemble du projet a été structuré autour des étapes suivantes :

### 3.1 Chargement et harmonisation des données

- Chargement des données vecteur (GeoJSON, shapefiles).

- Chargement dest raster WorldPop.

- Harmonisation des systèmes de coordonnées :

- EPSG:4326 pour les représentations géographiques,

- UTM 31N pour les opérations métriques (buffers, distances).

### 3.2 Classification des localités et typologie spatiale

- Extraction des types OSM : village, town, hamlet, island, farm.

- Création d’un zonage urbain / rural, basé sur la densité sur un rayon de 2km autour des infrastructures.

- Attribution d’une zone (urbain/rural) aux infrastructures sanitaires.

### 3.3 Buffers autour des infrastructures

Des rayons différents ont été appliqués selon la zone :
```
Infrastructure	Urbain	Rural
Hôpital	        5 km	15 km
Pharmacie	    2 km	7 km
```
Les buffers ont été construits en UTM puis reprojetés en WGS84 pour le calcul de population.

### 3.4 Population desservie (WorldPop)

Pour chaque infrastructure :

- construction d’un buffer,

- extraction de la population via Zonal Statistics,

- consolidation des résultats par zone urbaine/rurale.

### 3.5 Corridors de transport

Un corridor unique a été construit selon :

- routes principales (trunk, primary, secondary),

- voie ferrée (rail).

Étapes :

- filtrage des routes et rails,

- construction d’un buffer de 2 km,

- fusion routes + rails,

extraction de :

- la population dans le corridor,

- les localités situées dans le corridor.

### 3.6 Zones protégées

- Quantification de la superficie protégée par département,

- Population vivant à l’intérieur des zones protégées (WorldPop),

- Carte statique comprenant :

- limites départementales,

- choroplèthe par pourcentage de population protégée.

### 3.7 Visualisations

Deux types de visualisations ont été produits :

#### a. Cartes statiques (matplotlib)

- Hôpitaux et pharmacies sur le territoire,

- Zones protégées,

- Buffers et populations desservies.

#### b. Cartes interactives (Folium)

- Buffers dynamiques,

- Population desservie affichée au survol,

- Couleurs par zone (urbain/rural),

- Corridors interactifs superposés.

---

4. Architecture du projet
```
│── data/                   # Données géospatiales (vectorielles et raster)
│── output/
│     ├── maps/             # Export des cartes statiques
│     ├── interactive/      # Cartes Folium
│     └── tables/           # Résultats intermédiaires
│── notebooks/
│     └── TP3_SES.ipynb     # Notebook principal du projet
│── TP3_SES/                # Fonctions modulaires (buffers, zonal stats…)
│── README.md               # Documentation du projet
```

---

## 5. Résultats produits
### 5.1 Analyses infrastuctures / population

Population desservie par infrastructure (urbain / rural).

### 5.2 Analyses territoriales

- Population vivant dans les aires protégées.

- Corridors de transport :

- population totale,

- nombre de localités traversées.

---

## 7. Limites du projet

- La qualité et la précision dépendent fortement d’OSM.

- L’identification urbaine/rurale dépend de la densité de population autour des infrastructures.

- La résolution Raster WorldPop impose une granularité de 100 m.

- Les données ferroviaires sont limitées (une seule classe : rail).

## 8. Auteur
```
Travail réalisé par :
Joo Young Veridict Gabriel DIOP
Leslye NKWA TSAMO
Math SOCE
Mouhamet SECK
ENSAE - ISE1 - CL, 2025
```

