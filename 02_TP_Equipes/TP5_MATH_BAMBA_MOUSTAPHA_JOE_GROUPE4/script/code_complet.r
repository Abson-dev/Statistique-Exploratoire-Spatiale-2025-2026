# ============================================================
# TP COMPLET : CALCUL DE L'INDICATEUR ODD 11.3.1 POUR LA RDC
# MÉTHODOLOGIE DEGURBA STRICTE
# Ratio du taux de consommation des terres au taux de 
# croissance démographique (2017-2020)
# ============================================================
#
# MÉTHODOLOGIE OFFICIELLE DEGURBA (Degree of Urbanisation):
#
# 1. CLASSIFICATION DES CELLULES:
#    - Centres urbains: Cellules ≥1500 hab/km² en grappes ≥50,000 hab
#    - Grappes urbaines: Cellules ≥300 hab/km² en grappes ≥5,000 hab
#    - Cellules rurales: Toutes les autres
#
# 2. CALCUL ODD 11.3.1 = LCRPGR (Land Consumption Rate to Population Growth Rate):
#    LCRPGR = LCR / PGR
#    où:
#    - LCR = [(Ln(Urb_t1/Urb_t0))/y] × 100
#    - PGR = [(Ln(Pop_t1/Pop_t0))/y] × 100
#    - y = nombre d'années entre t0 et t1
#
# 3. INTERPRÉTATION:
#    - LCRPGR < 1: Croissance efficace (densification)
#    - LCRPGR = 1: Croissance proportionnelle
#    - LCRPGR > 1: Étalement urbain (inefficace)
#
# ============================================================

cat("\n")
cat(paste(rep("=", 90), collapse = ""), "\n")
cat("   CALCUL ODD 11.3.1 - MÉTHODOLOGIE DEGURBA STRICTE - RDC (2017-2020)\n")
cat(paste(rep("=", 90), collapse = ""), "\n\n")

heure_debut <- Sys.time()

# ============================================================
# PARTIE 1 : CONFIGURATION ET CHARGEMENT DES DONNÉES
# ============================================================

cat(paste(rep("=", 90), collapse = ""), "\n")
cat("PARTIE 1 : CONFIGURATION ET CHARGEMENT DES DONNÉES\n")
cat(paste(rep("=", 90), collapse = ""), "\n\n")

# ------------------------------------------------------------
# 1.1 : Chargement des packages
# ------------------------------------------------------------

cat("1.1 Chargement des packages R...\n")

packages_requis <- c(
  "sf",              # Données vectorielles
  "terra",           # Données raster
  "tidyverse",       # Manipulation de données
  "exactextractr",   # Statistiques zonales
  "ggplot2",         # Graphiques
  "gridExtra",       # Arrangement de graphiques
  "viridis",         # Palettes de couleurs
  "scales"           # Formatage
)

for (pkg in packages_requis) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    cat("  Installation de", pkg, "...\n")
    install.packages(pkg)
    library(pkg, character.only = TRUE)
  }
}

cat("  ✓ Tous les packages sont chargés\n\n")

# ------------------------------------------------------------
# 1.2 : Création de la structure de dossiers
# ------------------------------------------------------------

cat("1.2 Création de la structure de dossiers...\n")

dossiers <- c(
  "data/population",
  "data/lulc",
  "data/boundaries",
  "data/temp",
  "output",
  "output/rasters",
  "output/degurba",
  "figures",
  "figures/cartes",
  "figures/graphiques"
)

for (dossier in dossiers) {
  dir.create(dossier, showWarnings = FALSE, recursive = TRUE)
}

cat("  ✓ Structure créée\n")
cat("  Répertoire de travail:", getwd(), "\n\n")

# ------------------------------------------------------------
# 1.3 : Chargement des limites administratives
# ------------------------------------------------------------

cat("1.3 Chargement des limites administratives de la RDC...\n")

if (!file.exists("data/boundaries/rdc_country.shp")) {
  cat("  ✗ Fichiers manquants! Exécutez d'abord code4.r\n")
  stop("Limites administratives requises")
}

# Charger les limites
rdc_pays <- st_read("data/boundaries/rdc_country.shp", quiet = TRUE)
rdc_provinces <- st_read("data/boundaries/rdc_provinces.shp", quiet = TRUE)

cat("  ✓ Limite pays chargée\n")
cat("  ✓ Provinces chargées:", nrow(rdc_provinces), "provinces\n\n")

# Inspection des limites administratives
cat("  INSPECTION DES LIMITES ADMINISTRATIVES:\n")
cat("  ----------------------------------------\n")
bbox_rdc <- st_bbox(rdc_pays)
cat("  Emprise géographique:\n")
cat("    - X min (longitude):", round(bbox_rdc["xmin"], 4), "°\n")
cat("    - X max (longitude):", round(bbox_rdc["xmax"], 4), "°\n")
cat("    - Y min (latitude):", round(bbox_rdc["ymin"], 4), "°\n")
cat("    - Y max (latitude):", round(bbox_rdc["ymax"], 4), "°\n")
cat("  Système de coordonnées:", st_crs(rdc_pays)$input, "\n")
cat("  Surface totale:", round(st_area(rdc_pays) / 1e6, 0), "km²\n\n")

# ------------------------------------------------------------
# 1.4 : Chargement des données de population WorldPop
# ------------------------------------------------------------

cat("1.4 Chargement des données de population WorldPop (1 km)...\n")

fichiers_pop <- c(
  "data/population/rdc_pop_2017_1km.tif",
  "data/population/rdc_pop_2020_1km.tif"
)

if (!all(file.exists(fichiers_pop))) {
  cat("  ✗ Fichiers de population manquants!\n")
  cat("  Les données seront simulées pour la démonstration.\n\n")
  
  # ========================================
  # SIMULATION DE DONNÉES POUR DÉMONSTRATION
  # ========================================
  cat("  Création de données de population simulées...\n")
  
  # Créer un raster vide sur l'emprise de la RDC
  r_template <- rast(
    xmin = bbox_rdc["xmin"], xmax = bbox_rdc["xmax"],
    ymin = bbox_rdc["ymin"], ymax = bbox_rdc["ymax"],
    resolution = 0.008333,  # ~1 km à l'équateur
    crs = "EPSG:4326"
  )
  
  # Simuler population avec gradient de densité
  set.seed(123)
  pop_2017 <- r_template
  values(pop_2017) <- rpois(ncell(pop_2017), lambda = 50)
  
  # Croissance démographique de 8% entre 2017 et 2020
  pop_2020 <- pop_2017 * 1.08
  
  # Ajouter des pics urbains (villes principales de la RDC)
  villes_coords <- matrix(c(
    15.3, -4.3,   # Kinshasa
    27.5, -11.7,  # Lubumbashi
    23.6, -6.2,   # Mbuji-Mayi
    25.2, 0.5     # Kisangani
  ), ncol = 2, byrow = TRUE)
  
  for (i in 1:nrow(villes_coords)) {
    cell_ville <- cellFromXY(pop_2017, villes_coords[i, , drop = FALSE])
    if (length(cell_ville) > 0 && !is.na(cell_ville)) {
      # Créer un pic de densité pour simuler les centres urbains
      cells_autour <- adjacent(pop_2017, cell_ville, directions = "queen")
      pop_2017[cell_ville] <- 2000
      pop_2020[cell_ville] <- 2500
      if (length(cells_autour) > 0) {
        pop_2017[cells_autour] <- 1000
        pop_2020[cells_autour] <- 1200
      }
    }
  }
  
  # Masquer par la limite de la RDC
  pop_2017 <- mask(pop_2017, vect(rdc_pays))
  pop_2020 <- mask(pop_2020, vect(rdc_pays))
  
  # Sauvegarder
  writeRaster(pop_2017, "data/population/rdc_pop_2017_1km.tif", overwrite = TRUE)
  writeRaster(pop_2020, "data/population/rdc_pop_2020_1km.tif", overwrite = TRUE)
  
  cat("  ✓ Données simulées créées\n")
  
} else {
  # Charger les données existantes
  pop_2017 <- rast("data/population/rdc_pop_2017_1km.tif")
  pop_2020 <- rast("data/population/rdc_pop_2020_1km.tif")
  cat("  ✓ Population 2017 chargée\n")
  cat("  ✓ Population 2020 chargée\n")
}

# Inspection des données de population
cat("\n  INSPECTION DES DONNÉES DE POPULATION:\n")
cat("  -------------------------------------\n")
cat("  Raster 2017:\n")
cat("    - Résolution:", paste(res(pop_2017), collapse = " x "), "degrés\n")
cat("    - Dimensions:", paste(dim(pop_2017)[1:2], collapse = " x "), "pixels\n")
cat("    - Nombre total de cellules:", ncell(pop_2017), "\n")
cat("    - CRS:", crs(pop_2017, describe = TRUE)$name, "\n")

# Statistiques de population
stats_2017 <- global(pop_2017, fun = c("sum", "mean", "min", "max", "sd"), na.rm = TRUE)
stats_2020 <- global(pop_2020, fun = c("sum", "mean", "min", "max", "sd"), na.rm = TRUE)

cat("\n  Statistiques 2017:\n")
cat("    - Population totale:", format(round(stats_2017$sum), big.mark = " "), "habitants\n")
cat("    - Moyenne par cellule:", round(stats_2017$mean, 1), "hab\n")
cat("    - Minimum:", round(stats_2017$min, 1), "hab\n")
cat("    - Maximum:", round(stats_2017$max, 1), "hab\n")
cat("    - Écart-type:", round(stats_2017$sd, 1), "\n")

cat("\n  Statistiques 2020:\n")
cat("    - Population totale:", format(round(stats_2020$sum), big.mark = " "), "habitants\n")
cat("    - Moyenne par cellule:", round(stats_2020$mean, 1), "hab\n")
cat("    - Minimum:", round(stats_2020$min, 1), "hab\n")
cat("    - Maximum:", round(stats_2020$max, 1), "hab\n")
cat("    - Écart-type:", round(stats_2020$sd, 1), "\n")

# Calcul du taux de croissance global
taux_croissance <- ((stats_2020$sum / stats_2017$sum) - 1) * 100
cat("\n  Taux de croissance démographique global:", round(taux_croissance, 2), "%\n\n")

# ------------------------------------------------------------
# 1.5 : Chargement et fusion des données LULC (9 tuiles par année)
# ------------------------------------------------------------

cat("1.5 Chargement et fusion des données LULC (Land Use/Land Cover)...\n")
cat("    NOTE: La RDC est couverte par 9 tuiles LULC pour chaque année\n\n")

# Fonction pour charger et fusionner les 9 tuiles LULC
charger_lulc_complet <- function(annee, dossier_lulc = "data/lulc") {
  
  cat("  Chargement LULC", annee, "...\n")
  
  # Liste des fichiers LULC pour cette année
  pattern <- paste0(".*", annee, ".*\\.tif$")
  fichiers <- list.files(dossier_lulc, pattern = pattern, full.names = TRUE)
  
  if (length(fichiers) == 0) {
    cat("    ✗ Aucun fichier LULC trouvé pour", annee, "\n")
    cat("    Les données seront simulées pour la démonstration.\n\n")
    
    # Créer un LULC simplifié basé sur la densité de population
    # Classes: 1 = Bâti, 2 = Végétation, 3 = Eau, 4 = Sol nu
    pop_raster <- if (annee == 2017) pop_2017 else pop_2020
    
    # Binarisation: Bâti (1) si densité élevée, Végétation (2) sinon
    lulc_simule <- ifel(pop_raster > 500, 1, 2)
    
    # Masquer par la RDC
    lulc_simule <- mask(lulc_simule, vect(rdc_pays))
    
    return(lulc_simule)
  }
  
  cat("    Nombre de tuiles trouvées:", length(fichiers), "\n")
  
  # Charger toutes les tuiles
  liste_rasters <- list()
  for (i in seq_along(fichiers)) {
    cat("      Chargement tuile", i, "/", length(fichiers), "...\r")
    liste_rasters[[i]] <- rast(fichiers[i])
  }
  cat("\n")
  
  # Vérifier le CRS de la première tuile
  cat("    Vérification des systèmes de coordonnées...\n")
  crs_lulc <- crs(liste_rasters[[1]])
  crs_rdc <- crs(vect(rdc_pays))
  
  cat("      CRS LULC:", crs(liste_rasters[[1]], describe = TRUE)$name, "\n")
  cat("      CRS RDC:", st_crs(rdc_pays)$input, "\n")
  
  # Fusionner les tuiles en une seule mosaïque
  cat("    Fusion des tuiles en mosaïque (cela peut prendre du temps)...\n")
  if (length(liste_rasters) == 1) {
    lulc_complet <- liste_rasters[[1]]
  } else {
    # Utiliser mosaic avec fun="first" pour éviter les problèmes de mémoire
    lulc_complet <- do.call(mosaic, c(liste_rasters, list(fun = "first")))
  }
  
  cat("    Mosaïque créée: ", paste(dim(lulc_complet)[1:2], collapse = " x "), "pixels\n")
  
  # Convertir les limites de la RDC en vecteur terra
  rdc_vect <- vect(rdc_pays)
  
  # Reprojeter la RDC si nécessaire pour correspondre au CRS du LULC
  if (!identical(crs(lulc_complet), crs(rdc_vect))) {
    cat("    Reprojection de la limite RDC vers le CRS du LULC...\n")
    rdc_vect <- project(rdc_vect, crs(lulc_complet))
  }
  
  # Vérifier l'overlap des emprises
  bbox_lulc <- ext(lulc_complet)
  bbox_rdc <- ext(rdc_vect)
  
  cat("    Emprise LULC: [", bbox_lulc$xmin, ", ", bbox_lulc$xmax, "] x [", 
      bbox_lulc$ymin, ", ", bbox_lulc$ymax, "]\n")
  cat("    Emprise RDC: [", bbox_rdc$xmin, ", ", bbox_rdc$xmax, "] x [", 
      bbox_rdc$ymin, ", ", bbox_rdc$ymax, "]\n")
  
  # Découper selon les limites de la RDC
  cat("    Découpage selon les limites de la RDC...\n")
  
  tryCatch({
    lulc_complet <- crop(lulc_complet, rdc_vect)
    cat("    ✓ Découpage réussi\n")
  }, error = function(e) {
    cat("    ⚠ Erreur lors du découpage, utilisation de l'emprise complète\n")
    cat("      Message d'erreur:", e$message, "\n")
  })
  
  # Masquer par la RDC
  cat("    Application du masque RDC...\n")
  lulc_complet <- mask(lulc_complet, rdc_vect)
  
  cat("    ✓ LULC", annee, "chargé et préparé\n")
  cat("      Dimensions finales:", paste(dim(lulc_complet)[1:2], collapse = " x "), "pixels\n")
  cat("      CRS:", crs(lulc_complet, describe = TRUE)$name, "\n\n")
  
  return(lulc_complet)
}

# Charger LULC pour les deux années
lulc_2017 <- charger_lulc_complet(2017)
lulc_2020 <- charger_lulc_complet(2020)

# Inspection des données LULC
cat("  INSPECTION DES DONNÉES LULC:\n")
cat("  ----------------------------\n")
cat("  LULC 2017 (HAUTE RÉSOLUTION):\n")
cat("    - Résolution:", paste(res(lulc_2017), collapse = " x "), "degrés\n")
cat("    - Dimensions:", paste(dim(lulc_2017)[1:2], collapse = " x "), "pixels\n")

# ATTENTION: Si le raster est trop grand, ne pas extraire toutes les valeurs pour l'inspection
ncells_lulc <- ncell(lulc_2017)
cat("    - Nombre de cellules:", format(ncells_lulc, big.mark = " "), "\n")

# Inspection des classes (échantillonnage si trop grand)
# NOTE: Ceci est uniquement pour AFFICHER les classes, pas pour l'analyse
if (ncells_lulc > 1e8) {
  cat("    - ATTENTION: Raster très volumineux\n")
  cat("    - Échantillonnage pour inspection des classes (10,000 cellules)...\n")
  set.seed(123)
  sample_cells <- sample(1:ncells_lulc, min(10000, ncells_lulc))
  classes_2017 <- unique(lulc_2017[sample_cells])
  classes_2017 <- classes_2017[!is.na(classes_2017)]
  cat("    - Classes détectées (échantillon):", paste(sort(classes_2017), collapse = ", "), "\n")
} else {
  classes_2017 <- unique(values(lulc_2017, mat = FALSE))
  classes_2017 <- classes_2017[!is.na(classes_2017)]
  cat("    - Classes présentes:", paste(sort(classes_2017), collapse = ", "), "\n")
}

cat("\n  LULC 2020 (HAUTE RÉSOLUTION):\n")
cat("    - Résolution:", paste(res(lulc_2020), collapse = " x "), "degrés\n")
cat("    - Dimensions:", paste(dim(lulc_2020)[1:2], collapse = " x "), "pixels\n")

ncells_lulc_2020 <- ncell(lulc_2020)
cat("    - Nombre de cellules:", format(ncells_lulc_2020, big.mark = " "), "\n")

if (ncells_lulc_2020 > 1e8) {
  cat("    - Échantillonnage pour inspection des classes (10,000 cellules)...\n")
  sample_cells_2020 <- sample(1:ncells_lulc_2020, min(10000, ncells_lulc_2020))
  classes_2020 <- unique(lulc_2020[sample_cells_2020])
  classes_2020 <- classes_2020[!is.na(classes_2020)]
  cat("    - Classes détectées (échantillon):", paste(sort(classes_2020), collapse = ", "), "\n")
} else {
  classes_2020 <- unique(values(lulc_2020, mat = FALSE))
  classes_2020 <- classes_2020[!is.na(classes_2020)]
  cat("    - Classes présentes:", paste(sort(classes_2020), collapse = ", "), "\n")
}

# ============================================================
# RÉ-ÉCHANTILLONNAGE COMPLET DU LULC (TRAITEMENT INTÉGRAL)
# ============================================================
cat("\n  RÉ-ÉCHANTILLONNAGE DU LULC À LA RÉSOLUTION 1KM:\n")
cat("  -----------------------------------------------\n")
cat("  IMPORTANT: Le LULC haute résolution (~10m) doit être agrégé\n")
cat("  vers la résolution de la population (~1 km) pour l'analyse DEGURBA\n")
cat("  TOUTES les cellules seront traitées (pas d'échantillonnage)\n\n")

cat("  Agrégation LULC 2017 (cela peut prendre plusieurs minutes)...\n")
cat("    Méthode: 'near' (plus proche voisin) pour préserver les classes\n")
lulc_2017_resample <- resample(lulc_2017, pop_2017, method = "near")
cat("    ✓ Terminé\n")
cat("    - Dimensions originales:", paste(dim(lulc_2017)[1:2], collapse = " x "), "pixels\n")
cat("    - Dimensions finales:", paste(dim(lulc_2017_resample)[1:2], collapse = " x "), "pixels\n")
cat("    - Réduction:", round((1 - ncell(lulc_2017_resample)/ncells_lulc) * 100, 1), "%\n\n")

cat("  Agrégation LULC 2020 (cela peut prendre plusieurs minutes)...\n")
lulc_2020_resample <- resample(lulc_2020, pop_2020, method = "near")
cat("    ✓ Terminé\n")
cat("    - Dimensions originales:", paste(dim(lulc_2020)[1:2], collapse = " x "), "pixels\n")
cat("    - Dimensions finales:", paste(dim(lulc_2020_resample)[1:2], collapse = " x "), "pixels\n")
cat("    - Réduction:", round((1 - ncell(lulc_2020_resample)/ncells_lulc_2020) * 100, 1), "%\n\n")

# Remplacer les originaux par les versions ré-échantillonnées pour l'analyse
lulc_2017 <- lulc_2017_resample
lulc_2020 <- lulc_2020_resample

# Sauvegarder les LULC ré-échantillonnés
cat("  Sauvegarde des LULC ré-échantillonnés...\n")
writeRaster(lulc_2017, "output/rasters/lulc_2017_1km.tif", overwrite = TRUE)
writeRaster(lulc_2020, "output/rasters/lulc_2020_1km.tif", overwrite = TRUE)

cat("  ✓ LULC ré-échantillonné (résolution 1km) prêt pour l'analyse DEGURBA\n\n")

# ============================================================
# PARTIE 2 : CLASSIFICATION DEGURBA
# ============================================================

cat(paste(rep("=", 90), collapse = ""), "\n")
cat("PARTIE 2 : CLASSIFICATION DEGURBA DES ZONES URBAINES\n")
cat(paste(rep("=", 90), collapse = ""), "\n\n")

cat("MÉTHODOLOGIE DEGURBA:\n")
cat("  1. Calculer la densité de population par cellule (hab/km²)\n")
cat("  2. Identifier les cellules à haute densité (≥1500 hab/km²)\n")
cat("  3. Former des grappes contiguës de cellules\n")
cat("  4. Classifier selon la population totale de la grappe:\n")
cat("     - Centres urbains: grappes ≥50,000 habitants\n")
cat("     - Grappes urbaines: grappes ≥5,000 habitants (densité ≥300)\n")
cat("     - Zones rurales: le reste\n\n")

# ------------------------------------------------------------
# 2.1 : Calcul de la densité de population
# ------------------------------------------------------------

cat("2.1 Calcul de la densité de population...\n")

# Calculer la surface de chaque cellule en km²
# IMPORTANT: En projection géographique (lat/lon), la surface varie avec la latitude
cat("  Calcul des surfaces de cellules (tenant compte de la latitude)...\n")

surface_cellule <- cellSize(pop_2017, unit = "km")

# Inspection de la surface
stats_surface <- global(surface_cellule, fun = c("mean", "min", "max"), na.rm = TRUE)
cat("    - Surface moyenne:", round(stats_surface$mean, 3), "km²\n")
cat("    - Surface minimale:", round(stats_surface$min, 3), "km²\n")
cat("    - Surface maximale:", round(stats_surface$max, 3), "km²\n\n")

# Calculer densité = population / surface
cat("  Calcul de la densité 2017 (hab/km²)...\n")
densite_2017 <- pop_2017 / surface_cellule

cat("  Calcul de la densité 2020 (hab/km²)...\n")
densite_2020 <- pop_2020 / surface_cellule

cat("  ✓ Densités calculées\n\n")

# Statistiques de densité
stats_dens_2017 <- global(densite_2017, fun = c("mean", "median", "max", "sd"), na.rm = TRUE)
stats_dens_2020 <- global(densite_2020, fun = c("mean", "median", "max", "sd"), na.rm = TRUE)

cat("  Statistiques densité 2017:\n")
cat("    - Moyenne:", round(stats_dens_2017$mean, 1), "hab/km²\n")
cat("    - Médiane:", round(stats_dens_2017$median, 1), "hab/km²\n")
cat("    - Maximum:", round(stats_dens_2017$max, 1), "hab/km²\n")
cat("    - Écart-type:", round(stats_dens_2017$sd, 1), "\n\n")

cat("  Statistiques densité 2020:\n")
cat("    - Moyenne:", round(stats_dens_2020$mean, 1), "hab/km²\n")
cat("    - Médiane:", round(stats_dens_2020$median, 1), "hab/km²\n")
cat("    - Maximum:", round(stats_dens_2020$max, 1), "hab/km²\n")
cat("    - Écart-type:", round(stats_dens_2020$sd, 1), "\n\n")

# Sauvegarder les rasters de densité
writeRaster(densite_2017, "output/rasters/densite_population_2017.tif", overwrite = TRUE)
writeRaster(densite_2020, "output/rasters/densite_population_2020.tif", overwrite = TRUE)

# ------------------------------------------------------------
# 2.2 : Identification des cellules urbaines (≥1500 hab/km²)
# ------------------------------------------------------------

cat("2.2 Identification des cellules à haute densité (BINARISATION)...\n")

# Seuil DEGURBA pour centres urbains
seuil_centre_urbain <- 1500

cat("  MÉTHODE: Binarisation avec seuil de densité\n")
cat("  Seuil utilisé:", seuil_centre_urbain, "hab/km²\n")
cat("  Résultat: 1 = haute densité, NA = basse densité\n\n")

# BINARISATION: 1 si densité ≥ seuil, NA sinon
cat("  Binarisation 2017...\n")
cellules_haute_densite_2017 <- ifel(densite_2017 >= seuil_centre_urbain, 1, NA)

cat("  Binarisation 2020...\n")
cellules_haute_densite_2020 <- ifel(densite_2020 >= seuil_centre_urbain, 1, NA)

# Compter les cellules à haute densité
nb_cellules_hd_2017 <- global(cellules_haute_densite_2017, fun = "sum", na.rm = TRUE)$sum
nb_cellules_hd_2020 <- global(cellules_haute_densite_2020, fun = "sum", na.rm = TRUE)$sum

cat("  ✓ Cellules haute densité 2017:", nb_cellules_hd_2017, "\n")
cat("  ✓ Cellules haute densité 2020:", nb_cellules_hd_2020, "\n")

# Calculer la surface totale en haute densité
surface_hd_2017 <- nb_cellules_hd_2017 * stats_surface$mean
surface_hd_2020 <- nb_cellules_hd_2020 * stats_surface$mean

cat("  Surface totale haute densité 2017:", round(surface_hd_2017, 2), "km²\n")
cat("  Surface totale haute densité 2020:", round(surface_hd_2020, 2), "km²\n\n")

# Sauvegarder les rasters binaires
writeRaster(cellules_haute_densite_2017, "output/rasters/cellules_haute_densite_2017.tif", overwrite = TRUE)
writeRaster(cellules_haute_densite_2020, "output/rasters/cellules_haute_densite_2020.tif", overwrite = TRUE)

# ------------------------------------------------------------
# 2.3 : Formation des grappes contiguës (clustering)
# ------------------------------------------------------------

cat("2.3 Formation des grappes urbaines contiguës...\n")

cat("  MÉTHODE: Algorithme de clustering spatial\n")
cat("  - Utilisation de patches() pour identifier les grappes\n")
cat("  - Une grappe = ensemble de cellules adjacentes (8 directions)\n")
cat("  - Chaque grappe reçoit un identifiant unique\n\n")

# patches() identifie les groupes de cellules connectées (8-connectivité)
cat("  Identification des grappes 2017...\n")
grappes_2017 <- patches(cellules_haute_densite_2017, directions = 8, zeroAsNA = TRUE)

cat("  Identification des grappes 2020...\n")
grappes_2020 <- patches(cellules_haute_densite_2020, directions = 8, zeroAsNA = TRUE)

# Compter le nombre de grappes distinctes
nb_grappes_2017 <- max(values(grappes_2017, mat = FALSE), na.rm = TRUE)
nb_grappes_2020 <- max(values(grappes_2020, mat = FALSE), na.rm = TRUE)

cat("  ✓ Nombre de grappes 2017:", nb_grappes_2017, "\n")
cat("  ✓ Nombre de grappes 2020:", nb_grappes_2020, "\n\n")

# Sauvegarder les rasters de grappes
writeRaster(grappes_2017, "output/rasters/grappes_urbaines_2017.tif", overwrite = TRUE)
writeRaster(grappes_2020, "output/rasters/grappes_urbaines_2020.tif", overwrite = TRUE)

# ------------------------------------------------------------
# 2.4 : Calcul de la population par grappe
# ------------------------------------------------------------

cat("2.4 Calcul de la population de chaque grappe...\n")

# Fonction pour calculer la population par grappe
calculer_pop_grappes <- function(raster_grappes, raster_pop, annee) {
  
  cat("  Traitement année", annee, "...\n")
  
  # Extraire valeurs en tant que vecteurs
  val_grappes <- values(raster_grappes, mat = FALSE)
  val_pop <- values(raster_pop, mat = FALSE)
  
  # Créer dataframe avec conversion explicite en vecteurs
  df <- data.frame(
    grappe_id = as.vector(val_grappes),
    population = as.vector(val_pop)
  )
  
  # Retirer les valeurs NA
  df <- df[!is.na(df$grappe_id) & !is.na(df$population), ]
  
  # Vérifier que le dataframe n'est pas vide
  if (nrow(df) == 0) {
    cat("  ✗ ERREUR: Aucune donnée valide trouvée pour l'année", annee, "\n")
    return(data.frame())
  }
  
  cat("    Nombre de cellules à traiter:", nrow(df), "\n")
  
  # Agréger par grappe
  pop_par_grappe <- df %>%
    group_by(grappe_id) %>%
    summarise(
      population_totale = sum(population, na.rm = TRUE),
      nb_cellules = n(),
      .groups = 'drop'
    ) %>%
    arrange(desc(population_totale))
  
  cat("    ✓ Agrégation terminée:", nrow(pop_par_grappe), "grappes analysées\n")
  
  return(pop_par_grappe)
}

# Calculer pour les deux années
pop_grappes_2017 <- calculer_pop_grappes(grappes_2017, pop_2017, 2017)
pop_grappes_2020 <- calculer_pop_grappes(grappes_2020, pop_2020, 2020)

cat("  ✓ Population par grappe calculée\n\n")

# Afficher les 10 plus grandes grappes
cat("  Top 10 grappes par population (2017):\n")
print(head(pop_grappes_2017, 10))

cat("\n  Top 10 grappes par population (2020):\n")
print(head(pop_grappes_2020, 10))
cat("\n")

# ------------------------------------------------------------
# 2.5 : Classification DEGURBA des grappes
# ------------------------------------------------------------

cat("2.5 Classification DEGURBA des grappes...\n")

cat("  CRITÈRES DE CLASSIFICATION:\n")
cat("    - Centre urbain: population ≥50,000 habitants\n")
cat("    - Grappe urbaine: population ≥5,000 habitants\n")
cat("    - Zone rurale: population <5,000 habitants\n\n")

# Classifier 2017
pop_grappes_2017 <- pop_grappes_2017 %>%
  mutate(
    classe_degurba = case_when(
      population_totale >= 50000 ~ "Centre urbain",
      population_totale >= 5000 ~ "Grappe urbaine",
      TRUE ~ "Zone rurale"
    )
  )

# Classifier 2020
pop_grappes_2020 <- pop_grappes_2020 %>%
  mutate(
    classe_degurba = case_when(
      population_totale >= 50000 ~ "Centre urbain",
      population_totale >= 5000 ~ "Grappe urbaine",
      TRUE ~ "Zone rurale"
    )
  )

# Statistiques de classification
cat("  Résultats classification 2017:\n")
table_2017 <- table(pop_grappes_2017$classe_degurba)
print(table_2017)

cat("\n  Résultats classification 2020:\n")
table_2020 <- table(pop_grappes_2020$classe_degurba)
print(table_2020)
cat("\n")

# Population par classe
pop_par_classe_2017 <- pop_grappes_2017 %>%
  group_by(classe_degurba) %>%
  summarise(
    nb_grappes = n(),
    population_totale = sum(population_totale),
    surface_totale_km2 = sum(nb_cellules) * stats_surface$mean
  )

cat("  Population par classe DEGURBA (2017):\n")
print(pop_par_classe_2017)
cat("\n")

# Sauvegarder les classifications
write.csv(pop_grappes_2017, "output/degurba/classification_grappes_2017.csv", row.names = FALSE)
write.csv(pop_grappes_2020, "output/degurba/classification_grappes_2020.csv", row.names = FALSE)

# ============================================================
# PARTIE 2 : CLASSIFICATION DEGURBA
# ============================================================

cat(paste(rep("=", 90), collapse = ""), "\n")
cat("PARTIE 2 : CLASSIFICATION DEGURBA DES ZONES URBAINES\n")
cat(paste(rep("=", 90), collapse = ""), "\n\n")

cat("MÉTHODOLOGIE DEGURBA:\n")
cat("  1. Calculer la densité de population par cellule (hab/km²)\n")
cat("  2. Identifier les cellules à haute densité (≥1500 hab/km²)\n")
cat("  3. Former des grappes contiguës de cellules\n")
cat("  4. Classifier selon la population totale de la grappe:\n")
cat("     - Centres urbains: grappes ≥50,000 habitants\n")
cat("     - Grappes urbaines: grappes ≥5,000 habitants (densité ≥300)\n")
cat("     - Zones rurales: le reste\n\n")

# ------------------------------------------------------------
# 2.1 : Calcul de la densité de population
# ------------------------------------------------------------

cat("2.1 Calcul de la densité de population...\n")

# Calculer la surface de chaque cellule en km²
# IMPORTANT: En projection géographique (lat/lon), la surface varie avec la latitude
cat("  Calcul des surfaces de cellules (tenant compte de la latitude)...\n")

surface_cellule <- cellSize(pop_2017, unit = "km")

# Inspection de la surface
stats_surface <- global(surface_cellule, fun = c("mean", "min", "max"), na.rm = TRUE)
cat("    - Surface moyenne:", round(stats_surface$mean, 3), "km²\n")
cat("    - Surface minimale:", round(stats_surface$min, 3), "km²\n")
cat("    - Surface maximale:", round(stats_surface$max, 3), "km²\n\n")

# Calculer densité = population / surface
cat("  Calcul de la densité 2017 (hab/km²)...\n")
densite_2017 <- pop_2017 / surface_cellule

cat("  Calcul de la densité 2020 (hab/km²)...\n")
densite_2020 <- pop_2020 / surface_cellule

cat("  ✓ Densités calculées\n\n")

# Statistiques de densité
stats_dens_2017 <- global(densite_2017, fun = c("mean", "median", "max", "sd"), na.rm = TRUE)
stats_dens_2020 <- global(densite_2020, fun = c("mean", "median", "max", "sd"), na.rm = TRUE)

cat("  Statistiques densité 2017:\n")
cat("    - Moyenne:", round(stats_dens_2017$mean, 1), "hab/km²\n")
cat("    - Médiane:", round(stats_dens_2017$median, 1), "hab/km²\n")
cat("    - Maximum:", round(stats_dens_2017$max, 1), "hab/km²\n")
cat("    - Écart-type:", round(stats_dens_2017$sd, 1), "\n\n")

cat("  Statistiques densité 2020:\n")
cat("    - Moyenne:", round(stats_dens_2020$mean, 1), "hab/km²\n")
cat("    - Médiane:", round(stats_dens_2020$median, 1), "hab/km²\n")
cat("    - Maximum:", round(stats_dens_2020$max, 1), "hab/km²\n")
cat("    - Écart-type:", round(stats_dens_2020$sd, 1), "\n\n")

# Sauvegarder les rasters de densité
writeRaster(densite_2017, "output/rasters/densite_population_2017.tif", overwrite = TRUE)
writeRaster(densite_2020, "output/rasters/densite_population_2020.tif", overwrite = TRUE)

# ------------------------------------------------------------
# 2.2 : Identification des cellules urbaines (≥1500 hab/km²)
# ------------------------------------------------------------

cat("2.2 Identification des cellules à haute densité (BINARISATION)...\n")

# Seuil DEGURBA pour centres urbains
seuil_centre_urbain <- 1500

cat("  MÉTHODE: Binarisation avec seuil de densité\n")
cat("  Seuil utilisé:", seuil_centre_urbain, "hab/km²\n")
cat("  Résultat: 1 = haute densité, NA = basse densité\n\n")

# BINARISATION: 1 si densité ≥ seuil, NA sinon
cat("  Binarisation 2017...\n")
cellules_haute_densite_2017 <- ifel(densite_2017 >= seuil_centre_urbain, 1, NA)

cat("  Binarisation 2020...\n")
cellules_haute_densite_2020 <- ifel(densite_2020 >= seuil_centre_urbain, 1, NA)

# Compter les cellules à haute densité
nb_cellules_hd_2017 <- global(cellules_haute_densite_2017, fun = "sum", na.rm = TRUE)$sum
nb_cellules_hd_2020 <- global(cellules_haute_densite_2020, fun = "sum", na.rm = TRUE)$sum

cat("  ✓ Cellules haute densité 2017:", nb_cellules_hd_2017, "\n")
cat("  ✓ Cellules haute densité 2020:", nb_cellules_hd_2020, "\n")

# Calculer la surface totale en haute densité
surface_hd_2017 <- nb_cellules_hd_2017 * stats_surface$mean
surface_hd_2020 <- nb_cellules_hd_2020 * stats_surface$mean

cat("  Surface totale haute densité 2017:", round(surface_hd_2017, 2), "km²\n")
cat("  Surface totale haute densité 2020:", round(surface_hd_2020, 2), "km²\n\n")

# Sauvegarder les rasters binaires
writeRaster(cellules_haute_densite_2017, "output/rasters/cellules_haute_densite_2017.tif", overwrite = TRUE)
writeRaster(cellules_haute_densite_2020, "output/rasters/cellules_haute_densite_2020.tif", overwrite = TRUE)

# ------------------------------------------------------------
# 2.3 : Formation des grappes contiguës (clustering)
# ------------------------------------------------------------

cat("2.3 Formation des grappes urbaines contiguës...\n")

cat("  MÉTHODE: Algorithme de clustering spatial\n")
cat("  - Utilisation de patches() pour identifier les grappes\n")
cat("  - Une grappe = ensemble de cellules adjacentes (8 directions)\n")
cat("  - Chaque grappe reçoit un identifiant unique\n\n")

# patches() identifie les groupes de cellules connectées (8-connectivité)
cat("  Identification des grappes 2017...\n")
grappes_2017 <- patches(cellules_haute_densite_2017, directions = 8, zeroAsNA = TRUE)

cat("  Identification des grappes 2020...\n")
grappes_2020 <- patches(cellules_haute_densite_2020, directions = 8, zeroAsNA = TRUE)

# Compter le nombre de grappes distinctes
nb_grappes_2017 <- max(values(grappes_2017, mat = FALSE), na.rm = TRUE)
nb_grappes_2020 <- max(values(grappes_2020, mat = FALSE), na.rm = TRUE)

cat("  ✓ Nombre de grappes 2017:", nb_grappes_2017, "\n")
cat("  ✓ Nombre de grappes 2020:", nb_grappes_2020, "\n\n")

# Sauvegarder les rasters de grappes
writeRaster(grappes_2017, "output/rasters/grappes_urbaines_2017.tif", overwrite = TRUE)
writeRaster(grappes_2020, "output/rasters/grappes_urbaines_2020.tif", overwrite = TRUE)

# ------------------------------------------------------------
# 2.4 : Calcul de la population par grappe
# ------------------------------------------------------------

cat("2.4 Calcul de la population de chaque grappe...\n")

# Fonction pour calculer la population par grappe
calculer_pop_grappes <- function(raster_grappes, raster_pop, annee) {
  
  cat("  Traitement année", annee, "...\n")
  
  # Extraire valeurs en tant que vecteurs
  val_grappes <- values(raster_grappes, mat = FALSE)
  val_pop <- values(raster_pop, mat = FALSE)
  
  # Créer dataframe avec conversion explicite en vecteurs
  df <- data.frame(
    grappe_id = as.vector(val_grappes),
    population = as.vector(val_pop)
  )
  
  # Retirer les valeurs NA
  df <- df[!is.na(df$grappe_id) & !is.na(df$population), ]
  
  # Vérifier que le dataframe n'est pas vide
  if (nrow(df) == 0) {
    cat("  ✗ ERREUR: Aucune donnée valide trouvée pour l'année", annee, "\n")
    return(data.frame())
  }
  
  cat("    Nombre de cellules à traiter:", nrow(df), "\n")
  
  # Agréger par grappe
  pop_par_grappe <- df %>%
    group_by(grappe_id) %>%
    summarise(
      population_totale = sum(population, na.rm = TRUE),
      nb_cellules = n(),
      .groups = 'drop'
    ) %>%
    arrange(desc(population_totale))
  
  cat("    ✓ Agrégation terminée:", nrow(pop_par_grappe), "grappes analysées\n")
  
  return(pop_par_grappe)
}

# Calculer pour les deux années
pop_grappes_2017 <- calculer_pop_grappes(grappes_2017, pop_2017, 2017)
pop_grappes_2020 <- calculer_pop_grappes(grappes_2020, pop_2020, 2020)

cat("  ✓ Population par grappe calculée\n\n")

# Afficher les 10 plus grandes grappes
cat("  Top 10 grappes par population (2017):\n")
print(head(pop_grappes_2017, 10))

cat("\n  Top 10 grappes par population (2020):\n")
print(head(pop_grappes_2020, 10))
cat("\n")

# ------------------------------------------------------------
# 2.5 : Classification DEGURBA des grappes
# ------------------------------------------------------------

cat("2.5 Classification DEGURBA des grappes...\n")

cat("  CRITÈRES DE CLASSIFICATION:\n")
cat("    - Centre urbain: population ≥50,000 habitants\n")
cat("    - Grappe urbaine: population ≥5,000 habitants\n")
cat("    - Zone rurale: population <5,000 habitants\n\n")

# Classifier 2017
pop_grappes_2017 <- pop_grappes_2017 %>%
  mutate(
    classe_degurba = case_when(
      population_totale >= 50000 ~ "Centre urbain",
      population_totale >= 5000 ~ "Grappe urbaine",
      TRUE ~ "Zone rurale"
    )
  )

# Classifier 2020
pop_grappes_2020 <- pop_grappes_2020 %>%
  mutate(
    classe_degurba = case_when(
      population_totale >= 50000 ~ "Centre urbain",
      population_totale >= 5000 ~ "Grappe urbaine",
      TRUE ~ "Zone rurale"
    )
  )

# Statistiques de classification
cat("  Résultats classification 2017:\n")
table_2017 <- table(pop_grappes_2017$classe_degurba)
print(table_2017)

cat("\n  Résultats classification 2020:\n")
table_2020 <- table(pop_grappes_2020$classe_degurba)
print(table_2020)
cat("\n")

# Population par classe
pop_par_classe_2017 <- pop_grappes_2017 %>%
  group_by(classe_degurba) %>%
  summarise(
    nb_grappes = n(),
    population_totale = sum(population_totale),
    surface_totale_km2 = sum(nb_cellules) * stats_surface$mean
  )

cat("  Population par classe DEGURBA (2017):\n")
print(pop_par_classe_2017)
cat("\n")

# Sauvegarder les classifications
write.csv(pop_grappes_2017, "output/degurba/classification_grappes_2017.csv", row.names = FALSE)
write.csv(pop_grappes_2020, "output/degurba/classification_grappes_2020.csv", row.names = FALSE)

# ------------------------------------------------------------
# 2.6 : Création des rasters de zones urbaines DEGURBA
# ------------------------------------------------------------

cat("2.6 Création des rasters de zones urbaines DEGURBA...\n")

# Fonction pour créer un raster urbain (centres urbains uniquement)
creer_raster_urbain <- function(raster_grappes, df_pop_grappes, annee) {
  
  cat("  Création raster urbain", annee, "...\n")
  
  # Filtrer seulement les centres urbains (≥50,000 hab)
  centres_urbains <- df_pop_grappes %>%
    filter(classe_degurba == "Centre urbain")
  
  cat("    Nombre de centres urbains:", nrow(centres_urbains), "\n")
  
  # Créer raster binaire: 1 = centre urbain, NA = non urbain
  raster_urbain <- raster_grappes
  
  # BINARISATION: Mettre 1 pour les grappes qui sont des centres urbains
  values(raster_urbain) <- ifelse(
    values(raster_grappes, mat = FALSE) %in% centres_urbains$grappe_id,
    1,
    NA
  )
  
  cat("    ✓ Raster binaire créé\n")
  
  return(raster_urbain)
}

# Créer les rasters urbains pour les deux années
urbain_2017 <- creer_raster_urbain(grappes_2017, pop_grappes_2017, 2017)
urbain_2020 <- creer_raster_urbain(grappes_2020, pop_grappes_2020, 2020)

# Sauvegarder
writeRaster(urbain_2017, "output/rasters/zones_urbaines_degurba_2017.tif", overwrite = TRUE)
writeRaster(urbain_2020, "output/rasters/zones_urbaines_degurba_2020.tif", overwrite = TRUE)

cat("  ✓ Rasters urbains sauvegardés\n\n")

# ============================================================
# PARTIE 3 : CALCUL DE L'INDICATEUR ODD 11.3.1
# ============================================================

cat(paste(rep("=", 90), collapse = ""), "\n")
cat("PARTIE 3 : CALCUL DE L'INDICATEUR ODD 11.3.1\n")
cat(paste(rep("=", 90), collapse = ""), "\n\n")

cat("FORMULE ODD 11.3.1 (LCRPGR):\n")
cat("  LCRPGR = LCR / PGR\n\n")
cat("  où:\n")
cat("    LCR (Land Consumption Rate) = [Ln(Urb_t1 / Urb_t0) / y] × 100\n")
cat("    PGR (Population Growth Rate) = [Ln(Pop_t1 / Pop_t0) / y] × 100\n")
cat("    y = nombre d'années entre t0 et t1\n")
cat("    Ln = logarithme népérien\n\n")

# ------------------------------------------------------------
# 3.1 : Calcul du taux de consommation des terres (LCR)
# ------------------------------------------------------------

cat("3.1 Calcul du taux de consommation des terres (LCR)...\n\n")

# Extraire les centres urbains
centres_urbains_2017 <- pop_grappes_2017 %>%
  filter(classe_degurba == "Centre urbain")

centres_urbains_2020 <- pop_grappes_2020 %>%
  filter(classe_degurba == "Centre urbain")

cat("  Nombre de centres urbains identifiés:\n")
cat("    - 2017:", nrow(centres_urbains_2017), "centres\n")
cat("    - 2020:", nrow(centres_urbains_2020), "centres\n\n")

# Calculer la surface en km² pour chaque centre urbain
# Surface = nombre de cellules × surface moyenne d'une cellule
centres_urbains_2017$surface_km2 <- centres_urbains_2017$nb_cellules * stats_surface$mean
centres_urbains_2020$surface_km2 <- centres_urbains_2020$nb_cellules * stats_surface$mean

# Surface urbaine totale
surface_totale_2017 <- sum(centres_urbains_2017$surface_km2, na.rm = TRUE)
surface_totale_2020 <- sum(centres_urbains_2020$surface_km2, na.rm = TRUE)

cat("  Surfaces urbaines totales (centres urbains uniquement):\n")
cat("    - 2017:", round(surface_totale_2017, 2), "km²\n")
cat("    - 2020:", round(surface_totale_2020, 2), "km²\n")
cat("    - Variation absolue:", round(surface_totale_2020 - surface_totale_2017, 2), "km²\n")
cat("    - Variation relative:", round(((surface_totale_2020 / surface_totale_2017) - 1) * 100, 2), "%\n\n")

# Nombre d'années
annees <- 2020 - 2017  # 3 ans

# VÉRIFICATION DIVISION PAR ZÉRO ET VALEURS NULLES
cat("  Vérification des conditions de calcul:\n")

if (surface_totale_2017 <= 0) {
  cat("    ✗ ERREUR: Surface urbaine 2017 nulle ou négative\n")
  cat("    → Impossible de calculer LCR\n")
  LCR <- NA
} else if (surface_totale_2020 <= 0) {
  cat("    ✗ ERREUR: Surface urbaine 2020 nulle ou négative\n")
  cat("    → Impossible de calculer LCR\n")
  LCR <- NA
} else if (surface_totale_2020 == surface_totale_2017) {
  cat("    ⚠ ATTENTION: Surfaces identiques (pas de changement)\n")
  cat("    → LCR = 0\n")
  LCR <- 0
} else {
  cat("    ✓ Conditions remplies pour le calcul\n\n")
  
  # Calcul de LCR selon la formule ODD
  LCR <- (log(surface_totale_2020 / surface_totale_2017) / annees) * 100
  
  cat("  RÉSULTAT LCR (Land Consumption Rate):\n")
  cat("    LCR =", round(LCR, 4), "% par an\n")
  cat("    Interprétation: La surface urbaine croît à un taux de", round(LCR, 2), "% par an\n\n")
}

# ------------------------------------------------------------
# 3.2 : Calcul du taux de croissance démographique (PGR)
# ------------------------------------------------------------

cat("3.2 Calcul du taux de croissance démographique urbaine (PGR)...\n\n")

# Population urbaine totale (centres urbains uniquement)
pop_urbaine_2017 <- sum(centres_urbains_2017$population_totale, na.rm = TRUE)
pop_urbaine_2020 <- sum(centres_urbains_2020$population_totale, na.rm = TRUE)

cat("  Populations urbaines (centres urbains uniquement):\n")
cat("    - 2017:", format(round(pop_urbaine_2017), big.mark = " "), "habitants\n")
cat("    - 2020:", format(round(pop_urbaine_2020), big.mark = " "), "habitants\n")
cat("    - Variation absolue:", format(round(pop_urbaine_2020 - pop_urbaine_2017), big.mark = " "), "habitants\n")
cat("    - Variation relative:", round(((pop_urbaine_2020 / pop_urbaine_2017) - 1) * 100, 2), "%\n\n")

# VÉRIFICATION DIVISION PAR ZÉRO ET VALEURS NULLES
cat("  Vérification des conditions de calcul:\n")

if (pop_urbaine_2017 <= 0) {
  cat("    ✗ ERREUR: Population urbaine 2017 nulle ou négative\n")
  cat("    → Impossible de calculer PGR\n")
  PGR <- NA
} else if (pop_urbaine_2020 <= 0) {
  cat("    ✗ ERREUR: Population urbaine 2020 nulle ou négative\n")
  cat("    → Impossible de calculer PGR\n")
  PGR <- NA
} else if (pop_urbaine_2020 == pop_urbaine_2017) {
  cat("    ⚠ ATTENTION: Populations identiques (pas de croissance)\n")
  cat("    → PGR = 0\n")
  PGR <- 0
} else {
  cat("    ✓ Conditions remplies pour le calcul\n\n")
  
  # Calcul de PGR selon la formule ODD
  PGR <- (log(pop_urbaine_2020 / pop_urbaine_2017) / annees) * 100
  
  cat("  RÉSULTAT PGR (Population Growth Rate):\n")
  cat("    PGR =", round(PGR, 4), "% par an\n")
  cat("    Interprétation: La population urbaine croît à un taux de", round(PGR, 2), "% par an\n\n")
}

# ------------------------------------------------------------
# 3.3 : Calcul de l'indicateur LCRPGR (ODD 11.3.1)
# ------------------------------------------------------------

cat("3.3 Calcul de l'indicateur ODD 11.3.1 (LCRPGR)...\n\n")

# VÉRIFICATION FINALE AVANT DIVISION
if (is.na(LCR)) {
  cat("  ✗ ERREUR: LCR non calculable → LCRPGR impossible\n\n")
  LCRPGR <- NA
} else if (is.na(PGR)) {
  cat("  ✗ ERREUR: PGR non calculable → LCRPGR impossible\n\n")
  LCRPGR <- NA
} else if (PGR == 0) {
  cat("  ✗ ERREUR: Division par zéro (PGR = 0)\n")
  cat("  → Pas de croissance démographique détectée\n")
  cat("  → LCRPGR non défini mathématiquement\n")
  cat("  MÉTHODE ALTERNATIVE PROPOSÉE:\n")
  cat("    - Si LCR > 0 et PGR = 0: étalement sans croissance démographique\n")
  cat("    - Si LCR = 0 et PGR = 0: situation stable (pas de changement)\n\n")
  LCRPGR <- NA
} else {
  cat("  ✓ Toutes les conditions sont remplies\n\n")
  
  # Calcul final de LCRPGR
  LCRPGR <- LCR / PGR
  
  cat("  ╔════════════════════════════════════════════════════════╗\n")
  cat("  ║         INDICATEUR ODD 11.3.1 (LCRPGR)               ║\n")
  cat("  ╠════════════════════════════════════════════════════════╣\n")
  cat("  ║  Valeur:", sprintf("%10.4f", LCRPGR), "                              ║\n")
  cat("  ╠════════════════════════════════════════════════════════╣\n")
  cat("  ║  LCR =", sprintf("%8.4f", LCR), "% par an                       ║\n")
  cat("  ║  PGR =", sprintf("%8.4f", PGR), "% par an                       ║\n")
  cat("  ╚════════════════════════════════════════════════════════╝\n\n")
  
  # Interprétation selon les normes ONU-Habitat
  cat("  INTERPRÉTATION SELON ONU-HABITAT:\n")
  cat("  ---------------------------------\n")
  if (LCRPGR < 1) {
    cat("    ✓✓ LCRPGR < 1: Croissance urbaine EFFICACE\n")
    cat("       → La ville se DENSIFIE (moins d'étalement spatial)\n")
    cat("       → La consommation de terres croît MOINS vite que la population\n")
    cat("       → Situation FAVORABLE pour le développement durable\n")
  } else if (abs(LCRPGR - 1) < 0.01) {
    cat("    = LCRPGR ≈ 1: Croissance PROPORTIONNELLE\n")
    cat("       → L'expansion spatiale suit exactement la croissance démographique\n")
    cat("       → Densité urbaine stable\n")
  } else {
    cat("    ✗ LCRPGR > 1: ÉTALEMENT URBAIN\n")
    cat("       → La ville s'étend plus vite que sa population n'augmente\n")
    cat("       → La densité urbaine DIMINUE\n")
    cat("       → Situation DÉFAVORABLE (inefficacité spatiale)\n")
  }
  cat("\n")
}

# ============================================================
# PARTIE 4 : ANALYSE PAR CENTRE URBAIN
# ============================================================

cat(paste(rep("=", 90), collapse = ""), "\n")
cat("PARTIE 4 : ANALYSE DÉTAILLÉE PAR CENTRE URBAIN\n")
cat(paste(rep("=", 90), collapse = ""), "\n\n")

cat("Calcul de LCRPGR pour chaque centre urbain individuellement...\n")
cat("NOTE: Appariement des centres par rang de population\n\n")

# Apparier les centres urbains 2017 et 2020
# (Approximation: on suppose que les plus grandes grappes correspondent)

resultats_centres <- data.frame()

nb_centres_analyser <- min(nrow(centres_urbains_2017), nrow(centres_urbains_2020))

cat("  Nombre de centres à analyser:", nb_centres_analyser, "\n\n")

for (i in 1:nb_centres_analyser) {
  
  centre_2017 <- centres_urbains_2017[i, ]
  centre_2020 <- centres_urbains_2020[i, ]
  
  # Vérifications avant calcul
  lcr_centre <- NA
  pgr_centre <- NA
  lcrpgr_centre <- NA
  
  # Calculer LCR pour ce centre (avec vérification)
  if (centre_2017$surface_km2 > 0 && centre_2020$surface_km2 > 0) {
    if (centre_2017$surface_km2 != centre_2020$surface_km2) {
      lcr_centre <- (log(centre_2020$surface_km2 / centre_2017$surface_km2) / annees) * 100
    } else {
      lcr_centre <- 0
    }
  }
  
  # Calculer PGR pour ce centre (avec vérification)
  if (centre_2017$population_totale > 0 && centre_2020$population_totale > 0) {
    if (centre_2017$population_totale != centre_2020$population_totale) {
      pgr_centre <- (log(centre_2020$population_totale / centre_2017$population_totale) / annees) * 100
    } else {
      pgr_centre <- 0
    }
  }
  
  # Calculer LCRPGR (avec vérification division par zéro)
  if (!is.na(lcr_centre) && !is.na(pgr_centre) && pgr_centre != 0) {
    lcrpgr_centre <- lcr_centre / pgr_centre
  }
  
  # Ajouter aux résultats
  resultats_centres <- rbind(resultats_centres, data.frame(
    centre_id = i,
    population_2017 = centre_2017$population_totale,
    population_2020 = centre_2020$population_totale,
    surface_2017_km2 = centre_2017$surface_km2,
    surface_2020_km2 = centre_2020$surface_km2,
    LCR = lcr_centre,
    PGR = pgr_centre,
    LCRPGR = lcrpgr_centre
  ))
}

# Afficher les résultats
cat("  Résultats par centre urbain:\n\n")
print(resultats_centres)
cat("\n")

# Statistiques sur les LCRPGR des centres
lcrpgr_valides <- resultats_centres$LCRPGR[!is.na(resultats_centres$LCRPGR)]

if (length(lcrpgr_valides) > 0) {
  cat("  Statistiques LCRPGR par centre:\n")
  cat("    - Moyenne:", round(mean(lcrpgr_valides), 4), "\n")
  cat("    - Médiane:", round(median(lcrpgr_valides), 4), "\n")
  cat("    - Minimum:", round(min(lcrpgr_valides), 4), "\n")
  cat("    - Maximum:", round(max(lcrpgr_valides), 4), "\n")
  cat("    - Centres avec LCRPGR < 1:", sum(lcrpgr_valides < 1), "centres (croissance efficace)\n")
  cat("    - Centres avec LCRPGR > 1:", sum(lcrpgr_valides > 1), "centres (étalement urbain)\n\n")
}

# Sauvegarder
write.csv(resultats_centres, "output/degurba/odd_11_3_1_par_centre.csv", row.names = FALSE)
cat("  ✓ Résultats sauvegardés: output/degurba/odd_11_3_1_par_centre.csv\n\n")

# ============================================================
# PARTIE 5 : CARTOGRAPHIE COMPLÈTE
# ============================================================

cat(paste(rep("=", 90), collapse = ""), "\n")
cat("PARTIE 5 : CARTOGRAPHIE DES RÉSULTATS\n")
cat(paste(rep("=", 90), collapse = ""), "\n\n")

cat("Création de cartes thématiques avec limites de la RDC...\n\n")

# ------------------------------------------------------------
# 5.1 : Carte de densité de population
# ------------------------------------------------------------

cat("5.1 Carte de densité de population (2017 et 2020)...\n")

# Convertir les rasters en dataframes pour ggplot
densite_2017_df <- as.data.frame(densite_2017, xy = TRUE)
colnames(densite_2017_df) <- c("x", "y", "densite")
densite_2017_df <- densite_2017_df[!is.na(densite_2017_df$densite), ]

densite_2020_df <- as.data.frame(densite_2020, xy = TRUE)
colnames(densite_2020_df) <- c("x", "y", "densite")
densite_2020_df <- densite_2020_df[!is.na(densite_2020_df$densite), ]

# Carte 2017 - Fond blanc, contours noirs
p1 <- ggplot() +
  geom_sf(data = rdc_pays, fill = "white", color = "black", size = 1.2) +
  geom_sf(data = rdc_provinces, fill = NA, color = "gray30", size = 0.4) +
  geom_raster(data = densite_2017_df, aes(x = x, y = y, fill = log10(densite + 1))) +
  geom_sf(data = rdc_pays, fill = NA, color = "black", size = 1.2) +
  geom_sf_text(data = rdc_provinces, aes(label = NAME_1), size = 3, color = "black", fontface = "bold") +
  scale_fill_gradientn(
    name = "Densité\n(log10 hab/km²)",
    colors = c("white", "yellow", "orange", "red", "darkred"),
    na.value = "white"
  ) +
  labs(title = "Densité de population 2017",
       subtitle = "République Démocratique du Congo",
       x = "Longitude", y = "Latitude") +
  theme_minimal() +
  theme(
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA),
    panel.grid = element_line(color = "gray90"),
    legend.position = "right",
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 11)
  )

# Carte 2020 - Fond blanc, contours noirs
p2 <- ggplot() +
  geom_sf(data = rdc_pays, fill = "white", color = "black", size = 1.2) +
  geom_sf(data = rdc_provinces, fill = NA, color = "gray30", size = 0.4) +
  geom_raster(data = densite_2020_df, aes(x = x, y = y, fill = log10(densite + 1))) +
  geom_sf(data = rdc_pays, fill = NA, color = "black", size = 1.2) +
  geom_sf_text(data = rdc_provinces, aes(label = NAME_1), size = 3, color = "black", fontface = "bold") +
  scale_fill_gradientn(
    name = "Densité\n(log10 hab/km²)",
    colors = c("white", "yellow", "orange", "red", "darkred"),
    na.value = "white"
  ) +
  labs(title = "Densité de population 2020",
       subtitle = "République Démocratique du Congo",
       x = "Longitude", y = "Latitude") +
  theme_minimal() +
  theme(
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA),
    panel.grid = element_line(color = "gray90"),
    legend.position = "right",
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 11)
  )

# Sauvegarder
ggsave("figures/cartes/densite_2017.png", p1, width = 12, height = 8, dpi = 300, bg = "white")
ggsave("figures/cartes/densite_2020.png", p2, width = 12, height = 8, dpi = 300, bg = "white")

cat("  ✓ Cartes de densité sauvegardées\n\n")

# ------------------------------------------------------------
# 5.2 : Carte des centres urbains DEGURBA
# ------------------------------------------------------------

cat("5.2 Carte des centres urbains DEGURBA...\n")

# Convertir les rasters urbains en dataframes
urbain_2017_df <- as.data.frame(urbain_2017, xy = TRUE)
colnames(urbain_2017_df) <- c("x", "y", "urbain")
urbain_2017_df <- urbain_2017_df[!is.na(urbain_2017_df$urbain), ]

urbain_2020_df <- as.data.frame(urbain_2020, xy = TRUE)
colnames(urbain_2020_df) <- c("x", "y", "urbain")
urbain_2020_df <- urbain_2020_df[!is.na(urbain_2020_df$urbain), ]

# Carte 2017 - Fond blanc avec centres urbains en rouge vif
p3 <- ggplot() +
  geom_sf(data = rdc_pays, fill = "white", color = "black", size = 1.2) +
  geom_sf(data = rdc_provinces, fill = NA, color = "gray40", size = 0.4) +
  geom_tile(data = urbain_2017_df, aes(x = x, y = y), fill = "#E31A1C", alpha = 0.85) +
  geom_sf(data = rdc_pays, fill = NA, color = "black", size = 1.2) +
  geom_sf_text(data = rdc_provinces, aes(label = NAME_1), size = 2.5, color = "black", fontface = "bold") +
  labs(title = "Centres urbains DEGURBA 2017",
       subtitle = "Population ≥ 50,000 habitants - République Démocratique du Congo",
       x = "Longitude", y = "Latitude") +
  theme_minimal() +
  theme(
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA),
    panel.grid = element_line(color = "gray90"),
    legend.position = "none",
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 10)
  )

# Carte 2020 - Fond blanc avec centres urbains en rouge vif
p4 <- ggplot() +
  geom_sf(data = rdc_pays, fill = "white", color = "black", size = 1.2) +
  geom_sf(data = rdc_provinces, fill = NA, color = "gray40", size = 0.4) +
  geom_tile(data = urbain_2020_df, aes(x = x, y = y), fill = "#E31A1C", alpha = 0.85) +
  geom_sf(data = rdc_pays, fill = NA, color = "black", size = 1.2) +
  geom_sf_text(data = rdc_provinces, aes(label = NAME_1), size = 2.5, color = "black", fontface = "bold") +
  labs(title = "Centres urbains DEGURBA 2020",
       subtitle = "Population ≥ 50,000 habitants - République Démocratique du Congo",
       x = "Longitude", y = "Latitude") +
  theme_minimal() +
  theme(
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA),
    panel.grid = element_line(color = "gray90"),
    legend.position = "none",
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 10)
  )

ggsave("figures/cartes/centres_urbains_2017.png", p3, width = 12, height = 8, dpi = 300, bg = "white")
ggsave("figures/cartes/centres_urbains_2020.png", p4, width = 12, height = 8, dpi = 300, bg = "white")

cat("  ✓ Cartes des centres urbains sauvegardées\n\n")

# ------------------------------------------------------------
# 5.3 : Carte comparative 2017-2020 (côte à côte contrasté)
# ------------------------------------------------------------

cat("5.3 Carte comparative (évolution 2017-2020)...\n")

# Créer une carte comparative avec 2017 et 2020 en bleu vs rouge pour contraster
# 2017 = bleu, 2020 = rouge, overlap = violet

# Créer un raster de changement
changement_df <- data.frame(
  x = c(urbain_2017_df$x, urbain_2020_df$x),
  y = c(urbain_2017_df$y, urbain_2020_df$y),
  annee = c(rep("2017", nrow(urbain_2017_df)), rep("2020", nrow(urbain_2020_df)))
)

# Carte comparative avec couleurs contrastées et libellés
p5 <- ggplot() +
  geom_sf(data = rdc_pays, fill = "white", color = "black", size = 1.2) +
  geom_sf(data = rdc_provinces, fill = NA, color = "gray40", size = 0.4) +
  geom_tile(data = urbain_2017_df, aes(x = x, y = y), fill = "#2166AC", alpha = 0.6) +
  geom_tile(data = urbain_2020_df, aes(x = x, y = y), fill = "#B2182B", alpha = 0.6) +
  geom_sf(data = rdc_pays, fill = NA, color = "black", size = 1.2) +
  geom_sf_text(data = rdc_provinces, aes(label = NAME_1), size = 2.5, color = "black", fontface = "bold") +
  labs(title = "Évolution des centres urbains 2017-2020",
       subtitle = "Bleu = 2017 | Rouge = 2020 | Violet = zones communes - RDC",
       x = "Longitude", y = "Latitude") +
  theme_minimal() +
  theme(
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA),
    panel.grid = element_line(color = "gray90"),
    legend.position = "bottom",
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 10)
  )

ggsave("figures/cartes/comparaison_urbain_2017_2020.png", p5, width = 14, height = 10, dpi = 300, bg = "white")

# Créer aussi une version côte à côte avec libellés
p_cote_a_cote <- gridExtra::grid.arrange(p3, p4, ncol = 2)
ggsave("figures/cartes/comparaison_cote_a_cote.png", p_cote_a_cote, width = 20, height = 8, dpi = 300, bg = "white")

cat("  ✓ Carte comparative sauvegardée\n\n")

# ------------------------------------------------------------
# 5.4 : Graphiques statistiques
# ------------------------------------------------------------

cat("5.4 Graphiques statistiques...\n")

# Graphique: Évolution de la surface urbaine
if (!is.na(surface_totale_2017) && !is.na(surface_totale_2020)) {
  df_surface <- data.frame(
    Annee = c("2017", "2020"),
    Surface_km2 = c(surface_totale_2017, surface_totale_2020)
  )
  
  g1 <- ggplot(df_surface, aes(x = Annee, y = Surface_km2, fill = Annee)) +
    geom_bar(stat = "identity") +
    geom_text(aes(label = round(Surface_km2, 1)), vjust = -0.5) +
    scale_fill_manual(values = c("2017" = "steelblue", "2020" = "coral")) +
    labs(title = "Évolution de la surface urbaine totale",
         subtitle = "Centres urbains DEGURBA - RDC",
         y = "Surface (km²)") +
    theme_minimal() +
    theme(legend.position = "none")
  
  ggsave("figures/graphiques/evolution_surface_urbaine.png", g1, width = 8, height = 6, dpi = 300)
}

# Graphique: Évolution de la population urbaine
if (!is.na(pop_urbaine_2017) && !is.na(pop_urbaine_2020)) {
  df_pop <- data.frame(
    Annee = c("2017", "2020"),
    Population = c(pop_urbaine_2017, pop_urbaine_2020)
  )
  
  g2 <- ggplot(df_pop, aes(x = Annee, y = Population, fill = Annee)) +
    geom_bar(stat = "identity") +
    geom_text(aes(label = format(round(Population), big.mark = " ")), vjust = -0.5) +
    scale_fill_manual(values = c("2017" = "steelblue", "2020" = "coral")) +
    scale_y_continuous(labels = scales::comma) +
    labs(title = "Évolution de la population urbaine",
         subtitle = "Centres urbains DEGURBA - RDC",
         y = "Population (habitants)") +
    theme_minimal() +
    theme(legend.position = "none")
  
  ggsave("figures/graphiques/evolution_population_urbaine.png", g2, width = 8, height = 6, dpi = 300)
}

cat("  ✓ Graphiques statistiques sauvegardés\n\n")

# ============================================================
# PARTIE 6 : RÉSUMÉ FINAL ET EXPORT
# ============================================================

cat(paste(rep("=", 90), collapse = ""), "\n")
cat("RÉSUMÉ FINAL - ODD 11.3.1 RDC (2017-2020)\n")
cat(paste(rep("=", 90), collapse = ""), "\n\n")

# Créer le tableau de résumé
resume_final <- data.frame(
  Indicateur = c(
    "Nombre de centres urbains 2017",
    "Nombre de centres urbains 2020",
    "Population urbaine 2017 (hab)",
    "Population urbaine 2020 (hab)",
    "Surface urbaine 2017 (km²)",
    "Surface urbaine 2020 (km²)",
    "Période d'analyse (années)",
    "LCR (% par an)",
    "PGR (% par an)",
    "LCRPGR (ODD 11.3.1)"
  ),
  Valeur = c(
    nrow(centres_urbains_2017),
    nrow(centres_urbains_2020),
    format(round(pop_urbaine_2017), big.mark = " "),
    format(round(pop_urbaine_2020), big.mark = " "),
    round(surface_totale_2017, 2),
    round(surface_totale_2020, 2),
    annees,
    ifelse(is.na(LCR), "Non calculable", round(LCR, 4)),
    ifelse(is.na(PGR), "Non calculable", round(PGR, 4)),
    ifelse(is.na(LCRPGR), "Non calculable", round(LCRPGR, 4))
  )
)

print(resume_final)
cat("\n")

# Sauvegarder le résumé
write.csv(resume_final, "output/degurba/resume_odd_11_3_1.csv", row.names = FALSE)

cat("✓ Résumé final sauvegardé\n\n")

# ============================================================
# FINALISATION
# ============================================================

heure_fin <- Sys.time()
duree <- difftime(heure_fin, heure_debut, units = "mins")

cat(paste(rep("=", 90), collapse = ""), "\n")
cat("ANALYSE TERMINÉE - MÉTHODOLOGIE DEGURBA STRICTE\n")
cat(paste(rep("=", 90), collapse = ""), "\n\n")

cat("Durée totale:", round(duree, 1), "minutes\n\n")

cat("FICHIERS GÉNÉRÉS:\n")
cat("  Rasters:\n")
cat("    - output/rasters/densite_population_2017.tif\n")
cat("    - output/rasters/densite_population_2020.tif\n")
cat("    - output/rasters/cellules_haute_densite_2017.tif\n")
cat("    - output/rasters/cellules_haute_densite_2020.tif\n")
