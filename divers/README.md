# Idées

## Gallicagram
- bug : axe y du barplot en subplot ; annotations en mode recherche par titres (affichage des titre derrière la mention "Corpus :")
- double clic sur un point du graphique pour lancer dans gallica la recherche correspondante (renvoi à Gallica)
- option delta entre deux courbes ->nouvelle courbe
- sous-corpus : les quotidiens

## Gallicapresse
- bug : barre de chargement
- structure des données selon le type de journal (quotidien/hebdomadaire/mensuel/etc.)

## N-GRAMME
- Récupérer les données des corpus Livre et Presse en texte brut par année
- Utiliser la fonction : data_frame(line = 1:nrow(book), text = book$text)  %>%  unnest_tokens(bigram, text, token = "ngrams", n = 2) %>%  count(bigram, sort = TRUE)
- Option joker pour avoir une suggestion du n+1-gramme
- Détermination grammaticale des mots
- Sensitivité à la casse, marques de l'oralité, contractions entre les mots
- Mode inflexion : utiliser les entrées du wikitionaire
- Plancher (google=40 livres différents min)
- Normalisation sur le fondement des mots les plus courants de la langue : en option
