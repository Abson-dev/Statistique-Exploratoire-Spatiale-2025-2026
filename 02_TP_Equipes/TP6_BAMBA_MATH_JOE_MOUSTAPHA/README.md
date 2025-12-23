# TP6 – Analyse des Indices Spectraux et Fusion avec les Données EHCVM pour le Niger
## Calcul et cartographie des indices de végétation, d’eau et de température de surface (2022)

---

## Description du Projet

Ce TP6 vise à calculer, analyser et cartographier des indices spectraux  
(**NDVI, EVI, NDWI, NDMI, MDVI**) ainsi que la **température de surface (LST)**  
pour le **Niger**, à partir d’images **Sentinel-2** et **MODIS**, sur la période  
**juin – septembre 2022**.

L’objectif est de produire des données spatialisées exploitables pour des études  
**socio-environnementales**, notamment via une **fusion avec les données EHCVM**
(Enquête Harmonisée sur le Bien-être des Ménages).

---

## Équipe

- **Math SOCE**
- **Cheikh Ahmadou Bamba FALL**
- **Cheikh Mouhamadou Moustapha NDIAYE**
- **Joe Young Veridique Gabriel DIOP**

**Classe :** ISE1 CL  
**Année académique :** 2025-2026

---

## Structure du Projet (Google Earth Engine & Local)

```
TP6_Niger_Indices_EHCVM/
│
├── gee_project/
│   ├── script_principal.js                 # Script GEE complet (analyse + exports)
│   ├── exports/                            # Exports GEE (Google Drive)
│   │   ├── Niger_Stats_Departements_2022.csv
│   │   ├── Niger_Stats_Regions_2022.csv
│   │   ├── Niger_Template_EHCVM_2022.csv
│   │   └── rasters/                        # NDVI, EVI, NDWI, NDMI, MDVI, LST, bandes S2
│   └── lien_acces_gee.txt                  # Lien vers le projet GEE
│
├── data_local/
│   ├── boundaries/
│   │   ├── geoBoundaries-NER-ADM0-all.zip  # Limite nationale
│   │   ├── geoBoundaries-NER-ADM1-all.zip  # Régions
│   │   ├── geoBoundaries-NER-ADM2-all.zip  # Départements
│   │   └── geoBoundaries-NER-ADM3-all.zip  # Communes (non utilisées)
│   │
│   └── ehcvm/
│       ├── ehcvm_welfare_n_er2021.dta      # Données EHCVM originales (Stata)
│       └── ehcvm_welfare_n_er2021.csv      # Version convertie pour GEE
│
├── outputs_local/
│   ├── cartes_choroplethes/
│   ├── statistiques_fusionnees/
│   └── rapports/
│
└── README.md
```

---

## Données Utilisées

### Données satellitaires (chargées directement dans GEE)

**Sentinel-2 Level-2A (juin–septembre 2022)**  
- Bandes : B2 (Blue), B3 (Green), B4 (Red), B8 (NIR), B11 (SWIR1)  
- Filtrage nuages < 20 %  
- Composite médian

**MODIS MOD11A2 (juin–septembre 2022)**  
- Température de surface terrestre (LST)  
- Résolution : 1 km  
- Conversion en degrés Celsius

---

### Données administratives

- **GADM / FAO GAUL**
  - ADM0 : Niger
  - ADM1 : 8 régions
  - ADM2 : 63 départements

---

### Données socio-économiques

**EHCVM Niger 2021**  
- Fichier original : `ehcvm_welfare_n_er2021.dta`  
- Conversion en CSV pour import et fusion

---

## Technologies et Outils

**Google Earth Engine (JavaScript API)**  
- Traitement d’images satellitaires
- Calcul d’indices spectraux
- Agrégation par unités administratives
- Export de tables et rasters

**Prétraitement local**  
- Conversion Stata → CSV  
- Nettoyage et vérification EHCVM

**Outils complémentaires**  
- **R / Python / Stata** : analyses et fusion EHCVM  
- **QGIS** : cartographie  
- **Excel** : consultation rapide

---

## Tâches Réalisées dans GEE

1. Chargement des limites administratives  
2. Traitement Sentinel-2 (filtrage, composite)  
3. Calcul des indices spectraux  
4. Calcul de la LST (MODIS)  
5. Agrégation statistique (régions, départements)  
6. Visualisation interactive  
7. Préparation des exports (CSV & GeoTIFF)

---

## Résultats Obtenus

**14 fichiers exportés :**
1. `Niger_Stats_Departements_2022.csv`
2. `Niger_Stats_Regions_2022.csv`
3. `Niger_Template_EHCVM_2022.csv`
4. `Niger_NDVI_2022.tif`
5. `Niger_EVI_2022.tif`
6. `Niger_NDWI_2022.tif`
7. `Niger_NDMI_2022.tif`
8. `Niger_MDVI_2022.tif`
9. `Niger_LST_2022.tif`
10. `Niger_S2_B02_2022.tif`
11. `Niger_S2_B03_2022.tif`
12. `Niger_S2_B04_2022.tif`
13. `Niger_S2_B08_2022.tif`
14. `Niger_S2_B11_2022.tif`

---

## Accès aux Résultats

**Google Earth Engine**  
Lien : https://code.earthengine.google.com/3a6feea90ef928542840454df2e45be4  

**Google Drive**  
Dossier : `GEE_Niger_Analyse`  

**Dépôt Git**  
Scripts, données légères et documentation uniquement.

---

## Prochaines Étapes : Fusion avec l’EHCVM

1. Télécharger `Niger_Template_EHCVM_2022.csv`  
2. Importer EHCVM  
3. Fusionner par **Département** ou **Région**  
4. Analyser les relations environnement ↔ bien-être

---

## Références

- Google Earth Engine : https://earthengine.google.com  
- Sentinel-2 : https://sentinel.esa.int  
- MODIS : https://modis.gsfc.nasa.gov  
- GADM : https://gadm.org  
- EHCVM Niger : INS Niger

---

## Licence

Projet académique réalisé dans le cadre du cours de **Statistique Spatiale – ENSAE-ISEP**.  
Données satellitaires ouvertes (Sentinel-2, MODIS).  
Données EHCVM : usage strictement académique.
