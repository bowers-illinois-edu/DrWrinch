# DrWrinch

Fully specified Bayes factors for process tracing.

This package implements the methods of Lopez, Bowers, and Gajardo Cooper
(2026), “Fully specified Bayes factors for process tracing”
([arXiv:2606.16683](https://arxiv.org/abs/2606.16683)).

A researcher has coded the evidence into two counts: observations
supporting a working theory and observations supporting a single rival.
One model underlies everything here. Each observation supports the
working theory with probability `theta`, the share of the evidence that
supports it. The working theory claims that share is above one half; the
rival claims it is at or below one half.

Each claim names a range of shares rather than one share, so neither
gives a probability for the counts on its own. The package computes two
Bayes factors. They share a numerator — the probability of the counts
averaged over the shares above one half, under uniform weights — and
differ in the denominator.

- [`bf_uniform_weights()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/bf_uniform_weights.md)
  averages over the rival’s whole range under the same uniform weights.
  At nine observations supporting the working theory and three
  supporting the rival it gives 20.67.
- [`bf_worst_case()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/bf_worst_case.md)
  evaluates the rival at the share that makes the counts most probable,
  one half at these counts. It gives 2.73, the smallest Bayes factor any
  weights on the rival’s shares can give.

Under the paper’s rule, a researcher sets the rival aside, at least
provisionally, when the uniform-weights Bayes factor is 20 or more and
the worst-case Bayes factor is above 1. Nine of twelve meets both
conditions.

[`sens_bias()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/sens_bias.md)
and
[`sens_coding()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/sens_coding.md)
report how biased the search, or how many observations re-coded, it
would take before a researcher following the rule would no longer set
the rival aside: at nine of twelve, a search about one percent more
likely to find pro-working-theory evidence, or one re-coded observation.
[`bf_rescaled()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/bf_rescaled.md)
computes the uniform-weights Bayes factor under weights on the shares
other than the uniform, and
[`bf_worst_case()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/bf_worst_case.md)
takes the same weights for the working theory’s shares.
[`bf_uniform_weights_finite()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/bf_finite.md)
and
[`bf_worst_case_finite()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/bf_finite.md)
compute both Bayes factors for documents read without replacement from
an archive of known size.

The package is named after [Dorothy Maud
Wrinch](https://en.wikipedia.org/wiki/Dorothy_Maud_Wrinch) (1894–1976),
the mathematician whose joint papers with Harold Jeffreys (1919, 1921,
1923) developed the framework that became Jeffreys’s theory of Bayes
factors. A companion package,
[DrBristol](https://github.com/bowers-illinois-edu/DrBristol),
implements p-value methods for the same class of problems.

## Installation

``` r

remotes::install_github("bowers-illinois-edu/DrWrinch")
```

## Interactive app

DrWrinch ships with a Shiny app that shows both Bayes factors and the
sensitivity analyses through a browser:

``` r

DrWrinch::run_app()
```

A hosted copy is at <https://jakebowers.shinyapps.io/drwrinch/>. Its
defaults reproduce the paper’s running example: nine observations for
the working theory, three for the rival, and thresholds of 20 and 1. The
Result tab shows the two Bayes factors side by side above a picture of
the three probabilities they are built from, so a reader can see where
each number comes from rather than take it on trust. The Sensitivity tab
reports how biased the search, or how many observations re-coded, it
would take to change the decision.

## Status

The package is under active development alongside the paper, which
compares a working theory with one rival at a time. The authors are
developing extensions to several rivals in a companion paper, and those
may become a separate package.
