 
FROM rocker/shiny:latest

# install openssl
# libsodium for shinyauthr
RUN apt-get update && apt-get install libssl-dev -y \
    nano \
    libxml2-dev \
    libsodium-dev \
    libmariadbclient-dev \
    libhiredis-dev

# install packages and remove downloaded files
COPY install_packages.R  /tmp/install_packages.R
RUN Rscript /tmp/install_packages.R

# install shiny authr package
RUN R -e "install.packages('devtools', dependencies = TRUE, repos = 'http://cran.rstudio.com/')"
RUN R -e "devtools::install_github('PaulC91/shinyauthr', dependencies = TRUE)"

# copy config files
ADD shiny-server.conf /etc/shiny-server/shiny-server.conf
ADD shiny-server.sh /usr/bin/shiny-server.sh

# copy app
ADD ./app /srv/shiny-server/app/

## allow permissions
RUN ["chmod", "+x", "/usr/bin/shiny-server.sh"]

# expose port
EXPOSE 3838

CMD ["usr/bin/shiny-server.sh"]
