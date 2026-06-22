# Getting started with DrWrinch

``` r

library(DrWrinch)
```

## The problem

A researcher classifying within-case evidence for a working theory
($`H_1`$) against a single rival ($`H_R`$) wants to summarize the weight
of evidence with a Bayes factor. The challenge is that the
per-observation probabilities a Bayes factor requires are hard to
motivate without overcommitting. DrWrinch supplies two fully specified
generative models that produce those probabilities, both tilted against
$`H_1`$ by construction, so the reported Bayes factor is a lower bound
on the evidence in favor of the working theory.

This vignette works the running example from Lopez, Bowers, and Gajardo
Cooper (2026): nine pieces of evidence favoring $`H_1`$ and three
favoring $`H_R`$.

## Two models

**Binomial model.** Each observation is an independent Bernoulli draw
from an infinite evidence universe with success probability $`\theta`$.
$`H_1`$ corresponds to $`\theta > 1/2`$. Under a uniform prior on
$`\theta`$, the Bayes factor is the ratio of posterior masses on the two
sides of $`1/2`$. This model fits research designs where the evidence
universe is open-ended: ongoing interviews, an expanding archive.

``` r

bf_binomial(y_W = 9, y_R = 3)
#> [1] 20.67196
```

**Hypergeometric urn model (Formulation C).** Evidence is drawn without
replacement from a finite urn. The Working Theory Favorable (WTF)
sub-model has urn composition $`(y_W + 1, \max(1, y_R))`$; the Rival
Theory Favorable (RTF) sub-model has urn composition $`(y_W, y_W + 1)`$.
The construction adds one unobserved pro-$`H_1`$ item to the working
theory’s urn and tilts the rival’s urn toward $`H_R`$ by exactly one
item. This model fits research designs where the evidence base is
bounded: a closed historical archive, a fixed roster of documents.

``` r

bf_urn(y_W = 9, y_R = 3)
#> [1] 323
```

The hypergeometric BF of 323 has a closed form:
$`(10/13) / (120/50388) = 323`$.

## When does each model apply?

| Design | Model |
|----|----|
| Ongoing interviews, growing archive, open-ended fieldwork | [`bf_binomial()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/bf_binomial.md) |
| Closed historical archive, fixed roster of documents | [`bf_urn()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/bf_urn.md) |

When in doubt, compute both. They report different but compatible
quantities: the binomial conditions on the evidence universe being
infinite; the urn conditions on it being bounded.

## A property worth knowing

Under symmetric evidence ($`y_W = y_R`$), both Bayes factors are exactly
$`1`$ – no evidence in either direction.

``` r

bf_binomial(5, 5)
#> [1] 1
bf_urn(5, 5)
#> [1] 1
```

For
[`bf_urn()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/bf_urn.md)
this is the central property distinguishing Formulation C from naive
constructions: the urn model returns 1 rather than $`\infty`$ or $`0`$
at the equipoise point.

## Sensitivity to observation bias

A reviewer might ask: how robust is the conclusion to the possibility
that pro-$`H_1`$ items were more likely to be observed than pro-$`H_R`$
items?
[`sens_urn()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/sens_urn.md)
reports the smallest observation-bias factor $`\omega > 1`$ at which the
Bayes factor first drops below a decision threshold (the default
threshold is $`20`$, the conventional cutoff for “strong” evidence).

``` r

s_urn <- sens_urn(9, 3, threshold = 20)
s_urn$bf
#> [1] 323
s_urn$omega_star
#> [1] 2.433984
```

The reading: pro-$`H_1`$ items would have had to be roughly 2.4 times
more likely to be noticed than pro-$`H_R`$ items before the urn
conclusion reverses.

## Sensitivity to coding error

A peer who cannot re-read every document can still ask how many of the
pro-$`H_1`$ observations would have to be re-coded as pro-$`H_R`$ before
the conclusion changes.
[`sens_coding()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/sens_coding.md)
reports that tipping point for either model: re-coding $`x`$
observations moves the counts from $`(y_W, y_R)`$ to
$`(y_W - x, y_R + x)`$ and recomputes the same Bayes factor.

``` r

sens_coding(9, 3, model = "binomial", threshold = 20)$x_star
#> [1] 1
sens_coding(9, 3, model = "urn", threshold = 20)$x_star
#> [1] 2
```

One re-coding overturns the binomial conclusion and two overturn the
hypergeometric. The binomial tolerates less because its Bayes factor
(20.67) starts only just above the threshold; the urn starts at 323 and
so absorbs one more re-coding before crossing.

## Sensitivity to the prior on $`\theta`$

For the binomial model,
[`sens_binomial()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/sens_binomial.md)
additionally reports the smallest rival-tilted prior at which the
conclusion reverses. The prior $`\text{Beta}(1, M + 1)`$ posits $`M`$
pseudo-observations all favoring the rival; `M_star` is the smallest
such $`M`$ that drives the Bayes factor below threshold.

``` r

s_binom <- sens_binomial(9, 3, threshold = 20)
s_binom$bf
#> [1] 20.67196
s_binom$omega_star
#> [1] 1.00981
s_binom$M_star
#> [1] 1
```

At the running example the binomial Bayes factor only just clears the
threshold, so `M_star` is 1: a single rival-favoring pseudo-observation
in the prior drops it below 20. A larger evidence base would tolerate
more.

## Weighted evidence

A researcher who believes one observation carries more probative weight
than the others can sum integer weights and pass the totals:

``` r

# Eight ordinary pro-H1 items at weight 1 and one "smoking gun" at
# weight 10, matching the paper's weighted running example: W = 8 + 10 = 18.
w_W <- c(10, rep(1, 8))
w_R <- rep(1, 3)
bf_binomial(sum(w_W), sum(w_R))
#> [1] 2336.962
bf_urn(sum(w_W), sum(w_R))
#> [1] 11475735
```

The “+1” rival-favoring construction goes through unchanged. See the
paper’s discussion of probative weight for the rationale.
