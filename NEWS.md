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
