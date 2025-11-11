# ==============================================================================
# SCRIPT DE VISUALISATION DES DONNÉES SPATIALES
# Objectif : Créer des cartes et graphiques pour explorer l'évolution temporelle
#            de l'incidence du paludisme au Sénégal
# ==============================================================================

# --- 0. INSTALLATION ET CHARGEMENT DES PACKAGES ---

# Liste des packages nécessaires
packages <- c("terra",        # manipulation de rasters
              "sf",           # manipulation de shapefiles
              "tmap",         # cartes thématiques
              "ggplot2",      # graphiques
              "dplyr",        # manipulation de données
              "viridis")      # palettes de couleurs

# Fonction pour installer les packages manquants
installer_si_manquant <- function(packages) {
  manquants <- packages[!packages %in% installed.packages()[, 1]]
  if(length(manquants) > 0) {
    cat("Installation des packages manquants:", paste(manquants, collapse = ", "), "\n")
    install.packages(manquants)
  }
}

installer_si_manquant(packages)

# Chargement des packages
library(terra)
library(sf)
library(tmap)
library(ggplot2)
library(dplyr)
library(viridis)

# --- 1. DÉFINITION DES CHEMINS ---

# Dossier de sortie pour les visualisations
out_dir <- "outputs"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# Chemin vers le shapefile du Sénégal
gadm_path <- "data/gadm/gadm41_SEN_shp"

# Dossier contenant les rasters (un fichier par année)
rast_dir <- "data/clippedlayers/"

# ==============================================================================
# PARTIE 1 : CHARGEMENT ET PRÉPARATION DES DONNÉES
# ==============================================================================

# ------------------------------------------------------------------
# Bloc : Charger shapefile + lister/charger/empiler rasters (couche 1)
# ------------------------------------------------------------------

# packages requis
if(!requireNamespace("sf", quietly = TRUE)) install.packages("sf")
if(!requireNamespace("terra", quietly = TRUE)) install.packages("terra")
library(sf)
library(terra)

# --- 0. Définitions / valeurs par défaut ---
# Si tu as déjà défini gadm_path ou rast_dir dans ton environnement, ce bloc les utilisera.
# Sinon il cherchera automatiquement le shapefile dans data/gadm/ et utilisera data/clippedlayers/ pour les rasters.
if(!exists("gadm_path")) gadm_path <- NULL
if(!exists("rast_dir")) rast_dir <- "data/clippedlayers"

# --- 1. Rechercher et charger automatiquement le shapefile si nécessaire ---
if(is.null(gadm_path) || !file.exists(gadm_path)) {
  shp_candidates <- list.files(
    path = "data/gadm",
    pattern = "\\.shp$",
    full.names = TRUE,
    recursive = TRUE,
    ignore.case = TRUE
  )
  if(length(shp_candidates) == 0) {
    stop("Aucun fichier .shp trouvé dans 'data/gadm'. Place le shapefile (fichiers .shp/.dbf/.shx/.prj) dans ce dossier, ou définis manuellement 'gadm_path'.")
  }
  # on prend le premier .shp trouvé
  gadm_path <- shp_candidates[1]
  message("Shapefile détecté et utilisé :", gadm_path)
}

# Lire le shapefile
gadm <- st_read(gadm_path, quiet = TRUE)
message("Shapefile chargé. CRS :", st_crs(gadm)$input)
message("Bounding box :", paste(round(st_bbox(gadm), 5), collapse = " "))

# --- 2. Lister les rasters dans rast_dir ---
if(!dir.exists(rast_dir)) stop("Dossier des rasters introuvable : ", rast_dir)
fichiers_raster <- list.files(
  path = rast_dir,
  pattern = "\\.(tif|tiff)$",
  full.names = TRUE,
  recursive = FALSE,
  ignore.case = TRUE
)
if(length(fichiers_raster) == 0) stop("Aucun raster .tif/.tiff trouvé dans ", rast_dir)

# --- 3. Extraire l'année depuis le nom de fichier (fonction robuste) ---
extraire_annee <- function(nom_fichier) {
  nm <- basename(nom_fichier)
  # essaie de trouver 4 chiffres juste avant l'extension (.tif or .tiff)
  m <- regmatches(nm, regexpr("\\d{4}(?=\\.(tif|tiff)$)", nm, perl = TRUE))
  if(length(m) == 0 || m == "") {
    # fallback : prendre le dernier groupe de 4 chiffres présent dans le nom
    all <- regmatches(nm, gregexpr("\\d{4}", nm, perl = TRUE))[[1]]
    if(length(all) == 0) return(NA_integer_)
    return(as.integer(tail(all, 1)))
  } else {
    return(as.integer(m))
  }
}

# appliquer et trier par année
annees <- sapply(fichiers_raster, extraire_annee)
ordre <- order(annees, na.last = TRUE)
fichiers_raster <- fichiers_raster[ordre]
annees <- annees[ordre]

message(length(fichiers_raster), " rasters trouvés ; années : ", paste(na.omit(unique(annees)), collapse = ", "))

# --- 4. Charger SEULEMENT la couche 1 de chaque raster et stocker dans une liste ---
liste_rasters <- vector("list", length(fichiers_raster))
for(i in seq_along(fichiers_raster)) {
  f <- fichiers_raster[i]
  r <- rast(f)               # lire le raster (terra)
  # vérifier qu'il y a au moins une couche
  if(nlyr(r) < 1) stop("Le raster n'a pas de couche : ", f)
  # extraire la couche 1 (incidence moyenne selon ta remarque)
  r1 <- r[[1]]
  # nommer la couche avec l'année si disponible
  yr <- annees[i]
  if(!is.na(yr)) names(r1) <- paste0("an_", yr) else names(r1) <- paste0("layer_", i)
  liste_rasters[[i]] <- r1
  
  # affichage de progression (tous les 5 ou dernier)
  if(i %% 5 == 0 || i == length(fichiers_raster)) {
    message("Chargés ", i, "/", length(fichiers_raster), " rasters")
  }
}

# --- 5. Empiler les rasters en un SpatRaster multi-couches ---
stack_rasters <- rast(liste_rasters)
message("Stack créé : ", nlyr(stack_rasters), " couches (une par année)")

# --- 6. Vérifier la cohérence des CRS et reprojeter le shapefile si nécessaire ---
# crs(stack_rasters) renvoie la projection du raster (format PROJ)
r_crs <- crs(stack_rasters)
s_crs <- st_crs(gadm)$wkt

# si CRS différents, reprojeter le shapefile vers le CRS des rasters (plus sûr que l'inverse)
if(is.na(s_crs) || (is.character(r_crs) && !grepl(s_crs, r_crs, fixed = TRUE))) {
  # on tente simplement de reprojeter le shapefile vers la CRS du raster
  message("Reprojection du shapefile vers la CRS des rasters...")
  gadm <- st_transform(gadm, crs = r_crs)
  message("Reprojection effectuée. Nouveau CRS :", st_crs(gadm)$input)
} else {
  message("CRS shapefile et rasters cohérents.")
}

# --- 7. Résumé final ---
message("Opération terminée : objet 'gadm' (sf) et 'stack_rasters' (SpatRaster) prêts à l'emploi.")
# fin du bloc


# ==============================================================================
# PARTIE 2 : CALCUL DES STATISTIQUES ANNUELLES
# ==============================================================================

cat("\n==================== CALCUL DES MOYENNES ====================\n\n")

# Calculer la moyenne de l'incidence pour chaque année (sur tout le Sénégal)
# On ignore les NA (océan et zones hors Sénégal)
moyennes_annuelles <- global(stack_rasters, fun = "mean", na.rm = TRUE)

# Créer un tableau avec année + moyenne
df_stats <- data.frame(
  annee = annees,
  incidence_moyenne = moyennes_annuelles[, 1]  # première colonne = les moyennes
)

cat("Statistiques calculées :\n")
print(head(df_stats, 3))
cat("...\n")
print(tail(df_stats, 3))

# Sauvegarder en CSV
csv_file <- file.path(out_dir, "statistiques_annuelles.csv")
write.csv(df_stats, csv_file, row.names = FALSE)
cat("\n✓ Statistiques sauvegardées :", csv_file, "\n")

# ==============================================================================
# PARTIE 3 : VISUALISATIONS
# ==============================================================================

cat("\n==================== CRÉATION DES VISUALISATIONS ====================\n\n")

# --- Trouver les limites min/max pour avoir une échelle commune ---
# (important pour comparer les années entre elles)
valeurs_toutes <- values(stack_rasters)
val_min <- min(valeurs_toutes, na.rm = TRUE)
val_max <- max(valeurs_toutes, na.rm = TRUE)

cat("Plage des valeurs d'incidence :", round(val_min, 3), "à", round(val_max, 3), "\n\n")

# -----------------------------------------------------------------------------
# GRAPHIQUE 1 : ÉVOLUTION TEMPORELLE (Courbe)
# -----------------------------------------------------------------------------

cat("1. Création du graphique d'évolution temporelle...\n")

p_evolution <- ggplot(df_stats, aes(x = annee, y = incidence_moyenne)) +
  geom_line(color = "#2E86AB", size = 1.2) +  # ligne bleue
  geom_point(color = "#A23B72", size = 3) +   # points roses
  geom_smooth(method = "loess", se = TRUE, color = "#F18F01", alpha = 0.2) +  # tendance lissée
  labs(
    title = "Évolution de l'incidence du paludisme au Sénégal (2000-2024)",
    subtitle = "Moyenne annuelle sur l'ensemble du territoire",
    x = "Année",
    y = "Incidence moyenne (cas pour 100 habitants)",
    caption = "Source : Données Pf Incidence Rate"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    panel.grid.minor = element_blank()
  )

# Sauvegarder
graphique_file <- file.path(out_dir, "evolution_temporelle.png")
ggsave(graphique_file, p_evolution, width = 10, height = 6, dpi = 300)
cat("   ✓ Graphique sauvegardé :", graphique_file, "\n\n")

# -----------------------------------------------------------------------------
# GRAPHIQUE 2 : CARTE D'UNE ANNÉE SPÉCIFIQUE (exemple : 2010)
# -----------------------------------------------------------------------------

cat("2. Création d'une carte pour l'année 2010...\n")

# Trouver l'index de l'année 2010 dans le stack
annee_a_cartographier <- 2010
idx_2010 <- which(annees == annee_a_cartographier)

if(length(idx_2010) == 0) {
  cat("   ⚠️  Année 2010 non trouvée, utilisation de l'année médiane\n")
  idx_2010 <- ceiling(nlyr(stack_rasters) / 2)
  annee_a_cartographier <- annees[idx_2010]
}

# Extraire le raster de cette année
raster_2010 <- stack_rasters[[idx_2010]]

# Créer la carte avec ggplot
# D'abord convertir le raster en data.frame pour ggplot
df_raster <- as.data.frame(raster_2010, xy = TRUE)
names(df_raster)[3] <- "incidence"  # renommer la 3e colonne

p_carte <- ggplot() +
  # La couche raster (incidence)
  geom_raster(data = df_raster, aes(x = x, y = y, fill = incidence)) +
  # Les frontières du Sénégal
  geom_sf(data = gadm, fill = NA, color = "black", size = 0.8) +
  # Palette de couleurs (viridis = du bleu au jaune)
  scale_fill_viridis_c(
    option = "plasma",  # options : viridis, plasma, magma, inferno
    na.value = "transparent",
    limits = c(val_min, val_max),
    name = "Incidence"
  ) +
  coord_sf() +
  labs(
    title = paste("Incidence du paludisme au Sénégal -", annee_a_cartographier),
    subtitle = "Valeurs moyennes par pixel (~4.6 km × 4.6 km)",
    x = "Longitude",
    y = "Latitude"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    legend.position = "right"
  )

# Sauvegarder
carte_file <- file.path(out_dir, paste0("carte_", annee_a_cartographier, ".png"))
ggsave(carte_file, p_carte, width = 10, height = 8, dpi = 300)
cat("   ✓ Carte sauvegardée :", carte_file, "\n\n")

# -----------------------------------------------------------------------------
# GRAPHIQUE 3 : COMPARAISON DE 6 ANNÉES (Facettes)
# -----------------------------------------------------------------------------

cat("3. Création d'une comparaison multi-années (facettes)...\n")

# Sélectionner 6 années équidistantes
n_annees_a_montrer <- 6
annees_selectionnees <- round(seq(min(annees), max(annees), 
                                  length.out = n_annees_a_montrer))

# Trouver les indices correspondants
idx_selectionnes <- sapply(annees_selectionnees, function(a) which(annees == a)[1])
idx_selectionnes <- idx_selectionnes[!is.na(idx_selectionnes)]

# Extraire ces couches et les convertir en data.frame
df_multi <- data.frame()
for(i in idx_selectionnes) {
  r <- stack_rasters[[i]]
  df_temp <- as.data.frame(r, xy = TRUE)
  names(df_temp)[3] <- "incidence"
  df_temp$annee <- annees[i]
  df_multi <- rbind(df_multi, df_temp)
}

# Créer le graphique avec facettes (une petite carte par année)
p_facettes <- ggplot() +
  geom_raster(data = df_multi, aes(x = x, y = y, fill = incidence)) +
  geom_sf(data = gadm, fill = NA, color = "black", size = 0.3) +
  scale_fill_viridis_c(
    option = "plasma",
    na.value = "transparent",
    limits = c(val_min, val_max),
    name = "Incidence"
  ) +
  facet_wrap(~ annee, ncol = 3) +  # 3 cartes par ligne
  coord_sf() +
  labs(
    title = "Comparaison de l'incidence du paludisme sur 6 années",
    x = NULL,
    y = NULL
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    strip.text = element_text(face = "bold", size = 11),
    axis.text = element_text(size = 7)
  )

# Sauvegarder
facettes_file <- file.path(out_dir, "comparaison_multi_annees.png")
ggsave(facettes_file, p_facettes, width = 12, height = 8, dpi = 300)
cat("   ✓ Facettes sauvegardées :", facettes_file, "\n\n")

# -----------------------------------------------------------------------------
# GRAPHIQUE 4 : CARTE INTERACTIVE (HTML)
# -----------------------------------------------------------------------------

cat("4. Création d'une carte interactive (HTML)...\n")

# tmap en mode interactif
tmap_mode("view")

# Créer la carte interactive pour l'année 2010
tm_carte <- tm_shape(raster_2010) +
  tm_raster(
    title = paste("Incidence", annee_a_cartographier),
    style = "cont",  # échelle continue
    palette = "plasma",
    breaks = seq(val_min, val_max, length.out = 8)
  ) +
  tm_shape(gadm) +
  tm_borders(col = "black", lwd = 2) +
  tm_layout(
    main.title = paste("Incidence du paludisme -", annee_a_cartographier),
    main.title.size = 1.2,
    legend.outside = TRUE
  )

# Sauvegarder en HTML (vous pourrez l'ouvrir dans un navigateur)
html_file <- file.path(out_dir, paste0("carte_interactive_", annee_a_cartographier, ".html"))
tmap_save(tm_carte, filename = html_file)
cat("   ✓ Carte interactive sauvegardée :", html_file, "\n")
cat("     (Ouvrez ce fichier dans votre navigateur pour l'explorer)\n\n")

# ==============================================================================
# RÉSUMÉ FINAL
# ==============================================================================

cat("\n==================== RÉSUMÉ ====================\n\n")
cat("Fichiers créés dans le dossier 'outputs/' :\n")
cat("  1. statistiques_annuelles.csv\n")
cat("  2. evolution_temporelle.png\n")
cat("  3. carte_", annee_a_cartographier, ".png\n", sep = "")
cat("  4. comparaison_multi_annees.png\n")
cat("  5. carte_interactive_", annee_a_cartographier, ".html\n\n", sep = "")
cat("✓ Visualisation terminée !\n")

# Remettre tmap en mode normal
tmap_mode("plot")