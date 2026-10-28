# ui.R -- one model, two Bayes factors, and the paper's rule.
#
# The Result tab opens with what the paper's rule decides at the
# reader's counts: the rival is set aside, at least provisionally, when
# the uniform-weights Bayes factor is at least 20 and the worst-case
# Bayes factor is above 1. Under that sit the two Bayes factors side by
# side, because they come from the same model and differ only in how
# they treat the rival's range of shares, and under them the picture
# that shows where both come from.
#
# The sidebar carries the two counts and the rule's two thresholds.

bslib::page_sidebar(
  title = "DrWrinch: Bayes factors for process tracing",
  theme = bslib::bs_theme(version = 5),

  # Not fillable. A fillable page forces each tab to fit the viewport
  # height, which collapsed the Sensitivity tab's two plots -- 360px
  # and 320px of requested height, under a paragraph of text -- into
  # unreadable strips with no way to scroll to them. Ordinary document
  # flow honours the heights the plots ask for and lets the page
  # scroll when a tab is taller than the window.
  fillable = FALSE,

  sidebar = bslib::sidebar(
    title = "Evidence counts",
    width = 320,

    numericInput(
      "y_W",
      "Observations supporting the working theory",
      value = 9, min = 0, step = 1
    ),
    numericInput(
      "y_R",
      "Observations supporting the rival",
      value = 3, min = 0, step = 1
    ),
    numericInput(
      "threshold_uniform",
      "Smallest uniform-weights Bayes factor at which to set the rival aside",
      # min = 0 rather than a tiny positive number: the browser counts a
      # value valid only if it is min plus a whole number of steps, so a
      # min of 1e-6 marked the default of 20 as invalid. The server
      # rejects zero itself.
      value = 20, min = 0, step = 1
    ),
    numericInput(
      "threshold_worst",
      "Value the worst-case Bayes factor must be above",
      value = 1, min = 0, step = 0.5
    ),
    tags$p(
      class = "text-muted small",
      "Both Bayes factors come from one model: each observation ",
      "supports the working theory with probability theta, the share ",
      "of the evidence that supports it. The working theory claims a ",
      "share above one half and the rival a share at or below it. The ",
      "paper's rule sets the rival aside when the uniform-weights Bayes ",
      "factor is at least 20 and the worst-case Bayes factor is above 1."
    )
  ),

  bslib::navset_card_tab(
    id = "main_tabs",

    # Give each tab its natural height instead of squeezing it to fit
    # the card. bslib wraps every nav_panel in a card_body() that is
    # fillable by default, which compressed the Sensitivity tab's two
    # plots -- 360px and 320px of requested height -- into strips about
    # twenty pixels tall, with no way to scroll to them. navset_card_tab()
    # has no fillable argument in bslib 0.11, so the wrapper it applies
    # is replaced with a non-fillable one.
    wrapper = function(...) bslib::card_body(..., fillable = FALSE),

    bslib::nav_panel(
      title = "Result",
      bslib::card(
        bslib::card_header("The paper's rule"),
        uiOutput("rule_text")
      ),
      bslib::layout_columns(
        col_widths = c(6, 6),
        bslib::card(
          bslib::card_header("Averaging over the rival's whole range"),
          uiOutput("result_uniform")
        ),
        bslib::card(
          bslib::card_header("The rival at its most favorable share"),
          uiOutput("result_worst_case")
        )
      ),
      bslib::card(
        bslib::card_header("Where both numbers come from"),
        uiOutput("decomposition_text"),
        plotly::plotlyOutput("plot_decomposition", height = "380px")
      )
    ),

    bslib::nav_panel(
      title = "Sensitivity",
      uiOutput("tipping_text"),
      plotly::plotlyOutput("plot_omega", height = "420px")
    ),

    bslib::nav_panel(
      title = "About",
      uiOutput("about_panel")
    )
  )
)
