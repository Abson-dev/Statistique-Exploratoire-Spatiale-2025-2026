/****************************************************
 * TP5 – LCRPGR Cameroun (SDG 11.3.1)
 * GHSL built-up + WorldPop + GADM1
 * 
/*** ========= 0. PARAMÈTRES GLOBAUX ========= ***/

// Période d'analyse : 2017–2022
var yearPast    = 2015;
var yearPresent = 2020;
var T           = yearPresent - yearPast;   // 5 ans

// Population WorldPop (tes assets)
var POP_T1_ID = 'projects/stat-exploratoires-spatiales/assets/cmr_pop_2015_CN_100m_R2025A_v1';
var POP_T2_ID = 'projects/stat-exploratoires-spatiales/assets/cmr_pop_2020_CN_100m_R2025A_v1';

// GADM Cameroun
var GADM0_ID = 'projects/stat-exploratoires-spatiales/assets/gadm41_CMR_0';
var GADM1_ID = 'projects/stat-exploratoires-spatiales/assets/gadm41_CMR_1';

// Échelles (un peu grossières pour alléger les calculs)
var builtScale = 500;   // m – GHSL built-up (on agrège un peu)
var popScale   = 500;   // m – WorldPop
var outScale   = 1000;  // m – raster LCRPGR (résolution de sortie)

// Géométries
var country = ee.FeatureCollection(GADM0_ID).geometry();  // Cameroun
var regions = ee.FeatureCollection(GADM1_ID);             // Régions GADM1

Map.centerObject(country, 6);

/*** ========= 1. IMAGES GHSL & POPULATION ========= ***/

// GHSL built-up : surface bâtie (m²) par pixel
function getBuilt(year) {
  return ee.Image('JRC/GHSL/P2023A/GHS_BUILT_S/' + year)
           .select('built_surface')        // m² bâtis par pixel
           .clip(country);
}

var builtPast    = getBuilt(yearPast);
var builtPresent = getBuilt(yearPresent);

// Population WorldPop (tes assets)
var popPast    = ee.Image(POP_T1_ID).clip(country);
var popPresent = ee.Image(POP_T2_ID).clip(country);

/*** ========= 2. FONCTION PRINCIPALE PAR RÉGION ========= ***/

function addLcrpgrStats(feature) {
  var geom = feature.geometry();
  var Tnum = ee.Number(T);

  // ---- BÂTI : somme des surfaces bâties (m²) ----
  var Vpast_m2 = ee.Number(
    builtPast.reduceRegion({
      reducer: ee.Reducer.sum(),
      geometry: geom,
      scale: builtScale,
      maxPixels: 1e13,
      tileScale: 4
    }).get('built_surface')
  );

  var Vpres_m2 = ee.Number(
    builtPresent.reduceRegion({
      reducer: ee.Reducer.sum(),
      geometry: geom,
      scale: builtScale,
      maxPixels: 1e13,
      tileScale: 4
    }).get('built_surface')
  );

  var Vpast_km2 = Vpast_m2.divide(1e6);
  var Vpres_km2 = Vpres_m2.divide(1e6);

  // ---- POPULATION : somme de la population ----
  var popPastTot = ee.Number(
    popPast.reduceRegion({
      reducer: ee.Reducer.sum(),
      geometry: geom,
      scale: popScale,
      maxPixels: 1e13,
      tileScale: 4
    }).values().get(0)          // première bande (peu importe son nom)
  );

  var popPresTot = ee.Number(
    popPresent.reduceRegion({
      reducer: ee.Reducer.sum(),
      geometry: geom,
      scale: popScale,
      maxPixels: 1e13,
      tileScale: 4
    }).values().get(0)
  );

  // ---- LCR, PGR, LCRPGR ----
  var LCR = Vpres_km2.subtract(Vpast_km2)
                     .divide(Vpast_km2)
                     .divide(Tnum);

  var PGR = popPresTot.divide(popPastTot)
                      .log()
                      .divide(Tnum);

  var ratio = LCR.divide(PGR);

  return feature.set({
    'Vpast_km2' : Vpast_km2,
    'Vpres_km2' : Vpres_km2,
    'Pop_past'  : popPastTot,
    'Pop_pres'  : popPresTot,
    'LCR'       : LCR,
    'PGR'       : PGR,
    'LCRPGR'    : ratio
  });
}

/*** ========= 3. APPLICATION AUX RÉGIONS ========= ***/

var regionsStats = regions.map(addLcrpgrStats);
// On ne fait plus de gros reduceColumns direct, juste un aperçu léger
print('Exemple région + stats :', regionsStats.first());

/*** ========= 4. RASTER LCRPGR + LÉGENDE ========= ***/

// 4.1. Rasteriser LCRPGR (valeur constante par région)
var lcrpgrImg = regionsStats.reduceToImage({
  properties: ['LCRPGR'],
  reducer: ee.Reducer.first()
});

// 4.2. Paramètres d'affichage
var vis = {
  min: 0,
  max: 2.5,
  palette: ['#2166ac', '#67a9cf', '#d1e5f0', '#fddbc7', '#ef8a62', '#b2182b']
};

Map.addLayer(lcrpgrImg, vis, 'LCRPGR 2015–2020 (GADM1)');

// 4.3. Légende simple
var legend = ui.Panel({
  style: {
    position: 'bottom-left',
    padding: '8px'
  }
});

legend.add(ui.Label('LCRPGR 2015–2020', {
  fontWeight: 'bold',
  fontSize: '13px',
  margin: '0 0 4px 0'
}));

var legendEntries = [
  {color: '#2166ac', label: '< 0.5  (densification forte)'},
  {color: '#67a9cf', label: '0.5 – 1  (densification)'},
  {color: '#d1e5f0', label: '1 – 1.5 (équilibré)'},
  {color: '#fddbc7', label: '1.5 – 2 (sprawl modéré)'},
  {color: '#ef8a62', label: '> 2    (sprawl fort)'}
];

legendEntries.forEach(function(item) {
  var colorBox = ui.Label({
    style: {
      backgroundColor: item.color,
      padding: '8px',
      margin: '0 4px 4px 0'
    }
  });
  var desc = ui.Label({
    value: item.label,
    style: {margin: '0 0 4px 0', fontSize: '11px'}
  });
  var row = ui.Panel({
    widgets: [colorBox, desc],
    layout: ui.Panel.Layout.Flow('horizontal')
  });
  legend.add(row);
});

Map.add(legend);

/*** ========= 5. EXPORTS (TABLE + RASTER) ========= ***/

// 5.1. Export de la table LCRPGR par région (CSV)
Export.table.toDrive({
  collection: regionsStats,
  description: 'CMR_LCRPGR_regions_GADM1_2015_2020_GHSL',
  fileFormat: 'CSV'
});

// 5.2. Export du raster LCRPGR (GeoTIFF)
Export.image.toDrive({
  image: lcrpgrImg,
  description: 'CMR_LCRPGR_1000m_2015_2020_GHSL',
  fileNamePrefix: 'CMR_LCRPGR_1000m_2015_2020_GHSL',
  region: country,
  scale: outScale,
  maxPixels: 1e13
});

/*** ========= 6. STATISTIQUES GLOBALES + HISTOGRAMME (CÔTÉ CLIENT) ========= ***/
/*
  Pour éviter "Too many concurrent aggregations", on récupère une fois
  la FeatureCollection complète côté client avec evaluate(), puis on calcule
  les stats (min, max, moyenne, écart-type) et on construit le chart
  en JavaScript pur.
*/

regionsStats.evaluate(function(fc) {
  // fc = objet JSON côté client
  var feats = fc.features;
  if (!feats || feats.length === 0) {
    print('Aucune région trouvée.');
    return;
  }

  // Récupérer les noms de régions et les LCRPGR
  var names = [];
  var values = [];
  feats.forEach(function(f) {
    var props = f.properties;
    names.push(props.NAME_1);          // adapter si le champ porte un autre nom
    values.push(props.LCRPGR);
  });

  // Calculs stats simples côté client
  var n = values.length;
  var min = Math.min.apply(null, values);
  var max = Math.max.apply(null, values);

  var sum = 0;
  values.forEach(function(v) { sum += v; });
  var mean = sum / n;

  var varSum = 0;
  values.forEach(function(v) { varSum += Math.pow(v - mean, 2); });
  var std = Math.sqrt(varSum / n);

  print('Résumé global LCRPGR (min / max / mean / stdDev) :', {
    min: min,
    max: max,
    mean: mean,
    stdDev: std
  });

  // Construire une DataTable pour le chart (API Google Viz)
  var dataTable = {
    cols: [
      {id: 'region', label: 'Région', type: 'string'},
      {id: 'lcrpgr', label: 'LCRPGR', type: 'number'}
    ],
    rows: names.map(function(name, i) {
      return {c: [{v: name}, {v: values[i]}]};
    })
  };

  var chart = ui.Chart(dataTable)
    .setChartType('ColumnChart')
    .setOptions({
      title: 'LCRPGR moyen par région (GADM1, 2015–2020)',
      hAxis: { title: 'Région' },
      vAxis: { title: 'LCRPGR' }
    });

  print(chart);
});
