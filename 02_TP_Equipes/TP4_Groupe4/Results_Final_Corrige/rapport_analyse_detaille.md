# RAPPORT D'ANALYSE: SEUILS D'EAU PERMANENTE EN ÉTHIOPIE

## 1. CONTEXTE ET OBJECTIFS
Cette analyse vise à déterminer le seuil optimal d'occurrence d'eau pour identifier les eaux permanentes en Éthiopie. L'objectif est de calculer les terres arables disponibles en excluant ces zones d'eau permanente.

- **Référence FAO**: 15.0 millions d'hectares de terres arables
- **Superficie de l'Éthiopie**: 113.14 Mha
- **Seuils testés**: 75, 85, 90, 95%

## 2. MÉTHODOLOGIE
1. **Mosaïquage** des données d'occurrence d'eau annuelle
2. **Découpage** selon les frontières de l'Éthiopie
3. **Analyse par seuil** des eaux permanentes
4. **** des terres arables disponibles
5. **Validation** par comparaison avec les données FAO

## 3. RÉSULTATS DÉTAILLÉS

| Seuil (%) | Eau permanente (Mha) | % Territoire | Terres arables ls (Mha) | Écart vs FAO (%) |
|-----------|----------------------|--------------|-------------------------------|------------------|
| 75.0 | 0.6515 | 0.576% | 17.436 | +16.238% |
| 85.0 | 0.6253 | 0.553% | 17.440 | +16.265% |
| 90.0 | 0.6063 | 0.536% | 17.443 | +16.285% |
| 95.0 | 0.5765 | 0.510% | 17.447 | +16.315% |

## 4. ANALYSE ET CONCLUSION

### Seuil optimal: **75%**

**Justification**: Ce seuil minimise l'écart avec les données FAO (16.238%)

**Caractéristiques pour 75%**:
- **Eau permanente détectée**: 0.6515 Mha (0.576% du territoire)
- **Terres disponibles**: 112.488 Mha
- **Terres arables ls**: 17.436 Mha
- **Coefficient arable utilisé**: 15.5%

### Interprétation
- L' est **supérieure** aux données FAO
- Suggestions: Réduire le coefficient arable ou ajuster le seuil

## 5. RECOMMANDATIONS
1. **Validation terrain**: Vérifier la détection d'eau sur le terrain
2. **Calibration fine**: Ajuster le coefficient arable avec des données locales
3. **Sensibilité**: Tester d'autres seuils (60%, 70%, 80%)
4. **Données complémentaires**: Intégrer les données d'utilisation des sols

## 6. FICHIERS GÉNÉRÉS
- `water_mosaic_full.tif`: Mosaïque complète des données
- `water_ethiopia_final.tif`: Données découpées pour l'Éthiopie
- `water_mask_XX.tif`: Masques d'eau par seuil
- `resultats_complets.csv`: Résultats détaillés
- `visualisation_complete.png`: Graphiques d'analyse
- `graphique_principal.png`: Graphique de synthèse
- `rapport_analyse_detaille.md`: Ce rapport
