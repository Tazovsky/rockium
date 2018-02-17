#!/bin/bash

export PATH2DOCKERFILE=./
export DOCKERHUB_NAME=tazovsky/rocker-standalone-chrome
export LOCAL_IMG_NAME=rstudio_rocker_selenium

export TAG=0.1.0
echo "Using tag $TAG"

if [ "$1" == "build" ]; then
  echo "Building image: $DOCKERHUB_NAME:$TAG"
  docker build -t $DOCKERHUB_NAME:$TAG $PATH2DOCKERFILE
  
elif [ "$1" == "rstudio" ]; then
  
  docker rm $(docker ps -q -f status=exited)
  echo "Running docker image: $DOCKERHUB_NAME:$TAG"
  docker run --name $LOCAL_IMG_NAME -d -p 3838:3838 -p 8787:8787 -p 4444:4444 -p 5900:5900 -v `pwd`:/src $DOCKERHUB_NAME:$TAG

elif [ "$1" == "stop" ]; then

docker stop $LOCAL_IMG_NAME
docker rm $(docker ps -q -f status=exited)

elif [ "$1" == "test" ]; then
  docker exec -it rstudio_rocker_selenium Rscript -e "setwd('/opt/bin/tests/'); testthat::test_file('test_shiny-server.R')"
fi