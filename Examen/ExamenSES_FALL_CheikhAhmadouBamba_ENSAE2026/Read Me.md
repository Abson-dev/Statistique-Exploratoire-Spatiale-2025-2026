# Devoir sur table – HarvestStat Africa : Analyse Spatiale des Statistiques Agricoles Infranationales

## Description du Projet
Ce devoir porte sur l’exploration et la visualisation de données agricoles infranationales en Afrique subsaharienne à partir de **HarvestStat Africa**, ainsi que sur l'analyse climatique avec **Google Earth Engine**.  
Dans un contexte d’insécurité alimentaire élevée et de variabilité climatique, la disponibilité de séries temporelles cohérentes sur la **production**, les **superficies récoltées** et les **rendements** est essentielle pour comprendre les systèmes alimentaires et améliorer la prise de décision.


L’objectif du projet est de :
- **inspecter** la cohérence des fichiers (frontières + données tabulaires),
- **valider** la correspondance géographique via l’identifiant **FNID**,
- **analyser** la qualité des données via le flag `qc_flag`,
- **produire** des statistiques descriptives et des visualisations,
- **intégrer** des données climatiques (précipitations) via Google Earth Engine,
- **exporter** automatiquement les résultats dans le dossier `outputs/`.

---

## Auteur
- **FALL Cheikh Ahmadou Bamba**  
**Classe :** ISEP3 / ISE Cycle Long (ISE1 CL)
**Année académique :** 2025-2026

---

## Dictionnaire des variables principales
- **fnid** : identifiant géographique unique (FEWS NET)  
- **country** : pays  
- **country_code** : code ISO  
- **admin_1** : unité administrative de premier niveau  
- **admin_2** : unité administrative de second niveau  
- **product** : culture agricole (ex. maïs, sorgho, millet)  
- **season_name** : saison de culture  
- **planting_year / planting_month** : année / mois de semis  
- **harvest_year / harvest_month** : année / mois de récolte  
- **crop_production_system** : système de production (pluvial, irrigué, …)  
- **qc_flag** : indicateur de qualité (0 = ok, 1 = valeur aberrante, 2 = faible variance)  
- **area** : superficie cultivée (ha)  
- **production** : production agricole (t)  
- **yield** : rendement (t/ha)  

---

## Structure du Projet
DOSSIER_EVALUATION/
│
├── data/
│   ├── hvstat_africa_boundary.gpkg        # Limites administratives (polygones)
│   └── hvstat_africa_data.csv             # Statistiques agricoles (séries temporelles)
│
├── scripts/
│   ├── DEVOIR_SES_COMPLET.R               # Script R principal (analyse HarvestStat)
│   ├── DEVOIR_GEE_PRECIPITATIONS.py       # Script Python (précipitations ERA5)
│   └── .ipynb_checkpoints/                # Checkpoints Jupyter (le cas échéant)
│
└── outputs/
│   ├── hvstat_inspection_summary.csv
│   ├── statistiques_descriptives_yield_par_pays_et_culture.csv
│   ├── tableaux_analyse_qc_flag.xlsx
│   ├── ghana_precip_annual_mean_spatial_stats_2015_2020.csv
│   └── (autres fichiers générés automatiquement)

**Chemins utilisés dans ce devoir :**
- **Données :** `C:/Users/admin/Pictures/DEVOIR/DOSSIER_EVALUATION/data/`
- **Sorties :** `C:/Users/admin/Pictures/DEVOIR/DOSSIER_EVALUATION/outputs/`
- **Scripts :** `C:/Users/admin/Pictures/DEVOIR/DOSSIER_EVALUATION/scripts/`

---

## Données Utilisées

### 1. Données agricoles (HarvestStat Africa)
- **`hvstat_africa_boundary.gpkg`**
  - Contient les limites administratives (polygones)
  - Utilisé pour la cartographie et la jointure avec les données agricoles via `fnid`

- **`hvstat_africa_data.csv`**
  - Statistiques agricoles infranationales (production, area, yield)
  - Multi-pays, multi-cultures, multi-saisons
  - Indicateur qualité : `qc_flag`

### 2. Données climatiques (Google Earth Engine)
- **ERA5 Daily** (ECMWF/ERA5/DAILY)
  - Bande : `total_precipitation` (convertie de mètres à mm)
  - Période : **2015-2020**
  - Région : **Ghana** (géométrie FAO/GAUL/2015/level0)
  - Produit : précipitations annuelles moyennes (mm/an)

---

## Technologies et Outils

###  **R / RStudio**  
- **Packages R utilisés :**
  - `sf` (données spatiales vectorielles)
  - `dplyr` (manipulation de données)
  - `readr` (import CSV rapide)
  - `writexl` (export Excel)
  - `stringr` (nettoyage/standardisation des textes)
  - `lubridate` (manipulation des dates)

###  **Python / Google Earth Engine**  
- **Bibliothèques Python :**
  - `ee` (Google Earth Engine API)
  - `geemap` (cartographie interactive)
  - `pandas` (traitement des données tabulaires)
  - `os` (gestion des chemins)

###  **Export :**
- CSV (résumés et métadonnées)
- Excel (tableaux d'analyse)
- PNG/HTML (visualisations - à implémenter)

---

## Tâches Réalisées

### 1) Inspection et validation des données (R)
- **Description de l'unité statistique** : combinaison fnid × product × season_name
- **Différence conceptuelle** entre `area`, `production` et `yield`
- **Analyse de la distribution de `qc_flag`** :
  - Par pays (Bénin, Burkina Faso, Mali, Togo, Niger)
  - Par culture (toutes les cultures disponibles)
- **Stratégie de traitement des `qc_flag`** :
  - `qc_flag = 0` : données valides (utilisées par défaut)
  - `qc_flag = 1` : valeurs aberrantes (correction robuste recommandée)
  - `qc_flag = 2` : faible variance (garder pour agrégats)

### 2) Tableaux d'analyse (R)
- **Pays disponibles** dans la base complète
- **Pays cibles** analysés (5 pays d'Afrique de l'Ouest)
- **Distribution de `qc_flag` par pays**
- **Distribution de `qc_flag` par culture**
- Export automatique vers `tableaux_analyse_qc_flag.xlsx`

### 3) Statistiques descriptives (R)
- **Rendement (`yield`) par pays et par culture** :
  - Moyenne, médiane, quartiles (Q25, Q75)
  - Écart-type, intervalle interquartile (IQR)
  - Minimum, maximum
- Export vers `statistiques_descriptives_yield_par_pays_et_culture.csv`

### 4) Analyse climatique avec Google Earth Engine (Python)
- **Authentification et initialisation** de l'API Earth Engine
- **Sélection des données ERA5 Daily** (précipitations totales)
- **Définition de la géométrie** du Ghana (FAO/GAUL)
- **Filtrage temporel** : 2015-2020
- **Conversion des unités** : mètres → millimètres
- **Calcul des totaux annuels** (mm/an) pour chaque année
- **Moyenne interannuelle** (2015-2020)
- **Statistiques spatiales** sur le Ghana :
  - Moyenne spatiale
  - Variance spatiale
  - Écart-type spatial
  - Coefficient de variation (CV)
- Export vers `ghana_precip_annual_mean_spatial_stats_2015_2020.csv`

---

## Résultats attendus (outputs)
Les résultats incluent :
- **Tableaux Excel** d'analyse de qualité (`tableaux_analyse_qc_flag.xlsx`)
- **Statistiques descriptives** du rendement (`statistiques_descriptives_yield_par_pays_et_culture.csv`)
- **Statistiques spatiales** des précipitations au Ghana (`ghana_precip_annual_mean_spatial_stats_2015_2020.csv`)
- **Résumé d'inspection** des données (`hvstat_inspection_summary.csv`)

---

## Limites globales du projet
Bien que ce devoir permette une bonne prise en main des statistiques spatiales appliquées aux données agricoles et climatiques, plusieurs limites doivent être considérées :

1. **Qualité hétérogène des données** : malgré `qc_flag`, certaines séries peuvent rester incomplètes ou difficilement comparables.
2. **Agrégation simplificatrice** : l'agrégation nationale (moyenne/somme) masque les disparités locales importantes.
3. **Dépendance à la cohérence géographique** : toute incohérence sur `fnid` (doublons, absences, changements administratifs) peut affecter la jointure spatiale.
4. **Résolution spatiale des données climatiques** : ERA5 (≈31 km) peut ne pas capturer les microclimats locaux.
5. **Période climatique limitée** : 2015-2020 est une période relativement courte pour l'analyse des tendances.
6. **Authentification Earth Engine** : nécessite un compte Google avec accès à l'API.

---

## Références
- FEWS NET / USAID (collecte de données agricoles infranationales)
- HarvestStat Africa (compilation et normalisation)
- Google Earth Engine (ECMWF ERA5 Daily)
- FAO GAUL (limites administratives)
- Concepts liés : séries temporelles, jointure spatiale, contrôle qualité (`qc_flag`), statistiques spatiales

---

## Licence
Projet académique (devoir sur table) - ISEP3 / ISE Cycle Long - Année 2025-2026.
Les données HarvestStat Africa sont sous licence open source (FEWS NET/USAID).
Les données ERA5 sont accessibles via Google Earth Engine (conditions d'utilisation de l'ECMWF).