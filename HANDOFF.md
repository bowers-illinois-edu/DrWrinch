# HANDOFF for DrWrinch

Last touched: 2026-05-19 (evening session in `~/repos/DrWrinch/`). Pick
up from here in a fresh Claude session run from `~/repos/DrWrinch/`.

## What DrWrinch is

The R package implementing Lopez, Bowers, and Gajardo Cooper (2026),
“Fully specified Bayes factors for process tracing.” Named after Dorothy
Maud Wrinch (1894–1976; joint papers with Harold Jeffreys in the early
1920s developed the framework that later became Jeffreys’s theory of
Bayes factors).

Companion package `DrBristol` (at `~/repos/DrBristol`) implements
p-value methods for the same class of problems. DrBristol is mature,
GitHub-only, named after Muriel Bristol; DrWrinch is its Bayes-factor
sibling. Do not merge the two.

The paper lives at `~/repos/fully_specified_bf`. Treat the paper as the
source of truth for notation and methodology; DrWrinch is the companion
code. Integration of DrWrinch into the paper is **appendix-only** — see
the project memory at
`~/.claude/projects/-Users-jwbowers-repos-fully-specified-bf/memory/project_drwrinch_paper_integration.md`.

## Current public surface (2026-05-19)

- **GitHub**: <https://github.com/bowers-illinois-edu/DrWrinch> (public,
  in the `bowers-illinois-edu` org). `main` is at version `0.0.1.9000`.
- **pkgdown site**: <https://bowers-illinois-edu.github.io/DrWrinch/>
  (built from `gh-pages` via the pkgdown.yaml workflow on every push to
  `main`).
- **Shiny app**: <https://jakebowers.shinyapps.io/drwrinch/> (deployed
  via `deploy.R` at the repo root; rsconnect targets
  `appName = "drwrinch"` on the `jakebowers` shinyapps.io account).
- **GitHub Actions**: R-CMD-check passes across macOS-release,
  Windows-release, Ubuntu oldrel-1 / release / devel. The pkgdown
  workflow auto-deploys on every push to `main`.

CRAN is on hold indefinitely (per Decision F of `PLAN_SHINY.md`); the
release path is GitHub plus pkgdown plus shinyapps.io, mirroring
DrBristol.

## Current state of the package

Version `0.0.1.9000`. `devtools::test()` passes 195/195 locally and in
CI. `devtools::check()` is clean (0 errors, 0 warnings, 0 notes).

Exported functions: `bf_binomial`, `bf_urn`, `sens_binomial`,
`sens_urn`, `run_app`.

Files of note:

- `R/bf_binomial.R`, `R/bf_urn.R`, `R/sens_binomial.R`, `R/sens_urn.R`,
  `R/utils.R` (internal `.find_omega_tipping`), `R/DrWrinch-package.R`,
  `R/run_app.R`.
- `inst/shiny/` — the deployed Shiny app: `global.R`, `ui.R`,
  `server.R`, and `R/helpers.R` + `R/plots.R` for the formatter and
  plotly wrappers. Verdicts use the Kass & Raftery (1995) scale
  (boundaries `1, 3, 20, 150`, upper-inclusive).
- `tests/testthat/test-bf_binomial.R`, `test-bf_urn.R`, `test-sens.R`,
  `test-app_helpers.R` (Layer 1 helpers + curves), `test-app_server.R`
  (Layer 2
  [`shiny::testServer`](https://rdrr.io/pkg/shiny/man/testServer.html)
  for both BF reactives, the urn-undefined branch, and the
  sensitivity-tab reactives).
- `vignettes/getting-started.Rmd` (paper running example).
- `inst/CITATION` (placeholder bibentry; update with venue/DOI on
  publication).
- `_pkgdown.yml` (Bootstrap 5; reference grouped Bayes factors /
  Sensitivity / Interactive app).
- `.github/workflows/R-CMD-check.yaml`,
  `.github/workflows/pkgdown.yaml`.
- `cran-comments.md` (kept for if/when CRAN comes back into scope).
- `LICENSE`, `LICENSE.md` (MIT; copyright in paper order).
- `NEWS.md`, `README.md`.
- `deploy.R` at repo root (in `.Rbuildignore`). Run from the repo root
  with `source("deploy.R")` to redeploy after changes; relies on
  `rsconnect::setAccountInfo(...)` having been run once on this machine.

Authors in DESCRIPTION (paper order): Matias Lopez (aut, cph), Jake
Bowers (cre, aut, cph), Daniel Gajardo Cooper (aut, cph).

## What this session delivered

1.  **Phase 1 (commit `8e8a6c1`)** — MVP Shiny app:
    [`run_app()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/run_app.md)
    launcher, `inst/shiny/{global.R, ui.R, server.R}`, helpers under
    `inst/shiny/R/helpers.R`, Layer 1 tests for `format_bf` / `bf_label`
    / `interpret_omega_star`, Layer 2 `testServer` tests for `bf_binom`
    / `bf_urn_v` / the urn-undefined card branch. DESCRIPTION bumped to
    `0.0.1.9000`; `shiny` and `bslib` added to Suggests.
2.  **Phase 2 (commit `b60386a`)** — Sensitivity tab with two plotly
    outputs (`plot_omega`, `plot_M`) and the `tipping_text` renderUI
    prose. New helpers: `interpret_M_star`, `bf_omega_curve`,
    `bf_M_curve`. New file `inst/shiny/R/plots.R` for the plotly
    wrappers. `plotly` added to Suggests and to
    [`run_app()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/run_app.md)’s
    `requireNamespace` guard.
3.  **Phase 3 (commit `e582d57`)** — Polish: `validate_counts` now
    rejects non-integer numeric input via `x == round(x)`; About tab
    gained Running-example, Sensitivity-glossary, and Sources sections
    with citation and GitHub link; `inst/shiny/global.R` gained an
    `install_github` stanza for shinyapps.io cold-start; `deploy.R` at
    the repo root; `_pkgdown.yml` gained an Interactive-app reference
    section; `NEWS.md` gained a `0.0.1.9000` block.
4.  **Phase 4 (this commit)** — Live deployment to
    <https://jakebowers.shinyapps.io/drwrinch/>. The deploy initially
    failed with `HTTP 401: Unauthorized` while shinyapps.io’s build
    worker tried to fetch DrWrinch from GitHub — a stale OAuth token
    cached on Posit’s build infrastructure from a
    previously-enabled-now-disabled GitHub linkage in Posit’s
    Authentication settings. The fix was to toggle GitHub auth back on
    in Posit’s user settings, click through the OAuth flow, then toggle
    it back off. README.md and NEWS.md updated with the live URL; the
    orphan `drwrinch-v2` app from a deploy retry is terminated.

## Lessons worth keeping

- **Stale GITHUB_PAT in `~/.Renviron`** (commented out 2026-05-19, with
  a note pointing to <https://github.com/settings/tokens> for a fresh
  one). If `remotes::install_github` ever falls back to anonymous
  unexpectedly, check that this token still works.
- **shinyapps.io’s “401 fetching GitHub” failure mode** is almost always
  a stale OAuth cache, not a missing PAT. The toggle-on / toggle-off
  cycle in Posit Authentication is the fix.
- **`rsconnect` refuses to bundle locally-installed packages** that lack
  `RemoteType` metadata. Trying to dodge GitHub via a local tarball
  doesn’t work cleanly; the right workarounds are
  1.  fix the OAuth cache (what worked this session), (b) R-universe.
- **The Shiny app pulls DrWrinch from GitHub on shinyapps.io cold
  start** via the `install_github` stanza in `inst/shiny/global.R`. ~30s
  one-time install per cold start; no cost in local dev where
  `devtools::load_all()` has already loaded it.

## What is still open

- **CRAN submission**: held indefinitely per Decision F. If resumed, the
  work would be: revisit `cran-comments.md`, ensure
  `R CMD check --as-cran` is clean, decide whether `\dontrun{}` wrapping
  of
  [`run_app()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/run_app.md)
  is the right discipline for CRAN examples (it is), bump version to
  `0.0.1`, submit.
- **`inst/CITATION`** still has a placeholder bibentry. Replace with the
  real venue/DOI on paper publication.
- **Layer 3 `shinytest2` snapshot tests**: skipped this session (heavy,
  fragile across OSes). Worth adding if the Shiny app’s UI starts
  drifting visually; the substantive claims are already pinned at Layers
  1 and 2.
- **Posit GitHub re-link**: GitHub auth is currently disabled in Posit
  Authentication (you toggled it off again after the OAuth refresh). If
  you ever want to publish to Posit Cloud, you will need to re-enable
  it.

## How to resume

1.  Read this file. If you are about to touch the Shiny app, read
    `PLAN_SHINY.md` too.
2.  Read `~/repos/ai_workflow/CLAUDE_CODING.md` for the user’s coding
    rules (tests-before-implementation, pause-for-review at checkpoints,
    `devtools::check()` before complete, “why” comments at branch
    points).
3.  Read `R/*.R`, `inst/shiny/*.R`, `inst/shiny/R/*.R`, and
    `tests/testthat/*.R` to ground yourself.
4.  The release-path commands are:
    - `devtools::test()`, `devtools::check()`
    - `git push origin main` (triggers the pkgdown workflow)
    - `source("deploy.R")` (redeploys the Shiny app; needs
      `rsconnect::setAccountInfo()` once per machine, see `deploy.R`’s
      comment block)

## Constraints inherited from the paper repo’s CLAUDE.md and memory

- **No unicode.** ASCII only. `---` for em dash, `--` for en dash, `->`
  for arrow, `"` and `'` straight quotes, `...` for ellipsis.
- **No methodological tribalism.** Bayes factors are a tool. Do not
  introduce “Bayesian” labels.
- **No athletic/defense metaphors for thresholds.** BFs are “above” or
  “below” thresholds, not “clearing” or “withstanding” them.
- **Plain language at branch points.** Avoid “is appropriate,” “is
  reasonable,” structural metaphors. Name what depends on what.
- **R package work follows `CLAUDE_CODING.md`.** Tests before
  implementation; `check()` before complete; “why” comments at branch
  points.

## DrWrinch and the paper repo

The paper repo’s renv currently has DrWrinch installed locally (via
`renv::install("local::~/repos/DrWrinch")`) so the new appendix section
renders. The renv lockfile was not snapshotted, so other machines
rebuilding the paper would still need to install DrWrinch first. With
the GitHub repo published and version `0.0.1.9000` tagged via the commit
log, the appendix’s `install_github("bowers-illinois-edu/DrWrinch")`
line resolves without further action.
