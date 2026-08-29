# testthat runs setup files before the test files.
#
# bf_urn() and sens_urn() warn once per session that the paper no longer
# uses the hypergeometric urn model. Triggering that warning here, where
# it is expected, keeps it out of the test files that call the urn for
# other reasons: test-bf_urn.R, test-sens.R, test-applications.R,
# test-sens_coding.R, and the two app files. test-deprecated.R resets the
# flags itself before checking that the warning fires, and re-arms them
# by firing it, so the order in which the files run does not matter.
suppressWarnings(bf_urn(1, 1))
suppressWarnings(sens_urn(1, 1))
