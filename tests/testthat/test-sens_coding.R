# Substantive tests for sens_coding (coding-error sensitivity).
#
# Coding error is the third sensitivity question in the paper, alongside
# observation bias (sens_*'s omega_star) and the rival-tilted prior
# (sens_binomial's M_star). A peer cannot re-read every document, but she
# can ask: how many of the pro-H_1 observations would have to be re-coded
# as pro-rival before the conclusion crosses the decision threshold?
#
# Re-coding x observations relabels x pro-H_1 items as pro-rival, moving
# the counts from (y_W, y_R) to (y_W - x, y_R + x). The total number of
# observations n = y_W + y_R does not change; only the split does. We then
# recompute the same model's Bayes factor at the new counts. This is why
# one function serves both models: the mechanism is the relabeling, and
# the model only decides which Bayes factor to recompute.
#
# The expected tipping points are the values reported in the paper's
# running example (k = 9 pro-H_1, r = 3 pro-rival, threshold = 20):
# one re-coding overturns the binomial conclusion, two overturn the
# hypergeometric.

# ---- the paper's running example ---------------------------------------

test_that("binomial coding tipping point at (9, 3) is 1 (paper value)", {
  # The paper reports that re-coding a single one of the nine pro-H_1
  # observations takes the binomial Bayes factor below 20, because the
  # baseline BF (20.67) sits just above the threshold.
  s <- sens_coding(9, 3, model = "binomial", threshold = 20)
  expect_equal(s$x_star, 1L)
  # Mechanism: the baseline is at or above threshold, and one re-coding
  # crosses it. (y_W - 1, y_R + 1) = (8, 4).
  expect_gte(bf_binomial(9, 3), 20)
  expect_lt(bf_binomial(8, 4), 20)
})

test_that("urn coding tipping point at (9, 3) is 2 (paper value)", {
  # The bounded-archive model tolerates one more re-coding than the
  # binomial: bf_urn(8, 4) = 34 is still above 20, but bf_urn(7, 5) = 5
  # is below it, so two re-codings are required.
  s <- sens_coding(9, 3, model = "urn", threshold = 20)
  expect_equal(s$x_star, 2L)
  expect_gte(bf_urn(8, 4), 20)
  expect_lt(bf_urn(7, 5), 20)
})

test_that("the returned baseline BF matches the model's BF at the observed counts", {
  sb <- sens_coding(9, 3, model = "binomial", threshold = 20)
  su <- sens_coding(9, 3, model = "urn", threshold = 20)
  expect_equal(sb$bf, bf_binomial(9, 3))
  expect_equal(su$bf, bf_urn(9, 3))
})

# ---- the definition, pinned independently ------------------------------

test_that("x_star is the smallest integer re-coding that drops the BF below threshold", {
  # Pin the substantive definition: x_star is the smallest x >= 0 such
  # that recomputing the model's BF at (y_W - x, y_R + x) falls below
  # threshold. Compute it independently here and compare.
  threshold <- 20
  cases <- list(c(9, 3), c(12, 2), c(18, 3), c(10, 0))
  for (m in c("binomial", "urn")) {
    bf_fn <- if (m == "binomial") bf_binomial else bf_urn
    for (yc in cases) {
      y_W <- yc[1]; y_R <- yc[2]
      bfs <- vapply(0:y_W, function(x) {
        v <- bf_fn(y_W - x, y_R + x)
        if (is.na(v)) NA_real_ else v
      }, numeric(1))
      hit <- which(!is.na(bfs) & bfs < threshold)
      expected <- if (length(hit) == 0L) NA_integer_ else as.integer(hit[1] - 1L)
      s <- sens_coding(y_W, y_R, model = m, threshold = threshold)
      expect_equal(s$x_star, expected,
                   info = sprintf("model=%s, y_W=%d, y_R=%d", m, y_W, y_R))
    }
  }
})

# ---- branch behavior ---------------------------------------------------

test_that("baseline below threshold yields x_star = 0 (no re-coding needed)", {
  # bf_binomial(7, 3) ~= 7.83 < 20: the conclusion already fails at the
  # observed coding, so zero re-codings are required to overturn it.
  s <- sens_coding(7, 3, model = "binomial", threshold = 20)
  expect_lt(s$bf, 20)
  expect_equal(s$x_star, 0L)

  # bf_urn(5, 5) = 1 < 20: same branch for the urn model.
  su <- sens_coding(5, 5, model = "urn", threshold = 20)
  expect_lt(su$bf, 20)
  expect_equal(su$x_star, 0L)
})

test_that("a lower threshold cannot make the conclusion easier to overturn", {
  # Lowering the threshold means the BF has further to fall before it
  # crosses, so it takes at least as many re-codings. x_star is
  # non-decreasing as the threshold drops.
  for (m in c("binomial", "urn")) {
    s_high <- sens_coding(9, 3, model = m, threshold = 20)
    s_low  <- sens_coding(9, 3, model = m, threshold = 5)
    expect_gte(s_low$x_star, s_high$x_star,
               label = sprintf("x_star at threshold 5 (model=%s)", m))
  }
})

test_that("the urn skips undefined re-codings without error", {
  # Re-coding eventually shrinks the rival-favorable urn below the sample
  # size (the swap regime, where bf_urn returns NA). Because re-coding
  # drives the BF toward equipoise, the threshold crossing always happens
  # before the urn becomes undefined for any threshold > 1, so the paper
  # example resolves to a finite integer rather than NA.
  s <- sens_coding(9, 3, model = "urn", threshold = 20)
  expect_false(is.na(s$x_star))
  expect_type(s$x_star, "integer")
})

# ---- input validation --------------------------------------------------

test_that("input validation rejects nonsense", {
  expect_error(sens_coding(-1, 3, model = "binomial"))
  expect_error(sens_coding(9, -1, model = "binomial"))
  expect_error(sens_coding(0, 0, model = "urn"))
  expect_error(sens_coding(9, 3, model = "binomial", threshold = -1))
  expect_error(sens_coding(9, 3, model = "not-a-model"))
})
