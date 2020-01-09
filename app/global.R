library(dplyr)
library(ggplot2)
library(scales)
library(shinyWidgets)
library(shinydashboard)
library(shinydashboardPlus)
library(shinyjs)
library(sodium)
library(shinyauthr)
library(RMySQL)
library(R6)
library(redux)
library(DT)
source("mock_users.R")

# Get mock  user_base for login
mysql_user = "db_user"
user_pass = "mypwd"
db_host <- "127.0.0.1"
db_port <- 3306
db_name <- "shiny_app"

# connect to mysql and get user base
conn <-
  dbConnect(
    MySQL(),
    user = mysql_user,
    password = user_pass,
    host = db_host,
    port = db_port,
    dbname = "shiny_app"
  )

user_base = dbSendQuery(conn, "select * from shiny_app.users")
user_base = dbFetch(user_base, n = -1)
dbDisconnect(conn = conn)

# Set up redis cache object
RedisCache <- R6Class(
  "RedisCache",
  public = list(
    initialize = function(..., namespace = NULL) {
      private$r <- redux::hiredis(host = '127.0.0.1', port = 6379)
      # Configure 20mb cache
      private$r$CONFIG_SET("maxmemory", "20mb")
      private$r$CONFIG_SET("maxmemory-policy", "allkeys-lru")
      private$namespace <- namespace
    },
    
    get = function(key) {
      key <- paste0(private$namespace, "-", key)
      s_value <- private$r$GET(key)
      if (is.null(s_value)) {
        return(key_missing())
      }
      unserialize(s_value)
    },
    
    set = function(key, value) {
      key <- paste0(private$namespace, "-", key)
      s_value <- serialize(value, NULL)
      private$r$SET(key, s_value)
    }
  ),
  private = list(r = NULL,
                 namespace = NULL)
)

# Load sales data
sales_agg <- readRDS("data/sales_agg.rds")

# Order statuses
o_status <- c(
  "delivered",
  "canceled",
  "invoiced",
  "shipped",
  "processing",
  "unavailable",
  "approved",
  "created"
)

# Format currency in value boxes
f_curr <- function(val, curr_sym) {
  val %>%
    round(., digits = 2) %>%
    format(., big.mark = ',') %>%
    as.character(.) %>%
    paste("$", .)
}

# Get categories for dropwdown menu
categs <- sales_agg %>%
  select(product_category_name) %>%
  mutate(product_category_name = as.character(product_category_name)) %>%
  distinct() %>%
  as.list()

# Get states states and cities for dropdown menus
states <- unique(as.character(sales_agg$customer_state))
cities <- unique(as.character(sales_agg$customer_city))