# Analyse des Distances entre Infrastructures et Aires Protégées au Sénégal

## Description du Projet
Ce projet analyse les distances spatiales entre différentes infrastructures (villes, hôpitaux, écoles, etc.) et les aires protégées du Sénégal.
L'analyse utilise Google Earth Engine pour calculer des statistiques de distance et identifier les infrastructures situées dans un rayon de 10 km des zones protégées.

## Équipe
- **ADDJITA Gérald**
- **GUEBEDIANG Kadidja**
- **TEVOEDJRE Michel**
- **THIOUB Cheikh**

**Classe :** ISE1 CL  
**Année académique :** 2025-2026

## Structure du Projet
```
TP2_ADDJITA_GUEBEDIANG_TEVOEDJRE_THIOUB_ISE1_CL_2025_2026/
│
├── Données/
│   ├── Délimitations/              # Limites administratives (GADM)
│   │   ├── gadm41_SEN_0.zip        # Niveau national
│   │   ├── gadm41_SEN_1.zip        # Niveau régional (14 régions)
│   │   ├── gadm41_SEN_2.zip        # Niveau départemental (45 départements)
│   │   ├── gadm41_SEN_3.zip        # Niveau communal
│   │   └── gadm41_SEN_4.zip        # Niveau arrondissement
│   │
│   ├── Infrastructures/            # Données OSM
│   │   ├── cities_100.zip          # Villes
│   │   ├── clinics_100.zip         # Cliniques
│   │   ├── hamlets_100.zip         # Hameaux
│   │   ├── hospitals_100.zip       # Hôpitaux
│   │   ├── pharmacies_100.zip      # Pharmacies
│   │   ├── schools_100.zip         # Écoles
│   │   ├── suburbs_100.zip         # Banlieues
│   │   ├── towns_100.zip           # Bourgs
│   │   └── villages_100.zip        # Villages
│   │
│   └── Zones_protégées/            # Aires protégées (WDPA - Protected Planet)
│       ├── shp0points.zip          # Points niveau 0
│       ├── shp0polygons.zip        # Polygones niveau 0
│       ├── shp1points.zip          # Points niveau 1
│       ├── shp1polygons.zip        # Polygones niveau 1
│       ├── shp2points.zip          # Points niveau 2
│       └── shp2polygons.zip        # Polygones niveau 2
│
└── TP2_SCRIPT.txt                  # Script Google Earth Engine
```

## Données Utilisées

### Données Vectorielles - Limites Administratives (GADM)
- **Source :** [GADM - Database of Global Administrative Areas](https://gadm.org/)
- **Niveaux :** 5 niveaux administratifs du Sénégal (pays, régions, départements, communes, arrondissements)
- **Format :** Shapefiles (.shp)

### Données Vectorielles - Infrastructures (OpenStreetMap)
- **Source :** [OpenStreetMap (OSM)](https://www.openstreetmap.org/)
- **Types :** 9 catégories d'infrastructures (villes, hôpitaux, écoles, etc.)
- **Format :** Shapefiles points (.shp)

### Données Vectorielles - Aires Protégées (Protected Planet)
- **Source :** [Protected Planet - World Database on Protected Areas (WDPA)](https://www.protectedplanet.net/)
- **Niveaux :** 3 niveaux de protection (points et polygones)
- **Format :** Shapefiles (.shp)

## Technologies et Outils

- **Google Earth Engine (GEE)** : Plateforme d'analyse géospatiale
- **JavaScript** : Langage de script pour GEE

### Fonctionnalités Principales
- **Calcul de distances** : Transformation de distance euclidienne (Fast Distance Transform)
- **Statistiques zonales** : Moyenne, min, max par aire protégée
- **Analyse de proximité** : Buffer de 10 km autour des aires protégées
- **Export CSV** : Sauvegarde des résultats dans Google Drive

## Analyses Réalisées

### 1. Calcul des Distances
- Distance euclidienne entre chaque infrastructure et les aires protégées
- Génération de 9 rasters de distance (un par type d'infrastructure)
- Visualisation en dégradé de couleur (bleu → rouge)

### 2. Statistiques Zonales
- Distance moyenne, minimale et maximale par aire protégée
- Statistiques globales pour l'ensemble du territoire
- Agrégation par niveau administratif

### 3. Analyse de Proximité (Buffer 10 km)
- Identification des infrastructures à moins de 10 km des aires protégées
- Comptage par type d'infrastructure
- Comptage par aire protégée

### 4. Visualisation Interactive
- Superposition de couches cartographiques
- Activation/désactivation des couches
- Zone tampon de 10 km visualisée sur la carte

## Utilisation

### Configuration Initiale
1. Créer un compte [Google Earth Engine](https://earthengine.google.com/)
2. Télécharger les données sources :
   - **GADM** : Limites administratives du Sénégal
   - **OSM** : Données d'infrastructures
   - **Protected Planet (WDPA)** : Aires protégées du Sénégal
3. Importer les assets dans le projet Cloud GEE 
4. Vérifier le nom du projet dans le script (ligne 11)

### Exécution du Script
1. Ouvrir le [Code Editor GEE](https://code.earthengine.google.com/)
2. Copier-coller le contenu de `TP2_SCRIPT.txt`
3. Exécuter le script (Run)
4. Consulter les résultats dans la console et sur la carte

### Export des Résultats
1. Aller dans l'onglet **Tasks** (en haut à droite)
2. Cliquer sur **RUN** pour chaque tâche d'export
3. Les fichiers CSV seront sauvegardés dans Google Drive
4. **Dossier de destination :** `GEE_Exports_Senegal`

### Visualisations sur la Carte
- Aires protégées (vert)
- Zone tampon 10 km (jaune)
- 9 rasters de distance (gradient bleu → rouge)
- Points d'infrastructures dans la zone 10 km (rouge)

## Références

- **GADM :** https://gadm.org/
- **OpenStreetMap :** https://www.openstreetmap.org/
- **Google Earth Engine :** https://earthengine.google.com/
- **Protected Planet :** https://www.protectedplanet.net/

## Licence
Projet académique