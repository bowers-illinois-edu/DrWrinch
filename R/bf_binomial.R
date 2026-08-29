#' Posterior odds on the working theory under a whole-interval Beta prior
#'
#' One model underlies every Bayes factor in this package. Each
#' observation supports the working theory with probability
#' \eqn{\theta}, the share of the evidence that supports it. The working
#' theory claims \eqn{\theta > \theta_{\text{cut}}} and the rival claims
#' \eqn{\theta \le \theta_{\text{cut}}}, with the cut at one half unless
#' the researcher moves it. The researcher has coded `y_W` observations
#' as supporting the working theory and `y_R` as supporting the rival,
#' and treats them as \eqn{n = y_W + y_R} independent draws.
#'
#' At the default uniform prior this function returns the uniform-weights
#' Bayes factor, 20.67 at nine observations against three, and
#' [bf_uniform_weights()] is the name to use for it. This function is the
#' earlier name for that number and is kept for one release. It is not a
#' plain alias, because it also carries the whole-interval Beta prior
#' that [sens_binomial()] needs, and under any prior but the uniform the
#' number it returns is a different object.
#'
#' @section Why a tilted prior returns posterior odds rather than a Bayes factor:
#' A `Beta(prior_a, prior_b)` prior on the whole interval from zero to
#' one does two jobs at once. It says how the researcher spreads her
#' weight over the shares inside each theory's range, and it also says
#' how much weight she gives each theory: the prior mass above the cut,
#' call it \eqn{\pi_1}, sets the prior odds \eqn{\pi_1 / (1 - \pi_1)}.
#' The Bayes factor renormalizes the prior to each theory's range before
#' averaging the likelihood, so the prior odds cancel out of it. The
#' posterior odds keep them: posterior odds are prior odds times Bayes
#' factor.
#'
#' This function returns the ratio of posterior masses on the two sides
#' of the cut, which is the posterior odds. Under the uniform prior the
#' two theories get equal weight, the prior odds are one, and the
#' posterior odds and the Bayes factor coincide --- a fact about that
#' prior, not a definition. Under a `Beta(1, M + 1)` prior, which reads
#' as M background cases all favoring the rival, the two separate and
#' move in opposite directions. At nine observations against three:
#'
#' \tabular{rrr}{
#'   background cases M \tab posterior odds \tab Bayes factor \cr
#'   0 \tab 20.67 \tab 20.67 \cr
#'   1 \tab 10.14 \tab 30.41 \cr
#'   2 \tab  5.63 \tab 39.39 \cr
#'   3 \tab  3.40 \tab 51.01 \cr
#'   4 \tab  2.18 \tab 67.56
#' }
#'
#' Tilting the prior toward the rival commits her to shares near zero,
#' under which nine of twelve is more surprising still, so the evidence
#' discriminates more sharply and the Bayes factor rises. The same tilt
#' lowers the prior odds by more, so the posterior odds fall. A
#' researcher who wants weights inside each theory's range without
#' moving the weight between the theories states them through
#' [bf_rescaled()] instead.
#'
#' Under observation bias `omega != 1`, the probability that an item
#' supports the working theory given it was observed is
#' `q = omega * theta / (1 + (omega - 1) * theta)` (Fisher's odds-ratio
#' transformation); the value is then computed by numerical integration.
#' `omega > 1` makes evidence for the working theory likelier to be
#' observed than it is in the evidence as a whole; `omega < 1` makes it
#' less likely.
#'
#' For weighted analyses, sum the weights first and pass the sums:
#' `bf_binomial(sum(w_W), sum(w_R))`. Integer weights act as effective
#' replication; see the paper for the rationale. Those are weights on
#' observations, a different object from the weights on shares that
#' [bf_rescaled()] takes.
#'
#' @param y_W Non-negative integer. Count (or summed integer weight) of
#'   evidence favorable to the working theory.
#' @param y_R Non-negative integer. Count (or summed integer weight) of
#'   evidence favorable to the rival.
#' @param omega Positive numeric. Observation-bias odds ratio.
#'   Default `1` (unbiased).
#' @param prior_a,prior_b Positive numerics. Beta prior shape
#'   parameters on `theta`, on the whole interval from zero to one.
#'   Default uniform prior, `1` and `1`.
#' @param theta_cut Numeric in (0, 1). Cutpoint separating the working
#'   theory from the rival. Default `0.5`.
#'
#' @return A length-1 numeric: the posterior odds on the working theory
#'   against the rival. Under the default uniform prior these are the
#'   uniform-weights Bayes factor; under any other prior they are not.
#'   Returns `NA_real_` if the integrated likelihood is numerically zero.
#'
#' @examples
#' # The paper's running example: nine pro-working-theory observations,
#' # three pro-rival. At the uniform prior this is the uniform-weights
#' # Bayes factor.
#' bf_binomial(9, 3)
#' bf_binomial(9, 3, omega = 0.5)
#'
#' # One background case favoring the rival. The posterior odds fall to
#' # 10.14 even though the Bayes factor rises to 30.41.
#' bf_binomial(9, 3, prior_a = 1, prior_b = 2)
#'
#' @seealso [bf_uniform_weights()] for this number under the uniform
#'   default; [bf_rescaled()] for weights stated within each theory's
#'   range; [bf_worst_case()] for the other Bayes factor from the same
#'   model; [sens_binomial()] for sensitivity to omega and prior;
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

#' The uniform-weights Bayes factor
#'
#' Two Bayes factors in this package come from one model, share a
#' numerator, and differ only in the denominator. Each observation
#' supports the working theory with probability \eqn{\theta}, the share
#' of the evidence that supports it; the working theory claims
#' \eqn{\theta > 1/2} and the rival claims \eqn{\theta \le 1/2}. The
#' shared numerator is the binomial probability of the counts averaged
#' over the shares above one half, giving every such share the same
#' weight.
#'
#' The rival claims a range of shares rather than one share, so her claim
#' does not by itself give a probability for the counts, and turning the
#' range into one number takes a rule. This function uses the rule that
#' matches the numerator: average over her whole range, giving every
#' share at or below one half the same weight. [bf_worst_case()] uses the
#' other rule, handing her the single share, one half, that fits the
#' counts best.
#'
#' The two rules answer different questions. Averaging over the rival's
#' whole range holds her to every version of her claim equally, including
#' shares near zero under which the counts are very improbable, and it is
#' averaging over those shares that lifts the number. Evaluating her at
#' one half grants her the version of her claim that fits the counts
#' best, which is why that number is smaller and why it carries an error
#' rate the averaged one does not.
#'
#' A researcher who wants weights other than the uniform within each
#' range states them through [bf_rescaled()].
#'
#' @param y_W Non-negative integer. Count (or summed integer weight) of
#'   evidence favorable to the working theory.
#' @param y_R Non-negative integer. Count (or summed integer weight) of
#'   evidence favorable to the rival.
#' @param omega Positive numeric. The odds by which the search favored
#'   surfacing evidence for the working theory. Default `1`, an
#'   unbiased search.
#'
#' @return A length-1 numeric: the Bayes factor in favor of the working
#'   theory, averaging over the rival's whole range of shares under
#'   uniform weights.
#'
#' @examples
#' # The paper's running example: nine observations support the working
#' # theory, three support the rival.
#' bf_uniform_weights(9, 3)
#'
#' # Granting that the search was twice as likely to surface evidence
#' # for the working theory lowers the value.
#' bf_uniform_weights(9, 3, omega = 2)
#'
#' @seealso [bf_worst_case()] for the other Bayes factor from the same
#'   model; [bf_rescaled()] for weights the researcher states within each
#'   range; [bf_binomial()] for the earlier name, which also carries the
#'   whole-interval Beta prior.
#' @export
bf_uniform_weights <- function(y_W, y_R, omega = 1) {
  # Uniform weight within each range is the default whole-interval
  # uniform prior, so the arithmetic already lives in bf_binomial().
  # Delegating rather than copying it keeps one implementation of the
  # closed form and of the omega branch.
  bf_binomial(y_W, y_R, omega = omega)
}
