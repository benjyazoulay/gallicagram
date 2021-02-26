IDEES

- recherche par journal (une liste déroulante avec recherche intelligente permet de sélectionner le journal)
- recherche multititres à partir d'une liste préétablie en csv (exemple : les quotidiens)
- ajouter des champs de recherches et afficher les courbes correspondantes
- accéder à base_temp hors ligne (csv) pour diviser le temps de téléchargement par deux (du coup mettre une borne inférieure en 1631 et une borne supérieure en 2021 dans les champs date)
- cumul des fréquences sur une même courbe (ex : juif+juive+judeo)
- option delta entre deux courbes ->nouvelle courbe
- dans l'onglet corpus : graphique plotly
- faire une version pour gallica-livres (peut être seulement une case à cocher pour basculer de l'un à l'autre)
- double clic sur un point du graphique pour lancer dans gallica la recherche correspondante

STRUCTURE DES DONNEES
- possible lorsque l'extraction rapide du csv depuis l'api sera implémenté
- structure géographique des données (réfléchir sur la visualisation : une carte sur toute la période/une carte dynamique ou avec sélection de l'année/un histogramme présentant la distribution dans les villes principales de publication pour toute la période/le même histogramme dynamique ou avec sélection de l'année dans une barre continue)
- structure des données selon le titre du journal (faire figurer les principaux types/histogramme de la distribution dans les titres mentionnant le plus souvent le terme recherché)
- structure des données selon le thème du journal
- structure des données selon le type de journal (quotidien/hebdomadaire/mensuel/etc.)


requête pour nombre de numéros total dans un journal en fonction de l'ark : url=str_c("https://gallica.bnf.fr/SRU?operation=searchRetrieve&version=1.2&startRecord=0&maximumRecords=1&page=1&collapsing=false&exactSearch=true&query=arkPress%20all%20%22",ark,"_date%22")

requête pournombre de numéros pour une recherche dans un journal en fonction de l'ark, du terme recherché, entre deux dates : url=str_c("https://gallica.bnf.fr/SRU?operation=searchRetrieve&version=1.2&startRecord=0&maximumRecords=1&page=1&collapsing=false&exactSearch=true&query=arkPress%20all%20%22",ark,"_date%22%20and%20%28gallica%20adj%20%22",mot,"%22%29%20sortby%20dc.date%20and%20(gallicapublication_date%3E=%22",beginning,"%22%20and%20gallicapublication_date%3C=%22",end,"%22)")
