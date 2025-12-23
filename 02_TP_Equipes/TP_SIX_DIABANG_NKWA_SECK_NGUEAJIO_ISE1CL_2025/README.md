# Calcul des Indices Spectraux au Burkina Faso

## Description du projet

Ce projet vise a calculer plusieurs indices spectraux sur l'ensemble des departements du Burkina Faso pour merger avec les données de la base EHCVM . L'analyse utilise Google Earth Engine.

## Auteurs

- Mouhamet SECK
- Leslye NKWA
- Mamadou DIABANG
- David NGUEAJIO

Projet realise dans le cadre du cours ISE1CL - 2025

### Indices calcules

- **dNBR** (Differenced Normalized Burn Ratio) : Evaluation de la severite des brulures
- **NDVI** (Normalized Difference Vegetation Index) : Sante et densite de la vegetation
- **SAVI** (Soil Adjusted Vegetation Index) : Vegetation corrigee de l'influence du sol
- **NDBI** (Normalized Difference Built-up Index) : Zones baties et urbanisees
- **NDWI** (Normalized Difference Water Index) : Detection de l'eau et humidite
- **MNDWI** (Modified Normalized Difference Water Index) : Surfaces en eau

### Periode d'etude

- Date de debut : 1er juillet 2021
- Date de fin : 31 juillet 2022
- Zone d'etude : 45 departements du Burkina Faso

## Structure du projet
```
TP_SIX_DIABANG_NKWA_SECK_NGUEAJIO_ISE1CL_2025/
│
├── data/
│   └── data.txt                    # Description des donnees utilisees
│
├── scripts/
│   ├── BF_Indice_eau.js            # Script pour le calcul du MNDWI et du NDWI
│   ├── Script_brulis_ndbr.js            # Script pour le calcul du dNBR et NBR
│   ├── script_vegetation.js            # Script pour le calcul du SAVI et NDVI
│   └── scrip_de_merge.R           # Script pour la fusion avec EHCVM
│
├── outputs/
│   ├── base_finale_EHCVM.dta         # Resultats final EHCVM mergé
│   ├── BFA_Final_stats.xlsx         # Resultats final des indices via fichier xlsx
│   ├── BFA_Stats_Departements_NDBI_2022 (1).csv         # Resultats NDBI par departement
│   ├── BurkinaFaso_dNBR_Statistics.xlsx         # Resultats dNBR par departement
│   ├── BF_Indices_Eau_Stats_2022.csv         # Resultats NDWI par departement
│   ├── BF_Comparaison_Pluies_Seche.csv        # Resultats MNDWI par departement
│   └── Ndbr_glimpse/                     # Apercu du Ndbr sur la carte
│
└── README.md                       # Ce fichier
```

## Donnees utilisees

### Source principale
- **Sentinel-2 Surface Reflectance** (COPERNICUS/S2_SR)
- **Limites administratives** : FAO GAUL 2015 (niveau 2 - departements)

### Pre-traitements
- Masquage des nuages via Scene Classification Layer (SCL), etc

## Utilisation

1. Ouvrir l'editeur Google Earth Engine
2. Copier le contenu d'un script du dossier `scripts/`
3. Executer le script (bouton "Run")
4. Interagir avec la carte pour visualiser les resultats
5. Lancer l'export depuis l'onglet "Tasks" pour obtenir les fichiers CSV


## Licence

Ce projet est libre d'utilisation a des fins academiques uniquement.


