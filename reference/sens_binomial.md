# Sensitivity analysis for the binomial Bayes factor

Reports tipping points for the binomial Bayes factor: the smallest
observation bias `omega > 1` and the smallest rival-tilted prior Beta(1,
M + 1) at which the Bayes factor first drops below `threshold`.

## Usage

``` r
sens_binomial(y_W, y_R, threshold = 20, theta_cut = 0.5, M_max = 200L)
```

## Arguments

- y_W:

  Non-negative integer. Observed count favorable to the working theory.

- y_R:

  Non-negative integer. Observed count favorable to the rival.

- threshold:

  Positive numeric. Decision threshold the Bayes factor must remain at
  or above. Default `20`.

- theta_cut:

  Numeric in (0, 1). Cutpoint. Default `0.5`.

- M_max:

  Positive integer. Largest `M` searched in the prior sweep. Default
  `200`.

## Value

A list with elements:

- `bf`:

  Bayes factor at the baseline (`omega = 1`, uniform prior).

- `omega_star`:

  Bias tipping point. `0` if `bf < threshold` at baseline; `NA_real_` if
  `bf` does not cross `threshold` for any reachable `omega`.

- `M_star`:

  Smallest integer `M >= 0` with Beta(1, M + 1) prior at which the Bayes
  factor drops below `threshold`. `0` if `bf < threshold` at baseline;
  `NA_integer_` if the BF does not drop below threshold within
  `[0, M_max]`.

## Details

`omega > 1` makes pro-\\H_1\\ items more likely to be observed than they
are in the universe, so the apparent dominance of pro- \\H_1\\ evidence
is partly an artifact of observation, and the Bayes factor falls.
`omega_star` is the value at which this fall first crosses `threshold`.
Beta(1, M + 1) priors place all density on \\\theta \< 1\\ and posit `M`
pseudo-observations all favoring the rival. `M_star` is the smallest
integer `M` at which the Bayes factor first drops below `threshold`.

If `bf_binomial(y_W, y_R) < threshold` at baseline, both tipping points
are `0` (the conclusion fails before any perturbation).

## See also

[`bf_binomial()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/bf_binomial.md),
[`sens_urn()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/sens_urn.md),
[`sens_coding()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/sens_coding.md).

## Examples

``` r
# The paper's running example. The binomial BF just clears 20, so both
# tipping points are small: a slight bias or one rival-favoring
# pseudo-observation overturns it.
s <- sens_binomial(9, 3)
s$bf
#> [1] 20.67196
s$omega_star
#> [1] 1.00981
s$M_star
#> [1] 1
```
