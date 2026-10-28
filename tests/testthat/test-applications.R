# Real-data regression tests from the six published process-tracing
# studies reanalyzed in Lopez, Bowers, and Gajardo Cooper (2026).
#
# The counts are the agreed codings in the paper repository's
# replications/<study>/results.csv. Hammoud-Gallego and Freier moved
# from (10, 3) to (11, 2) on 2026-08-30, when their null result on
# emigrant numbers was counted against a rival predictor. Every number
# pinned here is one the paper prints, so a change to the package that
# moved any of them has to break a test rather than a table.
#
# The studies also cover a useful spread of inputs: no rival evidence
# (Steinsson, y_R = 0), a uniform-weights value barely above 20
# (Andersen), and counts that fail the rule as coded (Pavone and
# Stiansen).
#
# Sources: Paper/evalues.qmd (tbl-app-summary and the chunk
# app-text-numbers); Paper/appendix.qmd (the six study subsections);
# the replications' sensitivity_axes.csv files (share_weights rows).

apps <- list(
  list(name = "Steinsson (2023)",                y_W = 12, y_R = 0,
       uw = 8191,      wc = 630.08, omega_star = 5.49, x_star = 4L,
       uw_jeff = 6219.2, wc_jeff = 956.92, uw_10 = 86511, wc_10 = 180.19),
  list(name = "Winward (2020)",                  y_W = 14, y_R = 3,
       uw = 264.328,   wc = 21.34,  omega_star = 1.74, x_star = 2L,
       uw_jeff = 91.6,   wc_jeff = 15.19,  uw_10 = 15795, wc_10 = 34.53),
  list(name = "Hammoud-Gallego & Freier (2022)", y_W = 11, y_R = 2,
       uw = 153.566,   wc = 14.91,  omega_star = 1.70, x_star = 2L,
       uw_jeff = 60.3,   wc_jeff = 11.04,  uw_10 = 3917,  wc_10 = 21.15),
  list(name = "Mor (2022)",                      y_W =  8, y_R = 2,
       uw = 29.5672,   wc = 4.00,   omega_star = 1.14, x_star = 1L,
       uw_jeff = 13.7,   wc_jeff = 3.02,   uw_10 = 298,   wc_10 = 6.03),
  list(name = "Andersen (2023)",                 y_W =  9, y_R = 3,
       uw = 20.672,    wc = 2.73,   omega_star = 1.01, x_star = 1L,
       uw_jeff = 9.5,    wc_jeff = 2.07,   uw_10 = 253,   wc_10 = 4.38),
  list(name = "Pavone & Stiansen (2021)",        y_W =  7, y_R = 4,
       uw = 4.15869,   wc = 0.83,   omega_star = 0,    x_star = 0L,
       uw_jeff = 2.7,    wc_jeff = 0.74,   uw_10 = 16,    wc_10 = 1.02)
)

for (a in apps) {
  local({
    a <- a
    test_that(sprintf("%s: both Bayes factors match the published values", a$name), {
      expect_equal(bf_uniform_weights(a$y_W, a$y_R), a$uw, tolerance = 1e-4)
      expect_equal(round(bf_worst_case(a$y_W, a$y_R), 2), a$wc,
                   tolerance = 0.005)
    })

    test_that(sprintf("%s: the bias and coding tipping points match", a$name), {
      # The applications table prints omega-star to two decimals; the
      # supplement's study subsections report the coding tipping point.
      expect_equal(round(sens_bias(a$y_W, a$y_R)$omega_star, 2), a$omega_star)
      expect_identical(sens_coding(a$y_W, a$y_R)$x_star, a$x_star)
    })

    test_that(sprintf("%s: the values under other weights on theta match", a$name), {
      # The share_weights rows of the study's sensitivity table:
      # Beta(1/2, 1/2) and Beta(10, 10) rescaled onto each half, on both
      # sides for the uniform-weights value and on the working theory's
      # side for the worst-case value.
      expect_equal(round(bf_rescaled(a$y_W, a$y_R, 0.5, 0.5, 0.5, 0.5), 1),
                   a$uw_jeff)
      expect_equal(round(bf_worst_case(a$y_W, a$y_R, a1 = 0.5, b1 = 0.5), 2),
                   a$wc_jeff)
      expect_equal(round(bf_rescaled(a$y_W, a$y_R, 10, 10, 10, 10)),
                   a$uw_10)
      expect_equal(round(bf_worst_case(a$y_W, a$y_R, a1 = 10, b1 = 10), 2),
                   a$wc_10)
    })
  })
}

test_that("the bias rows of the six study tables reproduce", {
  # Each study's table in the supplement has a row with the bias factor
  # at 2 and at 5. These are the worst-case values in that row with the
  # rival at its best share, as decided on 2026-10-27. Five cells differ
  # from the values the paper printed with the rival held at one half:
  # Andersen at 5 (0.28), Mor at 5 (0.41), Winward at 5 (0.38), and
  # Pavone and Stiansen at 2 (0.33) and 5 (0.18). In each of those cells
  # the bias passes y_W / y_R.
  cells <- list(
    list(y_W = 12, y_R = 0, om2 = 35.02972083, om5 = 4.39384034),
    list(y_W = 14, y_R = 3, om2 = 1.65053141,  om5 = 0.37395586),
    list(y_W = 11, y_R = 2, om2 = 1.86511523,  om5 = 0.51370533),
    list(y_W =  8, y_R = 2, om2 = 1.00674494,  om5 = 0.39939620),
    list(y_W =  9, y_R = 3, om2 = 0.66612932,  om5 = 0.21461247),
    list(y_W =  7, y_R = 4, om2 = 0.32362482,  om5 = 0.05347840)
  )
  for (cl in cells) {
    expect_equal(bf_worst_case(cl$y_W, cl$y_R, omega = 2), cl$om2,
                 tolerance = 1e-6)
    expect_equal(bf_worst_case(cl$y_W, cl$y_R, omega = 5), cl$om5,
                 tolerance = 1e-6)
  }
})

test_that("the rule sets the rival aside in five of the six studies", {
  # Main paper, section 5: every study but Pavone and Stiansen has a
  # uniform-weights value of 20 or more and a worst-case value above 1,
  # and for Steinsson and Winward even the worst-case value is above 20.
  uw <- vapply(apps, function(a) bf_uniform_weights(a$y_W, a$y_R), numeric(1))
  wc <- vapply(apps, function(a) bf_worst_case(a$y_W, a$y_R), numeric(1))
  meets <- uw >= 20 & wc > 1
  expect_equal(meets, c(TRUE, TRUE, TRUE, TRUE, TRUE, FALSE))
  expect_equal(wc > 20, c(TRUE, TRUE, FALSE, FALSE, FALSE, FALSE))
})

test_that("Pavone and Stiansen's letter changes the decision at a weight of five", {
  # The letter is one of the seven pro-working-theory observations, so a
  # weight of w gives weighted counts 6 + w and 4. At weight 4 the
  # uniform-weights value is 15.88, below 20; at weight 5 the two values
  # are 25.04 and 2.89, which meet the rule; at weight 10, the weight the
  # applications table uses, they are 277 and 20.54, and the decision
  # changes at a bias of 1.67.
  meets_at <- function(w) {
    bf_uniform_weights(6 + w, 4) >= 20 && bf_worst_case(6 + w, 4) > 1
  }
  meets <- vapply(1:10, meets_at, logical(1))
  expect_identical(min(which(meets)), 5L)
  expect_true(all(meets[5:10]))
  expect_equal(round(bf_uniform_weights(10, 4), 2), 15.88)
  expect_equal(round(c(bf_uniform_weights(11, 4), bf_worst_case(11, 4)), 2),
               c(25.04, 2.89))
  expect_equal(round(bf_uniform_weights(16, 4)), 277)
  expect_equal(round(bf_worst_case(16, 4), 2), 20.54)
  expect_equal(round(sens_bias(16, 4)$omega_star, 2), 1.67)
})

test_that("the three studies with values in the hundreds all tip near 1.7", {
  # The paper's closing paragraph on the table: Winward, Hammoud-Gallego
  # and Freier, and Pavone and Stiansen with the letter at weight ten
  # have uniform-weights values of 264, 154, and 277, and each decision
  # changes at a bias between 1.6 and 1.8.
  om <- vapply(list(c(14, 3), c(11, 2), c(16, 4)),
               function(y) sens_bias(y[1], y[2])$omega_star, numeric(1))
  expect_true(all(om > 1.6 & om < 1.8))
})
