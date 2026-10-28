# Layer 1 tests for the Shiny app's pure helper functions.
#
# Written before the helpers themselves (per the package's coding
# standards: tests precede implementation). The helpers live under
# `inst/shiny/R/helpers.R` -- not under the package's own `R/` --
# because they belong to the app, not to the package's exported
# namespace. We source them from the install/dev path so testthat can
# reach them whether the package is loaded by devtools::load_all() or
# installed by R CMD check.
#
# The helpers turn the package's numbers into the sentences the app
# shows. The paper's rule sets the rival aside, at least provisionally,
# when the uniform-weights Bayes factor is 20 or more and the worst-case
# Bayes factor is above 1, so the sentences have to say which of the two
# conditions decides.

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


# ---- interpret_rule -----------------------------------------------------
#
# The paper's rule sets the rival aside, at least provisionally, when the
# uniform-weights Bayes factor is 20 or more and the worst-case Bayes
# factor is above 1. interpret_rule() says which way the rule goes at
# the reader's counts and, when it keeps the rival, which condition
# failed, because the reader's next question is which number to look at.

test_that("interpret_rule says the rule sets the rival aside when both conditions hold", {
  out <- interpret_rule(20.67, 2.73)
  expect_match(out, "sets the rival aside", fixed = TRUE)
  expect_no_match(out, "keeps the rival", fixed = TRUE)
})

test_that("interpret_rule names the uniform-weights condition when it fails", {
  out <- interpret_rule(4.16, 1.2)
  expect_match(out, "keeps the rival", fixed = TRUE)
  expect_match(out, "uniform-weights Bayes factor is below 20", fixed = TRUE)
})

test_that("interpret_rule names the worst-case condition when only it fails", {
  # Possible only with more than 100 observations, as at 59 of 101.
  out <- interpret_rule(20.78, 0.98)
  expect_match(out, "keeps the rival", fixed = TRUE)
  expect_match(out, "worst-case Bayes factor is 1 or below", fixed = TRUE)
  expect_no_match(out, "below 20", fixed = TRUE)
})

test_that("interpret_rule follows the thresholds it is given", {
  # The uniform-weights condition is met at the threshold; the
  # worst-case condition is not.
  expect_match(interpret_rule(25, 2, threshold_uniform = 25),
               "sets the rival aside", fixed = TRUE)
  expect_match(interpret_rule(25, 2, threshold_worst = 2),
               "worst-case Bayes factor is 2 or below", fixed = TRUE)
})


# ---- interpret_bias -----------------------------------------------------
#
# interpret_bias() turns the list sens_bias() returns into a sentence.
# Below a bias of two it reports a percentage, because "about 1 percent
# more likely" is how a reader thinks about a small bias; from two on it
# reports a multiple, because "233 percent more likely" is harder to
# read than "2.33 times as likely".

sb <- function(om_u, om_w) {
  list(bf_uniform = 30, bf_worst = 3, omega_uniform = om_u,
       omega_worst = om_w, omega_star = suppressWarnings(min(om_u, om_w,
                                                            na.rm = TRUE)))
}

test_that("interpret_bias reports a small bias as a percentage and names the condition", {
  out <- interpret_bias(sb(1.0098, 1.559))
  expect_match(out, "about 1 percent more likely", fixed = TRUE)
  expect_match(out, "uniform-weights Bayes factor falls to 20", fixed = TRUE)
  expect_match(out, "1.56", fixed = TRUE)
})

test_that("interpret_bias reports a large bias as a multiple", {
  out <- interpret_bias(sb(2.334, 3.236))
  expect_match(out, "2.33 times as likely", fixed = TRUE)
})

test_that("interpret_bias names the worst-case condition when it fails first", {
  out <- interpret_bias(sb(3, 2))
  expect_match(out, "worst-case Bayes factor falls to 1", fixed = TRUE)
})

test_that("interpret_bias says there is nothing for bias to change when the rule already keeps the rival", {
  out <- interpret_bias(sb(0, 0))
  expect_match(out, "unbiased search", fixed = TRUE)
  expect_match(out, "no decision for bias to change", fixed = TRUE)
})

test_that("interpret_bias handles a condition that no bias makes fail", {
  # Steinsson's twelve of twelve: the worst-case value never falls to 1,
  # so the uniform-weights condition decides.
  out <- interpret_bias(sb(5.485, Inf))
  expect_match(out, "5.49 times as likely", fixed = TRUE)
  expect_match(out, "no bias", ignore.case = TRUE)
})


# ---- interpret_coding ---------------------------------------------------

sc <- function(x_u, x_w) {
  list(bf_uniform = 30, bf_worst = 3, x_uniform = x_u, x_worst = x_w,
       x_star = suppressWarnings(as.integer(min(x_u, x_w, na.rm = TRUE))))
}

test_that("interpret_coding names one re-coding, in the singular, and the condition", {
  out <- interpret_coding(sc(1L, 2L))
  expect_match(out, "1 re-coded observation ", fixed = TRUE)
  expect_match(out, "uniform-weights Bayes factor below 20", fixed = TRUE)
})

test_that("interpret_coding pluralizes", {
  out <- interpret_coding(sc(2L, 4L))
  expect_match(out, "2 re-coded observations", fixed = TRUE)
})

test_that("interpret_coding says nothing needs re-coding when the rule already keeps the rival", {
  out <- interpret_coding(sc(0L, 0L))
  expect_match(out, "as coded", fixed = TRUE)
})


# ---- bf_omega_curve -----------------------------------------------------

test_that("bf_omega_curve samples both Bayes factors on a log grid", {
  df <- bf_omega_curve(9, 3)
  expect_named(df, c("omega", "bf_uniform", "bf_worst"))
  expect_equal(nrow(df), 80)
  expect_true(all(diff(log(df$omega)) > 0))
  expect_equal(range(df$omega), c(0.25, 8))
})

test_that("both curves fall as the bias grows", {
  # Granting more bias toward the working theory lowers both values.
  df <- bf_omega_curve(9, 3)
  expect_true(all(diff(df$bf_uniform) < 0))
  expect_true(all(diff(df$bf_worst) < 0))
})

test_that("the curves are the package's values at each bias", {
  df <- bf_omega_curve(9, 3)
  for (i in c(1, 30, 80)) {
    expect_equal(df$bf_uniform[i],
                 DrWrinch::bf_uniform_weights(9, 3, omega = df$omega[i]))
    expect_equal(df$bf_worst[i],
                 DrWrinch::bf_worst_case(9, 3, omega = df$omega[i]))
  }
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
