# 🌍 Analyse Spatiale du Burkina Faso

**Auteur:** Addjta Gérald Guerngué  
**Date:** Novembre 2025  
**Cours:** TP Statistique Spatiale Exploratoire  
**Plateforme:** Google Earth Engine

---

## 📖 Description du projet

Ce projet présente une analyse spatiale exploratoire complète du Burkina Faso, utilisant Google Earth Engine pour visualiser et analyser :
- Les données démographiques (WorldPop 2015-2025)
- Les limites administratives (GADM niveaux 0-3)
- Les infrastructures (villes, villages, écoles, hôpitaux)

## 🎯 Objectifs

1. Extraire et analyser les caractéristiques des données vectorielles et raster
2. Créer des visualisations pertinentes et interactives
3. Développer une application web interactive pour l'exploration des données
4. Analyser l'évolution démographique et la distribution des infrastructures

---

## 📂 Structure du projet

```
burkina-faso-analyse-spatiale/
│
├── README.txt                         # Documentation principale (ce fichier)
│
├── Data/
│   ├── données_pop_2015-2025/        # Rasters de population WorldPop
│   ├── Gdam/                         # Limites administratives GADM
│   └── Infrastructures/              # Données des infrastructures (villes, écoles, etc.)
│
├── Scripts/
│   ├── exploration.txt               # Script d'exploration des données
│   └── application.txt               # Application interactive complète
│
├── Docs/
│   ├── Installation et utilisation.txt       # Guide d'utilisation de l'application
│   
└── results/                          # Résultats d'analyse et exports
```

---


## 📊 Données utilisées

### Données vectorielles (Dossier : `Data/Gdam/`)
- **GADM 4.1** - Limites administratives du Burkina Faso
  - `gadm41_BFA_0` : Frontière nationale (1 feature)
  - `gadm41_BFA_1` : Régions (13 features)
  - `gadm41_BFA_2` : Provinces (45 features)
  - `gadm41_BFA_3` : Départements (351 features)

### Données raster (Dossier : `Data/données_pop_2015-2025/`)
- **WorldPop** - Population 2015-2025
  - `bfa_pop_2015_CN_100m_R2025A_v1` à `bfa_pop_2025_CN_100m_R2025A_v1`
  - Résolution : 100m
  - Format : GeoTIFF
  - 11 images annuelles (2015-2025)

### Infrastructures (Dossier : `Data/Infrastructures/`)
- `cities_100` : Villes (11 points)
- `villages_100` : Villages (8,344 points)
- `schools_100` : Écoles (4,116 points)
- `hospitals_100` : Hôpitaux (428 points)

**Sources des données :**
- GADM : https://gadm.org/
- WorldPop : https://www.worldpop.org/
- Infrastructures : OpenStreetMap

---

## 🎨 Fonctionnalités de l'application

### Interface interactive
- ✅ Sélection de l'année avec slider (2015-2025)
- ✅ Activation/désactivation des couches par niveau administratif
- ✅ 4 modes de visualisation de la population
- ✅ Affichage dynamique des infrastructures
- ✅ Analyse détaillée par région

### Visualisations disponibles
1. **Densité de population** - Carte de chaleur avec palette de couleurs
2. **Hotspots** - Identification des zones de forte concentration
3. **Gradient** - Visualisation des zones de croissance démographique
4. **Choroplèthe** - Population agrégée par région
5. **Distance aux hôpitaux** - Carte d'accessibilité aux soins de santé

### Analyses statistiques
- 📈 Évolution temporelle de la population (2015-2025)
- 🔄 Comparaison entre deux années sélectionnées
- 📍 Statistiques régionales détaillées (population, infrastructures)
- 🏥 Ratio population/infrastructures par région
- 📊 Distribution de la densité de population

---

## 📈 Résultats principaux

### Caractéristiques des données

**Limites administratives :**
- Pays (Niveau 0) : 1 feature
- Régions (Niveau 1) : 13 features
- Provinces (Niveau 2) : 45 features
- Départements (Niveau 3) : 351 features

**Infrastructures recensées :**
- Villes : 11
- Villages : 8,344
- Écoles : 4,116
- Hôpitaux : 428

### Analyse démographique

**Population 2025 :**
- Population totale estimée : ~23 millions d'habitants
- Densité moyenne : Variable selon les régions
- Région la plus peuplée : Centre (incluant Ouagadougou)

**Évolution 2015-2025 :**
- Taux de croissance démographique : Croissance soutenue
- Tendance : Concentration urbaine croissante
- Zones de forte croissance : Région Centre et Hauts-Bassins

### Distribution spatiale

**Concentration de la population :**
- Forte concentration dans la région Centre (capitale Ouagadougou)
- Concentration secondaire : Hauts-Bassins (Bobo-Dioulasso)
- Zones rurales : Densité plus faible et dispersée

**Gradient de densité :**
- Gradient fort autour des centres urbains principaux
- Décroissance progressive vers les zones périphériques
- Zones de faible densité dans le Nord et l'Est

### Infrastructures et accessibilité

**Distribution des infrastructures :**
- Écoles : Répartition relativement homogène (4,116 établissements)
- Hôpitaux : Concentration dans les zones urbaines (428 établissements)
- Disparités d'accès entre zones urbaines et rurales

**Ratios population/infrastructures (moyennes nationales) :**
- Population par école : ~5,594 habitants/école
- Population par hôpital : ~53,738 habitants/hôpital
- Variabilité importante selon les régions

**Accessibilité aux soins :**
- Distance moyenne aux hôpitaux : Variable selon les régions
- Zones à faible accessibilité : Régions périphériques et rurales
- Zones à forte accessibilité : Centres urbains (Centre, Hauts-Bassins)

### Insights clés

1. **Croissance démographique soutenue** : Augmentation constante de la population entre 2015 et 2025
2. **Urbanisation croissante** : Concentration progressive dans les centres urbains principaux
3. **Disparités régionales** : Écarts importants entre régions en termes de population et d'infrastructures
4. **Défis d'accessibilité** : Zones rurales avec accès limité aux services de santé et éducation
5. **Hotspots identifiés** : Ouagadougou et Bobo-Dioulasso comme principaux pôles de concentration

---

## 🛠️ Technologies utilisées

- **Google Earth Engine** - Plateforme de géomatique cloud pour l'analyse spatiale
- **JavaScript** - Langage de programmation pour les scripts GEE
- **GADM** - Base de données des limites administratives mondiales
- **WorldPop** - Données démographiques à haute résolution
- **OpenStreetMap** - Source de données pour les infrastructures

---

## 📝 Scripts disponibles

### 1. Script d'exploration (`Scripts/exploration.txt`)
Script complet pour :
- Charger et explorer toutes les données
- Extraire les caractéristiques des limites administratives
- Calculer les statistiques de population par année
- Analyser la distribution des infrastructures
- Générer des visualisations statiques
- Créer des graphiques et histogrammes

### 2. Application interactive (`Scripts/application.txt`)
Application web interactive avec :
- Interface utilisateur complète
- Sélection dynamique de l'année
- Contrôles pour chaque type de couche
- Modes de visualisation multiples
- Analyses régionales en temps réel
- Graphiques d'évolution temporelle
- Fonction de comparaison d'années

---

## 👤 Auteur

**Addjita Gérald Guerngué**
- Promotion : 2026/ISE1-CL
- Institution : ENSAE
- Email : addjitagerald@gmail.com

---

## 🙏 Remerciements

- **Professeur :** M.Aboubacar HEMA  - Cours de Statistique Spatiale Exploratoire
- **Institution :** ENSAE
---

## 📚 Références

1. GADM database of Global Administrative Areas, version 4.1. (2022). Available at: https://gadm.org/
2. WorldPop. Population Counts 2015-2025. University of Southampton. (2025). Available at: https://www.worldpop.org/
3. OpenStreetMap contributors. (2024). Available at: https://www.openstreetmap.org/
4. Google Earth Engine Team. (2024). Google Earth Engine Platform. Available at: https://earthengine.google.com/

---

## 🔗 Liens utiles

- **Documentation Google Earth Engine :** https://developers.google.com/earth-engine/
- **Tutoriels GEE :** https://developers.google.com/earth-engine/tutorials
- **GADM Data :** https://gadm.org/data.html
- **WorldPop Data :** https://www.worldpop.org/geodata/listing?id=76
- **Code Editor GEE :** https://code.earthengine.google.com/

---

**📌 Note :** Ce projet a été réalisé dans le cadre d'un travail pratique académique sur l'analyse spatiale exploratoire. Les données utilisées sont disponibles publiquement et les analyses peuvent être reproduites en suivant les instructions d'installation.

**⭐ N'oubliez pas de consulter les fichiers dans `Docs/` pour plus de détails sur l'utilisation !**