#  Identification des Terres Arables en Éthiopie

##  Description Générale et Objectifs
Ceci est une VERSION 2 DU PROJET
Ce projet vise à **identifier et cartographier les terres arables en Éthiopie** à une résolution de 30 mètres, en combinant plusieurs sources de données satellite et en appliquant des filtres pour exclure les zones non cultivables.

### Objectifs principaux :
1. **Créer une carte des terres potentiellement cultivables** en combinant :
   - Les zones déjà cultivées (GFSAD)
   - Les zones défrichées entre 2000 et 2015 (Hansen)

2. **Affiner cette carte** en excluant :
   - Les zones avec présence d'eau permanente (JRC Water Occurrence)
   - Les surfaces imperméables : villes, routes (GMIS)
   - Les aires protégées : parcs nationaux, réserves (WDPA)

3. **Calculer les superficies arables** :
   - Par pays (total national)
   - Par région (11 régions)
   - Par zone administrative (79 zones)

4. **Our contribution: Comparer 3 scénarios selon le seuil d'occurrence d'eau :**
   - **(90%)** 
   - **(40%)** 
   - **(10%)** 

---

##  Packages Nécessaires

### Installation des dépendances :

```bash
pip install numpy pandas geopandas rasterio folium matplotlib pyproj shapely
```

### Liste détaillée :
- **numpy** : manipulation d'arrays et calculs matriciels
- **pandas** : gestion des tableaux statistiques
- **geopandas** : traitement des données géospatiales vectorielles
- **rasterio** : lecture/écriture de rasters GeoTIFF
- **folium** : création de cartes HTML interactives
- **matplotlib** : export d'images PNG pour les overlays
- **pyproj** : reprojection de coordonnées (EPSG:32637 ↔ EPSG:4326)
- **shapely** : manipulation de géométries

---

##  Structure du Projet

```
TP4-SES/
│
├── data/                              # Données d'entrée
│   ├── boundaries/                    # Limites administratives (GADM)
│   │   ├── gadm41_ETH_0.shp          # Pays (Éthiopie)
│   │   ├── gadm41_ETH_1.shp          # Régions (11)
│   │   └── gadm41_ETH_2.shp          # Zones (79)
│   │
│   ├── water/                         # JRC Water Occurrence (4 tuiles)
│   │   ├── occurrence_30E_10Nv1_4_2021.tif
│   │   ├── occurrence_30E_20Nv1_4_2021.tif
│   │   ├── occurrence_40E_10Nv1_4_2021.tif
│   │   └── occurrence_40E_20Nv1_4_2021.tif
│   │
│   ├── gfsad/                         # Terres cultivées (GFSAD)
│   │   └── *.tif
│   │
│   ├── forest/                        # Déforestation Hansen (2000-2015)
│   │   ├── Hansen_GFC-2023-v1.11_lossyear_*.tif
│   │   └── Hansen_GFC-2023-v1.11_treecover2000_*.tif
│   │
│   ├── impervious/                    # Surfaces imperméables (GMIS)
│   │   └── *.tif
│   │
│   ├── pente/                         # Pentes (optionnel, non utilisé)
│   │   └── *.tif
│   │
│   └── protected_areas/               # Aires protégées WDPA (3 shapefiles)
│       ├── WDPA_WDOECM_Dec2025_Public_ETH_shp_0/
│       ├── WDPA_WDOECM_Dec2025_Public_ETH_shp_1/
│       └── WDPA_WDOECM_Dec2025_Public_ETH_shp_2/
│
├── output/                            # Résultats générés
│   ├── 01_preprocessed/               # Rasters prétraités (voir détails ci-dessous)
│   ├── 02_maps/                       # Cartes HTML et rasters finaux
│   ├── 03_statistics/                 # Fichiers CSV avec les superficies
│   └── logs/                          # Logs de vérification
│ 
│ 
├── script/
│   ├── step1_preparation.py           # Script 1 : Préparation spatiale
│   ├── step2_premier_calcul.py                 # script 2 : pour les terres potentiellement arabes
│   └── step3_affinage.py   # Script 3 : Masquages et calculs finaux   
│ 
│ 
└──README.md

```

---

##  Description des Scripts

### **Script 1 : `step1_preparation.py`**

**Objectif** : Préparer tous les rasters en les harmonisant spatialement.

#### Étapes :

1. **Chargement des limites administratives** (GADM)
   - Pays, régions, zones

2. **Mosaïquage des tuiles d'eau** (JRC)
   - Fusion des 4 tuiles en une seule mosaïque
   - Reprojection vers EPSG:32637 (UTM Zone 37N)
   - Clipping avec les limites de l'Éthiopie

3. **Traitement des autres couches** :
   - **GFSAD** : reprojection → mosaïque → clipping
   - **Impervious** : reprojection → mosaïque → clipping
   - **Forest (Hansen)** : déjà aligné, simple clipping
   - **Aires protégées (WDPA)** : fusion des 3 shapefiles

4. **Vérification de l'alignement spatial** :
   - Tous les rasters finaux ont :
     - Même résolution : **30m**
     - Même CRS : **EPSG:32637**
     - Même emprise : **Éthiopie**

#### Sorties (dans `output/01_preprocessed/`) :
- `water_occurrence_ethiopia.tif`
- `cropland_ethiopia.tif` (GFSAD)
- `impervious_ethiopia.tif` (GMIS)
- `forest_loss_ethiopia.tif` (Hansen)
- `protected_areas_ethiopia.shp` (WDPA fusionné)

---

### **Script 2 : `step2_premier_calcul.py`**

**Objectif** :    Visualiser les terres potentiellement arabes

### **Script 3 : `step3_affinage.py`**

**Objectif** :Masquages et calculs finaux

#### Étapes :

1. **Création de la carte de base** :
   - Logique : `(terres cultivées OU zones défrichées) = 1`
   - Résultat : `base_potential_cultivable_binary.tif`

2. **Application des masques** (3 scénarios d'eau) :
   - **Masque eau** : exclusion selon le seuil d'occurrence (90%, 40%, 10%)
   - **Masque impervious** : exclusion des zones urbaines/bâties
   - **Masque WDPA** : exclusion des aires protégées
   - **Note** : La pente n'est pas utilisée dans cette version

3. **Génération des cartes HTML interactives** :
   - 3 cartes finales (une par scénario)
   - Légendes intégrées avec couleurs distinctes
   - Overlay Leaflet sur fond CartoDB

4. **Calculs statistiques** :
   - Superficie totale arable par scénario
   - Répartition par région (11)
   - Répartition par zone (79)
   - Export en CSV

#### Sorties (dans `output/02_maps/`) :
- `arable_final_90pct.tif` + `.html` (scénario conservateur)
- `arable_final_40pct.tif` + `.html` (scénario modéré)
- `arable_final_10pct.tif` + `.html` (scénario strict)

#### Sorties (dans `output/03_statistics/`) :
- `superficies_regions_90pct.csv`
- `superficies_regions_40pct.csv`
- `superficies_regions_10pct.csv`
- `superficies_zones_90pct.csv`
- `superficies_zones_40pct.csv`
- `superficies_zones_10pct.csv`
- `comparaison_scenarios.csv` (résumé des 3 scénarios)

---

## Contenu du Dossier `output/`

### `01_preprocessed/` (rasters harmonisés)
- Tous les rasters sont alignés : 30m, EPSG:32637, emprise Éthiopie
- Prêts pour l'analyse

### `02_maps/` (cartes finales)
- **GeoTIFF** : rasters binaires (1 = arable, 0 = non)
- **HTML** : cartes interactives visualisables dans un navigateur
- Format léger pour exploration rapide

### `03_statistics/` (tableaux CSV)
- Superficies en hectares
- Pourcentages par zone
- Tri décroissant (zones les plus arables en premier)


### `logs/` (vérifications)
- `01_alignement_spatial.txt` : résolution, CRS, dimensions de chaque couche

---

## Sources de Données

| **Donnée** | **Source** | **Description** | **Résolution** |
|------------|-----------|-----------------|----------------|
| **Terres cultivées** | [NASA GFSAD30](https://lpdaac.usgs.gov/products/gfsad30afcev001/) | Global Food Security-support Analysis Data, terres cultivées actuelles | 30m |
| **Déforestation** | [Hansen Global Forest Change](https://glad.earthengine.app/view/global-forest-change) | Zones défrichées 2000-2015 | 30m |
| **Occurrence d'eau** | [JRC Global Surface Water](https://global-surface-water.appspot.com/) | Pourcentage de temps avec eau (0-100%) | 30m |
| **Surfaces imperméables** | [GMIS Dataset](https://sedac.ciesin.columbia.edu/data/set/ulandsat-gmis-v1) | Global Man-made Impervious Surface (villes, routes) | 30m |
| **Aires protégées** | [WDPA](https://www.protectedplanet.net/) | World Database on Protected Areas (parcs, réserves) | Vectoriel |
| **Limites administratives** | [GADM](https://gadm.org/) | Database of Global Administrative Areas (version 4.1) | Vectoriel |
| **Pentes** | [SRTM DEM](https://www2.jpl.nasa.gov/srtm/) | Shuttle Radar Topography Mission (optionnel) | 30m |

---

##  Limites et Défis Rencontrés

### 1. **Contraintes mémoire**
**Problème** : Les rasters sont énormes (42 194 × 55 116 pixels ≈ 2.3 milliards de pixels)
- Chargement complet en RAM = 2-9 GB selon le type de données
- Opérations vectorisées créent des arrays temporaires gigantesques

**Solutions appliquées** :
- Traitement par blocs (5000×5000 pixels)
- Rasterisation zone par zone au lieu de tout d'un coup
- Libération explicite de la mémoire (`gc.collect()`)

### 2. **Temps de calcul**
**Problème** : Calculs statistiques zone par zone (79 zones) très lents

**Compromis** :
- Script optimisé pour fonctionner sur des PC standards (8-16 GB RAM)
- Temps total : 15-20 minutes (au lieu de crashes mémoire)

### 3. **Choix du seuil d'eau**
**Problème** : Pas de consensus scientifique sur le seuil optimal d'occurrence d'eau

**Approche** :
- Création de 3 scénarios (10%, 40%, 90%)


### 5. **Simplifications méthodologiques**
- **Pente exclue** 

### Résultats éloigné des grandes institutions.

---

## Citation



```
- Xiong, J., et al. (2017). GFSAD30: Global Food Security-support Analysis Data
- Hansen, M.C., et al. (2013). High-Resolution Global Maps of 21st-Century Forest Cover Change
- Pekel, J.F., et al. (2016). High-resolution mapping of global surface water
- Brown de Colstoun, E.C., et al. (2017). Global Man-made Impervious Surface (GMIS) Dataset
- UNEP-WCMC & IUCN (2021). World Database on Protected Areas (WDPA)
```

---

##  Contact

Pour toute question ou amélioration, n'hésitez pas à ouvrir une issue sur GitHub.

---

## Licence


Ce projet est open source. Les données sources ont leurs propres licences respectives.


