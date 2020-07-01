FROM rocker/shiny:3.5.1
MAINTAINER Marine Institute
# install ssl
# and gdal
RUN sudo apt-get update && apt-get install -y libssl-dev libudunits2-0 libudunits2-dev libproj-dev libgdal-dev && apt-get clean && rm -rf /var/lib/apt/lists/ && rm -rf /tmp/downloaded_packages/ /tmp/*.rds
# install additional packages
RUN Rscript -e "install.packages(c('shiny','rgdal','leaflet','sf','dplyr','readr'), repos='https://cran.rstudio.com/')"

COPY Data /srv/shiny-server/geocalc/Data
COPY README.md /srv/shiny-server/geocalc/
COPY app.R /srv/shiny-server/geocalc/

EXPOSE 3838
CMD ["/usr/bin/shiny-server.sh"]
