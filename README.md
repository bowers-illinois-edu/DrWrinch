# DrWrinch

Fully specified Bayes factors for process tracing.

This package implements the methods of Lopez, Bowers, and Gajardo Cooper
(2026), "Fully specified Bayes factors for process tracing"
([arXiv:2606.16683](https://arxiv.org/abs/2606.16683)). Two
generative models for evidence in favor of a working theory against a
single rival --- a binomial model for open-ended evidence and a
hypergeometric urn model for bounded archives --- each yield a
conservative Bayes factor. Sensitivity analyses vary coding error,
observation bias, and the prior.

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

DrWrinch ships with a Shiny app that exposes the Bayes-factor and
sensitivity functions through a browser UI:

```r
DrWrinch::run_app()
```

A hosted copy lives at <https://jakebowers.shinyapps.io/drwrinch/>.
Defaults reproduce the paper's running example (`y_W = 9, y_R = 3,
threshold = 20`); the Sensitivity tab reports the coding-error,
observation-bias (omega_star), and prior (M_star) tipping points with
plotly curves.

## Status

Under active development alongside the paper. The single-rival case is
the current focus. Multiple-rival extensions are being developed in a
companion paper and may live in a separate package.
