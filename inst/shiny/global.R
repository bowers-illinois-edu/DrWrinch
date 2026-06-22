# global.R -- runs exactly once when the Shiny app starts. We load
# the runtime dependencies and source the app's helper functions
# here so ui.R and server.R inherit a fully-prepared environment.

# DrWrinch is not on CRAN. shinyapps.io installs whatever version its
# build manifest resolved into the read-only system library
# (/usr/lib/R), and that copy can lag the GitHub HEAD this app needs
# (e.g. an older DrWrinch without sens_coding). We cannot overwrite the
# system copy at runtime -- R CMD INSTALL there fails with "Permission
# denied" -- so we install the required version into a writable,
# session-local library and put it FIRST on the search path, shadowing
# any stale system copy. The GitHub download and build succeed at
# runtime; only the install *location* has to be writable.
#
# Version is read with packageVersion() (which does not load the
# namespace) rather than requireNamespace() (which does); loading the
# old namespace first would stop library(DrWrinch) from picking up the
# freshly installed copy. In local development DrWrinch is already
# loaded via devtools::load_all() at the current version, so the
# compareVersion() guard skips the install and this is a no-op.
.dw_lib <- file.path(tempdir(), "drwrinch-lib")
dir.create(.dw_lib, showWarnings = FALSE, recursive = TRUE)
.libPaths(c(.dw_lib, .libPaths()))

.dw_needed <- "0.0.1.9001"
.dw_have <- tryCatch(
  as.character(utils::packageVersion("DrWrinch")),
  error = function(e) NA_character_
)
if (is.na(.dw_have) || utils::compareVersion(.dw_have, .dw_needed) < 0) {
  remotes::install_github(
    "bowers-illinois-edu/DrWrinch",
    upgrade = "never",
    lib = .dw_lib
  )
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
