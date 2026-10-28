#' Both Bayes factors for documents read from an archive of known size
#'
#' The binomial model behind [bf_uniform_weights()] and [bf_worst_case()]
#' treats the observations as independent draws. A researcher reading a
#' finite archive does not read the same document twice, so each document
#' read changes the share of what is left. These two functions compute the
#' supplement's version of both Bayes factors for that case (section
#' "Finite evidence without replacement").
#'
#' The archive holds `M` documents, \eqn{K} of which support the working
#' theory. The working theory claims \eqn{K > M/2} and the rival claims
#' \eqn{K \le M/2}, so when `M` is even the archive split exactly in half
#' belongs to the rival, as a share of one half does in the binomial
#' model. The probability of reading `y_W` supporting documents among
#' \eqn{N = y_W + y_R} is the hypergeometric probability
#' \deqn{p(E \mid M, K) = \binom{K}{y_W}\binom{M-K}{y_R} \Big/ \binom{M}{N}.}
#' The numerator of both Bayes factors averages it over the working
#' theory's values of \eqn{K} with equal weights.
#' `bf_uniform_weights_finite()` divides by the same average over the
#' rival's values. `bf_worst_case_finite()` divides by the probability at
#' the largest \eqn{K} at or below \eqn{M/2}.
#'
#' At nine of twelve the two values are 162.88 and 16.84 from an archive of
#' 20 and 25.22 and 3.19 from an archive of 100, and they approach the
#' binomial values, 20.67 and 2.73, as the archive grows. In every case the
#' supplement computed, whenever the binomial values meet the paper's rule
#' (uniform weights 20 or more, worst case above 1), the finite values meet
#' it too. So a researcher need not state the size of the archive, but may
#' vary `M` to ask how large it would have to be for the conclusion to
#' change.
#'
#' Counts that one side cannot produce give the limiting values: `Inf`
#' when the rival's archives cannot produce them (nine supporting
#' documents from an archive of twelve) and `0` when only the rival's can.
#' `bf_worst_case_finite()` returns `NaN` when neither the working
#' theory's archives nor the half-split archive can produce the counts,
#' which happens only when the counts favor the rival.
#'
#' @param y_W Non-negative whole number. Documents read that support the
#'   working theory.
#' @param y_R Non-negative whole number. Documents read that support the
#'   rival.
#' @param M Whole number at least `y_W + y_R`. Documents in the archive.
#'
#' @return A length-1 numeric: the Bayes factor in favor of the working
#'   theory.
#'
#' @examples
#' # Nine of twelve documents read from an archive of 20.
#' bf_uniform_weights_finite(9, 3, M = 20)
#' bf_worst_case_finite(9, 3, M = 20)
#'
#' # From a much larger archive the values are close to the binomial ones.
#' bf_uniform_weights_finite(9, 3, M = 1e5)
#' bf_uniform_weights(9, 3)
#'
#' @seealso [bf_uniform_weights()] and [bf_worst_case()] for the binomial
#'   versions, which need no archive size.
#' @name bf_finite
NULL

#' @rdname bf_finite
#' @export
bf_uniform_weights_finite <- function(y_W, y_R, M) {
  K <- .archive_compositions(y_W, y_R, M)
  n <- y_W + y_R
  mean(stats::dhyper(y_W, K$working, M - K$working, n)) /
    mean(stats::dhyper(y_W, K$rival, M - K$rival, n))
}

#' @rdname bf_finite
#' @export
bf_worst_case_finite <- function(y_W, y_R, M) {
  K <- .archive_compositions(y_W, y_R, M)
  n <- y_W + y_R
  K_half <- max(K$rival)
  mean(stats::dhyper(y_W, K$working, M - K$working, n)) /
    stats::dhyper(y_W, K_half, M - K_half, n)
}

# The numbers of supporting documents each theory allows in an archive
# of M: more than half for the working theory, at most half for the
# rival. Checks the inputs once for both functions. seq.int() rather
# than (half + 1):M, because M = 1 would otherwise run the sequence
# backwards.
.archive_compositions <- function(y_W, y_R, M) {
  .check_counts(y_W, y_R)
  stopifnot(length(M) == 1L, is.numeric(M), !is.na(M), is.finite(M),
            M == round(M), M >= 1, M >= y_W + y_R)
  half <- floor(M / 2)
  list(working = seq.int(half + 1, M), rival = seq.int(0, half))
}
