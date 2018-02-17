# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# NOTE: DO *NOT* EDIT THIS FILE.  IT IS GENERATED.
# PLEASE UPDATE Dockerfile.txt INSTEAD OF THIS FILE
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
FROM selenium-rocker/node-chrome:3.9.1-actinium
LABEL authors=SeleniumHQ

#RUN sudo apt-get update && sudo apt-get install -y vim

USER seluser

#====================================
# Scripts to run Selenium Standalone
#====================================
COPY entry_point.sh /opt/bin/entry_point.sh


USER root

#initialize shiny server
#COPY shiny-server.sh /usr/bin/shiny-server.sh
#CMD ["/usr/bin/shiny-server.sh"]

#RUN exec shiny-server >> /var/log/shiny-server.log 2>&1 &

#ENTRYPOINT "exec shiny-server >> /var/log/shiny-server.log" && /bin/bash

#RUN export ADD=shiny && bash /etc/cont-init.d/add

RUN shiny-server &

EXPOSE 4444 3838 8787

#CMD ["/init"]
