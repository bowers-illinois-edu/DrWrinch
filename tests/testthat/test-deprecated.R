# Tests for the deprecation of the hypergeometric urn model.
#
# The paper began with two probability models and now has one. Each
# observation supports the working theory with probability theta, the
# share of the evidence that supports it, and the two Bayes factors the
# paper reports differ only in what they do with the range of shares the
# rival claims. The urn model, which described a bounded archive of a
# stated size, is no longer in the paper at all.
#
# bf_urn() and sens_urn() are not removed, because the first arXiv
# version of the paper cites them and its replication code calls them.
# They warn instead, once per session, and they must go on returning
# exactly what they returned: a deprecation that changed a number would
# break the replication it exists to protect.

test_that("bf_urn warns once per session and points at bf_worst_case", {
  # Reset and check in one block, so that the order in which testthat
  # runs the files cannot decide whether the warning has already fired.
  .reset_deprecation_warnings()
  expect_warning(bf_urn(9, 3), regexp = "bf_worst_case",
                 class = "deprecatedWarning")
  expect_no_warning(bf_urn(9, 3))
  expect_no_warning(bf_urn(12, 0))
})

test_that("deprecation leaves bf_urn's values untouched", {
  # The published value for Andersen (2023), which test-applications.R
  # also pins. Warning about a function must not change what it computes.
  expect_equal(suppressWarnings(bf_urn(9, 3)), 323, tolerance = 1e-6)
  expect_equal(suppressWarnings(bf_urn(8, 4)), suppressWarnings(bf_urn(8, 4)))
  expect_true(is.na(suppressWarnings(bf_urn(2, 9))))
})

test_that("sens_urn warns once per session and points at bf_worst_case", {
  .reset_deprecation_warnings()
  # Fire bf_urn's warning first, since sens_urn calls it internally and
  # this block is about sens_urn's own warning.
  suppressWarnings(bf_urn(1, 1))
  expect_warning(sens_urn(9, 3), regexp = "bf_worst_case",
                 class = "deprecatedWarning")
  expect_no_warning(sens_urn(9, 3))
})

test_that("deprecation leaves sens_urn's values untouched", {
  # The bias tipping point test-sens.R pins for the running example.
  s <- suppressWarnings(sens_urn(9, 3, threshold = 20))
  expect_equal(s$omega_star, 2.433984, tolerance = 1e-5)
  expect_equal(s$bf, suppressWarnings(bf_urn(9, 3)))
})

test_that("sens_coding with the urn warns once, not once per re-coding", {
  # sens_coding() recomputes the Bayes factor at each re-coding, so a
  # warning on every call to bf_urn() would emit several from one call
  # the researcher made. Warning once per session is what keeps a
  # deprecation notice a notice rather than noise.
  .reset_deprecation_warnings()
  expect_warning(s <- sens_coding(9, 3, model = "urn", threshold = 20),
                 class = "deprecatedWarning")
  expect_equal(s$x_star, 2L)
  expect_no_warning(sens_coding(9, 3, model = "urn", threshold = 20))
})

test_that("the surviving Bayes factors do not warn", {
  # Only the urn is deprecated. A warning on the functions the paper
  # does use would train a reader to ignore the notices.
  .reset_deprecation_warnings()
  expect_no_warning(bf_uniform_weights(9, 3))
  expect_no_warning(bf_worst_case(9, 3))
  expect_no_warning(bf_rescaled(9, 3))
  expect_no_warning(bf_binomial(9, 3))
  expect_no_warning(sens_coding(9, 3, model = "worst_case"))
  expect_no_warning(sens_binomial(9, 3))
  # Re-arm, so this block leaves the session in the state the setup file
  # established whatever order the files ran in.
  suppressWarnings(bf_urn(1, 1))
  suppressWarnings(sens_urn(1, 1))
})
