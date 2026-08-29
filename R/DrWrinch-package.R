#' DrWrinch: Fully Specified Bayes Factors for Process Tracing
#'
#' A researcher has coded her evidence into two counts: observations
#' supporting her working theory and observations supporting a single
#' rival. One model underlies everything this package computes. Each
#' observation supports the working theory with probability
#' \eqn{\theta}, the share of the evidence that supports it. The working
#' theory claims \eqn{\theta > 1/2} and the rival claims
#' \eqn{\theta \le 1/2}.
#'
#' The rival's claim is a range of shares rather than one share, so it
#' does not by itself give a probability for the counts, and turning the
#' range into one number takes a rule. The package computes the two
#' Bayes factors that follow from the two rules a reader can neither
#' call arbitrary nor call self-serving. They share a numerator, the
#' probability of the counts averaged over the shares above one half
#' under uniform weights, and differ only in the denominator.
#' [bf_uniform_weights()] averages over the rival's whole range under
#' the same uniform weights. [bf_worst_case()] evaluates her claim at
#' the single share, one half, that makes the observed counts most
#' probable, which makes its value a lower bound and gives it an error
#' rate: a researcher who sets the rival aside at 20 is misled at most
#' one time in twenty when the rival is right, whatever the size of the
#' body of evidence.
#'
#' [bf_rescaled()] computes the first of those two under weights the
#' researcher states instead of the uniform default, and [bf_separated()]
#' and [separation_g()] report how far apart the two theories' claims
#' would have to be before the counts reach a threshold. The sensitivity
#' functions [sens_coding()] and [sens_binomial()] ask what a reader
#' would have to grant --- re-coded observations, a biased search, or
#' background cases favoring the rival --- before the researcher's report
#' would change.
#'
#' The package is named after Dorothy Maud Wrinch (1894--1976), whose
#' joint papers with Harold Jeffreys (1919, 1921, 1923) developed the
#' framework that became Jeffreys's theory of Bayes factors. See
#' <https://en.wikipedia.org/wiki/Dorothy_Maud_Wrinch>.
#'
#' @keywords internal
"_PACKAGE"
