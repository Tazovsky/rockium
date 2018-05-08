# NOTE:
# This Dockerfile is stored under "rplatform" directory but it will be
# moved to top level project directory during image build by RP so
# all local paths should be relative to your project's top level
# directory.

FROM rocker/rstudio-stable:3.4.3

MAINTAINER Kamil Foltynski "kamil.foltynski@gmail.com"
 
# install Shiny server 
RUN export ADD=shiny && bash /etc/cont-init.d/add 
 
#================= Define your system dependencies in this Dockerfile

RUN apt-get update && apt-get install -y \
    libssl-dev \
    libsasl2-dev \
    libpng-dev \
    openjdk-8-jdk \
    openjdk-8-jre \
    libxml2-dev \
    libcairo-dev \
    libicu-dev \
    bzip2 \
    liblzma-dev \
    libbz2-dev \
    subversion \
    curl \
    libmariadb-client-lgpl-dev \
    libv8-3.14-dev \
    procps \
    vim \
    systemd

RUN R CMD javareconf

# gnupg
RUN apt-get update && apt-get install -y gnupg

# install phantomJS
COPY rplatform/image_scripts/install_phantomJS.sh /opt/bin/install_phantomJS.sh
RUN bash /opt/bin/install_phantomJS.sh

#======================================== selenium part

# Equivalent to selenium base docker image:
# https://github.com/SeleniumHQ/docker-selenium/tree/master/Base

RUN dpkg --purge --force-depends ca-certificates-java
RUN apt-get install -y ca-certificates-java

RUN apt-get install -y \
    bzip2 \
    #ca-certificates \
    #openjdk-8-jre-headless \
    tzdata \
    sudo \
    unzip \
    wget \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/* 
  
  #\
  #&& sed -i 's/securerandom\.source=file:\/dev\/random/securerandom\.source=file:\/dev\/urandom/' ./usr/lib/jvm/java-8-openjdk-amd64/jre/lib/security/java.security

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
USER root

#==========
# Selenium
#==========
RUN  sudo mkdir -p /opt/selenium \
  && sudo chown root:root /opt/selenium \
  && wget --no-verbose https://selenium-release.storage.googleapis.com/3.9/selenium-server-standalone-3.9.1.jar \
    -O /opt/selenium/selenium-server-standalone.jar

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
    fluxbox \
    x11vnc \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

#===================================================
# Run the following commands as non-privileged user
#===================================================

USER root

#==============================
# Scripts to run Selenium Node
#==============================

COPY rplatform/NodeBase/entry_point.sh /opt/bin/
COPY rplatform/NodeBase/functions.sh /opt/bin/

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
COPY rplatform/NodeChrome/wrap_chrome_binary /opt/bin/wrap_chrome_binary
RUN /opt/bin/wrap_chrome_binary

USER root

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

COPY rplatform/NodeChrome/generate_config /opt/bin/generate_config

# Generating a default config during build time
RUN /opt/bin/generate_config > /opt/selenium/config.json

#===================================================
#========= Equivalent to StandaloneChrome
#===================================================

USER root

#====================================
# Scripts to run Selenium Standalone
#====================================
#COPY StandaloneChrome/entry_point.sh /opt/bin/entry_point.sh
#CMD ["/opt/bin/entry_point.sh"]

#EXPOSE 4444

#===================================================
#========= Equivalent to StandaloneChromeDebug
#===================================================

USER root

# export passwd to file
ENV VNC_PASSWD_DIR=/home/seluser/.vnc
ENV VNC_PASSWD_FILE=$VNC_PASSWD_DIR/passwd

RUN mkdir -p $VNC_PASSWD_DIR
RUN x11vnc -storepasswd 'secret' $VNC_PASSWD_FILE

COPY rplatform/StandaloneChromeDebug/entry_point.sh /opt/bin/entry_point.sh

EXPOSE 4444 5900

RUN apt-get update -y && apt-get install -y \
    openssl \
    supervisor \
    passwd
    
#COPY rplatform/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
#RUN mkdir -p /var/log/supervisor && chmod 777 -R /var/log/supervisor
#CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

CMD ["/init"]
