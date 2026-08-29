# Substantive tests for the worst-case Bayes factor and its separated
# version, ported from the paper repository's tests/test_bf_bounded.R
# (functions renamed to the package's names, assertions rewritten as
# testthat expectations).
#
# The model behind both Bayes factors in this package is the same one:
# each observation supports the working theory with probability theta,
# the share of the evidence that supports it. The working theory claims
# theta > 1/2 and the rival claims theta <= 1/2. The numerator is shared
# --- the binomial probability of the counts averaged over the shares
# above one half under uniform weights. The two Bayes factors differ in
# what they do with the rival's range of shares.
#
# bf_worst_case() hands the rival the single share, one half, at which
# her claim makes the observed counts most probable. That is the most
# generous reading of the rival available, which is why the resulting
# number is a lower bound: no weighting the rival could have stated
# before coding would make the evidence against her look weaker.
#
# Sources for the claims tested here: Theorem 2 and Corollary 1 of the
# paper's plan_common_urn.qmd (the error rate at every collection size),
# the closed form eq-lambda-cf of the same file, Proposition 2 (the 4.81
# ceiling at nine of twelve), and the six-study table of plan_overall.md.

test_that("the closed form equals the averaged-over-shares definition", {
  # bf_worst_case() computes a ratio of binomial coefficients rather
  # than an integral. The definition it replaces divides the probability
  # of the counts averaged over the shares above one half by the
  # probability of the counts at a share of exactly one half. Averaging
  # under uniform weights on the interval from one half to one means
  # dividing the integral by the width of that interval, one half,
  # which is where the factor of 2 comes from.
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
  # The exact rational value, then the two decimals the paper prints.
  expect_equal(bf_worst_case(9, 3), 7814 / 2860, tolerance = 1e-12)
  expect_equal(round(bf_worst_case(9, 3), 2), 2.73)
})

test_that("the six applications reproduce the published values", {
  # Same six studies as test-applications.R, same counts. Pinning them
  # here keeps a number already in print from changing silently.
  apps <- list(
    list(name = "Steinsson (2023)",                y_W = 12, y_R = 0,
         worst = 630.08, gap = 0.063),
    list(name = "Winward (2020)",                  y_W = 14, y_R = 3,
         worst = 21.34,  gap = 0.068),
    list(name = "Hammoud-Gallego & Freier (2022)", y_W = 10, y_R = 3,
         worst = 3.97,   gap = 0.106),
    list(name = "Mor (2022)",                      y_W =  8, y_R = 2,
         worst = 4.00,   gap = 0.123),
    list(name = "Andersen (2023)",                 y_W =  9, y_R = 3,
         worst = 2.73,   gap = 0.123),
    list(name = "Pavone & Stiansen (2021)",        y_W =  7, y_R = 4,
         worst = 0.83,   gap = 0.231)
  )
  for (a in apps) {
    expect_equal(round(bf_worst_case(a$y_W, a$y_R), 2), a$worst,
                 tolerance = 0.005, info = a$name)
    expect_equal(separation_g(a$y_W, a$y_R), a$gap, info = a$name)
  }
})

test_that("weighting Pavone's letter reproduces the paper's weighted counts", {
  # Weights act as replication: an observation the researcher weights at
  # ten enters as ten observations. Pavone & Stiansen's agreed counts
  # (7, 4) do not clear a threshold of 20, but weighting one pro-working-
  # theory document more heavily moves them.
  expect_equal(round(bf_worst_case(16, 4), 1), 20.5)
  expect_equal(round(bf_worst_case(18, 3), 1), 143.3)
})

test_that("the worst-case Bayes factor is defined at every count", {
  # Counts that favor the rival are not an error case. The statistic is
  # a ratio of two positive probabilities whatever the counts.
  expect_true(is.finite(bf_worst_case(0, 12)))
  expect_gt(bf_worst_case(0, 12), 0)
})

test_that("counts favoring the working theory can still fall below one", {
  # Seven of twelve gives 0.56. A rival who may claim an evenly split
  # body of evidence is not embarrassed by seven of twelve: those counts
  # are more probable at a share of one half than averaged over the
  # shares the working theory claims. Reporting a number below one here
  # is the honest reading, not a failure of the statistic.
  expect_equal(round(bf_worst_case(7, 5), 2), 0.56)
  # With twelve observations the value first reaches 20 at eleven of
  # twelve, which is what makes this Bayes factor demanding.
  v12 <- vapply(0:12, function(k) bf_worst_case(k, 12 - k), numeric(1))
  expect_equal(min(which(v12 >= 20)) - 1L, 11L)
})

test_that("the average of the statistic is one when the rival is exactly right", {
  # This is the error-rate guarantee at work. If the evidence really is
  # split evenly --- the rival's best case --- then across repeated
  # samples the worst-case Bayes factor averages to exactly one. An
  # average of one is what Markov's inequality needs: a researcher who
  # treats 20 as decisive is then misled at most one time in twenty.
  for (N in c(2, 5, 12)) {
    lam <- vapply(0:N, function(k) bf_worst_case(k, N - k), numeric(1))
    expect_equal(sum(stats::dbinom(0:N, N, 0.5) * lam), 1,
                 tolerance = 1e-10, info = sprintf("N = %d", N))
  }
})

test_that("the average falls below one at every share the rival could claim", {
  # The rival claims a share at or below one half. One half is her best
  # case; anything lower makes the average smaller still, so the error
  # rate at one half covers her whole range.
  lam12 <- vapply(0:12, function(k) bf_worst_case(k, 12 - k), numeric(1))
  for (s in c(0.1, 0.25, 0.4, 0.49)) {
    expect_lt(sum(stats::dbinom(0:12, 12, s) * lam12), 1)
  }
})

test_that("the guarantee survives draws without replacement, at any collection size", {
  # A researcher reading documents does not replace them, and the
  # collection she reads from is finite. The binomial model treats the
  # draws as independent, so the guarantee has to be checked against the
  # sampling she actually does: twelve documents drawn without
  # replacement from a collection of M documents of which K1 support the
  # working theory. The rival's claim is that K1 is at most half of M.
  # The average stays at or below one at every collection size tried,
  # which is why the paper can state the error rate without ever naming
  # a collection size.
  lam12 <- vapply(0:12, function(k) bf_worst_case(k, 12 - k), numeric(1))
  for (M in c(12, 13, 24, 60, 240)) {
    for (K1 in seq_len(floor(M / 2))) {
      avg <- sum(stats::dhyper(0:12, K1, M - K1, 12) * lam12)
      expect_lte(avg, 1 + 1e-12)
    }
  }
})

test_that("the statistic rises by increasing steps as the count rises", {
  # This convexity is the step the proof of the without-replacement case
  # turns on (Hoeffding's result on sampling without replacement applies
  # to it). Testing it directly means a future change to the closed form
  # cannot break the proof without breaking a test.
  lam12 <- vapply(0:12, function(k) bf_worst_case(k, 12 - k), numeric(1))
  expect_true(all(diff(diff(lam12)) > 0))
})

test_that("nine of twelve cannot be pushed past the 4.81 ceiling", {
  # Proposition 2. Even a researcher who states her weights so as to put
  # all of them on the share that best fits her counts cannot get more
  # than 2^12 * 9^9 * 3^3 / 12^12 = 4.81 out of nine of twelve. So the
  # difference between 2.73 and 4.81 bounds everything a choice of
  # weights could buy her, and the choice of uniform weights is not
  # where the number comes from.
  ceiling_9_3 <- 2^12 * 9^9 * 3^3 / 12^12
  expect_equal(round(ceiling_9_3, 2), 4.81)
  expect_lt(bf_worst_case(9, 3), ceiling_9_3)
})

test_that("the separated version reaches the threshold at the reported separation", {
  # In the separated version the working theory claims a share of at
  # least 1/2 + g and the rival at most 1/2 - g. The researcher does not
  # choose g. She solves for the g at which the value equals the
  # threshold she cares about and reports that, which is a way of asking
  # how far apart the two theories have to be before her counts settle
  # the question. The reported g is rounded up, so the value at the
  # printed g clears the threshold and the value one thousandth below
  # does not.
  g_star <- separation_g(9, 3)
  expect_equal(g_star, 0.123)
  expect_gte(bf_separated(9, 3, g_star), 20)
  expect_lt(bf_separated(9, 3, g_star - 0.001), 20)
})

test_that("the unrounded separation solves the equation exactly", {
  d <- 9 - 3
  g_exact <- (20^(1 / d) - 1) / (2 * (20^(1 / d) + 1))
  expect_equal(bf_separated(9, 3, g_exact), 20, tolerance = 1e-10)
})

test_that("the separated value depends on the margin and rises with g", {
  # Everything except the margin y_W - y_R cancels in the separated
  # version, so even counts give exactly one however far apart the two
  # theories are placed, and the value exceeds one exactly when the
  # counts favor the working theory.
  expect_equal(bf_separated(6, 6, 0.2), 1, tolerance = 1e-12)
  expect_gt(bf_separated(7, 5, 0.2), 1)
  expect_lt(bf_separated(5, 7, 0.2), 1)
  gs <- c(0.05, 0.1, 0.2, 0.3)
  expect_true(all(diff(vapply(gs, function(g) bf_separated(9, 3, g),
                              numeric(1))) > 0))
})

test_that("reversing every coding sends the separated value to its reciprocal", {
  # Swapping the counts flips the sign of the margin, so the separated
  # version inverts exactly. The worst-case Bayes factor does not have
  # this property, because its numerator averages over a range while its
  # denominator sits at a point. Pinning both facts keeps the paper's
  # scope sentence about the separated version honest.
  for (g in c(0.05, 0.123, 0.25)) {
    expect_equal(bf_separated(3, 9, g), 1 / bf_separated(9, 3, g),
                 tolerance = 1e-12, info = sprintf("g = %g", g))
    expect_equal(bf_separated(0, 12, g), 1 / bf_separated(12, 0, g),
                 tolerance = 1e-12, info = sprintf("g = %g", g))
  }
  expect_gt(abs(bf_worst_case(3, 9) - 1 / bf_worst_case(9, 3)), 0.1)
})

test_that("separation_g requires counts that favor the working theory", {
  # With even or rival-favoring counts no separation lifts the value to
  # a threshold above one, so there is nothing to report and the
  # function should say so rather than return a number.
  expect_error(separation_g(3, 9))
  expect_error(separation_g(6, 6))
})

test_that("no assumed bias recovers the untilted separated value", {
  # omega is the odds by which the search favored surfacing a document
  # supporting the working theory. omega = 1 is the unbiased search.
  expect_equal(bf_separated_bias(9, 3, 0.125, omega = 1),
               bf_separated(9, 3, 0.125), tolerance = 1e-12)
})

test_that("granting more search bias weakens the report", {
  # If the search was omega times as likely to surface a document
  # supporting the working theory, then part of the apparent dominance
  # of the counts is an artifact of how the researcher looked, and the
  # corrected value falls.
  oms <- c(1, 1.25, 1.5, 2, 3)
  vals <- vapply(oms, function(o) bf_separated_bias(9, 3, 0.2, omega = o),
                 numeric(1))
  expect_true(all(diff(vals) < 0))
  # The two cells the paper quotes at a separation of 0.125.
  expect_equal(round(bf_separated_bias(9, 3, 0.125, 1), 0), 21)
  expect_equal(round(bf_separated_bias(9, 3, 0.125, 1.5), 1), 6.4)
})

test_that("the bias-corrected statistic keeps the guarantee at omega >= 1", {
  # A search that favors the working theory turns a share theta in the
  # collection into a larger share among the documents found, which is
  # Fisher's noncentral hypergeometric distribution for draws without
  # replacement. The proof of the guarantee for the corrected statistic
  # is still owed, so the paper labels these tables "numerically
  # checked" and this test is what that label refers to.
  dfnc <- function(x, K1, M, N, om) {
    supp <- max(0, N - (M - K1)):min(N, K1)
    w <- stats::dhyper(supp, K1, M - K1, N) * om^supp
    w <- w / sum(w)
    out <- numeric(length(x))
    j <- match(x, supp)
    out[!is.na(j)] <- w[j[!is.na(j)]]
    out
  }
  for (om in c(1, 1.5, 3)) {
    for (g in c(0.125, 0.25)) {
      v <- vapply(0:12, function(k) bf_separated_bias(k, 12 - k, g, om),
                  numeric(1))
      for (M in c(24, 60, 240)) {
        for (K1 in seq_len(floor(M * (0.5 - g)))) {
          expect_lte(sum(dfnc(0:12, K1, M, 12, om) * v), 1 + 1e-9)
        }
      }
    }
  }
})

test_that("input validation rejects nonsense", {
  # Counts are scalar non-negative integers. The integer check matters
  # here in a way it does not for bf_binomial(): bf_worst_case() sums
  # binomial coefficients over 0:y_W, and a fractional y_W would be
  # truncated silently and return a wrong number rather than an error.
  expect_error(bf_worst_case(-1, 3))
  expect_error(bf_worst_case(3, -1))
  expect_error(bf_worst_case(9.5, 3))
  expect_error(bf_worst_case(c(9, 10), 3))
  # The separation g places the two theories on opposite sides of one
  # half, so it has to be strictly between zero and one half.
  expect_error(bf_separated(9, 3, 0))
  expect_error(bf_separated(9, 3, 0.5))
  expect_error(bf_separated_bias(9, 3, 0.125, omega = 0))
})

test_that("very large counts stay finite and still match the definition", {
  # The closed form sums binomial coefficients, which overflow a double
  # past roughly a thousand observations and leave Inf/Inf = NaN. No
  # process-tracing study comes near that, but the function redoes the
  # same arithmetic on the log scale rather than returning NaN. The check
  # is the same one section 1 makes at small counts: the value must equal
  # the ratio of the averaged probability of the counts to the
  # probability at a share of one half.
  for (p in list(c(600, 600), c(620, 580), c(640, 560), c(700, 500))) {
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
