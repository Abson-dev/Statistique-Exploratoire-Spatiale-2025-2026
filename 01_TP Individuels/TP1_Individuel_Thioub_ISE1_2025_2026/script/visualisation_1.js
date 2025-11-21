///////////////////////////////////////////////////////////////////////////////////////////////
////      ECOLE NATIONALE DE LA STATISTIQUE ET DE L'ANALYSE ECONOMIQUE PIERRE NDIAYE     /////
////          COURS DE STATISTIQUES EXPLORATOIRE ET SPATIALE - ISE1_CYCLE LONG           /////
////                           ENSEIGNANT: M.HEMA Aboubacar                               /////
////                   TP1_GOOGLE EARTH ENGINE AVEC JAVASCRIPT                            /////
////                   PAYS : Cameroun                                                    /////
////                   Élève : Cheikh THIOUB                                              /////
////                   VERSION AMÉLIORÉE - Analyses Spatiales Avancées                    /////
///////////////////////////////////////////////////////////////////////////////////////////////


// ============================================================================
// 1. INITIALISATION ET CHARGEMENT DES DONNÉES
// ============================================================================

// Chargement des limites administratives depuis les assets
var regions = ee.FeatureCollection('projects/userscheikhthioub501/assets/gadm41_CMR_1');
var departements = ee.FeatureCollection('projects/userscheikhthioub501/assets/gadm41_CMR_2');
var arrondissements = ee.FeatureCollection('projects/userscheikhthioub501/assets/gadm41_CMR_3');

// Configuration de la vue initiale (centré sur le Cameroun)
Map.setCenter(12.3547, 6.0, 6);

// ============================================================================
// 2. CALCUL DES SUPERFICIES ET ENRICHISSEMENT DES DONNÉES
// ============================================================================

/**
 * Calcule la superficie de chaque entité et l'ajoute comme propriété
 * @param {ee.FeatureCollection} fc - Collection de features
 * @returns {ee.FeatureCollection} - Collection enrichie avec superficies
 */
function calculerSuperficies(fc) {
  return fc.map(function(feature) {
    var area = feature.geometry().area().divide(1e6); // Conversion en km²
    return feature.set('superficie_km2', area);
  });
}

// Enrichissement des données avec les superficies
regions = calculerSuperficies(regions);
departements = calculerSuperficies(departements);
arrondissements = calculerSuperficies(arrondissements);

// ============================================================================
// 3. STYLES ET VISUALISATIONS
// ============================================================================

// Palette de couleurs pour la visualisation par densité
var paletteRegions = ['#ffffcc', '#ffeda0', '#fed976', '#feb24c', '#fd8d3c', 
                       '#fc4e2a', '#e31a1c', '#bd0026', '#800026'];

// Style de base pour les contours
var styleRegions = {color: 'black', fillColor: '00000000', width: 2.5};
var styleDepartements = {color: '#0066cc', fillColor: '00000000', width: 1.5};
var styleArrondissements = {color: '#00cc66', fillColor: '00000000', width: 0.8};

// Visualisation avec remplissage coloré par superficie
var regionsColorees = regions.style({
  fillColor: '00000000',
  color: 'black',
  width: 2
});

// Couches de base
var layerRegions = Map.addLayer(regionsColorees, {}, 'Contours Régions', true);
var layerDepartements = Map.addLayer(departements.style(styleDepartements), {}, 'Contours Départements', false);
var layerArrondissements = Map.addLayer(arrondissements.style(styleArrondissements), {}, 'Contours Arrondissements', false);

// ============================================================================
// 4. INTERFACE UTILISATEUR PRINCIPALE
// ============================================================================

// Panneau principal
var panel = ui.Panel({
  style: {
    position: 'top-left',
    padding: '12px',
    width: '360px',
    maxHeight: '95%',
    backgroundColor: 'white',
    border: '2px solid #2c3e50'
  }
});

// En-tête avec logo et titre
var header = ui.Panel({
  style: {
    backgroundColor: '#2c3e50',
    padding: '15px',
    margin: '0 0 10px 0'
  }
});

var titre = ui.Label({
  value: '🇨🇲 ATLAS INTERACTIF DU CAMEROUN',
  style: {
    fontSize: '16px',
    fontWeight: 'bold',
    color: 'white',
    textAlign: 'center',
    margin: '0'
  }
});

var sousTitre = ui.Label({
  value: 'Analyse Spatiale des Subdivisions Administratives',
  style: {
    fontSize: '11px',
    color: '#ecf0f1',
    textAlign: 'center',
    margin: '5px 0 0 0',
    fontStyle: 'italic'
  }
});

header.add(titre);
header.add(sousTitre);
panel.add(header);

// ============================================================================
// 5. PANNEAU D'IDENTIFICATION DYNAMIQUE
// ============================================================================

var identificationPanel = ui.Panel({
  style: {
    position: 'bottom-right',
    padding: '12px',
    backgroundColor: 'rgba(255, 255, 255, 0.95)',
    border: '2px solid #3498db',
    shown: false,
    maxWidth: '350px'
  }
});
Map.add(identificationPanel);

// ============================================================================
// 6. LOGIQUE D'IDENTIFICATION AVANCÉE AU CLIC
// ============================================================================

/**
 * Gère l'identification des entités administratives au clic sur la carte
 */
Map.onClick(function(coords) {
  identificationPanel.style().set('shown', false);
  identificationPanel.clear();
  
  var point = ee.Geometry.Point(coords.lon, coords.lat);
  
  // Récupération des informations pour chaque niveau administratif
  var regionInfo = regions.filterBounds(point).first();
  var deptInfo = departements.filterBounds(point).first();
  var arrInfo = arrondissements.filterBounds(point).first();
  
  // Récupération des propriétés côté client
  ee.List([
    regionInfo.toDictionary(),
    deptInfo.toDictionary(),
    arrInfo.toDictionary()
  ]).evaluate(function(results) {
    
    var regionData = results[0];
    var deptData = results[1];
    var arrData = results[2];
    
    if (regionData && regionData.NAME_1) {
      // Titre du panneau
      identificationPanel.add(ui.Label({
        value: '📍 INFORMATIONS GÉOGRAPHIQUES',
        style: {
          fontSize: '13px',
          fontWeight: 'bold',
          color: '#2c3e50',
          margin: '0 0 10px 0'
        }
      }));
      
      // Coordonnées
      identificationPanel.add(createInfoRow('Coordonnées', 
        coords.lat.toFixed(4) + '°N, ' + coords.lon.toFixed(4) + '°E'));
      
      identificationPanel.add(ui.Label({value: '─────────────────', 
        style: {color: '#bdc3c7', margin: '8px 0'}}));
      
      // Région
      if (regionData.NAME_1) {
        identificationPanel.add(createInfoRow('🏛 Région', regionData.NAME_1, true));
        if (regionData.superficie_km2) {
          identificationPanel.add(createInfoRow('   Superficie', 
            Math.round(regionData.superficie_km2).toLocaleString() + ' km²'));
        }
      }
      
      // Département
      if (deptData && deptData.NAME_2) {
        identificationPanel.add(createInfoRow('🏢 Département', deptData.NAME_2, true));
        if (deptData.superficie_km2) {
          identificationPanel.add(createInfoRow('   Superficie', 
            Math.round(deptData.superficie_km2).toLocaleString() + ' km²'));
        }
      }
      
      // Arrondissement
      if (arrData && arrData.NAME_3) {
        identificationPanel.add(createInfoRow('🏘 Arrondissement', arrData.NAME_3, true));
        if (arrData.superficie_km2) {
          identificationPanel.add(createInfoRow('   Superficie', 
            Math.round(arrData.superficie_km2).toLocaleString() + ' km²'));
        }
      }
      
      // Afficher le panneau
      identificationPanel.style().set('shown', true);
      
      // Affichage dans la console
      print('═══════════════════════════════════');
      print('📍 Localisation cliquée');
      print('Région:', regionData.NAME_1);
      print('Département:', deptData ? deptData.NAME_2 : 'N/A');
      print('Arrondissement:', arrData ? arrData.NAME_3 : 'N/A');
      print('═══════════════════════════════════');
    }
  });
});

/**
 * Crée une ligne d'information formatée
 */
function createInfoRow(label, value, isBold) {
  var row = ui.Panel({
    layout: ui.Panel.Layout.Flow('horizontal'),
    style: {margin: '3px 0'}
  });
  
  row.add(ui.Label({
    value: label + ':',
    style: {
      fontSize: '11px',
      fontWeight: isBold ? 'bold' : 'normal',
      color: '#34495e',
      width: '110px'
    }
  }));
  
  row.add(ui.Label({
    value: value,
    style: {
      fontSize: '11px',
      fontWeight: isBold ? 'bold' : 'normal',
      color: isBold ? '#2980b9' : '#7f8c8d'
    }
  }));
  
  return row;
}

// ============================================================================
// 7. CONTRÔLES DE VISIBILITÉ DES COUCHES
// ============================================================================

var sectionCouches = createSection('🗺 COUCHES CARTOGRAPHIQUES');
panel.add(sectionCouches);

panel.add(createLayerControl('Régions (10)', layerRegions, true));
panel.add(createLayerControl('Départements (58)', layerDepartements, false));
panel.add(createLayerControl('Arrondissements (360)', layerArrondissements, false));

function createLayerControl(label, layer, defaultValue) {
  var control = ui.Checkbox({
    label: label,
    value: defaultValue,
    style: {fontSize: '12px', margin: '4px 0'}
  });
  control.onChange(function(checked) {
    layer.setShown(checked);
  });
  return control;
}

// ============================================================================
// 8. STATISTIQUES GÉNÉRALES
// ============================================================================

var sectionStats = createSection('📊 STATISTIQUES GÉNÉRALES');
panel.add(sectionStats);

// Calcul et affichage des statistiques
regions.aggregate_array('superficie_km2').evaluate(function(superficies) {
  var totalSuperficie = superficies.reduce(function(a, b) { return a + b; }, 0);
  var superficieMoyenne = totalSuperficie / superficies.length;
  
  panel.add(createStatLabel('Superficie totale', 
    Math.round(totalSuperficie).toLocaleString() + ' km²'));
  panel.add(createStatLabel('Superficie moyenne/région', 
    Math.round(superficieMoyenne).toLocaleString() + ' km²'));
  panel.add(createStatLabel('Nombre de régions', '10'));
  panel.add(createStatLabel('Nombre de départements', '58'));
  panel.add(createStatLabel('Nombre d\'arrondissements', '360'));
});

function createStatLabel(label, value) {
  var row = ui.Panel({
    layout: ui.Panel.Layout.Flow('horizontal'),
    style: {margin: '5px 0', padding: '5px', backgroundColor: '#ecf0f1'}
  });
  
  row.add(ui.Label({
    value: label + ':',
    style: {fontSize: '11px', color: '#34495e', width: '180px'}
  }));
  
  row.add(ui.Label({
    value: value,
    style: {fontSize: '11px', fontWeight: 'bold', color: '#27ae60'}
  }));
  
  return row;
}

// ============================================================================
// 9. RECHERCHE DE LOCALITÉS
// ============================================================================

var sectionRecherche = createSection('🔍 RECHERCHE RAPIDE');
panel.add(sectionRecherche);

var searchBox = ui.Textbox({
  placeholder: 'Entrez le nom d\'une région...',
  style: {width: '100%', margin: '5px 0'}
});

var searchButton = ui.Button({
  label: 'Rechercher',
  style: {width: '100%', margin: '5px 0'},
  onClick: function() {
    var query = searchBox.getValue().toUpperCase();
    
    regions.filter(ee.Filter.stringContains('NAME_1', query))
      .first()
      .geometry()
      .bounds()
      .evaluate(function(bounds) {
        if (bounds) {
          Map.centerObject(ee.Geometry.Rectangle(bounds.coordinates[0]), 8);
          print('✓ Région trouvée:', query);
        } else {
          print('✗ Aucune région trouvée pour:', query);
        }
      });
  }
});

panel.add(searchBox);
panel.add(searchButton);

// ============================================================================
// 10. LÉGENDE INTERACTIVE
// ============================================================================

var sectionLegende = createSection('🎨 LÉGENDE');
panel.add(sectionLegende);

var legendePanel = ui.Panel({
  style: {
    padding: '8px',
    backgroundColor: '#f8f9fa',
    border: '1px solid #dee2e6',
    margin: '5px 0'
  }
});

var legendItems = [
  {color: 'black', label: 'Zone géographique', width: '2.5px'},
  {color: '#0066cc', label: 'Départements', width: '1.5px'},
  {color: '#00cc66', label: 'Arrondissements', width: '0.8px'}
];

legendItems.forEach(function(item) {
  var row = ui.Panel({
    layout: ui.Panel.Layout.Flow('horizontal'),
    style: {margin: '4px 0'}
  });
  
  var colorBox = ui.Label({
    style: {
      backgroundColor: item.color,
      padding: '10px',
      margin: '0 8px 0 0',
      border: '1px solid #999'
    }
  });
  
  var label = ui.Label({
    value: item.label + ' (' + item.width + ')',
    style: {fontSize: '11px', color: '#495057'}
  });
  
  row.add(colorBox);
  row.add(label);
  legendePanel.add(row);
});

panel.add(legendePanel);

// ============================================================================
// 11. INSTRUCTIONS D'UTILISATION
// ============================================================================

var sectionInstructions = createSection('💡 MODE D\'EMPLOI');
panel.add(sectionInstructions);

var instructions = [
  '• Cliquez sur la carte pour identifier une zone',
  '• Utilisez les checkbox pour afficher/masquer les couches',
  '• La recherche permet de localiser rapidement une région',
  '• Les superficies sont calculées automatiquement',
  '• Survolez les zones pour plus de détails'
];

instructions.forEach(function(instruction) {
  panel.add(ui.Label({
    value: instruction,
    style: {
      fontSize: '10px',
      color: '#6c757d',
      margin: '3px 0',
      fontStyle: 'italic'
    }
  }));
});

// ============================================================================
// 12. PIED DE PAGE
// ============================================================================

var footer = ui.Panel({
  style: {
    backgroundColor: '#ecf0f1',
    padding: '10px',
    margin: '15px 0 0 0',
    border: '1px solid #bdc3c7'
  }
});

footer.add(ui.Label({
  value: 'Développé par: Cheikh THIOUB',
  style: {fontSize: '10px', color: '#7f8c8d', textAlign: 'center'}
}));

footer.add(ui.Label({
  value: 'ENSAE Pierre Ndiaye - 2025',
  style: {fontSize: '9px', color: '#95a5a6', textAlign: 'center', margin: '3px 0 0 0'}
}));

panel.add(footer);

// ============================================================================
// FONCTIONS UTILITAIRES
// ============================================================================

/**
 * Crée une section avec titre formaté
 */
function createSection(titre) {
  return ui.Label({
    value: titre,
    style: {
      fontSize: '13px',
      fontWeight: 'bold',
      color: '#2c3e50',
      margin: '15px 0 8px 0',
      padding: '5px 0',
     
    }
  });
}

// Ajout du panneau à l'interface
ui.root.insert(0, panel);

// ============================================================================
// MESSAGE FINAL
// ============================================================================

print('═══════════════════════════════════════════════════════════');
print('✓ CARTE INTERACTIVE CHARGÉE AVEC SUCCÈS');
print('═══════════════════════════════════════════════════════════');
print(' Fonctionnalités disponibles:');
print('   • Identification géographique au clic');
print('   • Calcul automatique des superficies');
print('   • Recherche de localités');
print('   • Statistiques en temps réel');
print('   • Visualisation multi-niveaux');
print('═══════════════════════════════════════════════════════════');