# Substantive tests for bf_binomial.
#
# The binomial model treats observations as iid Bernoulli draws from an
# infinite evidence universe with success probability theta. The Bayes
# factor compares H_1: theta > theta_cut against H_R: theta <= theta_cut.
# Under a Beta(prior_a, prior_b) prior, the posterior is
# Beta(prior_a + y_W, prior_b + y_R), and the BF is the posterior odds
# of being above the cut.

test_that("symmetric evidence under a symmetric prior yields BF = 1", {
  # Statistical principle: when y_W = y_R and the prior is symmetric
  # about theta_cut = 0.5, the posterior is symmetric and assigns
  # equal mass on either side. There is literally no evidence.
  for (n in c(1, 5, 10, 20, 50)) {
    expect_equal(bf_binomial(n, n), 1, tolerance = 1e-10,
                 info = sprintf("uniform prior, y_W = y_R = %d", n))
  }
  for (a in c(2, 5, 10)) {
    expect_equal(bf_binomial(7, 7, prior_a = a, prior_b = a), 1,
                 tolerance = 1e-10,
                 info = sprintf("Beta(%d, %d) prior, y_W = y_R = 7", a, a))
  }
})

test_that("uniform-prior BF equals the analytical posterior-odds expression", {
  # Closed-form check: with Beta(1,1), posterior is Beta(8, 4) at (7, 3).
  p_below <- stats::pbeta(0.5, 8, 4)
  expected <- (1 - p_below) / p_below
  expect_equal(bf_binomial(7, 3), expected, tolerance = 1e-12)
})

test_that("Beta(1, M+1) prior is equivalent to M extra pro-rival pseudo-observations", {
  # This is the substantive interpretation used by sens_binomial:
  # Beta(a, b) prior with a + b - 2 = M pseudo-observations of which
  # a - 1 favor H_1. Setting prior_a = 1, prior_b = M + 1 means M
  # pseudo-observations, all favoring H_R. The posterior with data
  # (y_W, y_R) is then Beta(1 + y_W, M + 1 + y_R), identical to the
  # posterior under uniform prior with data (y_W, y_R + M).
  for (y_W in c(5, 10, 17)) {
    for (y_R in c(0, 3, 5)) {
      for (M in c(0, 1, 3, 10, 25)) {
        expect_equal(
          bf_binomial(y_W, y_R, prior_a = 1, prior_b = M + 1),
          bf_binomial(y_W, y_R + M),
          tolerance = 1e-10,
          info = sprintf("y_W=%d, y_R=%d, M=%d", y_W, y_R, M)
        )
      }
    }
  }
})

test_that("BF is monotone increasing in y_W (y_R fixed)", {
  # Adding pro-H_1 evidence cannot lower the BF.
  bfs <- vapply(0:25, function(y) bf_binomial(y, 3), numeric(1))
  expect_true(all(diff(bfs) > 0),
              info = "bf_binomial(y, 3) must be strictly increasing in y")
})

test_that("omega > 1 lowers the BF; omega < 1 raises it", {
  # Substantive reading: omega > 1 means pro-H_1 items were more likely
  # to be observed than they are in the population, so the apparent
  # dominance is partly an artifact and the BF falls. omega < 1 means
  # the opposite, so the data is even stronger evidence for H_1.
  base <- bf_binomial(7, 3)
  expect_lt(bf_binomial(7, 3, omega = 2), base)
  expect_gt(bf_binomial(7, 3, omega = 0.5), base)
})

test_that("BF is monotone decreasing in omega over a typical range", {
  omegas <- seq(0.5, 5, by = 0.25)
  bfs <- vapply(omegas, function(w) bf_binomial(7, 3, omega = w), numeric(1))
  expect_true(all(diff(bfs) < 0),
              info = "bf_binomial must be strictly decreasing in omega")
})

test_that("default omega = 1 matches explicit omega = 1", {
  # Catches drift between the closed-form omega = 1 branch and the
  # numerical-integration branch.
  for (y in list(c(2, 1), c(7, 3), c(10, 3), c(17, 3), c(20, 5))) {
    expect_equal(
      bf_binomial(y[1], y[2]),
      bf_binomial(y[1], y[2], omega = 1.0),
      tolerance = 1e-6,
      info = sprintf("y_W=%d, y_R=%d", y[1], y[2])
    )
  }
})

test_that("input validation rejects nonsense", {
  expect_error(bf_binomial(-1, 3))
  expect_error(bf_binomial(3, -1))
  expect_error(bf_binomial(7, 3, omega = -1))
  expect_error(bf_binomial(7, 3, prior_a = 0))
  expect_error(bf_binomial(7, 3, theta_cut = 0))
  expect_error(bf_binomial(7, 3, theta_cut = 1))
})
