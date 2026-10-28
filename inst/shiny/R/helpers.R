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
# Both Bayes factors the app shows are defined at every pair of counts,
# so NA should not arise; the branch stays because Inf can (a rival
# probability that underflows to zero at very large counts) and because
# a defensive label beats a blank cell.
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


# The paper's rule sets the rival aside, at least provisionally, when
# the uniform-weights Bayes factor is at least threshold_uniform (20)
# and the worst-case Bayes factor is above threshold_worst (1). The
# three helpers below turn the package's numbers into the sentences the
# app shows, and each says which of the two conditions decides, because
# that tells the reader which number to look at next.

# interpret_rule() says which way the rule goes at the reader's counts.
# The uniform-weights condition is met at its threshold and the
# worst-case condition is not, as in the paper.
interpret_rule <- function(bf_uniform, bf_worst,
                           threshold_uniform = 20, threshold_worst = 1) {
  uniform_fails <- bf_uniform < threshold_uniform
  worst_fails <- bf_worst <= threshold_worst
  if (!uniform_fails && !worst_fails) {
    return(paste0(
      "A researcher following the rule sets the rival aside, at least ",
      "provisionally: the uniform-weights Bayes factor is at least ",
      threshold_uniform, " and the worst-case Bayes factor is above ",
      threshold_worst, "."
    ))
  }
  reasons <- c(
    if (uniform_fails) paste0("the uniform-weights Bayes factor is below ",
                              threshold_uniform),
    if (worst_fails) paste0("the worst-case Bayes factor is ",
                            threshold_worst, " or below")
  )
  paste0("A researcher following the rule keeps the rival, because ",
         paste(reasons, collapse = " and "), ".")
}


# How much more likely a search with bias om is to find a
# pro-working-theory observation, in words. Below a bias of two a
# percentage reads naturally ("about 1 percent more likely"); from two
# on a multiple does ("2.33 times as likely" rather than "133 percent
# more likely").
describe_bias <- function(om) {
  if (om < 2) {
    paste0("about ", round((om - 1) * 100), " percent more likely")
  } else {
    paste0(formatC(om, format = "f", digits = 2), " times as likely")
  }
}


# interpret_bias() turns the list sens_bias() returns into a sentence.
# omega_star is 0 when the rule already keeps the rival at an unbiased
# search, Inf for a condition no bias makes fail, and NA when the
# package's search found no crossing.
interpret_bias <- function(sb, threshold_uniform = 20, threshold_worst = 1) {
  om <- sb$omega_star
  if (!is.na(om) && om == 0) {
    return(paste0(
      "The rule keeps the rival even with an unbiased search, so there is ",
      "no decision for bias to change."
    ))
  }
  if (is.na(om) || is.infinite(om)) {
    return(paste0(
      "No bias the search tried changes the decision: neither Bayes ",
      "factor falls to its threshold."
    ))
  }
  uniform_first <- isTRUE(sb$omega_uniform <= sb$omega_worst) ||
    is.na(sb$omega_worst)
  first <- if (uniform_first) {
    paste0("the uniform-weights Bayes factor falls to ", threshold_uniform)
  } else {
    paste0("the worst-case Bayes factor falls to ", threshold_worst)
  }
  other_om <- if (uniform_first) sb$omega_worst else sb$omega_uniform
  other <- if (is.infinite(other_om)) {
    if (uniform_first) {
      paste0(" No bias makes the worst-case Bayes factor fall to ",
             threshold_worst, ".")
    } else {
      paste0(" No bias makes the uniform-weights Bayes factor fall to ",
             threshold_uniform, ".")
    }
  } else if (is.na(other_om)) {
    ""
  } else {
    paste0(" The other condition fails only at a bias of ",
           formatC(other_om, format = "f", digits = 2), ".")
  }
  paste0(
    "A search ", describe_bias(om), " to find a pro-working-theory ",
    "observation than a pro-rival one would change the decision: at a ",
    "bias of ", formatC(om, format = "f", digits = 2), ", ", first, ".",
    other
  )
}


# interpret_coding() turns the list sens_coding() returns into a
# sentence. x_star is 0 when the rule already keeps the rival as coded
# and NA when no re-coding of the supporting observations makes either
# condition fail.
interpret_coding <- function(sc, threshold_uniform = 20, threshold_worst = 1) {
  x <- sc$x_star
  if (!is.na(x) && x == 0L) {
    return("The rule keeps the rival as coded, so no re-coding is needed.")
  }
  if (is.na(x)) {
    return(paste0(
      "No re-coding of the observations supporting the working theory ",
      "changes the decision."
    ))
  }
  uniform_first <- !is.na(sc$x_uniform) && sc$x_uniform == x
  which_cond <- if (uniform_first) {
    paste0("takes the uniform-weights Bayes factor below ", threshold_uniform)
  } else {
    paste0("takes the worst-case Bayes factor to ", threshold_worst,
           " or below")
  }
  paste0(
    x, " re-coded observation", if (x == 1L) " " else "s ",
    "(relabeling ", if (x == 1L) "an observation" else paste(x, "observations"),
    " that supported the working theory as supporting the rival) ",
    which_cond, " and changes the decision."
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
