# Brazillian e-commerce dashboard 📦

The following dashboard (based on an aggregated version of the [`e-commerce dataset by Olist`](https://www.kaggle.com/olistbr/brazilian-ecommerce) ) has been built to explore a few [`shiny`](https://shiny.rstudio.com) core concepts:

* Reactivity: data has been preaggreated in order to take heavy computaiton away from the user, providing a faster and more reactive user experience. 
* [`shinydashboard`](https://rstudio.github.io/shinydashboard) structure for faster dashboard styling and layout. Additional UI elements (like the right sidebar) are provided by
[`shinydashboardplus`](https://rinterface.github.io/shinydashboardPlus/) package.
* User authenthication and password hasing is performed through [`shinyauthr`](https://github.com/PaulC91/shinyauthr). Usernames and passwords are stored in a
MySQL database.  
This authenthication method **is not** meant to be used in a production environment as it requires to implement logic to check for client authenthication
on every piece of content.  
* In order to anticipate multi-user usage, plots are cached via [``redis``](https://redis.io), halvening load times to render cached plots.
* The app (and the mock user db) has been dockerized for easy deployment.


## Overview

The dashboard conists in two views:

1. Sales
    * Order volumes plot over time.
    * Sales brekdwon by state / city.
    
2. Operations
    * Order approval time by state/city.
    * Delivery processing time by state/city.
    * Shipping time by state/city  


The right sidebar allows to:

* Filter by relevant dimensions.
* Change reporting window (daily, weekly, monthly).
* Download filtered data in .csv format.


## Usage
### Installation

`docker` and `docker-compose` will be neede to build and run the containers.  

To download and build the app just run:
```sh
# Clone the repo
git clone https://github.com/andodet/shiny-test

# Build the image
cd shiny-test
docker-compose up --build
```

This will likely take a while as a number of R packages will be installed with all their dependencies. After the process is finished the dashboard will be exposed on
[http://localhost:3838/app](http://localhost:3838/app)


## Further development

This dashboard is meant to be a proof of concept and it would still require a few tweaks before being ready for deployment.
Namely, it's needed to:

* Setup proper authehtication (via [`shinyproxy`]() or behind and nginx server).
* Unit testing.
* Use secrets for db credentials.
* Set up a password for redis instance.

