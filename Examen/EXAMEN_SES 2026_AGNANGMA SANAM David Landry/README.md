# Projet : Analyse spatiale des données agricoles en Afrique subsaharienne

## Description du projet
Ce projet réalise une analyse statistique et spatiale des données agricoles de l'Afrique subsaharienne en utilisant le jeu de données HarvestStat Africa. L'étude se concentre particulièrement sur cinq pays d'Afrique de l'Ouest : Bénin, Burkina Faso, Mali, Niger et Togo.

##  Objectifs
1. Analyser la qualité des données agricoles (indicateur `qc_flag`)
2. Comparer les distributions de rendement par pays, culture et système de production
3. Élaborer des stratégies de traitement des données problématiques
4. Réaliser une analyse spatiale (matrices de voisinage et indice de Moran)

## Structure du projet
projet_agriculture/
├── data/
├── outputs/ # Résultats et visualisations
├── scripts/
├── README.md
└── environnement.R (rproj)
text

## Données utilisées

### Source principale
- **HarvestStat Africa**
- **Variables principales** :
  - `fnid` : identifiant géographique unique
  - `country` : pays
  - `admin_1`, `admin_2` : unités administratives
  - `product` : type de culture
  - `yield` : rendement (t/ha)
  - `area` : superficie (ha)
  - `production` : production (t)
  - `qc_flag` : indicateur de qualité (0=OK, 1=aberrante, 2=faible variance)

### Pays étudiés
- Bénin
- Burkina Faso
- Mali
- Niger
- Togo


### 2. Statistiques descriptives

### 3. Analyse spatiale
- Construction de matrices de contiguité (queen, rook, distance)
- Calcul de l'indice de Moran

# Auteur

David Landry SANAM
