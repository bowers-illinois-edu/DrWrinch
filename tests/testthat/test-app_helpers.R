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
