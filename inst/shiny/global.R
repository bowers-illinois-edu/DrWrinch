# global.R -- runs exactly once when the Shiny app starts. We load
# the runtime dependencies and source the app's helper functions
# here so ui.R and server.R inherit a fully-prepared environment.

# DrWrinch is not on CRAN, so on shinyapps.io the package will not
# be in the installed manifest automatically. We install it from
# GitHub on first cold-start; subsequent renders use the cached
# install (~30s one-time hit). In local development,
# devtools::load_all() has already loaded DrWrinch, so this branch
# is a no-op.
if (!requireNamespace("DrWrinch", quietly = TRUE)) {
  remotes::install_github("bowers-illinois-edu/DrWrinch")
}

library(shiny)
library(bslib)
library(plotly)
library(DrWrinch)

# Helpers and plot functions live under inst/shiny/R/ rather than
# the package's R/ so they stay out of the package namespace. Shiny
# 1.5+ auto-sources files in R/ under the app directory; sourcing
# explicitly here is belt-and-braces and makes the dependencies
# obvious to a reader.
source("R/helpers.R", local = TRUE)
source("R/plots.R", local = TRUE)
