rm(list=ls())

# ----- NOTE -----
# Try plot differences between 2 templates

# ----- Library ----- 
library(shiny)
library(ggplot2)
library(gridExtra)

max_upload_size <- 20 # Maximum size of upload file (Mb)
options(shiny.maxRequestSize = max_upload_size*1024^2) 

# ----- UI -----
ui <- fluidPage(
    titlePanel('Comparison between 2 templates'),
    sidebarLayout(
        sidebarPanel(
            width = 3,
            fileInput('dfA', 'Choose file A to upload',
                      accept = c('.csv')),
            # uiOutput(outputId = 'ui_datapathA'),
            fileInput('dfB', 'Choose file B to upload',
                      accept = c('.csv')),
            # uiOutput(outputId = 'ui_datapathB'),
            uiOutput(outputId = 'ui_burden'),
            fluidRow(
                column(4, actionButton("template", "Update Template")),
                column(3, uiOutput(outputId = 'ui_plot')),
                column(5, uiOutput(outputId = 'ui_export'))
            ),
            hr(),
            h3('How to use'),
            p('1. Choose 2 templates you want to compare'),
            p('2. Click', strong('Update Template'), 'button'),
            p('3. Wait for loading time ...'),
            p('4. Choose', strong('country'), 'and', strong('category'), 'you want to compare'),
            p('5. Click', strong('Plot Graph'), 'button to plot'),
            p('6. To download figures, click', strong('Export to TIF'), 'button'),
            hr(),
            h3('Description'),
            p('- The first 2 figures are the estimated burden of 2 templates over time'),
            p('- The 3rd figure is the difference of the burden of template A and the burden of template B over time'),
            p('- The last figure is the portion of the diferrence over time, 
              calculated by taking the absolute value of the difference between burden of 2 templates, 
              then divided by the burden of template B')
        ),
        mainPanel(
            fluidRow(
                column(6,
                       plotOutput(outputId = 'uip1')
                ),
                column(6,
                       plotOutput(outputId = 'uip2')
                )
            ),
            plotOutput(outputId = 'uip3'),
            plotOutput(outputId = 'uip4')
        )
    )
)

server <- function(input, output, session) {
    # Read file A after clicking the button update template
    dataA <- eventReactive(input$template, {
        dfA <- read.csv(input$dfA$datapath)
        return(dfA)
    })
    
    # Read file B after clicking the button update template
    dataB <- eventReactive(input$template, {
        dfB <- read.csv(input$dfB$datapath)
        return(dfB)
    })
    
    # # Show the directory path of file A after uploading file A
    # observeEvent(input$dfA,{
    #     output$ui_datapathA <- renderUI({
    #         tagList(verbatimTextOutput("datapathA"))
    #     })
    # })
    # output$datapathA <- renderPrint({
    #     cat(input$dfA$datapath)
    # })
    
    # # Show the directory path of file B after uploading file B
    # observeEvent(input$dfB,{
    #     output$ui_datapathB <- renderUI({
    #         tagList(verbatimTextOutput("datapathB"))
    #     })
    # })
    # output$datapathB <- renderPrint({
    #     cat(input$dfB$datapath)
    # })
    
    # Initialize other UI when update file A and file B
    observeEvent({input$dfA 
        input$dfB}, {
            output$ui_burden <- renderUI({})
            output$ui_plot <- renderUI({})
            output$ui_export <- renderUI({})
            output$uip1 <- renderPlot({})
            output$uip2 <- renderPlot({})
            output$uip3 <- renderPlot({})
            output$uip4 <- renderPlot({})
        })
    
    # Create UI when clicking update template button
    observeEvent(input$template,{
        progress <- shiny::Progress$new()
        on.exit(progress$close())
        progress$set(message = "Reading file", value = 0.5)
        
        A <- dataA()
        B <- dataB()
        country.A <- unique(A$country)
        country.B <- unique(B$country)
        country.same <- country.A[country.A %in% country.B]
        output$ui_burden <- renderUI({
            tagList(
                selectInput('country', 'Choose country:', choices = country.same),
                radioButtons(inputId  = 'burden',
                             label = 'Choose category',
                             choices  = c('Cases', 'Deaths', 'Cohort_Size', 'DALYs'),
                             selected = 'Cases')
            )
        })
        output$ui_plot <- renderUI({
            tagList(actionButton("plot", "Plot Graph"))
        })
        
        progress$set(1, detail = "Done")
    })
    
    list.plots <- reactiveValues(data = NULL)
    
    observeEvent(input$plot,{
        progress <- shiny::Progress$new()
        on.exit(progress$close())
        progress$set(message = "Plotting", value = 0.5)
        A <- isolate(dataA())
        B <- isolate(dataB())
        A <- A[order(A$country, A$age, A$year), ]
        B <- B[order(B$country, B$age, B$year), ]
        country_name <- input$country
        
        A.Country <- A[which(A$country == country_name),]
        B.Country <- B[which(B$country == country_name),]
        B.Country <- B.Country[, colnames(A.Country)]
        RawDif.Country <- A.Country
        RawDif.Country[,c(6:9)] <- A.Country[,c(6:9)] - B.Country[,c(6:9)]
        progress$set(0.75, detail = "Processing")
        year_vec <- unique(RawDif.Country$year)
        # cohort <- rep(0, length(year_vec))
        quantotalcases <- rep(0, length(year_vec))
        quantotaldeaths <- rep(0, length(year_vec))
        quantotaldalys <- rep(0, length(year_vec))
        quantotalcohort <- rep(0, length(year_vec))
        dif_cases <- rep(0, length(year_vec))
        dif_deaths <- rep(0, length(year_vec))
        dif_cohort <- rep(0, length(year_vec))
        dif_dalys <- rep(0, length(year_vec))
        for (idx_year in 1 : length(year_vec)){
            select_year <- year_vec[idx_year]
            idx_row <- which(RawDif.Country$year == select_year)
            quantotalcases[idx_year] <- sum(abs(B.Country$cases[idx_row]))
            quantotaldeaths[idx_year] <- sum(abs(B.Country$deaths[idx_row]))
            quantotalcohort[idx_year] <- sum(abs(B.Country$cohort_size[idx_row]))
            quantotaldalys[idx_year] <- sum(abs(B.Country$dalys[idx_row]))
            dif_cohort[idx_year] <- sum(abs(RawDif.Country$cohort_size[idx_row]))
            dif_cases[idx_year] <- sum(abs(RawDif.Country$cases[idx_row]))
            dif_deaths[idx_year] <- sum(abs(RawDif.Country$deaths[idx_row]))
            dif_dalys[idx_year] <- sum(abs(RawDif.Country$dalys[idx_row]))
        }
        temp <- data.frame(year = year_vec, country = country_name, 
                           dif_cohort = dif_cohort, dif_deaths = dif_deaths, dif_cases = dif_cases, dif_dalys = dif_dalys, 
                           portion_dif_cases = dif_cases / quantotalcases * 100, portion_dif_deaths = dif_deaths / quantotaldeaths * 100,
                           portion_dif_cohort = dif_cohort / quantotalcohort * 100, portion_dif_dalys = dif_dalys / quantotaldalys * 100)
        
        # fnA <- substr(input$dfA, start = 1, stop = nchar(input$dfA) - 4)
        # fnB <- substr(input$dfB, start = 1, stop = nchar(input$dfB) - 4)
        fnA <- 'File A'
        fnB <- 'File B'
        
        if (input$burden == 'Cases'){
            p1 <- ggplot(data = A.Country, aes(x = year, y = cases, fill = age)) + geom_col() + 
                labs(x = "Year", y = 'Cases', 
                     title = paste0(fnA, ' - ', country_name)) + 
                theme(plot.title = element_text(hjust = 0.5), legend.position = 'none')
            
            p2 <- ggplot(data = B.Country, aes(x = year, y = cases, fill = age)) + geom_col() + 
                labs(x = "Year", y = 'Cases', 
                     title = paste0(fnB, ' - ', country_name)) + 
                theme(plot.title = element_text(hjust = 0.5), legend.position = 'none')
            
            p3 <- ggplot(data = RawDif.Country, aes(x = year, y = cases, fill = age)) + geom_col() + 
                labs(x = "Year", y = 'Cases', 
                     title = paste0('Dif - ', country_name)) + 
                theme(plot.title = element_text(hjust = 0.5), legend.position = 'right')
            
            p4 <- ggplot(data = temp, aes(x = year, y = portion_dif_cases)) + geom_line() + geom_point(size = 0.5) + 
                labs(x = "Year", y = 'Portion Dif Cases (%)', 
                     title = paste0('Portion Dif - ', country_name)) + 
                theme(plot.title = element_text(hjust = 0.5))
        }
        if (input$burden == 'Deaths'){
            p1 <- ggplot(data = A.Country, aes(x = year, y = deaths, fill = age)) + geom_col() + 
                labs(x = "Year", y = 'Deaths', 
                     title = paste0(fnA, ' - ', country_name)) + 
                theme(plot.title = element_text(hjust = 0.5), legend.position = 'none')
            
            p2 <- ggplot(data = B.Country, aes(x = year, y = deaths, fill = age)) + geom_col() + 
                labs(x = "Year", y = 'Deaths', 
                     title = paste0(fnB, ' - ', country_name)) + 
                theme(plot.title = element_text(hjust = 0.5), legend.position = 'none')
            
            p3 <- ggplot(data = RawDif.Country, aes(x = year, y = deaths, fill = age)) + geom_col() + 
                labs(x = "Year", y = 'Deaths', 
                     title = paste0('Dif - ', country_name)) + 
                theme(plot.title = element_text(hjust = 0.5), legend.position = 'right')
            
            p4 <- ggplot(data = temp, aes(x = year, y = portion_dif_deaths)) + geom_line() + geom_point(size = 0.5) + 
                labs(x = "Year", y = 'Portion Dif Deaths (%)', 
                     title = paste0('Portion Dif - ', country_name)) + 
                theme(plot.title = element_text(hjust = 0.5))
        }
        if (input$burden == 'Cohort_Size'){
            p1 <- ggplot(data = A.Country, aes(x = year, y = cohort_size, fill = age)) + geom_col() + 
                labs(x = "Year", y = 'People', 
                     title = paste0(fnA, ' - ', country_name)) + 
                theme(plot.title = element_text(hjust = 0.5), legend.position = 'none')
            
            p2 <- ggplot(data = B.Country, aes(x = year, y = cohort_size, fill = age)) + geom_col() + 
                labs(x = "Year", y = 'People', 
                     title = paste0(fnB, ' - ', country_name)) + 
                theme(plot.title = element_text(hjust = 0.5), legend.position = 'none')
            
            p3 <- ggplot(data = RawDif.Country, aes(x = year, y = cohort_size, fill = age)) + geom_col() + 
                labs(x = "Year", y = 'People', 
                     title = paste0('Dif - ', country_name)) + 
                theme(plot.title = element_text(hjust = 0.5), legend.position = 'right')
            
            p4 <- ggplot(data = temp, aes(x = year, y = portion_dif_cohort)) + geom_line() + geom_point(size = 0.5) + 
                labs(x = "Year", y = 'Portion Dif Cohort (%)', 
                     title = paste0('Portion Dif - ', country_name)) + 
                theme(plot.title = element_text(hjust = 0.5))
        }
        if (input$burden == 'DALYs'){
            p1 <- ggplot(data = A.Country, aes(x = year, y = dalys, fill = age)) + geom_col() + 
                labs(x = "Year", y = 'DALYs', 
                     title = paste0(fnA, ' - ', country_name)) + 
                theme(plot.title = element_text(hjust = 0.5), legend.position = 'none')
            
            p2 <- ggplot(data = B.Country, aes(x = year, y = dalys, fill = age)) + geom_col() + 
                labs(x = "Year", y = 'DALYs', 
                     title = paste0(fnB, ' - ', country_name)) + 
                theme(plot.title = element_text(hjust = 0.5), legend.position = 'none')
            
            p3 <- ggplot(data = RawDif.Country, aes(x = year, y = dalys, fill = age)) + geom_col() + 
                labs(x = "Year", y = 'DALYs', 
                     title = paste0('Dif - ', country_name)) + 
                theme(plot.title = element_text(hjust = 0.5), legend.position = 'right')
            
            p4 <- ggplot(data = temp, aes(x = year, y = portion_dif_dalys)) + geom_line() + geom_point(size = 0.5) + 
                labs(x = "Year", y = 'Portion Dif DALYs (%)', 
                     title = paste0('Portion Dif - ', country_name)) + 
                theme(plot.title = element_text(hjust = 0.5))
        }
        
        p1 <- p1 + theme(axis.text = element_text(size=6), axis.title = element_text(size = 6), plot.title = element_text(size = 6))
        p2 <- p2 + theme(axis.text = element_text(size=6), axis.title = element_text(size = 6), plot.title = element_text(size = 6))
        p3 <- p3 + theme(axis.text = element_text(size=6), axis.title = element_text(size = 6), plot.title = element_text(size = 6))
        p4 <- p4 + theme(axis.text = element_text(size=6), axis.title = element_text(size = 6), plot.title = element_text(size = 6))
        
        list.plots$data <- list(p1, p2, p3, p4)
        
        p1 <- p1 + theme(axis.text = element_text(size=12), axis.title = element_text(size = 14), plot.title = element_text(size = 16))
        p2 <- p2 + theme(axis.text = element_text(size=12), axis.title = element_text(size = 14), plot.title = element_text(size = 16))
        p3 <- p3 + theme(axis.text = element_text(size=12), axis.title = element_text(size = 14), plot.title = element_text(size = 16))
        p4 <- p4 + theme(axis.text = element_text(size=12), axis.title = element_text(size = 14), plot.title = element_text(size = 16))
        
        output$uip1 <- renderPlot({p1})
        output$uip2 <- renderPlot({p2})
        output$uip3 <- renderPlot({p3})
        output$uip4 <- renderPlot({p4})
        output$ui_export <- renderUI({
            tagList(downloadButton("export", "Export to TIF"))
        })
        showNotification("Plotting ... Please wait ...", type = 'message')
        progress$set(1, detail = "Done")
    })
    
    plotInput = function() {
        dummy <- list.plots$data
        grid.arrange(
            grobs = dummy,
            widths = c(2, 2, 3),
            layout_matrix = rbind(c(1, 2, 3), cbind(4, 4, 4))
        )
    }
    
    output$export <- downloadHandler(
        filename = function(){
            # paste(substr(input$dfA, start = 1, stop = nchar(input$dfA) - 4), '_',
            #       substr(input$dfB, start = 1, stop = nchar(input$dfB) - 4), '_',
            #       input$burden, '.tif', sep = '')
            
            # sub function is to remove the extensive of files
            paste(sub(".csv$", "", basename(input$dfA$name)), '_',
                  sub(".csv$", "", basename(input$dfB$name)), '_',
                  input$burden, '.tif', sep = '')
        },
        content = function(file) {
            ggsave(file, plot = plotInput(), device = 'tiff')
        }
    )
}

shinyApp(ui, server)