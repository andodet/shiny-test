library(RMySQL)
library(sodium)

# mock user list for shinyauthr
user_base <- tibble(
  user = c("user1", "user2"),
  password = sapply(c("pass1", "pass2"), sodium::password_store),
  permissions = c("admin", "standard"),
  name = c("User One", "User Two")
)

mysql_user = "root"
user_pass = "pippo"
db_host <- "127.0.0.1"
db_port <- 3306

# open mysql connection
conn <- dbConnect(MySQL(), user = mysql_user,password = user_pass, host = db_host, port = db_port,
                  dbname = "shiny_app")

# enable external table creation from outside
#https://stackoverflow.com/questions/50745431/trying-to-use-r-with-mysql-the-used-command-is-not-allowed-with-this-mysql-vers/51630365#51630365
dbSendQuery(conn, "SET GLOBAL local_infile = true")

# setup user table
RMySQL::dbWriteTable(conn = conn, value = user_base, overwrite = TRUE, name = 'users',
                     row.names = FALSE)
dbDisconnect(conn = conn)
rm(user_base)