#' Worst-case Bayes factor: the rival at its most favorable share
#'
#' A researcher has coded the evidence into two counts: `y_W` observations
#' support the working theory and `y_R` support a single rival. One model
#' underlies both Bayes factors in this package. Each observation supports
#' the working theory with probability \eqn{\theta}, the share of the
#' evidence that supports it. The working theory claims
#' \eqn{\theta > 1/2} and the rival claims \eqn{\theta \le 1/2}.
#'
#' The numerator is the one [bf_uniform_weights()] uses: the binomial
#' probability of the counts averaged over the shares above one half. The
#' denominator is the largest probability any weights on the rival's
#' shares can give the counts. When at least as many observations support
#' the working theory as the rival, the probability of the counts rises on
#' the whole of the rival's range, so that largest probability is the one
#' at a share of one half. The value is therefore the smallest Bayes
#' factor a critic can produce by changing only the weights on the rival's
#' shares (supplement, prp-bound). At nine observations for the working
#' theory and three for the rival it is 7814 / 2860 = 2.73.
#'
#' The paper's rule sets the rival aside, at least provisionally, when the
#' uniform-weights value is 20 or more and this value is above 1. A value
#' above 1 means that no weights on the rival's shares make the counts
#' more probable under the rival than under the working theory.
#'
#' @section Closed form:
#' With \eqn{N = y_W + y_R}, uniform weights on the working theory's
#' shares, and no bias, the value is
#' \deqn{\frac{\sum_{j=0}^{y_W} \binom{N+1}{j}}{(N+1)\binom{N}{y_W}}}
#' (supplement, thm-closed-form). The paper evaluates the rival at one
#' half at every count, and so does this function when `y_W < y_R`;
#' at those counts the value is below 1 and the rule keeps the rival
#' whichever share the rival is held at.
#'
#' @section Stated weights on the working theory's shares:
#' `a1` and `b1` replace the uniform weights in the numerator with a
#' Beta\eqn{(a_1, b_1)} distribution rescaled onto the shares above one
#' half: if \eqn{X} has that distribution, \eqn{\theta = 1/2 + X/2}. Only
#' the working theory's weights enter, because the rival is evaluated at
#' its most favorable share whatever weights its proponent might state. At
#' nine of twelve, Beta(1/2, 1/2) gives 2.07 and Beta(10, 10) gives 4.38.
#' No weights give more than 4.81, the value with all the weight on a
#' share of nine twelfths.
#'
#' @section A biased search:
#' A search `omega` times as likely to find a pro-working-theory
#' observation as a pro-rival one turns a share \eqn{\theta} of the
#' evidence into a share
#' \eqn{q = \omega\theta / (\omega\theta + 1 - \theta)} among the
#' observations found. The numerator averages the probability of the
#' counts at \eqn{q} over the working theory's shares. The rival's shares
#' become shares found of at most \eqn{\omega / (1 + \omega)}, and the
#' counts are most probable at a share found of \eqn{y_W / N}, so the
#' denominator is the probability at whichever of the two is smaller.
#'
#' Up to \eqn{\omega = y_W / y_R} that is the probability at a share of
#' one half, which is the value the paper's code computed. Past it the
#' rival's most favorable share is below one half. At nine of twelve and
#' \eqn{\omega = 5}, one half becomes 5/6 found, where nine of twelve has
#' probability 0.197, while a share of 0.375 becomes 0.75 found, where it
#' has probability 0.258; the numerator is 0.0554, so the value is
#' 0.0554 / 0.258 = 0.21 rather than 0.0554 / 0.197 = 0.28. The bias at
#' which the value falls to 1 always comes before \eqn{y_W / y_R}, so
#' [sens_bias()] gives the same tipping point under either reading.
#'
#' @param y_W Non-negative whole number. Count, or summed weight, of
#'   observations supporting the working theory.
#' @param y_R Non-negative whole number. Count, or summed weight, of
#'   observations supporting the rival.
#' @param omega Positive number. The bias factor: how many times as likely
#'   the search was to find a pro-working-theory observation as a
#'   pro-rival one. Default `1`, an unbiased search.
#' @param a1,b1 Positive numbers. The Beta pair rescaled onto the working
#'   theory's shares. Default `1` and `1`, uniform weights.
#'
#' @return A length-1 numeric: the Bayes factor in favor of the working
#'   theory with the rival at its most favorable share.
#'
#' @examples
#' # The paper's running example: nine observations support the working
#' # theory, three support the rival.
#' bf_worst_case(9, 3)
#'
#' # Seven of twelve falls below one: a rival who may claim an evenly
#' # split body of evidence is not embarrassed by those counts.
#' bf_worst_case(7, 5)
#'
#' # The smoking-gun memo counted as ten observations.
#' bf_worst_case(18, 3)
#'
#' # Weights on the working theory's shares concentrated near 3/4.
#' bf_worst_case(9, 3, a1 = 10, b1 = 10)
#'
#' # A search twice as likely to find pro-working-theory evidence.
#' bf_worst_case(9, 3, omega = 2)
#'
#' @seealso [bf_uniform_weights()] for the Bayes factor that averages over
#'   the rival's whole range; [bf_worst_case_finite()] for documents read
#'   from an archive of known size; [sens_bias()] and [sens_coding()] for
#'   the sensitivity analyses.
#' @export
bf_worst_case <- function(y_W, y_R, omega = 1, a1 = 1, b1 = 1) {
  .check_counts(y_W, y_R)
  .check_omega(omega)
  stopifnot(length(a1) == 1L, length(b1) == 1L,
            is.numeric(a1), is.numeric(b1), a1 > 0, b1 > 0)
  n <- y_W + y_R
  if (omega == 1 && a1 == 1 && b1 == 1) {
    return(.worst_case_closed_form(y_W, n))
  }
  num <- .integrate(
    function(theta) {
      stats::dbinom(y_W, n, .tilt(theta, omega)) * .d_rescaled_W(theta, a1, b1)
    },
    0.5, 1
  )
  # The rival's shares become shares found of at most omega / (1 + omega).
  # When the counts favor the working theory, the probability of the
  # counts peaks at a share found of y_W / n, so the rival does best at
  # whichever of the two is smaller. When the counts favor the rival the
  # paper holds the rival at one half, and so does this function.
  q_half <- .tilt(0.5, omega)
  q_rival <- if (n > 0 && y_W >= y_R) min(q_half, y_W / n) else q_half
  num / stats::dbinom(y_W, n, q_rival)
}

# The closed form of thm-closed-form. Binomial coefficients overflow a
# double past roughly a thousand observations, which would turn the
# ratio into Inf / Inf = NaN. No process-tracing study comes near that,
# but the same arithmetic on the log scale costs a few lines and never
# overflows.
.worst_case_closed_form <- function(y_W, n) {
  value <- sum(choose(n + 1, 0:y_W)) / ((n + 1) * choose(n, y_W))
  if (is.finite(value)) return(value)
  log_terms <- lchoose(n + 1, 0:y_W)
  m <- max(log_terms)
  log_numerator <- m + log(sum(exp(log_terms - m)))
  exp(log_numerator - log(n + 1) - lchoose(n, y_W))
}
