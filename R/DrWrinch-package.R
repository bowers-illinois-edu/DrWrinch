#' DrWrinch: Fully Specified Bayes Factors for Process Tracing
#'
#' A researcher has coded the evidence into two counts: observations
#' supporting the working theory and observations supporting a single
#' rival. One model underlies everything this package computes. Each
#' observation supports the working theory with probability \eqn{\theta},
#' the share of the evidence that supports it. The working theory claims
#' \eqn{\theta > 1/2} and the rival claims \eqn{\theta \le 1/2}.
#'
#' Each claim is a range of shares rather than one share, so neither gives
#' a probability for the counts on its own. The package computes the two
#' Bayes factors of Lopez, Bowers, and Gajardo Cooper (2026). They share a
#' numerator, the probability of the counts averaged over the shares above
#' one half under uniform weights, and differ in the denominator.
#' [bf_uniform_weights()] averages over the rival's shares under the same
#' uniform weights. [bf_worst_case()] evaluates the rival at its most
#' favorable share, one half when the counts favor the working theory,
#' which makes its value the smallest any weights on the rival's shares
#' can give. The paper's rule sets the rival aside, at least
#' provisionally, when the first is 20 or more and the second is above 1.
#'
#' [bf_rescaled()] computes the uniform-weights Bayes factor under other
#' weights on the shares, and `bf_worst_case()` takes the same weights on
#' the working theory's side. [bf_uniform_weights_finite()] and
#' [bf_worst_case_finite()] compute both Bayes factors for documents read
#' without replacement from an archive of known size. [sens_bias()] and
#' [sens_coding()] report how biased the search, or how many observations
#' re-coded, it would take before a researcher following the rule would no
#' longer set the rival aside.
#'
#' The package is named after Dorothy Maud Wrinch (1894--1976), whose
#' joint papers with Harold Jeffreys (1919, 1921, 1923) developed the
#' framework that became Jeffreys's theory of Bayes factors. See
#' <https://en.wikipedia.org/wiki/Dorothy_Maud_Wrinch>.
#'
#' @keywords internal
"_PACKAGE"
