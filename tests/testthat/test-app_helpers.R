# Layer 1 tests for the Shiny app's pure helper functions.
#
# Written before the helpers themselves (per the package's coding
# standards: tests precede implementation). The helpers live under
# `inst/shiny/R/helpers.R` -- not under the package's own `R/` --
# because they belong to the app, not to the package's exported
# namespace. We source them from the install/dev path so testthat can
# reach them whether the package is loaded by devtools::load_all() or
# installed by R CMD check.

helpers_path <- system.file("shiny/R/helpers.R", package = "DrWrinch")
if (!nzchar(helpers_path) || !file.exists(helpers_path)) {
  stop(
    "Expected inst/shiny/R/helpers.R but did not find it. ",
    "Implement the app helpers (Phase 1 of PLAN_SHINY.md) so these ",
    "tests can run."
  )
}
source(helpers_path, local = TRUE)
source(file.path(dirname(helpers_path), "curves.R"), local = TRUE)


# ---- format_bf ----------------------------------------------------------

test_that("format_bf returns a list with value, verdict, and direction", {
  out <- format_bf(39)
  expect_named(out, c("value", "verdict", "direction"), ignore.order = TRUE)
})

test_that("format_bf(39) is strong evidence for the working theory", {
  out <- format_bf(39)
  expect_equal(out$verdict, "strong")
  expect_equal(out$direction, "favors working theory")
})

test_that("format_bf(1) is at the bare-mention boundary with no direction", {
  out <- format_bf(1)
  expect_equal(out$verdict, "not worth more than a bare mention")
  expect_equal(out$direction, "neither")
})

test_that("format_bf(NA_real_) is undefined and does not crash", {
  out <- format_bf(NA_real_)
  expect_equal(out$verdict, "undefined")
})

test_that("format_bf(Inf) is very-strong evidence for the working theory", {
  out <- format_bf(Inf)
  expect_equal(out$verdict, "very strong")
  expect_equal(out$direction, "favors working theory")
})

test_that("format_bf(0.5) labels rival-favoring evidence symmetrically", {
  out <- format_bf(0.5)
  expect_equal(out$verdict, "not worth more than a bare mention")
  expect_equal(out$direction, "favors rival")
})

test_that("format_bf(0.01) is strong evidence for the rival", {
  out <- format_bf(0.01)
  expect_equal(out$verdict, "strong")
  expect_equal(out$direction, "favors rival")
})


# ---- bf_label -----------------------------------------------------------

test_that("bf_label respects the Kass & Raftery boundaries", {
  expect_equal(bf_label(1),    "not worth more than a bare mention")
  expect_equal(bf_label(3),    "not worth more than a bare mention")
  expect_equal(bf_label(10),   "positive")
  expect_equal(bf_label(20),   "positive")
  expect_equal(bf_label(30),   "strong")
  expect_equal(bf_label(100),  "strong")
  expect_equal(bf_label(150),  "strong")
  expect_equal(bf_label(151),  "very strong")
})

test_that("bf_label is symmetric across BF = 1", {
  expect_equal(bf_label(1/3),    "not worth more than a bare mention")
  expect_equal(bf_label(1/20),   "positive")
  expect_equal(bf_label(1/150),  "strong")
  expect_equal(bf_label(1/151),  "very strong")
})


# ---- interpret_omega_star ----------------------------------------------

test_that("interpret_omega_star(0) reports failure at baseline", {
  out <- interpret_omega_star(0, threshold = 20)
  expect_type(out, "character")
  expect_match(out, "below threshold|already|baseline", ignore.case = TRUE)
})

test_that("interpret_omega_star(NA_real_) reports robust-to-any-bias", {
  out <- interpret_omega_star(NA_real_, threshold = 20)
  expect_type(out, "character")
  expect_match(out, "robust|any.*bias", ignore.case = TRUE)
})

test_that("interpret_omega_star(1.304) yields a ~30% interpretation", {
  out <- interpret_omega_star(1.304, threshold = 20)
  expect_type(out, "character")
  expect_match(out, "30", fixed = TRUE)
  expect_match(out, "%", fixed = TRUE)
})

test_that("interpret_omega_star(1.5) yields a 50% interpretation", {
  out <- interpret_omega_star(1.5, threshold = 20)
  expect_match(out, "50", fixed = TRUE)
  expect_match(out, "%", fixed = TRUE)
})

test_that("interpret_omega_star mentions the threshold it was given", {
  out <- interpret_omega_star(1.3, threshold = 20)
  expect_match(out, "20", fixed = TRUE)
})


# ---- interpret_M_star --------------------------------------------------
#
# Same three-branch pattern as interpret_omega_star, but for the
# prior-sweep tipping point M_star from sens_binomial(). Values:
#   0           -- baseline already below threshold (the conclusion fails
#                  without any rival-favoring pseudo-observations).
#   NA_integer_ -- the BF stays above threshold across the searched
#                  prior sweep [0, M_max].
#   positive    -- the smallest integer M at which the Beta(1, M + 1)
#                  prior drops the BF below threshold.

test_that("interpret_M_star(0L) reports failure at baseline", {
  out <- interpret_M_star(0L, threshold = 20)
  expect_type(out, "character")
  expect_match(out, "below threshold|already|baseline", ignore.case = TRUE)
})

test_that("interpret_M_star(NA_integer_) reports robust-to-prior-sweep", {
  out <- interpret_M_star(NA_integer_, threshold = 20)
  expect_type(out, "character")
  expect_match(out, "robust|stays above|did not cross", ignore.case = TRUE)
})

test_that("interpret_M_star(14L) reports the integer count and threshold", {
  out <- interpret_M_star(14L, threshold = 20)
  expect_match(out, "14", fixed = TRUE)
  expect_match(out, "20", fixed = TRUE)
})

test_that("interpret_M_star names the posterior odds, not the Bayes factor", {
  # What a Beta(1, M + 1) prior drops below the threshold is the
  # posterior odds. The Bayes factor rises with M, so prose saying the
  # Bayes factor falls would tell the reader the opposite of the truth.
  for (m in list(0L, NA_integer_, 14L)) {
    out <- interpret_M_star(m, threshold = 20)
    expect_match(out, "posterior odds", ignore.case = TRUE)
    expect_false(grepl("Bayes factor", out, fixed = TRUE))
  }
})


# ---- interpret_x_star --------------------------------------------------
#
# Coding-error tipping point from sens_coding(). Same three-branch
# pattern as interpret_omega_star()/interpret_M_star():
#   0           -- baseline already below threshold (no re-coding needed).
#   NA_integer_ -- no re-coding within the observed counts overturns it.
#   positive    -- the number of pro-H_1 observations that must be
#                  re-coded as pro-rival to drop the BF below threshold.

test_that("interpret_x_star(0L) reports failure at baseline", {
  out <- interpret_x_star(0L, threshold = 20)
  expect_type(out, "character")
  expect_match(out, "below threshold|baseline|no re-coding", ignore.case = TRUE)
})

test_that("interpret_x_star(NA_integer_) reports robustness to re-coding", {
  out <- interpret_x_star(NA_integer_, threshold = 20)
  expect_type(out, "character")
  expect_match(out, "does not|not turn", ignore.case = TRUE)
})

test_that("interpret_x_star(1L) names one re-coding (singular) and the threshold", {
  out <- interpret_x_star(1L, threshold = 20)
  expect_match(out, "1 pro-working-theory observation", fixed = TRUE)
  expect_match(out, "20", fixed = TRUE)
  # singular: must not pluralize at x = 1
  expect_false(grepl("1 pro-working-theory observations", out, fixed = TRUE))
})

test_that("interpret_x_star(2L) pluralizes", {
  out <- interpret_x_star(2L, threshold = 20)
  expect_match(out, "2 pro-working-theory observations", fixed = TRUE)
})


# ---- bf_omega_curve ----------------------------------------------------

test_that("bf_omega_curve(9, 3) is monotone-decreasing in omega", {
  # Granting more search bias toward the working theory can only lower
  # the value, so the curve the app draws must fall from left to right.
  df <- bf_omega_curve(9, 3, threshold = 20)
  expect_equal(nrow(df), 80)
  expect_true(all(diff(df$omega) > 0))
  expect_true(all(diff(df$bf) <= 1e-9))
})

test_that("bf_omega_curve near omega = 1 brackets the unbiased value", {
  # At an unbiased search the curve must pass through the number the
  # Result tab shows, 20.67 at the running example.
  df <- bf_omega_curve(9, 3, threshold = 20)
  idx <- which.min(abs(df$omega - 1))
  expect_gt(df$bf[idx], 19)
  expect_lt(df$bf[idx], 23)
})

test_that("bf_omega_curve propagates the threshold for downstream layers", {
  df <- bf_omega_curve(9, 3, threshold = 25)
  expect_true(all(df$threshold == 25))
})


# ---- post_odds_M_curve -------------------------------------------------
#
# A Beta(1, M + 1) prior on the whole interval from zero to one moves
# weight between the two theories as well as within their ranges, so
# what falls as M rises is the posterior odds, not the Bayes factor.
# The column is named for what it holds.

test_that("post_odds_M_curve(10, 0, M_max=50) falls as M rises", {
  df <- post_odds_M_curve(10, 0, M_max = 50, threshold = 20)
  expect_equal(nrow(df), 51)
  expect_true(all(diff(df$post_odds) <= 1e-9))
})

test_that("post_odds_M_curve at M = 0 is the uniform-weights Bayes factor", {
  # At M = 0 the prior is uniform, the two theories carry equal weight,
  # the prior odds are one, and the posterior odds and the Bayes factor
  # coincide. That is the only M at which they do.
  df <- post_odds_M_curve(10, 0, M_max = 5, threshold = 20)
  expect_equal(df$post_odds[1], DrWrinch::bf_uniform_weights(10, 0))
})

test_that("the Bayes factor rises where the posterior odds fall", {
  # The fact that makes the naming matter. Tilting the prior toward the
  # rival commits her to shares near zero, under which the counts are
  # more surprising still, so the Bayes factor rises even as the
  # posterior odds fall.
  df <- post_odds_M_curve(9, 3, M_max = 4, threshold = 20)
  bayes_factor <- vapply(0:4, function(M) {
    lik <- function(t) stats::dbinom(9, 12, t)
    num <- stats::integrate(
      function(t) lik(t) * stats::dbeta(t, 1, M + 1), 0.5, 1)$value
    den <- stats::integrate(
      function(t) lik(t) * stats::dbeta(t, 1, M + 1), 0, 0.5)$value
    pi_1 <- 1 - stats::pbeta(0.5, 1, M + 1)
    (num / pi_1) / (den / (1 - pi_1))
  }, numeric(1))
  expect_true(all(diff(df$post_odds) < 0))
  expect_true(all(diff(bayes_factor) > 0))
})


# ---- validate_counts ---------------------------------------------------
#
# validate_counts uses shiny::validate(need(...)), which raises a
# condition rather than returning a value. We catch the condition and
# inspect its message; calling the function in isolation (outside a
# reactive) is fine for that.

test_that("validate_counts accepts integer-valued doubles", {
  testthat::skip_if_not_installed("shiny")
  # shiny::numericInput returns doubles like 7 (not 7L). The
  # validator must accept these; otherwise every initial render
  # would fail.
  out <- tryCatch(validate_counts(7, 3), condition = function(e) e)
  expect_null(out)
})

test_that("validate_counts rejects non-integer values with 'whole number' prose", {
  testthat::skip_if_not_installed("shiny")
  # Without this check, as.integer(input$y_W) in the server would
  # silently truncate 7.5 to 7. Process tracers count documents and
  # witnesses; a non-integer is a typo we should surface.
  err <- tryCatch(validate_counts(7.5, 3), condition = function(e) e)
  expect_true(inherits(err, "condition"))
  expect_match(conditionMessage(err), "whole number", ignore.case = TRUE)
})

test_that("validate_counts rejects negative values", {
  testthat::skip_if_not_installed("shiny")
  err <- tryCatch(validate_counts(-1, 3), condition = function(e) e)
  expect_true(inherits(err, "condition"))
  expect_match(conditionMessage(err), "non-negative|whole number",
               ignore.case = TRUE)
})

test_that("validate_counts rejects (0, 0) since there is no evidence", {
  testthat::skip_if_not_installed("shiny")
  err <- tryCatch(validate_counts(0, 0), condition = function(e) e)
  expect_true(inherits(err, "condition"))
  expect_match(conditionMessage(err), "both be zero", ignore.case = TRUE)
})
