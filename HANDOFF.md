---
next: In ~/repos/fully_specified_bf, make the edits listed in ~/repos/DrWrinch/PLAN_decision_rule.md under "What the paper repository has to change once DrWrinch 0.0.2.1 is on GitHub", starting with the two cross-checks in tests/bf_weighted.R that call bf_binomial() and bf_urn() through the package, which stop the paper's render once its renv library installs 0.0.2.1.
kind: code
project_kind: R package
milestone: the paper and its appendix built on DrWrinch 0.0.2.1 from GitHub
sessions_to_milestone: 1
blocked_on:
estimated_by: backfill 2026-10-25
---

# HANDOFF for DrWrinch

Last touched: 2026-10-27. Read `PLAN_decision_rule.md` next. It records
what changed in the paper between 2026-08-29 and 2026-10-19, the four
choices Jake made on 2026-10-27, the tests written before the code, and
the edits the paper repository needs once this version is on GitHub.

## What DrWrinch is

The R package implementing Lopez, Bowers, and Gajardo Cooper (2026),
"Fully specified Bayes factors for process tracing." The paper is in
`~/repos/fully_specified_bf` and is the source of truth for notation and
methods. Named after Dorothy Maud Wrinch (1894--1976), whose joint papers
with Harold Jeffreys developed the framework that became Jeffreys's theory
of Bayes factors. The companion package `DrBristol` (`~/repos/DrBristol`)
implements p-value methods for the same problems; the two stay separate.

## State of the package, 2026-10-27

Version 0.0.2.1, commit `f3c04a8`, pushed to `main` on 2026-10-27. All
134 tests (1101 expectations) succeed with no warnings, and
`devtools::check()` reports 0 errors, 0 warnings, 0 notes. The pkgdown
workflow rebuilt the site from that commit; its previous run, on
2026-08-30, had failed. The hosted app runs 0.0.2.1: both tabs render the
running example, with the rule set aside at 20.67 and 2.73, one re-coding,
and a bias of 1.01.

The paper's rule sets the rival aside, at least provisionally, when the
uniform-weights Bayes factor is 20 or more and the worst-case Bayes factor
is above 1. The exported functions follow it:

- `bf_uniform_weights(y_W, y_R, omega)`, in `R/bf_uniform_weights.R`.
- `bf_worst_case(y_W, y_R, omega, a1, b1)`, in `R/bf_worst_case.R`. Under
  bias it divides by the largest probability any rival share gives the
  counts, which moves below a share of one half once `omega > y_W / y_R`
  (Jake's decision of 2026-10-27; the paper's five affected table cells
  are to be recomputed to match). When `y_W < y_R` the rival stays at one
  half, as in the paper's closed form.
- `bf_rescaled()`, in `R/bf_rescaled.R`.
- `bf_uniform_weights_finite()` and `bf_worst_case_finite()`, in
  `R/bf_finite.R`, for an archive of known size.
- `sens_bias()` and `sens_coding()`, in `R/sens_bias.R` and
  `R/sens_coding.R`. Each returns the tipping point for each condition of
  the rule and the smaller of the two.
- `run_app()`, in `R/run_app.R`.

Removed in this version, without deprecation because no one else uses the
package: `bf_binomial()`, `bf_urn()`, `sens_urn()`, `sens_binomial()`,
`bf_separated()`, `separation_g()`, `bf_separated_bias()`, and the
deprecation helper. `BiasedUrn`, `ggplot2`, and `dplyr` left DESCRIPTION.

The Shiny app (`inst/shiny/`) takes two thresholds, opens the Result tab
with what the rule decides, and on the Sensitivity tab reports the coding
and bias tipping points under the rule beside one plot of both Bayes
factors against the bias. `.dw_needed` in `inst/shiny/global.R` is
0.0.2.1.

## Public surface

- GitHub: https://github.com/bowers-illinois-edu/DrWrinch, `main` at
  0.0.2.1.
- pkgdown site: https://bowers-illinois-edu.github.io/DrWrinch/, rebuilt
  by the pkgdown workflow on every push to `main`. `_pkgdown.yml` lists
  the new reference index.
- Shiny app: https://jakebowers.shinyapps.io/drwrinch/, deployed with
  `source("deploy.R")` from the repository root. It runs 0.0.2.1.
- CRAN is on hold indefinitely (Decision F of `PLAN_SHINY.md`).

## The paper repository

The paper still sources its own `tests/*.R`. Two cross-checks in its
`tests/bf_weighted.R` call `DrWrinch::bf_binomial()` and
`DrWrinch::bf_urn()`, so the paper, the supplement, and the replications
will stop with an error as soon as the paper's renv library installs this
version. `PLAN_decision_rule.md` lists those fixes, the supplement's
reproduction section rewrite, the `renv.lock` update, and the five
worst-case cells. The current arXiv preprint's reproduction section calls
removed functions, so the next arXiv replacement is what brings the
preprint and the package back into agreement.

## Deployment failures and their fixes

- **Install DrWrinch from GitHub on this machine before deploying**
  (2026-10-27). `rsconnect` records the locally installed DrWrinch in the
  manifest, and shinyapps.io builds the image from that record. With an
  older local copy (0.0.1.9000 then), the image held the old version,
  `global.R` fell back to `install_github()` at start-up, and that
  anonymous call failed with GitHub's API rate limit (HTTP 403, 60
  requests an hour shared by every app on the server's address), so the
  app failed to start. After `remotes::install_github(
  "bowers-illinois-edu/DrWrinch")` here and a second deploy, the image held
  0.0.2.1 and the app started without contacting GitHub.

- **Stale GITHUB_PAT in `~/.Renviron`** (commented out 2026-05-19,
  with a note pointing to https://github.com/settings/tokens for a
  fresh one). If `remotes::install_github` ever falls back to
  anonymous unexpectedly, check that this token still works.
- **shinyapps.io's "401 fetching GitHub" failure mode** is almost
  always a stale OAuth cache, not a missing PAT. The toggle-on /
  toggle-off cycle in Posit Authentication is the fix.
- **shinyapps.io's "stale DrWrinch / function-not-found" failure mode**
  (hit and fixed 2026-06-22). shinyapps installs DrWrinch into the
  read-only system library (`/usr/lib/R`) at image-build time from its
  manifest, and that copy can lag GitHub HEAD. A runtime
  `install_github` cannot overwrite it (`mv ... Permission denied`,
  "cannot remove earlier installation, is it in use?"), so the app
  silently keeps the old version and errors on any newer function (this
  session: `'sens_coding' is not an exported object`). The symptom is a
  tab-level "An error has occurred" with the plots still rendering, and
  the real cause is only visible via `rsconnect::showLogs()`. Fix in
  `inst/shiny/global.R`: install the required version into a writable,
  session-local library (`tempdir()`) placed FIRST on `.libPaths()`,
  shadowing the stale system copy. Check the installed version with
  `packageVersion()` --- NOT `requireNamespace()`, which loads the old
  namespace and then blocks `library()` from picking up the reinstall.
  The GitHub download and build succeed at runtime; only the install
  *location* has to be writable. Each cold start spends about 30 seconds
  on this install. When the
  required version changes, bump `.dw_needed` in `global.R`.
- **`rsconnect` refuses to bundle locally-installed packages** that
  lack `RemoteType` metadata. Trying to dodge GitHub via a local
  tarball doesn't work cleanly; the right workarounds are
  (a) fix the OAuth cache (what worked this session), (b)
  R-universe.
- **The Shiny app pulls DrWrinch from GitHub on shinyapps.io cold
  start** via the `install_github` stanza in
  `inst/shiny/global.R`, about 30 seconds per cold start. Local
  development skips it, because `devtools::load_all()` has already
  loaded the current version.

## Still open

- `inst/CITATION` points to the arXiv preprint (arXiv:2606.16683). Add
  the journal DOI when the paper is published.
- The app has no `shinytest2` snapshot tests. The helpers and the reactive
  graph are tested through `testthat` and `shiny::testServer()`.
- GitHub authentication is switched off in Posit's settings. Publishing to
  Posit Cloud would need it switched on again.
