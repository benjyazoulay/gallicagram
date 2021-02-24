library(shiny)
library(ggplot2)
library(plotly)
library(stringr)
library(xml2)

Plot <- function(data,input){
  tableau = data[["tableau"]]
  Title = paste("<b>Gallicagram a épluché", as.character(sum(tableau$base_temp)))
  Title = Title %>% paste(' numéros,\n et trouvé "', data[["mot"]],sep="") 
  Title = Title %>% paste(as.character(sum(tableau$nb_temp)),sep = '" dans ')
  Title = Title %>% paste("d'entre eux</b>")
  width = nrow(tableau)
  span = 2/width + input$span*(width-2)/(10*width)
  tableau$row = 1:width
  tableau$loess = loess(data=tableau,ratio_temp~row,span=span)$fitted
  text = as.character(tableau$base_temp)
  plot = plot_ly(tableau, x=~date,y=~loess,text=~base_temp,type='scatter',mode='spline',hoverinfo="text")
  y <- list(title = "Fréquence d'occurence dans Gallica-presse",titlefont = 41)
  x <- list(title = data[["resolution"]],titlefont = 41)
  plot = layout(plot, yaxis = y, xaxis = x,title = Title)
  return(plot)
}

get_data <- function(mot,from,to,resolution){
  mot = str_replace(mot," ","%20")
    tableau<-as.data.frame(matrix(nrow=0,ncol=3),stringsAsFactors = FALSE)
    progress <- shiny::Progress$new()
    on.exit(progress$close())
    progress$set(message = "Patience...", value = 0)
    for (i in from:to){
      end_of_month = c(31,28,31,30,31,30,31,31,30,31,30,31)
      if( i%%4==0){end_of_month[2]=29} #Ne pas oublier les années bisextiles (merci Maxendre de m'y avoir fait penser)
      y<-as.character(i)
      if(resolution=="Année"){beginning = str_c(y,"/01/01")
      end = str_c(y,"/12/31")}
      I = 1
      if(resolution=="Mois"){I=1:12} #Pour faire ensuite une boucle sur les mois
        for(j in I){
          if(resolution=="Mois"){
            z = as.character(j)
            if(nchar(z)<2){z<-str_c("0",z)}
            beginning = str_c(y,"/",z,"/01")
            end = str_c(y,"/",z,"/",end_of_month[j])}
      url<-str_c("https://gallica.bnf.fr/SRU?operation=searchRetrieve&version=1.2&startRecord=1&maximumRecords=1&page=1collapsing=false&exactSearch=true&query=text%20adj%20%22",mot,"%22%20%20and%20(dc.type%20all%20%22fascicule%22)%20and%20(gallicapublication_date%3E=%22",beginning,"%22%20and%20gallicapublication_date%3C=%22",end,"%22)%20sortby%20dc.date/sort.ascending&suggest=10&keywords=",mot)
      ngram<-as.character(read_xml(url))
      a<-str_extract(str_extract(ngram,"numberOfRecordsDecollapser&gt;+[:digit:]+"),"[:digit:]+")
      url_base<-str_c("https://gallica.bnf.fr/SRU?operation=searchRetrieve&version=1.2&startRecord=1&maximumRecords=1&page=1collapsing=false&version=1.2&query=(dc.type%20all%20%22fascicule%22)%20and%20(gallicapublication_date%3E=%22",beginning,"%22%20and%20gallicapublication_date%3C=%22",end,"%22)&suggest=10&keywords=")
      ngram_base<-as.character(read_xml(url_base))
      b<-str_extract(str_extract(ngram_base,"numberOfRecordsDecollapser&gt;+[:digit:]+"),"[:digit:]+")
      tableau[nrow(tableau)+1,] = NA
      date=y
      if(resolution=="Mois"){date = paste(y,z,sep="/")}
      tableau[nrow(tableau),]<-c(date,a,b)
      }
      progress$inc(1/(to-from), detail = paste("Gallicagram ratisse l'an", i))
     }
  
  colnames(tableau)<-c("date","nb_temp","base_temp")
  format = "%Y"
  if(resolution=="Mois"){format=paste(format,"%m",sep="/")}
  tableau.date = as.Date(as.character(tableau$date),format=format)
  tableau$nb_temp<-as.integer(tableau$nb_temp)
  tableau$base_temp<-as.integer(tableau$base_temp)
  tableau$ratio_temp<-tableau$nb_temp/tableau$base_temp
  data = list(tableau,mot,resolution)
  names(data) = c("tableau","mot","resolution")
  return(data)}


ui <- fluidPage(
   
   # Application title
   titlePanel("Réglages"),
   
   sidebarLayout(
      sidebarPanel(
        textInput("mot","Mot à chercher","Mendes-France"),
        numericInput("beginning","Début",1952),
        numericInput("end","Fin",1958),
         sliderInput("span",
                     "Lissage de la courbe :",
                     min = 0,
                     max = 10,
                     value = 0),
         selectInput("resolution", label = "Résolution :", choices = c("Année","Mois")),
        actionButton("do","Générer le graphique"),
        ),
      
            mainPanel(
         plotlyOutput("plot")
      )
   )
)

# Define server logic required to draw a histogram
server <- function(input, output){
    observeEvent(input$do,{
    data = get_data(input$mot,input$beginning,input$end,input$resolution)
      output$plot <- renderPlotly({Plot(data,input)})
    })
}

shinyApp(ui = ui, server = server)