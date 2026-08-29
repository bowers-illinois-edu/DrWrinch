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
#     half, the rival's best case. Dividing by it gives bf_worst_case().
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


# bf_omega_curve() samples the uniform-weights Bayes factor along a
# log-spaced grid of search-bias values. omega is the odds by which the
# search favored surfacing evidence for the working theory.
#
# Defaults: 80 points between 0.25 and 8 cover four-fold bias toward the
# rival and eight-fold bias toward the working theory, wider than any
# process-tracing reader is likely to argue for. Log spacing gives
# omega < 1 and omega > 1 equal visual room, which matters because the
# tipping point usually sits close to one.
bf_omega_curve <- function(y_W, y_R,
                           threshold = 20,
                           theta_cut = 0.5,
                           n_grid = 80L,
                           omega_range = c(0.25, 8)) {
  omegas <- exp(seq(
    log(omega_range[1]),
    log(omega_range[2]),
    length.out = n_grid
  ))
  # bf_binomial() integrates numerically once omega leaves 1, so a
  # quadrature failure at an extreme omega yields NA rather than
  # killing the whole curve.
  bfs <- vapply(omegas, function(om) {
    tryCatch(
      DrWrinch::bf_binomial(y_W, y_R, omega = om, theta_cut = theta_cut),
      error = function(e) NA_real_
    )
  }, numeric(1))
  data.frame(
    omega = omegas,
    bf = bfs,
    threshold = threshold,
    stringsAsFactors = FALSE
  )
}


# post_odds_M_curve() sweeps a Beta(1, M + 1) prior on the whole
# interval from zero to one, which reads as M background cases all
# favoring the rival.
#
# What falls as M rises is the posterior odds, not the Bayes factor.
# Such a prior sets how much weight each theory gets as well as how
# weight is spread inside each theory's range; the Bayes factor
# renormalizes the first away and the posterior odds keep it. The Bayes
# factor actually rises with M. The column is named for what it holds so
# that nothing downstream can label it wrongly.
post_odds_M_curve <- function(y_W, y_R,
                              theta_cut = 0.5,
                              M_max = 50L,
                              threshold = 20) {
  Ms <- 0:M_max
  odds <- vapply(Ms, function(M) {
    DrWrinch::bf_binomial(
      y_W, y_R,
      prior_a = 1, prior_b = M + 1L,
      theta_cut = theta_cut
    )
  }, numeric(1))
  data.frame(
    M = Ms,
    post_odds = odds,
    threshold = threshold,
    stringsAsFactors = FALSE
  )
}
