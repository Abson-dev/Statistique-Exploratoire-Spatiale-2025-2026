# ============================================================================
# Devoir de statistique exploratoire spatitiale 
# ============================================================================

# ============================================================================
# PARTIE 1 : CHARGEMENT ET PRÉPARATION DES DONNÉES
# ============================================================================

# Installation et chargement des packages nécessaires
# ----------------------------------------------------
packages_necessaires <- c(
  "sf",           # Pour les données spatiales (geopackage)
  "tidyverse",    # Pour la manipulation de données
  "ggplot2",      # Pour les visualisations
  "viridis",      # Pour les palettes de couleurs
  "tmap",         # Pour les cartes thématiques
  "spdep",        # Pour l'autocorrélation spatiale
  "spatstat",     # Pour l'analyse de patterns spatiaux
  "gstat",        # Pour le krigeage et variogrammes
  "raster",       # Pour les données raster
  "leaflet",      # Pour les cartes interactives
  "corrplot",     # Pour les matrices de corrélation
  "moments",      # Pour skewness et kurtosis
  "car",          # Pour les tests statistiques avancés
  "lmtest",       # Pour les tests sur modèles linéaires
  "MASS"          # Pour les fonctions statistiques
)


library(readxl)
library(writexl)
library(dplyr)
library(tidyr)
library(ggplot2)
library(forcats)

# Installer les packages manquants
nouveaux_packages <- packages_necessaires[!(packages_necessaires %in% installed.packages()[,"Package"])]
if(length(nouveaux_packages)) install.packages(nouveaux_packages)

# Charger tous les packages
lapply(packages_necessaires, library, character.only = TRUE)

# ----------------------------------------------------
# CHARGEMENT DES DONNÉES GEOPACKAGE
# ----------------------------------------------------

# Remplacer par le chemin vers votre fichier
chemin_fichier <- "data/hvstat_africa_boundary_v1.0.gpkg"

# Lire les données spatiales
donnees_spatiales <- st_read(chemin_fichier)

df_excel <- read.csv("data/hvstat_africa_data_v1.0.csv")

# Aperçu de la structure des données
str(donnees_spatiales)
head(donnees_spatiales)
summary(donnees_spatiales)

# Vérifier le système de coordonnées
st_crs(donnees_spatiales)


names(df_excel)
df_excel <- df_excel %>%
  mutate(
    planting_year = as.integer(planting_year),
    harvest_year  = as.integer(harvest_year),
    planting_month = as.integer(planting_month),
    harvest_month  = as.integer(harvest_month)
  )

df_final <- donnees_spatiales %>%
  left_join(df_excel, by = c("FNID" = "fnid"))


names(df_final)




df <- df_final
names(df)


if(!dir.exists("outputs")) dir.create("outputs")


countries_of_interest <- c("Burkina Faso", "Benin", "Mali", "Togo", "Niger")
df <- df %>% filter(country %in% countries_of_interest)
# ============================================================================
# Section 1  
# ============================================================================

# ----------------------------------------------------------------------------
# 1 a Unité statistique d'observation
# ----------------------------------------------------------------------------
# Chaque ligne correspond à une parcelle  spécifique qui est donc l'unité statistique. Chaque unité est 
# est localisée dans un andorissment spécifique , dans une région spécifique et dans un pays spécifique

# Les variables principales :
# - FNID : identifiant unique de l'observation c'est dire parcelle, il permet donc d'identifier la parcelle 
# - ADMIN1, ADMIN2 : niveaux administratifs, ils permettent de loclaliser la parcelle , le niveau 1 correspond à la région et 
# le niveau 2 correspond au département 
# - product : culture cultivée
# - season_name : saison de plantation, utile pour comparer rendements en saison des pluies ou saison sèche

# ----------------------------------------------------------------------------
# 1 b Différence entre production (total) et yield (rendement)
# ----------------------------------------------------------------------------
# La variable area fait réference à la surface  récoltée
# La production fait réference à la  quantité totale récoltée
# La variable yield aborde  production par unité de surface (tonnes/ha)

# ----------------------------------------------------------------------------
# 2 a Analyse de la distribution de QC_flag par pays et par culture
# ----------------------------------------------------------------------------
qc_summary <- df %>%
  st_drop_geometry() %>%  # CORRECTION: Retirer la géométrie avant group_by
  group_by(country, product) %>%
  count(qc_flag) %>%
  pivot_wider(names_from = qc_flag, values_from = n, values_fill = 0) %>%
  ungroup()

write_xlsx(qc_summary, "outputs/qc_flag_summary.xlsx")

# Graphique QC_flag
ggplot(st_drop_geometry(df), aes(x = fct_infreq(factor(qc_flag)), fill = country)) +
  geom_bar(position = "dodge") +
  facet_wrap(~product) +
  labs(title = "Distribution QC_flag par pays et culture",
       x = "QC_flag", y = "Nombre d'observations") +
  theme_minimal()
ggsave("outputs/figures/qc_flag_distribution.png")

# ----------------------------------------------------------------------------
# 2 b La méthode proposée est la méthode de filtrage des observations avec qc_flag =1 
# ----------------------------------------------------------------------------
# Maintenant  pour qc_flag = 2 mieux vaux fusionner avec le fichier où c'est qc_flag = 0 car il ya peu de doutes 
# sur la variances 
df_clean <- df %>% filter(qc_flag != 1)
cat("Nombre d'observations après filtrage QC:", nrow(df_clean), "\n")

# ----------------------------------------------------------------------------
# 2 Proposons des statistiques descriptives 
# ----------------------------------------------------------------------------
stats_yield <- df_clean %>%
  st_drop_geometry() %>%  # CORRECTION: Retirer la géométrie
  group_by(country, product) %>%
  summarise(
    mean_yield = mean(yield, na.rm = TRUE),
    median_yield = median(yield, na.rm = TRUE),
    sd_yield = sd(yield, na.rm = TRUE),
    min_yield = min(yield, na.rm = TRUE),
    max_yield = max(yield, na.rm = TRUE),
    Q1 = quantile(yield, 0.25, na.rm = TRUE),
    Q3 = quantile(yield, 0.75, na.rm = TRUE),
    .groups = "drop"
  )

print(head(stats_yield))
write_xlsx(stats_yield, "outputs/yield_stats_by_country_product.xlsx")

# Graphique boxplot du yield par pays et culture
ggplot(st_drop_geometry(df_clean), aes(x = product, y = yield, fill = country)) +
  geom_boxplot() +
  facet_wrap(~country) +
  labs(title = "Boxplot de yield par culture et pays",
       x = "Culture", y = "Yield (tonnes/ha)") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
ggsave("outputs/figures/yield_boxplot_by_country_product.png")

# Histogramme global de yield
ggplot(st_drop_geometry(df_clean), aes(x = yield, fill = country)) +
  geom_histogram(alpha = 0.6, bins = 30, position = "identity") +
  labs(title = "Histogramme global de yield par pays",
       x = "Yield (tonnes/ha)", y = "Nombre d'observations") +
  theme_minimal()
ggsave("outputs/figures/yield_histogram_by_country.png")