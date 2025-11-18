# ==============================================================================
# FICHIER PRINCIPAL DU PROJET R
# Gère la configuration de l'environnement, le chargement des librairies 
# et l'exécution séquentielle des scripts d'analyse.
# ==============================================================================

# --- 1. Installation et Chargement des Librairies (À exécuter une seule fois) ---

# Liste des packages requis
packages <- c("sf", "ggplot2", "tmap", "rnaturalearth", "rnaturalearthdata", 
              "dplyr", "tidyr", "shiny", "leaflet", "webshot", "mapview", "units", "nngeo")

# Fonction pour vérifier, installer et charger
install_and_load <- function(pkg){
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, dependencies = TRUE)
  }
  library(pkg, character.only = TRUE)
}

# Appliquer la fonction à la liste des packages
cat("Chargement des librairies...\n")
sapply(packages, install_and_load)

# --- 2. Définition des Chemins et de l'Environnement ---

# Définition du chemin de base du projet (Ce chemin doit être adapté à votre machine)
base_path <- "C:/Users/DELL/Desktop/ENSAE/ISEP3/Semestre 1/Analyse spatiale/TP2/TP2"


# Chemin du répertoire de sortie
output_dir <- file.path(base_path, "outputs")

# Création du répertoire 'outputs' s'il n'existe pas
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
  cat("Dossier de sortie créé à l'emplacement :", output_dir, "\n")
} else {
  cat("Le dossier de sortie existe déjà :", output_dir, "\n")
}

# Chemin du répertoire contenant les scripts d'analyse
scripts_dir <- file.path(base_path, "scripts")





# --- 3. Exécution Séquentielle des Scripts d'Analyse ---


cat("\nDébut de l'exécution séquentielle des scripts...\n")

# Visualisation des aires protégées
cat("  -> Exécution du script : Visualisation_Aires protégées.R ...\n")
source(file.path(scripts_dir, "Visualisation_Aires protégées.R"), encoding = "UTF-8") 
cat("  -> Fin de l'exécution de : Visualisation_Aires protégées.R\n")


# Visualisation des cours d'eau
cat("  -> Exécution du script : Visualisation_Cours d'eau.R ...\n")
source(file.path(scripts_dir, "Visualisation_Cours d'eau.R"), encoding = "UTF-8") 
cat("  -> Fin de l'exécution de : Visualisation_Cours d'eau.R\n")


# Visualisation des fleuves et rivières
cat("  -> Exécution du script : Visualisation_Fleuves et rivières.R ...\n")
source(file.path(scripts_dir, "Visualisation_Fleuves et rivières.R"), encoding = "UTF-8") 
cat("  -> Fin de l'exécution de : Visualisation_Fleuves et rivières.R\n")


# Visualisation des grandes villes
cat("  -> Exécution du script : Visualisation_Grandes villes.R ...\n")
source(file.path(scripts_dir, "Visualisation_Grandes villes.R"), encoding = "UTF-8") 
cat("  -> Fin de l'exécution de : Visualisation_Grandes villes.R\n")


# Visualisation des hôpitaux
cat("  -> Exécution du script : Visualisation_Hôpitaux.R ...\n")
source(file.path(scripts_dir, "Visualisation_Hôpitaux.R"), encoding = "UTF-8") 
cat("  -> Fin de l'exécution de : Visualisation_Hôpitaux.R\n")


# Visualisation conjointe des limites administratives, des aires protégées, des points habitables et des équipements sociaux
cat("  -> Exécution du script : script1.R ...\n")
source(file.path(scripts_dir, "script1.R"), encoding = "UTF-8") 
cat("  -> Fin de l'exécution de : script1.R\n")


cat("\n Tous les scripts ont été traités.\n")