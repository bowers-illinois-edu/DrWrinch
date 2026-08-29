# Substantive tests for bf_uniform_weights, and for what bf_binomial
# keeps that the new name does not.
#
# One model underlies both Bayes factors in this package: each
# observation supports the working theory with probability theta, the
# share of the evidence that supports it; the working theory claims
# theta > 1/2 and the rival claims theta <= 1/2. Both Bayes factors
# share a numerator, the binomial probability of the counts averaged
# over the shares above one half. bf_uniform_weights() spreads the
# rival's claim evenly over every share at or below one half;
# bf_worst_case() instead hands her the single share, one half, that
# fits the counts best.
#
# bf_binomial() is the earlier name for the same number. It survives
# because it carries something bf_uniform_weights() deliberately does
# not: a Beta prior on the whole interval from zero to one. That path
# is what sens_binomial()'s M_star analysis uses, and the last block of
# this file pins the reason the two cannot be merged.

test_that("bf_uniform_weights and bf_binomial return the same number", {
  # The rename adds no mathematics. Pinning the equality over a grid is
  # what lets test-applications.R keep testing the published values
  # through the old name without duplicating them here.
  for (y_W in c(0, 1, 7, 9, 12, 14, 18)) {
    for (y_R in c(0, 2, 3, 4, 5)) {
      expect_equal(bf_uniform_weights(y_W, y_R), bf_binomial(y_W, y_R),
                   tolerance = 1e-12,
                   info = sprintf("y_W = %d, y_R = %d", y_W, y_R))
    }
  }
})

test_that("the equality survives a biased search", {
  # omega is the odds by which the search favored surfacing evidence for
  # the working theory. Both functions route it the same way, including
  # through the numerical-integration branch that omega != 1 triggers.
  for (om in c(0.5, 0.8, 1, 1.5, 3)) {
    expect_equal(bf_uniform_weights(9, 3, omega = om),
                 bf_binomial(9, 3, omega = om),
                 tolerance = 1e-10, info = sprintf("omega = %g", om))
  }
})

test_that("the running example gives 20.67", {
  # Nine observations support the working theory and three the rival.
  # Under uniform weights on each side the value has a closed form: the
  # posterior mass above one half against the mass at or below it, under
  # a uniform prior, which is a Beta(y_W + 1, y_R + 1) posterior.
  p_below <- stats::pbeta(0.5, 9 + 1, 3 + 1)
  expect_equal(bf_uniform_weights(9, 3), (1 - p_below) / p_below,
               tolerance = 1e-12)
  expect_equal(round(bf_uniform_weights(9, 3), 2), 20.67)
})

test_that("weighting Pavone's letter reproduces the paper's weighted counts", {
  # Weights on observations act as replication: a document the
  # researcher weights at ten enters as ten observations. Pavone and
  # Stiansen's agreed counts (7, 4) do not reach 20, and the paper
  # reports what weighting the smoking-gun letter does to that.
  expect_equal(round(bf_uniform_weights(18, 3), 0), 2337)
})

test_that("a biased search lowers the value and an unbiased one is the default", {
  # Granting that the search was more likely to surface evidence for the
  # working theory concedes that part of the counts' dominance came from
  # how the researcher looked, so the value falls.
  expect_lt(bf_uniform_weights(9, 3, omega = 2), bf_uniform_weights(9, 3))
  expect_gt(bf_uniform_weights(9, 3, omega = 0.5), bf_uniform_weights(9, 3))
  expect_equal(bf_uniform_weights(9, 3, omega = 1), bf_uniform_weights(9, 3),
               tolerance = 1e-6)
})

test_that("input validation rejects nonsense", {
  expect_error(bf_uniform_weights(-1, 3))
  expect_error(bf_uniform_weights(3, -1))
  expect_error(bf_uniform_weights(9, 3, omega = 0))
})

test_that("bf_binomial with a tilted prior returns posterior odds, not a Bayes factor", {
  # This is why bf_binomial() survives the rename rather than becoming a
  # plain alias, and it is the distinction the supplement's
  # prior-sensitivity table is built to show.
  #
  # Put a Beta(alpha, beta) prior on the whole interval from zero to
  # one. It does two things at once. It says how the researcher spreads
  # her weight within each theory's range, and it also says how much
  # weight she gives each theory: the mass above one half, call it pi_1,
  # sets the prior odds pi_1 / (1 - pi_1). The Bayes factor divides the
  # averaged likelihood under each theory after renormalizing the prior
  # to that theory's range, so the prior odds cancel out of it. The
  # posterior odds are the prior odds times the Bayes factor. Under the
  # uniform prior the mass is split evenly, the prior odds are one, and
  # the two objects coincide --- which is a fact about that prior, not a
  # definition.
  #
  # A Beta(1, M + 1) prior reads as M background cases all favoring the
  # rival. bf_binomial() returns the posterior odds under it. The two
  # columns move in opposite directions as M grows: tilting toward the
  # rival commits her to shares near zero, under which nine of twelve is
  # more surprising still, so the Bayes factor rises; but the same tilt
  # lowers the prior odds by more, so the posterior odds fall.
  three_objects <- function(alpha, beta, y_W = 9, y_R = 3) {
    n <- y_W + y_R
    lik <- function(t) stats::dbinom(y_W, n, t)
    num <- stats::integrate(
      function(t) lik(t) * stats::dbeta(t, alpha, beta), 0.5, 1)$value
    den <- stats::integrate(
      function(t) lik(t) * stats::dbeta(t, alpha, beta), 0, 0.5)$value
    pi_1 <- 1 - stats::pbeta(0.5, alpha, beta)
    c(prior_odds = pi_1 / (1 - pi_1),
      bayes_factor = (num / pi_1) / (den / (1 - pi_1)),
      posterior_odds = num / den)
  }
  tab <- t(vapply(0:4, function(M) three_objects(1, M + 1), numeric(3)))

  # The identity that ties the three columns together.
  expect_equal(unname(tab[, "posterior_odds"]),
               unname(tab[, "prior_odds"] * tab[, "bayes_factor"]),
               tolerance = 1e-9)
  # bf_binomial()'s prior path reproduces the posterior-odds column at
  # every M, and NOT the Bayes-factor column.
  from_package <- vapply(0:4,
                         function(M) bf_binomial(9, 3, prior_a = 1,
                                                 prior_b = M + 1),
                         numeric(1))
  expect_equal(from_package, unname(tab[, "posterior_odds"]),
               tolerance = 1e-8)
  # The two rows the supplement's prose quotes: one background case
  # against the working theory sends the posterior odds to 10.14, below
  # 20, while raising the Bayes factor to 30.41.
  expect_equal(round(from_package[2], 2), 10.14)
  expect_equal(round(unname(tab[2, "bayes_factor"]), 2), 30.41)
  # They separate everywhere except at the uniform prior.
  expect_equal(from_package[1], unname(tab[1, "bayes_factor"]),
               tolerance = 1e-8)
  expect_true(all(from_package[-1] < tab[-1, "bayes_factor"]))
  # And they move in opposite directions as the prior tilts.
  expect_true(all(diff(from_package) < 0))
  expect_true(all(diff(tab[, "bayes_factor"]) > 0))
})

test_that("bf_uniform_weights offers no whole-interval prior arguments", {
  # The headline function is the paper's object: uniform weight within
  # each theory's range, nothing to set. A reader who wants other
  # weights states them within each range through bf_rescaled(); a
  # reader who wants the whole-interval prior of the sensitivity table
  # calls bf_binomial(). Keeping the arguments apart keeps the two
  # families from being mistaken for one, since they agree only at the
  # uniform.
  expect_false(any(c("prior_a", "prior_b") %in%
                     names(formals(bf_uniform_weights))))
  expect_error(bf_uniform_weights(9, 3, prior_a = 1, prior_b = 2))
})
