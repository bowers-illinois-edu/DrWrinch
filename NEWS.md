# DrWrinch 0.0.1.9001

* Added `sens_coding()` -- the coding-error sensitivity tipping point
  for both models: the smallest number of pro-working-theory
  observations that would have to be re-coded as pro-rival before the
  Bayes factor drops below the threshold. This is the paper's third
  sensitivity question, alongside observation bias (`omega_star`) and
  the rival-tilted prior (`M_star`). It is also surfaced in the Shiny
  app's Sensitivity tab.
* Refreshed the running example throughout (function examples, vignette,
  README, Shiny defaults) to the paper's `(y_W = 9, y_R = 3)` case,
  matching the submitted manuscript: the binomial Bayes factor is 20.67
  (just above the threshold of 20) and the hypergeometric is 323. The
  earlier `(7, 3)` example predated a revision of the paper.
* `inst/CITATION` now points to the preprint, arXiv:2606.16683.

# DrWrinch 0.0.1.9000

* Added `run_app()` -- an interactive Shiny app exposing the four
  core functions through a browser UI. Inputs (y_W, y_R, threshold)
  sit in a sidebar with theta_cut, prior_a, and prior_b tucked into
  an Advanced accordion. The main panel has three tabs: Result
  (Binomial / Urn sub-tabs with formatted Bayes factors, Kass &
  Raftery verdicts, and direction labels), Sensitivity (tipping-
  point prose plus plotly curves of BF vs. omega and BF vs. M), and
  About (running example, verdict scale, and sources).
* Added `shiny (>= 1.7.0)`, `bslib (>= 0.6.0)`, and `plotly (>=
  4.10.0)` to `Suggests`. The Shiny stack is runtime-only; the four
  core Bayes factor functions remain usable without it. `run_app()`
  guards each dependency with `requireNamespace()` and reports a
  clear install hint on miss.
* Dropped the unused `DrBristol` cross-reference from `Suggests`
  (it was never `library()`-ed in any R, test, or vignette code and
  was blocking the GitHub Actions workflows).
* Repository published at
  https://github.com/bowers-illinois-edu/DrWrinch; pkgdown site at
  https://bowers-illinois-edu.github.io/DrWrinch/; Shiny app
  deployed to https://jakebowers.shinyapps.io/drwrinch/.

# DrWrinch 0.0.0.9002

* CRAN-readiness additions: `Depends: R (>= 4.0.0)`, `cph` role on all
  authors, `inst/CITATION` pointing to the working paper.
* Added `vignettes/getting-started.Rmd` walking through the paper
  running example with both models and the sensitivity tipping points.
* Added `cran-comments.md` for submission.
* Added GitHub Actions workflows for R CMD check (matrix across
  Ubuntu / macOS / Windows) and pkgdown deployment.
* Added `_pkgdown.yml` for the package website.

# DrWrinch 0.0.0.9001

* Implemented `bf_urn()` (Formulation C of the hypergeometric urn model:
  WTF = `(y_W + 1, max(1, y_R))`, RTF = `(y_W, y_W + 1)`).
* Extended `bf_binomial()` with observation-bias parameter `omega` and
  general Beta priors.
* Implemented `sens_binomial()` and `sens_urn()` (bias and prior tipping
  points via `uniroot`).
* Added `tests/testthat/` covering the substantive properties: BF = 1
  under symmetric evidence, the paper's analytical value `bf_urn(7, 3)
  = 39`, RTF-degeneracy at `y_R > y_W + 1`, pseudo-observation prior
  equivalence, and parity with the paper's `sens_bias_hyper_separated`.

# DrWrinch 0.0.0.9000

* Initial skeleton renamed from `FullBF`.
