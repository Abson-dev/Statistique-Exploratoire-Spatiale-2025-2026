# téchargeons quelques library
library(shiny)
library(sf)
library(ggplot2)
library(dplyr)
library(stringr)
library(spdep)

# chargement des données et visualisation, pour avoir une idée

data1 <- read.csv("C:/Examen/data/hvstat_africa_data_v1.0.csv")
data2 <- "C:/Examen/data/hvstat_africa_boundary_v1.0.gpkg"
donnees <- st_read(data2, quiet = FALSE)
print(donnees)
st_layers(data2)


# 1 Décrire l'unité statistique d'observation en précisant le rôle des variables 

L unité statistique est la production agricole.

fnid= identifiant géographique unique : clé pour relier chaque observation à une
zone géographique unique.
admin1 = unité administravtive de premier niveau : situer l observation
dans un cadre territrial large (ex = région)
admin2 = unité administrative de second niveau : elle permet d affiner l
etude dans un cadre local (ex : département), une façon de desagreger notre étude.
product = type de culture : c est la variable qui définit l objet de la mesure.
season_name = saison de culture : Elle distingue les cycles de productions,
et permet de comparer les performances selon les conditions climatiques.

# 2 Analyse de la distribution de qc_flag par pays et par culture.
# Proposer une strategie statistique pour traiter les observations avec qc_flag=1
# (valeur aberrantes) et qc_flag = 2 (faible variance).

qc_stats <- data1 %>%
  group_by(country, product, qc_flag) %>%
  summarise(n_obs = n(), .groups = "drop") %>%
  mutate(freq = n_obs / sum(n_obs))

# Visualisation avec un tableau croisé

table_qc <- data1 %>%
  count(country, product, qc_flag) %>%
  tidyr::spread(qc_flag, n, fill = 0)


# ici on essaie de filtrer en fonction de qc_flag
outliers <- data1 %>% filter(qc_flag == 1)
lowvar   <- data1 %>% filter(qc_flag == 2)

# Enregistrons les fichiers
write.csv(outliers, "outliers_removed.csv")
write.csv(lowvar, "low_variance_removed.csv")


# Produire des statistiques descriptives (moyenne, médiane, quantiles, dispersion)
#de yield par country , product


stats_des <- data1 %>%
  group_by(country, product) %>%
  summarise(
    mean_yield   = mean(yield, na.rm = TRUE),
    median_yield = median(yield, na.rm = TRUE),
    q25_yield    = quantile(yield, 0.25, na.rm = TRUE),
    q75_yield    = quantile(yield, 0.75, na.rm = TRUE),
    min_yield    = min(yield, na.rm = TRUE),
    max_yield    = max(yield, na.rm = TRUE),
    sd_yield     = sd(yield, na.rm = TRUE),
    var_yield    = var(yield, na.rm = TRUE),
    n_obs        = n()
  )

# Comparer les distrubustions de rendements entre les systemes de productions.

yield_stats <- data1 %>%
  group_by(crop_production_system) %>%
  summarise(
    mean_yield   = mean(yield, na.rm = TRUE),
    median_yield = median(yield, na.rm = TRUE),
    q25_yield    = quantile(yield, 0.25, na.rm = TRUE),
    q75_yield    = quantile(yield, 0.75, na.rm = TRUE),
    sd_yield     = sd(yield, na.rm = TRUE),
    n_obs        = n()
  )

# Bloxplot

p <- ggplot(data1, aes(x = crop_production_system, y = yield, fill = crop_production_system)) +
  geom_boxplot() +
  labs(title = "Comparaison des distributions de rendement par système de production",
       x = "Système de production",
       y = "Rendement")

ggsave("Exam/output/boxplot_yield.png", plot = p, width = 7, height = 5)

# Densité
q <- ggplot(data1, aes(x = yield, color = crop_production_system, fill = crop_production_system)) +
  geom_density(alpha = 0.3) +
  labs(title = "Distribution des rendements par système de production",
       x = "Rendement",
       y = "Densité")
ggsave("Exam/output/Densité.png", plot = q, width = 7, height = 5)

# On suppose que vous avez calculé le rendement moyen par admin_1 sur
 2015-20200 pour le "Mais" au Sénégal.*
   1- Indiquez comment construire la matrice de contiguité spatiale à
     partir de la variable fnid ou admin_1 (ex. queen, rook, distance seuil).
   2- Calculez l indice de Moran global sur ces rendements moyens (formule + interpretation du signe).


# Charger les polygones pour le Senefal

senegal <- donnees[donnees$ADMIN0 == "Senegal", ]

# Queen contiguity
nb_queen <- poly2nb(senegal, queen = TRUE)
W_queen  <- nb2listw(nb_queen, style = "W")

# Rook contiguity
nb_rook <- poly2nb(senegal, queen = FALSE)
W_rook  <- nb2listw(nb_rook, style = "W")

# Distance threshold (ex. 100 km)
coords <- st_coordinates(st_centroid(senegal))
nb_dist <- dnearneigh(coords, 0, 100000)   # 100 km = 100000 m
W_dist  <- nb2listw(nb_dist, style = "W")


# Calcul de l'indice de Moran

# mean_yield est un vecteur des rendements moyens par admin_1

library(dplyr)

# Exemple : fusion par la variable fnid
merged_data <- donnees %>%
  left_join(data1, by = c("FNID" = "fnid"))

# rendemant moyen
mean_yield <- merged_data %>%
  filter(country == "Senegal", product == "Maize", harvest_year >= 2015, harvest_year <= 2020) %>%
  group_by(ADMIN1) %>%
  summarise(mean_yield = mean(yield, na.rm = TRUE))

# calcul final de l'indice de Morgan

moran_global <- moran.test(mean_yield$mean_yield, W_queen)

print(moran_global)
