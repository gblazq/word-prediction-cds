library(shiny)

# Define UI
shinyUI(
    navbarPage("",
    tabPanel("App",
    fluidPage(theme = "bootstrap.css",
    
    tags$head(
        tags$meta(name="viewport", content="width=devide-width")
    ),
    # Application title
    title = ("Word prediction"),
    
    fluidRow(
        column(width = 6, h1("Word prediction", align = "center", style = "font-size: 4em;"), offset = 3),
        style = "padding-top: 8%; padding-bottom: 1%;"),

    fluidRow(
        column(width = 6, textInput('sentence', '', ''), offset = 3,
               class="form-group-lg", style = "padding-bottom: 0.75%")
    ),
    
    fluidRow(
        column(width = 6, checkboxInput("threeOutputs", "Output three words", TRUE),
               offset = 3, align = "center", style="font-size: 1.5em;")    
    ),
    
    
    fluidRow(
        conditionalPanel(condition = "input.threeOutputs == true",
                         column(width = 2, textOutput('next_word_second'), align = "center", offset = 2,
                                style = "font-size: 2em;", class = "panel panel-primary"),
                         column(width = 2, textOutput('next_word_first'), align = "center", offset = 1,
                                style = "font-size: 2em;", class = "panel panel-success"),
                         column(width = 2, textOutput('next_word_third'), align = "center", offset = 1,
                                style = "font-size: 2em;", class = "panel panel-primary")),
        conditionalPanel(condition = "input.threeOutputs == false",
                         column(width = 4, textOutput('next_word_first2'), align = "center", offset = 4,
                                style = "font-size: 2em;", class = "panel panel-success")),
        style = "padding-top: 3%"),
    
    fluidRow(column(width=12, p("Guillermo Blázquez Cruz - 2015"), align="center"),
             style = "padding-top: 9%; color: #9C9C9C;"),
    fluidRow(column(width=12, p("Contact: guilleblazquez at gmail dot com"), align="center"),
             style = "color: #9C9C9C;"))),
    tabPanel("Help",
             fluidRow(
                 column(width=4, offset=4, h2("How does it work?"), style = "padding-top: 5%; padding-bottom: 0.5%; color: #00BC8C;"),
                 column(width=4, offset=4, p("Write a sentence and the app will predict the next word.
                                             You can choose between 1 or 3 predictions. 
                                             The most likely word will appear in the center inside a light green box.
                                             If you choose 3 predictions, the second and third will appear on the left and right boxes, respectively."),
                        align="left", style = "font-size: 1.5em;"),
                column(width=4, offset=4, h2("'On the fly' prediction"), style = "padding-top: 2%; padding-bottom: 0.5%; color: #00BC8C;"),
                column(width=4, offset=4, p("The app predicts as you type, finishing the word you are writing. When the space key is pressed, 
                                            it predicts the following word in the sentence."),
                    align="left", style = "font-size: 1.5em;"))
             )))
