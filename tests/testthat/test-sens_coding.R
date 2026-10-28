# Substantive tests for sens_coding(), sensitivity to coding error.
#
# A peer cannot re-read every document the way the researcher did, so
# the coding of any one observation can be disputed but not settled at
# a distance. What a peer can compute is how many re-codings would
# change the decision. Re-coding x observations relabels x
# pro-working-theory observations as pro-rival, moving the counts from
# (y_W, y_R) to (y_W - x, y_R + x); the number of observations stays
# the same.
#
# The paper's rule sets the rival aside when the uniform-weights Bayes
# factor is 20 or more and the worst-case Bayes factor is above 1. The
# supplement reports the smallest number of re-codings at which either
# condition fails. sens_coding() returns the number at which each
# condition fails and the smaller of the two.
#
# Sources: Paper/appendix.qmd, sec-sens-coding (the chunk that defines
# coding_sens() and sens_coding_bounded()).

test_that("one re-coding changes the decision in the running example", {
  # Nine of twelve. One re-coding gives eight of twelve, where the
  # uniform-weights value is below 20. The worst-case value falls to 1
  # or below only after two re-codings: 1.10 at eight of twelve, 0.56 at
  # seven.
  s <- sens_coding(9, 3)
  expect_equal(s$x_uniform, 1L)
  expect_equal(s$x_worst, 2L)
  expect_equal(s$x_star, 1L)
  expect_gte(bf_uniform_weights(9, 3), 20)
  expect_lt(bf_uniform_weights(8, 4), 20)
  expect_equal(round(bf_worst_case(8, 4), 2), 1.10)
  expect_equal(round(bf_worst_case(7, 5), 2), 0.56)
  expect_equal(s$bf_uniform, bf_uniform_weights(9, 3))
  expect_equal(s$bf_worst, bf_worst_case(9, 3))
})

test_that("each tipping point is the smallest re-coding at which its condition fails", {
  # The definition, computed independently by scanning re-codings.
  first_fail <- function(y_W, y_R, fails) {
    for (x in 0:y_W) if (fails(y_W - x, y_R + x)) return(as.integer(x))
    NA_integer_
  }
  for (y in list(c(9, 3), c(12, 2), c(18, 3), c(10, 0), c(14, 3), c(30, 10))) {
    s <- sens_coding(y[1], y[2])
    x_u <- first_fail(y[1], y[2], function(a, b) bf_uniform_weights(a, b) < 20)
    x_w <- first_fail(y[1], y[2], function(a, b) bf_worst_case(a, b) <= 1)
    expect_identical(s$x_uniform, x_u)
    expect_identical(s$x_worst, x_w)
    expect_identical(s$x_star, min(x_u, x_w))
  }
})

test_that("the two conditions treat a value equal to the threshold differently", {
  # The rule asks for a uniform-weights value of 20 or more, so a value
  # exactly at the threshold still meets it, and for a worst-case value
  # above 1, so a value exactly at its threshold does not. Setting each
  # threshold to the value one re-coding produces shows the difference:
  # at x = 1 the uniform-weights condition still holds and the
  # worst-case condition already fails.
  s <- sens_coding(9, 3,
                   threshold_uniform = bf_uniform_weights(8, 4),
                   threshold_worst = bf_worst_case(8, 4))
  expect_equal(s$x_uniform, 2L)
  expect_equal(s$x_worst, 1L)
  expect_equal(s$x_star, 1L)
})

test_that("counts that already fail the rule need no re-coding", {
  # Pavone and Stiansen's seven of eleven fails both conditions as
  # coded. Seven of ten fails only the uniform-weights one, and that is
  # enough for the rule to keep the rival.
  s <- sens_coding(7, 4)
  expect_identical(c(s$x_uniform, s$x_worst, s$x_star), c(0L, 0L, 0L))
  s <- sens_coding(7, 3)
  expect_identical(s$x_uniform, 0L)
  expect_gt(s$x_worst, 0L)
  expect_identical(s$x_star, 0L)
})

test_that("re-coding never helps the working theory", {
  # Relabeling a pro-working-theory observation as pro-rival lowers both
  # values, which is why the first re-coding at which a condition fails
  # is the only one to report: every later re-coding fails it too.
  uw <- vapply(0:9, function(x) bf_uniform_weights(9 - x, 3 + x), numeric(1))
  wc <- vapply(0:9, function(x) bf_worst_case(9 - x, 3 + x), numeric(1))
  expect_true(all(diff(uw) < 0))
  expect_true(all(diff(wc) < 0))
})

test_that("the function no longer offers separate models or a cutpoint", {
  # The urn model, the separation table, and the cutpoint are gone with
  # the parts of the paper that used them. The two thresholds are the
  # only settings.
  expect_identical(names(formals(sens_coding)),
                   c("y_W", "y_R", "threshold_uniform", "threshold_worst"))
})

test_that("input validation rejects nonsense", {
  expect_error(sens_coding(-1, 3))
  expect_error(sens_coding(3, -1))
  expect_error(sens_coding(0, 0))
  expect_error(sens_coding(9.5, 3))
  expect_error(sens_coding(9, 3, threshold_uniform = 0))
  expect_error(sens_coding(9, 3, threshold_worst = -1))
})
