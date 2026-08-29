#' Bayes factor under the hypergeometric urn model (deprecated)
#'
#' Deprecated. The paper began with two probability models and now has
#' one: each observation supports the working theory with probability
#' \eqn{\theta}, the share of the evidence that supports it, and the two
#' Bayes factors it reports differ only in what they do with the range of
#' shares the rival claims. The urn model, which described a body of
#' evidence of a stated size, is no longer in the paper. Use
#' [bf_worst_case()] for the Bayes factor that evaluates the rival at her
#' best single share, or [bf_uniform_weights()] for the one that averages
#' over her whole range.
#'
#' This function is not removed, because the first arXiv version of the
#' paper cites it and its replication code calls it. It returns exactly
#' what it always returned and warns once per session.
#'
#' Computes the Bayes factor for a working theory \eqn{H_1} against a
#' single rival \eqn{H_R}, given observed counts `y_W` of evidence
#' favorable to \eqn{H_1} and `y_R` of evidence favorable to \eqn{H_R},
#' under Formulation C of the urn construction. The Working Theory
#' Favorable (WTF) sub-model has urn composition \eqn{(y_W + 1,
#' \max(1, y_R))}; the Rival Theory Favorable (RTF) sub-model has urn
#' composition \eqn{(y_W, y_W + 1)}. Both constructions tilt in favor
#' of the rival, so the Bayes factor returned is a lower bound on the
#' evidence for \eqn{H_1}.
#'
#' This model fits research designs where the evidence base is bounded
#' and fixed --- a closed historical archive, a fixed roster of
#' documents. For open-ended evidence collection, see [bf_binomial()].
#'
#' Observation bias `omega` enters as the odds ratio in Fisher's
#' non-central hypergeometric distribution (via [BiasedUrn::dFNCHypergeo()]):
#' `omega = 1` is unbiased; `omega > 1` makes pro-\eqn{H_1} items
#' likelier to be drawn; `omega < 1` makes them less likely.
#'
#' For weighted analyses, sum the weights first and pass the sums:
#' `bf_urn(sum(w_W), sum(w_R))`.
#'
#' When `y_R > y_W + 1`, the RTF urn cannot supply a sample of size
#' \eqn{n = y_W + y_R}, the construction is undefined, and the function
#' returns `NA_real_`.
#'
#' @param y_W Non-negative integer. Count (or summed integer weight) of
#'   evidence favorable to the working theory.
#' @param y_R Non-negative integer. Count (or summed integer weight) of
#'   evidence favorable to the rival.
#' @param omega Positive numeric. Observation-bias odds ratio.
#'   Default `1` (unbiased).
#'
#' @return A length-1 numeric: the Bayes factor in favor of \eqn{H_1}.
#'   `NA_real_` if the RTF urn is too small for the sample; `Inf` if
#'   the RTF probability of the observed pattern is numerically zero.
#'
#' @examples
#' # The paper's running example: nine pro-working-theory observations,
#' # three pro-rival. The closed form is (10/13) / (120/50388) = 323.
#' bf_urn(9, 3)
#' bf_urn(9, 3, omega = 0.5)
#'
#' @seealso [bf_worst_case()] and [bf_uniform_weights()], the two Bayes
#'   factors the paper now reports; [sens_coding()] for sensitivity to
#'   coding error under either of them.
#' @export
bf_urn <- function(y_W, y_R, omega = 1) {
  .deprecate_once(
    "bf_urn",
    paste("bf_urn() is deprecated. The paper no longer uses the",
          "hypergeometric urn model: it now has one model and two Bayes",
          "factors computed from it. Use bf_worst_case() for the Bayes",
          "factor that evaluates the rival at her best single share, or",
          "bf_uniform_weights() for the one that averages over her whole",
          "range. bf_urn() is kept for the first arXiv version's",
          "replication code and still returns what it always returned.")
  )
  stopifnot(
    length(y_W) == 1L, length(y_R) == 1L,
    y_W >= 0, y_R >= 0, y_W + y_R > 0,
    omega > 0
  )
  n <- y_W + y_R
  # Formulation C urns: WTF adds one unobserved pro-H_1 item to a
  # universe that contains at least one pro-H_R item; RTF tilts toward
  # the rival by exactly one pro-rival item.
  m1w <- y_W + 1
  m2w <- max(1, y_R)
  m1r <- y_W
  m2r <- y_W + 1
  # When y_R > y_W + 1, the RTF urn of size 2 y_W + 1 cannot supply a
  # sample of size n = y_W + y_R: the construction is undefined.
  if (m1r + m2r < n) return(NA_real_)
  if (omega == 1) {
    # Central hypergeometric is dhyper; faster and exact.
    pr_w <- stats::dhyper(y_W, m1w, m2w, n)
    pr_r <- stats::dhyper(y_W, m1r, m2r, n)
  } else {
    # Fisher's non-central hypergeometric handles biased observation:
    # `odds = omega` is the odds ratio that pro-H_1 items enter the
    # sample relative to pro-H_R items.
    pr_w <- BiasedUrn::dFNCHypergeo(y_W, m1w, m2w, n, odds = omega)
    pr_r <- BiasedUrn::dFNCHypergeo(y_W, m1r, m2r, n, odds = omega)
  }
  if (pr_r == 0) return(Inf)
  pr_w / pr_r
}
