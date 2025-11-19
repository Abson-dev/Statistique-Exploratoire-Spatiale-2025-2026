# Chemin du nouveau répertoire d'outputs
output_dir <- file.path(base_path, "outputs")

# Créer le répertoire 'outputs' s'il n'existe pas
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
  cat("Dossier de sortie créé à l'emplacement :", output_dir, "\n")
} else {
  cat("Le dossier de sortie existe déjà :", output_dir, "\n")
}


# Importation du shapefile des aires protégées
AP_shp <- file.path(base_path, "/data/data2/202303-osm2igeo-cameroun-shp-wgs84-4326/202303_OSM2IGEO_CAMEROUN_SHP_WGS84_4326/Y_OSM_ENVIRONNEMENT/AIRE_PROTEGEE.shp")

# Lecture du shapefile des aires protégées
aires_protegees <- st_read(AP_shp)

# Importation du shapefile du Cameroun
CMR_shp_0 <- file.path(base_path, "/data/data2/shapefiles_limites_administratives_GADM_Cameroun/gadm41_CMR_0.shp")
CMR_shp_1 <- file.path(base_path, "/data/data2/shapefiles_limites_administratives_GADM_Cameroun/gadm41_CMR_1.shp")


# Importation du shapefile du cameroun
cameroun_limite_0 <- st_read(CMR_shp_0)
cameroun_limite_1 <- st_read(CMR_shp_1)


# Aperçu des données
print(head(aires_protegees))
print(st_crs(aires_protegees)) # Système de coordonnées

print(st_crs(cameroun_limite_0))


# Visualisation statique des aires protégées sur la carte du Cameroun
ggplot() +
  
  # Couche de font (Cameroun)
  geom_sf(data = cameroun_limite_1, 
          fill = "grey95", 
          color = "grey30", 
          size = 0.5) +
  
  # Couche principale (Aires protégées)
  geom_sf(data = aires_protegees, 
          aes(fill = "Aire protégée"), 
          color = "darkgreen", 
          size = 0.5) +
  
  # Configuration des couleurs et de la légende
  scale_fill_manual(values = "lightgreen", name = "Légende :") +
  
  # Ajout de titres et informations
  labs(title = "Répartition des aires protégées au Cameroun",
       caption = paste(
         "              Nombre d'aires :", nrow(aires_protegees), 
         "\n\nSource : GADM (Carte du Cameroun) & OpenStreetMap (Aires protégées)"
       )
  ) +
  
  # Thème pour une meilleure présentation
  theme_minimal() +
  
  # Ajustement de la taille, de la légende et de la caption
  theme(
    
    aspect.ratio = 1.2, 
    axis.title = element_blank(),
    axis.text = element_blank(),
    axis.ticks = element_blank(),
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    
    # Déplacement la légende à gauche
    legend.position = "right",
    
    # Centrage du texte de la caption (nombre d'aires et sources) en bas
    plot.caption = element_text(hjust = 0.3, size = 10, color = "grey30"),
    
    # Ajustement la marge du titre pour libérer l'espace en haut
    plot.title = element_text(hjust = 0.1, face = "bold"),
  )

# Chemin complet pour l'enregistrement
output_file_path <- file.path(output_dir, "aires protegees_Cameroun.png")

# Enregistrer le graphique
ggsave(filename = output_file_path,
       width = 8, 
       height = 10, 
       units = "in",
       dpi = 300)





# Visualisation dynamique des aires protégées sur la carte du Cameroun
carte_tmap <- 
  # Couche de fond (Cameroun)
  tm_shape(cameroun_limite_1) +
  #  tm_fill(col = "grey90", legend.show = FALSE) + 
  tm_borders(col = "grey50", lwd = 1) +
  
  # Couche principale (Aires protégées)
  tm_shape(aires_protegees) +
  tm_fill(col = "forestgreen", alpha = 0.6, legend.show = FALSE) + # Remplissage sans légende ici
  tm_borders(col = "darkgreen", lwd = 0.5) +
  
  # Ajout d'une légende
  tm_add_legend(
    type = "fill", 
    col = "forestgreen",
    labels = "Aire protégée", 
    title = "Légende :"
  ) +
  
  # Mise en page 
  tm_layout(
    title = "Aires protégées au Cameroun",
    title.position = c("center", "top"),
    title.size = 1.2,
    
    # Positionnement de la légende
    legend.position = c("right", "top"),
    legend.title.size = 0.6,
    legend.text.size = 0.4,
    
    frame = FALSE, # Retrait de l'encadrement
    inner.margins = c(0.01, 0.01, 0.01, 0.01)
  ) +
  
  # Ajout des informations en bas de page
  tm_credits(text = paste("Nombre d'aires :", nrow(aires_protegees)),
             position = c("left", "bottom"),
             size = 0.7,
             col = "grey30") +
  tm_credits(text = "Source : OpenStreetMap & GADM",
             position = c("right", "bottom"), 
             size = 0.6,
             col = "grey30",
             align = "right")


tmap_mode("view") 
print(carte_tmap)




# --- Enregistrement de la carte dynamique en HTML ---

# 1. Définir le chemin complet du fichier HTML

output_file_html <- file.path(output_dir, "aires_reservees_Cameroun.html")

# 2. Utiliser tmap_save() pour enregistrer
tmap_save(tm = carte_tmap, filename = output_file_html)


