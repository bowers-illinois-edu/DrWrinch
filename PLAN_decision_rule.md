# Plan: bring DrWrinch in line with the paper as of 2026-10-19

Written 2026-10-27 by Claude for Jake, in this repository.

Status at the end of 2026-10-27: the package changes below are made, in
DrWrinch 0.0.2.1 (commit `f3c04a8`), which is on GitHub and on
shinyapps.io. The edits to the paper repository are not made. The sections
from "What changed in the paper" through "Decisions" describe the package
as it stood before the update.

DrWrinch was last updated on 2026-08-29: version 0.0.2.0, commit `e551b80`,
already pushed to GitHub. Since then the paper (`~/repos/fully_specified_bf`,
last commit `c93870c` on 2026-10-19) has changed its rule for setting the
rival aside, added two computations the package lacks, re-coded one
application, and added a finite-archive version of both Bayes factors. Most
of what the package has to do in response follows from the paper with no
choice left open. Three choices about the package's interface were left
open, and the section "Your answers, 2026-10-27" records how you settled
them.

## What changed in the paper

### The rule for setting the rival aside now has two thresholds

When the package was last updated, the authors claimed for the worst-case
Bayes factor an error rate of at most one in twenty at a threshold of 20.
The authors now state a different rule (`Paper/evalues.qmd`, section "Using
the two Bayes factors to make a decision"): the researcher sets the rival
aside when the uniform-weights Bayes factor is 20 or more and the worst-case
Bayes factor is above 1. At nine observations for the working theory and
three for the rival, both conditions hold, because 20.67 is at least 20 and
2.73 is above 1. The error-rate theorem is still in the supplement, but the
authors no longer rest the main paper's rule on it.

No function in the package computed whether this rule held, and three
places followed the old rule:

- `sens_binomial()` returned the search bias at which the uniform-weights
  Bayes factor falls below 20. It returned nothing about the worst-case
  Bayes factor.
- `sens_coding(model = "worst_case")` returned a table of separations $g^*$,
  one row per re-coding. The supplement has commented that table out
  (`Paper/appendix.qmd`, lines 1157--1186). The main paper still computes
  $g^*$ in one code chunk but no longer mentions it in its text.
- The Shiny app applied one threshold to both Bayes factors. Its panel for
  the worst-case Bayes factor said that a researcher who sets the rival
  aside at the typed threshold is misled "at most one time in twenty,"
  whatever threshold was typed. The guarantee at a threshold $t$ is one time in $t$, so at the
  paper's threshold of 1 it promises nothing.

### Both sensitivity analyses now ask when either condition fails

The authors write $\omega^\star$ for the smallest search bias at which the
researcher would no longer set the rival aside: either the uniform-weights
Bayes factor has fallen to 20 or the worst-case Bayes factor has fallen to
1, whichever happens at the smaller bias (`Paper/evalues.qmd`,
sec-sensitivity, and the function `omega_star()` in the paper's
`tests/bf_weighted.R`). The worst-case condition needs the worst-case Bayes factor
under a biased search, which Daniel added on 2026-10-01 as
`worst_bf_weighted()`. A search with bias $\omega$ turns a share $\theta$ of
the evidence into a share $\omega\theta/(\omega\theta + 1 - \theta)$ among
the observations found. The uniform-weights Bayes factor already used that
tilt. Daniel's function applies the same tilt and evaluates the rival at a
share of one half in the evidence, which the search turns into a share of
$\omega/(1 + \omega)$ among the observations found.

At nine of twelve the uniform-weights Bayes factor falls to 20 at a bias of
1.0098 and the worst-case Bayes factor falls to 1 at 1.559, so
$\omega^\star = 1.01$. With the memo at weight 10 the counts are 18 and 3,
the two biases are 2.334 and 3.236, and $\omega^\star = 2.33$. In the
applications table, $\omega^\star$ now fills the column the separation used
to fill. Figure 3 plots both biases against every weight on the memo from 1
to 20.

The coding analysis changed the same way (`Paper/appendix.qmd`,
sec-sens-coding). The authors report the smallest number of re-codings at
which either condition fails. The supplement's code computes the worst-case
half in an inline loop because the package does not provide it.

### The worst-case Bayes factor takes stated weights on the working theory's side

On 2026-08-30 the paper's `tests/bf_rescaled.R` gained
`bounded_bf_rescaled(y_W, y_R, a1, b1)`. It computes the worst-case Bayes
factor when the researcher states a Beta$(a_1, b_1)$ distribution rescaled
onto the working theory's shares instead of the uniform. Only the working
theory's weights enter, because the rival is evaluated at one half whatever
weights the rival's proponent might state. The replications' sensitivity
tables report it beside the uniform-weights value: at nine of twelve it is
2.07 under Beta(1/2, 1/2) and 4.38 under Beta(10, 10). The package's
`bf_worst_case()` took no weights.

### One application was re-coded

On 2026-08-30 you moved Hammoud-Gallego and Freier from 10 observations for
the working theory and 3 for the rival to 11 and 2 (commit `117e878`),
because their null result on emigrant numbers counts against a rival
predictor. The uniform-weights Bayes factor rises from 33.86 to 153.57. The
worst-case Bayes factor rises from 3.97 to 14.91. The number of re-codings
that takes the uniform-weights value below 20 rises from one to two.
`tests/testthat/test-applications.R` pinned the old counts.

### The supplement has a finite-archive version of both Bayes factors

On 2026-09-11 Daniel added the section "Finite evidence without replacement"
(`Paper/appendix.qmd`, lines 143--245). An archive holds $M$ documents,
and $K$ of them support the working theory. The working theory claims
$K > M/2$ and the rival claims $K$ at most $M/2$. The uniform-weights version averages the hypergeometric probability of
the counts over each theory's values of $K$. The worst-case version
evaluates the rival at the largest $K$ at or below $M/2$. At nine of twelve
drawn from an archive of 20, the uniform-weights version is 162.88. In
every case the authors computed, whenever the binomial Bayes factors meet
the rule, the finite ones meet it too. So a researcher need not choose $M$,
but may vary it as a sensitivity parameter. The finite-archive version is
not the urn that `bf_urn()` computes, whose composition was built from the
observed counts.

### Two analyses the package offers are no longer in the paper

The whole-interval Beta$(1, M + 1)$ prior, where $M$ counts background
cases favoring the rival rather than documents in an archive, was what
`sens_binomial()` used for `M_star` and what the app drew in its second
sensitivity plot. It now sits
inside a commented block of the supplement (lines 465--532). The separated
Bayes factor and its separation $g^*$ are commented out of the supplement
(lines 769--1062).

### The paper dropped gendered pronouns

On 2026-08-30 you removed "she," "her," "he," and "his" from both documents.
The package's help pages, README, vignette, and app used "she" for the
researcher and "her" for the rival, on 221 lines.

## Five worst-case cells in the supplement's study tables

Each study's subsection of the supplement has a table of Bayes factors under
changed assumptions; for Andersen it is `tbl-app-andersen-sens`. The tables
are built from `replications/<study>/sensitivity_axes.csv`. One row of each
table varies the search bias over $\omega = 1, 2, 5$. In Andersen's table
the worst-case column of that row reads 2.73 / 0.67 / 0.28.

The 0.28 is not the worst case. Here is the arithmetic at Andersen's counts,
nine of twelve, and $\omega = 5$.

- A search with bias $\omega$ turns a share $\theta$ of the evidence into a
  share $q = \omega\theta/(\omega\theta + 1 - \theta)$ among the
  observations found. At $\omega = 5$ the rival's share of one half becomes
  $q = 5/6 = 0.833$. The probability of nine of twelve at $q = 0.833$ is
  0.197.
- The rival claims every share at or below one half, not only one half. At
  $\theta = 0.375$ the same search gives $q = 1.875/2.5 = 0.75$. The
  probability of nine of twelve at $q = 0.75$ is 0.258. No share gives
  more, because nine of twelve is most probable when $q = 9/12$.
- The numerator, the working theory's average, is 0.0554. The table
  divides it by 0.197 and prints 0.28. Divided by 0.258, the largest
  probability the rival's shares can give, it is 0.21.

The paper defines the worst-case Bayes factor as the one whose denominator
is the largest probability any weights on the rival's shares can give.
Without bias, and with at least as many observations for the working
theory as for the rival, that denominator is the probability at one half.
With bias it stays at one half only while $\omega/(1 + \omega)$, the share
found when the rival's share is one half, is at most $k/N$. The inequality
$\omega/(1 + \omega) \le k/N$ rearranges to $\omega \le k/r$. At a larger
bias the largest denominator is the probability at $q = k/N$.

Five printed cells are affected:

| Study | Counts | $\omega$ | Printed | At the rival's best share |
|---|---|---|---|---|
| Andersen | (9, 3) | 5 | 0.28 | 0.21 |
| Mor | (8, 2) | 5 | 0.41 | 0.40 |
| Winward | (14, 3) | 5 | 0.38 | 0.37 |
| Pavone and Stiansen | (7, 4) | 2 | 0.33 | 0.32 |
| Pavone and Stiansen | (7, 4) | 5 | 0.18 | 0.05 |

Steinsson and Hammoud-Gallego and Freier are unaffected: Steinsson has no
rival observations, and for Hammoud-Gallego and Freier $k/r = 11/2 = 5.5$
is above 5.

None of the paper's decisions or tipping points change. Every affected cell
is below 1 under both computations, so a researcher following the rule keeps the rival there
either way. And each bias at which the paper reports the worst-case value
reaching 1 is below $k/r$ for its study: 1.56 against 3 for Andersen, 2.01
against 4 for Mor, 2.49 against 4.67 for Winward, and 2.81 against 5.5 for
Hammoud-Gallego and Freier. That ordering holds for any counts. At the bias
where $\omega/(1 + \omega)$ equals $k/N$, the denominator is the largest
probability the counts can have at any share, and the numerator averages
smaller probabilities, so the worst-case value is below 1 at that bias. It
starts above 1 at $\omega = 1$ whenever the rule holds, so it reaches 1 at
a smaller bias, where one half is still the rival's best share.

On 2026-10-27 you chose to recompute the five cells at the rival's best
share and to add a note to the supplement saying why and how. Item 5 of the
next section lists what that takes.

## What the paper repository has to change once DrWrinch 0.0.2.1 is on GitHub

These edits belong to a session in `~/repos/fully_specified_bf`. The first
three are required: without them the paper, the supplement, or the
replications stop with an error once the paper's renv library installs the
new version.

1. `tests/bf_weighted.R` has two cross-checks guarded by
   `requireNamespace("DrWrinch")`. The one in `binom_bf_weighted()` calls
   `DrWrinch::bf_binomial(W, R, omega = omega)`; replace that call with
   `DrWrinch::bf_uniform_weights(W, R, omega = omega)`, which computes the
   same number. The one in `hyper_bf_weighted()` calls `DrWrinch::bf_urn()`;
   delete it, because the package no longer has the urn. Every file that
   sources `tests/bf_weighted.R` depends on this fix: `Paper/evalues.qmd`
   (chunk `sensitivity-full`), `Paper/appendix.qmd` (sec-sens-bias and the
   applications section), and the six `replications/<study>/our_bf.R`.
   Keep that cross-check's tolerance of 1e-6. The package now integrates
   to a relative tolerance of 1e-10, while the paper's own
   `binom_bf_weighted()` keeps R's default, so any gap between the two
   comes from the paper's side.
2. `Paper/appendix.qmd`, sec-sens-coding: the chunk that defines
   `coding_sens()` calls `sens_coding(k, r, model = "binomial",
   threshold = 20)$x_star`, and `sens_coding()` no longer has a `model`
   argument. `sens_coding(k, r)$x_star` returns the smaller of the two
   tipping points, which is what `coding_sens()` computes, so the chunk can
   call it directly. The comment on `library(DrWrinch)` in the chunk
   `sens-setup` names `bf_binomial` and `sens_binomial`, which are gone.
3. `Paper/appendix.qmd`, sec-reproduction: every call changes.
   `bf_binomial(9, 3)` becomes `bf_uniform_weights(9, 3)`;
   `source("../tests/bf_bounded.R")` and `bounded_bf(9, 3)` become
   `bf_worst_case(9, 3)`; `sens_binomial(9, 3)$omega_star` becomes
   `sens_bias(9, 3)$omega_star`, which now also asks when the worst-case
   value falls to 1 and still returns 1.0098 here;
   `sens_coding(9, 3, model = "binomial", threshold = 20)$x_star` becomes
   `sens_coding(9, 3)$x_star`; and the weighted calls at (18, 3) become
   `bf_uniform_weights(18, 3)` and `bf_worst_case(18, 3)`. The prose names
   `bf_binomial` and `tests/bf_bounded.R` as the sources, lists "the
   separation" among the numbers reproduced, and sends readers to
   `?bf_binomial` and `?sens_binomial`; all of that changes with the calls.
   The TODO comment about renaming `bf_binomial` can go.
4. `renv.lock` records DrWrinch 0.0.1.9001 from a local source. Install
   0.0.2.1 from GitHub and snapshot.
5. The five worst-case cells (previous section), recomputed with the rival
   at its best share, plus a note saying why and how:
   - In `worst_bf_weighted()` in `tests/bf_weighted.R`, divide by
     `dbinom(W, N, min(omega / (1 + omega), W / N))` instead of
     `dbinom(W, N, omega / (1 + omega))` when `W >= R`. Below
     $\omega = W/R$ the two agree, so `sens_bias_worst()` and every tipping
     point the paper prints stay as they are. A cross-check against
     `DrWrinch::bf_worst_case(W, R, omega = omega)`, guarded the way item 1's
     is, would tie the two implementations together.
   - Rerun `make replications`, which rewrites the six
     `sensitivity_axes.csv` files. Andersen's, Mor's, and Winward's change
     at $\omega = 5$, and Pavone and Stiansen's at $\omega = 2$ and 5.
   - In sec-sens-bias of `Paper/appendix.qmd`, the formula for the
     worst-case Bayes factor under bias divides by
     $q^{*k}(1 - q^*)^{r}$ with $q^* = \min(\omega/(1 + \omega), k/N)$
     instead of by the same expression at $q(1/2) = \omega/(1 + \omega)$.
   - The note, in sec-sens-bias with a pointer from each study table, says
     why: the worst-case Bayes factor divides by the largest probability
     the rival's shares can give the counts; a biased search turns the
     rival's shares into shares found of at most $\omega/(1 + \omega)$;
     the counts are most probable at a share found of $k/N$; so once
     $\omega$ exceeds $k/r$ the rival's best share is below one half. It
     gives Andersen's arithmetic at $\omega = 5$ (0.0554 / 0.258 = 0.21
     against 0.0554 / 0.197 = 0.28), and it says that no decision and no
     tipping point changes, because the worst-case value reaches 1 before
     $\omega$ reaches $k/r$.

Item 3 is on the path to the next arXiv replacement, not cleanup. The
current preprint's reproduction section calls `bf_binomial()`,
`sens_binomial()`, and `sens_coding(model = "binomial")`, none of which
exists once 0.0.2.1 is on GitHub, so a reader who installs the package to
reproduce the preprint will meet errors until the replacement is posted.

Two things do not have to change. `Paper/evalues.qmd` sources
`tests/bf_bounded.R` and `tests/bf_rescaled.R` and works unchanged once
item 1 is done. This repository's earlier plan proposed switching it to
`library(DrWrinch)`, but the paper project's memory records your rule that
the main paper's body does not call DrWrinch, so the list leaves that
switch out. And the replications still compute the urn's Bayes factor
(column `hyper_bf`) and the separation (`separation_g`), which no table
prints; removing them is cleanup, not a fix.

## Changes made without asking

1. `bf_worst_case()` gains three arguments: `omega` for search bias, which
   matches `bf_uniform_weights(omega = )`, and `a1, b1` for the working
   theory's weights, which match `bf_rescaled()`. The closed form stays as
   the fast path at the defaults. Other values are integrated, as
   `bf_binomial()` integrated when `omega` was not 1.
2. `test-applications.R` moves Hammoud-Gallego and Freier to (11, 2). It
   also pins each study's $\omega^\star$ as the applications table reports
   it: 5.49, 1.74, 1.70, 1.14, and 1.01, no entry for Pavone and Stiansen,
   and 1.67 for Pavone and Stiansen with the letter at weight 10.
3. New tests pin the numbers above. They also pin how `bf_worst_case()`
   treats bias: up to $\omega = k/r$ it returns the paper's value, with the
   rival at one half, and past that bias it returns the smallest value over
   the rival's shares.
4. The help pages, README, vignette, DESCRIPTION, and app state the paper's
   rule and stop presenting the worst-case Bayes factor as an error rate at
   20. They drop the gendered pronouns by the four rules you used in the
   paper: drop the possessive, recast the sentence, use singular "they," or
   name the role.
5. The app takes two thresholds, 20 and 1, and says whether a researcher
   following the rule sets the rival aside. It reports $\omega^\star$ and the coding tipping point
   under the rule. The panel for the worst-case Bayes factor loses its
   separation line.
6. The root finder behind `sens_bias()` uses the paper's tolerance, so that
   its biases agree with the paper's to six digits instead of four.
7. The version moves from 0.0.2.0 to 0.0.2.1, and `.dw_needed` in
   `inst/shiny/global.R` moves with it.

This session did not change the paper repository. The section before this
one lists the edits it needs.

## Decisions

1. Should the paper's rule become the default in the sensitivity functions?
   I recommend yes. A new
   `sens_bias(y_W, y_R, threshold_uniform = 20, threshold_worst = 1)` would
   return the bias at which each condition fails and the smaller of the two.
   `sens_coding()` would take the same two thresholds and a new default,
   `model = "rule"`, returning the number of re-codings at which each
   condition fails and the smaller of the two. `model = "worst_case"` would
   then return a tipping point at the worst-case threshold instead of the
   separation table. No code in either version of the paper calls that
   branch. The alternative leaves `sens_coding()` as it is and adds rule
   functions beside it. That alternative breaks nothing, but the package
   would then give two answers to the coding question.
2. Should the package add the finite-archive Bayes factors? I recommend
   adding them, as `bf_uniform_weights_finite(y_W, y_R, M)` and
   `bf_worst_case_finite(y_W, y_R, M)`, and rewording the deprecation notice
   of `bf_urn()` to point to them. That notice says the paper has no
   hypergeometric model. The supplement has had one since 2026-09-11.
3. What should happen to `M_star`? I recommend deprecating `sens_binomial()`
   the way `bf_urn()` was deprecated: it keeps returning what it returns and
   warns once per session. `sens_bias()` would replace its `omega_star`, and
   its `M_star` belongs to an analysis the paper has commented out. The
   app's background-cases plot would go. The supplement's reproduction
   section still calls `sens_binomial()`, so the paper's render would show
   the warning until the switch to `library(DrWrinch)` replaces that call.

## Your answers, 2026-10-27

1. The rule is the default. Because of answer 3, `sens_coding()` takes no
   `model` argument at all: like `sens_bias()`, it always returns the
   tipping point for each condition and the smaller of the two, so the
   separation table and the urn branch go with the functions behind them.
2. Add `bf_uniform_weights_finite()` and `bf_worst_case_finite()`.
3. Drop rather than deprecate, since no one else uses the package. Dropped:
   `bf_urn()`, `sens_urn()`, the deprecation helper, `sens_binomial()` (its
   `M_star` and the app's background-cases plot with it), `bf_binomial()`
   (with the whole-interval Beta prior and `theta_cut`), and the separated
   Bayes factor (`bf_separated()`, `separation_g()`,
   `bf_separated_bias()`). Anything the paper neither uses nor is likely to
   use goes too. `BiasedUrn` leaves Imports, because only `bf_urn()` needed
   it.
4. Under bias, `bf_worst_case()` divides by the largest probability the
   rival's shares can give the counts, and the paper recomputes its five
   affected cells the same way, with a note saying why and how. When the
   counts favor the rival ($y_W < y_R$) the function keeps the rival at one
   half, as the paper's closed form does for every count; the rule's
   second condition fails at those counts under either convention.

Dropping `bf_binomial()` and `bf_urn()` breaks the two cross-checks in the
paper's `tests/bf_weighted.R` that call them through `DrWrinch::`, as soon
as the paper's renv library gets the new version. Item 1 of the section on
the paper repository says how to fix each one.

## Tests written before implementation

Rewritten: `test-bf_uniform_weights.R`, `test-bf_worst_case.R`,
`test-bf_rescaled.R`, `test-sens_coding.R`, `test-applications.R`. New:
`test-bf_finite.R`, `test-sens_bias.R`. Removed with the functions they
tested: `test-bf_binomial.R`, `test-bf_urn.R`, `test-sens.R`,
`test-deprecated.R`, `setup-deprecation.R`. The app's four test files were
rewritten after the functions passed their tests and before the app was
changed: `test-app_helpers.R` (new helpers `interpret_rule()`,
`interpret_bias()`, `interpret_coding()`, and a `bf_omega_curve()` that
returns both Bayes factors), `test-app_plots.R` (one bias picture with two
curves and the two thresholds), `test-app_server.R` (two threshold inputs, a
rule card, no separation, no prior sweep), and `test-app_decomposition.R`
(renamed from `test-app_worst_case.R`, with the separation tests removed).

The tests pin one behavior the memo did not anticipate. The finite-archive
worst-case value is 0/0, and so `NaN`, when neither the
working theory nor the half-split archive can produce the counts (no
supporting document in a full reading of an archive of six). That happens
only when the counts favor the rival.

## Decision

The paper's HANDOFF says Matias Lopez plans to submit by 2026-10-30. Should
the paper-repository edits above be made before that submission? I
recommend yes. The supplement's reproduction section calls functions that
are no longer on GitHub, so a reviewer who installs the package to
reproduce the running example would meet errors, and the five worst-case
cells would otherwise go out computed with the rival held at one half.
