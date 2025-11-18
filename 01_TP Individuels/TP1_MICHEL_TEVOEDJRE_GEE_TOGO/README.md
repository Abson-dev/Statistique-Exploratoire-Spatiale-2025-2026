# Analyse de l'Incidence du Paludisme au Togo (2000-2024)

## 🎓 Contexte Académique

**Établissement** : ENSAE Dakar  
**Formation** : ISE 1 Cycle Long  
**Cours** : Statistique Exploratoire Spatiale  
**Année** : 2025-2026  
**Auteur** : Michel TEVOEDJRE

## 📋 Description

Analyse spatiale et temporelle de l'incidence du paludisme à *Plasmodium falciparum* au Togo (2000-2024) avec Google Earth Engine. Données du Malaria Atlas Project, analyses multi-échelles (nationale, régionale, sous-préfectorale).

## 🗂️ Structure

```
TP1_MICHEL_TEVOEDJRE_GEE_TOGO/
├── Script_GEE_Michel_TEVOEDJRE.txt    # Script principal GEE
└── data/
    ├── clippedlayers/                  # Rasters d'incidence (25 fichiers .tiff)
    └── gadm41_TGO_shp/                 # Shapefiles administratifs (4 niveaux)
```

## 🚀 Utilisation

1. **Compte Google Earth Engine** : [earthengine.google.com](https://earthengine.google.com/)
2. **Importer les assets** dans votre projet GEE (shapefiles + rasters)
3. **Modifier le script** :
   ```javascript
   var YEAR = 2024;  // Année à analyser (2000-2024)
   var path = "projects/YOUR_PROJECT/assets/";  // Votre chemin
   ```
4. **Exécuter** dans le Code Editor

## 📊 Fonctionnalités

### Analyses Statistiques
- Statistiques nationales (min, max, moyenne, écart-type)
- Incidence par région et sous-préfecture
- Évolution temporelle 2000-2024
- Calcul de tendances et variations

### Visualisations
- Cartes interactives avec palette de couleurs
- Graphique d'évolution temporelle
- Légende personnalisée
- Limites administratives (pays, régions, sous-préfectures)

## 🎯 Objectifs Pédagogiques

- Manipulation de données géospatiales (shapefiles, rasters)
- Calculs de statistiques zonales
- Visualisation cartographique
- Analyse temporelle et interprétation épidémiologique

## 🔧 Personnalisation

```javascript
// Changer l'année
var YEAR = 2020;

// Modifier la palette
var palette = ['#ffffcc', '#ffeda0', '#fed976', '#feb24c', 
               '#fd8d3c', '#fc4e2a', '#e31a1c', '#bd0026', '#800026'];

// Exporter les résultats
Export.table.toDrive({
  collection: incidenceRegions,
  description: 'Incidence_Regions_' + YEAR
});
```

## 📚 Sources

- **Données** : [Malaria Atlas Project](https://malariaatlas.org/)
- **Géographie** : [GADM](https://gadm.org/)
- **Documentation** : [Google Earth Engine](https://developers.google.com/earth-engine/)

## 📝 Livrables

1. Script GEE commenté et fonctionnel
2. Données spatiales (shapefiles + rasters)
3. Documentation (README)

## ⚠️ Notes

- Unité : cas pour 1000 habitants par an
- Résolution : ~1 km
- Période : 2000-2024 (25 années)
- Respecter l'intégrité académique et citer les sources