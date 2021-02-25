library(stringr)
library(dplyr)
library(ggplot2)
library(lubridate)
library(purrr)
library(stats)
library(utils)
library(xml2)
library(tidyverse)

#####GALLICAPRESSE
#Gallicapresse révèle la structure des données utilisées dans l'analyse de notoriété réalisée par GALLICAGRAM
#Les affichages effectués grâce à cet outil révèlent la structure des données selon :
#Les titres de presse les plus représentés
#L'origine géographique des mentions (ville de publication de ces titres de presse)
#Cet outil affiche des analyses en termes absolus et relatifs.
#Deux résolutions d'affichage sont disponibles : à l'année et au mois

#####EXTRACTION D'UN RAPPORT DE RECHERCHE
#La fonction d'extraction de rapport de recherche depuis gallica fonctionnant mal, nous reprenons ici une partie de l'outil gargallica qui exécute parfaitement cette tâche

setwd("C:/Users/Benjamin/Downloads/") #inscrivez ici votre répertoire de travail
#####GARGALLICA###############
i = 1

# Indiquez la question (la requête CQL visible dans l'URL query = () )
# Il faut recopier la question posée sur gallica.bnf.fr

question <- '(dc.type%20all%20"fascicule")%20sortby%20dc.date/sort.ascending&suggest=10&keywords='

page <- function(i)xml2::read_xml(paste0('http://gallica.bnf.fr/SRU?operation=searchRetrieve&version=1.2&query=(', question,')&collapsing=true&maximumRecords=50&startRecord=', i))


# Première 50 réponses (initialiser la structure xml avec un premier coup)
tot <- page(1)
# récupérer le nombre total de réponses
te <- xml2::as_list(tot)
nmax <- as.integer(unlist(te$searchRetrieveResponse$numberOfRecords))
# nmax <- 7853

# Boucle sur la suite, 50 par 50
# Ajouter au document xml tot les réponses des autres pages
for (j in seq(51, nmax, by = 50)){
  temp <- page(j)
  print(j)
  for (l in xml2::xml_children(temp)){
    xml2::xml_add_child(tot, l)
  }
}

xml2::write_xml(tot, 'results.xml')

xml_to_df <- function(doc, ns = xml_ns(doc)) {
  library(xml2)
  library(purrr)
  split_by <- function(.x, .f, ...) {
    vals <- map(.x, .f, ...)
    split(.x, simplify_all(transpose(vals)))
  }
  node_to_df <- function(node) {
    # Filter the attributes for ones that aren't namespaces
    # x <- list(.index = 0, .name = xml_name(node, ns))
    x <- list(.name = xml_name(node, ns))
    # Attributes as column headers, and their values in the first row
    attrs <- xml_attrs(node)
    if (length(attrs) > 0) {attrs <- attrs[!grepl("xmlns", names(attrs))]}
    if (length(attrs) > 0) {x <- c(x, attrs)}
    # Build data frame manually, to avoid as.data.frame's good intentions
    children <- xml_children(node)
    if (length(children) >= 1) {
      x <- 
        children %>%
        # Recurse here
        map(node_to_df) %>%
        split_by(".name") %>%
        map(bind_rows) %>%
        map(list) %>%
        {c(x, .)}
      attr(x, "row.names") <- 1L
      class(x) <- c("tbl_df", "data.frame")
    } else {
      x$.value <- xml_text(node)
    }
    x
  }
  node_to_df(doc)
}

# u <- xml_to_df(xml2::xml_find_all(tot, ".//srw:records"))
x = 1:3
parse_gallica <- function(x){
  xml2::xml_find_all(tot, ".//srw:recordData")[x] %>% 
    xml_to_df() %>% 
    select(-.name) %>% 
    .$`oai_dc:dc` %>% 
    .[[1]] %>% 
    mutate(recordId = 1:nrow(.)) %>% 
    #    tidyr::unnest() %>% 
    tidyr::gather(var, val, - recordId) %>% 
    group_by(recordId, var) %>% 
    mutate(value = purrr::map(val, '.value') %>% purrr::flatten_chr() %>% paste0( collapse = " -- ")) %>% 
    select(recordId, var, value) %>% 
    ungroup() %>% 
    mutate(var = stringr::str_remove(var, 'dc:')) %>% 
    tidyr::spread(var, value) %>% 
    select(-.name)
}

tot <- xml2::read_xml('results.xml')

tot_df <- 1:nmax %>% 
  parse_gallica %>% 
  bind_rows()

write.csv(tot_df,"rapport_tot.csv")

total<-read.csv("rapport_tot.csv")
##############################
total<-total[,c(5,8,10,15)]
total$title<-str_replace(total$title,"-"," ")
total$title<-str_remove_all(total$title,"[\\p{Punct}&&[^']].+")
total$publisher<-str_replace_all(total$publisher,"-"," ")
total$publisher<-gsub("[\\(\\)]", "", regmatches(total$publisher, gregexpr("\\(.*?\\)", total$publisher)))
total$publisher<-str_remove_all(total$publisher,'c"')
total$publisher<-str_remove_all(total$publisher,'"')
total$publisher<-str_remove_all(total$publisher,'character0')
total$identifier<-str_remove_all(total$identifier,"([:blank:].+)")
