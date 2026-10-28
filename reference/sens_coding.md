# Sensitivity to coding

A peer cannot re-read every document the way the researcher did, so the
coding of any one observation can be disputed but not settled at a
distance. What a peer can compute is how many re-codings would change
the decision. Re-coding `x` observations relabels `x` observations that
supported the working theory as supporting the rival, moving the counts
from `(y_W, y_R)` to `(y_W - x, y_R + x)`. The number of observations
does not change; only the split does.

## Usage

``` r
sens_coding(y_W, y_R, threshold_uniform = 20, threshold_worst = 1)
```

## Arguments

- y_W:

  Non-negative whole number. Count, or summed weight, of observations
  supporting the working theory.

- y_R:

  Non-negative whole number. Count, or summed weight, of observations
  supporting the rival.

- threshold_uniform:

  Positive number. The uniform-weights Bayes factor must be at least
  this large for the rule to set the rival aside. Default `20`.

- threshold_worst:

  Positive number. The worst-case Bayes factor must be above this value
  for the rule to set the rival aside. Default `1`.

## Value

A list with elements

- `bf_uniform`, `bf_worst`:

  The two Bayes factors at the observed coding.

- `x_uniform`:

  The smallest number of re-codings at which the uniform-weights value
  falls below `threshold_uniform`.

- `x_worst`:

  The smallest number of re-codings at which the worst-case value falls
  to `threshold_worst` or below.

- `x_star`:

  The smaller of the two.

A tipping point is `NA` when no re-coding of the `y_W` observations
makes its condition fail.

## Details

The paper's rule sets the rival aside, at least provisionally, when the
uniform-weights Bayes factor is 20 or more and the worst-case Bayes
factor is above 1. This function returns the smallest number of
re-codings at which each condition fails and the smaller of the two,
which is the number the supplement reports. At nine observations for the
working theory and three for the rival, one re-coding takes the
uniform-weights value from 20.67 to 6.49, below 20, while the worst-case
value falls to 1 or below only after two (1.10 at eight of twelve, 0.56
at seven). So one re-coding changes the decision. The conclusion
tolerates so little re-coding because the uniform-weights value starts
so close to 20.

Re-coding lowers both Bayes factors, so every re-coding past the first
one at which a condition fails also fails it. A tipping point of `0`
means the condition already fails at the observed coding.

## See also

[`sens_bias()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/sens_bias.md)
for sensitivity to a biased search;
[`bf_uniform_weights()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/bf_uniform_weights.md)
and
[`bf_worst_case()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/bf_worst_case.md)
for the values recomputed here.

## Examples

``` r
# The paper's running example.
sens_coding(9, 3)
#> $bf_uniform
#> [1] 20.67196
#> 
#> $bf_worst
#> [1] 2.732168
#> 
#> $x_uniform
#> [1] 1
#> 
#> $x_worst
#> [1] 2
#> 
#> $x_star
#> [1] 1
#> 

# Winward's fourteen of seventeen: two re-codings change the decision.
sens_coding(14, 3)$x_star
#> [1] 2
```
