"""
EXAMEN FINAL: Statistique exploratoire spatiale
Année académique : 2025/2026
Nom : Kadidja GUEBEDIANG A NKEN
Classe : ISE1 Cycle Long
"""

"""
les bases de données
"""
hvstat_gpkg<-st_read("data/hvstat_africa_boundary_v1.0.gpkg")
hvstat_csv <- read_csv("data/hvstat_africa_data_v1.0.csv")

"""
Partie 1 : HarvestStat Africa
"""

"""
1. a)Decrire l'unité statistique:

l'unité statistique ici est le pays d'Afrique subsaharienne. ce qui est étudié ici n'est pas entièrement le pays mais 
l'aspect agricole en mettant en lumière :
 -l'identifiant géographique unique du pays à travers la variable "fnid" permettant de reconnaitre de manière unique les admin 2 de chaque pays
 -les unité administratives du premier niveau (Variable "admin1" , ex: les régions)  et du deuxième niveau (Variable "admin2", ex: les départements)  donnant les noms
 des deux niveaux des unités administratives prises en compte
 -les cultures agricoles qu'on peut trouver dans chaque zone étudiée (variable "product") : 
 -et enfin la période étudiée (ex: winter pour hiver, avec la variable season_name)
"""

"""
1. b)Expliquer la difference conceptuelle entre area, production et yield

La variable "area" ici représente la surface cultivée dans chaque admin2 pour une
production particulière en hectare (exemple pla surface cultivée de macabo au Sénégal dans la région de Fatick département de Foundiouge en 2014 
était de 300ha) 
Pendant que la avariable "production" représente la production en tonne d'une culture dans une unité administrative
de niveau 2 dans un pays donné durant une année
Et le rendement est le rapport entre la production d'une culture et la surface occupée par cette culture

La relation théorique qui lie ces trois concepts est la formule : rendement= production(t)/area(ha)

"""
"""
2. Analyser la distribution de qc_flag par pays et par culture
"""

# voici les résultats des valeurs 
n=nrow(hvstat_csv)

cat("\n Qualité des données (qc_flag)\n")
cat("  ok :", sum((hvstat_csv$qc_flag == 0))/n*100, "\n")
cat("  aberrant:", (sum(hvstat_csv$qc_flag == 1))/n*100, "\n")
cat("  faible variance:", sum((hvstat_csv$qc_flag == 2))/n*100, "\n")

#une solution à proposer Filtrer : ne garder que les observations de bonne qualité
hvstat_clean <- hvstat_csv %>%
  filter(qc_flag == 0)

"""
3. produire  dees statistiques descriptives 
"""
library (writexl)
pays   <- "Benin" 
produit      <- "Maize"

hvstat_csv_filtre<- hvstat_csv %>%
  filter(country == pays,
         product == produit
         ) %>%
  group_by(fnid, admin_1)

statistique <- hvstat_csv_filtre %>%
  mutate(Pays=country)%>%
  mutate(moyenne = mean(area,na.rm=TRUE)) %>%
  mutate(mediane = median(area, na.rm=TRUE) ) %>%
  mutate(ecartype =  sd(area, na.rm=TRUE) ) %>%
  rename(
    Modalite = country,
    Moyenne = moyenne,
    Mediane = mediane,
    Ecart_type = ecartype  #pour la dispersion
  )

write_xlsx(statistique, "statistique_benin.xlsx")

pays   <- "Mali" 
produit      <- "Maize"

hvstat_csv_filtre<- hvstat_csv %>%
  filter(country == pays,
         product == produit
  ) %>%
  group_by(fnid, admin_1)

statistique <- hvstat_csv_filtre %>%
  mutate(Pays=country)%>%
  mutate(moyenne = mean(area,na.rm=TRUE)) %>%
  mutate(mediane = median(area, na.rm=TRUE) ) %>%
  mutate(ecartype =  sd(area, na.rm=TRUE) ) %>%
  rename(
    Modalite = country,
    Moyenne = moyenne,
    Mediane = mediane,
    Ecart_type = ecartype  #pour la dispersion
  )

write_xlsx(statistique, "statistique_Mali.xlsx")

"""
4.comparer les distrbutions de rendement entre les systèmes de production
"""
print (unique(hvstat_csv$crop_production_system))
hvstat_csv<- hvstat_csv %>%
  filter(country == pays,
  ) %>%
  group_by(crop_production_system) %>%
  mutate(Pays=country)%>%
  mutate(Moyenne=mean(yield))
  
cat("\n─── Distribution du rendement ───\n")
summary(hvstat_csv_systeme$yield)
View(hvstat_csv_systeme)


"""
Cas du Senegal
"""
PAYS_CIBLE   <- "Senegal"
PRODUIT      <- "Maize"
PERIODE      <- 2015:2020

RDTMOY <- hvstat_clean %>%
  filter(country == PAYS_CIBLE,
         product == PRODUIT,
         harvest_year %in% PERIODE) %>%
  group_by(admin_1) %>%
  summarise(
    yield_moy  = mean(yield, na.rm = TRUE),
    n_annees   = n_distinct(harvest_year),
    .groups = "drop"
  )
print(RDTMOY)

"""
pour construire les matrices de contiguïté spatiale, nous allons faire la matrice Queen
"""

######Construction de la Matrice Queen

geo_sen <- hvstat_pckg %>%
  filter(ADMIN0 == PAYS_CIBLE) %>%
  left_join(sen_mais, by = c("FNID" = "fnid"))

cat("Polygones Sénégal :", nrow(geo_sen), "\n")

coord <- st_coordinates(st_centroid(geo_sen))
head(coord)

geo_sen_nb <- poly2nb(geo_sen)
summary(geo_sen_nb)

# Visualiser
par(mar = c(0, 0, 0, 0))
plot(st_geometry(geo_sen), border = "grey")
plot(geo_sen_nb, coord, add = TRUE, col = "red")

"""
Indice de Moran
"""
# Matrice de pondération spatiale
geo_sen_listw <- nb2listw(geo_sen_nb, style = "W", zero.policy = TRUE)

# Calcul de l'indice de Moran
moran_I <- moran(
  x = geo_sen$yield,
  listw = geo_sen_listw,
  n = length(geo_sen$yield_moy),
  S0 = Szero(geo_sen_listw)
)$I

# Affichage
print(paste("Indice de Moran :", round(moran_I, 4)))

###Analyse spatiale*

# Rendement moyen des céréales par pays 
comp_pays <- hvstat_csv %>%
  filter(product %in% cereales) %>%
  group_by(country, product) %>%
  summarise(
    yield_moy = mean(yield, na.rm = TRUE),
    .groups   = "drop"
  )

# Top 10 pays producteurs de maïs
top10_mais <- comp_pays %>%
  filter(product == "Maize") %>%
  slice_max(yield_moy, n = 10)

p_comp <- ggplot(top10_mais,
                  aes(x = reorder(country, yield_moy), y = yield_moy)) +
  geom_col(fill = "darkgoldenrod2", alpha = 0.85) +
  geom_text(aes(label = round(yield_moy, 2)), hjust = -0.1, size = 3.5) +
  coord_flip() +
  labs(
    title = "Top 10 pays — Rendement moyen du maïs",
    x = NULL, y = "Rendement (t/ha)"
  ) +
  theme_minimal(base_size = 12)

ggsave(paste0(out_dir, "15_comparaison_pays_mais.png"),
       p_comp, width = 10, height = 6, dpi = 300)

####
heat_data <- hvstat_clean %>%
  filter(product %in% c("Maize", "Rice", "Sorghum", "Millet", "Wheat"),
         country %in% PAYS_AO) %>%
  group_by(country, product) %>%
  summarise(yield_moy = mean(yield, na.rm = TRUE), .groups = "drop")

p_heat <- ggplot(heat_data, aes(x = product, y = country, fill = yield_moy)) +
  geom_tile(color = "white") +
  scale_fill_viridis_c(option = "B", name = "Rendement\n(t/ha)") +
  labs(title = "Rendements moyens — Afrique de l'Ouest",
       x = NULL, y = NULL) +
  theme_minimal(base_size = 11) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave(paste0(out_dir, "16_heatmap_cultures_pays.png"),
       p_heat, width = 9, height = 7, dpi = 300)



# Coefficient de variation (CV) par zone = mesure de l'instabilité

cv_par_zone <- hvstat_csv %>%
  filter(country == PAYS_CIBLE, product == PRODUIT) %>%
  group_by(fnid, admin_1) %>%
  summarise(
    yield_moy = mean(yield, na.rm = TRUE),
    yield_sd  = sd(yield, na.rm = TRUE),
    yield_cv  = yield_sd / yield_moy * 100,   # CV en %
    n_obs     = n(),
    .groups   = "drop"
  ) %>%
  filter(n_obs >= 5)   # au moins 5 années de données

# Jointure spatiale
geo_cv <- hvstat_geo %>%
  filter(ADMIN0 == PAYS_CIBLE) %>%
  left_join(cv_par_zone, by = c("FNID" = "fnid"))

# Carte du CV
p_cv <- ggplot(geo_cv) +
  geom_sf(aes(fill = yield_cv), color = "grey40", linewidth = 0.3) +
  scale_fill_distiller(
    palette = "RdYlGn", direction = -1, na.value = "grey85",
    name = "CV (%)"
  ) +
  labs(
    title    = "Variabilité du rendement du maïs",
    subtitle = paste(PAYS_CIBLE, "| CV = écart-type / moyenne × 100"),
    caption  = "Un CV élevé indique une production instable"
  ) +
  theme_void(base_size = 11) +
  theme(legend.position = "right",
        plot.title = element_text(face = "bold"))

ggsave(paste0(out_dir, "17_carte_CV_rendement.png"),
       p_cv, width = 10, height = 8, dpi = 300)

