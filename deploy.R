# Deploy the DrWrinch Shiny app to shinyapps.io. Run from the repo
# root with source("deploy.R"). Not shipped with the package
# (see .Rbuildignore).
#
# First-time setup on this machine:
#   install.packages("rsconnect")
#   rsconnect::setAccountInfo(
#     name   = "<your-shinyapps-account>",
#     token  = "<copy from shinyapps.io dashboard>",
#     secret = "<copy from shinyapps.io dashboard>"
#   )
#
# Subsequent deploys only need to source this file.

if (!requireNamespace("rsconnect", quietly = TRUE)) {
  install.packages("rsconnect", repos = "https://cloud.r-project.org")
}

# Explicit appFiles allowlist prevents accidental upload of any
# rsconnect/ state directory, NOTES.md, .RData snapshots, or other
# local artifacts that might land under inst/shiny/.
rsconnect::deployApp(
  appDir   = "inst/shiny",
  appName  = "drwrinch",
  appTitle = "DrWrinch: Bayes factors for process tracing",
  appFiles = c(
    "global.R",
    "ui.R",
    "server.R",
    "R/helpers.R",
    "R/curves.R",
    "R/plots.R"
  ),
  forceUpdate = TRUE
)
