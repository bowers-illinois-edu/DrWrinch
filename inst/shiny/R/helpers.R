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
  shiny::validate(
    shiny::need(
      is.numeric(y_W) && length(y_W) == 1L && !is.na(y_W) && y_W >= 0,
      "Enter a non-negative whole number for y_W (working-theory count)."
    ),
    shiny::need(
      is.numeric(y_R) && length(y_R) == 1L && !is.na(y_R) && y_R >= 0,
      "Enter a non-negative whole number for y_R (rival-theory count)."
    ),
    shiny::need(
      y_W + y_R > 0,
      "y_W and y_R cannot both be zero -- there is no evidence to evaluate."
    )
  )
}
