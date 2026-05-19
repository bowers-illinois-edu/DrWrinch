#' Sensitivity analysis for the binomial Bayes factor
#'
#' Reports how the Bayes factor under the binomial model moves as the
#' coding-error rate `delta` and the prior parameters vary. Coding error
#' is modeled as the probability that a piece of evidence is misclassified
#' relative to its true theoretical content.
#'
#' @param k Integer. Observed count favorable to the working theory.
#' @param n Integer. Total observed count.
#' @param delta_grid Numeric in \eqn{[0, 0.5)}. Grid of coding-error
#'   rates. Default a sequence from 0 to 0.2.
#' @param prior_a,prior_b Positive numerics. Beta prior shape
#'   parameters. Default uniform.
#' @param theta_cut Numeric in (0, 1). Cutpoint. Default `0.5`.
#'
#' @return A data frame with columns `delta`, `bf`, and any prior
#'   parameters varied.
#'
#' @seealso [bf_binomial()], [sens_urn()].
#' @export
sens_binomial <- function(k, n,
                          delta_grid = seq(0, 0.2, by = 0.02),
                          prior_a = 1, prior_b = 1,
                          theta_cut = 0.5) {
  stop("Not yet implemented. See Paper/evalues.qmd sensitivity section ",
       "and Paper/memo_sensitivity_separation.md for the D1--D6 ",
       "decisions separating encounter, coding, weighting, and prior.")
}
