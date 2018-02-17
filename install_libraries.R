repos = c(
  "https://mran.microsoft.com/snapshot/2018-02-16",
  "https://bioconductor.org/packages/3.6/bioc",
  "https://bioconductor.org/packages/3.6/data/annotation",
  "https://bioconductor.org/packages/3.6/data/experiment"
)

options(repos = repos)
install.packages(c("devtools", "parallel", "future"))

# see: https://www.r-bloggers.com/speeding-up-package-installation-2/
cores <- max(parallel::detectCores(), future::availableCores())
options(Ncpus = cores)

cat(paste(">>> CPUs used: ", cores, "\n"))

pkgs <- unique(c(
  "RSelenium",
  "testthat",
  "shiny",
  "shinydashboard",
  "data.table",
  "png"
))

install.packages(pkgs)
