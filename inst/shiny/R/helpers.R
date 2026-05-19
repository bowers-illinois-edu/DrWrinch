# Pure helpers for the DrWrinch Shiny app.
#
# These functions live under inst/shiny/R/ rather than the package's
# own R/ because they belong to the app, not to the package's exported
# namespace. The app sources this file via global.R; tests reach it via
# system.file("shiny/R/helpers.R", package = "DrWrinch").

# Kass & Raftery (1995, JASA, Table 6) Bayes factor scale. Bins are
# upper-inclusive, so BF = 3 is still "not worth more than a bare
# mention" and BF = 3.0001 is "positive". For BF < 1 we mirror via
# 1/BF and let format_bf() flip the direction label.
KR_BREAKS <- c(3, 20, 150)
KR_LABELS <- c(
  "not worth more than a bare mention",
  "positive",
  "strong",
  "very strong"
)


# bf_label() returns the Kass & Raftery bin name for a numeric BF.
# Direction is handled separately in format_bf() so this function can
# also be reused by the Jeffreys-strip plot (Phase 2), which annotates
# bins symmetrically around BF = 1.
bf_label <- function(bf) {
  if (is.na(bf)) return("undefined")
  # An infinite BF sits above any finite K&R cutoff; assign it the
  # top bin rather than letting the if-chain fall through.
  if (is.infinite(bf) && bf > 0) return("very strong")
  if (bf <= 0) return("undefined")
  # For BF < 1, mirror onto [1, Inf) and apply the same scale; the
  # rival-favoring direction is reported by format_bf().
  m <- if (bf >= 1) bf else 1 / bf
  if (m <= 3)   return("not worth more than a bare mention")
  if (m <= 20)  return("positive")
  if (m <= 150) return("strong")
  "very strong"
}


# format_bf() packages a numeric BF into the three fields the UI cards
# render: a printable value string, the K&R verdict, and the direction.
# NA (urn undefined) and Inf (rival probability numerically zero) are
# expected branches, not errors, and each gets its own labeling.
format_bf <- function(bf) {
  if (is.na(bf)) {
    return(list(
      value = "undefined",
      verdict = "undefined",
      direction = "not applicable"
    ))
  }
  if (bf <= 0) {
    return(list(
      value = "undefined",
      verdict = "undefined",
      direction = "not applicable"
    ))
  }
  verdict <- bf_label(bf)
  # Direction reports which theory the evidence tilts toward. Exact
  # equipoise (BF = 1) gets "neither" rather than a side label.
  direction <- if (is.infinite(bf)) {
    "favors working theory"
  } else if (bf > 1) {
    "favors working theory"
  } else if (bf < 1) {
    "favors rival"
  } else {
    "neither"
  }
  # signif() to three significant figures reads cleanly across the
  # BF range readers will see (e.g., "0.5", "7.83", "39", "150").
  # Inf gets a phrase rather than the literal "Inf" so it does not
  # look like a typo in a screenshot.
  value <- if (is.infinite(bf)) {
    "> 150 (very large)"
  } else {
    formatC(signif(bf, 3), format = "g")
  }
  list(value = value, verdict = verdict, direction = direction)
}


# interpret_omega_star() turns the numeric tipping point from
# sens_urn()/sens_binomial() into a sentence a non-statistician can
# read. The three branches map to the three values
# .find_omega_tipping() can return: 0, NA_real_, or a positive number.
interpret_omega_star <- function(om, threshold = 20) {
  # om = 0: baseline BF was already at or below threshold, so no
  # tilt toward pro-rival observation is needed for the conclusion
  # to fail.
  if (!is.na(om) && om == 0) {
    return(paste0(
      "The Bayes factor sits below threshold ", threshold,
      " at baseline. The conclusion fails without any observation bias."
    ))
  }
  # NA_real_ means the doubling search reached its cap without the
  # BF crossing threshold. The conclusion is robust to any plausible
  # observation bias.
  if (is.na(om)) {
    return(paste0(
      "The Bayes factor stays above threshold ", threshold,
      " across the range of observation bias the search considered. ",
      "The conclusion is robust to any realistic observation bias."
    ))
  }
  # Positive omega_star: report the bias as a percentage above 1.
  # round() to whole percent reads more naturally than the raw float;
  # the underlying numeric remains available to the plot.
  pct <- round((om - 1) * 100)
  paste0(
    "Pro-working-theory items would need to be about ", pct,
    "% more likely to be observed than pro-rival items for the ",
    "Bayes factor to drop to threshold ", threshold, "."
  )
}


# validate_counts() centralizes the input checks the result and
# sensitivity render paths both need. Lives here, not in server.R, so
# the same prose appears wherever a count input is read.
#
# Returns nothing on success. On failure, shiny::validate() short-
# circuits the calling reactive with the friendly message.
validate_counts <- function(y_W, y_R) {
  # Whole-number check uses (x == round(x)) so that numericInput's
  # double-valued integers (e.g., 7, not 7L) still pass. This catches
  # the 7.5-typed-into-the-box case the server's as.integer() would
  # otherwise silently truncate.
  shiny::validate(
    shiny::need(
      is.numeric(y_W) && length(y_W) == 1L && !is.na(y_W) &&
        y_W >= 0 && y_W == round(y_W),
      "Enter a non-negative whole number for y_W (working-theory count)."
    ),
    shiny::need(
      is.numeric(y_R) && length(y_R) == 1L && !is.na(y_R) &&
        y_R >= 0 && y_R == round(y_R),
      "Enter a non-negative whole number for y_R (rival-theory count)."
    ),
    shiny::need(
      y_W + y_R > 0,
      "y_W and y_R cannot both be zero -- there is no evidence to evaluate."
    )
  )
}


# interpret_M_star() turns the prior-sweep tipping point from
# sens_binomial() into a sentence. Same three-branch pattern as
# interpret_omega_star(): 0 (baseline already fails), NA_integer_
# (BF stays above threshold across the prior sweep), positive integer
# (number of rival-favoring pseudo-observations required).
interpret_M_star <- function(m, threshold = 20) {
  if (!is.na(m) && m == 0L) {
    return(paste0(
      "The Bayes factor sits below threshold ", threshold,
      " at baseline. No rival-favoring pseudo-observations are ",
      "needed for the conclusion to fail."
    ))
  }
  if (is.na(m)) {
    return(paste0(
      "The Bayes factor stays above threshold ", threshold,
      " across the prior sweep the search considered. The conclusion ",
      "is robust to any realistic rival-tilted prior."
    ))
  }
  paste0(
    "Adding M = ", m, " rival-favoring pseudo-observation",
    if (m == 1L) "" else "s",
    " (a Beta(1, M + 1) prior) drops the Bayes factor below ",
    "threshold ", threshold, "."
  )
}


# bf_omega_curve() returns a long-format data.frame of BF samples
# along a log-spaced omega grid for one model. Pure function -- no
# Shiny, no plotly. The plot wrapper composes binomial and urn curves
# via rbind() and feeds them to plotly.
#
# Defaults: 80 grid points between omega = 0.25 and omega = 8 cover
# four-fold pro-rival bias to eight-fold pro-H_1 bias, wider than any
# observation-bias prior we expect in process tracing. Log spacing
# gives equal visual weight to omega < 1 and omega > 1, which matters
# because the tipping point is usually close to 1.
bf_omega_curve <- function(y_W, y_R,
                           model = c("binomial", "urn"),
                           threshold = 20,
                           theta_cut = 0.5,
                           n_grid = 80L,
                           omega_range = c(0.25, 8)) {
  model <- match.arg(model)
  omegas <- exp(seq(
    log(omega_range[1]),
    log(omega_range[2]),
    length.out = n_grid
  ))
  bf_at <- if (model == "binomial") {
    # bf_binomial uses stats::integrate; wrap in tryCatch so a
    # quadrature failure at pathological omega yields NA rather than
    # killing the curve.
    function(om) tryCatch(
      DrWrinch::bf_binomial(y_W, y_R, omega = om, theta_cut = theta_cut),
      error = function(e) NA_real_
    )
  } else {
    function(om) tryCatch(
      DrWrinch::bf_urn(y_W, y_R, omega = om),
      error = function(e) NA_real_
    )
  }
  bfs <- vapply(omegas, bf_at, numeric(1))
  data.frame(
    omega = omegas,
    bf = bfs,
    model = model,
    threshold = threshold,
    stringsAsFactors = FALSE
  )
}


# bf_M_curve() returns BF as a function of the prior pseudo-
# observation count M, with prior Beta(1, M + 1). Used by the
# binomial-only prior-sensitivity bar chart on the Sensitivity tab.
bf_M_curve <- function(y_W, y_R,
                       theta_cut = 0.5,
                       M_max = 50L,
                       threshold = 20) {
  Ms <- 0:M_max
  bfs <- vapply(Ms, function(M) {
    DrWrinch::bf_binomial(
      y_W, y_R,
      prior_a = 1, prior_b = M + 1L,
      theta_cut = theta_cut
    )
  }, numeric(1))
  data.frame(
    M = Ms,
    bf = bfs,
    threshold = threshold,
    stringsAsFactors = FALSE
  )
}
