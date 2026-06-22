# Sensitivity analysis for coding error

Reports the coding-error tipping point: the smallest number of pro-
working-theory observations that would have to be re-coded as pro-rival
before the Bayes factor first drops below `threshold`.

## Usage

``` r
sens_coding(
  y_W,
  y_R,
  model = c("binomial", "urn"),
  threshold = 20,
  theta_cut = 0.5
)
```

## Arguments

- y_W:

  Non-negative integer. Observed count favorable to the working theory.

- y_R:

  Non-negative integer. Observed count favorable to the rival.

- model:

  Which Bayes factor to recompute after re-coding: `"binomial"`
  (open-ended evidence) or `"urn"` (bounded archive).

- threshold:

  Positive numeric. Decision threshold the Bayes factor must remain at
  or above. Default `20`.

- theta_cut:

  Numeric in (0, 1). Cutpoint for the binomial model; ignored by the urn
  model. Default `0.5`.

## Value

A list with elements:

- `bf`:

  Bayes factor at the observed coding (no re-coding).

- `x_star`:

  Smallest integer `x >= 0` re-codings at which the Bayes factor drops
  below `threshold`. `0` if `bf < threshold` at baseline; `NA_integer_`
  if no re-coding in `[0, y_W]` with a defined Bayes factor drops it
  below `threshold`.

## Details

This is the third sensitivity question in the paper, alongside
observation bias
([`sens_urn()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/sens_urn.md)
and
[`sens_binomial()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/sens_binomial.md)'s
`omega_star`) and the rival-tilted prior
([`sens_binomial()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/sens_binomial.md)'s
`M_star`). A peer cannot re-read every document, but she can ask how
many pro-\\H_1\\ observations would have to be re-coded for the
conclusion to change.

Re-coding `x` observations relabels `x` pro-\\H_1\\ items as pro-rival,
moving the counts from `(y_W, y_R)` to `(y_W - x, y_R + x)`. The total
number of observations \\n = y_W + y_R\\ does not change; only the split
does. The same model's Bayes factor is then recomputed at the new
counts. One function serves both models because the mechanism is the
relabeling; `model` only selects which Bayes factor to recompute —
[`bf_binomial()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/bf_binomial.md)
for open-ended evidence,
[`bf_urn()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/bf_urn.md)
for a bounded archive.

Re-coding moves evidence toward equipoise, so the Bayes factor falls as
`x` grows. For the urn model, re-coding eventually shrinks the
rival-favorable urn below the sample size (the swap regime, where
[`bf_urn()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/bf_urn.md)
is undefined and returns `NA`); these re-codings are skipped rather than
counted as a crossing. Because the Bayes factor reaches equipoise before
that point for any `threshold > 1`, the tipping point is found within
the defined range in ordinary use.

If `bf_<model>(y_W, y_R) < threshold` at baseline, `x_star` is `0` (the
conclusion fails before any re-coding).

## See also

[`sens_binomial()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/sens_binomial.md)
and
[`sens_urn()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/sens_urn.md)
for observation-bias and prior sensitivity;
[`bf_binomial()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/bf_binomial.md)
and
[`bf_urn()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/bf_urn.md)
for the Bayes factors themselves.

## Examples

``` r
# The paper's running example: one re-coding overturns the binomial
# conclusion, two overturn the hypergeometric.
sens_coding(9, 3, model = "binomial")$x_star
#> [1] 1
sens_coding(9, 3, model = "urn")$x_star
#> [1] 2
```
