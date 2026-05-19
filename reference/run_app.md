# Launch the DrWrinch Shiny app

Starts an interactive Shiny session that computes the binomial and urn
Bayes factors and their verdicts on the Kass & Raftery (1995) scale. The
four core functions
([`bf_binomial()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/bf_binomial.md),
[`bf_urn()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/bf_urn.md),
[`sens_binomial()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/sens_binomial.md),
[`sens_urn()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/sens_urn.md))
are usable from the command line without launching the app; this
function is a convenience wrapper for users who prefer a GUI.

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

[`bf_binomial()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/bf_binomial.md),
[`bf_urn()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/bf_urn.md),
[`sens_binomial()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/sens_binomial.md),
[`sens_urn()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/sens_urn.md).

## Examples

``` r
if (FALSE) { # \dontrun{
run_app()
} # }
```
