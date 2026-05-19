# server.R -- reactive graph for the Phase 1 MVP. Two BF reactives,
# two renderUI cards, plus the static About panel. The sensitivity
# tab, plots, and tipping-point prose arrive in Phase 2.
#
# Reactive naming: bf_binom (binomial BF reactive) and bf_urn_v (urn
# BF reactive). The "_v" on the urn reactive avoids shadowing the
# package function bf_urn() inside this server scope; we still need
# to call DrWrinch::bf_urn() to compute it.

function(input, output, session) {

  # counts_ok() short-circuits with a shiny::validate() message when
  # the inputs do not satisfy validate_counts(). All downstream
  # reactives read y_W / y_R from this, so the validation prose
  # appears in both card outputs simultaneously rather than firing
  # twice with diverging text.
  counts_ok <- reactive({
    validate_counts(input$y_W, input$y_R)
    list(
      y_W = as.integer(input$y_W),
      y_R = as.integer(input$y_R)
    )
  })

  bf_binom <- reactive({
    co <- counts_ok()
    DrWrinch::bf_binomial(
      co$y_W, co$y_R,
      prior_a = input$prior_a,
      prior_b = input$prior_b,
      theta_cut = input$theta_cut
    )
  })

  bf_urn_v <- reactive({
    co <- counts_ok()
    DrWrinch::bf_urn(co$y_W, co$y_R)
  })

  output$result_binom <- renderUI({
    fmt <- format_bf(bf_binom())
    tagList(
      tags$p(tags$strong("Bayes factor:"), " ", fmt$value),
      tags$p(tags$strong("Verdict (Kass & Raftery):"), " ", fmt$verdict),
      tags$p(tags$strong("Direction:"), " ", fmt$direction)
    )
  })

  output$result_urn <- renderUI({
    bf <- bf_urn_v()
    fmt <- format_bf(bf)
    if (is.na(bf)) {
      # The urn construction is undefined when y_R > y_W + 1: the
      # rival-favorable urn (size 2 y_W + 1) cannot supply a sample
      # of size n = y_W + y_R. We explain this out loud rather than
      # render a blank cell -- per Decision D in PLAN_SHINY.md.
      tagList(
        tags$p(tags$strong("Bayes factor:"), " undefined"),
        tags$p(
          "The urn model is undefined for these counts because the ",
          "rival-favorable urn cannot supply a sample of size ",
          "n = y_W + y_R when y_R > y_W + 1. Use the binomial tab ",
          "or revisit the counts."
        )
      )
    } else {
      tagList(
        tags$p(tags$strong("Bayes factor:"), " ", fmt$value),
        tags$p(tags$strong("Verdict (Kass & Raftery):"), " ", fmt$verdict),
        tags$p(tags$strong("Direction:"), " ", fmt$direction)
      )
    }
  })

  output$about_panel <- renderUI({
    tagList(
      tags$h4("Two models, one question"),
      tags$p(
        "DrWrinch computes Bayes factors for a working theory against ",
        "a single rival, given counts of evidence favoring each side. ",
        "Two generative models are implemented:"
      ),
      tags$ul(
        tags$li(
          tags$strong("Binomial:"),
          " open-ended evidence collection -- ongoing interviews, ",
          "an expanding archive, a growing set of cases."
        ),
        tags$li(
          tags$strong("Urn (hypergeometric):"),
          " bounded archive -- a closed historical record, a fixed ",
          "set of documents. Returns 'undefined' when the rival- ",
          "favorable urn construction cannot supply the observed ",
          "sample size (y_R > y_W + 1)."
        )
      ),
      tags$p(
        "We recommend reading both tabs together. The paper (Lopez, ",
        "Bowers, and Gajardo Cooper 2026) argues that when the design ",
        "is ambiguous between open-ended and bounded evidence, ",
        "computing both Bayes factors is the conservative move: the ",
        "urn is more favorable to the working theory by construction, ",
        "and the binomial generalizes more easily to other settings."
      ),
      tags$h4("Verdict scale"),
      tags$p(
        "Verdicts use the Kass & Raftery (1995) scale:"
      ),
      tags$ul(
        tags$li("BF in (1, 3]: not worth more than a bare mention"),
        tags$li("BF in (3, 20]: positive"),
        tags$li("BF in (20, 150]: strong"),
        tags$li("BF > 150: very strong")
      ),
      tags$p(
        "For BF < 1, the same bins apply to 1/BF and the direction ",
        "flips from 'favors working theory' to 'favors rival'. BF = 1 ",
        "is exact equipoise; the direction reads 'neither'."
      )
    )
  })
}
