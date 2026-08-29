#' Worst-case Bayes factor: the rival evaluated at her best single share
#'
#' A researcher has coded her evidence into two counts: `y_W` observations
#' support her working theory and `y_R` support a single rival. One model
#' underlies both Bayes factors in this package. Each observation supports
#' the working theory with probability \eqn{\theta}, the share of the
#' evidence that supports it. The working theory claims
#' \eqn{\theta > 1/2} and the rival claims \eqn{\theta \le 1/2}.
#'
#' The rival's claim is a range of shares, not one share, so it does not
#' by itself give a probability for the counts. Turning the range into
#' one number takes a rule, and this function uses the rule most generous
#' to the rival: evaluate her claim at the single share, one half, that
#' makes the observed counts most probable. Because no other share in her
#' range fits the counts better, no weighting of her range that the
#' researcher could have stated before coding would make the evidence
#' against the rival look weaker. The reported value is therefore a lower
#' bound, and a critic cannot say the researcher chose the rival's model
#' to suit herself.
#'
#' The numerator is the same one [bf_uniform_weights()] uses: the
#' probability of the counts averaged over the shares above one half
#' under uniform weights. The two functions come from the same model and
#' differ only in the denominator. [bf_uniform_weights()] averages over
#' the rival's whole range; this function takes her best point in it.
#'
#' @section Closed form:
#' With \eqn{N = y_W + y_R}, the ratio equals
#' \deqn{\frac{\sum_{j=0}^{y_W} \binom{N+1}{j}}{(N+1)\binom{N}{y_W}},}
#' which is what this function computes. The value is defined at every
#' pair of counts, including counts that favor the rival, where it falls
#' below one.
#'
#' @section Error rate:
#' In a world where the rival's claim holds, a researcher who treats 20
#' as the value at which she sets the rival aside is misled at most one
#' time in twenty. The guarantee holds for independent draws and for
#' draws without replacement from a collection of any size, so she never
#' has to state how large the body of evidence is.
#'
#' @param y_W Non-negative integer. Count (or summed integer weight) of
#'   evidence favorable to the working theory.
#' @param y_R Non-negative integer. Count (or summed integer weight) of
#'   evidence favorable to the rival.
#'
#' @return A length-1 numeric: the Bayes factor in favor of the working
#'   theory, evaluating the rival at a share of one half.
#'
#' @examples
#' # The paper's running example: nine observations support the working
#' # theory, three support the rival.
#' bf_worst_case(9, 3)
#'
#' # Seven of twelve falls below one. A rival who may claim an evenly
#' # split body of evidence is not embarrassed by those counts.
#' bf_worst_case(7, 5)
#'
#' @seealso [bf_uniform_weights()] for the other Bayes factor from the
#'   same model, which averages over the rival's whole range;
#'   [bf_separated()] and [separation_g()] for the version that separates
#'   the two theories by a stated margin.
#' @export
bf_worst_case <- function(y_W, y_R) {
  .check_counts(y_W, y_R)
  n <- y_W + y_R
  value <- sum(choose(n + 1, 0:y_W)) / ((n + 1) * choose(n, y_W))
  if (is.finite(value)) return(value)
  # Binomial coefficients overflow a double past roughly a thousand
  # observations, which turns the expression above into Inf/Inf = NaN.
  # No process-tracing application comes near that, but returning NaN
  # silently would be worse than the few lines it costs to redo the same
  # arithmetic on the log scale, where nothing overflows.
  log_terms <- lchoose(n + 1, 0:y_W)
  m <- max(log_terms)
  log_numerator <- m + log(sum(exp(log_terms - m)))
  exp(log_numerator - log(n + 1) - lchoose(n, y_W))
}

#' Bayes factor when the two theories are separated by a stated margin
#'
#' The plain version of the model puts the two theories against each
#' other at the same point: the working theory claims a share above one
#' half and the rival a share at or below it, so the two claims touch.
#' A researcher who wants to ask how far apart the theories must be
#' before her counts settle the question separates them by a margin `g`:
#' the working theory now claims a share of at least \eqn{1/2 + g} and
#' the rival a share of at most \eqn{1/2 - g}. She compares the
#' probability of her counts at the first share against the probability
#' at the second.
#'
#' Everything except the margin between the counts cancels, leaving
#' \deqn{\left(\frac{1 + 2g}{1 - 2g}\right)^{y_W - y_R}.}
#' Two consequences follow. Equal counts give exactly one however far
#' apart the researcher places the two theories, and reversing every
#' coding decision sends the value to its exact reciprocal. Neither is
#' true of [bf_worst_case()], whose numerator averages over a range while
#' its denominator sits at a point.
#'
#' The researcher does not pick `g` to suit her conclusion. She solves
#' for the `g` at which the value reaches the threshold she cares about
#' and reports that; [separation_g()] does the solving.
#'
#' @param y_W,y_R Non-negative integers. Counts favoring the working
#'   theory and the rival.
#' @param g Numeric strictly between 0 and 0.5. The margin separating the
#'   two theories' claims from one half.
#'
#' @return A length-1 numeric: the Bayes factor in favor of the working
#'   theory at separation `g`.
#'
#' @examples
#' # At the separation the running example needs to reach 20.
#' bf_separated(9, 3, separation_g(9, 3))
#'
#' # Equal counts give one at any separation.
#' bf_separated(6, 6, 0.2)
#'
#' @seealso [separation_g()] for the separation that reaches a threshold;
#'   [bf_separated_bias()] for the version that grants a biased search;
#'   [bf_worst_case()] for the unseparated Bayes factor.
#' @export
bf_separated <- function(y_W, y_R, g) {
  .check_counts(y_W, y_R)
  stopifnot(length(g) == 1L, g > 0, g < 0.5)
  ((1 + 2 * g) / (1 - 2 * g))^(y_W - y_R)
}

#' The separation at which the counts reach a threshold
#'
#' A researcher reports how far apart the two theories have to be placed
#' before her counts settle the question at the threshold she cares
#' about. This function solves [bf_separated()] for that margin: it
#' returns the `g` at which the separated Bayes factor equals
#' `threshold`. At nine observations for the working theory against
#' three for the rival and a threshold of 20, the answer is 0.123, so the
#' two theories reach 20 once one claims a share of at least 0.623 and
#' the other a share of at most 0.377.
#'
#' The reported margin is rounded up rather than to nearest. Rounding
#' down would leave the Bayes factor at the printed margin just under the
#' threshold, so a reader who recomputed the value from the printed
#' margin would find it did not reach the threshold the researcher
#' claimed.
#'
#' The function requires more observations supporting the working theory
#' than the rival. With equal or rival-favoring counts the separated
#' Bayes factor never exceeds one, so no margin reaches a threshold above
#' one and there is nothing to report.
#'
#' @param y_W,y_R Non-negative integers. Counts favoring the working
#'   theory and the rival. Requires `y_W > y_R`.
#' @param threshold Numeric above 1. The value at which the researcher
#'   would set the rival aside. Default `20`.
#' @param digits Non-negative integer. Decimal places in the reported
#'   margin. Default `3`.
#'
#' @return A length-1 numeric: the margin, rounded up to `digits`
#'   decimals.
#'
#' @examples
#' separation_g(9, 3)
#' separation_g(9, 3, threshold = 100)
#'
#' @seealso [bf_separated()], which this function inverts.
#' @export
separation_g <- function(y_W, y_R, threshold = 20, digits = 3) {
  .check_counts(y_W, y_R)
  stopifnot(
    length(threshold) == 1L, threshold > 1,
    length(digits) == 1L, digits >= 0, digits == round(digits)
  )
  d <- y_W - y_R
  if (d <= 0) {
    stop("separation_g() needs more observations supporting the working ",
         "theory than the rival: no separation lifts the Bayes factor to ",
         "a threshold above one otherwise")
  }
  g <- (threshold^(1 / d) - 1) / (2 * (threshold^(1 / d) + 1))
  ceiling(g * 10^digits) / 10^digits
}

#' Separated Bayes factor granting a search biased toward the working theory
#'
#' Suppose the researcher's search was `omega` times as likely to surface
#' a document supporting the working theory as one supporting the rival.
#' Then part of the apparent dominance of her counts comes from how she
#' looked rather than from what is there. The bias turns a share
#' \eqn{\theta} of supporting documents in the collection into a share
#' \eqn{\omega\theta / (\omega\theta + 1 - \theta)} among the documents
#' she found, and this function compares the two theories' claims after
#' both have been tilted that way. At `omega = 1` it returns
#' [bf_separated()] exactly.
#'
#' Granting more bias lowers the value: conceding that the search favored
#' the working theory weakens what the counts can show.
#'
#' The error-rate guarantee that [bf_worst_case()] carries has been
#' checked numerically for this statistic at every `omega` at or above
#' one that the authors tried, and it provably fails below one. A proof
#' for `omega >= 1` is still owed, so tables built from this function
#' should say that the guarantee was checked numerically rather than
#' proved.
#'
#' @param y_W,y_R Non-negative integers. Counts favoring the working
#'   theory and the rival.
#' @param g Numeric strictly between 0 and 0.5. The margin separating the
#'   two theories' claims from one half.
#' @param omega Positive numeric. The odds by which the search favored
#'   surfacing evidence for the working theory. Default `1`, an unbiased
#'   search.
#'
#' @return A length-1 numeric: the bias-corrected separated Bayes factor.
#'
#' @examples
#' # An unbiased search recovers the uncorrected value.
#' bf_separated_bias(9, 3, 0.125)
#'
#' # Granting that the search favored the working theory by half again
#' # takes the running example from about 21 down to about 6.4.
#' bf_separated_bias(9, 3, 0.125, omega = 1.5)
#'
#' @seealso [bf_separated()] for the uncorrected version;
#'   [sens_binomial()] for sensitivity to `omega` under [bf_binomial()].
#' @export
bf_separated_bias <- function(y_W, y_R, g, omega = 1) {
  .check_counts(y_W, y_R)
  stopifnot(
    length(g) == 1L, g > 0, g < 0.5,
    length(omega) == 1L, omega > 0
  )
  tilt <- function(theta) omega * theta / (omega * theta + 1 - theta)
  t1 <- tilt(0.5 + g)
  t0 <- tilt(0.5 - g)
  (t1 / t0)^y_W * ((1 - t1) / (1 - t0))^y_R
}

# Counts must be whole numbers, not merely non-negative. bf_worst_case()
# sums binomial coefficients over 0:y_W, and R truncates a fractional
# y_W there without complaint, so an unchecked 9.5 would return the value
# for 9 rather than an error.
.check_counts <- function(y_W, y_R) {
  stopifnot(
    length(y_W) == 1L, length(y_R) == 1L,
    is.numeric(y_W), is.numeric(y_R),
    !is.na(y_W), !is.na(y_R),
    y_W >= 0, y_R >= 0,
    y_W == round(y_W), y_R == round(y_R)
  )
  invisible(TRUE)
}
