################################################################################
#     Examen final — STATISTIQUE EXPLORATOIRE SPATIALE (SES)                   
#     Partie 1 : Avec R                   
#     Données : HarvestStat Africa (hvstat)                                    
################################################################################

# ==============================================================================
# CHARGEMENT
# ==============================================================================


# --- 1es. Packages ---
pkgs <- c(
  "dplyr", "tidyr", "stringr", "readr", "forcats",    # manipulation
  "sf",                                               # vecteur spatial
  "terra",                                            # raster
  "exactextractr",                                    # stats zonales
  "spdep",                                            # autocorrélation spatiale
  "ggplot2", "scales", "patchwork",                   # graphiques
  "tmap",                                             # carto thématique
  "leaflet", "htmlwidgets",                           # carto interactive
  "classInt", "RColorBrewer",                         # discrétisation & palettes
  "cartography",                                      # symboles proportionnels
  "viridis"                                           # palettes colorblind-safe
)
## missing <- pkgs[!(pkgs %in% installed.packages()[, "Package"])]
## if (length(missing)) install.packages(missing, repos = "https://cran.r-project.org")
##invisible(lapply(pkgs, library, character.only = TRUE))

# --- Chemins ---
data_dir <- "data/"
out_dir  <- "outputs/"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# --- Chargement ---
hvstat_geo <- st_read(paste0(data_dir, "harveststat.gpkg"),
                      quiet = TRUE)
hvstat_csv <- read.csv(paste0(data_dir, "harveststat.csv"),
                       stringsAsFactors = FALSE)

cat("\n─── Données CSV ───\n")
cat("  Observations  :", nrow(hvstat_csv), "\n")
cat("  Variables     :", ncol(hvstat_csv), "\n")
cat("  Pays          :", n_distinct(hvstat_csv$country), "\n")
cat("  Cultures      :", n_distinct(hvstat_csv$product), "\n")
cat("  Période       :", min(hvstat_csv$harvest_year), "-",
    max(hvstat_csv$harvest_year), "\n")





# ==============================================================================
# 2. Analyse de la variable qc_flag
# ==============================================================================

cat("\n─── Qualité des données (qc_flag) ───\n")
cat("  0 = ok         :", sum(hvstat_csv$qc_flag == 0), "\n")
cat("  1 = aberrant   :", sum(hvstat_csv$qc_flag == 1), "\n")
cat("  2 = var. faible:", sum(hvstat_csv$qc_flag == 2), "\n")




# Calculer la distribution de qc_flag par pays
distribution_pays <- hvstat_csv %>%
  group_by(country, qc_flag) %>%
  summarise(count = n(), .groups = "drop")

# Visualisation avec ggplot2
ggplot(distribution_pays, aes(x = country, y = count, fill = factor(qc_flag))) +
  geom_bar(stat = "identity", position = "dodge") +
  labs(title = "Distribution de la variable cq par pays",
       x = "Pays",
       y = "Nombre d'observations",
       fill = "Modalité de cq") +
  theme_minimal()


# Calculer la distribution de qc_flag par pays
distribution_product <- hvstat_csv %>%
  group_by(product, qc_flag) %>%
  summarise(count = n(), .groups = "drop")
View(distribution_product)

# Visualisation avec ggplot2
ggplot(distribution_product, aes(x = product, y = count, fill = factor(qc_flag))) +
  geom_bar(stat = "identity", position = "dodge") +
  labs(title = "Distribution de la variable cq par pays",
       x = "Pays",
       y = "Nombre d'observations",
       fill = "Modalité de cq") +
  theme_minimal()








# Filtrer : ne garder que les observations de bonne qualité
hvstat_clean <- hvstat_csv %>%
  filter(qc_flag == 0)

cat("  Après filtrage qc_flag == 0 :", nrow(hvstat_clean), "obs\n")



# ==============================================================================
# 3. STATISTIQUES DESCRIPTIVES
# ==============================================================================

# --- Analyse au niveau pays ---
couverture_pays <- hvstat_clean %>%
  group_by(country) %>%
  summarise(
    n_obs        = n(),
    n_cultures   = n_distinct(product),
    n_admin1     = n_distinct(admin_1),
    annee_min    = min(harvest_year),
    annee_max    = max(harvest_year),
    yield_median = median(yield, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(n_obs))

cat("\n─── Top 10 pays par nombre d'observations ───\n")
print(head(couverture_pays, 10))

# --- Analyse des cultures ---
cereales <- c("Maize", "Rice", "Sorghum", "Millet", "Wheat",
              "Barley", "Fonio", "Teff")

stats_cereales <- hvstat_clean %>%
  filter(product %in% cereales) %>%
  group_by(product) %>%
  summarise(
    n_obs      = n(),
    n_pays     = n_distinct(country),
    yield_moy  = mean(yield, na.rm = TRUE),
    yield_med  = median(yield, na.rm = TRUE),
    yield_sd   = sd(yield, na.rm = TRUE),
    area_total = sum(area, na.rm = TRUE),
    prod_total = sum(production, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(n_obs))

cat("\n─── Statistiques des céréales principales ───\n")
print(stats_cereales)

# --- Graphique : distribution des rendements par céréale ---
p_box <- hvstat_clean %>%
  filter(product %in% cereales, !is.na(yield), yield < 15) %>%
  ggplot(aes(x = reorder(product, yield, FUN = median),
             y = yield, fill = product)) +
  geom_boxplot(outlier.size = 0.5, alpha = 0.8) +
  coord_flip() +
  scale_fill_viridis_d(guide = "none") +
  labs(title = "Distribution des rendements par céréale",
       subtitle = "Afrique subsaharienne — HarvestStat",
       x = NULL, y = "Rendement (t/ha)") +
  theme_minimal(base_size = 12)

ggsave(paste0(out_dir, "01_boxplot_rendements_cereales.png"),
       p_box, width = 10, height = 6, dpi = 300)


# --- Graphique : distribution des rendements selon systeme de production ---
p_box <- hvstat_clean %>%
  filter(systeme %in% uniques(hvstat_clean$crop_production_system), !is.na(yield), yield < 15) %>%
  ggplot(aes(x = reorder(systeme, yield, FUN = median),
             y = yield) +
  geom_boxplot(outlier.size = 0.5, alpha = 0.8) +
  coord_flip() +
  scale_fill_viridis_d(guide = "none") +
  labs(title = "Distribution des rendements selon le systeme",
       subtitle = "Afrique subsaharienne — HarvestStat",
       x = NULL, y = "Rendement (t/ha)") +
  theme_minimal(base_size = 12)

ggsave(paste0(out_dir, "01_boxplot_rendements_systeme.png"),
       p_box, width = 10, height = 6, dpi = 300))

## le reste de la partie 1 est fait sur les scripts python ##






