#' Launch the DrWrinch Shiny app
#'
#' Starts an interactive Shiny session showing the two Bayes factors the
#' paper computes from one model, side by side, together with the three
#' probabilities they are built from: the numerator they share and the
#' two denominators that separate them. A Sensitivity tab reports what a
#' reader would have to grant before the researcher's report would
#' change. Every function the app calls ([bf_uniform_weights()],
#' [bf_worst_case()], [separation_g()], [sens_coding()],
#' [sens_binomial()]) works from the command line without it.
#'
#' The Shiny stack (shiny, bslib) is in `Suggests`, not `Imports`, so
#' users who only want the core Bayes factor functions do not have to
#' install it. `run_app()` checks for these packages at call time and
#' stops with an install hint if any is missing.
#'
#' @param launch_browser Logical. If `TRUE` (default in interactive
#'   sessions), opens the default web browser to the app's URL.
#' @param ... Additional arguments passed to [shiny::runApp()] (for
#'   example, `port`, `host`, `display.mode`).
#'
#' @return Invisibly returns the value of [shiny::runApp()]. Called for
#'   its side effect of starting a Shiny session.
#'
#' @examples
#' \dontrun{
#' run_app()
#' }
#'
#' @seealso [bf_uniform_weights()] and [bf_worst_case()], the two Bayes
#'   factors the app shows; [sens_coding()] and [sens_binomial()] for the
#'   sensitivity tab.
#' @export
run_app <- function(launch_browser = interactive(), ...) {
  # Shiny and bslib are runtime-only. Check at call time so the core
  # BF functions remain usable without the full Shiny install. If
  # either is missing, point the user at the exact install command.
  for (pkg in c("shiny", "bslib", "plotly")) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      stop(
        "Install '", pkg, "' to use run_app(): ",
        "install.packages('", pkg, "')",
        call. = FALSE
      )
    }
  }
  app_dir <- system.file("shiny", package = "DrWrinch")
  if (!nzchar(app_dir)) {
    stop(
      "Could not find the Shiny app directory. Was DrWrinch installed ",
      "from source without 'inst/'?",
      call. = FALSE
    )
  }
  shiny::runApp(appDir = app_dir, launch.browser = launch_browser, ...)
}
