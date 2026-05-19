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
testthat::skip_if_not_installed("plotly")

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


# ---- Phase 2: Sensitivity tab -----------------------------------------
#
# The sensitivity tab reports tipping points -- omega_star (observation
# bias) and M_star (rival-favoring pseudo-observations) -- for both
# models, plus the plotly curves over omega and M. The plot rendering
# itself is left to manual review / Layer 3 snapshots; these tests
# pin the substantive numeric and prose claims the sensitivity panel
# is supposed to surface.

test_that("sens_u(7, 3, threshold=20) reactive returns omega_star ~ 1.30", {
  shiny::testServer(app = app_dir, expr = {
    session$setInputs(
      y_W = 7, y_R = 3, threshold = 20,
      theta_cut = 0.5, prior_a = 1, prior_b = 1
    )
    res <- sens_u()
    expect_equal(round(res$omega_star, 2), 1.30)
    expect_equal(res$bf, 39)
  })
})

test_that("sens_b(7, 3, threshold=20) reports baseline failure", {
  shiny::testServer(app = app_dir, expr = {
    session$setInputs(
      y_W = 7, y_R = 3, threshold = 20,
      theta_cut = 0.5, prior_a = 1, prior_b = 1
    )
    res <- sens_b()
    expect_equal(res$omega_star, 0)
    expect_equal(res$M_star, 0L)
  })
})

test_that("sens_b(7, 3, threshold=5) yields a real omega_star > 1", {
  shiny::testServer(app = app_dir, expr = {
    session$setInputs(
      y_W = 7, y_R = 3, threshold = 5,
      theta_cut = 0.5, prior_a = 1, prior_b = 1
    )
    res <- sens_b()
    expect_gt(res$omega_star, 1)
    expect_false(is.na(res$omega_star))
  })
})

test_that("sens_b(10, 0, threshold=20)$M_star is a positive integer", {
  shiny::testServer(app = app_dir, expr = {
    session$setInputs(
      y_W = 10, y_R = 0, threshold = 20,
      theta_cut = 0.5, prior_a = 1, prior_b = 1
    )
    res <- sens_b()
    expect_gt(res$M_star, 0L)
    expect_false(is.na(res$M_star))
  })
})

test_that("tipping_text for (7, 3, 20) carries the urn's ~30% prose", {
  shiny::testServer(app = app_dir, expr = {
    session$setInputs(
      y_W = 7, y_R = 3, threshold = 20,
      theta_cut = 0.5, prior_a = 1, prior_b = 1
    )
    txt <- as.character(output$tipping_text)
    expect_match(txt, "30", fixed = TRUE, all = FALSE)
    expect_match(txt, "%", fixed = TRUE, all = FALSE)
  })
})

test_that("tipping_text for (7, 3, 20) signals binomial baseline failure", {
  shiny::testServer(app = app_dir, expr = {
    session$setInputs(
      y_W = 7, y_R = 3, threshold = 20,
      theta_cut = 0.5, prior_a = 1, prior_b = 1
    )
    expect_match(
      as.character(output$tipping_text),
      "baseline|below threshold",
      ignore.case = TRUE, all = FALSE
    )
  })
})
