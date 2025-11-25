# TP 3

## Description du Projet
Ce projet utilise Google Earth Engine (GEE) pour analyser et visualiser à travers une carte interactive l'accès des populations aux infrastructures de santé, d'éducation, aux routes, aux ressources en eau.

## Équipe
- **ADDJITA Gérald**
- **GUEBEDIANG Kadidja**
- **TEVOEDJRE Michel**
- **THIOUB Cheikh**

**Classe :** ISE1 CL
**Année académique :** 2025-2026

## Structure du Projet
```
projet-gee-senegal/
│
├── data/                           # Données géospatiales
├── script.js                       # Script principal GEE
└── README.md                       # Documentation du projet
```

## Données Utilisées

### Données Vectorielles
- Limites administratives (régions, frontières nationales)
- Infrastructures de santé (hôpitaux, cliniques, pharmacies)
- Infrastructures d'éducation (écoles, collèges, lycées, universités)
- Localités (villes, villages, hameaux, banlieues)
- Réseau de transport (routes bitumées, routes non bitumées, voies ferrées)
- Ressources en eau (cours d'eau)

### Données Raster
- Population totale
- Densité de population

## Fonctionnalités

### 1. Cartographie Interactive
- Visualisation de toutes les infrastructures sur une carte interactive
- Activation/désactivation des couches par catégorie
- Vue hybride (satellite + carte)

### 2. Zones Tampons d'Accessibilité
- Calcul des zones de couverture autour des infrastructures
- Distances analysées : 5 km, 10 km, 20 km
- Visualisation de l'accessibilité géographique aux services

### 3. Statistiques Nationales
- Décompte des infrastructures 
- Export des statistiques en format CSV

### 4. Cartes Choroplèthes
- Visualisation thématique de la distribution des infrastructures
- Carte des hôpitaux 
- Carte des écoles 
- Carte de la population 

### 5. Analyse de Couverture
- Calcul du pourcentage de population non couverte par infrastructure
- Analyse à différentes échelles de distance

### 6. Interactivité
- Clic sur la carte pour obtenir des informations détaillées (rayon 10 km)
- Panneau de statistiques nationales en temps réel
- Boutons d'export et de réinitialisation

## Utilisation

### Prérequis
- Compte Google Earth Engine

## Analyses Réalisées

### Infrastructure de Santé
- Distribution spatiale des hôpitaux, cliniques et pharmacies
- Zones de couverture sanitaire
- Pourcentage de population avec accès aux services de santé

### Infrastructure d'Éducation
- Distribution spatiale des établissements d'enseignement
- Accessibilité aux écoles, collèges, lycées et universités
- Analyse de la couverture éducative

### Démographie
- Visualisation de la population totale et de la densité
- Répartition spatiale de la population
- Corrélation entre population et infrastructures

### Transport et Mobilité
- Réseau routier (bitumé et non bitumé)
- Réseau ferroviaire
- Analyse de l'accessibilité

### Ressources en Eau
- Localisation des cours d'eau
- Zones d'accès à l'eau

## Technologies et Outils
- **Google Earth Engine** : Plateforme de géomatique cloud
- **JavaScript** : Langage de programmation pour GEE
- **Earth Engine API** : API pour le traitement géospatial
- **Principales fonctions utilisées :**
  - `ee.FeatureCollection` : Manipulation de données vectorielles
  - `ee.Image` : Manipulation de données raster
  - `buffer()` : Création de zones tampons
  - `reduceRegion()` : Calculs statistiques zonaux
  - `Map.addLayer()` : Ajout de couches cartographiques
  - `ui.Panel()` : Création d'interface utilisateur

## Résultats Principaux
L'analyse a permis de :
- Cartographier l'ensemble des infrastructures essentielles au Sénégal
- Identifier les zones à faible accessibilité aux services de base
- Quantifier la couverture géographique des infrastructures par région
- Calculer le pourcentage de population non desservie
- Visualiser les disparités régionales en matière d'infrastructures
- Fournir une base pour la planification et la prise de décision