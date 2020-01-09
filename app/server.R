library(shiny)
source("./global.R")

shinyOptions(cache = RedisCache$new(namespace = "redis_test"))

server <- function(input, output) {
  # login status info
  credentials <- callModule(
    shinyauthr::login,
    "login",
    data = user_base,
    user_col = user,
    pwd_col = password,
    sodium_hashed = TRUE,
    log_out = reactive(logout_init())
  )
  
  logout_init <- callModule(shinyauthr::logout,
                            "logout",
                            reactive(credentials()$user_auth))
  
  # Open/close sidebar on login
  #TODO: remove sidebar instead of hiding it
  observe({
    if (credentials()$user_auth) {
      print("Logged in: expanding sidebar")
    } else {
      print("Login Screen: Sidebar collapsed")
      
    }
  })
  
  # Left sidebar
  output$l_sidebar <- renderMenu({
    req(credentials()$user_auth)
    sidebarMenu(
      menuItem('Sales', tabName = "sales_recap", icon = icon("dashboard")),
      menuItem('Operations', tabName = "dispatching", icon = icon("box "))
    )
  })
  
  # Right sidebar
  output$r_sidebar <- renderMenu({
    req(credentials()$user_auth)
    rightSidebar(
      background = "dark",
      width = 400,
      rightSidebarTabContent(
        id = 'right_sidebar',
        icon = "sliders-h",
        active = TRUE,
        dateRangeInput("date_input", label = "Select Dates", format = 'yyyy-mm-dd',
                       start = "2016-09-04", end = "2017-03-01"),
        
        selectInput(
          "status",
          label = "Order Status",
          choices = o_status,
          selected =
            c("delivered", "invoiced", "shipped", "approved"),
          multiple = TRUE
        ),
        
        pickerInput(
          "categs",
          choices = categs,
          selected = unlist(categs, use.names = FALSE),
          multiple = TRUE,
          label = "Categories",
          options = pickerOptions(liveSearch = TRUE,
                                  actionsBox = TRUE)
        ),
        
        pickerInput(
          "state",
          choices = states,
          selected = unlist(states, use.names = FALSE),
          multiple = TRUE,
          label = "State",
          options = pickerOptions(liveSearch = TRUE,
                                  actionsBox = TRUE)
        ),
        
        pickerInput(
          "city",
          choices = cities,
          selected = unlist(cities, use.names = FALSE),
          multiple = TRUE,
          label = "City",
          options = pickerOptions(liveSearch = TRUE,
                                  actionsBox = TRUE)
        ),
        
        radioButtons(
          "rep_window",
          label = "Reporting Window",
          c(
            "Daily" = "order_approved_at",
            "Weekly" = "year_week",
            "Monthly" = "year_month"
          )
        ),
        # Style download_button div to avoid inline label
        tags$head(
          tags$style(type="text/css", "#download_button label{ display: table-cell; text-align: center;
          vertical-align: middle; } #download_button .form-group { display: table-row;}")
        ),
        tags$div(
          id = "download_button",
          tags$label("Download Data", class="control-label"),
          downloadButton(outputId = "download_data", label = "Download .csv")
          )
      )
    )
  })
  
  
  # Get reactive sales data (by dates)
  df_agg <- reactive({
    s_agg <- sales_agg %>%
      filter(
        order_approved_at >= input$date_input[1],
        order_approved_at <= input$date_input[2],
        order_status %in% input$status,
        product_category_name %in% input$categs,
        customer_state %in% input$state,
        customer_city %in% input$city
      ) %>%
      group_by_at(vars(input$rep_window)) %>%
      summarise(
        tot_revenue = sum(tot_price, na.rm = TRUE),
        avg_approval_time = mean(approval_time, na.rm = TRUE),
        tot_orders = n_distinct(order_id),
        aov = tot_revenue / tot_orders
      ) %>%
      ungroup()
  })

  # Get sales data by product category
  categ_recap <- reactive({
    s_agg <- sales_agg %>%
      filter(
        order_approved_at >= input$date_input[1],
        order_approved_at <= input$date_input[2],
        order_status %in% input$status,
        product_category_name %in% input$categs,
        customer_state %in% input$state,
        customer_city %in% input$city
      ) %>%
      group_by(product_category_name) %>%
      summarise(
        tot_revenue = sum(tot_price, na.rm = TRUE),
        tot_orders = n_distinct(order_id),
        aov = tot_revenue / tot_orders
      ) %>%
      ungroup()
  })
  
  # Get sales data by city
  city_recap <- reactive({
    sales_agg %>%
      filter(
        order_approved_at >= input$date_input[1],
        order_approved_at <= input$date_input[2],
        order_status %in% input$status,
        product_category_name %in% input$categs,
        customer_state %in% input$state,
        customer_city %in% input$city
      ) %>%
      group_by(customer_city) %>% 
      summarise(
        tot_revenue = sum(tot_price, na.rm = TRUE),
        tot_orders = n_distinct(order_id),
        avg_item_price = mean(avg_item_price, na.rm = TRUE),
        aov = tot_revenue / tot_orders,
      ) %>%
      ungroup()
  })
  
  # Set up download handler for download button
  output$download_data <- downloadHandler(
    filename = function() {
      paste0(input$date_input[1],
            "-", input$date_input[2],
            "_data.csv")
    },
    content = function(file) {
      write.csv(df_agg(), file, row.names = FALSE)
    }
  )
  
  ## Topbar stats ------------------------------
  output$orders <- renderValueBox({
    req(credentials()$user_auth)
    infoBox(
      df_agg() %>%
        summarise(tot_orders = sum(tot_orders)) %>%
        .$tot_orders %>%
        format(round(., 1), big.mark = ","),
      subtitle = "Total Orders",
      icon = icon("box"), color = "red"
    )
    
  })
  
  output$tot_revenue <- renderValueBox({
    req(credentials()$user_auth)
    infoBox(
      df_agg() %>%
        summarise(tot_revenue = sum(tot_revenue)) %>%
        .$tot_revenue %>%
        f_curr(., "$"),
      subtitle = "Total Revenue",
      icon = icon("dollar-sign"), color = "green"
    )
    
  })
  
  output$aov <- renderValueBox({
    req(credentials()$user_auth)
    infoBox(
      df_agg() %>%
        summarise(aov = mean(aov, na.rm = TRUE)) %>%
        .$aov %>%
        f_curr(., "$"),
      subtitle = "AOV",
      icon = icon("credit-card"), color = "orange"
    )
    
  })
  
  output$approval_time <- renderValueBox({
    req(credentials()$user_auth)
    infoBox(
      val <- df_agg() %>%
        summarise(approval_time = mean(avg_approval_time, na.rm = TRUE)) %>%
        .$approval_time %>%
        round(., 2) %>% 
        paste(., "days"),
      subtitle = "Approval Time",
      icon = icon("box"), color = "lime"
    )
    
  })
  
  
  ## Orders/revenue graph -------------
  # Render plot
  output$sales_trend  <- renderCachedPlot({
    p <-
      ggplot(df_agg(), aes_string(input$rep_window, group = 1)) +
      geom_line(aes(y = df_agg()$tot_orders)) +
      scale_colour_manual(values = c("blue", "red")) +
      scale_y_continuous(breaks = pretty_breaks(15)) +
      labs(y = "Tot. Orders") +
      theme_light()

    
    # Keep axis lables formatted with weekly/monthly data
    if(input$rep_window == "order_approved_at"){
      p <- p + scale_x_date(breaks = pretty_breaks(30)) +
        theme(axis.text.x  = element_text(angle = 90, hjust = -0.2)) +
        labs(x = "Order Approval Day")
    } else if(input$rep_window == "year_week") {
      p <-  p + scale_x_discrete() +
        theme(axis.text.x = element_text(angle = 90, hjust = -0.2)) +
        labs(x = "Approval Week")
    } else {
      p <- p + scale_x_discrete() +
        theme(axis.text.x = element_text(angle = 90, hjust = -0.2)) +
        labs(x = "Approval Month")
    }
    p <- p + theme(text = element_text(size = 17),
                   axis.text.x = element_text(angle = 90))
    p # Return graph
  },
  cacheKeyExpr = { list(df_agg()) }
  )

  # Render table inside boxx
        title = "My gradient Box",
        width = 12,
        height = NULL,
        icon = "fa-heart",
        gradientColor = "red",
        boxToolSize = "xs",
        closable = FALSE,
        collapsible = TRUE,
        plotOutput("sales_trend")
      )
      
    )
      
  })


  # Recap Tables -------------
  # Render sales table
  output$sales_recap_tbl <- renderDataTable({
    req(credentials()$user_auth)
    datatable(select(df_agg(), -avg_approval_time),
              options = list(order = list(list('1', 'desc'))),
              colnames = c("Approved Date",
                           "Tot. Revenue",
                           "Tot. Orders",
                           "Avg. Order Value"),
              rownames = FALSE) %>% 
      formatCurrency("tot_revenue", currency = "$") %>% 
      formatCurrency("aov", currency = "$")
  })


  # Render category table
  output$categ_table <- renderDataTable({
    req(credentials()$user_auth)
    datatable(categ_recap(), options = list(order = list("2", "desc")),
              colnames = c("Category",
                           "Tot. Revenue",
                           "Tot. Orders",
                           "Avg. Order Value"),
              rownames = FALSE) %>%
      formatCurrency("tot_revenue", currency = "$") %>%
      formatCurrency("aov", currency = "$")
  })


  # Render cities table
  output$city_table <- renderDataTable({
    req(credentials()$user_auth)
    datatable(city_recap(), options = list(order = list(list("3", "desc"))),
              colnames = c("Customer City",
                           "Tot. Revenue",
                           "Tot. Orders",
                           "Avg. Item Price",
                           "Avg. Order Value"),
              rownames = FALSE) %>% 
      formatCurrency("tot_revenue", currency = "$") %>% 
      formatCurrency("aov", currency = "$") %>%
      formatCurrency("avg_item_price", currency = "$")
  })


  # Output tables in sales tab
  output$sales_tbox <- renderUI({
    req(credentials()$user_auth)
    tabBox(
      title = "",
      id = "sales_recap_tbox",
      width = 12,
      tabPanel(
        title = "Sales Recap",
        dataTableOutput("sales_recap_tbl")
      ),
      tabPanel(
        title = "Sales by Category",
        dataTableOutput("categ_table")
      ),
      tabPanel(
        title = "Stats by city",
        dataTableOutput("city_table")
      )
    )
  })

  ## Operations tab -------------
  
  # Ops KPIs by city
  ops_city_recap <- reactive({
    sales_agg %>%
      filter(
        order_approved_at >= input$date_input[1],
        order_approved_at <= input$date_input[2],
        order_status %in% input$status,
        product_category_name %in% input$categs,
        customer_state %in% input$state,
        customer_city %in% input$city
      ) %>%
      group_by(customer_city) %>%
      summarise(
        tot_orders = n_distinct(order_id, na.rm = TRUE),
        avg_approval_time = mean(approval_time, na.rm = TRUE),
        avg_delivery_process_time = mean(delivery_process_time, na.rm = TRUE),
        avg_delivery_time = mean(delivery_time, na.rm = TRUE)
      ) %>%
      ungroup()
  })
  
  output$city_ops_table <- renderDataTable({
    req(credentials()$user_auth)
    datatable(ops_city_recap(),
              colnames = c("City",
                           "Tot. Orders (days)",
                           "Avg. Approval Time (days)",
                           "Avg. Delivery Process Time (days)",
                           "Avg. Delivery Time (days)"),
              rownames = FALSE
    ) %>% 
      formatRound(columns = c("avg_approval_time",
                              "avg_delivery_process_time",
                              "avg_delivery_time"),
                  digits = 2)
  })
  
  ops_state_recap <- reactive({
    sales_agg %>%
      filter(
        order_approved_at >= input$date_input[1],
        order_approved_at <= input$date_input[2],
        order_status %in% input$status,
        product_category_name %in% input$categs,
        customer_state %in% input$state,
        customer_city %in% input$city
      ) %>%
      group_by(customer_state) %>%
      summarise(
        tot_orders = n_distinct(order_id, na.rm = TRUE),
        avg_approval_time = mean(approval_time, na.rm = TRUE),
        avg_delivery_process_time = mean(delivery_process_time, na.rm = TRUE),
        avg_delivery_time = mean(delivery_time, na.rm = TRUE)
      ) %>%
      ungroup()
  })

  output$state_ops_table <- renderDataTable({
    req(credentials()$user_auth)
    datatable(ops_state_recap(),
              colnames = c("State",
                           "Tot. Orders (days)",
                           "Avg. Approval Time (days)",
                           "Avg. Delivery Process Time (days)",
                           "Avg. Delivery Time (days)"),
              rownames = FALSE
    ) %>% 
      formatRound(columns = c("avg_approval_time",
                              "avg_delivery_process_time",
                              "avg_delivery_time"),
                  digits = 2)
  })
  
  # Output tables in ops tab
  output$ops_tbox <- renderUI({
    req(credentials()$user_auth)
    tabBox(
      title = "",
      id = "ops_recap_tbox",
      width = 12,
      tabPanel(
        title = "By City",
        dataTableOutput("city_ops_table")
      ),
      tabPanel(
        title = "By State",
        dataTableOutput("state_ops_table")
      )
    )
  })

  
}