# =============================================================================
# Pré Requis
# =============================================================================

#install.packages(c("osmdata", "sf", "dplyr", "ggplot2", "tmap"))

#install.packages("osmextract")
#install.packages("ggspatial")
library(ggspatial)
library(here)
library(osmextract)
library(sf)
library(ggplot2)
library(sf)
library(dplyr)



# chemin du fichier PBF
chemin_pbf <- here("data", "data3", "cameroon-251115.osm.pbf")

# Créer le dossier Output
if (!dir.exists(here("outputs", "cartes"))) {
  dir.create(here("outputs", "cartes"), recursive=TRUE)
}
# =============================================================================
# EXTRACTION DES DONNÉES ET TELECHARGEMENT
# =============================================================================

# TOUS les points
all_points <- oe_read(
  chemin_pbf,
  layer = "points"
)


# pharmacies
extraire_pharmacies <- function(data) {
  # Convertir other_tags en caractères
  data_clean <- data %>%
    mutate(other_tags_char = as.character(other_tags))
  
  # Filtrer
  result <- data_clean %>%
    filter(!is.na(other_tags_char)) %>%
    filter(grepl("pharmacy", other_tags_char, ignore.case = TRUE))
  
  return(result)
}

pharmacies <- extraire_pharmacies(all_points) #284 pharmacies



# ECOLES
extraire_ecoles <- function(data) {
  # Convertir other_tags en caractères
  data_clean <- data %>%
    mutate(other_tags_char = as.character(other_tags))
  
  # Filtrer
  result <- data_clean %>%
    filter(!is.na(other_tags_char)) %>%
    filter(grepl("school", other_tags_char, ignore.case = TRUE))
  
  return(result)
}


ecoles <- extraire_ecoles(all_points)

# Extraire les villes
villes <- oe_read(
  chemin_pbf,
  layer = "points",
  query = "SELECT * FROM points WHERE place IN ('city', 'town', 'village')"
)

# Extraire les routes
routes <- oe_read(
  chemin_pbf,
  layer = "lines",
  query = "SELECT * FROM lines WHERE highway IN ('motorway', 'trunk', 'primary', 'secondary', 'tertiary')"
)

# Extraire leslimites du pays
pays <- oe_read(
  chemin_pbf,
  layer = "multipolygons",
  query = "SELECT * FROM multipolygons WHERE boundary = 'administrative' AND admin_level = '2'"
)


# Extraire les régions
regions <- oe_read(
  chemin_pbf,
  layer = "multipolygons",
  query = "SELECT * FROM multipolygons WHERE boundary = 'administrative' AND admin_level = '4'"
)

# Sauvegarde
st_write(pharmacies, here("data", "data3", "pharmacies.gpkg"), delete_dsn = TRUE)
st_write(ecoles, here("data", "data3", "ecoles.gpkg"), delete_dsn = TRUE)
st_write(villes, here("data", "data3", "villes.gpkg"), delete_dsn = TRUE)
st_write(routes, here("data", "data3", "routes.gpkg"), delete_dsn = TRUE)
st_write(regions, here("data", "data3", "regions.gpkg"), delete_dsn = TRUE)
st_write(pays, here("data", "data3", "pays.gpkg"), delete_dsn = TRUE)










# =============================================================================
# CHARGEMENT DES DONNÉES
# =============================================================================

cat("=== CHARGEMENT DES DONNÉES ===\n")

pays <- st_read(here("data", "data3", "pays.gpkg"), quiet = TRUE)
pharmacies <- st_read(here("data", "data3", "pharmacies.gpkg"), quiet = TRUE)
ecoles <- st_read(here("data", "data3", "ecoles.gpkg"), quiet = TRUE)
villes <- st_read(here("data", "data3", "villes.gpkg"), quiet = TRUE)
routes <- st_read(here("data", "data3", "routes.gpkg"), quiet = TRUE)
regions <- st_read(here("data", "data3", "regions.gpkg"), quiet = TRUE)

# Séparons les villes
villes_city <- villes %>% filter(place == "city")
villes_town <- villes %>% filter(place == "town")
villages <- villes %>% filter(place %in% c("village", "hamlet"))

# Filtre routes
routes_prin_sec <- routes %>% 
  filter(highway %in% c("primary", "secondary", "motorway", "trunk"))



# =============================================================================
# THÈME AVEC ESPACE POUR LÉGENDE
# =============================================================================

theme_carte <- theme_minimal() +
  theme(
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5, margin = margin(b = 10)),
    plot.subtitle = element_text(size = 11, hjust = 0.5, color = "gray40", margin = margin(b = 10)),
    plot.caption = element_text(size = 8, hjust = 1, color = "gray50", margin = margin(t = 10)),
    legend.position = "right",
    legend.title = element_text(size = 12, face = "bold"),
    legend.text = element_text(size = 10),
    legend.key.height = unit(1, "cm"),
    legend.key.width = unit(1, "cm"),
    legend.background = element_rect(fill = "white", color = "gray70", linewidth = 0.5),
    legend.margin = margin(10, 10, 10, 10),
    panel.grid = element_line(color = "gray95", linewidth = 0.2),
    panel.background = element_rect(fill = "white"),
    plot.margin = unit(c(1, 2, 1, 1), "cm")
  )

# =============================================================================
# CARTE 1 : VUE D'ENSEMBLE : 
# =============================================================================

cat("=== CARTE 1 : Vue d'ensemble ===\n")

carte1 <- ggplot() +
  geom_sf(data = pays, fill = NA, color = "black", linewidth = 1.2) +
  geom_sf(data = regions, fill = NA, color = "gray50", linewidth = 0.4, linetype = "dotted") +
  
  # Routes
  #geom_sf(data = routes %>% filter(highway == "residential"), 
  # 	   aes(color = "Résidentielle"), linewidth = 0.3, alpha = 0.4) +
  #geom_sf(data = routes %>% filter(highway == "tertiary"), 
  #	   aes(color = "Tertiaire"), linewidth = 0.4, alpha = 0.5) +
  geom_sf(data = routes %>% filter(highway == "secondary"), 
          aes(color = "Secondaire"), linewidth = 0.5, alpha = 0.7) +
  geom_sf(data = routes %>% filter(highway == "primary"), 
          aes(color = "Principale"), linewidth = 0.7, alpha = 0.8) +
  geom_sf(data = routes %>% filter(highway %in% c("motorway", "trunk")), 
          aes(color = "Autoroute"), linewidth = 0.9, alpha = 0.9) +
  
  scale_color_manual(
    name = "Type de route",
    values = c(
      "Autoroute" = "#DC143C",
      "Principale" = "#FF8C00",
      "Secondaire" = "#FFD700"
      #"Tertiaire" = "#FFFF99",
      #"Résidentielle" = "#CCCCCC"
    ),
    breaks = c("Autoroute", "Principale", "Secondaire"#, "Tertiaire", "Résidentielle"
    )
  ) +
  
  # Villages
  geom_sf(data = villages, aes(fill = "Village"), color = "#D2B48C", 
          size = 0.8, alpha = 0.6, shape = 21, stroke = 0) +
  
  # Villes
  geom_sf(data = villes_town, aes(fill = "Bourg"), color = "#FF8C00", 
          size = 3.5, alpha = 0.8, shape = 21, stroke = 0) +
  geom_sf(data = villes_city, aes(fill = "Ville"), color = "#DC143C", 
          size = 6, alpha = 0.9, shape = 21, stroke = 0) +
  
  scale_fill_manual(
    name = "Localités",
    values = c(
      "Ville" = "#DC143C",
      "Bourg" = "#FF8C00",
      "Village" = "#D2B48C"
    ),
    labels = c(
      sprintf("Ville (%s)", nrow(villes_city)),
      sprintf("Bourg (%s)", nrow(villes_town)),
      sprintf("Village (%s)", nrow(villages))
    )
  ) +
  
  # Pharmacies
  geom_sf(data = pharmacies, aes(shape = "Pharmacie"), 
          color = "#228B22", size = 3, stroke = 1.2, alpha = 0.9) +
  
  # Écoles
  geom_sf(data = ecoles, aes(shape = "École"), 
          color = "#00BFFF", size = 1.5, alpha = 0.8) +
  
  scale_shape_manual(
    name = "Services",
    values = c(
      "Pharmacie" = 3, # Croix
      "École" = 17 # Triangle
    ),
    labels = c(
      sprintf("Pharmacie (%s)", nrow(pharmacies)),
      sprintf("École (%s)", nrow(ecoles))
    )
  ) +
  
  annotation_scale(location = "bl", width_hint = 0.25) +
  annotation_north_arrow(location = "tl", which_north = "true",
                         style = north_arrow_fancy_orienteering,
                         height = unit(1.2, "cm"), width = unit(1.2, "cm")) +
  
  labs(
    title = "Infrastructure du Cameroun - Vue d'ensemble",
    subtitle = "Routes, localités, écoles et pharmacies",
    caption = "Source: OpenStreetMap"
  ) +
  
  theme_carte +
  guides(
    color = guide_legend(order = 1, override.aes = list(linewidth = 3)),
    fill = guide_legend(order = 2, override.aes = list(size = 5, shape = 21)),
    shape = guide_legend(order = 3, override.aes = list(size = 4))
  )

ggsave(here("outputs", "cartes", "01_vue_ensemble.png"), 
       carte1, width = 17, height = 11, dpi = 300, bg = "white")
cat("✓ Carte 1 sauvegardée\n\n")

# =============================================================================
# CARTE 2 : ÉCOLES UNIQUEMENT
# =============================================================================

cat("=== CARTE 2 : Écoles ===\n")

carte2 <- ggplot() +
  geom_sf(data = pays, fill = NA, color = "black", linewidth = 1.2) +
  geom_sf(data = regions, fill = NA, color = "gray50", linewidth = 0.4, linetype = "dotted") +
  
  geom_sf(data = ecoles, aes(color = "École"), size = 2.5, shape = 17, alpha = 0.8) +
  
  scale_color_manual(
    name = "Infrastructure\néducative",
    values = c("École" = "#228B22"),
    labels = sprintf("École (%s)", nrow(ecoles))
  ) +
  
  annotation_scale(location = "bl", width_hint = 0.25) +
  annotation_north_arrow(location = "tl", which_north = "true",
                         style = north_arrow_fancy_orienteering,
                         height = unit(1.2, "cm"), width = unit(1.2, "cm")) +
  
  labs(
    title = "Distribution des écoles au Cameroun",
    subtitle = sprintf("Total : %s écoles recensées", nrow(ecoles)),
    caption = "Source: OpenStreetMap"
  ) +
  
  theme_carte +
  guides(color = guide_legend(override.aes = list(size = 5)))

ggsave(here("outputs", "cartes", "02_ecoles.png"), 
       carte2, width = 14, height = 10, dpi = 300, bg = "white")
cat("✓ Carte 2 sauvegardée\n\n")

# =============================================================================
# CARTE 3 : PHARMACIES UNIQUEMENT
# =============================================================================

cat("=== CARTE 3 : Pharmacies ===\n")

carte3 <- ggplot() +
  geom_sf(data = pays, fill = NA, color = "black", linewidth = 1.2) +
  geom_sf(data = regions, fill = NA, color = "gray50", linewidth = 0.4, linetype = "dotted") +
  
  geom_sf(data = pharmacies, aes(color = "Pharmacie"), size = 3.5, shape = 3, 
          stroke = 1.5, alpha = 0.9) +
  
  scale_color_manual(
    name = "Infrastructure\nsanitaire",
    values = c("Pharmacie" = "#DC143C"),
    labels = sprintf("Pharmacie (%s)", nrow(pharmacies))
  ) +
  
  annotation_scale(location = "bl", width_hint = 0.25) +
  annotation_north_arrow(location = "tl", which_north = "true",
                         style = north_arrow_fancy_orienteering,
                         height = unit(1.2, "cm"), width = unit(1.2, "cm")) +
  
  labs(
    title = "Distribution des pharmacies au Cameroun",
    subtitle = sprintf("Total : %s pharmacies recensées", nrow(pharmacies)),
    caption = "Source: OpenStreetMap"
  ) +
  
  theme_carte +
  guides(color = guide_legend(override.aes = list(size = 5, stroke = 2)))

ggsave(here("outputs", "cartes", "03_pharmacies.png"), 
       carte3, width = 14, height = 10, dpi = 300, bg = "white")
cat("✓ Carte 3 sauvegardée\n\n")

# =============================================================================
# CARTE 4 : RÉSEAU ROUTIER
# =============================================================================

cat("=== CARTE 4 : Réseau routier ===\n")

carte4 <- ggplot() +
  geom_sf(data = pays, fill = NA, color = "black", linewidth = 1.2) +
  geom_sf(data = regions, fill = NA, color = "gray60", linewidth = 0.3, linetype = "dotted") +
  
  geom_sf(data = routes %>% filter(highway == "residential"), 
          aes(color = "Résidentielle", size = "Résidentielle"), alpha = 0.5) +
  geom_sf(data = routes %>% filter(highway == "tertiary"), 
          aes(color = "Tertiaire", size = "Tertiaire"), alpha = 0.6) +
  geom_sf(data = routes %>% filter(highway == "secondary"), 
          aes(color = "Secondaire", size = "Secondaire"), alpha = 0.7) +
  geom_sf(data = routes %>% filter(highway == "primary"), 
          aes(color = "Principale", size = "Principale"), alpha = 0.8) +
  geom_sf(data = routes %>% filter(highway %in% c("motorway", "trunk")), 
          aes(color = "Autoroute", size = "Autoroute"), alpha = 0.9) +
  
  scale_color_manual(
    name = "Type de route",
    values = c(
      "Autoroute" = "#DC143C",
      "Principale" = "#FF8C00",
      "Secondaire" = "#FFD700",
      "Tertiaire" = "#FFFF99",
      "Résidentielle" = "#CCCCCC"
    )
  ) +
  
  scale_size_manual(
    name = "Type de route",
    values = c(
      "Autoroute" = 1.5,
      "Principale" = 1.2,
      "Secondaire" = 0.9,
      "Tertiaire" = 0.6,
      "Résidentielle" = 0.3
    )
  ) +
  
  annotation_scale(location = "bl", width_hint = 0.25) +
  annotation_north_arrow(location = "tl", which_north = "true",
                         style = north_arrow_fancy_orienteering,
                         height = unit(1.2, "cm"), width = unit(1.2, "cm")) +
  
  labs(
    title = "Réseau routier du Cameroun",
    subtitle = sprintf("Total : %s segments de routes", nrow(routes)),
    caption = "Source: OpenStreetMap | Hiérarchie routière"
  ) +
  
  theme_carte +
  guides(
    color = guide_legend(override.aes = list(linewidth = 3)),
    size = guide_legend(override.aes = list(linewidth = c(3, 2.5, 2, 1.5, 1)))
  )

ggsave(here("outputs", "cartes", "04_reseau_routier.png"), 
       carte4, width = 14, height = 10, dpi = 300, bg = "white")
cat("✓ Carte 4 sauvegardée\n\n")

# =============================================================================
# CARTE 5 : VILLES ET VILLAGES
# =============================================================================

cat("=== CARTE 5 : Villes et villages ===\n")

carte5 <- ggplot() +
  geom_sf(data = pays, fill = NA, color = "black", linewidth = 1.2) +
  geom_sf(data = regions, fill = NA, color = "gray50", linewidth = 0.4, linetype = "dotted") +
  
  geom_sf(data = villages, aes(color = "Village", size = "Village"), alpha = 0.6, shape = 20) +
  geom_sf(data = villes_town, aes(color = "Bourg", size = "Bourg"), alpha = 0.85, shape = 16) +
  geom_sf(data = villes_city, aes(color = "Ville", size = "Ville"), alpha = 0.95, shape = 16) +
  
  scale_color_manual(
    name = "Type de localité",
    values = c(
      "Ville" = "#DC143C",
      "Bourg" = "#FF8C00",
      "Village" = "#D2B48C"
    ),
    labels = c(
      sprintf("Ville (%s)", nrow(villes_city)),
      sprintf("Bourg (%s)", nrow(villes_town)),
      sprintf("Village (%s)", nrow(villages))
    )
  ) +
  
  scale_size_manual(
    name = "Type de localité",
    values = c(
      "Ville" = 7,
      "Bourg" = 4,
      "Village" = 1.5
    ),
    labels = c(
      sprintf("Ville (%s)", nrow(villes_city)),
      sprintf("Bourg (%s)", nrow(villes_town)),
      sprintf("Village (%s)", nrow(villages))
    )
  ) +
  
  annotation_scale(location = "bl", width_hint = 0.25) +
  annotation_north_arrow(location = "tl", which_north = "true",
                         style = north_arrow_fancy_orienteering,
                         height = unit(1.2, "cm"), width = unit(1.2, "cm")) +
  
  labs(
    title = "Hiérarchie urbaine du Cameroun",
    subtitle = sprintf("Total : %s localités", nrow(villes)),
    caption = "Source: OpenStreetMap"
  ) +
  
  theme_carte

ggsave(here("outputs", "cartes", "05_villes_villages.png"), 
       carte5, width = 14, height = 10, dpi = 300, bg = "white")
cat("✓ Carte 5 sauvegardée\n\n")

# =============================================================================
# CARTE 6 : ÉCOLES + VILLES + VILLAGES
# =============================================================================

cat("=== CARTE 6 : Écoles, villes et villages ===\n")

carte6 <- ggplot() +
  geom_sf(data = pays, fill = NA, color = "black", linewidth = 1.2) +
  geom_sf(data = regions, fill = NA, color = "gray50", linewidth = 0.4, linetype = "dotted") +
  
  geom_sf(data = villages, aes(color = "Village", shape = "Village", size = "Village"), alpha = 0.7) +
  geom_sf(data = villes_town, aes(color = "Bourg", shape = "Bourg", size = "Bourg"), alpha = 0.85) +
  geom_sf(data = villes_city, aes(color = "Ville", shape = "Ville", size = "Ville"), alpha = 0.95) +
  geom_sf(data = ecoles, aes(color = "École", shape = "École", size = "École"), alpha = 0.8) +
  
  scale_color_manual(
    name = "Infrastructure",
    values = c(
      "Ville" = "#DC143C",
      "Bourg" = "#FF8C00",
      "Village" = "#D2B48C",
      "École" = "#228B22"
    ),
    labels = c(
      sprintf("Ville (%s)", nrow(villes_city)),
      sprintf("Bourg (%s)", nrow(villes_town)),
      sprintf("Village (%s)", nrow(villages)),
      sprintf("École (%s)", nrow(ecoles))
    )
  ) +
  
  scale_shape_manual(
    name = "Infrastructure",
    values = c(
      "Ville" = 16,
      "Bourg" = 16,
      "Village" = 20,
      "École" = 17
    ),
    labels = c(
      sprintf("Ville (%s)", nrow(villes_city)),
      sprintf("Bourg (%s)", nrow(villes_town)),
      sprintf("Village (%s)", nrow(villages)),
      sprintf("École (%s)", nrow(ecoles))
    )
  ) +
  
  scale_size_manual(
    name = "Infrastructure",
    values = c(
      "Ville" = 7,
      "Bourg" = 4,
      "Village" = 1.5,
      "École" = 3
    ),
    labels = c(
      sprintf("Ville (%s)", nrow(villes_city)),
      sprintf("Bourg (%s)", nrow(villes_town)),
      sprintf("Village (%s)", nrow(villages)),
      sprintf("École (%s)", nrow(ecoles))
    )
  ) +
  
  annotation_scale(location = "bl", width_hint = 0.25) +
  annotation_north_arrow(location = "tl", which_north = "true",
                         style = north_arrow_fancy_orienteering,
                         height = unit(1.2, "cm"), width = unit(1.2, "cm")) +
  
  labs(
    title = "Infrastructures éducatives et localités",
    subtitle = "Distribution des écoles et du peuplement",
    caption = "Source: OpenStreetMap"
  ) +
  
  theme_carte

ggsave(here("outputs", "cartes", "06_ecoles_villes.png"), 
       carte6, width = 16, height = 10, dpi = 300, bg = "white")
cat("✓ Carte 6 sauvegardée\n\n")

# =============================================================================
# CARTE 7 : ROUTES + ÉCOLES
# =============================================================================

cat("=== CARTE 7 : Routes et écoles ===\n")

carte7 <- ggplot() +
  geom_sf(data = pays, fill = NA, color = "black", linewidth = 1.2) +
  geom_sf(data = regions, fill = NA, color = "gray60", linewidth = 0.3, linetype = "dotted") +
  
  geom_sf(data = routes_prin_sec %>% filter(highway == "secondary"), 
          aes(color = "Secondaire", size = "Secondaire"), alpha = 0.7) +
  geom_sf(data = routes_prin_sec %>% filter(highway == "primary"), 
          aes(color = "Principale", size = "Principale"), alpha = 0.8) +
  geom_sf(data = routes_prin_sec %>% filter(highway %in% c("motorway", "trunk")), 
          aes(color = "Autoroute", size = "Autoroute"), alpha = 0.9) +
  
  scale_color_manual(
    name = "Type de route",
    values = c(
      "Autoroute" = "#DC143C",
      "Principale" = "#FF8C00",
      "Secondaire" = "#FFD700"
    )
  ) +
  
  scale_size_manual(
    name = "Type de route",
    values = c(
      "Autoroute" = 1.5,
      "Principale" = 1.2,
      "Secondaire" = 0.9
    )
  ) +
  
  geom_sf(data = ecoles, aes(fill = "École"), 
          color = "#228B22", size = 2, shape = 24, alpha = 0.8) +
  
  scale_fill_manual(
    name = "Infrastructure\néducative",
    values = c("École" = "#228B22"),
    labels = sprintf("École (%s)", nrow(ecoles))
  ) +
  
  annotation_scale(location = "bl", width_hint = 0.25) +
  annotation_north_arrow(location = "tl", which_north = "true",
                         style = north_arrow_fancy_orienteering,
                         height = unit(1.2, "cm"), width = unit(1.2, "cm")) +
  
  labs(
    title = "Accessibilité routière aux écoles",
    subtitle = sprintf("%s écoles | Réseau routier principal", nrow(ecoles)),
    caption = "Source: OpenStreetMap"
  ) +
  
  theme_carte +
  guides(
    color = guide_legend(order = 1, override.aes = list(linewidth = 3)),
    size = guide_legend(order = 1),
    fill = guide_legend(order = 2, override.aes = list(size = 5, shape = 24))
  )

ggsave(here("outputs", "cartes", "07_routes_ecoles.png"), 
       carte7, width = 16, height = 10, dpi = 300, bg = "white")
cat("✓ Carte 7 sauvegardée\n\n")

# =============================================================================
# CARTE 8 : ROUTES + PHARMACIES
# =============================================================================

cat("=== CARTE 8 : Routes et pharmacies ===\n")

carte8 <- ggplot() +
  geom_sf(data = pays, fill = NA, color = "black", linewidth = 1.2) +
  geom_sf(data = regions, fill = NA, color = "gray60", linewidth = 0.3, linetype = "dotted") +
  
  #geom_sf(data = routes_prin_sec %>% filter(highway == "secondary"), 
  #	   aes(color = "Secondaire", size = "Secondaire"), alpha = 0.7) +
  geom_sf(data = routes_prin_sec %>% filter(highway == "primary"), 
          aes(color = "Principale", size = "Principale"), alpha = 0.8) +
  geom_sf(data = routes_prin_sec %>% filter(highway %in% c("motorway", "trunk")), 
          aes(color = "Autoroute", size = "Autoroute"), alpha = 0.9) +
  
  scale_color_manual(
    name = "Type de route",
    values = c(
      "Autoroute" = "#DC143C",
      "Principale" = "#FF8C00"
      #"Secondaire" = "#FFD700"
    )
  ) +
  
  scale_size_manual(
    name = "Type de route",
    values = c(
      "Autoroute" = 1.5,
      "Principale" = 1.2
      #"Secondaire" = 0.9
    )
  ) +
  
  geom_sf(data = pharmacies, aes(shape = "Pharmacie"), 
          color = "#228B22", size = 3, stroke = 1.3, alpha = 0.9) +
  
  scale_shape_manual(
    name = "Infrastructure\nsanitaire",
    values = c("Pharmacie" = 3),
    labels = sprintf("Pharmacie (%s)", nrow(pharmacies))
  ) +
  
  annotation_scale(location = "bl", width_hint = 0.25) +
  annotation_north_arrow(location = "tl", which_north = "true",
                         style = north_arrow_fancy_orienteering,
                         height = unit(1.2, "cm"), width = unit(1.2, "cm")) +
  
  labs(
    title = "Accessibilité routière aux pharmacies",
    subtitle = sprintf("%s pharmacies | Réseau routier principal", nrow(pharmacies)),
    caption = "Source: OpenStreetMap"
  ) +
  
  theme_carte +
  guides(
    color = guide_legend(order = 1, override.aes = list(linewidth = 3)),
    size = guide_legend(order = 1),
    shape = guide_legend(order = 2, override.aes = list(size = 5, stroke = 2))
  )

ggsave(here("outputs", "cartes", "08_routes_pharmacies.png"), 
       carte8, width = 16, height = 10, dpi = 300, bg = "white")
cat("✓ Carte 8 sauvegardée\n\n")

# =============================================================================
# CARTE 9 : Ecoles et pharmacies avec villes 
# =============================================================================



carte9 <- ggplot() +
  geom_sf(data = pays, fill = NA, color = "black", linewidth = 1.2) +
  geom_sf(data = regions, fill = NA, color = "gray50", linewidth = 0.4, linetype = "dotted") +
  
  
  # Villages
  geom_sf(data = villages, aes(fill = "Village"), color = "#D2B48C", 
          size = 0.8, alpha = 0.6, shape = 21, stroke = 0) +
  
  # Villes
  geom_sf(data = villes_town, aes(fill = "Bourg"), color = "#FF8C00", 
          size = 3.5, alpha = 0.8, shape = 21, stroke = 0) +
  geom_sf(data = villes_city, aes(fill = "Ville"), color = "#DC143C", 
          size = 4, alpha = 0.9, shape = 21, stroke = 0) +
  
  scale_fill_manual(
    name = "Localités",
    values = c(
      "Ville" = "#DC143C",
      "Bourg" = "#FF8C00",
      "Village" = "#D2B48C"
    ),
    labels = c(
      sprintf("Ville (%s)", nrow(villes_city)),
      sprintf("Bourg (%s)", nrow(villes_town)),
      sprintf("Village (%s)", nrow(villages))
    )
  ) +
  
  # Écoles
  geom_sf(data = ecoles, aes(shape = "École"), 
          color = "#00BFFF", size =3, alpha = 0.8) +
  
  scale_shape_manual(
    name = "Services",
    values = c(
      "École" = 3, 
      "Pharmacie" = 17
    ),
    labels = c(
      sprintf("Pharmacie (%s)", nrow(pharmacies)),
      sprintf("École (%s)", nrow(ecoles))
    )
  ) +
  
  # Pharmacies
  geom_sf(data = pharmacies, aes(shape = "Pharmacie"), 
          color = "#228B22", size = 5, stroke = 1.2, alpha = 0.9) +
  
  annotation_scale(location = "bl", width_hint = 0.25) +
  annotation_north_arrow(location = "tl", which_north = "true",
                         style = north_arrow_fancy_orienteering,
                         height = unit(1.2, "cm"), width = unit(1.2, "cm")) +
  
  labs(
    title = "Infrastructure du Cameroun - vue d'ensemble",
    subtitle = "Routes, localités, écoles et pharmacies",
    caption = "Source: OpenStreetMap"
  ) +
  
  theme_carte +
  guides(
    color = guide_legend(order = 1, override.aes = list(linewidth = 3)),
    fill = guide_legend(order = 2, override.aes = list(size = 5, shape = 21)),
    shape = guide_legend(order = 3, override.aes = list(size = 4))
  )

ggsave(here("outputs", "09_pharma&ecoles.png"),
       carte9, width = 17, height = 11, dpi = 300, bg = "white")
cat("✓ Carte 9 sauvegardée\n\n")