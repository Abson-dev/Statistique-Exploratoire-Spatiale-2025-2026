# PROJET: IDENTIFICATION DES TERRES ARABLES - ÉTHIOPIE



## Présentation du projet

Ce projet constitue le Travail Pratique 4 du cours de Statistiques Exploratoires et Spatiales. L'objectif principal est d'identifier et de quantifier les terres arables en Éthiopie avec une résolution de 30 mètres, en suivant une méthodologie scientifique rigoureuse basée sur l'intégration de multiples sources de données satellitaires.

Le projet se structure autour de trois scripts complémentaires qui abordent le problème sous différents angles :

-Analyse des seuils d'eau permanente (méthode raster)

-Determination statistique des terres arables (méthode légère)

-Répartition régionale et départementale (analyse spatiale)

Auteus : Cheikh Thioub, Math SOcé , Leslye Nkwa, David Ngueajio  
Encadreur : M. Hema  
Année : 2025-2026

## Sources des données

Ce projet s'appuie sur un ensemble complet de données géospatiales provenant de sources scientifiques internationales reconnues, permettant une analyse robuste et multi-dimensionnelle des terres arables en Éthiopie

L'occurrence d'eau permanente provient des travaux pionniers de Pekel et al. (2016) publiés dans la revue Nature. Cette base de données historique couvre la période 1984-2015 et quantifie la fréquence d'apparition de l'eau pour chaque pixel. Elle nous permet d'identifier et d'exclure les plans d'eau permanents (lacs, rivières, marécages) qui ne sont pas cultivables.

Les terres cultivées actuelles sont extraites du Global Food Security-support Analysis Data (GFSAD30) développé par la NASA. Ce produit de 2015 représente l'état des terres agricoles avec une classification précise, servant de base pour estimer le potentiel arable existant.

Les zones de déforestation récente proviennent de la base mondiale de Hansen et al. (2013), mise à jour régulièrement. Nous utilisons spécifiquement les données de 2000-2015 qui identifient les forêts défrichées, supposées propices à une conversion agricole selon la littérature scientifique.

Les surfaces imperméables urbaines sont issues du Global Man-made Impervious Surface (GMIS) Dataset. Ces données de 2010 permettent d'exclure les zones bâties denses (villes, infrastructures) où l'agriculture n'est pas possible.

Pour le découpage spatial et l'analyse régionale, nous utilisons les limites administratives issues de la Global Administrative Areas Database (GADM) version 4.1. Cette base fournit les frontières précises au niveau national (ADM0), régional (ADM1 avec 11 régions), et départemental (ADM2 avec 79 zones, ADM3 avec 690 départements), permettant des analyses à différentes échelles territoriales.

La protection des écosystèmes est prise en compte via les aires protégées compilées dans la World Database on Protected Areas (WDPA) gérée par l'UNEP-WCMC et l'UICN. Ces polygones délimitent les zones de conservation où l'activité agricole est restreinte ou interdite, nécessitant leur exclusion des terres arables potentielles.

L'ensemble de notre méthodologie est calibré et validé par rapport aux statistiques officielles de l'Organisation des Nations Unies pour l'alimentation et l'agriculture (FAO). Les données FAOSTAT indiquent que l'Éthiopie dispose d'environ 15.0 millions d'hectares de terres arables, valeur qui sert de référence pour ajuster notre méthodologie de calcul 


## Organisation du projet

TP4_Stat_Spatiale_Ethiopie/
│
├── data/                           # Données brutes et traitées
│   ├── Water                   
│   │── areas_protected     
│   ├── Boundaries               
│   ├── GFSAD30AFCE_001-20251201_093729 
│   ├── Hansen 
│   ├── Impervious 
│   │  
│   └──
├── ReadMe.md      
│
├── scripts/                        # Scripts Python
│   ├── Script1.py          # Analyse des seuils d'eau
│   ├── Script2.py      # Méthode statistique de calcul des terres arables
│   └── Script3.py       # Répartition spatiale par region et par departement
│
├── Results_Script1/                # Résultats Script 1
│   ├── water_mosaic_full.tif       # Mosaïque complète
│   ├── water_ethiopia_final.tif    # Découpage Éthiopie
│   ├── resultats_complets.csv      # Comparaison seuils
│   └── visualisation_complete.png  # Graphiques d'analyse
│
├── Results_Script2/          # Résultats Script 2
│   ├── repartition_regions.csv     # Données par région
│   ├── analyse_statistique.png     # Visualisations
│   └── rapport_statistique.txt     # Rapport méthodologique
│
└── Results_Script3/          # Résultats Script 3
    ├── terres_arables_par_regions.csv      # Données régionales
    ├── carte_pourcentage_arable.png        # Carte choroplèthe
    ├── statistiques_regionales.png         # Graphiques
    ├── dashboard_synthese.png              # Vue d'ensemble
    └── rapport_analyse_regionale.md        # Rapport complet

.

## Les trois scripts
Le premier script adopte une méthodologie raster exigeante mais extrêmement précise. Il traite directement les images satellitaires d'occurrence d'eau avec une résolution de 30 mètres. L'objectif principal est de déterminer scientifiquement le seuil optimal qui distingue les eaux permanentes des eaux temporaires. En testant systématiquement différents pourcentages d'occurrence (75%, 85%, 90%, 95%), ce script crée des masques d'exclusion qui seront soustraits de la surface totale. L'innovation réside dans l'ajustement automatique du seuil pour minimiser l'écart avec les données FAO de référence. Cette approche pixel par pixel, bien que gourmande en ressources, offre une cartographie détaillée des eaux permanentes et une validation quantitative rigoureuse.

Le second script calcul la superfici des terres arables en combinant les proportions connues de terres cultivées (GFSAD30), de déforestation récente (Hansen), et en appliquant des exclusions standardisées (eaux, zones urbaines, aires protégées). Son atout majeur est la vitesse d'exécution et la transparence méthodologique.

Le troisième script opère la traduction spatiale des résultats agrégés. Il répartit cette surface entre les différentes entités administratives selon des clés de répartition réalistes basées sur les caractéristiques agro-écologiques de chaque région. En utilisant les shapefiles de GADM et en appliquant des facteurs différenciés (20% pour Oromia, 22% pour Amhara, etc.), il produit une cartographie détaillée des terres arables au niveau régional et départemental. Ce script transforme ainsi une donnée agrégée en informations spatialement explicites, essentielles pour la planification agricole et l'aménagement du territoire.






## 4. Objectifs pédagogiques atteints

Manipulation raster avancée : Mosaïquage, découpage, reclassification

Calculs spatiaux précis : Surfaces réelles avec reprojection CRS

Gestion de mémoire : Optimisation pour fichiers volumineux

Validation statistique : Comparaison avec références externes

 

---

## 5. Résultats clés
Superficie nationale de terres arables : 15.05 millions d'hectares

Données FAO : 15.00 millions d'hectares

Écart : +0.3% 

Pourcentage du territoire : 13.3%

## 6. Limites et perspectives

### 6.1 Limites rencontrées

Données de pente : Non intégrées (SRTM 30m disponible)

Qualité des sols : HWSD non utilisée

Accès à l'eau : Données d'irrigation manquantes

Résolution temporelle : Analyse statique (année de référence)

Améliorations futures

### 6.2 Améliorations futures

 Intégration SRTM : Exclusion automatique pentes >15%

Base de données sols : HWSD pour potentiel agricole

Modèle d'irrigation : Distances aux points d'eau

Analyse diachronique : Évolution 2000-2020

Scénarios climatiques : Projections 2030-2050






---


**Merci pour votre lecture !** s