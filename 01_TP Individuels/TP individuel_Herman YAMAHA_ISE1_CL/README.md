# TP individuelle sur les matrices de voisinage et l'indice de Moran global

## Réalisation de :

 NGAKE YAMAHA Herman Parfait
 
 Etudiant en ISE1-CL à l'ENSAE de Dakar
 
 
## Sous la supervision de :

M. Aboubacar HEMA
 
Research Analyst & Data Scientist


---

## 1. Description générale

Ce TP porte sur l'analyse de données spatiales en utilisant le langage R. 
La structure générale s'articule autour de la manipulation de jeux de données géographiques,
la modélisation des relations de voisinage et l'étude de l'autocorrélation spatiale.


Le rendu est subdivisé en trois sections principales :


###  1.1 Manipulation des jeux de données (Exercice 4.1)

Cette première partie se concentre sur l'importation et la structuration des données.

**Objectif** : Apprendre à transformer des données brutes en objets spatiaux (en format SpatialPointsDataFrame).

**Concepts clés** : Définition de la contiguïté de type "bishop" et des matrices de voisinages. 

**Application** : Travail sur les revenus annuelles moyens des ménages de Columbus en 1980 pour créer une carte thématiques par classes de valeurs (discrétisation).



###  1.2 Construction des structures de voisinage et poids (Exercice 4.2)

Ici, on s'intéresse à la manière dont les entités géographiques interagissent entre elles à travers des matrices de voisinage.

**Objectifs** : Construire et comparer différentes méthodes pour définir le concept de voisinage en statistique exploratoire spatiale.

**Méthodes abordées** : La contiguïté physique (partage d'une bordure) les $k$ plus proches voisins (basé sur la proximité numérique) et le seuil de distance (toutes les entités dans un rayon de $X$ km sont voisines).

**Applications** : Analyse des résumés statistiques de ces structures pour comprendre la densité du réseau spatial.



###  1.3 Analyse de l'autocorrélation spatiale : L'indice de Moran (Exercice 4.3)

La dernière partie est plus théorique. Elle traite de l'indice de Moran, qui sert 
à mesurer si des phénomènes similaires ont tendance à être proches géographiquement (autocorrélation positive) ou dispersés (autocorrélation négative).

**Objectifs** : Comprendre les propriétés mathématiques des vecteurs spatialement décalés ($WX$).

**Démonstration** : Montrer l'égalité entre la pente de la droite de régression de $WX$ par rapport à
$X$ et l'indice de Moran global lorsque la matrice de poids est normalisée.

---

## 2. Packages R utilisés

"spData", "spDataLarge", "sp", "sf", "spdep", "classInt" et "here".



---

## 3. Structure du TP

```
TP individuel_Herman YAMAHA_ISE1_CL/
│
│
└── outputs/
│    ├── Revenu annuel moyen des ménages par quartier à Columbus.png
│    ├── Voisinage KNN.png
│    ├── Voisinage par contiguïté.png
│    ├── Voisinage par distance seuil.png
│    └── voisinage_bishop.png
│
│
├── script/
│    └── script.R        # Le script des exercices 4.1 et 4.2
│  
│
├── Exercice 4.3.pdf     # Le fichier pdf de l'exercice 4.3
│
│
├── Exercice 4.3.tex     # Le fichier latex de l'exercice 4.3
│
│
└── README.md

```

**Remarque :**
L’exercice proposé dans le cours correspond en réalité à la question de l’exercice 4.3.
C’est pourquoi nous ne l’avons pas traité séparément car en travaillant sur l’exercice 4.3, nous répondons déjà à cet exercice.

---
