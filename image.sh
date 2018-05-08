#!/bin/bash

export IMAGE_NAME_RSTUDIO=geneapps/rp_rstudio_shiny_selenium:0.1.0
export COMPOSE=docker-compose.yml
export RSTUDIO=rp-rstudio-shiny
export CORE_DIR="/mnt/vol"

set -e

if [ "$1" == "build" ]; then
  
  docker build -t $IMAGE_NAME_RSTUDIO .

elif [ "$1" == "pull" ]; then
  
  echo "Pulling image $IMAGE_NAME_RSTUDIO..."
  docker pull $IMAGE_NAME_RSTUDIO
  
elif [ "$1" == "push" ]; then
  echo "Use 'rp build --tag=X.X.X'"
  
elif [ "$1" == "rstudio" ]; then
  
  # We don't want to lose custom annotations, so they are saved outside 
  # docker image and every time container is run they are mounted from 
  # local dir. It is more convenient way than keeping them inside docker image
  # and commiting changes in docker every time they are created
  FacileAtezoDataSet="/usr/local/lib/R/site-library/FacileAtezoDataSet/extdata/FacileAtezoDataSet/custom-annotation"
  FacileTCGADataSet="/usr/local/lib/R/site-library/FacileTCGADataSet/extdata/FacileTCGADataSet/custom-annotation"
  ExampleDataSet="/usr/local/lib/R/site-library/FacileExplorer/extdata/exampleFacileDataSet/custom-annotation"
  
  [ ! -z "$(docker ps -q -f status=exited)" ] && \
    echo "Removing containers on status=exited..." && \
    docker rm $(docker ps -q -f status=exited)
    
  
  echo "Running container: $IMAGE_NAME_RSTUDIO..."
  echo "Rstudio running on: http://localhost:8787"
  docker run --name $RSTUDIO -d \
             -e SCREEN_WIDTH=1440 \
             -e SCREEN_HEIGHT=1100 \
             -p 3838:3838 \
             -p 8787:8787 \
             -p 4444:4444 \
             -p 5900:5900 \
             -v $(pwd)/shinylog/:/var/log/shiny-server/ \
             -v $(pwd)/facileexplorer/inst/shiny/:/srv/shiny-server/fe/ \
             -v $(pwd)/custom-annotation/FacileTCGADataSet/:$FacileTCGADataSet \
             -v $(pwd)/custom-annotation/FacileAtezoDataSet/:$FacileAtezoDataSet \
             -v $(pwd)/custom-annotation/ExampleDataSet/:$ExampleDataSet \
             -v `pwd`:$CORE_DIR $IMAGE_NAME_RSTUDIO
  
  if [ ! -z $2 ] && [ $2 == "--install-fe" ]; then
    echo "Installing FacileExplorer..."
    docker exec -it $RSTUDIO \
      Rscript -e "devtools::install('$CORE_DIR/facileexplorer', quiet = FALSE)"
  fi
  
elif [ "$1" == "stop" ]; then
  docker stop $RSTUDIO
  
elif [ "$1" == "test" ]; then

    echo "Running linter and unit tests..."
    docker exec -it $RSTUDIO \
      Rscript -e "setwd('$CORE_DIR/facileexplorer');\
                  suppressMessages(devtools::load_all());\
                  source('rstudio-image/linter.R')"
    
# unit tests
elif [ "$1" == "unittest" ]; then

  docker exec -it $RSTUDIO \
    Rscript -e "setwd('$CORE_DIR/facileexplorer');\
                suppressMessages(devtools::load_all());\
                devtools::test()"

# frontend tests
elif [ "$1" == "uitest" ]; then

  echo "Installing package..."
  docker exec -it $RSTUDIO \
    Rscript -e "devtools::install('$CORE_DIR/facileexplorer', quiet = TRUE);\
                if (!require('RSelenium')) install.packages('RSelenium', quiet = TRUE)"

  if [ "$2" == "reference" ] ; then
    echo "Generating reference screenshots..."
    docker exec -it $RSTUDIO \
      Rscript -e "module = 'create.ref.screenshots';\
                  testthat::test_file('$CORE_DIR/frontend-tests/test_scenarios.R')"
  else
    echo "Testing front-end..."
    docker exec -it $RSTUDIO \
      Rscript -e "module = 'test';\
                  testthat::test_file('$CORE_DIR/frontend-tests/test_scenarios.R')"
    
    if [ -f "$CORE_DIR/frontend-tests/output/report/input.yml" ]; then
      echo "Generating report from tests..."
      docker exec -it $RSTUDIO \
        Rscript -e "library(rmarkdown);\
                    rmarkdown::render('$CORE_DIR/frontend-tests/prepare.report.Rmd', output_file = '/src/frontend-tests/output/report/tests.report.html')"
    fi
  fi
elif [ "$1" == "vnc" ]; then

  echo "Running VNC Viewer on localhost:5900..."
  open vnc://localhost:5900 && echo "Password: secret"
  
else
  echo "Usage: ./image.sh [param]"
  echo
  echo "This script contains useful docker commands for development"
  echo
  echo "Params:"
  echo
  echo "   build - build docker image"
  echo "   pull - get all images from Docker Hub"
  echo "   push - push all images to Docker Hub"
  echo "   rstudio - run image as daemon and start Rstudio in a browser"
  echo "   test - run linter and unittests"
  echo "   unittest - run unittests ONLY"
  echo "   uitest - run frontend tests"
  echo "   uitest reference - generate reference screenshots for frontend tests"
  echo "   vnc - open VNC Viewer window (tested on OSX only)"
  echo
fi
