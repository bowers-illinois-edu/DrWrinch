# DrWrinch

Fully specified Bayes factors for process tracing.

This package implements the methods of Lopez, Bowers, and Gajardo Cooper
(2026), "Fully specified Bayes factors for process tracing"
([arXiv:2606.16683](https://arxiv.org/abs/2606.16683)).

A researcher has coded her evidence into two counts: observations
supporting her working theory and observations supporting a single
rival. One model underlies everything here. Each observation supports
the working theory with probability `theta`, the share of the evidence
that supports it. The working theory claims that share is above one
half; the rival claims it is at or below one half.

The rival's claim names a range of shares rather than one share, so it
gives no probability for the counts on its own, and turning the range
into one number takes a rule. Two rules are available that a reader can
neither call arbitrary nor call self-serving, so the package computes
two Bayes factors. They share a numerator --- the probability of the
counts averaged over the shares above one half, under uniform weights
--- and differ only in the denominator.

- `bf_uniform_weights()` averages over the rival's whole range under
  the same uniform weights. At nine observations supporting the working
  theory against three supporting the rival it gives 20.67.
- `bf_worst_case()` evaluates the rival's claim at the single share, one
  half, that makes the observed counts most probable. At the same counts
  it gives 2.73. No weighting of her range stated before coding would
  make the evidence against her look weaker, so this value is a lower
  bound, and it carries an error rate: a researcher who sets the rival
  aside at 20 is misled at most one time in twenty when the rival is
  right, whatever the size of the body of evidence she drew from.

`bf_rescaled()` computes the first under weights the researcher states
instead of the uniform default. `separation_g()` reports how far apart
the two theories' claims would have to be before the counts reach a
threshold. `sens_coding()` and `sens_binomial()` ask what a reader would
have to grant --- re-coded observations, a biased search, or background
cases favoring the rival --- before the report would change.

The package is named after [Dorothy Maud
Wrinch](https://en.wikipedia.org/wiki/Dorothy_Maud_Wrinch) (1894--1976),
the mathematician whose joint papers with Harold Jeffreys (1919, 1921,
1923) developed the framework that became Jeffreys's theory of Bayes
factors. A companion package, [DrBristol](https://github.com/bowers-illinois-edu/DrBristol),
implements p-value methods for the same class of problems.

## Installation

```r
remotes::install_github("bowers-illinois-edu/DrWrinch")
```

## Interactive app

DrWrinch ships with a Shiny app that shows both Bayes factors and the
sensitivity analyses through a browser:

```r
DrWrinch::run_app()
```

A hosted copy lives at <https://jakebowers.shinyapps.io/drwrinch/>.
Defaults reproduce the paper's running example (`y_W = 9, y_R = 3,
threshold = 20`). The Result tab shows the two Bayes factors side by
side above a picture of the three probabilities they are built from, so
a reader can see where each number comes from rather than take it on
trust. The Sensitivity tab reports what would have to be granted for
the report to change.

## Status

Under active development alongside the paper. The single-rival case is
the current focus. Multiple-rival extensions are being developed in a
companion paper and may live in a separate package.
