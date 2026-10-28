# Both Bayes factors for documents read from an archive of known size

The binomial model behind
[`bf_uniform_weights()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/bf_uniform_weights.md)
and
[`bf_worst_case()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/bf_worst_case.md)
treats the observations as independent draws. A researcher reading a
finite archive does not read the same document twice, so each document
read changes the share of what is left. These two functions compute the
supplement's version of both Bayes factors for that case (section
"Finite evidence without replacement").

## Usage

``` r
bf_uniform_weights_finite(y_W, y_R, M)

bf_worst_case_finite(y_W, y_R, M)
```

## Arguments

- y_W:

  Non-negative whole number. Documents read that support the working
  theory.

- y_R:

  Non-negative whole number. Documents read that support the rival.

- M:

  Whole number at least `y_W + y_R`. Documents in the archive.

## Value

A length-1 numeric: the Bayes factor in favor of the working theory.

## Details

The archive holds `M` documents, \\K\\ of which support the working
theory. The working theory claims \\K \> M/2\\ and the rival claims \\K
\le M/2\\, so when `M` is even the archive split exactly in half belongs
to the rival, as a share of one half does in the binomial model. The
probability of reading `y_W` supporting documents among \\N = y_W +
y_R\\ is the hypergeometric probability \$\$p(E \mid M, K) =
\binom{K}{y_W}\binom{M-K}{y_R} \Big/ \binom{M}{N}.\$\$ The numerator of
both Bayes factors averages it over the working theory's values of \\K\\
with equal weights. `bf_uniform_weights_finite()` divides by the same
average over the rival's values. `bf_worst_case_finite()` divides by the
probability at the largest \\K\\ at or below \\M/2\\.

At nine of twelve the two values are 162.88 and 16.84 from an archive of
20 and 25.22 and 3.19 from an archive of 100, and they approach the
binomial values, 20.67 and 2.73, as the archive grows. In every case the
supplement computed, whenever the binomial values meet the paper's rule
(uniform weights 20 or more, worst case above 1), the finite values meet
it too. So a researcher need not state the size of the archive, but may
vary `M` to ask how large it would have to be for the conclusion to
change.

Counts that one side cannot produce give the limiting values: `Inf` when
the rival's archives cannot produce them (nine supporting documents from
an archive of twelve) and `0` when only the rival's can.
`bf_worst_case_finite()` returns `NaN` when neither the working theory's
archives nor the half-split archive can produce the counts, which
happens only when the counts favor the rival.

## See also

[`bf_uniform_weights()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/bf_uniform_weights.md)
and
[`bf_worst_case()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/bf_worst_case.md)
for the binomial versions, which need no archive size.

## Examples

``` r
# Nine of twelve documents read from an archive of 20.
bf_uniform_weights_finite(9, 3, M = 20)
#> [1] 162.8846
bf_worst_case_finite(9, 3, M = 20)
#> [1] 16.84375

# From a much larger archive the values are close to the binomial ones.
bf_uniform_weights_finite(9, 3, M = 1e5)
#> [1] 20.67565
bf_uniform_weights(9, 3)
#> [1] 20.67196
```
