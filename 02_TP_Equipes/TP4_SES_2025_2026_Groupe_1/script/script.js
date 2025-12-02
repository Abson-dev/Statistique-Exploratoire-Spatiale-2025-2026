// -------------------------------------------------------------------------------- //
// *** 0. CONSTANTES ET ASSETS ***

var EE_GAUL_LEVEL0 = 'projects/travaux-pratique-478314/assets/gadm41_BDI_0'; 
var EE_GAUL_LEVEL1 = 'projects/travaux-pratique-478314/assets/gadm41_BDI_1'; 
var EE_GAUL_LEVEL2 = 'projects/travaux-pratique-478314/assets/gadm41_BDI_2'; 

var GFSAD_ASSET_ID = 'projects/travaux-pratique-478314/assets/GFSAD_Burundi_2015'; 
var GMIS_ASSET_ID = 'projects/travaux-pratique-478314/assets/GMIS_Burundi'; 

// -------------------------------------------------------------------------------- //
// *** 1. DÉFINITION DE LA ZONE D'INTÉRÊT (AOI) ***
var AOI_FC = ee.FeatureCollection(EE_GAUL_LEVEL0);
Map.centerObject(AOI_FC, 8);
var AOI_GEOM = AOI_FC.geometry();

// -------------------------------------------------------------------------------- //
// *** 2. COUCHES ADMINISTRATIVES (Contours uniquement, découpés à l'AOI) ***
var clip_and_style = function(feature_collection, color, width, name, visibility) {
  var clipped_fc = feature_collection
                    .filterBounds(AOI_FC)
                    .map(function(f) {
                      return ee.Feature(
                        f.geometry().intersection(AOI_GEOM, ee.ErrorMargin(100)), 
                        f.toDictionary()
                      );
                    });
  Map.addLayer(
    clipped_fc.style({color: color, width: width, fillColor: '00000000'}), 
    {}, 
    name,
    visibility
  );
  return clipped_fc;
};

Map.addLayer(AOI_FC.style({color: '000000', width: 3, fillColor: '00000000'}), {}, '1. Limites Nationales');
var provinces = clip_and_style(ee.FeatureCollection(EE_GAUL_LEVEL1), '555555', 2, '2. Limites Provinces', true);
var communes = clip_and_style(ee.FeatureCollection(EE_GAUL_LEVEL2), 'AAAAAA', 1, '3. Limites Communes', false);

// -------------------------------------------------------------------------------- //
// *** 3. COUCHES D'ANALYSE ***

// A. Terres Cultivées (GFSAD) → booléen
var gfsad_image = ee.Image(GFSAD_ASSET_ID);
var cropland_mask = gfsad_image.select(0).eq(1).clip(AOI_FC);
Map.addLayer(cropland_mask.updateMask(cropland_mask), {palette: ['FF00FF']}, '4. Terres Cultivées (GFSAD)', false); 

// B. Forêts Déboisées (Hansen LossYear 1-15, 2000-2015) → booléen
var gfc = ee.Image('UMD/hansen/global_forest_change_2015_v1_3');
var lossYear = gfc.select(['lossyear']);
var cleared_forest_mask = lossYear.gte(1).and(lossYear.lte(15)).gt(0).clip(AOI_FC);
Map.addLayer(cleared_forest_mask.updateMask(cleared_forest_mask), {palette: ['FF8C00']}, '5. Forêts Déboisées (Hansen)', false);

// C. Zones Protégées (WDPA) → booléen
var wdpa_polygons = ee.FeatureCollection('WCMC/WDPA/current/polygons').filterBounds(AOI_FC);
var reserved_mask = wdpa_polygons.reduceToImage({properties: ['WDPAID'], reducer: ee.Reducer.count()})
    .unmask(0).gt(0).clip(AOI_FC);
Map.addLayer(reserved_mask.updateMask(reserved_mask), {palette: ['0000FF']}, '6. Zones Protégées (WDPA)', false);

// D. Eaux Permanentes (JRC GSW - Occurrence > 75%) → booléen
var gsw = ee.Image('JRC/GSW1_4/GlobalSurfaceWater');
var water_mask = gsw.select('occurrence').gt(75).clip(AOI_FC);
Map.addLayer(water_mask.updateMask(water_mask), {palette: ['00FFFF']}, '7. Eaux Permanentes (JRC)', false);

// E. Pentes Rudes (SRTM > 15°) → booléen
var srtm = ee.Image('USGS/SRTMGL1_003'); 
var slope = ee.Terrain.slope(srtm); 
var slope_mask = slope.gt(15).clip(AOI_FC);
Map.addLayer(slope_mask.updateMask(slope_mask), {palette: ['FF0000']}, '8. Pentes > 15° (SRTM)', false);

// F. Surfaces Imperméables (GMIS - Utilisation du seuil > 10%) → booléen
var gmis_image = ee.Image('projects/travaux-pratique-478314/assets/GMIS_Burundi');
// Sélection de la bande 0 (Percent imperviousness)
var percent_impervious = gmis_image.select(0); 

// 1. Masquer les 255 (NoData) pour qu'ils ne participent pas au calcul.
var gmis_valid = percent_impervious.updateMask(percent_impervious.neq(255));

// 2. Remplacer les 200 (Non-HBASE) par 0 pour garantir qu'ils ne sont pas considérés comme > 10%.
var gmis_clean = gmis_valid.where(gmis_valid.eq(200), 0);

// 3. Application du seuil de 10%.
var impervious_mask = gmis_clean.gt(10).clip(AOI_FC);

Map.addLayer(impervious_mask.updateMask(impervious_mask), {palette: ['808080']}, '9. Surfaces Imperméables (GMIS)', false);


// -------------------------------------------------------------------------------- //
// *** 4. CALCUL DES TERRES ARABLES FINALES (Logique Corrigée 2.0) ***

// ÉTAPE 1: Terres Arables de Base = Cultures OU Forêts déboisées
var terres_arables_base = cropland_mask.unmask(0).or(cleared_forest_mask.unmask(0));

// ÉTAPE 2: Zone d'Exclusion Totale (les pixels à RETIRER valent 1)
// Tous les masques sont des images binaires (0 ou 1)
var zone_exclusion_totale = water_mask.unmask(0)
    .or(slope_mask.unmask(0))
    .or(reserved_mask.unmask(0))
    .or(impervious_mask.unmask(0)); 

// ÉTAPE 3: Création du masque d'Application
// On inverse l'exclusion : là où l'exclusion totale vaut 0 (zones à CONSERVER), ce masque vaut 1.
// Là où l'exclusion vaut 1 (zones à RETIRER), ce masque vaut 0.
var masque_application = zone_exclusion_totale.not();

// ÉTAPE 4: Terres Arables Finales
// On prend la base et on lui applique le masque d'application.
// Les pixels exclus dans masque_application (valeur 0) sont masqués (retirés) de terres_arables_base.
var terres_arables_finales = terres_arables_base.updateMask(masque_application);

// Affichage des couches
Map.addLayer(terres_arables_base.updateMask(terres_arables_base), {palette: ['00FF00']}, '10. Terres Arables de Base (Cultures + Forêts déboisées)', false);
Map.addLayer(zone_exclusion_totale.updateMask(zone_exclusion_totale), {palette: ['000000']}, '11. Zone d\'Exclusion Totale (Masque NOIR)', false);
Map.addLayer(terres_arables_finales.updateMask(terres_arables_finales), {palette: ['006400']}, '12. Terres Arables Finales (après exclusion)', true);


// -------------------------------------------------------------------------------- //
// *** 5. PRÉCALCUL DES STATISTIQUES PAR COMMUNE ET PROVINCE ***
print('Calcul des statistiques par commune et province en cours...');

// Fonction de calcul réutilisable
var calculate_stats = function(feature, area_name_prop) {
  var geom = feature.geometry();
  var area_total = geom.area().divide(1e6); // km²
  
  var arable_area = terres_arables_finales.multiply(ee.Image.pixelArea())
    .reduceRegion({
      reducer: ee.Reducer.sum(),
      geometry: geom,
      scale: 30,
      maxPixels: 1e10,
      bestEffort: true
    }).values().get(0);
  
  var arable_km2 = ee.Number(arable_area).divide(1e6);
  var ratio = arable_km2.divide(area_total).multiply(100);
  
  return feature.set({
    'NOM': feature.get(area_name_prop), 
    'area_total_km2': area_total,
    'arable_km2': arable_km2,
    'ratio_percent': ratio
  });
};

// Calcul pour chaque commune
var communes_with_stats = communes
  .map(function(f) { 
    return calculate_stats(f, 'NAME_2').set({
      'Type': 'Commune', 
      'NOM_PROVINCE': f.get('NAME_1') 
    }); 
  });

// Calcul pour chaque province
var provinces_with_stats = provinces
  .map(function(f) { 
    return calculate_stats(f, 'NAME_1').set({
      'Type': 'Province', 
      'NOM_PROVINCE': f.get('NAME_1') 
    }); 
  });

print('Statistiques calculées pour toutes les communes et provinces.');

// -------------------------------------------------------------------------------- //
// *** 5.5. GRAPHIQUES DE CLASSEMENT (CONSOLE) ***
print('--- CLASSEMENTS PAR PROVINCE ---');

// PROVINCE: 1. Superficie Arable (avec annotations des valeurs statiques)
var chart_prov_arable = ui.Chart.feature.byFeature({
  features: provinces_with_stats.sort('arable_km2', false).limit(5), 
  xProperty: 'NOM',
  yProperties: ['arable_km2']
})
.setChartType('BarChart')
.setOptions({
  title: 'Top 5 des Provinces - Superficie Arable (km²)',
  vAxis: {title: 'Superficie Arable (km²)'},
  hAxis: {title: 'Province'},
  colors: ['#006400'],
  legend: {position: 'none'},
  dataLabels: {
    visible: true,
    style: {fontSize: 10, bold: true, color: '#333'} 
  }
});
print(chart_prov_arable);

// PROVINCE: 2. Ratio Arable 
var chart_prov_ratio = ui.Chart.feature.byFeature({
  features: provinces_with_stats.sort('ratio_percent', false).limit(5), 
  xProperty: 'NOM',
  yProperties: ['ratio_percent']
})
.setChartType('BarChart')
.setOptions({
  title: 'Top 5 des Provinces - Ratio Arable (%)',
  vAxis: {title: 'Ratio (%)', format: '#,##0.00'},
  hAxis: {title: 'Province'},
  colors: ['#27ae60'],
  legend: {position: 'none'},
  dataLabels: {
    visible: true,
    style: {fontSize: 10, bold: true, color: '#333'},
    format: '#,##0.00'
  }
});
print(chart_prov_ratio);

// PROVINCE: 3. Superficie Totale
var chart_prov_total_area = ui.Chart.feature.byFeature({
  features: provinces_with_stats.sort('area_total_km2', false).limit(5), 
  xProperty: 'NOM',
  yProperties: ['area_total_km2']
})
.setChartType('BarChart')
.setOptions({
  title: 'Top 5 des Provinces - Superficie Totale (km²)',
  vAxis: {title: 'Superficie Totale (km²)'},
  hAxis: {title: 'Province'},
  colors: ['#34495e'],
  legend: {position: 'none'},
  dataLabels: {
    visible: true,
    style: {fontSize: 10, bold: true, color: '#333'} 
  }
});
print(chart_prov_total_area);

print('--- CLASSEMENTS PAR COMMUNE ---');

// COMMUNE: 1. Superficie Arable 
var chart_comm_arable = ui.Chart.feature.byFeature({
  features: communes_with_stats.sort('arable_km2', false).limit(5), 
  xProperty: 'NOM',
  yProperties: ['arable_km2']
})
.setChartType('BarChart')
.setOptions({
  title: 'Top 5 des Communes - Superficie Arable (km²)',
  vAxis: {title: 'Superficie Arable (km²)'},
  hAxis: {title: 'Commune'},
  colors: ['#006400'],
  legend: {position: 'none'},
  dataLabels: {
    visible: true,
    style: {fontSize: 10, bold: true, color: '#333'} 
  }
});
print(chart_comm_arable);

// COMMUNE: 2. Ratio Arable 
var chart_comm_ratio = ui.Chart.feature.byFeature({
  features: communes_with_stats.sort('ratio_percent', false).limit(5), 
  xProperty: 'NOM',
  yProperties: ['ratio_percent']
})
.setChartType('BarChart')
.setOptions({
  title: 'Top 5 des Communes - Ratio Arable (%)',
  vAxis: {title: 'Ratio (%)', format: '#,##0.00'},
  hAxis: {title: 'Commune'},
  colors: ['#27ae60'],
  legend: {position: 'none'},
  dataLabels: {
    visible: true,
    style: {fontSize: 10, bold: true, color: '#333'},
    format: '#,##0.00' 
  }
});
print(chart_comm_ratio);

// COMMUNE: 3. Superficie Totale 
var chart_comm_total_area = ui.Chart.feature.byFeature({
  features: communes_with_stats.sort('area_total_km2', false).limit(5), 
  xProperty: 'NOM',
  yProperties: ['area_total_km2']
})
.setChartType('BarChart')
.setOptions({
  title: 'Top 5 des Communes - Superficie Totale (km²)',
  vAxis: {title: 'Superficie Totale (km²)'},
  hAxis: {title: 'Commune'},
  colors: ['#34495e'],
  legend: {position: 'none'},
  dataLabels: {
    visible: true,
    style: {fontSize: 10, bold: true, color: '#333'} 
  }
});
print(chart_comm_total_area);



// -------------------------------------------------------------------------------- //
// *** 5.6. EXPORTATIONS VERS GOOGLE DRIVE ***

// Le chemin d'exportation imbriqué correct pour créer TP4_SES_Groupe_1/outputs
var EXPORT_FOLDER = 'TP4_SES_Groupe_1_outputs';

print('--- TÂCHES D\'EXPORTATION PRÊTES (Voir l\'onglet Tasks) ---');

// Liste des colonnes STATISTIQUES à conserver dans les CSV, y compris le 'Type'
var stats_columns_global = ['NOM', 'NOM_PROVINCE', 'Type', 'area_total_km2', 'arable_km2', 'ratio_percent'];


// A. EXPORTATION DU FICHIER CSV POUR LES COMMUNES
var communes_exported = communes_with_stats.select(stats_columns_global);

Export.table.toDrive({
  collection: communes_exported,
  description: 'Stats_Communes', 
  folder: EXPORT_FOLDER, 
  fileNamePrefix: 'Stats_Communes',
  fileFormat: 'CSV'
});


// B. EXPORTATION DU FICHIER CSV POUR LES PROVINCES
var provinces_exported = provinces_with_stats.select(stats_columns_global);

Export.table.toDrive({
  collection: provinces_exported,
  description: 'Stats_Provinces', 
  folder: EXPORT_FOLDER, 
  fileNamePrefix: 'Stats_Provinces',
  fileFormat: 'CSV'
});

// -------------------------------------------------------------------------------- //
// *** 6. PANNEAU DE STATISTIQUES GLOBALES ***
var statsPanel = ui.Panel({
  style: {
    width: '320px',
    position: 'top-left',
    padding: '10px',
    backgroundColor: 'white'
  }
});

statsPanel.add(ui.Label('STATISTIQUES NATIONALES', {
  fontWeight: 'bold',
  fontSize: '16px',
  margin: '0 0 10px 0'
}));

statsPanel.add(ui.Label('Calcul en cours...', {fontStyle: 'italic', color: '888888'}));

Map.add(statsPanel);

// Calcul des statistiques
var superficie_arables_m2 = terres_arables_finales.multiply(ee.Image.pixelArea())
    .reduceRegion({
      reducer: ee.Reducer.sum(),
      geometry: AOI_GEOM,
      scale: 30,
      maxPixels: 1e10
    }).values().get(0);

// Évaluation séparée pour éviter les problèmes
provinces.size().evaluate(function(nb_prov) {
  communes.size().evaluate(function(nb_comm) {
    AOI_FC.geometry().area().divide(1e6).evaluate(function(sup_pays) {
      ee.Number(superficie_arables_m2).divide(1e6).evaluate(function(sup_arables) {
        
        var stats = {
          nb_provinces: nb_prov,
          nb_communes: nb_comm,
          superficie_pays: sup_pays,
          superficie_arables: sup_arables || 0
        };
        
        statsPanel.clear();
        
        statsPanel.add(ui.Label('STATISTIQUES NATIONALES', {
          fontWeight: 'bold',
          fontSize: '16px',
          margin: '0 0 10px 0',
          color: '2c3e50'
        }));
  
  // Nombre de provinces
  statsPanel.add(ui.Label('Nombre de provinces :', {fontWeight: 'bold', margin: '10px 0 2px 0'}));
  statsPanel.add(ui.Label(stats.nb_provinces.toString(), {fontSize: '14px', margin: '0 0 5px 10px'}));
  
  // Nombre de communes
  statsPanel.add(ui.Label('Nombre de communes :', {fontWeight: 'bold', margin: '5px 0 2px 0'}));
  statsPanel.add(ui.Label(stats.nb_communes.toString(), {fontSize: '14px', margin: '0 0 5px 10px'}));
  
  statsPanel.add(ui.Label('──────────────────', {color: 'CCCCCC'}));
  
  // Superficie pays
  var sup_pays_str = stats.superficie_pays.toFixed(0).replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
  statsPanel.add(ui.Label('Superficie du Burundi :', {fontWeight: 'bold', margin: '5px 0 2px 0'}));
  statsPanel.add(ui.Label(sup_pays_str + ' km²', {fontSize: '14px', margin: '0 0 5px 10px'}));
  
  // Superficie terres arables
  var sup_arables_str = stats.superficie_arables.toFixed(0).replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
  statsPanel.add(ui.Label("Superficie de l'ensemble des terres arables du Burundi :", {fontWeight: 'bold', margin: '5px 0 2px 0'}));
  statsPanel.add(ui.Label(sup_arables_str + ' km²', {fontSize: '14px', margin: '0 0 5px 10px', color: '006400'}));
  
  // Ratio
  var ratio = (stats.superficie_arables / stats.superficie_pays) * 100;
  statsPanel.add(ui.Label('Ratio Superficie des terres arables / superficie totale :', {fontWeight: 'bold', margin: '5px 0 2px 0'}));
  statsPanel.add(ui.Label(ratio.toFixed(2) + ' %', {
    fontSize: '16px', 
    margin: '0 0 5px 10px',
    color: '006400',
    fontWeight: 'bold'
  }));
      });
    });
  });
});

// -------------------------------------------------------------------------------- //
// *** 7. CLIC INTERACTIF AVEC STATISTIQUES ***
var infoPanel = ui.Panel({
  style: {
    width: '320px', 
    position: 'bottom-left', 
    padding: '10px',
    backgroundColor: 'white'
  }
});

// Message d'instruction initial
infoPanel.add(ui.Label(' INFORMATIONS LOCALES', {
  fontWeight: 'bold',
  fontSize: '14px',
  margin: '0 0 8px 0',
  color: '2c3e50'
}));

infoPanel.add(ui.Label('Cliquez sur un point du pays pour obtenir les informations sur :', {
  fontSize: '12px',
  margin: '0 0 5px 0',
  whiteSpace: 'pre-wrap'
}));

infoPanel.add(ui.Label('• La commune (nom, superficie totale, superficie de terres arables, ratio)', {
  fontSize: '11px',
  margin: '0 0 3px 5px'
}));

infoPanel.add(ui.Label('• La province (nom, superficie totale, superficie de terres arables, ratio)', {
  fontSize: '11px',
  margin: '0 0 5px 5px'
}));

Map.add(infoPanel);

var display_names_on_click = function(coords) {
  infoPanel.clear();
  infoPanel.add(ui.Label(' Recherche en cours...', {fontWeight: 'bold', fontSize: '13px'}));
  
  var clickPoint = ee.Geometry.Point(coords.lon, coords.lat);
  
  var clicked_commune = communes_with_stats.filterBounds(clickPoint).first();
  var clicked_province = provinces_with_stats.filterBounds(clickPoint).first();
  
  clicked_commune.evaluate(function(commune_result) {
    clicked_province.evaluate(function(province_result) {
      
      infoPanel.clear();
      
      if (!commune_result || !province_result) {
        infoPanel.add(ui.Label('Aucune donnée à cet emplacement. Veuillez cliquer sur un point inclus dans le territoire national.', {
          color: 'red',
          fontSize: '13px',
          fontWeight: 'bold'
        }));
        return;
      }
      
      var commune_name = commune_result.properties.NOM || 'N/A';
      var province_name = province_result.properties.NOM || 'N/A';
      
      var sup_comm = commune_result.properties.area_total_km2 || 0;
      var arable_comm_km2 = commune_result.properties.arable_km2 || 0;
      var ratio_comm = commune_result.properties.ratio_percent || 0;
      
      var sup_prov = province_result.properties.area_total_km2 || 0;
      var arable_prov_km2 = province_result.properties.arable_km2 || 0;
      var ratio_prov = province_result.properties.ratio_percent || 0;
      
      // En-tête
      infoPanel.add(ui.Label('📍 INFORMATIONS LOCALES', {
        fontWeight: 'bold',
        fontSize: '14px',
        margin: '0 0 10px 0',
        color: '2c3e50'
      }));
      
      // COMMUNE
      infoPanel.add(ui.Label('COMMUNE', {
        fontWeight: 'bold',
        fontSize: '13px',
        margin: '0 0 5px 0',
        color: '34495e'
      }));
      
      infoPanel.add(ui.Label('Nom :', {fontWeight: 'bold', margin: '0 0 2px 0', fontSize: '11px'}));
      infoPanel.add(ui.Label(commune_name, {margin: '0 0 6px 10px', fontSize: '12px'}));
      
      infoPanel.add(ui.Label('Superficie totale :', {fontWeight: 'bold', margin: '0 0 2px 0', fontSize: '11px'}));
      infoPanel.add(ui.Label(sup_comm.toFixed(2) + ' km²', {margin: '0 0 6px 10px', fontSize: '11px'}));
      
      infoPanel.add(ui.Label('Superficie terres arables :', {fontWeight: 'bold', margin: '0 0 2px 0', fontSize: '11px'}));
      infoPanel.add(ui.Label(arable_comm_km2.toFixed(2) + ' km²', {margin: '0 0 6px 10px', fontSize: '11px', color: '27ae60'}));
      
      infoPanel.add(ui.Label('Ratio :', {fontWeight: 'bold', margin: '0 0 2px 0', fontSize: '11px'}));
      infoPanel.add(ui.Label(ratio_comm.toFixed(2) + ' %', {margin: '0 0 10px 10px', fontSize: '13px', fontWeight: 'bold', color: '27ae60'}));
      
      infoPanel.add(ui.Label('━━━━━━━━━━━━━━━━━', {color: 'CCCCCC'}));
      
      // PROVINCE
      infoPanel.add(ui.Label('PROVINCE', {
        fontWeight: 'bold',
        fontSize: '13px',
        margin: '8px 0 5px 0',
        color: '34495e'
      }));
      
      infoPanel.add(ui.Label('Nom :', {fontWeight: 'bold', margin: '0 0 2px 0', fontSize: '11px'}));
      infoPanel.add(ui.Label(province_name, {margin: '0 0 6px 10px', fontSize: '12px'}));
      
      infoPanel.add(ui.Label('Superficie totale :', {fontWeight: 'bold', margin: '0 0 2px 0', fontSize: '11px'}));
      infoPanel.add(ui.Label(sup_prov.toFixed(2) + ' km²', {margin: '0 0 6px 10px', fontSize: '11px'}));
      
      infoPanel.add(ui.Label('Superficie terres arables :', {fontWeight: 'bold', margin: '0 0 2px 0', fontSize: '11px'}));
      infoPanel.add(ui.Label(arable_prov_km2.toFixed(2) + ' km²', {margin: '0 0 6px 10px', fontSize: '11px', color: '27ae60'}));
      
      infoPanel.add(ui.Label('Ratio :', {fontWeight: 'bold', margin: '0 0 2px 0', fontSize: '11px'}));
      infoPanel.add(ui.Label(ratio_prov.toFixed(2) + ' %', {margin: '0 0 5px 10px', fontSize: '13px', fontWeight: 'bold', color: '27ae60'}));
      
    });
  });
};

Map.onClick(display_names_on_click);