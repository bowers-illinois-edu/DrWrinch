# DrWrinch 0.0.2.0

* Added `bf_worst_case()`, `bf_separated()`, `separation_g()`, and
  `bf_separated_bias()` -- the second Bayes factor from the paper's one
  model, which evaluates the rival's claim at the single share, one
  half, that makes the observed counts most probable, plus the version
  that separates the two theories' claims by a stated margin and the
  margin at which a threshold is reached.
* Added `bf_uniform_weights()`, the documented name for the Bayes factor
  that averages over the rival's whole range of shares under uniform
  weights. `bf_binomial()` returns the same number at its defaults and
  is kept for one release.
* Added `bf_rescaled()`, which computes that same Bayes factor under
  weights the researcher states within each theory's range: a Beta(a, b)
  distribution squeezed onto each half, one pair per side.
* The Shiny app now shows the two Bayes factors from one model side by
  side, above a picture of the three probabilities they are built from:
  the numerator they share and the two denominators that separate them.
  Dividing the first bar by the second gives the uniform-weights value
  and by the third gives the worst-case value, so a reader can see where
  each number comes from. The urn panel is gone. The sensitivity tab
  reports the recoding table for the worst-case Bayes factor beside the
  tipping point for the uniform-weights one.
* The app's sidebar no longer offers a cutpoint or a Beta prior on the
  whole interval. The cutpoint applies to only one of the two Bayes
  factors, so moving it left the two cards showing numbers that could
  not be compared; the whole-interval prior made the reported quantity
  the posterior odds while the card called it a Bayes factor. A reader
  who wants either calls `bf_binomial()` or `bf_rescaled()` directly.
* The app's prior-sweep curve and prose now say posterior odds
  throughout, and the data function behind the curve is renamed
  `post_odds_M_curve()` with a `post_odds` column.
* README, the package documentation, the DESCRIPTION, and the
  getting-started vignette describe one model and two Bayes factors. The
  vignette derives every number it reports rather than asserting it.

* `bf_urn()` and `sens_urn()` are deprecated. The paper began with two
  probability models and now has one, so the hypergeometric urn model is
  no longer in it. Neither function is removed and neither returns
  anything different: the first arXiv version of the paper cites them and
  its replication code calls them. Each warns once per session, naming
  the replacement -- `bf_worst_case()` and `bf_uniform_weights()` for the
  Bayes factors, `bf_separated_bias()` and `sens_coding(model =
  "worst_case")` for the sensitivity questions `sens_urn()` answered. The
  notice fires once rather than on every call because
  `sens_coding(model = "urn")` recomputes the urn Bayes factor at every
  re-coding.
* `sens_coding()`'s `model` argument now takes `"uniform_weights"` (the
  default) and `"worst_case"`; `"binomial"` is accepted as the earlier
  name for the first and returns the same thing, and `"urn"` still works
  for the superseded model. Under `"worst_case"` the function returns a
  recoding table rather than a tipping point: one row per re-coding with
  the recomputed Bayes factor and the separation at which the two-share
  version reaches the threshold, reproducing the supplement's table. Its
  question is different because at counts like nine against three the
  worst-case Bayes factor was never above 20, so re-coding cannot
  overturn a conclusion the researcher did not draw.
* `sens_binomial()`'s help now says that `M_star` is a tipping point in
  the *posterior odds*, not the Bayes factor. As the `Beta(1, M + 1)`
  prior tilts toward the rival the Bayes factor rises, so the object the
  old help described did not exist.
* **Documentation correction.** `bf_binomial()`'s help said it returned
  "the Bayes factor" whatever the prior. It returns the ratio of
  posterior masses either side of the cut, which is the *posterior
  odds*. A Beta prior on the whole interval sets how much weight each
  theory gets as well as how weight is spread within each theory's
  range, and the Bayes factor renormalizes the first away while the
  posterior odds keep it. The two coincide only at the uniform prior; at
  nine observations against three under Beta(1, 2) the posterior odds
  are 10.14 while the Bayes factor is 30.41, and they move in opposite
  directions as the prior tilts further toward the rival. The help page
  now says so and `test-bf_uniform_weights.R` pins both columns.
  `sens_binomial()`'s `M_star` is a tipping point in the posterior odds,
  and its help still needs the same correction.

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
