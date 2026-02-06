#### Partie 1 : 

library(sf)        # lecture et gestion des polygones
library(dplyr)     # manipulation
library(ggplot2)   # cartes
library(spdep)     # Pour une analyse spatiale 
library(readr)     # lecture des fichers csv
library(readxl)
library(writexl)

path_gpkg <- "data/hvstat_africa_boundary_v1.0.gpkg"
path_csv  <- "data/hvstat_africa_data_v1.0.csv"

africa_sf <- st_read(path_gpkg)  # contient FNID, ADMIN0, ADMIN1, ADMIN2 + geometry
hv <- read_csv(path_csv, show_col_types = FALSE)  # contient fnid + variables agricoles



###1-

##1-a

      #Ici on considère comme unité d'observation, une zone ou espace cultivée. Cette 
      #dernière est identifié à l'aide de la variable fnid (qui est un identifiant 
      #géographique unique pour chaque zone cultivée), les variables admin_1 et 
      #admin_2 permettent de ratacher la zone à un pays et une région (ou departement 
      #selon certains pays), la variable product donne le nom du nom du produit qui y est 
      #cultivé et season_name, la saison la saison  à laquelle on le produit est cultuvée 
      #dans la zone en question.

##1-b
  
     #area désigne la surface ou encore la superficie de la zone de cultivé (elle est ici mesuré
     #en ha), production quant à elle fait référence à la quantité produite ou encore à la quantité
     # obtenu issue de la récolte de la cuture dans la zone, Cepandant yield donne le rendement,
     # obtenu, c'est à dire la quantité produite par unité de surface de la zone.
     # Ces trois variables sont relié par la relation théoriques suivante : 
     
     #       yield = production / area . (/ signifiant la division)


###2-

##2-a : Analyse de la distribution de qc_flag par pays et par culture 
  
country_choice <- c("Benin", "Burkina Faso", "Mali", "Togo", "Niger")
product_choice <- unique(hv$product)

Dist_qc_flag_par_pays <- hv %>%
  filter(country == country_choice) %>%
  group_by(country, product) %>%
  summarise(
    n_obs      = n(),
    qc_flag_skewness = moments::skewness(qc_flag, na.rm = TRUE),
    qc_flag_kurtosis = moments::kurtosis(qc_flag, na.rm = TRUE),
    .groups = "drop"
  )

write_xlsx(Dist_qc_flag_par_pays, path = "outputs/Dist_qc_flag_par_pays.xlsx")

##2-b 
    
    #Pour traiter les observation qc_flag=2 qui représente les valeurs abbérantes, on peut utiliser la technique dite
    #de winsorisation, cela consiste à donner toutes les valeur de qc_flag suppériere ou 99em centile
    #la valeur du 99em centile (on peut faire de meme avec les dcile etc...)
    
    #Pour ce qui est des valeur du qc_flag avec une faible variance (qc_flag=2),  
    

###3- Production de statistiques descriptives par pays et par culture 
    
stat_desc <- hv %>%
  filter(country == country_choice) %>%
  group_by(country, product) %>%
  summarise(
    n_obs      = n(),
    yield_max = max(yield),
    yield_min = min(yield),
    yield_etendu = max(yield) - min(yield),
    yield_quartile_1= quantile(yield, 0.25, na.rm = TRUE),
    yield_medium = sd(yield, na.rm = TRUE),
    yield_quartile_3= quantile(yield, 0.75, na.rm = TRUE),
    yield_mean = mean(yield, na.rm = TRUE),
    .groups = "drop"
  )

write_xlsx(stat_desc, path = "outputs/stat_desc_yield.xlsx")



###4- Comparaison des distribution des rendements entre les système de production

Pays_culture <- hv %>%
  filter(country == 'Senegal', product == 'Rice')
  
p <-  ggplot(Pays_culture, aes(x = as.factor(Pays_culture$crop_production_system), y = Pays_culture$yield)) +
  geom_boxplot(fill = "skyblue", outlier.color = "red", alpha = 0.7) +
  coord_cartesian(ylim = c(0, quantile(Pays_culture$yield, 0.95, na.rm = TRUE))) +  # Zoom sur les 95% des valeurs
  labs(
    title = "Boxplot des rendements selon le systéme de production pour le riz au Sénégal",
    x = "Syteme de production",
    y = "Rendement"
  ) +
  theme_minimal()


print(p)


# Dans le cas du Sénégal avec l'agriculture on vois que les rendement avec le systeme irrigué 
#sont beaucoups plus élevé et mois dispersé que les autres formes.



### Claculons le rendement moyen par région entre 2015 et 2020 pour le Mais au Sénégal

prod_choice <- "Maize"
year_choice <- c(2015, 2016, 2017, 2018, 2019, 2020)

Base_sen_mais_15_20 <- hv %>%
  filter(country == 'Senegal', product == prod_choice, harvest_year == year_choice) %>%
  group_by(admin_1) %>%
  summarise(
    yield_mean = mean(yield, na.rm = TRUE),
    .groups = "drop"
  )

##1- Construction avec queen 

# la matrice “queen” consiste à poser wij = 1 si les admin_1 i et j ont au moins une frontière ou un sommet commun


nb_q <- poly2nb(africa_sf, queen = TRUE)

# 2) Zones sans voisins
no_nb <- which(card(nb_q) == 0)
length(no_nb)

# 3) Visualisation simple des liens (sur centroïdes)
coords <- st_coordinates(st_centroid(st_geometry(africa_dat)))

plot(st_geometry(africa_dat), border = "grey70", main = "Voisinage Queen (liens entre centroïdes)")
plot(nb_q, coords, add = TRUE, col = "red")




##2- Calcul de l'indice de Moran

africa_sf <- africa_sf %>%
  rename(fnid = FNID)

africa_dat <- africa_sf %>%
  left_join(hv, by = "fnid")

africa_dat <- africa_dat %>%
  filter(country == 'Senegal', product == prod_choice, harvest_year == year_choice) %>%
  group_by(admin_1) %>%
  summarise(
    yield_mean = mean(yield, na.rm = TRUE),
    .groups = "drop"
  )


af_ok <- africa_dat %>% filter(!is.na(yield_mean))

nb_ok <- poly2nb(af_ok, queen = TRUE)

# Poids W (normalisation par ligne)
lw_ok <- nb2listw(nb_ok, style = "W", zero.policy = TRUE)

y <- af_ok$yield_mean

# Indice de Moran global 
moran_res <- moran.test(y, lw_ok, zero.policy = TRUE)
moran_res

# Moran plot (diagramme de Moran)
moran.plot(y, lw_ok, zero.policy = TRUE)

##Résultat du calcul 


#moran_res <- moran.test(y, lw_ok, zero.policy = TRUE)
#moran_res

#Moran I test under randomisation

#data:  y  
#weights: lw_ok  
#n reduced by no-neighbour observations  

#Moran I statistic standard deviate = 0.4385, p-value = 0.3305
#alternative hypothesis: greater
#sample estimates:
#  Moran I statistic       Expectation          Variance 
#       -0.03141638       -0.33333333        0.47406678 
#On a un I faible et négative, cela indique une faible spatiale autocorrellation négative



