# Tests for the app helpers that serve the worst-case Bayes factor and
# the picture of where both Bayes factors come from.
#
# The app now shows two Bayes factors computed from one model. They
# share a numerator, the probability of the counts averaged over the
# shares above one half, and they differ in the denominator: one
# averages over the rival's whole range of shares, the other takes her
# best single share, one half. bf_decomposition() computes all three
# probabilities at every count the researcher might have reported, which
# is what lets the app draw the two divisions rather than assert them.
#
# These live in their own file because test-app_helpers.R is at the
# 300-line mark.

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
  # The dark bars are one probability distribution over the counts, so
  # they sum to one. The other two columns do not: they are averages of
  # a probability, not probabilities of the counts.
  df <- bf_decomposition(9, 3)
  expect_equal(sum(df$den_half), 1, tolerance = 1e-12)
  expect_equal(df$den_half, stats::dbinom(0:12, 12, 0.5), tolerance = 1e-12)
})


# ---- interpret_separation ----------------------------------------------
#
# When the worst-case Bayes factor is below the researcher's threshold,
# what she reports beside it is the separation: how far apart the two
# theories' claims would have to be before her counts reach that
# threshold. separation_g() returns NA when the counts do not favor the
# working theory, because then no separation reaches a threshold above
# one, and the prose has to say so rather than print NA.

test_that("interpret_separation names both shares and the threshold", {
  out <- interpret_separation(0.123, threshold = 20)
  expect_type(out, "character")
  # 0.5 + g and 0.5 - g, as percentages, which is how the paper reads
  # the separation aloud.
  expect_match(out, "62.3", fixed = TRUE)
  expect_match(out, "37.7", fixed = TRUE)
  expect_match(out, "20", fixed = TRUE)
})

test_that("interpret_separation reports the threshold it was given", {
  out <- interpret_separation(0.2, threshold = 100)
  expect_match(out, "100", fixed = TRUE)
  expect_match(out, "70", fixed = TRUE)
  expect_match(out, "30", fixed = TRUE)
})

test_that("interpret_separation says plainly when there is no separation", {
  out <- interpret_separation(NA_real_, threshold = 20)
  expect_type(out, "character")
  expect_match(out, "no separation", ignore.case = TRUE)
  expect_false(grepl("NA", out, fixed = TRUE))
})
