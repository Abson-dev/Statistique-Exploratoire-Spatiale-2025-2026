# MÉTHODOLOGIE COMPLÈTE - CALCUL DE L'INDICATEUR ODD 11.3.1 POUR LA RDC

## Guide détaillé basé sur le document QGIS adapté pour R

---

## INTRODUCTION

### Qu'est-ce que l'indicateur ODD 11.3.1 ?

**Définition officielle :**
> "Ratio du taux de consommation des terres au taux de croissance démographique"

**Objectif :**
- Mesurer l'efficacité de la croissance urbaine
- Identifier si les villes s'étendent de manière durable
- Comparer la vitesse de consommation des terres avec la croissance démographique

**Interprétation :**
- **Ratio > 1** : Les terres sont consommées plus rapidement que la population ne croît → **Expansion urbaine (sprawl)**
- **Ratio < 1** : La population croît plus vite que la consommation de terres → **Densification**
- **Ratio = 1** : Croissance proportionnelle

---

## PARTIE 1 : PRÉPARATION DES DONNÉES

### ÉTAPE 0 : Configuration de l'environnement R

```r
# ============================================================
# ÉTAPE 0 : CONFIGURATION DE L'ENVIRONNEMENT
# ============================================================

# Définir le répertoire de travail
setwd("C:/Users/Easy Services Pro/OneDrive/Bureau/ENSAE_ISEP3/Semestre1/Statistique/Stat E. spaciale/TP5_SES")

# Définir le miroir CRAN
options(repos = c(CRAN = "https://cloud.r-project.org/"))

# Charger les packages nécessaires
library(sf)           # Données vectorielles
library(terra)        # Données raster
library(tidyverse)    # Manipulation de données
library(geodata)      # Téléchargement de données géographiques
library(exactextractr)# Statistiques zonales
library(ggplot2)      # Visualisation

# Créer la structure de dossiers
dirs <- c("data", "data/population", "data/lulc", "data/boundaries", 
          "data/urban_areas", "output", "figures")
lapply(dirs, function(d) dir.create(d, showWarnings = FALSE, recursive = TRUE))

cat("✓ Environnement configuré\n")
```

---

### ÉTAPE 1 : DÉFINIR LA GÉOGRAPHIE ANALYTIQUE (DEGURBA)

**Principe :** Selon la méthodologie officielle, l'indicateur ODD 11.3.1 doit être calculé pour des zones urbaines définies selon la classification DEGURBA (Degree of Urbanisation).

#### 1.1 Méthode officielle DEGURBA

**Définition DEGURBA :**
La classification DEGURBA définit les zones urbaines basées sur :
- La densité de population (≥1500 hab/km² dans des cellules de 1 km²)
- La population totale minimale (≥50 000 habitants)
- La contiguïté spatiale des cellules denses

**Processus de création DEGURBA (selon le document) :**

1. **Préparer les données d'entrée :**
   - Raster de population (résolution 1 km recommandée)
   - Raster de zones bâties (résolution 10-30 m)

2. **Appliquer les critères de densité :**
   - Identifier les cellules avec densité ≥ 1500 hab/km²
   - Regrouper les cellules contiguës
   - Ne garder que les clusters ≥ 50 000 habitants

3. **Définir les centres urbains :**
   - Appliquer un buffer (gap-filling) pour combler les trous
   - Lisser les frontières

**Pour la RDC - Approche pratique :**

```r
# ============================================================
# ÉTAPE 1 : DÉFINIR LES ZONES URBAINES (DEGURBA)
# ============================================================

# OPTION A : Utiliser le GHS Urban Centre Database (recommandé)
# Ce dataset contient les zones urbaines pré-calculées selon DEGURBA

# Télécharger depuis : https://ghsl.jrc.ec.europa.eu/download.php
# Filtrer pour COD (RDC)

# OPTION B : Créer manuellement les zones urbaines principales
# Pour les 10 plus grandes villes de la RDC

villes_rdc <- data.frame(
  nom = c("Kinshasa", "Lubumbashi", "Mbuji-Mayi", "Kananga", 
          "Kisangani", "Bukavu", "Goma", "Kolwezi", "Likasi", "Matadi"),
  lon = c(15.3139, 27.4667, 23.6000, 22.4167, 25.2000, 
          28.8473, 29.2247, 25.4667, 26.7333, 13.4500),
  lat = c(-4.3317, -11.6667, -6.1500, -5.8961, 0.5167, 
          -2.5084, -1.6740, -10.7167, -10.9833, -5.8167)
)

# Convertir en objet spatial (WGS84)
villes_sf <- st_as_sf(villes_rdc, coords = c("lon", "lat"), crs = 4326)

# IMPORTANT : Déterminer la zone UTM appropriée pour chaque ville
# La RDC s'étend sur plusieurs zones UTM (32S à 36S)

# Pour simplifier, on utilise UTM 33S pour la zone centrale
# En pratique, il faudrait utiliser la zone UTM appropriée pour chaque ville

villes_utm <- st_transform(villes_sf, crs = 32733)

# Créer des buffers de 10 km (rayon recommandé pour zones urbaines)
# Ce rayon doit être ajusté selon la taille réelle de chaque ville
zones_urbaines <- st_buffer(villes_utm, dist = 10000)  # 10 km

# Sauvegarder
st_write(zones_urbaines, "data/urban_areas/zones_urbaines_rdc.shp", 
         delete_dsn = TRUE)

cat("✓ Zones urbaines définies\n")
```

**NOTE IMPORTANTE :** Dans un projet réel, le rayon du buffer devrait être déterminé par :
1. L'analyse des données de population (étendue de la zone avec densité > 300 hab/km²)
2. L'analyse des zones bâties continues
3. Les limites administratives officielles des villes

---

### ÉTAPE 2 : ACQUÉRIR LES DONNÉES DE POPULATION

**Spécifications requises selon le document :**
- **Source recommandée :** WorldPop ou données de recensement nationales
- **Résolution :** 100 m (idéal) ou 1 km (acceptable)
- **Format :** Raster avec nombre de personnes par pixel
- **Années requises :** Au moins 2 années espacées de 3, 5 ou 10 ans

```r
# ============================================================
# ÉTAPE 2 : DONNÉES DE POPULATION
# ============================================================

# 2.1 Télécharger WorldPop (résolution 1 km avec ajustement ONU)
# Ces données sont ajustées aux estimations officielles de l'ONU

urls_pop <- list(
  pop_2017 = "https://data.worldpop.org/GIS/Population/Global_2000_2020_1km_UNadj/2017/COD/cod_ppp_2017_1km_Aggregated_UNadj.tif",
  pop_2020 = "https://data.worldpop.org/GIS/Population/Global_2000_2020_1km_UNadj/2020/COD/cod_ppp_2020_1km_Aggregated_UNadj.tif"
)

for (nom in names(urls_pop)) {
  fichier <- paste0("data/population/rdc_", nom, "_1km.tif")
  if (!file.exists(fichier)) {
    download.file(urls_pop[[nom]], fichier, mode = "wb", timeout = 600)
  }
}

# 2.2 Charger et vérifier les données
pop_2017 <- rast("data/population/rdc_pop_2017_1km.tif")
pop_2020 <- rast("data/population/rdc_pop_2020_1km.tif")

# 2.3 Vérifier les systèmes de coordonnées
cat("CRS Population 2017:", crs(pop_2017, proj = TRUE), "\n")
cat("CRS Population 2020:", crs(pop_2020, proj = TRUE), "\n")

# 2.4 CRITIQUE : Reprojeter en UTM pour correspondre aux zones urbaines
# IMPORTANT : Le document QGIS insiste sur l'importance d'un CRS cohérent

pop_2017_utm <- project(pop_2017, "EPSG:32733", method = "bilinear")
pop_2020_utm <- project(pop_2020, "EPSG:32733", method = "bilinear")

# Sauvegarder les versions reprojetées
writeRaster(pop_2017_utm, "data/population/rdc_pop_2017_utm33s.tif", overwrite = TRUE)
writeRaster(pop_2020_utm, "data/population/rdc_pop_2020_utm33s.tif", overwrite = TRUE)

# 2.5 Vérifier la qualité des données
cat("\nStatistiques Population 2017:\n")
cat("  Min:", minmax(pop_2017_utm)[1], "\n")
cat("  Max:", minmax(pop_2017_utm)[2], "\n")
cat("  Total:", round(global(pop_2017_utm, "sum", na.rm = TRUE)$sum), "habitants\n")

cat("\nStatistiques Population 2020:\n")
cat("  Min:", minmax(pop_2020_utm)[1], "\n")
cat("  Max:", minmax(pop_2020_utm)[2], "\n")
cat("  Total:", round(global(pop_2020_utm, "sum", na.rm = TRUE)$sum), "habitants\n")

cat("✓ Données de population prêtes\n")
```

---

### ÉTAPE 3 : ACQUÉRIR LES DONNÉES D'OCCUPATION DU SOL (LULC)

**Spécifications selon le document :**
- **Résolution recommandée :** 10-30 mètres
- **Sources acceptées :** 
  - Esri Living Atlas (10 m) - **RECOMMANDÉ**
  - ESA WorldCover (10 m)
  - Dynamic World (10 m)
  - GHS-BUILT (10 m)
  - Landsat/Sentinel (30 m)
- **Classe recherchée :** Built-up areas (zones bâties)
- **Années requises :** Mêmes années que les données de population

#### 3.1 Téléchargement des données LULC

**IMPORTANT :** Pour la RDC, plusieurs tuiles sont nécessaires car le pays est très grand.

```r
# ============================================================
# ÉTAPE 3 : DONNÉES D'OCCUPATION DU SOL (LULC)
# ============================================================

# 3.1 Option A : Esri Living Atlas (RECOMMANDÉ)
# Téléchargement manuel depuis : https://livingatlas.arcgis.com/landcover/
# Sélectionner les années 2017 et 2020
# Télécharger les tuiles couvrant la RDC

# 3.2 Option B : ESA WorldCover (Alternative)
# Disponible pour 2020 et 2021 seulement

# Tuiles principales couvrant les zones urbaines de la RDC
tuiles_esa <- c(
  "S06E015",  # Kinshasa
  "S12E027",  # Lubumbashi
  "S09E024",  # Mbuji-Mayi
  "S06E021",  # Kananga
  "N00E024"   # Kisangani
)

telecharger_esa <- function(annee, tuile) {
  url <- paste0("https://esa-worldcover.s3.eu-central-1.amazonaws.com/v200/",
                annee, "/map/ESA_WorldCover_10m_", annee, "_v200_", tuile, "_Map.tif")
  fichier <- paste0("data/lulc/ESA_", annee, "_", tuile, ".tif")
  
  if (!file.exists(fichier)) {
    cat("Téléchargement de", tuile, "pour", annee, "...\n")
    download.file(url, fichier, mode = "wb", timeout = 900, quiet = TRUE)
  }
  return(fichier)
}

# Télécharger pour 2020 (remplace 2017 car pas disponible)
fichiers_2020 <- lapply(tuiles_esa, function(t) telecharger_esa(2020, t))

cat("✓ Données LULC téléchargées\n")
```

#### 3.2 Traitement des données LULC - Extraction des zones bâties

**Selon le document, les étapes sont :**

```r
# ============================================================
# ÉTAPE 3.2 : EXTRACTION DES ZONES BÂTIES
# ============================================================

# 3.2.1 Charger une tuile LULC (exemple pour Kinshasa)
lulc_kinshasa_2020 <- rast("data/lulc/ESA_2020_S06E015.tif")

# 3.2.2 Identifier la classe "Built-up"
# Pour ESA WorldCover : classe 50 = Built-up
# Pour Esri LULC : classe 7 = Built Area

# 3.2.3 Découper à l'étendue de la zone urbaine
zone_kinshasa <- zones_urbaines[zones_urbaines$nom == "Kinshasa", ]

# Reprojeter le LULC en UTM 33S
lulc_kinshasa_utm <- project(lulc_kinshasa_2020, "EPSG:32733", method = "near")

# 3.2.4 Découper (clip) le LULC à la zone urbaine
lulc_clip <- crop(lulc_kinshasa_utm, vect(zone_kinshasa))
lulc_mask <- mask(lulc_clip, vect(zone_kinshasa))

# 3.2.5 Extraire uniquement les zones bâties (classe 50 pour ESA)
# Méthode 1 : Reclassification binaire
rcl_matrix <- matrix(c(
  0, 49, 0,      # Classes 0-49 → 0 (non bâti)
  50, 50, 1,     # Classe 50 → 1 (bâti)
  51, 255, 0     # Classes 51-255 → 0 (non bâti)
), ncol = 3, byrow = TRUE)

zones_baties <- classify(lulc_mask, rcl_matrix)

# 3.2.6 IMPORTANT : Retirer les valeurs nulles pour le calcul de surface
# Selon le document QGIS : "Remove zero values to ensure only built-up areas are considered"
zones_baties[zones_baties == 0] <- NA

# Sauvegarder
writeRaster(zones_baties, "data/lulc/kinshasa_baties_2020.tif", overwrite = TRUE)

cat("✓ Zones bâties extraites pour Kinshasa\n")
```

**RÉPÉTER pour toutes les zones urbaines et toutes les années**

---

## PARTIE 2 : CALCUL DE L'INDICATEUR

### ÉTAPE 4 : CALCULER LA SURFACE BÂTIE PAR ZONE URBAINE

**Principe :** Utiliser les statistiques zonales pour sommer les pixels de zones bâties dans chaque zone urbaine.

```r
# ============================================================
# ÉTAPE 4 : CALCUL DES SURFACES BÂTIES
# ============================================================

# 4.1 Fonction pour calculer la surface bâtie
calculer_surface_batie <- function(raster_bati, zone_urbaine, resolution_m = 10) {
  # IMPORTANT : Vérifier que le CRS est le même
  if (st_crs(zone_urbaine) != crs(raster_bati)) {
    stop("Les systèmes de coordonnées ne correspondent pas!")
  }
  
  # Extraire le nombre de pixels bâtis (valeur = 1)
  stats <- exact_extract(raster_bati, zone_urbaine, fun = 'sum', progress = FALSE)
  
  # Calculer la surface
  # Chaque pixel = resolution_m × resolution_m mètres carrés
  surface_m2 <- stats * (resolution_m^2)
  surface_km2 <- surface_m2 / 1e6
  
  return(data.frame(
    nb_pixels_batis = stats,
    surface_m2 = surface_m2,
    surface_km2 = surface_km2
  ))
}

# 4.2 Appliquer pour 2017
# NOTE : Ici on utilise des données simulées, car ESA WorldCover 2017 n'existe pas
# Dans un projet réel, utilisez Esri LULC 2017 ou Landsat

# Exemple pour Kinshasa
surface_kinshasa_2017 <- calculer_surface_batie(
  raster_bati = rast("data/lulc/kinshasa_baties_2017.tif"),  # À remplacer par vos données
  zone_urbaine = zones_urbaines[zones_urbaines$nom == "Kinshasa", ],
  resolution_m = 10  # 10m pour ESA WorldCover
)

# 4.3 Appliquer pour 2020
surface_kinshasa_2020 <- calculer_surface_batie(
  raster_bati = rast("data/lulc/kinshasa_baties_2020.tif"),
  zone_urbaine = zones_urbaines[zones_urbaines$nom == "Kinshasa", ],
  resolution_m = 10
)

# 4.4 Afficher les résultats
cat("\nSURFACE BÂTIE - KINSHASA\n")
cat("2017:", surface_kinshasa_2017$surface_km2, "km²\n")
cat("2020:", surface_kinshasa_2020$surface_km2, "km²\n")
cat("Variation:", surface_kinshasa_2020$surface_km2 - surface_kinshasa_2017$surface_km2, "km²\n")

# 4.5 RÉPÉTER pour toutes les villes
resultats_surfaces <- data.frame()

for (i in 1:nrow(zones_urbaines)) {
  ville <- zones_urbaines[i, ]
  nom_ville <- ville$nom
  
  # Charger les rasters de zones bâties pour cette ville
  # (à adapter selon vos fichiers)
  
  surface_2017 <- calculer_surface_batie(
    raster_bati = rast(paste0("data/lulc/", nom_ville, "_baties_2017.tif")),
    zone_urbaine = ville,
    resolution_m = 10
  )
  
  surface_2020 <- calculer_surface_batie(
    raster_bati = rast(paste0("data/lulc/", nom_ville, "_baties_2020.tif")),
    zone_urbaine = ville,
    resolution_m = 10
  )
  
  resultats_surfaces <- rbind(resultats_surfaces, data.frame(
    ville = nom_ville,
    surface_2017_km2 = surface_2017$surface_km2,
    surface_2020_km2 = surface_2020$surface_km2
  ))
}

cat("✓ Surfaces bâties calculées\n")
```

---

### ÉTAPE 5 : CALCULER LA POPULATION PAR ZONE URBAINE

```r
# ============================================================
# ÉTAPE 5 : CALCUL DE LA POPULATION PAR ZONE URBAINE
# ============================================================

# 5.1 Fonction pour calculer la population
calculer_population <- function(raster_pop, zone_urbaine) {
  # Vérifier le CRS
  if (st_crs(zone_urbaine) != crs(raster_pop)) {
    stop("Les systèmes de coordonnées ne correspondent pas!")
  }
  
  # Extraire et sommer les valeurs de population
  # Les rasters WorldPop contiennent le nombre de personnes par pixel
  stats <- exact_extract(raster_pop, zone_urbaine, fun = 'sum', progress = FALSE)
  
  return(round(stats))
}

# 5.2 Calculer pour toutes les zones urbaines
pop_2017_utm <- rast("data/population/rdc_pop_2017_utm33s.tif")
pop_2020_utm <- rast("data/population/rdc_pop_2020_utm33s.tif")

resultats_population <- data.frame()

for (i in 1:nrow(zones_urbaines)) {
  ville <- zones_urbaines[i, ]
  nom_ville <- ville$nom
  
  pop_2017 <- calculer_population(pop_2017_utm, ville)
  pop_2020 <- calculer_population(pop_2020_utm, ville)
  
  resultats_population <- rbind(resultats_population, data.frame(
    ville = nom_ville,
    pop_2017 = pop_2017,
    pop_2020 = pop_2020
  ))
}

cat("✓ Population calculée\n")
print(resultats_population)
```

---

### ÉTAPE 6 : CALCULER L'INDICATEUR ODD 11.3.1

**Formules officielles selon le document :**

#### Land Consumption Rate (LCR)

$$LCR = \frac{\ln(\frac{V_{present}}{V_{past}})}{T} \times 100$$

Où :
- V_present = Surface bâtie à la fin de la période (km²)
- V_past = Surface bâtie au début de la période (km²)
- T = Nombre d'années dans la période d'analyse
- ln = Logarithme naturel

#### Population Growth Rate (PGR)

$$PGR = \frac{\ln(\frac{Pop_{t+n}}{Pop_t})}{Y} \times 100$$

Où :
- Pop_t+n = Population à la fin de la période
- Pop_t = Population au début de la période
- Y = Nombre d'années (identique à T)

#### Ratio LCR/PGR

$$Ratio = \frac{LCR}{PGR}$$

```r
# ============================================================
# ÉTAPE 6 : CALCUL DE L'INDICATEUR ODD 11.3.1
# ============================================================

# 6.1 Fonction de calcul conforme aux spécifications ONU-Habitat
calculer_odd_1131 <- function(surface_t1, surface_t2, pop_t1, pop_t2, nb_annees) {
  
  # VALIDATION DES DONNÉES
  # Vérifier que toutes les valeurs sont positives et non nulles
  if (any(c(surface_t1, surface_t2, pop_t1, pop_t2) <= 0)) {
    warning("Valeurs nulles ou négatives détectées")
    return(data.frame(
      LCR = NA, PGR = NA, ratio = NA,
      interpretation = "Données invalides"
    ))
  }
  
  # CALCUL DU TAUX DE CONSOMMATION DES TERRES (LCR)
  # Formule : LCR = [ln(V_present / V_past) / T] × 100
  LCR <- (log(surface_t2 / surface_t1) / nb_annees) * 100
  
  # CALCUL DU TAUX DE CROISSANCE DÉMOGRAPHIQUE (PGR)
  # Formule : PGR = [ln(Pop_t+n / Pop_t) / Y] × 100
  PGR <- (log(pop_t2 / pop_t1) / nb_annees) * 100
  
  # CALCUL DU RATIO
  # Formule : Ratio = LCR / PGR
  if (PGR == 0) {
    ratio <- NA
    interpretation <- "PGR nul - calcul impossible"
  } else {
    ratio <- LCR / PGR
    
    # INTERPRÉTATION selon les critères ONU-Habitat
    if (is.na(ratio) || is.infinite(ratio)) {
      interpretation <- "Calcul impossible"
    } else if (ratio > 1) {
      interpretation <- "Expansion urbaine (urban sprawl)"
    } else if (ratio < 1) {
      interpretation <- "Densification urbaine"
    } else {
      interpretation <- "Croissance proportionnelle"
    }
  }
  
  return(data.frame(
    LCR = round(LCR, 4),
    PGR = round(PGR, 4),
    ratio = round(ratio, 4),
    interpretation = interpretation
  ))
}

# 6.2 Combiner toutes les données
donnees_completes <- merge(resultats_surfaces, resultats_population, by = "ville")

# 6.3 Définir la période d'analyse
nb_annees <- 3  # 2017 à 2020 = 3 ans

# 6.4 Calculer l'indicateur pour chaque ville
resultats_odd <- data.frame()

for (i in 1:nrow(donnees_completes)) {
  ville_data <- donnees_completes[i, ]
  
  indicateur <- calculer_odd_1131(
    surface_t1 = ville_data$surface_2017_km2,
    surface_t2 = ville_data$surface_2020_km2,
    pop_t1 = ville_data$pop_2017,
    pop_t2 = ville_data$pop_2020,
    nb_annees = nb_annees
  )
  
  resultats_odd <- rbind(resultats_odd, cbind(
    ville = ville_data$ville,
    ville_data,
    indicateur
  ))
}

# 6.5 Afficher les résultats
cat("\n")
cat(strrep("=", 70), "\n")
cat("   RÉSULTATS ODD 11.3.1 - RDC (2017-2020)\n")
cat(strrep("=", 70), "\n\n")

print(resultats_odd, row.names = FALSE)

# 6.6 Sauvegarder
write.csv(resultats_odd, "output/resultats_odd_1131_rdc.csv", row.names = FALSE)

cat("\n✓ Indicateur ODD 11.3.1 calculé\n")
```

---

## PARTIE 3 : INDICATEURS SECONDAIRES

### ÉTAPE 7 : Calcul des indicateurs complémentaires

**Selon le document, deux indicateurs secondaires sont essentiels :**

#### 7.1 Surface bâtie par habitant (Built-up Area Per Capita)

**Formule :**
$$\text{Built-up per capita} = \frac{UrBU_t}{Pop_t}$$

Où :
- UrBU_t = Surface bâtie totale au temps t (en m²)
- Pop_t = Population au temps t

**Interprétation :**
- Valeurs élevées (>150 m²/hab) : Ville peu dense, potentiellement inefficace
- Valeurs moyennes (80-150 m²/hab) : Densité urbaine raisonnable
- Valeurs faibles (<80 m²/hab) : Ville très dense, possibles problèmes de surpeuplement

```r
# ============================================================
# ÉTAPE 7.1 : SURFACE BÂTIE PAR HABITANT
# ============================================================

# Calculer pour 2017 et 2020
resultats_odd$builtup_per_capita_2017 <- (resultats_odd$surface_2017_km2 * 1e6) / resultats_odd$pop_2017
resultats_odd$builtup_per_capita_2020 <- (resultats_odd$surface_2020_km2 * 1e6) / resultats_odd$pop_2020

cat("\nSurface bâtie par habitant (m²/personne):\n")
print(resultats_odd[, c("ville", "builtup_per_capita_2017", "builtup_per_capita_2020")])
```

#### 7.2 Variation totale de la surface bâtie (%)

**Formule :**
$$\text{Total change} = \frac{UrBU_{t+n} - UrBU_t}{UrBU_t} \times 100$$

```r
# ============================================================
# ÉTAPE 7.2 : VARIATION TOTALE DE LA SURFACE BÂTIE
# ============================================================

resultats_odd$variation_surface_pct <- ((resultats_odd$surface_2020_km2 - resultats_odd$surface_2017_km2) / 
                                         resultats_odd$surface_2017_km2) * 100

resultats_odd$variation_pop_pct <- ((resultats_odd$pop_2020 - resultats_odd$pop_2017) / 
                                     resultats_odd$pop_2017) * 100

cat("\nVariations en pourcentage:\n")
print(resultats_odd[, c("ville", "variation_surface_pct", "variation_pop_pct")])
```

---

## PARTIE 4 : REPORTING AVEC LE TEMPLATE ONU-HABITAT

### ÉTAPE 8 : Utiliser le template officiel de reporting

**Selon le document, UN-Habitat fournit un template Excel pour le calcul et le reporting.**

```r
# ============================================================
# ÉTAPE 8 : PRÉPARATION DES DONNÉES POUR LE TEMPLATE
# ============================================================

# Le template UN-Habitat nécessite les données suivantes :
# - Built up area within urban boundaries (km²) : T1 et T2
# - Total population within urban boundaries : T1 et T2
# - T (Number of years between analysis cycles)

# Préparer les données au format requis
template_data <- resultats_odd[, c(
  "ville",
  "surface_2017_km2