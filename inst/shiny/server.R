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

  # Sensitivity reactives. We call the package's sens_* functions
  # directly so the numeric tipping points the app shows match the
  # paper's (and the vignette's) computation exactly. No re-derivation
  # inside the server.
  sens_b <- reactive({
    co <- counts_ok()
    DrWrinch::sens_binomial(
      co$y_W, co$y_R,
      threshold = input$threshold,
      theta_cut = input$theta_cut
    )
  })

  sens_u <- reactive({
    co <- counts_ok()
    DrWrinch::sens_urn(
      co$y_W, co$y_R,
      threshold = input$threshold
    )
  })

  # Coding-error reactives, the paper's third sensitivity question. Same
  # pattern: call sens_coding() directly so the app's re-coding counts
  # match the paper's. The urn branch returns NA when the baseline urn is
  # undefined; the tipping_text output guards on that below.
  sens_code_b <- reactive({
    co <- counts_ok()
    DrWrinch::sens_coding(
      co$y_W, co$y_R, model = "binomial",
      threshold = input$threshold, theta_cut = input$theta_cut
    )
  })

  sens_code_u <- reactive({
    co <- counts_ok()
    DrWrinch::sens_coding(
      co$y_W, co$y_R, model = "urn",
      threshold = input$threshold
    )
  })

  output$result_binom <- renderUI({
    fmt <- format_bf(bf_binom())
    tagList(
      tags$p(tags$strong("Bayes factor:"), " ", fmt$value),
      tags$p(tags$strong("Verdict (Kass & Raftery):"), " ", fmt$verdict),
      tags$p(tags$strong("Direction:"), " ", fmt$direction),
      tags$p(
        tags$strong("What this number means."),
        " This is the binomial Bayes factor integrated under a uniform ",
        "prior on the working-theory probability theta -- a prior that ",
        "gives no a priori weight to theta above the cutpoint. The ",
        "reported value is conservative in that sense; the Sensitivity ",
        "tab's M_star reports how far the prior can be tilted toward ",
        "the rival before the BF drops below threshold."
      )
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
        tags$p(tags$strong("Direction:"), " ", fmt$direction),
        tags$p(
          tags$strong("What this number means."),
          " This is the smallest Bayes factor the rival can argue for ",
          "within the family of urn compositions the paper's ",
          "conditioning assumption admits: rival urn (y_W, y_W + 1) ",
          "paired with working-theory urn (y_W + 1, max(1, y_R)). No ",
          "admitted rival composition makes the data more probable ",
          "for the rival, so a reported BF of 20 means at least 20 ",
          "within that family. The bound is not global; specifications ",
          "outside the conditioning assumption are not covered."
        )
      )
    }
  })

  # Sensitivity-tab prose. interpret_omega_star() and interpret_M_star()
  # produce the per-branch sentences; this output composes them into
  # the two sections the panel shows.
  output$tipping_text <- renderUI({
    sb <- sens_b()
    su <- sens_u()
    th <- input$threshold

    binom_om_prose <- interpret_omega_star(sb$omega_star, threshold = th)
    urn_om_prose <- if (is.na(su$bf)) {
      paste0(
        "The urn model is undefined at these counts; no observation-",
        "bias sensitivity is reported. Use the binomial entry above ",
        "or revisit the counts."
      )
    } else {
      interpret_omega_star(su$omega_star, threshold = th)
    }
    M_prose <- interpret_M_star(sb$M_star, threshold = th)

    code_b_prose <- interpret_x_star(sens_code_b()$x_star, threshold = th)
    code_u_prose <- if (is.na(su$bf)) {
      paste0(
        "The urn model is undefined at these counts; no coding-error ",
        "sensitivity is reported."
      )
    } else {
      interpret_x_star(sens_code_u()$x_star, threshold = th)
    }

    tagList(
      tags$p(
        "The Result-tab Bayes factors are already conservative ",
        "readings: the urn's is a lower bound across the admitted ",
        "family of rival urn compositions, the binomial's is ",
        "integrated under a rival-neutral uniform prior. The tipping ",
        "points below ask how much further perturbation that ",
        "conservative reading can absorb before the BF drops below ",
        "threshold. Larger tipping points mean more room."
      ),
      tags$h4("Coding-error sensitivity"),
      tags$p(tags$strong("Binomial model:"), " ", code_b_prose),
      tags$p(tags$strong("Urn model:"), " ", code_u_prose),
      tags$h4("Observation-bias sensitivity"),
      tags$p(tags$strong("Binomial model:"), " ", binom_om_prose),
      tags$p(tags$strong("Urn model:"), " ", urn_om_prose),
      tags$h4("Prior sensitivity (binomial only)"),
      tags$p(M_prose)
    )
  })

  output$plot_omega <- plotly::renderPlotly({
    co <- counts_ok()
    sb <- sens_b()
    su <- sens_u()
    plot_bf_vs_omega(
      y_W = co$y_W, y_R = co$y_R,
      threshold = input$threshold,
      theta_cut = input$theta_cut,
      omega_star_b = sb$omega_star,
      omega_star_u = su$omega_star,
      urn_defined = !is.na(su$bf)
    )
  })

  output$plot_M <- plotly::renderPlotly({
    co <- counts_ok()
    sb <- sens_b()
    plot_bf_vs_M(
      y_W = co$y_W, y_R = co$y_R,
      threshold = input$threshold,
      theta_cut = input$theta_cut,
      M_max = 50L,
      M_star = sb$M_star
    )
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
          "an expanding archive, a growing set of cases. Implemented ",
          "in bf_binomial()."
        ),
        tags$li(
          tags$strong("Urn (hypergeometric):"),
          " bounded archive -- a closed historical record, a fixed ",
          "set of documents. Implemented in bf_urn(). Returns ",
          "'undefined' when the rival-favorable urn construction ",
          "cannot supply the observed sample size (y_R > y_W + 1)."
        )
      ),
      tags$p(
        "We recommend reading both tabs together. The paper argues ",
        "that when the design is ambiguous between open-ended and ",
        "bounded evidence, computing both Bayes factors is the ",
        "conservative move: the urn is more favorable to the working ",
        "theory by construction, and the binomial generalizes more ",
        "easily to other settings."
      ),

      tags$h4("Running example"),
      tags$p(
        "The default inputs (y_W = 9, y_R = 3, threshold = 20) ",
        "reproduce the running example from the paper. The binomial ",
        "returns BF ~ 20.7 -- just above threshold 20, in the K&R ",
        "'strong' bin -- while the urn returns BF = 323, far above ",
        "threshold and in the K&R 'very strong' bin. The binomial ",
        "clears the threshold by so little that the Sensitivity tab's ",
        "three checks all overturn it with a small push: re-coding one ",
        "of the nine pro-working-theory observations, a roughly 1% ",
        "observation bias, or a single rival-favoring pseudo-observation ",
        "in the prior. The urn is far more robust -- it takes two ",
        "re-codings or a roughly 143% observation bias to bring it below ",
        "threshold."
      ),

      tags$h4("Verdict scale"),
      tags$p(
        "Verdicts use the Kass & Raftery (1995, JASA) scale:"
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
      ),

      tags$h4("Sensitivity"),
      tags$p(
        "omega_star (observation-bias tipping point): the smallest ",
        "value of omega > 1 at which the Bayes factor first drops ",
        "below the chosen threshold. Larger omega_star means the ",
        "conclusion is more robust to pro-working-theory observation ",
        "bias."
      ),
      tags$p(
        "M_star (prior-sweep tipping point, binomial only): the ",
        "smallest integer M such that a Beta(1, M+1) rival-tilted ",
        "prior drops the Bayes factor below threshold. Larger ",
        "M_star means the conclusion survives stronger rival-tilted ",
        "priors."
      ),

      tags$h4("Sources"),
      tags$p(
        "Lopez, Bowers, and Gajardo Cooper (2026), ",
        tags$em("Fully specified Bayes factors for process tracing"),
        ". Source code and documentation: ",
        tags$a(
          href = "https://github.com/bowers-illinois-edu/DrWrinch",
          "github.com/bowers-illinois-edu/DrWrinch"
        ),
        "."
      )
    )
  })
}
