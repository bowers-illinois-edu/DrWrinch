#' Sensitivity analysis for the binomial Bayes factor
#'
#' Reports tipping points for the binomial Bayes factor: the smallest
#' observation bias `omega > 1` and the smallest rival-tilted prior
#' Beta(1, M + 1) at which the Bayes factor first drops below
#' `threshold`.
#'
#' `omega > 1` makes pro-\eqn{H_1} items more likely to be observed
#' than they are in the universe, so the apparent dominance of pro-
#' \eqn{H_1} evidence is partly an artifact of observation, and the
#' Bayes factor falls. `omega_star` is the value at which this fall
#' first crosses `threshold`. Beta(1, M + 1) priors place all density
#' on \eqn{\theta < 1} and posit `M` pseudo-observations all favoring
#' the rival. `M_star` is the smallest integer `M` at which the Bayes
#' factor first drops below `threshold`.
#'
#' If `bf_binomial(y_W, y_R) < threshold` at baseline, both tipping
#' points are `0` (the conclusion fails before any perturbation).
#'
#' @param y_W Non-negative integer. Observed count favorable to the
#'   working theory.
#' @param y_R Non-negative integer. Observed count favorable to the
#'   rival.
#' @param threshold Positive numeric. Decision threshold the Bayes
#'   factor must remain at or above. Default `20`.
#' @param theta_cut Numeric in (0, 1). Cutpoint. Default `0.5`.
#' @param M_max Positive integer. Largest `M` searched in the prior
#'   sweep. Default `200`.
#'
#' @return A list with elements:
#'   \describe{
#'     \item{`bf`}{Bayes factor at the baseline (`omega = 1`, uniform prior).}
#'     \item{`omega_star`}{Bias tipping point. `0` if `bf < threshold`
#'       at baseline; `NA_real_` if `bf` does not cross `threshold` for
#'       any reachable `omega`.}
#'     \item{`M_star`}{Smallest integer `M >= 0` with Beta(1, M + 1)
#'       prior at which the Bayes factor drops below `threshold`.
#'       `0` if `bf < threshold` at baseline; `NA_integer_` if the BF
#'       does not drop below threshold within `[0, M_max]`.}
#'   }
#'
#' @examples
#' # The paper's running example. The binomial BF just clears 20, so both
#' # tipping points are small: a slight bias or one rival-favoring
#' # pseudo-observation overturns it.
#' s <- sens_binomial(9, 3)
#' s$bf
#' s$omega_star
#' s$M_star
#'
#' @seealso [bf_binomial()], [sens_urn()], [sens_coding()].
#' @export
sens_binomial <- function(y_W, y_R,
                          threshold = 20,
                          theta_cut = 0.5,
                          M_max = 200L) {
  stopifnot(
    length(y_W) == 1L, length(y_R) == 1L,
    y_W >= 0, y_R >= 0,
    threshold > 0,
    theta_cut > 0, theta_cut < 1,
    M_max >= 0
  )

  bf_base <- bf_binomial(y_W, y_R, theta_cut = theta_cut)

  omega_star <- .find_omega_tipping(
    function(omega) bf_binomial(y_W, y_R, omega = omega,
                                theta_cut = theta_cut),
    threshold
  )

  M_star <- if (is.na(bf_base) || bf_base < threshold) {
    # Conclusion already fails at the uniform prior. No rival-favoring
    # pseudo-observations are needed; M_star = 0.
    0L
  } else {
    bfs <- vapply(
      0:M_max,
      function(M) bf_binomial(y_W, y_R,
                              prior_a = 1, prior_b = M + 1,
                              theta_cut = theta_cut),
      numeric(1)
    )
    hit <- which(bfs < threshold)
    if (length(hit) == 0L) NA_integer_ else as.integer(hit[1] - 1L)
  }

  list(bf = bf_base, omega_star = omega_star, M_star = M_star)
}
