# DrWrinch: Fully Specified Bayes Factors for Process Tracing

A researcher has coded the evidence into two counts: observations
supporting the working theory and observations supporting a single
rival. One model underlies everything this package computes. Each
observation supports the working theory with probability \\\theta\\, the
share of the evidence that supports it. The working theory claims
\\\theta \> 1/2\\ and the rival claims \\\theta \le 1/2\\.

## Details

Each claim is a range of shares rather than one share, so neither gives
a probability for the counts on its own. The package computes the two
Bayes factors of Lopez, Bowers, and Gajardo Cooper (2026). They share a
numerator, the probability of the counts averaged over the shares above
one half under uniform weights, and differ in the denominator.
[`bf_uniform_weights()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/bf_uniform_weights.md)
averages over the rival's shares under the same uniform weights.
[`bf_worst_case()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/bf_worst_case.md)
evaluates the rival at its most favorable share, one half when the
counts favor the working theory, which makes its value the smallest any
weights on the rival's shares can give. The paper's rule sets the rival
aside, at least provisionally, when the first is 20 or more and the
second is above 1.

[`bf_rescaled()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/bf_rescaled.md)
computes the uniform-weights Bayes factor under other weights on the
shares, and
[`bf_worst_case()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/bf_worst_case.md)
takes the same weights on the working theory's side.
[`bf_uniform_weights_finite()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/bf_finite.md)
and
[`bf_worst_case_finite()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/bf_finite.md)
compute both Bayes factors for documents read without replacement from
an archive of known size.
[`sens_bias()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/sens_bias.md)
and
[`sens_coding()`](https://bowers-illinois-edu.github.io/DrWrinch/reference/sens_coding.md)
report how biased the search, or how many observations re-coded, it
would take before a researcher following the rule would no longer set
the rival aside.

The package is named after Dorothy Maud Wrinch (1894–1976), whose joint
papers with Harold Jeffreys (1919, 1921, 1923) developed the framework
that became Jeffreys's theory of Bayes factors. See
<https://en.wikipedia.org/wiki/Dorothy_Maud_Wrinch>.

## See also

Useful links:

- <https://github.com/bowers-illinois-edu/DrWrinch>

- <https://bowers-illinois-edu.github.io/DrWrinch/>

- Report bugs at
  <https://github.com/bowers-illinois-edu/DrWrinch/issues>

## Author

**Maintainer**: Jake Bowers <jwbowers@illinois.edu>
([ORCID](https://orcid.org/0000-0002-4048-1166)) \[copyright holder\]

Authors:

- Jake Bowers <jwbowers@illinois.edu>
  ([ORCID](https://orcid.org/0000-0002-4048-1166)) \[copyright holder\]

- Matias Lopez <matiaslopez.uy@gmail.com>
  ([ORCID](https://orcid.org/0000-0002-0871-2841)) \[copyright holder\]

- Daniel Gajardo Cooper <drgajardo@uc.cl> \[copyright holder\]
