# Tests for bf_decomposition(), the data behind the Result tab's picture
# of where both Bayes factors come from.
#
# The app shows two Bayes factors computed from one model. They share a
# numerator, the probability of the counts averaged over the shares
# above one half, and they differ in the denominator: one averages over
# the rival's whole range of shares, the other evaluates the rival at a
# share of one half. bf_decomposition() computes all three probabilities
# at every count the researcher might have reported, which is what lets
# the app draw the two divisions rather than assert them.

helpers_path <- system.file("shiny/R/helpers.R", package = "DrWrinch")
if (!nzchar(helpers_path) || !file.exists(helpers_path)) {
  stop("Expected inst/shiny/R/helpers.R but did not find it.")
}
source(helpers_path, local = TRUE)
source(file.path(dirname(helpers_path), "curves.R"), local = TRUE)


# ---- bf_decomposition --------------------------------------------------

test_that("bf_decomposition has one row per count the researcher could report", {
  df <- bf_decomposition(9, 3)
  expect_equal(nrow(df), 13L)
  expect_equal(df$k, 0:12)
  expect_named(df, c("k", "numerator", "den_avg", "den_half"))
})

test_that("the numerator over the half-share denominator is the worst-case BF", {
  # The claim the picture makes: at each count, the light bar divided by
  # the dark bar is the worst-case Bayes factor. If this ever stopped
  # holding, the app would be drawing one thing and reporting another.
  for (n in c(12, 17, 20)) {
    df <- bf_decomposition(n, 0)
    expect_equal(
      df$numerator / df$den_half,
      vapply(df$k, function(k) DrWrinch::bf_worst_case(k, n - k), numeric(1)),
      tolerance = 1e-8, info = sprintf("N = %d", n)
    )
  }
})

test_that("the numerator over the averaged denominator is the uniform-weights BF", {
  df <- bf_decomposition(9, 3)
  expect_equal(
    df$numerator / df$den_avg,
    vapply(df$k, function(k) DrWrinch::bf_uniform_weights(k, 12 - k),
           numeric(1)),
    tolerance = 1e-7
  )
  # The two numbers the Result tab shows, read off the same three bars.
  observed <- df[df$k == 9, ]
  expect_equal(round(observed$numerator / observed$den_avg, 2), 20.67)
  expect_equal(round(observed$numerator / observed$den_half, 2), 2.73)
})

test_that("the two averaged probabilities partition the shares", {
  # Every count has probability 1/(N+1) when averaged over all shares
  # from zero to one. The two columns average over the two halves and
  # each doubles its integral, so together they come to 2/(N+1) at every
  # count. This catches a rescaling error in either column on its own.
  for (n in c(5, 12, 21)) {
    df <- bf_decomposition(n, 0)
    expect_equal(df$numerator + df$den_avg, rep(2 / (n + 1), n + 1),
                 tolerance = 1e-8, info = sprintf("N = %d", n))
  }
})

test_that("the half-share column is the binomial distribution at one half", {
  # The dark bars are the probabilities of the counts when the share is
  # exactly one half, the Binomial(N, 1/2) distribution, so they sum to
  # one.
  df <- bf_decomposition(9, 3)
  expect_equal(sum(df$den_half), 1, tolerance = 1e-12)
  expect_equal(df$den_half, stats::dbinom(0:12, 12, 0.5), tolerance = 1e-12)
})
