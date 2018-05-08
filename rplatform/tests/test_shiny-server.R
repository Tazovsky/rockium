library(RSelenium)
library(testthat)
library(png)

testthat::context("Shiny Server can be accessed by Selenium Server")

test_that("Selenium Server takes snapshot of Shiny Server", {
  dir.create(tmpDir <- tempfile())
  on.exit(unlink(tmpDir, TRUE, TRUE))
  
  url <- "http://localhost:3838/"
  
  remDr <- remoteDriver(remoteServerAddr = "localhost",
                        port = 4444,
                        browserName = "chrome")

  on.exit(remDr$closeall())
  
  remDr$open(silent = TRUE)
  
  remDr$setWindowSize(width = 1440, height = 1100)
  
  remDr$navigate(url)
  
  Sys.sleep(2)
  
  snapshotPath <- file.path(tmpDir, "snap.png")
  
  cat("snapshotPath: ", snapshotPath)
  
  remDr$screenshot(file = snapshotPath)
  
  expect_true(file.exists("test_shiny-server-ref.png"))
  
  expect_identical(png::readPNG(snapshotPath),
                   png::readPNG("test_shiny-server-ref.png"))
})

