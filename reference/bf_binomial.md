# Bayes factor under the binomial model

Computes the Bayes factor for a working theory \\H_1: \theta \>
\theta\_{\text{cut}}\\ against a rival \\H_R: \theta \le
\theta\_{\text{cut}}\\, given `y_W` pieces of evidence favorable to
\\H_1\\ and `y_R` pieces favorable to \\H_R\\, treated as \\n = y_W +
y_R\\ independent Bernoulli draws from an infinite evidence universe
with success probability `theta`.

## Usage

``` r
bf_binomial(y_W, y_R, omega = 1, prior_a = 1, prior_b = 1, theta_cut = 0.5)
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

- prior_a, prior_b:

  Positive numerics. Beta prior shape parameters on `theta`. Default
  uniform prior, `1` and `1`.

- theta_cut:

  Numeric in (0, 1). Cutpoint separating \\H_1\\ from \\H_R\\. Default
  `0.5`.

## Value

A length-1 numeric: the Bayes factor in favor of \\H_1\\. Returns
`NA_real_` if the integrated likelihood is numerically zero.

## Details

This model fits research designs where the evidence universe is
open-ended — ongoing interviews, an expanding archive, a growing set of
cases. For bounded archives, see
[`bf_urn()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/bf_urn.md).

Under a `Beta(prior_a, prior_b)` prior on `theta` and observation bias
`omega = 1` (unbiased), the posterior is
`Beta(prior_a + y_W, prior_b + y_R)` and the Bayes factor is the ratio
of posterior masses on the two sides of `theta_cut`. Under observation
bias `omega != 1`, the probability that an item supports \\H_1\\ given
it was observed is \`q = omega \* theta / (1 + (omega -

1.  - theta)`(Fisher's odds-ratio transformation); the Bayes factor is then computed by numerical integration.`omega
      \>
      1`makes pro- \eqn{H_1} items likelier to be observed than they are in the universe;`omega
      \< 1\` makes them less likely.

For weighted analyses, sum the weights first and pass the sums:
`bf_binomial(sum(w_W), sum(w_R))`. Integer weights act as effective
replication; see the paper for the rationale.

## See also

[`bf_urn()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/bf_urn.md)
for the bounded-archive case;
[`sens_binomial()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/sens_binomial.md)
for sensitivity to omega and prior.

## Examples

``` r
bf_binomial(7, 3)
#> [1] 7.827586
bf_binomial(7, 3, omega = 0.5)
#> [1] 68.20801
bf_binomial(7, 3, prior_a = 1, prior_b = 4)
#> [1] 1.529957
```
