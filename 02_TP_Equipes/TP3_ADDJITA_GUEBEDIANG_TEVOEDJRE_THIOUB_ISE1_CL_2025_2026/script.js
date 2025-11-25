// ============================================================================
// ANALYSE INTERACTIVE DES CONDITIONS DE VIE DES MÉNAGES AU SÉNÉGAL
// Version enrichie avec toutes les infrastructures et interactivité
// ============================================================================

// --------------------------------------------------------------------------
// 1. IMPORTATION DES DONNÉES
// --------------------------------------------------------------------------

var region_senegal = ee.FeatureCollection('projects/micro-raceway-476718-g5/assets/regions');
var shapefile_senegal = ee.FeatureCollection('projects/micro-raceway-476718-g5/assets/shapefile_senegal');
var banlieu = ee.FeatureCollection('projects/micro-raceway-476718-g5/assets/suburbs');

// Infrastructures de santé
var clinics = ee.FeatureCollection('projects/micro-raceway-476718-g5/assets/clinics');
var hopitals = ee.FeatureCollection('projects/micro-raceway-476718-g5/assets/hospitals');
var pharmacie = ee.FeatureCollection('projects/micro-raceway-476718-g5/assets/pharmacies');

// Infrastructures d'éducation
var ecole = ee.FeatureCollection('projects/micro-raceway-476718-g5/assets/schools');
var lycee = ee.FeatureCollection('projects/micro-raceway-476718-g5/assets/lycee');
var college = ee.FeatureCollection('projects/micro-raceway-476718-g5/assets/college');
var universite = ee.FeatureCollection('projects/micro-raceway-476718-g5/assets/universite');

// Localités
var village = ee.FeatureCollection('projects/micro-raceway-476718-g5/assets/villages');
var hamlets = ee.FeatureCollection('projects/micro-raceway-476718-g5/assets/hamlets');
var towns = ee.FeatureCollection('projects/micro-raceway-476718-g5/assets/towns');
var city = ee.FeatureCollection('projects/micro-raceway-476718-g5/assets/ville');

// Données de population
var densitepop = ee.Image('projects/micro-raceway-476718-g5/assets/densite');
var poptotale = ee.Image('projects/micro-raceway-476718-g5/assets/populationtotale');

// Routes
var Routebitumee = ee.FeatureCollection('projects/micro-raceway-476718-g5/assets/Routebitumee');
var Routenonbitumee = ee.FeatureCollection('projects/micro-raceway-476718-g5/assets/Routenonbitumee');

// Accès à l'eau
var voieferree = ee.FeatureCollection('projects/micro-raceway-476718-g5/assets/Voie_ferree');
var coursdeau = ee.FeatureCollection('projects/micro-raceway-476718-g5/assets/Cour_d_eau');

// --------------------------------------------------------------------------
// 2. CONFIGURATION DE LA CARTE
// --------------------------------------------------------------------------

Map.centerObject(shapefile_senegal, 7);
Map.setOptions('HYBRID');

var senegalStyle = {
  color: '#2E7D32',
  fillColor: '00000000',
  width: 3
};

var regionStyle = {
  color: '#757575',
  fillColor: '00000000',
  width: 1.5
};

Map.addLayer(shapefile_senegal.style(senegalStyle), {}, 'Frontières Sénégal', true, 0.9);
Map.addLayer(region_senegal.style(regionStyle), {}, 'Régions', true, 0.6);

// --------------------------------------------------------------------------
// 3. VISUALISATION DES INFRASTRUCTURES AVEC STYLES AMÉLIORÉS
// --------------------------------------------------------------------------

// === SANTÉ ===
Map.addLayer(hopitals, {color: '#B71C1C'}, '🏥 Hôpitaux', true);
Map.addLayer(clinics, {color: '#FF5722'}, '🏥 Cliniques', false);
Map.addLayer(pharmacie, {color: '#FF9800'}, '💊 Pharmacies', false);

// === ÉDUCATION ===
Map.addLayer(universite, {color: '#0D47A1'}, '🎓 Universités', true);
Map.addLayer(lycee, {color: '#1976D2'}, '🏫 Lycées', false);
Map.addLayer(college, {color: '#42A5F5'}, '🏛️ Collèges', false);
Map.addLayer(ecole, {color: '#64B5F6'}, '📚 Écoles', false);

// === LOCALITÉS ===
Map.addLayer(city, {color: '#FFD700'}, '🌆 Grandes Villes', true);
Map.addLayer(towns, {color: '#FFA726'}, '🏙️ Villes', false);
Map.addLayer(banlieu, {color: '#FFCC80'}, '🏘️ Banlieues', false);
Map.addLayer(village, {color: '#66BB6A'}, '🏡 Villages', false);
Map.addLayer(hamlets, {color: '#A5D6A7'}, '🏘️ Hameaux', false);

// === INFRASTRUCTURES DE TRANSPORT ===
Map.addLayer(Routebitumee.style({color: '#212121', width: 2}), {}, '🛣️ Routes bitumées', true, 0.8);
Map.addLayer(Routenonbitumee.style({color: '#8D6E63', width: 1.5}), {}, '🛤️ Routes non bitumées', false, 0.7);
Map.addLayer(voieferree.style({color: '#37474F', width: 2.5}), {}, '🚂 Voies ferrées', false, 0.8);

// === RESSOURCES EN EAU ===
Map.addLayer(coursdeau.style({color: '#0288D1', width: 2}), {}, '💧 Cours d\'eau', true, 0.7);

// === DONNÉES DE POPULATION ===
var popVis = {
  min: 0,
  max: 1000,
  palette: ['#FFF3E0', '#FFE0B2', '#FFCC80', '#FFB74D', '#FF9800', '#F57C00', '#E65100']
};

Map.addLayer(poptotale, popVis, '👥 Population Totale', false, 0.7);
Map.addLayer(densitepop, popVis, '📊 Densité Population', false, 0.7);

// --------------------------------------------------------------------------
// 4. ZONES TAMPONS D'ACCESSIBILITÉ
// --------------------------------------------------------------------------

function createBuffers(features, distances, name, color) {
  distances.forEach(function(dist) {
    var buffered = features.map(function(feat) {
      return feat.buffer(dist);
    });
    var union = buffered.union();
    Map.addLayer(union.style({fillColor: color + '40', color: color, width: 1}), 
                 {}, name + ' (' + (dist/1000) + ' km)', false, 0.3);
  });
}

var distances = [5000, 10000, 20000];

// Couverture santé
createBuffers(hopitals, distances, '🏥 Accès Hôpitaux', '#B71C1C');
createBuffers(clinics, distances, '🏥 Accès Cliniques', '#FF5722');
createBuffers(pharmacie, distances, '💊 Accès Pharmacies', '#FF9800');

// Couverture éducation
createBuffers(universite, distances, '🎓 Accès Universités', '#0D47A1');
createBuffers(lycee, distances, '🏫 Accès Lycées', '#1976D2');
createBuffers(ecole, distances, '📚 Accès Écoles', '#64B5F6');

// Couverture eau
createBuffers(coursdeau, [1000, 3000, 5000], '💧 Accès Cours d\'eau', '#0288D1');

// --------------------------------------------------------------------------
// 5. STATISTIQUES PAR RÉGION AVEC TOUTES LES VARIABLES
// --------------------------------------------------------------------------

function enrichRegionWithStats(region) {
  var geom = region.geometry();
  
  // Santé
  var nbHopitals = hopitals.filterBounds(geom).size();
  var nbClinics = clinics.filterBounds(geom).size();
  var nbPharmacies = pharmacie.filterBounds(geom).size();
  
  // Éducation
  var nbUniversites = universite.filterBounds(geom).size();
  var nbLycees = lycee.filterBounds(geom).size();
  var nbColleges = college.filterBounds(geom).size();
  var nbEcoles = ecole.filterBounds(geom).size();
  
  // Localités
  var nbVilles = city.filterBounds(geom).size();
  var nbTowns = towns.filterBounds(geom).size();
  var nbVillages = village.filterBounds(geom).size();
  var nbHameaux = hamlets.filterBounds(geom).size();
  
  // Population
  var popTotal = poptotale.reduceRegion({
    reducer: ee.Reducer.sum(),
    geometry: geom,
    scale: 1000,
    maxPixels: 1e13,
    bestEffort: true
  }).values().get(0);
  
  return region
    .set('nb_hopitaux', nbHopitals)
    .set('nb_cliniques', nbClinics)
    .set('nb_pharmacies', nbPharmacies)
    .set('nb_universites', nbUniversites)
    .set('nb_lycees', nbLycees)
    .set('nb_colleges', nbColleges)
    .set('nb_ecoles', nbEcoles)
    .set('nb_villes', nbVilles)
    .set('nb_towns', nbTowns)
    .set('nb_villages', nbVillages)
    .set('nb_hameaux', nbHameaux)
    .set('population', popTotal);
}

var regionsEnrichies = region_senegal.map(enrichRegionWithStats);

// --------------------------------------------------------------------------
// 6. CARTES CHOROPLÈTHES INTERACTIVES
// --------------------------------------------------------------------------

// Carte: Hôpitaux par région
var hopitauxParRegion = regionsEnrichies.map(function(region) {
  var count = hopitals.filterBounds(region.geometry()).size();
  return region.set('nb_hopitaux', count);
});

// Créer une image à partir des propriétés
var emptyImage = ee.Image(0).byte();
var hopitauxChoropleth = emptyImage.paint({
  featureCollection: hopitauxParRegion,
  color: 'nb_hopitaux'
});

Map.addLayer(hopitauxChoropleth, {
  min: 0, max: 15, 
  palette: ['#FFEBEE', '#FFCDD2', '#EF9A9A', '#E57373', '#EF5350', '#F44336', '#B71C1C']
}, '📊 Carte: Hôpitaux/Région', false, 0.7);

// Carte: Écoles par région
var ecolesParRegion = regionsEnrichies.map(function(region) {
  var count = ecole.filterBounds(region.geometry()).size();
  return region.set('nb_ecoles', count);
});

var ecolesChoropleth = emptyImage.paint({
  featureCollection: ecolesParRegion,
  color: 'nb_ecoles'
});

Map.addLayer(ecolesChoropleth, {
  min: 0, max: 500, 
  palette: ['#E3F2FD', '#90CAF9', '#42A5F5', '#1E88E5', '#1565C0', '#0D47A1']
}, '📊 Carte: Écoles/Région', false, 0.7);

// --------------------------------------------------------------------------
// 7. INTERACTIVITÉ: CLICK SUR LA CARTE
// --------------------------------------------------------------------------

// Variable globale pour stocker le panel actuel
var currentInfoPanel = null;
var currentMarker = null;

Map.onClick(function(coords) {
  // Supprimer le panel précédent s'il existe
  if (currentInfoPanel !== null) {
    Map.remove(currentInfoPanel);
  }
  
  // Supprimer le marqueur précédent s'il existe
  if (currentMarker !== null) {
    Map.layers().remove(currentMarker);
  }
  
  var point = ee.Geometry.Point([coords.lon, coords.lat]);
  var buffer = point.buffer(10000); // 10 km autour du clic
  
  // Panel d'information
  var infoPanel = ui.Panel({
    style: {
      position: 'bottom-right',
      padding: '10px',
      backgroundColor: 'white',
      width: '350px',
      border: '2px solid #1976D2'
    }
  });
  
  // En-tête avec bouton de fermeture
  var headerPanel = ui.Panel({
    layout: ui.Panel.Layout.flow('horizontal'),
    style: {margin: '0 0 10px 0'}
  });
  
  var title = ui.Label('📍 INFORMATIONS LOCALES', {
    fontSize: '16px',
    fontWeight: 'bold',
    color: '#1976D2',
    stretch: 'horizontal'
  });
  
  var closeButton = ui.Button({
    label: '✕',
    onClick: function() {
      Map.remove(infoPanel);
      if (currentMarker !== null) {
        Map.layers().remove(currentMarker);
        currentMarker = null;
      }
      currentInfoPanel = null;
    },
    style: {
      width: '30px',
      height: '30px',
      padding: '0',
      color: 'red',
      fontWeight: 'bold',
      backgroundColor: '#FFEBEE'
    }
  });
  
  headerPanel.add(title);
  headerPanel.add(closeButton);
  infoPanel.add(headerPanel);
  
  infoPanel.add(ui.Label('Coordonnées: ' + coords.lat.toFixed(4) + ', ' + coords.lon.toFixed(4), 
    {fontSize: '11px', color: '#666'}));
  infoPanel.add(ui.Label('Rayon d\'analyse: 10 km', {fontSize: '11px', color: '#666', margin: '0 0 5px 0'}));
  
  // Ajouter un label de chargement pour la région
  var regionLabel = ui.Label('📍 Région: ⏳ Chargement...', {
    fontSize: '14px',
    fontWeight: 'bold',
    color: '#2E7D32',
    backgroundColor: '#E8F5E9',
    padding: '5px',
    margin: '5px 0'
  });
  infoPanel.add(regionLabel);
  
  // Identifier la région - Méthode améliorée
  var regionAtPoint = region_senegal.filterBounds(point);
  
  regionAtPoint.size().evaluate(function(count) {
    if (count > 0) {
      regionAtPoint.first().evaluate(function(feature) {
        if (feature && feature.properties) {
          // Essayer différents noms de propriétés possibles
          var regionName = feature.properties.name || 
                          feature.properties.NAME || 
                          feature.properties.nom || 
                          feature.properties.NOM ||
                          feature.properties.region ||
                          feature.properties.REGION ||
                          feature.properties.ADM1_FR ||
                          feature.properties.ADM1_EN ||
                          'Région identifiée';
          
          regionLabel.setValue('📍 Région: ' + regionName);
          
          // Debug: afficher toutes les propriétés dans la console
          print('Propriétés de la région:', Object.keys(feature.properties));
        } else {
          regionLabel.setValue('📍 Région: Données non disponibles');
        }
      });
    } else {
      regionLabel.setValue('📍 Région: Hors zones répertoriées');
    }
  });
  
  // Ajouter un label de chargement pour la localité
  var localiteLabel = ui.Label('📌 Localité la plus proche: ⏳ Recherche...', {
    fontSize: '13px',
    fontWeight: 'bold',
    color: '#1565C0',
    backgroundColor: '#E3F2FD',
    padding: '5px',
    margin: '5px 0'
  });
  infoPanel.add(localiteLabel);
  
  var distanceLabel = ui.Label('', {
    fontSize: '11px',
    color: '#666',
    margin: '0 0 10px 5px'
  });
  infoPanel.add(distanceLabel);
  
  // Trouver la localité la plus proche
  var allLocalites = city.merge(towns).merge(village).merge(hamlets).merge(banlieu);
  
  // Calculer la distance pour chaque localité
  var localitesAvecDistance = allLocalites.map(function(localite) {
    var distance = localite.geometry().distance(point, 1); // distance en mètres
    return localite.set('distance', distance);
  });
  
  // Trier par distance et prendre la plus proche
  var localitePlusProche = localitesAvecDistance.sort('distance').first();
  
  localitePlusProche.evaluate(function(loc) {
    if (loc && loc.properties) {
      var nomLocalite = loc.properties.name || loc.properties.NAME || loc.properties.nom || loc.properties.NOM || 'Localité inconnue';
      var distanceKm = (loc.properties.distance / 1000).toFixed(2);
      
      localiteLabel.setValue('📌 Localité la plus proche: ' + nomLocalite);
      distanceLabel.setValue('📏 Distance: ' + distanceKm + ' km');
    } else {
      localiteLabel.setValue('📌 Aucune localité proche trouvée');
      distanceLabel.setValue('');
    }
  });
  
  infoPanel.add(ui.Label('------------------------------------------------------------', {margin: '10px 0 5px 0', color: '#E0E0E0'}));
  infoPanel.add(ui.Label('📊 INFRASTRUCTURES DANS UN RAYON DE 10 KM:', {
    fontSize: '12px',
    fontWeight: 'bold',
    color: '#424242',
    margin: '5px 0'
  }));
  
  // Compter les infrastructures dans le buffer
  var stats = [
    {name: '🏥 Hôpitaux', collection: hopitals, color: '#B71C1C'},
    {name: '🏥 Cliniques', collection: clinics, color: '#FF5722'},
    {name: '💊 Pharmacies', collection: pharmacie, color: '#FF9800'},
    {name: '🎓 Universités', collection: universite, color: '#0D47A1'},
    {name: '🏫 Lycées', collection: lycee, color: '#1976D2'},
    {name: '🏛️ Collèges', collection: college, color: '#42A5F5'},
    {name: '📚 Écoles', collection: ecole, color: '#64B5F6'},
    {name: '🌆 Grandes Villes', collection: city, color: '#FFD700'},
    {name: '🏙️ Villes', collection: towns, color: '#FFA726'},
    {name: '🏡 Villages', collection: village, color: '#66BB6A'}
  ];
  
  stats.forEach(function(stat) {
    stat.collection.filterBounds(buffer).size().evaluate(function(count) {
      if (count > 0) {
        var label = ui.Label(stat.name + ': ' + count, {
          fontSize: '12px',
          color: stat.color,
          fontWeight: 'bold',
          margin: '2px 0'
        });
        infoPanel.add(label);
      }
    });
  });
  
  // Population dans la zone
  var popInZone = poptotale.reduceRegion({
    reducer: ee.Reducer.sum(),
    geometry: buffer,
    scale: 1000,
    maxPixels: 1e9
  });
  
  popInZone.evaluate(function(result) {
    var popValue = result[Object.keys(result)[0]];
    if (popValue) {
      infoPanel.add(ui.Label('👥 Population (estimée): ' + Math.round(popValue).toLocaleString(), {
        fontSize: '12px',
        fontWeight: 'bold',
        color: '#FF6F00',
        margin: '5px 0'
      }));
    }
  });
  

  // Message de fermeture automatique
  var autoCloseLabel = ui.Label('⏱️ Cliquez sur ✕ pour fermer ou sur la carte pour une nouvelle zone', {
    fontSize: '10px',
    color: '#999',
    fontStyle: 'italic',
    margin: '10px 0 0 0',
    textAlign: 'center'
  });
  infoPanel.add(autoCloseLabel);
  
  Map.add(infoPanel);
  currentInfoPanel = infoPanel;
  
  // Ajouter un marqueur temporaire
  var marker = ui.Map.Layer(point.buffer(500), {color: 'red'}, 'Sélection');
  Map.layers().set(Map.layers().length(), marker);
  currentMarker = marker;
});

// --------------------------------------------------------------------------
// 8. INTERFACE UTILISATEUR COMPLÈTE
// --------------------------------------------------------------------------

var mainPanel = ui.Panel({
  style: {
    width: '380px',
    position: 'top-left',
    backgroundColor: 'rgba(255, 255, 255, 0.95)',
    padding: '0px'
  }
});

// En-tête
var header = ui.Panel({
  style: {
    backgroundColor: '#1976D2',
    padding: '15px'
  }
});

header.add(ui.Label('🇸🇳 TABLEAU DE BORD', {
  fontSize: '20px',
  fontWeight: 'bold',
  color: 'black',
  textAlign: 'center'
}));

header.add(ui.Label('Analyse des Conditions de Vie au Sénégal', {
  fontSize: '13px',
  color: 'black',
  textAlign: 'center',
  margin: '5px 0 0 0'
}));

mainPanel.add(header);

// Instructions
var instructions = ui.Label(
  '💡 Cliquez n\'importe où sur la carte pour obtenir des informations détaillées sur la zone (rayon 10km).\n\n' +
  '🗺️ Activez/désactivez les couches dans le menu des calques.',
  {fontSize: '11px', padding: '10px', color: '#555', backgroundColor: '#E3F2FD'}
);
mainPanel.add(instructions);

// Statistiques nationales
var statsPanel = ui.Panel({
  style: {padding: '10px', backgroundColor: '#FAFAFA', margin: '5px'}
});

statsPanel.add(ui.Label('📊 STATISTIQUES NATIONALES', {
  fontSize: '14px',
  fontWeight: 'bold',
  color: '#1976D2',
  margin: '0 0 8px 0'
}));

var statsLabel = ui.Label('⏳ Calcul en cours...', {fontSize: '11px'});
statsPanel.add(statsLabel);

mainPanel.add(statsPanel);

// Calcul des statistiques (méthode Earth Engine)
hopitals.size().evaluate(function(nHopitals) {
  clinics.size().evaluate(function(nClinics) {
    pharmacie.size().evaluate(function(nPharmacies) {
      universite.size().evaluate(function(nUniversites) {
        lycee.size().evaluate(function(nLycees) {
          ecole.size().evaluate(function(nEcoles) {
            city.size().evaluate(function(nVilles) {
              village.size().evaluate(function(nVillages) {
                statsLabel.setValue(
                  '🏥 SANTÉ:\n' +
                  '   • Hôpitaux: ' + nHopitals + '\n' +
                  '   • Cliniques: ' + nClinics + '\n' +
                  '   • Pharmacies: ' + nPharmacies + '\n\n' +
                  '🎓 ÉDUCATION:\n' +
                  '   • Universités: ' + nUniversites + '\n' +
                  '   • Lycées: ' + nLycees + '\n' +
                  '   • Écoles: ' + nEcoles + '\n\n' +
                  '🏘️ LOCALITÉS:\n' +
                  '   • Grandes villes: ' + nVilles + '\n' +
                  '   • Villages: ' + nVillages
                );
              });
            });
          });
        });
      });
    });
  });
});

// Boutons d'action
var actionsPanel = ui.Panel({
  style: {padding: '10px', margin: '5px'},
  layout: ui.Panel.Layout.flow('horizontal')
});

var exportBtn = ui.Button({
  label: '📥 Exporter Stats',
  onClick: function() {
    Export.table.toDrive({
      collection: regionsEnrichies,
      description: 'Statistiques_Regions_Senegal',
      fileFormat: 'CSV'
    });
    print('✅ Export lancé! Vérifiez votre Google Drive.');
  },
  style: {stretch: 'horizontal', backgroundColor: '#4CAF50', color: 'white'}
});

var resetBtn = ui.Button({
  label: '🔄 Réinitialiser',
  onClick: function() {
    Map.clear();
    Map.centerObject(shapefile_senegal, 7);
  },
  style: {stretch: 'horizontal', backgroundColor: '#FF5722', color: 'white'}
});

actionsPanel.add(exportBtn);
actionsPanel.add(resetBtn);
mainPanel.add(actionsPanel);

ui.root.insert(0, mainPanel);

// --------------------------------------------------------------------------
// 9. LÉGENDE AMÉLIORÉE
// --------------------------------------------------------------------------

var legend = ui.Panel({
  style: {
    position: 'bottom-left',
    padding: '10px',
    backgroundColor: 'rgba(255, 255, 255, 0.9)'
  }
});

legend.add(ui.Label('🗺️ LÉGENDE', {
  fontWeight: 'bold',
  fontSize: '13px',
  margin: '0 0 5px 0'
}));

var legendItems = [
  {label: '🏥 Rouge foncé: Hôpitaux', color: '#B71C1C'},
  {label: '🏥 Orange: Cliniques', color: '#FF5722'},
  {label: '🎓 Bleu foncé: Universités', color: '#0D47A1'},
  {label: '🏫 Bleu: Lycées', color: '#1976D2'},
  {label: '💧 Bleu clair: Cours d\'eau', color: '#0288D1'},
  {label: '🛣️ Noir: Routes bitumées', color: '#212121'},
  {label: '🌆 Or: Grandes villes', color: '#FFD700'},
  {label: '🏡 Vert: Villages', color: '#66BB6A'}
];

legendItems.forEach(function(item) {
  var panel = ui.Panel({
    layout: ui.Panel.Layout.flow('horizontal'),
    style: {margin: '2px 0'}
  });
  
  var colorBox = ui.Label('■', {
    color: item.color,
    fontSize: '16px',
    margin: '0 5px 0 0'
  });
  
  var label = ui.Label(item.label, {fontSize: '10px'});
  
  panel.add(colorBox);
  panel.add(label);
  legend.add(panel);
});

Map.add(legend);

// --------------------------------------------------------------------------
// 10. CALCUL % POPULATION NON COUVERTE
// --------------------------------------------------------------------------

var popBand = poptotale.bandNames().get(0);

function computeUncoveredPopulation(features, distances, name) {
  distances.forEach(function(dist) {
    var union = features
      .map(function(f){ return f.buffer(dist); })
      .union()
      .geometry();

    var totalPop = poptotale.reduceRegion({
      reducer: ee.Reducer.sum(),
      geometry: shapefile_senegal.geometry(),
      scale: poptotale.projection().nominalScale(),
      maxPixels: 1e13
    }).get(popBand);

    var popCovered = poptotale
      .updateMask(poptotale.clip(union))
      .reduceRegion({
        reducer: ee.Reducer.sum(),
        geometry: shapefile_senegal.geometry(),
        scale: poptotale.projection().nominalScale(),
        maxPixels: 1e13
      }).get(popBand);

    ee.Dictionary({
      total: totalPop,
      covered: popCovered
    }).evaluate(function(res){
      if (!res || res.total === null) {
        print("⚠️ Calcul impossible pour", name, dist/1000, "km");
        return;
      }

      var notCovered = res.total - (res.covered || 0);
      var percent = (notCovered / res.total) * 100;

      print(
        "📊 Population NON couverte —", 
        name, "à", dist/1000, "km :", 
        percent.toFixed(2), "%",
        "(" + Math.round(notCovered).toLocaleString(), "habitants)"
      );
    });
  });
}

print('============================================================');
print('📊 ANALYSE DE COUVERTURE GÉOGRAPHIQUE');
print('============================================================');

computeUncoveredPopulation(hopitals, [5000, 10000, 20000], "Hôpitaux");
computeUncoveredPopulation(clinics, [5000, 10000, 20000], "Cliniques");
computeUncoveredPopulation(ecole, [5000, 10000, 20000], "Écoles");
computeUncoveredPopulation(lycee, [5000, 10000, 20000], "Lycées");
computeUncoveredPopulation(universite, [10000, 20000, 50000], "Universités");

// --------------------------------------------------------------------------
// 11. MESSAGES FINAUX
// --------------------------------------------------------------------------

print('============================================================');
print('✅ CARTE INTERACTIVE CHARGÉE AVEC SUCCÈS !');
print('============================================================');
print('💡 FONCTIONNALITÉS:');
print('   • Cliquez sur la carte pour info détaillées (rayon 10km)');
print('   • Activez les couches dans le panneau latéral');
print('   • Visualisez les zones tampons d\'accessibilité');
print('   • Exportez les statistiques régionales');
print('   • Consultez les cartes choroplèthes');
print('============================================================');