# scripts/railways_protected_analysis.R
# Analyse spatiale : buffers autour des chemins de fer + population dans aires protégées

# ---------------------------
# 0. Packages
# ---------------------------
needed <- c("sf","raster","exactextractr","dplyr","htmlwidgets","leaflet","htmltools","readr","units","tibble")
to_install <- needed[!(needed %in% installed.packages()[,"Package"])]
if(length(to_install)) install.packages(to_install)

library(sf)
library(raster)
library(exactextractr)
library(dplyr)
library(leaflet)
library(htmlwidgets)
library(htmltools)
library(readr)
library(units)
library(tibble)

# ---------------------------
# 1. Chemins
# ---------------------------
data_dir <- "data"
out_dir  <- "outputs"
dir.create(out_dir, showWarnings = FALSE)

path_population <- file.path(data_dir, "population", "cmr_pop_2025_CN_100m_R2025A_v1.tif")
rail_dir        <- file.path(data_dir, "railways")
protected_dirs  <- c(file.path(data_dir,"protected_area_niveau0"))
places_path     <- list.files(file.path(data_dir,"points_habitables"), pattern = "\\.shp$", full.names = TRUE)[1]
pois_path       <- list.files(file.path(data_dir,"equipements_sociaux"), pattern = "\\.shp$", full.names = TRUE)[1]
gadm0_path      <- list.files(file.path(data_dir,"limites_niveau0"), pattern = "\\.shp$", full.names = TRUE)[1]
rail_shp_path   <- list.files(rail_dir, pattern = "\\.shp$", full.names = TRUE)[1]

stopifnot(file.exists(path_population))
stopifnot(file.exists(rail_shp_path))
stopifnot(file.exists(places_path))
stopifnot(file.exists(pois_path))
stopifnot(file.exists(gadm0_path))

protected_shp_files <- unlist(lapply(protected_dirs, function(d) {
  if(dir.exists(d)) list.files(d, pattern="\\.shp$", full.names = TRUE) else character(0)
}))
if(length(protected_shp_files)==0) stop("Aucun shapefile d'aires protégées trouvé dans protected_area_niveau*")

# ---------------------------
# 2. Lecture des données
# ---------------------------
pop_r <- raster(path_population)
rails <- st_read(rail_shp_path, quiet = TRUE)
places <- st_read(places_path, quiet = TRUE)
pois <- st_read(pois_path, quiet = TRUE)
gadm0 <- st_read(gadm0_path, quiet = TRUE)

protected_list <- lapply(protected_shp_files, function(p) st_read(p, quiet = TRUE))
protected_sf <- do.call(rbind, protected_list)
protected_sf <- st_make_valid(protected_sf)

# ---------------------------
# 3. Préparer CRS
# ---------------------------
r_crs <- crs(pop_r)
r_crs_proj4 <- as.character(r_crs)
metric_crs <- st_crs(3857)

rails_m <- st_transform(st_make_valid(rails), metric_crs)
places_m <- st_transform(st_make_valid(places), metric_crs)
pois_m <- st_transform(st_make_valid(pois), metric_crs)
protected_m <- st_transform(st_make_valid(protected_sf), metric_crs)
gadm0_m <- st_transform(st_make_valid(gadm0), metric_crs)

# ---------------------------
# 4. Filtrer rails
# ---------------------------
if("fclass" %in% names(rails_m)){
  rails_m <- rails_m %>% filter(tolower(fclass) %in% c("rail","light_rail","railway","railway_link","narrow_gauge","preserved"))
} else if("railway" %in% names(rails_m)){
  rails_m <- rails_m %>% filter(!is.na(railway))
}
rails_m <- st_make_valid(rails_m)
rails_union <- st_union(rails_m)

# ---------------------------
# 5. Créer buffers 1km,5km,10km
# ---------------------------
buffer_dists <- c(1000, 5000, 10000)
buffers_m <- lapply(buffer_dists, function(d) st_buffer(rails_union, dist = d))
names(buffers_m) <- paste0("b", buffer_dists/1000, "km")
buffers_m_union <- setNames(lapply(buffers_m, function(x) st_union(st_make_valid(x))), names(buffers_m))

# ---------------------------
# 6. Reprojeter buffers et autres vers CRS raster
# ---------------------------
r_crs_sf <- st_crs(r_crs_proj4)
buffers_for_extract <- lapply(buffers_m_union, function(b) st_transform(b, crs = r_crs_sf))
protected_for_extract <- st_transform(protected_sf, crs = r_crs_sf)
places_for_extract <- st_transform(places, crs = r_crs_sf)
pois_for_extract <- st_transform(pois, crs = r_crs_sf)

# ---------------------------
# 7. Fonction somme population (arrondie)
# ---------------------------
sum_pop_in_polys <- function(raster_layer, polygons_sf){
  vals <- exactextractr::exact_extract(raster_layer, polygons_sf, 'sum')
  vals[is.na(vals)] <- 0
  vals <- round(vals)  # <-- populations arrondies en entiers
  return(vals)
}

# ---------------------------
# 8. Calculs buffers
# ---------------------------
buffers_results <- list()
for(nm in names(buffers_for_extract)){
  poly <- st_cast(buffers_for_extract[[nm]], "POLYGON")
  pop_sums <- sum_pop_in_polys(pop_r, poly)
  area_km2 <- st_area(st_transform(poly, metric_crs)) %>% set_units("km^2") %>% drop_units()
  
  inter_places <- st_intersects(places_for_extract, poly)
  places_in_buffer <- places_for_extract[lengths(inter_places) > 0, ]
  place_types <- tolower(if("fclass" %in% names(places_in_buffer)) places_in_buffer$fclass else places_in_buffer$name)
  n_city <- sum(place_types=="city", na.rm=TRUE)
  n_town <- sum(place_types=="town", na.rm=TRUE)
  n_village <- sum(place_types=="village", na.rm=TRUE)
  n_hamlet <- sum(place_types=="hamlet", na.rm=TRUE)
  
  pois_in_buffer <- pois_for_extract[lengths(st_intersects(pois_for_extract, poly)) > 0, ]
  poi_types <- tolower(if("fclass" %in% names(pois_in_buffer)) pois_in_buffer$fclass else pois_in_buffer$name)
  n_school <- sum(grepl("school", poi_types), na.rm=TRUE)
  n_hospital <- sum(grepl("hospital", poi_types), na.rm=TRUE)
  n_clinic <- sum(grepl("clinic", poi_types), na.rm=TRUE)
  n_pharmacy <- sum(grepl("pharmacy", poi_types), na.rm=TRUE)
  
  buffers_results[[nm]] <- tibble(
    buffer = nm,
    n_polygons = length(poly),
    area_km2 = sum(as.numeric(area_km2)),
    population = sum(pop_sums, na.rm = TRUE),
    n_city = n_city,
    n_town = n_town,
    n_village = n_village,
    n_hamlet = n_hamlet,
    n_school = n_school,
    n_hospital = n_hospital,
    n_clinic = n_clinic,
    n_pharmacy = n_pharmacy
  )
}
buffers_results_df <- bind_rows(buffers_results)
write_csv(buffers_results_df, file.path(out_dir, "buffers_railways_summary.csv"))

# ---------------------------
# 9. Aires protégées
# ---------------------------
protected_for_extract$wdpaid <- if("WDPAID" %in% names(protected_for_extract)) protected_for_extract$WDPAID else seq_len(nrow(protected_for_extract))
protected_for_extract$NAME <- if("NAME" %in% names(protected_for_extract)) protected_for_extract$NAME else NA

protected_pop <- sum_pop_in_polys(pop_r, protected_for_extract)
protected_area_km2 <- st_area(st_transform(protected_for_extract, metric_crs)) %>% set_units("km^2") %>% drop_units()

prot_counts <- lapply(seq_len(nrow(protected_for_extract)), function(i){
  prot_poly <- protected_for_extract[i,]
  pop_i <- protected_pop[i]
  area_i <- as.numeric(protected_area_km2[i])
  
  places_in <- places_for_extract[lengths(st_intersects(places_for_extract, prot_poly)) > 0, ]
  place_types <- tolower(if("fclass" %in% names(places_in)) places_in$fclass else places_in$name)
  n_city <- sum(place_types=="city", na.rm=TRUE)
  n_town <- sum(place_types=="town", na.rm=TRUE)
  n_village <- sum(place_types=="village", na.rm=TRUE)
  n_hamlet <- sum(place_types=="hamlet", na.rm=TRUE)
  
  pois_in <- pois_for_extract[lengths(st_intersects(pois_for_extract, prot_poly)) > 0, ]
  poi_types <- tolower(if("fclass" %in% names(pois_in)) pois_in$fclass else pois_in$name)
  n_school <- sum(grepl("school", poi_types), na.rm=TRUE)
  n_hospital <- sum(grepl("hospital", poi_types), na.rm=TRUE)
  n_clinic <- sum(grepl("clinic", poi_types), na.rm=TRUE)
  n_pharmacy <- sum(grepl("pharmacy", poi_types), na.rm=TRUE)
  
  tibble(
    wdpaid = protected_for_extract$wdpaid[i],
    name = protected_for_extract$NAME[i],
    area_km2 = area_i,
    population = pop_i,
    n_city = n_city,
    n_town = n_town,
    n_village = n_village,
    n_hamlet = n_hamlet,
    n_school = n_school,
    n_hospital = n_hospital,
    n_clinic = n_clinic,
    n_pharmacy = n_pharmacy
  )
})
protected_results_df <- bind_rows(prot_counts)
write_csv(protected_results_df, file.path(out_dir, "protected_areas_summary.csv"))

# ---------------------------
# 10. Carte interactive : Buffers
# ---------------------------
message("Construction de la carte interactive buffers...")

check_empty <- function(x) {
  is.null(x) || length(x) == 0 || (inherits(x, "sf") && nrow(x) == 0) || (inherits(x, "sfc") && length(x) == 0)
}

rails_4326 <- st_transform(rails_union, 4326)
buffers_4326 <- lapply(buffers_m_union, function(x){
  if(!check_empty(x)) st_transform(x, 4326) else NULL
})

buffers_4326_col <- list()
for(nm in names(buffers_4326)){
  buf <- buffers_4326[[nm]]
  if(!check_empty(buf)){
    buf <- st_make_valid(buf)
    if(inherits(buf, "sfc_POLYGON") || inherits(buf, "sfc_MULTIPOLYGON")){
      buf <- st_cast(buf, "POLYGON", warn = FALSE)
    }
    buf <- st_sf(geometry = buf)
    if(nrow(buf) > 0) buffers_4326_col[[nm]] <- buf
  }
}

buffer_popups <- list()
for(nm in names(buffers_4326_col)){
  row <- buffers_results_df %>% filter(buffer == nm)
  popup_text <- paste0(
    "<strong>", nm, "</strong><br/>",
    "Population: ", row$population, "<br/>",
    "Villes: ", row$n_city, "<br/>",
    "Towns: ", row$n_town, "<br/>",
    "Villages: ", row$n_village, "<br/>",
    "Hamlets: ", row$n_hamlet, "<br/>",
    "Écoles: ", row$n_school, "<br/>",
    "Hôpitaux: ", row$n_hospital, "<br/>",
    "Cliniques: ", row$n_clinic, "<br/>",
    "Pharmacies: ", row$n_pharmacy
  )
  buffer_popups[[nm]] <- rep(popup_text, nrow(buffers_4326_col[[nm]]))
}

buffer_colors_fill <- c("b1" = "green", "b5" = "orange", "b10" = "red")
buffer_colors_contour <- c("b1" = "#006400", "b5" = "#FF8C00", "b10" = "#8B0000")
buffer_names_short <- gsub("km","", names(buffers_4326_col))

m_buffers <- leaflet() %>% addTiles(group = "OSM (default)")

buffer_order <- c("b10","b5","b1")
for(nm_short in buffer_order){
  i <- which(buffer_names_short == nm_short)
  buf <- buffers_4326_col[[i]]
  nm_full <- names(buffers_4326_col)[i]
  
  fill_col <- buffer_colors_fill[[nm_short]]
  contour_col <- buffer_colors_contour[[nm_short]]
  group_name <- paste0("Buffer ", gsub("b","",nm_short), " km")
  
  m_buffers <- m_buffers %>% addPolygons(
    data = buf,
    color = contour_col,
    fillColor = fill_col,
    fillOpacity = 1,
    weight = 1,
    group = group_name,
    popup = buffer_popups[[nm_full]]
  )
}

m_buffers <- m_buffers %>% addPolylines(
  data = rails_4326, color = "black", weight = 2, group = "Railways"
)

overlay_groups_buffers <- c("Buffer 10 km", "Buffer 5 km", "Buffer 1 km", "Railways")
m_buffers <- m_buffers %>% addLayersControl(
  overlayGroups = overlay_groups_buffers,
  options = layersControlOptions(collapsed = FALSE)
)

m_buffers <- m_buffers %>% addLegend(
  position = "bottomright",
  colors = c(buffer_colors_fill["b10"], buffer_colors_fill["b5"], buffer_colors_fill["b1"]),
  labels = c("Buffer 10 km", "Buffer 5 km", "Buffer 1 km"),
  title = "Buffers ferroviaires",
  opacity = 1
)

htmlwidgets::saveWidget(m_buffers, file.path(out_dir, "chemin_de_fer.html"), selfcontained = TRUE)
message("Carte buffers enregistrée.")

# ---------------------------
# 11. Carte interactive : Aires protégées
# ---------------------------
protected_4326 <- st_transform(protected_sf, 4326)

protected_popup <- paste0(
  "<strong>", ifelse(is.na(protected_4326$NAME), "Aire protégée", protected_4326$NAME), "</strong><br/>",
  "Population: ", protected_results_df$population, "<br/>",
  "Villes: ", protected_results_df$n_city, "<br/>",
  "Towns: ", protected_results_df$n_town, "<br/>",
  "Villages: ", protected_results_df$n_village, "<br/>",
  "Hamlets: ", protected_results_df$n_hamlet, "<br/>",
  "Écoles: ", protected_results_df$n_school, "<br/>",
  "Hôpitaux: ", protected_results_df$n_hospital, "<br/>",
  "Cliniques: ", protected_results_df$n_clinic, "<br/>",
  "Pharmacies: ", protected_results_df$n_pharmacy
)
protected_popup <- protected_popup[1:nrow(protected_4326)]

m_protected <- leaflet() %>% addTiles(group = "OSM (default)")

if(!check_empty(protected_4326)){
  m_protected <- m_protected %>% addPolygons(
    data = protected_4326,
    color = "darkgreen",
    fillColor = "green",
    fillOpacity = 0.6,
    weight = 1,
    group = "Protected areas",
    popup = protected_popup
  )
}

htmlwidgets::saveWidget(m_protected, file.path(out_dir, "aires_proteges.html"), selfcontained = TRUE)
message("Carte aires protégées enregistrée.")
