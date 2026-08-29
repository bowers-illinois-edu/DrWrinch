# plotly wrappers around the pure data functions in curves.R. Kept in a
# separate file so the numbers behind each picture can be tested without
# loading plotly.

# Colors, named once. The three-bar picture shades one hue by role: the
# shared numerator lightest, the averaged denominator mid, the
# best-single-share denominator solid.
NUM_COL  <- "rgba(135, 206, 235, 0.45)"
AVG_COL  <- "rgba(135, 206, 235, 0.85)"
HALF_COL <- "#2c7fb8"
LINE_COL <- "#666666"
MARK_COL <- "#d62728"


# decade_ticks: one tick per power of ten spanning the values given.
# Both sensitivity plots put a quantity that runs over many decades on a
# log axis, and plotly labels such an axis with a mixture of mantissas
# ("2" and "5" between the decades) and SI prefixes ("100u" for a
# hundred-millionth), which leaves a reader unable to say what a given
# gridline is. Ticks only at the decades, written as powers of ten, can
# be read one way. Values at or below zero cannot sit on a log axis, so
# they take no part in setting the range. The dashed threshold line is
# part of both pictures, so its value is passed in alongside the data.
decade_ticks <- function(x) {
  x <- x[is.finite(x) & x > 0]
  if (length(x) == 0L) {
    return(numeric(0))
  }
  10^(seq(floor(log10(min(x))), ceiling(log10(max(x)))))
}


# plot_bf_decomposition: the three probabilities behind both Bayes
# factors, at every count of N observations the researcher might have
# reported. Three bars per count. Dividing the first bar by the second
# gives the uniform-weights Bayes factor and by the third gives the
# worst-case one, so a reader can see where both numbers come from
# rather than take them on trust.
plot_bf_decomposition <- function(y_W, y_R) {
  df <- bf_decomposition(y_W, y_R)
  n <- y_W + y_R

  # The bar type belongs on each add_trace() below, never here: a
  # type on the base call materialises a fourth trace built from x
  # alone, which plotly draws with the count itself as the height.
  # That trace has no name, reaches the legend as "trace 0", and its
  # heights run to n while every real bar is a probability below one,
  # so it takes over the y scale and flattens the three real bars.
  p <- plotly::plot_ly(df, x = ~k)
  p <- plotly::add_trace(
    p, y = ~numerator, type = "bar",
    name = "averaged over shares above one half",
    marker = list(color = NUM_COL)
  )
  p <- plotly::add_trace(
    p, y = ~den_avg, type = "bar",
    name = "averaged over shares at or below one half",
    marker = list(color = AVG_COL)
  )
  p <- plotly::add_trace(
    p, y = ~den_half, type = "bar",
    name = "at a share of one half, the rival's best case",
    marker = list(color = HALF_COL)
  )
  # Mark the count the researcher actually reported, so the two
  # divisions the cards print can be located in the picture.
  p <- plotly::layout(
    p,
    barmode = "group",
    xaxis = list(
      title = paste0("observations supporting the working theory, of ", n),
      dtick = 1
    ),
    yaxis = list(title = "probability of the count"),
    # The horizontal legend and the x-axis title are both drawn below
    # the plotting area, so moving the legend down without widening
    # the bottom margin prints the axis title on top of it. The two
    # settings only work as a pair.
    legend = list(orientation = "h", y = -0.32, yanchor = "top"),
    margin = list(b = 120),
    shapes = list(list(
      type = "line",
      x0 = y_W, x1 = y_W, yref = "paper", y0 = 0, y1 = 1,
      line = list(dash = "dot", color = MARK_COL, width = 1)
    )),
    annotations = list(list(
      x = y_W, y = 1, yref = "paper", text = paste0("observed: ", y_W),
      showarrow = FALSE, yanchor = "bottom", font = list(color = MARK_COL)
    ))
  )
  p
}


# plot_bf_vs_omega: the uniform-weights Bayes factor as the assumed
# search bias grows, with the threshold as a dashed line and the
# tipping point as a dotted vertical one.
plot_bf_vs_omega <- function(y_W, y_R, threshold,
                             theta_cut = 0.5,
                             omega_star = NULL) {
  df <- bf_omega_curve(y_W, y_R, threshold, theta_cut)
  # A quadrature failure at an extreme omega leaves a gap rather than
  # letting the log axis truncate the curve silently.
  df <- df[is.finite(df$bf), , drop = FALSE]

  # Doublings spanning the data: 0.25, 0.5, 1, 2, 4, 8 at the defaults.
  omega_ticks <- 2^(seq(
    floor(log2(min(df$omega))),
    ceiling(log2(max(df$omega)))
  ))

  # One tick per decade on the Bayes-factor axis. plotly labelled its
  # minor ticks with their mantissa and abbreviated the large values
  # with SI prefixes, so the axis read "2 / 10k / 5 / 2 / 1000 / 5".
  bf_ticks <- decade_ticks(c(df$bf, threshold))

  p <- plotly::plot_ly(
    data = df, x = ~omega, y = ~bf,
    type = "scatter", mode = "lines",
    name = "uniform-weights Bayes factor",
    line = list(color = HALF_COL)
  )
  p <- plotly::add_lines(
    p,
    x = range(df$omega), y = c(threshold, threshold),
    name = paste0("threshold = ", threshold),
    line = list(dash = "dash", color = LINE_COL),
    inherit = FALSE
  )
  shapes <- if (!is.null(omega_star) && is.finite(omega_star) &&
                omega_star > 1) {
    list(list(
      type = "line", x0 = omega_star, x1 = omega_star,
      yref = "paper", y0 = 0, y1 = 1,
      line = list(dash = "dot", color = MARK_COL, width = 1)
    ))
  } else {
    list()
  }
  plotly::layout(
    p,
    # plotly labels a log axis's minor ticks with their mantissa, which
    # turned the range from 0.25 to 8 into "3 4 5 6 7 8 9 1 2 3 4 5 6 7
    # 8". The middle "1" was a search bias of one, the point at which the
    # search favours neither theory, and nothing on the axis said so.
    # The ticks below are the doublings either side of that point, taken
    # from the data so they still fit if omega_range is widened.
    xaxis = list(
      type = "log",
      title = "assumed search bias toward the working theory",
      tickmode = "array",
      tickvals = omega_ticks,
      ticktext = as.character(omega_ticks)
    ),
    yaxis = list(
      type = "log",
      title = "Bayes factor",
      tickmode = "array",
      tickvals = bf_ticks,
      exponentformat = "power"
    ),
    hovermode = "x unified",
    shapes = shapes
  )
}


# plot_post_odds_vs_M: the posterior odds as background cases favoring
# the rival are granted. The y axis says posterior odds, not Bayes
# factor: under these priors the Bayes factor rises while the posterior
# odds fall, so labeling the axis wrongly would reverse the reading.
plot_post_odds_vs_M <- function(y_W, y_R, threshold,
                                theta_cut = 0.5,
                                M_max = 50L,
                                M_star = NULL) {
  df <- post_odds_M_curve(y_W, y_R, theta_cut, M_max, threshold)

  # The odds fall through eight decades, which plotly wrote as
  # "1 / 0.01 / 100u / 1u / 10n" using SI prefixes for micro and nano.
  odds_ticks <- decade_ticks(c(df$post_odds, threshold))

  p <- plotly::plot_ly(
    data = df, x = ~M, y = ~post_odds,
    type = "bar", marker = list(color = HALF_COL),
    name = "posterior odds"
  )
  p <- plotly::add_lines(
    p,
    x = c(0, M_max), y = c(threshold, threshold),
    name = paste0("threshold = ", threshold),
    line = list(dash = "dash", color = LINE_COL),
    inherit = FALSE
  )
  shapes <- if (!is.null(M_star) && !is.na(M_star) && M_star > 0L) {
    list(list(
      type = "line", x0 = M_star, x1 = M_star,
      yref = "paper", y0 = 0, y1 = 1,
      line = list(dash = "dot", color = MARK_COL, width = 1)
    ))
  } else {
    list()
  }
  plotly::layout(
    p,
    xaxis = list(title = "background cases favoring the rival (M)"),
    yaxis = list(
      type = "log",
      title = "posterior odds",
      tickmode = "array",
      tickvals = odds_ticks,
      exponentformat = "power"
    ),
    shapes = shapes
  )
}
