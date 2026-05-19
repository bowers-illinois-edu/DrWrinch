#' Sensitivity analysis for the urn Bayes factor
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
#' s <- sens_urn(7, 3)
#' s$bf
#' s$omega_star
#'
#' @seealso [bf_urn()], [sens_binomial()].
#' @export
sens_urn <- function(y_W, y_R, threshold = 20) {
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
