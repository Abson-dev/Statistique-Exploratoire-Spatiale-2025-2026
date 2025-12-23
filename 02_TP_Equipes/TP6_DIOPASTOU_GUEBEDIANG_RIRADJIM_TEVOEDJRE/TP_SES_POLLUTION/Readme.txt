# Analyse croisée des indices Sentinel-2 et des conditions de vie (EHCVM – Mali, 2021)

## 1. Objectif du projet

Ce projet vise à explorer les relations potentielles entre :
- des **indices spectraux Sentinel-2** (NDVI, NDBI, NDMI, SAVI, UI),
- et des **indicateurs socio-économiques issus de l’enquête EHCVM 2021** au Mali.

L’analyse se situe volontairement à un **niveau macro-spatial**, compte tenu des limites d’appariement spatial entre les deux sources.

---

## 2. Données utilisées

### 2.1 Données Sentinel-2
- Source : Google Earth Engine
- Résolution : agrégée par polygones administratifs
- Indices :
  - **NDVI** = (NIR − Red) / (NIR + Red)
  - **NDBI** = (SWIR − NIR) / (SWIR + NIR)
  - **NDMI** = (NIR − SWIR) / (NIR + SWIR)
  - **SAVI** = ((NIR − Red) / (NIR + Red + L)) × (1 + L)
  - **UI** = indicateur composite d’urbanisation

### 2.2 Données EHCVM
- Source : Enquête Harmonisée sur les Conditions de Vie des Ménages
- Niveau initial : ménage
- Variables :
  - taille du ménage
  - accès à l’électricité
  - accès à des toilettes améliorées
  - gestion des ordures
- Agrégation : moyenne par grappe

---

## 3. Méthodologie

1. Nettoyage et harmonisation des formats
2. Reconstruction robuste de l’export CSV Sentinel (mal formé)
3. Conversion des géométries GeoJSON en objets Shapely
4. Validation géométrique
5. Analyse descriptive des indices
6. Analyse de cohérence interne (corrélations entre indices)
7. Comparaison macro avec les statistiques EHCVM

---

## 4. Analyses réalisées (approche conditionnelle)

Les analyses permettent :
- d’identifier des **tendances environnementales moyennes**,
- d’évaluer la **cohérence physique des indices Sentinel**,
- d’explorer des **associations potentielles** avec les conditions de vie.

Toute interprétation causale ou prédictive est volontairement exclue.

---

## 5. Limites

- Absence d’appariement spatial fin ménage–pixel
- Différences d’échelle spatiale et conceptuelle
- Résultats interprétés comme **exploratoires**

---

## 6. Sorties

- `Sentinel_Mali_2021_READY.geojson`
- `Sentinel_Mali_2021_READY.csv`
- Statistiques descriptives
- Matrices de corrélation

---