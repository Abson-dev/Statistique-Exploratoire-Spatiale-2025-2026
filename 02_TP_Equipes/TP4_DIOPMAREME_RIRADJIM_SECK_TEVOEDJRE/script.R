# Chargement des bibliothèques nécessaires
library(sf)           # Pour les shapefiles
library(terra)        # Pour les rasters
library(dplyr)        # Pour la manipulation de données
library(ggplot2)

# =============================================================================
# Inspection
# =============================================================================

# =============================================================================
# FONCTION UTILITAIRE POUR AFFICHER LES PROPRIETES DES SHAPEFILES
# =============================================================================

verifier_shapefile <- function(chemin_fichier, nom_fichier) {
  cat("\n", rep("=", 80), "\n", sep = "")
  cat("SHAPEFILE:", nom_fichier, "\n")
  cat(rep("=", 80), "\n", sep = "")
  
  # Lecture du shapefile
  shp <- st_read(chemin_fichier, quiet = TRUE)
  
  # Informations générales
  cat("\n--- INFORMATIONS GENERALES ---\n")
  cat("Nombre d'entités:", nrow(shp), "\n")
  cat("Nombre de colonnes:", ncol(shp), "\n")
  cat("Type de géométrie:", unique(st_geometry_type(shp)), "\n")
  
  # Système de projection
  cat("\n--- SYSTEME DE PROJECTION ---\n")
  crs_info <- st_crs(shp)
  cat("EPSG:", crs_info$epsg, "\n")
  cat("Proj4string:", crs_info$proj4string, "\n")
  cat("Est projeté:", st_is_longlat(shp) == FALSE, "\n")
  
  # Emprise spatiale
  cat("\n--- EMPRISE SPATIALE (BOUNDING BOX) ---\n")
  bbox <- st_bbox(shp)
  cat("xmin:", bbox["xmin"], "\n")
  cat("xmax:", bbox["xmax"], "\n")
  cat("ymin:", bbox["ymin"], "\n")
  cat("ymax:", bbox["ymax"], "\n")
  
  # Colonnes disponibles
  cat("\n--- COLONNES DISPONIBLES ---\n")
  cat(paste(names(shp), collapse = ", "), "\n")
  
  # Aperçu des premières lignes
  cat("\n--- APERCU DES DONNEES (5 premières lignes) ---\n")
  print(head(st_drop_geometry(shp), 5))
  
  # Validation de la géométrie
  cat("\n--- VALIDATION DE LA GEOMETRIE ---\n")
  valide <- all(st_is_valid(shp))
  cat("Toutes les géométries sont valides:", valide, "\n")
  if (!valide) {
    cat("ATTENTION: Certaines géométries sont invalides!\n")
    cat("Nombre de géométries invalides:", sum(!st_is_valid(shp)), "\n")
  }
  
  return(shp)
}

# =============================================================================
# FONCTION UTILITAIRE POUR AFFICHER LES PROPRIETES DES RASTERS
# =============================================================================

verifier_raster <- function(chemin_fichier, nom_fichier) {
  cat("\n", rep("=", 80), "\n", sep = "")
  cat("RASTER:", nom_fichier, "\n")
  cat(rep("=", 80), "\n", sep = "")
  
  # Lecture du raster
  r <- rast(chemin_fichier)
  
  # Informations générales
  cat("\n--- INFORMATIONS GENERALES ---\n")
  cat("Nombre de couches:", nlyr(r), "\n")
  cat("Nombre de lignes:", nrow(r), "\n")
  cat("Nombre de colonnes:", ncol(r), "\n")
  cat("Nombre total de cellules:", ncell(r), "\n")
  
  # Résolution
  cat("\n--- RESOLUTION ---\n")
  res_info <- res(r)
  cat("Résolution X:", res_info[1], "\n")
  cat("Résolution Y:", res_info[2], "\n")
  cat("Unité:", if (is.lonlat(r)) "degrés" else "mètres", "\n")
  
  # Système de projection
  cat("\n--- SYSTEME DE PROJECTION ---\n")
  crs_info <- crs(r, describe = TRUE)
  cat("CRS:", crs(r), "\n")
  cat("EPSG (si disponible):", if (is.na(crs_info$code)) "N/A" else crs_info$code, "\n")
  cat("Est en lon/lat:", is.lonlat(r), "\n")
  
  # Emprise spatiale
  cat("\n--- EMPRISE SPATIALE ---\n")
  ext_info <- ext(r)
  cat("xmin:", ext_info[1], "\n")
  cat("xmax:", ext_info[2], "\n")
  cat("ymin:", ext_info[3], "\n")
  cat("ymax:", ext_info[4], "\n")
  
  # Statistiques des valeurs
  cat("\n--- STATISTIQUES DES VALEURS ---\n")
  cat("Valeur minimale:", minmax(r)[1], "\n")
  cat("Valeur maximale:", minmax(r)[2], "\n")
  cat("Type de données:", datatype(r), "\n")
  
  # Valeur NoData
  cat("\n--- VALEURS MANQUANTES ---\n")
  cat("Valeur NoData:", NAflag(r), "\n")
  cat("Nombre de cellules NA:", global(r, "isNA", na.rm = FALSE)[1,1], "\n")
  
  # Taille du fichier
  cat("\n--- TAILLE ---\n")
  taille_mo <- file.size(chemin_fichier) / (1024^2)
  cat("Taille du fichier:", round(taille_mo, 2), "Mo\n")
  
  return(r)
}

# =============================================================================
# IMPORTATION ET VERIFICATION DES DONNEES
# =============================================================================

cat("\n")
cat(rep("#", 80), "\n", sep = "")
cat("# DEBUT DE LA VERIFICATION DES DONNEES GEOSPATIALES\n")
cat(rep("#", 80), "\n", sep = "")

# -----------------------------------------------------------------------------
# 1. AIRES PROTEGEES (WDPA)
# -----------------------------------------------------------------------------

cat("\n\n>>> AIRES PROTEGEES (WDPA) <<<\n")

wdpa_polygons <- verifier_shapefile(
  "data/Protected_areas/protected_areas_kenya_polygons.shp",
  "Aires protégées Kenya (Polygones)"
)

wdpa_points <- verifier_shapefile(
  "data/Protected_areas/protected_areas_kenya_points.shp",
  "Aires protégées Kenya (Points)"
)

# -----------------------------------------------------------------------------
# 2. TERRES CULTIVEES (GFSAD30)
# -----------------------------------------------------------------------------

cat("\n\n>>> TERRES CULTIVEES (GFSAD30) <<<\n")

gfsad_N00E30 <- verifier_raster(
  "data/Terres_cultivees/GFSAD30AFCE_2015_N00E30_001_2017261090100.tif",
  "GFSAD30 N00E30"
)

gfsad_N00E40 <- verifier_raster(
  "data/Terres_cultivees/GFSAD30AFCE_2015_N00E40_001_2017261090100.tif",
  "GFSAD30 N00E40"
)

gfsad_S10E30 <- verifier_raster(
  "data/Terres_cultivees/GFSAD30AFCE_2015_S10E30_001_2017261090100.tif",
  "GFSAD30 S10E30"
)

# -----------------------------------------------------------------------------
# 3. SURFACES IMPERMEABLES (GMIS)
# -----------------------------------------------------------------------------

cat("\n\n>>> SURFACES IMPERMEABLES (GMIS) <<<\n")

gmis_36M <- verifier_raster(
  "data/Surfaces_impermeables/KEN_36M_gmis_impervious_surface_percentage_utm_30m.tif",
  "GMIS 36M"
)

gmis_36N <- verifier_raster(
  "data/Surfaces_impermeables/KEN_36N_gmis_impervious_surface_percentage_utm_30m.tif",
  "GMIS 36N"
)

gmis_37M <- verifier_raster(
  "data/Surfaces_impermeables/KEN_37M_gmis_impervious_surface_percentage_utm_30m.tif",
  "GMIS 37M"
)

gmis_37N <- verifier_raster(
  "data/Surfaces_impermeables/KEN_37N_gmis_impervious_surface_percentage_utm_30m.tif",
  "GMIS 37N"
)

# -----------------------------------------------------------------------------
# 4. DEFORESTATION HANSEN
# -----------------------------------------------------------------------------

cat("\n\n>>> DEFORESTATION HANSEN <<<\n")

hansen_loss <- verifier_raster(
  "data/Hansen_forestation/Hansen_Loss_2001_2015_Kenya.tif",
  "Hansen Forest Loss 2001-2015"
)

# -----------------------------------------------------------------------------
# 5. EAUX PERMANENTES (JRC)
# -----------------------------------------------------------------------------

cat("\n\n>>> EAUX PERMANENTES (JRC) <<<\n")

jrc_water <- verifier_raster(
  "data/Eaux_permanentes/JRC_PermanentWater_Kenya.tif",
  "JRC Permanent Water"
)

# -----------------------------------------------------------------------------
# 6. PENTE/RELIEF
# -----------------------------------------------------------------------------

cat("\n\n>>> PENTE/RELIEF <<<\n")

kenya_slope <- verifier_raster(
  "data/Pente_relief/kenya_slope_le15pct_uint8.tif",
  "Kenya Slope (≤15%)"
)

# -----------------------------------------------------------------------------
# 7. FRONTIERES ADMINISTRATIVES (GADM)
# -----------------------------------------------------------------------------

cat("\n\n>>> FRONTIERES ADMINISTRATIVES (GADM) <<<\n")

gadm_0 <- verifier_shapefile(
  "data/Gadm/gadm41_KEN_0.shp",
  "GADM Niveau 0 (Pays)"
)

gadm_1 <- verifier_shapefile(
  "data/Gadm/gadm41_KEN_1.shp",
  "GADM Niveau 1 (Régions)"
)

gadm_2 <- verifier_shapefile(
  "data/Gadm/gadm41_KEN_2.shp",
  "GADM Niveau 2 (Comtés)"
)

gadm_3 <- verifier_shapefile(
  "data/Gadm/gadm41_KEN_3.shp",
  "GADM Niveau 3 (Sous-comtés)"
)

# =============================================================================
# SAUVEGARDE DES PROPRIETES DANS UN FICHIER TEXTE
# =============================================================================

cat("\n")
cat(rep("#", 80), "\n", sep = "")
cat("# SAUVEGARDE DES PROPRIETES\n")
cat(rep("#", 80), "\n", sep = "")
cat("\n")

# Créer le dossier outputs s'il n'existe pas
if (!dir.exists("outputs")) {
  dir.create("outputs")
}

# Rediriger la sortie console vers un fichier texte
sink("outputs/proprietes_donnees.txt")

cat("=============================================================================\n")
cat("PROPRIETES DES DONNEES GEOSPATIALES - KENYA\n")
cat("Date:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
cat("=============================================================================\n\n")

# Réafficher toutes les propriétés dans le fichier
cat("\n>>> AIRES PROTEGEES (WDPA) <<<\n")
print(st_crs(wdpa_polygons))
print(st_bbox(wdpa_polygons))
cat("\nNombre d'entités (polygones):", nrow(wdpa_polygons), "\n")
cat("Nombre d'entités (points):", nrow(wdpa_points), "\n")

cat("\n>>> TERRES CULTIVEES (GFSAD30) <<<\n")
cat("GFSAD30 N00E30:\n")
cat("  - Résolution:", res(gfsad_N00E30), "\n")
cat("  - CRS:", crs(gfsad_N00E30), "\n")
cat("  - EPSG:", crs(gfsad_N00E30, describe=TRUE)$code, "\n")
cat("GFSAD30 N00E40:\n")
cat("  - Résolution:", res(gfsad_N00E40), "\n")
cat("  - CRS:", crs(gfsad_N00E40), "\n")
cat("  - EPSG:", crs(gfsad_N00E40, describe=TRUE)$code, "\n")
cat("GFSAD30 S10E30:\n")
cat("  - Résolution:", res(gfsad_S10E30), "\n")
cat("  - CRS:", crs(gfsad_S10E30), "\n")
cat("  - EPSG:", crs(gfsad_S10E30, describe=TRUE)$code, "\n")

cat("\n>>> SURFACES IMPERMEABLES (GMIS) <<<\n")
cat("GMIS 36M:\n")
cat("  - Dimensions:", dim(gmis_36M), "\n")
cat("  - CRS:", crs(gmis_36M), "\n")
cat("  - EPSG:", crs(gmis_36M, describe=TRUE)$code, "\n")
cat("GMIS 36N:\n")
cat("  - Dimensions:", dim(gmis_36N), "\n")
cat("  - CRS:", crs(gmis_36N), "\n")
cat("  - EPSG:", crs(gmis_36N, describe=TRUE)$code, "\n")
cat("GMIS 37M:\n")
cat("  - Dimensions:", dim(gmis_37M), "\n")
cat("  - CRS:", crs(gmis_37M), "\n")
cat("  - EPSG:", crs(gmis_37M, describe=TRUE)$code, "\n")
cat("GMIS 37N:\n")
cat("  - Dimensions:", dim(gmis_37N), "\n")
cat("  - CRS:", crs(gmis_37N), "\n")
cat("  - EPSG:", crs(gmis_37N, describe=TRUE)$code, "\n")

cat("\n>>> DEFORESTATION HANSEN <<<\n")
cat("Hansen Loss:\n")
cat("  - Résolution:", res(hansen_loss), "\n")
cat("  - Dimensions:", dim(hansen_loss), "\n")
cat("  - CRS:", crs(hansen_loss), "\n")
cat("  - EPSG:", crs(hansen_loss, describe=TRUE)$code, "\n")

cat("\n>>> EAUX PERMANENTES (JRC) <<<\n")
cat("JRC Water:\n")
cat("  - Résolution:", res(jrc_water), "\n")
cat("  - Dimensions:", dim(jrc_water), "\n")
cat("  - CRS:", crs(jrc_water), "\n")
cat("  - EPSG:", crs(jrc_water, describe=TRUE)$code, "\n")

cat("\n>>> PENTE/RELIEF <<<\n")
cat("Kenya Slope:\n")
cat("  - Résolution:", res(kenya_slope), "\n")
cat("  - Dimensions:", dim(kenya_slope), "\n")
cat("  - CRS:", crs(kenya_slope), "\n")
cat("  - EPSG:", crs(kenya_slope, describe=TRUE)$code, "\n")

cat("\n>>> FRONTIERES ADMINISTRATIVES (GADM) <<<\n")
cat("GADM Niveau 0 - Nombre d'entités:", nrow(gadm_0), "\n")
cat("GADM Niveau 1 - Nombre d'entités:", nrow(gadm_1), "\n")
cat("GADM Niveau 2 - Nombre d'entités:", nrow(gadm_2), "\n")
cat("GADM Niveau 3 - Nombre d'entités:", nrow(gadm_3), "\n")

# Fermer la redirection
sink()

cat("Les propriétés ont été sauvegardées dans: outputs/proprietes_donnees.txt\n\n")


# =============================================================================
# ANALYSE DES TERRES ARABLES AU KENYA
# =============================================================================

# =============================================================================
# 1. CHARGEMENT DES DONNEES
# =============================================================================

cat("Chargement des données...\n")

# Rasters en EPSG:4326 (WGS84)
gfsad_N00E30 <- rast("data/Terres_cultivees/GFSAD30AFCE_2015_N00E30_001_2017261090100.tif")
gfsad_N00E40 <- rast("data/Terres_cultivees/GFSAD30AFCE_2015_N00E40_001_2017261090100.tif")
gfsad_S10E30 <- rast("data/Terres_cultivees/GFSAD30AFCE_2015_S10E30_001_2017261090100.tif")

hansen_loss <- rast("data/Hansen_forestation/Hansen_Loss_2001_2015_Kenya.tif")
jrc_water <- rast("data/Eaux_permanentes/JRC_PermanentWater_Kenya.tif")

# Raster en EPSG:3857 (Web Mercator)
kenya_slope <- rast("data/Pente_relief/kenya_slope_le15pct_uint8.tif")

# Rasters en UTM (zones 36N et 37N)
gmis_36M <- rast("data/Surfaces_impermeables/KEN_36M_gmis_impervious_surface_percentage_utm_30m.tif")
gmis_36N <- rast("data/Surfaces_impermeables/KEN_36N_gmis_impervious_surface_percentage_utm_30m.tif")
gmis_37M <- rast("data/Surfaces_impermeables/KEN_37M_gmis_impervious_surface_percentage_utm_30m.tif")
gmis_37N <- rast("data/Surfaces_impermeables/KEN_37N_gmis_impervious_surface_percentage_utm_30m.tif")

# Shapefiles
wdpa_polygons <- st_read("data/Protected_areas/protected_areas_kenya_polygons.shp", quiet = TRUE)
gadm_0 <- st_read("data/Gadm/gadm41_KEN_0.shp", quiet = TRUE)
gadm_1 <- st_read("data/Gadm/gadm41_KEN_1.shp", quiet = TRUE)
gadm_2 <- st_read("data/Gadm/gadm41_KEN_2.shp", quiet = TRUE)

# =============================================================================
# 2. REPROJECTION VERS EPSG:4326 (30m ≈ 0.0002694946°)
# =============================================================================

cat("Reprojection des données...\n")

# Reprojection du slope (EPSG:3857 → EPSG:4326)
kenya_slope_4326 <- project(kenya_slope, "EPSG:4326", method="near")

# Pour GMIS : définir une grille de référence commune
cat("Reprojection GMIS avec grille commune...\n")

# Utiliser hansen_loss comme référence (même résolution et étendue)
template <- hansen_loss

# Reprojeter chaque tuile GMIS vers la grille de référence
gmis_36M_4326 <- project(gmis_36M, template, method="bilinear")
gmis_36N_4326 <- project(gmis_36N, template, method="bilinear")
gmis_37M_4326 <- project(gmis_37M, template, method="bilinear")
gmis_37N_4326 <- project(gmis_37N, template, method="bilinear")

# Libérer la mémoire
rm(gmis_36M, gmis_36N, gmis_37M, gmis_37N)
gc()

# Maintenant faire la mosaïque (même résolution garantie)
gmis_4326 <- mosaic(gmis_36M_4326, gmis_36N_4326, gmis_37M_4326, gmis_37N_4326)

# Libérer encore
rm(gmis_36M_4326, gmis_36N_4326, gmis_37M_4326, gmis_37N_4326)
gc()

# =============================================================================
# 3. AGREGATION TERRES CULTIVEES + DEFORESTATION
# =============================================================================

cat("Agrégation terres cultivées et déforestation...\n")

# Mosaïque GFSAD30
gfsad_mosaic <- mosaic(gfsad_N00E30, gfsad_N00E40, gfsad_S10E30)

# Aligner gfsad_mosaic sur hansen_loss (même étendue et résolution)
gfsad_mosaic <- resample(gfsad_mosaic, hansen_loss, method="near")

# Binarisation: terres cultivées = 1, reste = 0
gfsad_bin <- ifel(gfsad_mosaic > 0, 1, 0)
hansen_bin <- ifel(hansen_loss > 0, 1, 0)

# Union: terres arables potentielles = cultivées OU déboisées
terres_potentielles <- max(gfsad_bin, hansen_bin)

# =============================================================================
# 4. APPLICATION DES MASQUES
# =============================================================================

cat("Application des masques...\n")

# Masque pente >15% (garder pente ≤15%)
mask_slope <- ifel(kenya_slope_4326 == 1, 1, NA)

# Masque eaux permanentes (exclure eau)
mask_water <- ifel(jrc_water == 0 | is.na(jrc_water), 1, NA)

# Masque surfaces imperméables (exclure >10% imperméable)
mask_impervious <- ifel(gmis_4326 < 10 | is.na(gmis_4326), 1, NA)

# Aligner tous les masques sur terres_potentielles
mask_slope <- resample(mask_slope, terres_potentielles, method="near")
mask_water <- resample(mask_water, terres_potentielles, method="near")
mask_impervious <- resample(mask_impervious, terres_potentielles, method="near")

# Application combinée des masques
terres_arables <- terres_potentielles * mask_slope * mask_water * mask_impervious

# =============================================================================
# 5. MASQUE AIRES PROTEGEES
# =============================================================================

cat("Exclusion des aires protégées...\n")

# Rasterisation des aires protégées
wdpa_rast <- rasterize(vect(wdpa_polygons), terres_arables, field=1)
mask_protected <- ifel(is.na(wdpa_rast), 1, NA)

# Masque final
terres_arables_final <- terres_arables * mask_protected

# =============================================================================
# 6. CALCUL DES SUPERFICIES
# =============================================================================

cat("Calcul des superficies...\n")

# Superficie totale Kenya (en km²)
pixel_area_km2 <- (30 * 30) / 1e6
superficie_totale <- global(terres_arables_final, "sum", na.rm=TRUE)[1,1] * pixel_area_km2

cat("\n=== RESULTATS ===\n")
cat("Superficie totale terres arables:", round(superficie_totale, 2), "km²\n")

# Par région (GADM niveau 1)
cat("\nCalcul par région...\n")
gadm_1_vect <- vect(gadm_1)
terres_par_region <- extract(terres_arables_final, gadm_1_vect, fun=sum, na.rm=TRUE)
gadm_1$superficie_km2 <- terres_par_region[,2] * pixel_area_km2

resultats_region <- gadm_1 %>%
  st_drop_geometry() %>%
  select(NAME_1, superficie_km2) %>%
  arrange(desc(superficie_km2))

print(resultats_region)

# Par comté (GADM niveau 2)
cat("\nCalcul par comté...\n")
gadm_2_vect <- vect(gadm_2)
terres_par_comte <- extract(terres_arables_final, gadm_2_vect, fun=sum, na.rm=TRUE)
gadm_2$superficie_km2 <- terres_par_comte[,2] * pixel_area_km2

resultats_comte <- gadm_2 %>%
  st_drop_geometry() %>%
  select(NAME_1, NAME_2, superficie_km2) %>%
  arrange(desc(superficie_km2))

# =============================================================================
# 7. EXPORT DES RESULTATS
# =============================================================================

cat("\nExport des résultats...\n")

# Export raster final
writeRaster(terres_arables_final, "outputs/terres_arables_kenya_30m.tif", overwrite=TRUE)

# Export tableaux
write.csv(resultats_region, "outputs/superficies_par_region.csv", row.names=FALSE)
write.csv(resultats_comte, "outputs/superficies_par_comte.csv", row.names=FALSE)

# =============================================================================
# 8. VISUALISATIONS
# =============================================================================

cat("Création des visualisations...\n")

# Carte des terres arables
png("outputs/carte_terres_arables.png", width=2400, height=2000, res=300)
plot(terres_arables_final, main="Terres arables au Kenya (30m)", 
     col=c("white", "darkgreen"), legend=FALSE)
plot(st_geometry(gadm_0), add=TRUE, border="black", lwd=2)
dev.off()

# Top 10 régions
top10_regions <- head(resultats_region, 10)
png("outputs/top10_regions.png", width=2400, height=1800, res=300)
par(mar=c(5,10,4,2))
barplot(top10_regions$superficie_km2, names.arg=top10_regions$NAME_1, 
        horiz=TRUE, las=1, main="Top 10 Régions - Terres arables (km²)",
        xlab="Superficie (km²)", col="darkgreen")
dev.off()

# Top 15 comtés
top15_comtes <- head(resultats_comte, 15)
png("outputs/top15_comtes.png", width=2400, height=2000, res=300)
par(mar=c(5,12,4,2))
barplot(top15_comtes$superficie_km2, names.arg=top15_comtes$NAME_2, 
        horiz=TRUE, las=1, main="Top 15 Comtés - Terres arables (km²)",
        xlab="Superficie (km²)", col="forestgreen")
dev.off()

# Carte choroplèthe par région
png("outputs/carte_regions_choroplethe.png", width=2400, height=2000, res=300)
plot(gadm_1["superficie_km2"], main="Terres arables par région",
     border="black")
dev.off()

cat("\n=== ANALYSE TERMINEE ===\n")
cat("Fichiers créés dans outputs/:\n")
cat("  - terres_arables_kenya_30m.tif\n")
cat("  - superficies_par_region.csv\n")
cat("  - superficies_par_comte.csv\n")
cat("  - carte_terres_arables.png\n")
cat("  - top10_regions.png\n")
cat("  - top15_comtes.png\n")
cat("  - carte_regions_choroplethe.png\n")

# Sauvegarder tout l'environnement de travail
save.image(file = "outputs/environnement_complet.RData")