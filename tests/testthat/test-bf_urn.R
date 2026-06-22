# Substantive tests for bf_urn (Formulation C).
#
# The Working Theory Favorable (WTF) sub-model has urn composition
#   (y_W + 1, max(1, y_R))
# and the Rival Theory Favorable (RTF) sub-model has urn composition
#   (y_W, y_W + 1).
# Both tilt in favor of H_R by construction, so the reported BF is a
# lower bound on the evidence for H_1.

test_that("paper analytical value: bf_urn(9, 3) = 323", {
  # The paper's running example (nine pro-H_1 observations, three
  # pro-rival). Direct combinatorial calculation under Formulation C:
  #   WTF: (10, 3), n = 12. pr_wtf = C(10,9)*C(3,3) / C(13,12) = 10 / 13
  #   RTF: (9, 10), n = 12. pr_rtf = C(9,9)*C(10,3) / C(19,12) = 120 / 50388
  #   BF  = (10/13) / (120/50388) = 323
  expect_equal(bf_urn(9, 3), 323, tolerance = 1e-12)
})

test_that("combinatorial cross-check at (7, 3) = 39", {
  # A second exact Formulation C identity, kept as a regression check
  # independent of the paper's running example:
  #   WTF: (8, 3), n = 10. pr_wtf = C(8,7)*C(3,3) / C(11,10) = 8 / 11
  #   RTF: (7, 8), n = 10. pr_rtf = C(7,7)*C(8,3) / C(15,10) = 56 / 3003
  #   BF  = (8/11) / (56/3003) = (8 * 3003) / (11 * 56) = 39
  expect_equal(bf_urn(7, 3), 39, tolerance = 1e-12)
})

test_that("symmetric evidence yields BF = 1 (non-degeneracy of Formulation C)", {
  # The core property distinguishing Formulation C from naive +1-on-both-
  # sides urn constructions: at y_W = y_R, BF = 1 exactly. The numerator
  # urn (y+1, y) and denominator urn (y, y+1) are mirror images, so the
  # probability of observing (y, y) is the same under each.
  for (n in c(1, 2, 3, 5, 10, 25)) {
    expect_equal(bf_urn(n, n), 1, tolerance = 1e-10,
                 info = sprintf("y_W = y_R = %d", n))
  }
})

test_that("RTF urn is too small when y_R > y_W + 1; bf_urn returns NA", {
  # RTF urn composition is (y_W, y_W + 1), with total y_W + (y_W + 1)
  # = 2 y_W + 1. The sample size is n = y_W + y_R. The construction is
  # well-defined iff 2 y_W + 1 >= y_W + y_R, i.e., y_R <= y_W + 1.
  # When y_R > y_W + 1, no sample of size n can be drawn from RTF.
  expect_true(is.na(bf_urn(2, 10)))
  expect_true(is.na(bf_urn(5, 7)))
  expect_true(is.na(bf_urn(0, 2)))
})

test_that("RTF boundary y_R = y_W + 1 is well-defined", {
  # At y_R = y_W + 1, the RTF urn is exactly the right size: every
  # item is drawn, and the observed (y_W, y_W + 1) pattern occurs
  # with probability 1. The BF is finite and well-defined.
  for (y_W in 1:6) {
    bf <- bf_urn(y_W, y_W + 1)
    expect_false(is.na(bf), info = sprintf("boundary at y_W = %d", y_W))
    expect_true(is.finite(bf) || bf == Inf,
                info = sprintf("boundary at y_W = %d", y_W))
  }
})

test_that("BF is monotone increasing in y_W (y_R fixed) within the defined regime", {
  bfs <- vapply(3:25, function(y) bf_urn(y, 3), numeric(1))
  expect_true(all(diff(bfs) > 0),
              info = "bf_urn(y, 3) must be strictly increasing in y")
})

test_that("omega > 1 lowers the BF; omega < 1 raises it", {
  base <- bf_urn(7, 3)
  expect_lt(bf_urn(7, 3, omega = 2), base)
  expect_gt(bf_urn(7, 3, omega = 0.5), base)
})

test_that("BF is monotone decreasing in omega over a typical range", {
  omegas <- seq(0.5, 5, by = 0.25)
  bfs <- vapply(omegas, function(w) bf_urn(7, 3, omega = w), numeric(1))
  expect_true(all(diff(bfs) < 0),
              info = "bf_urn must be strictly decreasing in omega")
})

test_that("default omega = 1 matches explicit omega = 1", {
  # The omega == 1 branch uses stats::dhyper; omega != 1 uses
  # BiasedUrn::dFNCHypergeo. They should agree at the boundary.
  for (y in list(c(2, 1), c(7, 3), c(10, 3), c(17, 3), c(20, 5))) {
    expect_equal(
      bf_urn(y[1], y[2]),
      bf_urn(y[1], y[2], omega = 1.0),
      tolerance = 1e-6,
      info = sprintf("y_W=%d, y_R=%d", y[1], y[2])
    )
  }
})

test_that("input validation rejects nonsense", {
  expect_error(bf_urn(-1, 3))
  expect_error(bf_urn(3, -1))
  expect_error(bf_urn(0, 0))  # no data at all
  expect_error(bf_urn(7, 3, omega = -1))
})
