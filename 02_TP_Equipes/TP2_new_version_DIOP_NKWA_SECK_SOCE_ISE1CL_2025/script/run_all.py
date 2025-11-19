# ==============================================================================
# run_all.py
# Script principal d'exécution - Analyse complète des infrastructures
# ==============================================================================
# ==============================================================================
# run_all.py
# Script principal d'exécution - Analyse complète des infrastructures
# ==============================================================================

import os
import warnings
import sys
from pathlib import Path

warnings.filterwarnings('ignore')

# Ajouter le répertoire du script au path
script_dir = Path(__file__).parent
sys.path.insert(0, str(script_dir))

# Imports des modules personnalisés
try:
    import data_loader as dl
    import preprocessing as prep
    import analyses as ana
    import viz as vz
    import interactive as inter
    import advanced_viz as adv
    import departmental_analysis as dept
    
    DataLoader = dl.DataLoader
    DataPreprocessor = prep.DataPreprocessor
    InfrastructureAnalyzer = ana.InfrastructureAnalyzer
    InfrastructureVisualizer = vz.InfrastructureVisualizer
    InteractiveMapper = inter.InteractiveMapper
    AdvancedVisualizer = adv.AdvancedVisualizer
    DepartmentalAnalyzer = dept.DepartmentalAnalyzer
    
except ImportError as e:
    print(f"⚠ Erreur d'importation : {e}")
    print("\n📁 Vérifiez que ces fichiers sont présents dans le dossier 'script/':")
    print("  • data_loader.py")
    print("  • preprocessing.py")
    print("  • utils.py")
    print("  • analyses.py")
    print("  • viz.py")
    print("  • interactive.py")
    print("  • advanced_viz.py")
    print("  • departmental_analysis.py")
    import traceback
    traceback.print_exc()
    sys.exit(1)

def print_header(text):
    """Affiche un en-tête formaté"""
    print("\n" + "="*70)
    print(text.center(70))
    print("="*70 + "\n")

def print_section(text):
    """Affiche un titre de section"""
    print("\n" + "-"*70)
    print(text.center(70))
    print("-"*70 + "\n")

def main():
    """
    Fonction principale pour exécuter toute l'analyse
    """
    
    print_header("ANALYSE SPATIALE DES INFRASTRUCTURES - BÉNIN")
    print("Ce script va:")
    print("  1. Charger les données OSM et administratives")
    print("  2. Prétraiter et harmoniser les données")
    print("  3. Analyser l'accessibilité aux infrastructures")
    print("  4. Générer des visualisations statiques et interactives")
    print("  5. Créer des visualisations avancées thématiques")
    print("  6. Calculer des statistiques départementales")
    print("  7. Exporter tous les résultats")
    print()
    
    # Demander confirmation (tapez --skip-confirm pour ignorer)
    if "--skip-confirm" not in sys.argv:
        response = input("Continuer? (o/n): ").lower()
        if response not in ['o', 'oui', 'y', 'yes']:
            print("Annulation.")
            return
    else:
        print("Mode automatique activé (--skip-confirm)")
        print()
    
    # -------------------------
    # 1. CHARGEMENT DES DONNÉES
    # -------------------------
    print_header("ÉTAPE 1/7 : CHARGEMENT DES DONNÉES")
    
    loader = DataLoader(data_dir="data")
    
    try:
        # Charger limites administratives
        print("Chargement des limites administratives...")
        boundaries = loader.load_boundaries(level=1)  # Niveau département
        
        # Charger localités
        print("\nChargement des localités...")
        places = loader.load_osm_layer('places', geometry_type='free')
        
        # Charger POIs (points d'intérêt)
        print("\nChargement des points d'intérêt...")
        pois = loader.load_osm_layer('pois', geometry_type='free')
        
        # Charger autres infrastructures
        print("\nChargement des cours d'eau...")
        waterways = loader.load_osm_layer('waterways', geometry_type='free')
        
        print("\nChargement des plans d'eau...")
        water = loader.load_osm_layer('water', geometry_type='polygon')
        
        print("\nChargement des routes...")
        roads = loader.load_osm_layer('roads', geometry_type='free')
        
        print("\nChargement des chemins de fer...")
        railways = loader.load_osm_layer('railways', geometry_type='free')
        
        # Charger zones protégées
        print("\nChargement des zones protégées...")
        protected = loader.load_protected_areas()
        
        # Charger population (optionnel)
        print("\nChargement du raster de population...")
        try:
            pop_raster = loader.load_population_raster(resolution='1km')
        except Exception as e:
            print(f"  ⚠ Raster population non chargé : {e}")
            pop_raster = None
        
        # Liste des couches disponibles
        loader.list_available_layers()
        
    except Exception as e:
        print(f"\n⚠ Erreur lors du chargement : {e}")
        import traceback
        traceback.print_exc()
        return
    
    # -------------------------
    # 2. PRÉTRAITEMENT
    # -------------------------
    print_header("ÉTAPE 2/7 : PRÉTRAITEMENT")
    
    preprocessor = DataPreprocessor()
    
    try:
        # Harmoniser les CRS
        print("Harmonisation des systèmes de coordonnées...")
        [boundaries, places, pois, waterways, water, roads, railways, protected] = \
            preprocessor.harmonize_crs(
                [boundaries, places, pois, waterways, water, roads, railways, protected],
                target_crs="EPSG:4326"
            )
        
        # Nettoyer les géométries
        print_section("Nettoyage des géométries")
        places = preprocessor.clean_geometries(places)
        pois = preprocessor.clean_geometries(pois)
        if roads is not None:
            roads = preprocessor.clean_geometries(roads, verbose=False)
        
        # Extraire les infrastructures thématiques
        print_section("Extraction des infrastructures thématiques")
        
        print("Extraction des infrastructures de santé...")
        health_facilities = preprocessor.extract_health_facilities(pois)
        
        print("\nExtraction des infrastructures éducatives...")
        schools = preprocessor.extract_education(pois)
        
        print("\nExtraction des localités...")
        localities = preprocessor.extract_localities(places)
        
        # Vérifier qu'on a bien des données
        if localities is None or len(localities) == 0:
            print("⚠ Aucune localité trouvée. Utilisation de tous les points...")
            localities = places
        
    except Exception as e:
        print(f"\n⚠ Erreur lors du prétraitement : {e}")
        import traceback
        traceback.print_exc()
        return
    
    # -------------------------
    # 3. ANALYSES SPATIALES
    # -------------------------
    print_header("ÉTAPE 3/7 : ANALYSES SPATIALES")
    
    # Initialiser l'analyseur
    analyzer = InfrastructureAnalyzer(boundaries, localities)
    
    # Préparer les infrastructures à analyser
    infrastructures = {}
    
    if 'hospitals' in health_facilities:
        infrastructures['Hôpitaux'] = health_facilities['hospitals']
    if 'clinics' in health_facilities:
        infrastructures['Cliniques'] = health_facilities['clinics']
    if 'pharmacies' in health_facilities:
        infrastructures['Pharmacies'] = health_facilities['pharmacies']
    if schools is not None:
        infrastructures['Écoles'] = schools
    if waterways is not None:
        infrastructures['Cours d\'eau'] = waterways
    if railways is not None:
        infrastructures['Chemins de fer'] = railways
    
    # Analyser chaque type d'infrastructure
    for infra_name, infra_gdf in infrastructures.items():
        if infra_gdf is not None and len(infra_gdf) > 0:
            try:
                analyzer.analyze_proximity(infra_gdf, infra_name, buffer_distance=100)
            except Exception as e:
                print(f"⚠ Erreur lors de l'analyse de {infra_name} : {e}")
    
    # Identifier les zones sous-desservies
    if len(analyzer.results) > 0:
        print_section("Identification des zones sous-desservies")
        underserved = analyzer.identify_underserved_areas(threshold_distance=5000)
        
        # Exporter les résultats
        print_section("Export des analyses")
        analyzer.export_results(output_dir="outputs/analyses")
    else:
        print("⚠ Aucune analyse disponible pour l'export")
    
    # -------------------------
    # 4. VISUALISATIONS STATIQUES
    # -------------------------
    print_header("ÉTAPE 4/7 : VISUALISATIONS STATIQUES")
    
    os.makedirs("outputs/maps", exist_ok=True)
    
    if len(analyzer.results) > 0:
        visualizer = InfrastructureVisualizer(boundaries, analyzer.results)
        
        print("Génération des cartes et graphiques...\n")
        for infra_name in analyzer.results.keys():
            try:
                print(f"  • {infra_name}...")
                
                # Nettoyer le nom pour les fichiers
                clean_name = infra_name.lower().replace(' ', '_').replace('é', 'e').replace('è', 'e').replace('\'', '_')
                
                # Carte
                visualizer.plot_infrastructure_map(
                    infra_name,
                    output_file=f"outputs/maps/carte_{clean_name}.png"
                )
                
                # Histogramme
                visualizer.plot_distance_distribution(
                    infra_name,
                    output_file=f"outputs/maps/hist_{clean_name}.png"
                )
            except Exception as e:
                print(f"    ⚠ Erreur : {e}")
        
        # Graphique comparatif
        try:
            print(f"\n  • Graphique comparatif...")
            visualizer.plot_comparison_barplot(
                output_file="outputs/maps/comparaison_infrastructures.png"
            )
        except Exception as e:
            print(f"    ⚠ Erreur : {e}")
        
        # Tableau de bord
        try:
            print(f"  • Tableau de bord...")
            visualizer.plot_summary_dashboard(
                output_file="outputs/maps/dashboard_complet.png"
            )
        except Exception as e:
            print(f"    ⚠ Erreur : {e}")
    else:
        print("⚠ Aucune visualisation possible (pas de résultats)")
    
    # -------------------------
    # 5. CARTES INTERACTIVES
    # -------------------------
    print_header("ÉTAPE 5/7 : CARTES INTERACTIVES")
    
    os.makedirs("outputs/interactive", exist_ok=True)
    
    if len(analyzer.results) > 0:
        mapper = InteractiveMapper(boundaries)
        
        print("Génération des cartes interactives...\n")
        for infra_name in analyzer.results.keys():
            try:
                print(f"  • {infra_name}...")
                clean_name = infra_name.lower().replace(' ', '_').replace('é', 'e').replace('è', 'e').replace('\'', '_')
                
                mapper.create_accessibility_map(
                    analyzer.results,
                    infra_name,
                    output_file=f"outputs/interactive/carte_{clean_name}.html"
                )
            except Exception as e:
                print(f"    ⚠ Erreur : {e}")
    else:
        print("⚠ Aucune carte interactive possible (pas de résultats)")
    
    # -------------------------
    # 6. VISUALISATIONS AVANCÉES
    # -------------------------
    print_header("ÉTAPE 6/7 : VISUALISATIONS AVANCÉES")
    
    os.makedirs("outputs/advanced", exist_ok=True)
    
    try:
        adv_viz = AdvancedVisualizer(boundaries, output_dir="outputs/advanced")
        
        # Population
        if pop_raster is not None:
            try:
                print("Carte de population...")
                adv_viz.plot_population_raster(
                    pop_raster.name,
                    output_file="outputs/advanced/population_benin.png"
                )
            except Exception as e:
                print(f"  ⚠ Population : {e}")
        
        # Localités
        if places is not None:
            try:
                print("Carte des localités...")
                adv_viz.plot_localities_map(
                    places,
                    output_file="outputs/advanced/localites_benin.png"
                )
            except Exception as e:
                print(f"  ⚠ Localités : {e}")
        
        # Santé + Éducation
        if pois is not None:
            try:
                print("Carte santé/éducation...")
                adv_viz.plot_health_education_map(
                    pois,
                    output_file="outputs/advanced/sante_education_benin.png"
                )
            except Exception as e:
                print(f"  ⚠ Santé/Éducation : {e}")
        
        # Aires protégées
        if protected is not None:
            try:
                print("Carte des aires protégées...")
                adv_viz.plot_protected_areas_map(
                    protected,
                    output_file="outputs/advanced/aires_protegees_benin.png"
                )
            except Exception as e:
                print(f"  ⚠ Aires protégées : {e}")
        
        # Hydrographie
        try:
            print("Carte hydrographique...")
            adv_viz.plot_hydrography_map(
                water,
                waterways,
                output_file="outputs/advanced/hydrographie_benin.png"
            )
        except Exception as e:
            print(f"  ⚠ Hydrographie : {e}")
        
        # Transport
        try:
            print("Carte des transports...")
            adv_viz.plot_transport_map(
                roads,
                railways,
                output_file="outputs/advanced/transport_benin.png"
            )
        except Exception as e:
            print(f"  ⚠ Transport : {e}")
    
    except Exception as e:
        print(f"\n⚠ Erreur dans les visualisations avancées : {e}")
        import traceback
        traceback.print_exc()
    
    # -------------------------
    # 7. ANALYSES DÉPARTEMENTALES
    # -------------------------
    print_header("ÉTAPE 7/7 : ANALYSES DÉPARTEMENTALES")
    
    try:
        # Déterminer la colonne des noms de départements
        dept_col = None
        for col in ['shapeName', 'NAME_1', 'name', 'ADMIN1']:
            if col in boundaries.columns:
                dept_col = col
                break
        
        if dept_col is None:
            print("⚠ Colonne de noms de départements non trouvée")
            print(f"  Colonnes disponibles : {boundaries.columns.tolist()}")
            dept_col = boundaries.columns[0]  # Utiliser la première colonne par défaut
        
        print(f"Utilisation de la colonne '{dept_col}' pour les départements\n")
        
        dept_analyzer = DepartmentalAnalyzer(boundaries, dept_col=dept_col)
        
        # Compter les infrastructures
        print("Comptage des infrastructures par département...")
        for infra_name, infra_gdf in infrastructures.items():
            if infra_gdf is not None and len(infra_gdf) > 0:
                col_name = f"n_{infra_name.lower().replace(' ', '_').replace('é','e').replace('è','e').replace('\'','_')}"
                dept_analyzer.count_infrastructures_by_dept(infra_gdf, col_name)
        
        # Population
        if pop_raster is not None:
            try:
                print("\nExtraction de la population par département...")
                dept_analyzer.compute_population_by_dept(pop_raster.name)
            except Exception as e:
                print(f"  ⚠ Population : {e}")
        
        # Aires protégées
        if protected is not None and len(protected) > 0:
            try:
                print("\nCalcul des aires protégées par département...")
                dept_analyzer.compute_protected_areas(protected)
            except Exception as e:
                print(f"  ⚠ Aires protégées : {e}")
        
        # Densités
        if 'n_ecoles' in dept_analyzer.stats.columns:
            dept_analyzer.compute_density('n_ecoles', result_col='ecoles_per_km2')
        
        # Résumé
        dept_analyzer.summary()
        
        # Export
        dept_analyzer.export_stats("outputs/analyses/stats_departements.csv")
        
        # Visualisations départementales
        dept_stats = dept_analyzer.get_geodataframe()
        
        # Trouver une colonne numérique à cartographier
        numeric_cols = [col for col in dept_stats.columns if col.startswith('n_')]
        
        if numeric_cols:
            for col in numeric_cols[:3]:  # Limiter à 3 pour ne pas surcharger
                try:
                    print(f"\nGénération des visualisations pour {col}...")
                    
                    # Carte choroplèthe
                    adv.plot_choropleth_department(
                        dept_stats, dept_col, col,
                        output_file=f"outputs/advanced/choropleth_{col}.png"
                    )
                    
                    # Graphique en barres
                    adv.plot_bar_department(
                        dept_stats, dept_col, col,
                        output_file=f"outputs/advanced/barplot_{col}.png"
                    )
                except Exception as e:
                    print(f"  ⚠ Erreur pour {col} : {e}")
        else:
            print("⚠ Aucune colonne numérique pour les visualisations départementales")
    
    except Exception as e:
        print(f"\n⚠ Erreur dans les analyses départementales : {e}")
        import traceback
        traceback.print_exc()
    
    # -------------------------
    # 8. RÉSUMÉ FINAL
    # -------------------------
    print_header("ANALYSE TERMINÉE")
    
    print(f"📁 Fichiers générés :")
    print(f"  • Analyses statistiques : outputs/analyses/")
    print(f"  • Cartes et graphiques : outputs/maps/")
    print(f"  • Cartes interactives : outputs/interactive/")
    print(f"  • Visualisations avancées : outputs/advanced/")
    
    if len(analyzer.results) > 0:
        print(f"\n📊 Résumé des infrastructures analysées :\n")
        for infra_name, result in analyzer.results.items():
            stats = result['stats']
            print(f"  {infra_name}:")
            print(f"    • Nombre d'infrastructures : {stats['n_infrastructures']}")
            print(f"    • Localités desservies (<100m) : {stats['pct_localities_served']:.1f}%")
            print(f"    • Distance moyenne : {stats['distance_mean_m']:.0f} m")
            print(f"    • Distance médiane : {stats['distance_median_m']:.0f} m")
            print(f"    • Distance maximale : {stats['distance_max_m']:.0f} m")
            print()
    
    print("="*70)
    print("✓ SUCCÈS".center(70))
    print("="*70)
    print("\n💡 Prochaines étapes :")
    print("  • Ouvrez les fichiers .html dans votre navigateur pour les cartes interactives")
    print("  • Consultez outputs/analyses/ pour les statistiques CSV")
    print("  • Utilisez les images PNG dans vos rapports")
    print()


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\nInterruption par l'utilisateur")
    except Exception as e:
        print(f"\n⚠ Erreur critique : {e}")
        import traceback
        traceback.print_exc()
import os
import warnings
import sys
from pathlib import Path

warnings.filterwarnings('ignore')

# Ajouter le répertoire du script au path
script_dir = Path(__file__).parent
sys.path.insert(0, str(script_dir))

# Imports des modules personnalisés
try:
    import data_loader as dl
    import preprocessing as prep
    import analyses as ana
    import viz as vz
    import interactive as inter
    
    DataLoader = dl.DataLoader
    DataPreprocessor = prep.DataPreprocessor
    InfrastructureAnalyzer = ana.InfrastructureAnalyzer
    InfrastructureVisualizer = vz.InfrastructureVisualizer
    InteractiveMapper = inter.InteractiveMapper
    
except ImportError as e:
    print(f"⚠ Erreur d'importation : {e}")
    print("\n📁 Vérifiez que ces fichiers sont présents dans le dossier 'script/':")
    print("  • data_loader.py")
    print("  • preprocessing.py")
    print("  • utils.py")
    print("  • analyses.py")
    print("  • viz.py")
    print("  • interactive.py")
    print("\n💡 Structure attendue:")
    print("  TP2 cette année/")
    print("  └── script/")
    print("      ├── data_loader.py")
    print("      ├── preprocessing.py")
    print("      ├── utils.py")
    print("      ├── analyses.py")
    print("      ├── viz.py")
    print("      ├── interactive.py")
    print("      └── run_all.py")
    import traceback
    traceback.print_exc()
    sys.exit(1)

def print_header(text):
    """Affiche un en-tête formaté"""
    print("\n" + "="*70)
    print(text.center(70))
    print("="*70 + "\n")

def print_section(text):
    """Affiche un titre de section"""
    print("\n" + "-"*70)
    print(text.center(70))
    print("-"*70 + "\n")

def main():
    """
    Fonction principale pour exécuter toute l'analyse
    """
    
    print_header("ANALYSE SPATIALE DES INFRASTRUCTURES - BÉNIN")
    print("Ce script va:")
    print("  1. Charger les données OSM et administratives")
    print("  2. Prétraiter et harmoniser les données")
    print("  3. Analyser l'accessibilité aux infrastructures")
    print("  4. Générer des visualisations statiques et interactives")
    print("  5. Exporter tous les résultats")
    print()
    
    # Demander confirmation
    response = input("Continuer? (o/n): ").lower()
    if response != 'o':
        print("Annulation.")
        return
    
    # -------------------------
    # 1. CHARGEMENT DES DONNÉES
    # -------------------------
    print_header("ÉTAPE 1/5 : CHARGEMENT DES DONNÉES")
    
    loader = DataLoader(data_dir="data")
    
    try:
        # Charger limites administratives
        print("Chargement des limites administratives...")
        boundaries = loader.load_boundaries(level=1)  # Niveau département
        
        # Charger localités
        print("\nChargement des localités...")
        places = loader.load_osm_layer('places', geometry_type='free')
        
        # Charger POIs (points d'intérêt)
        print("\nChargement des points d'intérêt...")
        pois = loader.load_osm_layer('pois', geometry_type='free')
        
        # Charger autres infrastructures
        print("\nChargement des cours d'eau...")
        waterways = loader.load_osm_layer('waterways', geometry_type='free')
        
        print("\nChargement des chemins de fer...")
        railways = loader.load_osm_layer('railways', geometry_type='free')
        
        # Charger zones protégées
        print("\nChargement des zones protégées...")
        protected = loader.load_protected_areas()
        
        # Liste des couches disponibles
        loader.list_available_layers()
        
    except Exception as e:
        print(f"\n⚠ Erreur lors du chargement : {e}")
        return
    
    # -------------------------
    # 2. PRÉTRAITEMENT
    # -------------------------
    print_header("ÉTAPE 2/5 : PRÉTRAITEMENT")
    
    preprocessor = DataPreprocessor()
    
    try:
        # Harmoniser les CRS
        print("Harmonisation des systèmes de coordonnées...")
        [boundaries, places, pois, waterways, railways, protected] = \
            preprocessor.harmonize_crs(
                [boundaries, places, pois, waterways, railways, protected],
                target_crs="EPSG:4326"
            )
        
        # Nettoyer les géométries
        print_section("Nettoyage des géométries")
        places = preprocessor.clean_geometries(places)
        pois = preprocessor.clean_geometries(pois)
        
        # Extraire les infrastructures thématiques
        print_section("Extraction des infrastructures thématiques")
        
        print("Extraction des infrastructures de santé...")
        health_facilities = preprocessor.extract_health_facilities(pois)
        
        print("\nExtraction des infrastructures éducatives...")
        schools = preprocessor.extract_education(pois)
        
        print("\nExtraction des localités...")
        localities = preprocessor.extract_localities(places)
        
        # Vérifier qu'on a bien des données
        if localities is None or len(localities) == 0:
            print("⚠ Aucune localité trouvée. Utilisation de tous les points...")
            localities = places
        
    except Exception as e:
        print(f"\n⚠ Erreur lors du prétraitement : {e}")
        import traceback
        traceback.print_exc()
        return
    
    # -------------------------
    # 3. ANALYSES SPATIALES
    # -------------------------
    print_header("ÉTAPE 3/5 : ANALYSES SPATIALES")
    
    # Initialiser l'analyseur
    analyzer = InfrastructureAnalyzer(boundaries, localities)
    
    # Préparer les infrastructures à analyser
    infrastructures = {}
    
    if 'hospitals' in health_facilities:
        infrastructures['Hôpitaux'] = health_facilities['hospitals']
    if 'clinics' in health_facilities:
        infrastructures['Cliniques'] = health_facilities['clinics']
    if 'pharmacies' in health_facilities:
        infrastructures['Pharmacies'] = health_facilities['pharmacies']
    if schools is not None:
        infrastructures['Écoles'] = schools
    if waterways is not None:
        infrastructures['Cours d\'eau'] = waterways
    if railways is not None:
        infrastructures['Chemins de fer'] = railways
    
    # Analyser chaque type d'infrastructure
    for infra_name, infra_gdf in infrastructures.items():
        if infra_gdf is not None and len(infra_gdf) > 0:
            try:
                analyzer.analyze_proximity(infra_gdf, infra_name, buffer_distance=100)
            except Exception as e:
                print(f"⚠ Erreur lors de l'analyse de {infra_name} : {e}")
    
    # Identifier les zones sous-desservies
    if len(analyzer.results) > 0:
        print_section("Identification des zones sous-desservies")
        underserved = analyzer.identify_underserved_areas(threshold_distance=5000)
        
        # Exporter les résultats
        print_section("Export des analyses")
        analyzer.export_results(output_dir="outputs/analyses")
    else:
        print("⚠ Aucune analyse disponible pour l'export")
    
    # -------------------------
    # 4. VISUALISATIONS STATIQUES
    # -------------------------
    print_header("ÉTAPE 4/5 : VISUALISATIONS STATIQUES")
    
    os.makedirs("outputs/maps", exist_ok=True)
    
    if len(analyzer.results) > 0:
        visualizer = InfrastructureVisualizer(boundaries, analyzer.results)
        
        print("Génération des cartes et graphiques...\n")
        for infra_name in analyzer.results.keys():
            try:
                print(f"  • {infra_name}...")
                
                # Nettoyer le nom pour les fichiers
                clean_name = infra_name.lower().replace(' ', '_').replace('é', 'e').replace('è', 'e').replace('\'', '_')
                
                # Carte
                visualizer.plot_infrastructure_map(
                    infra_name,
                    output_file=f"outputs/maps/carte_{clean_name}.png"
                )
                
                # Histogramme
                visualizer.plot_distance_distribution(
                    infra_name,
                    output_file=f"outputs/maps/hist_{clean_name}.png"
                )
            except Exception as e:
                print(f"    ⚠ Erreur : {e}")
        
        # Graphique comparatif
        try:
            print(f"\n  • Graphique comparatif...")
            visualizer.plot_comparison_barplot(
                output_file="outputs/maps/comparaison_infrastructures.png"
            )
        except Exception as e:
            print(f"    ⚠ Erreur : {e}")
        
        # Tableau de bord
        try:
            print(f"  • Tableau de bord...")
            visualizer.plot_summary_dashboard(
                output_file="outputs/maps/dashboard_complet.png"
            )
        except Exception as e:
            print(f"    ⚠ Erreur : {e}")
    else:
        print("⚠ Aucune visualisation possible (pas de résultats)")
    
    # -------------------------
    # 5. CARTES INTERACTIVES
    # -------------------------
    print_header("ÉTAPE 5/5 : CARTES INTERACTIVES")
    
    os.makedirs("outputs/interactive", exist_ok=True)
    
    if len(analyzer.results) > 0:
        mapper = InteractiveMapper(boundaries)
        
        print("Génération des cartes interactives...\n")
        for infra_name in analyzer.results.keys():
            try:
                print(f"  • {infra_name}...")
                clean_name = infra_name.lower().replace(' ', '_').replace('é', 'e').replace('è', 'e').replace('\'', '_')
                
                mapper.create_accessibility_map(
                    analyzer.results,
                    infra_name,
                    output_file=f"outputs/interactive/carte_{clean_name}.html"
                )
            except Exception as e:
                print(f"    ⚠ Erreur : {e}")
    else:
        print("⚠ Aucune carte interactive possible (pas de résultats)")
    
    # -------------------------
    # 6. RÉSUMÉ FINAL
    # -------------------------
    print_header("ANALYSE TERMINÉE")
    
    print(f"📁 Fichiers générés :")
    print(f"  • Analyses statistiques : outputs/analyses/")
    print(f"  • Cartes et graphiques : outputs/maps/")
    print(f"  • Cartes interactives : outputs/interactive/")
    
    if len(analyzer.results) > 0:
        print(f"\n📊 Résumé des infrastructures analysées :\n")
        for infra_name, result in analyzer.results.items():
            stats = result['stats']
            print(f"  {infra_name}:")
            print(f"    • Nombre d'infrastructures : {stats['n_infrastructures']}")
            print(f"    • Localités desservies (<100m) : {stats['pct_localities_served']:.1f}%")
            print(f"    • Distance moyenne : {stats['distance_mean_m']:.0f} m")
            print(f"    • Distance médiane : {stats['distance_median_m']:.0f} m")
            print(f"    • Distance maximale : {stats['distance_max_m']:.0f} m")
            print()
    
    print("="*70)
    print("✓ SUCCÈS".center(70))
    print("="*70)
    print("\nOuvrez les fichiers .html dans votre navigateur pour les cartes interactives")
    print()


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\nInterruption par l'utilisateur")
    except Exception as e:
        print(f"\n⚠ Erreur critique : {e}")
        import traceback
        traceback.print_exc()