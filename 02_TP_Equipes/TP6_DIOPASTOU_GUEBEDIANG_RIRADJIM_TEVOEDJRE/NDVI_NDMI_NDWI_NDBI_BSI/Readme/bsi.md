## Indice des Sols Nus (BSI)

### Description de l’indicateur

Le **BSI (Bare Soil Index)** est un indice spectral de télédétection utilisé pour **identifier et cartographier les sols nus ou faiblement végétalisés**. Il est particulièrement pertinent pour l’analyse de la dégradation des sols, la désertification et la dynamique d’occupation du sol dans les régions arides et semi-arides.

Le BSI repose sur les **différences de comportement spectral entre les sols nus, la végétation et l’eau**. Les sols nus présentent généralement une réflectance élevée dans le **rouge (Red)** et le **moyen infrarouge (SWIR)**, tandis que la végétation réfléchit davantage le **proche infrarouge (NIR)** et absorbe le rouge. L’eau, quant à elle, absorbe fortement dans le NIR et le SWIR.

Ainsi, le BSI permet de **renforcer le signal des sols nus** tout en atténuant celui de la végétation et des surfaces en eau.

Les valeurs du BSI sont comprises entre **−1 et +1** :

- **BSI négatif** : surfaces couvertes par la végétation ou par l’eau ;
- **BSI proche de 0** : zones de transition, sols partiellement couverts ;
- **BSI positif élevé (> 0)** : sols nus, surfaces dégradées ou zones faiblement végétalisées.

Le BSI est couramment utilisé pour :
- la cartographie des sols nus et des zones dégradées ;
- l’étude de la désertification et de l’érosion des sols ;
- l’analyse de la dynamique saisonnière de la couverture du sol ;
- les études environnementales et agroécologiques.

---

### Méthodologie de calcul

Le BSI est calculé à partir des images multispectrales **Sentinel-2**, en combinant quatre bandes spectrales :

- **B4 (Rouge – Red)** : bande centrée autour de **665 nm**, sensible à la réflectance des sols nus ;
- **B8 (Proche infrarouge – NIR)** : bande centrée autour de **842 nm**, fortement réfléchie par la végétation ;
- **B11 (Moyen infrarouge – SWIR)** : bande centrée autour de **1610 nm**, très sensible à l’humidité du sol et aux surfaces minérales ;
- **B2 (Bleu – Blue)** : bande centrée autour de **490 nm**, utilisée pour améliorer la discrimination entre sols nus et surfaces artificialisées.

La formule du BSI est définie comme suit :

$$
BSI = \frac{(SWIR + Red) - (NIR + Blue)}{(SWIR + Red) + (NIR + Blue)}
$$

où :
- $SWIR$ représente la réflectance de la bande **B11** ;
- $Red$ représente la réflectance de la bande **B4** ;
- $NIR$ représente la réflectance de la bande **B8** ;
- $Blue$ représente la réflectance de la bande **B2**.

Cette formulation permet de **maximiser le contraste des sols nus** tout en réduisant l’influence de la végétation et de l’eau.