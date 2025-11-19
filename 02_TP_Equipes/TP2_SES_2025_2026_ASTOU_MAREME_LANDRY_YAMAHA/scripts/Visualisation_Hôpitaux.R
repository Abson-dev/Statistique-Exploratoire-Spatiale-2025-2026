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
HPT_shp <- file.path(base_path, "/data/data2/202303-osm2igeo-cameroun-shp-wgs84-4326/202303_OSM2IGEO_CAMEROUN_SHP_WGS84_4326/I_OSM_ZONE_ACTIVITE/PAI_SANTE.shp")

# Lecture du shapefile des aires protégées
hopital <- st_read(HPT_shp)

# Importation des shapefiles du Cameroun
CMR_shp_1 <- file.path(base_path, "/data/data2/shapefiles_limites_administratives_GADM_Cameroun/gadm41_CMR_1.shp")
CMR_shp_3 <- file.path(base_path, "/data/data2/shapefiles_limites_administratives_GADM_Cameroun/gadm41_CMR_3.shp")


# Importation des shapefiles du cameroun
cameroun_limite_1 <- st_read(CMR_shp_1)
cameroun_limite_3 <- st_read(CMR_shp_3)


# --- VISUALISATION STATIQUE ---

CRS_METRIQUE <- 32633 
hopital_projete <- st_transform(hopital, crs = CRS_METRIQUE)

# --- CRÉATION DU TAMPON (BUFFER) ---
distance_tampon_km <- 25 # Distance d'accès aux soins (en km)
distance_tampon_m <- distance_tampon_km * 1000 # Conversion en mètres

# Créer le tampon autour de chaque hôpital
zones_acces_hopital <- st_buffer(hopital_projete, dist = distance_tampon_m)

# Optionnel: Dissoudre les tampons qui se chevauchent pour une vue d'ensemble
zones_acces_dissolues <- st_union(zones_acces_hopital)

ggplot() +
  
  # Couche de fond (Cameroun - Limites régionales)
  geom_sf(data = cameroun_limite_1, 
          fill = "grey95", 
          color = "grey30", 
          size = 0.5) +
  
  # Couche des ZONES D'ACCÈS (Tampons) - SOUS LES HÔPITAUX
  geom_sf(data = zones_acces_dissolues, # Ou zones_acces_hopital pour des tampons individuels
          fill = "blue", 
          alpha = 0.4, 
          color = NA) + # Pas de contour pour le tampon
  
  # Couche principale (Hôpitaux) - SYMBOLES DES POINTS
  geom_sf(data = hopital_projete, 
          aes(color = "Hôpital"), # Associer à une couleur pour la légende
          shape = 3,             # Symbole "+" ou "x" (forme de croix) pour l'hôpital
          size = 2,            # Taille du symbole
          stroke = 1) +          # Épaisseur du contour du symbole
  
  # Configuration des couleurs et de la légende
  scale_color_manual(name = "Légende :", 
                     values = c("Hôpital" = "darkred")) + # Couleur pour le symbole de l'hôpital
  
  # Configuration du remplissage pour le tampon
  scale_fill_manual(name = "Zones d'accès :",
                    values = c("Zone d'accès" = "lightcoral")) + # Couleur pour le remplissage du tampon
  
  # Ajout de titres et informations
  labs(title = "Localisation et zones d'accès aux hôpitaux au Cameroun",
       subtitle = paste("Distance d'accès de", distance_tampon_km, "km autour de chaque hôpital"),
       caption = paste(
         "Nombre d'hôpitaux dans la base de données :", nrow(hopital_projete), 
         "\nSource : GADM (Limites administratives) & OpenStreetMap (Hôpitaux)"
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
    
    legend.position = "right", # Position de la légende générale
    
    plot.caption = element_text(hjust = 0.5, size = 9, color = "grey30"),
    plot.title = element_text(hjust = 0.5, face = "bold"),
    plot.subtitle = element_text(hjust = 0.5)
  )

# Chemin complet pour l'enregistrement
output_file_path <- file.path(output_dir, "carte_statique_hôpitaux.png")

# Enregistrer le graphique
ggsave(filename = output_file_path,
       width = 8, 
       height = 10, 
       units = "in",
       dpi = 300)








# --- Interface dynamique ---

CRS_METRIQUE <- 32633 

# Projection
regions_dep_arr_projete <- st_transform(cameroun_limite_3, crs = CRS_METRIQUE)
hopital_projete <- st_transform(hopital, crs = CRS_METRIQUE)

# Création de la limite nationale unique (statique)
# N'est plus utilisé pour le clipping, mais peut servir pour l'enrichissement
limite_nationale <- st_union(regions_dep_arr_projete) 

# Calcul de la variable statique pour l'affichage (Total National)
total_hopitaux_pays_display <- paste("Total Hôpitaux Cameroun :", nrow(hopital_projete))

# 1. Calcul du Nombre d'Hôpitaux par Région (Utilise hopital_projete, left=FALSE pour le compte)
hopitaux_par_region <- st_join(
  hopital_projete,
  regions_dep_arr_projete,
  join = st_intersects,
  left = FALSE # On ne compte que ceux DANS les régions
) %>%
  st_drop_geometry() %>%
  group_by(NAME_1) %>% 
  tally(name = "Nb_Hopitaux") %>%
  ungroup()

# 2. Jointure et Nettoyage de la couche Région (pour le pop-up polygone)
regions_interactives <- regions_dep_arr_projete %>%
  group_by(NAME_1) %>%
  summarise(geometry = st_union(geometry)) %>%
  ungroup() %>%
  left_join(hopitaux_par_region, by = "NAME_1") %>%
  mutate(Nb_Hopitaux = replace_na(Nb_Hopitaux, 0)) %>%
  rename(Région = NAME_1,
         `Nombre d'hôpitaux dans la région` = Nb_Hopitaux) %>%
  select(Région, `Nombre d'hôpitaux dans la région`)

# 3. ENRICHISSEMENT de la couche Hôpitaux pour les pop-ups
hopital_projete_enriched <- hopital_projete %>%
  # Utiliser left = TRUE pour garder TOUS les points
  st_join(regions_dep_arr_projete %>% select(NAME_1, NAME_2, NAME_3), 
          join = st_intersects, 
          left = TRUE) %>% 
  
  # Jointure tabulaire (les outliers auront des NA pour NAME_1, Nb_Hopitaux sera NA)
  left_join(hopitaux_par_region, by = "NAME_1") %>%
  
  # Renommage Final des colonnes (Assurez-vous d'avoir le bon nom de colonne pour Nom_Hopital)
  rename(Nom_Hopital = NOM) %>% 
  rename(Région = NAME_1,
         Département = NAME_2,
         Arrondissement = NAME_3,
         `Nombre d'hôpitaux dans la région` = Nb_Hopitaux) %>%
  
  # Nettoyage final
  mutate(popup_fix = "") %>%
  select(popup_fix, Nom_Hopital, Arrondissement, Département, Région, `Nombre d'hôpitaux dans la région`) 


# --------------------------------------------------------------------------


# --- Définition de l'Interface Utilisateur (UI) ---
ui <- fluidPage(
  titlePanel("Carte interactive de couverture sanitaire du Cameroun"),
  
  sidebarLayout(
    sidebarPanel(
      sliderInput("buffer_dist", "Distance de tampon (km) :", 
                  min = 0, max = 100, value = 5, step = 1),
      hr(),
      tags$p("Source : OSM, GADM", style = "font-size: 10px; color: grey;")
    ),
    mainPanel(
      tmapOutput("interactive_map", height = "800px")
    )
  )
)

# --------------------------------------------------------------------------


# --- Définition de la Logique du Serveur (Server) ---
server <- function(input, output, session) {
  
  options(tmap.mode = "view")
  
  # 1. CALCUL DU TAMPON RÉACTIF 
  buffer_reactive <- reactive({
    dist_m <- input$buffer_dist * 1000 
    
    if (dist_m == 0) {
      # Utilise hopital_projete pour la cohérence
      return(st_sf(geometry = st_sfc(crs = st_crs(hopital_projete)))) 
    }
    
    # Calcul initial du tampon agrégé autour des hôpitaux (y compris les outliers)
    tampon_union <- st_union(st_buffer(hopital_projete, dist = dist_m))
    
    # Retourner le tampon sans intersection
    # Cela permet au tampon de s'étendre en dehors des limites et aux polygones isolés d'être vus.
    return(tampon_union)
  })
  
  # 2. Rendu de la carte tmap
  output$interactive_map <- renderTmap({
    
    tmap_mode("view")
    
    tampon_a_afficher <- buffer_reactive() 
    
    # Création du tmap
    tm_basemap(server = "OpenStreetMap") +
      
      # COUCHE 1 : RÉGIONS (Arrière-plan, pour le clic sur polygone)
      tm_shape(regions_interactives, name = "Régions administratives", 
               popup.vars = TRUE) +
      tm_borders(col = "grey10", lwd = 2, alpha = 0.05) +
      tm_fill(col = NA, alpha = 0) +
      
      # COUCHE 2 : TAMPON D'ACCÈS (Zone d'influence)
      tm_shape(tampon_a_afficher, name = paste0("Zone d'Accès (", input$buffer_dist, " km)")) +
      tm_fill(col = "lightcoral", alpha = 0.4) +
      tm_borders(col = "darkred", lwd = 0.5, alpha = 0.6) +
      
      # COUCHE 3 : POINTS HÔPITAUX (Avant-plan, affiche maintenant les outliers)
      tm_shape(hopital_projete_enriched, name = "Hôpitaux Localisation") +
      tm_dots(col = "darkred", 
              shape = 10,
              size = 1.2, 
              popup.vars = c(" " = "popup_fix",
                             "Nom de l'Hôpital" = "Nom_Hopital",
                             "Arrondissement" = "Arrondissement",
                             "Département" = "Département",
                             "Région" = "Région",
                             "Nombre d'hôpitaux dans la région" = "Nombre d'hôpitaux dans la région")) + 
      
      # Mise en page
      tm_layout(
        title = "Répartition des hôpitaux au Cameroun",
        title.position = c("center", "top"),
        title.size = 1.2,
        legend.show = TRUE, 
        frame = FALSE
      )
  })
}

# --- Lancement de l'application Shiny ---
shinyApp(ui = ui, server = server)



