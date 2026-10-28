# Substantive tests for sens_bias(), sensitivity to a biased search.
#
# The paper's rule sets the rival aside when the uniform-weights Bayes
# factor is 20 or more and the worst-case Bayes factor is above 1. A
# search omega times as likely to find a pro-working-theory observation
# as a pro-rival one lowers both values. The paper writes omega-star for
# the smallest bias at which the rule no longer sets the rival aside:
# the uniform-weights value has fallen to 20, or the worst-case value
# has fallen to 1, whichever happens at the smaller bias. sens_bias()
# returns the bias at which each condition fails and the smaller of the
# two.
#
# The numbers pinned here are the ones the paper prints, computed in
# the paper repository by sens_bias_binom(), sens_bias_worst(), and
# omega_star() in tests/bf_weighted.R.
#
# Sources: Paper/evalues.qmd (sec-sensitivity, chunks sensitivity-full
# and weight-bias-curves, tbl-app-summary); Paper/appendix.qmd
# (sec-sens-bias).

test_that("the running example tips at a bias of 1.01", {
  # Nine of twelve. The uniform-weights value, 20.67, starts barely
  # above 20, so a search about one percent more likely to find a
  # pro-working-theory observation takes it to 20. The worst-case value
  # falls to 1 only at 1.56, so the uniform-weights condition fails
  # first and omega-star is 1.01.
  s <- sens_bias(9, 3)
  expect_equal(s$omega_uniform, 1.00979420, tolerance = 1e-7)
  expect_equal(s$omega_worst, 1.55926191, tolerance = 1e-7)
  expect_equal(s$omega_star, s$omega_uniform)
  expect_equal(round(s$omega_star, 2), 1.01)
  expect_equal(s$bf_uniform, bf_uniform_weights(9, 3))
  expect_equal(s$bf_worst, bf_worst_case(9, 3))
})

test_that("the memo at weight ten moves the tipping point to 2.33", {
  # Weighted counts 18 and 3. The search would have to be more than
  # twice as likely to find a pro-working-theory observation before the
  # rule stopped setting the rival aside. The worst-case condition fails
  # at 3.24, the dashed line's height at weight 10 in Figure 3.
  s <- sens_bias(18, 3)
  expect_equal(s$omega_uniform, 2.33407511, tolerance = 1e-7)
  expect_equal(s$omega_worst, 3.23585694, tolerance = 1e-7)
  expect_equal(round(s$omega_star, 2), 2.33)
})

test_that("at each tipping point the Bayes factor equals its threshold", {
  # The definition, checked directly: recomputing each value at the
  # returned bias gives back the threshold it was searched against.
  for (y in list(c(9, 3), c(18, 3), c(14, 3), c(16, 4))) {
    s <- sens_bias(y[1], y[2])
    expect_equal(bf_uniform_weights(y[1], y[2], omega = s$omega_uniform), 20,
                 tolerance = 1e-6)
    expect_equal(bf_worst_case(y[1], y[2], omega = s$omega_worst), 1,
                 tolerance = 1e-6)
  }
  # Other thresholds are the researcher's to state.
  s <- sens_bias(18, 3, threshold_uniform = 100, threshold_worst = 2)
  expect_equal(bf_uniform_weights(18, 3, omega = s$omega_uniform), 100,
               tolerance = 1e-6)
  expect_equal(bf_worst_case(18, 3, omega = s$omega_worst), 2,
               tolerance = 1e-6)
})

test_that("the worst-case condition fails before one half stops being the rival's best share", {
  # Up to omega = y_W / y_R the rival's best share is one half; past it
  # the best share is lower (test-bf_worst_case.R). At the bias where
  # omega / (1 + omega) equals y_W / N, the denominator is the largest
  # probability the counts can have, so the worst-case value is already
  # below 1 there and reaches 1 at a smaller bias. So each tipping point
  # is the same whether the rival is held at one half or at its best
  # share, and the paper's reported tipping points stand.
  for (y in list(c(9, 3), c(14, 3), c(11, 2), c(8, 2), c(16, 4), c(18, 3))) {
    expect_lt(sens_bias(y[1], y[2])$omega_worst, y[1] / y[2])
  }
})

test_that("counts that already fail the rule tip at zero", {
  # Pavone and Stiansen's seven of eleven: 4.16 under uniform weights
  # and 0.83 under the worst case. The rule does not set the rival aside
  # at an unbiased search, so there is no decision for bias to change,
  # and both tipping points are 0.
  s <- sens_bias(7, 4)
  expect_equal(s$omega_uniform, 0)
  expect_equal(s$omega_worst, 0)
  expect_equal(s$omega_star, 0)
  # A count can fail one condition and not the other: seven of ten is
  # below 20 under uniform weights and above 1 under the worst case.
  s <- sens_bias(7, 3)
  expect_lt(s$bf_uniform, 20)
  expect_gt(s$bf_worst, 1)
  expect_equal(s$omega_uniform, 0)
  expect_gt(s$omega_worst, 1)
  expect_equal(s$omega_star, 0)
})

test_that("with no rival observations the worst-case condition never fails", {
  # Steinsson's twelve of twelve. With y_R = 0 the probability of the
  # counts rises with the share found, so the numerator, which averages
  # over shares above one half, always exceeds the probability at one
  # half: both values fall toward 1 as the bias grows and never reach
  # it. The worst-case tipping point is therefore infinite, and
  # omega-star is the uniform-weights one, 5.49.
  s <- sens_bias(12, 0)
  expect_identical(s$omega_worst, Inf)
  expect_equal(s$omega_uniform, 5.48513308, tolerance = 1e-7)
  expect_equal(s$omega_star, s$omega_uniform)
  expect_gt(bf_worst_case(12, 0, omega = 1e6), 1)
})

test_that("more weight on the memo needs more bias to change the decision", {
  # Figure 3: for every weight on the memo from 1 to 20, the bias at
  # which the uniform-weights value falls to 20 lies below the bias at
  # which the worst-case value falls to 1, both rise with the weight,
  # and the first reaches 3.82 at weight 20.
  curves <- t(vapply(1:20, function(w) {
    s <- sens_bias(w + 8, 3)
    c(s$omega_uniform, s$omega_worst)
  }, numeric(2)))
  expect_true(all(curves[, 1] < curves[, 2]))
  expect_false(is.unsorted(curves[, 1]))
  expect_false(is.unsorted(curves[, 2]))
  expect_equal(round(curves[20, 1], 2), 3.82)
  expect_equal(round((curves[20, 1] - curves[1, 1]) / 19, 2), 0.15)
})

test_that("input validation rejects nonsense", {
  expect_error(sens_bias(-1, 3))
  expect_error(sens_bias(9.5, 3))
  expect_error(sens_bias(0, 0))
  expect_error(sens_bias(9, 3, threshold_uniform = 0))
  expect_error(sens_bias(9, 3, threshold_worst = -1))
})
