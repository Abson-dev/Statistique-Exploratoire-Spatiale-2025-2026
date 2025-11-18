# 🌍 Analyse Spatiale du Kenya - Données de Paludisme et Population

## 📋 Description du Projet
Ce projet réalise une analyse spatiale approfondie du Kenya, combinant des données administratives, démographiques et épidémiologiques du paludisme. L'étude produit des visualisations cartographiques statiques et interactives pour comprendre la distribution spatiale de la maladie et sa relation avec la densité de population.

## 👨‍💻 Auteur
**AGNANGMA SANAM David Landry**  
*Data Scientist & Géomaticien*

## 🗂️ Architecture du Projet
L'utilisateur devra télécharger les shapefiles ("gadm41_KEN_shp.zip") depuis le site GADM via le lien "https://gadm.org/data.html", puis les données sur la malaria le taux d'incidence ("National_Unit-data.csv") au format csv sur le site "https://data.malariaatlas.org/maps?layers=Malaria:202508_Global_Pf_Parasite_Rate". Ensuite, il devra mettre ces deux fichiers dans le dossier data et puis compiler le script pour avoir toutes les sorties

```
Projet_Kenya_Malaria/
│
├── 📁 data/ # Dossier des données sources
│ ├── gadm41_KEN_shp.zip # Fichiers shapefile GADM du Kenya
│ ├── National_Unit-data.csv # Données paludisme par unité administrative
│ └── gadm41_KEN_shp/ # Dossier dézippé des shapefiles
│ ├── gadm41_KEN_0.shp # Niveau national
│ ├── gadm41_KEN_1.shp # Niveau comtés (47 comtés)
│ ├── gadm41_KEN_2.shp # Niveau districts
│ └── gadm41_KEN_3.shp # Niveau sous-districts
│
├── 📁 outputs/ # Dossier des résultats générés
│ ├── Cartes statiques (PNG)
│ │ ├── kenya_national_map.png # Carte administrative nationale
│ │ ├── malaria_counties_map.png # Carte incidence paludisme par comté
│ │ └── combined_population_malaria_map.png # Carte combinée population-paludisme
│ │
│ ├── Cartes interactives (HTML)
│ │ └── kenya_malaria_interactive.html # Carte Leaflet interactive
│ │
│ ├── Analyses statistiques (CSV)
│ │ ├── malaria_statistics_summary.csv # Statistiques descriptives
│ │ └── top10_counties_malaria.csv # Top 10 comtés les plus touchés
│ │
│ └── Métadonnées
│ └── analysis_metadata.rds # Métadonnées de l'analyse
│
├── 📁 Scripts/ # Dossier des scripts R
│ └── kenya_malaria_analysis.R # Script principal d'analyse
│
└── README.md # Documentation du projet

```

## Installation et Exécution

### Prérequis
- **R** (version 4.0 ou supérieure)
- **RStudio** (recommandé)

### Packages R Requis
Le script installe automatiquement les packages nécessaires :
```r
sf, stars, ggplot2, ggspatial, raster, leaflet, viridis, 
dplyr, readr, htmltools, rmarkdown, kableExtra, geodata, terra, utils
Instructions d'Exécution
Préparation des données :

Placez les fichiers suivants dans le dossier data :

gadm41_KEN_shp.zip (shapefiles GADM)

National_Unit-data.csv (données paludisme)

Lancement de l'analyse :

Exécutez le script kenya_malaria_analysis.R

À l'invite, sélectionnez le dossier data contenant vos fichiers

Résultats :

Les outputs sont générés dans le dossier outputs au même niveau que data

 Fonctionnalités de l'Analyse
1. Traitement des Données Géospatiales
Import et traitement des shapefiles GADM (4 niveaux administratifs)

Téléchargement automatique des données de population WorldPop

Jointure des données paludisme avec les limites administratives

2. Visualisations Cartographiques
 Cartes Statiques (ggplot2)
Carte Administrative : Limites nationales et des 47 comtés

Carte d'Incidence Paludisme : Distribution spatiale par comté

Carte Combinée : Superposition population et incidence paludisme

 Cartes Interactives (Leaflet)
Navigation et zoom interactifs

Informations au clic sur chaque comté

Couches multiples (OpenStreetMap, CartoDB)

Légende dynamique et échelle

3. Analyses Statistiques
Statistiques descriptives de l'incidence du paludisme

Identification des 10 comtés les plus touchés

Export des résultats en format CSV

4. Gestion des Données Manquantes
Création automatique de données simulées si fichiers manquants

Téléchargement de données WorldPop alternatives

 Résultats Clés
Métriques Calculées
Taux d'incidence du paludisme pour 1000 habitants

Nombre total de cas par comté

Densité de population à haute résolution

Distribution spatiale des points chauds épidémiologiques

Visualisations Produites
Cartes thématiques professionnelles

Analyses de corrélation population-paludisme

Représentations multi-échelles (national, comtés)

 Configuration Technique
Système de Coordonnées
Projection : WGS 84 (EPSG:4326)

Système de référence : Géographique

Formats de Fichiers Supportés
Entrée : Shapefile (.shp), CSV, GeoTIFF

Sortie : PNG, HTML, CSV, RDS

Performance
Traitement optimisé des raster de population

Gestion mémoire efficace pour les grandes datasets

Export rapide des visualisations haute résolution

 Applications et Utilisations
Pour les Décideurs de Santé Publique
Identification des zones prioritaires d'intervention

Allocation optimale des ressources sanitaires

Surveillance épidémiologique spatiale

Pour les Chercheurs
Analyse des déterminants spatiaux du paludisme

Modélisation des risques épidémiologiques

Études de corrélation environnement-santé

Pour la Formation
Exemple complet d'analyse spatiale en R

Code modulaire et réutilisable

Bonnes pratiques en géomatique santé

 Notes Méthodologiques
Sources de Données
GADM : Données administratives du Kenya

WorldPop : Données de population à haute résolution

Données Nationales : Surveillance paludisme (ou simulées)

Limitations
Résolution spatiale dépendante des données sources

Données paludisme potentiellement simulées

Couverture temporelle limitée à l'année 2023

Améliorations Futures
Intégration de données environnementales

Analyses temporelles et tendances

Modélisation prédictive spatiale

 Contribution
Les contributions sont les bienvenues ! Pour contribuer :

Forkez le projet

Créez une branche feature (git checkout -b feature/AmazingFeature)

Commitez vos changements (git commit -m 'Add some AmazingFeature')

Pushez la branche (git push origin feature/AmazingFeature)

Ouvrez une Pull Request