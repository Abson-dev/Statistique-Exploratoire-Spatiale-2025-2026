

library(haven)
library(dplyr)

base_bf <- read_dta("C:/Users/HP/Desktop/ISE1 CL/Semestre1/Statistiques Exploratoires Spatiales/TP/TP_Groupe/TP 6/data/s00_me_bfa2021.dta")
View(base_bf)


unique(base_bf$s00q02)

library(readxl)
BFA_Final_stats <- read_excel("C:/Users/HP/Desktop/ISE1 CL/Semestre1/Statistiques Exploratoires Spatiales/TP/TP_Groupe/TP 6/outputs/BFA_Final_stats.xlsx")
View(BFA_Final_stats)


# Assure-toi que les colonnes de jointure ont le même type (ex: character ou factor)
base_bf$s00q02 <- as.character(base_bf$s00q02)
BFA_Final_stats$dept_code <- as.character(BFA_Final_stats$dept_code)

# Merge : left_join pour garder tous les ménages, même si le dept n'existe pas dans BFA_Final_stats
base <- base_bf %>%
  left_join(BFA_Final_stats, by = c("s00q02" = "dept_code"))


# Chemin complet du fichier de sortie
output_path <- "C:/Users/HP/Desktop/ISE1 CL/Semestre1/Statistiques Exploratoires Spatiales/TP/TP_Groupe/TP 6/outputs/base.dta"

# Sauvegarder au format .dta
write_dta(base, path = output_path)

cat("Fichier sauvegardé avec succès :", output_path, "\n")





