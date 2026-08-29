# Layer 2 tests for the DrWrinch Shiny app's reactive graph.
#
# These fire up the actual server function via shiny::testServer and
# check that the substantive claims of the running example survive the
# trip from input to reactive to rendered card. The Bayes factors
# themselves are tested in test-bf_*.R and the sensitivity functions in
# test-sens*.R; these cover the plumbing between those functions and
# what a reader sees in the browser.
#
# The app shows two Bayes factors computed from one model. They share a
# numerator and differ in the denominator: bf_uniform_weights() averages
# over the rival's whole range of shares, bf_worst_case() takes her best
# single share, one half. The sidebar carries only the two counts and
# the threshold, so every test sets exactly those.

testthat::skip_if_not_installed("shiny")
testthat::skip_if_not_installed("bslib")
testthat::skip_if_not_installed("plotly")

app_dir <- system.file("shiny", package = "DrWrinch")
if (!nzchar(app_dir) || !dir.exists(app_dir)) {
  stop("Expected inst/shiny/ but did not find it.")
}


test_that("(y_W=9, y_R=3) produces the paper's two Bayes factors", {
  # The running example. Averaging over the rival's whole range gives
  # 20.67, just above a threshold of 20. Granting her the single share
  # that fits the counts best gives 2.73, which was never above it.
  shiny::testServer(app = app_dir, expr = {
    session$setInputs(y_W = 9, y_R = 3, threshold = 20)
    expect_equal(round(bf_uw(), 2), 20.67)
    expect_equal(round(bf_wc(), 2), 2.73)
  })
})


test_that("counts favoring the rival still produce two defined numbers", {
  # The urn model was undefined when the rival's count exceeded the
  # working theory's by more than one, and the app had to explain a
  # blank cell. Neither Bayes factor in the one-model paper has that
  # gap: both are ratios of positive probabilities at every count, and
  # both fall below one when the counts favor the rival.
  shiny::testServer(app = app_dir, expr = {
    session$setInputs(y_W = 2, y_R = 10, threshold = 20)
    expect_true(is.finite(bf_uw()))
    expect_true(is.finite(bf_wc()))
    expect_lt(bf_uw(), 1)
    expect_lt(bf_wc(), 1)
    expect_no_match(as.character(output$result_uniform), "undefined",
                    ignore.case = TRUE, all = TRUE)
    expect_no_match(as.character(output$result_worst_case), "undefined",
                    ignore.case = TRUE, all = TRUE)
  })
})


test_that("even counts give one under uniform weights but less under the worst case", {
  # At five against five the evidence is split, and averaging over each
  # theory's range symmetrically gives exactly one. The worst-case Bayes
  # factor gives 0.37, below one: a rival who may claim an evenly split
  # body of evidence is not merely tied by even counts, she is favored,
  # because an even split makes those counts more probable than any
  # average over the shares the working theory claims.
  shiny::testServer(app = app_dir, expr = {
    session$setInputs(y_W = 5, y_R = 5, threshold = 20)
    expect_equal(bf_uw(), 1, tolerance = 1e-10)
    expect_equal(round(bf_wc(), 2), 0.37)
  })
})


test_that("the uniform-weights card names the Kass and Raftery bin for 20.67", {
  shiny::testServer(app = app_dir, expr = {
    session$setInputs(y_W = 9, y_R = 3, threshold = 20)
    txt <- as.character(output$result_uniform)
    expect_match(txt, "20.7", fixed = TRUE, all = FALSE)
    expect_match(txt, "strong", ignore.case = TRUE, all = FALSE)
    expect_match(txt, "favors working theory", fixed = TRUE, all = FALSE)
  })
})


test_that("the worst-case card names its own bin and reports the separation", {
  # At 2.73 the worst-case Bayes factor is in the bare-mention bin, so
  # the card has to report the separation instead: the working theory
  # would have to claim at least 62.3 percent of the evidence and the
  # rival at most 37.7 percent before these counts reach 20.
  shiny::testServer(app = app_dir, expr = {
    session$setInputs(y_W = 9, y_R = 3, threshold = 20)
    txt <- as.character(output$result_worst_case)
    expect_match(txt, "2.73", fixed = TRUE, all = FALSE)
    expect_match(txt, "62.3", fixed = TRUE, all = FALSE)
    expect_match(txt, "37.7", fixed = TRUE, all = FALSE)
  })
})


test_that("the decomposition reactive holds the three probabilities behind both", {
  # The picture on the Result tab is three bars per count. Dividing the
  # shared numerator by each of the two denominators has to give back
  # the two numbers the cards print, or the app draws one thing and
  # reports another.
  shiny::testServer(app = app_dir, expr = {
    session$setInputs(y_W = 9, y_R = 3, threshold = 20)
    df <- decomp()
    expect_equal(nrow(df), 13L)
    row <- df[df$k == 9, ]
    expect_equal(round(row$numerator / row$den_avg, 2), 20.67)
    expect_equal(round(row$numerator / row$den_half, 2), 2.73)
  })
})


# ---- the Sensitivity tab -----------------------------------------------

test_that("sens_b(9, 3, threshold=20) tips with a slight bias and one background case", {
  # The uniform-weights Bayes factor clears 20 by so little that a one
  # percent search bias, or a single background case favoring the rival,
  # changes what the researcher would report.
  shiny::testServer(app = app_dir, expr = {
    session$setInputs(y_W = 9, y_R = 3, threshold = 20)
    s <- sens_b()
    expect_equal(round(s$omega_star, 4), 1.0098)
    expect_equal(s$M_star, 1L)
  })
})


test_that("the sensitivity prose reports one re-coding for the uniform weights", {
  shiny::testServer(app = app_dir, expr = {
    session$setInputs(y_W = 9, y_R = 3, threshold = 20)
    txt <- as.character(output$tipping_text)
    expect_match(txt, "Re-coding 1 pro-working-theory observation",
                 fixed = TRUE, all = FALSE)
  })
})


test_that("the sensitivity prose calls the prior sweep posterior odds", {
  # A Beta(1, M + 1) prior moves weight between the two theories as well
  # as within their ranges, so what it drops below the threshold is the
  # posterior odds. The Bayes factor rises with M, so prose naming the
  # Bayes factor here would tell the reader the opposite of the truth.
  shiny::testServer(app = app_dir, expr = {
    session$setInputs(y_W = 9, y_R = 3, threshold = 20)
    txt <- as.character(output$tipping_text)
    expect_match(txt, "M = 1", fixed = TRUE, all = FALSE)
    expect_match(txt, "posterior odds", ignore.case = TRUE, all = FALSE)
  })
})


test_that("the sensitivity prose shows what re-coding does to the separation", {
  # For the worst-case Bayes factor re-coding cannot overturn a
  # conclusion the researcher did not draw at these counts. What it
  # moves is the separation: 0.123 at the agreed coding, 0.179 after one
  # re-coding, 0.318 after two.
  shiny::testServer(app = app_dir, expr = {
    session$setInputs(y_W = 9, y_R = 3, threshold = 20)
    txt <- as.character(output$tipping_text)
    for (g in c("0.123", "0.179", "0.318")) {
      expect_match(txt, g, fixed = TRUE, all = FALSE)
    }
  })
})


test_that("the app no longer offers the urn", {
  # Task 5 deprecated the urn model and task 6 removes its panel. A
  # reader who opens the app should not meet a model the paper dropped.
  shiny::testServer(app = app_dir, expr = {
    session$setInputs(y_W = 9, y_R = 3, threshold = 20)
    for (out in list(output$result_uniform, output$result_worst_case,
                     output$tipping_text, output$about_panel)) {
      expect_no_match(as.character(out), "hypergeometric",
                      ignore.case = TRUE, all = TRUE)
    }
  })
})
