library(shiny)
library(ggplot2)
library(plotly)
library(stringr)
library(xml2)

ui <- fluidPage(
   
   # Application title
   titlePanel("Réglages"),
   
   sidebarLayout(
      sidebarPanel(
        textInput("mot","ngram","Mendes-France"),
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
server <- function(input, output) {
  observeEvent(input$do,{
    mot = str_replace(input$mot," ","%20")
    if(input$resolution=="Année"){
      width = input$end-input$beginning
      span = 2/width + input$span*(width-2)/(10*width)
      tableau<-as.data.frame(matrix(nrow=0,ncol=3),stringsAsFactors = FALSE)
      progress <- shiny::Progress$new()
      on.exit(progress$close())
      progress$set(message = "Making plot", value = 0)
      for (i in input$beginning:input$end){
        y<-as.character(i)  
        url<-str_c("https://gallica.bnf.fr/SRU?operation=searchRetrieve&version=1.2&startRecord=1&maximumRecords=1&page=1collapsing=false&exactSearch=true&query=text%20adj%20%22",mot,"%22%20%20and%20(dc.type%20all%20%22fascicule%22)%20and%20(gallicapublication_date%3E=%22",y,"/01/01%22%20and%20gallicapublication_date%3C=%22",y,"/12/31%22)%20sortby%20dc.date/sort.ascending&suggest=10&keywords=",mot)
        ngram<-as.character(read_xml(url))
        a<-str_extract(str_extract(ngram,"numberOfRecordsDecollapser&gt;+[:digit:]+"),"[:digit:]+")
        url_base<-str_c("https://gallica.bnf.fr/SRU?operation=searchRetrieve&version=1.2&startRecord=1&maximumRecords=1&page=1collapsing=false&version=1.2&query=(dc.type%20all%20%22fascicule%22)%20and%20(gallicapublication_date%3E=%22",y,"/01/01%22%20and%20gallicapublication_date%3C=%22",y,"/12/31%22)&suggest=10&keywords=")
        ngram_base<-as.character(read_xml(url_base))
        b<-str_extract(str_extract(ngram_base,"numberOfRecordsDecollapser&gt;+[:digit:]+"),"[:digit:]+")
        tableau[nrow(tableau)+1,] = NA
        tableau[nrow(tableau),]<-c(i,a,b)
        progress$inc(1/(input$end-input$beginning), detail = paste("Gallicagram ratisse l'an", i))
      }
      
      colnames(tableau)<-c("date","nb_temp","base_temp")
      tableau$date<-as.integer(tableau$date)
      tableau$nb_temp<-as.integer(tableau$nb_temp)
      tableau$base_temp<-as.integer(tableau$base_temp)
      tableau$ratio_temp<-tableau$nb_temp/tableau$base_temp
      
      #####AFFICHAGE DU GRAPHE
      title = paste("Fréquence d'usage de l'expression '", mot,sep="")
      title=paste(title,"' (Gallica-Presse)",sep="")
      plot = plot_ly(tableau, x=~date,y=~ratio_temp,type='scatter',mode='line')
      output$plot <- renderPlotly({
        plot})
    }
   })
}

shinyApp(ui = ui, server = server)