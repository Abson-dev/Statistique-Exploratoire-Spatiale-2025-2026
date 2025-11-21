///////////////////////////////////////////////////////////////////////////////////////////////
////      ECOLE NATIONALE DE LA STATISTIQUE ET DE L'ANALYSE ECONOMIQUE PIERRE NDIAYE     /////
////          COURS DE STATISTIQUES EXPLORATOIRE ET SPATIALE - ISE1_CYCLE LONG           /////
////                           ENSEIGNANT: M. HEMA Aboubacar                              /////
////                   TP1_GOOGLE EARTH ENGINE AVEC JAVASCRIPT                            /////
////                   PAYS : Cameroun                                                    /////
////                   VERSION FINALE - Nombre de cas uniquement                         /////
///////////////////////////////////////////////////////////////////////////////////////////////

// ============================================================================
// 1. INITIALISATION ET CHARGEMENT DES DONNÉES
// ============================================================================

print('═══════════════════════════════════════════════════════════');
print('🚀 SYSTÈME D\'ANALYSE PALUDISME');
print('═══════════════════════════════════════════════════════════\n');

// Charger les données administratives
var pays = ee.FeatureCollection("projects/userscheikhthioub501/assets/gadm41_CMR_0");
var regions = ee.FeatureCollection("projects/userscheikhthioub501/assets/gadm41_CMR_1");
var departements = ee.FeatureCollection("projects/userscheikhthioub501/assets/gadm41_CMR_2");

print('✓ Données administratives chargées');

// Charger les données de population WorldPop
var worldpop = ee.Image("projects/userscheikhthioub501/assets/cmr_level0_100m_2000_2020");
print('✓ Données de population chargées');

// Charger une image malaria de référence pour la projection
var malariaRef = ee.Image("projects/userscheikhthioub501/assets/202508_Global_Pf_Incidence_Count_CMR_2000");
var malariaProjection = malariaRef.projection();
var malariaScale = malariaProjection.nominalScale().getInfo();

print('✓ Image de référence malaria chargée');
print('📏 Échelle native malaria:', malariaScale, 'mètres\n');

// ============================================================================
// 2. AGRÉGATION DE LA POPULATION
// ============================================================================

print('⚙ AGRÉGATION DE LA POPULATION...');

var populationAggregated = worldpop
  .reduceResolution({
    reducer: ee.Reducer.sum(),
    maxPixels: 65536
  })
  .reproject({
    crs: malariaProjection,
    scale: malariaScale
  });

print('✅ Agrégation terminée');

// ============================================================================
// 3. CHARGEMENT DES DONNÉES MALARIA (NOMBRE DE CAS)
// ============================================================================

print('\n⚙ CHARGEMENT DES DONNÉES MALARIA (2000-2021)...');

var malariaImages = [];

for (var year = 2000; year <= 2021; year++) {
  var path = "projects/userscheikhthioub501/assets/202508_Global_Pf_Incidence_Count_CMR_" + year;
  
  try {
    var incidenceCount = ee.Image(path)
      .select([0])
      .rename('incidence_count')
      .float();
    
    malariaImages.push(incidenceCount);
    
  } catch (e) {
    print('⚠ Erreur année', year, ':', e);
  }
}

print('✓', malariaImages.length, 'années chargées');

// Variables globales
var currentYear = 2000;
var currentYearIndex = 0;
var currentMalaria = malariaImages[0];
var regionsWithStats = null;

// ============================================================================
// 4. ANALYSE STATISTIQUE RÉGIONALE
// ============================================================================

function analyzeByRegion(feature, yearIndex) {
  var regionGeometry = feature.geometry();
  
  var malariaImage = malariaImages[yearIndex];
  
  // Statistiques population
  var popStats = populationAggregated.reduceRegion({
    reducer: ee.Reducer.sum().combine(ee.Reducer.mean(), null, true),
    geometry: regionGeometry,
    scale: malariaScale,
    maxPixels: 1e13,
    bestEffort: true
  });
  
  // Statistiques nombre de cas
  var countStats = malariaImage.reduceRegion({
    reducer: ee.Reducer.sum().combine({
      reducer2: ee.Reducer.mean(),
      sharedInputs: true
    }).combine({
      reducer2: ee.Reducer.max(),
      sharedInputs: true
    }),
    geometry: regionGeometry,
    scale: malariaScale,
    maxPixels: 1e13,
    bestEffort: true
  });
  
  return feature.set({
    'pop_totale': popStats.get('b1'),
    'pop_moyenne': popStats.get('b1_mean'),
    'cas_total': countStats.get('incidence_count_sum'),
    'cas_moyen': countStats.get('incidence_count_mean'),
    'cas_max': countStats.get('incidence_count_max'),
    'annee': 2000 + yearIndex
  });
}

function updateRegionalStatistics(yearIndex) {
  regionsWithStats = regions.map(function(feature) {
    return analyzeByRegion(feature, yearIndex);
  });
}

updateRegionalStatistics(0);

// ============================================================================
// 5. CONFIGURATION DE LA CARTE
// ============================================================================

// Utiliser OpenStreetMap comme fond de carte
Map.setOptions('ROADMAP');
Map.centerObject(pays, 6);

// Palette de couleurs pour le nombre de cas
var paletteCas = ['#440154', '#3b528b', '#21918c', '#5ec962', '#fde725'];

// ============================================================================
// 6. INTERFACE UTILISATEUR
// ============================================================================

var controlPanel = ui.Panel({
  style: {
    position: 'top-left',
    padding: '0px',
    width: '300px',
    backgroundColor: 'white',
    border: '2px solid #e74c3c'
  }
});

var header = ui.Panel({
  style: {
    backgroundColor: '#e74c3c',
    padding: '12px',
    margin: '0'
  }
});

header.add(ui.Label({
  value: '🦟 NOMBRE DE CAS - PALUDISME',
  style: {
    fontSize: '14px',
    fontWeight: 'bold',
    color: 'white',
    textAlign: 'center'
  }
}));

header.add(ui.Label({
  value: 'Cameroun • 2000-2021',
  style: {
    fontSize: '10px',
    color: '#fadbd8',
    textAlign: 'center',
    margin: '3px 0 0 0'
  }
}));

controlPanel.add(header);

var conteneur = ui.Panel({
  style: { padding: '10px' }
});
controlPanel.add(conteneur);

// Contrôle de l'année
conteneur.add(ui.Label({
  value: '⏱ ANNÉE:',
  style: { fontSize: '12px', fontWeight: 'bold', margin: '0 0 5px 0' }
}));

var yearLabel = ui.Label({
  value: '2000',
  style: { fontSize: '13px', fontWeight: 'bold', color: '#e74c3c', textAlign: 'center' }
});
conteneur.add(yearLabel);

var yearSlider = ui.Slider({
  min: 2000,
  max: 2021,
  value: 2000,
  step: 1,
  style: { stretch: 'horizontal', margin: '5px 0 15px 0' },
  onChange: function(year) {
    updateYear(Math.round(year));
  }
});
conteneur.add(yearSlider);

// Statistiques nationales
conteneur.add(ui.Label({
  value: '📊 STATISTIQUES NATIONALES:',
  style: { fontSize: '12px', fontWeight: 'bold', margin: '0 0 5px 0' }
}));

var statsPanel = ui.Panel({
  style: {
    padding: '8px',
    backgroundColor: '#f8f9fa',
    border: '1px solid #dee2e6',
    margin: '0 0 15px 0'
  }
});

var statsLabel = ui.Label({
  value: 'Chargement...',
  style: { fontSize: '10px', color: '#2c3e50', whiteSpace: 'pre' }
});
statsPanel.add(statsLabel);
conteneur.add(statsPanel);

// Légende
conteneur.add(ui.Label({
  value: '🎨 NOMBRE DE CAS:',
  style: { fontSize: '12px', fontWeight: 'bold', margin: '0 0 5px 0' }
}));

var legendePanel = ui.Panel({
  style: {
    padding: '8px',
    backgroundColor: '#ffffff',
    border: '1px solid #ced4da',
    margin: '0 0 15px 0'
  }
});
conteneur.add(legendePanel);

// Boutons
var btnPanel = ui.Panel({
  layout: ui.Panel.Layout.Flow('horizontal'),
  style: { margin: '5px 0' }
});

var btnExport = ui.Button({
  label: '📤 Exporter données',
  style: { width: '100%', fontSize: '11px', backgroundColor: '#e74c3c', color: 'white' },
  onClick: exportData
});

btnPanel.add(btnExport);
conteneur.add(btnPanel);

// ============================================================================
// FONCTIONS PRINCIPALES
// ============================================================================

function updateYear(year) {
  currentYear = year;
  currentYearIndex = year - 2000;
  currentMalaria = malariaImages[currentYearIndex];
  
  yearLabel.setValue(year.toString());
  updateRegionalStatistics(currentYearIndex);
  updateVisualization();
  updateNationalStatistics();
  updateRegionalRanking();
}

function updateVisualization() {
  // Nettoyer les couches existantes
  var layers = Map.layers();
  for (var i = layers.length() - 1; i >= 0; i--) {
    var layer = layers.get(i);
    var name = layer.getName();
    if (name && name.indexOf('Cas') >= 0) {
      Map.remove(layer);
    }
  }
  
  // Ajouter la couche des cas de paludisme
  Map.addLayer(currentMalaria, {
    min: 0,
    max: 2000,
    palette: paletteCas,
    opacity: 0.8
  }, 'Cas de paludisme ' + currentYear, true);
  
  updateLegend(paletteCas, ['0', '400', '800', '1200', '1600', '2000']);
}

function updateNationalStatistics() {
  var stats = currentMalaria.reduceRegion({
    reducer: ee.Reducer.mean().combine({
      reducer2: ee.Reducer.stdDev(),
      sharedInputs: true
    }).combine({
      reducer2: ee.Reducer.minMax(),
      sharedInputs: true
    }),
    geometry: pays.geometry(),
    scale: malariaScale,
    maxPixels: 1e13,
    bestEffort: true
  });
  
  stats.evaluate(function(result) {
    if (result) {
      var mean = result.incidence_count_mean;
      var stdDev = result.incidence_count_stdDev;
      var min = result.incidence_count_min;
      var max = result.incidence_count_max;
      
      if (mean !== null) {
        var texte = '📊 Cas moyens: ' + mean.toFixed(0) + '/pixel\n' +
                    '📐 Écart-type: ±' + stdDev.toFixed(0) + '\n' +
                    '📉 Minimum: ' + min.toFixed(0) + '\n' +
                    '📈 Maximum: ' + max.toFixed(0);
        statsLabel.setValue(texte);
      }
    }
  });
}

function updateRegionalRanking() {
  // Cette fonction peut être utilisée pour afficher le classement des régions
  // si vous souhaitez l'ajouter plus tard
}

function updateLegend(palette, labels) {
  legendePanel.clear();
  
  for (var i = 0; i < Math.min(palette.length, labels.length); i++) {
    var row = ui.Panel({
      layout: ui.Panel.Layout.Flow('horizontal'),
      style: { margin: '2px 0',  }
    });
    
    var colorBox = ui.Label({
      style: {
        backgroundColor: palette[i],
        padding: '10px',
        margin: '0 8px 0 0',
        border: '1px solid #333',
        width: '20px'
      }
    });
    
    row.add(colorBox);
    row.add(ui.Label({
      value: labels[i] + ' cas',
      style: { fontSize: '9px', color: '#2c3e50' }
    }));
    
    legendePanel.add(row);
  }
}

function exportData() {
  print('💾 Export des données pour ' + currentYear + '...');
  
  // Exporter les statistiques régionales
  Export.table.toDrive({
    collection: regionsWithStats,
    description: 'Stats_Cameroun_Cas_' + currentYear,
    fileFormat: 'CSV',
    selectors: ['NAME_1', 'pop_totale', 'cas_total', 'cas_moyen', 'cas_max']
  });
  
  // Exporter la carte des cas
  Export.image.toDrive({
    image: currentMalaria,
    description: 'Carte_Cas_Paludisme_' + currentYear,
    scale: malariaScale,
    region: pays.geometry(),
    maxPixels: 1e13,
    crs: malariaProjection.crs()
  });
  
  print('✅ Export lancé - Vérifiez l\'onglet "Tasks"');
}

// ============================================================================
// INITIALISATION DE LA CARTE
// ============================================================================

print('⚙ Initialisation de la carte...\n');

// Ajouter les couches administratives
Map.addLayer(
  pays.style({color: '#c0392b', fillColor: '00000000', width: 3}),
  {},
  'Frontières nationales'
);

Map.addLayer(
  regions.style({color: '#e74c3c', fillColor: '00000000', width: 1.5}),
  {},
  'Régions'
);

Map.addLayer(
  departements.style({color: '#e67e22', fillColor: '00000000', width: 0.8}),
  {},
  'Départements',
  false
);

// Initialiser la visualisation
updateVisualization();
updateNationalStatistics();
updateLegend(paletteCas, ['0', '400', '800', '1200', '1600', '2000']);

ui.root.insert(0, controlPanel);

// ============================================================================
// MESSAGES FINAUX
// ============================================================================

print(' SYSTÈME PRÊT');
print(' Données: 2000-2021 (' + malariaImages.length + ' années)');
print(' Visualisation: Nombre de cas uniquement');
print(' Fond de carte: OpenStreetMap');
print('');
print('📚 Développé par: Cheikh THIOUB | ENSAE Pierre Ndiaye');

// Validation rapide
currentMalaria.reduceRegion({
  reducer: ee.Reducer.sum(),
  geometry: pays.geometry(),
  scale: malariaScale,
  maxPixels: 1e13,
  bestEffort: true
}).evaluate(function(stats) {
  if (stats && stats.incidence_count_sum !== null) {
    print('📈 Cas totaux initiaux: ' + Math.round(stats.incidence_count_sum).toLocaleString());
  }
});