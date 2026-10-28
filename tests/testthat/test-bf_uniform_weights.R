# Substantive tests for bf_uniform_weights().
#
# One model underlies both Bayes factors in this package: each
# observation supports the working theory with probability theta, the
# share of the evidence that supports it; the working theory claims
# theta > 1/2 and the rival claims theta <= 1/2. Both Bayes factors
# share a numerator, the binomial probability of the counts averaged
# over the shares above one half under uniform weights.
# bf_uniform_weights() also averages over the rival's whole range under
# uniform weights; bf_worst_case() instead evaluates the rival at the
# single share, one half, that fits the counts best.
#
# Sources: Paper/evalues.qmd (sec-two-bfs, sec-decide and its
# avg-error footnote, sec-sensitivity) and Paper/appendix.qmd
# (thm-closed-form, sec-sens-bias).

test_that("the running example gives 20.67", {
  # Nine observations support the working theory and three the rival.
  # Under uniform weights the ratio of the two averages equals the
  # posterior mass above one half over the mass at or below it under a
  # Beta(y_W + 1, y_R + 1) posterior, because the equal weights on the
  # two equally wide halves cancel.
  p_below <- stats::pbeta(0.5, 9 + 1, 3 + 1)
  expect_equal(bf_uniform_weights(9, 3), (1 - p_below) / p_below,
               tolerance = 1e-12)
  expect_equal(round(bf_uniform_weights(9, 3), 2), 20.67)
})

test_that("the value equals the ratio of the two averaged probabilities", {
  # The definition the paper prints: the binomial probability of the
  # counts averaged over (1/2, 1] divided by the same probability
  # averaged over [0, 1/2]. The two numbers the main paper quotes at
  # nine of twelve are the two averages themselves.
  for (n in c(1, 5, 12, 21)) {
    for (k in 0:n) {
      num <- 2 * stats::integrate(function(t) stats::dbinom(k, n, t),
                                  0.5, 1)$value
      den <- 2 * stats::integrate(function(t) stats::dbinom(k, n, t),
                                  0, 0.5)$value
      expect_equal(bf_uniform_weights(k, n - k), num / den, tolerance = 1e-8,
                   info = sprintf("y_W = %d, N = %d", k, n))
    }
  }
  num_9 <- 2 * stats::integrate(function(t) stats::dbinom(9, 12, t),
                                0.5, 1)$value
  den_9 <- 2 * stats::integrate(function(t) stats::dbinom(9, 12, t),
                                0, 0.5)$value
  expect_equal(round(num_9, 5), 0.14675)
  expect_equal(round(den_9, 5), 0.00710)
})

test_that("the closed form of the supplement holds at every count", {
  # The supplement's thm-closed-form lets a reader compute the value by
  # hand from whole numbers: with S the sum of choose(N + 1, j) for j
  # from 0 to k, the uniform-weights Bayes factor is S / (2^(N+1) - S).
  for (n in c(1, 4, 12, 17)) {
    for (k in 0:n) {
      S <- sum(choose(n + 1, 0:k))
      expect_equal(bf_uniform_weights(k, n - k), S / (2^(n + 1) - S),
                   tolerance = 1e-10, info = sprintf("y_W = %d, N = %d", k, n))
    }
  }
})

test_that("equal counts give exactly one", {
  # With as many observations on each side, the probability of the
  # counts at a share theta equals its probability at 1 - theta, so the
  # two averages are equal and the counts favor neither theory.
  for (n in c(1, 3, 6, 20)) {
    expect_equal(bf_uniform_weights(n, n), 1, tolerance = 1e-12)
  }
})

test_that("weighting the memo at ten gives 2,337", {
  # Weights on observations act as replication: the memo weighted at ten
  # enters as ten observations, so the weighted counts are 8 + 10 = 18
  # and 3.
  expect_equal(round(bf_uniform_weights(18, 3)), 2337)
})

test_that("the value averages exactly one when the rival's uniform weights hold", {
  # The avg-error footnote of the main paper. If every share from zero
  # to one half is equally likely, the probability of a count is the
  # denominator of the Bayes factor at that count, so in the average of
  # the Bayes factor over counts each weight cancels its denominator and
  # what remains is the sum of the numerators, which is one. A
  # nonnegative quantity that averages one reaches 20 at most one time
  # in twenty.
  p_rival <- vapply(0:12, function(k) 2 * stats::integrate(
    function(t) stats::dbinom(k, 12, t), 0, 0.5)$value, numeric(1))
  bf <- vapply(0:12, function(k) bf_uniform_weights(k, 12 - k), numeric(1))
  expect_equal(sum(p_rival * bf), 1, tolerance = 1e-8)
  # With twelve observations the value is 20 or more exactly at nine or
  # more, and under those weights that happens with probability 0.009.
  expect_equal(bf >= 20, 0:12 >= 9)
  expect_equal(round(sum(p_rival[10:13]), 3), 0.009)
  # At a share of exactly one half the same rule fires with probability
  # 299 / 4096 = 0.073, so the limit holds on average over the shares,
  # not at every share.
  expect_equal(round(sum(stats::dbinom(9:12, 12, 0.5)), 3), 0.073)
})

test_that("a biased search tilts the share and lowers the value", {
  # A search omega times as likely to find a pro-working-theory
  # observation turns a share theta into q = omega theta / (omega theta
  # + 1 - theta) among the observations found. The supplement's formula
  # replaces theta by q inside the binomial probability and keeps the
  # uniform weights on theta.
  tilt <- function(t, om) om * t / (om * t + 1 - t)
  for (om in c(0.5, 1.5, 2, 5)) {
    num <- stats::integrate(function(t) stats::dbinom(9, 12, tilt(t, om)),
                            0.5, 1)$value
    den <- stats::integrate(function(t) stats::dbinom(9, 12, tilt(t, om)),
                            0, 0.5)$value
    expect_equal(bf_uniform_weights(9, 3, omega = om), num / den,
                 tolerance = 1e-8, info = sprintf("omega = %g", om))
  }
  # Conceding that the search favored the working theory concedes that
  # part of the counts' dominance came from how the researcher looked.
  oms <- c(0.5, 1, 1.5, 2, 3, 5)
  vals <- vapply(oms, function(o) bf_uniform_weights(9, 3, omega = o),
                 numeric(1))
  expect_true(all(diff(vals) < 0))
  # The value the replications' sensitivity tables print at omega = 2.
  expect_equal(bf_uniform_weights(9, 3, omega = 2), 2.85481299,
               tolerance = 1e-7)
})

test_that("the closed form and the integral agree at omega = 1", {
  # omega = 1 takes the closed-form branch; any other value integrates.
  # A value of omega next to one must give nearly the same number, or
  # the two branches compute different things.
  for (y in list(c(2, 1), c(9, 3), c(14, 3), c(18, 3))) {
    expect_equal(bf_uniform_weights(y[1], y[2], omega = 1 + 1e-9),
                 bf_uniform_weights(y[1], y[2]), tolerance = 1e-6)
  }
})

test_that("the function offers no weights on theta and no cutpoint", {
  # The uniform-weights Bayes factor has nothing to set but the bias.
  # Weights stated within each range go through bf_rescaled(). A single
  # Beta density over the whole interval would also set the prior odds
  # on the two theories, so its ratio of posterior masses is posterior
  # odds and not a Bayes factor; the paper uses only rescaled pairs.
  expect_identical(names(formals(bf_uniform_weights)),
                   c("y_W", "y_R", "omega"))
})

test_that("input validation rejects nonsense", {
  # Weights are whole numbers in the paper, so counts are too. A
  # fractional count would otherwise return a number for a coding no
  # researcher could have made.
  expect_error(bf_uniform_weights(-1, 3))
  expect_error(bf_uniform_weights(3, -1))
  expect_error(bf_uniform_weights(9.5, 3))
  expect_error(bf_uniform_weights(c(9, 10), 3))
  expect_error(bf_uniform_weights(9, 3, omega = 0))
})
