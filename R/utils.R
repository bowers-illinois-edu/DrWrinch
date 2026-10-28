# Internal helpers shared by the Bayes factor and sensitivity functions.

# Counts must be whole numbers, not merely non-negative. The paper
# restricts weights on observations to whole numbers so that weighted
# counts are whole, and bf_worst_case() sums binomial coefficients over
# 0:y_W, where R would truncate a fractional y_W without complaint and
# return the value for a coding no researcher could have made.
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

.check_omega <- function(omega) {
  stopifnot(length(omega) == 1L, is.numeric(omega), !is.na(omega),
            omega > 0, is.finite(omega))
  invisible(TRUE)
}

.check_threshold <- function(threshold) {
  stopifnot(length(threshold) == 1L, is.numeric(threshold),
            !is.na(threshold), threshold > 0)
  invisible(TRUE)
}

# A search omega times as likely to find a pro-working-theory observation
# as a pro-rival one turns a share theta of the evidence into this share
# among the observations found. It solves q / (1 - q) = omega * theta /
# (1 - theta), the odds tilted by omega (supplement, sec-sens-bias).
.tilt <- function(theta, omega) omega * theta / (omega * theta + 1 - theta)

# stats::integrate() stops when its error estimate falls below
# max(abs.tol, rel.tol * |value|), and its default abs.tol is about
# 1e-4. The probabilities integrated here are often far smaller than
# that --- the rival's average at eighteen of twenty-one is about 1e-5
# --- so the default would accept an answer with no correct digits.
# Setting abs.tol to zero makes the relative tolerance govern, and the
# tight relative tolerance is what lets the tipping-point search below
# agree with the paper's to six digits.
.integrate <- function(f, lower, upper) {
  stats::integrate(f, lower, upper, rel.tol = 1e-10, abs.tol = 0,
                   subdivisions = 1000L)$value
}

# The smallest omega > 1 at which bf_fn(omega) falls to target, for a
# bf_fn that decreases in omega (granting more bias toward the working
# theory lowers both Bayes factors). The caller has already established
# that the condition holds at omega = 1, so bf_fn(1) >= target here.
#
# The search doubles an upper bracket from 2 until the value falls to
# the target and then hands the bracket to uniroot(). The tolerance is
# the one the paper's tests/bf_weighted.R uses. If no bracket is found
# within max_doublings (omega up to about 10^12), the function returns
# NA rather than claim that no bias would ever change the decision.
.find_omega_tipping <- function(bf_fn, target, max_doublings = 40L) {
  # At an extreme bias the integrand can be so sharply peaked that
  # integrate() gives up. A failed evaluation is treated as "not known to
  # be below the target", so the search moves on to a larger bracket or
  # returns NA, rather than stopping the caller with an error.
  f <- function(omega) {
    tryCatch(bf_fn(omega) - target, error = function(e) NA_real_)
  }
  if (isTRUE(f(1) == 0)) return(1)
  hi <- 2
  for (i in seq_len(max_doublings)) {
    f_hi <- f(hi)
    if (!is.na(f_hi) && f_hi <= 0) {
      return(tryCatch(
        stats::uniroot(f, interval = c(1, hi), tol = 1e-10)$root,
        error = function(e) NA_real_
      ))
    }
    hi <- hi * 2
  }
  NA_real_
}

# The smaller of two tipping points, ignoring one that the search could
# not find. A tipping point that was not found lies beyond the search
# range, so the one that was found is the smaller.
.smaller <- function(a, b) {
  if (is.na(a) && is.na(b)) return(a)
  min(a, b, na.rm = TRUE)
}
