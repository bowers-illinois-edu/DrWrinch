# ui.R -- one model, two Bayes factors.
#
# The Result tab puts the two Bayes factors side by side rather than in
# separate tabs, because the point of the paper is that they come from
# the same model and differ only in how they treat the rival's range of
# shares. Under them sits the picture that shows where both come from.
#
# The sidebar carries only the two counts and the threshold. Earlier
# versions offered a cutpoint and a Beta prior on the whole interval;
# both are gone. The cutpoint applies to only one of the two Bayes
# factors, so moving it would leave the two cards showing numbers that
# cannot be compared, and the whole-interval prior makes the reported
# quantity the posterior odds rather than a Bayes factor. A reader who
# wants either can call bf_binomial() or bf_rescaled() directly.

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
      "threshold",
      "The value at which you would set the rival aside",
      value = 20, min = 1e-6, step = 1
    ),
    tags$p(
      class = "text-muted small",
      "Both Bayes factors come from one model: each observation ",
      "supports the working theory with probability theta, the share ",
      "of the evidence that supports it. The working theory claims a ",
      "share above one half and the rival a share at or below it."
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
      bslib::layout_columns(
        col_widths = c(6, 6),
        bslib::card(
          bslib::card_header("Averaging over the rival's whole range"),
          uiOutput("result_uniform")
        ),
        bslib::card(
          bslib::card_header("Granting the rival her best single share"),
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
      plotly::plotlyOutput("plot_omega", height = "360px"),
      plotly::plotlyOutput("plot_M", height = "320px")
    ),

    bslib::nav_panel(
      title = "About",
      uiOutput("about_panel")
    )
  )
)
