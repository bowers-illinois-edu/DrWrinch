#' Sensitivity analysis for coding error
#'
#' A peer cannot re-read every document the way the original researcher
#' did, so the coding of any one piece of evidence can be disputed but
#' not settled at a distance. What can be computed is how much re-coding
#' it would take to change what the researcher reports. Re-coding `x`
#' observations relabels `x` items that supported the working theory as
#' supporting the rival, moving the counts from `(y_W, y_R)` to
#' `(y_W - x, y_R + x)`. The number of observations does not change; only
#' the split does.
#'
#' The two Bayes factors in this package answer that question
#' differently, so this function returns different things for them.
#'
#' @section What re-coding does to the uniform-weights Bayes factor:
#' [bf_uniform_weights()] averages over the rival's whole range of
#' shares, and at the running example it sits at 20.67, just above a
#' threshold of 20. So the question a peer asks has an answer in whole
#' re-codings: how many would it take to bring the value below the
#' threshold? The function returns that number as `x_star`. At nine
#' observations against three it is one, and the conclusion tolerates so
#' little re-coding precisely because the value started so close to the
#' threshold. If the value is already below the threshold at the observed
#' coding, `x_star` is `0`.
#'
#' @section What re-coding does to the worst-case Bayes factor:
#' [bf_worst_case()] hands the rival her best single share, so at the
#' same counts it reports 2.73, which was never above 20. Re-coding
#' cannot overturn a conclusion the researcher did not draw. What it
#' moves is the separation she reports beside the value: how far apart
#' the two theories' claims would have to be before her counts reach her
#' threshold ([separation_g()]). Each re-coding narrows the margin
#' between the counts by two, so the required separation grows quickly.
#' The function returns one row per re-coding rather than a tipping
#' point. At nine observations against three the separation runs from
#' 0.123 at the agreed coding to 0.179 after one re-coding and 0.318
#' after two, and after three the counts are even and no separation
#' reaches a threshold above one.
#'
#' Rows run from the observed coding up to the first re-coding at which
#' the counts stop favoring the working theory, because past that point
#' the coding error a peer would be proposing has changed direction.
#'
#' @section The superseded urn model:
#' `model = "urn"` recomputes [bf_urn()] and returns a tipping point in
#' the same shape as the uniform-weights branch. The paper no longer uses
#' that model; the option is kept because the first arXiv version cites
#' it. Re-coding eventually shrinks the rival-favorable urn below the
#' sample size, where [bf_urn()] is undefined and returns `NA`; those
#' re-codings are skipped rather than counted as a crossing, so an
#' undefined value never masquerades as a tipping point.
#'
#' @param y_W Non-negative integer. Observed count favorable to the
#'   working theory.
#' @param y_R Non-negative integer. Observed count favorable to the
#'   rival.
#' @param model Which Bayes factor to recompute after re-coding.
#'   `"uniform_weights"` (the default) averages over the rival's whole
#'   range; `"worst_case"` evaluates her at one half; `"binomial"` is the
#'   earlier name for `"uniform_weights"` and returns the same thing;
#'   `"urn"` is the superseded bounded-archive model.
#' @param threshold Positive numeric. The value at which the researcher
#'   would set the rival aside. Default `20`. Under `"worst_case"` this
#'   is the threshold the reported separations answer at.
#' @param theta_cut Numeric in (0, 1). Cutpoint for the uniform-weights
#'   model; ignored by `"worst_case"` and `"urn"`, whose cut is fixed at
#'   one half by construction. Default `0.5`.
#'
#' @return For `"uniform_weights"`, `"binomial"`, and `"urn"`, a list
#'   with elements:
#'   \describe{
#'     \item{`bf`}{Bayes factor at the observed coding.}
#'     \item{`x_star`}{Smallest integer `x >= 0` re-codings at which the
#'       Bayes factor drops below `threshold`. `0` if it is already below
#'       `threshold` at the observed coding; `NA_integer_` if no
#'       re-coding in `[0, y_W]` with a defined Bayes factor drops it
#'       below `threshold`.}
#'   }
#'   For `"worst_case"`, a list with elements:
#'   \describe{
#'     \item{`bf`}{Worst-case Bayes factor at the observed coding.}
#'     \item{`recoding`}{A data frame with one row per re-coding and
#'       columns `x` (re-codings), `y_W` and `y_R` (the counts after
#'       them), `bf` (the worst-case Bayes factor there), and `g_star`
#'       (the separation at which the two-share version reaches
#'       `threshold`, `NA` once the counts no longer favor the working
#'       theory).}
#'   }
#'
#' @examples
#' # The paper's running example. One re-coding takes the uniform-weights
#' # Bayes factor below 20.
#' sens_coding(9, 3)$x_star
#'
#' # The same counts under the worst-case Bayes factor, which was never
#' # above 20: what re-coding moves is the separation she reports.
#' sens_coding(9, 3, model = "worst_case")$recoding
#'
#' @seealso [sens_binomial()] for observation-bias and prior
#'   sensitivity; [bf_uniform_weights()], [bf_worst_case()], and
#'   [separation_g()] for the quantities recomputed here.
#' @export
sens_coding <- function(y_W, y_R,
                        model = c("uniform_weights", "worst_case",
                                  "binomial", "urn"),
                        threshold = 20,
                        theta_cut = 0.5) {
  model <- match.arg(model)
  # "binomial" named this Bayes factor before the paper had one model
  # with two of them. Mapping it here keeps calls in the first arXiv
  # version's replication code returning what they returned.
  if (model == "binomial") model <- "uniform_weights"

  stopifnot(
    length(y_W) == 1L, length(y_R) == 1L,
    y_W >= 0, y_R >= 0, y_W + y_R > 0,
    threshold > 0,
    theta_cut > 0, theta_cut < 1
  )

  if (model == "worst_case") {
    tab <- .recoding_table(y_W, y_R, threshold)
    return(list(bf = tab$bf[1], recoding = tab))
  }

  # bf_at() recomputes the chosen Bayes factor after re-coding x
  # observations. theta_cut only reaches the uniform-weights branch;
  # bf_urn() has no cutpoint.
  bf_at <- if (model == "uniform_weights") {
    function(x) bf_binomial(y_W - x, y_R + x, theta_cut = theta_cut)
  } else {
    function(x) bf_urn(y_W - x, y_R + x)
  }

  bf_base <- bf_at(0)

  # Scan re-codings from none up to relabeling every observation that
  # supported the working theory, stopping at the first x whose Bayes
  # factor is both defined and below threshold. The first crossing is
  # the smallest x because re-coding moves the evidence monotonically
  # toward the rival.
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

# One row per re-coding for the worst-case branch. Rows stop at the
# first re-coding whose counts no longer favor the working theory: past
# that point separation_g() has nothing to report, and a peer proposing
# further re-codings would be arguing that the rival's evidence
# outweighs the working theory's rather than that the coding was wrong.
.recoding_table <- function(y_W, y_R, threshold) {
  x_max <- min(y_W, max(0L, ceiling((y_W - y_R) / 2)))
  x <- 0:x_max
  y_W_x <- y_W - x
  y_R_x <- y_R + x
  g_star <- vapply(
    seq_along(x),
    function(i) {
      if (y_W_x[i] > y_R_x[i]) {
        separation_g(y_W_x[i], y_R_x[i], threshold = threshold)
      } else {
        NA_real_
      }
    },
    numeric(1)
  )
  data.frame(
    x = x,
    y_W = y_W_x,
    y_R = y_R_x,
    bf = mapply(bf_worst_case, y_W_x, y_R_x),
    g_star = g_star
  )
}
