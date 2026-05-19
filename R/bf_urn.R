#' Bayes factor under the hypergeometric urn model
#'
#' Computes the Bayes factor for a working theory \eqn{H_1} against a
#' single rival \eqn{H_R}, given observed counts `y_W` of evidence
#' favorable to \eqn{H_1} and `y_R` of evidence favorable to \eqn{H_R},
#' under Formulation C of the urn construction. The Working Theory
#' Favorable sub-model has urn composition \eqn{(y_W + 1, \max(1, y_R))};
#' the Rival Theory Favorable sub-model has urn composition
#' \eqn{(y_W, y_W + 1)}. Both constructions tilt in favor of the rival,
#' so the Bayes factor returned is a lower bound on the evidence for
#' \eqn{H_1}.
#'
#' Observation bias `omega` enters as the odds ratio in Fisher's
#' non-central hypergeometric distribution (via the BiasedUrn package):
#' `omega = 1` is unbiased; `omega > 1` makes pro-\eqn{H_1} items
#' likelier to be observed; `omega < 1` makes them less likely.
#'
#' This model fits research designs where the evidence base is bounded
#' and fixed --- a closed historical archive, a fixed roster of
#' documents. For open-ended evidence collection, see [bf_binomial()].
#'
#' @param y_W Integer. Count of evidence favorable to the working theory.
#' @param y_R Integer. Count of evidence favorable to the rival.
#' @param omega Positive numeric. Observation bias (odds ratio).
#'   Default `1` (unbiased).
#'
#' @return A length-1 numeric: the Bayes factor in favor of \eqn{H_1}.
#'
#' @examples
#' \dontrun{
#' bf_urn(y_W = 8, y_R = 2)
#' bf_urn(y_W = 8, y_R = 2, omega = 0.5)
#' }
#'
#' @seealso [bf_binomial()] for the open-ended-evidence case.
#' @export
bf_urn <- function(y_W, y_R, omega = 1) {
  stop("Not yet implemented. See Paper/evalues.qmd Section 5 and ",
       "Paper/appendix.qmd for the Formulation C construction.")
}
