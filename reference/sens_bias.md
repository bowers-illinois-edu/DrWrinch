# Sensitivity to a biased search

The paper's rule sets the rival aside, at least provisionally, when the
uniform-weights Bayes factor is 20 or more and the worst-case Bayes
factor is above 1. A reader who doubts the result may ask whether the
search for evidence favored the working theory. Write \\\omega\\ for the
bias factor: a search with bias \\\omega\\ is \\\omega\\ times as likely
to find a pro-working-theory observation as a pro-rival one. Granting
more bias lowers both Bayes factors, because a search that finds
pro-working-theory observations more easily would produce mostly
pro-working-theory counts even from evidence that mostly favored the
rival.

## Usage

``` r
sens_bias(y_W, y_R, threshold_uniform = 20, threshold_worst = 1)
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

  The two Bayes factors at an unbiased search.

- `omega_uniform`:

  The bias at which the uniform-weights Bayes factor falls to
  `threshold_uniform`.

- `omega_worst`:

  The bias at which the worst-case Bayes factor falls to
  `threshold_worst`.

- `omega_star`:

  The smaller of the two.

## Details

This function returns the bias at which each condition of the rule fails
and the smaller of the two, which the paper writes \\\omega^\star\\: the
smallest bias at which a researcher following the rule would no longer
set the rival aside. At nine observations for the working theory and
three for the rival, the uniform-weights value falls to 20 at a bias of
1.0098 and the worst-case value falls to 1 at 1.559, so \\\omega^\star =
1.01\\: a search about one percent more likely to find
pro-working-theory observations would change the decision. With the
smoking-gun memo counted as ten observations, the counts are 18 and 3
and \\\omega^\star = 2.33\\.

Whether a search could have been that lopsided is a question about how
the evidence was collected, which readers who know the case can answer
and the function cannot.

## Special values

A tipping point is `0` when its condition already fails at an unbiased
search, because then there is no decision for bias to change. It is
`Inf` when no bias makes the condition fail: with no observations for
the rival, both Bayes factors fall toward 1 as the bias grows and never
reach it, so a threshold of 1 or less is never crossed. It is `NA` when
the search, which tries biases up to about \\10^{12}\\, finds no
crossing; `omega_star` then reports the other tipping point.

## See also

[`bf_uniform_weights()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/bf_uniform_weights.md)
and
[`bf_worst_case()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/bf_worst_case.md),
whose `omega` argument this function varies;
[`sens_coding()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/sens_coding.md)
for sensitivity to coding.

## Examples

``` r
# The paper's running example.
sens_bias(9, 3)
#> $bf_uniform
#> [1] 20.67196
#> 
#> $bf_worst
#> [1] 2.732168
#> 
#> $omega_uniform
#> [1] 1.009794
#> 
#> $omega_worst
#> [1] 1.559262
#> 
#> $omega_star
#> [1] 1.009794
#> 

# The memo counted as ten observations.
sens_bias(18, 3)$omega_star
#> [1] 2.334075
```
