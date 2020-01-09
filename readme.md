# Brazillian e-commerce dashboard 📦️

**@TODO:** explain what `shiny` is and why it is meaningful for data-driven webapp development.

The following dashboard (based on the [`e-commerce dataset by Olist`](https://www.kaggle.com/olistbr/brazilian-ecommerce) ) has been built to explore a few [`shiny`](https://shiny.rstudio.com) core concepts:

* Reactivity: data has been preaggreated in order to take heavy computaiton away from the user, providing a faster and more reactive user experience. **TODO**: specify both on data and input menus
* [`shinydashboard`](https://rstudio.github.io/shinydashboard) structure for faster dashboard styling and layout.
* User authenthication through [`shinyauthr`](https://github.com/PaulC91/shinyauthr).  
**Disclaimer**: by any mean this should be considered a safe approach  due to the lack strong server-side checks.
* In order to anticipate multi-user usage, plots are cached via [``redis``](https://redis.io), halvening load times for cached plots.

In order to easily deploy

* Dockerized deployment through `docker-compose`

## Overview

The dashboard is composed by two main sections:

* **Sales**: this section is mainly directed to business users, who will find KPIs such as:
    + Total oprders
    + Total revenue
    + Average order value
    + Average order approval time

* **Operations**:
    + Order approval times 
    + TBD
    + TBD

## Usage
### Prerequisites
In order to build the image `docker` and `docker-compose` will be needed.
 This will likely take some time as all the packages (and their dependencies) will need to be installed.

### How to install

Clone the repository 
```
https://github.com/andodet/shiny-dash-test.git
```

Build the custom docker image (this will take a while as all the packages will be built from source)
```
$ cd shiny-dash-test
$ docker-compose up --build
```

Point your broser to [``http://localhost:3838/app``](http://localhost:3838/app)

## Further development

This dashboard is has been developed as a proof of concept and not intended for deployment in a production environment.  
In order tog get it ready for production, a few changes are essential:

* Proper authenthication (i.e behind and nginx server) 
* Unit/integration test
* Refactor the app following a r-package structure (with tools like [``golem``](https://thinkr-open.github.io/golem/)) to make it easier to share and integrate with CI/CD tools.
* Db credentials are not supposed to be displayed in [`docker-compose.yml`](docker-compose.yml), build image using docker secrets.
* Set up a password for Redis cache

## Screenshots

Couple screenshots of the final result.
