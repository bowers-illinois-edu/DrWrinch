#' Find the smallest omega > 1 at which `bf_fn(omega) = target`
#'
#' Internal helper. Bracket-doubles upward from `omega = 2` until
#' `bf_fn(omega) - target` changes sign, then uses [stats::uniroot()]
#' to locate the root. Assumes `bf_fn` is monotone decreasing in
#' `omega` (more bias toward H_1 lowers the Bayes factor). Returns `0`
#' if the baseline Bayes factor is already at or below `target`; `NA`
#' if no upper bracket is found within `max_doublings`.
#'
#' @param bf_fn Function of a single argument `omega` returning the
#'   Bayes factor.
#' @param target Positive numeric. Threshold the Bayes factor must
#'   cross.
#' @param max_doublings Integer. Cap on the bracket-doubling loop.
#'   Default `40` (omega up to ~2^40).
#'
#' @return Numeric scalar.
#' @noRd
.find_omega_tipping <- function(bf_fn, target, max_doublings = 40L) {
  f <- function(omega) bf_fn(omega) - target
  f1 <- f(1)
  if (is.na(f1)) return(NA_real_)
  # Baseline already at or below target: the conclusion fails at
  # omega = 1 and no positive bias is needed to overturn it.
  if (f1 <= 0) return(0)
  # Bracket upward by doubling until the BF falls below the target.
  # In pathological cases (BF asymptotes above target) we cap the
  # search and return NA rather than running forever.
  w_hi <- 2
  for (iter in seq_len(max_doublings)) {
    f_hi <- f(w_hi)
    if (!is.na(f_hi) && f_hi <= 0) break
    w_hi <- w_hi * 2
    if (iter == max_doublings) return(NA_real_)
  }
  tryCatch(
    stats::uniroot(f, interval = c(1, w_hi))$root,
    error = function(e) NA_real_
  )
}
