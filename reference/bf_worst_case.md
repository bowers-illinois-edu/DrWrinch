# Worst-case Bayes factor: the rival at its most favorable share

A researcher has coded the evidence into two counts: `y_W` observations
support the working theory and `y_R` support a single rival. One model
underlies both Bayes factors in this package. Each observation supports
the working theory with probability \\\theta\\, the share of the
evidence that supports it. The working theory claims \\\theta \> 1/2\\
and the rival claims \\\theta \le 1/2\\.

## Usage

``` r
bf_worst_case(y_W, y_R, omega = 1, a1 = 1, b1 = 1)
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

- a1, b1:

  Positive numbers. The Beta pair rescaled onto the working theory's
  shares. Default `1` and `1`, uniform weights.

## Value

A length-1 numeric: the Bayes factor in favor of the working theory with
the rival at its most favorable share.

## Details

The numerator is the one
[`bf_uniform_weights()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/bf_uniform_weights.md)
uses: the binomial probability of the counts averaged over the shares
above one half. The denominator is the largest probability any weights
on the rival's shares can give the counts. When at least as many
observations support the working theory as the rival, the probability of
the counts rises on the whole of the rival's range, so that largest
probability is the one at a share of one half. The value is therefore
the smallest Bayes factor a critic can produce by changing only the
weights on the rival's shares (supplement, prp-bound). At nine
observations for the working theory and three for the rival it is 7814 /
2860 = 2.73.

The paper's rule sets the rival aside, at least provisionally, when the
uniform-weights value is 20 or more and this value is above 1. A value
above 1 means that no weights on the rival's shares make the counts more
probable under the rival than under the working theory.

## Closed form

With \\N = y_W + y_R\\, uniform weights on the working theory's shares,
and no bias, the value is \$\$\frac{\sum\_{j=0}^{y_W}
\binom{N+1}{j}}{(N+1)\binom{N}{y_W}}\$\$ (supplement, thm-closed-form).
The paper evaluates the rival at one half at every count, and so does
this function when `y_W < y_R`; at those counts the value is below 1 and
the rule keeps the rival whichever share the rival is held at.

## Stated weights on the working theory's shares

`a1` and `b1` replace the uniform weights in the numerator with a
Beta\\(a_1, b_1)\\ distribution rescaled onto the shares above one half:
if \\X\\ has that distribution, \\\theta = 1/2 + X/2\\. Only the working
theory's weights enter, because the rival is evaluated at its most
favorable share whatever weights its proponent might state. At nine of
twelve, Beta(1/2, 1/2) gives 2.07 and Beta(10, 10) gives 4.38. No
weights give more than 4.81, the value with all the weight on a share of
nine twelfths.

## A biased search

A search `omega` times as likely to find a pro-working-theory
observation as a pro-rival one turns a share \\\theta\\ of the evidence
into a share \\q = \omega\theta / (\omega\theta + 1 - \theta)\\ among
the observations found. The numerator averages the probability of the
counts at \\q\\ over the working theory's shares. The rival's shares
become shares found of at most \\\omega / (1 + \omega)\\, and the counts
are most probable at a share found of \\y_W / N\\, so the denominator is
the probability at whichever of the two is smaller.

Up to \\\omega = y_W / y_R\\ that is the probability at a share of one
half, which is the value the paper's code computed. Past it the rival's
most favorable share is below one half. At nine of twelve and \\\omega =
5\\, one half becomes 5/6 found, where nine of twelve has probability
0.197, while a share of 0.375 becomes 0.75 found, where it has
probability 0.258; the numerator is 0.0554, so the value is 0.0554 /
0.258 = 0.21 rather than 0.0554 / 0.197 = 0.28. The bias at which the
value falls to 1 always comes before \\y_W / y_R\\, so
[`sens_bias()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/sens_bias.md)
gives the same tipping point under either reading.

## See also

[`bf_uniform_weights()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/bf_uniform_weights.md)
for the Bayes factor that averages over the rival's whole range;
[`bf_worst_case_finite()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/bf_finite.md)
for documents read from an archive of known size;
[`sens_bias()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/sens_bias.md)
and
[`sens_coding()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/sens_coding.md)
for the sensitivity analyses.

## Examples

``` r
# The paper's running example: nine observations support the working
# theory, three support the rival.
bf_worst_case(9, 3)
#> [1] 2.732168

# Seven of twelve falls below one: a rival who may claim an evenly
# split body of evidence is not embarrassed by those counts.
bf_worst_case(7, 5)
#> [1] 0.5644911

# The smoking-gun memo counted as ten observations.
bf_worst_case(18, 3)
#> [1] 143.2847

# Weights on the working theory's shares concentrated near 3/4.
bf_worst_case(9, 3, a1 = 10, b1 = 10)
#> [1] 4.384581

# A search twice as likely to find pro-working-theory evidence.
bf_worst_case(9, 3, omega = 2)
#> [1] 0.6661293
```
