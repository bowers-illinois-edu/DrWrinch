#' The uniform-weights Bayes factor
#'
#' A researcher has coded the evidence into two counts: `y_W` observations
#' support the working theory and `y_R` support a single rival. One model
#' underlies every Bayes factor in this package. Each observation supports
#' the working theory with probability \eqn{\theta}, the share of the
#' evidence that supports it. The working theory claims
#' \eqn{\theta > 1/2} and the rival claims \eqn{\theta \le 1/2}.
#'
#' Each claim is a range of shares rather than one share, so neither gives
#' a probability for the counts on its own. This function averages the
#' binomial probability of the counts over each theory's range, giving
#' every share in a range the same weight, and divides the working
#' theory's average by the rival's. At nine observations for the working
#' theory and three for the rival the two averages are 0.14675 and
#' 0.00710, and the Bayes factor is 20.67. [bf_worst_case()] keeps the
#' same numerator and evaluates the rival at a share of one half instead.
#'
#' The paper's rule sets the rival aside, at least provisionally, when
#' this value is 20 or more and the worst-case value is above 1. If every
#' share from zero to one half is equally likely, this value averages
#' exactly one over the counts the rival's claim could produce, so a
#' researcher who follows the rule is misled at most one time in twenty
#' on average over those shares, though not at every share.
#'
#' @section Closed form:
#' With \eqn{N = y_W + y_R} and \eqn{S = \sum_{j=0}^{y_W} \binom{N+1}{j}},
#' the value is \eqn{S / (2^{N+1} - S)} (supplement, thm-closed-form). The
#' function computes the same number as the ratio of the posterior masses
#' above and below one half under a Beta\eqn{(y_W + 1, y_R + 1)}
#' distribution, which is what the equal weights on two equally wide
#' ranges reduce to.
#'
#' @section A biased search:
#' A search `omega` times as likely to find a pro-working-theory
#' observation as a pro-rival one turns a share \eqn{\theta} of the
#' evidence into a share
#' \eqn{q = \omega\theta / (\omega\theta + 1 - \theta)} among the
#' observations found. Under bias the function puts \eqn{q} in place of
#' \eqn{\theta} inside the binomial probability, keeps the equal weights
#' on \eqn{\theta}, and integrates. Granting more bias lowers the value.
#' [sens_bias()] finds the bias at which the value falls to 20.
#'
#' @section Weights on observations:
#' A researcher who counts one observation as worth several routine ones
#' gives it a whole-number weight and passes the summed weights as the
#' counts: a memo weighted at ten among nine pro-working-theory
#' observations gives `bf_uniform_weights(18, 3)`, which is 2,337. These
#' weights on observations are a different object from the weights on
#' shares that [bf_rescaled()] takes.
#'
#' @param y_W Non-negative whole number. Count, or summed weight, of
#'   observations supporting the working theory.
#' @param y_R Non-negative whole number. Count, or summed weight, of
#'   observations supporting the rival.
#' @param omega Positive number. The bias factor: how many times as likely
#'   the search was to find a pro-working-theory observation as a
#'   pro-rival one. Default `1`, an unbiased search.
#'
#' @return A length-1 numeric: the Bayes factor in favor of the working
#'   theory.
#'
#' @examples
#' # The paper's running example: nine observations support the working
#' # theory, three support the rival.
#' bf_uniform_weights(9, 3)
#'
#' # A search twice as likely to find pro-working-theory evidence.
#' bf_uniform_weights(9, 3, omega = 2)
#'
#' # The smoking-gun memo counted as ten observations.
#' bf_uniform_weights(18, 3)
#'
#' @seealso [bf_worst_case()] for the other Bayes factor from the same
#'   model; [bf_rescaled()] for weights on shares other than the uniform;
#'   [bf_uniform_weights_finite()] for documents read from an archive of
#'   known size; [sens_bias()] and [sens_coding()] for the sensitivity
#'   analyses.
#' @export
bf_uniform_weights <- function(y_W, y_R, omega = 1) {
  .check_counts(y_W, y_R)
  .check_omega(omega)
  n <- y_W + y_R
  if (omega == 1) {
    # Both tails of the Beta(y_W + 1, y_R + 1) distribution are computed
    # directly rather than one as 1 minus the other, so that neither loses
    # its digits when the other is near one.
    above <- stats::pbeta(0.5, y_W + 1, y_R + 1, lower.tail = FALSE)
    below <- stats::pbeta(0.5, y_W + 1, y_R + 1)
    return(above / below)
  }
  # Under bias there is no closed form. The equal weights on the two
  # halves have the same height, 2, so they cancel and the ratio of the
  # two integrals is the ratio of the two averages.
  lik <- function(theta) stats::dbinom(y_W, n, .tilt(theta, omega))
  .integrate(lik, 0.5, 1) / .integrate(lik, 0, 0.5)
}
