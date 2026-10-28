# The uniform-weights Bayes factor under weights the researcher states

A range of shares is not a probability for the counts, so before coding
the researcher states how each theory spreads its weight over the shares
inside its range.
[`bf_uniform_weights()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/bf_uniform_weights.md)
uses the default, which gives every share in a range the same weight.
This function takes the alternative the paper offers, so that a reader
who would have weighted the shares differently can see what those
weights do to the reported number.

## Usage

``` r
bf_rescaled(y_W, y_R, a1 = 1, b1 = 1, aR = 1, bR = 1)
```

## Arguments

- y_W:

  Non-negative integer. Count (or summed integer weight) of evidence
  favorable to the working theory.

- y_R:

  Non-negative integer. Count (or summed integer weight) of evidence
  favorable to the rival.

- a1, b1:

  Positive numerics. The Beta pair squeezed onto the working theory's
  range, the shares above one half. Default `1` and `1`, the uniform
  weights.

- aR, bR:

  Positive numerics. The Beta pair squeezed onto the rival's range, the
  shares at or below one half. Default `1` and `1`.

## Value

A length-1 numeric: the Bayes factor in favor of the working theory
under the stated weights.

## Details

The alternative starts from the Beta\\(a, b)\\ family, a family of
distributions for a quantity between zero and one whose two parameters
set where the weight piles up: with \\a \> b\\ toward one, with \\a \<
b\\ toward zero, and with \\a = b\\ symmetrically, concentrated in the
middle when \\a = b\\ is above one and pushed toward both ends when it
is below one. Larger values of both parameters concentrate the weight
more tightly.

Each theory's range is half as wide as the interval from zero to one, so
the researcher squeezes a Beta distribution onto it. If \\X\\ has the
Beta\\(a, b)\\ distribution, then \\\theta = 1/2 + X/2\\ lies between
one half and one, which is the working theory's range, and \\\theta =
X/2\\ lies between zero and one half, which is the rival's. Squeezing an
interval to half its width doubles the density, so the two weighting
functions are \$\$2 f\_{a,b}(2\theta - 1) \quad\text{and}\quad 2
f\_{a,b}(2\theta),\$\$ with \\f\_{a,b}\\ the Beta density. Setting both
pairs to \\(1, 1)\\ gives every share in each range the same weight and
returns
[`bf_uniform_weights()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/bf_uniform_weights.md)
exactly.

## What the parameters mean substantively

The two pairs are a claim about what each theory predicts, and they move
the reported number, so a researcher has to argue for them. At nine
observations supporting the working theory against three supporting the
rival, the uniform default gives 20.67. Beta(1/2, 1/2) on both sides
piles weight at both ends of each range, including right next to one
half where the two theories predict nearly the same share, so the counts
separate the theories less and the value falls to 9.53. Beta(10, 10) on
both sides concentrates each theory near the middle of its range, so the
working theory predicts a share near three quarters and the rival a
share near one quarter, the two predict more different things, and the
value rises to 252.92.

The pairs need not match. A researcher who expects that under either
theory the search would still turn up evidence for the other puts both
densities next to one half, with `a1 = 0.5, b1 = 1` for the working
theory and `aR = 1, bR = 0.5` for the rival, and gets 7.35 at nine of
twelve. A researcher who expects each theory to leave almost no evidence
for the other pushes both densities to the far ends, reversing those two
pairs, and gets 28.08. The first value is below the paper's threshold of
20 and the second is above it.

## Weights on shares are not weights on observations

The weights here are weights on \\\theta\\, the share of the evidence
supporting the working theory. They are a different object from a weight
on an observation, which acts as replication: a document the researcher
weights at ten enters as ten observations, and the researcher passes
that by summing the weights into `y_W` and `y_R`.

## See also

[`bf_uniform_weights()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/bf_uniform_weights.md)
for the uniform default;
[`bf_worst_case()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/bf_worst_case.md),
whose `a1, b1` take the same rescaled pair for the working theory's
shares while the rival is evaluated at its most favorable share.

## Examples

``` r
# The uniform default, which is bf_uniform_weights(9, 3).
bf_rescaled(9, 3)
#> [1] 20.67196

# Beta(1/2, 1/2) on both sides: weight next to one half, where the
# two theories claim nearly the same share.
bf_rescaled(9, 3, 0.5, 0.5, 0.5, 0.5)
#> [1] 9.526137

# Beta(10, 10) on both sides: each theory concentrated in the middle
# of its range, so the two claims are far apart.
bf_rescaled(9, 3, 10, 10, 10, 10)
#> [1] 252.9172
```
