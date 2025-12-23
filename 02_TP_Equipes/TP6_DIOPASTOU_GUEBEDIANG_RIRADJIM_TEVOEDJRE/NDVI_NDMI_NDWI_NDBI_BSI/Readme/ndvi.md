## Indice de Végétation Normalisé (NDVI)

### Description de l’indicateur

Le **NDVI (Normalized Difference Vegetation Index)** est un indice spectral de télédétection largement utilisé pour **caractériser la présence, la densité et l’état physiologique de la végétation** à la surface terrestre.

Il repose sur une **propriété biophysique fondamentale des plantes vertes** : la **chlorophylle** absorbe fortement le rayonnement dans le **rouge** pour les besoins de la photosynthèse, tandis que la structure interne des feuilles réfléchit fortement le rayonnement dans le **proche infrarouge (NIR)**.

Ainsi, plus la végétation est **dense, saine et photosynthétiquement active**, plus la différence entre la réflectance dans le proche infrarouge et celle dans le rouge est élevée.

Les valeurs du NDVI sont comprises entre **−1 et +1** :

- **NDVI < 0** : surfaces non végétalisées, principalement l’eau, certaines surfaces artificialisées ou zones très sombres ;
- **NDVI proche de 0 (≈ 0 à 0.2)** : sols nus, zones faiblement végétalisées, surfaces désertiques ou rocheuses ;
- **NDVI intermédiaire (≈ 0.2 à 0.4)** : végétation clairsemée, cultures en début ou en fin de cycle végétatif ;
- **NDVI élevé (> 0.4)** : végétation dense, vigoureuse et active photosynthétiquement (forêts, cultures en pleine croissance).

Le NDVI est couramment mobilisé pour :

- le suivi spatio-temporel de la végétation et des cultures ;
- l’analyse de la productivité végétale ;
- la détection du stress hydrique et de la dégradation environnementale ;
- les études sur la sécheresse et la variabilité climatique.

---

### Méthodologie de calcul

Le NDVI est calculé à partir des images multispectrales du satellite **Sentinel-2**, qui offrent une résolution spatiale et spectrale adaptée à l’analyse de la végétation.

Les bandes spectrales utilisées sont :

- **B4 (Rouge)** : bande centrée autour de **665 nm**, fortement absorbée par la chlorophylle ;
- **B8 (Proche infrarouge – NIR)** : bande centrée autour de **842 nm**, fortement réfléchie par la structure cellulaire des feuilles.

Ces bandes sont généralement exploitées à une **résolution spatiale de 10 m** ou agrégées à une résolution plus grossière selon l’objectif de l’étude.

Le NDVI est défini par la relation suivante :

$$
NDVI = \frac{NIR - Red}{NIR + Red}
$$

où :

- $NIR$ représente la réflectance de la bande **B8** ;
- $Red$ représente la réflectance de la bande **B4**.

La normalisation de l’indice permet :

- de réduire l’influence des conditions d’illumination et de la topographie ;
- de faciliter la comparaison spatiale et temporelle des valeurs ;
- d’obtenir un indicateur adimensionnel borné entre −1 et +1.

