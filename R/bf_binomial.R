#' Bayes factor under the binomial model
#'
#' Computes the Bayes factor for a working theory \eqn{H_1: \theta > 0.5}
#' against a rival \eqn{H_R: \theta \le 0.5}, given `k` pieces of
#' evidence favorable to \eqn{H_1} out of `n` independent draws from an
#' infinite evidence universe with success probability `theta`. Under a
#' `Beta(prior_a, prior_b)` prior on `theta`, the posterior is
#' `Beta(prior_a + k, prior_b + n - k)`, and the Bayes factor is the
#' ratio of posterior probabilities on the two sides of the cut.
#'
#' This model fits research designs where the evidence universe is
#' open-ended --- ongoing interviews, an expanding archive, a growing
#' set of cases. For bounded archives, see [bf_urn()].
#'
#' The default uniform prior (`prior_a = prior_b = 1`) makes the Bayes
#' factor equal to the posterior odds. Other priors are accepted but
#' should be motivated in the analysis.
#'
#' @param k Integer. Count of evidence favorable to the working theory.
#' @param n Integer. Total count of evidence pieces observed.
#' @param theta_cut Numeric in (0, 1). Cutpoint separating \eqn{H_1}
#'   from \eqn{H_R}. Default `0.5`.
#' @param prior_a,prior_b Positive numerics. Beta prior shape
#'   parameters on `theta`. Default uniform prior, `1` and `1`.
#'
#' @return A length-1 numeric: the Bayes factor in favor of \eqn{H_1}.
#'
#' @examples
#' bf_binomial(k = 8, n = 10)
#' bf_binomial(k = 5, n = 10)
#' bf_binomial(k = 50, n = 60, prior_a = 2, prior_b = 2)
#'
#' @seealso [bf_urn()] for the bounded-archive case.
#' @export
bf_binomial <- function(k, n, theta_cut = 0.5, prior_a = 1, prior_b = 1) {
  stopifnot(
    length(k) == 1L, length(n) == 1L,
    k >= 0, n >= k,
    theta_cut > 0, theta_cut < 1,
    prior_a > 0, prior_b > 0
  )
  post_a <- prior_a + k
  post_b <- prior_b + (n - k)
  p_h1 <- stats::pbeta(theta_cut, post_a, post_b, lower.tail = FALSE)
  p_hr <- stats::pbeta(theta_cut, post_a, post_b, lower.tail = TRUE)
  p_h1 / p_hr
}
