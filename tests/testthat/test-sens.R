# Substantive tests for sens_binomial and sens_urn.
#
# Both functions report tipping points: the smallest observation bias
# omega > 1 (and, for sens_binomial, the smallest rival-tilted prior
# count M) at which the Bayes factor first drops below `threshold`.

test_that("sens_urn(7, 3) matches the paper's reported omega_star", {
  # Cross-validated against the paper's own helper
  # `sens_bias_hyper_separated(rep(1, 7), rep(1, 3), threshold = 20)`
  # (from ~/repos/fully_specified_bf/tests/bf_separated.R), which uses
  # uniroot on the same hypergeometric BF function. We hard-code the
  # numerical value here so this test is self-contained.
  s <- sens_urn(7, 3, threshold = 20)
  expect_equal(s$omega_star, 1.304023, tolerance = 1e-5)
})

test_that("sens returns 0 tipping points when baseline BF is below threshold", {
  # bf_binomial(7, 3) ~= 7.83, below threshold 20. Substantively:
  # the conclusion already fails at omega = 1 and M = 0, so no
  # perturbation is required to overturn it.
  sb <- sens_binomial(7, 3, threshold = 20)
  expect_lt(sb$bf, 20)
  expect_equal(sb$omega_star, 0)
  expect_equal(sb$M_star, 0L)

  # bf_urn(5, 5) = 1, well below threshold.
  su <- sens_urn(5, 5, threshold = 20)
  expect_lt(su$bf, 20)
  expect_equal(su$omega_star, 0)
})

test_that("tipping points are positive when baseline BF exceeds threshold", {
  # bf_binomial(17, 3) and bf_urn(17, 3) are both well above 20.
  sb <- sens_binomial(17, 3, threshold = 20)
  expect_gt(sb$bf, 20)
  expect_gt(sb$omega_star, 1)
  expect_gt(sb$M_star, 0)

  su <- sens_urn(17, 3, threshold = 20)
  expect_gt(su$bf, 20)
  expect_gt(su$omega_star, 1)
})

test_that("omega_star is the actual crossing point: BF(omega_star) = threshold", {
  # The tipping point is found by uniroot, so BF at omega_star should
  # equal the threshold to within uniroot tolerance.
  threshold <- 20
  sb <- sens_binomial(17, 3, threshold = threshold)
  expect_equal(bf_binomial(17, 3, omega = sb$omega_star), threshold,
               tolerance = 1e-4)

  su <- sens_urn(17, 3, threshold = threshold)
  expect_equal(bf_urn(17, 3, omega = su$omega_star), threshold,
               tolerance = 1e-4)
})

test_that("M_star is consistent with the pseudo-observation reading", {
  # Beta(1, M+1) prior with data (y_W, y_R) is identical to uniform
  # prior with data (y_W, y_R + M). M_star, the smallest M dropping
  # BF below threshold, should therefore equal the smallest non-
  # negative integer M for which bf_binomial(y_W, y_R + M) < threshold.
  y_W <- 17; y_R <- 3; threshold <- 20
  bfs <- vapply(0:200, function(M) bf_binomial(y_W, y_R + M), numeric(1))
  expected_M_star <- as.integer(which(bfs < threshold)[1] - 1L)

  sb <- sens_binomial(y_W, y_R, threshold = threshold)
  expect_equal(sb$M_star, expected_M_star)
})

test_that("raising the threshold cannot raise omega_star", {
  # If a higher threshold can still be overcome, the data must be even
  # less robust to bias. Monotone: omega_star is non-increasing in
  # threshold (within the range where it stays positive).
  s_low  <- sens_urn(17, 3, threshold = 5)
  s_high <- sens_urn(17, 3, threshold = 50)
  expect_gte(s_low$omega_star, s_high$omega_star)
})
