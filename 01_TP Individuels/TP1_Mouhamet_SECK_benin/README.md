# TP1 – Analyse Spatiale du Bénin : WorldPop (2024) & Prévalence du Paludisme (2000–2024)

Ce projet constitue une introduction à l’analyse spatiale en Python dans le cadre du TP1 de Statistiques Exploratoires Spatiales.  
Il porte sur l’importation, l’exploration et la visualisation de données géographiques appliquées au **Bénin**, incluant :

- les limites administratives (GADM),
- la densité de population WorldPop 2024,
- les rasters annuels du taux de prévalence du paludisme (Plasmodium falciparum) de 2000 à 2024.

---

## 📂 Structure du projet
```
TP1/
│
├── data/
│ ├── gadm/ # Limites administratives (GADM)
│ ├── worldpop/ # Population 2024 (WorldPop)
│ └── malaria/ # Rasters MAP 2000–2024 (Malaria Atlas Project)
│
├── TP1_Mouhamet_SECK.ipynb # Notebook d'analyse
└── README.md # Documentation du TP
```

---

## 🧰 Bibliothèques utilisées

- **geopandas** : manipulation des données vectorielles (shapefiles)  
- **rasterio** : lecture et traitement des données raster (GeoTIFF)  
- **numpy** : analyses numériques (masquage NoData, statistiques)  
- **matplotlib** : visualisation et production des cartes  
- **os / re** : gestion des fichiers et extraction automatique

---

## 📌 Objectifs du TP

1. **Importer et inspecter les données spatiales** (vectorielles & raster).  
2. **Visualiser les limites administratives** du Bénin.  
3. **Afficher et analyser la densité de population WorldPop 2024.**  
4. **Charger et comparer les cartes de prévalence du paludisme** entre 2000, 2012 et 2024.  
5. **Étudier l’évolution temporelle** (2000–2024) du taux moyen.  
6. **Croiser population vs prévalence** pour mettre en évidence la structure spatiale du risque.  

---

## 🗺️ Illustrations principales

- Cartes GADM du Bénin (admin0–admin2)  
- Carte de densité de population (WorldPop 2024)  
- Comparaison Pf parasite rate (2000–2012–2024)  
- Évolution temporelle du taux moyen annuel  
- Comparaison Population 2024 vs Prévalence 2024  

---

## 📥 Téléchargement des données

- **GADM** : https://gadm.org  
- **WorldPop 2024 – Population** : https://www.worldpop.org  
- **Malaria Atlas Project (MAP)** : https://data.malariaatlas.org  

---


