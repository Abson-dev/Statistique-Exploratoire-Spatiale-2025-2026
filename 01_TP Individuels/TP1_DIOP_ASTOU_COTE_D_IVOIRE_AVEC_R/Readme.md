**Analyse Spatiale de la Population en Côte d’Ivoire (2015-2024)**



* ***Description du Projet***



Ce projet analyse la répartition spatiale et l’évolution de la population en Côte d’Ivoire sur la période 2015-2024. L’analyse utilise des données géospatiales, à la fois vectorielles (shapefiles des limites administratives) et raster (population), pour visualiser les distributions, explorer les propriétés des données et réaliser des applications pratiques telles que le calcul de la densité ou l’évolution de la population par district.



**Auteur**



Astou Diop



Classe : ENSAE, 2ème année



Année académique : 2024-2025



* ***Structure du Projet***



Projet\_Population\_CIV/

│

├── DATA/

│   ├── limites\_niveau0/

│   │   ├── gadm41\_CIV\_0.shp

│   │   ├── gadm41\_CIV\_0.dbf

│   │   ├── gadm41\_CIV\_0.shx

│   │   ├── gadm41\_CIV\_0.prj

│   │   └── gadm41\_CIV\_0.cpg

│   │

│   ├── limites\_niveau1/

│   │   ├── gadm41\_CIV\_1.shp

│   │   ├── gadm41\_CIV\_1.dbf

│   │   ├── gadm41\_CIV\_1.shx

│   │   ├── gadm41\_CIV\_1.prj

│   │   └── gadm41\_CIV\_1.cpg

│   │

│   ├── limites\_niveau2/

│   │   ├── gadm41\_CIV\_2.shp

│   │   ├── gadm41\_CIV\_2.dbf

│   │   ├── gadm41\_CIV\_2.shx

│   │   ├── gadm41\_CIV\_2.prj

│   │   └── gadm41\_CIV\_2.cpg

│   │

│   ├── limites\_niveau3/

│   │   ├── gadm41\_CIV\_3.shp

│   │   ├── gadm41\_CIV\_3.dbf

│   │   ├── gadm41\_CIV\_3.shx

│   │   ├── gadm41\_CIV\_3.prj

│   │   └── gadm41\_CIV\_3.cpg

│   │

│   ├── limites\_niveau4/

│   │   ├── gadm41\_CIV\_4.shp

│   │   ├── gadm41\_CIV\_4.dbf

│   │   ├── gadm41\_CIV\_4.shx

│   │   ├── gadm41\_CIV\_4.prj

│   │   └── gadm41\_CIV\_4.cpg

│   │

│   └── rasters\_population\_2015\_2024/

│       ├── civ\_pop\_2015\_CN\_1km\_R2025A\_UA\_v1.tiff

│       ├── civ\_pop\_2016\_CN\_1km\_R2025A\_UA\_v1.tiff

│       ├── civ\_pop\_2017\_CN\_1km\_R2025A\_UA\_v1.tiff

│       ├── civ\_pop\_2018\_CN\_1km\_R2025A\_UA\_v1.tiff

│       ├── civ\_pop\_2019\_CN\_1km\_R2025A\_UA\_v1.tiff

│       ├── civ\_pop\_2020\_CN\_1km\_R2025A\_UA\_v1.tiff

│       ├── civ\_pop\_2021\_CN\_1km\_R2025A\_UA\_v1.tiff

│       ├── civ\_pop\_2022\_CN\_1km\_R2025A\_UA\_v1.tiff

│       ├── civ\_pop\_2023\_CN\_1km\_R2025A\_UA\_v1.tiff

│       └── civ\_pop\_2024\_CN\_1km\_R2025A\_UA\_v1.tiff

│

├── outputs/

│   ├── proprietes/

│   │   ├── proprietes\_shapefiles.csv

│   │   └── proprietes\_rasters\_population.csv

│   │

│   ├── cartes/

│   │   ├── shapefiles/

│   │   │   ├── carte\_niveau\_0.png

│   │   │   ├── carte\_niveau\_1.png

│   │   │   ├── carte\_niveau\_2.png

│   │   │   ├── carte\_niveau\_3.png

│   │   │   └── carte\_niveau\_4.png

│   │   │

│   │   └── rasters/

│   │       ├── carte\_population\_2015.png

│   │       ├── carte\_population\_2016.png

│   │       ├── carte\_population\_2017.png

│   │       ├── carte\_population\_2018.png

│   │       ├── carte\_population\_2019.png

│   │       ├── carte\_population\_2020.png

│   │       ├── carte\_population\_2021.png

│   │       ├── carte\_population\_2022.png

│   │       ├── carte\_population\_2023.png

│   │       └── carte\_population\_2024.png

│   │

│   └── graphiques/

│       ├── barplot\_superficie\_districts.png

│       ├── barplot\_population\_districts\_2024.png

│       ├── barplot\_densite\_districts\_2024.png

│       └── evolution\_population\_2015\_2024.png

│

├── scripts/

│   └── script.R

│

└── README.md



* ***Données Utilisées***



 	***Données Raster***



Source : worldpop.org/geodata



Format : GeoTIFF (.tif)



Contenu : Estimations du nombre total de personnes



Période : 2015-2024 (10 fichiers annuels)



 	***Données Vectorielles***



Source : GADM (Database of Global Administrative Areas)



Format : Shapefile (.shp)



Niveaux administratifs :



Niveau 0 : Pays



Niveau 1 : Districts



Niveau 2 : Régions



Niveau 3 : Sous-préfectures



Niveau 4 : Communes



* ***Technologies et Outils***



R : Langage principal pour l’analyse statistique



Packages principaux :



sf : Manipulation de données vectorielles



terra : Manipulation de données raster



tmap : Cartographie thématique



ggplot2 : Visualisations graphiques



dplyr : Manipulation de données



* ***Analyses Réalisées***



Vérification des propriétés des shapefiles et des rasters



Visualisation des limites administratives par niveau combinées avec labels



Cartes thématiques de la population annuelle sur la période 2015-2024





* **Applications Pratiques**



Calcul et analyse de la superficie par district



Calcul et analyse de la population totale par district



Calcul et analyse de la densité par district



Analyse de l’évolution de la population de 2015 à 2024





* ***Références***



GADM : https://gadm.org/



Données population raster : https://hub.worldpop.org/





