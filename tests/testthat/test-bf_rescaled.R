# Substantive tests for bf_rescaled, the uniform-weights Bayes factor
# computed under weights the researcher states instead of the uniform
# default. Ported from the paper repository's tests/test_bf_rescaled.R.
#
# The researcher has to say how she spreads her weight over the shares
# inside each theory's range, because a range of shares is not a
# probability for her counts. The paper's default gives every share in a
# range the same weight. The alternative it offers takes a Beta(a, b)
# distribution, which lives on the interval from zero to one, and
# squeezes it onto each theory's half:
#
#   theta = 1/2 + X/2 for the working theory,  theta = X/2 for the rival,
#
# where X has the Beta(a, b) distribution. Squeezing an interval to half
# its width doubles the density, which is where the factor of 2 in the
# rescaled densities comes from. Setting a = b = 1 on both sides
# recovers the uniform default.
#
# The parameters mean something the researcher can argue about. With
# a = b above one the weight piles up in the middle of each half, so the
# working theory predicts a share near three quarters and the rival a
# share near one quarter, and the two theories predict more different
# things. With a = b below one the weight piles up at both ends of each
# half, including right next to one half, where the two theories predict
# nearly the same thing.
#
# Sources: Paper/evalues.qmd (sec-two-bfs) and Paper/appendix.qmd
# (sec-choosing-distributions), and the applications tables in both,
# which print the Beta(1/2, 1/2) column beside the uniform default.

test_that("each rescaled density is a distribution on its own half", {
  # A density that did not integrate to one over the half it lives on
  # would not be a weighting at all.
  for (ab in list(c(1, 1), c(0.5, 0.5), c(10, 10), c(1, 0.5), c(0.5, 1),
                  c(2, 5))) {
    a <- ab[1]
    b <- ab[2]
    expect_equal(
      stats::integrate(.d_rescaled_W, 0.5, 1, a = a, b = b)$value, 1,
      tolerance = 1e-6, info = sprintf("working theory, Beta(%g, %g)", a, b))
    expect_equal(
      stats::integrate(.d_rescaled_R, 0, 0.5, a = a, b = b)$value, 1,
      tolerance = 1e-6, info = sprintf("rival, Beta(%g, %g)", a, b))
  }
})

test_that("the rescaled densities match the closed forms the supplement prints", {
  # Checking the code against the formula in the paper, so that a reader
  # who works out the algebra by hand meets the same function.
  for (ab in list(c(1, 1), c(0.5, 0.5), c(10, 10), c(1, 0.5), c(0.5, 1),
                  c(2, 5))) {
    a <- ab[1]
    b <- ab[2]
    th_W <- c(0.6, 0.75, 0.9)
    expect_equal(
      .d_rescaled_W(th_W, a, b),
      2^b * (2 * th_W - 1)^(a - 1) * (1 - th_W)^(b - 1) / beta(a, b),
      info = sprintf("working theory, Beta(%g, %g)", a, b))
    th_R <- c(0.1, 0.25, 0.4)
    expect_equal(
      .d_rescaled_R(th_R, a, b),
      2^a * th_R^(a - 1) * (1 - 2 * th_R)^(b - 1) / beta(a, b),
      info = sprintf("rival, Beta(%g, %g)", a, b))
  }
})

test_that("uniform weights on both sides recover the uniform-weights Bayes factor", {
  # bf_rescaled() integrates; bf_uniform_weights() uses the closed form
  # that the uniform case allows. They must agree at every count, or the
  # default is not the default the paper says it is.
  for (n in c(5, 12, 21)) {
    for (y_W in 0:n) {
      y_R <- n - y_W
      expect_equal(bf_rescaled(y_W, y_R), bf_uniform_weights(y_W, y_R),
                   tolerance = 1e-7,
                   info = sprintf("y_W = %d, y_R = %d", y_W, y_R))
    }
  }
  expect_equal(round(bf_rescaled(9, 3), 2), 20.67)
})

test_that("the two weightings the paper quotes at nine of twelve reproduce", {
  # Beta(1/2, 1/2) on each half puts weight next to one half, where the
  # two theories claim nearly the same share, so the counts discriminate
  # less and the value falls from 20.67 to 9.53. Beta(10, 10) on each
  # half pushes the two claims apart, toward three quarters and one
  # quarter, so the counts discriminate more and the value rises to
  # 252.92. The weights are a substantive choice and they move the
  # number: this is the fact the paper's sensitivity discussion rests on.
  expect_equal(round(bf_rescaled(9, 3, a1 = 0.5, b1 = 0.5,
                                 aR = 0.5, bR = 0.5), 2), 9.53)
  expect_equal(round(bf_rescaled(9, 3, a1 = 10, b1 = 10,
                                 aR = 10, bR = 10), 2), 252.92)
  expect_lt(bf_rescaled(9, 3, 0.5, 0.5, 0.5, 0.5), bf_rescaled(9, 3))
  expect_gt(bf_rescaled(9, 3, 10, 10, 10, 10), bf_rescaled(9, 3))
})

test_that("the applications table's Beta(1/2, 1/2) column reproduces", {
  # The six studies, in the order the supplement's table prints them.
  # These numbers are in print, so a change to the integration has to
  # break a test rather than a table.
  studies <- list(
    list(name = "Steinsson (2023)",                y_W = 12, y_R = 0,
         jeffreys = 6219.2),
    list(name = "Winward (2020)",                  y_W = 14, y_R = 3,
         jeffreys = 91.6),
    list(name = "Hammoud-Gallego & Freier (2022)", y_W = 10, y_R = 3,
         jeffreys = 14.4),
    list(name = "Mor (2022)",                      y_W =  8, y_R = 2,
         jeffreys = 13.7),
    list(name = "Andersen (2023)",                 y_W =  9, y_R = 3,
         jeffreys = 9.5),
    list(name = "Pavone & Stiansen (2021)",        y_W =  7, y_R = 4,
         jeffreys = 2.7)
  )
  for (s in studies) {
    expect_equal(round(bf_rescaled(s$y_W, s$y_R, 0.5, 0.5, 0.5, 0.5), 1),
                 s$jeffreys, info = s$name)
  }
  # Which studies clear a threshold of 20 is the substantive reading of
  # the column: only Steinsson and Winward do, so for the other four the
  # conclusion at 20 was carried by the uniform weights rather than by
  # the counts alone.
  jeff <- vapply(studies,
                 function(s) bf_rescaled(s$y_W, s$y_R, 0.5, 0.5, 0.5, 0.5),
                 numeric(1))
  expect_equal(jeff >= 20, c(TRUE, TRUE, FALSE, FALSE, FALSE, FALSE))
})

test_that("the two sides can be weighted differently", {
  # The supplement's two examples. A researcher who thinks that under
  # either theory she would still find evidence for the other one puts
  # both densities next to one half, which weakens what her counts can
  # show. A researcher who thinks each theory would leave almost no
  # evidence for the other pushes both densities to the far ends, which
  # strengthens it.
  toward_half <- bf_rescaled(9, 3, a1 = 0.5, b1 = 1, aR = 1, bR = 0.5)
  toward_ends <- bf_rescaled(9, 3, a1 = 1, b1 = 0.5, aR = 0.5, bR = 1)
  expect_lt(toward_half, bf_rescaled(9, 3))
  expect_gt(toward_ends, bf_rescaled(9, 3))
})

test_that("input validation rejects nonsense", {
  expect_error(bf_rescaled(-1, 3))
  expect_error(bf_rescaled(9.5, 3))
  expect_error(bf_rescaled(9, 3, a1 = 0))
  expect_error(bf_rescaled(9, 3, bR = -1))
})
