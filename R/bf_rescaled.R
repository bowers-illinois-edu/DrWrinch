#' The uniform-weights Bayes factor under weights the researcher states
#'
#' A range of shares is not a probability for the counts, so before
#' coding the researcher says how she spreads her weight over the shares
#' inside each theory's range. [bf_uniform_weights()] uses the default,
#' which gives every share in a range the same weight. This function
#' takes the alternative the paper offers, so that a reader who would
#' have weighted the shares differently can see what his weights do to
#' the reported number.
#'
#' The alternative starts from the Beta\eqn{(a, b)} family, a family of
#' distributions for a quantity between zero and one whose two
#' parameters set where the weight piles up: with \eqn{a > b} toward one,
#' with \eqn{a < b} toward zero, and with \eqn{a = b} symmetrically,
#' concentrated in the middle when \eqn{a = b} is above one and pushed
#' toward both ends when it is below one. Larger values of both
#' parameters concentrate the weight more tightly.
#'
#' Each theory's range is half as wide as the interval from zero to one,
#' so the researcher squeezes a Beta distribution onto it. If \eqn{X} has
#' the Beta\eqn{(a, b)} distribution, then \eqn{\theta = 1/2 + X/2} lies
#' between one half and one, which is the working theory's range, and
#' \eqn{\theta = X/2} lies between zero and one half, which is the
#' rival's. Squeezing an interval to half its width doubles the density,
#' so the two weighting functions are
#' \deqn{2 f_{a,b}(2\theta - 1) \quad\text{and}\quad 2 f_{a,b}(2\theta),}
#' with \eqn{f_{a,b}} the Beta density. Setting both pairs to
#' \eqn{(1, 1)} gives every share in each range the same weight and
#' returns [bf_uniform_weights()] exactly.
#'
#' @section What the parameters mean substantively:
#' The two pairs are a claim about what each theory predicts, and they
#' move the reported number, so a researcher has to argue for them. At
#' nine observations supporting the working theory against three
#' supporting the rival, the uniform default gives 20.67. Beta(1/2, 1/2)
#' on both sides piles weight at both ends of each range, including right
#' next to one half where the two theories predict nearly the same share,
#' so the counts separate the theories less and the value falls to 9.53.
#' Beta(10, 10) on both sides concentrates each theory near the middle of
#' its range, so the working theory predicts a share near three quarters
#' and the rival a share near one quarter, the two predict more different
#' things, and the value rises to 252.92.
#'
#' The pairs need not match. A researcher who thinks that under either
#' theory she would still turn up evidence for the other one puts both
#' densities next to one half, with `a1 = 0.5, b1 = 1` for the working
#' theory and `aR = 1, bR = 0.5` for the rival. A researcher who thinks
#' each theory would leave almost no evidence for the other pushes both
#' densities to the far ends, reversing those two pairs.
#'
#' @section Weights on shares are not weights on observations:
#' The weights here are weights on \eqn{\theta}, the share of the
#' evidence supporting the working theory. They are a different object
#' from a weight on an observation, which acts as replication: a document
#' the researcher weights at ten enters as ten observations, and she
#' passes that by summing the weights into `y_W` and `y_R`.
#'
#' @param y_W Non-negative integer. Count (or summed integer weight) of
#'   evidence favorable to the working theory.
#' @param y_R Non-negative integer. Count (or summed integer weight) of
#'   evidence favorable to the rival.
#' @param a1,b1 Positive numerics. The Beta pair squeezed onto the
#'   working theory's range, the shares above one half. Default `1` and
#'   `1`, the uniform weights.
#' @param aR,bR Positive numerics. The Beta pair squeezed onto the
#'   rival's range, the shares at or below one half. Default `1` and `1`.
#'
#' @return A length-1 numeric: the Bayes factor in favor of the working
#'   theory under the stated weights.
#'
#' @examples
#' # The uniform default, which is bf_uniform_weights(9, 3).
#' bf_rescaled(9, 3)
#'
#' # Beta(1/2, 1/2) on both sides: weight next to one half, where the
#' # two theories claim nearly the same share.
#' bf_rescaled(9, 3, 0.5, 0.5, 0.5, 0.5)
#'
#' # Beta(10, 10) on both sides: each theory concentrated in the middle
#' # of its range, so the two claims are far apart.
#' bf_rescaled(9, 3, 10, 10, 10, 10)
#'
#' @seealso [bf_uniform_weights()] for the uniform default;
#'   [bf_worst_case()] for the Bayes factor that evaluates the rival at
#'   her best single share instead of averaging over her range;
#'   [bf_binomial()] for a Beta prior on the whole interval, which also
#'   moves weight between the theories.
#' @export
bf_rescaled <- function(y_W, y_R, a1 = 1, b1 = 1, aR = 1, bR = 1) {
  .check_counts(y_W, y_R)
  stopifnot(
    length(a1) == 1L, length(b1) == 1L,
    length(aR) == 1L, length(bR) == 1L,
    a1 > 0, b1 > 0, aR > 0, bR > 0
  )
  n <- y_W + y_R
  lik <- function(theta) stats::dbinom(y_W, n, theta)
  # No closed form once the weights leave the uniform, so integrate.
  # Beta shapes below one make the density unbounded at the end of each
  # range, but the singularity is integrable and stats::integrate()
  # handles it at the tolerances the paper's tables need.
  num <- stats::integrate(
    function(theta) lik(theta) * .d_rescaled_W(theta, a1, b1), 0.5, 1)$value
  den <- stats::integrate(
    function(theta) lik(theta) * .d_rescaled_R(theta, aR, bR), 0, 0.5)$value
  num / den
}

# The two weighting functions, each a Beta density squeezed onto half the
# interval. The factor of 2 is the Jacobian of that squeezing: halving
# the width doubles the density, which is what keeps each of these
# integrating to one over the range it lives on.
.d_rescaled_W <- function(theta, a, b) 2 * stats::dbeta(2 * theta - 1, a, b)

.d_rescaled_R <- function(theta, a, b) 2 * stats::dbeta(2 * theta, a, b)
