# TP6 – Analyse des Indices Spectraux et Fusion avec les Données EHCVM pour le Niger
## Calcul et cartographie des indices de végétation, d'eau et de température de surface (2022)

## Description du Projet
Ce TP6 vise à calculer, analyser et cartographier des indices spectraux (NDVI, EVI, NDWI, NDMI, MDVI) et la température de surface (LST) pour le Niger, à partir d'images Sentinel-2 et MODIS, sur la période juin-septembre 2022. L'objectif est de produire des données spatialisées exploitables pour des études socio-environnementales, notamment via une fusion avec les données de l'enquête EHCVM (Enquête Harmonisée sur le Bien-être des Ménages).

Contrainte technique majeure : Le traitement des images satellitaires (Sentinel-2, MODIS) nécessite habituellement le téléchargement de centaines de gigaoctets de données. Avec nos contraintes de stockage (disques durs limités, quotas Google Drive insuffisants), cette approche traditionnelle était impossible.

Solution adoptée : Google Earth Engine (GEE) nous a permis de :

Traiter directement les données dans le cloud, sans téléchargement local

Accéder à des collections complètes d'images (Sentinel-2, MODIS) via leur API

Effectuer des calculs à l'échelle nationale en quelques minutes

Exporter uniquement les résultats agrégés (tables CSV) et les cartes finales

## Équipe
- **Math SOCE**
- **Cheikh Ahmadou Bamba FALL**
- **Cheikh Mouhamadou Moustapha NDIAYE**
- **Joe Young Veridique Gabriel DIOP**

**Classe :** ISE1 CL  
**Année académique :** 2025-2026

## Structure du Projet (sur Google Earth Engine et en local)
TP6_Niger_Indices_EHCVM/
│
├── gee_project/
│ ├── script_principal.js # Script GEE complet (analyse + exports)
│ ├── exports/ # Dossiers d'export GEE (Drive)
│ │ ├── Niger_Stats_Departements_2022.csv
│ │ ├── Niger_Stats_Regions_2022.csv
│ │ ├── Niger_Template_EHCVM_2022.csv
│ │ ├── rasters/ (NDVI, EVI, NDWI, NDMI, MDVI, LST, bandes S2)
│ └── lien_acces_gee.txt # Lien vers le projet GEE partagé
│
├── data_local/ # Données importées/transformées localement
│ ├── boundaries/
│ │ ├── geoBoundaries-NER-ADM0-all.zip # Limite nationale
│ │ ├── geoBoundaries-NER-ADM1-all.zip # Régions
│ │ ├── geoBoundaries-NER-ADM2-all.zip # Départements
│ │ └── geoBoundaries-NER-ADM3-all.zip # Communes (non utilisées ici)
│ │
│ └── ehcvm/
│ ├── ehcvm_welfare_n_er2021.dta # Données EHCVM originales (Stata)
│ └── ehcvm_welfare_n_er2021.csv # Version convertie pour GEE
│
├── outputs_local/ # Exports locaux (si traitements complémentaires)
│ ├── cartes_choroplethes/
│ ├── statistiques_fusionnees/
│ └── rapports/
│
└── README.md # Ce fichier

text

## Données Utilisées
### Données satellitaires (chargées directement dans GEE)
- **Sentinel-2 Level-2A** (juin-septembre 2022) :
  - Bandes utilisées : B2 (Blue), B3 (Green), B4 (Red), B8 (NIR), B11 (SWIR1)
  - Sélection d'images avec moins de 20% de couverture nuageuse
  - Composite médian sur la période

- **MODIS MOD11A2** (juin-septembre 2022) :
  - Température de surface terrestre (LST) en degrés Celsius
  - Résolution : 1 km

### Données administratives (importées dans GEE)
- **GADM/FAO GAUL** :
  - Niveau 0 : Niger (ADM0)
  - Niveau 1 : 8 régions (ADM1)
  - Niveau 2 : 63 départements (ADM2)

### Données socio-économiques (importées et transformées)
- **EHCVM Niger 2021** :
  - Fichier original : `ehcvm_welfare_n_er2021.dta` (Stata)
  - Converti en CSV pour faciliter l'import et la fusion ultérieure

## Technologies et Outils
**Google Earth Engine (JavaScript API) :**
- Traitement de grandes collections d'images
- Calcul d'indices spectraux à l'échelle nationale
- Agrégation statistique par unités administratives
- Export de tables et rasters

**Prétraitement local :**
- Conversion de données Stata vers CSV
- Vérification et nettoyage des données EHCVM

**Outils complémentaires (recommandés) :**
- **R/Python/Stata** : pour fusionner les indices avec EHCVM et analyses avancées
- **QGIS** : pour la cartographie à partir des rasters exportés
- **Excel** : pour consultation rapide des tableaux statistiques

## Tâches Réalisées dans GEE
### 1. Chargement des limites administratives
- Import des couches GADM (pays, régions, départements)
- Vérification des géométries et des attributs

### 2. Traitement Sentinel-2
- Filtrage temporel (juin-septembre 2022) et spatial (Niger)
- Sélection des bandes utiles aux indices
- Création d'un composite médian (réduction des nuages)

### 3. Calcul des indices spectraux
- **NDVI** : santé de la végétation
- **EVI** : végétation avec correction atmosphérique
- **NDWI** : présence d'eau
- **NDMI** : humidité du couvert végétal
- **MDVI** : indice de végétation modifié

### 4. Calcul de la température de surface (LST)
- Chargement et traitement MODIS MOD11A2
- Conversion en degrés Celsius

### 5. Agrégation statistique
- Calcul par département et par région de :
  - Moyenne, écart-type, minimum, maximum
  - Pour chaque indice et la LST

### 6. Visualisation interactive
- Affichage des indices avec palettes colorimétriques adaptées
- Superposition des limites administratives

### 7. Préparation des exports
- **Tables CSV** :
  - Statistiques par département
  - Statistiques par région
  - Template pour fusion avec EHCVM (moyennes par département)
- **Rasters GeoTIFF** :
  - 6 indices (NDVI, EVI, NDWI, NDMI, MDVI, LST)
  - 5 bandes Sentinel-2 brutes (B2, B3, B4, B8, B11)

## Résultats Obtenus
### Fichiers générés (14 exports) :
1. `Niger_Stats_Departements_2022.csv` – statistiques pour les 63 départements
2. `Niger_Stats_Regions_2022.csv` – statistiques pour les 8 régions
3. `Niger_Template_EHCVM_2022.csv` – template de fusion avec EHCVM
4. `Niger_NDVI_2022.tif` – carte NDVI
5. `Niger_EVI_2022.tif` – carte EVI
6. `Niger_NDWI_2022.tif` – carte NDWI
7. `Niger_NDMI_2022.tif` – carte NDMI
8. `Niger_MDVI_2022.tif` – carte MDVI
9. `Niger_LST_2022.tif` – carte température de surface
10. `Niger_S2_B02_2022.tif` – bande bleue
11. `Niger_S2_B03_2022.tif` – bande verte
12. `Niger_S2_B04_2022.tif` – bande rouge
13. `Niger_S2_B08_2022.tif` – bande proche infrarouge
14. `Niger_S2_B11_2022.tif` – bande SWIR1

## Comment Accéder aux Résultats Complets
1. **Via Google Earth Engine** (recommandé) :
   - Lien du projet : [https://code.earthengine.google.com/3a6feea90ef928542840454df2e45be4](https://code.earthengine.google.com/3a6feea90ef928542840454df2e45be4)
   - Le professeur a été ajouté en tant qu'éditeur
   - Tous les exports sont visibles dans l'onglet "Tasks"

2. **Via Google Drive** :
   - Les exports sont envoyés dans le dossier `GEE_Niger_Analyse`
   - Format : CSV (tables) et GeoTIFF (rasters)

3. **Dans ce dépôt** :
   - Seuls les fichiers légers sont inclus (scripts, données sources, documentations)
   - Les rasters volumineux sont accessibles via GEE ou Drive

## Prochaines Étapes (Fusion avec EHCVM)
1. **Télécharger** `Niger_Template_EHCVM_2022.csv`
2. **Importer** les données EHCVM (format CSV ou Stata)
3. **Fusionner** sur la clé `Departement` (ou `Region` selon le niveau d'analyse)
4. **Analyser** les corrélations entre indices environnementaux et indicateurs de bien-être

## Références
- **Google Earth Engine** : [https://earthengine.google.com/](https://earthengine.google.com/)
- **Sentinel-2** : [https://sentinel.esa.int/](https://sentinel.esa.int/)
- **MODIS** : [https://modis.gsfc.nasa.gov/](https://modis.gsfc.nasa.gov/)
- **GADM** : [https://gadm.org/](https://gadm.org/)
- **EHCVM Niger** : Institut National de la Statistique (INS)

## Licence
Projet académique réalisé dans le cadre du cours de Statistique Spatiale à l'ENSAE-ISEP.  
Les données satellitaires sont ouvertes (Sentinel-2, MODIS).  

Les données EHCVM sont fournies par l'INS Niger pour usage académique.
