# Launch the DrWrinch Shiny app

Starts an interactive Shiny session showing the two Bayes factors the
paper computes from one model, side by side, together with the three
probabilities they are built from: the numerator they share and the two
denominators that separate them. A Sensitivity tab reports what a reader
would have to grant before the researcher's report would change. Every
function the app calls
([`bf_uniform_weights()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/bf_uniform_weights.md),
[`bf_worst_case()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/bf_worst_case.md),
[`sens_bias()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/sens_bias.md),
[`sens_coding()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/sens_coding.md))
works from the command line without it.

## Usage

``` r
run_app(launch_browser = interactive(), ...)
```

## Arguments

- launch_browser:

  Logical. If `TRUE` (default in interactive sessions), opens the
  default web browser to the app's URL.

- ...:

  Additional arguments passed to
  [`shiny::runApp()`](https://rdrr.io/pkg/shiny/man/runApp.html) (for
  example, `port`, `host`, `display.mode`).

## Value

Invisibly returns the value of
[`shiny::runApp()`](https://rdrr.io/pkg/shiny/man/runApp.html). Called
for its side effect of starting a Shiny session.

## Details

The Shiny stack (shiny, bslib) is in `Suggests`, not `Imports`, so users
who only want the core Bayes factor functions do not have to install it.
`run_app()` checks for these packages at call time and stops with an
install hint if any is missing.

## See also

[`bf_uniform_weights()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/bf_uniform_weights.md)
and
[`bf_worst_case()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/bf_worst_case.md),
the two Bayes factors the app shows;
[`sens_bias()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/sens_bias.md)
and
[`sens_coding()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/sens_coding.md)
for the sensitivity tab.

## Examples

``` r
if (FALSE) { # \dontrun{
run_app()
} # }
```
