# Layer 2 tests for the DrWrinch Shiny app's reactive graph.
#
# These fire up the actual server function via shiny::testServer and
# check that the substantive claims of the running example survive the
# trip from input to reactive to rendered card. The Bayes factors and the
# sensitivity functions are tested in test-bf_*.R and test-sens_*.R;
# these cover the plumbing between those functions and what a reader
# sees in the browser.
#
# The app shows two Bayes factors computed from one model and the
# paper's rule for using them: a researcher sets the rival aside, at
# least provisionally, when the uniform-weights Bayes factor is 20 or
# more and the worst-case Bayes factor is above 1. The sidebar carries
# the two counts and the two thresholds, so every test sets those four.

testthat::skip_if_not_installed("shiny")
testthat::skip_if_not_installed("bslib")
testthat::skip_if_not_installed("plotly")

app_dir <- system.file("shiny", package = "DrWrinch")
if (!nzchar(app_dir) || !dir.exists(app_dir)) {
  stop("Expected inst/shiny/ but did not find it.")
}

set_example <- function(session, y_W = 9, y_R = 3,
                        threshold_uniform = 20, threshold_worst = 1) {
  session$setInputs(y_W = y_W, y_R = y_R,
                    threshold_uniform = threshold_uniform,
                    threshold_worst = threshold_worst)
}


test_that("(y_W=9, y_R=3) produces the paper's two Bayes factors", {
  shiny::testServer(app = app_dir, expr = {
    set_example(session)
    expect_equal(round(bf_uw(), 2), 20.67)
    expect_equal(round(bf_wc(), 2), 2.73)
  })
})


test_that("the rule card sets the rival aside at nine of twelve", {
  # 20.67 is at least 20 and 2.73 is above 1, so both conditions hold.
  shiny::testServer(app = app_dir, expr = {
    set_example(session)
    txt <- as.character(output$rule_text)
    expect_match(txt, "sets the rival aside", fixed = TRUE, all = FALSE)
  })
})


test_that("the rule card follows the thresholds in the sidebar", {
  # Raising the uniform-weights threshold to 25 puts 20.67 below it, and
  # the card has to say which condition failed.
  shiny::testServer(app = app_dir, expr = {
    set_example(session, threshold_uniform = 25)
    txt <- as.character(output$rule_text)
    expect_match(txt, "keeps the rival", fixed = TRUE, all = FALSE)
    expect_match(txt, "below 25", fixed = TRUE, all = FALSE)
  })
})


test_that("counts favoring the rival still produce two defined numbers", {
  # Both Bayes factors are ratios of positive probabilities at every
  # count, and both fall below one when the counts favor the rival.
  shiny::testServer(app = app_dir, expr = {
    set_example(session, y_W = 2, y_R = 10)
    expect_true(is.finite(bf_uw()))
    expect_true(is.finite(bf_wc()))
    expect_lt(bf_uw(), 1)
    expect_lt(bf_wc(), 1)
    expect_match(as.character(output$rule_text), "keeps the rival",
                 fixed = TRUE, all = FALSE)
  })
})


test_that("even counts give one under uniform weights but less in the worst case", {
  # At five against five, averaging over each theory's range
  # symmetrically gives exactly one. The worst-case value is 0.37: an
  # even split makes those counts more probable than any average over
  # the shares the working theory claims.
  shiny::testServer(app = app_dir, expr = {
    set_example(session, y_W = 5, y_R = 5)
    expect_equal(bf_uw(), 1, tolerance = 1e-10)
    expect_equal(round(bf_wc(), 2), 0.37)
  })
})


test_that("the uniform-weights card names the Kass and Raftery bin for 20.67", {
  shiny::testServer(app = app_dir, expr = {
    set_example(session)
    txt <- as.character(output$result_uniform)
    expect_match(txt, "20.7", fixed = TRUE, all = FALSE)
    expect_match(txt, "strong", ignore.case = TRUE, all = FALSE)
    expect_match(txt, "favors working theory", fixed = TRUE, all = FALSE)
  })
})


test_that("the worst-case card reports its value without an error rate or a separation", {
  # The worst-case card used to promise an error rate of one in twenty at
  # whatever threshold was typed, and to report a separation. The paper's
  # rule uses this value at a threshold of 1, where no such rate applies,
  # and the separation is gone from the paper.
  shiny::testServer(app = app_dir, expr = {
    set_example(session)
    txt <- as.character(output$result_worst_case)
    expect_match(txt, "2.73", fixed = TRUE, all = FALSE)
    expect_no_match(txt, "one time in twenty", fixed = TRUE, all = TRUE)
    expect_no_match(txt, "separation", ignore.case = TRUE, all = TRUE)
    expect_no_match(txt, "62.3", fixed = TRUE, all = TRUE)
  })
})


test_that("the decomposition reactive holds the three probabilities behind both", {
  # Dividing the shared numerator by each of the two denominators has to
  # give back the two numbers the cards print.
  shiny::testServer(app = app_dir, expr = {
    set_example(session)
    df <- decomp()
    expect_equal(nrow(df), 13L)
    row <- df[df$k == 9, ]
    expect_equal(round(row$numerator / row$den_avg, 2), 20.67)
    expect_equal(round(row$numerator / row$den_half, 2), 2.73)
  })
})


# ---- the Sensitivity tab -----------------------------------------------

test_that("the bias reactive gives the paper's tipping point of 1.01", {
  shiny::testServer(app = app_dir, expr = {
    set_example(session)
    s <- sens_b()
    expect_equal(round(s$omega_uniform, 4), 1.0098)
    expect_equal(round(s$omega_worst, 3), 1.559)
    expect_equal(round(s$omega_star, 2), 1.01)
  })
})


test_that("the coding reactive gives one re-coding", {
  shiny::testServer(app = app_dir, expr = {
    set_example(session)
    s <- sens_code()
    expect_identical(s$x_uniform, 1L)
    expect_identical(s$x_worst, 2L)
    expect_identical(s$x_star, 1L)
  })
})


test_that("the sensitivity prose reports the coding and the bias tipping points", {
  shiny::testServer(app = app_dir, expr = {
    set_example(session)
    txt <- as.character(output$tipping_text)
    expect_match(txt, "1 re-coded observation ", fixed = TRUE, all = FALSE)
    expect_match(txt, "about 1 percent more likely", fixed = TRUE,
                 all = FALSE)
  })
})


test_that("the app no longer offers the urn, the separation, or the prior sweep", {
  # A reader who opens the app should not meet an analysis the paper
  # dropped: the hypergeometric urn, the separation between the two
  # theories' claims, or the Beta(1, M + 1) prior on the whole interval.
  shiny::testServer(app = app_dir, expr = {
    set_example(session)
    for (out in list(output$result_uniform, output$result_worst_case,
                     output$tipping_text, output$about_panel)) {
      txt <- as.character(out)
      expect_no_match(txt, "hypergeometric", ignore.case = TRUE, all = TRUE)
      expect_no_match(txt, "separation", ignore.case = TRUE, all = TRUE)
      expect_no_match(txt, "posterior odds", ignore.case = TRUE, all = TRUE)
    }
  })
})
