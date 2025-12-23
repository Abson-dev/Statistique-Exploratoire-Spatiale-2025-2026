// ============================================================================
// ANALYSE COMPLETE INDICES SPECTRAUX - NIGER
// Sentinel-2 + MODIS LST + Statistiques + Cartographie + Export EHCVM
// Periode : Juin-Septembre 2022
// ============================================================================

// ----------------------------------------------------------------------------
// 0. CONFIGURATION
// ----------------------------------------------------------------------------

var CONFIG = {
  dateDebut: '2022-06-01',
  dateFin: '2022-09-30',
  cloudThreshold: 20,
  exportFolder: 'GEE_Niger_Analyse',
  scale: 100,  // Resolution pour les stats (100m pour equilibrer vitesse/precision)
  scaleExport: 10  // Resolution pour les exports raster
};

print('========================================');
print('CONFIGURATION');
print('========================================');
print('Periode:', CONFIG.dateDebut, 'au', CONFIG.dateFin);
print('Seuil nuages:', CONFIG.cloudThreshold, '%');
print('Dossier export:', CONFIG.exportFolder);
print('');

// ----------------------------------------------------------------------------
// 1. CHARGER LES LIMITES ADMINISTRATIVES
// ----------------------------------------------------------------------------

print('========================================');
print('LIMITES ADMINISTRATIVES');
print('========================================');

// Pays (ADM0)
var niger = ee.FeatureCollection('FAO/GAUL/2015/level0')
  .filter(ee.Filter.eq('ADM0_NAME', 'Niger'));

// Regions (ADM1)
var regions = ee.FeatureCollection('FAO/GAUL/2015/level1')
  .filter(ee.Filter.eq('ADM0_NAME', 'Niger'));

// Departements (ADM2)
var departements = ee.FeatureCollection('FAO/GAUL/2015/level2')
  .filter(ee.Filter.eq('ADM0_NAME', 'Niger'));

print('Pays charge');
print('Nombre de regions:', regions.size());
print('Nombre de departements:', departements.size());
print('');

// Centrer la carte
Map.centerObject(niger, 6);

// Afficher les limites
Map.addLayer(niger, {color: 'black'}, 'Niger', false);
Map.addLayer(regions, {color: 'blue'}, 'Regions', false);
Map.addLayer(departements, {color: 'red'}, 'Departements', false);

// ----------------------------------------------------------------------------
// 2. CHARGER ET TRAITER SENTINEL-2
// ----------------------------------------------------------------------------

print('========================================');
print('SENTINEL-2');
print('========================================');

// Fonction pour selectionner les bandes
function selectBands(image) {
  return image.select(['B2', 'B3', 'B4', 'B8', 'B11'])
    .copyProperties(image, ['system:time_start']);
}

// Charger la collection
var s2 = ee.ImageCollection('COPERNICUS/S2_SR')
  .filterBounds(niger)
  .filterDate(CONFIG.dateDebut, CONFIG.dateFin)
  .filter(ee.Filter.lt('CLOUDY_PIXEL_PERCENTAGE', CONFIG.cloudThreshold))
  .map(selectBands);

print('Nombre d\'images trouvees:', s2.size());

// Creer le composite
var composite = s2.median().clip(niger);

// Extraire les bandes
var B2 = composite.select('B2');
var B3 = composite.select('B3');
var B4 = composite.select('B4');
var B8 = composite.select('B8');
var B11 = composite.select('B11');

// Visualiser RGB
var rgbVis = {
  bands: ['B4', 'B3', 'B2'],
  min: 0,
  max: 3000,
  gamma: 1.4
};
Map.addLayer(composite, rgbVis, 'Sentinel-2 RGB', false);

print('Composite Sentinel-2 cree');
print('');

// ----------------------------------------------------------------------------
// 3. CALCULER LES INDICES SPECTRAUX
// ----------------------------------------------------------------------------

print('========================================');
print('CALCUL DES INDICES');
print('========================================');

// NDVI - Normalized Difference Vegetation Index
var NDVI = B8.subtract(B4)
  .divide(B8.add(B4).add(0.0001))
  .rename('NDVI')
  .clip(niger);

// EVI - Enhanced Vegetation Index
var EVI = B8.subtract(B4)
  .divide(B8.add(B4.multiply(6)).subtract(B2.multiply(7.5)).add(1).add(0.0001))
  .multiply(2.5)
  .rename('EVI')
  .clip(niger);

// NDWI - Normalized Difference Water Index
var NDWI = B3.subtract(B8)
  .divide(B3.add(B8).add(0.0001))
  .rename('NDWI')
  .clip(niger);

// NDMI - Normalized Difference Moisture Index
var NDMI = B8.subtract(B11)
  .divide(B8.add(B11).add(0.0001))
  .rename('NDMI')
  .clip(niger);

// MDVI - Modified Difference Vegetation Index
var MDVI = B8.multiply(2).subtract(B4)
  .divide(B8.multiply(2).add(B4).add(0.0001))
  .rename('MDVI')
  .clip(niger);

print('NDVI calcule (Vegetation)');
print('EVI calcule (Vegetation amelioree)');
print('NDWI calcule (Eau)');
print('NDMI calcule (Humidite)');
print('MDVI calcule (Vegetation modifiee)');
print('');

// Combiner tous les indices
var indices = NDVI.addBands(EVI).addBands(NDWI).addBands(NDMI).addBands(MDVI);

// ----------------------------------------------------------------------------
// 4. CHARGER MODIS LST
// ----------------------------------------------------------------------------

print('========================================');
print('MODIS LST');
print('========================================');

var modis = ee.ImageCollection('MODIS/061/MOD11A2')
  .filterBounds(niger)
  .filterDate(CONFIG.dateDebut, CONFIG.dateFin)
  .select('LST_Day_1km');

var LST = modis.mean()
  .multiply(0.02)
  .subtract(273.15)
  .rename('LST')
  .clip(niger);

print('LST calculee (Temperature de surface en degres C)');
print('');

// Ajouter LST aux indices
var indicesComplet = indices.addBands(LST);

// ----------------------------------------------------------------------------
// 5. VISUALISATIONS SUR LA CARTE
// ----------------------------------------------------------------------------

print('========================================');
print('VISUALISATIONS');
print('========================================');

// Palettes
var ndviPalette = ['brown', 'yellow', 'lightgreen', 'green', 'darkgreen'];
var eviPalette = ['white', 'lightgreen', 'green', 'darkgreen'];
var ndwiPalette = ['brown', 'tan', 'white', 'lightblue', 'blue'];
var ndmiPalette = ['red', 'orange', 'yellow', 'lightgreen', 'green'];
var mdviPalette = ['brown', 'yellow', 'green', 'darkgreen'];
var lstPalette = ['blue', 'cyan', 'yellow', 'orange', 'red'];

// Ajouter les couches
Map.addLayer(NDVI, {min: 0, max: 0.8, palette: ndviPalette}, 'NDVI', false);
Map.addLayer(EVI, {min: 0, max: 1, palette: eviPalette}, 'EVI', false);
Map.addLayer(NDWI, {min: -0.5, max: 0.5, palette: ndwiPalette}, 'NDWI', false);
Map.addLayer(NDMI, {min: -0.5, max: 0.5, palette: ndmiPalette}, 'NDMI', false);
Map.addLayer(MDVI, {min: 0, max: 0.8, palette: mdviPalette}, 'MDVI', false);
Map.addLayer(LST, {min: 20, max: 45, palette: lstPalette}, 'LST', false);

print('6 couches ajoutees a la carte');
print('');

// ----------------------------------------------------------------------------
// 6. STATISTIQUES PAR DEPARTEMENT
// ----------------------------------------------------------------------------

print('========================================');
print('EXTRACTION PAR DEPARTEMENT');
print('========================================');

// Fonction pour calculer les statistiques
var calculerStats = function(feature) {
  var stats = indicesComplet.reduceRegion({
    reducer: ee.Reducer.mean()
      .combine({reducer2: ee.Reducer.stdDev(), sharedInputs: true})
      .combine({reducer2: ee.Reducer.min(), sharedInputs: true})
      .combine({reducer2: ee.Reducer.max(), sharedInputs: true}),
    geometry: feature.geometry(),
    scale: CONFIG.scale,
    maxPixels: 1e13
  });
  
  return feature.set(stats);
};

// Calculer pour les departements
var statsDept = departements.map(calculerStats);

print('Statistiques calculees pour', departements.size(), 'departements');
print('');

// Verifier un exemple
var exemple = statsDept.first();
print('Exemple - Premier departement:');
print(exemple);

// ----------------------------------------------------------------------------
// 7. STATISTIQUES PAR REGION
// ----------------------------------------------------------------------------

print('========================================');
print('EXTRACTION PAR REGION');
print('========================================');

var statsRegion = regions.map(calculerStats);

print('Statistiques calculees pour', regions.size(), 'regions');
print('');

// ----------------------------------------------------------------------------
// 8. STATISTIQUES GLOBALES NIGER
// ----------------------------------------------------------------------------

print('========================================');
print('STATISTIQUES GLOBALES NIGER');
print('========================================');

var statsNiger = indicesComplet.reduceRegion({
  reducer: ee.Reducer.mean()
    .combine({reducer2: ee.Reducer.stdDev(), sharedInputs: true})
    .combine({reducer2: ee.Reducer.min(), sharedInputs: true})
    .combine({reducer2: ee.Reducer.max(), sharedInputs: true}),
  geometry: niger.geometry(),
  scale: CONFIG.scale,
  maxPixels: 1e13
});

print('NDVI moyen Niger:', statsNiger.get('NDVI_mean'));
print('EVI moyen Niger:', statsNiger.get('EVI_mean'));
print('NDWI moyen Niger:', statsNiger.get('NDWI_mean'));
print('NDMI moyen Niger:', statsNiger.get('NDMI_mean'));
print('MDVI moyen Niger:', statsNiger.get('MDVI_mean'));
print('LST moyenne Niger:', statsNiger.get('LST_mean'));
print('');

// Superficie
var superficie = niger.geometry().area().divide(1e6);
print('Superficie Niger (km2):', superficie);
print('');

// ----------------------------------------------------------------------------
// 9. CREER LES CARTES CHOROPETHES
// ----------------------------------------------------------------------------

print('========================================');
print('CREATION DES CARTES CHOROPETHES');
print('========================================');

// Fonction simplifiee pour creer une carte choroplethe
var creerCarte = function(fc, propriete, palette, min, max) {
  // Creer les intervalles de classes
  var nbClasses = palette.length;
  var intervalle = (max - min) / nbClasses;
  
  var styled = fc.map(function(feature) {
    var valeur = ee.Number(feature.get(propriete));
    
    // Calculer l'indice de couleur
    var index = valeur.subtract(min).divide(intervalle).floor().int();
    index = index.max(0).min(nbClasses - 1);
    
    // Obtenir la couleur
    var couleur = ee.List(palette).get(index);
    
    // Retourner la feature avec la couleur
    return feature.set('color', couleur);
  });
  
  // Appliquer le style
  return styled.style({
    color: 'black',
    width: 1,
    fillColor: ee.String(styled.first().get('color')).cat('80')  // Ajouter transparence
  });
};

// Version alternative : Utiliser paint pour colorier
var creerCarteAlternative = function(fc, propriete, palette, min, max) {
  var nbClasses = palette.length;
  var intervalle = (max - min) / nbClasses;
  
  // Creer une image vide
  var image = ee.Image(0).byte();
  
  // Pour chaque classe de couleur
  for (var i = 0; i < nbClasses; i++) {
    var minClasse = min + i * intervalle;
    var maxClasse = min + (i + 1) * intervalle;
    
    // Filtrer les features dans cette classe
    var features = fc.filter(
      ee.Filter.and(
        ee.Filter.gte(propriete, minClasse),
        ee.Filter.lt(propriete, maxClasse)
      )
    );
    
    // Peindre avec la couleur
    image = image.paint(features, palette[i]);
  }
  
  return image;
};

// Creer les cartes (methode alternative plus stable)
var carteDeptNDVI = ee.Image().byte().paint({
  featureCollection: statsDept,
  color: 'NDVI_mean'
}).visualize({
  min: 0,
  max: 0.8,
  palette: ndviPalette
});

var carteDeptEVI = ee.Image().byte().paint({
  featureCollection: statsDept,
  color: 'EVI_mean'
}).visualize({
  min: 0,
  max: 1,
  palette: eviPalette
});

var carteDeptLST = ee.Image().byte().paint({
  featureCollection: statsDept,
  color: 'LST_mean'
}).visualize({
  min: 20,
  max: 45,
  palette: lstPalette
});

// Ajouter les limites des departements en noir
var limitesDept = ee.Image().byte().paint({
  featureCollection: departements,
  color: 0,
  width: 1
});

Map.addLayer(carteDeptNDVI, {}, 'Carte NDVI Departements', false);
Map.addLayer(carteDeptEVI, {}, 'Carte EVI Departements', false);
Map.addLayer(carteDeptLST, {}, 'Carte LST Departements', false);
Map.addLayer(limitesDept, {palette: 'black'}, 'Limites Departements', false);

print('Cartes choropethes creees');
print('');

// ----------------------------------------------------------------------------
// 10. EXPORTS - TABLES CSV
// ----------------------------------------------------------------------------

print('========================================');
print('PREPARATION DES EXPORTS - TABLES');
print('========================================');

// Export statistiques departements
Export.table.toDrive({
  collection: statsDept,
  description: 'Niger_Stats_Departements_2022',
  folder: CONFIG.exportFolder,
  fileNamePrefix: 'Niger_Stats_Departements_2022',
  fileFormat: 'CSV',
  selectors: ['ADM0_NAME', 'ADM1_NAME', 'ADM2_NAME', 'ADM2_CODE',
              'NDVI_mean', 'NDVI_stdDev', 'NDVI_min', 'NDVI_max',
              'EVI_mean', 'EVI_stdDev', 'EVI_min', 'EVI_max',
              'NDWI_mean', 'NDWI_stdDev', 'NDWI_min', 'NDWI_max',
              'NDMI_mean', 'NDMI_stdDev', 'NDMI_min', 'NDMI_max',
              'MDVI_mean', 'MDVI_stdDev', 'MDVI_min', 'MDVI_max',
              'LST_mean', 'LST_stdDev', 'LST_min', 'LST_max']
});

// Export statistiques regions
Export.table.toDrive({
  collection: statsRegion,
  description: 'Niger_Stats_Regions_2022',
  folder: CONFIG.exportFolder,
  fileNamePrefix: 'Niger_Stats_Regions_2022',
  fileFormat: 'CSV',
  selectors: ['ADM0_NAME', 'ADM1_NAME', 'ADM1_CODE',
              'NDVI_mean', 'NDVI_stdDev', 'NDVI_min', 'NDVI_max',
              'EVI_mean', 'EVI_stdDev', 'EVI_min', 'EVI_max',
              'NDWI_mean', 'NDWI_stdDev', 'NDWI_min', 'NDWI_max',
              'NDMI_mean', 'NDMI_stdDev', 'NDMI_min', 'NDMI_max',
              'MDVI_mean', 'MDVI_stdDev', 'MDVI_min', 'MDVI_max',
              'LST_mean', 'LST_stdDev', 'LST_min', 'LST_max']
});

print('Export tables prepare');
print('  1. Niger_Stats_Departements_2022.csv');
print('  2. Niger_Stats_Regions_2022.csv');
print('');

// ----------------------------------------------------------------------------
// 11. EXPORTS - RASTERS (INDICES)
// ----------------------------------------------------------------------------

print('========================================');
print('PREPARATION DES EXPORTS - RASTERS');
print('========================================');

var exportParams = {
  folder: CONFIG.exportFolder,
  region: niger.geometry(),
  scale: CONFIG.scaleExport,
  crs: 'EPSG:4326',
  maxPixels: 1e13
};

// NDVI
Export.image.toDrive({
  image: NDVI,
  description: 'Niger_NDVI_2022',
  fileNamePrefix: 'Niger_NDVI_2022',
  folder: exportParams.folder,
  region: exportParams.region,
  scale: exportParams.scale,
  crs: exportParams.crs,
  maxPixels: exportParams.maxPixels
});

// EVI
Export.image.toDrive({
  image: EVI,
  description: 'Niger_EVI_2022',
  fileNamePrefix: 'Niger_EVI_2022',
  folder: exportParams.folder,
  region: exportParams.region,
  scale: exportParams.scale,
  crs: exportParams.crs,
  maxPixels: exportParams.maxPixels
});

// NDWI
Export.image.toDrive({
  image: NDWI,
  description: 'Niger_NDWI_2022',
  fileNamePrefix: 'Niger_NDWI_2022',
  folder: exportParams.folder,
  region: exportParams.region,
  scale: exportParams.scale,
  crs: exportParams.crs,
  maxPixels: exportParams.maxPixels
});

// NDMI
Export.image.toDrive({
  image: NDMI,
  description: 'Niger_NDMI_2022',
  fileNamePrefix: 'Niger_NDMI_2022',
  folder: exportParams.folder,
  region: exportParams.region,
  scale: exportParams.scale,
  crs: exportParams.crs,
  maxPixels: exportParams.maxPixels
});

// MDVI
Export.image.toDrive({
  image: MDVI,
  description: 'Niger_MDVI_2022',
  fileNamePrefix: 'Niger_MDVI_2022',
  folder: exportParams.folder,
  region: exportParams.region,
  scale: exportParams.scale,
  crs: exportParams.crs,
  maxPixels: exportParams.maxPixels
});

// LST
Export.image.toDrive({
  image: LST,
  description: 'Niger_LST_2022',
  fileNamePrefix: 'Niger_LST_2022',
  folder: exportParams.folder,
  region: exportParams.region,
  scale: 1000,  // MODIS native resolution
  crs: exportParams.crs,
  maxPixels: exportParams.maxPixels
});

print('Export rasters prepare');
print('  1. Niger_NDVI_2022.tif');
print('  2. Niger_EVI_2022.tif');
print('  3. Niger_NDWI_2022.tif');
print('  4. Niger_NDMI_2022.tif');
print('  5. Niger_MDVI_2022.tif');
print('  6. Niger_LST_2022.tif');
print('');

// ----------------------------------------------------------------------------
// 12. EXPORTS - BANDES SENTINEL-2 BRUTES
// ----------------------------------------------------------------------------

print('========================================');
print('PREPARATION DES EXPORTS - BANDES S2');
print('========================================');

// B2 (Blue)
Export.image.toDrive({
  image: B2,
  description: 'Niger_S2_B02_2022',
  fileNamePrefix: 'Niger_S2_B02_2022',
  folder: exportParams.folder,
  region: exportParams.region,
  scale: exportParams.scale,
  crs: exportParams.crs,
  maxPixels: exportParams.maxPixels
});

// B3 (Green)
Export.image.toDrive({
  image: B3,
  description: 'Niger_S2_B03_2022',
  fileNamePrefix: 'Niger_S2_B03_2022',
  folder: exportParams.folder,
  region: exportParams.region,
  scale: exportParams.scale,
  crs: exportParams.crs,
  maxPixels: exportParams.maxPixels
});

// B4 (Red)
Export.image.toDrive({
  image: B4,
  description: 'Niger_S2_B04_2022',
  fileNamePrefix: 'Niger_S2_B04_2022',
  folder: exportParams.folder,
  region: exportParams.region,
  scale: exportParams.scale,
  crs: exportParams.crs,
  maxPixels: exportParams.maxPixels
});

// B8 (NIR)
Export.image.toDrive({
  image: B8,
  description: 'Niger_S2_B08_2022',
  fileNamePrefix: 'Niger_S2_B08_2022',
  folder: exportParams.folder,
  region: exportParams.region,
  scale: exportParams.scale,
  crs: exportParams.crs,
  maxPixels: exportParams.maxPixels
});

// B11 (SWIR1)
Export.image.toDrive({
  image: B11,
  description: 'Niger_S2_B11_2022',
  fileNamePrefix: 'Niger_S2_B11_2022',
  folder: exportParams.folder,
  region: exportParams.region,
  scale: 20,  // SWIR native resolution
  crs: exportParams.crs,
  maxPixels: exportParams.maxPixels
});

print('Export bandes S2 prepare');
print('  1. Niger_S2_B02_2022.tif (Blue)');
print('  2. Niger_S2_B03_2022.tif (Green)');
print('  3. Niger_S2_B04_2022.tif (Red)');
print('  4. Niger_S2_B08_2022.tif (NIR)');
print('  5. Niger_S2_B11_2022.tif (SWIR1)');
print('');

// ----------------------------------------------------------------------------
// 13. CREER UN TEMPLATE POUR FUSION EHCVM
// ----------------------------------------------------------------------------

print('========================================');
print('TEMPLATE POUR FUSION EHCVM');
print('========================================');

// Creer une table simplifiee pour faciliter la fusion
var templateEHCVM = statsDept.map(function(feature) {
  return ee.Feature(null, {
    'Pays': feature.get('ADM0_NAME'),
    'Region': feature.get('ADM1_NAME'),
    'Departement': feature.get('ADM2_NAME'),
    'Code_Dept': feature.get('ADM2_CODE'),
    'NDVI': feature.get('NDVI_mean'),
    'EVI': feature.get('EVI_mean'),
    'NDWI': feature.get('NDWI_mean'),
    'NDMI': feature.get('NDMI_mean'),
    'MDVI': feature.get('MDVI_mean'),
    'LST': feature.get('LST_mean'),
    'Annee': 2022,
    'Saison': 'Juin-Septembre'
  });
});

// Export du template
Export.table.toDrive({
  collection: templateEHCVM,
  description: 'Niger_Template_EHCVM_2022',
  folder: CONFIG.exportFolder,
  fileNamePrefix: 'Niger_Template_EHCVM_2022',
  fileFormat: 'CSV'
});

print('Template EHCVM cree');
print('  Fichier: Niger_Template_EHCVM_2022.csv');
print('');
print('INSTRUCTIONS FUSION EHCVM:');
print('1. Telecharger Niger_Template_EHCVM_2022.csv');
print('2. Dans votre logiciel (R, Stata, Python):');
print('   - Charger EHCVM');
print('   - Charger le template');
print('   - Fusionner sur "Departement" ou "Region"');
print('3. Variables ajoutees: NDVI, EVI, NDWI, NDMI, MDVI, LST');
print('');

// ----------------------------------------------------------------------------
// 14. RESUME FINAL ET INSTRUCTIONS
// ----------------------------------------------------------------------------

print('========================================');
print('         RESUME FINAL');
print('========================================');
print('');
print('DONNEES TRAITEES:');
print('  Images Sentinel-2:', s2.size());
print('  Periode:', CONFIG.dateDebut, 'au', CONFIG.dateFin);
print('  Departements:', departements.size());
print('  Regions:', regions.size());
print('');
print('INDICES CALCULES:');
print('  1. NDVI - Vegetation');
print('  2. EVI  - Vegetation amelioree');
print('  3. NDWI - Eau');
print('  4. NDMI - Humidite');
print('  5. MDVI - Vegetation modifiee');
print('  6. LST  - Temperature de surface');
print('');
print('EXPORTS PREPARES (13 fichiers):');
print('');
print('TABLES CSV (3):');
print('  1. Niger_Stats_Departements_2022.csv');
print('  2. Niger_Stats_Regions_2022.csv');
print('  3. Niger_Template_EHCVM_2022.csv');
print('');
print('RASTERS INDICES (6):');
print('  4. Niger_NDVI_2022.tif');
print('  5. Niger_EVI_2022.tif');
print('  6. Niger_NDWI_2022.tif');
print('  7. Niger_NDMI_2022.tif');
print('  8. Niger_MDVI_2022.tif');
print('  9. Niger_LST_2022.tif');
print('');
print('RASTERS BANDES S2 (5):');
print('  10. Niger_S2_B02_2022.tif');
print('  11. Niger_S2_B03_2022.tif');
print('  12. Niger_S2_B04_2022.tif');
print('  13. Niger_S2_B08_2022.tif');
print('  14. Niger_S2_B11_2022.tif');
print('');
print('========================================');
print('PROCHAINES ETAPES:');
print('========================================');
print('1. Aller dans "Tasks" (en haut a droite)');
print('2. Cliquer "RUN" sur chaque export (14 au total)');
print('3. Attendre 30-90 minutes');
print('4. Telecharger depuis Google Drive > ' + CONFIG.exportFolder);
print('');
print('POUR LA CARTOGRAPHIE:');
print('5. Ouvrir les fichiers CSV dans Excel/QGIS/R');
print('6. Creer des cartes avec les colonnes *_mean');
print('7. Utiliser les rasters .tif pour cartographie avancee');
print('');
print('POUR FUSION EHCVM:');
print('8. Utiliser Niger_Template_EHCVM_2022.csv');
print('9. Fusionner avec EHCVM sur "Departement"');
print('10. Analyser correlations indices vs variables socio-eco');
print('========================================');

// ----------------------------------------------------------------------------
// FIN DU SCRIPT
// ----------------------------------------------------------------------------