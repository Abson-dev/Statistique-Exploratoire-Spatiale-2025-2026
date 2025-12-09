# **Analyse du Ratio LCRPGR au Cameroun (2015–2025)**

## **1. Contexte général**

Dans un contexte de croissance urbaine soutenue , il devient indispensable de suivre l’évolution des villes camerounaises de manière rigoureuse et reproductible afin d’éclairer les politiques publiques et de soutenir un développement urbain plus équilibré.

---

## **Équipe du projet**

* **Leslye Nkwa**
* **Mouhamet Seck**
* **David Ngueajio**
* **Mamadou Lamine Diabang**

  
  Classe : **ISE1 CL**
  Année académique : **2025–2026**

**Professeur :
Mr. Hema Aboubacar, Analyste de recherche à IFPRI, data scientist**

---

## **2. Problématique**

Comment mesurer et visualiser efficacement la relation entre la croissance démographique et l’expansion spatiale des zones bâties au Cameroun entre 2015 et 2025 ?

Plus précisément , meme on peu se demander:

* **Les villes consomment-elles plus de terres qu’elles ne gagnent d’habitants ?**
* **Peut-on identifier les régions présentant un étalement urbain excessif ?**
* **Quelles zones montrent au contraire une densification maîtrisée ?**
* **Comment ces dynamiques varient-elles d’une région à l’autre ?**

L’analyse repose sur l’indicateur **LCRPGR (Land Consumption Rate to Population Growth Rate)**, utilisé pour quantifier l’équilibre ou le déséquilibre entre expansion urbaine et croissance démographique.

---

## **3. Cadre du travail donné**

Ce projet s’inscrit dans le cadre des **Objectifs de Développement Durable (ODD)**, et particulièrement dans la mesure officielle :

### **ODD 11.3.1 — Ratio du taux de consommation des terres au taux de croissance démographique**

*Source : UN-Habitat*

Cet indicateur vise à évaluer la capacité d’un pays à promouvoir une **urbanisation équilibrée**, évitant une expansion excessive des surfaces bâties au détriment des terres naturelles ou agricoles. Le LCRPGR constitue aujourd’hui la référence internationale pour analyser l’efficacité de l’occupation spatiale en milieu urbain.

Dans le contexte camerounais, il revêt un intérêt particulier pour :

* documenter les transformations urbaines récentes ;
* accompagner les stratégies nationales d’aménagement du territoire ;
* appuyer les collectivités locales dans la maîtrise de l’étalement urbain ;
* renforcer les outils d’aide à la décision dans la planification durable.

---

## **4. Objectifs du projet**

Ce travail vise à :

1. **Mesurer le LCRPGR du Cameroun** sur la période 2015–2025.
2. **Analyser les variations régionales** du ratio afin d’identifier :

   * les régions à forte consommation de terres (LCR >> PGR) ;
   * les régions où la croissance démographique reste dominante (LCR << PGR).
3. **Produire des cartes, tableaux et couches rasters** exploitables dans GEE .
4. **Proposer une lecture territoriale et politique** des résultats pour soutenir les démarches de planification urbaine durable.

---

## **5. Données et sources**

Le projet utilise exclusivement des données ouvertes et harmonisées :

### **5.1 Land Cover (Esri 10m)**

— Extraction des surfaces bâties en 2015 et 2020
— Indispensable pour mesurer le *Land Consumption Rate (LCR)*
Disponible dans `data/land_cover/`

### **5.2 Population WorldPop (100 m)**

— Données 2015 et 2020
— Utilisées pour calculer le *Population Growth Rate (PGR)*
 Disponible dans `data/worldpop/`

### **5.3 Limites administratives GADM**

— Découpage aux niveaux 0 à 3
— Permet l’analyse par région
 Disponible dans `data/gadm/`

### **5.4 Documentation et guides**

— Documents méthodologiques UN-Habitat / ESCAP
 Dans `data/docu/` 

---

## **6. Structure du projet**

La structure complète du projet est la suivante :

```
TP5_Cameroun_LCRPGR/
│
├── data/                                           # Toutes les données sources utilisées dans GEE
│   │
│   ├── land_cover/                                   # Tuiles Esri Land Cover 10m 
│   │   ├── 32N_20170101-20180101.tif
│   │   ├── 33N_20170101-20180101.tif
│   │   ├── 33P_20170101-20180101.tif
│   │   ├── 32N_20220101-20230101.tif
│   │   ├── 33N_20220101-20230101.tif
│   │   └── 33P_20220101-20230101.tif
│   │
│   ├── worldpop/                                   # Population 100m
│   │   ├── cmr_pop_2015_CN_100m_R2025A_v1.tif
│   │   └── cmr_pop_2020_CN_100m_R2025A_v1.tif
│   │
│   ├── gadm/                                       # Frontières administratives du Cameroun
│   │   ├── gadm41_CMR_0.shp
│   │   ├── gadm41_CMR_1.shp
│   │   ├── gadm41_CMR_2.shp
│   │   └── gadm41_CMR_3.shp
│   │
│   └── docu/                                       # Documents fournis par le professeur
│       ├── KGZ_911_QGISstepbystepFinal_ENG_ESCAP.pdf
│       ├── KGZ_1131_QGISstepbystepFinal_ENG_ESCAP.pdf
│       ├── KGZ_Degurba_QGISstepbystep_ESCAP.pdf
│       └── sdgi-2023-release-documentation.pdf
│
│
├── outputs/                                        # Sorties générées par GEE (export)
│   ├── CMR_LCRPGR_regions_2015_2020.csv
│   │
│   ├── CMR_LCRPGR_500m_2015_2020.tif
│   │
│
├── script.js                                       # Scripts Google Earth Engine    
│
└── README.md                                       # Description du projet, méthodologie et exécution


```



---

## **7. Méthodologie**

1. **Extraction des surfaces bâties** (2015 & 2020) : Nous faisons ensuite un calcul de surfaces bâties.

2. **Extraction des populations WorldPop**

3. **Calcul du LCR et du PGR**: A partir des formules

   * LCR = variation des surfaces bâties
   * PGR = variation de la population
   * LCRPGR = LCR / PGR

4. **Analyse**

   * Cameroun (national)
   * Régions (N1 GADM)

5. **Visualisation**

   * Cartes raster du LCRPGR
   * Tableaux CSV régionaux
   * Graphiques dans GEE


---


## **8. Exécution**

1. Ouvrir `script.js` dans **Google Earth Engine**.
2. Modifier le chemin d’export si nécessaire.
3. Lancer les blocs de code.
4. Récupérer les fichiers générés dans `outputs/`.

---

## **9. Licence**

Projet académique — usage strictement pédagogique.
Sources de données : Esri LandCover, WorldPop, GADM, UN-Habitat.


