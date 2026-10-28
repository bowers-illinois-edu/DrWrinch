# The uniform-weights Bayes factor

A researcher has coded the evidence into two counts: `y_W` observations
support the working theory and `y_R` support a single rival. One model
underlies every Bayes factor in this package. Each observation supports
the working theory with probability \\\theta\\, the share of the
evidence that supports it. The working theory claims \\\theta \> 1/2\\
and the rival claims \\\theta \le 1/2\\.

## Usage

``` r
bf_uniform_weights(y_W, y_R, omega = 1)
```

## Arguments

- y_W:

  Non-negative whole number. Count, or summed weight, of observations
  supporting the working theory.

- y_R:

  Non-negative whole number. Count, or summed weight, of observations
  supporting the rival.

- omega:

  Positive number. The bias factor: how many times as likely the search
  was to find a pro-working-theory observation as a pro-rival one.
  Default `1`, an unbiased search.

## Value

A length-1 numeric: the Bayes factor in favor of the working theory.

## Details

Each claim is a range of shares rather than one share, so neither gives
a probability for the counts on its own. This function averages the
binomial probability of the counts over each theory's range, giving
every share in a range the same weight, and divides the working theory's
average by the rival's. At nine observations for the working theory and
three for the rival the two averages are 0.14675 and 0.00710, and the
Bayes factor is 20.67.
[`bf_worst_case()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/bf_worst_case.md)
keeps the same numerator and evaluates the rival at a share of one half
instead.

The paper's rule sets the rival aside, at least provisionally, when this
value is 20 or more and the worst-case value is above 1. If every share
from zero to one half is equally likely, this value averages exactly one
over the counts the rival's claim could produce, so a researcher who
follows the rule is misled at most one time in twenty on average over
those shares, though not at every share.

## Closed form

With \\N = y_W + y_R\\ and \\S = \sum\_{j=0}^{y_W} \binom{N+1}{j}\\, the
value is \\S / (2^{N+1} - S)\\ (supplement, thm-closed-form). The
function computes the same number as the ratio of the posterior masses
above and below one half under a Beta\\(y_W + 1, y_R + 1)\\
distribution, which is what the equal weights on two equally wide ranges
reduce to.

## A biased search

A search `omega` times as likely to find a pro-working-theory
observation as a pro-rival one turns a share \\\theta\\ of the evidence
into a share \\q = \omega\theta / (\omega\theta + 1 - \theta)\\ among
the observations found. Under bias the function puts \\q\\ in place of
\\\theta\\ inside the binomial probability, keeps the equal weights on
\\\theta\\, and integrates. Granting more bias lowers the value.
[`sens_bias()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/sens_bias.md)
finds the bias at which the value falls to 20.

## Weights on observations

A researcher who counts one observation as worth several routine ones
gives it a whole-number weight and passes the summed weights as the
counts: a memo weighted at ten among nine pro-working-theory
observations gives `bf_uniform_weights(18, 3)`, which is 2,337. These
weights on observations are a different object from the weights on
shares that
[`bf_rescaled()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/bf_rescaled.md)
takes.

## See also

[`bf_worst_case()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/bf_worst_case.md)
for the other Bayes factor from the same model;
[`bf_rescaled()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/bf_rescaled.md)
for weights on shares other than the uniform;
[`bf_uniform_weights_finite()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/bf_finite.md)
for documents read from an archive of known size;
[`sens_bias()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/sens_bias.md)
and
[`sens_coding()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/sens_coding.md)
for the sensitivity analyses.

## Examples

``` r
# The paper's running example: nine observations support the working
# theory, three support the rival.
bf_uniform_weights(9, 3)
#> [1] 20.67196

# A search twice as likely to find pro-working-theory evidence.
bf_uniform_weights(9, 3, omega = 2)
#> [1] 2.854813

# The smoking-gun memo counted as ten observations.
bf_uniform_weights(18, 3)
#> [1] 2336.962
```
