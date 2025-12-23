#  Analyse Température Mali

## 📊 Vue d'ensemble

Fusion des données **MODIS LST** (température de surface), **EHCVM** (enquête ménages) et **shapefiles administratifs** pour analyser l'exposition thermique des populations au Mali. Création de carte donnant la temperature par pixel

---

## 📁 Données utilisées

| Source | Description | Format | Résolution |
|--------|-------------|--------|-----------|
| **MODIS Terra** | Température de surface (LST) | HDF (MOD11A2.061) | 1 km, 8 jours |
| **EHCVM 2021** | Enquête ménages (6,143 ménages) | .dta (Stata) | 10 régions |
| **Shapefiles** | Limites administratives Mali | .shp | Régions/Cercles/Communes |

**Période couverte :** Novembre 2025 - Avril 2026 (24 fichiers MODIS)

---

## 🎯 Indicateurs calculés

### 1. **Température moyenne (T_Jour_moy, T_Nuit_moy)**
- **Mesure :** Température de surface en °C
- **Formule :** `T(°C) = (Valeur_pixel × 0.02) - 273.15`
- **Usage :** Exposition thermique de base par région

### 2. **Amplitude thermique (Amplitude_JN)**
- **Mesure :** Différence jour-nuit
- **Formule :** `Amplitude = T_Jour - T_Nuit`
- **Usage :** Indicateur de confort thermique (amplitude élevée = inconfort)

### 3. **Indice de Vulnérabilité Thermique (IVT)**
- **Mesure :** Score composite 0-1
- **Formule :** `IVT = 0.4×T_norm + 0.3×Variabilité_norm + 0.3×Amplitude_norm`
- **Catégories :**
  - Très faible (< 0.2)
  - Faible (0.2-0.4)
  - Modérée (0.4-0.6)
  - Élevée (0.6-0.8)
  - Très élevée (> 0.8)

### 4. **Exposition thermique (Exposition_chaleur)**
- **Mesure :** Catégorisation de l'exposition
- **Seuils :**
  - Faible : T < 30°C
  - Modérée : 30-35°C
  - Élevée : 35-40°C
  - Extrême : T > 40°C

### 5. **Score de risque chaleur**
- **Mesure :** Score synthétique 0-100
- **Formule :** `Score = 0.5×Percentile_T + 0.3×Pct_jours_inconfort + 0.2×(IVT×100)`
- **Seuil alerte :** > 70

### 6. **Différentiel urbain-rural**
- **Mesure :** Effet îlot de chaleur urbain
- **Formule :** `Δ = T_urbain_moyen - T_rural_moyen`
- **Usage :** Identifier les îlots de chaleur

### 7. **Position Nord-Sud**
- **Mesure :** Score de position 0-100
- **Formule :** `Score = ((Latitude - Lat_min) / (Lat_max - Lat_min)) × 100`
- **Usage :** Analyser le gradient thermique

### 8. **Exposition relative nationale**
- **Mesure :** Écart à la moyenne nationale
- **Formule :** `Δ = T_région - T_nationale_moyenne`
- **Catégories :** Beaucoup plus frais / Plus frais / Moyenne / Plus chaud / Beaucoup plus chaud

---

## 📋 Fichiers de sortie

### Principal
**`EHCVM_temperature_fusion.csv`** (6,143 lignes × ~35 colonnes)
- Données EHCVM complètes
- Tous les indicateurs de température
- Géolocalisation (latitude, longitude)

### Statistiques agrégées
**`EHCVM_temperature_fusion_stats_agregees.xlsx`** (4 onglets)
1. Par région (10 régions)
2. Par milieu (urbain/rural)
3. Répartition par exposition
4. Répartition par vulnérabilité

### Visualisations
- `cartes_exposition_thermique.png` : 4 cartes choroplèthes
- `graphiques_analyse_socio_thermique.png` : 6 graphiques analytiques
- `dashboard_temperature_ehcvm_interactif.html` : Dashboard web interactif

---

## 🔧 Installation et utilisation

### Prérequis
```bash
pip install pandas numpy geopandas matplotlib seaborn plotly pyhdf 
```


## 📈 Résultats clés attendus

### Gradient thermique
- **Nord (Kidal) :** ~40-45°C
- **Centre (Mopti) :** ~35-40°C
- **Sud (Sikasso) :** ~30-35°C
- **Tendance :** -1.5 à -2.0°C par degré de latitude

### Îlot de chaleur urbain
- Différentiel attendu : **+2 à +4°C** (Bamako vs zones rurales)

### Ménages en exposition élevée/extrême
- Estimation : **20-30%** des ménages (régions Nord)

---

## ⚠️ Limites méthodologiques

1. **Température de surface ≠ Température de l'air**
   - Écart de 5-10°C possible
   - LST reflète le ressenti au sol, pas l'air ambiant

2. **Résolution spatiale**
   - 1 km : moyenne d'une zone, pas un point précis
   - Attribution régionale (pas de coordonnées GPS exactes par ménage)

3. **Couverture nuageuse**
   - Pixels manquants si nuages présents
   - Vérifier le % de pixels valides

4. **Période limitée**
   - 6 mois de données (saison sèche 2025-2026)
   - Pas de cycle annuel complet

---

## 📚 Références

- **MODIS Terra LST :** [doi:10.5067/MODIS/MOD11A2.061](https://doi.org/10.5067/MODIS/MOD11A2.061)
- **EHCVM Mali 2021 :** INSTAT - Institut National de la Statistique
- **Shapefiles :** OCHA/HDX Mali Administrative Boundaries

---

## 👥 Contact et citation

**Projet :** Analyse socio-thermique Mali (2025)  
**Données :** MODIS + EHCVM + Shapefiles administratifs  
**Code :** Python 3.8+ (pandas, geopandas, plotly, pyhdf)

