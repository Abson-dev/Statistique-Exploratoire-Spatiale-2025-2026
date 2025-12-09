# TP5 de Statistique exploratoire spatiale : Analyse du ratio LCRPGR en Tanzanie entre 2017 et 2022

---

## Membres de l'équipe : 

- **Cheikh THIOUB**
- **Marème DIOP**
- **Gerald ADDJITA**
- **David Landry AGNANGMA SANAM**
- **Herman Parfait NGAKE YAMAHA**

**Superviseur :** **M. HEMA**

**Année académique : 2025 - 2026**

---

## 1. Description du Projet

Ce projet vise à analyser l'indicateur ODD 11.3.1, également connu sous le nom de **Ratio de la Consommation des Terres par rapport au Taux de Croissance Démographique (LCRPGR)**.

**Objectif principal** : Évaluer l'efficacité de la gestion de l'étalement urbain en Tanzanie en comparant la vitesse à laquelle les surfaces bâties augmentent par rapport à la croissance démographique sur la période 2017-2022.

---

## 2. Sources de données

| Source de Données | Rôle (Couche) | Période | Description |
|:---|:---|:---|:---|
| **GADM** | Limites Administratives | 2017/2022 | Fournit les géométries des régions tanzaniennes (ADMIN1) pour la cartographie. |
| **ESRI Global Land Cover** | Surfaces Bâties (V) | 2017 & 2022 | Utilisé pour calculer la **Surface Bâtie** au début et à la fin de la période d'étude, essentielle pour le LCR. |
| **WorldPop** | Population (Pop) | 2017 & 2022 | Utilisé pour obtenir les données de **Population** au début et à la fin de la période d'étude, essentielle pour le PGR. |

**Lien vers les données brutes :** `https://drive.google.com/drive/folders/1KOZ4_Fz8F1fb8YbP-6AMJk3pwlhJpWDz?usp=sharing`

**Datation des données :**

Les données utilisées concernent la période allant de **2017 à 2022**, permettant un calcul précis des taux de croissance sur cette période de cinq ans.

---

## 3. Structure du Projet
  

```
TP4_SES_2025_2026_Groupe_1/
│
│
├── script/
│    │
│    └── TP5_SES_Groupe_1.ipynb                           # Notebook Colab contenant le code source Python
│
│
├── outputs/
│    │
│    ├── Carte_LCRPGR_Tanzanie_Complete.html              # Carte interactive Folium finale
│    │
│    └── resultats_lcr_pgr_tanzanie_2017_2022.csv         # Résultats statistiques agrégés
│
│
│─── README.md
```


---
#  Méthodologie d'analyse 


L'analyse suit un processus de traitement géospatial en quatre étapes clés, entièrement automatisé dans Google Colab avec Python.

## **Collecte et préparation des données**

Trois sources de données principales sont intégrées :
- **ESRI Global Land Cover** : Données d'occupation du sol à 10m de résolution pour identifier les zones bâties (classe 7)
- **WorldPop** : Rasters de population à 100m pour les années 2017 et 2022
- **GADM** : Limites administratives des 31 régions de Tanzanie

Chaque source subit un prétraitement spécifique : mosaïquage des tuiles pour l'occupation du sol, correction des facteurs d'échelle pour la population, et harmonisation des systèmes de coordonnées (reprojection en UTM Zone 35S).

## **Calcul des indicateurs clés**

Pour chaque région, nous calculons :

1. **LCR (Land Consumption Rate)** : Taux annuel de croissance des surfaces bâties  
   $LCR = \frac{(V_{2022} - V_{2017}) / V_{2017}}{5}$

2. **PGR (Population Growth Rate)** : Taux annuel de croissance démographique  
   $PGR = \frac{\ln(Pop_{2022} / Pop_{2017})}{5}$

3. **LCRPGR (Indicateur ODD 11.3.1)** : Ratio LCR/PGR

Les calculs sont effectués à deux échelles : régionale (pour les 31 régions) et nationale (agrégation des valeurs régionales).

## **Cadre d'interprétation**

Le ratio LCRPGR est interprété selon trois catégories :
- **LCRPGR > 1** : Étalement urbain - les terres sont consommées plus rapidement que la croissance démographique
- **LCRPGR < 1** : Densification - la population croît plus vite que l'expansion spatiale
- **LCRPGR = 1** : Équilibre relatif entre croissance spatiale et démographique

Des indicateurs secondaires complètent l'analyse : densité urbaine (hab/km²), superficie bâtie par habitant (m²/personne), et variation absolue des surfaces bâties.





## Aspects techniques

### **Optimisations implémentées**

- **Réductions spatiales adaptatives** : Échelles de calcul optimisées (50m pour les surfaces bâties)
- **Gestion des erreurs** : Contrôle robuste des valeurs nulles et des divisions par zéro
- **Agrégation parallèle** : Traitement région par région pour minimiser la charge mémoire

### **Validation des résultats**

Plusieurs contrôles de qualité sont intégrés :

1. Vérification de la plausibilité démographique (comparaison avec les estimations officielles)
2. Analyse de cohérence spatiale (valeurs aberrantes détectées visuellement)


## 📈 Applications et Perspectives

### **Utilisation des résultats**

Les résultats fournissent une base quantitative pour :
- Évaluer l'efficacité des politiques de gestion du territoire
- Identifier les régions prioritaires pour des interventions de densification
- Suivre les progrès vers l'ODD 11 (Villes et communautés durables)
- Éclairer les décisions d'aménagement urbain et régional

##️ Structure des Livrables

### **Données statistiques**
- **Fichier CSV** : Tableau complet avec 31 lignes (régions) + 1 ligne (national) et 15 colonnes d'indicateurs

### **Visualisations**
1. **Carte interactive HTML** :
   - Choroplèthe coloré selon le ratio LCRPGR
   - Barre de recherche de région pour l'obtention des ratios de façon plus fuide
   - Panneau d'informations nationales permanentes
   - Fonctionnalités d'interaction (survol, clic, recherche)
   - Visualisable dans tout navigateur

2. **Graphiques analytiques** :
   - Comparaison visuelle LCR vs PGR
   - Classements des régions par différents indicateurs
---

  
  ## 5. Lien du projet 

  Le script complet, les représentations graphiques et la carte interactive sont disponibles sur Google Colab.
  
  Lien : **`https://colab.research.google.com/drive/1VlwVUcH4loiOKWz_LHBvaocQQ5G1bQ5Y?usp=sharing`**
  
