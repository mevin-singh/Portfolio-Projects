## app.R ##
library(dplyr)
library(leaflet)
library(RSelenium)
library(rvest)
library(XML)
library(tidyverse)
library(magrittr)
library(htmlwidgets)
library(shinyWidgets)
library(shinyjs)
library(shiny)
library(leaflet.extras)
library(shinyTime)
library(markdown)
library(ggimage)
library(ggmap)
library(ggplot2)
library(jsonlite)
library(tidyr)
library(wordcloud)
library(RColorBrewer)
library(wordcloud2)
library(shinydashboard)
library(shinydashboardPlus)
library(googleway)
library(stringr)
library(readr)
library(shinyEffects)

source("Project_Functions.R")

#api key (personal)
api_key <- "AIzaSyBA6-2PxIz_N2xtd-13cbwe_jdDuFUA1sQ"

#--------------Load dataset---------------------------
restaurants <- read.csv("RestaurantsFull.csv")
#handling cuisine to find unique values of cuisine 
cuisine <- as.data.frame(str_split_fixed(restaurants$Cuisine, ",", 15)) 
cuisine1 <- cuisine[!apply(is.na(cuisine) | cuisine == "", 1, all),]
dat <- cuisine %>% mutate_all(na_if,"")
df2 <- as.vector(as.matrix(dat))
all_cuisines <- unique(df2)
#reading attractions data
attractions <- read.csv("attractions_cleanedfinal.csv")
#reading supermarket data
supermarkets <- read.csv("supermarkets_clean.csv")
supermarket_brands <- unique(supermarkets$business_name)

#-----------------NEWS: Preparation for data table output----------------------------------
df <- read.csv('news.csv')

df$url_to_image <- paste0("<img src='",df$Image,"'height='100'></img>")
df$Title <- paste0("<a href='",df$Link,"' style='color:rgb(54, 190, 239)'><font size='+1'><b>",df$Title,"</b></font></a>")
df$subtitle <- paste0("<b>",df$Source,"</b><br> (",df$Time,")")
df$combinedtext <- paste0(df$title,"<br>",df$subtitle)
df <- subset(df, select=c(url_to_image, Title, combinedtext))


#-----------------End of News data table-----------


#----------------plotR: data preparation------------
all_cuisine_string <- paste(all_cuisines, collapse = ",")
hawkers_plotR <- read.csv("HCFull.csv") %>% mutate(Cuisine = all_cuisine_string,Colour = "lavender",price_num = 1) %>% 
  select(name_of_centre, Cuisine, Lat,Long, Colour, price_num, no_of_stalls) 
names(hawkers_plotR ) <- c("Name", "Cuisine", "Lat","Long", "Colour","Price","Number of options") 
restaurants_plotR <- read.csv("RestaurantsFull.csv") %>% mutate(Colour = "blue",price_num = nchar(Price),number_options = 1) %>% 
  select(Name,Cuisine,Lat,Long,Colour, price_num,number_options)
names(restaurants_plotR) <- c("Name","Cuisine","Lat","Long","Colour","Price","Number of options")
compiled_rh <- rbind(hawkers_plotR,restaurants_plotR)

#----------------Weather: Preparation for output--------------
weathers <- data.frame( weather = c( "Fair (Day)", 
                                     'Fair (Night)', 
                                     "Cloudy",
                                     "Partly Cloudy (Day)",
                                     "Partly Cloudy (Night)", 
                                     "Light Showers", 
                                     "Light Rain", 
                                     "Showers",
                                     "Moderate Rain", 
                                     "Thundery Showers"    ),    
                        
                        icon.link = c("https://cdn-icons-png.flaticon.com/512/2698/2698194.png",
                                      "https://cdn-icons-png.flaticon.com/512/3590/3590251.png",
                                      'https://cdn-icons-png.flaticon.com/512/3313/3313983.png',
                                      "https://cdn-icons-png.flaticon.com/512/3208/3208752.png",
                                      "https://cdn-icons-png.flaticon.com/512/2675/2675857.png",
                                      "https://cdn-icons-png.flaticon.com/512/3075/3075858.png",
                                      "https://cdn-icons-png.flaticon.com/512/3075/3075858.png",
                                      "https://cdn-icons-png.flaticon.com/512/3520/3520675.png",
                                      "https://cdn-icons-png.flaticon.com/512/3520/3520675.png",
                                      "https://cdn-icons-png.flaticon.com/512/1146/1146860.png") )


date = Sys.Date()
url <- "https://api.data.gov.sg/v1/environment/24-hour-weather-forecast?date="
url <- paste0(url,date)
weather_data_24hr <- fromJSON(url)
wdata <- as.data.frame(weather_data_24hr$items$periods[[1]]$regions)

# To solve the error when loading weather data over 12am
if (nrow(wdata) == 0){
  date = Sys.Date()-1
  url <- "https://api.data.gov.sg/v1/environment/24-hour-weather-forecast?date="
  url <- paste0(url,date)
  weather_data_24hr <- fromJSON(url)
  wdata <- as.data.frame(weather_data_24hr$items$periods[[1]]$regions)
}
names(wdata) <- c('West', 'East', 'Central', 'South', 'North')

# Choosing only 2nd row
wdata <- wdata[2, ]
wdata <- wdata %>% gather() %>% rename(region = key, forecast = value)
wdata$lat <- c(1.329490, 1.352480, 1.350400, 1.302570, 1.448200)
wdata$long <- c(103.738258, 103.944611, 103.848747,103.834686, 103.819489) # coordinates represents roughly in the middle of each region

# Newly formatted data
wdata.icon <- merge(wdata,weathers, by.x="forecast", by.y="weather")%>%select(region,forecast,icon.link)

# Prepare for smart recommendation 
wdata.icon$url_to_image <- paste0("<img src='",wdata.icon$icon.link,"'height='50'></img>")
wdata.icon$region <- paste0("<style='color:rgb(54, 190, 239)'><b>",wdata.icon$region,"</b>")
wdata.icon$forecast <- paste0("<style='color:rgb(54, 190, 239)'><font size='-5'><b>",wdata.icon$forecast,"</b></font>")
wdata.icon$combinedtext <- paste0(wdata.icon$region, "<br>",wdata.icon$forecast)
wdata.icon <- subset(wdata.icon, select=c(url_to_image, combinedtext))
wdata.icon$num <- seq.int(nrow(wdata.icon)) 
wdata.icon <- wdata.icon %>%select(num, everything())
wdata.icon <- data.frame(t(wdata.icon[-1]))

#----------End of weather data preparation----------

#------Attraction: Preparation for itinerary box output--------
df1 <- attractions %>% mutate(link_clean = ifelse(is.na(Link)," ",Link )) %>%
  mutate(popup_info = paste(Name, link_clean)) %>% drop_na(c('Price',"Duration..hr."))
df1[(df1['Price'] == "$$$$"|df1['Price'] == "$$$$$"), 'Price'] <- '$$$'

#-------END of attraction dataset preparation---------
#---------styling of popup for itinarary--------
withPopup <- function(tag) {
  content <- div("Click name to see the crowd")
  tagAppendAttributes(
    tag,
    `data-toggle` = "popover",
    `data-html` = "true",
    `data-trigger` = "hover",
    `data-content` = content
  )
}
####################---------- UI --------------------##################

#-------------------------- UI: HEADER ----------------------------------------  
header <- dashboardHeader(title = "GoWhereSia",
                          tags$li(a(href = '',
                                    img(src="GoWhereSia.png", height=20),
                                    title = "Back to Apps Home"),
                                  class = "dropdown"))

#-------------------------- UI: SIDEBAR ----------------------------------------
sidebar <- dashboardSidebar(
    useShinyjs(),
    ## Sidebar content
    sidebarMenu(
      id = "tabs",
      menuItem("Home", tabName = "homepage", icon = icon(name = "home", lib = "font-awesome")),
      menuItem("Quick Search", tabName = "dashboard", icon = icon(name = "map", lib = "font-awesome")),
      menuItem("Itinerary", tabName = "itinerary", icon = icon(name = "clipboard", lib = "font-awesome")),
      menuItem("Crowd Insights",tabName = "Crowd_Info", icon = icon(name = "user",lib = "font-awesome")),
      menuItem('Weather', tabName = 'Weather', icon = icon('cloud-sun-rain')),
      menuItem("News", tabName ="News",icon = icon("th")),
      menuItem("About Us", tabName ="aboutus",icon = icon("plane"))
  ))
#-------------------------- UI: BODY ----------------------------------------
body <- dashboardBody(
  setShadow(class = "small-box"),
  tags$head(tags$script("$(function() { $(\"[data-toggle='popover']\").popover(); })")),
  # infoBoxes with fill=FALSE
    tabItems(
      #--------------------------------------
      # About Us Tab content     
      tabItem(tabName = "aboutus", 
              
              #page header
              fluidRow( box(title = h2(strong("About Us ♔"), align="center"), 
                            width = 12,
                            "Planning an itinerary can sometimes be stressful for people who are travelling, 
                            especially if they do not know the country well enough. 
                            As a tourist, a considerable amount of time will be needed to research about the country, 
                            before they can find suitable attractions, places to eat as well as hotels to stay in. 
                            Knowing that sometimes things may not go as planned, back-ups plans may also be needed."
                            ,
                            br(),
                            br(),
                            img(src = "Mission.jpg",
                                height = "330px",
                                width = "100%"),
                            br(),
                            br() ))
                
      ),
      
      #-----------------------------------------
      # HOME tab content
      tabItem(tabName = "homepage",
              fluidRow(
                
                #Singapore landscape image!
                flipBox(
                id = "myflipbox", 
                trigger = "click",
                width = 12,
                
                front = div(
                  br(),
                  h1(strong("Explore Singapore with GoWhereSia")),
                  
                  em("Click here to find out more!"),
                  br(),
                  br(),
                  class = "text-center",
                  img(
                    src = 'Homepage.png',
                    width = "100%"
                  )
                ),
                back = div(
                  class = "text-center",
                  height = "400px",
                  width = "100%",
                  h1(strong("GoWhereSia")),
                  p(em(strong("The only travel app you will ever need!"))),
                  img(src = "AboutUs.jpeg",
                      width = "90%"),
                  br(),
                  br()
                )
              )),
              
              br(),
      
            fluidRow( box(title = strong("Easy trip planning with GoWhereSia"), 
                    width = 12,
                    "Planning an itinerary can sometimes be stressful for people who are travelling, 
                    especially if they do not know the country well enough. 
                    As a tourist, a considerable amount of time will be needed to research about the country, 
                    before they can find suitable attractions, places to eat as well as hotels to stay in. 
                    Knowing that sometimes things may not go as planned, back-ups plans may also be needed.",
                    br(),
                    br()
      )
      ),
      
      
      #-----------------------------------------------------------------------
      ### QUICK SEARCH ###
      fluidRow( 
        box(title = strong("QUICK SEARCH"),
            width = 4,
            "Find out more about the attractions and food that Singapore has to off here!",
            br(),
            br(),
            solidHeader = TRUE,
            status = "warning",
            #background = "yellow",
            img(src = "https://www.holidify.com/images/bgImages/SINGAPORE.jpg", 
                height = '200', width = '100%', align = "center"),
            br(),
            br(),
            actionBttn(inputId= "quicksearch", 
                       label = em(strong("CLICK TO FIND OUT MORE")), 
                       style="unite", size = "xs", color="danger",
                       block = TRUE)
            
        ),
        
        ### FOOOD ###
        box(title = strong("FOOD GUIDE"),
            width = 4,
            "Click here to check out the delicacies that Singapore has to offer!",
            br(),
            br(),
            solidHeader = TRUE,
            status = "warning",
            #background = "yellow",
            img(src = "https://www.visitsingapore.com/editorials/did-you-know-foodies/jcr:content/par/mobile_21_content_sl/sliderccpar1/editorial_generic_co.thumbnail.overview-image.1460.822.jpg", 
                height = '200', width = '100%', align = "center"),
            br(),
            br(),
            actionBttn(inputId= "foodguide", 
                       label = em(strong("CLICK TO FIND OUT MORE")), 
                       style="unite", size = "xs", color="danger",
                       block = TRUE)
        ),
        
        ### LATEST WEATHER ###
        box(title = strong("WEATHER"),
            width = 4,
            "Be preared for Singapore's sudden showers! Find out the latest weather here!",
            br(),
            br(),
            solidHeader = TRUE,
            #background = "yellow",
            status = "warning",
            img(src = "https://www.1blueplanet.com/weather/weathermap/1blue_singapore_weather_map.gif?rand=620801", 
                height = '200', width = '100%', align = "center"),
            br(),
            br(),
            
            actionBttn(inputId= "weather", 
                       label = em(strong("CLICK TO FIND OUT MORE")), 
                       style="unite", size = "xs", color="danger",
                       block = TRUE)
        )
        
      ),
      
      #-------------------------------------------------------
      fluidRow( 
        box(title = strong("ITINERARY"),
            width = 4,
            "Rain or shine, check out GoWhereSia Itinerary for a perfect day out in Singapore!",
            br(),
            br(),
            
            solidHeader = TRUE,
            status = "warning",
            #background = "yellow",
            img(src = "https://www.asiaone.com/sites/default/files/styles/article_main_image/public/original_images/Feb2014/20140225_jsrest20-tour-guide-singapore_ST.jpg?itok=hV-7-tfk", 
                height = '200', width = '100%', align = "center"),
            br(),
            br(),
            actionBttn(inputId= "itinerary", 
                       label = em(strong("CLICK TO FIND OUT MORE")), 
                       style="unite", size = "xs", color="danger",
                       block = TRUE)
        ),
        
        ### CROWD INSIGHT ###
        box(title = strong("CROWDS INSIGHTS"),
            width = 4,
            "Crowd Insights on the popularity of attractions on different days of the week!",
            br(),
            br(),
            
            solidHeader = TRUE,
            status = "warning",
            #background = "yellow",
            img(src = "https://static1.straitstimes.com.sg/s3fs-public/styles/large30x20/public/articles/2017/04/15/42247519_-_14_04_2017_-_nhmarket15.jpg?VersionId=q2ZZ0CzWgQEw7g1gpyxK4sk9UkboRuYp&itok=iJ6JhUXo", 
                height = '200', width = '100%', align = "center"),
            br(),
            br(),
            actionBttn(inputId= "crowdinfo", 
                       label = em(strong("CLICK TO FIND OUT MORE")), 
                       style="unite", size = "xs", color="danger",
                       block = TRUE)
        ),
        
        ### ATTRACTIONS NEWS ###
        box(title = strong("LATEST NEWS"),
            width = 4,
            "Click here to check out more things you can do in Singapapore!",
            br(),
            br(),
            
            solidHeader = TRUE,
            status = "warning",
            #background = "yellow",
            img(src = "https://www.theedgesingapore.com/_next/image?url=https%3A%2F%2Fedgemarkets-transferred.s3-ap-southeast-1.amazonaws.com%2F386245506%20(1).jpg&w=3840&q=75", 
                height = '200', width = '100%', align = "center"),
            br(),
            br(),
            actionBttn(inputId= "latestnews", 
                       label = em(strong("CLICK TO FIND OUT MORE")),
                       style="unite", size = "xs", color="danger",
                       block = TRUE)
        )
      ),
      
      #LATEST COVID UPDATES
      fluidRow(box(width=12,
               title = h3(strong("COVID-19: Travelling to Singapore (Updated as of 1 April 2022)")),
               h4(strong("Planning to visit Singapore?")),
               'Singapore is reopening to all fully vaccinated travellers without quarantine on 1 April. Here’s a quick guide to enjoying seamless travel to Singapore!',
               br(),
               br(),
               img(src = "STB_tourismguide.jpeg", width = 500),
               br(),
               br(),
               br(),
               br(),
               h4(strong("Accepted Vaccinations for Entry")),
               'All travellers aged 12 and below do not need to be vaccinated for entry to Singapore. 
               Travellers aged 13 and above are only considered “fully vaccinated” for purposes of entry to Singapore if they meet either of the 
               following conditions at least 2 weeks before arrival in Singapore, if not they are considered “non-fully vaccinated”:',
               br(),
               br(),
               '1. Received the full regimen of WHO EUL Vaccines in the list of accepted vaccinations below and met the minimum dose interval period; or',
               br(),
               br(),
               '2. Contracted COVID-19 before being vaccinated, and received at least one dose of any WHO EUL Vaccines (listed below) at least 28 days from their first 
               diagnosis of a COVID-19 infection. Travellers must produce acceptable proof of their first positive COVID-19 diagnosis.',
               br(),
               br(),
               'Fully vaccinated travellers and children aged 12 and below should refer to this travel checklist for more details including 
               how to show proof of vaccination, and maintaining that vaccination status for activities within Singapore. 
               Travellers who do not meet the vaccination criteria for entry should refer to the Travel Checklist for Non-fully Vaccinated Travellers aged 13 and above.',
               br(),
               br(),
              
               img(src = "vaccines.png", width = 500),
               br(),
               br()
               
               )),
      
      
      
      #-----------------------------------------------------------------------

      
      
      #Latest Promotions
      carousel(width=12,
               id = "mycarousel",
               carouselItem(
                 caption = h4(strong("LATEST PROMOTIONS")),
                 tags$img(src = "USS.png")
               ),
               
               carouselItem(
                 caption = h4(strong("LATEST PROMOTIONS")),
                 tags$img(src = "https://thesmartlocal.com/wp-content/uploads/2019/05/images_easyblog_articles_7789_DBS-mothers-day-1.jpg")
               )
      )),
      
      
      
      
      
      #--------------------------------------
      # Quick Search
      tabItem(tabName = "dashboard",
              
              fluidRow( box(title = h2(strong("Quick Search ➲"), align="center"), 
                            width = 12,
                            "Find out more about the attractions and food that Singapore has to offer with just a few clicks! 
                            GoWhereSia also offers the feature for you to filter the locations based on price points!
                            Click on any attractions and restaurants to find out more!",
                            br(),
                            br()
              )),
              
              
              fluidRow(
                
                #ATTRACTIONS DESCRIPTION
                box(title = strong("Attraction Details  📍"),
                    solidHeader = TRUE,
                    collapsible = TRUE,
                    collapsed = TRUE,
                    status = "warning",
                    uiOutput("showATTRACTIONS")),
        
                #RESTAURANTS DESCRIPTION
                box(title = strong("Restaurants Details  🍴"),
                    solidHeader = TRUE,
                    collapsible = TRUE,
                    collapsed = TRUE,
                    status = "warning",
                    uiOutput("showRESTAURANTS"))
                
                
              ),
              
              fluidRow(
                tabBox(
                  title = strong("Maps"),
                  id = "tabset1",
                  width = 12,
                  
                  #------ ATTRACTIONS CONTROL ---------
                  tabPanel(strong("Attractions"),
                           google_mapOutput("plotA"),
                           br(),
                           h2(strong("Attractions")),
                           sliderInput(inputId = "PriceA", label = h4(strong("Price Selection:")), 
                                       min = 1, max = 5, value = 3),
                           em("(1 = Least Expensive, 5 = Most Expensive)" )),

                  #------ RESTAURANTS CONTROL ---------
                  tabPanel(strong("Restaurants"), 
                           google_mapOutput("plotR"),
                           br(),
                           selectInput("Cuisine", label = h2(strong("Type of Cuisine")), 
                                       choices = all_cuisines, 
                                       selected = "Italian"),
                           br(),
                           sliderInput(inputId = "PriceR", label = h4(strong("Price Selection:")), 
                                       min = 1, max = 7, value = 3),
                           em("(1 = Least Expensive, 7 = Most Expensive)" ),
                           br(),
                           em("Purple Markers - Hawker Centers")),
                  
                  tabPanel(strong("Supermarkets"), 
                           google_mapOutput("plotS"),
                           br(),
                           selectInput(inputId = "SMbrand1", label= h2(strong("Supermarkets in SG")),
                                       choices = supermarket_brands, 
                                       selected = "Giant"),
                           plotOutput("Supermarket_Rankings"))
                )),
              ),
      
      
      #--------------------------------------
      # Crowd info
      tabItem(tabName = "Crowd_Info",
              
              #page header
              fluidRow( box(title = h2(strong("Crowd Insights 𓀟"), align="center"), 
                            width = 12,
                            "Isn’t it annoying when people get into your perfect Instagram shot? 
                            Hate squeezing with people at popular attractions? 
                            GoWhereSia got your back! 
                            Crowd Insights will provide daily updates on crowds in Singapore so you can avoid those sweaty crowds!",
                            br(),
                            br()
              )),
              
              #h2(strong("Crowd Insights")),
              fluidRow(
                box(
                  title = strong("Crowd Insights (for attractions)"),
                  solidHeader = TRUE,
                  status = "warning",
                  width = 12,
                  leafletOutput("plotcrowd")
                )),
              fluidRow(
                column(6,
                       infoBoxOutput( "AttractionName", width = NULL),
                       infoBoxOutput("AttractionPrice", width = NULL),
                       infoBoxOutput("AttractionOH", width = NULL),
                       infoBoxOutput("AttractionDesc", width = NULL),
                       infoBoxOutput("AttractionLink", width = NULL)
                ),
                column(6,
                  box(
                    title = strong("Controls for Crowd Insights"),
                    solidHeader = TRUE,
                    status = "warning",
                    width = NULL,
                    selectInput(inputId="attraction_type",label = h2(strong("Attraction")),
                                choices = unique(attractions$Name),
                                selected = "Night Safari, Singapore"),
                    plotOutput("crowd_information")
                  )
                )
              )
      ),
      
      
      #--------------------------------------
      # News Tab content     
      tabItem(tabName = "News",
              
              #page header
              fluidRow( box(title = h2(strong("Things To Do In Singapore ✑"), align="center"), 
                            width = 12,
                            "What’s popular in Singapore? 
                            Check out the most popular attractions in Singapore as advertised by various news media platforms. 
                            Have fun exploring!",
                            br(),
                            br()
              )),

              fluidRow(
                box(DT::dataTableOutput("news"), width = 12))
      ),
      
      #----------------------------------------
      # Itinerary Tab content
      tabItem(tabName = "itinerary", 
              #page header
              fluidRow( box(title = h2(strong("Itinerary ✈"), align="center"), 
                            width = 12,
                            "Bored at home and wondering what you can do in Singapore this weekend? 
                            Take a look at Singapore’s Top Attractions and plan your trip now! 
                            Too lazy to do so? Don’t worry! 
                            Check out GoWhereSia’s personalised itinerary that will help you plan out your day in a few clicks.",
                            br(),
                            br()
              )),
              
              #h2(strong("Itinerary")),
              fluidRow(
                box(width = 6,
                    title = span('Personalise Your Own Itinerary!', style = "font-weight: bold;color:orange;font-size: 20px"),
                    collapsible = TRUE,
                    collapsed = TRUE,
                    uiOutput("selectprice", width = 5), 
                    uiOutput("selecttype", width = 5),
                    fluidRow(column(12,
                                    br(),
                                    actionButton("go", "Ready to Go!"),
                                    div(style = "margin-left:50px;height:48px"))),
                                       
                    fluidRow(
                      withPopup(valueBoxOutput("Activity_1.1", width = 12))),
                    fluidRow(
                      valueBoxOutput("Lunch.1", width = 12)),
                    fluidRow(
                      withPopup(valueBoxOutput("Activity_2.1", width = 12))),
                    fluidRow(
                      valueBoxOutput("Dinner.1", width = 12))
                ),
                
                box(width = 6,
                    title = span('Try Our Smart Recommendation!', style ="font-weight: bold;color:orange;font-size: 20px"),
                    collapsible = TRUE,
                    collapsed = TRUE,
                    fluidRow(column(12,
                                    materialSwitch(inputId = "smartmode",
                                                   label = strong(em("Activities are recommended according to the weather forecast!")),
                                                   value = FALSE,
                                                   status = "primary"))),
                    fluidRow(
                      box(DT::dataTableOutput("image"), width = 12)),
                    fluidRow(
                      withPopup(valueBoxOutput("Activity_1.2", width = 12))),
                    fluidRow(
                      valueBoxOutput("Lunch.2", width = 12)),
                    fluidRow(
                      withPopup(valueBoxOutput("Activity_2.2", width = 12))),
                    fluidRow(
                      valueBoxOutput("Dinner.2", width = 12))
                )),
              fluidRow(
                box(width =12, 
                    solidHeader = T,
                    status = 'warning',
                    title = strong("Top 20 Most Popular Attractions"),
                    wordcloud2Output("wordcloud")
                ))),
      
      
      
      #--------------------------------------
      #Weather tab
      tabItem(tabName = "Weather", 
              
              #page header
              fluidRow( box(title = h2(strong("Weather ☁"), align="center"), 
                            width = 12,
                            "Hate being caught in the rain? 
                            Before you go, make sure to check the weather forecast available on this page! 
                            The weather in Singapore can be so unpredictable - be sure to bring along an umbrella, cap and sunscreen for a full day around Singapore. 
                            Alternatively, you can check out our GoWhereSia’s smart recommendation function (itinerary tab) for a itinerary specifically tailored to the weather!"
                            ,br(),
                            br()
              )),

      fluidRow(
        
        # Row 1 for selecting time and date
        column(4,
               box(
                 title = strong('Select Date and Time'),
                 dateInput(inputId = "date", "Date:", value = Sys.Date()), 
                 timeInput(inputId = "time", "Time:", value = Sys.time()),
                 status = 'warning',
                 solidHeader = TRUE,
                 width = NULL
               )),
       column(8,
         box(
           title = strong("Today's Weather Readings"),
           status = 'info',
           solidHeader = TRUE,
           width = NULL,
           fluidRow(column(width = 10,
                           valueBoxOutput('air', width = 6),
                           valueBoxOutput('rain', width = 6))
           ),    
           
           fluidRow(column(width = 10,
                           valueBoxOutput('wind', width = 6),
                           valueBoxOutput('humidity', width = 6))
           )
         )
       )        
      ),
      
      # Row 1 for weather readings
      #  fluidRow(
      #        box(
      #        title = "Today's Weather Readings",
      #        status = 'info',
      #        solidHeader = TRUE,
      #        width = 9
      #      )
      #      
      # 
      # ),
      #  Row 2 with Weather information
      fluidRow(
        tabBox(
          title = strong('Weather Forecast'),
          #status = 'primary',
          #solidHeader = FALSE,
          #width = 6,
          # use id at the server
          id = 'tabset1', height = '700px',
          tabPanel(strong('2h'), leafletOutput('plot2h')),
          tabPanel(strong('24h'), leafletOutput('plot24h')),
          tabPanel(strong('Legend'), uiOutput('legend1')),
          tabPanel(strong('Next 4 Days'), #tableOutput('table')
                   fluidRow(valueBoxOutput('day1', width = 12)),
                   fluidRow(valueBoxOutput('day2', width = 12)),
                   fluidRow(valueBoxOutput('day3', width = 12)),
                   fluidRow(valueBoxOutput('day4', width = 12))
                   
          )
          
        ),
        
        # Column 3 with UV index information
        tabBox(
          title = strong('UV Information'),
          #width = 6,
          #use id at the server
          id = 'tabset2', height = '700px',
          #status = 'primary',
          tabPanel(strong('UV Index'), plotOutput('plotUV')),
          tabPanel(strong('UV Exposure Risk'), #renderTable('legend2')
                   fluidRow(valueBox(value = tags$p('0 - 2', style = 'font-size: 80%'),
                                     subtitle = tags$p('Low. Sun protection is not needed.', style = 'font-size: 120%'),
                                     color = 'green',
                                     icon = icon('thumbs-up', style = "font-size:80%; position:relative; right:10px;top:2px"),
                                     width = 12)),
                   fluidRow(valueBox(value = tags$p('3 - 5', style = 'font-size: 80%'),
                                     subtitle = tags$p('Moderate. Some sun protection is needed.', style = 'font-size: 120%'),
                                     color = 'yellow',
                                     icon = icon('thumbs-up', style = "font-size:80%; position:relative; right:10px;top:2px"),
                                     width = 12)),
                   fluidRow(valueBox(value = tags$p('6 - 7', style = 'font-size: 80%'),
                                     subtitle = tags$p('High. Some sun protection is needed.', style = 'font-size: 120%'),
                                     color = 'orange',
                                     icon = icon('thumbs-down', style = "font-size:80%; position:relative; right:10px;top:10px"),
                                     width = 12)),
                   fluidRow(valueBox(value = tags$p('8 - 10', style = 'font-size: 80%'),
                                     subtitle = tags$p('Very High. Extra sun protection against sunburn is needed.', style = 'font-size: 120%'),
                                     color = 'red',
                                     icon = icon('thumbs-down', style = "font-size:80%; position:relative; right:10px;top:10px"),
                                     width = 12)),
                   fluidRow(valueBox(value = tags$p('Above 11', style = 'font-size: 80%'),
                                     subtitle = tags$p('Extreme. Extra sun protection against sunburn is needed.', style = 'font-size: 120%'),
                                     color = 'purple',
                                     icon = icon('thumbs-down', style = "font-size:80%; position:relative; right:10px;top:10px"),
                                     width = 12))
                   
          )
        )
      )
    )
  )
)
#--------------------------END UI : BODY ----------------------------------------

ui <- dashboardPage(header, sidebar, body, 
                    skin = "yellow")

#server function

server <- function(input, output,session) {

  ### Printing output for Quick Search ATTRACTIONS
  selectedA <- reactive({
    selectmarker <-  input$plotA_marker_click #input$<map_id>_<shape>_click
    
    LON <- selectmarker$lon
    LAT <- selectmarker$lat
    
    if (is.null(LON) | is.null(LAT)){
      data <- strong(em("Please select attraction for more details!"))
      return(data)
    }else{
      data <- attractions %>% filter( round(as.numeric(Lat), digits = 4) == LAT & round(as.numeric(Long), digits = 4) == LON) %>% head(1)  
      
      doc <- tags$html(
        tags$title(data$Name),
        tags$body(
          h2(data$Name, style="color:#500000;font-weight:bold"),
          br(),
          #img(src= paste0(data$Name, ".jpg"), width = '100%'),
          #br(),
          #br(),
          p(strong("Description: "), 
            data$Description,
            style="color:#000000"),
          
          p(strong("Opening Hour: "), 
            data$Opening_Hour,
            style="color:#000000"),
          
          p(strong("Address: "), 
            data$Address, 
            style="color:#000000"),                         
          
          p(strong("Link:"),
            tags$a(data$Link, 
            href = data$Link),
            style="color:#000000")
        ))
      return(doc)
    }
    
  })
  
  output$showATTRACTIONS <- renderUI(selected())
          
  ###------ Restaurants Details --------- ###
  selectedR <- reactive({
    selectmarker <-  input$plotR_marker_click #input$<map_id>_<shape>_click
    
    LON <- selectmarker$lon
    LAT <- selectmarker$lat
    
    if (is.null(LON) | is.null(LAT)){
      data <- strong(em("Please select restaurants for more details!"))
      return(data)
    }else{
      
      data <- restaurants %>% filter( round(as.numeric(Lat), digits = 4) == LAT & round(as.numeric(Long), digits = 4) == LON) %>% head(1)  
      
      doc <- tags$html(
        tags$title(data$Name),
        tags$body(
          h2(data$Name, style="color:#500000;font-weight:bold"),
          
          br(),
          
          p(strong("Price: "), 
            data$Price,
            style="color:#000000"),
          
          p(strong("Opening Hour: "), 
            data$Hours,
            style="color:#000000"),
          
          p(strong("Address: "), 
            data$Address, 
            style="color:#000000"),                         
          
          p(strong("Good For:"),
            data$Good.For,
            style="color:#000000")
        ))
      return(doc)
    }
    
  })
  
  output$showATTRACTIONS <- renderUI(selectedA())
  output$showRESTAURANTS <- renderUI(selectedR())
  
  
  ###--- HOME PAGE HYPERLINKS ---###
  observeEvent(input$quicksearch, {
    updateTabsetPanel(session = session, inputId = "tabs", selected = "dashboard") })
  
  
  observeEvent(input$foodguide, {
    updateTabsetPanel(session = session, inputId = "tabs", selected = "dashboard") })
  
  
  observeEvent(input$weather, {
    updateTabsetPanel(session = session, inputId = "tabs", selected = "Weather") })
  
  
  
  observeEvent(input$itinerary, {
    updateTabsetPanel(session = session, inputId = "tabs", selected = "itinerary") })
  
  
  observeEvent(input$crowdinfo, {
    updateTabsetPanel(session = session, inputId = "tabs", selected = "Crowd_Info") })
  
  
  observeEvent(input$latestnews, {
    updateTabsetPanel(session = session, inputId = "tabs", selected = "News") })
  
  
  
  
  #######----------------OUTPUT: ITINERARY---------------------------
  # Hide all the activity box first
  itinerary_names <- list("Activity_1.1","Lunch.1", "Activity_2.1","Dinner.1",
                          "Activity_1.2","Lunch.2","Activity_2.2","Dinner.2")
  
  # Hide all the activity box first
  for (i in itinerary_names){toggle(i)}
  
  # Show the activity if user presses action button
  observeEvent(input$go, {
    for (i in itinerary_names[1:4]){toggle(i)}
  })
  
  observeEvent(input$smartmode, {
    if (input$smartmode == 'TRUE'){
      for (i in itinerary_names[5:8]){show(i)}     
    }else
    {
      for (i in itinerary_names[5:8]){hide(i)}  
    }
  })
  
  # Filter option for user
  output$selectprice <- renderUI({
    selectInput("Price","Price:",c("$" = "$",
                                   "$$" = "$$",
                                   "$$$" = "$$$"))
  })
  
  output$selecttype <- renderUI({
    selectInput("Type","Type:",c("Indoors" = "Indoors",
                                 "Outdoors" = "Outdoors"))
  })
  
  # Personalized Box Dataset Preparation - Activity  
  data_input1 <- reactive({
    req(input$Price)
    req(input$Type)
    req(input$go)
    data1 <- df1[df1["Price"] == input$Price,]
    data1 <- data1[data1["Indoor.outdoors"] == input$Type,]
  })
  
  # Smart Recommendation Dataset Preparation - Activity
  data_input2 <- reactive({
    if(input$smartmode == 'TRUE'){
      data2 <- data.frame(matrix(ncol = ncol(df1), nrow = 0)) 
      for (i in 1:nrow(wdata)){
        data <- df1[df1["region"] == tolower(wdata[i,'region']),]
        #if raining
        if (grepl("Showers",wdata[i,'forecast']) == 'TRUE'){
          data <- data[data['Indoor.outdoors'] == 'Indoors',]
        }
        data2 <-rbind(data2, data)
      }
      
      data2 <- data2}
  })
  
  # Restaurant Dataset Preparation    
  data_input3 <- reactive({  
    req(input$Price)
    restaurants <- read.csv("RestaurantsFull.csv") 
    df3 <- restaurants %>% mutate(popup_info = Name) %>% drop_na('Price')
    df3[(df3['Price'] == '$$$$'|df3['Price'] == '$$$$$'|df3['Price'] == '$$$$$$$'),'Price'] <- "$$$"
    hawker <- read.csv("HCFull.csv") 
    hawker <- hawker %>% rename(Name=name_of_centre)
    
    if (input$Price == '$'){
      df3 <- hawker
    }else
    {df3[df3["Price"] == input$Price,]}
    
    len <- nrow(df3)
    n <- sample(c(1:len), size = 2)
    foodrecom <- df3[n, ]
  })  
  
  observeEvent(data_input1(), {
    data1 <<- data_input1()
  })
  
  observeEvent(data_input2(), {
    data2 <<- data_input2()
  })
  
  counter <- reactiveValues(countervalue1 = 0,countervalue2 = 0,
                            countervalue3 = 0,countervalue4 = 0) 
  
  activity <- reactiveValues(a1 = NULL, a2 = NULL, a3 = NULL, a4 = NULL)
  
  # Shorter Visiting Period for Morning Activity - Personalized
  output$Activity_1.1 <- renderValueBox({
    data1 <- data_input1()
    data1_less <- data1[data1['Duration..hr.'] < 2,]
    
    # random generator
    len <- nrow(data1_less)
    n <- sample(c(1:len), size = 1)
    activity_1.1 <- data1_less[n, ]
    activity$a1 <- activity_1.1$Name
    
    valueBox(value = actionLink(
      inputId = "box1link",
      label = div(activity_1.1$Name, style = "color: white;font-size: 50%;")),
      subtitle = paste(activity_1.1$Duration..hr., "hr"), 
      icon = icon("camera", lib = "glyphicon",style = "font-size:80%; position:relative;right:10px;top:20px"),
      color = "yellow"
    )
  })
  
  # Shorter Visiting Period for Morning Activity - Smart  
  output$Activity_1.2 <- renderValueBox({
    data2 <- data_input2()
    data2_less <- data2[data2['Duration..hr.'] < 2,]
    
    # random generator
    len <- nrow(data2_less)
    n <- sample(c(1:len), size = 1)
    activity_1.2 <- data2_less[n, ]
    activity$a3 <- activity_1.2$Name
    
    valueBox(value = actionLink(
      inputId = "box3link",
      label = div(activity_1.2$Name, style = "color: white;font-size: 50%;")), 
      paste(activity_1.2$Duration..hr., "hr [", activity_1.2$Indoor.outdoors,",",activity_1.2$region, "]"), 
      icon = icon("camera", lib = "glyphicon",style = "font-size:80%; position:relative;right:10px;top:20px"),
      color = "yellow"
    )
  })
  
  # Longer Visiting Period for Afternoon Activity -Personalised
  output$Activity_2.1 <- renderValueBox({
    data1 <- data_input1()
    data1_more <- data1[data1['Duration..hr.'] >= 2,]
    
    # random generator
    len <- nrow(data1_more)
    n <- sample(c(1:len), size = 1)
    activity_2.1 <- data1_more[n, ]
    activity$a2 <- activity_2.1$Name
    
    valueBox(value = actionLink(
      inputId = "box2link",
      label = div(activity_2.1$Name, style = "color: white;font-size: 50%;")), 
      paste(activity_2.1$Duration..hr., "hr"), 
      icon = icon("sunglasses", lib = "glyphicon",style = "font-size:80%; position:relative;right:10px;top:20px"),
      color = "purple")
    
  })  
  
  # Longer Visiting Period for Afternoon Activity  - Smart
  output$Activity_2.2 <- renderValueBox({
    data2 <- data_input2()
    data2_more <- data2[data2['Duration..hr.'] >= 2,]
    
    # random generator
    len <- nrow(data2_more)
    n <- sample(c(1:len), size = 1)
    activity_2.2 <- data2_more[n, ]
    activity$a4 <- activity_2.2$Name
    
    valueBox(value = actionLink(
      inputId = "box4link",
      label = div(activity_2.2$Name, style = "color: white;font-size: 50%;")),
      paste(activity_2.2$Duration..hr., "hr [", activity_2.2$Indoor.outdoors,",",activity_2.2$region,"]"), 
      icon = icon("sunglasses", lib = "glyphicon",style = "font-size:80%; position:relative;right:10px;top:20px"),
      color = "purple")
    
  })
  
  observeEvent(input$box1link, {
    counter$countervalue1 <- counter$countervalue1 + 1 
    if (counter$countervalue1 > 0){
      updateTabsetPanel(session = session, inputId = "tabs", selected = "Crowd_Info")
      updateSelectInput(session = session, inputId = "attraction_type",selected = activity$a1)
    }
  })
  
  observeEvent(input$box2link, {
    counter$countervalue2 <- counter$countervalue2 + 1 
    if (counter$countervalue2 > 0){
      updateTabsetPanel(session = session, inputId = "tabs", selected = "Crowd_Info")
      updateSelectInput(session = session, inputId = "attraction_type",selected = activity$a2)
    }
  })
  
  observeEvent(input$box3link, {
    counter$countervalue3 <- counter$countervalue3 + 1 
    if (counter$countervalue3 > 0){
      updateTabsetPanel(session = session, inputId = "tabs", selected = "Crowd_Info")
      updateSelectInput(session = session, inputId = "attraction_type",selected = activity$a3)
    }
  })
  
  observeEvent(input$box4link, {
    counter$countervalue4 <- counter$countervalue4 + 1 
    if (counter$countervalue4 > 0){
      updateTabsetPanel(session = session, inputId = "tabs", selected = "Crowd_Info")
      updateSelectInput(session = session, inputId = "attraction_type",selected = activity$a4)
    }
  })
  
  observeEvent(data_input3(), {
    foodrecom <<- data_input3()
  }) 
  
  output$Lunch.1 <- output$Lunch.2 <- renderValueBox({
    foodrecom <- data_input3()
    lunch <- foodrecom[1, ]
    if (input$Price != '$'){
      valueBox(tags$p(lunch$Name, style = "font-size: 50%;"),
               paste("1 hr", "[",lunch$Cuisine,"]"), 
               icon = icon("cutlery", lib = "glyphicon",style = "font-size:80%; position:relative;right:10px;top:20px"),
               color = "blue")
    } else
    {
      valueBox(tags$p(lunch$Name, style = "font-size: 50%;"),
               paste("1 hr", "[Number of stalls:",lunch$no_of_stalls,"]"), 
               icon = icon("cutlery", lib = "glyphicon",style = "font-size:80%; position:relative;right:10px;top:20px"),
               color = "blue")
    }
  })   
  
  output$Dinner.1 <- output$Dinner.2 <- renderValueBox({
    foodrecom <- data_input3()
    dinner <- foodrecom[2, ]
    if (input$Price != '$'){
      valueBox(tags$p(dinner$Name, style = "font-size: 50%;"),
               paste("1 hr", "[",dinner$Cuisine,"]"), 
               icon = icon("cutlery", lib = "glyphicon",style = "font-size:80%; position:relative;right:10px;top:20px"),
               color = "blue")
    }else
    { valueBox(tags$p(dinner$Name, style = "font-size: 50%;"),
               paste("1 hr", "[Number of stalls:",dinner$no_of_stalls,"]"), 
               icon = icon("cutlery", lib = "glyphicon",style = "font-size:80%; position:relative;right:10px;top:20px"),
               color = "blue")
    }
  }) 
  
  ##------Image and text for smart recommendation-----------
  image_input <- reactive({ 
    req(input$smartmode)
    if (input$smartmode == 'TRUE'){
      wdata.icon <- wdata.icon
    }
  })
  
  headerCallback <- c(
    "function(thead, data, start, end, display){",
    "  $('th', thead).css('display', 'none');
    $('table.dataTable.no-footer').css('border-bottom', 'none');",
    "}"
  )
  
  output$image <- DT::renderDataTable({
    wdata.icon <- image_input()
    DT::datatable(wdata.icon, 
                  options = list(autoWidth = TRUE,scrollX=TRUE,
                                 headerCallback = JS(headerCallback),
                                 paging = FALSE,
                                 searching = FALSE,
                                 info = FALSE),
                  escape=FALSE,
                  rownames=FALSE)%>% DT::formatStyle(columns = c(1:5), width='80px')
  })
  
  #######---------------- END OF ITINERARY-------------------------
  
  #######-------------- OUTPUT: NEWS -----------------------------
  
  # customize the length drop-down menu; display 15 rows per page by default
  output$news <- DT::renderDataTable({
    DT::datatable(df, 
                  options = list(lengthMenu = c(15, 30, 50),
                                 pageLength = 15, autoWidth = TRUE,
                                 headerCallback = JS(headerCallback)),
                  escape=FALSE,
                  rownames=FALSE)
  })
  #######-------------- END OF NEWS------------------
  
  #######----------------OUTPUT: attraction map -------------------
  output$plotA <-renderGoogle_map(
    {
      # catching the error 
      attractions <- read.csv("attractions_cleanedfinal.csv")
      df1 <- attractions %>% mutate(link_clean = ifelse(is.na(attractions$Link)," ",attractions$Link), 
                                    price_num = nchar(Price))%>% 
        dplyr::filter(price_num == input$PriceA) %>% 
        mutate(popup_info = paste(Name, link_clean)) 
      # attractions
      google_map(data = df1, key = api_key ,search_box = TRUE ) %>% 
        add_markers( lon= df1$Long, lat = df1$Lat , mouse_over= df1$popup_info)
    })

######### Observe Event Here ##############################  
  
  observeEvent(input$PriceA, {
    df1 <- attractions %>% mutate(link_clean = ifelse(is.na(attractions$Link)," ",attractions$Link), 
                                  price_num = nchar(Price))%>% 
      dplyr::filter(price_num == input$PriceA) %>% 
      mutate(popup_info = paste(Name, link_clean))
    
    google_map_update(map_id = "plotA") %>% clear_markers() %>%
      add_markers(data = df1, mouse_over = df1$popup_info)
  })
  
  #----------------------output: restaurants map -------------------
  output$plotR <- renderGoogle_map(
    {
      df2 <- compiled_rh %>% dplyr::filter(as.integer(Price) == as.integer(input$PriceR),grepl(input$Cuisine,compiled_rh$Cuisine)) %>% 
        mutate(popup_info = paste(Name, Cuisine)) 
      
      google_map(data = df2, key = api_key,search_box = TRUE ) %>% 
        add_markers(lon = df2$Long, lat = df2$Lat , 
                    mouse_over = df2$Name, 
                    colour = "Colour",
                    layer_id = "Restaurants") 
    })
  
  observeEvent(c(input$PriceR, input$Cuisine), {
    
    df2 <- compiled_rh %>% dplyr::filter(Price == input$PriceR, grepl(input$Cuisine, compiled_rh$Cuisine)) %>% 
      mutate(popup_info = Name) 
    #------------------------------------------------------------------------------------------------------------------------
    if(nrow(df2) <= 0){
      google_map_update(map_id = "plotR") %>% clear_markers(layer_id = "Restaurants")
    } else {
    google_map_update(map_id = "plotR") %>% clear_markers(layer_id = "Restaurants") %>%
      add_markers(data = df2,
                  mouse_over= "popup_info",
                  lat = "Lat",
                  lon = "Long",
                  colour = "Colour", 
                  layer_id = "Restaurants")}
  })
  
  observeEvent(input$SMbrand1, {
    sm_data <- read.csv("supermarkets_clean.csv") %>% dplyr::filter(business_name == input$SMbrand1)

    google_map_update(map_id = "plotS") %>% clear_markers(layer_id = "Supermarket") %>% 
      add_markers(data = sm_data,
                  lat = "Lat",
                  lon = "Long",
                  mouse_over = paste0(sm_data$business_name, ":", sm_data$premise_address),
                  opacity = 1, layer_id = "Supermarket")
    
  })
  
  
  
 
  #----------------------output: Supermarkets map -------------------
  output$plotS <- renderGoogle_map( 
    {
      sm_data <- read.csv("supermarkets_clean.csv") %>% dplyr::filter(business_name == input$SMbrand1)
      
      google_map(data=sm_data, key = api_key, search_box = TRUE) %>% 
        add_markers(lon = sm_data$Long, lat = sm_data$Lat, 
                    mouse_over = paste0(sm_data$business_name, ":", sm_data$premise_address),
                    opacity = 1, layer_id = "Supermarket")
      
    })
  
  output$info_supermarket_selected <- renderInfoBox({
    infoBox("Selected supermarket:",input$SMBrand1, icon = icon("list"),color = "purple",fill = TRUE)})
  
  #----------------------output: crowd heat map -------------------
  output$plotcrowd <- renderLeaflet(
    {
      #reading cleaned data
      days_weeks <- c("Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday")
      day_today <- weekdays(Sys.Date())
      clean_data <- read.csv("attractions_cleanedfinal.csv") %>%
        pivot_longer(cols = all_of(days_weeks),names_to= "Day",values_to= "Crowd_level") %>% 
        dplyr::filter(Day==day_today)
      
      #jitter the coordinates to ensure that the markers don't overlap 
      clean_data$lat <- jitter(clean_data$Lat, factor = 0.001)
      clean_data$Long <- jitter(clean_data$Long, factor = 0.001)
      
      #creating a list of icons 
      myicons <- iconList(
        "not crowded" = makeIcon("https://cdn-icons-png.flaticon.com/512/190/190411.png",
                                 iconWidth = 20, iconHeight = 20),
        "some crowd" = makeIcon("https://www.pinclipart.com/picdir/big/568-5689042_blank-caution-sign-clipart-png-download.png",iconWidth = 20, iconHeight = 20),
        "crowded" = makeIcon("https://cdn-icons-png.flaticon.com/512/5854/5854013.png",iconWidth = 20, iconHeight = 20),
        "max" = makeIcon("https://cdn-icons-png.flaticon.com/512/594/594739.png",iconWidth = 20, iconHeight = 20),
        "closed" = makeIcon("https://cdn-icons-png.flaticon.com/512/694/694604.png",iconWidth = 20, iconHeight = 20),
        "temporarily closed" = makeIcon("https://cdn-icons-png.flaticon.com/512/694/694604.png",iconWidth = 20, iconHeight = 20),
        "No data" = makeIcon("https://cdn-icons-png.flaticon.com/512/599/599618.png",iconWidth = 20, iconHeight = 20))
      
      
      html_legend <- "<img src='https://cdn-icons-png.flaticon.com/512/190/190411.png' style='width:12px;height:12px;'> Not Crowded<br/>
<img src='https://www.pinclipart.com/picdir/big/568-5689042_blank-caution-sign-clipart-png-download.png' style='width:12px;height:12px;'> Some Crowd<br/>
<img src='https://cdn-icons-png.flaticon.com/512/5854/5854013.png' style='width:12px;height:12px;'> Crowded <br/>
<img src='https://cdn-icons-png.flaticon.com/512/594/594739.png' style='width:12px;height:12px;'> Max Capacity<br/>
<img src='https://cdn-icons-png.flaticon.com/512/694/694604.png' style='width:12px;height:12px;'> Closed or Temporarily Closed <br/>
<img src='https://cdn-icons-png.flaticon.com/512/599/599618.png' style='width:12px;height:12px;'> No Data "
      
      # Creating a icon map 
      selected_attraction <- attractions %>% dplyr::filter(Name == input$attraction_type) 
      icon_map_crowd <- clean_data %>% leaflet() %>% addTiles() %>% 
        setView(lng = selected_attraction$Long,lat = selected_attraction$Lat,16) %>%
        addMarkers(lng=~Long,lat=~Lat, icon= ~myicons[Crowd_level],popup= ~Name)%>% 
        addControl(html = html_legend, position = "bottomleft")
      
    })
  #----------------------output: crowd barchart  -------------------
  output$crowd_information <- renderPlot(
    {
      attractions <- read.csv("attractions_cleanedfinal.csv")
      library(ggplot2)
      library(tidyr)
      
      # Turning the data into longer format and convert the values into "crowdedness" 
      days_week <- c("Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday")
      attractions_long <- attractions %>% pivot_longer(cols = all_of(days_week),
                                                       names_to= "Day",values_to= "Crowd_level") %>% 
        mutate(crowd_level_num = ifelse(Crowd_level == "No data"|Crowd_level == "closed"|Crowd_level == "temporarily closed", 0.01, 
                                        ifelse(Crowd_level == "not crowded",1,
                                               ifelse(Crowd_level == "some crowd", 2, 
                                                      ifelse(Crowd_level == "crowded", 3 ,4)))))
      
      
      selected_attraction <- attractions_long %>% dplyr::filter(Name == input$attraction_type)
      ggplot(data=selected_attraction, aes(x=Day,y=crowd_level_num)) + 
        geom_bar(stat = "identity",aes(fill= Day)) +
        scale_x_discrete(limits = all_of(days_week)) +
        labs(title = "Crowd Level against days of the week",y = "Crowd Level ", x = "Days of the week") +
        geom_text(aes(label = str_wrap(Crowd_level,width = 7)), vjust = -0.3,colour = "Black", size = 3.5) + ylim(0, 3)
      
      
    }
  )
  #----------------------output: supermarket rankings -------------------
  output$Supermarket_Rankings <- renderPlot(
    {
      supermarkets <- read.csv("supermarkets_clean.csv") 
      
      supermarket_ranking <- supermarkets %>% group_by(business_name) %>% summarise(number_of_stores = n()) %>% arrange(-number_of_stores) %>%
        slice_head(n=10) %>% arrange(number_of_stores)
      rank <- supermarket_ranking %>% select(business_name) 
      ranking <- as.vector(unlist(rank))
      ggplot(supermarket_ranking, aes(x = business_name, y = number_of_stores))+
        geom_col(aes(fill = business_name), width = 0.7) + 
        scale_x_discrete(limits = ranking) +
        labs(title = "No. of stores from supermarket chains",y = "Number of stores" , x = "Supermarket") +
        coord_flip() 
    }
  )
  
  #----------------------output: Display Information on the various attractions  -------------------
  output$AttractionName <- renderInfoBox({
    infoBox("Selected Attraction:",input$attraction_type , icon = icon("list"), color = "aqua", fill = TRUE)
  })
  output$AttractionOH <- renderInfoBox({
    selectedloc <- attractions %>% dplyr::filter(Name == input$attraction_type)
    infoBox("Opening Hours:",selectedloc$Opening_Hour , icon = icon("list"),color = "blue",fill = TRUE)
  })
  output$AttractionDesc <- renderInfoBox({
    selectedloc <- attractions %>% dplyr::filter(Name == input$attraction_type)
    infoBox("Description:",selectedloc$Description , icon = icon("list"),color = "teal",fill = TRUE)
  })
  output$AttractionLink <- renderInfoBox({
    selectedloc <- attractions %>% dplyr::filter(Name == input$attraction_type)
    infoBox("Link:", selectedloc$Link , icon = icon("list"),color = "olive",fill = TRUE, href = selectedloc$Link )
  })
  output$AttractionPrice <- renderInfoBox({
    selectedloc <- attractions %>% dplyr::filter(Name == input$attraction_type)
    infoBox("Price:",selectedloc$Price , icon = icon("list"),color = "light-blue",fill = TRUE)
  })
  
  #--------------------output : wordcloud ---------------------------------------
  output$wordcloud <- renderWordcloud2({
    data <- read.csv('TripAdvisorAttractionData.csv')
    
    top22 <- data %>% select(place.name) %>% slice(1:22)
    
    # Changing the names so that it can fit the word cloud
    top20 <- as.data.frame(top22[-c(7, 17), ])
    colnames(top20) <- c('name')
    top20[6, ] <- 'Sands Skypark'
    top20$freq <- 20:1
    
    wordcloud2(data=top20, size=0.3, color=rep_len( c("#F96E61","#FEB97D","#D94B58", "#E3534C"), nrow(top20)), minRotation = 0, maxRotation = 0 )
  })
  
  # initilising leaflet
  m <- leaflet() %>% addTiles()
  
  # Customised weather icons
  weathers <- data.frame( weather = c( "Fair (Day)",
                                       'Fair (Night)',
                                       "Cloudy",
                                       "Partly Cloudy (Day)",
                                       "Partly Cloudy (Night)",
                                       "Light Showers",
                                       "Light Rain",
                                       "Showers",
                                       "Moderate Rain",
                                       "Thundery Showers"    ),
                          
                          icon.link = c("https://cdn-icons-png.flaticon.com/512/2698/2698194.png",
                                        "https://cdn-icons-png.flaticon.com/512/3590/3590251.png",
                                        'https://cdn-icons-png.flaticon.com/512/3313/3313983.png',
                                        "https://cdn-icons-png.flaticon.com/512/3208/3208752.png",
                                        "https://cdn-icons-png.flaticon.com/512/2675/2675857.png",
                                        "https://cdn-icons-png.flaticon.com/512/3075/3075858.png",
                                        "https://cdn-icons-png.flaticon.com/512/3075/3075858.png",
                                        "https://cdn-icons-png.flaticon.com/512/3520/3520675.png",
                                        "https://cdn-icons-png.flaticon.com/512/3520/3520675.png",
                                        "https://cdn-icons-png.flaticon.com/512/1146/1146860.png") )
  
  #----------- Output portion for weather forecast ---------------------
  # Output for 2h weather forecast
  output$plot2h <- renderLeaflet({
    date <- as.character(input$date)
    time <- strftime(input$time, "%T")
    
    data <- get2hrData(date,time)
    
    data <- inner_join(data, weathers, by = c('forecast' = 'weather'))
    
    m <- addMarkers(m,
                    lng=data$long,
                    lat=data$lat,
                    label= data$location,
                    popup = paste('Region:', data$area, '<br>',
                                  'Forecast:', data$forecast, '<br>'),
                    icon = makeIcon( iconUrl = data$icon.link,
                                     iconWidth = 38,
                                     iconHeight = 38) ) %>% addProviderTiles("CartoDB.Positron")
    
    ## Adding different types of maps
    m <- addTiles(m, group = 'Default')
    m <- addProviderTiles(m, 'Esri.WorldImagery', group = 'Esri')
    m <- addProviderTiles(m, 'Stamen.Toner', group = 'Toner')
    m <- addProviderTiles(m, 'Stamen.TonerLite', group = 'Toner Lite')
    
    m <- addLayersControl(m, baseGroups = c('Default', 'Esri', 'Toner Lite', 'Toner'))
    
    m
  }
  
  )
  
  
  output$plot24h <-renderLeaflet({
    
    date <- as.character(input$date)
    
    data <- get24hrData(date)
    
    data <- inner_join(data, weathers, by = c('forecast' = 'weather'))
    
    m <- addMarkers(m,
                    lng=data$long,
                    lat=data$lat,
                    label= data$location,
                    popup = paste('Region:', data$region, '<br>',
                                  'Forecast:', data$forecast, '<br>'),
                    icon = makeIcon( iconUrl = data$icon.link,
                                     iconWidth = 38,
                                     iconHeight = 38) ) %>% addProviderTiles("CartoDB.Positron")
    
    ## Adding different types of maps
    m <- addTiles(m, group = 'Default')
    m <- addProviderTiles(m, 'Esri.WorldImagery', group = 'Esri')
    m <- addProviderTiles(m, 'Stamen.Toner', group = 'Toner')
    m <- addProviderTiles(m, 'Stamen.TonerLite', group = 'Toner Lite')
    
    m <- addLayersControl(m, baseGroups = c('Default', 'Esri', 'Toner Lite', 'Toner'))
    
    m
    
  }
  
  )
  
  output$plotUV <- renderPlot({
    
    date <- as.character(input$date)
    
    data <- getUVdata(date)
    
    legend <- 'UV Index'
    ggplot(data, aes(x = timestamp, y = value, color = as.factor(color))) + geom_line(group = 1) + 
      geom_point() + scale_color_manual(legend, values = c('#AFB83B', '#FAD000', '#FF9933', '#B8255F', '#884DFF')) +
      ylab('UV Index') + xlab('Time of Day') + theme_dark() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
                                                                    axis.text.x = element_text(size = 12), axis.text.y = element_text(size = 12))
  }, height = 600)
  
  
 
  
  output$day1 <- renderValueBox({
    
    date <- as.character(input$date)
    data <- getColor(date)
    data <- data[1, ]
    
    valueBox(value = tags$p(paste0(data$Date, ' ', data$Day), style = 'font-size: 80%'),
             subtitle = tags$p(data$Forecast, style = 'font-size: 120%'),
             color = as.character(data$Color),
             icon = icon('calendar-week', style = "font-size:80%; position:relative; right:10px;top:2px"),
             width = 12)
  })
  
  output$day2 <- renderValueBox({
    
    date <- as.character(input$date)
    data <- getColor(date)
    data <- data[2, ]
    
    valueBox(value = tags$p(paste0(data$Date, ' ', data$Day), style = 'font-size: 80%'),
             subtitle = tags$p(data$Forecast, style = 'font-size: 120%'),
             color = as.character(data$Color),
             icon = icon('calendar-week', style = "font-size:80%; position:relative; right:10px;top:2px"),
             width = 12)
  })
  
  output$day3 <- renderValueBox({
    
    date <- as.character(input$date)
    data <- getColor(date)
    data <- data[3, ]
    
    valueBox(value = tags$p(paste0(data$Date, ' ', data$Day), style = 'font-size: 80%'),
             subtitle = tags$p(data$Forecast, style = 'font-size: 120%'),
             color = as.character(data$Color),
             icon = icon('calendar-week', style = "font-size:80%; position:relative; right:10px;top:2px")
    )
  })
  
  output$day4 <- renderValueBox({
    
    date <- as.character(input$date)
    data <- getColor(date)
    data <- data[4, ]
    
    valueBox(value = tags$p(paste0(data$Date, ' ', data$Day), style = 'font-size: 80%'),
             subtitle = tags$p(data$Forecast, style = 'font-size: 120%'),
             color = as.character(data$Color),
             icon = icon('calendar-week', style = "font-size:80%; position:relative; right:10px;top:2px")
    )
  })
  
  output$air <- renderValueBox({
    date <- as.character(input$date)
    data <- getAirdata(date) 
    
    valueBox(value = tags$p(paste0(data, ' ', '°C'), style = 'font-size: 60%'),
             subtitle = tags$p('Air Temperature', style = 'font-size: 120%'),
             color = 'aqua',
             icon = icon('temperature-high', style = "font-size:80%; position:relative; right:10px;top:2px")
             
    )
    
    
  })
  
  output$rain <- renderValueBox({
    date <- as.character(input$date)
    data <- getRaindata(date) 
    
    valueBox(value = tags$p(paste0(data, ' ', 'mm'), style = 'font-size: 60%'),
             subtitle = tags$p('Rainfall', style = 'font-size: 120%'),
             color = 'light-blue',
             icon = icon('cloud-rain', style = "font-size:80%; position:relative; right:15px;top:2px")
             
    )
    
    
  })
  
  output$wind <- renderValueBox({
    date <- as.character(input$date)
    data <- getWinddata(date) 
    
    valueBox(value = tags$p(paste0(data, ' ', 'km/h'), style = 'font-size: 60%'),
             subtitle = tags$p('Wind Speed', style = 'font-size: 120%'),
             color = 'blue',
             icon = icon('wind', style = "font-size:80%; position:relative; right:15px;top:2px")
    )
    
    
  })
  
  output$humidity <- renderValueBox({
    date <- as.character(input$date)
    data <- getHumiditydata(date) 
    
    valueBox(value = tags$p(paste0(data, ' ', '%'), style = 'font-size: 60%'),
             subtitle = tags$p('Humidity', style = 'font-size: 120%'),
             color = 'teal',
             icon = icon('hotjar', lib = 'font-awesome', style = "font-size:80%; position:relative; right:15px;top:2px")
    )
    
    
  })
  
  output$legend1 <- renderUI(
    tags$html(
      tags$body(
        fluidRow(
          # Fair Day
          column(3, align = "center", div(img(src='https://cdn-icons-png.flaticon.com/512/2698/2698194.png',
                                              style="height: 60px",
                                              height = 70, HTML('<figcaption><span style="font-weight:bold">Fair (Day)</span></figcaption><br>'))
          )),
          
          
          # Fair Night
          column(3, align = "center", div(img(src='https://cdn-icons-png.flaticon.com/512/3590/3590251.png',
                                              style="height: 60px",
                                              height = 70, HTML('<figcaption><span style="font-weight:bold">Fair (Night)</span></figcaption><br>'))
          )),
          
          
          # Cloudy
          column(3, align = "center", div(img(src='https://cdn-icons-png.flaticon.com/512/3313/3313983.png',
                                              style="height: 60px",
                                              height = 70, HTML('<figcaption><span style="font-weight:bold">Cloudy</span></figcaption><br>'))
          )),
          
          
          # Partly Cloudy(Day)
          column(3, align = "center", div(img(src='https://cdn-icons-png.flaticon.com/512/3208/3208752.png',
                                              style="height: 60px",
                                              height = 70, HTML('<figcaption><span style="font-weight:bold">Partly Cloudy (Day)</span></figcaption><br>'))
          )),
          
          hr(),
          
          # Partly Cloudy (Night)
          column(3, align = "center",div(img(src='https://cdn-icons-png.flaticon.com/512/2675/2675857.png',
                                             style="height: 60px",
                                             height = 70, HTML('<figcaption><span style="font-weight:bold">Partly Cloudy (Night)</span></figcaption><br>'))
          )),
          
          
          # Light Showers
          column(3, align = "center",div(img(src='https://cdn-icons-png.flaticon.com/512/3075/3075858.png',
                                             style= 'height:60px',
                                             height = 70, HTML('<figcaption><span style="font-weight:bold">Light Showers</span></figcaption><br>'))
          )),
          
          
          # Showers
          column(3, align = "center",div(img(src='https://cdn-icons-png.flaticon.com/512/3520/3520675.png',
                                             style="height: 60px",
                                             height = 70, HTML('<figcaption><span style="font-weight:bold">Showers</span></figcaption><br>'))
          )),
          
          
          # Moderate Rain
          column(3, align = "center",div(img(src='https://cdn-icons-png.flaticon.com/512/3520/3520675.png',
                                             style="height: 60px",
                                             height = 70, HTML('<figcaption><span style="font-weight:bold">Moderate Rain</span></figcaption><br>'))
          )),
          
          
          # Thundery Showers
          column(3, align = "center",div(img(src='https://cdn-icons-png.flaticon.com/512/1146/1146860.png',
                                             style="height: 60px",
                                             height = 70, HTML('<figcaption><span style="font-weight:bold">Thundery Showers</span></figcaption>')))
          )
          
        )
      )
    )
  )
}



shinyApp(ui = ui , server = server)
