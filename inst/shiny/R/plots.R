# plotly wrappers around the pure curve functions in helpers.R.
# Kept in a separate file so that the data computation can be tested
# without loading plotly, and so the plot file can be regenerated
# without touching the helpers.

# plot_bf_vs_omega: two-series line plot of BF as omega varies.
# Binomial in one color, urn in another (or omitted when undefined),
# threshold as a dashed horizontal line, omega_star tipping points as
# dotted vertical lines.
plot_bf_vs_omega <- function(y_W, y_R, threshold,
                             theta_cut = 0.5,
                             omega_star_b = NULL,
                             omega_star_u = NULL,
                             urn_defined = TRUE) {
  df_b <- bf_omega_curve(y_W, y_R, "binomial", threshold, theta_cut)
  df <- if (urn_defined) {
    df_u <- bf_omega_curve(y_W, y_R, "urn", threshold, theta_cut)
    rbind(df_b, df_u)
  } else {
    df_b
  }
  # Drop NaN/NA/non-finite BF rows so plotly's log y-axis does not
  # silently truncate. The cause is usually a quadrature failure at
  # extreme omega; the curve is monotone so a gap is acceptable.
  df <- df[is.finite(df$bf), , drop = FALSE]

  p <- plotly::plot_ly(
    data = df,
    x = ~omega, y = ~bf, color = ~model,
    type = "scatter", mode = "lines",
    colors = c("binomial" = "#1f77b4", "urn" = "#ff7f0e")
  )
  # Threshold reference line spanning the visible omega range. Drawn
  # as a trace (rather than a layout shape) so it appears in the
  # plotly legend and the user can toggle it.
  p <- plotly::add_lines(
    p,
    x = range(df$omega),
    y = c(threshold, threshold),
    name = paste0("threshold = ", threshold),
    line = list(dash = "dash", color = "#666666"),
    inherit = FALSE
  )
  # omega_star markers as vertical reference lines via layout shapes.
  # Only draw markers that fall inside the plotted domain and that
  # represent a real tipping point (positive finite value).
  shapes <- list()
  add_marker <- function(om, color) {
    if (!is.null(om) && is.finite(om) && om > 1) {
      list(
        type = "line",
        x0 = om, x1 = om,
        yref = "paper", y0 = 0, y1 = 1,
        line = list(dash = "dot", color = color, width = 1)
      )
    } else {
      NULL
    }
  }
  shapes <- Filter(Negate(is.null), list(
    add_marker(omega_star_b, "#1f77b4"),
    if (urn_defined) add_marker(omega_star_u, "#ff7f0e") else NULL
  ))
  p <- plotly::layout(
    p,
    xaxis = list(type = "log", title = "Observation bias (omega)"),
    yaxis = list(type = "log", title = "Bayes factor"),
    title = "BF vs. observation bias",
    hovermode = "x unified",
    shapes = shapes
  )
  p
}


# plot_bf_vs_M: bar chart of BF as a function of rival-favoring
# pseudo-observations M (Beta(1, M+1) prior). Threshold horizontal
# line; M_star vertical reference if available.
plot_bf_vs_M <- function(y_W, y_R, threshold,
                         theta_cut = 0.5,
                         M_max = 50L,
                         M_star = NULL) {
  df <- bf_M_curve(y_W, y_R, theta_cut, M_max, threshold)

  p <- plotly::plot_ly(
    data = df,
    x = ~M, y = ~bf,
    type = "bar",
    marker = list(color = "#1f77b4"),
    name = "BF (binomial)"
  )
  p <- plotly::add_lines(
    p,
    x = c(0, M_max),
    y = c(threshold, threshold),
    name = paste0("threshold = ", threshold),
    line = list(dash = "dash", color = "#666666"),
    inherit = FALSE
  )
  shape_list <- list()
  if (!is.null(M_star) && !is.na(M_star) && M_star > 0L) {
    shape_list <- list(list(
      type = "line",
      x0 = M_star, x1 = M_star,
      yref = "paper", y0 = 0, y1 = 1,
      line = list(dash = "dot", color = "#d62728", width = 1)
    ))
  }
  p <- plotly::layout(
    p,
    xaxis = list(title = "Rival-favoring pseudo-observations (M)"),
    yaxis = list(type = "log", title = "Bayes factor"),
    title = "BF under Beta(1, M+1) priors",
    shapes = shape_list
  )
  p
}
