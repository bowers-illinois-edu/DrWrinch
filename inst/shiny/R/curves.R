# Data for the app's plots. Kept apart from helpers.R so the numbers
# behind each picture can be tested without loading plotly, and so
# neither file grows past the package's file-length rule.
#
# Every function here is pure: counts in, data frame out, no Shiny.


# bf_decomposition() computes the three probabilities behind the two
# Bayes factors, at every count of N observations the researcher might
# have reported. This is the picture the paper draws (its fig-bounded)
# and the Result tab copies: three bars per count.
#
#   numerator: the probability of the count averaged over the shares
#     above one half, under uniform weights. Both Bayes factors share
#     it, which is why they can be read off one picture.
#   den_avg:   the same average taken over the shares at or below one
#     half. Dividing the numerator by it gives bf_uniform_weights().
#   den_half:  the probability of the count at a share of exactly one
#     half, the rival's most favorable share whenever the count favors
#     the working theory. Dividing by it gives bf_worst_case().
#
# Averaging over a half-width interval means dividing the integral by
# one half, which is where the factor of 2 comes from.
bf_decomposition <- function(y_W, y_R) {
  n <- y_W + y_R
  counts <- 0:n
  averaged <- function(lo, hi) {
    vapply(counts, function(k) {
      2 * stats::integrate(function(t) stats::dbinom(k, n, t), lo, hi)$value
    }, numeric(1))
  }
  data.frame(
    k = counts,
    numerator = averaged(0.5, 1),
    den_avg = averaged(0, 0.5),
    den_half = stats::dbinom(counts, n, 0.5),
    stringsAsFactors = FALSE
  )
}


# bf_omega_curve() samples both Bayes factors along a log-spaced grid
# of search-bias values. omega is the bias factor: how many times as
# likely the search was to find a pro-working-theory observation as a
# pro-rival one.
#
# Defaults: 80 points between 0.25 and 8 cover a search four times as
# likely to find pro-rival evidence through one eight times as likely to
# find pro-working-theory evidence, wider than any process-tracing
# reader is likely to argue for. Log spacing gives omega < 1 and
# omega > 1 equal room on the axis, which matters because the tipping
# point usually sits close to one.
bf_omega_curve <- function(y_W, y_R, n_grid = 80L, omega_range = c(0.25, 8)) {
  omegas <- exp(seq(log(omega_range[1]), log(omega_range[2]),
                    length.out = n_grid))
  # Both functions integrate once omega leaves 1, so a quadrature
  # failure at an extreme omega yields NA rather than blanking the plot.
  at <- function(f) {
    vapply(omegas, function(om) {
      tryCatch(f(y_W, y_R, omega = om), error = function(e) NA_real_)
    }, numeric(1))
  }
  data.frame(
    omega = omegas,
    bf_uniform = at(DrWrinch::bf_uniform_weights),
    bf_worst = at(DrWrinch::bf_worst_case),
    stringsAsFactors = FALSE
  )
}
