# ============================================================================= #
#                                                                               #
# ENSAE Pierre NDIAYE de Dakar ISE1-Cycle long 2024-2025                        #
# COURS DE Statistique exploratoire spaciale       avec M.Aboubacre HEMA        #
#                                                                               #              
# TP - STATISTIQUES EXPLORATOIRES SPATIALES                                     #
#                                                                               #
# L’objectif de ce TP est de manipuler et d’analyser des données géospatiales.  #
# Plus précisément, il s’agit de télécharger des données vectorielles sur les   #
# limites administratives de la Côte d’Ivoire et des données raster représentant#
# la répartition de la  population, d’explorer leurs propriétés et de réaliser  #
# leur visualisation cartographique.                                            #
#                                                                               #
# Logiciel R                                                                    #
# Auteur : Astou Diop                                                           #        
#                                                                               #
# ============================================================================= #



# ------------------------------
# 1. CHARGEMENT DES LIBRAIRIES
# ------------------------------
packages <- c("sf", "terra", "dplyr", "tmap", "ggplot2", "viridis", "stars", 
              "ggspatial", "raster", "cowplot", "leaflet")

installed <- packages %in% installed.packages()
if(any(!installed)) install.packages(packages[!installed])
lapply(packages, library, character.only = TRUE)

tmap_mode("plot")

# ------------------------------
# 2. CREATION DOSSIER OUTPUTS
# ------------------------------
dirs <- c(
  "outputs/proprietes",
  "outputs/cartes/shapefiles",
  "outputs/cartes/rasters",
  "outputs/graphiques"
)
for(d in dirs){ if(!dir.exists(d)) dir.create(d, recursive = TRUE) }

# ------------------------------
# 3. CHEMIN VERS LE DOSSIER DATA
# ------------------------------
DATA_DIR <- "DATA"  # dossier DATA à la racine

# ------------------------------
# 4. CHARGEMENT SHAPEFILES
# ------------------------------
shp0 <- st_read(file.path(DATA_DIR, "limites_niveau0", "gadm41_CIV_0.shp"))
shp1 <- st_read(file.path(DATA_DIR, "limites_niveau1", "gadm41_CIV_1.shp"))
shp2 <- st_read(file.path(DATA_DIR, "limites_niveau2", "gadm41_CIV_2.shp"))
shp3 <- st_read(file.path(DATA_DIR, "limites_niveau3", "gadm41_CIV_3.shp"))
shp4 <- st_read(file.path(DATA_DIR, "limites_niveau4", "gadm41_CIV_4.shp"))

shapefiles_list <- list("0"=shp0, "1"=shp1, "2"=shp2, "3"=shp3, "4"=shp4)
niveaux_names <- c("pays","district","régions","sous-préfectures","communes")

# ------------------------------
# 5. CHARGEMENT RASTERS POPULATION
# ------------------------------
raster_dir <- file.path(DATA_DIR, "rasters_population_2015_2024")
raster_files <- list.files(raster_dir, pattern="\\.tif$", full.names=TRUE)
rasters_population <- lapply(raster_files, terra::rast)
names(rasters_population) <- paste0("pop_", 2015:2024)

# ------------------------------
# 6. CREATION CSV PROPRIETES
# ------------------------------

# --- Shapefiles ---
shp_props <- data.frame(
  niveau=character(), fichier=character(), nombre_entites=numeric(), crs=character(),
  type_geometrie=character(), xmin=numeric(), xmax=numeric(), ymin=numeric(), ymax=numeric(),
  stringsAsFactors=FALSE
)

i <- 1
for(niv in names(shapefiles_list)){
  shp <- shapefiles_list[[niv]]
  folder <- file.path(DATA_DIR, paste0("limites_niveau", niv))
  shp_file <- list.files(folder, pattern="\\.shp$", full.names=TRUE)[1]
  
  row <- data.frame(
    niveau = niveaux_names[i],
    fichier = basename(shp_file),
    nombre_entites = nrow(shp),
    crs = st_crs(shp)$input,
    type_geometrie = paste(unique(st_geometry_type(shp)), collapse=";"),
    xmin = st_bbox(shp)[["xmin"]],
    xmax = st_bbox(shp)[["xmax"]],
    ymin = st_bbox(shp)[["ymin"]],
    ymax = st_bbox(shp)[["ymax"]],
    stringsAsFactors = FALSE
  )
  
  shp_props <- rbind(shp_props, row)
  i <- i + 1
}
write.csv(shp_props, "outputs/proprietes/proprietes_shapefiles.csv", row.names=FALSE)

# --- Rasters ---
rast_props <- data.frame(
  Annee=character(), Fichier=character(), hauteur=numeric(), Largeur=numeric(), nb_bandes=numeric(),
  resolution_x=numeric(), resolution_y=numeric(), projection=character(), type_donnees=character(),
  min_valeur=numeric(), max_valeur=numeric(), Moyenne=numeric(), ecart_type=numeric(),
  bbox_minx=numeric(), bbox_miny=numeric(), bbox_maxx=numeric(), bbox_maxy=numeric(),
  stringsAsFactors=FALSE
)

for(year in names(rasters_population)){
  r <- rasters_population[[year]]
  stats <- global(r, fun=c("min","max","mean","sd"), na.rm=TRUE)
  
  rowr <- data.frame(
    Annee=year,
    Fichier=basename(raster_files[which(names(rasters_population)==year)]),
    hauteur=nrow(r), Largeur=ncol(r), nb_bandes=nlyr(r),
    resolution_x=res(r)[1], resolution_y=res(r)[2],
    projection=as.character(crs(r)), type_donnees=terra::datatype(r),
    min_valeur=stats[1], max_valeur=stats[2], Moyenne=stats[3], ecart_type=stats[4],
    bbox_minx=ext(r)[1], bbox_miny=ext(r)[3], bbox_maxx=ext(r)[2], bbox_maxy=ext(r)[4],
    stringsAsFactors=FALSE
  )
  
  rast_props <- rbind(rast_props, rowr)
}
write.csv(rast_props, "outputs/proprietes/proprietes_rasters_population.csv", row.names=FALSE)

# ------------------------------
# 7. VISUALISATION CARTOGRAPHIQUE
# ------------------------------
plot_niveau <- function(shp, niveau, nom_colonne=NULL){
  if(is.null(nom_colonne)) nom_colonne <- names(shp)[2]
  p <- tm_shape(shp) +
    tm_polygons(col="lightblue", border.col="black") +
    tm_text(text=nom_colonne, size=0.6, shadow=TRUE) +
    tm_layout(title=paste("Limites Administratives - Niveau", niveau), legend.outside=TRUE)
  tmap_save(p, filename=paste0("outputs/cartes/shapefiles/carte_niveau_", niveau, ".png"))
  return(p)
}
p0 <- plot_niveau(shp0,0,"Cote d'ivoire")
p1 <- plot_niveau(shp1,1,"NAME_1")
p2 <- plot_niveau(shp2,2,"NAME_2")
p3 <- plot_niveau(shp3,3,"NAME_3")
p4 <- plot_niveau(shp4,4,"NAME_4")

# Cartes population raster
couleurs <- c("green","#92c5de","#0571b0","#fddbc7","#ca0020")
for(annee in 2015:2024){
  raster_ann <- rasters_population[[paste0("pop_", annee)]]
  raster_ann[raster_ann==0] <- NA
  val <- values(raster_ann); val <- val[!is.na(val)]
  breaks <- quantile(val, probs=seq(0,1,length.out=6), na.rm=TRUE)
  p <- tm_shape(raster_ann) +
    tm_raster(palette=couleurs, breaks=breaks, title="Population") +
    tm_shape(shp0) + tm_borders(col="black", lwd=2) +
    tm_layout(title=paste("Population", annee), legend.outside=TRUE)
  tmap_save(p, filename=paste0("outputs/cartes/rasters/carte_population_", annee, ".png"))
}

# ------------------------------
# 8. APPLICATIONS PRATIQUES - GRAPHIQUES
# ------------------------------

# 8.1 Superficie districts
superficie_districts <- shp1 %>%
  mutate(superficie_km2 = as.numeric(st_area(geometry))/1e6) %>%
  select(NAME_1, superficie_km2)
ggplot(superficie_districts, aes(x=reorder(NAME_1,-superficie_km2), y=superficie_km2)) +
  geom_col(fill="skyblue") +
  labs(title="Superficie par district (niveau 1)", x="Districts", y="Superficie (km²)") +
  theme_minimal() + theme(axis.text.x=element_text(angle=45,hjust=1))
ggsave("outputs/graphiques/barplot_superficie_districts.png", width=10,height=6)

# --- 8.2 Population par district (2024) ---
pop_col <- "global_pop_2024_CN_1km_R2025A_v1"

# Barplot population
ggplot(pop_district, aes(x = reorder(district, -!!sym(pop_col)), y = !!sym(pop_col))) +
  geom_col(fill = "orange") +
  labs(title = "Population par district (2024)",
       x = "Districts", y = "Population") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
ggsave("outputs/graphiques/barplot_population_districts_2024.png", width = 10, height = 6)

# --- 8.3 Densité par district (2024) ---
densite_district <- pop_district %>%
  mutate(superficie_km2 = superficie_districts$superficie_km2,
         densite = !!sym(pop_col) / superficie_km2)

# Barplot densité
ggplot(densite_district, aes(x = reorder(district, -densite), y = densite)) +
  geom_col(fill = "green") +
  labs(title = "Densité par district (2024)",
       x = "Districts", y = "Densité (hab/km²)") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
ggsave("outputs/graphiques/barplot_densite_districts_2024.png", width = 10, height = 6)

# 8.4 Evolution population totale
pop_totale <- data.frame(Annee=2015:2024, Population=NA_real_)
for(annee in 2015:2024){
  r <- rasters_population[[paste0("pop_",annee)]]
  pop_totale$Population[pop_totale$Annee==annee] <- as.numeric(global(r,fun=sum,na.rm=TRUE))
}
ggplot(pop_totale,aes(x=Annee,y=Population)) +
  geom_line(color="red",linewidth=1.2) + geom_point(color="blue",size=2) +
  labs(title="Evolution de la population en Côte d'Ivoire (2015-2024)",
       x="Année",y="Population totale") +
  theme_minimal()
ggsave("outputs/graphiques/evolution_population_2015_2024.png", width=8,height=5)

message("===== TP TERMINE AVEC SUCCES =====")
