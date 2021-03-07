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

tableau=total
tableau$nb_numeros<-NA
tableau$ark<-tableau$identifier
tableau$ark<-str_remove_all(tableau$ark,"https://gallica.bnf.fr/ark:/12148/")
tableau$ark<-str_replace_all(tableau$ark,"/","_")

tableau$duree_publi<-NA
tableau$date_deb<-NA
tableau$date_fin<-NA

for (i in 1:length(tableau$identifier)) 
{tryCatch({
  ark=tableau$ark[i]
  url=str_c("https://gallica.bnf.fr/SRU?operation=searchRetrieve&version=1.2&startRecord=0&maximumRecords=1&page=1&collapsing=false&exactSearch=true&query=arkPress%20all%20%22",ark,"%22%20sortby%20dc.date/sort.ascending")
  ngram<-as.character(read_xml(url))
  a<-str_extract(str_extract(ngram,"numberOfRecordsDecollapser&gt;+[:digit:]+"),"[:digit:]+")
  tableau$nb_numeros[i]<-as.integer(a)
  b=str_extract(str_extract(ngram,"date>.........."),"[:digit:].........")
  b=str_remove_all(b,"[:alpha:]")
  b=str_remove_all(b,":")
  b=str_remove_all(b,"/")
  b=str_remove_all(b,"<")
  tableau$date_deb[i]<-b
  url=str_c("https://gallica.bnf.fr/SRU?operation=searchRetrieve&version=1.2&startRecord=",a,"&maximumRecords=1&page=1&collapsing=false&exactSearch=true&query=arkPress%20all%20%22",ark,"%22%20sortby%20dc.date/sort.ascending")
  ngram<-as.character(read_xml(url))
  c=str_extract(str_extract(ngram,"date>.........."),"[:digit:].........")
  c=str_remove_all(c,"[:alpha:]")
  c=str_remove_all(c,":")
  c=str_remove_all(c,"/")
  c=str_remove_all(c,"<")
  tableau$date_fin[i]<-c
  print(i)
}, error=function(e){})}


tableau$deb_bis<-tableau$date_deb
tableau$fin_bis<-tableau$date_fin
for (i in 1:length(tableau$deb_bis)) {
  if(is.na(tableau$deb_bis[i])){}
  else if (str_length(tableau$deb_bis[i])==4){tableau$deb_bis[i]<-str_c(tableau$deb_bis[i],"-01-01")}
  }
for (i in 1:length(tableau$deb_bis)) {
  if(is.na(tableau$deb_bis[i])){}
  else if (str_length(tableau$deb_bis[i])==7){tableau$deb_bis[i]<-str_c(tableau$deb_bis[i],"-01")}
}
for (i in 1:length(tableau$deb_bis)) {
  if(is.na(tableau$fin_bis[i])){}
  else if (str_length(tableau$fin_bis[i])==4){tableau$fin_bis[i]<-str_c(tableau$fin_bis[i],"-12-31")}
}
for (i in 1:length(tableau$deb_bis)) {
  if(is.na(tableau$fin_bis[i])){}
  else if (str_length(tableau$fin_bis[i])==7){tableau$fin_bis[i]<-str_c(tableau$fin_bis[i],"-31")}
  
}

tableau$duree_publi=as.integer(as.Date(tableau$fin_bis)-as.Date(tableau$deb_bis))

tableau$is_quotidien<-FALSE
for (i in 1:length(tableau$is_quotidien)) {
  if(is.na(tableau$nb_numeros[i]/tableau$duree_publi[i])){}
  else if(tableau$duree_publi[i]<366){}
  else if(tableau$nb_numeros[i]/tableau$duree_publi[i]>52/365){tableau$is_quotidien[i]<-TRUE}
  
}

  tableau$sdewey<-""
tableau$sdewey_nom<-""
for (i in 1:length(tableau$ark)) {
  url<-str_c("https://gallica.bnf.fr/services/Categories?SRU=arkPress%20all%20%22",tableau$ark[i],"%22")
  extrait<-as.character(paste(read_html(url)))
  extrait<-str_extract(extrait,"sdewey.+howMany")
  tableau$sdewey[i]<-str_extract(extrait,"[:digit:]+")
  extrait<-str_extract(extrait,"libelleValue.+")
  extrait<-str_remove_all(extrait,"libelleValue")
  extrait<-str_remove_all(extrait,"howMany")
  extrait<-str_remove_all(extrait,"[:punct:]")
  tableau$sdewey_nom[i]<-extrait
  print(i)
}
