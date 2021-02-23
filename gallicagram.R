library(ggplot2)
library(lubridate)
library(stringr)
library(utils)
library(xml2)
library(stringr)
library(dplyr)
setwd("C:/Users/Benjamin/Downloads/gallicagram")



gallicagram = function(mot,beginning,end,definition="year",span=2/(end-beginning)){
mot = str_replace(mot," ","%20")
if(definition=="year"){
tableau<-as.data.frame(matrix(nrow=0,ncol=3),stringsAsFactors = FALSE)
for (i in beginning:end){
  #mot<-"revolution%20nationale" #un espace entre deux mots doit être remplacé par "%20"
  y<-as.character(i)  
  url<-str_c("https://gallica.bnf.fr/SRU?operation=searchRetrieve&version=1.2&startRecord=1&maximumRecords=1&page=1collapsing=false&exactSearch=true&query=text%20adj%20%22",mot,"%22%20%20and%20(dc.type%20all%20%22fascicule%22)%20and%20(gallicapublication_date%3E=%22",y,"/01/01%22%20and%20gallicapublication_date%3C=%22",y,"/12/31%22)%20sortby%20dc.date/sort.ascending&suggest=10&keywords=",mot)
  ngram<-as.character(read_xml(url))
  a<-str_extract(str_extract(ngram,"numberOfRecordsDecollapser&gt;+[:digit:]+"),"[:digit:]+")
  url_base<-str_c("https://gallica.bnf.fr/SRU?operation=searchRetrieve&version=1.2&startRecord=1&maximumRecords=1&page=1collapsing=false&version=1.2&query=(dc.type%20all%20%22fascicule%22)%20and%20(gallicapublication_date%3E=%22",y,"/01/01%22%20and%20gallicapublication_date%3C=%22",y,"/12/31%22)&suggest=10&keywords=")
  ngram_base<-as.character(read_xml(url_base))
  b<-str_extract(str_extract(ngram_base,"numberOfRecordsDecollapser&gt;+[:digit:]+"),"[:digit:]+")
  
  tableau[nrow(tableau)+1,] = NA
  tableau[nrow(tableau),]<-c(i,a,b)
  print(i)
}

colnames(tableau)<-c("date","nb_temp","base_temp")
tableau$date<-as.integer(tableau$date)
tableau$nb_temp<-as.integer(tableau$nb_temp)
tableau$base_temp<-as.integer(tableau$base_temp)
tableau$ratio_temp<-tableau$nb_temp/tableau$base_temp

#####AFFICHAGE DU GRAPHE
title = paste("Fréquence d'usage de l'expression '", mot,sep="")
title=paste(title,"' (Gallica-Presse)",sep="")
a = ggplot(tableau,aes(date,ratio_temp))+geom_smooth(size=1,span=span,se=F)+ theme_classic()+
  theme(axis.text.x = element_text(angle=45))+
  xlab("Date") +  ggtitle(title)+
  guides(color=guide_legend(override.aes=list(fill=NA)))  + 
 theme(plot.title = element_text(hjust = 0.5))
print(a)
} 
if(definition=="month"){
##########POUR UNE RESOLUTION AU MOIS##########

tab6<-as.data.frame(matrix(nrow=0,ncol=3),stringsAsFactors = FALSE)
colnames(tab6)<-c("date","nb_temp","base_temp")
########## EXTRACTION
for (i in beginning:end){
  for (j in 1:12) 
  {
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
    tab6[nrow(tab6)+1,] = NA
    tab6[nrow(tab6),] = c(date,a,b)
    print(str_c(i,"-",j))
  }
}


#####CALCUL DE L'INDICATEUR
tab6<-tab6[-1,]
tab6$date<-ymd(as.character(tab6$date))
tab6$nb_temp<-as.integer(tab6$nb_temp)
tab6$base_temp<-as.integer(tab6$base_temp)
tab6$ratio_temp<-tab6$nb_temp/tab6$base_temp

#####AFFICHAGE
tab6%>%subset(tab6$date>=ymd(19400101) & tab6$date<=ymd(19450101))%>% ggplot(aes(date,ratio_temp))+geom_line(size=1)+ theme_classic() +
  scale_x_date(breaks=seq(as.Date("1940/1/1"), as.Date("1945/1/1"), "2 months"),date_labels = "%b %Y")+
  theme(axis.text.x = element_text(angle=45))+
  xlab("Date")+ylab("Part des numéros faisant mention de l'expression \n 'Révolution nationale' dans le corpus Gallica-Presse")+
  ggtitle("Fréquence d'usage de l'expression 'Révolution nationale' durant l'Occupation (Gallica-Presse)")+
  theme(axis.ticks = element_line(colour = "grey")) + 
  guides(color=guide_legend(override.aes=list(fill=NA)))  + 
  scale_x_continuous(expand=c(0,0)) + theme(plot.title = element_text(hjust = 0.5))
}
}
# 