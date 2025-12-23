## Indice de Construction Normalisé (NDBI)

### Description de l’indicateur

Le **NDBI (Normalized Difference Built-up Index)** est un indice spectral utilisé en télédétection pour **identifier et cartographier les zones bâties ou artificialisées** à la surface terrestre. Il permet de différencier les zones urbaines des zones végétalisées ou aquatiques.

Le principe du NDBI repose sur la **différence spectrale entre le proche infrarouge (NIR) et les bandes du moyen infrarouge (SWIR)**. Les surfaces bâties et artificialisées réfléchissent davantage le rayonnement dans le **SWIR** que dans le **NIR**, tandis que la végétation et l’eau présentent des comportements inverses.

Les valeurs du NDBI sont comprises entre **−1 et +1** :

- **NDBI négatif** : zones non bâties, principalement végétation dense ou plans d’eau ;
- **NDBI proche de 0** : zones mixtes, transition entre zones bâties et naturelles ;
- **NDBI positif (> 0)** : zones fortement urbanisées ou surfaces artificialisées.

Le NDBI est particulièrement utilisé pour :
- la cartographie et le suivi de l’urbanisation ;
- l’analyse de la densité des constructions ;
- l’évaluation de l’extension des villes et la planification urbaine ;
- les études environnementales sur l’artificialisation du sol.

---

### Méthodologie de calcul

Le NDBI est calculé à partir des images multispectrales du satellite **Sentinel-2**, avec une combinaison spécifique de bandes :

- **B8 (Proche infrarouge – NIR)** : bande centrée autour de **842 nm**, fortement réfléchie par la végétation ;
- **B11 (Moyen infrarouge – SWIR)** : bande centrée autour de **1610 nm**, sensible aux matériaux urbains et aux surfaces artificialisées.

La formule du NDBI est définie comme suit :

$$
NDBI = \frac{SWIR - NIR}{SWIR + NIR}
$$

où :
- $SWIR$ représente la réflectance de la bande **B11** ;
- $NIR$ représente la réflectance de la bande **B8**.

La normalisation permet d’obtenir un indicateur **adimensionnel**, borné entre −1 et +1, et de comparer les zones urbanisées dans l’espace et le temps.