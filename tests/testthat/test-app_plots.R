# Tests for the app's plotly wrappers in `inst/shiny/R/plots.R`.
#
# The pure numbers behind each picture are already tested through
# curves.R. What is tested here is the step after that: whether the
# picture a reader sees actually shows those numbers. A plot can be
# built from correct data and still mislead, which is what happened in
# the version deployed on 2026-08-29 -- a stray unnamed trace carried
# the count itself as if it were a probability, set the y scale, and
# flattened the three real bars to invisibility.
#
# These tests source the app files rather than the package namespace,
# because the app's plot code deliberately lives outside it.

skip_if_not_installed("plotly")

plots_path <- system.file("shiny/R/plots.R", package = "DrWrinch")
if (!nzchar(plots_path) || !file.exists(plots_path)) {
  stop("Expected inst/shiny/R/plots.R but did not find it.")
}
source(file.path(dirname(plots_path), "curves.R"), local = TRUE)
source(plots_path, local = TRUE)

# The paper's running example, used throughout the package's tests.
Y_W <- 9
Y_R <- 3


# ---- plot_bf_decomposition ----------------------------------------------

test_that("the decomposition picture draws exactly three series", {
  # One series per probability the two Bayes factors are built from.
  # A fourth series means something is in the picture that no part of
  # the model puts there.
  built <- plotly::plotly_build(plot_bf_decomposition(Y_W, Y_R))
  expect_length(built$x$data, 3)
})


test_that("every series in the decomposition picture is named", {
  # An unnamed series reaches the legend as plotly's placeholder
  # ("trace 0"), which a reader cannot map onto anything in the model.
  built <- plotly::plotly_build(plot_bf_decomposition(Y_W, Y_R))
  names_shown <- vapply(
    built$x$data,
    function(tr) if (is.null(tr$name)) NA_character_ else tr$name,
    character(1)
  )
  expect_false(any(is.na(names_shown)))
  expect_true(all(nzchar(names_shown)))
})


test_that("every bar height in the decomposition picture is a probability", {
  # This is the assertion that would have caught the stray series: its
  # heights ran from 0 to n, the counts, while every quantity the
  # picture is supposed to show is a probability.
  built <- plotly::plotly_build(plot_bf_decomposition(Y_W, Y_R))
  heights <- unlist(lapply(built$x$data, function(tr) as.numeric(tr$y)))
  expect_true(all(heights >= 0))
  expect_true(all(heights <= 1))
})


test_that("the decomposition picture reproduces both Bayes factors", {
  # The substantive point of the figure: a reader who divides the first
  # bar by the second at the observed count should recover the
  # uniform-weights Bayes factor, and by the third the worst-case one.
  # If the bars ever stop doing this the picture is decoration.
  built <- plotly::plotly_build(plot_bf_decomposition(Y_W, Y_R))

  at_observed <- function(trace) {
    ks <- as.numeric(trace$x)
    as.numeric(trace$y)[which(ks == Y_W)]
  }
  numerator <- at_observed(built$x$data[[1]])
  den_avg <- at_observed(built$x$data[[2]])
  den_half <- at_observed(built$x$data[[3]])

  expect_equal(
    numerator / den_avg,
    DrWrinch::bf_uniform_weights(Y_W, Y_R),
    tolerance = 1e-6
  )
  expect_equal(
    numerator / den_half,
    DrWrinch::bf_worst_case(Y_W, Y_R),
    tolerance = 1e-6
  )
})


test_that("the legend sits clear of the horizontal axis title", {
  # Both the axis title and a horizontal legend are drawn below the
  # plotting area, so the legend has to be pushed further down AND the
  # bottom margin widened to hold it. Setting only the first prints the
  # axis title on top of the legend entries, which is what the deployed
  # version did.
  layout <- plotly::plotly_build(plot_bf_decomposition(Y_W, Y_R))$x$layout
  expect_lt(layout$legend$y, -0.25)
  expect_gte(layout$margin$b, 100)
})


# ---- the two sensitivity pictures ---------------------------------------

test_that("the sensitivity pictures build with every series named", {
  # Same defect class, checked on the other two figures so it cannot
  # reappear there unnoticed.
  omega_plot <- plotly::plotly_build(
    plot_bf_vs_omega(Y_W, Y_R, threshold = 20)
  )
  m_plot <- plotly::plotly_build(
    plot_post_odds_vs_M(Y_W, Y_R, threshold = 20, M_max = 10L)
  )

  for (built in list(omega_plot, m_plot)) {
    named <- vapply(
      built$x$data,
      function(tr) !is.null(tr$name) && nzchar(tr$name),
      logical(1)
    )
    expect_true(all(named))
  }
})


test_that("the search-bias axis is labelled with search-bias values", {
  # On a log axis plotly labels the minor ticks with their mantissa, so
  # the axis read "3 4 5 6 7 8 9 1 2 3 4 5 6 7 8" from 0.25 to 8. The
  # middle "1" was a search bias of one, the point at which the search
  # favoured neither theory, and nothing on the axis said so. Explicit
  # ticks name the doublings a reader can argue about instead.
  layout <- plotly::plotly_build(
    plot_bf_vs_omega(Y_W, Y_R, threshold = 20)
  )$x$layout
  expect_equal(layout$xaxis$ticktext, c("0.25", "0.5", "1", "2", "4", "8"))
  expect_length(layout$xaxis$tickvals, 6)
  expect_equal(layout$xaxis$tickmode, "array")
})


test_that("both sensitivity y axes carry one tick per decade", {
  # plotly labelled these log axes with mantissas and SI prefixes. The
  # Bayes-factor axis read "2 / 10k / 5 / 2 / 1000 / 5" and the
  # posterior-odds axis read "1 / 0.01 / 100u / 1u / 10n", where u and n
  # were micro and nano. A reader could not tell which gridline was
  # which. One tick per decade, written as a power of ten, can only be
  # read one way.
  built <- list(
    plotly::plotly_build(plot_bf_vs_omega(Y_W, Y_R, threshold = 20)),
    plotly::plotly_build(
      plot_post_odds_vs_M(Y_W, Y_R, threshold = 20, M_max = 10L)
    )
  )
  for (b in built) {
    y <- b$x$layout$yaxis
    expect_equal(y$tickmode, "array")
    expect_equal(y$exponentformat, "power")
    expect_gt(length(y$tickvals), 1)
    # Every tick value is a whole power of ten.
    expect_equal(log10(y$tickvals), round(log10(y$tickvals)))
  }
})
