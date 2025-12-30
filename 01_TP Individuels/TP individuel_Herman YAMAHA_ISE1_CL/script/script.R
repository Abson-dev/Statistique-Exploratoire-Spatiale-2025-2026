# =====================================================================
# TP INDIVIDUEL SES : Herman YAMAHA
# ISE 1 - CL
# Année académique 2025 - 2026
# Sous la supervision de : M. HEMA
# =====================================================================

# =====================================================================
# SECTION 1 : INSTALLATION ET CHARGEMENT DES PACKAGES
# =====================================================================

# Fonction pour installer uniquement les packages manquants
install_if_missing <- function(packages) {
  new_packages <- packages[!(packages %in% installed.packages()[,"Package"])]
  if(length(new_packages) > 0) {
    install.packages(new_packages, dependencies = TRUE)
    cat("Packages installés :", paste(new_packages, collapse = ", "), "\n")
  } else {
    cat("Tous les packages sont déjà installés.\n")
  }
}

# Liste des packages nécessaires
required_packages <- c("spData", "spDataLarge", "sp", "sf", "spdep", 
                       "classInt", "here")

# Installation des packages manquants
install_if_missing(required_packages)

# Chargement des bibliothèques
library(spData)
library(spDataLarge)
library(sp)
library(sf)
library(spdep)
library(classInt)
library(here)

cat("\n=== Tous les packages ont été chargés avec succès ===\n\n")


# =====================================================================
# EXERCICE 4-1
# =====================================================================

# ---------------------------------------------------------------------
# Question 1 : Chargement et transformation des données Baltimore
# ---------------------------------------------------------------------

# Charger les données baltimore du package spData
data("baltimore", package = "spData")

# Affichage
View(baltimore)

# Transformation en SpatialPointsDataFrame
# On spécifie les colonnes X et Y pour la géométrie
baltimore_sp <- SpatialPointsDataFrame(coords = baltimore[, c("X", "Y")], 
                                       data = baltimore)

# Affichage des statistiques sommaires
print(summary(baltimore_sp))


# ---------------------------------------------------------------------
# Question 2 : Matrice de contiguïté Bishop
# ---------------------------------------------------------------------

# Écrire la matrice de contiguïté de type Bishop de l'exemple de la grille régulière du cours

# Création d'une grille régulière 3x3 pour l'exemple

# Pour obtenir Bishop, on prend Queen et on soustrait Rook
nb_queen <- cell2nb(3, 3, type = "queen")
nb_rook <- cell2nb(3, 3, type = "rook")
nb_bishop <- diffnb(nb_queen, nb_rook)

# a. Matrice binaire (non normalisée)
W_bishop_bin <- nb2mat(nb_bishop, style = "B")

# b. Version normalisée
W_bishop_norm <- nb2mat(nb_bishop, style = "W")

# Renommer les lignes et colonnes des matrices de 1 à 9
rownames(W_bishop_bin)  <- 1:9
colnames(W_bishop_bin)  <- 1:9

rownames(W_bishop_norm) <- 1:9
colnames(W_bishop_norm) <- 1:9

# Affichage de la matrice binaire
print("Matrice Bishop binaire :")
print(W_bishop_bin)

# Affichage de la matrice normalisée
print("Matrice Bishop normalisée :")
print(W_bishop_norm)


# Représentation de la structure de voisinage avec contiguïté Bishop sur une carte

# Remonter d'un niveau depuis la racine (script/) vers le dossier outputs/
file_path <- here("..", "outputs", "voisinage_bishop.png")

png(file_path, width = 2000, height = 2000, res = 200)

# a. Coordonnées 3x3
coords <- as.matrix(expand.grid(x = 1:3, y = 3:1))

# b. Taille des carrés
size <- 1  

# c. Tracé des carrés
plot(NA, xlim = c(0.5, 3.5), ylim = c(0.5, 3.5), asp = 1, axes = FALSE, xlab = "", ylab = "")
for (i in 1:nrow(coords)) {
  x <- coords[i, 1]
  y <- coords[i, 2]
  rect(x - size/2, y - size/2, x + size/2, y + size/2,
       border = "black", col = "lightgrey")
}

# d. Ajout des liens bishops
plot(nb_bishop, coords = coords, add = TRUE, col = "red", pch = 19, lwd = 2)

# e. Titre principal
title("Structure de voisinage avec contiguïté Bishop (3x3)", cex = 3)

# f. Ajouter les numéros
text(coords, labels = 1:9, pos = 2, col = "blue", cex = 1.7)

# g. Message explicatif en bas de la figure
mtext("Un segment rouge entre deux points indique que ceux-ci sont en relation de voisinage (contiguïté Bishop).",
      side = 1, line = 3, col = "black", cex = 1.1)

dev.off()

cat("Graphique 'voisinage_bishop.png' créé avec succès.\n\n")


# ---------------------------------------------------------------------
# Question 3 : Vérification de la structure de voisinage pour Columbus
# ---------------------------------------------------------------------

# Téléchargement de Columbus
columbus_sf <- st_read("https://geodacenter.github.io/data-and-lab//data/columbus.geojson")

# Convertissement en objet spatial
columbus_sp <- as(columbus_sf, "Spatial")

# Génération de la matrice de voisinage
col_nb_generated <- poly2nb(columbus_sp)

cat("Résumé de la matrice de voisinage générée :\n")
summary(col_nb_generated)

# Chargement du fichier externe .gal
col.gal.nb <- read.gal(system.file("etc/weights/columbus.gal", package = "spdep")[1])

cat("\nRésumé de la matrice de voisinage du fichier .gal :\n")
summary(col.gal.nb)

# Vérification si les structures sont identiques
identical_check <- all.equal(col.gal.nb, col_nb_generated, check.attributes = FALSE)
print(identical_check)

# Indices des régions à comparer
indices <- c(5, 16, 25, 30, 31, 39)

for (i in indices) {
  voisins_gal <- sort(col.gal.nb[[i]])
  voisins_gen <- sort(col_nb_generated[[i]])
  
  cat("\n--- Région", i, "---\n")
  cat("col.gal.nb (", length(voisins_gal), "voisins):", voisins_gal, "\n")
  cat("col_nb_generated (", length(voisins_gen), "voisins):", voisins_gen, "\n")
  
  # Comparaison
  communs    <- intersect(voisins_gal, voisins_gen)
  seulement1 <- setdiff(voisins_gal, voisins_gen)
  seulement2 <- setdiff(voisins_gen, voisins_gal)
  
  cat("Communs:", communs, "\n")
  cat("Seulement dans col.gal.nb:", seulement1, "\n")
  cat("Seulement dans col_nb_generated:", seulement2, "\n")
}

# Commentaire 
cat("\n--- COMMENTAIRE ---\n")
cat("Les résultats de la comparaison montrent que les deux structures de voisinage\n",
    "ne sont pas parfaitement identiques. La majorité des régions possèdent le même\n",
    "nombre de voisins, mais certaines présentent des différences de longueur dans\n",
    "leurs listes de contiguïté. Par exemple, les régions 5, 16 et 25 comptent 7 voisins dans col.gal.nb\n",
    "contre 8 dans col_nb_generated, tandis que les régions 30, 31 et 39 affichent\n",
    "respectivement 4 dans col.gal.nb contre 5 dans col_nb_generated, ou 2 dans col.gal.nb contre 3 voisins col_nb_generated.\n\n",
    "Ces écarts révèlent que, même si les deux matrices décrivent globalement la même logique spatiale,\n",
    "elles divergent sur quelques cas particuliers. Cela peut provenir d'une différence de règle de\n",
    "construction de voisinage ou de légères variations géométriques.\n\n")


# ---------------------------------------------------------------------
# Question 4 : Carte des revenus par quartier à Columbus
# ---------------------------------------------------------------------

# Pour le jeu de données columbus, avec la fonction classIntervals() du package classInt, produire
# la carte des quartiers de Columbus coloriés en dégradé de vert selon les valeurs
# de la variable revenu (INC) en quatre classes de longueur égale.

file_path <- here("..", "outputs", "Revenu annuel moyen des ménages par quartier à Columbus.png")

png(file_path, width = 2000, height = 2000, res = 200)

# Ajuster les marges intérieures et extérieures
par(mar = c(2, 4, 4, 2) + 0.1)  # Réduire la marge inférieure intérieure
par(oma = c(4, 0, 0, 0))  # Ajouter une marge extérieure en bas

# Décaler le graphe vers la gauche (plt = proportion de la fenêtre utilisée)
par(plt = c(0.02, 0.80, 0.15, 0.95)) 

# 1) Calcul des intervalles : 4 classes de longueur égale
intervals <- classIntervals(columbus_sf$INC, n = 4, style = "equal")

# 2) Définition des couleurs (dégradé de vert)
colors <- c("#e5f5e0", "#a1d99b", "#41ab5d", "#006d2c")

# 3) Carte avec revenu INC (sans barre de dégradé en bas)
plot(columbus_sf["INC"], 
     breaks = intervals$brks, 
     pal = colors, 
     main = "Revenu annuel moyen des ménages (en milliers de dollars US) par quartier à Columbus",
     key.pos = NULL,
     reset = FALSE,
     line = -2)

# 4) Calcul des centroïdes et extraction des coordonnées
centroids <- st_centroid(columbus_sf)
coords <- st_coordinates(centroids)

# 5) Ajouter les numéros des quartiers (COLUMBUS_I)
text(coords[,1], coords[,2],
     labels = as.character(columbus_sf$COLUMBUS_I),
     col = "black", cex = 0.8, font = 2)

# 6) Légende avec intervalles [a – b[ sauf le dernier [a – b]
brks_labels <- sprintf("%.2f", intervals$brks)
interval_labels <- paste0("[ ", brks_labels[-length(brks_labels)], " – ", 
                          brks_labels[-1], " [")

# Modifier le dernier intervalle pour qu'il soit fermé à droite
interval_labels[length(interval_labels)] <- paste0("[ ", 
                                                   brks_labels[length(brks_labels)-1], 
                                                   " – ", 
                                                   brks_labels[length(brks_labels)], 
                                                   " ]")


# Ajouter un titre centré au-dessus de la légende
# Récupérer les coordonnées de la légende


legend(x = lg$rect$left, 
       y = lg$rect$top + 1,   # +0.5 = décalage vers le haut
       legend = interval_labels,
       fill = colors,
       cex = 0.8,
       bty = "n",
       inset = c(0.15, 0))



# Positionner le titre centré
text(x = mean(c(lg$rect$left, lg$rect$left + lg$rect$w)),
     y = lg$rect$top + 1.05,   # un peu au-dessus de la légende
     labels = "Classes des revenus",
     font = 2, cex = 0.8, inset = c(0.45, 0))


# 7) Message dans la marge extérieure
mtext("La variable COLUMBUS_I a été utilisée comme identifiant des quartiers.",
      side = 1, line = 2, cex = 0.9, col = "black", outer = TRUE)

# Réinitialiser les marges
par(mar = c(5, 4, 4, 2) + 0.1)
par(oma = c(0, 0, 0, 0))

dev.off()

cat("Graphique 'Revenu annuel moyen des ménages par quartier à Columbus.png' créé avec succès.\n\n")


# =====================================================================
# EXERCICE 4-2
# =====================================================================

# ---------------------------------------------------------------------
# Question 1 : Chargement des données nc
# ---------------------------------------------------------------------

# Charger les données nc du package spData

# nc <- st_read(system.file("shapes/sids.shp", package="spData")[1], quiet=TRUE)
# Ce shp n'est plus disponible dans ce lien, raison pour laquelle nous avons utilisé un autre chemin

nc <- st_read("https://geodacenter.github.io/data-and-lab/data/sids.geojson")

# Extraction des centroïdes pour les représentations graphiques
coords <- st_coordinates(st_centroid(st_geometry(nc)))


# ---------------------------------------------------------------------
# Question 2 : Voisinage par contiguïté
# ---------------------------------------------------------------------

# Construction du voisinage par contiguïté
nc_nb_contig <- poly2nb(nc)

# Représentation graphique
file_path <- here("..", "outputs", "Voisinage par contiguïté.png")

png(file_path, width = 2000, height = 2000, res = 200)

plot(st_geometry(nc), border = "grey")
plot(nc_nb_contig, coords, add = TRUE, col = "red", pch = 19, cex = 0.6)
title("Voisinage par contiguïté (Queen)")

dev.off()

cat("Graphique 'Voisinage par contiguïté.png' créé avec succès.\n\n")

# Résumé de la structure
cat("Résumé de la structure de voisinage par contiguïté :\n")
summary(nc_nb_contig)

# Commentaire du résumé de la structure
cat("\n--- COMMENTAIRE ---\n")
cat("
Le résumé de la structure de voisinage montre que l'on travaille sur 100 régions,
avec un total de 490 liens de contiguïté. Cela signifie que la matrice des voisins est très creuse,
puisque seulement 4,9 % des cases sont non nulles, ce qui est typique en analyse spatiale.
En moyenne, chaque région est connectée à environ 5 voisines, ce qui traduit une situation assez équilibrée.
La distribution du nombre de voisins révèle que la majorité des régions ont entre 4 et 6 voisins,
tandis que huit régions périphériques n'en ont que deux, ce qui reflète leur position en bordure de la carte.
À l'inverse, deux régions centrales se distinguent par une forte connectivité avec neuf voisins chacune.
Globalement, cette structure est cohérente : les régions centrales sont plus connectées,
les périphériques moins, et la matrice conserve une densité faible mais suffisante pour l'analyse spatiale.
")


# ---------------------------------------------------------------------
# Question 3 : Voisinage KNN (K=5)
# ---------------------------------------------------------------------

# Construire une matrice de voisinage basée sur les 5 plus proches voisins

file_path <- here("..", "outputs", "Voisinage KNN.png")

png(file_path, width = 2000, height = 2000, res = 200)

# k-NN dirigé (5 plus proches voisins)
knn <- knearneigh(coords, k = 5)
nb_dir <- knn2nb(knn, sym = FALSE)

# Carte
plot(st_geometry(nc), border = "grey")
points(coords, pch = 19, col = "red", cex = 0.7)   # points rouges

# Flèches bleues avec décalage
offset <- 0.07  # décalage 

for (i in seq_along(nb_dir)) {
  if (length(nb_dir[[i]]) > 0) {
    xi <- coords[i, 1]; yi <- coords[i, 2]
    for (j in nb_dir[[i]]) {
      xj <- coords[j, 1]; yj <- coords[j, 2]
      
      # vecteur direction
      dx <- xj - xi
      dy <- yj - yi
      d <- sqrt(dx^2 + dy^2)
      
      # décalage proportionnel à la distance
      start_x <- xi + dx * (offset / d)
      start_y <- yi + dy * (offset / d)
      end_x   <- xj - dx * (offset / d)
      end_y   <- yj - dy * (offset / d)
      
      arrows(x0 = start_x, y0 = start_y,
             x1 = end_x, y1 = end_y,
             length = 0.08, col = "blue", lwd = 0.7)
    }
  }
}

title("Voisinage KNN (K=5)")

dev.off()

cat("Graphique 'Voisinage KNN.png' créé avec succès.\n\n")

# Résumé de la structure
cat("Résumé de la structure de voisinage KNN (K=5) :\n")
summary(nb_dir)

# Commentaire du résumé de la structure
cat("\n--- COMMENTAIRE ---\n")
cat("
Dans cette structure de voisinage construite par la méthode des 5 plus proches voisins,
il faut bien distinguer la logique des flèches.
Chaque centroïde envoie exactement 5 flèches sortantes vers ses 5 voisins les plus proches en distance euclidienne.
Ces flèches matérialisent le choix direct de la région : elles garantissent que chaque unité est reliée à cinq autres, sans exception.
En revanche, un centroïde peut recevoir plusieurs flèches entrantes, car il peut être choisi comme voisin par de nombreuses autres régions.
C'est ce mécanisme qui explique pourquoi, dans une représentation graphique symétrisée, certains points semblent reliés à plus de 5 voisins :
ils n'ont toujours que 5 liens sortants, mais ils accumulent davantage de liens entrants.

Le résumé confirme cette logique : la liste contient 100 régions, chacune avec 5 liens sortants,
ce qui donne un total de 500 relations et une densité de 5 % dans la matrice. La moyenne est donc de 5 voisins par région,
et la distribution est parfaitement uniforme puisque toutes les régions affichent 5 liens.
Le caractère « non-symmetric neighbours list » souligne que la relation n'est pas forcément réciproque :
une région peut considérer une autre comme l'un de ses 5 plus proches voisins sans que l'inverse soit vrai.
Cette structure est typique des graphes k-nearest neighbors, où l'on impose un nombre fixe de voisins sortants,
mais où le nombre de voisins entrants peut varier, ce qui rend la matrice non symétrique.
")



# ---------------------------------------------------------------------
# Question 4 : Voisinage par distance seuil
# ---------------------------------------------------------------------

# Choisir un seuil de distance et construire une matrice de voisinage basée sur ce seuil de distance

# Calcul de la distance critique (distance minimale nécessaire pour que chaque comté ait au moins un voisin)
k1 <- knearneigh(coords, k = 1)
dist_min <- unlist(nbdists(knn2nb(k1), coords))
seuil <- max(dist_min) # Seuil garantissant qu'aucun comté ne soit isolé

cat("Seuil de distance calculé :", seuil, "degrés\n")
cat("(L'unité du système de coordonnées WGS84 est le degré)\n\n")

# Construction du voisinage par seuil de distance
nc_nb_dist <- dnearneigh(coords, 0, seuil)

# Représentation graphique
file_path <- here("..", "outputs", "Voisinage par distance seuil.png")

png(file_path, width = 2000, height = 2000, res = 200)

plot(st_geometry(nc), border = "grey")
plot(nc_nb_dist, coords, add = TRUE, col = "darkgreen")
title(main = paste("Voisinage par distance (Seuil =", round(seuil, 2), "degré)"))

dev.off()

cat("Graphique 'Voisinage par distance seuil.png' créé avec succès.\n\n")

# Note : On n'a pas converti le degré en km parce que la conversion n'est pas fixe, 
# elle varie en fonction des positions sur la terre.

# Résumé de la structure
cat("Résumé de la structure de voisinage par distance seuil :\n")
summary(nc_nb_dist)

# Commentaire
cat("\n--- COMMENTAIRE ---\n")
cat("
Cette structure de voisinage concerne 100 régions et présente 304 liens de contiguïté,
soit une densité de 3,04 % dans la matrice, ce qui confirme son caractère creux.
Chaque région possède en moyenne 3 voisins, mais la distribution est hétérogène :
certaines n'ont qu'un seul lien tandis qu'une région atteint 6 voisins.
On observe deux sous-graphes disjoints, ce qui signifie que l'ensemble des régions n'est pas entièrement connecté
et que certaines zones forment des composantes séparées.
La répartition montre que la majorité des régions ont entre 2 et 4 voisins,
mais 11 régions périphériques se distinguent par une connectivité minimale avec seulement un voisin.
Globalement, cette structure traduit une connectivité faible et fragmentée,
où la présence de sous-graphes disjoints souligne l'importance de vérifier la cohésion du réseau spatial avant toute analyse.
")


# =====================================================================
# FIN DU SCRIPT
# =====================================================================