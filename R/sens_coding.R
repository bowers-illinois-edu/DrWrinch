#' Sensitivity to coding
#'
#' A peer cannot re-read every document the way the researcher did, so the
#' coding of any one observation can be disputed but not settled at a
#' distance. What a peer can compute is how many re-codings would change
#' the decision. Re-coding `x` observations relabels `x` observations that
#' supported the working theory as supporting the rival, moving the counts
#' from `(y_W, y_R)` to `(y_W - x, y_R + x)`. The number of observations
#' does not change; only the split does.
#'
#' The paper's rule sets the rival aside, at least provisionally, when the
#' uniform-weights Bayes factor is 20 or more and the worst-case Bayes
#' factor is above 1. This function returns the smallest number of
#' re-codings at which each condition fails and the smaller of the two,
#' which is the number the supplement reports. At nine observations for
#' the working theory and three for the rival, one re-coding takes the
#' uniform-weights value from 20.67 to 6.49, below 20, while the worst-case
#' value falls to 1 or below only after two (1.10 at eight of twelve, 0.56
#' at seven). So one re-coding changes the decision. The conclusion
#' tolerates so little re-coding because the uniform-weights value starts
#' so close to 20.
#'
#' Re-coding lowers both Bayes factors, so every re-coding past the first
#' one at which a condition fails also fails it. A tipping point of `0`
#' means the condition already fails at the observed coding.
#'
#' @param y_W Non-negative whole number. Count, or summed weight, of
#'   observations supporting the working theory.
#' @param y_R Non-negative whole number. Count, or summed weight, of
#'   observations supporting the rival.
#' @param threshold_uniform Positive number. The uniform-weights Bayes
#'   factor must be at least this large for the rule to set the rival
#'   aside. Default `20`.
#' @param threshold_worst Positive number. The worst-case Bayes factor must
#'   be above this value for the rule to set the rival aside. Default `1`.
#'
#' @return A list with elements
#'   \describe{
#'     \item{`bf_uniform`, `bf_worst`}{The two Bayes factors at the
#'       observed coding.}
#'     \item{`x_uniform`}{The smallest number of re-codings at which the
#'       uniform-weights value falls below `threshold_uniform`.}
#'     \item{`x_worst`}{The smallest number of re-codings at which the
#'       worst-case value falls to `threshold_worst` or below.}
#'     \item{`x_star`}{The smaller of the two.}
#'   }
#'   A tipping point is `NA` when no re-coding of the `y_W` observations
#'   makes its condition fail.
#'
#' @examples
#' # The paper's running example.
#' sens_coding(9, 3)
#'
#' # Winward's fourteen of seventeen: two re-codings change the decision.
#' sens_coding(14, 3)$x_star
#'
#' @seealso [sens_bias()] for sensitivity to a biased search;
#'   [bf_uniform_weights()] and [bf_worst_case()] for the values recomputed
#'   here.
#' @export
sens_coding <- function(y_W, y_R, threshold_uniform = 20, threshold_worst = 1) {
  .check_counts(y_W, y_R)
  stopifnot(y_W + y_R > 0)
  .check_threshold(threshold_uniform)
  .check_threshold(threshold_worst)

  x <- 0:y_W
  uw <- vapply(x, function(i) bf_uniform_weights(y_W - i, y_R + i), numeric(1))
  wc <- vapply(x, function(i) bf_worst_case(y_W - i, y_R + i), numeric(1))

  # The uniform-weights condition is met at the threshold and the
  # worst-case condition is not, as in the paper's rule.
  x_uniform <- x[which(uw < threshold_uniform)[1]]
  x_worst <- x[which(wc <= threshold_worst)[1]]

  list(bf_uniform = uw[1], bf_worst = wc[1],
       x_uniform = x_uniform, x_worst = x_worst,
       x_star = .smaller(x_uniform, x_worst))
}
