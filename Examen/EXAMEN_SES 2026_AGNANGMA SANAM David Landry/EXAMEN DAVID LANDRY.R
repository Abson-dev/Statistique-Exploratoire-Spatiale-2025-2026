# EXAMEN DE SES

#chargement des données
africa_boundary <- st_read("data/hvstat_africa_boundary_v1.0.gpkg")
africa_data <- read.csv("data/hvstat_africa_data_v1.0.csv")


# Chargement des bibliothèques nécessaires
library(dplyr)      # Pour la manipulation des données
library(ggplot2)    # Pour les visualisations
library(tidyr)      # Pour la transformation des données
library(forcats)    # Pour la manipulation des facteurs
library(kableExtra) # Pour la mise en forme des tableaux
library(spdep)






# structure des données
str(africa_data)

# L'unité statistique d'observation dans ce jeu de données est une combinaison unique de région administrative, de culture, et de saison agricole pour une année spécifique.

# Rôle des variables :

# fnid : Identifiant géographique unique (FEWS NET)
# Cette variable sert de clé primaire pour identifier de manière unique
# chaque unité administrative infra-nationale.

# admin_1 : Unité administrative de premier niveau (régionsou provinces)
# Cette variable représente la subdivision administrative principale d'un pays.

# admin_2 : Unité administrative de deuxième niveau (départements/districts)
# Cette variable représente une subdivision plus fine que admin_1.

# product : Culture agricole
# Cette variable indique le type de culture observée (ex: maïs, sorgho, millet).

# season_name : Saison de culture
# Cette variable indique la période de l'année ou le cycle agricole.


# Question 1.b

# Relation théorique entre les variables :
# yield = production / area

# Différence conceptuelle :

# area : Superficie cultivée (en ha)
print("La variable 'area' représente la surface totale cultivée pour une culture donnée, exprimée en hectares (ha). C'est une mesure de l'étendue spatiale consacrée à la production agricole.")

# production : Production agricole (en tonnes)
print("La variable 'production' représente la quantité totale récoltée pour une culture donnée, exprimée en tonnes métriques (t). C'est le résultat physique de l'activité agricole.")

# yield : Rendement (en tonnes par hectare)
print("La variable 'yield' représente l'efficacité productive, c'est-à-dire la production par unité de surface. Elle est exprimée en tonnes métriques par hectare (t/ha).")


#Question 2

# Analysons la distribution de qc_flag par pays et culture


# Pays d'interet pour notre étude
pays_interet <- c("Benin", "Burkina Faso", "Mali", "Togo", "Niger")

# Filtrage des données
data_filtree <- africa_data %>%
  filter(country %in% pays_interet)


#distribution par pays
print("Distribution des observations par pays :")
table(data_filtree$country)

# Benin : 26770, Burkina Faso : 15650, Mali : 2521, Niger : 17503 et Togo : 2270

# Création d'un tableau de contingence pour qc_flag par pays
table_qc_pays <- table(data_filtree$country, data_filtree$qc_flag)

print("Distribution de qc_flag par pays :")
print(table_qc_pays)

#                  0     1     2
#Benin        26434   137   199
#Burkina Faso 15596    46     8
#Mali          2500    21     0
#Niger        17428    54    21
#Togo          2261     5     4


# Calcul des proportions par pays
prop_qc_pays <- prop.table(table_qc_pays, margin = 1) * 100
print("Proportions de qc_flag par pays (en %) :")
print(round(prop_qc_pays, 2))

# Visualisation 

data_qc_pays <- data_filtree %>%
  group_by(country, qc_flag) %>%
  summarise(n = n(), .groups = "drop") %>%
  group_by(country) %>%
  mutate(prop = n / sum(n) * 100)

# graphique en barres empilées
graph_qc_pays <- ggplot(data_qc_pays, aes(x = country, y = prop, fill = as.factor(qc_flag))) +
  geom_bar(stat = "identity", position = "stack") +
  geom_text(aes(label = paste0(round(prop, 1), "%")), 
            position = position_stack(vjust = 0.5), 
            size = 3, color = "white") +
  labs(title = "Distribution des indicateurs de qualité (qc_flag) par pays",
       subtitle = "Proportions en pourcentage",
       x = "Pays",
       y = "Proportion (%)",
       fill = "qc_flag") +
  scale_fill_manual(values = c("0" = "#2E8B57", "1" = "#FF8C00", "2" = "#DC143C"),
                    labels = c("0 = OK", "1 = Valeur aberrante", "2 = Faible variance")) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        plot.title = element_text(hjust = 0.5),
        plot.subtitle = element_text(hjust = 0.5))

print(graph_qc_pays)

# Sauvegarde du graphique dans le dossier outputs
ggsave("outputs/qc_flag_par_pays.png", 
       plot = graph_qc_pays, 
       width = 10, 
       height = 6, 
       dpi = 300)

#Analyse du qc_flag par culture (pour des soucis de visualisation, on présentera sur le graphiques que les 10 premières cultures)

# Identification des cultures principales dans notre sous-ensemble
cultures_principales <- data_filtree %>%
  count(product, sort = TRUE) %>%
  head(10) %>%
  pull(product)

print("cultures principales dans les pays sélectionnés :")
print(cultures_principales)

# Filtrage pour ne garder que les cultures principales
data_cultures <- data_filtree %>%
  filter(product %in% cultures_principales)

# Table de contingence pour qc_flag par culture
table_qc_culture <- table(data_cultures$product, data_cultures$qc_flag)
print("Distribution de qc_flag par culture (top 10) :")
print(table_qc_culture)

# Calcul des proportions par culture
prop_qc_culture <- prop.table(table_qc_culture, margin = 1) * 100
print("Proportions de qc_flag par culture (en %) :")
print(round(prop_qc_culture, 2))

#Visualisation de qc_flag par cultures

# Préparation des données pour la visualisation
data_qc_culture <- data_cultures %>%
  group_by(product, qc_flag) %>%
  summarise(n = n(), .groups = "drop") %>%
  group_by(product) %>%
  mutate(prop = n / sum(n) * 100) %>%
  # Réorganisation des cultures par nombre total d'observations
  mutate(product = fct_reorder(product, n, .fun = sum, .desc = TRUE))

# Création du graphique en barres empilées
graph_qc_culture <- ggplot(data_qc_culture, aes(x = product, y = prop, fill = as.factor(qc_flag))) +
  geom_bar(stat = "identity", position = "stack") +
  geom_text(aes(label = paste0(round(prop, 1), "%")), 
            position = position_stack(vjust = 0.5), 
            size = 2.5, color = "white") +
  labs(title = "Distribution de qc_flag par culture",
       subtitle = "10 premières cultures",
       x = "Culture",
       y = "Proportion (%)",
       fill = "qc_flag") +
  scale_fill_manual(values = c("0" = "#2E8B57", "1" = "#FF8C00", "2" = "#DC143C"),
                    labels = c("0 = OK", "1 = Valeur aberrante", "2 = Faible variance")) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        plot.title = element_text(hjust = 0.5),
        plot.subtitle = element_text(hjust = 0.5))

# Affichage du graphique
print(graph_qc_culture)

# Sauvegarde du graphique
ggsave("outputs/qc_flag_par_culture.png", 
       plot = graph_qc_culture, 
       width = 12, 
       height = 6, 
       dpi = 300)


# Question 2.b
#Nous proposons la méthode qui suit :



# ÉTAPE 1 : SÉPARATION DES DONNÉES PAR TYPE DE PROBLÈME

# Données normales (qc_flag = 0)
data_normales <- data_filtree %>%
  filter(qc_flag == 0)

# Données aberrantes (qc_flag = 1)
data_aberrantes <- data_filtree %>%
  filter(qc_flag == 1)

# Données avec faible variance (qc_flag = 2)
data_faible_var <- data_filtree %>%
  filter(qc_flag == 2)

print(paste("Données normales :", nrow(data_normales)))
# 64219
print(paste("Données aberrantes :", nrow(data_aberrantes)))
#263
print(paste("Données à faible variance :", nrow(data_faible_var)))
#232

# ÉTAPE 2 : STRATÉGIE POUR QC_FLAG = 1 (VALEURS ABERRANTES)

# Pour les valeurs aberrantes on fait une imputation par la médiane de la même culture dans la même région admin_1

imputation_aberrantes <- function(data_aberrantes, data_normales) {
  
  # Calcul des médianes par admin_1 et culture pour chaque variable
  medians <- data_normales %>%
    group_by(admin_1, product) %>%
    summarise(
      median_yield = median(yield, na.rm = TRUE),
      median_area = median(area, na.rm = TRUE),
      median_production = median(production, na.rm = TRUE),
      .groups = "drop"
    )
  
  # Jointure ici pour imputer les valeurs aberrantes
  data_imputee <- data_aberrantes %>%
    left_join(medians, by = c("admin_1", "product")) %>%
    mutate(
      yield = ifelse(is.na(median_yield), yield, median_yield),
      area = ifelse(is.na(median_area), area, median_area),
      production = ifelse(is.na(median_production), production, median_production)
    ) %>%
    select(-starts_with("median_"))
  
  # Marquage des données comme "corrigées"
  data_imputee$qc_flag <- 3  # il s'agit du code pour "valeur corrigée"
  
  return(data_imputee)
}

# Application de l'imputation
if(nrow(data_aberrantes) > 0) {
  data_aberrantes_corrigees <- imputation_aberrantes(data_aberrantes, data_normales)
} else {
  data_aberrantes_corrigees <- data_aberrantes
}

print(paste("Valeurs aberrantes corrigées :", nrow(data_aberrantes_corrigees)))

# ÉTAPE 3 : STRATÉGIE POUR QC_FLAG = 2 (FAIBLE VARIANCE)


# Pour les données avec faible variance, on vérifie et fusionne avec les données de l'année précédente/suivante pour améliorer la fiabilité

traitement_faible_variance <- function(data_faible_var, data_normales) {
  
  # Pour chaque observation à faible variance, vérifier si elle est cohérente
  # avec la tendance temporelle de la même région et culture
  
  data_faible_var_traitee <- data_faible_var %>%
    group_by(fnid, product) %>%
    mutate(
      # Vérifier la cohérence avec la médiane des années adjacentes
      yield_median_adjacent = median(
        data_normales$yield[
          data_normales$fnid == first(fnid) & 
            data_normales$product == first(product) &
            abs(data_normales$harvest_year - harvest_year) <= 2
        ],
        na.rm = TRUE
      ),
      # Si différence trop grande (> 50%), remplacer par la médiane
      yield = ifelse(
        !is.na(yield_median_adjacent) & 
          abs(yield - yield_median_adjacent)/yield_median_adjacent > 0.5,
        yield_median_adjacent,
        yield
      )
    ) %>%
    select(-yield_median_adjacent)
  
  # Marquer comme "vérifiée"
  data_faible_var_traitee$qc_flag <- 4  # Nouveau code pour "vérifiée"
  
  return(data_faible_var_traitee)
}

# Application du traitement
if(nrow(data_faible_var) > 0) {
  data_faible_var_traitee <- traitement_faible_variance(data_faible_var, data_normales)
} else {
  data_faible_var_traitee <- data_faible_var
}

print(paste("Données faible variance traitées :", nrow(data_faible_var_traitee)))




# Question 3 : produire des statistiques descriptives (moyenne, médiane, quantiles, dispersion) de yield par pays (country), culture (product)

# On reprend ici notre base filtrée
data_analyse <- data_filtree


# Filtrage pour ne garder que les observations avec yield non NA
data_yield <- data_analyse %>%
  filter(!is.na(yield))

print(paste("Nombre d'observations avec yield disponible :", nrow(data_yield)))
# 63909


# Calcul des statistiques descriptives par pays
stats_pays <- data_yield %>%
  group_by(country) %>%
  summarise(
    Observations = n(),
    Moyenne = round(mean(yield, na.rm = TRUE), 2),
    Médiane = round(median(yield, na.rm = TRUE), 2),
    Q1 = round(quantile(yield, 0.25, na.rm = TRUE), 2),
    Q3 = round(quantile(yield, 0.75, na.rm = TRUE), 2),
    Min = round(min(yield, na.rm = TRUE), 2),
    Max = round(max(yield, na.rm = TRUE), 2),
    Écart_type = round(sd(yield, na.rm = TRUE), 2),
    Coeff_variation = round(sd(yield, na.rm = TRUE) / mean(yield, na.rm = TRUE), 2)
  ) %>%
  arrange(desc(Moyenne))

print("Statistiques descriptives de yield par pays :")

tableau_pays_simple <- kable(stats_pays, 
                             format = "html",
                             caption = "Tableau 1 : Statistiques descriptives du rendement (t/ha) par pays",
                             col.names = c("Pays", "N", "Moyenne", "Médiane", 
                                           "Q1", "Q3", "Min", "Max", 
                                           "Écart-type", "Coeff. variation"),
                             align = c("l", rep("c", 9))) %>%
  kable_styling(bootstrap_options = c("striped", "hover", "condensed"),
                full_width = FALSE,
                position = "center") %>%
  row_spec(0, bold = TRUE, background = "#2E8B57", color = "white") %>%
  column_spec(1, bold = TRUE)

# Affichage du tableau
print(tableau_pays_simple)

# Sauvegarde du tableau en HTML
save_kable(tableau_pays_simple, file = "outputs/tableau_stats_pays.html")


# Calcul des statistiques descriptives par cultures

# Identification des 10 cultures principales
top_cultures <- data_yield %>%
  count(product, sort = TRUE) %>%
  head(10) %>%
  pull(product)

# Calcul des statistiques pour les top 10 cultures
stats_cultures <- data_yield %>%
  filter(product %in% top_cultures) %>%
  group_by(product) %>%
  summarise(
    Observations = n(),
    Moyenne = round(mean(yield, na.rm = TRUE), 2),
    Médiane = round(median(yield, na.rm = TRUE), 2),
    Q1 = round(quantile(yield, 0.25, na.rm = TRUE), 2),
    Q3 = round(quantile(yield, 0.75, na.rm = TRUE), 2),
    Min = round(min(yield, na.rm = TRUE), 2),
    Max = round(max(yield, na.rm = TRUE), 2),
    Écart_type = round(sd(yield, na.rm = TRUE), 2),
    Coeff_variation = round(sd(yield, na.rm = TRUE) / mean(yield, na.rm = TRUE), 2)
  ) %>%
  arrange(desc(Moyenne))

print("Statistiques descriptives de yield pour les 10 cultures principales :")

# Tableau pour les cultures
tableau_cultures <- kable(stats_cultures, 
                          format = "html",
                          caption = "Tableau 2 : Statistiques du rendement (t/ha) par culture",
                          col.names = c("Culture", "N", "Moyenne", "Médiane", 
                                        "Q1", "Q3", "Min", "Max", 
                                        "Écart-type", "Coeff. variation"),
                          align = c("l", rep("c", 9))) %>%
  kable_styling(bootstrap_options = c("striped", "hover", "condensed"),
                full_width = FALSE,
                position = "center") %>%
  row_spec(0, bold = TRUE, background = "#4682B4", color = "white") %>%
  column_spec(1, bold = TRUE)

# Affichage du tableau
print(tableau_cultures)

# Sauvegarde du tableau
save_kable(tableau_cultures, file = "outputs/tableau_stats_cultures.html")



#Question 4

# Utilisation des données filtrées des 5 pays
data_systeme <- data_filtree

# Vérification des systèmes de production présents
systemes <- unique(data_systeme$crop_production_system)
print("Systèmes de production présents :")
print(systemes)

# Les systèmes sont : [1] "All (PS)", "Rainfed (PS)", "Plaine/Bas-fond irrigated (PS)", "Bas-fonds rainfed (PS)" et "irrigated" 

#Statistiques descriptives par systèmes

# Calcul des statistiques par système de production
stats_systemes <- data_systeme %>%
  group_by(crop_production_system) %>%
  summarise(
    Observations = n(),
    Moyenne = round(mean(yield, na.rm = TRUE), 2),
    Médiane = round(median(yield, na.rm = TRUE), 2),
    Q1 = round(quantile(yield, 0.25, na.rm = TRUE), 2),
    Q3 = round(quantile(yield, 0.75, na.rm = TRUE), 2),
    Min = round(min(yield, na.rm = TRUE), 2),
    Max = round(max(yield, na.rm = TRUE), 2),
    Écart_type = round(sd(yield, na.rm = TRUE), 2),
    Coeff_variation = round(sd(yield, na.rm = TRUE) / mean(yield, na.rm = TRUE), 2)
  ) %>%
  arrange(desc(Moyenne))

print("Statistiques descriptives par système de production :")

# Création du tableau
tableau_systemes <- kable(stats_systemes, 
                          format = "html",
                          caption = "Tableau : Statistiques du rendement (t/ha) par système de production",
                          col.names = c("Système", "N", "Moyenne", "Médiane", 
                                        "Q1", "Q3", "Min", "Max", 
                                        "Écart-type", "Coeff. variation"),
                          align = c("l", rep("c", 9))) %>%
  kable_styling(bootstrap_options = c("striped", "hover", "condensed"),
                full_width = FALSE,
                position = "center") %>%
  row_spec(0, bold = TRUE, background = "#8B4513", color = "white") %>%
  column_spec(1, bold = TRUE)

# Affichage du tableau
print(tableau_systemes)

# Sauvegarde du tableau
save_kable(tableau_systemes, file = "outputs/tableau_stats_systemes.html")


# PÄRTIE 2

# Construction de la matrice de contiguité spatiale


# Filtrage des données pour le Sénégal et la période 2015-2020
data_senegal <- africa_data %>%
  filter(country == "Senegal",
         product == "Maize",
         harvest_year >= 2015 & harvest_year <= 2020,
         !is.na(yield))


# Calcul du rendement moyen par admin_1
rendement_moyen <- data_senegal %>%
  group_by(admin_1) %>%
  summarise(
    rendement_moyen = mean(yield, na.rm = TRUE),
    n_observations = n(),
    .groups = "drop"
  )

print("Rendement moyen par région admin_1 :")
print(rendement_moyen)


# Pour construire la matrice de contiguité spatiale à partir des données admin_1 du Sénégal :

# Méthode "queen" : On considère deux régions comme voisines si elles partagent au moins un point commun (soit une frontière, soit un sommet).

# Méthode "rook" : On considère deux régions comme voisines seulement si elles partagent une frontière commune (sans compter les sommets isolés).

# Méthode par distance seuil : On calcule les centroïdes de chaque région admin_1, puis on définit un rayon de voisinage. Deux régions sont voisines si la distance entre leurs centroïdes est inférieure à un seuil fixé

# La variable fnid peut servir d'identifiant unique pour relier les données agricoles aux données géographiques.
