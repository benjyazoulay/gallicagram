library(shiny)
library(ggplot2)
library(plotly)
library(stringr)

library(xml2)
library(markdown)
library(shinythemes)
data = list()


Plot <- function(data,input){
  tableau = data[["tableau"]]
  Title = paste("<b>Gallicagram a épluché", as.character(sum(tableau$base_temp)))
  Title = Title %>% paste(' numéros,\n et trouvé "', data[["mot"]],sep="") 
  Title = Title %>% paste(as.character(sum(tableau$nb_temp)),sep = '" dans ')
  Title = Title %>% paste("d'entre eux</b>")
  width = length(unique(tableau$date))
  span = 2/width + input$span*(width-2)/(10*width)
  #tableau$row = 1:width
  tableau$loess = tableau$nb_temp
  for(mot in str_split(data$mot,",")[[1]]){
    mot = str_replace(mot," ","%20")
    z = which(tableau$mot==mot)
    tableau$loess[z] = loess(data=tableau[z,],ratio_temp~as.integer(date),span=span)$fitted
  }
  tableau$hovers = str_c(tableau$date,": x = ",tableau$nb_temp,", N = ",tableau$base_temp)
  plot = plot_ly(tableau, x=~date,y=~loess,text=~hovers,color =~mot,type='scatter',mode='spline',hoverinfo="text")
  y <- list(title = "Fréquence d'occurence dans Gallica-presse",titlefont = 41)
  x <- list(title = data[["resolution"]],titlefont = 41)
  plot = layout(plot, yaxis = y, xaxis = x,title = Title)
  if(length(grep(",",data$mot))==0){plot = layout(plot,showlegend=FALSE)}
  if(input$barplot){
    Title = paste("<b>Répartition du nombre de numéros présents dans la base\nde données Gallica-presse pour la période", as.character(tableau$date[1])," - ",as.character(tableau$date[length(tableau$date)]))
    width = nrow(tableau)
    span = 2/width + input$span*(width-2)/(10*width)
    tableau$hovers = str_c(tableau$date,": N = ",tableau$base_temp)
    plot1 = plot_ly(tableau, x=~date,y=~base_temp,text=~hovers,type='bar',hoverinfo="text",marker = list(color='rgba(31, 119, 180,1)'))
    y <- list(title = "Nombre de numéros dans Gallica-presse",titlefont = 41)
    x <- list(title = data[["resolution"]],titlefont = 41)
    plot1 = layout(plot1, yaxis = y, xaxis = x,title = Title,showlegend = FALSE)
    plot = subplot(plot,plot1,nrows = 2,legend=NULL,shareX = T)
    return(plot)
  } else{
    return(plot)
  }
}

Plot1 <- function(data,input){
  tableau = data[["tableau"]]

  return(plot1)
}

get_data <- function(mot,from,to,resolution){
    mot = str_replace(mot," ","%20")
    mots = str_split(mot,",")[[1]]
    tableau<-as.data.frame(matrix(nrow=0,ncol=4),stringsAsFactors = FALSE)
    progress <- shiny::Progress$new()
    on.exit(progress$close())
    progress$set(message = "Patience...", value = 0)
    for (i in from:to){
    for(mot in mots){
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
      url<-str_c("https://gallica.bnf.fr/SRU?operation=searchRetrieve&exactSearch=true&maximumRecords=1&page=1&collapsing=false&version=1.2&query=text%20all%20%22",mot,"%22%20%20and%20(dc.type%20all%20%22fascicule%22)%20and%20(gallicapublication_date%3E=%22",beginning,"%22%20and%20gallicapublication_date%3C=%22",end,"%22)%20sortby%20dc.date/sort.ascending&suggest=10&keywords=",mot)
      ngram<-as.character(read_xml(url))
      a<-str_extract(str_extract(ngram,"numberOfRecordsDecollapser&gt;+[:digit:]+"),"[:digit:]+")
      url_base<-str_c("https://gallica.bnf.fr/SRU?operation=searchRetrieve&exactSearch=true&maximumRecords=1&page=1&collapsing=false&version=1.2&query=(dc.type%20all%20%22fascicule%22)%20and%20(gallicapublication_date%3E=%22",beginning,"%22%20and%20gallicapublication_date%3C=%22",end,"%22)&suggest=10&keywords=")
      ngram_base<-as.character(read_xml(url_base))
      b<-str_extract(str_extract(ngram_base,"numberOfRecordsDecollapser&gt;+[:digit:]+"),"[:digit:]+")
      tableau[nrow(tableau)+1,] = NA
      date=y
      if(resolution=="Mois"){date = paste(y,z,sep="/")}
      tableau[nrow(tableau),]<-c(date,a,b,mot)
      }
    }
    progress$inc(1/(to-from), detail = paste("Gallicagram ratisse l'an", i))
    }
  colnames(tableau)<-c("date","nb_temp","base_temp","mot")
  format = "%Y"
  if(resolution=="Mois"){format=paste(format,"%m",sep="/")}
  tableau.date = as.Date(as.character(tableau$date),format=format)
  tableau$nb_temp<-as.integer(tableau$nb_temp)
  tableau$base_temp<-as.integer(tableau$base_temp)
  tableau$ratio_temp<-tableau$nb_temp/tableau$base_temp
  mots = str_replace(mots,"%20"," ")
  data = list(tableau,paste(mots,collapse=","),resolution)
  names(data) = c("tableau","mot","resolution")
  return(data)}


ui <- navbarPage("Gallicagram",
   tabPanel("Graphique",fluidPage(),
    tags$head(
    tags$style(HTML(".shiny-output-error-validation{color: red;}"))),
    pageWithSidebar(headerPanel('Réglages'),
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
        checkboxInput("barplot", "Afficher la quantité de données", value = FALSE),
        ),
      
            mainPanel(plotlyOutput("plot"),
                      headerPanel(""),
                      plotlyOutput("plot1"),
         downloadButton('downloadData', 'Télécharger les données')))),
         tabPanel("Notice",shiny::includeMarkdown("Notice.md")),
         tabPanel("Corpus",plotlyOutput("corpus"))
      )
   


# Define server logic required to draw a histogram
server <- function(input, output){
  output$corpus = renderPlotly(Barplot())
   observeEvent(input$do,{
    datasetInput <- reactive({
        data$tableau})
    df = get_data(input$mot,input$beginning,input$end,input$resolution)
    output$plot <- renderPlotly({Plot(df,input)})
    if(input$barplot){
    output$plot1 <- renderPlotly({Plot1(df,input)})}
    output$downloadData <- downloadHandler(
      filename = function() {
        paste('data-', Sys.Date(), '.csv', sep='')
      },
      content = function(con) {
        write.csv(df$tableau, con)
      })
    })
  
  
}
Barplot <- function(){table<-read.csv("base_gallica.csv")
table$hovers = str_c(table$date,": N = ",table$base_temp)
plot2<-plot_ly(table, x=~date,y=~base_temp,text=~hovers,type='bar',hoverinfo="text")
Title = paste("<b>Répartition des numéros dans Gallica-presse<b>")
y <- list(title = "Nombre de numéros dans Gallica-presse",titlefont = 41)
x <- list(title = "Date",titlefont = 41)
plot2 = layout(plot2, yaxis = y, xaxis = x,title = Title)
plot2}

shinyApp(ui = ui, server = server)