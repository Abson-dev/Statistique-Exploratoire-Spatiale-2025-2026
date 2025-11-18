# =============================================================================
# TP - STATISTIQUES EXPLORATOIRES SPATIALES
# Analyse des 13 couches géographiques du Cameroun
# =============================================================================

# INSTALLATION DES PACKAGES (décommenter si nécessaire)

# install.packages(c("sf", "dplyr", "ggplot2", "mapview", "tmap", "units", "nngeo", "webshot2"))
# webshot2::install_phantomjs()

# charger les packages 

#library(webshot)
#library(sf)          # Données spatiales
#library(dplyr)       # Manipulation de données
#library(ggplot2)     # Visualisations
#library(mapview)     # Cartes interactives
#library(tmap)        # Cartes thématiques
#library(units)       # Gestion des unités
#library(nngeo)       # Analyses de voisinage

# Définir le répertoire de travail (dossier)
#setwd("C:/Users/bmd/Music/TP1_SES_2025_2026_ASTOU_MAREME_LANDRY_YAMAHA")


# creer une fonction pour charger les donnees 

charger_donnees_osm <- function() {
  cat("Chargement des données du Cameroun...\n\n")
  
  base <- file.path(base_path, "data/data1")
  
  
  donnees <- list()
  
  # --- 1. LIMITES ADMINISTRATIVES ---
  donnees$limites_n0 <- st_read(file.path(base, "limites_niveau0", "gadm41_CMR_0.shp"), quiet = TRUE)
  donnees$limites_n1 <- st_read(file.path(base, "limites_niveau1", "gadm41_CMR_1.shp"), quiet = TRUE)
  donnees$limites_n2 <- st_read(file.path(base, "limites_niveau2", "gadm41_CMR_2.shp"), quiet = TRUE)
  
  # Pour les cartes principales, on utilise le niveau 1
  donnees$limites <- donnees$limites_n1
  
  # --- 2. AIRES PROTÉGÉES (polygones) ---
  donnees$protected_n0 <- st_read(file.path(base, "protected_area_niveau0", "WDPA_WDOECM_Nov2025_Public_CMR_shp-polygons.shp"), quiet = TRUE)
  donnees$protected_n1 <- st_read(file.path(base, "protected_area_niveau1", "WDPA_WDOECM_Nov2025_Public_CMR_shp-polygons.shp"), quiet = TRUE)
  donnees$protected_n2 <- st_read(file.path(base, "protected_area_niveau2", "WDPA_WDOECM_Nov2025_Public_CMR_shp-polygons.shp"), quiet = TRUE)
  
  # --- 3. POINTS HABITABLES (villes, villages…) ---
  places <- st_read(file.path(base, "points_habitables", "gis_osm_places_free_1.shp"), quiet = TRUE)
  
  donnees$cities   <- filter(places, fclass == "city")
  donnees$towns    <- filter(places, fclass == "town")
  donnees$villages <- filter(places, fclass == "village")
  donnees$hamlets  <- filter(places, fclass == "hamlet")
  donnees$suburbs  <- filter(places, fclass == "suburb")
  
  # --- 4. EQUIPEMENTS SOCIAUX (santé + éducation) ---
  pois <- st_read(file.path(base, "equipements_sociaux", "gis_osm_pois_free_1.shp"), quiet = TRUE)
  
  # Santé
  donnees$hospitals  <- filter(pois, fclass == "hospital")
  donnees$clinics    <- filter(pois, fclass == "clinic")
  donnees$pharmacies <- filter(pois, fclass == "pharmacy")
  
  # Éducation
  donnees$schools    <- filter(pois, fclass == "school")
  
  # --- 5. RAILWAYS ---
  railways <- st_read(file.path(base, "railways", "gis_osm_railways_free_1.shp"), quiet = TRUE)
  donnees$railways <- filter(railways, fclass == "rail")
  
  # --- 6. HYDROGRAPHIE ---
  waterways <- st_read(file.path(base, "waterways", "gis_osm_waterways_free_1.shp"), quiet = TRUE)
  water_poly <- st_read(file.path(base, "water_polygone", "gis_osm_water_a_free_1.shp"), quiet = TRUE)
  
  donnees$rivers <- filter(waterways, fclass == "river")
  donnees$water  <- water_poly
  
  cat("\nToutes les données ont été chargées avec succès !\n")
  return(donnees)
}
donnees_cameroun <- charger_donnees_osm()




# creer une fonction pour visualiser les donnees 

visualiser <- function(donnees) {
  
  # 0) Création du dossier outputs -------------------------------
  if (!dir.exists("outputs")) {
    dir.create("outputs")
  }
  
  limites <- donnees$limites_n1
  
  # --------------------------------------------------------------
  # 1. INFRASTRUCTURES SOCIALES
  # --------------------------------------------------------------
  donnees$schools$type    <- "Schools"
  donnees$hospitals$type  <- "Hospitals"
  donnees$clinics$type    <- "Clinics"
  donnees$pharmacies$type <- "Pharmacies"
  
  infra <- rbind(
    donnees$schools,
    donnees$hospitals, 
    donnees$clinics, 
    donnees$pharmacies
  )
  
  p1 <- ggplot() +
    geom_sf(data = infra, aes(color = type), size = 2.8) +
    scale_color_manual(values = c(
      "Hospitals"="red",
      "Clinics"="orange",
      "Pharmacies"="purple",
      "Schools"="blue"
    )) +
    geom_sf(data = limites, fill = NA, color = "black") +
    labs(title = "Infrastructures sociales - Cameroun", color = "Type") +
    theme_minimal()
  
  #ggsave("outputs/1_infrastructures_sociales.png", p1, width = 12, height = 8)
  
  output_file_path <- file.path(output_dir, "1_infrastructures_sociales.png")
  
  # Enregistrer le graphique
  ggsave(filename = output_file_path,
         width = 12, 
         height = 8, 
         units = "in",
         dpi = 300)
  # --------------------------------------------------------------
  # 2. ETABLISSEMENTS HUMAINS
  # --------------------------------------------------------------
  
  donnees$villages$type <- "Villages"
  donnees$hamlets$type  <- "Hamlets"
  donnees$suburbs$type  <- "Suburbs"
  donnees$cities$type   <- "Cities"
  donnees$towns$type    <- "Towns"
  
  humans <- rbind(
    donnees$villages,
    donnees$hamlets,
    donnees$suburbs,
    donnees$cities, 
    donnees$towns
  )
  
  p2 <- ggplot() +
    geom_sf(data = humans, aes(color = type), size = 2.2) +
    scale_color_manual(values = c(
      "Villages"="green",
      "Hamlets"="purple",
      "Suburbs"="blue",
      "Towns"="orange",
      "Cities"="red"
      
    )) +
    geom_sf(data = limites, fill = NA, color = "black") +
    labs(title = "Établissements humains - Cameroun", color = "Type") +
    theme_minimal()
  
  #ggsave("outputs/2_etablissements_humains.png", p2, width = 12, height = 8)
  
  output_file_path <- file.path(output_dir, "2_etablissements_humains.png")
  
  # Enregistrer le graphique
  ggsave(filename = output_file_path,
         width = 12, 
         height = 8, 
         units = "in",
         dpi = 300)
  
  # --------------------------------------------------------------
  # 3. ESPACES PROTEGES
  # --------------------------------------------------------------
  donnees$protected_n1$type <- "Protected"
  
  p3 <- ggplot() +
    geom_sf(data = limites, fill = NA, color = "black") +
    geom_sf(data = donnees$protected_n1, aes(fill = type), alpha = 0.5) +
    scale_fill_manual(values = c("Protected"="forestgreen")) +
    labs(title = "Espaces protégés - Cameroun", fill = "Zone") +
    theme_minimal()
  
  #ggsave("outputs/3_espaces_proteges.png", p3, width = 12, height = 8)
  
  output_file_path <- file.path(output_dir, "3_espaces_proteges.png")
  
  # Enregistrer le graphique
  ggsave(filename = output_file_path,
         width = 12, 
         height = 8, 
         units = "in",
         dpi = 300)
  
  # --------------------------------------------------------------
  # 4. ESPACES D’EAU (water)
  # --------------------------------------------------------------
  donnees$water$type <- "Water"
  
  p4 <- ggplot() +
    geom_sf(data = donnees$water, aes(fill = type), alpha = 0.5) +
    scale_fill_manual(values = c("Water"="lightblue")) +
    geom_sf(data = limites, fill = NA, color = "black") +
    labs(title = "Espaces d'eau - Cameroun", fill = "Type") +
    theme_minimal()
  
  #ggsave("outputs/4_espaces_eau.png", p4, width = 12, height = 8)
  
  output_file_path <- file.path(output_dir, "4_espaces_eau.png")
  
  # Enregistrer le graphique
  ggsave(filename = output_file_path,
         width = 12, 
         height = 8, 
         units = "in",
         dpi = 300)
  
  # --------------------------------------------------------------
  # 5. POINTS D’EAU (rivers)
  # --------------------------------------------------------------
  donnees$rivers$type <- "Rivers"
  
  p5 <- ggplot() +
    geom_sf(data = donnees$rivers, aes(color = type), size = 1.2) +
    scale_color_manual(values = c("Rivers"="blue")) +
    geom_sf(data = limites, fill = NA, color = "black") +
    labs(title = "Points d’eau (Rivières) - Cameroun", color = "Type") +
    theme_minimal()
  
  #ggsave("outputs/5_points_eau_rivers.png", p5, width = 12, height = 8)
  
  output_file_path <- file.path(output_dir, "5_points_eau_rivers.png")
  
  # Enregistrer le graphique
  ggsave(filename = output_file_path,
         width = 12, 
         height = 8, 
         units = "in",
         dpi = 300)
  
  # --------------------------------------------------------------
  # 6. VOIES FERREES
  # --------------------------------------------------------------
  donnees$railways$type <- "Railways"
  
  p6 <- ggplot() +
    geom_sf(data = limites, fill = NA, color = "black") +
    geom_sf(data = donnees$railways, aes(color = type), linewidth = 2) +
    scale_color_manual(values = c("Railways"="brown")) +
    labs(title = "Voies ferrées - Cameroun", color = "Type") +
    theme_minimal()
  
  #ggsave("outputs/6_voies_ferrees.png", p6, width = 12, height = 8)
  
  output_file_path <- file.path(output_dir, "6_voies_ferrees.png")
  
  # Enregistrer le graphique
  ggsave(filename = output_file_path,
         width = 12, 
         height = 8, 
         units = "in",
         dpi = 300)
  
  cat("\n✔ Les 06 cartes ont été générées dans le dossier : outputs/\n")
}
visualiser(donnees_cameroun)

