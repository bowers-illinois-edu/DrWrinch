# Bayes factor under the hypergeometric urn model

Computes the Bayes factor for a working theory \\H_1\\ against a single
rival \\H_R\\, given observed counts `y_W` of evidence favorable to
\\H_1\\ and `y_R` of evidence favorable to \\H_R\\, under Formulation C
of the urn construction. The Working Theory Favorable (WTF) sub-model
has urn composition \\(y_W + 1, \max(1, y_R))\\; the Rival Theory
Favorable (RTF) sub-model has urn composition \\(y_W, y_W + 1)\\. Both
constructions tilt in favor of the rival, so the Bayes factor returned
is a lower bound on the evidence for \\H_1\\.

## Usage

``` r
bf_urn(y_W, y_R, omega = 1)
```

## Arguments

- y_W:

  Non-negative integer. Count (or summed integer weight) of evidence
  favorable to the working theory.

- y_R:

  Non-negative integer. Count (or summed integer weight) of evidence
  favorable to the rival.

- omega:

  Positive numeric. Observation-bias odds ratio. Default `1` (unbiased).

## Value

A length-1 numeric: the Bayes factor in favor of \\H_1\\. `NA_real_` if
the RTF urn is too small for the sample; `Inf` if the RTF probability of
the observed pattern is numerically zero.

## Details

This model fits research designs where the evidence base is bounded and
fixed — a closed historical archive, a fixed roster of documents. For
open-ended evidence collection, see
[`bf_binomial()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/bf_binomial.md).

Observation bias `omega` enters as the odds ratio in Fisher's
non-central hypergeometric distribution (via
[`BiasedUrn::dFNCHypergeo()`](https://rdrr.io/pkg/BiasedUrn/man/BiasedUrn-2-Univariate.html)):
`omega = 1` is unbiased; `omega > 1` makes pro-\\H_1\\ items likelier to
be drawn; `omega < 1` makes them less likely.

For weighted analyses, sum the weights first and pass the sums:
`bf_urn(sum(w_W), sum(w_R))`.

When `y_R > y_W + 1`, the RTF urn cannot supply a sample of size \\n =
y_W + y_R\\, the construction is undefined, and the function returns
`NA_real_`.

## See also

[`bf_binomial()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/bf_binomial.md)
for the open-ended-evidence case;
[`sens_urn()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/sens_urn.md)
for sensitivity to omega;
[`sens_coding()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/sens_coding.md)
for sensitivity to coding error.

## Examples

``` r
# The paper's running example: nine pro-working-theory observations,
# three pro-rival. The closed form is (10/13) / (120/50388) = 323.
bf_urn(9, 3)
#> [1] 323
bf_urn(9, 3, omega = 0.5)
#> [1] 4804.609
```
