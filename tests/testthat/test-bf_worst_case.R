# Substantive tests for the worst-case Bayes factor.
#
# The model behind both Bayes factors in this package is the same one:
# each observation supports the working theory with probability theta,
# the share of the evidence that supports it. The working theory claims
# theta > 1/2 and the rival claims theta <= 1/2. The numerator is shared
# --- the binomial probability of the counts averaged over the shares
# above one half under the working theory's weights. bf_worst_case()
# divides it by the probability of the counts at a share of one half,
# which, when at least as many observations favor the working theory as
# the rival, is the largest probability any weights on the rival's
# shares can give. So the value is the smallest Bayes factor a critic
# can produce by changing only the rival's weights.
#
# The paper's rule sets the rival aside when the uniform-weights Bayes
# factor is 20 or more and this value is above 1. Above 1 means no
# weights on the rival's shares make the counts more probable under the
# rival than under the working theory.
#
# Sources: Paper/evalues.qmd (sec-two-bfs, sec-decide and its
# worst-binds footnote, sec-sensitivity); Paper/appendix.qmd
# (thm-closed-form, prp-bound, thm-error-rate, sec-sens-bias); the
# paper repository's tests/test_bf_bounded.R, tests/test_bf_rescaled.R
# section 9, and tests/bf_weighted.R (worst_bf_weighted).

# ---- the closed form and the running example ---------------------------

test_that("the closed form equals the averaged-over-shares definition", {
  # bf_worst_case() computes a ratio of binomial coefficients rather
  # than an integral. The definition divides the probability of the
  # counts averaged over the shares above one half by the probability at
  # a share of exactly one half. Averaging under uniform weights on an
  # interval of width one half means multiplying the integral by 2.
  for (N in c(2, 5, 12, 21)) {
    for (k in 0:N) {
      by_integral <- 2 * stats::integrate(
        function(t) stats::dbinom(k, N, t), 0.5, 1
      )$value / stats::dbinom(k, N, 0.5)
      expect_equal(bf_worst_case(k, N - k), by_integral, tolerance = 1e-8,
                   info = sprintf("N = %d, y_W = %d", N, k))
    }
  }
})

test_that("nine of twelve gives 7814/2860, the paper's running example", {
  # The ten coefficients choose(13, 0:9) add to 7814, and 13 * 220 =
  # 2860, so the value is an exact fraction a reader can check by hand.
  expect_equal(sum(choose(13, 0:9)), 7814)
  expect_equal(bf_worst_case(9, 3), 7814 / 2860, tolerance = 1e-12)
  expect_equal(round(bf_worst_case(9, 3), 2), 2.73)
})

test_that("weighting the memo at ten gives 143.3", {
  # Weighted counts 8 + 10 = 18 and 3. Pavone and Stiansen's letter at
  # weight ten gives 6 + 10 = 16 and 4.
  expect_equal(round(bf_worst_case(18, 3), 1), 143.3)
  expect_equal(round(bf_worst_case(16, 4), 1), 20.5)
})

test_that("counts favoring the working theory can still fall below one", {
  # Seven of twelve gives 0.56: those counts are more probable at a
  # share of one half than averaged over the shares the working theory
  # claims, so a rival who may claim an even split is not embarrassed by
  # them, and the paper's rule keeps the rival.
  expect_equal(round(bf_worst_case(7, 5), 2), 0.56)
  expect_true(is.finite(bf_worst_case(0, 12)))
  expect_gt(bf_worst_case(0, 12), 0)
})

# ---- the lower bound ----------------------------------------------------

test_that("no weights on the rival's shares give a smaller value", {
  # prp-bound. When y_W >= y_R the probability of the counts rises on
  # the whole of [0, 1/2], so every share the rival claims gives the
  # counts at most the probability at one half. Any weighted average of
  # those probabilities is therefore at most that, and dividing the same
  # numerator by it gives at least the worst-case value. The four rival
  # weightings are the ones the supplement used: uniform on [0, 1/2], a
  # point mass at 0.4, uniform on [0.4, 0.5], and the point mass at one
  # half itself.
  num <- 2 * stats::integrate(function(t) stats::dbinom(9, 12, t),
                              0.5, 1)$value
  dens <- c(
    2 * stats::integrate(function(t) stats::dbinom(9, 12, t), 0, 0.5)$value,
    stats::dbinom(9, 12, 0.4),
    10 * stats::integrate(function(t) stats::dbinom(9, 12, t), 0.4, 0.5)$value,
    stats::dbinom(9, 12, 0.5)
  )
  bfs <- num / dens
  expect_true(all(bfs >= bf_worst_case(9, 3) - 1e-12))
  expect_equal(round(bfs, 2), c(20.67, 11.78, 4.97, 2.73))
})

test_that("nine of twelve cannot be pushed past the 4.81 ceiling", {
  # With the rival at one half, no weights on the working theory's
  # shares give more than the point mass on the share that fits the
  # counts best, nine twelfths: dbinom(9, 12, 3/4) / dbinom(9, 12, 1/2).
  ceiling_9_3 <- stats::dbinom(9, 12, 0.75) / stats::dbinom(9, 12, 0.5)
  expect_equal(round(ceiling_9_3, 2), 4.81)
  expect_lt(bf_worst_case(9, 3), ceiling_9_3)
})

# ---- the rule's second condition ---------------------------------------

test_that("below 101 observations the second condition never changes the rule", {
  # The worst-binds footnote of the main paper. With fewer than 101
  # observations, every count whose uniform-weights Bayes factor is 20
  # or more also has a worst-case value above 1. With 101 observations
  # the two conditions disagree at exactly one count, 59 of 101, where
  # the values are 20.78 and 0.98.
  conflict <- function(N) {
    k <- 0:N
    uw <- vapply(k, function(j) bf_uniform_weights(j, N - j), numeric(1))
    wc <- vapply(k, function(j) bf_worst_case(j, N - j), numeric(1))
    k[uw >= 20 & wc <= 1]
  }
  for (N in 1:100) {
    expect_length(conflict(N), 0)
  }
  expect_identical(conflict(101), 59L)
  expect_equal(round(bf_uniform_weights(59, 42), 2), 20.78)
  expect_equal(round(bf_worst_case(59, 42), 2), 0.98)
})

# ---- the error-rate property of the statistic ---------------------------

test_that("the statistic averages exactly one when the evidence is split evenly", {
  # thm-error-rate in the supplement. At a share of one half, across
  # repeated samples, the worst-case value averages to exactly one, so
  # it reaches a threshold t at most one time in t.
  for (N in c(2, 5, 12)) {
    lam <- vapply(0:N, function(k) bf_worst_case(k, N - k), numeric(1))
    expect_equal(sum(stats::dbinom(0:N, N, 0.5) * lam), 1,
                 tolerance = 1e-10, info = sprintf("N = %d", N))
  }
})

test_that("the average falls below one at every smaller share", {
  lam12 <- vapply(0:12, function(k) bf_worst_case(k, 12 - k), numeric(1))
  for (s in c(0.1, 0.25, 0.4, 0.49)) {
    expect_lt(sum(stats::dbinom(0:12, 12, s) * lam12), 1)
  }
})

test_that("the average stays at most one under draws without replacement", {
  # Twelve documents drawn without replacement from a collection of M,
  # K1 of which support the working theory, with K1 at most M / 2 as the
  # rival claims. The theorem holds at every collection size, which is
  # why the supplement never has to name one.
  lam12 <- vapply(0:12, function(k) bf_worst_case(k, 12 - k), numeric(1))
  for (M in c(12, 13, 24, 60, 240)) {
    for (K1 in seq_len(floor(M / 2))) {
      avg <- sum(stats::dhyper(0:12, K1, M - K1, 12) * lam12)
      expect_lte(avg, 1 + 1e-12)
    }
  }
  # The step of the proof that uses Hoeffding's result needs the
  # statistic to rise by increasing steps as the count rises.
  expect_true(all(diff(diff(lam12)) > 0))
})

# ---- stated weights on the working theory's side ------------------------

test_that("stated weights enter only the numerator", {
  # The rival is evaluated at one half whatever weights its proponent
  # might state, so only the working theory's weights can enter: a
  # Beta(a1, b1) rescaled onto (1/2, 1). The value is the numerator of
  # bf_rescaled() under those weights over the probability at one half.
  d_W <- function(t, a, b) 2 * stats::dbeta(2 * t - 1, a, b)
  for (ab in list(c(0.5, 0.5), c(10, 10), c(1, 0.5), c(0.5, 1))) {
    num <- stats::integrate(
      function(t) stats::dbinom(9, 12, t) * d_W(t, ab[1], ab[2]), 0.5, 1
    )$value
    expect_equal(bf_worst_case(9, 3, a1 = ab[1], b1 = ab[2]),
                 num / stats::dbinom(9, 12, 0.5), tolerance = 1e-7,
                 info = sprintf("Beta(%g, %g)", ab[1], ab[2]))
  }
  # The uniform pair is the default and reproduces the closed form.
  for (kr in list(c(9, 3), c(12, 0), c(14, 3), c(7, 4), c(5, 5))) {
    expect_equal(bf_worst_case(kr[1], kr[2], a1 = 1, b1 = 1),
                 bf_worst_case(kr[1], kr[2]), tolerance = 1e-7)
  }
})

test_that("the two weightings the replications print at nine of twelve reproduce", {
  # Beta(1/2, 1/2) rescaled puts weight next to one half, where the
  # working theory predicts nearly what the rival does, and the value
  # falls; Beta(10, 10) concentrates the working theory near three
  # quarters, where nine of twelve is most probable, and it rises.
  expect_equal(round(bf_worst_case(9, 3, a1 = 0.5, b1 = 0.5), 2), 2.07)
  expect_equal(round(bf_worst_case(9, 3, a1 = 10, b1 = 10), 2), 4.38)
  # No weights on the working theory's side pass the 4.81 ceiling, and
  # with uniform weights on the rival's side added back the value can
  # only rise (prp-bound with the same working-theory weights).
  ceiling_9_3 <- stats::dbinom(9, 12, 0.75) / stats::dbinom(9, 12, 0.5)
  for (ab in list(c(1, 1), c(0.5, 0.5), c(10, 10), c(1, 0.5), c(0.5, 1),
                  c(50, 50))) {
    v <- bf_worst_case(9, 3, a1 = ab[1], b1 = ab[2])
    expect_lt(v, ceiling_9_3)
    expect_lte(v, bf_rescaled(9, 3, ab[1], ab[2], 1, 1) + 1e-9)
  }
})

# ---- a biased search ------------------------------------------------------

test_that("a biased search tilts the numerator and moves the rival to its best share", {
  # A search omega times as likely to find a pro-working-theory
  # observation turns a share theta into omega theta / (omega theta + 1 -
  # theta) among the observations found. The numerator averages the
  # binomial probability of the counts at the tilted share over the
  # working theory's shares. The denominator is the largest probability
  # any of the rival's shares can give the counts. The rival's shares,
  # those at or below one half, become shares found of at most
  # omega / (1 + omega), and the counts are most probable at a share found
  # of y_W / N. So the denominator is the probability at y_W / N when the
  # rival can reach it and at omega / (1 + omega) when it cannot.
  tilt <- function(t, om) om * t / (om * t + 1 - t)
  for (om in c(0.5, 1.5, 2, 5)) {
    num <- 2 * stats::integrate(
      function(t) stats::dbinom(9, 12, tilt(t, om)), 0.5, 1)$value
    den <- stats::dbinom(9, 12, min(om / (1 + om), 9 / 12))
    expect_equal(bf_worst_case(9, 3, omega = om), num / den,
                 tolerance = 1e-8, info = sprintf("omega = %g", om))
  }
  # Granting more bias lowers the value.
  vals <- vapply(c(1, 1.25, 1.5, 2, 3, 5), function(o)
    bf_worst_case(9, 3, omega = o), numeric(1))
  expect_true(all(diff(vals) < 0))
})

test_that("past omega = y_W / y_R the rival's best share is below one half", {
  # Jake's decision of 2026-10-27, for the supplement's study tables.
  # omega / (1 + omega) passes y_W / N exactly when omega passes
  # y_W / y_R. Up to that bias the rival's best share is one half, and
  # the value is the one the paper's worst_bf_weighted() computes. Past
  # it, holding the rival at one half would overstate the worst case: at
  # nine of twelve and omega = 5, one half becomes 5/6 found, where nine
  # of twelve has probability 220 (5/6)^9 (1/6)^3 = 0.197, while a share
  # of 0.375 becomes 0.75 found, where it has probability
  # 220 (3/4)^9 (1/4)^3 = 0.258. The working theory's probability is
  # 0.0554, so the value is 0.0554 / 0.258 = 0.21 rather than 0.28.
  tilt <- function(t, om) om * t / (om * t + 1 - t)
  num_5 <- 2 * stats::integrate(
    function(t) stats::dbinom(9, 12, tilt(t, 5)), 0.5, 1)$value
  expect_equal(round(num_5, 4), 0.0554)
  expect_equal(round(stats::dbinom(9, 12, 5 / 6), 3), 0.197)
  expect_equal(round(stats::dbinom(9, 12, 0.75), 3), 0.258)
  expect_equal(tilt(0.375, 5), 0.75)
  expect_equal(round(bf_worst_case(9, 3, omega = 5), 2), 0.21)
  # Up to omega = 3 the value is the paper's, with the rival at one half.
  at_half <- function(om) 2 * stats::integrate(
    function(t) stats::dbinom(9, 12, tilt(t, om)), 0.5, 1)$value /
    stats::dbinom(9, 12, om / (1 + om))
  for (om in c(1.5, 2, 3)) {
    expect_equal(bf_worst_case(9, 3, omega = om), at_half(om),
                 tolerance = 1e-8)
  }
  expect_equal(bf_worst_case(9, 3, omega = 2), 0.66612932, tolerance = 1e-7)
  # Past it the value is smaller than the one at one half, and it is the
  # smallest value over every share the rival claims, found by search.
  smallest <- function(om) {
    best <- stats::optimize(function(t) stats::dbinom(9, 12, tilt(t, om)),
                            c(0, 0.5), maximum = TRUE)$objective
    2 * stats::integrate(function(t) stats::dbinom(9, 12, tilt(t, om)),
                         0.5, 1)$value / best
  }
  for (om in c(3.5, 5, 10)) {
    expect_lt(bf_worst_case(9, 3, omega = om), at_half(om))
    expect_equal(bf_worst_case(9, 3, omega = om), smallest(om),
                 tolerance = 1e-6)
  }
})

test_that("counts favoring the rival keep the rival at one half under bias", {
  # The paper holds the rival at one half for every count, which gives
  # the closed form of thm-closed-form, and calls that value the worst
  # case only when y_W >= y_R. The package keeps that convention: with
  # fewer observations for the working theory than for the rival, the
  # rival stays at one half, tilted, at every bias. The rule's second
  # condition fails at these counts either way, because the value is
  # below 1.
  tilt <- function(t, om) om * t / (om * t + 1 - t)
  num <- 2 * stats::integrate(
    function(t) stats::dbinom(3, 12, tilt(t, 2)), 0.5, 1)$value
  expect_equal(bf_worst_case(3, 9, omega = 2),
               num / stats::dbinom(3, 12, 2 / 3), tolerance = 1e-8)
  expect_lt(bf_worst_case(3, 9, omega = 2), 1)
})

# ---- inputs -------------------------------------------------------------

test_that("input validation rejects nonsense", {
  # Counts are scalar non-negative whole numbers. The integer check
  # matters: the closed form sums binomial coefficients over 0:y_W, and
  # a fractional y_W would be truncated silently.
  expect_error(bf_worst_case(-1, 3))
  expect_error(bf_worst_case(3, -1))
  expect_error(bf_worst_case(9.5, 3))
  expect_error(bf_worst_case(c(9, 10), 3))
  expect_error(bf_worst_case(9, 3, omega = 0))
  expect_error(bf_worst_case(9, 3, a1 = 0))
  expect_error(bf_worst_case(9, 3, b1 = -1))
})

test_that("very large counts stay finite and still match the definition", {
  # The closed form overflows a double past roughly a thousand
  # observations and would return Inf / Inf = NaN. The function redoes
  # the same arithmetic on the log scale instead.
  for (p in list(c(600, 600), c(620, 580), c(700, 500))) {
    y_W <- p[1]
    n <- p[1] + p[2]
    expect_true(is.nan(sum(choose(n + 1, 0:y_W)) / ((n + 1) * choose(n, y_W))),
                info = "the direct closed form must in fact overflow here")
    by_integral <- 2 * stats::integrate(
      function(t) stats::dbinom(y_W, n, t), 0.5, 1
    )$value / stats::dbinom(y_W, n, 0.5)
    expect_equal(bf_worst_case(p[1], p[2]), by_integral, tolerance = 1e-8,
                 info = sprintf("y_W = %d, y_R = %d", p[1], p[2]))
  }
})
