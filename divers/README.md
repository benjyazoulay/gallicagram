# Idées

## Gallicagram
- sous-corpus : les quotidiens
- exemple d'affichage interactif au démarrage
- option delta entre deux courbes ->nouvelle courbe
- double clic sur un point du graphique pour lancer dans gallica la recherche correspondante (renvoi à Gallica)
- coefficient de corrélation, significativité : y/années et entre deux courbes

## Gallicapresse
- structure géographique des données (réfléchir sur la visualisation : une carte sur toute la période/une carte dynamique ou avec sélection de l'année/un histogramme présentant la distribution dans les villes principales de publication pour toute la période/le même histogramme dynamique ou avec sélection de l'année dans une barre continue)
- structure des données selon le thème du journal
- structure des données selon le type de journal (quotidien/hebdomadaire/mensuel/etc.)

## N-GRAMME
- Récupérer les données des corpus Livre et Presse en texte brut par année
- Utiliser la fonction : data_frame(line = 1:nrow(book), text = book$text)  %>%  unnest_tokens(bigram, text, token = "ngrams", n = 2) %>%  count(bigram, sort = TRUE)
- Option joker pour avoir une suggestion du n+1-gramme
- Détermination grammaticale des mots
- Sensitivité à la casse
- Mode inflexion : utiliser les entrées du wikitionaire
- Plancher (google=40 livres différents min)
- Normalisation sur le fondement des mots les plus courants de la langue : en option
