#' Sensitivity to search bias and to a prior tilted toward the rival
#'
#' Two questions a peer asks about the uniform-weights Bayes factor, each
#' answered by the value at which the researcher's report would change.
#' The counts are `y_W` observations supporting the working theory and
#' `y_R` supporting the rival.
#'
#' @section Search bias:
#' `omega` is the odds by which the search favored surfacing evidence for
#' the working theory: at `omega > 1` part of the apparent dominance of
#' the counts came from how the researcher looked rather than from what
#' is there, so the value falls as `omega` rises. `omega_star` is the
#' bias at which it first falls below `threshold`. The prior stays
#' uniform throughout this sweep, so the two theories keep equal weight
#' and the value being swept is the Bayes factor.
#'
#' @section Why M_star is a posterior-odds tipping point:
#' A `Beta(1, M + 1)` prior on the whole interval reads as `M` background
#' cases all favoring the rival, so sweeping `M` asks how many the
#' researcher would have to grant before her report changed. That prior
#' moves weight between the two theories as well as within their ranges,
#' and [bf_binomial()] returns the ratio of posterior masses either side
#' of the cut, which is the posterior odds. `M_star` is therefore the
#' smallest `M` at which the *posterior odds* fall below `threshold`.
#'
#' It could not be anything else. Tilting the prior toward the rival
#' commits her to shares near zero, under which counts favoring the
#' working theory are more surprising still, so the Bayes factor *rises*
#' with `M` --- from 20.67 to 30.41, 39.39, 51.01 and 67.56 over the
#' first five values at nine observations against three. A Bayes-factor
#' tipping point under these priors would not exist. The prior odds fall
#' faster than the Bayes factor rises, which is what sends the posterior
#' odds down. The table in [bf_binomial()] shows both columns.
#'
#' If the baseline value is already below `threshold`, both tipping
#' points are `0`.
#'
#' @param y_W Non-negative integer. Observed count favorable to the
#'   working theory.
#' @param y_R Non-negative integer. Observed count favorable to the
#'   rival.
#' @param threshold Positive numeric. The value at which the researcher
#'   would set the rival aside. Default `20`.
#' @param theta_cut Numeric in (0, 1). Cutpoint. Default `0.5`.
#' @param M_max Positive integer. Largest `M` searched in the prior
#'   sweep. Default `200`.
#'
#' @return A list with elements:
#'   \describe{
#'     \item{`bf`}{The uniform-weights Bayes factor at the baseline
#'       (`omega = 1`, uniform prior).}
#'     \item{`omega_star`}{Search-bias tipping point in the Bayes
#'       factor. `0` if `bf < threshold` at baseline; `NA_real_` if the
#'       value does not cross `threshold` for any reachable `omega`.}
#'     \item{`M_star`}{Smallest integer `M >= 0` at which the posterior
#'       odds under a `Beta(1, M + 1)` prior fall below `threshold`,
#'       not a Bayes-factor tipping point. `0` if `bf < threshold` at
#'       baseline; `NA_integer_` if the posterior odds stay at or above
#'       `threshold` throughout `[0, M_max]`.}
#'   }
#'
#' @examples
#' # The paper's running example. The Bayes factor just clears 20, so
#' # both tipping points are small: a slight search bias, or one
#' # background case favoring the rival, changes what she would report.
#' s <- sens_binomial(9, 3)
#' s$bf
#' s$omega_star
#' s$M_star
#'
#' @seealso [bf_uniform_weights()] and [bf_binomial()] for the value
#'   being swept; [sens_coding()] for sensitivity to coding error;
#'   [bf_rescaled()] for weights stated within each theory's range, which
#'   move weight within the ranges without moving it between them.
#' @export
sens_binomial <- function(y_W, y_R,
                          threshold = 20,
                          theta_cut = 0.5,
                          M_max = 200L) {
  stopifnot(
    length(y_W) == 1L, length(y_R) == 1L,
    y_W >= 0, y_R >= 0,
    threshold > 0,
    theta_cut > 0, theta_cut < 1,
    M_max >= 0
  )

  bf_base <- bf_binomial(y_W, y_R, theta_cut = theta_cut)

  omega_star <- .find_omega_tipping(
    function(omega) bf_binomial(y_W, y_R, omega = omega,
                                theta_cut = theta_cut),
    threshold
  )

  M_star <- if (is.na(bf_base) || bf_base < threshold) {
    # Conclusion already fails at the uniform prior. No rival-favoring
    # pseudo-observations are needed; M_star = 0.
    0L
  } else {
    bfs <- vapply(
      0:M_max,
      function(M) bf_binomial(y_W, y_R,
                              prior_a = 1, prior_b = M + 1,
                              theta_cut = theta_cut),
      numeric(1)
    )
    hit <- which(bfs < threshold)
    if (length(hit) == 0L) NA_integer_ else as.integer(hit[1] - 1L)
  }

  list(bf = bf_base, omega_star = omega_star, M_star = M_star)
}
