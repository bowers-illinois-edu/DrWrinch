#' Sensitivity analysis for the urn Bayes factor
#'
#' Reports how the Bayes factor under the hypergeometric urn model moves
#' as the coding-error rate `delta` and the observation-bias parameter
#' `omega` vary across user-supplied grids. Returns a long-format data
#' frame for direct plotting; companion plotting helpers are planned.
#'
#' @param y_W Integer. Observed count favorable to the working theory.
#' @param y_R Integer. Observed count favorable to the rival.
#' @param delta_grid Numeric in \eqn{[0, 0.5)}. Grid of coding-error
#'   rates. Default `seq(0, 0.2, by = 0.02)`.
#' @param omega_grid Positive numeric. Grid of observation-bias odds
#'   ratios. Default `c(0.5, 1, 2)`.
#'
#' @return A data frame with columns `delta`, `omega`, and `bf`.
#'
#' @seealso [bf_urn()], [sens_binomial()].
#' @export
sens_urn <- function(y_W, y_R,
                     delta_grid = seq(0, 0.2, by = 0.02),
                     omega_grid = c(0.5, 1, 2)) {
  stop("Not yet implemented. See Paper/evalues.qmd sensitivity section ",
       "and Paper/memo_sensitivity_separation.md.")
}
