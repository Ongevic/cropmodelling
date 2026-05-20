library(shiny)
library(leaflet)
library(tidyverse)
library(dplyr)
library(sf)
library(tigris)
library(ggplot2)
library(scales) 
library(shinydashboard)
library(DT) #for table display
#library(geomtextpath) #to align text along x axis intercepting lines for phenology
global_size = 15 
# Get Florida shapefile

#comment out setwd before deploying online!
#setwd("C:/Users/alwin/OneDrive - University of Florida/ABE_Hemp_DSS_PhD/hemp_r-shiny_webapp/Hemp-DSS-Dashboard/hemp_dss_dashboard")
#setwd("D:/OneDrive - University of Florida/ABE_Hemp_DSS_PhD/hemp_r-shiny_webapp/Hemp-DSS-Dashboard/hemp_dss_dashboard")

color_palette <- palette.colors(palette = "Okabe-Ito")
color_palette

# Simulate some data (replace with your actual data)
set.seed(123) 
fl_counties <- tigris::counties(state = "FL")  # Get county boundaries
county_data <- fl_counties %>% 
  mutate(
    population = round(runif(nrow(fl_counties), 10000, 1000000)),
    income = round(runif(nrow(fl_counties), 30000, 80000))
  )

location_df <- data.frame(
  location = c("Jay (WFREC)", "Citra (PSREU)", "Live Oak (NFREC)", "Apopka (MREC)", "Belle Glade (EREC)", "Homestead (TREC)", "Balm (GCREC)"),
  latitude = c(  30.6,    29.4,              30.3,   28.6,   26.7,   25.5,   27.76),
  longitude = c(-87.1,   -82.2,             -82.9,  -81.5,  -80.6,  -80.5,  -82.22)
)
date_breaks <- as.Date(c("2024-03-01", "2024-03-15", "2024-04-01", "2024-04-15",
                         "2024-05-01", "2024-05-15", "2024-06-01", "2024-06-15",
                         "2024-06-30"))
planting_date_df <- data.frame(
  location = c("Jay (WFREC)", "Jay (WFREC)", "Jay (WFREC)","Jay (WFREC)", "Jay (WFREC)","Jay (WFREC)","Jay (WFREC)", "Jay (WFREC)","Jay (WFREC)",
               "Citra (PSREU)", "Citra (PSREU)", "Citra (PSREU)","Citra (PSREU)", "Citra (PSREU)","Citra (PSREU)","Citra (PSREU)", "Citra (PSREU)","Citra (PSREU)",
               "Live Oak (NFREC)", "Live Oak (NFREC)", "Live Oak (NFREC)","Live Oak (NFREC)", "Live Oak (NFREC)","Live Oak (NFREC)","Live Oak (NFREC)", "Live Oak (NFREC)","Live Oak (NFREC)",
               "Apopka (MREC)", "Apopka (MREC)", "Apopka (MREC)","Apopka (MREC)", "Apopka (MREC)","Apopka (MREC)","Apopka (MREC)", "Apopka (MREC)","Apopka (MREC)",
               "Belle Glade (EREC)", "Belle Glade (EREC)", "Belle Glade (EREC)","Belle Glade (EREC)", "Belle Glade (EREC)","Belle Glade (EREC)","Belle Glade (EREC)", "Belle Glade (EREC)","Belle Glade (EREC)",
               "Homestead (TREC)", "Homestead (TREC)", "Homestead (TREC)","Homestead (TREC)", "Homestead (TREC)","Homestead (TREC)","Homestead (TREC)", "Homestead (TREC)","Homestead (TREC)",
               "Balm (GCREC)", "Balm (GCREC)", "Balm (GCREC)","Balm (GCREC)", "Balm (GCREC)","Balm (GCREC)","Balm (GCREC)", "Balm (GCREC)","Balm (GCREC)",
               "Jay (WFREC)", "Jay (WFREC)", "Jay (WFREC)","Jay (WFREC)", "Jay (WFREC)","Jay (WFREC)","Jay (WFREC)", "Jay (WFREC)","Jay (WFREC)",  #start NWG
               "Citra (PSREU)", "Citra (PSREU)", "Citra (PSREU)","Citra (PSREU)", "Citra (PSREU)","Citra (PSREU)","Citra (PSREU)", "Citra (PSREU)","Citra (PSREU)",
               "Live Oak (NFREC)", "Live Oak (NFREC)", "Live Oak (NFREC)","Live Oak (NFREC)", "Live Oak (NFREC)","Live Oak (NFREC)","Live Oak (NFREC)", "Live Oak (NFREC)","Live Oak (NFREC)",
               "Apopka (MREC)", "Apopka (MREC)", "Apopka (MREC)","Apopka (MREC)", "Apopka (MREC)","Apopka (MREC)","Apopka (MREC)", "Apopka (MREC)","Apopka (MREC)",
               "Belle Glade (EREC)", "Belle Glade (EREC)", "Belle Glade (EREC)","Belle Glade (EREC)", "Belle Glade (EREC)","Belle Glade (EREC)","Belle Glade (EREC)", "Belle Glade (EREC)","Belle Glade (EREC)",
               "Homestead (TREC)", "Homestead (TREC)", "Homestead (TREC)","Homestead (TREC)", "Homestead (TREC)","Homestead (TREC)","Homestead (TREC)", "Homestead (TREC)","Homestead (TREC)",
               "Balm (GCREC)", "Balm (GCREC)", "Balm (GCREC)","Balm (GCREC)", "Balm (GCREC)","Balm (GCREC)","Balm (GCREC)", "Balm (GCREC)","Balm (GCREC)"),
  cultivar = c("IH Williams", "IH Williams", "IH Williams","IH Williams", "IH Williams","IH Williams","IH Williams", "IH Williams","IH Williams",
               "IH Williams", "IH Williams", "IH Williams","IH Williams", "IH Williams","IH Williams","IH Williams", "IH Williams","IH Williams",
               "IH Williams", "IH Williams", "IH Williams","IH Williams", "IH Williams","IH Williams","IH Williams", "IH Williams","IH Williams",
               "IH Williams", "IH Williams", "IH Williams","IH Williams", "IH Williams","IH Williams","IH Williams", "IH Williams","IH Williams",
               "IH Williams", "IH Williams", "IH Williams","IH Williams", "IH Williams","IH Williams","IH Williams", "IH Williams","IH Williams",
               "IH Williams", "IH Williams", "IH Williams","IH Williams", "IH Williams","IH Williams","IH Williams", "IH Williams","IH Williams",
               "IH Williams", "IH Williams", "IH Williams","IH Williams", "IH Williams","IH Williams","IH Williams", "IH Williams","IH Williams",
               "NWG 2730", "NWG 2730", "NWG 2730","NWG 2730", "NWG 2730","NWG 2730","NWG 2730", "NWG 2730","NWG 2730",  #start NWG
               "NWG 2730", "NWG 2730", "NWG 2730","NWG 2730", "NWG 2730","NWG 2730","NWG 2730", "NWG 2730","NWG 2730",
               "NWG 2730", "NWG 2730", "NWG 2730","NWG 2730", "NWG 2730","NWG 2730","NWG 2730", "NWG 2730","NWG 2730",
               "NWG 2730", "NWG 2730", "NWG 2730","NWG 2730", "NWG 2730","NWG 2730","NWG 2730", "NWG 2730","NWG 2730",
               "NWG 2730", "NWG 2730", "NWG 2730","NWG 2730", "NWG 2730","NWG 2730","NWG 2730", "NWG 2730","NWG 2730",
               "NWG 2730", "NWG 2730", "NWG 2730","NWG 2730", "NWG 2730","NWG 2730","NWG 2730", "NWG 2730","NWG 2730",
               "NWG 2730", "NWG 2730", "NWG 2730","NWG 2730", "NWG 2730","NWG 2730","NWG 2730", "NWG 2730","NWG 2730"),
  planting = c("01-Mar", "15-Mar", "01-Apr","15-Apr", "01-May","15-May","01-Jun", "15-Jun","30-Jun",
               "01-Mar", "15-Mar", "01-Apr","15-Apr", "01-May","15-May","01-Jun", "15-Jun","30-Jun",
               "01-Mar", "15-Mar", "01-Apr","15-Apr", "01-May","15-May","01-Jun", "15-Jun","30-Jun",
               "01-Mar", "15-Mar", "01-Apr","15-Apr", "01-May","15-May","01-Jun", "15-Jun","30-Jun",
               "01-Mar", "15-Mar", "01-Apr","15-Apr", "01-May","15-May","01-Jun", "15-Jun","30-Jun",
               "01-Mar", "15-Mar", "01-Apr","15-Apr", "01-May","15-May","01-Jun", "15-Jun","30-Jun",
               "01-Mar", "15-Mar", "01-Apr","15-Apr", "01-May","15-May","01-Jun", "15-Jun","30-Jun",
               "01-Mar", "15-Mar", "01-Apr","15-Apr", "01-May","15-May","01-Jun", "15-Jun","30-Jun",
               "01-Mar", "15-Mar", "01-Apr","15-Apr", "01-May","15-May","01-Jun", "15-Jun","30-Jun",  #start NWG
               "01-Mar", "15-Mar", "01-Apr","15-Apr", "01-May","15-May","01-Jun", "15-Jun","30-Jun",
               "01-Mar", "15-Mar", "01-Apr","15-Apr", "01-May","15-May","01-Jun", "15-Jun","30-Jun",
               "01-Mar", "15-Mar", "01-Apr","15-Apr", "01-May","15-May","01-Jun", "15-Jun","30-Jun",
               "01-Mar", "15-Mar", "01-Apr","15-Apr", "01-May","15-May","01-Jun", "15-Jun","30-Jun",
               "01-Mar", "15-Mar", "01-Apr","15-Apr", "01-May","15-May","01-Jun", "15-Jun","30-Jun"),
  planting_DAS =  c(60,  75, 90,105,120,135,150,165,180,
                    60,  75, 90,105,120,135,150,165,180,
                    60,  75, 90,105,120,135,150,165,180,
                    60,  75, 90,105,120,135,150,165,180,
                    60,  75, 90,105,120,135,150,165,180,
                    60,  75, 90,105,120,135,150,165,180,
                    60,  75, 90,105,120,135,150,165,180,
                    60,  75, 90,105,120,135,150,165,180, #start NWG, Jay (WFREC)
                    60,  75, 90,105,120,135,150,165,180, #Live Oak (NFREC)
                    60,  75, 90,105,120,135,150,165,180, #Citra (PSREU)
                    60,  75, 90,105,120,135,150,165,180, #Apopka (MREC)
                    60,  75, 90,105,120,135,150,165,180, #Belle Glade (EREC)
                    60,  75, 90,105,120,135,150,165,180, #Homestead (TREC)
                    60,  75, 90,105,120,135,150,165,180),#Balm (GCREC)
  flowering_DAP = c(58,52,47,43,45,53,56,51,44, #IH Williams, Jay (WFREC)
                    57,53,48,45,47,54,56,52,45, #Live Oak (NFREC)
                    53,50,44,42,42,47,51,48,42, #Citra (PSREU)
                    47,44,41,39,38,43,48,46,41, #Apopka (MREC)
                    45,43,40,38,37,38,41,41,38, #Belle Glade (EREC)
                    42,41,38,37,36,36,38,38,36, #Homestead (TREC)
                    48,46,42,40,39,41,45,44,40, #Balm (GCREC)
                    52,47,42,38,35,34,34,34,34, #start NWG, Jay (WFREC)
                    51,48,42,39,37,36,36,36,35, #Live Oak (NFREC)
                    47,44,40,37,34,34,34,34,34, #Citra (PSREU)
                    42,39,36,34,33,33,34,34,33, #Apopka (MREC)
                    40,38,35,34,32,32,32,32,32, #Belle Glade (EREC)
                    37,36,34,32,31,31,31,32,32, #Homestead (TREC)
                    37,36,34,32,31,31,31,32,32),#Balm (GCREC)
  maturity_DAP =  c(144,138,132,128,130,137,140,137,131,  #IH Williams, Jay (WFREC)
                    142,138,132,129,130,137,139,135,128,  #Live Oak (NFREC)
                    137,134,129,127,127,133,136,133,128,  #Citra (PSREU)
                    129,127,124,123,124,128,132,130,126,  #Apopka (MREC)
                    131,128,124,123,122,123,126,125,123,  #Belle Glade (EREC)
                    124,123,121,120,120,121,123,123,121,  #Homestead (TREC)
                    129,126,123,122,122,125,128,126,122,  #Balm (GCREC)
                    105,99,93,89,86,85,85,86,85,  #start NWG, Jay (WFREC)
                    104,100,94,90,88,87,87,87,86, #Live Oak (NFREC)
                    101,97,91,88,86,85,86,86,85, #Citra (PSREU)
                    95,91,87,85,84,84,85,85,85, #Apopka (MREC)
                    92,90,86,85,83,82,83,83,83, #Belle Glade (EREC)
                    89,87,84,83,82,82,82,83,83, #Homestead (TREC)
                    89,87,84,83,82,82,82,83,83) #Balm (GCREC)
)

ui <- dashboardPage(
  dashboardHeader(title = "Florida Hemp DSS"),
  dashboardSidebar(
    width = 425,
      fluidRow(
      style = "font-size: 16px;", # Adjust the size as needed
      column(width = 6, selectInput("location", "Select Location:", choices = NULL)),
      column(width = 6, selectInput("cultivar", "Select Cultivar:", choices = NULL))
    ),
    leafletOutput("florida_map", width = "100%", height = "385px")
  ),
  dashboardBody(
    style = "font-size: 16px;", # Adjust the size as needed
    tabsetPanel(
      #### Tab: Potential Production ####
      tabPanel("Potential Production",
               style = "font-size: 16px;", # Adjust the size as needed
               #h2("Content for Tab 1"),
               fluidRow(
                 #br(),
                 column(width = 4, selectInput("density_categorized", "Planting Density:", choices = NULL)),
                 column(width = 4, selectInput("nitrogen_categorized", "Fertilizer:", choices = NULL)),
                 column(width = 4, selectInput("harvest_categorized", "Harvest Time:", choices = NULL)),
                 br(),
                 #column(width = 6, sliderInput("lowThreshold", "Low Yield Threshold (Kg/ha)", min = 0, max = 10000, value = 7000)),
                 #column(width = 6, sliderInput("highThreshold", "High Yield Threshold (Kg/ha)", min = 0, max = 10000, value = 9000))
                 #new dynamic column
                 column(width = 6, uiOutput("lowThresholdUI")),  
                 column(width = 6, uiOutput("highThresholdUI")) 
               ),
               plotOutput("barPlot")
               #plotOutput("florida_hemp_filtered_biomass_relative", height = 350),
               #br(),
               #plotOutput("florida_hemp_filtered_GWAD_relative", height = 350)
               # Add your input elements (e.g., sliders, text boxes) and outputs (e.g., plots, tables) here
      ),
      #### Tab: Phenology and Planting Date Suitability ####
      tabPanel("Phenology and Planting Date Suitability",
               style = "font-size: 16px;height: 90vh; overflow-y: auto;", # Adjust the size as needed
               #h2("Content for Tab 2"),
               # Input: Select Year
               fluidRow(
                 #br(),
                 #column(width = 4, selectInput("YEAR", "Year:", choices = NULL)),
                 column(width = 4, selectInput("planting", "Planting Date:", choices = NULL))#,
                 #column(width = 4, selectInput("density2", "Planting Density (per m2):", choices = NULL)),
                 #column(width = 4, selectInput("nitrogen2", "Fertilizer Amount (kg N per ha):", choices = NULL))
               ),
               verbatimTextOutput("phenology_info"),
               #textOutput("general_info"),
               #verbatimTextOutput("general_info2"),
               #verbatimTextOutput("planting_date"),  
               #verbatimTextOutput("flowering_date"),  
               #verbatimTextOutput("grain_maturity_date"),  
               #textOutput("general_info2"),
               #textOutput("planting_date"),
               #textOutput("flowering_date"),
               #textOutput("grain_maturity_date"),
               plotOutput("individual_experiment_biomass", height = 230),
               br(),
               #textOutput("temperature_stress"),
               verbatimTextOutput("temperature_stress"),
               plotOutput("individual_experiment_weather_tmin_tmax", height = 230),
               plotOutput("individual_experiment_weather_precipitation", height = 230),
               #plotOutput("individual_experiment_weather_precipitation2", height = 230),
               #br(),
               plotOutput("individual_experiment_weather_avg_temperature", height = 230),
               br(),
               plotOutput("individual_experiment_weather_daylength", height = 230),
               br()
               #plotOutput("datePlot", height = 270)
               #plotOutput("individual_experiment_phenology", height = 300)
               # Add input and output elements specific to Tab 2
      ),
      #### Tab: Background Information ####
      tabPanel("Background Information",
               style = "font-size: 16px;height: 90vh; overflow-y: auto;", # Adjust the size as needed
               br(),
               verbatimTextOutput("simulation_information")
               #textOutput("simulation_information"),
               #br(),
               #DT::dataTableOutput("background_information")  # Output the table
               # Add your input elements (e.g., sliders, text boxes) and outputs (e.g., plots, tables) here
      )
      #### Tab: (old) ####
      #tabPanel("(old)",
      #         style = "font-size: 16px;", # Adjust the size as needed
      #         #h2("Content for Tab 1"),
      #         fluidRow(
      #           #br(),
      #           column(width = 4, selectInput("density", "Planting Density:", choices = NULL)),
      #           column(width = 4, selectInput("nitrogen", "Fertilizer:", choices = NULL)),
      #           column(width = 4, selectInput("harvest", "Harvest Time:", choices = NULL))
      #         ),
      #         plotOutput("florida_hemp_filtered_biomass", height = 350),
      #         br(),
      #         plotOutput("florida_hemp_filtered_GWAD", height = 350)
      #         # Add your input elements (e.g., sliders, text boxes) and outputs (e.g., plots, tables) here
      #)
    )
  )
)

server <- function(input, output,session) {
  # Download and read Florida shapefile from tigris (reactive)
  florida_shape <- reactive({
    states(cb = TRUE) %>% 
      filter(NAME == "Florida") %>%
      st_transform(crs = 4326)  # Transform to WGS84 if needed
  })
#  # Read the CSV file reactively
#  florida_data <- reactive({
#    read_csv("florida_data.csv")
#  })
  # Read the CSV file reactively
  florida_data <- reactive({
    read_csv("summary_combined_subset.csv")
  })
#  florida_data_categorized <- reactive({
#    read_csv("plantgro_combined_full_subset_backup.csv")
#  })
  florida_data_individual_years <- reactive({
    read_csv("tops_weight_summary_subset_all_sites.csv") # %>%
     #  drop_na()
  })
  #PLANTGRO TIMESERIES
  plantgro_data <- reactive({
    read_csv("plantgro_for_biomass_development_curve_subset.csv")
  })
  weather_data <- reactive({
    read_csv("weather_data_subset.csv")
  })
  #florida_data$planting <- as.Date(florida_data$planting)
  # Update SelectInput Choices Based on Data
  observe({
    updateSelectInput(session, "location", choices = unique(florida_data()$location), selected = "Jay (WFREC)")
    updateSelectInput(session, "cultivar", choices = unique(florida_data()$cultivar), selected = "IH Williams")
    updateSelectInput(session, "density", choices = unique(florida_data()$density), selected = "200/m2 (18.6/sqft)")
    updateSelectInput(session, "nitrogen", choices = unique(florida_data()$nitrogen), selected = "280 Kg/ha (250 LB/acre)")
    updateSelectInput(session, "harvest", choices = unique(florida_data()$harvest), selected = "Grain Maturity")
    #updateSelectInput(session, "location_categorized", choices = unique(florida_data_categorized()$location))
    #updateSelectInput(session, "cultivar_categorized", choices = unique(florida_data_categorized()$cultivar))
    updateSelectInput(session, "density_categorized", choices = unique(florida_data_individual_years()$density), selected = "200/m2 (18.6/sqft)")
    updateSelectInput(session, "nitrogen_categorized", choices = unique(florida_data_individual_years()$nitrogen), selected = "280 Kg/ha (250 LB/acre)")
    updateSelectInput(session, "harvest_categorized", choices = unique(florida_data_individual_years()$harvest), selected = "Grain Maturity")
    #updateSelectInput(session, "YEAR", choices = unique(plantgro_data()$YEAR))
    updateSelectInput(session, "planting", choices = unique(plantgro_data()$planting))
    updateSelectInput(session, "density2", choices = unique(plantgro_data()$density))
    updateSelectInput(session, "nitrogen2", choices = unique(plantgro_data()$nitrogen))
  })
  
  output$florida_map <- renderLeaflet({
    # Filter data based on selected location
    filtered_df <- location_df[location_df$location == input$location, ]
    leaflet(florida_shape()) %>%  # Use the reactive shape data
      addTiles() %>%
      addMarkers(lng = filtered_df$longitude, lat = filtered_df$latitude, popup = filtered_df$location) %>% 
      #addPolygons(
      #  fillColor = "lightblue",
      #  weight = 2,
      #  color = "darkblue",
      #  fillOpacity = 0.7
      #) %>%
      setView(-84.1, 27.6, zoom = 5.5)  # Center on Florida
  })
  # Population histogram
  #output$population_hist <- renderPlot({
  #  ggplot(county_data, aes(x = population)) +
  #    geom_histogram(binwidth = 50000, fill = "skyblue", color = "black") +
  #    labs(title = "County Population Distribution", x = "Population", y = "Count") +
  #    geom_vline(xintercept = input$pop_threshold, color = "brown", linetype = "dashed")
  #})
  output$phenology_info <- renderText({
    filtered_planting_date_df <- planting_date_df[planting_date_df$planting == input$planting & planting_date_df$location == input$location & planting_date_df$cultivar == input$cultivar,]
    paste0("Continuous black or colored line indicates average biomass or weather over the year. 
Shadowed area indicates variation in biomass among seasons.
Planting date indicated by dark green dashed line.
Flowering indicated by orange dashed line, approximately ", (filtered_planting_date_df$flowering_DAP), " days after planting.
Grain maturity indicated by brown dashed line, approximately ", (filtered_planting_date_df$maturity_DAP), " days after planting.
")
  })
  output$simulation_information <- renderText({
    paste("Outputs are based on simulations with CSM-CROPGRO-Hemp in DSSAT 4.8.2. 
Weather data obtained from FAWN (https://fawn.ifas.ufl.edu/). Low and high yield slider 
presets are based on 85% and 115% of average yield of the specific site and treatments.

Cultivars: fiber cultivar 'IH Williams' (IND Hemp) https://indhemp.com/ 
multi-purpose cultivar 'NWG 2730' (New West Genetics) https://newwestgenetics.com/abound-hemp-seed/

Following are soil and simulation setting information about the specific sites:

Jay (WFREC), Dothan fine sandy loam, 2003-2023 seasons, Century(Parton) for simulation of SOM
Live Oak (NFREC), Sandy soil, 2003-2023 seasons, Century(Parton) for simulation of SOM
Citra (PSREU), Arrendondo sand, 2003-2023 seasons, Century(Parton) for simulation of SOM
Balm (GCREC), Sandy soil (Candler), 2004-2023 seasons, Century(Parton) for simulation of SOM
Apopka (MREC), Arrendondo sand, 2003-2023 seasons, Century(Parton) for simulation of SOM
Belle Glade (EREC), Pahokee muck soil, 2005-2023 seasons, Century(Parton) for simulation of SOM
Homestread (TREC), Krome gravely loam (20cm), 2003-2023 seasons, Century(Parton) for simulation of SOM
          
Contact: alwinhopf@ufl.edu, https://programs.ifas.ufl.edu/hemp/")
  })
  output$temperature_stress <- renderText({
    paste0("Dashed red and blue lines indicate possibility of heat stress (>35\u00B0C/95\u00B0F) and freezing (<0\u00B0C/32\u00B0F)") 
  })
  # Income histogram
  #output$income_hist <- renderPlot({
  #  ggplot(county_data, aes(x = income)) +
  #    geom_histogram(binwidth = 5000, fill = "lightgreen", color = "black") +
  #    labs(title = "County Income Distribution", x = "Income", y = "Count") +
  #    geom_vline(xintercept = input$income_threshold, color = "brown", linetype = "dashed")
  #})
  # Filtered Florida Hemp Data
  florida_data_filtered <- reactive({
    florida_data() %>%
      mutate(planting = as.Date(planting, format = "%m/%d/%Y")) %>%
      filter(location %in% input$location,
             cultivar %in% input$cultivar,
             density %in% input$density,
             nitrogen %in% input$nitrogen,
             harvest %in% input$harvest)
  })
  # Filtered Florida Hemp Data
  florida_data_individual_years_filtered <- reactive({
    florida_data_individual_years() %>%
      mutate(planting = as.Date(planting, format = "%m/%d/%Y")) %>%
      filter(location %in% input$location,
             cultivar %in% input$cultivar,
             density %in% input$density_categorized,
             nitrogen %in% input$nitrogen_categorized,
             harvest %in% input$harvest_categorized) 
  })
  # Global variable definition
  category_labels <- c("1" = "Low Yield", "2" = "Medium Yield", "3" = "High Yield")
  
  florida_data_filtered_categorized <- reactive({
    req(input$lowThreshold, input$highThreshold)  # Require thresholds to be available
    #print(florida_data_categorized()) %>%
    intermediate_data <- florida_data_individual_years() %>%
      mutate(planting = as.Date(planting, format = "%m/%d/%Y"),
             CWAD = as.numeric(CWAD)) %>% # Ensure CWAD is numeric) %>%
      filter(location %in% input$location,
             cultivar %in% input$cultivar,
             density %in% input$density_categorized,
             nitrogen %in% input$nitrogen_categorized,
             harvest %in% input$harvest_categorized)  %>%
      # Calculate 'Category' only if CWAD is not NA
      mutate(
      #  Category = ifelse(!is.na(Mean_CWAD), 
      #                         factor(case_when(
      #  Mean_CWAD < input$lowThreshold ~ "Low Yield",
      #  Mean_CWAD >= input$lowThreshold & Mean_CWAD < input$highThreshold ~ "Medium Yield",
      #  TRUE ~ "High Yield"
      #), levels = c("Low Yield", "Medium Yield", "High Yield")), NA_character_)
      Category = ifelse(!is.na(CWAD),
                        factor(case_when(
                          CWAD < input$lowThreshold ~ "1", # Assign numeric category as character
                          CWAD >= input$lowThreshold & CWAD < input$highThreshold ~ "2",
                          TRUE ~ "3"
                        ), levels = c("1", "2", "3")), NA_character_),
      Category_Label = category_labels[Category]
      )
    # Print Intermediate Output
    #intermediate_data$category_labels <- c("1" = "Low Yield", "2" = "Medium Yield", "3" = "High Yield")
    print(head(intermediate_data$Category)) # To print in console
    print("Data after Category mutation:")
    print(head(intermediate_data, 5))  # Adjust the number of rows as needed
    final_data <- intermediate_data %>%
      mutate(Category = as.character(Category)) %>% # Convert to character before count
      count(planting, Category) %>%
      mutate(n = as.numeric(n)) %>% # Convert n to numeric if it's not
      group_by(planting) %>%
      mutate(percent = n / sum(n)) %>%
      mutate(percent = ifelse(n == 0, 0, n / sum(n))) %>% # Replace 0 percentage if n is 0
      #mutate(percent = ifelse(sum(n) == 0, 0, n / sum(n))) %>% # Handle division-by-zero
      ungroup() %>%
      complete(planting, Category, fill = list(n = 0, percent = 0)) # Fill in missing combinations
    # Add dummy rows for missing categories
    #complete(planting, Category, fill = list(n = 0))
    #mutate(Category = factor(Category, levels = c("Low Yield", "Medium Yield", "High Yield")))  # Convert back to factor
    
    # Print Final Output
    print("Final output data:")
    print(head(final_data, 10))  # Adjust the number of rows as needed
    final_data  # Return the final data
    # Intermediate Output After Category Mutation
  })
  sliderLimits <- reactive({
    req(florida_data_filtered()) #
    req(florida_data_individual_years_filtered()) #
    filtered_data <- florida_data_filtered()  
    filtered_data2 <- florida_data_individual_years_filtered()  
    # Check if filtered data is available
    req(filtered_data)  
    print("Structure of filtered_data:")  # Print structure
    print(str(filtered_data))
    print("First 5 rows of filtered_data:") # Print first 5 rows
    print(head(filtered_data, 5))
    print("Structure of filtered_data2:")  # Print structure
    print(str(filtered_data2))
    print("First 5 rows of filtered_data2:") # Print first 5 rows
    print(head(filtered_data2, 5))
    # Check if CWAD column exists
    validate(
      need(
        "CWAD" %in% names(filtered_data2),
        "The 'CWAD' column is missing from the filtered dataset. Please check your data filtering in plantgro_summary_subset_all_sites.csv."
      )
    )
    cwad_values <- filtered_data2$CWAD
    # Check if there are any non-missing CWAD values
    if (any(!is.na(cwad_values))) {
      filtered_max <- max(cwad_values, na.rm = TRUE)
      filtered_mean <- mean(cwad_values, na.rm = TRUE)
      
      list(
        #low = 0.6 * filtered_max,
        #high = 0.9 * filtered_max,
        low = 0.85 * filtered_mean,
        high = 1.15 * filtered_mean,
        max = filtered_max
      )
    } else {
      # Default values if no valid max is found
      list(low = 0, high = 0, max = 15000) 
    }
  })
  # Dynamic slider UI for Low Yield Threshold
  output$lowThresholdUI <- renderUI({
    limits <- sliderLimits()
    # Print for debugging
    print("sliderLimits() output:")
    print(limits)
    print("Low Threshold Slider Value:")
    print(limits$low)
    sliderInput("lowThreshold", "Low Yield Threshold (Kg/ha)",
                min = 0,
                max = 15000,
                value = limits$low
                #,label = paste0("Low Yield Threshold (", round(limits$low), " Kg/ha)")
                )
  })
  
  # Dynamic slider UI for High Yield Threshold
  output$highThresholdUI <- renderUI({
    limits <- sliderLimits()
    # Print for debugging
    print("sliderLimits() output:")
    print(limits)
    print("Low Threshold Slider Value:")
    print(limits$high)
    sliderInput("highThreshold", "High Yield Threshold (Kg/ha)",
                min = 0,
                max = 15000,
                value = limits$high,
                #,label = paste0("Low Yield Threshold (", round(limits$low), " Kg/ha)")
                )
  })
  # Output plot
  output$barPlot <- renderPlot({
    req(florida_data_filtered_categorized())
    #florida_data_filtered_categorized()$Category <- factor(florida_data_filtered_categorized()$Category, levels = c("Low Yield", "Medium Yield", "High Yield")) 
    #florida_data_filtered_categorized()$Category <- factor(florida_data_filtered_categorized$Category, levels = c("Low Yield", "Medium Yield", "High Yield"))
    ggplot(florida_data_filtered_categorized(), aes(x = planting, y = percent, fill = Category)) +
      geom_bar(stat = "identity", position = "dodge") +  # Dodged bars for categories
      labs(
        title = "Yield (Biomass) Probabilities by Planting Date",
        x = "Planting Date (mm-dd)",
        y = "Probability (%)"
      ) +
      scale_y_continuous(labels = scales::percent_format()) +
      scale_x_date(breaks = date_breaks, date_labels = "%m-%d") +
      #scale_fill_manual(values = c("Low Yield" = "lightblue", "Medium Yield" = "orange", "High Yield" = "darkred")) +
      #scale_fill_manual(values = c("Low Yield" = "lightblue", "Medium Yield" = "orange", "High Yield" = "darkred"),
      #                  breaks = c("Low Yield", "Medium Yield", "High Yield")) +
      scale_fill_manual(values = c("1" = "darkgreen", "2" = "orange", "3" = "brown"),
                        labels = c("1" = "Low Yield", "2" = "Medium Yield", "3" = "High Yield")) +
      theme_bw() +
      theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(), 
            text = element_text(size=global_size), plot.title = element_text(hjust = 0.5), 
            legend.position="bottom", legend.box.background = element_rect(fill = "transparent"), legend.background = element_rect(fill = "transparent"),
            panel.background = element_rect(fill = "transparent"),
            plot.background = element_rect(fill = "transparent", color = NA))
  },bg = "transparent")
  # Filtered Weather Data
  weather_data_filtered <- reactive({
    weather_data() %>%
      filter(location %in% input$location)
  })
  plantgro_data_filtered <- reactive({
    plantgro_data() %>%
      filter(planting %in% input$planting,
             location %in% input$location,
             cultivar %in% input$cultivar)
  })
  # Visualize Hemp Data - Filtered
  output$florida_hemp_filtered_biomass <- renderPlot({
    # Make sure data is available before plotting
    req(florida_data_filtered())
    ggplot(florida_data_filtered(), aes(x = planting, y = CWAD, fill=cultivar)) +
      geom_col(position = "dodge") +  # Scatterplot with points
      labs(x = "Planting Date (mm-dd)", 
           y = (expression(Biomass~"("*kg~dm~ha^{-1}*")")), 
           title = "Aboveground Biomass")  + 
      scale_x_date(breaks = date_breaks, date_labels = "%m-%d") +
      theme_bw() +
      scale_y_continuous(expand = c(0, 0)) +
      theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(), 
            text = element_text(size=global_size), plot.title = element_text(hjust = 0.5), legend.position="none", 
            panel.background = element_rect(fill = "transparent"),
            plot.background = element_rect(fill = "transparent", color = NA))
  },bg = "transparent")
  # Visualize Hemp Data - Filtered
  output$florida_hemp_filtered_GWAD <- renderPlot({
    # Make sure data is available before plotting
    req(florida_data_filtered())
    ggplot(florida_data_filtered(), aes(x = planting, y = GWAD, fill=cultivar)) +
      geom_col(position = "dodge") +  # Scatterplot with points
      labs(x = "Planting Date (mm-dd)", y = (expression(Grain~Weight~"("*kg~dm~ha^{-1}*")")), title = "Grain Weight") + scale_x_date(breaks = date_breaks, date_labels = "%m-%d") + #+ scale_x_date(date_labels = "%d-%m")
      theme_bw() +
      scale_y_continuous(expand = c(0, 0)) +
      theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(), 
            text = element_text(size=global_size), plot.title = element_text(hjust = 0.5), legend.position="none", 
            panel.background = element_rect(fill = "transparent"),
            plot.background = element_rect(fill = "transparent", color = NA))
  },bg = "transparent")
  output$florida_hemp_filtered_biomass_categorized <- renderPlot({
    # Make sure data is available before plotting
    req(florida_data_filtered())
    ggplot(florida_data_filtered(), aes(x = planting, y = CWAD, fill=cultivar)) +
      geom_col(position = "dodge") +  # Scatterplot with points
      labs(x = "Planting Date (mm-dd)", 
           y = (expression(Biomass~"("*kg~dm~ha^{-1}*")")), 
           title = "Aboveground Biomass")  + 
      scale_x_date(breaks = date_breaks, date_labels = "%m-%d") +
      theme_bw() +
      #scale_y_continuous(expand = c(0, 0)) +
      theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(), 
            text = element_text(size=global_size), plot.title = element_text(hjust = 0.5), legend.position="none", 
            panel.background = element_rect(fill = "transparent"),
            plot.background = element_rect(fill = "transparent", color = NA))
  },bg = "transparent")
  # Visualize Hemp Data - Full
  output$florida_hemp <- renderPlot({
    # Make sure data is available before plotting
    req(florida_data())
    ggplot(florida_data(), aes(x = planting, y = CWAD, fill=cultivar)) +
      geom_col(position = "dodge") +  # Scatterplot with points
      labs(x = "Planting Date (mm-dd)", y = "Biomass", title = "Biomass vs. Planting Date FULL") +
      theme_minimal() +  theme(text = element_text(size=global_size), legend.position="none")
  })
  #Biomass curve of individual experiment
  ####PLANTGRO TIMESERIES####
  output$individual_experiment_biomass <- renderPlot({
    # Make sure data is available before plotting
    filtered_planting_date_df <- planting_date_df[planting_date_df$planting == input$planting & planting_date_df$location == input$location & planting_date_df$cultivar == input$cultivar, ]
    # Make sure data is available before plotting
    req(plantgro_data_filtered())
    ggplot(plantgro_data_filtered(),aes(x=DAP,y=CWAD)) +
      #geom_line(aes(),linewidth=2.0) + 
      #geom_smooth() +
      stat_summary(geom = "ribbon", fun.min = min, fun.max = max, alpha = 0.1) +
      stat_summary(geom = "line", fun = mean, size=2) +
      geom_vline(xintercept = as.numeric(filtered_planting_date_df$flowering_DAP), color = "orange", linetype = "dashed", size=2) +
      geom_text(
        aes(x = as.numeric(filtered_planting_date_df$flowering_DAP), 
            y = +Inf),   # Position text at y = 95
        label = "Flowering Date", 
        vjust = 1,   # Align the top of the text with y = 95
        hjust = 0.5 # Center text horizontally over the vline
      ) +
      #geom_textvline(label = "the strong cars", as.numeric(filtered_planting_date_df$flowering_DAP), color = "orange", linetype = "dashed", size=2, vjust = 1.3) +
      geom_vline(xintercept = as.numeric(filtered_planting_date_df$maturity_DAP), color = "brown", linetype = "dashed", size=2) +
      geom_text(
        aes(x = as.numeric(filtered_planting_date_df$maturity_DAP), 
            y = +Inf),   # Position text at y = 95
        label = "Grain Maturity", 
        vjust = 1,   # Align the top of the text with y = 95
        hjust = 0.5 # Center text horizontally over the vline
      ) +
      ylab(expression(Biomass~"("*kg~dm~ha^{-1}*")")) +
      xlab("Days after Planting") +
      ggtitle("Aboveground Biomass") + 
      theme_bw() +
      scale_y_continuous(expand = c(0, 0)) +
      scale_x_continuous(expand = c(0, 0),breaks = pretty_breaks(n = 10)) +
      theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(), 
            text = element_text(size=global_size), plot.title = element_text(hjust = 0.5),
            panel.background = element_rect(fill = "transparent"),
            plot.background = element_rect(fill = "transparent", color = NA))
  },bg = "transparent")
  #Weather curve of individual experiment
  output$individual_experiment_weather_precipitation <- renderPlot({
    filtered_planting_date_df <- planting_date_df[planting_date_df$planting == input$planting & planting_date_df$location == input$location & planting_date_df$cultivar == input$cultivar, ]
    # Make sure data is available before plotting
    req(weather_data_filtered())
    ggplot(weather_data_filtered(),aes(x=DAS,y=PRED)) +
      #geom_line(aes(),linewidth=2.0) + 
      #geom_smooth() +
      stat_summary(geom = "ribbon", fun.min = min, fun.max = max, alpha = 0.1) +
      stat_summary(geom = "line", fun = mean, size=2) +
      geom_vline(xintercept = as.numeric(filtered_planting_date_df$planting_DAS), color = "darkgreen", linetype = "dashed", size=2) +
      geom_vline(xintercept = as.numeric(filtered_planting_date_df$planting_DAS+filtered_planting_date_df$flowering_DAP), color = "orange", linetype = "dashed", size=2) +
      geom_vline(xintercept = as.numeric(filtered_planting_date_df$planting_DAS+filtered_planting_date_df$maturity_DAP), color = "brown", linetype = "dashed", size=2) +
      ylab(expression(Daily~Precip.~(mm))) +
      xlab("Day of Year") +
      ggtitle("Precipitation") + 
      theme_bw() +
      scale_y_continuous(expand = c(0, 0)) + ylim(0, 100) + 
      scale_x_continuous(expand = c(0, 0),breaks = pretty_breaks(n = 10)) +
      theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(), 
            text = element_text(size=global_size), plot.title = element_text(hjust = 0.5),
            panel.background = element_rect(fill = "transparent"),
            plot.background = element_rect(fill = "transparent", color = NA))
  },bg = "transparent")
  #Weather curve of individual experiment
  output$individual_experiment_weather_precipitation2 <- renderPlot({
    filtered_planting_date_df <- planting_date_df[planting_date_df$planting == input$planting & 
                                                    planting_date_df$location == input$location & 
                                                    planting_date_df$cultivar == input$cultivar, ]
    
    req(weather_data_filtered())  # Ensure data is available
    
    reference_year <- 2023  # Replace if you have an input for this
    
    # Calculate min/max DAS for plot's date range
    min_DAS <- min(weather_data_filtered()$DAS, na.rm = TRUE)
    max_DAS <- max(weather_data_filtered()$DAS, na.rm = TRUE)
    
    ggplot(weather_data_filtered(), aes(x = DAS, y = PRED)) +
      stat_summary(geom = "ribbon", fun.min = min, fun.max = max, alpha = 0.1) +
      stat_summary(geom = "line", fun = mean, size = 2) +
      geom_vline(xintercept = as.numeric(filtered_planting_date_df$planting_DAS), 
                 color = "darkgreen", linetype = "dashed", size = 2) +
      geom_vline(xintercept = as.numeric(filtered_planting_date_df$planting_DAS + filtered_planting_date_df$flowering_DAP), 
                 color = "orange", linetype = "dashed", size = 2) +
      geom_vline(xintercept = as.numeric(filtered_planting_date_df$planting_DAS + filtered_planting_date_df$maturity_DAP), 
                 color = "brown", linetype = "dashed", size = 2) +
      ylab(expression(Daily~Precip.~(mm))) +
      xlab("Day of Year") +
      ggtitle("Precipitation") +
      theme_bw() +
      scale_y_continuous(expand = c(0, 0)) +
      
      # Primary x-axis (Day of Year)
      scale_x_continuous(
        expand = c(0, 0), 
        breaks = pretty_breaks(n = 10),
        # Secondary x-axis (Date in dd-mm format)
        sec.axis = sec_axis(
          # --- The correction is here ---
          trans = function(x) as.Date(x, origin = as.Date(paste0(reference_year, "-01-01"))),  # Use a function to pass origin 
          breaks = seq(
            as.Date(paste0(reference_year, "-01-01")) + min_DAS - 1, 
            as.Date(paste0(reference_year, "-01-01")) + max_DAS - 1, 
            by = "1 month"
          ),
          labels = function(date) { format(date, "%d-%m") }
        )
      ) +
      
      # Customize appearance
      theme(panel.grid.major = element_blank(), 
            panel.grid.minor = element_blank(),
            text = element_text(size = global_size), 
            plot.title = element_text(hjust = 0.5),
            panel.background = element_rect(fill = "transparent"),
            plot.background = element_rect(fill = "transparent", color = NA),
            axis.text.x.top = element_text(margin = margin(t = 5)))  
  }, bg = "transparent")
  output$individual_experiment_weather_avg_temperature <- renderPlot({
    filtered_planting_date_df <- planting_date_df[planting_date_df$planting == input$planting & planting_date_df$location == input$location & planting_date_df$cultivar == input$cultivar, ]
    # Make sure data is available before plotting
    req(weather_data_filtered())
    ggplot(weather_data_filtered(),aes(x=DAS,y=TAVD)) +
      #geom_line(aes(),linewidth=2.0) + 
      #geom_smooth() +
      stat_summary(geom = "ribbon", fun.min = min, fun.max = max, alpha = 0.1) +
      stat_summary(geom = "line", fun = mean, size=2) +
      geom_vline(xintercept = as.numeric(filtered_planting_date_df$planting_DAS), color = "darkgreen", linetype = "dashed", size=2) +
      geom_vline(xintercept = as.numeric(filtered_planting_date_df$planting_DAS+filtered_planting_date_df$flowering_DAP), color = "orange", linetype = "dashed", size=2) +
      geom_vline(xintercept = as.numeric(filtered_planting_date_df$planting_DAS+filtered_planting_date_df$maturity_DAP), color = "brown", linetype = "dashed", size=2) +
      labs(y = expression(paste("Temperature (", degree, "C)"))) +
      xlab("Day of Year") +
      ggtitle("Average Daily Temperature") + 
      theme_bw() +
      scale_y_continuous(expand = c(0, 0)) +
      scale_x_continuous(expand = c(0, 0),breaks = pretty_breaks(n = 10)) +
      theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(), 
            text = element_text(size=global_size), plot.title = element_text(hjust = 0.5),
            panel.background = element_rect(fill = "transparent"),
            plot.background = element_rect(fill = "transparent", color = NA))
  },bg = "transparent")
  output$individual_experiment_weather_daylength <- renderPlot({
    filtered_planting_date_df <- planting_date_df[planting_date_df$planting == input$planting & planting_date_df$location == input$location & planting_date_df$cultivar == input$cultivar, ]
    # Make sure data is available before plotting
    req(weather_data_filtered())
    ggplot(weather_data_filtered(),aes(x=DAS,y=DAYLD)) +
      #geom_line(aes(),linewidth=2.0) + 
      #geom_smooth() +
      stat_summary(geom = "ribbon", fun.min = min, fun.max = max, alpha = 0.1) +
      stat_summary(geom = "line", fun = mean, size=2) +
      geom_vline(xintercept = as.numeric(filtered_planting_date_df$planting_DAS), color = "darkgreen", linetype = "dashed", size=2) +
      geom_vline(xintercept = as.numeric(filtered_planting_date_df$planting_DAS+filtered_planting_date_df$flowering_DAP), color = "orange", linetype = "dashed", size=2) +
      geom_vline(xintercept = as.numeric(filtered_planting_date_df$planting_DAS+filtered_planting_date_df$maturity_DAP), color = "brown", linetype = "dashed", size=2) +
      ylab("Daylength (h)") +
      xlab("Day of Year") +
      ggtitle("Daylength (Sunrise to Sunset, without Twilight)") + 
      theme_bw() +
      scale_y_continuous(expand = c(0, 0)) +
      scale_x_continuous(expand = c(0, 0),breaks = pretty_breaks(n = 10)) +
      theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(), 
            text = element_text(size=global_size), plot.title = element_text(hjust = 0.5),
            panel.background = element_rect(fill = "transparent"),
            plot.background = element_rect(fill = "transparent", color = NA))
  },bg = "transparent")
  output$individual_experiment_weather_tmin_tmax <- renderPlot({
    filtered_planting_date_df <- planting_date_df[planting_date_df$planting == input$planting & planting_date_df$location == input$location & planting_date_df$cultivar == input$cultivar, ]
    # Make sure data is available before plotting
    req(weather_data_filtered())
    ggplot(weather_data_filtered(),aes(x=DAS)) +
      #geom_line(aes(),linewidth=2.0) + 
      #geom_smooth() +
      stat_summary(aes(y = TMND),geom = "ribbon", fun.min = min, fun.max = max, alpha = 0.1, fill = "blue") +
      stat_summary(aes(y = TMND),geom = "line", fun = mean, color = "blue", size=2) +
      stat_summary(aes(y = TMXD),geom = "ribbon", fun.min = min, fun.max = max, alpha = 0.1, fill = "red") +
      stat_summary(aes(y = TMXD),geom = "line", fun = mean, color = "red", size=2) +
      geom_vline(xintercept = as.numeric(filtered_planting_date_df$planting_DAS), color = "darkgreen", linetype = "dashed", size=2) +
      geom_vline(xintercept = as.numeric(filtered_planting_date_df$planting_DAS+filtered_planting_date_df$flowering_DAP), color = "orange", linetype = "dashed", size=2) +
      geom_vline(xintercept = as.numeric(filtered_planting_date_df$planting_DAS+filtered_planting_date_df$maturity_DAP), color = "brown", linetype = "dashed", size=2) +
      geom_hline(yintercept = 35, color = "red", linetype = "dashed", size=1, alpha = 0.5) +
      geom_hline(yintercept = 0, color = "blue", linetype = "dashed", size=1, alpha = 0.5) +
      labs(y = expression(paste("Temperature (", degree, "C)"))) +
      xlab("Day of Year") +
      ggtitle("Daily Maximum and Minimum Temperature") + 
      theme_bw() +
      scale_y_continuous(expand = c(0, 0)) +
      scale_x_continuous(expand = c(0, 0),breaks = pretty_breaks(n = 10)) +
      theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(), 
            text = element_text(size=global_size), plot.title = element_text(hjust = 0.5),
            panel.background = element_rect(fill = "transparent"),
            plot.background = element_rect(fill = "transparent", color = NA),
            legend.position = "bottom")
  },bg = "transparent")
  output$datePlot <- renderPlot({
    selectedDate <- input$planting # Get selected date from user input
    
    # Sample data (replace with your actual data)
    df <- data.frame(
      date = seq.Date(from = ymd("2024-01-01"), to = ymd("2024-12-30"), by = "day"),
      value = rnorm(365)
    )
    
    # Create plot
    ggplot(df, aes(x = date, y = value)) +
      geom_line() +
      labs(title = "Line Chart with Vertical Line on Selected Date")+
      geom_vline(xintercept = as.numeric(selectedDate), color = "red", linetype = "dashed")
  },)
  # Sample data (replace with your own)
  background_information <- data.frame(
    Site = c("Jay (WFREC)", "Live Oak (NFREC)", "Citra (PSREU)", 
             "Balm (GCREC)", "Apopka (MREC)", "Belle Glade (EREC)","Homestead (TREC)"),
    SoilType = c("Dothan fine sandy loam", "Sandy", "Arrendondo sand", 
                 "Sandy (Candler)", "Arrendondo sand", "Pahokee muck", "Krome gravely loam"),
    Information = c("2003-2023, Century(Parton) for simulation of SOM",
                    "2003-2023, Century(Parton) for simulation of SOM",
                    "2003-2023, Century(Parton) for simulation of SOM",
                    "2004-2023, Century(Parton) for simulation of SOM",
                    "2003-2023, Century(Parton) for simulation of SOM",
                    "2005-2023, Century(Parton) for simulation of SOM",
                    "2003-2023, Ceres(Godwin) for simulation of SOM")
  )
  
  # Render the table
  output$background_information <- DT::renderDataTable({
    background_information
  })
}

shinyApp(ui, server)

#setwd("D:/OneDrive - University of Florida/ABE_Hemp_DSS_PhD/hemp_r-shiny_webapp/Hemp-DSS-Dashboard/hemp_dss_dashboard")
#florida_data <- read_csv("florida_data.csv")

#req(florida_data)
#ggplot(florida_data, aes(x = planting, y = biomass)) +
#  geom_point() +  # Scatterplot with points
#  labs(x = "Plantin Date", y = "Biomass", title = "Biomass vs. Planting Date") +
#  theme_minimal() 

