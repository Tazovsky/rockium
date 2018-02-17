library(RSelenium)
library(testthat)
library(png)

test_that("Shiny Server is working", {
  dir.create(tmpDir <- tempfile())
  on.exit(unlink(tmpDir, TRUE, TRUE))
  remDr <- remoteDriver(remoteServerAddr = "localhost",
                        port = 4444,
                        browserName = "chrome")
  
  remDr$open(silent = TRUE)
  on.exit(remDr$closeall())
  url <- "http://localhost:3838/"
  remDr$navigate(url)
  
  Sys.sleep(2)
  
  snapshotPath <- file.path(tmpDir, "snap.png")
  
  cat("snapshotPath: ", snapshotPath)
  
  remDr$screenshot(file = snapshotPath)
  
  expect_true(file.exists("/src/tests/test_shiny-server-ref.png"))
  
  expect_identical(png::readPNG(snapshotPath),
                   png::readPNG("/src/tests/test_shiny-server-ref.png"))
})

