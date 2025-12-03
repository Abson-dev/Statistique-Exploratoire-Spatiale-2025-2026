# TP4 de Statistique exploratoire spatiale : Identification des terres Arables au Burundi

---

## Membres de l'équipe : 

- Herman Parfait NGAKE YAMAHA
- Joe Young Veridique Gabriel DIOP
- David Landry AGNANGMA SANAM
- Cheikh Ahmadou Bamba FALL
- Gérald Guerngue ADDJITA

**Superviseur :** M. HEMA

**Année académique : 2025 - 2026**

---

## 1. Description du Projet

Ce projet vise à réaliser une **analyse spatiale des terres arables au Burundi** afin d’estimer la superficie totale des zones réellement aptes à l’agriculture.  L’approche consiste à identifier et cartographier les terres cultivables en excluant les espaces non exploitables ou soumis à des restrictions légales. L’ensemble du travail est réalisé sur la plateforme **Google Earth Engine (GEE)** à l’aide du langage **JavaScript**, en mobilisant à la fois des données satellitaires (terres cultivées, couverture forestière, eaux permanentes, surfaces imperméables et pentes raides) et des données vectorielles (limites administratives et zones protégées). Les résultats produits permettent de générer des statistiques précises par niveau administratif, aussi bien à l’échelle des **provinces (ADMIN1)** qu’à celle des **communes (ADMIN2)**.


---

## 2. Sources de données

| Source de Données | Rôle (Couche) | GEE Asset ou Référence | Description |
|-------------------|---------------|------------------------|-------------|
| **GADM** | Limites Administratives | Assets privés (Level 0, 1, 2) | Délimitation de la Zone d'Intérêt (Burundi). Utilisé pour l'agrégation statistique. |
| **GFSAD** | Terres Cultivées | Asset privé (`GFSAD_Burundi_2015`) | Définition de la **Base Arable** (zones actuellement cultivées). |
| **Hansen GFC** | Forêts Déboisées | `UMD/hansen/global_forest_change_2015_v1_3` | Définition de la **Base Arable** (forêts perdues entre 2000 et 2015). |
| **WDPA** | Zones Protégées | `WCMC/WDPA/current/polygons` | **Masque d'Exclusion** (légal). |
| **JRC GSW** | Eaux Permanentes | `JRC/GSW1_4/GlobalSurfaceWater` | **Masque d'Exclusion** (physique, occurrence > 75%). |
| **SRTM** | Topographie | `USGS/SRTMGL1_003` | **Masque d'Exclusion** (pentes > 15°). |
| **GMIS** | Surfaces Imperméables | Asset privé (`GMIS_Burundi`) | **Masque d'Exclusion** (zones bâties/routes, > 10% d'imperméabilité). |


**Remarque :** Les assets privés sont dans le dossier **data**, contenu dans le drive dont le lien est le suivant : https://drive.google.com/drive/folders/1G8ptfyG6sN0w7afHuUuvsxSLpf_WW-jk?usp=sharing.


**Datation des données :**

Les données administratives et certaines couches géospatiales utilisées sont datées de **2015**.  
À cette époque, avant la reforme qui a conduit à la création d'une nouvelle province de Rumonge, le Burundi comptait **17 provinces et 133 communes**.  
Or, en **2025**, le pays est réorganisé en **5 provinces et 42 communes**.  
Les résultats doivent donc être interprétés comme une **photographie de la situation géographique de 2015**, même si le projet est réalisé en 2025.

---

## 3. Structure du Projet
  

```
TP4_SES_2025_2026_Groupe_1/
│
│
├── script/
│    │
│    └── script.js                                # Le code source JavaScript pour Google Earth Engine
│
│
├── outputs/
│    │
│    ├── Stats_Communes.xlsx                      # Superficie total, superficie arable et ratio arable par commune
│    │
│    └── Stats_Provinces.xlsx                     # Superficie total, superficie arable et ratio arable par province
│   
│
│─── README.md
```


---
  
## 4. Fonctionnalités du script GEE (`script.js`)

Le script principal est structuré en plusieurs parties afin d'éffectuer un traitement  méthodique des données géospatiales et restituer les résultats sous forme de statistiques et de cartes interactives.

### 4.1. Chaîne de traitement des Images Raster

La première partie du script se concentre sur le traitement et la combinaison des images satellitaires et topographiques :

**Pré-traitement et Masquage** 

Toutes les couches d'entrée sont converties en masques binaires (valeur 1 pour la présence de la caractéristique, 0 pour son absence). Une attention particulière est portée à la couche GMIS (Surfaces Imperméables) dont les valeurs spéciales (`255` pour NoData et `200` pour Non-HBASE) sont nettoyées pour garantir la précision du masque d'exclusion. Cette étape assure que seules les zones réellement imperméables (> 10%) sont considérées.

**Calcul de la base arable**  

La base potentielle de terres arables est établie par l'union logique (opération OR) de deux composantes :
- Les zones actuellement cultivées (GFSAD 2015) ;
- Les zones de déforestation récente (Hansen GFC 2000-2015).

Cette approche capture à la fois les terres agricoles existantes et les zones récemment déboisées qui pourraient être converties en terres cultivables.

**Application des exclusions**  

Une zone d'exclusion totale est créée par l'union (OR) de quatre masques de contraintes :
- Eaux permanentes (occurrence > 75%) ;
- Pentes fortes (> 15°) ;
- Zones protégées (aires de conservation légale) ;
- Surfaces imperméables (zones bâties et routes > 10%).

Les **Terres arables finales** sont obtenues en retirant cette zone d'exclusion totale de la base arable. Seules les zones qui sont à la fois potentiellement arables et non soumises à des contraintes physiques ou légales sont conservées.

### 4.2. Visualisation cartographique et interactivité

L'interface cartographique offre plusieurs outils pour l'analyse et l'exploration des résultats de manière interactive :

**Superposition multi-couches**  

Toutes les couches intermédiaires (limites administratives, terres cultivées, forêts déboisées, pentes, zones protégées, eaux permanentes et surfaces imperméables) ainsi que les couches dérivées (Base arable, zone d'exclusion totale et terres arables finales) sont disponibles sur la carte. L'utilisateur peut activer/désactiver chaque couche pour vérifier visuellement l'application des critères d'inclusion et d'exclusion.

**Panneau de statistiques nationales** 

Un panneau dédié (coin supérieur gauche) affiche en temps réel les indicateurs clés à l'échelle nationale :
- Nombre de provinces et de communes ;
- Superficie totale du Burundi (km²) ;
- Superficie totale des terres arables (km²) ;
- Ratio national (% du territoire national classé comme terre arable).

Ces statistiques agrégées fournissent une vue d'ensemble immédiate du potentiel agricole du pays.

**Fonctionnalité d'interrogation par Clic**  

L'utilisateur peut cliquer sur n'importe quel point de la carte pour obtenir instantanément les statistiques locales. Un panneau interactif (coin inférieur gauche) s'actualise et affiche :
- **Pour la commune** : Nom, superficie totale, superficie arable, ratio arable (%) ;
- **Pour la province** : Nom, superficie totale, superficie arable, ratio arable (%).

Cette fonctionnalité permet d'identifier rapidement les unités administratives ayant un fort ou faible potentiel agricole sans quitter l'interface cartographique.

### 4.3. Restitution statistique et exportations

Le script effectue une agrégation statistique complète des résultats pour faciliter la planification et l'analyse comparative :

**Graphiques de Classement (Console GEE)**  

Le script génère automatiquement six diagrammes en barres affichés dans la console GEE :

*Par Province :*
- Top 5 des provinces par superficie arable (km²) ;
- Top 5 des provinces par ratio arable (%) ;
- Top 5 des provinces par superficie totale (km²).

*Par Commune :*
- Top 5 des communes par superficie arable (km²) ;
- Top 5 des communes par ratio arable (%) ;
- Top 5 des communes par superficie totale (km²).

Ces visualisations permettent d'identifier rapidement les zones prioritaires pour l'expansion agricole et de comparer les performances relatives des différentes unités administratives.

**Exportation des données (CSV vers Google Drive)**  

Deux fichiers CSV sont automatiquement générés et prêts à être exportés dans le dossier `TP4_SES_Groupe_1_outputs` sur Google Drive :

1. **`Stats_Communes.csv`**  

   Contient pour chacune des 133 communes :
   - Type (Commune) ;
   - NOM (nom de la commune) ;
   - NOM_PROVINCE (province d'appartenance) ;
   - area_total_km2 (superficie totale en km²) ;
   - arable_km2 (superficie arable en km²) ;
   - ratio_percent (ratio arable en %).

2. **`Stats_Provinces.csv`**  

   Contient pour chacune des 17 provinces :
   - Type (Province) ;
   - NOM (nom de la province) ;
   - area_total_km2 (superficie totale en km²) ;
   - arable_km2 (superficie arable en km²) ;
   - ratio_percent (ratio arable en %).


Ces exports garantissent :
- La **traçabilité** des résultats d'analyse ;
- L'**interopérabilité** avec d'autres outils (QGIS, Excel, R, Python) ;
- L'**intégration** dans des systèmes de planification et d'aide à la décision.

---

  
  ## 5. Lien du Projet Google Earth Engine

  Le script complet et la carte interactive sont disponibles sur Google Earth Engine.
  
  Lien : **https://code.earthengine.google.com/2b871ebaf17a088f1217680504f3abdc**


  Le professeur encadrant est déjà ajouté comme éditeur au projet via son adresse e-mail.

---
  
  ## 6. Références
- **GADM :** https://gadm.org/
- **GFSAD 30 m :** [Global Food Security-support Analysis Data](https://search.earthdata.nasa.gov/search)
- **Hansen Global Forest Change :** https://earthenginepartners.appspot.com/science-2013-global-forest
- **JRC Global Surface Water :** https://global-surface-water.appspot.com/
- **GMIS :** https://data.nasa.gov/dataset/global-man-made-impervious-surface-gmis-dataset-from-landsat
- **WDPA :** https://www.protectedplanet.net/
- **Google Earth Engine :** https://earthengine.google.com/
