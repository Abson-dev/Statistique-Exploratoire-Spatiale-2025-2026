# TP6 – Analyse des indices spectraux et fusion avec EHCVM (Mali 2021-2022)

## Membres de l'équipe

- **DIOP Astou**
- **GUEBEDIANG Kadidja**
- **RIRADJIM Trésor**
- **TEVOEDJRE Michel**

**Classe :** ISE1 CL  
**Superviseur :** M. HEMA  
**Année académique :** 2025 - 2026

---

## 1. Description du TP

**Objectif :**  
Ce TP a pour objectif de calculer et analyser cinq indices spectraux pour le Mali afin d’évaluer l’environnement des ménages selon différentes dimensions :  

- **NDVI (Normalized Difference Vegetation Index)** : densité de la végétation  
- **NDWI (Normalized Difference Water Index)** : surfaces d’eau et zones inondées  
- **NDMI (Normalized Difference Moisture Index)** : humidité de la végétation  
- **NDBI (Normalized Difference Built-up Index)** : urbanisation  
- **BSI (Bare Soil Index)** : sols nus et désertification  

Ces indices sont ensuite fusionnés avec les données EHCVM pour chaque département, afin de croiser les conditions environnementales avec les caractéristiques des ménages.

**Pays étudié :** Mali  
**Année :** 2021-2022

---

## 2. Sources des données

### Images satellites Sentinel-2
- Fournissent des images multispectrales avec différentes bandes : Blue, Green, Red, NIR, SWIR.  
- Seules cinq bandes sont utilisées pour calculer les indices (Blue, Green, Red, NIR, SWIR).  
- On a choisi les images **L2A (réflectance de surface)** déjà corrigées pour l’atmosphère, permettant un calcul direct des indices.  

### Zone d’étude
- Définition de la zone géographique correspondant au Mali pour limiter le traitement aux pixels pertinents et réduire le volume de données.

### Filtrage temporel
- Période sélectionnée : **novembre 2021 à juillet 2022**, correspondant à la période de l’enquête EHCVM.  

### Sélection des bandes utiles pour chaque indice
| Indice | Bandes utilisées |
|--------|-----------------|
| NDVI   | Red, NIR        |
| NDWI   | Green, NIR      |
| NDMI   | NIR, SWIR       |
| NDBI   | NIR, SWIR       |
| BSI    | Blue, Red, NIR, SWIR |

### Calcul de la moyenne annuelle
- Pour chaque pixel, la moyenne de toutes les images disponibles est calculée pour obtenir un raster unique par bande.  

### Téléchargement des bandes
- Chaque bande moyenne est exportée au format **GeoTIFF** pour être utilisée dans Python et calculer directement les indices.  

### Base EHCVM
- Source : *Programme d’Harmonisation et de Modernisation des Enquêtes sur les Conditions de Vie des ménages dans les États membres de l’UEMOA*.  

### Limites administratives du Mali
- Source : *GeoBoundaries* (le site GADM étant indisponible) pour correspondre au mieux aux limites observées dans la base EHCVM.

---

## 3. Structure du projet

Le projet est organisé dans le dossier `TP6_Groupe3` avec la structure suivante :  

```
TP6_Groupe3/
│
├─ scripts/
│   ├─ NDVI.ipynb
│   ├─ NDWI.ipynb
│   ├─ NDMI.ipynb
│   ├─ NDBI.ipynb
│   ├─ BSI.ipynb
│   └─ fusion_ehcvm_indices.ipynb
│
└─ outputs/
    ├─ NDVI/
    ├─ NDWI/
    ├─ NDMI/
    ├─ NDBI/
    ├─ BSI/
    └─ EHCVM_indices_fusion.csv
│
└─ Readme/
    ├─ NDVI.md
    ├─ NDWI.md
    ├─ NDMI.md
    ├─ NDBI.md
    ├─ BSI.md
```

**Note :** Le dossier `data/` contenant les bandes de Sentinel-2, la base EHCVM ainsi que les limites administratives du Mali n’est pas inclus ici car sa taille dépasse la limite de GitHub.

---

## 4. Description des scripts

### 4.1 NDVI.ipynb
- **Calcul de l’indice :**  
  L’indice NDVI a été calculé à partir des bandes **Red** et **NIR**.  

- **Analyse :**  
  1. **Niveau national :**  
     - Cartographie de l’indice pour l’ensemble du pays.  
     - Histogramme de la distribution de l’indice au niveau national.  
  2. **Niveau régional :**  
     - Calcul de la moyenne de l’indice par région.  
     - Cartographie des valeurs régionales.  
     - Barplot représentant la moyenne de l’indice par région.  
  3. **Niveau départemental :**  
     - Calcul de la moyenne de l’indice par département.  
     - Carte des valeurs départementales.  
     - Barplot correspondant.  
     - Export des résultats sous forme de **CSV** (`NDVI_departements.csv`) dans le dossier `outputs/NDVI/`.  

### 4.2 NDWI.ipynb
- **Calcul de l’indice :**  
  L’indice NDWI a été calculé à partir des bandes **Green** et **NIR**.  
- **Analyse :** Même méthodologie que pour NDVI (national, régional, départemental) avec cartes, histogrammes/barplots et export CSV dans `outputs/NDWI/`.  

### 4.3 NDMI.ipynb
- **Calcul de l’indice :**  
  L’indice NDMI a été calculé à partir des bandes **NIR** et **SWIR**.  
- **Analyse :** Idem que NDVI avec export CSV dans `outputs/NDMI/`.  

### 4.4 NDBI.ipynb
- **Calcul de l’indice :**  
  L’indice NDBI a été calculé à partir des bandes **NIR** et **SWIR**.  
- **Analyse :** Idem que NDVI avec export CSV dans `outputs/NDBI/`.  

### 4.5 BSI.ipynb
- **Calcul de l’indice :**  
  L’indice BSI a été calculé à partir des bandes **Blue, Red, NIR et SWIR**.  
- **Analyse :** Idem que NDVI avec export CSV dans `outputs/BSI/`.  

### 4.6 fusion_ehcvm_indices.ipynb
- **Objectif :**  
  Fusionner la base **EHCVM** au niveau départemental avec les indices calculés.  
- **Méthodologie :**  
  - Utilisation des CSV produits par chaque script d’indice (NDVI, NDWI, NDMI, NDBI, BSI).  
  - Fusion avec la base EHCVM pour obtenir un fichier final `EHCVM_indices_fusion.csv` dans `outputs/`.  

**Note sur le dossier Readme :** 
Le dossier **Readme** contient les fichiers : `NDVI.md`, `NDWI.md`, `NDMI.md`, `NDBI.md`, `BSI.md`  
- Chaque fichier fournit :  
  - La **description** de l’indice  
  - La **méthodologie de calcul**  
  - La **formule mathématique** utilisée pour le calcul de l’indice
---