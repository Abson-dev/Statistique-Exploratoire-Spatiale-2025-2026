
# ==============================================================================
# SCRIPT D'INSPECTION DES DONNÉES SPATIALES
# Objectif : Examiner les shapefiles et rasters pour vérifier leur cohérence
# ==============================================================================

# --- 1. CHARGEMENT DES PACKAGES ---
if(!requireNamespace("sf", quietly = TRUE)) install.packages("sf")
if(!requireNamespace("terra", quietly = TRUE)) install.packages("terra")
library(sf)
library(terra)

# --- 2. DÉFINITION DES CHEMINS ---
shp_path <- "data/gadm/gadm41_SEN_shp"
rast_dir <- "data/clippedlayers/"
out_dir  <- "outputs/"

# Créer le dossier outputs s'il n'existe pas
if(!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

# ==============================================================================
# PARTIE 1 : INSPECTION DU SHAPEFILE
# ==============================================================================

cat("\n==================== SHAPEFILE ====================\n\n")

# Lecture du shapefile (quiet = TRUE évite les messages de sf)
gadm <- st_read(shp_path, quiet = TRUE)

# Afficher un aperçu des données
cat("--- Aperçu des données (première entité) ---\n")
print(gadm[1, ])

# Vérifier le système de coordonnées (CRS)
cat("\n--- Système de projection ---\n")
crs_info <- st_crs(gadm)
print(crs_info)

# Afficher l'emprise géographique (bounding box)
cat("\n--- Emprise géographique (bbox) ---\n")
bbox <- st_bbox(gadm)
print(bbox)

# Statistiques de base
cat("\n--- Résumé ---\n")
cat("Nombre d'entités (régions/polygones):", nrow(gadm), "\n")
cat("Nombre de colonnes (attributs):", ncol(gadm), "\n")
cat("Nom des colonnes:", paste(names(gadm), collapse = ", "), "\n")

# ==============================================================================
# PARTIE 2 : INSPECTION DES RASTERS
# ==============================================================================

cat("\n\n==================== RASTERS ====================\n\n")

# Lister tous les fichiers raster (formats .tif et .tiff)
r_files <- list.files(rast_dir, 
                      pattern = "\\.(tif|tiff)$", 
                      full.names = TRUE, 
                      ignore.case = TRUE)

# Vérifier qu'on a trouvé des fichiers
if(length(r_files) == 0) {
  stop("Aucun fichier raster trouvé dans ", rast_dir)
}

cat("Nombre de rasters trouvés:", length(r_files), "\n")
cat("Liste des fichiers:\n")
print(basename(r_files))

# --- Fonction pour inspecter un raster ---
inspect_raster <- function(filepath) {
  
  # Charger le raster avec terra
  r <- rast(filepath)
  
  cat("\n---- ", basename(filepath), " ----\n")
  
  # Dimensions : (couches, lignes, colonnes)
  cat("Dimensions (nlayers, nrow, ncol):", paste(dim(r), collapse = " x "), "\n")
  
  # Taille d'un pixel (résolution spatiale)
  cat("Résolution (largeur x hauteur du pixel):", paste(res(r), collapse = " x "), "\n")
  
  # Emprise géographique du raster
  cat("Extent (xmin, xmax, ymin, ymax):", as.vector(ext(r)), "\n")
  
  # Système de projection
  cat("CRS:", crs(r, describe = TRUE)$name, "\n")
  
  # Statistiques des valeurs
  stats <- global(r, fun = c("min", "max"), na.rm = TRUE)
  cat("Valeurs min/max par couche:\n")
  print(stats)
  
  # Pourcentage de valeurs manquantes (NA)
  na_count <- global(r, fun = "isNA")
  total_cells <- ncell(r) * nlyr(r)
  na_pct <- round(sum(na_count) / total_cells * 100, 2)
  cat("Pourcentage de NA:", na_pct, "%\n")
  
  return(r)
}

# Appliquer la fonction à tous les rasters
rasters <- lapply(r_files, inspect_raster)

# ==============================================================================
# PARTIE 3 : VÉRIFICATION DE LA COHÉRENCE
# ==============================================================================

cat("\n\n==================== VÉRIFICATIONS ====================\n\n")

# Vérifier que tous les rasters ont le même CRS
crs_list <- sapply(rasters, crs)
if(length(unique(crs_list)) > 1) {
  warning("ATTENTION : Les rasters n'ont pas tous le même système de projection !")
} else {
  cat("✓ Tous les rasters ont le même CRS\n")
}

# Comparer le CRS du shapefile et des rasters
shp_crs <- st_crs(gadm)$wkt
rast_crs <- crs(rasters[[1]])
if(shp_crs != rast_crs) {
  warning("ATTENTION : Le shapefile et les rasters n'ont pas le même CRS !")
  cat("  CRS shapefile:", st_crs(gadm)$input, "\n")
  cat("  CRS rasters:", crs(rasters[[1]], describe = TRUE)$name, "\n")
} else {
  cat("✓ Le shapefile et les rasters ont le même CRS\n")
}

# ==============================================================================
# PARTIE 4 : EXPORT DU RÉSUMÉ
# ==============================================================================

cat("\n\n==================== EXPORT ====================\n\n")

# Créer un tableau récapitulatif des métadonnées
meta <- data.frame(
  fichier = basename(r_files),
  n_couches = sapply(rasters, nlyr),
  n_lignes = sapply(rasters, nrow),
  n_colonnes = sapply(rasters, ncol),
  resolution_x = sapply(rasters, function(x) res(x)[1]),
  resolution_y = sapply(rasters, function(x) res(x)[2]),
  projection = sapply(rasters, function(x) crs(x, describe = TRUE)$name),
  stringsAsFactors = FALSE
)

# Sauvegarder en CSV
out_file <- file.path(out_dir, "rasters_metadata_summary.csv")
write.csv(meta, out_file, row.names = FALSE)

cat("✓ Résumé enregistré dans:", out_file, "\n")
cat("\nInspection terminée !\n")