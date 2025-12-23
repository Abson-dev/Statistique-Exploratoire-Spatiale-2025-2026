# README - Travail Pratique N°6
Calcul d'indices spectraux avec le code editor de l'API JavaScript de la plateforme Google Earth Engine.

## 1. Vue d’ensemble

Au cours de ce travail pratique, il était question pour nous d'écrire des scripts permettant le calcul d'indice spectraux pour le Burkina Faso à partir d'images satellitaires.
La granularité attendue correspondait au niveau départemental

## 2. Structure du dépôt


├── data/
│   ├── raw/            # Données brutes et éparses
│   ├── processed/      # Base de données finale après jointure
│
├── src/
│   ├── script_gee_js/  # Scripts Google Earth Engine
│   ├── script_gee_js/  # Jointure
│
├── README.md

## 3. Données

### 3.1 Sources

Images satellitaires : Sentinel - 2 (Projet Copernicus/ESA)
Données administratives : GADM
Données socio-économiques : EHCVM (World Bank Group)

### 3.2 Résolution et période

Résolution spatiale : 20m (Mais analyses multi-échelles sur 50 ou 100m)
Période temporelle : Juillet 2021 – Juillet 2022

### 4. Indices et variables calculés

Indice	Formule	Interprétation	Catégorie
NDVI	(NIR − RED) / (NIR + RED)	Vigueur végétale	Végétation
NDBI	(SWIR − NIR) / (SWIR + NIR)	Zones bâties	Urbanisation
…	…	…	…
etc

### 5. Méthodologie
- Principe clé :
Aucune agrégation n’est réalisée sans inspection préalable de la distribution.

### 6. Reproductibilité
Environnement de travail:
**Langages :** JavaScript (GEE), R (pour jointure)
**Outils :** Google Earth Engine, RStudio

### 8. Limitations

Les indices sont des proxys, pas des mesures directes

### 9. Perspectives

### 10. Auteur & Contact
Auteurs : 
- Lamine DIABANG
- David NGUEAJIO
- Leslye NKWA
- Mouhammet SECK

*Elèves en ISE1 - Cycle Long*
**Institution : ENSAE Dakar**
**ANNEE ACADEMIQUE: 2025/2026**
