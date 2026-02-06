# ==============================================================================
# DEVOIR SUR TABLE - STATISTIQUES EXPLORATOIRES SPATIALES (SES)
# Auteur : Cheikh Ahmadou Bamba FALL
# Étudiant : ISE Cycle Long (ISE1 CL) — Année 2025-2026
# ==============================================================================

# --- 1. CHARGEMENT DES PACKAGES ---
if(!requireNamespace("sf", quietly = TRUE)) install.packages("sf")
if(!requireNamespace("dplyr", quietly = TRUE)) install.packages("dplyr")
if(!requireNamespace("readr", quietly = TRUE)) install.packages("readr")
if(!requireNamespace("stringr", quietly = TRUE)) install.packages("stringr")
if(!requireNamespace("lubridate", quietly = TRUE)) install.packages("lubridate")

library(sf)
library(dplyr)
library(readr)
library(stringr)
library(lubridate)

# --- 2. DÉFINITION DES CHEMINS ---
base_dir <- "C:/Users/admin/Pictures/DEVOIR/DOSSIER_EVALUATION"

gpkg_path <- file.path(base_dir, "data", "hvstat_africa_boundary.gpkg")
csv_path  <- file.path(base_dir, "data", "hvstat_africa_data.csv")
out_dir   <- file.path(base_dir, "outputs")

# On crée le dossier outputs s'il n'existe pas
if(!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

# On vérifie s'il existe des fichiers
if(!file.exists(gpkg_path)) stop("GeoPackage introuvable : ", gpkg_path)
if(!file.exists(csv_path))  stop("CSV introuvable : ", csv_path)

# ==============================================================================
# PARTIE 1 : HarvestStat Africa
# ==============================================================================
# ==============================================================================
# 1-a-/ DESCRIPTION DE L’UNITÉ STATISTIQUE D’OBSERVATION
# ==============================================================================
# Dans la base HarvestStat Africa, l’unité statistique d’observation correspond à une
# combinaison unique d’une entité géographique infranationale (fnid, admin_1, admin_2),
# d’une culture agricole (product) et d’une saison de culture (season_name). Le fnid
# constitue l’identifiant géographique unique permettant la jointure spatiale avec
# les limites administratives, tandis que admin_1 et admin_2 situent l’observation
# aux niveaux régional et départemental. La variable product précise la culture
# observée et season_name distingue les cycles de production au cours d’une même
# année. Chaque ligne du jeu de données représente ainsi une observation agricole
# localisée, associée à une culture et à une saison données.


# ==============================================================================
# 1-b-/ DIFFÉRENCE CONCEPTUELLE ENTRE area, production ET yield
# area désigne la superficie cultivée (ha), production la quantité totale récoltée
# (tonnes) et yield le rendement agricole (tonnes/ha). La production dépend à la
# fois de l’étendue des terres exploitées et de leur productivité. La relation
# théorique fondamentale est : production = area × yield. L’augmentation de la
# production peut donc être extensive (area), intensive (yield) ou mixte.


# ==============================================================================
# 2-a-1/ ANALYSE DE LA DISTRIBUTION DE qc_flag PAR PAYS
# (Bénin, Burkina Faso, Mali, Togo, Niger)
# ==============================================================================


library(dplyr)
library(readr)

# Chargement des données
hv <- read_csv(
  "C:/Users/admin/Pictures/DEVOIR/DOSSIER_EVALUATION/data/hvstat_africa_data.csv",
  show_col_types = FALSE
)

# Codes ISO des pays présents et concernés
codes_cibles <- c("BJ", "BF", "ML", "NE", "TG")

# Filtrage
hv_filtre <- hv %>%
  filter(country_code %in% codes_cibles)

# Vérification
distinct(hv_filtre, country, country_code)

# ------------------------------------------------------------------
# Distribution de qc_flag PAR PAYS
# ------------------------------------------------------------------

qc_flag_distribution_pays <- hv_filtre %>%
  group_by(country, qc_flag) %>%
  summarise(
    n_obs = n(),
    pct = round(100 * n_obs / sum(n_obs), 2),
    .groups = "drop"
  ) %>%
  arrange(country, qc_flag)

# Affichage
qc_flag_distribution_pays

# Le tableau de distribution de qc_flag par pays montre une forte dominance des
# observations valides (qc_flag = 0) pour l’ensemble des pays étudiés, ce qui
# confirme la bonne qualité globale des données HarvestStat Africa. 
#Le Bénin et le Niger se distinguent par des volumes d’observations très élevés, tandis que
# le Burkina Faso présente une qualité statistique particulièrement élevée avec
# très peu de données problématiques. 
#Le Mali et le Togo disposent de bases plus réduites mais globalement cohérentes. Dans tous les cas, les valeurs aberrantes
# et les données à faible variance restent marginales, ce qui justifie le recours
# prioritaire aux observations qc_flag = 0 dans les analyses empiriques.


# ==============================================================================
# 2-a-2-/ ANALYSE DE LA DISTRIBUTION DE qc_flag PAR CULTURE
# ==============================================================================

qc_flag_distribution_culture <- hv %>%
  group_by(product, qc_flag) %>%
  summarise(
    n_obs = n(),
    pct = round(100 * n_obs / sum(n_obs), 2),
    .groups = "drop"
  ) %>%
  arrange(product, qc_flag)

# Affichage
qc_flag_distribution_culture

# L’analyse de qc_flag par culture montre que la majorité des cultures présente
# une forte proportion de données valides, en particulier les
# cultures vivrières majeures. Certaines cultures secondaires affichent toutefois
# des valeurs aberrantes ou une faible variance, qui
# restent marginales. Ces résultats justifient le filtrage sur qc_flag = 0 et une
# interprétation prudente pour les cultures présentant des qc_flags non nuls

# ==============================================================================
#2-b-/  STRATÉGIE DE TRAITEMENT DES qc_flag
# qc_flag = 1 : valeurs aberrantes  -> correction robuste (winsorisation / NA + imputation)
# qc_flag = 2 : faible variance     -> garder pour agrégats, exclure des analyses nécessitant une variation
# ==============================================================================






# ==============================================================================
#DES TABLEAUX D’ANALYSE
# ==============================================================================

if(!requireNamespace("writexl", quietly = TRUE)) install.packages("writexl")
library(writexl)

# ------------------------------------------------------------------
# Tableau 1 : Pays présents dans la base 
# ------------------------------
table_pays_disponibles <- hv %>%
  distinct(country, country_code) %>%
  arrange(country)

# ------------------------------------------------------------------
# Tableau 2 : Pays effectivement analysés
# ------------------------------------------------------------------
table_pays_cibles <- hv_filtre %>%
  distinct(country, country_code) %>%
  arrange(country)

# ------------------------------------------------------------------
# Tableau 3 : Distribution de qc_flag par pays
# ------------------------------------------------------------------
table_qc_flag_par_pays <- qc_flag_distribution_pays

# ------------------------------------------------------------------
# Tableau 4 : Distribution de qc_flag par culture
# ------------------------------------------------------------------
table_qc_flag_par_culture <- qc_flag_distribution_culture

# ------------------------------------------------------------------
# Enregistrement des tableaux dans outputs/
# ------------------------------------------------------------------
write_xlsx(
  list(
    pays_disponibles               = table_pays_disponibles,
    pays_cibles_analyse            = table_pays_cibles,
    qc_flag_distribution_par_pays  = table_qc_flag_par_pays,
    qc_flag_distribution_par_culture = table_qc_flag_par_culture
  ),
  path = file.path(out_dir, "tableaux_analyse_qc_flag.xlsx")
)

# ==============================================================================
# 3-/ STATISTIQUES DESCRIPTIVES DE yield PAR PAYS ET PAR CULTURE
# ==============================================================================

# hv <- read_csv(csv_path, show_col_types = FALSE)

# ------------------------------------------------------------------
# Calcul des statistiques descriptives
# ------------------------------------------------------------------
stats_yield_pays_culture <- hv %>%
  filter(!is.na(yield)) %>%                 # exclure les NA
  group_by(country, product) %>%
  summarise(
    n_obs     = n(),
    mean_yld  = mean(yield, na.rm = TRUE),
    median_yld = median(yield, na.rm = TRUE),
    q25_yld   = quantile(yield, 0.25, na.rm = TRUE),
    q75_yld   = quantile(yield, 0.75, na.rm = TRUE),
    sd_yld    = sd(yield, na.rm = TRUE),
    iqr_yld   = IQR(yield, na.rm = TRUE),
    min_yld   = min(yield, na.rm = TRUE),
    max_yld   = max(yield, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(country, product)

# ------------------------------------------------------------------
# Enregistrement en CSV dans outputs/
# ------------------------------------------------------------------

write_csv(
  stats_yield_pays_culture,
  file.path(out_dir, "statistiques_descriptives_yield_par_pays_et_culture.csv")
)

# Affichage
head(stats_yield_pays_culture

