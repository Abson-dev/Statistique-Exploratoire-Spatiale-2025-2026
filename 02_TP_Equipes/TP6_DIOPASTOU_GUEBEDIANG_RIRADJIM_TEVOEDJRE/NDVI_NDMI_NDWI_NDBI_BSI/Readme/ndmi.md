## Indice de Teneur en Eau de la Végétation (NDMI)

### Description de l’indicateur

Le **NDMI (Normalized Difference Moisture Index)** est un indice spectral de télédétection utilisé pour **estimer la teneur en eau de la végétation** et détecter le **stress hydrique des plantes**. Il permet d’évaluer la santé physiologique des cultures, des forêts et de la végétation naturelle.

Le principe repose sur la **différence de réflectance entre le proche infrarouge (NIR) et le moyen infrarouge (SWIR)** :

- la réflectance dans le **NIR** est fortement liée à la structure des feuilles et à la biomasse ;
- la réflectance dans le **SWIR** est fortement influencée par la teneur en eau dans les tissus végétaux.

Ainsi, un NDMI élevé correspond à une végétation **riche en eau et saine**, tandis qu’un NDMI faible ou négatif indique **stress hydrique, sécheresse ou végétation dégradée**.

Les valeurs du NDMI sont comprises entre **−1 et +1** :

- **NDMI négatif** : végétation stressée ou faible humidité dans les feuilles  
- **NDMI proche de 0** : zones en transition ou végétation modérément humide  
- **NDMI positif** : végétation saine et riche en eau  

Le NDMI est particulièrement utilisé pour :
- le suivi de l’humidité de la végétation et le stress hydrique ;
- l’évaluation de la santé des cultures et des forêts ;
- la surveillance environnementale dans les régions sensibles à la sécheresse.

---

### Méthodologie de calcul

Le NDMI est calculé à partir des images multispectrales **Sentinel-2**, en utilisant les bandes suivantes :

- **B8 (Proche infrarouge – NIR, 842 nm)** : fortement réfléchie par la structure des feuilles ;  
- **B11 (Moyen infrarouge – SWIR, 1610 nm)** : absorbée en fonction de la teneur en eau des tissus végétaux.

La formule du NDMI est définie comme suit :

$$
NDMI = \frac{NIR - SWIR}{NIR + SWIR}
$$

où :  
- $NIR$ représente la réflectance de la bande **B8** ;  
- $SWIR$ représente la réflectance de la bande **B11**.  

Cette normalisation permet d’obtenir un indicateur **adimensionnel**, borné entre −1 et +1, facilitant la comparaison spatiale et temporelle de l’humidité de la végétation.

---

### Remarque méthodologique

Le NDMI est robuste pour détecter le stress hydrique, mais certaines limites doivent être prises en compte :

- sensibilité aux nuages et aux ombres sur la végétation ;  
- saturation possible dans les zones de végétation très dense ;  
- dépendance à la correction atmosphérique des images.  

Pour des analyses complètes, le NDMI est souvent utilisé **en complément du NDVI et du NDWI**, permettant de distinguer la végétation saine, les zones humides et les sols nus ou artificialisés.