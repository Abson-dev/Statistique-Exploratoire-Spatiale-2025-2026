# 🇪🇹 Cartographie Dynamique des Indicateurs de Santé en Éthiopie

Application interactive Google Earth Engine pour visualiser les indicateurs de santé maternelle et infantile en Éthiopie (2016).

## 🎯 Fonctionnalités

- ✅ Visualisation de 6 indicateurs de santé
- ✅ Légende dynamique qui s'adapte à chaque indicateur
- ✅ Indice de vulnérabilité composite
- ✅ Propriétés détaillées des rasters (résolution, dimensions, nombre de pixels)
- ✅ Inspecteur de points interactif
- ✅ Génération d'histogrammes
- ✅ Mode comparaison côte à côte
- ✅ Export vers Google Drive

## 📊 Indicateurs disponibles

1. **Contraception** : Proportion de femmes sans contraception moderne
2. **Pauvreté** : Ménages parmi les plus pauvres
3. **Malnutrition** : Enfants en insuffisance pondérale (12-23 mois)
4. **Éducation** : Mères sans éducation formelle
5. **Démographie** : Grands ménages (≥9 membres)
6. **Naissances** : Densité de naissances vivantes
7. **Vulnérabilité** : Indice composite pondéré

## 🚀 Installation et Utilisation

### Prérequis
- Compte Google Earth Engine (gratuit) : https://earthengine.google.com/signup/
- Accès aux assets suivants dans GEE

### Méthode 1 : Exécution directe depuis GitHub

1. **Ouvrir Google Earth Engine Code Editor** : https://code.earthengine.google.com/

2. **Copier le code** :
   - Ouvrez le fichier [`script.js`](./script.js)
   - Cliquez sur "Raw" puis copiez tout le code (Ctrl+A, Ctrl+C)

3. **Coller dans GEE** :
   - Dans l'éditeur GEE, créez un nouveau script
   - Collez le code copié

4. **Importer vos données** :
   Vous devez d'abord importer vos propres assets ou utiliser des données publiques.
   Remplacez les lignes suivantes par vos chemins d'assets :
```javascript
   // Remplacez par vos chemins d'assets
   var contraception = ee.Image('projects/YOUR_PROJECT/assets/ETH_CONTRACEPTION_MEAN');
   var demographie = ee.Image('projects/YOUR_PROJECT/assets/ETH_HSIZE_MEAN');
   // ... etc
```

5. **Exécuter** : Cliquez sur "Run" ▶️

### Méthode 2 : Installation via GEE Repository

Si vous avez un compte GEE Team/Pro, vous pouvez partager directement via GEE :
```
https://code.earthengine.google.com/?accept_repo=users/YOUR_USERNAME/ethiopia-health
```

## 📁 Structure des données

### Assets requis

| Asset | Description | Format |
|-------|-------------|--------|
| `ETH_CONTRACEPTION_MEAN` | Absence de contraception | Raster (0-1) |
| `ETH_HSIZE_MEAN` | Grands ménages | Raster (0-1) |
| `ETH_HWEALTH_MEAN` | Pauvreté | Raster (0-1) |
| `ETH_MALNUTRITION_MEAN` | Malnutrition infantile | Raster (0-1) |
| `ETH_MEDUCATION_MEAN` | Éducation informelle | Raster (0-1) |
| `ETH_births_pp_v2_2015` | Naissances vivantes | Raster |
| `gadm41_ETH_0` | Frontières Éthiopie | FeatureCollection |

### Sources de données alternatives (publiques)

Si vous n'avez pas accès aux données originales, vous pouvez utiliser :

- **WorldPop** : Données de population
- **DHS Spatial Data** : Données d'enquêtes démographiques
- **GADM** : Frontières administratives (disponibles publiquement)

## 🎨 Captures d'écran

### Interface principale
![Interface](./screenshots/interface.png)

### Panneau des propriétés
![Propriétés](./screenshots/properties.png)

### Indice de vulnérabilité
![Vulnérabilité](./screenshots/vulnerability.png)

## 📖 Documentation

### Calcul de l'indice de vulnérabilité

L'indice composite est calculé avec les pondérations suivantes :
```javascript
Vulnérabilité = (Contraception × 0.25) + 
                (Pauvreté × 0.30) + 
                (Malnutrition × 0.30) + 
                (Éducation × 0.15)
```

### Palettes de couleurs

- **Rouge** : Indicateurs négatifs (pauvreté, malnutrition)
- **Bleu** : Indicateurs démographiques
- **Gradient vert-rouge** : Indice de vulnérabilité

## 🛠️ Personnalisation

### Modifier les pondérations
```javascript
var indiceVulnerabilite = contracepNorm.multiply(0.25)    // 25%
  .add(pauvreteNorm.multiply(0.30))                       // 30%
  .add(malnutNorm.multiply(0.30))                         // 30%
  .add(educNorm.multiply(0.15));                          // 15%
```

### Changer les seuils d'alerte
```javascript
// Modifier le seuil (actuellement 0.5 = 50%)
var zonesAlerteRouge = indiceVulnerabilite.gt(0.7).selfMask();
```

### Ajouter de nouvelles palettes
```javascript
var maPalette = ['#ffffb2', '#fecc5c', '#fd8d3c', '#f03b20', '#bd0026'];
```

## 🤝 Contribution

Les contributions sont les bienvenues ! 

1. Fork ce repository
2. Créez une branche (`git checkout -b feature/amelioration`)
3. Commit vos changements (`git commit -m 'Ajout fonctionnalité X'`)
4. Push vers la branche (`git push origin feature/amelioration`)
5. Ouvrez une Pull Request

## 📝 Citation

Si vous utilisez ce code dans vos recherches, veuillez citer :
```bibtex
@software{ethiopia_health_mapping_2024,
  author = {Votre Nom},
  title = {Cartographie Dynamique des Indicateurs de Santé en Éthiopie},
  year = {2024},
  url = {https://github.com/votre-username/ethiopia-health-mapping-gee}
}
```

## 📄 Licence

MIT License - voir le fichier [LICENSE](LICENSE) pour plus de détails.

## 👨‍💻 Auteur

**Votre Nom**
- GitHub: [@votre-username](https://github.com/votre-username)
- Email: votre.email@example.com

## 🙏 Remerciements

- Google Earth Engine pour la plateforme
- DHS Program pour les données
- Anthropic Claude pour l'assistance au développement

## 📚 Ressources

- [Documentation Google Earth Engine](https://developers.google.com/earth-engine)
- [Guide des API GEE](https://developers.google.com/earth-engine/guides)
- [Forum GEE](https://groups.google.com/g/google-earth-engine-developers)

## 🐛 Signaler un bug

Ouvrez une [issue](https://github.com/votre-username/ethiopia-health-mapping-gee/issues) avec :
- Description du problème
- Étapes pour reproduire
- Captures d'écran si possible

## 🔄 Versions

### v1.0.0 (2024-11-19)
- ✨ Version initiale
- ✅ 7 indicateurs de santé
- ✅ Légendes dynamiques
- ✅ Propriétés des rasters
- ✅ Interface interactive complète

---

⭐ **N'oubliez pas de mettre une étoile si ce projet vous aide !** ⭐