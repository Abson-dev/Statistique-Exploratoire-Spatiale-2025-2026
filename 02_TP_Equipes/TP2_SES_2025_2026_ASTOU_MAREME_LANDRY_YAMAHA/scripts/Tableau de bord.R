# =============================================================================
# INSTALLATION ET CHARGEMENT DES LIBRAIRIES
# =============================================================================

# Liste des packages nécessaires
packages <- c("sf", "ggplot2", "dplyr", "leaflet", "htmlwidgets", "viridis", 
              "knitr", "units", "readr", "leaflet.extras", "RColorBrewer", 
              "cowplot", "plotly", "htmltools", "httr", "jsonlite", "data.table")

# Installer les packages manquants
for(pkg in packages) {
  if(!require(pkg, character.only = TRUE)) {
    install.packages(pkg)
    library(pkg, character.only = TRUE)
  }
}

# =============================================================================
# CONFIGURATION INITIALE - SÉLECTION DU DOSSIER DATA
# =============================================================================

# Fonction pour sélectionner le dossier data interactivement
selectionner_dossier_data <- function() {
  cat("Veuillez sélectionner le dossier 'data' contenant les données du projet...\n")
  
  # Utiliser une boîte de dialogue pour sélectionner le dossier
  if (Sys.info()["sysname"] == "Windows") {
    # Méthode pour Windows
    if (!require(utils)) {
      install.packages("utils")
      library(utils)
    }
    data_folder <- choose.dir(caption = "Sélectionnez le dossier 'data'")
  } else {
    # Méthode pour Mac/Linux (utilise tcltk)
    if (!require(tcltk)) {
      install.packages("tcltk")
      library(tcltk)
    }
    data_folder <- tk_choose.dir(caption = "Sélectionnez le dossier 'data'")
  }
  
  if (is.na(data_folder) || data_folder == "") {
    cat("❌ Aucun dossier sélectionné. Utilisation du répertoire courant.\n")
    data_folder <- getwd()
  }
  
  # Vérifier si le dossier contient des fichiers de données
  fichiers_data <- list.files(data_folder, pattern = "\\.shp$|\\.zip$", ignore.case = TRUE)
  if (length(fichiers_data) == 0) {
    cat("⚠️  Avertissement: Le dossier sélectionné ne contient pas de fichiers .shp ou .zip visibles.\n")
    cat("   Fichiers trouvés:", paste(list.files(data_folder), collapse = ", "), "\n")
  } else {
    cat("✅ Fichiers de données trouvés:", paste(fichiers_data, collapse = ", "), "\n")
  }
  
  return(data_folder)
}

# Sélectionner le dossier data
data_folder <- selectionner_dossier_data()

# Définir le répertoire de travail sur le dossier data
setwd(data_folder)
cat("📁 Répertoire de travail défini sur:", data_folder, "\n")

# Créer le dossier outputs au même niveau que le dossier data
parent_folder <- dirname(data_folder)
outputs_folder <- file.path(parent_folder, "outputs")

if (!dir.exists(outputs_folder)) {
  dir.create(outputs_folder)
  cat("✅ Dossier 'outputs' créé avec succès dans:", outputs_folder, "\n")
} else {
  cat("📁 Dossier 'outputs' existe déjà dans:", outputs_folder, "\n")
}

# =============================================================================
# FONCTIONS POUR TÉLÉCHARGER LES DONNÉES DE POPULATION
# =============================================================================

telecharger_donnees_population <- function() {
  cat("Tentative de téléchargement des données de population...\n")
  
  # URL des données de population (WorldPop ou données similaires)
  urls_population <- c(
    "https://data.humdata.org/dataset/e9b15f54-5a0f-4fa8-ba92-97d1e6d0eab5/resource/317c36f4-4069-46de-8b13-6c5d7d96b0d8/download/cmr_ppp_2020_UNadj_constrained.tif",
    "https://www.worldpop.org/rest/data/pop/gpw?iso3=CMR"
  )
  
  tryCatch({
    # Méthode 1: Téléchargement direct depuis WorldPop
    url_worldpop <- "https://data.worldpop.org/GIS/Population/Global_2000_2020_Constrained/2020/maxar_v1/cmr/cmr_ppp_2020_constrained.tif"
    
    dest_file <- file.path(data_folder, "population_data.tif")
    
    if(!file.exists(dest_file)) {
      cat("Téléchargement des données de population WorldPop...\n")
      download.file(url_worldpop, dest_file, mode = "wb", quiet = FALSE)
    }
    
    return(dest_file)
    
  }, error = function(e) {
    cat("❌ Impossible de télécharger les données de population en ligne\n")
    cat("Message d'erreur:", e$message, "\n")
    return(NULL)
  })
}

enrichir_donnees_population <- function(donnees) {
  cat("Enrichissement des données de population...\n")
  
  # Si les données OSM n'ont pas de population, on va créer des estimations
  if(!is.null(donnees$villages)) {
    # Estimation de la population basée sur le type de localité
    donnees$villages <- donnees$villages %>%
      mutate(
        population_estimee = case_when(
          fclass == "city" & is.na(population) ~ runif(n(), 100000, 500000),
          fclass == "town" & is.na(population) ~ runif(n(), 5000, 50000),
          fclass == "village" & is.na(population) ~ runif(n(), 100, 5000),
          fclass == "hamlet" & is.na(population) ~ runif(n(), 10, 100),
          fclass == "suburb" & is.na(population) ~ runif(n(), 1000, 20000),
          !is.na(population) & population > 0 ~ as.numeric(population),
          TRUE ~ NA_real_
        ),
        # Catégorisation de la population pour la visualisation
        categorie_population = cut(
          population_estimee,
          breaks = c(0, 100, 1000, 5000, 20000, 100000, Inf),
          labels = c("Très petit (<100)", "Petit (100-1k)", "Moyen (1k-5k)", 
                     "Grand (5k-20k)", "Très grand (20k-100k)", "Ville (>100k)"),
          include.lowest = TRUE
        )
      )
    
    cat("Population estimée pour les villages - Min:", round(min(donnees$villages$population_estimee, na.rm = TRUE)), 
        "Max:", round(max(donnees$villages$population_estimee, na.rm = TRUE)), 
        "Moyenne:", round(mean(donnees$villages$population_estimee, na.rm = TRUE)), "\n")
  }
  
  # Appliquer la même logique aux autres types de localités
  types_localites <- c("cities", "towns", "hamlets", "suburbs")
  for(type in types_localites) {
    if(!is.null(donnees[[type]])) {
      donnees[[type]] <- donnees[[type]] %>%
        mutate(
          population_estimee = case_when(
            fclass == "city" & is.na(population) ~ runif(n(), 100000, 500000),
            fclass == "town" & is.na(population) ~ runif(n(), 5000, 50000),
            fclass == "village" & is.na(population) ~ runif(n(), 100, 5000),
            fclass == "hamlet" & is.na(population) ~ runif(n(), 10, 100),
            fclass == "suburb" & is.na(population) ~ runif(n(), 1000, 20000),
            !is.na(population) & population > 0 ~ as.numeric(population),
            TRUE ~ NA_real_
          )
        )
    }
  }
  
  return(donnees)
}

# =============================================================================
# FONCTION DE CHARGEMENT ET NETTOYAGE DES DONNÉES
# =============================================================================

charger_donnees_completes <- function() {
  cat("Chargement des données OSM et aires protégées du Cameroun...\n")
  
  # Charger les données OSM disponibles
  donnees <- list()
  
  if(file.exists("gis_osm_places_free_1.shp")) {
    places <- st_read("gis_osm_places_free_1.shp", quiet = TRUE)
    
    # Nettoyer les données de population
    places <- places %>%
      mutate(
        population = as.numeric(population),
        population_corrigee = case_when(
          is.na(population) ~ NA_real_,
          population <= 0 ~ NA_real_,
          population > 1000000 ~ NA_real_,
          TRUE ~ population
        )
      )
    
    donnees$cities   <- filter(places, fclass == "city")
    donnees$towns    <- filter(places, fclass == "town")
    donnees$villages <- filter(places, fclass == "village")
    donnees$hamlets  <- filter(places, fclass == "hamlet")
    donnees$suburbs  <- filter(places, fclass == "suburb")
    
    cat("Lieux chargés - Villages:", nrow(donnees$villages), "\n")
  }
  
  if(file.exists("gis_osm_pois_free_1.shp")) {
    pois <- st_read("gis_osm_pois_free_1.shp", quiet = TRUE)
    donnees$hospitals  <- filter(pois, fclass == "hospital")
    donnees$clinics    <- filter(pois, fclass == "clinic")
    donnees$pharmacies <- filter(pois, fclass == "pharmacy")
    donnees$schools    <- filter(pois, fclass == "school")
    cat("Équipements chargés - Hôpitaux:", nrow(donnees$hospitals), 
        "Cliniques:", nrow(donnees$clinics), 
        "Écoles:", nrow(donnees$schools), "\n")
  }
  
  if(file.exists("gis_osm_railways_free_1.shp")) {
    railways <- st_read("gis_osm_railways_free_1.shp", quiet = TRUE)
    donnees$rail <- filter(railways, fclass == "rail")
    # Calculer la longueur totale des railways
    if(nrow(donnees$rail) > 0) {
      donnees$longueur_railways <- round(as.numeric(sum(st_length(donnees$rail))) / 1000, 1)
    } else {
      donnees$longueur_railways <- 0
    }
    cat("Railways chargés:", nrow(donnees$rail), "- Longueur totale:", donnees$longueur_railways, "km\n")
  }
  
  if(file.exists("gis_osm_waterways_free_1.shp")) {
    waterways <- st_read("gis_osm_waterways_free_1.shp", quiet = TRUE)
    donnees$rivers <- filter(waterways, fclass == "river")
  }
  
  if(file.exists("gis_osm_water_a_free_1.shp")) {
    donnees$water <- st_read("gis_osm_water_a_free_1.shp", quiet = TRUE)
  }
  
  # Charger les aires protégées
  cat("Chargement des aires protégées...\n")
  aires_protegees <- charger_aires_protegees()
  donnees$aires_protegees <- aires_protegees
  
  # Enrichir avec les données de population
  donnees <- enrichir_donnees_population(donnees)
  
  cat("Données complètes chargées avec succès !\n")
  return(donnees)
}

charger_aires_protegees <- function() {
  fichiers_zip <- c(
    "WDPA_WDOECM_Nov2025_Public_CMR_shp_0.zip",
    "WDPA_WDOECM_Nov2025_Public_CMR_shp_1.zip", 
    "WDPA_WDOECM_Nov2025_Public_CMR_shp_2.zip"
  )
  
  aires <- list()
  
  for(zip_file in fichiers_zip) {
    if(file.exists(zip_file)) {
      cat("Décompression de", zip_file, "...\n")
      unzip(zip_file, exdir = ".")
      break
    }
  }
  
  fichiers_aires_poly <- "WDPA_WDOECM_Nov2025_Public_CMR_shp-polygons.shp"
  fichiers_aires_points <- "WDPA_WDOECM_Nov2025_Public_CMR_shp-points.shp"
  
  if(file.exists(fichiers_aires_poly)) {
    aires$polygones <- st_read(fichiers_aires_poly, quiet = TRUE)
    if(!all(st_is_valid(aires$polygones))) {
      aires$polygones <- st_make_valid(aires$polygones)
    }
    cat("Aires protégées (polygones):", nrow(aires$polygones), "\n")
  }
  
  if(file.exists(fichiers_aires_points)) {
    aires$points <- st_read(fichiers_aires_points, quiet = TRUE)
    cat("Aires protégées (points):", nrow(aires$points), "\n")
  }
  
  return(aires)
}

# =============================================================================
# ANALYSES POUR POLITIQUES PUBLIQUES
# =============================================================================

analyser_pour_politiques_publiques <- function(donnees) {
  cat("Analyse pour les politiques publiques...\n")
  
  resultats <- list()
  
  # 1. ACCESSIBILITÉ AUX SERVICES DE SANTÉ
  if(!is.null(donnees$villages) && !is.null(donnees$hospitals)) {
    distances_sante <- st_distance(donnees$villages, donnees$hospitals)
    distance_min_sante <- apply(distances_sante, 1, min)
    
    resultats$accessibilite_sante <- donnees$villages %>%
      mutate(
        distance_hopital_km = as.numeric(distance_min_sante) / 1000,
        categorie_access_sante = cut(
          distance_hopital_km,
          breaks = c(0, 10, 25, 50, 100, Inf),
          labels = c("Très bonne (<10km)", "Bonne (10-25km)", "Moyenne (25-50km)", 
                     "Faible (50-100km)", "Très faible (>100km)")
        )
      )
    
    resultats$stats_sante <- summary(resultats$accessibilite_sante$distance_hopital_km)
  }
  
  # 2. ACCESSIBILITÉ AUX ÉCOLES
  if(!is.null(donnees$villages) && !is.null(donnees$schools)) {
    distances_ecoles <- st_distance(donnees$villages, donnees$schools)
    distance_min_ecoles <- apply(distances_ecoles, 1, min)
    
    resultats$accessibilite_education <- donnees$villages %>%
      mutate(
        distance_ecole_km = as.numeric(distance_min_ecoles) / 1000,
        categorie_access_ecole = cut(
          distance_ecole_km,
          breaks = c(0, 2, 5, 10, 20, Inf),
          labels = c("Excellente (<2km)", "Bonne (2-5km)", "Moyenne (5-10km)", 
                     "Faible (10-20km)", "Très faible (>20km)")
        )
      )
  }
  
  # 3. PROXIMITÉ AUX AIRES PROTÉGÉES
  if(!is.null(donnees$villages) && !is.null(donnees$aires_protegees$polygones)) {
    distances_aires <- st_distance(donnees$villages, donnees$aires_protegees$polygones)
    distance_min_aires <- apply(distances_aires, 1, min)
    
    resultats$proximite_aires <- donnees$villages %>%
      mutate(
        distance_aire_km = as.numeric(distance_min_aires) / 1000,
        zone_influence_aire = cut(
          distance_aire_km,
          breaks = c(0, 5, 10, 20, 50, Inf),
          labels = c("Zone tampon immédiate", "Zone d'influence proche", 
                     "Zone périphérique", "Zone éloignée", "Hors influence")
        )
      )
  }
  
  # 4. POTENTIEL ÉCOTOURISTIQUE
  if(!is.null(donnees$villages) && !is.null(donnees$aires_protegees$polygones)) {
    resultats$potentiel_ecotourisme <- resultats$proximite_aires %>%
      mutate(
        potentiel_ecotourisme = case_when(
          distance_aire_km <= 10 ~ "Élevé",
          distance_aire_km <= 25 ~ "Moyen",
          distance_aire_km <= 50 ~ "Faible",
          TRUE ~ "Nul"
        )
      )
  }
  
  # 5. CONNECTIVITÉ FERROVIAIRE
  if(!is.null(donnees$villages) && !is.null(donnees$rail)) {
    distances_rail <- st_distance(donnees$villages, donnees$rail)
    distance_min_rail <- apply(distances_rail, 1, min)
    
    resultats$connectivite_ferroviaire <- donnees$villages %>%
      mutate(
        distance_rail_km = as.numeric(distance_min_rail) / 1000,
        niveau_connectivite = cut(
          distance_rail_km,
          breaks = c(0, 5, 15, 30, 50, Inf),
          labels = c("Très bien connecté", "Bien connecté", "Connectivité moyenne", 
                     "Mal connecté", "Non connecté")
        )
      )
  }
  
  return(resultats)
}

# =============================================================================
# FONCTIONS AMÉLIORÉES POUR CRÉER DES CARTES INTERACTIVES AVEC SYMBOLOGIE DIFFÉRENCIÉE
# =============================================================================

creer_carte_strategique_interactive <- function(donnees, analyses) {
  cat("Création de la carte stratégique interactive...\n")
  
  carte_strategique <- leaflet() %>%
    addTiles(group = "Carte standard") %>%
    addProviderTiles(providers$CartoDB.Positron, group = "Carte claire") %>%
    addProviderTiles(providers$Esri.WorldImagery, group = "Satellite")
  
  # Aires protégées - style sobre
  if(!is.null(donnees$aires_protegees$polygones)) {
    carte_strategique <- carte_strategique %>%
      addPolygons(
        data = donnees$aires_protegees$polygones,
        group = "Aires protégées",
        color = "#006400",
        fillColor = "#228B22",
        fillOpacity = 0.4,  # Réduit l'opacité pour moins de surcharge
        weight = 1.5,       # Épaisseur réduite
        smoothFactor = 1,
        popup = ~paste(
          "<div style='font-family: Arial; max-width: 350px;'>",
          "<h4 style='color: #006400; margin-bottom: 10px;'>🏞️ ", ifelse(is.na(NAME), "Aire protégée", NAME), "</h4>",
          "<div style='background: #f8f9fa; padding: 10px; border-radius: 5px;'>",
          "<p style='margin: 5px 0;'><b>🗺️ Type:</b> ", ifelse(is.na(DESIG), "Non spécifié", DESIG), "</p>",
          "<p style='margin: 5px 0;'><b>📋 Statut:</b> ", ifelse(is.na(STATUS), "Inconnu", STATUS), "</p>",
          "<p style='margin: 5px 0;'><b>📏 Surface:</b> ", 
          ifelse(is.na(REP_AREA), "Inconnue", paste(format(round(REP_AREA, 1), big.mark = " "), "km²")), "</p>",
          "</div>",
          "</div>"
        )
      )
  }
  
  # Réseau ferroviaire - style distinct
  if(!is.null(donnees$rail)) {
    donnees_rail_avec_longueur <- donnees$rail %>%
      mutate(longueur_km = round(as.numeric(st_length(.)) / 1000, 1))
    
    carte_strategique <- carte_strategique %>%
      addPolylines(
        data = donnees_rail_avec_longueur,
        group = "Réseau ferroviaire",
        color = "#8B0000",
        weight = 3,         # Épaisseur réduite
        opacity = 0.7,
        dashArray = "5,5",  # Ligne pointillée pour distinction
        popup = ~paste(
          "<div style='font-family: Arial;'>",
          "<h4 style='color: #8B0000;'>🚆 Ligne ferroviaire</h4>",
          "<p><b>Longueur du segment:</b> ", longueur_km, " km</p>",
          "</div>"
        )
      )
  }
  
  # Villages par accessibilité santé - cercles de tailles différentes
  if(!is.null(analyses$accessibilite_sante)) {
    pal_sante <- colorFactor(
      palette = c("#1a9641", "#a6d96a", "#ffffbf", "#fdae61", "#d7191c"),
      domain = analyses$accessibilite_sante$categorie_access_sante
    )
    
    # Taille des cercles basée sur la population
    analyses$accessibilite_sante <- analyses$accessibilite_sante %>%
      mutate(
        radius = case_when(
          is.na(population_estimee) ~ 4,
          population_estimee < 100 ~ 3,
          population_estimee < 1000 ~ 5,
          population_estimee < 5000 ~ 7,
          population_estimee < 20000 ~ 9,
          TRUE ~ 11
        )
      )
    
    carte_strategique <- carte_strategique %>%
      addCircleMarkers(
        data = analyses$accessibilite_sante,
        group = "Accessibilité santé",
        radius = ~radius,
        color = ~pal_sante(categorie_access_sante),
        fillOpacity = 0.7,
        stroke = TRUE,
        weight = 1,
        opacity = 0.8,
        popup = ~paste(
          "<div style='font-family: Arial; max-width: 300px;'>",
          "<h4 style='color: #2c3e50; margin-bottom: 10px;'>🏘️ ", ifelse(is.na(name), "Village", name), "</h4>",
          "<div style='background: #f8f9fa; padding: 10px; border-radius: 5px;'>",
          "<p style='margin: 5px 0;'><b>👥 Population:</b> ", 
          ifelse(is.na(population_estimee), "Non disponible", 
                 format(round(population_estimee), big.mark = " ")), "</p>",
          "<p style='margin: 5px 0;'><b>🏥 Distance hôpital:</b> ", 
          round(distance_hopital_km, 1), " km</p>",
          "<p style='margin: 5px 0;'><b>📊 Niveau d'accès:</b> ", 
          as.character(categorie_access_sante), "</p>",
          "</div>",
          "</div>"
        )
      ) %>%
      addLegend(
        position = "bottomleft",
        pal = pal_sante,
        values = analyses$accessibilite_sante$categorie_access_sante,
        title = "Accessibilité Santé<br>(distance à l'hôpital)",
        opacity = 0.8,
        group = "Accessibilité santé"
      )
  }
  
  # Équipements de santé - icônes distinctes
  if(!is.null(donnees$hospitals)) {
    # Créer des icônes personnalisées pour les hôpitaux
    hospital_icon <- makeAwesomeIcon(
      icon = 'plus',
      markerColor = 'red',
      iconColor = 'white',
      library = 'fa'
    )
    
    carte_strategique <- carte_strategique %>%
      addAwesomeMarkers(
        data = donnees$hospitals,
        group = "Équipements santé",
        icon = hospital_icon,
        popup = ~paste(
          "<div style='font-family: Arial;'>",
          "<h4 style='color: #c0392b;'>🏥 Établissement de santé</h4>",
          "<p><b>Nom:</b> ", ifelse(is.na(name), "Non nommé", name), "</p>",
          "<p><b>Type:</b> Hôpital</p>",
          "</div>"
        )
      )
  }
  
  # Écoles - icônes distinctes
  if(!is.null(donnees$schools)) {
    school_icon <- makeAwesomeIcon(
      icon = 'graduation-cap',
      markerColor = 'blue',
      iconColor = 'white',
      library = 'fa'
    )
    
    carte_strategique <- carte_strategique %>%
      addAwesomeMarkers(
        data = donnees$schools,
        group = "Établissements éducatifs",
        icon = school_icon,
        popup = ~paste(
          "<div style='font-family: Arial;'>",
          "<h4 style='color: #2980b9;'>🏫 Établissement scolaire</h4>",
          "<p><b>Nom:</b> ", ifelse(is.na(name), "Non nommé", name), "</p>",
          "</div>"
        )
      )
  }
  
  # Villes principales - icônes distinctes
  if(!is.null(donnees$cities)) {
    city_icon <- makeAwesomeIcon(
      icon = 'building',
      markerColor = 'green',
      iconColor = 'white',
      library = 'fa'
    )
    
    carte_strategique <- carte_strategique %>%
      addAwesomeMarkers(
        data = donnees$cities,
        group = "Villes principales",
        icon = city_icon,
        popup = ~paste(
          "<div style='font-family: Arial;'>",
          "<h4 style='color: #228B22;'>🏙️ ", ifelse(is.na(name), "Ville", name), "</h4>",
          "<p><b>Population:</b> ", 
          ifelse(is.na(population_estimee), "Non disponible", 
                 format(round(population_estimee), big.mark = " ")), "</p>",
          "</div>"
        )
      )
  }
  
  # Contrôles des couches avec groupes organisés
  groupes_overlay <- c()
  if(!is.null(donnees$aires_protegees$polygones)) groupes_overlay <- c(groupes_overlay, "Aires protégées")
  if(!is.null(donnees$rail)) groupes_overlay <- c(groupes_overlay, "Réseau ferroviaire")
  if(!is.null(analyses$accessibilite_sante)) groupes_overlay <- c(groupes_overlay, "Accessibilité santé")
  if(!is.null(donnees$hospitals)) groupes_overlay <- c(groupes_overlay, "Équipements santé")
  if(!is.null(donnees$schools)) groupes_overlay <- c(groupes_overlay, "Établissements éducatifs")
  if(!is.null(donnees$cities)) groupes_overlay <- c(groupes_overlay, "Villes principales")
  
  # Configuration des contrôles de couches avec certains groupes désactivés par défaut
  carte_strategique <- carte_strategique %>%
    addLayersControl(
      baseGroups = c("Carte standard", "Carte claire", "Satellite"),
      overlayGroups = groupes_overlay,
      options = layersControlOptions(collapsed = FALSE)
    ) %>%
    # Désactiver certaines couches par défaut pour éviter la surcharge
    hideGroup("Équipements santé") %>%
    hideGroup("Établissements éducatifs") %>%
    hideGroup("Réseau ferroviaire") %>%
    addMiniMap(toggleDisplay = TRUE) %>%
    addMeasure(position = "topleft") %>%
    addScaleBar(position = "bottomleft") %>%
    addFullscreenControl() %>%
    # Ajouter un contrôle de recherche
    addSearchFeatures(
      targetGroups = c("Villes principales", "Accessibilité santé"),
      options = searchFeaturesOptions(
        zoom = 10, openPopup = TRUE, firstTipSubmit = TRUE,
        autoCollapse = TRUE, hideMarkerOnCollapse = TRUE
      )
    )
  
  htmlwidgets::saveWidget(carte_strategique, file = file.path(outputs_folder, "carte_strategique_interactive.html"))
  cat("✅ Carte stratégique interactive sauvegardée dans:", outputs_folder, "\n")
  
  return(carte_strategique)
}

creer_carte_accessibilite_interactive <- function(donnees, analyses) {
  cat("Création de la carte d'accessibilité interactive...\n")
  
  # Palette de couleurs pour l'accessibilité santé
  pal_sante <- colorFactor(
    palette = c("#1a9641", "#a6d96a", "#ffffbf", "#fdae61", "#d7191c"),
    domain = analyses$accessibilite_sante$categorie_access_sante
  )
  
  # Palette pour l'accessibilité éducation
  if(!is.null(analyses$accessibilite_education)) {
    pal_education <- colorFactor(
      palette = c("#1f78b4", "#a6cee3", "#ffffbf", "#fdbf6f", "#ff7f00"),
      domain = analyses$accessibilite_education$categorie_access_ecole
    )
  }
  
  carte <- leaflet() %>%
    addTiles(group = "Carte standard") %>%
    addProviderTiles(providers$CartoDB.Positron, group = "Carte claire")
  
  # Ajouter les villages avec accessibilité santé - tailles basées sur population
  if(!is.null(analyses$accessibilite_sante)) {
    analyses$accessibilite_sante <- analyses$accessibilite_sante %>%
      mutate(
        radius_sante = case_when(
          is.na(population_estimee) ~ 4,
          population_estimee < 100 ~ 3,
          population_estimee < 1000 ~ 5,
          population_estimee < 5000 ~ 7,
          TRUE ~ 9
        )
      )
    
    carte <- carte %>%
      addCircleMarkers(
        data = analyses$accessibilite_sante,
        group = "Accessibilité santé",
        radius = ~radius_sante,
        color = ~pal_sante(categorie_access_sante),
        fillOpacity = 0.8,
        stroke = TRUE,
        weight = 1,
        popup = ~paste(
          "<div style='font-family: Arial; max-width: 300px;'>",
          "<h4 style='color: #2c3e50; margin-bottom: 10px;'>🏘️ ", ifelse(is.na(name), "Village", name), "</h4>",
          "<div style='background: #f8f9fa; padding: 10px; border-radius: 5px;'>",
          "<p style='margin: 5px 0;'><b>👥 Population:</b> ", 
          ifelse(is.na(population_estimee), "Non disponible", 
                 format(round(population_estimee), big.mark = " ")), "</p>",
          "<p style='margin: 5px 0;'><b>🏥 Distance hôpital:</b> ", 
          round(distance_hopital_km, 1), " km</p>",
          "<p style='margin: 5px 0;'><b>📊 Niveau d'accès:</b> ", 
          as.character(categorie_access_sante), "</p>",
          "</div>",
          "</div>"
        )
      ) %>%
      addLegend(
        position = "bottomright",
        pal = pal_sante,
        values = analyses$accessibilite_sante$categorie_access_sante,
        title = "Accessibilité Santé<br>(distance à l'hôpital)",
        opacity = 0.8,
        group = "Accessibilité santé"
      )
  }
  
  # Ajouter les villages avec accessibilité éducation - formes différentes
  if(!is.null(analyses$accessibilite_education)) {
    analyses$accessibilite_education <- analyses$accessibilite_education %>%
      mutate(
        radius_education = case_when(
          is.na(population_estimee) ~ 4,
          population_estimee < 100 ~ 3,
          population_estimee < 1000 ~ 5,
          population_estimee < 5000 ~ 7,
          TRUE ~ 9
        )
      )
    
    carte <- carte %>%
      addCircleMarkers(
        data = analyses$accessibilite_education,
        group = "Accessibilité éducation",
        radius = ~radius_education,
        color = ~pal_education(categorie_access_ecole),
        fillOpacity = 0.8,
        stroke = TRUE,
        weight = 1,
        popup = ~paste(
          "<div style='font-family: Arial; max-width: 300px;'>",
          "<h4 style='color: #2c3e50; margin-bottom: 10px;'>🏘️ ", ifelse(is.na(name), "Village", name), "</h4>",
          "<div style='background: #f8f9fa; padding: 10px; border-radius: 5px;'>",
          "<p style='margin: 5px 0;'><b>👥 Population:</b> ", 
          ifelse(is.na(population_estimee), "Non disponible", 
                 format(round(population_estimee), big.mark = " ")), "</p>",
          "<p style='margin: 5px 0;'><b>🏫 Distance école:</b> ", 
          round(distance_ecole_km, 1), " km</p>",
          "<p style='margin: 5px 0;'><b>📊 Niveau d'accès:</b> ", 
          as.character(categorie_access_ecole), "</p>",
          "</div>",
          "</div>"
        )
      ) %>%
      addLegend(
        position = "bottomright",
        pal = pal_education,
        values = analyses$accessibilite_education$categorie_access_ecole,
        title = "Accessibilité Éducation<br>(distance à l'école)",
        opacity = 0.8,
        group = "Accessibilité éducation"
      )
  }
  
  # Ajouter les équipements de santé avec icônes distinctes
  if(!is.null(donnees$hospitals)) {
    hospital_icon <- makeAwesomeIcon(
      icon = 'plus',
      markerColor = 'red',
      iconColor = 'white',
      library = 'fa'
    )
    
    carte <- carte %>%
      addAwesomeMarkers(
        data = donnees$hospitals,
        group = "Équipements santé",
        icon = hospital_icon,
        popup = ~paste(
          "<div style='font-family: Arial;'>",
          "<h4 style='color: #c0392b;'>🏥 Établissement de santé</h4>",
          "<p><b>Nom:</b> ", ifelse(is.na(name), "Non nommé", name), "</p>",
          "<p><b>Type:</b> Hôpital</p>",
          "</div>"
        )
      )
  }
  
  # Ajouter les écoles avec icônes distinctes
  if(!is.null(donnees$schools)) {
    school_icon <- makeAwesomeIcon(
      icon = 'graduation-cap',
      markerColor = 'blue',
      iconColor = 'white',
      library = 'fa'
    )
    
    carte <- carte %>%
      addAwesomeMarkers(
        data = donnees$schools,
        group = "Établissements éducatifs",
        icon = school_icon,
        popup = ~paste(
          "<div style='font-family: Arial;'>",
          "<h4 style='color: #2980b9;'>🏫 Établissement scolaire</h4>",
          "<p><b>Nom:</b> ", ifelse(is.na(name), "Non nommé", name), "</p>",
          "</div>"
        )
      )
  }
  
  # Contrôles des couches
  groupes_overlay <- c()
  if(!is.null(analyses$accessibilite_sante)) groupes_overlay <- c(groupes_overlay, "Accessibilité santé")
  if(!is.null(analyses$accessibilite_education)) groupes_overlay <- c(groupes_overlay, "Accessibilité éducation")
  if(!is.null(donnees$hospitals)) groupes_overlay <- c(groupes_overlay, "Équipements santé")
  if(!is.null(donnees$schools)) groupes_overlay <- c(groupes_overlay, "Établissements éducatifs")
  
  carte <- carte %>%
    addLayersControl(
      baseGroups = c("Carte standard", "Carte claire"),
      overlayGroups = groupes_overlay,
      options = layersControlOptions(collapsed = FALSE)
    ) %>%
    hideGroup("Équipements santé") %>%
    hideGroup("Établissements éducatifs") %>%
    addMiniMap(toggleDisplay = TRUE) %>%
    addMeasure(position = "topleft") %>%
    addScaleBar(position = "bottomleft") %>%
    addFullscreenControl()
  
  htmlwidgets::saveWidget(carte, file = file.path(outputs_folder, "carte_accessibilite_interactive.html"))
  cat("✅ Carte accessibilité interactive sauvegardée dans:", outputs_folder, "\n")
  
  return(carte)
}

creer_carte_connectivite_interactive <- function(donnees, analyses) {
  cat("Création de la carte de connectivité interactive...\n")
  
  if(!is.null(analyses$connectivite_ferroviaire)) {
    # Palette pour la connectivité ferroviaire
    pal_rail <- colorFactor(
      palette = c("#00441B", "#238B45", "#74C476", "#BAE4B3", "#F7FCF5"),
      domain = analyses$connectivite_ferroviaire$niveau_connectivite
    )
    
    carte <- leaflet() %>%
      addTiles(group = "Carte standard") %>%
      addProviderTiles(providers$CartoDB.Positron, group = "Carte claire")
    
    # Ajouter le réseau ferroviaire avec style distinct
    if(!is.null(donnees$rail)) {
      donnees_rail_avec_longueur <- donnees$rail %>%
        mutate(longueur_km = round(as.numeric(st_length(.)) / 1000, 1))
      
      carte <- carte %>%
        addPolylines(
          data = donnees_rail_avec_longueur,
          group = "Réseau ferroviaire",
          color = "#8B0000",
          weight = 4,
          opacity = 0.8,
          popup = ~paste(
            "<div style='font-family: Arial;'>",
            "<h4 style='color: #8B0000;'>🚆 Ligne ferroviaire</h4>",
            "<p><b>Longueur du segment:</b> ", longueur_km, " km</p>",
            "</div>"
          )
        )
    }
    
    # Ajouter les villages avec connectivité - tailles basées sur population
    analyses$connectivite_ferroviaire <- analyses$connectivite_ferroviaire %>%
      mutate(
        radius_rail = case_when(
          is.na(population_estimee) ~ 4,
          population_estimee < 100 ~ 3,
          population_estimee < 1000 ~ 5,
          population_estimee < 5000 ~ 7,
          TRUE ~ 9
        )
      )
    
    carte <- carte %>%
      addCircleMarkers(
        data = analyses$connectivite_ferroviaire,
        group = "Connectivité villages",
        radius = ~radius_rail,
        color = ~pal_rail(niveau_connectivite),
        fillOpacity = 0.8,
        stroke = TRUE,
        weight = 1,
        popup = ~paste(
          "<div style='font-family: Arial; max-width: 300px;'>",
          "<h4 style='color: #2c3e50; margin-bottom: 10px;'>🏘️ ", ifelse(is.na(name), "Village", name), "</h4>",
          "<div style='background: #f8f9fa; padding: 10px; border-radius: 5px;'>",
          "<p style='margin: 5px 0;'><b>👥 Population:</b> ", 
          ifelse(is.na(population_estimee), "Non disponible", 
                 format(round(population_estimee), big.mark = " ")), "</p>",
          "<p style='margin: 5px 0;'><b>🚆 Distance rail:</b> ", 
          round(distance_rail_km, 1), " km</p>",
          "<p style='margin: 5px 0;'><b>📊 Niveau connectivité:</b> ", 
          as.character(niveau_connectivite), "</p>",
          "</div>",
          "</div>"
        )
      ) %>%
      addLegend(
        position = "bottomright",
        pal = pal_rail,
        values = analyses$connectivite_ferroviaire$niveau_connectivite,
        title = "Connectivité Ferroviaire<br>(distance au rail)",
        opacity = 0.8,
        group = "Connectivité villages"
      )
    
    # Contrôles des couches
    groupes_overlay <- c("Réseau ferroviaire", "Connectivité villages")
    
    carte <- carte %>%
      addLayersControl(
        baseGroups = c("Carte standard", "Carte claire"),
        overlayGroups = groupes_overlay,
        options = layersControlOptions(collapsed = FALSE)
      ) %>%
      addMiniMap(toggleDisplay = TRUE) %>%
      addScaleBar(position = "bottomleft") %>%
      addFullscreenControl()
    
    htmlwidgets::saveWidget(carte, file = file.path(outputs_folder, "carte_connectivite_interactive.html"))
    cat("✅ Carte connectivité interactive sauvegardée dans:", outputs_folder, "\n")
    
    return(carte)
  }
}

creer_carte_ecotourisme_interactive <- function(donnees, analyses) {
  cat("Création de la carte écotourisme interactive...\n")
  
  if(!is.null(analyses$potentiel_ecotourisme)) {
    # Palette pour le potentiel écotouristique
    pal_ecotourisme <- colorFactor(
      palette = c("#006D2C", "#41AB5D", "#74C476", "#BAE4B3"),
      domain = analyses$potentiel_ecotourisme$potentiel_ecotourisme
    )
    
    carte <- leaflet() %>%
      addTiles(group = "Carte standard") %>%
      addProviderTiles(providers$CartoDB.Positron, group = "Carte claire") %>%
      addProviderTiles(providers$Esri.WorldImagery, group = "Satellite")
    
    # Ajouter les aires protégées avec style sobre
    if(!is.null(donnees$aires_protegees$polygones)) {
      carte <- carte %>%
        addPolygons(
          data = donnees$aires_protegees$polygones,
          group = "Aires protégées",
          color = "#006400",
          fillColor = "#228B22",
          fillOpacity = 0.4,
          weight = 1.5,
          popup = ~paste(
            "<div style='font-family: Arial;'>",
            "<h4 style='color: #006400;'>🏞️ ", ifelse(is.na(NAME), "Aire protégée", NAME), "</h4>",
            "<p><b>Type:</b> ", ifelse(is.na(DESIG), "Non spécifié", DESIG), "</p>",
            "<p><b>Statut:</b> ", ifelse(is.na(STATUS), "Inconnu", STATUS), "</p>",
            "<p><b>Surface:</b> ", ifelse(is.na(REP_AREA), "Inconnue", paste(round(REP_AREA, 1), "km²")), "</p>",
            "</div>"
          )
        )
    }
    
    # Ajouter les villages avec potentiel écotouristique - tailles variables
    analyses$potentiel_ecotourisme <- analyses$potentiel_ecotourisme %>%
      mutate(
        radius_eco = case_when(
          is.na(population_estimee) ~ 4,
          population_estimee < 100 ~ 3,
          population_estimee < 1000 ~ 5,
          population_estimee < 5000 ~ 7,
          TRUE ~ 9
        )
      )
    
    carte <- carte %>%
      addCircleMarkers(
        data = analyses$potentiel_ecotourisme,
        group = "Potentiel écotouristique",
        radius = ~radius_eco,
        color = ~pal_ecotourisme(potentiel_ecotourisme),
        fillOpacity = 0.8,
        stroke = TRUE,
        weight = 1,
        popup = ~paste(
          "<div style='font-family: Arial; max-width: 300px;'>",
          "<h4 style='color: #2c3e50; margin-bottom: 10px;'>🏘️ ", ifelse(is.na(name), "Village", name), "</h4>",
          "<div style='background: #f8f9fa; padding: 10px; border-radius: 5px;'>",
          "<p style='margin: 5px 0;'><b>👥 Population:</b> ", 
          ifelse(is.na(population_estimee), "Non disponible", 
                 format(round(population_estimee), big.mark = " ")), "</p>",
          "<p style='margin: 5px 0;'><b>🏞️ Distance aire protégée:</b> ", 
          round(distance_aire_km, 1), " km</p>",
          "<p style='margin: 5px 0;'><b>🌟 Potentiel écotouristique:</b> ", 
          as.character(potentiel_ecotourisme), "</p>",
          "</div>",
          "</div>"
        )
      ) %>%
      addLegend(
        position = "bottomright",
        pal = pal_ecotourisme,
        values = analyses$potentiel_ecotourisme$potentiel_ecotourisme,
        title = "Potentiel Écotouristique",
        opacity = 0.8,
        group = "Potentiel écotouristique"
      )
    
    # Contrôles des couches
    groupes_overlay <- c()
    if(!is.null(donnees$aires_protegees$polygones)) groupes_overlay <- c(groupes_overlay, "Aires protégées")
    groupes_overlay <- c(groupes_overlay, "Potentiel écotouristique")
    
    carte <- carte %>%
      addLayersControl(
        baseGroups = c("Carte standard", "Carte claire", "Satellite"),
        overlayGroups = groupes_overlay,
        options = layersControlOptions(collapsed = FALSE)
      ) %>%
      addMiniMap(toggleDisplay = TRUE) %>%
      addScaleBar(position = "bottomleft") %>%
      addFullscreenControl()
    
    htmlwidgets::saveWidget(carte, file = file.path(outputs_folder, "carte_ecotourisme_interactive.html"))
    cat("✅ Carte écotourisme interactive sauvegardée dans:", outputs_folder, "\n")
    
    return(carte)
  }
}

creer_carte_biodiversite_interactive <- function(donnees) {
  cat("Création de la carte biodiversité interactive...\n")
  
  if(!is.null(donnees$aires_protegees$polygones)) {
    # Palette pour la surface des aires protégées
    pal_surface <- colorBin(
      palette = "viridis",
      domain = donnees$aires_protegees$polygones$REP_AREA,
      bins = 5,
      na.color = "#808080"
    )
    
    carte <- leaflet() %>%
      addTiles(group = "Carte standard") %>%
      addProviderTiles(providers$CartoDB.Positron, group = "Carte claire") %>%
      addProviderTiles(providers$Esri.WorldImagery, group = "Satellite")
    
    # Ajouter les aires protégées avec gradient de couleur
    carte <- carte %>%
      addPolygons(
        data = donnees$aires_protegees$polygones,
        group = "Aires protégées",
        color = ~pal_surface(REP_AREA),
        fillColor = ~pal_surface(REP_AREA),
        fillOpacity = 0.6,
        weight = 1.5,
        smoothFactor = 1,
        popup = ~paste(
          "<div style='font-family: Arial; max-width: 350px;'>",
          "<h4 style='color: #006400; margin-bottom: 10px;'>🏞️ ", ifelse(is.na(NAME), "Aire protégée", NAME), "</h4>",
          "<div style='background: #f8f9fa; padding: 10px; border-radius: 5px;'>",
          "<p style='margin: 5px 0;'><b>🗺️ Type:</b> ", ifelse(is.na(DESIG), "Non spécifié", DESIG), "</p>",
          "<p style='margin: 5px 0;'><b>📋 Statut:</b> ", ifelse(is.na(STATUS), "Inconnu", STATUS), "</p>",
          "<p style='margin: 5px 0;'><b>📏 Surface:</b> ", 
          ifelse(is.na(REP_AREA), "Inconnue", paste(format(round(REP_AREA, 1), big.mark = " "), "km²")), "</p>",
          "<p style='margin: 5px 0;'><b>🏛️ Gestion:</b> ", ifelse(is.na(GOV_TYPE), "Non spécifié", GOV_TYPE), "</p>",
          "</div>",
          "</div>"
        )
      ) %>%
      addLegend(
        position = "bottomright",
        pal = pal_surface,
        values = donnees$aires_protegees$polygones$REP_AREA,
        title = "Surface des Aires Protégées (km²)",
        opacity = 0.8,
        group = "Aires protégées",
        labFormat = labelFormat(suffix = " km²", big.mark = " ")
      )
    
    # Ajouter les villes principales pour référence avec icônes distinctes
    if(!is.null(donnees$cities)) {
      city_icon <- makeAwesomeIcon(
        icon = 'building',
        markerColor = 'darkpurple',
        iconColor = 'white',
        library = 'fa'
      )
      
      carte <- carte %>%
        addAwesomeMarkers(
          data = donnees$cities,
          group = "Villes principales",
          icon = city_icon,
          popup = ~paste(
            "<div style='font-family: Arial;'>",
            "<h4 style='color: #228B22;'>🏙️ ", ifelse(is.na(name), "Ville", name), "</h4>",
            "<p><b>Population:</b> ", 
            ifelse(is.na(population_estimee), "Non disponible", 
                   format(round(population_estimee), big.mark = " ")), "</p>",
            "</div>"
          )
        )
    }
    
    # Contrôles des couches
    groupes_overlay <- c("Aires protégées")
    if(!is.null(donnees$cities)) groupes_overlay <- c(groupes_overlay, "Villes principales")
    
    carte <- carte %>%
      addLayersControl(
        baseGroups = c("Carte standard", "Carte claire", "Satellite"),
        overlayGroups = groupes_overlay,
        options = layersControlOptions(collapsed = FALSE)
      ) %>%
      addMiniMap(toggleDisplay = TRUE) %>%
      addScaleBar(position = "bottomleft") %>%
      addFullscreenControl()
    
    htmlwidgets::saveWidget(carte, file = file.path(outputs_folder, "carte_biodiversite_interactive.html"))
    cat("✅ Carte biodiversité interactive sauvegardée dans:", outputs_folder, "\n")
    
    return(carte)
  }
}

creer_histogramme_interactif <- function(analyses) {
  cat("Création de l'histogramme interactif...\n")
  
  if(!is.null(analyses$accessibilite_sante)) {
    # Préparer les données pour plotly
    hist_data <- analyses$accessibilite_sante$distance_hopital_km
    median_distance <- median(hist_data, na.rm = TRUE)
    mean_distance <- mean(hist_data, na.rm = TRUE)
    
    # Créer un histogramme interactif avec plotly (version corrigée)
    hist_interactif <- plot_ly() %>%
      add_histogram(
        x = hist_data,
        nbinsx = 20,
        name = "Distribution des distances",
        marker = list(
          color = "#3182BD",
          line = list(color = "white", width = 1)
        ),
        hovertemplate = "Distance: %{x:.1f} km<br>Nombre de villages: %{y}<extra></extra>"
      ) %>%
      layout(
        # Ligne verticale pour la médiane
        shapes = list(
          list(
            type = "line",
            x0 = median_distance,
            x1 = median_distance,
            y0 = 0,
            y1 = 1,
            yref = "paper",
            line = list(color = "#E6550D", dash = "dash", width = 3)
          ),
          # Ligne verticale pour la moyenne
          list(
            type = "line",
            x0 = mean_distance,
            x1 = mean_distance,
            y0 = 0,
            y1 = 1,
            yref = "paper",
            line = list(color = "#756BB1", dash = "dot", width = 2)
          )
        ),
        # Annotations pour les lignes
        annotations = list(
          list(
            x = median_distance,
            y = 0.95,
            xref = "x",
            yref = "paper",
            text = paste("Médiane:", round(median_distance, 1), "km"),
            showarrow = TRUE,
            arrowhead = 7,
            ax = 0,
            ay = -40,
            font = list(color = "#E6550D", size = 12),
            bgcolor = "white",
            bordercolor = "#E6550D"
          ),
          list(
            x = mean_distance,
            y = 0.85,
            xref = "x",
            yref = "paper",
            text = paste("Moyenne:", round(mean_distance, 1), "km"),
            showarrow = TRUE,
            arrowhead = 7,
            ax = 0,
            ay = -40,
            font = list(color = "#756BB1", size = 12),
            bgcolor = "white",
            bordercolor = "#756BB1"
          )
        ),
        title = list(
          text = "<b>DISTRIBUTION DES DISTANCES VILLAGES-HÔPITAUX</b>",
          x = 0.5,
          font = list(size = 18, family = "Arial")
        ),
        xaxis = list(
          title = "<b>Distance à l'hôpital le plus proche (km)</b>",
          gridcolor = "#e1e5ed",
          zeroline = FALSE
        ),
        yaxis = list(
          title = "<b>Nombre de villages</b>",
          gridcolor = "#e1e5ed",
          zeroline = FALSE
        ),
        plot_bgcolor = "#f8f9fa",
        paper_bgcolor = "#ffffff",
        margin = list(t = 60, r = 40, b = 60, l = 60),
        hoverlabel = list(
          bgcolor = "white",
          font = list(color = "black", family = "Arial"),
          bordercolor = "#3182BD"
        ),
        font = list(family = "Arial")
      )
    
    # Ajouter des statistiques descriptives
    stats_text <- paste(
      "📊 <b>Statistiques descriptives:</b><br>",
      "• Minimum:", round(min(hist_data, na.rm = TRUE), 1), "km<br>",
      "• Maximum:", round(max(hist_data, na.rm = TRUE), 1), "km<br>",
      "• Écart-type:", round(sd(hist_data, na.rm = TRUE), 1), "km<br>",
      "• Villages analysés:", length(hist_data)
    )
    
    hist_interactif <- hist_interactif %>%
      layout(
        annotations = list(
          list(
            x = 0.02,
            y = 0.98,
            xref = "paper",
            yref = "paper",
            text = stats_text,
            showarrow = FALSE,
            align = "left",
            bgcolor = "rgba(255,255,255,0.8)",
            bordercolor = "#3182BD",
            borderwidth = 1,
            font = list(size = 10)
          )
        )
      )
    
    htmlwidgets::saveWidget(hist_interactif, file = file.path(outputs_folder, "histogramme_distances_interactif.html"))
    cat("✅ Histogramme interactif sauvegardé dans:", outputs_folder, "\n")
    
    return(hist_interactif)
  } else {
    cat("❌ Données d'accessibilité santé non disponibles pour l'histogramme\n")
    return(NULL)
  }
}

# =============================================================================
# FONCTION AMÉLIORÉE POUR CRÉER TOUTES LES VISUALISATIONS INTERACTIVES
# =============================================================================

creer_visualisations_interactives_completes <- function(donnees, analyses) {
  cat("Création de toutes les visualisations interactives...\n")
  
  # 1. Carte stratégique interactive
  carte_strategique <- creer_carte_strategique_interactive(donnees, analyses)
  
  # 2. Carte d'accessibilité interactive
  carte_accessibilite <- creer_carte_accessibilite_interactive(donnees, analyses)
  
  # 3. Carte de connectivité interactive
  carte_connectivite <- creer_carte_connectivite_interactive(donnees, analyses)
  
  # 4. Carte écotourisme interactive
  carte_ecotourisme <- creer_carte_ecotourisme_interactive(donnees, analyses)
  
  # 5. Carte biodiversité interactive
  carte_biodiversite <- creer_carte_biodiversite_interactive(donnees)
  
  # 6. Histogramme interactif
  histogramme_interactif <- creer_histogramme_interactif(analyses)
  
  cat("✅ Toutes les visualisations interactives créées avec succès!\n")
  
  return(list(
    strategique = carte_strategique,
    accessibilite = carte_accessibilite,
    connectivite = carte_connectivite,
    ecotourisme = carte_ecotourisme,
    biodiversite = carte_biodiversite,
    histogramme = histogramme_interactif
  ))
}

# =============================================================================
# FONCTION AMÉLIORÉE POUR GÉNÉRER LE RAPPORT AVEC TOUTES LES CARTES INTERACTIVES
# =============================================================================

generer_rapport_ameliore <- function(donnees, analyses, visualisations) {
  cat("Génération du rapport amélioré avec cartes interactives...\n")
  
  # Calcul des indicateurs clés
  indicateurs_clés <- list()
  
  if(!is.null(analyses$accessibilite_sante)) {
    indicateurs_clés$villages_sante_proche <- sum(analyses$accessibilite_sante$distance_hopital_km <= 25, na.rm = TRUE)
    indicateurs_clés$distance_mediane_sante <- round(median(analyses$accessibilite_sante$distance_hopital_km, na.rm = TRUE), 1)
    indicateurs_clés$villages_sante_eloignes <- sum(analyses$accessibilite_sante$distance_hopital_km > 50, na.rm = TRUE)
  }
  
  if(!is.null(analyses$connectivite_ferroviaire)) {
    indicateurs_clés$villages_connectes <- sum(analyses$connectivite_ferroviaire$distance_rail_km <= 15, na.rm = TRUE)
    indicateurs_clés$villages_non_connectes <- sum(analyses$connectivite_ferroviaire$distance_rail_km > 30, na.rm = TRUE)
  }
  
  if(!is.null(analyses$potentiel_ecotourisme)) {
    indicateurs_clés$potentiel_ecotourisme_eleve <- sum(analyses$potentiel_ecotourisme$potentiel_ecotourisme == "Élevé", na.rm = TRUE)
    indicateurs_clés$potentiel_ecotourisme_moyen <- sum(analyses$potentiel_ecotourisme$potentiel_ecotourisme == "Moyen", na.rm = TRUE)
  }
  
  # Lecture du tableau de bord pour les indicateurs supplémentaires
  if(file.exists(file.path(outputs_folder, "tableau_bord_indicateurs.csv"))) {
    tableau_bord <- read.csv(file.path(outputs_folder, "tableau_bord_indicateurs.csv"))
  }
  
  rapport_content <- paste('
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport Stratégique - Cameroun</title>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <style>
        :root {
            --primary-color: #2c3e50;
            --secondary-color: #3498db;
            --accent-color: #e74c3c;
            --success-color: #27ae60;
            --warning-color: #f39c12;
            --light-bg: #f8f9fa;
            --dark-text: #2c3e50;
        }
        
        body {
            font-family: "Segoe UI", Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: var(--dark-text);
        }
        
        .container {
            max-width: 1400px;
            margin: 20px auto;
            background: white;
            border-radius: 15px;
            box-shadow: 0 15px 35px rgba(0,0,0,0.1);
            overflow: hidden;
        }
        
        .header {
            background: linear-gradient(135deg, var(--primary-color), var(--secondary-color));
            color: white;
            padding: 40px;
            text-align: center;
            position: relative;
        }
        
        .header h1 {
            margin: 0;
            font-size: 2.5em;
            font-weight: 300;
        }
        
        .header p {
            font-size: 1.2em;
            opacity: 0.9;
            margin: 10px 0 0 0;
        }
        
        .nav-tabs {
            display: flex;
            background: var(--light-bg);
            border-bottom: 1px solid #ddd;
            flex-wrap: wrap;
        }
        
        .nav-tab {
            padding: 15px 25px;
            cursor: pointer;
            border: none;
            background: none;
            font-size: 16px;
            font-weight: 500;
            transition: all 0.3s ease;
            border-bottom: 3px solid transparent;
            white-space: nowrap;
        }
        
        .nav-tab:hover {
            background: #e9ecef;
        }
        
        .nav-tab.active {
            border-bottom: 3px solid var(--secondary-color);
            color: var(--secondary-color);
            background: white;
        }
        
        .tab-content {
            display: none;
            padding: 30px;
            animation: fadeIn 0.5s ease-in;
        }
        
        .tab-content.active {
            display: block;
        }
        
        .kpi-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
            gap: 20px;
            margin: 30px 0;
        }
        
        .kpi-card {
            background: white;
            padding: 25px;
            border-radius: 10px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.08);
            text-align: center;
            border-left: 5px solid var(--secondary-color);
            transition: transform 0.3s ease;
        }
        
        .kpi-card:hover {
            transform: translateY(-5px);
        }
        
        .kpi-card.health { border-left-color: var(--accent-color); }
        .kpi-card.transport { border-left-color: var(--warning-color); }
        .kpi-card.tourism { border-left-color: var(--success-color); }
        .kpi-card.environment { border-left-color: #9b59b6; }
        
        .kpi-value {
            font-size: 2.5em;
            font-weight: bold;
            margin: 10px 0;
            color: var(--primary-color);
        }
        
        .kpi-label {
            font-size: 1.1em;
            color: #666;
        }
        
        .kpi-icon {
            font-size: 2em;
            margin-bottom: 10px;
            color: var(--secondary-color);
        }
        
        .visualization-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(600px, 1fr));
            gap: 25px;
            margin: 30px 0;
        }
        
        .viz-card {
            background: white;
            border-radius: 10px;
            overflow: hidden;
            box-shadow: 0 5px 15px rgba(0,0,0,0.08);
            display: flex;
            flex-direction: column;
        }
        
        .viz-frame {
            width: 100%;
            height: 500px;
            border: none;
            flex-grow: 1;
        }
        
        .viz-content {
            padding: 20px;
            background: white;
        }
        
        .viz-title {
            font-size: 1.3em;
            font-weight: 600;
            margin-bottom: 10px;
            color: var(--primary-color);
        }
        
        .recommendations {
            background: var(--light-bg);
            padding: 30px;
            border-radius: 10px;
            margin: 30px 0;
        }
        
        .rec-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
        }
        
        .rec-card {
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 3px 10px rgba(0,0,0,0.1);
        }
        
        .rec-icon {
            font-size: 2em;
            margin-bottom: 15px;
            color: var(--secondary-color);
        }
        
        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(20px); }
            to { opacity: 1; transform: translateY(0); }
        }
        
        .interactive-frame {
            width: 100%;
            height: 600px;
            border: none;
            border-radius: 10px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.1);
        }
        
        .download-section {
            text-align: center;
            padding: 30px;
            background: var(--light-bg);
            border-radius: 10px;
            margin: 30px 0;
        }
        
        .btn {
            display: inline-block;
            padding: 12px 30px;
            background: var(--secondary-color);
            color: white;
            text-decoration: none;
            border-radius: 5px;
            margin: 0 10px;
            transition: background 0.3s ease;
        }
        
        .btn:hover {
            background: #2980b9;
        }
        
        .data-table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
        }
        
        .data-table th, .data-table td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        
        .data-table th {
            background-color: var(--primary-color);
            color: white;
        }
        
        .data-table tr:hover {
            background-color: #f5f5f5;
        }
        
        .legend-note {
            font-size: 0.9em;
            color: #666;
            font-style: italic;
            margin-top: 10px;
        }
        
        .feature-info {
            background: #e8f4fd;
            padding: 15px;
            border-radius: 8px;
            margin: 15px 0;
            border-left: 4px solid var(--secondary-color);
        }
        
        .symbology-guide {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 8px;
            margin: 20px 0;
        }
        
        .symbology-item {
            display: flex;
            align-items: center;
            margin: 10px 0;
        }
        
        .symbology-icon {
            width: 30px;
            height: 30px;
            margin-right: 15px;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        
        @media (max-width: 768px) {
            .visualization-grid {
                grid-template-columns: 1fr;
            }
            
            .nav-tabs {
                flex-direction: column;
            }
            
            .nav-tab {
                text-align: center;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1><i class="fas fa-chart-line"></i> RAPPORT STRATÉGIQUE CAMEROUN</h1>
            <p>Analyse intégrée pour les politiques publiques de développement</p>
            <p style="font-size: 0.9em; opacity: 0.8;">Dossier data: ', data_folder, '</p>
        </div>
        
        <div class="nav-tabs">
            <button class="nav-tab active" onclick="openTab(\'dashboard\')">
                <i class="fas fa-tachometer-alt"></i> Tableau de Bord
            </button>
            <button class="nav-tab" onclick="openTab(\'accessibility\')">
                <i class="fas fa-hospital"></i> Accessibilité
            </button>
            <button class="nav-tab" onclick="openTab(\'infrastructure\')">
                <i class="fas fa-train"></i> Infrastructure
            </button>
            <button class="nav-tab" onclick="openTab(\'tourism\')">
                <i class="fas fa-tree"></i> Écotourisme
            </button>
            <button class="nav-tab" onclick="openTab(\'environment\')">
                <i class="fas fa-leaf"></i> Environnement
            </button>
            <button class="nav-tab" onclick="openTab(\'symbology\')">
                <i class="fas fa-map-marked-alt"></i> Guide Cartographique
            </button>
            <button class="nav-tab" onclick="openTab(\'data\')">
                <i class="fas fa-database"></i> Données
            </button>
            <button class="nav-tab" onclick="openTab(\'recommendations\')">
                <i class="fas fa-lightbulb"></i> Recommandations
            </button>
        </div>
        
        <!-- TAB TABLEAU DE BORD -->
        <div id="dashboard" class="tab-content active">
            <h2><i class="fas fa-tachometer-alt"></i> TABLEAU DE BORD STRATÉGIQUE</h2>
            
            <div class="kpi-grid">
                <div class="kpi-card health">
                    <div class="kpi-icon"><i class="fas fa-hospital"></i></div>
                    <div class="kpi-value">', ifelse(!is.null(indicateurs_clés$villages_sante_proche), indicateurs_clés$villages_sante_proche, "N/A"), '</div>
                    <div class="kpi-label">Villages avec accès santé acceptable (<25km)</div>
                </div>
                
                <div class="kpi-card transport">
                    <div class="kpi-icon"><i class="fas fa-train"></i></div>
                    <div class="kpi-value">', ifelse(!is.null(indicateurs_clés$villages_connectes), indicateurs_clés$villages_connectes, "N/A"), '</div>
                    <div class="kpi-label">Villages bien connectés au réseau ferroviaire</div>
                </div>
                
                <div class="kpi-card tourism">
                    <div class="kpi-icon"><i class="fas fa-tree"></i></div>
                    <div class="kpi-value">', ifelse(!is.null(indicateurs_clés$potentiel_ecotourisme_eleve), indicateurs_clés$potentiel_ecotourisme_eleve, "N/A"), '</div>
                    <div class="kpi-label">Villages à fort potentiel écotouristique</div>
                </div>
                
                <div class="kpi-card environment">
                    <div class="kpi-icon"><i class="fas fa-mountain"></i></div>
                    <div class="kpi-value">', ifelse(!is.null(donnees$aires_protegees$polygones), nrow(donnees$aires_protegees$polygones), "N/A"), '</div>
                    <div class="kpi-label">Aires protégées identifiées</div>
                </div>
            </div>
            
            <div class="visualization-grid">
                <div class="viz-card">
                    <iframe src="carte_strategique_interactive.html" class="viz-frame"></iframe>
                    <div class="viz-content">
                        <div class="viz-title">Carte Interactive Stratégique</div>
                        <p>Explorez les données avec différentes couches : aires protégées, réseau ferroviaire, accessibilité santé, équipements.</p>
                        <div class="feature-info">
                            <strong>🚀 Fonctionnalités interactives :</strong>
                            <ul>
                                <li>🔄 Contrôle des couches (en haut à droite)</li>
                                <li>🔍 Zoom et déplacement</li>
                                <li>📊 Infobulles détaillées au clic</li>
                                <li>🗺️ Mini-carte de navigation</li>
                                <li>📏 Outils de mesure</li>
                                <li>🔎 Fonction de recherche</li>
                            </ul>
                        </div>
                    </div>
                </div>
                
                <div class="viz-card">
                    <iframe src="histogramme_distances_interactif.html" class="viz-frame"></iframe>
                    <div class="viz-content">
                        <div class="viz-title">Distribution Interactive des Distances</div>
                        <p>Analyse statistique des temps d\'accès aux soins médicaux avec visualisation interactive.</p>
                        <div class="feature-info">
                            <strong>📈 Fonctionnalités :</strong>
                            <ul>
                                <li>📊 Histogramme interactif</li>
                                <li>📏 Ligne médiane automatique</li>
                                <li>🖱️ Survol pour les détails</li>
                                <li>📱 Zoom et sélection</li>
                            </ul>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        
        <!-- TAB ACCESSIBILITÉ -->
        <div id="accessibility" class="tab-content">
            <h2><i class="fas fa-hospital"></i> ANALYSE DE L\'ACCESSIBILITÉ</h2>
            
            <div class="feature-info">
                <strong>📋 Indicateurs d\'accessibilité :</strong>
                <ul>
                    <li><strong>Distance aux hôpitaux :</strong> ', ifelse(!is.null(indicateurs_clés$distance_mediane_sante), paste(indicateurs_clés$distance_mediane_sante, "km (médiane)"), "N/A"), '</li>
                    <li><strong>Villages bien desservis :</strong> ', ifelse(!is.null(indicateurs_clés$villages_sante_proche), indicateurs_clés$villages_sante_proche, "N/A"), ' villages</li>
                    <li><strong>Villages éloignés :</strong> ', ifelse(!is.null(indicateurs_clés$villages_sante_eloignes), indicateurs_clés$villages_sante_eloignes, "N/A"), ' villages (>50km)</li>
                </ul>
            </div>
            
            <div class="visualization-grid">
                <div class="viz-card">
                    <iframe src="carte_accessibilite_interactive.html" class="viz-frame"></iframe>
                    <div class="viz-content">
                        <div class="viz-title">Carte Interactive d\'Accessibilité</div>
                        <p>Visualisation complète de l\'accessibilité aux services de santé et d\'éducation sur l\'ensemble du territoire.</p>
                        <div class="feature-info">
                            <strong>🎨 Légendes dynamiques :</strong>
                            <ul>
                                <li>🏥 Accessibilité santé (5 catégories)</li>
                                <li>🏫 Accessibilité éducation (5 catégories)</li>
                                <li>📍 Équipements de santé et écoles</li>
                                <li>📊 Infobulles détaillées par village</li>
                            </ul>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        
        <!-- TAB INFRASTRUCTURE -->
        <div id="infrastructure" class="tab-content">
            <h2><i class="fas fa-train"></i> INFRASTRUCTURES DE TRANSPORT</h2>
            
            <div class="feature-info">
                <strong>🚆 État du réseau ferroviaire :</strong>
                <ul>
                    <li><strong>Villages bien connectés :</strong> ', ifelse(!is.null(indicateurs_clés$villages_connectes), indicateurs_clés$villages_connectes, "N/A"), ' villages</li>
                    <li><strong>Villages non connectés :</strong> ', ifelse(!is.null(indicateurs_clés$villages_non_connectes), indicateurs_clés$villages_non_connectes, "N/A"), ' villages</li>
                    <li><strong>Longueur du réseau :</strong> ', ifelse(!is.null(donnees$longueur_railways), donnees$longueur_railways, "N/A"), ' km</li>
                </ul>
            </div>
            
            <div class="visualization-grid">
                <div class="viz-card">
                    <iframe src="carte_connectivite_interactive.html" class="viz-frame"></iframe>
                    <div class="viz-content">
                        <div class="viz-title">Connectivité Ferroviaire Interactive</div>
                        <p>Analyse détaillée de l\'accès au réseau ferroviaire national avec légende dynamique.</p>
                        <div class="feature-info">
                            <strong>🚊 Couches disponibles :</strong>
                            <ul>
                                <li>🛤️ Réseau ferroviaire détaillé</li>
                                <li>🏘️ Niveaux de connectivité (5 catégories)</li>
                                <li>📏 Distances exactes au réseau</li>
                                <li>📊 Informations par segment</li>
                            </ul>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        
        <!-- TAB ÉCOTOURISME -->
        <div id="tourism" class="tab-content">
            <h2><i class="fas fa-tree"></i> POTENTIEL ÉCOTOURISTIQUE</h2>
            
            <div class="feature-info">
                <strong>🌟 Potentiel identifié :</strong>
                <ul>
                    <li><strong>Potentiel élevé :</strong> ', ifelse(!is.null(indicateurs_clés$potentiel_ecotourisme_eleve), indicateurs_clés$potentiel_ecotourisme_eleve, "N/A"), ' villages</li>
                    <li><strong>Potentiel moyen :</strong> ', ifelse(!is.null(indicateurs_clés$potentiel_ecotourisme_moyen), indicateurs_clés$potentiel_ecotourisme_moyen, "N/A"), ' villages</li>
                    <li><strong>Total des villages analysés :</strong> ', ifelse(!is.null(donnees$villages), nrow(donnees$villages), "N/A"), '</li>
                </ul>
            </div>
            
            <div class="visualization-grid">
                <div class="viz-card">
                    <iframe src="carte_ecotourisme_interactive.html" class="viz-frame"></iframe>
                    <div class="viz-content">
                        <div class="viz-title">Carte Interactive du Potentiel Écotouristique</div>
                        <p>Identification des villages propices au développement du tourisme durable basé sur la proximité des aires protégées.</p>
                        <div class="feature-info">
                            <strong>🌿 Éléments cartographiques :</strong>
                            <ul>
                                <li>🏞️ Aires protégées délimitées</li>
                                <li>🎯 Potentiel écotouristique (4 niveaux)</li>
                                <li>👥 Taille des villages selon population</li>
                                <li>📊 Distances aux aires protégées</li>
                            </ul>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        
        <!-- TAB ENVIRONNEMENT -->
        <div id="environment" class="tab-content">
            <h2><i class="fas fa-leaf"></i> PROTECTION ENVIRONNEMENTALE</h2>
            
            <div class="feature-info">
                <strong>🏞️ Réseau d\'aires protégées :</strong>
                <ul>
                    <li><strong>Nombre d\'aires protégées :</strong> ', ifelse(!is.null(donnees$aires_protegees$polygones), nrow(donnees$aires_protegees$polygones), "N/A"), '</li>
                    <li><strong>Surface totale :</strong> ', ifelse(!is.null(donnees$aires_protegees$polygones), paste(round(sum(donnees$aires_protegees$polygones$REP_AREA, na.rm = TRUE), 1), "km²"), "N/A"), '</li>
                    <li><strong>Surface moyenne :</strong> ', ifelse(!is.null(donnees$aires_protegees$polygones), paste(round(mean(donnees$aires_protegees$polygones$REP_AREA, na.rm = TRUE), 1), "km²"), "N/A"), '</li>
                </ul>
            </div>
            
            <div class="visualization-grid">
                <div class="viz-card">
                    <iframe src="carte_biodiversite_interactive.html" class="viz-frame"></iframe>
                    <div class="viz-content">
                        <div class="viz-title">Carte Interactive de la Biodiversité</div>
                        <p>Cartographie complète des aires protégées avec visualisation des surfaces et informations détaillées.</p>
                        <div class="feature-info">
                            <strong>🦁 Caractéristiques :</strong>
                            <ul>
                                <li>🎨 Gradient de couleur par surface</li>
                                <li>📏 Légende des surfaces (km²)</li>
                                <li>🏛️ Informations de gestion</li>
                                <li>🏙️ Villes de référence</li>
                                <li>🛰️ Vue satellite disponible</li>
                            </ul>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        
        <!-- TAB GUIDE CARTOGRAPHIQUE -->
        <div id="symbology" class="tab-content">
            <h2><i class="fas fa-map-marked-alt"></i> GUIDE DE SYMBOLOGIE CARTOGRAPHIQUE</h2>
            
            <div class="symbology-guide">
                <h3><i class="fas fa-icons"></i> Légende des Symboles Utilisés</h3>
                
                <h4>🏘️ Types de Localités (taille proportionnelle à la population)</h4>
                <div class="symbology-item">
                    <div class="symbology-icon" style="background: #1a9641; border-radius: 50%; width: 12px; height: 12px;"></div>
                    <span>Très petit village (&lt;100 habitants)</span>
                </div>
                <div class="symbology-item">
                    <div class="symbology-icon" style="background: #1a9641; border-radius: 50%; width: 16px; height: 16px;"></div>
                    <span>Petit village (100-1,000 habitants)</span>
                </div>
                <div class="symbology-item">
                    <div class="symbology-icon" style="background: #1a9641; border-radius: 50%; width: 20px; height: 20px;"></div>
                    <span>Village moyen (1,000-5,000 habitants)</span>
                </div>
                <div class="symbology-item">
                    <div class="symbology-icon" style="background: #1a9641; border-radius: 50%; width: 24px; height: 24px;"></div>
                    <span>Grand village (&gt;5,000 habitants)</span>
                </div>
                
                <h4>🏥 Équipements de Santé</h4>
                <div class="symbology-item">
                    <div class="symbology-icon"><i class="fas fa-plus" style="color: red;"></i></div>
                    <span>Hôpitaux</span>
                </div>
                
                <h4>🏫 Établissements Éducatifs</h4>
                <div class="symbology-item">
                    <div class="symbology-icon"><i class="fas fa-graduation-cap" style="color: blue;"></i></div>
                    <span>Écoles</span>
                </div>
                
                <h4>🏙️ Villes Principales</h4>
                <div class="symbology-item">
                    <div class="symbology-icon"><i class="fas fa-building" style="color: green;"></i></div>
                    <span>Villes</span>
                </div>
                
                <h4>🛤️ Infrastructure de Transport</h4>
                <div class="symbology-item">
                    <div class="symbology-icon" style="background: #8B0000; width: 20px; height: 3px;"></div>
                    <span>Réseau ferroviaire</span>
                </div>
                
                <h4>🏞️ Aires Protégées</h4>
                <div class="symbology-item">
                    <div class="symbology-icon" style="background: #228B22; width: 20px; height: 15px; border: 1px solid #006400;"></div>
                    <span>Zones protégées (remplissage vert)</span>
                </div>
            </div>
            
            <div class="feature-info">
                <strong>💡 Conseils d\'Utilisation des Cartes :</strong>
                <ul>
                    <li><strong>Gestion des couches :</strong> Utilisez le contrôle en haut à droite pour activer/désactiver les différentes couches</li>
                    <li><strong>Éviter la surcharge :</strong> Désactivez les couches non nécessaires pour une meilleure lisibilité</li>
                    <li><strong>Navigation :</strong> Utilisez la mini-carte pour vous repérer rapidement</li>
                    <li><strong>Recherche :</strong> Utilisez la loupe pour rechercher des localités spécifiques</li>
                    <li><strong>Mesure :</strong> L\'outil de mesure permet de calculer des distances directement sur la carte</li>
                </ul>
            </div>
        </div>
        
        <!-- TAB DONNÉES -->
        <div id="data" class="tab-content">
            <h2><i class="fas fa-database"></i> DONNÉES ET INDICATEURS</h2>
            
            <div class="kpi-grid">
                <div class="kpi-card">
                    <div class="kpi-icon"><i class="fas fa-village"></i></div>
                    <div class="kpi-value">', ifelse(!is.null(donnees$villages), nrow(donnees$villages), "N/A"), '</div>
                    <div class="kpi-label">Villages analysés</div>
                </div>
                
                <div class="kpi-card">
                    <div class="kpi-icon"><i class="fas fa-hospital"></i></div>
                    <div class="kpi-value">', ifelse(!is.null(donnees$hospitals), nrow(donnees$hospitals), "N/A"), '</div>
                    <div class="kpi-label">Hôpitaux recensés</div>
                </div>
                
                <div class="kpi-card">
                    <div class="kpi-icon"><i class="fas fa-school"></i></div>
                    <div class="kpi-value">', ifelse(!is.null(donnees$schools), nrow(donnees$schools), "N/A"), '</div>
                    <div class="kpi-label">Établissements scolaires</div>
                </div>
                
                <div class="kpi-card">
                    <div class="kpi-icon"><i class="fas fa-train"></i></div>
                    <div class="kpi-value">', ifelse(!is.null(donnees$longueur_railways), donnees$longueur_railways, "N/A"), '</div>
                    <div class="kpi-label">km de voies ferrées</div>
                </div>
            </div>
            
            <div class="download-section">
                <h3><i class="fas fa-download"></i> Téléchargements</h3>
                <p>Accédez aux données et analyses complètes :</p>
                <a href="tableau_bord_indicateurs.csv" class="btn" download>
                    <i class="fas fa-table"></i> Données Indicateurs
                </a>
                <a href="carte_strategique_interactive.html" class="btn" download>
                    <i class="fas fa-map"></i> Carte Interactive Principale
                </a>
            </div>
            
            <div class="feature-info">
                <strong>📊 Métadonnées :</strong>
                <ul>
                    <li><strong>Source des données OSM :</strong> OpenStreetMap</li>
                    <li><strong>Source des aires protégées :</strong> WDPA (World Database on Protected Areas)</li>
                    <li><strong>Données de population :</strong> Estimations basées sur le type de localité</li>
                    <li><strong>Date des données :</strong> Novembre 2025</li>
                    <li><strong>Système de coordonnées :</strong> WGS84</li>
                </ul>
            </div>
        </div>
        
        <!-- TAB RECOMMANDATIONS -->
        <div id="recommendations" class="tab-content">
            <h2><i class="fas fa-lightbulb"></i> RECOMMANDATIONS STRATÉGIQUES</h2>
            
            <div class="rec-grid">
                <div class="rec-card">
                    <div class="rec-icon"><i class="fas fa-heartbeat"></i></div>
                    <h4>Santé Publique</h4>
                    <ul>
                        <li><strong>Priorité 1 :</strong> Construction de centres de santé dans les zones éloignées (>50km des hôpitaux)</li>
                        <li><strong>Priorité 2 :</strong> Développement d\'un réseau de télé-médecine pour les villages isolés</li>
                        <li><strong>Priorité 3 :</strong> Amélioration des routes d\'accès aux hôpitaux existants</li>
                        <li><strong>Priorité 4 :</strong> Formation du personnel médical local</li>
                    </ul>
                </div>
                
                <div class="rec-card">
                    <div class="rec-icon"><i class="fas fa-road"></i></div>
                    <h4>Infrastructures</h4>
                    <ul>
                        <li><strong>Priorité 1 :</strong> Extension du réseau ferroviaire vers les régions isolées</li>
                        <li><strong>Priorité 2 :</strong> Amélioration de la connectivité routière vers les aires protégées</li>
                        <li><strong>Priorité 3 :</strong> Développement des transports publics inter-villages</li>
                        <li><strong>Priorité 4 :</strong> Modernisation des gares existantes</li>
                    </ul>
                </div>
                
                <div class="rec-card">
                    <div class="rec-icon"><i class="fas fa-leaf"></i></div>
                    <h4>Environnement & Tourisme</h4>
                    <ul>
                        <li><strong>Priorité 1 :</strong> Renforcement de la protection des aires protégées critiques</li>
                        <li><strong>Priorité 2 :</strong> Développement de l\'écotourisme communautaire dans les villages à fort potentiel</li>
                        <li><strong>Priorité 3 :</strong> Promotion de l\'agriculture durable en périphérie des aires protégées</li>
                        <li><strong>Priorité 4 :</strong> Création de corridors écologiques entre les aires protégées</li>
                    </ul>
                </div>
            </div>
            
            <div class="recommendations">
                <h3><i class="fas fa-chart-line"></i> Plan d\'Action Prioritaire</h3>
                <div class="rec-grid">
                    <div class="rec-card">
                        <h4>Court Terme (0-6 mois)</h4>
                        <ul>
                            <li>Identifier les 10 villages les plus isolés pour intervention sanitaire</li>
                            <li>Lancer des études de faisabilité pour les extensions ferroviaire</li>
                            <li>Mettre en place un programme de formation en écotourisme</li>
                        </ul>
                    </div>
                    
                    <div class="rec-card">
                        <h4>Moyen Terme (6-18 mois)</h4>
                        <ul>
                            <li>Construire 5 nouveaux centres de santé</li>
                            <li>Démarrer les travaux d\'extension ferroviaire</li>
                            <li>Développer 3 sites pilotes d\'écotourisme</li>
                        </ul>
                    </div>
                    
                    <div class="rec-card">
                        <h4>Long Terme (18+ mois)</h4>
                        <ul>
                            <li>Atteindre 90% de couverture sanitaire acceptable</li>
                            <li>Réduire de 50% les villages non connectés</li>
                            <li>Créer 500 emplois dans l\'écotourisme</li>
                        </ul>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <script>
        function openTab(tabName) {
            var tabContents = document.getElementsByClassName("tab-content");
            for (var i = 0; i < tabContents.length; i++) {
                tabContents[i].classList.remove("active");
            }
            
            var tabButtons = document.getElementsByClassName("nav-tab");
            for (var i = 0; i < tabButtons.length; i++) {
                tabButtons[i].classList.remove("active");
            }
            
            document.getElementById(tabName).classList.add("active");
            event.currentTarget.classList.add("active");
        }
        
        document.addEventListener("DOMContentLoaded", function() {
            const kpiCards = document.querySelectorAll(".kpi-card");
            kpiCards.forEach((card, index) => {
                card.style.animationDelay = (index * 0.1) + "s";
            });
            
            // Amélioration de l\'expérience mobile
            const vizFrames = document.querySelectorAll(".viz-frame");
            vizFrames.forEach(frame => {
                frame.addEventListener("load", function() {
                    this.style.minHeight = "400px";
                });
            });
        });
        
        // Gestion du redimensionnement
        window.addEventListener("resize", function() {
            const activeTab = document.querySelector(".tab-content.active");
            if (activeTab) {
                const vizFrames = activeTab.querySelectorAll(".viz-frame");
                vizFrames.forEach(frame => {
                    frame.style.height = "500px";
                });
            }
        });
    </script>
</body>
</html>')
  
  writeLines(rapport_content, file.path(outputs_folder, "rapport_strategique_interactif.html"))
  cat("✅ Rapport stratégique interactif généré dans:", outputs_folder, "\n")
}

# =============================================================================
# EXÉCUTION PRINCIPALE AMÉLIORÉE
# =============================================================================

cat("🚀 DÉMARRAGE DE L'ANALYSE STRATÉGIQUE AVEC VISUALISATIONS INTERACTIVES...\n")
cat("========================================================================\n")
cat("📁 Dossier data sélectionné:", data_folder, "\n")
cat("📁 Dossier outputs:", outputs_folder, "\n")
cat("========================================================================\n")

# Tenter de télécharger les données de population
telecharger_donnees_population()

# Charger toutes les données
donnees_completes <- charger_donnees_completes()

# Analyser pour les politiques publiques
analyses_politiques <- analyser_pour_politiques_publiques(donnees_completes)

# Créer les visualisations interactives complètes
visualisations_interactives <- creer_visualisations_interactives_completes(donnees_completes, analyses_politiques)

# Générer le tableau de bord indicateurs
if(!is.null(analyses_politiques$accessibilite_sante)) {
  indicateurs <- data.frame(
    Indicateur = c(
      "Villages à moins de 10km d'un hôpital",
      "Villages à moins de 5km d'une école",
      "Villages à moins de 10km d'une aire protégée",
      "Villages à moins de 5km du réseau ferroviaire",
      "Distance médiane aux soins de santé (km)",
      "Distance médiane aux établissements scolaires (km)",
      "Longueur totale du réseau ferroviaire (km)",
      "Nombre total d'aires protégées",
      "Hôpitaux recensés",
      "Établissements scolaires recensés"
    ),
    Valeur = c(
      sum(analyses_politiques$accessibilite_sante$distance_hopital_km <= 10, na.rm = TRUE),
      if(!is.null(analyses_politiques$accessibilite_education)) sum(analyses_politiques$accessibilite_education$distance_ecole_km <= 5, na.rm = TRUE) else NA,
      if(!is.null(analyses_politiques$proximite_aires)) sum(analyses_politiques$proximite_aires$distance_aire_km <= 10, na.rm = TRUE) else NA,
      if(!is.null(analyses_politiques$connectivite_ferroviaire)) sum(analyses_politiques$connectivite_ferroviaire$distance_rail_km <= 5, na.rm = TRUE) else NA,
      round(median(analyses_politiques$accessibilite_sante$distance_hopital_km, na.rm = TRUE), 1),
      if(!is.null(analyses_politiques$accessibilite_education)) round(median(analyses_politiques$accessibilite_education$distance_ecole_km, na.rm = TRUE), 1) else NA,
      if(!is.null(donnees_completes$longueur_railways)) donnees_completes$longueur_railways else 0,
      if(!is.null(donnees_completes$aires_protegees$polygones)) nrow(donnees_completes$aires_protegees$polygones) else 0,
      if(!is.null(donnees_completes$hospitals)) nrow(donnees_completes$hospitals) else 0,
      if(!is.null(donnees_completes$schools)) nrow(donnees_completes$schools) else 0
    ),
    Unité = c("villages", "villages", "villages", "villages", "km", "km", "km", "aires", "établissements", "établissements")
  )
  
  write.csv(indicateurs, file.path(outputs_folder, "tableau_bord_indicateurs.csv"), row.names = FALSE)
  cat("✅ Tableau de bord indicateurs sauvegardé dans:", outputs_folder, "\n")
}

# Générer le rapport HTML interactif complet
generer_rapport_ameliore(donnees_completes, analyses_politiques, visualisations_interactives)

# Résumé final amélioré
cat("\n", strrep("=", 70), "\n")
cat("🎉 ANALYSE STRATÉGIQUE INTERACTIVE TERMINÉE AVEC SUCCÈS!\n")
cat(strrep("=", 70), "\n")
cat("📁 RAPPORTS ET CARTES INTERACTIVES GÉNÉRÉS DANS:", outputs_folder, "\n")
cat("   • 🌐 rapport_strategique_interactif.html (Rapport principal interactif)\n")
cat("   • 🗺️  carte_strategique_interactive.html (Carte maîtresse)\n")
cat("   • 🏥 carte_accessibilite_interactive.html (Accessibilité santé/éducation)\n")
cat("   • 🚆 carte_connectivite_interactive.html (Connectivité ferroviaire)\n")
cat("   • 🌿 carte_ecotourisme_interactive.html (Potentiel écotouristique)\n")
cat("   • 🦁 carte_biodiversite_interactive.html (Aires protégées)\n")
cat("   • 📊 histogramme_distances_interactif.html (Analyse statistique)\n")
cat("   • 📈 tableau_bord_indicateurs.csv (Données brutes)\n")
cat("\n🎯 AMÉLIORATIONS APPORTÉES:\n")
cat("   • 👥 Données de population estimées pour tous les villages\n")
cat("   • 🎯 Symboles de tailles variables selon la population\n")
cat("   • 🏥 Icônes distinctes pour chaque type d'équipement\n")
cat("   • 🎨 Styles différenciés pour éviter la surcharge visuelle\n")
cat("   • 🔄 Certaines couches désactivées par défaut\n")
cat("   • 📋 Nouvel onglet guide de symbologie cartographique\n")
cat("   • 🔎 Fonction de recherche intégrée\n")
cat("\n📍 CHEMIN COMPLET DU RAPPORT:", file.path(outputs_folder, "rapport_strategique_interactif.html"), "\n")
cat(strrep("=", 70), "\n")