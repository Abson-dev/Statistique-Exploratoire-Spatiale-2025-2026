library(ggspatial)
library(here)
library(osmextract)
library(sf)
library(ggplot2)
library(sf)
library(dplyr)
#install.packages("spdep")
library(spdep)

chemin <- "data/"

gpk <- st_read(paste0(chemin, "hvstat_africa_boundary_v1.0.gpkg"),
                      quiet = TRUE)
df_csv <- read.csv(paste0(chemin, "hvstat_africa_data_v1.0.csv"),
                       stringsAsFactors = FALSE)


#Question 1 : Décrivons l'unité statistique etc.

colnames(df_csv)
head(df_csv)
summary(df_csv$admin_2)
table(df_csv$admin_2) # none : 66748 

#L'unité d'observation est une culture agricole

#fnid : ID unique pour chaque pays 
#country, country_code : pays
#admin_1, admin_2 : divisions administratives (région, département)

View(df_csv)

#1.B
#area : la surface cultivée en ha

#production : production agricole (t)

#yield : rendement (t/ha)


# RELATION : yield = production/area

##Question 2 : 


#qc_flag : indicateur de qualité (0 = ok, 1 = valeur aberrante, 2 = faible variance)

#Nombre total d'observation dans la base

nrow(df_csv) #203125 observations

#Trouvons les pays dans la base




unique(df_csv$country)
# On va prendre ces pays :*
#"Burkina Faso", "Mali", "Benin", Togo", "Niger" 


# Pays d'Afrique de l'Ouest 
pays <- c(
  "Burkina Faso", "Benin", "Ghana", "Guinea", "Liberia",
  "Mali", "Mauritania", "Niger", "Nigeria",
  "Sierra Leone", "Togo"
)





# Distribution globale de qc_flag 
df_csv %>% 
  count(qc_flag) %>%
  mutate(pct = n / sum(n) * 100)



# Filtrer pour l'Afrique de l'Ouest

# Distribution globale qc_flag pour pays
nrow(df_csv$qc_flag)

df_ao <- df_csv %>% filter(country %in% pays)
df_ao %>% 
  count(qc_flag) %>%
  mutate(pct = n / sum(n) * 100)

# Par pays (pays dans pays uniquement)
df_ao %>%
  group_by(country, qc_flag) %>%
  summarise(n = n(), .groups = 'drop') %>%
  group_by(country) %>%
  mutate(pct = n / sum(n) * 100) %>%
  arrange(country, qc_flag)


#qc_flag     n        pct
#1       0 78053 97.8193576
#2       1   283  0.3546677
#3       2  1457  1.8259747

# Par culture 
df_ao %>%
  group_by(product, qc_flag) %>%
  summarise(n = n(), .groups = 'drop') %>%
  group_by(product) %>%
  mutate(pct = n / sum(n) * 100) %>%
  arrange(desc(n))

length(unique(df_csv$product)) #94 comme y en a 94 ce sera long dans un graphique



# Visualisation
p1 <- ggplot(df_ao, aes(x = reorder(country, country, length), 
                  fill = factor(qc_flag))) +
  geom_bar(position = "fill") +
  coord_flip() +
  labs(title = "Distribution de qc_flag ",
       y = "Proportion", x = "Pays", fill = "QC Flag") +
  theme_minimal()
p1
ggsave(filename = "outputs/distribution_qc_flag_pays.png", plot = p1, width = 8, height = 6, dpi = 300)


#Ici nous visualisons globalement la distribution de cette variable sur toute 
#la base avec les pays dans pays


df_plot <- df_ao %>%
  count(qc_flag) %>%                 
  mutate(pct = n / sum(n) * 100)    

# Graphe
p2 <- ggplot(df_plot, aes(x = factor(qc_flag), y = pct, fill = factor(qc_flag))) +
  geom_bar(stat = "identity") +      
  coord_flip() +                     
  geom_text(aes(label = paste0(round(pct, 2), "%")), 
            hjust = -0.1, size = 4) +
  labs(title = "Distribution de qc_flag",
       x = "QC Flag",
       y = "Pourcentage (%)",
       fill = "QC Flag") +
  theme_minimal() +
  scale_y_continuous(expand = expansion(mult = c(0, 0.1)))

p2
ggsave(filename = "outputs/distribution_globale_qc_flag_pour_pays.png", plot = p2, width = 8, height = 6, dpi = 300)

#Ce graphique nous montre que pour les pays ("Burkina Faso", "Mali", "Benin", "Togo", "Niger")
#2 représente 0.35% de cette base
#1 : représente 1.82% de cette base
#0 : 97.81%


#AZnalyse par pays et par culture simultanément

# Table résumé
resume <- df_ao %>%
  group_by(country, product, qc_flag) %>%
  summarise(n = n(), .groups = 'drop') %>%
  group_by(country, product) %>%
  mutate(
    total = sum(n),
    pct = round(n / total * 100, 1)
  ) %>%
  arrange(country, product, qc_flag)

# Afficher
print(resume, n = 10)


#2.b Une stratégie de corriger les observations avec 1 et 2

#les valeurs aberrantes peuvent ^petre corrigées en appliquant
#la méthode statistique qui ramène aux bornes : premier quartile si c'est une valeur aberrante vers le bas,
#au troisième quartile si c'est une valeur aberrante v ers le haut.

#Question 3 : producyion des statistiques descrip

colnames(df_csv)

#Vérifions si les données sont annuelles

summary(df_csv$harvest_year)

length(unique(df_csv$harvest_year))

#Test des valeurs manquantes 
sum(is.na(df_ao$yield))

sum(is.na(df_ao$yield))

missing_complet <- df_ao %>%
  group_by(country) %>%
  summarise(
    total_obs = n(),
    yield_NA = sum(is.na(yield)),
    area_NA = sum(is.na(area)),
    production_NA = sum(is.na(production)),
    pct_yield_NA = round(sum(is.na(yield)) / n() * 100, 1),
    pct_area_NA = round(sum(is.na(area)) / n() * 100, 1),
    pct_prod_NA = round(sum(is.na(production)) / n() * 100, 1)
  ) %>%
  arrange(desc(pct_yield_NA))

print(missing_complet)


## On enlève certains pays comme Guinea,Sierra Leo…, Liberia qui ont plus de 50% de valeurs
## manquantes pour les autres pays de l'Afrique de l'Ouest que nous alloçns garder 
##  (le Sénégal étant exclu) ont des pourcentages au plus de 6% on peut tolérer.


pays <- c(
  "Burkina Faso", "Benin", "Ghana",
  "Mali", "Mauritania", "Niger", "Nigeria",
  "Togo"
)

df_ao2 <- df_csv %>% filter(country %in% pays)


# Statistiques descriptives de yield par pays
stats_pays <- df_ao2 %>%
  filter(!is.na(yield)) %>%
  group_by(country) %>%
  summarise(
    n_obs = n(),
    moyenne = round(mean(yield), 2),
    mediane = round(median(yield), 2),
    ecart_type = round(sd(yield), 2),
    min = round(min(yield), 2),
    max = round(max(yield), 2),
    Q1 = round(quantile(yield, 0.25), 2),
    Q3 = round(quantile(yield, 0.75), 2)
  ) %>%
  arrange(desc(moyenne))

print(stats_pays)


# Statistiques descriptives de yield par culture
stats_culture <- df_ao2 %>%
  filter(!is.na(yield)) %>%
  group_by(product) %>%
  summarise(
    n_obs = n(),
    moyenne = round(mean(yield), 2),
    mediane = round(median(yield), 2),
    ecart_type = round(sd(yield), 2),
    min = round(min(yield), 2),
    max = round(max(yield), 2),
    Q1 = round(quantile(yield, 0.25), 2),
    Q3 = round(quantile(yield, 0.75), 2)
  ) %>%
  arrange(desc(moyenne))

print(stats_culture)



#question 4 : 

#summary(df_csv$crop_production_system )

unique(df_ao2$crop_production_system)




#On va regrouper par crop_production_system et calculer les rendements par systeme

# Stats par système de production
stats_systeme <- df_ao2 %>%
  filter(!is.na(yield)) %>%
  group_by(crop_production_system) %>%
  summarise(
    
    moyenne = round(mean(yield), 2),
   
  ) %>%
  arrange(desc(moyenne))

stats_systeme

#Resultats

"""
1 irrigated                        17.3 
2 All (PS)                          3.71
3 Plaine/Bas-fond irrigated (PS)    2.95
4 Rainfed (PS)                      1.55
5 Bas-fonds rainfed (PS)            1.31
6 dam irrigation                    0.91
7 surface water                     0.67
8 parastatal recessional            0.57
9 dieri                             0.38
"""

# Le système irrigué fait en moyenne un rendement 17.3 t/ha c'est le plus élevé. Il fait
#5 fois plus le rendement moyen de "All" qui est le deuxieme le plus élevé. LES rendements moyens les plus faibles sont obsxervés avec
#dam irrigation, surface water, parastatal recessional, dieri qui sont inférieurs à 1t/ha.
# le rendement moyen le plus faible est observé avec dieri 



### Indiquons comment construire la matrice de contiguité spatiale à partir de fnid ou admin_1

# Pour construire la matrice, on associe le fichier .gpkg à notre base csv 


names(gpk)


# 1. rendements moyens par admin_1 (période 2015-2020)
rendements_senegal <- df_csv %>%
  filter(country == "Senegal",
         harvest_year >= 2015, 
         harvest_year <= 2020,
         !is.na(yield)) %>%
  group_by(admin_1) %>%
  summarise(
    rendement_moyen = mean(yield),
    
  )

# 2. Charger les géométries du Sénégal
gpk_senegal <- gpk %>%
  filter(ADMIN0 == "Senegal")

# 3. Joindre 
gpk_senegal <- gpk_senegal %>%
  left_join(rendements_senegal, by = c("ADMIN1" = "admin_1"))




# 4. Matrice de contiguïté
w <- poly2nb(gpk_senegal, queen = TRUE)
w_listw <- nb2listw(w, style = "W")

# 5. Indice de Moran
moran_test <- moran.test(gpk_senegal$rendement_moyen, w_listw)

print(moran_test)
print(paste("I =", round(moran_test$estimate[1], 4)))
print(paste("p-value =", round(moran_test$p.value, 4)))

"""
Autocorrélation spatiale POSITIVE significative des rendements agricoles au Sénégal (2015-2020).
Les régions voisines ont tendance à avoir des rendements similaires :
  
Si une région a un bon rendement → ses voisines aussi
Si une région a un faible rendement → ses voisines aussi
"""