#===================================================
# Equivalent to selenium base docker image
#===================================================

FROM rocker/rstudio-stable:3.4.3

MAINTAINER Kamil Foltynski "kamil.foltynski@contractors.roche.com"

## Configure default locale, see https://github.com/rocker-org/rocker/issues/19
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
&& locale-gen en_US.utf8 \
&& /usr/sbin/update-locale LANG=en_US.UTF-8

RUN apt-get update && apt-get install -y \
  libssl-dev \
  libpng-dev \
  texlive-latex-base \
  texlive-fonts-recommended \
  texlive-fonts-extra \
  texlive-latex-extra

# java install
RUN apt-get install -y \
  openjdk-8-jdk \
  openjdk-8-jre 

RUN apt-get update && apt-get install -y \
  libxml2-dev \
  libcairo-dev \
  libicu-dev \
  bzip2 \
  liblzma-dev \
  libbz2-dev \
  curl \
  qpdf \
  texinfo

# install shiny server
# rocker documentation: https://github.com/rocker-org/rocker/tree/master/rstudio
# RUN export ADD=shiny && bash /etc/cont-init.d/add # not necessary when using supervisord.conf


#RUN wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
#RUN dpkg -i google-chrome-stable_current_amd64.deb; apt-get -fy install; rm -f google-chrome-stable_current_amd64.deb

# gnupg
RUN apt-get update && apt-get install -y gnupg

#======================================== selenium


RUN apt-get install -y \
    bzip2 \
    ca-certificates \
    openjdk-8-jre-headless \
    tzdata \
    sudo \
    unzip \
    wget \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/* \
  && sed -i 's/securerandom\.source=file:\/dev\/random/securerandom\.source=file:\/dev\/urandom/' ./usr/lib/jvm/java-8-openjdk-amd64/jre/lib/security/java.security

RUN apt-get update && apt-get install -y locales locales-all
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

RUN locale-gen en_US
RUN locale-gen en_US.UTF-8
RUN update-locale 

#========================================
# Add normal user with passwordless sudo
#========================================
RUN useradd seluser \
         --shell /bin/bash  \
         --create-home \
  && usermod -a -G sudo seluser \
  && echo 'ALL ALL = (ALL) NOPASSWD: ALL' >> /etc/sudoers \
  && echo 'seluser:secret' | chpasswd

#===================================================
# Run the following commands as non-privileged user
#===================================================
USER seluser

#==========
# Selenium
#==========
RUN  sudo mkdir -p /opt/selenium \
  && sudo chown seluser:seluser /opt/selenium \
  && wget --no-verbose https://selenium-release.storage.googleapis.com/3.9/selenium-server-standalone-3.9.1.jar \
    -O /opt/selenium/selenium-server-standalone.jar

# back to root
#USER root

#CMD ["/init"]


#===================================================
#========= Equivalent to NodeBase
#===================================================
USER root

#==============
# VNC and Xvfb
#==============
RUN apt-get update -qqy \
  && apt-get -qqy install \
    locales \
    xvfb \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

#===================================================
# Run the following commands as non-privileged user
#===================================================

USER seluser

#==============================
# Scripts to run Selenium Node
#==============================
#COPY NodeBase/entry_point.sh \
#  functions.sh \
#    /opt/bin/

COPY NodeBase/entry_point.sh /opt/bin/
COPY NodeBase/functions.sh /opt/bin/

#============================
# Some configuration options
#============================
ENV SCREEN_WIDTH 1360
ENV SCREEN_HEIGHT 1020
ENV SCREEN_DEPTH 24
ENV DISPLAY :99.0

#========================
# Selenium Configuration
#========================
# As integer, maps to "maxInstances"
ENV NODE_MAX_INSTANCES 1
# As integer, maps to "maxSession"
ENV NODE_MAX_SESSION 1
# As integer, maps to "port"
ENV NODE_PORT 5555
# In milliseconds, maps to "registerCycle"
ENV NODE_REGISTER_CYCLE 5000
# In milliseconds, maps to "nodePolling"
ENV NODE_POLLING 5000
# In milliseconds, maps to "unregisterIfStillDownAfter"
ENV NODE_UNREGISTER_IF_STILL_DOWN_AFTER 60000
# As integer, maps to "downPollingLimit"
ENV NODE_DOWN_POLLING_LIMIT 2
# As string, maps to "applicationName"
ENV NODE_APPLICATION_NAME ""

# Following line fixes https://github.com/SeleniumHQ/docker-selenium/issues/87
ENV DBUS_SESSION_BUS_ADDRESS=/dev/null

CMD ["/opt/bin/entry_point.sh"]

#===================================================
#========= Equivalent to NodeChrome
#===================================================
USER root

#============================================
# Google Chrome
#============================================
# can specify versions by CHROME_VERSION;
#  e.g. google-chrome-stable=53.0.2785.101-1
#       google-chrome-beta=53.0.2785.92-1
#       google-chrome-unstable=54.0.2840.14-1
#       latest (equivalent to google-chrome-stable)
#       google-chrome-beta  (pull latest beta)
#============================================
ARG CHROME_VERSION="google-chrome-stable"
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
  && echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list \
  && apt-get update -qqy \
  && apt-get -qqy install \
    ${CHROME_VERSION:-google-chrome-stable} \
  && rm /etc/apt/sources.list.d/google-chrome.list \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

#=================================
# Chrome Launch Script Wrapper
#=================================
COPY NodeChrome/wrap_chrome_binary /opt/bin/wrap_chrome_binary
RUN /opt/bin/wrap_chrome_binary

USER seluser

#============================================
# Chrome webdriver
#============================================
# can specify versions by CHROME_DRIVER_VERSION
# Latest released version will be used by default
#============================================
ARG CHROME_DRIVER_VERSION="latest"
RUN CD_VERSION=$(if [ ${CHROME_DRIVER_VERSION:-latest} = "latest" ]; then echo $(wget -qO- https://chromedriver.storage.googleapis.com/LATEST_RELEASE); else echo $CHROME_DRIVER_VERSION; fi) \
  && echo "Using chromedriver version: "$CD_VERSION \
  && wget --no-verbose -O /tmp/chromedriver_linux64.zip https://chromedriver.storage.googleapis.com/$CD_VERSION/chromedriver_linux64.zip \
  && rm -rf /opt/selenium/chromedriver \
  && unzip /tmp/chromedriver_linux64.zip -d /opt/selenium \
  && rm /tmp/chromedriver_linux64.zip \
  && mv /opt/selenium/chromedriver /opt/selenium/chromedriver-$CD_VERSION \
  && chmod 755 /opt/selenium/chromedriver-$CD_VERSION \
  && sudo ln -fs /opt/selenium/chromedriver-$CD_VERSION /usr/bin/chromedriver

COPY NodeChrome/generate_config /opt/bin/generate_config

# Generating a default config during build time
RUN /opt/bin/generate_config > /opt/selenium/config.json

#===================================================
#========= Equivalent to StandaloneChrome
#===================================================

USER seluser

#====================================
# Scripts to run Selenium Standalone
#====================================
COPY StandaloneChrome/entry_point.sh /opt/bin/entry_point.sh

EXPOSE 4444

#==================================== Shiny Server

USER root

# Install dependencies and Download and install shiny server
RUN apt-get update && apt-get install -y \
    sudo \
    gdebi-core \
    pandoc \
    pandoc-citeproc \
    libcurl4-gnutls-dev \
    libcairo2-dev \
    libxt-dev && \
    wget --no-verbose https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/VERSION -O "version.txt" && \
    VERSION=$(cat version.txt)  && \
    wget --no-verbose "https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/shiny-server-$VERSION-amd64.deb" -O ss-latest.deb && \
    gdebi -n ss-latest.deb && \
    rm -f version.txt ss-latest.deb && \
    R -e "install.packages(c('shiny', 'rmarkdown'), repos='https://cran.rstudio.com/')" && \
    cp -R /usr/local/lib/R/site-library/shiny/examples/* /srv/shiny-server/ && \
    rm -rf /var/lib/apt/lists/*


#==================================== shiny server + rstudio = 1 container
# sources:
# https://stackoverflow.com/questions/29212887/rstudio-and-shiny-in-one-dockerfile
# https://github.com/smartinsightsfromdata/Docker-for-shiny-server-free-edition-on-centos

# Add RStudio binaries to PATH
# export PATH="/usr/lib/rstudio-server/bin/:$PATH"
ENV PATH /usr/lib/rstudio-server/bin/:$PATH 
ENV LANG en_US.UTF-8

RUN apt-get update -y && apt-get install -y \
    openssl \
    supervisor \
    pandoc \
    passwd


RUN mkdir -p /var/log/shiny-server \
    && chown shiny:shiny /var/log/shiny-server \
    && chown shiny:shiny -R /srv/shiny-server \
    && chmod 777 -R /srv/shiny-server \
    && chown shiny:shiny -R /opt/shiny-server/samples/sample-apps \
    && chmod 777 -R /opt/shiny-server/samples/sample-apps  

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN mkdir -p /var/log/supervisor \
    && chmod 777 -R /var/log/supervisor

EXPOSE 8787 3838

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]


#======== install R pacakges here
COPY install_libraries.R /code/install_libraries.R
RUN R -f /code/install_libraries.R

#======== run tests
COPY tests/ /opt/bin/tests

#ENTRYPOINT ["Rscript", "-e", "testthat::test_file('/opt/bin/tests/test_shiny-server.R')"]



