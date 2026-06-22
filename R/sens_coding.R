#' Sensitivity analysis for coding error
#'
#' Reports the coding-error tipping point: the smallest number of pro-
#' working-theory observations that would have to be re-coded as
#' pro-rival before the Bayes factor first drops below `threshold`.
#'
#' This is the third sensitivity question in the paper, alongside
#' observation bias ([sens_urn()] and [sens_binomial()]'s `omega_star`)
#' and the rival-tilted prior ([sens_binomial()]'s `M_star`). A peer
#' cannot re-read every document, but she can ask how many pro-\eqn{H_1}
#' observations would have to be re-coded for the conclusion to change.
#'
#' Re-coding `x` observations relabels `x` pro-\eqn{H_1} items as
#' pro-rival, moving the counts from `(y_W, y_R)` to
#' `(y_W - x, y_R + x)`. The total number of observations
#' \eqn{n = y_W + y_R} does not change; only the split does. The same
#' model's Bayes factor is then recomputed at the new counts. One
#' function serves both models because the mechanism is the relabeling;
#' `model` only selects which Bayes factor to recompute --- [bf_binomial()]
#' for open-ended evidence, [bf_urn()] for a bounded archive.
#'
#' Re-coding moves evidence toward equipoise, so the Bayes factor falls
#' as `x` grows. For the urn model, re-coding eventually shrinks the
#' rival-favorable urn below the sample size (the swap regime, where
#' [bf_urn()] is undefined and returns `NA`); these re-codings are
#' skipped rather than counted as a crossing. Because the Bayes factor
#' reaches equipoise before that point for any `threshold > 1`, the
#' tipping point is found within the defined range in ordinary use.
#'
#' If `bf_<model>(y_W, y_R) < threshold` at baseline, `x_star` is `0`
#' (the conclusion fails before any re-coding).
#'
#' @param y_W Non-negative integer. Observed count favorable to the
#'   working theory.
#' @param y_R Non-negative integer. Observed count favorable to the
#'   rival.
#' @param model Which Bayes factor to recompute after re-coding:
#'   `"binomial"` (open-ended evidence) or `"urn"` (bounded archive).
#' @param threshold Positive numeric. Decision threshold the Bayes
#'   factor must remain at or above. Default `20`.
#' @param theta_cut Numeric in (0, 1). Cutpoint for the binomial model;
#'   ignored by the urn model. Default `0.5`.
#'
#' @return A list with elements:
#'   \describe{
#'     \item{`bf`}{Bayes factor at the observed coding (no re-coding).}
#'     \item{`x_star`}{Smallest integer `x >= 0` re-codings at which the
#'       Bayes factor drops below `threshold`. `0` if `bf < threshold`
#'       at baseline; `NA_integer_` if no re-coding in `[0, y_W]` with a
#'       defined Bayes factor drops it below `threshold`.}
#'   }
#'
#' @examples
#' # The paper's running example: one re-coding overturns the binomial
#' # conclusion, two overturn the hypergeometric.
#' sens_coding(9, 3, model = "binomial")$x_star
#' sens_coding(9, 3, model = "urn")$x_star
#'
#' @seealso [sens_binomial()] and [sens_urn()] for observation-bias and
#'   prior sensitivity; [bf_binomial()] and [bf_urn()] for the Bayes
#'   factors themselves.
#' @export
sens_coding <- function(y_W, y_R,
                        model = c("binomial", "urn"),
                        threshold = 20,
                        theta_cut = 0.5) {
  model <- match.arg(model)
  stopifnot(
    length(y_W) == 1L, length(y_R) == 1L,
    y_W >= 0, y_R >= 0, y_W + y_R > 0,
    threshold > 0,
    theta_cut > 0, theta_cut < 1
  )

  # bf_at() recomputes the chosen model's Bayes factor after re-coding x
  # pro-H_1 observations as pro-rival. theta_cut only affects the
  # binomial model; bf_urn() has no cutpoint.
  bf_at <- if (model == "binomial") {
    function(x) bf_binomial(y_W - x, y_R + x, theta_cut = theta_cut)
  } else {
    function(x) bf_urn(y_W - x, y_R + x)
  }

  bf_base <- bf_at(0)

  # Scan re-codings from none (x = 0) up to relabeling every pro-H_1
  # observation (x = y_W), stopping at the first x whose Bayes factor is
  # both defined and below threshold. The first crossing is the smallest
  # x because re-coding moves evidence monotonically toward the rival.
  # Undefined values (the urn's swap regime) are skipped, not treated as
  # a crossing, so an undefined re-coding never masquerades as a tipping
  # point.
  x_star <- NA_integer_
  for (x in 0:y_W) {
    bf_x <- bf_at(x)
    if (!is.na(bf_x) && bf_x < threshold) {
      x_star <- as.integer(x)
      break
    }
  }

  list(bf = bf_base, x_star = x_star)
}
