#!/usr/bin/env Rscript
# Run the fitness app
# Usage: Rscript run.R
#   or open in RStudio and click "Run App"

renv::load()
library(fitnessapp)
fitnessapp::run_app(options = list(port = 3838, launch.browser = TRUE))
