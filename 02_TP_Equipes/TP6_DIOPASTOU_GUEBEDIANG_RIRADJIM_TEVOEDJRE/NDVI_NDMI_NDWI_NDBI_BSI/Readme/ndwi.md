## Indice Normalisé de Différence de l’Eau (NDWI)

### Description de l’indicateur

Le **NDWI (Normalized Difference Water Index)** est un indice spectral de télédétection utilisé pour **détecter la présence de l’eau de surface** et apprécier le **niveau d’humidité des milieux naturels**. Il est particulièrement pertinent pour l’identification des plans d’eau, des zones inondées et des surfaces à forte teneur en eau.

Le principe du NDWI repose sur le **contraste spectral entre la réflectance de l’eau dans le vert et dans le proche infrarouge**. Les surfaces en eau réfléchissent modérément le rayonnement dans le **vert**, mais absorbent fortement le rayonnement dans le **proche infrarouge (NIR)**. À l’inverse, la végétation et les sols secs présentent une réflectance plus élevée dans le NIR.

Ainsi, les zones riches en eau présentent des valeurs de NDWI plus élevées que les surfaces sèches ou faiblement humides.

Les valeurs du NDWI sont comprises entre **−1 et +1** :

- **NDWI négatif** : surfaces sèches, sols nus, zones bâties ou végétation peu humide ;
- **NDWI proche de 0** : surfaces légèrement humides ou zones de transition ;
- **NDWI positif modéré (≈ 0.1 à 0.3)** : sols humides, zones inondables ou végétation avec une teneur en eau significative ;
- **NDWI élevé (> 0.3)** : plans d’eau, zones fortement inondées ou surfaces saturées en eau.

Le NDWI est couramment utilisé pour :
- la cartographie des plans d’eau et des zones humides ;
- le suivi des inondations et des variations saisonnières de l’eau ;
- l’analyse du stress hydrique et des conditions hydrologiques ;
- les études environnementales et climatiques.

---

### Méthodologie de calcul

Dans le cadre des données **Sentinel-2**, le NDWI est calculé à partir des bandes spectrales suivantes :

- **B3 (Vert)** : bande centrée autour de **560 nm**, présentant une réflectance relativement élevée pour l’eau ;
- **B8 (Proche infrarouge – NIR)** : bande centrée autour de **842 nm**, fortement absorbée par l’eau.

Ces bandes sont utilisées à une **résolution spatiale de 10 m** (ou rééchantillonnées à une résolution commune si nécessaire).

La formule du NDWI est définie comme suit :

$$
NDWI = \frac{Green - NIR}{Green + NIR}
$$

où :
- $Green$ représente la réflectance de la bande **B3** ;
- $NIR$ représente la réflectance de la bande **B8**.

La normalisation de l’indice permet :
- de limiter l’influence des variations d’illumination ;
- d’améliorer la comparabilité spatiale et temporelle ;
- d’obtenir un indicateur adimensionnel borné entre −1 et +1.