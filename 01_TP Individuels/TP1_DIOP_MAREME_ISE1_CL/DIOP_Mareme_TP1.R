#====================================================================================#
#     ENSAE Pierre NDIAYE de Dakar ISE1-Cycle long 2025-2026                         #
#     COURS DE Statistique exploratoire spaciale       avec M.Aboubacre HEMA         #
#    Devoir de maison : TP individuel                                                #
#                                                                                    #
#      Fait par DIOP MAREME                                                                              #
#                                                                                    #
#                                                                                    #
#                                                                                    #
#====================================================================================#

                

# L'Angola (AGO_0) est subdivisé en 18 provinces  (ici, AGO_1), elles-mêmes divisées administrativement en 163 
# municipalités (AGO_2) puis en 527 communes (ici, AGO_3)
#Dans ce Tp, nous avonsimporté les fichiers shapefile 
#de l'Angola et les visualiser avec R.

#==============   Etape 1  =================#

# I. Installation des packages nécessaires
#install.packages("stars")      # Pour la manipulation des données raster et vecteur
#install.packages("sf")         # Pour la manipulation des objets géospatiaux
#install.packages("ggplot2")    # Pour les visualisations graphiques
#install.packages("ggspatial")  # Pour ajouter des éléments cartographiques comme la flèche du nord et l'échelle
#install.packages("raster")     # Pour la manipulation des données raster
#install.packages("cowplot")    # Pour extraire la légende et afficher la carte sans légende
#install.packages("leaflet")    #   Pour avoir une carte interactive  en ajoutant les limites administratives
#install.packages("viridis")   # Pour la palette de couleurs viridis
#install.packages("units")  # Facultatif, mais utile pour éviter des erreurs liées aux unités spatiales



# II. Chargement des bibliothèques nécessaires
library(stars)
library(sf)
library(ggplot2)
library(ggspatial) 
library(raster)
library(cowplot)
library(leaflet)
library(viridis)    # Pour la palette de couleurs viridis
library(RColorBrewer) 
library(dplyr)
library(here)

# III. Lecture des fichiers shapefiles



angola <- st_read(here("data", "gadm41_AGO_0.shp"))

region_ang   <- st_read(here("data", "gadm41_AGO_1.shp"))
province_ang <- st_read(here("data", "gadm41_AGO_2.shp"))
commune_ang  <- st_read(here("data", "gadm41_AGO_3.shp"))
#st_read() est une fonction du package sf

#==============   FIN Etape 1  =================#


names (region_ang)
names (province_ang)
names (commune_ang)
#==============  Informations générales =================#




## --- 1. Niveau National (angola - GADM 0) ---
cat("\n==================================\n")
cat("1. Informations sur le Niveau National (angola)\n")
cat("==================================\n")

# Nombre d'entités (lignes)
cat(paste("Nombre d'entités (Pays):", nrow(angola), "\n")) #1

# Noms des colonnes (variables)
cat("Noms des colonnes:\n")
print(names(angola))

---
  
  ## --- 2. Niveau Provinces (region_ang - GADM 1) ---
  cat("\n==================================\n")
cat("2. Informations sur le Niveau Provinces (region_ang)\n")
cat("==================================\n")

# Nombre d'entités (Provinces)
cat(paste("Nombre de Provinces:", nrow(region_ang), "\n"))#18  provinces

# Noms des colonnes (variables)
cat("Noms des colonnes:\n")
print(names(region_ang))

# Aperçu des noms des premières provinces
cat("Aperçu des noms de Provinces (NAME_1):\n")
print(region_ang %>% st_drop_geometry() %>% select( NAME_1) %>% head(5))

# Vérification du nombre unique de provinces
cat(paste("Nombre de valeurs uniques pour NAME_1:", 
          n_distinct(region_ang$NAME_1), "\n"))

---
  
  ## --- 3. Niveau Municipalités (province_ang - GADM 2) ---
  cat("\n==================================\n")
cat("3. Informations sur le Niveau Municipalités (province_ang)\n")
cat("==================================\n")

# Nombre d'entités (Municipalités)
cat(paste("Nombre de Municipalités:", nrow(province_ang), "\n")) #163 municipalités

# Noms des colonnes (variables)
cat("Noms des colonnes:\n")
print(names(province_ang))

# Aperçu des données clés (Province + Municipalité)
cat("Aperçu des Municipalités (NAME_2) et de leurs Provinces (NAME_1):\n")
print(province_ang %>% st_drop_geometry() %>% select(NAME_1, NAME_2) %>% head(5))

---
  
  ## --- 4. Niveau Communes (commune_ang - GADM 3) ---
  cat("\n==================================\n")
cat("4. Informations sur le Niveau Communes (commune_ang)\n")
cat("==================================\n")

# Nombre d'entités (Communes)
cat(paste("Nombre de Communes:", nrow(commune_ang), "\n")) #527 communes

# Noms des colonnes (variables)
cat("Noms des colonnes:\n")
print(names(commune_ang))

# Aperçu des données clés (Province, Municipalité + Commune)
cat("Aperçu des Communes (NAME_3), Municipalités (NAME_2) et Provinces (NAME_1):\n")
print(commune_ang %>% st_drop_geometry() %>% select(NAME_1, NAME_2, NAME_3) %>% head(5))

# Vérification du nombre unique de communes
cat(paste("Nombre de valeurs uniques pour NAME_3:", 
          n_distinct(commune_ang$NAME_3), "\n"))



cat("\n==================================\n")
cat("CARTES STATIQUES")
cat("==================================\n")


#1- Représentation de la carte de l'Angola

map_pays <- ggplot(data = angola) +
  # Contour du pays (Angola)
  geom_sf(fill = "antiquewhite", color = "black", linewidth = 0.5) +
  
  # Ajout de l'indication du Nord (Top Right)
  annotation_north_arrow(location = "tr", which_north = "true",
                         pad_x = unit(0.25, "in"), pad_y = unit(0.25, "in"), 
                         style = north_arrow_fancy_orienteering())+
  
  # Ajout de l'échelle (Bottom Left)
  annotation_scale(
    location = "bl", 
    bar_cols = c("grey30", "white"), 
    width_hint = 0.3
  ) +
  
  # Titre et Thème
  labs(title = "Angola : Contour de l'Angola") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"))

# Afficher la carte
print(map_pays)

ggsave(
  filename = "angola_map.png",
  plot = map_pays,
  path = "outputs", # Chemin relatif à la racine du projet
  width = 8,
  height = 10,
  units = "in",
  dpi = 300
)









#2- Représentation de l'Angola au niveau rProvinces

# Calcul des centroïdes des provinces pour placer les étiquettes
centroids_provinces <- st_centroid(region_ang, of_largest_polygon = TRUE)

map_provinces <- ggplot(data = region_ang) +
  # Remplissage par Province (NAME_1)
  geom_sf(aes(fill = NAME_1), color = "white", linewidth = 0.3) +
  
  # Palette Viridis et suppression de la légende
  scale_fill_viridis_d(option = "D", guide = "none") +
  
  # Ajout des étiquettes de Province (NAME_1)
  geom_sf_label(data = centroids_provinces, aes(label = NAME_1), 
                size = 3, 
                label.padding = unit(0.15, "lines"), 
                label.size = 0.1) +
  
  # Nord et Échelle
  annotation_north_arrow(location = "tr", which_north = "true",
                         pad_x = unit(0.25, "in"), pad_y = unit(0.25, "in"), 
                         style = north_arrow_fancy_orienteering())+

  annotation_scale(location = "bl", bar_cols = c("grey30", "white")) +
  
  # Titre et Thème
  labs(title = "Angola : Provinces (NAME_1)") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"))

# Afficher la carte
print(map_provinces)

ggsave(
  filename = "angola_provinces_map.png",
  plot = map_provinces,
  path = "outputs", # Chemin relatif à la racine du projet
  width = 8,
  height = 10,
  units = "in",
  dpi = 300
)


# Niveau Municipalités
map_municipalites <- ggplot(data = province_ang) +
  # Remplissage avec une couleur unie (pas de distinction de couleur)
  geom_sf(fill = "#AEC6CF", color = "white", linewidth = 0.5) +
  
  # Ajout des contours des Provinces pour le contexte
  geom_sf(data = region_ang, fill = NA, color = "black", linewidth = 0.1) +
  
  # Nord et Échelle
  annotation_north_arrow(location = "tr", which_north = "true",
                         pad_x = unit(0.25, "in"), pad_y = unit(0.25, "in"), 
                         style = north_arrow_fancy_orienteering())+
  annotation_scale(location = "bl", bar_cols = c("grey30", "white")) +
  
  # Titre et Thème
  labs(title = "Angola : Municipalités (Niveau 2)") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"))

# Afficher la carte
print(map_municipalites)

ggsave(
  filename = "angola_municipalités_map.png",
  plot = map_municipalites,
  path = "outputs", # Chemin relatif à la racine du projet
  width = 8,
  height = 10,
  units = "in",
  dpi = 300
)



#3- Représentation de la carte de l'Angola  au niveau commune 

map_communes <- ggplot(data = commune_ang) +
  # Remplissage avec une couleur unie (très clair pour ne pas alourdir)
  geom_sf(fill = "#D8BFD8", color = "grey50", linewidth = 0.05) +
  
  # Ajout des contours des Provinces pour le contexte
  geom_sf(data = region_ang, fill = NA, color = "black", linewidth = 0.4) +
  
  # Nord et Échelle
  annotation_north_arrow(location = "tr", which_north = "true",
                         pad_x = unit(0.25, "in"), pad_y = unit(0.25, "in"), 
                         style = north_arrow_fancy_orienteering())+
  annotation_scale(location = "bl", bar_cols = c("grey30", "white")) +
  
  # Titre et Thème
  labs(title = "Angola : Communes (Niveau 3)") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"))

# Afficher la carte
print(map_communes)

ggsave(
  filename = "angola_communes_map.png",
  plot = map_communes,
  path = "outputs", # Chemin relatif à la racine du projet
  width = 8,
  height = 10,
  units = "in",
  dpi = 300
)


cat("\n==================================\n")
cat("CARTE DYNAMIQUE")
cat("==================================\n")





# --- 1. Préparation des Couches Leaflet ---

# Couche Provinces (Niveau 1)
# Utilisation d'une palette pour la distinction
pal_provinces <- colorFactor(palette = "Set3", domain = region_ang$NAME_1)

provinces_leaf <- region_ang %>%
  st_transform(4326) %>% # Transformation en WGS84 (requis par Leaflet)
  mutate(
    popup_text = paste(
      "<b>Province:</b>", NAME_1, "<br>", 
      "<b>Code GADM:</b>", GID_1
    )
  )

# Couche Municipalités (Niveau 2)
# Utilisation d'une couleur unie pour éviter la surcharge
municipalites_leaf <- province_ang %>%
  st_transform(4326) %>%
  mutate(
    popup_text = paste(
      "<b>Municipalité:</b>", NAME_2, "<br>", 
      "<b>Province:</b>", NAME_1, "<br>", 
      "<b>Code GADM:</b>", GID_2
    )
  )

# Couche Communes (Niveau 3)
communes_leaf <- commune_ang %>%
  st_transform(4326) %>%
  mutate(
    popup_text = paste(
      "<b>Commune:</b>", NAME_3, "<br>", 
      "<b>Municipalité:</b>", NAME_2
    )
  )


## --- 2. Construction de la Carte Leaflet ---

m <- leaflet() %>%
  # Ajout du fond de carte (tiles)
  addProviderTiles(providers$CartoDB.Positron, group = "Basemap") %>%
  
  # --- Ajout des Couches Géométriques ---
  
  # Couche 1: Provinces (Coloriée par nom)
  addPolygons(
    data = provinces_leaf,
    fillColor = ~pal_provinces(NAME_1), # Remplissage par la palette Set3
    color = "black", # Contour
    weight = 1.5,
    opacity = 1,
    fillOpacity = 0.7,
    popup = ~popup_text,
    group = "Niveau 1 : Provinces (NAME_1)" # Nom du calque pour le contrôle
  ) %>%
  
  # Couche 2: Municipalités (Couleur unie)
  addPolygons(
    data = municipalites_leaf,
    fillColor = "#8C9DAB", # Gris-bleu uni
    color = "white",
    weight = 0.5,
    opacity = 1,
    fillOpacity = 0.6,
    popup = ~popup_text,
    group = "Niveau 2 : Municipalités (NAME_2)" # Nom du calque pour le contrôle
  ) %>%
  
  # Couche 3: Communes (Couleur unie, contour très fin)
  addPolygons(
    data = communes_leaf,
    fillColor = "#D8BFD8", # Lavande uni
    color = "grey",
    weight = 0.2,
    opacity = 1,
    fillOpacity = 0.5,
    popup = ~popup_text,
    group = "Niveau 3 : Communes (NAME_3)" # Nom du calque pour le contrôle
  ) %>%
  
  # --- Contrôle des Calques (Sélection du Niveau) ---
  addLayersControl(
    baseGroups = c("Niveau 1 : Provinces (NAME_1)", 
                   "Niveau 2 : Municipalités (NAME_2)", 
                   "Niveau 3 : Communes (NAME_3)"),
    overlayGroups = "Basemap",
    options = layersControlOptions(collapsed = FALSE) # Le contrôle reste ouvert
  ) %>%
  
  # Réglage de la vue initiale sur l'Angola
  setView(lng = 17.5, lat = -12.5, zoom = 5)

# Afficher la carte interactive
m


# Assurez-vous d'avoir la librairie 'htmlwidgets' installée et chargée
# install.packages("htmlwidgets")
library(htmlwidgets)

# --- Sauvegarde de la carte interactive ---

# 1. Spécifiez le chemin et le nom du fichier (dans votre dossier 'outputs')
output_file_path <- file.path("outputs", "carte_angola_interactive.html")

# 2. Sauvegardez la carte
saveWidget(
  widget = m,                   # L'objet leaflet à sauvegarder
  file = output_file_path,      # Le chemin complet du fichier HTML
  selfcontained = TRUE          # Inclut toutes les dépendances (CSS, JS) dans le fichier
)

cat(paste("Carte interactive sauvegardée à :", output_file_path))



### Rasters
library(terra)
library(sf)
library(tmap)

pop <- rast(here("data", "ago_pop_2020_CN_100m_R2025A_v1.tif"))
pop
#Voir les valeurs manquantes
#has.na(pop)
#global(pop, fun = "isNA", na.rm = FALSE)



pop_angola <- mask(pop, vect(angola)) |> crop(vect(angola))# On reste dans la limite de l'Angola

tmap_mode("view")


carte_pop<- tm_shape(pop_angola) +
  tm_raster(style = "quantile",            # type de découpage
            n = 7,                         # nombre de classes
            palette = "viridis",           # palette
            title = "Population Angola 2020 (WorldPop)") +
  tm_shape(angola) +
  tm_borders(lwd = 1.2, col = "black") +   # contour du pays
  tm_layout(main.title = "Population totale par pixel — Angola",
            frame = FALSE)



# Exporter en PNG
tmap_save( carte_pop,
          filename = here::here("outputs","carte_population_angola.png"),
          dpi = 300,
          width = 3000,   # pixels
          height = 2500)  # pixels
tmap_mode("plot")   
