# ==============================================================================
# check_environment.py
# Script de diagnostic pour vérifier l'environnement et les dépendances
# ==============================================================================

import sys
import os
from pathlib import Path

print("\n" + "="*70)
print("DIAGNOSTIC DE L'ENVIRONNEMENT".center(70))
print("="*70 + "\n")

# 1. Vérifier la version de Python
print("1. VERSION DE PYTHON")
print("-" * 70)
print(f"   Version: {sys.version}")
print(f"   Exécutable: {sys.executable}")
print()

# 2. Vérifier le répertoire de travail
print("2. RÉPERTOIRE DE TRAVAIL")
print("-" * 70)
print(f"   Current directory: {os.getcwd()}")
print(f"   Script directory: {Path(__file__).parent}")
print()

# 3. Vérifier les modules requis
print("3. MODULES PYTHON REQUIS")
print("-" * 70)

required_modules = [
    'geopandas',
    'rasterio',
    'numpy',
    'pandas',
    'matplotlib',
    'seaborn',
    'folium',
    'shapely'
]

missing_modules = []
for module in required_modules:
    try:
        __import__(module)
        print(f"   ✓ {module}")
    except ImportError:
        print(f"   ✗ {module} - MANQUANT")
        missing_modules.append(module)

if missing_modules:
    print(f"\n⚠ Modules manquants: {', '.join(missing_modules)}")
    print(f"\nPour installer:")
    print(f"   pip install {' '.join(missing_modules)}")
else:
    print(f"\n✓ Tous les modules sont installés")

print()

# 4. Vérifier les fichiers du projet
print("4. FICHIERS DU PROJET")
print("-" * 70)

script_dir = Path(__file__).parent
required_files = [
    'data_loader.py',
    'preprocessing.py',
    'utils.py',
    'analyses.py',
    'viz.py',
    'interactive.py',
    'run_all.py'
]

missing_files = []
for file in required_files:
    file_path = script_dir / file
    if file_path.exists():
        print(f"   ✓ {file}")
    else:
        print(f"   ✗ {file} - MANQUANT")
        missing_files.append(file)

if missing_files:
    print(f"\n⚠ Fichiers manquants: {', '.join(missing_files)}")
else:
    print(f"\n✓ Tous les fichiers sont présents")

print()

# 5. Vérifier la structure des dossiers data
print("5. STRUCTURE DES DONNÉES")
print("-" * 70)

# Remonter au dossier parent pour trouver 'data'
project_dir = script_dir.parent
data_dir = project_dir / "data"

if data_dir.exists():
    print(f"   ✓ Dossier data trouvé: {data_dir}")
    
    # Vérifier les sous-dossiers
    shp_dir = data_dir / "shapefiles"
    tif_dir = data_dir / "tif_geojson"
    
    if shp_dir.exists():
        shp_files = list(shp_dir.glob("*.shp"))
        print(f"   ✓ shapefiles/ trouvé: {len(shp_files)} fichiers .shp")
    else:
        print(f"   ✗ shapefiles/ manquant")
    
    if tif_dir.exists():
        geojson_files = list(tif_dir.glob("*.geojson"))
        tif_files = list(tif_dir.glob("*.tif"))
        print(f"   ✓ tif_geojson/ trouvé: {len(geojson_files)} .geojson, {len(tif_files)} .tif")
    else:
        print(f"   ✗ tif_geojson/ manquant")
else:
    print(f"   ✗ Dossier data NON TROUVÉ")
    print(f"   Recherché dans: {data_dir}")

print()

# 6. Tester l'importation des modules
print("6. TEST D'IMPORTATION DES MODULES")
print("-" * 70)

sys.path.insert(0, str(script_dir))

modules_to_test = [
    ('data_loader', 'DataLoader'),
    ('preprocessing', 'DataPreprocessor'),
    ('utils', 'create_buffer'),
    ('analyses', 'InfrastructureAnalyzer'),
    ('viz', 'InfrastructureVisualizer'),
    ('interactive', 'InteractiveMapper')
]

import_errors = []
for module_name, class_name in modules_to_test:
    try:
        module = __import__(module_name)
        if hasattr(module, class_name):
            print(f"   ✓ {module_name}.{class_name}")
        else:
            print(f"   ⚠ {module_name} importé mais {class_name} introuvable")
            import_errors.append(f"{module_name}.{class_name}")
    except Exception as e:
        print(f"   ✗ {module_name} - ERREUR: {e}")
        import_errors.append(module_name)

if import_errors:
    print(f"\n⚠ Problèmes d'importation détectés")
else:
    print(f"\n✓ Tous les modules s'importent correctement")

print()

# 7. Résumé
print("="*70)
print("RÉSUMÉ".center(70))
print("="*70)

issues = []
if missing_modules:
    issues.append(f"Modules Python manquants: {len(missing_modules)}")
if missing_files:
    issues.append(f"Fichiers projet manquants: {len(missing_files)}")
if not data_dir.exists():
    issues.append("Dossier data introuvable")
if import_errors:
    issues.append(f"Erreurs d'importation: {len(import_errors)}")

if issues:
    print("\n⚠ PROBLÈMES DÉTECTÉS:")
    for issue in issues:
        print(f"  • {issue}")
    print("\n💡 ACTIONS À FAIRE:")
    if missing_modules:
        print(f"  1. Installer les modules: pip install {' '.join(missing_modules)}")
    if missing_files:
        print(f"  2. Créer les fichiers manquants dans script/")
    if not data_dir.exists():
        print(f"  3. Créer la structure data/shapefiles/ et data/tif_geojson/")
    if import_errors:
        print(f"  4. Vérifier le contenu des modules avec erreurs")
else:
    print("\n✓ ENVIRONNEMENT PRÊT!")
    print("  Vous pouvez exécuter: python script/run_all.py")

print("\n" + "="*70 + "\n")