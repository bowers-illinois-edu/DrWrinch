# Real-data regression tests from the six published process-tracing
# studies reanalyzed in Lopez, Bowers, and Gajardo Cooper (2026).
#
# The paper's applications compute their Bayes factors through weighted
# helpers (binom_bf_weighted / hyper_bf_weighted in the paper repo)
# which, for unit weights, reduce exactly to bf_binomial(y_W, y_R) and
# bf_urn(y_W, y_R). The paper's replication scripts assert that
# equivalence at run time; here we pin the published (y_W, y_R) counts
# so the package cannot silently change a number that is already in
# print. The studies also exercise a useful spread of inputs: no rival
# evidence (Steinsson, y_R = 0), a near-threshold case (Andersen), and a
# case below threshold under both models (Pavone & Stiansen).

# name, (y_W, y_R), binomial BF, urn BF, coding-error tipping (binom, urn)
apps <- list(
  list(name = "Mor (2022)",                       y_W =  8, y_R = 2,
       binom = 29.5672,  urn = 442,     x_binom = 1L, x_urn = 2L),
  list(name = "Steinsson (2023)",                 y_W = 12, y_R = 0,
       binom = 8191,     urn = 742900,  x_binom = 4L, x_urn = 5L),
  list(name = "Andersen (2023)",                  y_W =  9, y_R = 3,
       binom = 20.672,   urn = 323,     x_binom = 1L, x_urn = 2L),
  list(name = "Hammoud-Gallego & Freier (2022)",  y_W = 10, y_R = 3,
       binom = 33.8596,  urn = 969,     x_binom = 1L, x_urn = 2L),
  list(name = "Pavone & Stiansen (2021)",         y_W =  7, y_R = 4,
       binom = 4.15869,  urn = 13,      x_binom = 0L, x_urn = 0L),
  list(name = "Winward (2020)",                   y_W = 14, y_R = 3,
       binom = 264.328,  urn = 95047.5, x_binom = 2L, x_urn = 4L)
)

for (a in apps) {
  local({
    a <- a
    test_that(sprintf("%s: bf_binomial and bf_urn match the published values", a$name), {
      expect_equal(bf_binomial(a$y_W, a$y_R), a$binom, tolerance = 1e-4)
      expect_equal(bf_urn(a$y_W, a$y_R), a$urn, tolerance = 1e-6)
    })

    test_that(sprintf("%s: sens_coding reproduces the coding-error tipping points", a$name), {
      expect_equal(sens_coding(a$y_W, a$y_R, model = "binomial", threshold = 20)$x_star, a$x_binom)
      expect_equal(sens_coding(a$y_W, a$y_R, model = "urn", threshold = 20)$x_star, a$x_urn)
    })
  })
}

test_that("Pavone & Stiansen (2021) is below threshold under both models", {
  # The agreed coding leaves both BFs under 20, so the coding-error
  # tipping point is 0: the conclusion does not clear the threshold even
  # before any re-coding.
  expect_lt(bf_binomial(7, 4), 20)
  expect_lt(bf_urn(7, 4), 20)
})

test_that("Steinsson (2023) exercises the no-rival-evidence edge (y_R = 0)", {
  # With y_R = 0 both Bayes factors are large and the conclusion absorbs
  # several re-codings before crossing the threshold.
  expect_gt(bf_binomial(12, 0), 20)
  expect_gt(bf_urn(12, 0), 20)
  expect_equal(sens_coding(12, 0, model = "binomial", threshold = 20)$x_star, 4L)
  expect_equal(sens_coding(12, 0, model = "urn", threshold = 20)$x_star, 5L)
})
