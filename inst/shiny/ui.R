# ui.R -- bslib::page_sidebar layout with one set of inputs in the
# sidebar and a top-level navset (Result / About). The Result tab
# nests a second navset for the two models (Binomial / Urn) per the
# user's "tabs, one model per tab" preference. The Sensitivity tab
# arrives in Phase 2.

bslib::page_sidebar(
  title = "DrWrinch: Bayes factors for process tracing",
  theme = bslib::bs_theme(version = 5),

  sidebar = bslib::sidebar(
    title = "Evidence counts",
    width = 320,

    numericInput(
      "y_W",
      "Pro-working-theory evidence (y_W)",
      value = 9, min = 0, step = 1
    ),
    numericInput(
      "y_R",
      "Pro-rival evidence (y_R)",
      value = 3, min = 0, step = 1
    ),
    numericInput(
      "threshold",
      "Decision threshold (BF)",
      value = 20, min = 1e-6, step = 1
    ),

    # theta_cut, prior_a, prior_b are hidden behind an Advanced
    # accordion per Decision C: most users of this app should not
    # need to know what a Beta-prior shape parameter is.
    bslib::accordion(
      open = FALSE,
      bslib::accordion_panel(
        title = "Advanced (binomial model)",
        sliderInput(
          "theta_cut",
          "theta_cut (cutpoint separating H_1 from rival)",
          value = 0.5, min = 0.05, max = 0.95, step = 0.05
        ),
        numericInput(
          "prior_a",
          "prior_a (Beta shape for working theory)",
          value = 1, min = 0.01, step = 0.5
        ),
        numericInput(
          "prior_b",
          "prior_b (Beta shape for rival)",
          value = 1, min = 0.01, step = 0.5
        )
      )
    )
  ),

  bslib::navset_card_tab(
    id = "main_tabs",

    bslib::nav_panel(
      title = "Result",
      bslib::navset_card_tab(
        id = "model_tabs",
        bslib::nav_panel(
          title = "Binomial",
          uiOutput("result_binom")
        ),
        bslib::nav_panel(
          title = "Urn",
          uiOutput("result_urn")
        )
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
