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

# appId names the exact application to write to. deployApp() can also
# find it from appName, but only by asking the server to match the name,
# and it consults inst/shiny/rsconnect/ first. That directory records a
# bundleId that changes on every deploy, so tracking it would put a
# modified file in git status each time; it is gitignored instead, and
# the id lives here where it never changes. With appId set, appName no
# longer selects the application -- it is kept because it records the
# name the app was created under.
#
# Explicit appFiles allowlist prevents accidental upload of any
# rsconnect/ state directory, NOTES.md, .RData snapshots, or other
# local artifacts that might land under inst/shiny/.
rsconnect::deployApp(
  appDir   = "inst/shiny",
  appId    = 17386998,
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
