

// ============================================
// CONFIGURATION POUR DÉPLOIEMENT EN APP
// ============================================

// Effacer l'interface par défaut
ui.root.clear();

// Créer le conteneur principal de l'application
var appContainer = ui.Panel({
  style: {
    width: '100%',
    height: '100%',
    padding: '0px'
  }
});

// Créer la carte
var map = ui.Map();
map.style().set({
  cursor: 'crosshair'
});

// Ajouter la carte au conteneur
appContainer.add(map);

// Ajouter le conteneur à la racine
ui.root.add(appContainer);



// ============================================
// CARTOGRAPHIE DYNAMIQUE DES INDICATEURS DE SANTÉ EN ÉTHIOPIE
// Version Exceptionnelle avec Légendes Dynamiques
// Google Earth Engine - JavaScript
// ============================================

// 1. CHARGEMENT DES DONNÉES
// ============================================

var contraception = ee.Image('projects/initiation-478314/assets/ETH_CONTRACEPTION_MEAN');
var demographie = ee.Image('projects/initiation-478314/assets/ETH_HSIZE_MEAN');
var pauvre = ee.Image('projects/initiation-478314/assets/ETH_HWEALTH_MEAN');
var malnutrition = ee.Image('projects/initiation-478314/assets/ETH_MALNUTRITION_MEAN');
var educationinformelle = ee.Image('projects/initiation-478314/assets/ETH_MEDUCATION_MEAN');
var naissancevivante = ee.Image('projects/initiation-478314/assets/ETH_births_pp_v2_2015');

// Charger les frontières (décommenter votre ligne)
var ethiopie = ee.FeatureCollection('projects/initiation-478314/assets/gadm41_ETH_0');

map.centerObject(ethiopie, 6);
map.addLayer(ethiopie, {color: 'black'}, 'Frontières Éthiopie', false);

// 2. PALETTES DE COULEURS
// ============================================

var paletteRouge = ['#ffffcc', '#ffeda0', '#fed976', '#feb24c', '#fd8d3c', 
                     '#fc4e2a', '#e31a1c', '#bd0026', '#800026'];
var paletteVerte = ['#f7fcf5', '#e5f5e0', '#c7e9c0', '#a1d99b', '#74c476',
                     '#41ab5d', '#238b45', '#006d2c', '#00441b'];
var paletteBleue = ['#f7fbff', '#deebf7', '#c6dbef', '#9ecae1', '#6baed6',
                     '#4292c6', '#2171b5', '#08519c', '#08306b'];
var paletteVulnerabilite = ['#006d2c', '#41ab5d', '#ffffcc', '#fd8d3c', '#bd0026'];

// 3. INDICE DE VULNÉRABILITÉ
// ============================================

var contracepNorm = contraception.unitScale(0, 1);
var pauvreteNorm = pauvre.unitScale(0, 1);
var malnutNorm = malnutrition.unitScale(0, 1);
var educNorm = educationinformelle.unitScale(0, 1);

var indiceVulnerabilite = contracepNorm.multiply(0.25)
  .add(pauvreteNorm.multiply(0.30))
  .add(malnutNorm.multiply(0.30))
  .add(educNorm.multiply(0.15))
  .rename('vulnerabilite');  // Donner un nom à la bande

indiceVulnerabilite = indiceVulnerabilite.clip(ethiopie);

// 4. PARAMÈTRES DE VISUALISATION
// ============================================

var visParams = {
  contraception: {
    min: 0, max: 1,
    palette: paletteRouge,
    opacity: 0.8,
    title: 'Absence de contraception',
    unit: '%',
    description: 'Proportion de femmes sans contraception moderne'
  },
  pauvrete: {
    min: 0, max: 1,
    palette: paletteRouge,
    opacity: 0.8,
    title: 'Pauvreté des ménages',
    unit: '%',
    description: 'Ménages parmi les plus pauvres'
  },
  malnutrition: {
    min: 0, max: 1,
    palette: paletteRouge,
    opacity: 0.8,
    title: 'Malnutrition infantile',
    unit: '%',
    description: 'Enfants en insuffisance pondérale'
  },
  education: {
    min: 0, max: 1,
    palette: paletteRouge,
    opacity: 0.8,
    title: 'Mères sans éducation formelle',
    unit: '%',
    description: 'Mères sans scolarisation'
  },
  demographie: {
    min: 0, max: 1,
    palette: paletteBleue,
    opacity: 0.8,
    title: 'Grands ménages (≥9 membres)',
    unit: '%',
    description: 'Proportion de grands ménages'
  },
  naissances: {
    min: 0, max: 3800,
    palette: paletteBleue,
    opacity: 0.8,
    title: 'Naissances vivantes',
    unit: 'naissances',
    description: 'Densité de naissances par grille'
  },
  vulnerabilite: {
    min: 0, max: 1,
    palette: paletteVulnerabilite,
    opacity: 0.8,
    title: 'Indice de Vulnérabilité Composite',
    unit: '',
    description: 'Indice combiné (0=faible, 1=élevé)'
  }
};

// 5. AJOUTER LES COUCHES
// ============================================

var layers = {
  'contraception': map.addLayer(contraception.clip(ethiopie), visParams.contraception, 
                   '1️⃣ Absence de contraception', false),
  'pauvrete': map.addLayer(pauvre.clip(ethiopie), visParams.pauvrete, 
                   '2️⃣ Pauvreté des ménages', false),
  'malnutrition': map.addLayer(malnutrition.clip(ethiopie), visParams.malnutrition, 
                   '3️⃣ Malnutrition infantile', false),
  'education': map.addLayer(educationinformelle.clip(ethiopie), visParams.education, 
                   '4️⃣ Mères sans éducation', false),
  'demographie': map.addLayer(demographie.clip(ethiopie), visParams.demographie, 
                   '5️⃣ Grands ménages', false),
  'naissances': map.addLayer(naissancevivante.clip(ethiopie), visParams.naissances, 
                   '6️⃣ Naissances vivantes', false),
  'vulnerabilite': map.addLayer(indiceVulnerabilite, visParams.vulnerabilite, 
                   '🎯 Indice de Vulnérabilité', true)
};

// Zones d'alerte
var zonesAlerteRouge = indiceVulnerabilite.gt(0.7).selfMask();
map.addLayer(zonesAlerteRouge, {palette: ['red']}, 
             '🚨 Zones d\'intervention prioritaire', false);

// 6. SYSTÈME DE LÉGENDE DYNAMIQUE
// ============================================

var legendPanel = ui.Panel({
  style: {
    position: 'bottom-left',
    padding: '8px 15px',
    shown: true
  }
});

function createDynamicLegend(visParam) {
  legendPanel.clear();
  
  // Titre de la légende
  var legendTitle = ui.Label({
    value: '📊 ' + visParam.title,
    style: {
      fontWeight: 'bold',
      fontSize: '14px',
      margin: '0 0 8px 0',
      color: '#333'
    }
  });
  legendPanel.add(legendTitle);
  
  // Description
  var legendDesc = ui.Label({
    value: visParam.description,
    style: {
      fontSize: '11px',
      margin: '0 0 8px 0',
      color: '#666',
      whiteSpace: 'pre-wrap'
    }
  });
  legendPanel.add(legendDesc);
  
  // Créer le gradient de couleurs
  var palette = visParam.palette;
  var steps = 5;
  
  for (var i = 0; i < steps; i++) {
    var fraction = i / (steps - 1);
    var value = visParam.min + (visParam.max - visParam.min) * fraction;
    var colorIndex = Math.floor(fraction * (palette.length - 1));
    
    var colorBox = ui.Label({
      style: {
        backgroundColor: palette[colorIndex],
        padding: '10px',
        margin: '0 0 2px 0',
        border: '1px solid #999'
      }
    });
    
    var valueLabel = ui.Label({
      value: (value * 100).toFixed(1) + ' ' + visParam.unit,
      style: {
        margin: '0 0 2px 8px',
        fontSize: '11px',
        stretch: 'horizontal'
      }
    });
    
    var row = ui.Panel({
      widgets: [colorBox, valueLabel],
      layout: ui.Panel.Layout.Flow('horizontal')
    });
    
    legendPanel.add(row);
  }
}

// Afficher la légende de la vulnérabilité par défaut
createDynamicLegend(visParams.vulnerabilite);
map.add(legendPanel);

// 7. PANNEAU DE CONTRÔLE INTERACTIF
// ============================================

var controlPanel = ui.Panel({
  style: {
    position: 'top-right',
    padding: '8px',
    width: '340px'
  }
});

var title = ui.Label({
  value: '🇪🇹 Cartographie Santé Éthiopie 2016',
  style: {
    fontSize: '18px',
    fontWeight: 'bold',
    margin: '0 0 10px 0',
    color: '#2c5aa0'
  }
});
controlPanel.add(title);

// Sélecteur d'indicateur
var indicatorLabel = ui.Label({
  value: '🎨 Sélectionner un indicateur:',
  style: {fontWeight: 'bold', margin: '10px 0 5px 0'}
});
controlPanel.add(indicatorLabel);

var indicatorSelect = ui.Select({
  items: [
    {label: '🎯 Indice de Vulnérabilité', value: 'vulnerabilite'},
    {label: '1️⃣ Absence de contraception', value: 'contraception'},
    {label: '2️⃣ Pauvreté des ménages', value: 'pauvrete'},
    {label: '3️⃣ Malnutrition infantile', value: 'malnutrition'},
    {label: '4️⃣ Mères sans éducation', value: 'education'},
    {label: '5️⃣ Grands ménages', value: 'demographie'},
    {label: '6️⃣ Naissances vivantes', value: 'naissances'}
  ],
  value: 'vulnerabilite',
  onChange: function(selected) {
    // Mettre à jour la légende
    createDynamicLegend(visParams[selected]);
    
    // Cacher toutes les couches sauf celle sélectionnée
    map.layers().forEach(function(layer) {
      var name = layer.getName();
      // Vérifier que name est une chaîne avant d'utiliser includes
      if (name && typeof name === 'string') {
        if (name.indexOf('1️⃣') > -1 || name.indexOf('2️⃣') > -1 || name.indexOf('3️⃣') > -1 || 
            name.indexOf('4️⃣') > -1 || name.indexOf('5️⃣') > -1 || name.indexOf('6️⃣') > -1 || 
            name.indexOf('🎯') > -1) {
          layer.setShown(false);
        }
      }
    });
    
    // Afficher la couche sélectionnée
    map.layers().forEach(function(layer) {
      var name = layer.getName();
      if (name && typeof name === 'string') {
        if ((selected === 'vulnerabilite' && name.indexOf('🎯') > -1) ||
            (selected === 'contraception' && name.indexOf('1️⃣') > -1) ||
            (selected === 'pauvrete' && name.indexOf('2️⃣') > -1) ||
            (selected === 'malnutrition' && name.indexOf('3️⃣') > -1) ||
            (selected === 'education' && name.indexOf('4️⃣') > -1) ||
            (selected === 'demographie' && name.indexOf('5️⃣') > -1) ||
            (selected === 'naissances' && name.indexOf('6️⃣') > -1)) {
          layer.setShown(true);
        }
      }
    });
  }
});
controlPanel.add(indicatorSelect);

// 9. CRÉER DES ZONES D'ALERTE PRIORITAIRES
// ============================================

var compareLabel = ui.Label({
  value: '⚖️ Mode Comparaison:',
  style: {fontWeight: 'bold', margin: '15px 0 5px 0'}
});
controlPanel.add(compareLabel);

var compareCheckbox = ui.Checkbox({
  label: 'Activer la comparaison côte à côte',
  value: false,
  onChange: function(checked) {
    if (checked) {
      // Créer une carte liée pour la comparaison
      var linkedmap = ui.map();
      linkedmap.setCenter(map.getCenter().coordinates().get(0).getInfo(), 
                          map.getCenter().coordinates().get(1).getInfo(), 6);
      
      // Ajouter à un panneau splitPanel
      var splitPanel = ui.SplitPanel({
        firstPanel: map,
        secondPanel: linkedmap,
        orientation: 'horizontal',
        wipe: true
      });
      
      ui.root.widgets().reset([splitPanel, controlPanel]);
      map.setControlVisibility({all: false});
      linkedmap.setControlVisibility({all: false});
    } else {
      ui.root.widgets().reset([map]);
      map.add(controlPanel);
      map.add(legendPanel);
    }
  }
});
controlPanel.add(compareCheckbox);

// 10. GRAPHIQUE INTERACTIF
// ============================================

var chartLabel = ui.Label({
  value: '📊 Analyse graphique:',
  style: {fontWeight: 'bold', margin: '15px 0 5px 0'}
});
controlPanel.add(chartLabel);

var createChartButton = ui.Button({
  label: '📈 Générer histogramme',
  onClick: function() {
    var selected = indicatorSelect.getValue();
    var imagemap = {
      'contraception': contraception,
      'pauvrete': pauvre,
      'malnutrition': malnutrition,
      'education': educationinformelle,
      'demographie': demographie,
      'naissances': naissancevivante,
      'vulnerabilite': indiceVulnerabilite
    };
    
    var chart = ui.Chart.image.histogram({
      image: imagemap[selected],
      region: ethiopie,
      scale: 5000,
      maxPixels: 1e9
    }).setOptions({
      title: 'Distribution: ' + visParams[selected].title,
      hAxis: {title: 'Valeur'},
      vAxis: {title: 'Fréquence'},
      colors: ['#1f77b4']
    });
    
    print(chart);
  },
  style: {stretch: 'horizontal'}
});
controlPanel.add(createChartButton);

// 11. INSPECTEUR DE POINTS AMÉLIORÉ
// ============================================

var inspectorPanel = ui.Panel({
  style: {
    shown: false,
    position: 'bottom-right',
    width: '300px',
    padding: '8px',
    backgroundColor: 'white'
  }
});

map.add(inspectorPanel);

map.onClick(function(coords) {
  inspectorPanel.style().set('shown', true);
  inspectorPanel.clear();
  
  var point = ee.Geometry.Point(coords.lon, coords.lat);
  
  inspectorPanel.add(ui.Label({
    value: '📍 Valeurs au point sélectionné',
    style: {fontWeight: 'bold', fontSize: '14px', margin: '0 0 8px 0'}
  }));
  
  inspectorPanel.add(ui.Label('Coordonnées: ' + 
    coords.lon.toFixed(4) + ', ' + coords.lat.toFixed(4),
    {fontSize: '11px', color: '#666'}));
  
  var images = {
    'Contraception': contraception,
    'Pauvreté': pauvre,
    'Malnutrition': malnutrition,
    'Éducation': educationinformelle,
    'Grands ménages': demographie,
    'Naissances': naissancevivante,
    'Vulnérabilité': indiceVulnerabilite
  };
  
  Object.keys(images).forEach(function(name) {
    var value = images[name].reduceRegion({
      reducer: ee.Reducer.first(),
      geometry: point,
      scale: 1000
    }).values().get(0);
    
    value.evaluate(function(val) {
      if (val !== null) {
        var displayVal = name === 'Naissances' ? val.toFixed(0) : (val * 100).toFixed(2) + '%';
        inspectorPanel.add(ui.Label(name + ': ' + displayVal, 
          {fontSize: '12px', margin: '2px 0'}));
      }
    });
  });
  
  var closeButton = ui.Button({
    label: 'Fermer',
    onClick: function() {
      inspectorPanel.style().set('shown', false);
    },
    style: {margin: '8px 0 0 0', stretch: 'horizontal'}
  });
  inspectorPanel.add(closeButton);
});

// 12. INSTRUCTIONS UTILISATEUR
// ============================================

var instructionsLabel = ui.Label({
  value: '💡 Instructions:',
  style: {fontWeight: 'bold', margin: '15px 0 5px 0'}
});
controlPanel.add(instructionsLabel);

var instructions = ui.Label({
  value: '• Sélectionnez un indicateur dans le menu\n' +
         '• La légende s\'adapte automatiquement\n' +
         '• Cliquez sur la carte pour voir les valeurs\n' +
         '• Utilisez les couches dans le panneau Layers',
  style: {
    fontSize: '11px',
    color: '#666',
    whiteSpace: 'pre',
    margin: '0 0 10px 0'
  }
});
controlPanel.add(instructions);

map.add(controlPanel);

// 13. EXPORT AMÉLIORÉ
// ============================================

var exportLabel = ui.Label({
  value: '💾 Exportation:',
  style: {fontWeight: 'bold', margin: '15px 0 5px 0'}
});
controlPanel.add(exportLabel);

var exportButton = ui.Button({
  label: '⬇️ Exporter l\'indicateur actuel',
  onClick: function() {
    var selected = indicatorSelect.getValue();
    var imagemap = {
      'contraception': contraception,
      'pauvrete': pauvre,
      'malnutrition': malnutrition,
      'education': educationinformelle,
      'demographie': demographie,
      'naissances': naissancevivante,
      'vulnerabilite': indiceVulnerabilite
    };
    
    Export.image.toDrive({
      image: imagemap[selected].clip(ethiopie),
      description: 'Ethiopie_' + selected,
      scale: 1000,
      region: ethiopie,
      maxPixels: 1e9,
      fileFormat: 'GeoTIFF'
    });
    
    print('✅ Export lancé pour: ' + selected);
    print('Vérifiez l\'onglet "Tasks" pour lancer l\'export');
  },
  style: {stretch: 'horizontal'}
});
controlPanel.add(exportButton);

print('✅ Application chargée avec succès!');
print('👉 Utilisez le panneau de contrôle à droite pour explorer les données');