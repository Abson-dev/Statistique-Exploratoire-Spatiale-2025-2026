# ==============================================================================
# VERSION ALTERNATIVE AVEC PLOTLY - CONTOURNEMENT LEAFLET
# ==============================================================================
# Si Leaflet ne fonctionne pas, utilisons Plotly pour la visualisation
# ==============================================================================


library(shiny)
library(sf)
library(terra)
library(ggplot2)
library(plotly)
library(viridisLite)
library(dplyr)

# ==============================================================================
# CHARGEMENT
# ==============================================================================

cat("Chargement des données...\n")

# Shapefile
shp_files <- list.files("data/gadm41_BEN_shp", pattern = "\\.shp$", full.names = TRUE, recursive = TRUE)
gadm <- st_read(shp_files[1], quiet = TRUE)
gadm <- st_make_valid(gadm)
if(st_crs(gadm)$epsg != 4326) gadm <- st_transform(gadm, 4326)

# Rasters
tif_files <- list.files("data/clippedlayers", pattern = "\\.(tif|tiff)$", full.names = TRUE)
annees <- as.integer(sapply(tif_files, function(x) {
  m <- regmatches(basename(x), gregexpr("\\d{4}", basename(x)))[[1]]
  if(length(m) == 0) return(NA)
  tail(m, 1)
}))

valides <- !is.na(annees)
tif_files <- tif_files[valides]
annees <- annees[valides]
ordre <- order(annees)
tif_files <- tif_files[ordre]
annees <- annees[ordre]

# Empiler
rasters_list <- lapply(seq_along(tif_files), function(i) {
  r <- rast(tif_files[i])
  if(nlyr(r) > 1) r <- r[[1]]
  r
})
stack_rasters <- rast(rasters_list)

if(!grepl("4326", crs(stack_rasters, proj = TRUE))) {
  stack_rasters <- project(stack_rasters, "EPSG:4326")
}

# Stats
moyennes <- global(stack_rasters, fun = "mean", na.rm = TRUE)[,1]
mins <- global(stack_rasters, fun = "min", na.rm = TRUE)[,1]
maxs <- global(stack_rasters, fun = "max", na.rm = TRUE)[,1]

df_stats <- data.frame(
  annee = annees,
  incidence_moyenne = moyennes,
  incidence_min = mins,
  incidence_max = maxs
)

val_min <- min(values(stack_rasters), na.rm = TRUE)
val_max <- max(values(stack_rasters), na.rm = TRUE)

cat("✓ Données chargées :", length(annees), "années\n")

# ==============================================================================
# UI
# ==============================================================================

ui <- fluidPage(
  titlePanel(
    div(
      style = "text-align: center; padding: 20px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; border-radius: 10px;",
      h2("🦟 Paludisme au Bénin - Visualisation Interactive"),
      p(paste("Données", min(annees), "-", max(annees)), style = "font-size: 16px;")
    )
  ),
  
  br(),
  
  sidebarLayout(
    sidebarPanel(
      width = 3,
      
      div(
        style = "background: #f8f9fa; padding: 15px; border-radius: 10px;",
        h4("🎮 Contrôles", style = "color: #667eea;"),
        
        sliderInput(
          "year", 
          "📅 Sélectionner l'année :", 
          min = min(annees), 
          max = max(annees),
          value = annees[round(length(annees)/2)],
          step = 1, 
          sep = "",
          animate = animationOptions(interval = 1000, loop = TRUE)
        )
      ),
      
      br(),
      
      div(
        style = "background: #f8f9fa; padding: 15px; border-radius: 10px;",
        h5("🎨 Style de carte", style = "color: #667eea;"),
        
        selectInput(
          "palette", 
          "Palette de couleurs :", 
          choices = c(
            "Plasma (Défaut)" = "plasma",
            "Viridis" = "viridis", 
            "Magma" = "magma", 
            "Inferno" = "inferno",
            "Turbo" = "turbo"
          ),
          selected = "plasma"
        ),
        
        checkboxInput("show_borders", "Afficher les frontières", value = TRUE),
        checkboxInput("show_labels", "Afficher les noms de régions", value = TRUE)
      ),
      
      br(),
      
      div(
        style = "background: #e3f2fd; padding: 15px; border-radius: 10px;",
        h5("📊 Statistiques", style = "color: #1976d2;"),
        verbatimTextOutput("stats_text")
      ),
      
      br(),
      
      div(
        style = "background: #f8f9fa; padding: 15px; border-radius: 10px;",
        h5("💾 Téléchargements", style = "color: #667eea;"),
        downloadButton("download_csv", "📊 Données CSV", class = "btn-primary btn-block", 
                       style = "margin-bottom: 10px;"),
        downloadButton("download_png", "🖼️ Carte PNG", class = "btn-success btn-block")
      )
    ),
    
    mainPanel(
      width = 9,
      
      tabsetPanel(
        type = "pills",
        
        tabPanel(
          "🗺️ Carte Interactive",
          br(),
          div(
            style = "border: 3px solid #667eea; border-radius: 10px; padding: 10px; background: white;",
            plotlyOutput("map_plotly", height = 600)
          ),
          br(),
          p(
            icon("info-circle"), 
            strong("Note:"), 
            "Cette carte utilise Plotly. Survolez la carte pour voir les valeurs exactes.",
            style = "text-align: center; color: #666; background: #f8f9fa; padding: 10px; border-radius: 5px;"
          )
        ),
        
        tabPanel(
          "📈 Évolution Temporelle",
          br(),
          plotlyOutput("ts_plot", height = 400),
          hr(),
          plotlyOutput("dist_plot", height = 350)
        ),
        
        tabPanel(
          "ℹ️ Informations",
          br(),
          div(
            style = "padding: 20px;",
            h3("À propos de ce projet", style = "color: #667eea;"),
            p("Cette application visualise l'évolution de l'incidence du paludisme 
              (Plasmodium falciparum) au Bénin sur plusieurs années."),
            
            hr(),
            
            h4("📊 Source des données"),
            p("Malaria Atlas Project - Global Pf Incidence Rate"),
            
            hr(),
            
            h4("🔧 Technologies"),
            tags$ul(
              tags$li("R et Shiny pour l'application web"),
              tags$li("Plotly pour les visualisations interactives"),
              tags$li("Terra et SF pour le traitement spatial"),
              tags$li("ggplot2 pour les graphiques statistiques")
            ),
            
            hr(),
            
            div(
              style = "background: #fff3cd; padding: 15px; border-left: 4px solid #ffc107; border-radius: 5px;",
              h5(icon("lightbulb"), " Astuce"),
              p("Utilisez le slider d'animation pour voir l'évolution dans le temps automatiquement.")
            )
          )
        )
      )
    )
  )
)

# ==============================================================================
# SERVER
# ==============================================================================

server <- function(input, output, session) {
  
  # Index sélectionné
  idx_sel <- reactive({
    which(annees == input$year)[1]
  })
  
  # Carte Plotly (au lieu de Leaflet)
  output$map_plotly <- renderPlotly({
    idx <- idx_sel()
    
    cat("\n→ Génération carte Plotly pour", annees[idx], "\n")
    
    # Extraire raster
    r <- stack_rasters[[idx]]
    
    # Convertir en matrice pour Plotly
    mat <- as.matrix(r, wide = TRUE)
    
    # CORRECTION: Inverser la matrice verticalement pour corriger l'orientation
    mat <- mat[nrow(mat):1, ]
    
    # Coordonnées
    ext <- ext(r)
    x_coords <- seq(ext[1], ext[2], length.out = ncol(mat))
    y_coords <- seq(ext[3], ext[4], length.out = nrow(mat))
    
    # Palette
    pal_option <- input$palette
    if(pal_option == "turbo") pal_option <- "viridis"
    cols <- viridis(100, option = pal_option)
    
    # Créer le plot
    p <- plot_ly(
      x = x_coords,
      y = y_coords,
      z = mat,
      type = "heatmap",
      colors = cols,
      zmin = val_min,
      zmax = val_max,
      hovertemplate = paste(
        "<b>Incidence:</b> %{z:.4f}<br>",
        "<b>Longitude:</b> %{x:.2f}<br>",
        "<b>Latitude:</b> %{y:.2f}",
        "<extra></extra>"
      )
    ) %>%
      layout(
        title = list(
          text = paste("<b>Incidence du Paludisme -", annees[idx], "</b>"),
          x = 0.5,
          xanchor = "center"
        ),
        xaxis = list(title = "Longitude", constrain = "domain"),
        yaxis = list(title = "Latitude", scaleanchor = "x"),
        plot_bgcolor = "#e3f2fd"
      ) %>%
      colorbar(title = "Incidence")
    
    # Ajouter frontières et noms de régions si demandé
    if(input$show_borders) {
      # Extraire coordonnées des polygones
      coords_list <- st_coordinates(gadm)
      
      for(feat in unique(coords_list[, "L2"])) {
        coords_feat <- coords_list[coords_list[, "L2"] == feat, c("X", "Y")]
        p <- p %>%
          add_trace(
            x = coords_feat[, "X"],
            y = coords_feat[, "Y"],
            type = "scatter",
            mode = "lines",
            line = list(color = "black", width = 2),
            showlegend = FALSE,
            hoverinfo = "skip"
          )
      }
      
      # Ajouter les noms de régions
      # Calculer les centroïdes des régions
      if(input$show_labels) {
        centroids <- st_centroid(gadm)
        coords_centroids <- st_coordinates(centroids)
        
        # Récupérer les noms des régions (adapter selon la colonne de ton shapefile)
        # Les colonnes possibles sont souvent: NAME_1, VARNAME_1, NL_NAME_1, etc.
        nom_colonne <- NULL
        for(col in c("NAME_1", "VARNAME_1", "NL_NAME_1", "NAME", "REGION", "Region")) {
          if(col %in% names(gadm)) {
            nom_colonne <- col
            break
          }
        }
        
        if(!is.null(nom_colonne)) {
          noms_regions <- gadm[[nom_colonne]]
          
          # Ajouter les annotations
          annotations_list <- lapply(seq_along(noms_regions), function(i) {
            list(
              x = coords_centroids[i, "X"],
              y = coords_centroids[i, "Y"],
              text = as.character(noms_regions[i]),
              showarrow = FALSE,
              font = list(
                size = 11,
                color = "white",
                family = "Arial Black"
              ),
              bgcolor = "rgba(0, 0, 0, 0.6)",
              borderpad = 4,
              borderwidth = 1,
              bordercolor = "white"
            )
          })
          
          p <- p %>%
            layout(annotations = annotations_list)
          
          cat("✓", length(noms_regions), "noms de régions ajoutés\n")
        } else {
          cat("⚠ Colonne de noms non trouvée. Colonnes disponibles:", paste(names(gadm), collapse=", "), "\n")
        }
      }
    }
    
    cat("✓ Carte générée\n")
    return(p)
  })
  
  # Graphique temporel
  output$ts_plot <- renderPlotly({
    idx <- idx_sel()
    
    p <- plot_ly(df_stats, x = ~annee, y = ~incidence_moyenne, type = "scatter", mode = "lines+markers",
                 line = list(color = "#667eea", width = 3),
                 marker = list(size = 8, color = "#764ba2"),
                 hovertemplate = "<b>Année:</b> %{x}<br><b>Incidence:</b> %{y:.4f}<extra></extra>") %>%
      add_trace(
        x = c(annees[idx], annees[idx]),
        y = c(min(df_stats$incidence_moyenne) * 0.95, max(df_stats$incidence_moyenne) * 1.05),
        type = "scatter",
        mode = "lines",
        line = list(color = "red", dash = "dash", width = 2),
        showlegend = FALSE,
        hoverinfo = "skip"
      ) %>%
      layout(
        title = list(text = "<b>Évolution de l'incidence (2000-2024)</b>", x = 0.5),
        xaxis = list(title = "Année"),
        yaxis = list(title = "Incidence moyenne"),
        hovermode = "x unified"
      )
    
    return(p)
  })
  
  # Distribution
  output$dist_plot <- renderPlotly({
    idx <- idx_sel()
    vals <- values(stack_rasters[[idx]])
    vals <- vals[!is.na(vals)]
    
    plot_ly(x = vals, type = "histogram", nbinsx = 50,
            marker = list(color = "#667eea", line = list(color = "white", width = 1))) %>%
      layout(
        title = list(text = paste("<b>Distribution de l'incidence -", annees[idx], "</b>"), x = 0.5),
        xaxis = list(title = "Incidence"),
        yaxis = list(title = "Fréquence"),
        shapes = list(
          list(
            type = "line",
            x0 = mean(vals), x1 = mean(vals),
            y0 = 0, y1 = 1,
            yref = "paper",
            line = list(color = "red", dash = "dash", width = 2)
          )
        ),
        annotations = list(
          list(
            x = mean(vals),
            y = 1,
            yref = "paper",
            text = paste("Moyenne:", round(mean(vals), 4)),
            showarrow = TRUE,
            arrowhead = 2,
            ax = 40,
            ay = -40
          )
        )
      )
  })
  
  # Stats
  output$stats_text <- renderText({
    idx <- idx_sel()
    s <- df_stats[idx,]
    
    paste0(
      "📅 Année : ", s$annee, "\n",
      "━━━━━━━━━━━━━━\n",
      "📊 Moyenne : ", sprintf("%.5f", s$incidence_moyenne), "\n",
      "📉 Minimum : ", sprintf("%.5f", s$incidence_min), "\n",
      "📈 Maximum : ", sprintf("%.5f", s$incidence_max), "\n"
    )
  })
  
  # Téléchargements
  output$download_csv <- downloadHandler(
    filename = function() {
      paste0("incidence_paludisme_senegal_", Sys.Date(), ".csv")
    },
    content = function(file) {
      write.csv(df_stats, file, row.names = FALSE)
    }
  )
  
  output$download_png <- downloadHandler(
    filename = function() {
      paste0("carte_paludisme_", input$year, ".png")
    },
    content = function(file) {
      idx <- idx_sel()
      r <- stack_rasters[[idx]]
      
      png(file, width = 1600, height = 1200, res = 150)
      par(mar = c(4, 4, 3, 6))
      
      # Tracer le raster
      pal_opt <- input$palette
      if(pal_opt == "turbo") pal_opt <- "viridis"
      
      plot(r, 
           main = paste("Incidence du Paludisme au Bénin -", annees[idx]),
           col = viridis(100, option = pal_opt),
           zlim = c(val_min, val_max),
           axes = TRUE,
           box = TRUE)
      
      # Ajouter les frontières
      if(input$show_borders) {
        plot(st_geometry(gadm), add = TRUE, border = "black", lwd = 2)
      }
      
      # Ajouter les noms si demandé
      if(input$show_labels) {
        nom_colonne <- NULL
        for(col in c("NAME_1", "VARNAME_1", "NL_NAME_1", "NAME", "REGION")) {
          if(col %in% names(gadm)) {
            nom_colonne <- col
            break
          }
        }
        
        if(!is.null(nom_colonne)) {
          centroids <- st_centroid(gadm)
          coords <- st_coordinates(centroids)
          text(coords[, "X"], coords[, "Y"], 
               labels = gadm[[nom_colonne]], 
               col = "white", cex = 0.8, font = 2,
               adj = 0.5)
        }
      }
      
      dev.off()
    }
  )
}

# ==============================================================================
# LANCER
# ==============================================================================

shinyApp(ui, server, options = list(launch.browser = TRUE))