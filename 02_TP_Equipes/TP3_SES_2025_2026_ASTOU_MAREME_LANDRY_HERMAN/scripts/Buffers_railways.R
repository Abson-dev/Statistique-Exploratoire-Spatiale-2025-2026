# --- 1. INSTALLATION ET CHARGEMENT DES PACKAGES ---
# Décommenter la ligne ci-dessous si le package n'est pas installé
# install.packages(c("sf", "terra", "dplyr", "exactextractr", "leaflet", "raster"))

# Packages essentiels
library(sf)
library(terra)       
library(dplyr)
library(exactextractr) 
library(leaflet)     
library(raster)      

library(htmlwidgets)

# --- 2. CONFIGURATION ET IMPORTATION DES DONNÉES ---

# Assurez-vous que les chemins d'accès sont corrects
railways <- st_read("data/railways/gis_osm_railways_free_1.shp")
gadm0 <- st_read("data/GADM_CMR/gadm41_CMR_0.shp")
gadm1 <- st_read("data/GADM_CMR/gadm41_CMR_1.shp") # Limites des régions (Niveau 1)
pop <- rast("data/cmr_pop_2025_CN_100m_R2024B_v1.tif")

# CRS de travail (UTM Zone 32N pour les distances en mètres)
target_crs <- "EPSG:32632"

# --- 3. PRÉTRAITEMENT ET CALCULS FONDAMENTAUX ---

# Reprojection pour le calcul (précision des surfaces/distances)
railways_proj <- st_transform(railways, target_crs)
gadm0_proj <- st_transform(gadm0, target_crs)
gadm1_proj <- st_transform(gadm1, target_crs)
pop_proj <- project(pop, target_crs) # Raster de population reprojeté

# Filtrage des chemins de fer sur la limite du Cameroun
railways_cmr <- st_intersection(railways_proj, gadm0_proj)

#  Calculer la population totale de chaque région (GADM1)
gadm1_proj$pop_region_total <- exact_extract(pop_proj, gadm1_proj, 'sum')

# CORRECTION : Utiliser dplyr::select()
gadm1_pop_data <- gadm1_proj %>% 
  st_drop_geometry() %>% 
  dplyr::select(NAME_1, pop_region_total)

# --- 4. CRÉATION DES BUFFERS ET JOINTURE SPATIALE ---

distances_m <- (1:10) * 1000 
buffers_list <- list()

# 4.1 Boucle de création des buffers (géométrie unifiée)
for (dist in distances_m) {
  # Création et fusion des zones tampons
  current_buffer <- st_buffer(railways_cmr, dist = dist) %>%
    st_union() %>%
    st_sf() 
  
  current_buffer$distance_km <- dist / 1000
  buffers_list[[as.character(dist)]] <- current_buffer
}

buffers_cmr <- do.call(rbind, buffers_list) %>%
  arrange(distance_km) 

#  Intersection spatiale des buffers avec les régions
# Cela fragmente chaque buffer en autant de pièces qu'il traverse de régions.
buffers_by_region <- st_intersection(buffers_cmr, gadm1_proj)

#  Recalculer la population pour chaque fragment de buffer
# Utilise la géométrie fragmentée pour une précision maximale
buffers_by_region$population_served <- exact_extract(pop_proj, buffers_by_region, 'sum')

# CORRECTION : Utiliser dplyr::select() et gérer correctement les colonnes
buffers_by_region <- buffers_by_region %>%
  left_join(gadm1_pop_data, by = "NAME_1") %>%
  # Supprimer la colonne en double si elle existe
  dplyr::select(-any_of(c("pop_region_total.x"))) %>%
  # Renommer la colonne jointe
  rename(pop_region_total = pop_region_total.y)

# --- 5. PRÉPARATION POUR LEAFLET (EPSG:4326) ---

# Reprojection en EPSG:4326 pour Leaflet
crs_leaflet <- "EPSG:4326"
railways_leaflet <- st_transform(railways_cmr, crs = crs_leaflet)
gadm1_leaflet <- st_transform(gadm1_proj, crs = crs_leaflet)
buffers_by_region_leaflet <- st_transform(buffers_by_region, crs = crs_leaflet)

# Création des Pop-ups Améliorés
buffers_by_region_leaflet <- buffers_by_region_leaflet %>%
  mutate(
    popup_label_enhanced = paste(
      "**Région :** ", NAME_1, "<br/>",
      "**Distance Buffer :** ", distance_km, " km", "<br/>",
      "---<br/>",
      "**Pop. Desservie (fragment) :** ", format(round(population_served), big.mark = " "), " pers.", "<br/>",
      "**Pop. Totale Région :** ", format(round(pop_region_total), big.mark = " "), " pers."
    ),
    group_name = paste("Buffer", distance_km, "km")
  )

# Préparation du Raster de Population (Rééchantillonnage fact=4)
pop_4326 <- project(pop, crs_leaflet)
pop_downsampled_terra <- terra::aggregate(pop_4326, fact = 4, fun = "sum")
pop_raster_fast <- raster(pop_downsampled_terra)

# Création des palettes de couleurs
pal_buffer <- colorNumeric(palette = "Greens", domain = 1:10, reverse = TRUE)
#pal_pop_density <- colorNumeric(palette = "YlOrRd", domain = values(pop_raster_fast), na.color = "transparent")
# Code actuel (Linéaire, peu de contraste)
pal_pop_density <- colorNumeric(
  palette = "YlOrRd", 
  domain = values(pop_raster_fast), 
  na.color = "transparent"
)

# --- 6. CRÉATION DE LA CARTE INTERACTIVE LEAFLET ---

map_final <- leaflet() %>%
  addProviderTiles(providers$CartoDB.Positron, group = "Fond de carte") %>%
  setView(lng = 12.73, lat = 5.50, zoom = 6)

# 6.1 Ajout de la couche de densité de population
map_final <- map_final %>%
  addRasterImage(
    pop_raster_fast, 
    colors = pal_pop_density, 
    opacity = 0.6, 
    group = "Densité de Population (Pixels)"
  ) %>%
  addLegend(
    "topleft", 
    pal = pal_pop_density, 
    values = values(pop_raster_fast),
    title = "Densité de Population",
    opacity = 0.6
  )

# 6.2 Ajout des Chemins de Fer (Rouge foncé)
map_final <- map_final %>%
  addPolylines(
    data = railways_leaflet,
    color = "darkred",
    weight = 3,
    group = "Chemins de Fer"
  )

# 6.3 Ajout des Limites des Régions (GADM1) - Rendu au-dessus des buffers
map_final <- map_final %>%
  addPolygons(
    data = gadm1_leaflet,
    fill = FALSE,         
    color = "blue",       
    weight = 1.5,
    opacity = 0.8,
    group = "Limites des Régions (GADM1)",
    popup = ~NAME_1       
  ) 

# 6.4 Ajout de chaque Buffer (fragments) comme une couche sélectionnable
for (dist_km in 1:10) { 
  # Filtrer les fragments appartenant au buffer de cette distance
  current_buffer_fragments <- buffers_by_region_leaflet %>%
    filter(distance_km == dist_km)
  
  if(nrow(current_buffer_fragments) > 0) {
    map_final <- map_final %>%
      addPolygons(
        data = current_buffer_fragments,
        fillColor = pal_buffer(dist_km), # Couleur selon la distance (Vert foncé pour 1km, Clair pour 10km)
        fillOpacity = 0.7,
        color = "black", 
        weight = 0.5,
        popup = ~popup_label_enhanced, # Utilisation du pop-up enrichi
        group = paste("Buffer", dist_km, "km") # Nom du groupe
      )
  }
}

# 6.5 Ajout du Contrôle des Couches (Sélection)
map_final <- map_final %>%
  addLayersControl(
    baseGroups = c("Fond de carte"),
    overlayGroups = c(
      "Densité de Population (Pixels)",
      "Chemins de Fer",
      "Limites des Régions (GADM1)", # Les limites des régions sont dans les overlays
      unique(buffers_by_region_leaflet$group_name) # Liste des 10 buffers
    ),
    options = layersControlOptions(collapsed = FALSE)
  ) %>%
  showGroup("Densité de Population (Pixels)") %>%
  showGroup("Chemins de Fer")

# Afficher la carte finale
map_final

saveWidget(
  widget = map_final,
  file = "outputs/carte_interactive_rail_cameroun.html", 
  selfcontained = TRUE 
)