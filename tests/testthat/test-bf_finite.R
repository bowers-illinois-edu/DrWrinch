# Substantive tests for the finite-archive Bayes factors,
# bf_uniform_weights_finite() and bf_worst_case_finite().
#
# The binomial model treats the observations as independent draws. A
# researcher reading a finite archive does not read the same document
# twice, so each document read changes the share of what is left. The
# supplement's section "Finite evidence without replacement" states the
# model for that case. The archive holds M documents, K of which support
# the working theory. The working theory claims K > M/2 and the rival
# claims K <= M/2, so when M is even the archive split exactly in half
# belongs to the rival, as theta = 1/2 does in the binomial model. The
# probability of drawing y_W supporting documents among N = y_W + y_R is
# the hypergeometric probability
#
#   p(E | M, K) = choose(K, y_W) choose(M - K, y_R) / choose(M, N).
#
# The uniform-weights version averages that probability over each
# theory's values of K with equal weights. The worst-case version keeps
# the same numerator and evaluates the rival at the largest K at or
# below M/2.
#
# Source: Paper/appendix.qmd, section "Finite evidence without
# replacement", chunks hypergeometric-bf, tbl-hyper, hyper-vs-binomial.

p_hyper <- function(k, N, M, K) choose(K, k) * choose(M - K, N - k) / choose(M, N)

test_that("both values match the supplement's sums over K", {
  # Written with choose() rather than dhyper() so that a reader can
  # compare the code with the formula the supplement prints.
  for (M in c(12, 13, 20, 21, 40)) {
    for (k in 6:12) {
      K1 <- (floor(M / 2) + 1):M
      KR <- 0:floor(M / 2)
      num <- mean(p_hyper(k, 12, M, K1))
      expect_equal(bf_uniform_weights_finite(k, 12 - k, M),
                   num / mean(p_hyper(k, 12, M, KR)), tolerance = 1e-12,
                   info = sprintf("M = %d, y_W = %d", M, k))
      expect_equal(bf_worst_case_finite(k, 12 - k, M),
                   num / p_hyper(k, 12, M, floor(M / 2)), tolerance = 1e-12,
                   info = sprintf("M = %d, y_W = %d", M, k))
    }
  }
})

test_that("the supplement's table at nine of twelve reproduces", {
  # tbl-hyper. Moving from an archive of 20 to one of 100 lowers both
  # values a great deal, which is why the supplement treats M as a
  # sensitivity parameter rather than a number to choose.
  expect_equal(round(bf_uniform_weights_finite(9, 3, 20), 2), 162.88)
  expect_equal(round(bf_worst_case_finite(9, 3, 20), 2), 16.84)
  expect_equal(round(bf_uniform_weights_finite(9, 3, 100), 2), 25.22)
  expect_equal(round(bf_worst_case_finite(9, 3, 100), 2), 3.19)
})

test_that("both values approach the binomial ones as the archive grows", {
  # Drawing twelve documents from an archive of a hundred thousand is
  # nearly the same as drawing them independently, so the finite values
  # should be close to 20.67 and 2.73.
  expect_equal(bf_uniform_weights_finite(9, 3, 1e5), bf_uniform_weights(9, 3),
               tolerance = 1e-3)
  expect_equal(bf_worst_case_finite(9, 3, 1e5), bf_worst_case(9, 3),
               tolerance = 1e-3)
  # And the approach is from above at nine of twelve: a smaller archive
  # is the researcher's more favorable case.
  uw <- vapply(c(20, 50, 100, 1000), function(M)
    bf_uniform_weights_finite(9, 3, M), numeric(1))
  expect_true(all(diff(uw) < 0))
  expect_true(all(uw > bf_uniform_weights(9, 3)))
})

test_that("whenever the binomial values meet the rule, the finite ones do too", {
  # hyper-vs-binomial. The supplement checks every number read N from 1
  # to 40, every count with at least half the documents read supporting
  # the working theory, and every archive size from N to N + 150. This
  # test runs a smaller grid, N up to 20 and archives up to N + 60, which
  # takes seconds rather than minutes. Two claims: when the binomial
  # worst-case value is above 1, the finite one is at least as large;
  # and when the binomial values meet the rule (uniform-weights 20 or
  # more, worst-case above 1), the finite values meet it too.
  grid <- expand.grid(N = 1:20, k = 0:20, d = 0:60)
  grid <- grid[grid$k <= grid$N & 2 * grid$k >= grid$N, ]
  grid$M <- grid$N + grid$d
  ok <- with(grid, mapply(function(k, N, M) {
    uw_b <- bf_uniform_weights(k, N - k)
    wc_b <- bf_worst_case(k, N - k)
    uw_f <- bf_uniform_weights_finite(k, N - k, M)
    wc_f <- bf_worst_case_finite(k, N - k, M)
    worst_ok <- !(wc_b > 1) || wc_f >= wc_b * (1 - 1e-9)
    rule_ok <- !(uw_b >= 20 && wc_b > 1) || (uw_f >= 20 && wc_f > 1)
    worst_ok && rule_ok
  }, k, N, M))
  # One expectation over the whole grid, naming the first failure if
  # there is one, rather than eight thousand separate expectations.
  first_bad <- grid[which(!ok)[1], ]
  expect_true(all(ok), info = paste(names(first_bad), first_bad, collapse = " "))
})

test_that("the uniform-weights finite value can fall below the binomial one", {
  # The supplement reports one case rather than a bound: three of five
  # documents from an archive of six gives 1.78 against a binomial 1.91.
  # With M even the rival owns the half-split archive as well as every
  # smaller K, so it averages over one more value than the working
  # theory does.
  expect_equal(round(bf_uniform_weights_finite(3, 2, 6), 2), 1.78)
  expect_equal(round(bf_uniform_weights(3, 2), 2), 1.91)
})

test_that("equal counts give one when the archive has an odd number of documents", {
  # With M odd the map K -> M - K sends the working theory's values of K
  # onto the rival's one for one, and at equal counts it leaves the
  # probability of the counts unchanged, so the two averages are equal.
  for (M in c(13, 21, 51)) {
    expect_equal(bf_uniform_weights_finite(6, 6, M), 1, tolerance = 1e-12)
  }
})

test_that("counts one side cannot produce give Inf or 0, as the sums imply", {
  # Nine supporting documents cannot come from an archive of twelve or
  # thirteen in which at most six support the working theory, so the
  # rival gives the counts probability zero and the ratio is infinite.
  for (M in c(12, 13)) {
    expect_identical(bf_uniform_weights_finite(9, 3, M), Inf)
    expect_identical(bf_worst_case_finite(9, 3, M), Inf)
  }
  # Reading an entire archive of six and finding no supporting document
  # is possible only if K = 0, which the rival claims and the working
  # theory does not, so the uniform-weights value is zero.
  expect_identical(bf_uniform_weights_finite(0, 6, 6), 0)
  # The worst-case value is undefined there: the half-split archive,
  # K = 3, cannot produce those counts either, so both probabilities
  # are zero. This happens only when the counts favor the rival; with
  # y_W >= y_R the value at the half-split archive is always positive or
  # the ratio is infinite.
  expect_true(is.nan(bf_worst_case_finite(0, 6, 6)))
  for (M in 6:30) {
    for (k in 3:6) {
      expect_false(is.nan(bf_worst_case_finite(k, 6 - k, M)))
    }
  }
})

test_that("input validation rejects nonsense", {
  # The archive must hold at least the documents read, and its size is a
  # whole number.
  expect_error(bf_uniform_weights_finite(9, 3, 11))
  expect_error(bf_worst_case_finite(9, 3, 11))
  expect_error(bf_uniform_weights_finite(9, 3, 20.5))
  expect_error(bf_uniform_weights_finite(9, 3, c(20, 30)))
  expect_error(bf_uniform_weights_finite(9.5, 3, 20))
  expect_error(bf_worst_case_finite(-1, 3, 20))
})
