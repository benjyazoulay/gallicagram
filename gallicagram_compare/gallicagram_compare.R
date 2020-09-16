library(WikidataR)
library(WikidataQueryServiceR)
library(xml2)
library(stringr)
library(rvest)
library(ggplot2)
library(ggrepel)
library(dplyr)
library(SPARQL)
library(tm)
library(quanteda)
library(stm)
library(wordcloud)
library(ggwordcloud)
library(tidytext)
library(lubridate)
setwd("C:/Users/Benjamin/Downloads/gallicagram")


liste<-read.csv("liste.csv",encoding = "UTF-8",header = FALSE)
colnames(liste)<-c("termes")

########## EXTRACTION
tab5<-as.data.frame(cbind(c(NA),c(NA),c(NA),c(NA)))
tab5<-tab5[-1,]

for (j in 1:length(liste$termes)) 
{

  for (i in 1900:1940)
  {
  mot<-str_replace(liste$termes[j]," ","%20")#un espace entre deux mots doit être remplacé par "%20"
  y<-as.character(i)  
  url<-str_c("https://gallica.bnf.fr/SRU?operation=searchRetrieve&version=1.2&startRecord=1&maximumRecords=1&page=1collapsing=false&exactSearch=true&query=text%20adj%20%22",mot,"%22%20%20and%20(dc.type%20all%20%22fascicule%22)%20and%20(gallicapublication_date%3E=%22",y,"/01/01%22%20and%20gallicapublication_date%3C=%22",y,"/12/31%22)%20sortby%20dc.date/sort.ascending&suggest=10&keywords=",mot)
  ngram<-as.character(read_xml(url))
  a<-str_extract(str_extract(ngram,"numberOfRecordsDecollapser&gt;+[:digit:]+"),"[:digit:]+")
  
  url_base<-str_c("https://gallica.bnf.fr/SRU?operation=searchRetrieve&version=1.2&startRecord=1&maximumRecords=1&page=1collapsing=false&version=1.2&query=(dc.type%20all%20%22fascicule%22)%20and%20(gallicapublication_date%3E=%22",y,"/01/01%22%20and%20gallicapublication_date%3C=%22",y,"/12/31%22)&suggest=10&keywords=")
  ngram_base<-as.character(read_xml(url_base))
  b<-str_extract(str_extract(ngram_base,"numberOfRecordsDecollapser&gt;+[:digit:]+"),"[:digit:]+")
  
  tab5<-rbind(tab5,c(i,a,b,liste$termes[j]))
  print(str_c(mot," ",i))
  }
}

#####CALCUL DE L'INDICATEUR
colnames(tab5)<-c("date","nb_temp","base_temp","termes")
tab5$date<-as.integer(tab5$date)
tab5$nb_temp<-as.integer(tab5$nb_temp)
tab5$base_temp<-as.integer(tab5$base_temp)
tab5$ratio_temp<-tab5$nb_temp/tab5$base_temp

#####AFFICHAGE DU GRAPHE

ggplot(tab5,aes(date,ratio_temp,color=termes))+geom_line(size=1)+
  scale_x_continuous(breaks = seq(1900,1940,2))+
  theme(axis.text.x = element_text(angle=45))+
  xlab("Date")+ylab("Part des numéros de presse mentionnant les termes recherchés")+
  ggtitle("Fréquence d'apparition dans la presse (Gallica-Presse)")+
  ggsave("Fréquence d'apparition dans la presse du nom de 4 grands militaires français.png",scale=2)


##########POUR UNE RESOLUTION AU MOIS##########

tab6<-as.data.frame(cbind(c(NA),c(NA),c(NA),c(NA)))
colnames(tab6)<-c("date","nb_temp","base_temp","termes")
########## EXTRACTION
for (x in 1:length(liste$termes))
{
for (i in 1940:1944)
{
  for (j in 1:12) 
  {
    mot<-str_replace(liste$termes[x]," ","%20")#un espace entre deux mots doit être remplacé par "%20"
    y<-as.character(i)
    z<-as.character(j)
    if(nchar(z)<2){z<-str_c("0",z)}
    url<-str_c("https://gallica.bnf.fr/SRU?operation=searchRetrieve&version=1.2&startRecord=1&maximumRecords=1&page=1collapsing=false&exactSearch=true&query=text%20adj%20%22",mot,"%22%20%20and%20(dc.type%20all%20%22fascicule%22)%20and%20(gallicapublication_date%3E=%22",y,"/",z,"/01%22%20and%20gallicapublication_date%3C=%22",y,"/",z,"/31%22)%20sortby%20dc.date/sort.ascending&suggest=10&keywords=",mot)
    ngram<-as.character(read_xml(url))
    a<-str_extract(str_extract(ngram,"numberOfRecordsDecollapser&gt;+[:digit:]+"),"[:digit:]+")
    
    url_base<-str_c("https://gallica.bnf.fr/SRU?operation=searchRetrieve&version=1.2&startRecord=1&maximumRecords=1&page=1collapsing=false&version=1.2&query=(dc.type%20all%20%22fascicule%22)%20and%20(gallicapublication_date%3E=%22",y,"/",z,"/01%22%20and%20gallicapublication_date%3C=%22",y,"/",z,"/31%22)&suggest=10&keywords=")
    ngram_base<-as.character(read_xml(url_base))
    b<-str_extract(str_extract(ngram_base,"numberOfRecordsDecollapser&gt;+[:digit:]+"),"[:digit:]+")
    date<-str_c(y,z,"01")
    tab6<-rbind(tab6,c(date,a,b,liste$termes[x]))
    print(str_c(mot," ",i,"-",j))
    
  }
  
}
}
#####CALCUL DE L'INDICATEUR
tab6<-tab6[-1,]
tab6$date<-ymd(as.character(tab6$date))
tab6$nb_temp<-as.integer(tab6$nb_temp)
tab6$base_temp<-as.integer(tab6$base_temp)
tab6$ratio_temp<-tab6$nb_temp/tab6$base_temp

#####AFFICHAGE
tab6%>%subset(tab6$date>=ymd(19400101) & tab6$date<=ymd(19450101))%>% 
  ggplot(aes(date,ratio_temp,color=termes))+geom_line(size=1)+
  scale_x_date(breaks=seq(as.Date("1940/1/1"), as.Date("1945/1/1"), "2 months"),date_labels = "%b %Y")+
  theme(axis.text.x = element_text(angle=45))+
  xlab("Date")+ylab("Part des numéros de presse mentionnant les termes recherchés")+
  ggtitle("Fréquence d'apparition dans la presse (Gallica-Presse)")+
  ggsave("Fréquence d'apparition dans la presse des noms Weygand et Pétain.png",scale=2)
