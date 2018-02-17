# rockium

### Intro

One Docker image containing Rstudio Server, Shiny Server and Selenium Server. 

### Why I did not use `docker-compose`?

The problem I encountered was requirement of deployment app in one and only one container. 
So the simplest solution was creating one container insted of using `docker-compose` with `rocker` and `selenium server`.


### Thanks to SeleniumHQ
Many soultions about installing Selenium Server in Docker image are borrowed from [SeleniumHQ](https://github.com/SeleniumHQ/docker-selenium).


## How to
- `./build.sh build` - build image
- `./build.sh rstudio` - run Rstudio on `localhost:8787`, Shiny Server on `localhost:3838`, Selenium Server on `localhost:4444`
- `./build.sh stop` - stop container
- `./build.sh test` - perform unit tests
