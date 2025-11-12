///////////////////////////////////////////////////////////////////////////////////////////////
////      ECOLE NATIONALE DE LA STATISTIQUE ET DE L'ANALYSE ECONOMIQUE PIERRE NDIAYE     /////
////          COURS DE STATISTIQUES EXPLORATOIRE ET SPATIALE - ISE1_CYCLE LONG          /////
////                           ENSEIGNANT: M.?HEMA Aboubacar                                  /////
////                   TP1_GOOGLE EARTH ENGINE AVEC JAVASCRIPT 
////                   PAYS : Cameroun
////                  MEMBRES: AGNANGMA SANAM David Landry                             /////
////                           DIOP Astou                                            /////
////                           DIOP Mareme                                          /////
////                           NGAKE YAMAHA Herman Parfait                         /////
//////////////////////////////////////////////////////////////////////////////////////









// Carte des subdivisions administratives du Cameroun


// --- 1. CHARGEMENT DES LIMITES ADMINISTRATIVES ---
var regions = ee.FeatureCollection('projects/initiation-476717/assets/gadm41_CMR_1');
var departements = ee.FeatureCollection('projects/initiation-476717/assets/gadm41_CMR_2');
var arrondissements = ee.FeatureCollection('projects/initiation-476717/assets/gadm41_CMR_3');

// --- 2. CONFIGURATION INITIALE DE LA CARTE ---
Map.setCenter(12.3547, 6.0, 6);

// Définition des styles
var styleRegions = {color: 'black', fillColor: '00000000', width: 2};
var styleDepartements = {color: 'blue', fillColor: '00000000', width: 1};
var styleArrondissements = {color: 'green', fillColor: '00000000', width: 0.5};

// Afficher les régions par défaut
var layerRegions = Map.addLayer(regions.style(styleRegions), {}, 'Contours Régions', true);
// Pré-charger les autres couches masquées
var layerDepartements = Map.addLayer(departements.style(styleDepartements), {}, 'Contours Départements', false);
var layerArrondissements = Map.addLayer(arrondissements.style(styleArrondissements), {}, 'Contours Arrondissements', false);


// --- 3. CRÉATION DU PANNEAU DE CONTRÔLE ---
var panel = ui.Panel({
  style: {
    position: 'top-left',
    padding: '10px',
    width: '320px',
    maxHeight: '95%'
  }
});

var titre = ui.Label({
  value: 'Subdivisions administratives du Cameroun',
  style: {fontSize: '18px', fontWeight: 'bold', margin: '0 0 10px 0'}
});
panel.add(titre);

// Panel pour afficher le nom du lieu cliqué sur la carte
var identificationPanel = ui.Panel({
  style: {
    // CORRECTION FINALE : On le laisse en position fixe (bottom-right)
    // pour éviter les erreurs de top/left/float/absolute.
    position: 'bottom-right', 
    padding: '8px',
    backgroundColor: 'rgba(255, 255, 255, 0.9)',
    border: '1px solid #999',
    shown: false // Masqué par défaut
  }
});
Map.add(identificationPanel);


// --- 4. LOGIQUE D'IDENTIFICATION AU CLIC ---

Map.onClick(function(coords) {
  // Masquer l'ancien panneau d'identification
  identificationPanel.style().set('shown', false); 

  var point = ee.Geometry.Point(coords.lon, coords.lat);
  
  // Fonction pour trouver le nom du polygone cliqué dans une FeatureCollection
  var getName = function(featureCollection, nameProperty) {
    return featureCollection.filterBounds(point).first().get(nameProperty);
  };
  
  // Exécuter les requêtes (côté client) pour récupérer les noms
  ee.List([
    getName(regions, 'NAME_1'),
    getName(departements, 'NAME_2'),
    getName(arrondissements, 'NAME_3')
  ]).evaluate(function(names) {
    
    var output = '--- Lieu Cliqué ---';
    var found = false;

    // Récupération des noms
    var regionName = names[0];
    var deptName = names[1];
    var arrName = names[2];

    if (regionName) {
      output += '\nRégion: ' + regionName;
      found = true;
    }
    if (deptName) {
      output += '\nDépartement: ' + deptName;
    }
    if (arrName) {
      output += '\nArrondissement: ' + arrName;
    }
    
    // Affichage dans la console (Inspection)
    print(output);
    
    // Affichage sur la carte (Panel fixe en bas à droite)
    if (found) {
      identificationPanel.clear();
      identificationPanel.add(ui.Label({
        value: 'Région: ' + regionName + '\n' +
               'Département: ' + (deptName ? deptName : 'N/A') + '\n' + 
               'Arrondissement: ' + (arrName ? arrName : 'N/A'),
        style: {whiteSpace: 'pre', fontWeight: 'bold', fontSize: '11px'}
      }));
      
      // Afficher le panneau (pas de manipulation de top/left/float)
      identificationPanel.style().set('shown', true);
    }
    
  });
});

// --- 5. CONTRÔLE DE VISIBILITÉ (UI) ---

function createLayerControl(label, layer, defaultValue) {
  var control = ui.Checkbox(label, defaultValue);
  control.onChange(function(checked) {
    layer.setShown(checked);
  });
  return control;
}

panel.add(ui.Label('Afficher/Masquer les Contours', {fontSize: '14px', fontWeight: 'bold', margin: '10px 0 8px 0'}));
panel.add(createLayerControl('Régions (10)', layerRegions, true));
panel.add(createLayerControl('Départements (58)', layerDepartements, false));
panel.add(createLayerControl('Arrondissements (360)', layerArrondissements, false));

panel.add(ui.Label('---', {margin: '15px 0 0 0'}));
panel.add(ui.Label('Identification des noms', {fontSize: '14px', fontWeight: 'bold', margin: '10px 0 0 0'}));
panel.add(ui.Label('Cliquez n\'importe où sur la carte pour voir le nom de la Région/Département/Arrondissement.', {fontStyle: 'italic', fontSize: '11px', margin: '5px 0 0 0'}));


// --- 6. LÉGENDE DES COULEURS (Contours) ---
var legendePanel = ui.Panel({
  style: {padding: '5px', backgroundColor: '#f9f9f9', border: '1px solid #ddd', margin: '15px 0 0 0'}
});

var items = [
  {color: 'black', label: 'Régions (Épaisse)'},
  {color: 'blue', label: 'Départements (Moyenne)'},
  {color: 'green', label: 'Arrondissements (Fine)'}
];

items.forEach(function(item) {
  var row = ui.Panel({layout: ui.Panel.Layout.Flow('horizontal'), style: {margin: '2px 0'}});
  var colorBox = ui.Label({style: {backgroundColor: item.color, padding: '8px', margin: '0 6px 0 0', border: '1px solid #999'}});
  var label = ui.Label({value: item.label, style: {fontSize: '11px'}});
  row.add(colorBox);
  row.add(label);
  legendePanel.add(row);
});
panel.add(legendePanel);

// Ajouter le panneau à la carte
ui.root.insert(0, panel);

print('Carte interactive chargée. Cliquez sur la carte pour identifier.');