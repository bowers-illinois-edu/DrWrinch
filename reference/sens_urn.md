# Sensitivity analysis for the urn Bayes factor

Reports the bias tipping point for the urn Bayes factor: the smallest
observation bias `omega > 1` at which the Bayes factor first drops below
`threshold`.

## Usage

``` r
sens_urn(y_W, y_R, threshold = 20)
```

## Arguments

- y_W:

  Non-negative integer. Observed count favorable to the working theory.

- y_R:

  Non-negative integer. Observed count favorable to the rival.

- threshold:

  Positive numeric. Decision threshold the Bayes factor must remain at
  or above. Default `20`.

## Value

A list with elements:

- `bf`:

  Bayes factor at `omega = 1`.

- `omega_star`:

  Bias tipping point. `0` if `bf < threshold` at baseline; `NA_real_` if
  `bf` does not cross `threshold` for any reachable `omega`.

## Details

`omega > 1` makes pro-\\H_1\\ items more likely to be drawn than they
are in the urn, so the apparent dominance of pro-\\H_1\\ evidence is
partly an artifact of observation, and the Bayes factor falls.
`omega_star` is the value at which this fall first crosses `threshold`.
If `bf_urn(y_W, y_R) < threshold` at baseline, `omega_star` is `0`.

## See also

[`bf_urn()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/bf_urn.md),
[`sens_binomial()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/sens_binomial.md),
[`sens_coding()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/sens_coding.md).

## Examples

``` r
# The paper's running example. bf_urn(9, 3) = 323 is far above 20, so
# pro-H_1 items must be ~2.4 times likelier to be observed before the
# urn BF reaches the threshold.
s <- sens_urn(9, 3)
s$bf
#> [1] 323
s$omega_star
#> [1] 2.433984
```
