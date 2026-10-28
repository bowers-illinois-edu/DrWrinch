#' Sensitivity to a biased search
#'
#' The paper's rule sets the rival aside, at least provisionally, when the
#' uniform-weights Bayes factor is 20 or more and the worst-case Bayes
#' factor is above 1. A reader who doubts the result may ask whether the
#' search for evidence favored the working theory. Write \eqn{\omega} for
#' the bias factor: a search with bias \eqn{\omega} is \eqn{\omega} times
#' as likely to find a pro-working-theory observation as a pro-rival one.
#' Granting more bias lowers both Bayes factors, because a search that
#' finds pro-working-theory observations more easily would produce mostly
#' pro-working-theory counts even from evidence that mostly favored the
#' rival.
#'
#' This function returns the bias at which each condition of the rule
#' fails and the smaller of the two, which the paper writes
#' \eqn{\omega^\star}: the smallest bias at which a researcher following
#' the rule would no longer set the rival aside. At nine observations for
#' the working theory and three for the rival, the uniform-weights value
#' falls to 20 at a bias of 1.0098 and the worst-case value falls to 1 at
#' 1.559, so \eqn{\omega^\star = 1.01}: a search about one percent more
#' likely to find pro-working-theory observations would change the
#' decision. With the smoking-gun memo counted as ten observations, the
#' counts are 18 and 3 and \eqn{\omega^\star = 2.33}.
#'
#' Whether a search could have been that lopsided is a question about how
#' the evidence was collected, which readers who know the case can answer
#' and the function cannot.
#'
#' @section Special values:
#' A tipping point is `0` when its condition already fails at an unbiased
#' search, because then there is no decision for bias to change. It is
#' `Inf` when no bias makes the condition fail: with no observations for
#' the rival, both Bayes factors fall toward 1 as the bias grows and never
#' reach it, so a threshold of 1 or less is never crossed. It is `NA` when
#' the search, which tries biases up to about \eqn{10^{12}}, finds no
#' crossing; `omega_star` then reports the other tipping point.
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
#'     \item{`bf_uniform`, `bf_worst`}{The two Bayes factors at an unbiased
#'       search.}
#'     \item{`omega_uniform`}{The bias at which the uniform-weights Bayes
#'       factor falls to `threshold_uniform`.}
#'     \item{`omega_worst`}{The bias at which the worst-case Bayes factor
#'       falls to `threshold_worst`.}
#'     \item{`omega_star`}{The smaller of the two.}
#'   }
#'
#' @examples
#' # The paper's running example.
#' sens_bias(9, 3)
#'
#' # The memo counted as ten observations.
#' sens_bias(18, 3)$omega_star
#'
#' @seealso [bf_uniform_weights()] and [bf_worst_case()], whose `omega`
#'   argument this function varies; [sens_coding()] for sensitivity to
#'   coding.
#' @export
sens_bias <- function(y_W, y_R, threshold_uniform = 20, threshold_worst = 1) {
  .check_counts(y_W, y_R)
  stopifnot(y_W + y_R > 0)
  .check_threshold(threshold_uniform)
  .check_threshold(threshold_worst)

  bf_u <- bf_uniform_weights(y_W, y_R)
  bf_w <- bf_worst_case(y_W, y_R)

  # The two conditions treat a value at the threshold differently, as the
  # rule does: the uniform-weights value meets its condition at 20, and
  # the worst-case value fails its condition at 1.
  omega_u <- if (bf_u < threshold_uniform) {
    0
  } else if (y_R == 0 && threshold_uniform <= 1) {
    Inf
  } else {
    .find_omega_tipping(function(om) bf_uniform_weights(y_W, y_R, omega = om),
                        threshold_uniform)
  }
  omega_w <- if (bf_w <= threshold_worst) {
    0
  } else if (y_R == 0 && threshold_worst <= 1) {
    Inf
  } else {
    .find_omega_tipping(function(om) bf_worst_case(y_W, y_R, omega = om),
                        threshold_worst)
  }

  list(bf_uniform = bf_u, bf_worst = bf_w,
       omega_uniform = omega_u, omega_worst = omega_w,
       omega_star = .smaller(omega_u, omega_w))
}
