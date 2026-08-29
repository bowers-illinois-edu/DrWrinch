#' Sensitivity analysis for the urn Bayes factor (deprecated)
#'
#' Deprecated. The paper no longer uses the hypergeometric urn model,
#' so there is no longer a reason to ask how search bias moves its Bayes
#' factor. The same question about the worst-case Bayes factor is
#' answered by [bf_separated_bias()], which tilts both theories' claims
#' by the assumed bias, and the coding-error question by
#' [sens_coding()] with `model = "worst_case"`.
#'
#' This function is not removed, because the first arXiv version of the
#' paper cites it and its replication code calls it. It returns exactly
#' what it always returned and warns once per session.
#'
#' Reports the bias tipping point for the urn Bayes factor: the
#' smallest observation bias `omega > 1` at which the Bayes factor
#' first drops below `threshold`.
#'
#' `omega > 1` makes pro-\eqn{H_1} items more likely to be drawn than
#' they are in the urn, so the apparent dominance of pro-\eqn{H_1}
#' evidence is partly an artifact of observation, and the Bayes factor
#' falls. `omega_star` is the value at which this fall first crosses
#' `threshold`. If `bf_urn(y_W, y_R) < threshold` at baseline,
#' `omega_star` is `0`.
#'
#' @param y_W Non-negative integer. Observed count favorable to the
#'   working theory.
#' @param y_R Non-negative integer. Observed count favorable to the
#'   rival.
#' @param threshold Positive numeric. Decision threshold the Bayes
#'   factor must remain at or above. Default `20`.
#'
#' @return A list with elements:
#'   \describe{
#'     \item{`bf`}{Bayes factor at `omega = 1`.}
#'     \item{`omega_star`}{Bias tipping point. `0` if `bf < threshold`
#'       at baseline; `NA_real_` if `bf` does not cross `threshold` for
#'       any reachable `omega`.}
#'   }
#'
#' @examples
#' # The paper's running example. bf_urn(9, 3) = 323 is far above 20, so
#' # pro-H_1 items must be ~2.4 times likelier to be observed before the
#' # urn BF reaches the threshold.
#' s <- sens_urn(9, 3)
#' s$bf
#' s$omega_star
#'
#' @seealso [bf_separated_bias()] and [sens_coding()] for the same two
#'   questions asked of the worst-case Bayes factor; [sens_binomial()]
#'   for them asked of the uniform-weights Bayes factor; [bf_urn()] for
#'   the Bayes factor swept here.
#' @export
sens_urn <- function(y_W, y_R, threshold = 20) {
  .deprecate_once(
    "sens_urn",
    paste("sens_urn() is deprecated. The paper no longer uses the",
          "hypergeometric urn model. The search-bias question it answers",
          "is answered for the worst-case Bayes factor by",
          "bf_separated_bias(), and the coding-error question by",
          "sens_coding(model = \"worst_case\"); see bf_worst_case() for",
          "the Bayes factor itself. sens_urn() is kept for the first",
          "arXiv version's replication code and still returns what it",
          "always returned.")
  )
  stopifnot(
    length(y_W) == 1L, length(y_R) == 1L,
    y_W >= 0, y_R >= 0, y_W + y_R > 0,
    threshold > 0
  )

  bf_base <- bf_urn(y_W, y_R)

  omega_star <- .find_omega_tipping(
    function(omega) bf_urn(y_W, y_R, omega = omega),
    threshold
  )

  list(bf = bf_base, omega_star = omega_star)
}
