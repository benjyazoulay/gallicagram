library(stringr)
library(plotly)

setwd("C:/Users/Benjamin/Downloads")
table<-read.csv("base_gallica_livres.csv")
table$hovers = str_c(table$date,": N = ",table$base_temp)
plot2<-plot_ly(table, x=~date,y=~base_temp,text=~hovers,type='bar',mode='spline',hoverinfo="text")
Title = paste("<b>Répartition des numéros dans Gallica-livres<b>")
y <- list(title = "Nombre de numéros dans Gallica-livres",titlefont = 41)
x <- list(title = "Date",titlefont = 41)
plot2 = layout(plot2, yaxis = y, xaxis = x,title = Title)
plot2

table<-read.csv("base_gallica.csv")
table$hovers = str_c(table$date,": N = ",table$base_temp)
plot3<-plot_ly(table, x=~date,y=~base_temp,text=~hovers,type='bar',mode='spline',hoverinfo="text")
Title = paste("<b>Répartition des numéros dans Gallica-presse<b>")
y <- list(title = "Nombre de numéros dans Gallica-presse",titlefont = 41)
x <- list(title = "Date",titlefont = 41)
plot3 = layout(plot3, yaxis = y, xaxis = x,title = Title)
plot3
