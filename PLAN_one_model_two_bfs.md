# Plan: bring DrWrinch in line with the one-model paper

Written 2026-08-29 by Jake with Claude, in the fully_specified_bf
repository, for a fresh Claude instance launched in this directory. Read
`~/repos/ai_workflow/CLAUDE_CODING.md` before touching any file: tests
before implementation, pause for Jake's review after the tests and again
after the implementation, `devtools::check()` before calling anything
done, bump the patch version when an exported function is added.

## What changed in the paper

On 2026-08-29 the paper (`~/repos/fully_specified_bf`, branch
`bounded-bf-rewrite`) stopped describing two probability models. It now
has one model --- each observation supports the working theory with
probability $\theta$, the share of the evidence that supports it; the
working theory claims $\theta > 1/2$ and the rival claims
$\theta \le 1/2$ --- and two Bayes factors computed from it. Both share
a numerator: the binomial probability of the counts averaged over the
shares above one half under weights the researcher states (uniform by
default). They differ in the denominator.

- The **uniform-weights Bayes factor** (the paper's earlier "binomial Bayes
  factor"; Jake fixed the name pair on 2026-08-29) averages the probability of the counts over the
  shares at or below one half under uniform weights. At nine of twelve
  it is 20.67. Under the uniform weights it equals
  `(1 - pbeta(0.5, k + 1, r + 1)) / pbeta(0.5, k + 1, r + 1)`, which is
  what `bf_binomial()` computes today.
- The **worst-case Bayes factor** evaluates the rival's claim at the single
  share, one half, that makes the counts most probable. At nine of
  twelve it is 2.73. Closed form under uniform weights:
  `sum(choose(N + 1, 0:k)) / ((N + 1) * choose(N, k))`. It is a lower
  bound on the Bayes factor against any weighting of the rival's shares
  (when `k >= r`), and a researcher who treats 20 as decisive under it
  is misled at most one time in twenty when the rival is right, for
  independent draws and for draws without replacement from a collection
  of any size (supplement, `thm-error-rate`).
- The **separated version** and its solved separation $g^{*}$: the
  working theory claims at least $1/2 + g$ and the rival at most
  $1/2 - g$; the ratio is $((1 + 2g)/(1 - 2g))^{k - r}$; $g^{*}$ is the
  $g$ at which it equals the threshold, rounded up. Plus a bias-tilted
  version `separated_bf_bias(k, r, g, omega)`.
- The hypergeometric urn model (`bf_urn()`, `sens_urn()`, the
  Formulation C sub-models) is no longer in the paper at all.

The canonical R for the worst-case objects is in the paper repository at
`tests/bf_bounded.R` with unit tests in `tests/test_bf_bounded.R` (base R,
no dependencies). The weighted and bias helpers the paper's sensitivity
section uses are in `tests/bf_weighted.R` and `tests/bf_separated.R`
there; the supplement's reproduction section (`Paper/appendix.qmd`,
section "Reproducing the running example") shows the calls the paper
makes and is the acceptance test for this plan.

## What the package holds today

`R/bf_binomial.R` (`bf_binomial(y_W, y_R, prior_a, prior_b, omega)`, a
Beta prior on the whole interval and a bias tilt), `R/bf_urn.R`
(`bf_urn`, superseded), `R/sens_binomial.R` (`omega_star`, `M_star`),
`R/sens_urn.R` (superseded), `R/sens_coding.R`
(`sens_coding(y_W, y_R, model = c("binomial", "urn"), threshold)`),
`R/utils.R` (the bracketing root finder), `R/run_app.R` (a Shiny app
over both models), tests under `tests/testthat/` for each of these plus
`test-applications.R`. Version 0.0.1.9001.

## Tasks, in order

1. **Add the worst-case objects.** New file `R/bf_worst_case.R` with
   `bf_worst_case(y_W, y_R)`, `bf_separated(y_W, y_R, g)`,
   `separation_g(y_W, y_R, threshold = 20, digits = 3)`, and
   `bf_separated_bias(y_W, y_R, g, omega = 1)`, ported from the paper's
   `tests/bf_bounded.R` with the same argument names the package already
   uses (`y_W`, `y_R`). Port the tests first, from
   `tests/test_bf_bounded.R` there: the closed form against the integral
   definition, the 7814/2860 value, the average of the statistic at most
   one under `dbinom(., N, 1/2)` weights and under `dhyper` for several
   collection sizes, the 4.81 ceiling, the reciprocal property of the
   separated version, the rounding-up of `separation_g`.

2. **Name the uniform-weights Bayes factor.** Add `bf_uniform_weights()`
   as the documented entry point, keep `bf_binomial()` as an alias for
   one release, and make the roxygen say plainly that both functions come from
   the same model and differ only in the denominator.

3. **Weights within each range.** The paper (supplement, "Choosing the
   distributions of theta within each range") now states weights as a
   Beta$(a, b)$ rescaled onto each theory's half: $\theta = 1/2 + X/2$
   under $H_1$ and $\theta = X/2$ under $H_R$. `bf_binomial()` currently
   takes `prior_a, prior_b` on the whole interval, which is a different
   family (the two agree only at the uniform). Add arguments for the
   rescaled family --- one $(a, b)$ pair per side, defaulting to
   $(1, 1)$ --- and a test that the whole-interval Beta$(1, \beta)$
   prior-sensitivity table in the supplement still reproduces through
   whichever argument path keeps it. The paper's applications table now
   prints the uniform-weights Bayes factor under Beta$(1/2, 1/2)$ rescaled on
   each half (6219.2, 91.6, 14.4, 13.7, 9.5, 2.7 for Steinsson, Winward,
   Hammoud-Gallego and Freier, Mor, Andersen, Pavone and Stiansen); that
   is a test.

4. **Sensitivity helpers.** `sens_coding()`'s `model` argument becomes
   `c("uniform_weights", "worst_case")` (keep `"binomial"` as an accepted alias);
   for the worst-case Bayes factor the coding-error analysis reports the
   recomputed `bf_worst_case` and `separation_g` at each re-coding, as the
   supplement's recoding table does, rather than a tipping point.
   `sens_binomial()` keeps `omega_star`; its `M_star` is the
   posterior-odds tipping point under whole-interval Beta$(1, M + 1)$
   priors and the roxygen must say so (the supplement's
   prior-sensitivity subsection explains why posterior odds and Bayes
   factor separate there).

5. **Retire the urn.** Deprecate `bf_urn()` and `sens_urn()` with
   `lifecycle`-style messages pointing at `bf_worst_case()`; do not delete
   them this release, because the arXiv v1 of the paper cites them.

6. **The Shiny app.** `run_app()` shows the two Bayes factors from one
   model, side by side, with the shared numerator and the two
   denominators visible (the paper's `fig-bounded` is the picture to
   copy: three bars per count). Drop the urn panel.

7. **Docs and version.** README and the package roxygen in
   `R/DrWrinch-package.R` describe one model and two Bayes factors;
   `devtools::document()`; bump to 0.0.2.0; `devtools::check()`.

8. **Close the loop with the paper.** Once `bf_worst_case()` exists,
   `Paper/appendix.qmd`'s reproduction section and `Paper/evalues.qmd`'s
   setup chunk in the paper repository switch from
   `source(here::here("tests/bf_bounded.R"))` to the package, and
   `renv.lock` there is updated. That edit belongs to a session in the
   paper repository, not this one.

## Numbers every test should pin

Nine of twelve: uniform-weights 20.67, worst-case 2.73 (= 7814/2860), ceiling 4.81,
separation 0.123 (shares 0.623 and 0.377), separated value at g = 0.123
at least 20, bias tipping point of the uniform-weights Bayes factor 1.0098 (the
supplement prints 1.010), one re-coding takes the uniform-weights Bayes factor
below 20, weighted counts (18, 3): uniform-weights 2,337, worst-case 143.3. Seven
of twelve: worst-case 0.56. The six applications: see task 3, and the
worst-case values 630.08, 21.34, 3.97, 4.00, 2.73, 0.83 with separations
0.063, 0.068, 0.106, 0.123, 0.123, 0.231.

## Found while implementing, 2026-08-29 (Claude, in this repository)

Two things the plan did not anticipate. Both are recorded in more than
one place so that neither depends on anyone remembering it.

**Task 4 needs one more correction than it lists.** `bf_binomial()`
returns the ratio of posterior masses either side of the cut. Under a
Beta prior on the whole interval that ratio is the posterior odds, not
the Bayes factor, because such a prior sets how much weight each theory
gets as well as how weight is spread inside each theory's range; the
Bayes factor renormalizes the first away and the posterior odds keep it.
At nine observations against three under Beta(1, 2) the posterior odds
are 10.14 and the Bayes factor is 30.41, and the two move in opposite
directions as the prior tilts further toward the rival. The plan already
says `sens_binomial()`'s `M_star` roxygen must say this. What it did not
say is that `bf_binomial()`'s own roxygen was wrong in the same way. That
is now fixed, the correction is in `NEWS.md`, and
`tests/testthat/test-bf_uniform_weights.R` pins both columns of the
supplement's table so the distinction cannot quietly go away.
`sens_binomial()`'s roxygen now carries the fix too, with the reason
task 4 did not state: because the Bayes factor rises as the prior tilts
toward the rival, a Bayes-factor tipping point under those priors does
not exist, so `M_star` could only ever have been a posterior-odds
tipping point.

**Task 8 has a name collision waiting for it.** The package now exports
`bf_rescaled(y_W, y_R, a1, b1, aR, bR)`. `Paper/appendix.qmd` in the
paper repository already defines a different `bf_rescaled(kk, rr, tau)`
in the dependence section, the count-rescaling approximation. Both accept
three numbers without complaint, so once that document loads the package
the existing call `bf_rescaled(9, 3, tau)` returns a wrong number rather
than failing. A TODO comment sits above the local definition in
`Paper/appendix.qmd` saying to rename it in the session that does task 8.

**Done 2026-08-29: task 7 included the vignette.** The plan's task 7 names the
README and the package-level roxygen. `vignettes/getting-started.Rmd`
also needs the rewrite: it mentions the urn twenty times, calls
`bf_urn()` five times and `sens_urn()` once, and still presents two
probability models. Once task 5 deprecates those functions, the
vignette rebuild that `devtools::check()` runs renders a deprecation
warning into the built HTML. The check still passes; the shipped
vignette is what degrades. Both are now
rewritten, along with `bf_worst_case()`'s stale cross-reference to
`bf_binomial()` and the app's `.dw_needed` version guard, which would
otherwise have kept deploying `0.0.1.9001`.
