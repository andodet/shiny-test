library(shiny)


ui = dashboardPagePlus(
  header = dashboardHeaderPlus(
    title = "Test Dashboard",
    enable_rightsidebar = TRUE,
    rightSidebarIcon = "filter",
    tags$li(
      class = "dropdown",
      style = "padding: 8px;
               float: right;",
      shinyauthr::logoutUI("logout")
    )
    
  ),
  
  sidebar = dashboardSidebar(#tags$div(id = 'l_sidebar')
    collapsed = TRUE,
    sidebarMenuOutput("l_sidebar")),
  
  rightsidebar = rightSidebar(
    background = "dark",
    width = 400,
    sidebarMenuOutput("r_sidebar")
    ),

  body <- dashboardBody(
    tags$head(
      tags$style(
        HTML('.content{padding-left: 30px;
      margin-right: 15px;}'
             ))),
    
    shinyjs::useShinyjs(),
    shinyauthr::loginUI("login"),
    
    ## sales_recap tab ---------------------
    # Topbar stats -------------
    tabItems(
      tabItem(
        tabName = "sales_recap",
        fluidRow(
          valueBoxOutput("orders", width = 3),
          valueBoxOutput("tot_revenue", width = 3),
          valueBoxOutput("aov", width = 3),
          valueBoxOutput("approval_time", width = 3)
        ),
        
        
        fluidRow(uiOutput("sales_plot")),
        fluidRow(uiOutput("sales_tbox"))
        # fluidRow(uiOutput("sales_recap_table"),
        #          uiOutput("categ_recap_table"),
        #          uiOutput("city_recap_table")
        # )
      ),
      
      tabItem(
        tabName = 'dispatching',
        fluidRow(
          uiOutput("ops_tbox")
        )
      )
    )
    
  )
)