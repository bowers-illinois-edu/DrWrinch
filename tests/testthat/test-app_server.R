# Layer 2 tests for the DrWrinch Shiny app's reactive graph.
#
# These tests fire up the actual server function via shiny::testServer
# and assert that the substantive claims of the running example survive
# the trip from input -> reactive -> renderUI. The pure-function layer
# (bf_binomial, bf_urn, sens_*) is already tested in test-bf_*.R and
# test-sens.R; these tests cover the plumbing between those functions
# and what the user actually sees in the browser.
#
# Phase 1 (MVP) tests only: the two BF reactives and the urn-undefined
# branch of the rendered card. Sensitivity-tab and plot reactives are
# added in Phase 2.

testthat::skip_if_not_installed("shiny")
testthat::skip_if_not_installed("bslib")

app_dir <- system.file("shiny", package = "DrWrinch")
if (!nzchar(app_dir) || !dir.exists(app_dir)) {
  stop(
    "Expected inst/shiny/ but did not find it. ",
    "Implement the MVP app (Phase 1 of PLAN_SHINY.md) so these ",
    "tests can run."
  )
}


test_that("(y_W=7, y_R=3) produces the expected BFs in both model reactives", {
  shiny::testServer(app = app_dir, expr = {
    session$setInputs(
      y_W = 7, y_R = 3, threshold = 20,
      theta_cut = 0.5, prior_a = 1, prior_b = 1
    )
    expect_equal(round(bf_binom(), 2), 7.83)
    expect_equal(bf_urn_v(), 39)
  })
})


test_that("(y_W=2, y_R=10) makes the urn undefined and the urn card says so", {
  shiny::testServer(app = app_dir, expr = {
    session$setInputs(
      y_W = 2, y_R = 10, threshold = 20,
      theta_cut = 0.5, prior_a = 1, prior_b = 1
    )
    expect_true(is.na(bf_urn_v()))
    # as.character(output$xxx) in testServer returns a 2-element
    # vector: the HTML string and a serialized HTMLDependency list
    # (literal "list()"). all = FALSE asks "at least one element
    # matches" so the metadata element does not sink the test.
    expect_match(
      as.character(output$result_urn),
      "undefined",
      ignore.case = TRUE,
      all = FALSE
    )
  })
})


test_that("(y_W=5, y_R=5) yields BF = 1 in both models", {
  shiny::testServer(app = app_dir, expr = {
    session$setInputs(
      y_W = 5, y_R = 5, threshold = 20,
      theta_cut = 0.5, prior_a = 1, prior_b = 1
    )
    expect_equal(bf_binom(), 1)
    expect_equal(bf_urn_v(), 1)
  })
})


test_that("the binomial card prose for (7, 3) names the 'positive' K&R bin", {
  shiny::testServer(app = app_dir, expr = {
    session$setInputs(
      y_W = 7, y_R = 3, threshold = 20,
      theta_cut = 0.5, prior_a = 1, prior_b = 1
    )
    expect_match(
      as.character(output$result_binom),
      "positive",
      ignore.case = TRUE,
      all = FALSE
    )
  })
})


test_that("the urn card prose for (7, 3) names the 'strong' K&R bin", {
  shiny::testServer(app = app_dir, expr = {
    session$setInputs(
      y_W = 7, y_R = 3, threshold = 20,
      theta_cut = 0.5, prior_a = 1, prior_b = 1
    )
    expect_match(
      as.character(output$result_urn),
      "strong",
      ignore.case = TRUE,
      all = FALSE
    )
  })
})
