library(shiny)
library(tidyverse)
source("function.R")
ui <- fluidPage(
  sidebarLayout(

# Side Panel --------------------------------------------------------------

  sidebarPanel(
    ## Header and  file upload
    h2('The uploaded data file'),
    fileInput('file', 'Choose info-file to upload',
              accept = c(
                'text/csv',
                'text/comma-separated-values',
                'text/tab-separated-values',
                'text/plain',
                '.csv',
                '.tsv'
              )
    ),
  ## Selection of header
    tags$hr(),
    checkboxInput('header', 'Header', TRUE),
  ## Action Buttons Updating 
  actionButton("run", "Run Analysis"),
  uiOutput("columns_df"),
  uiOutput("group_inp"),
  uiOutput("group_sub")
  ),

# Main Panel --------------------------------------------------------------
  mainPanel(
  tableOutput("eff"),
  plotOutput("fig")
  )

# End of UI ---------------------------------------------------------------
  )
)


# Server ------------------------------------------------------------------

server <- function(input, output, session) { # added session for updateSelectInput

  info <- reactive({
    inFile <- input$file
    # Instead # if (is.null(inFile)) ... use "req"
    req(inFile)

    # Changes in read.table 
    f <- read.csv(inFile$datapath, header = input$header)
    return(f)
  })
  
  
  
  
  running_analysis <- eventReactive(input$run, {
    df <- info()
    f <- df[df[[input$group]] %in% input$group_subs, c(input$columns, input$group)]
    #if(length(input$group_subs) == 2){
    invariance_eff(f, input$columns, input$group)
    #}else if(length(input$group_subs) > 2){
    #multi_group_eff(f, input$columns, input$group)
    #} else{
    #  "ERROR in the running analysis function"
    #}
    
  })
  
  running_analysis <- eventReactive(input$run, {
    df <- info()
    f <- df[df[[input$group]] %in% input$group_subs, c(input$columns, input$group)]
    if(length(input$group_subs) == 2){
    invariance_eff(f, input$columns, input$group)
    }else if(length(input$group_subs) > 2){
    multi_group_eff(f, input$group, input$columns)
    }else{
      "ERROR in the running analysis function"
    }
    
     
    
  })


  output$columns_df <- renderUI({
    checkboxGroupInput("columns", "choose variable:", choices = names(info()))
  })
  
  output$group_inp <- renderUI({
    selectInput("group","Select Grouping Variable", choices = names(info()))
  })
  
  output$group_sub <- renderUI({
   df <- info()
   groups_name <- unique(df[[input$group]])
   checkboxGroupInput("group_subs", "choose variable:", choices = groups_name) 
  })
  
  output$eff <- renderTable({
    #### Start at 0 for subgroups
    #### ALLOW DIFFERENT FILE FORMATS SAV !
    #### 
    df <- info()
    eff_df <- running_analysis()
    if(length(eff_df) == 2){
      eff_df[1]
    }else{
      eff_df
    }
    
  })

output$fig <- renderPlot({
  eff_df <- running_analysis()
  if(length(eff_df) == 2){
    eff_df$average %>%
    ggplot() +
    aes(x = average.item, y = average.av) +
    geom_bar(stat = "identity") +
    geom_errorbar(aes(ymin = average.l_ci, ymax = average.h_ci)) +
    facet_wrap(~average.eff)
  }else{
    gathered_df <- gather(eff_df, key = "effsize", value = "value", -items)
    ggplot(gathered_df) +
    aes(x = items, y = value) +
    geom_bar(stat = "identity") +
    facet_wrap(~effsize)
  }
  
    #### Start at 0 for subgroups
    #### ALLOW DIFFERENT FILE FORMATS SAV !
    #### 
  })  
  ### Debug Stuff
  session$onSessionEnded(stopApp)
  
  }
shinyApp(ui, server)