#' Bayes factor under the binomial model
#'
#' Computes the Bayes factor for a working theory \eqn{H_1: \theta >
#' \theta_{\text{cut}}} against a rival \eqn{H_R: \theta \le
#' \theta_{\text{cut}}}, given `y_W` pieces of evidence favorable to
#' \eqn{H_1} and `y_R` pieces favorable to \eqn{H_R}, treated as
#' \eqn{n = y_W + y_R} independent Bernoulli draws from an infinite
#' evidence universe with success probability `theta`.
#'
#' This model fits research designs where the evidence universe is
#' open-ended --- ongoing interviews, an expanding archive, a growing
#' set of cases. For bounded archives, see [bf_urn()].
#'
#' Under a `Beta(prior_a, prior_b)` prior on `theta` and observation
#' bias `omega = 1` (unbiased), the posterior is
#' `Beta(prior_a + y_W, prior_b + y_R)` and the Bayes factor is the
#' ratio of posterior masses on the two sides of `theta_cut`. Under
#' observation bias `omega != 1`, the probability that an item supports
#' \eqn{H_1} given it was observed is `q = omega * theta / (1 + (omega -
#' 1) * theta)` (Fisher's odds-ratio transformation); the Bayes factor
#' is then computed by numerical integration. `omega > 1` makes pro-
#' \eqn{H_1} items likelier to be observed than they are in the
#' universe; `omega < 1` makes them less likely.
#'
#' For weighted analyses, sum the weights first and pass the sums:
#' `bf_binomial(sum(w_W), sum(w_R))`. Integer weights act as effective
#' replication; see the paper for the rationale.
#'
#' @param y_W Non-negative integer. Count (or summed integer weight) of
#'   evidence favorable to the working theory.
#' @param y_R Non-negative integer. Count (or summed integer weight) of
#'   evidence favorable to the rival.
#' @param omega Positive numeric. Observation-bias odds ratio.
#'   Default `1` (unbiased).
#' @param prior_a,prior_b Positive numerics. Beta prior shape
#'   parameters on `theta`. Default uniform prior, `1` and `1`.
#' @param theta_cut Numeric in (0, 1). Cutpoint separating \eqn{H_1}
#'   from \eqn{H_R}. Default `0.5`.
#'
#' @return A length-1 numeric: the Bayes factor in favor of \eqn{H_1}.
#'   Returns `NA_real_` if the integrated likelihood is numerically zero.
#'
#' @examples
#' # The paper's running example: nine pro-working-theory observations,
#' # three pro-rival. The binomial Bayes factor sits just above 20.
#' bf_binomial(9, 3)
#' bf_binomial(9, 3, omega = 0.5)
#' bf_binomial(9, 3, prior_a = 1, prior_b = 4)
#'
#' @seealso [bf_urn()] for the bounded-archive case;
#'   [sens_binomial()] for sensitivity to omega and prior;
#'   [sens_coding()] for sensitivity to coding error.
#' @export
bf_binomial <- function(y_W, y_R,
                        omega = 1,
                        prior_a = 1, prior_b = 1,
                        theta_cut = 0.5) {
  stopifnot(
    length(y_W) == 1L, length(y_R) == 1L,
    y_W >= 0, y_R >= 0,
    omega > 0,
    prior_a > 0, prior_b > 0,
    theta_cut > 0, theta_cut < 1
  )
  n <- y_W + y_R
  if (omega == 1) {
    # Unbiased observation: theta and q coincide, so the posterior is
    # Beta(prior_a + y_W, prior_b + y_R) in closed form. Avoid the
    # numerical integration that would otherwise be needed.
    p_below <- stats::pbeta(theta_cut, prior_a + y_W, prior_b + y_R)
  } else {
    # Biased observation: q = omega * theta / (1 + (omega - 1) * theta)
    # is Fisher's odds-ratio transformation of theta, the probability
    # that an item supports H_1 given it was observed. No closed form
    # for the posterior on theta, so we integrate.
    posterior_unn <- function(theta) {
      q <- (omega * theta) / (1 + (omega - 1) * theta)
      stats::dbinom(y_W, n, q) * stats::dbeta(theta, prior_a, prior_b)
    }
    p_marginal <- stats::integrate(posterior_unn, 0, 1)$value
    if (p_marginal == 0) return(NA_real_)
    p_below <- stats::integrate(posterior_unn, 0, theta_cut)$value / p_marginal
  }
  (1 - p_below) / p_below
}
