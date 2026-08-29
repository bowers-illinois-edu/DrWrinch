# server.R -- reactive graph for the one-model app.
#
# Two Bayes factors come from one model and share a numerator. The
# reactives are named for which rule they use on the rival's range of
# shares: bf_uw() averages over the whole range under uniform weights,
# bf_wc() takes her best single share, one half. Both call the package
# directly, so every number the app shows is the number the paper
# reports, not a re-derivation.

function(input, output, session) {

  # counts_ok() short-circuits with a validate() message when the
  # inputs are not two non-negative whole numbers. Everything reads its
  # counts from here, so the message appears once rather than in
  # diverging copies.
  counts_ok <- reactive({
    validate_counts(input$y_W, input$y_R)
    list(y_W = as.integer(input$y_W), y_R = as.integer(input$y_R))
  })

  bf_uw <- reactive({
    co <- counts_ok()
    DrWrinch::bf_uniform_weights(co$y_W, co$y_R)
  })

  bf_wc <- reactive({
    co <- counts_ok()
    DrWrinch::bf_worst_case(co$y_W, co$y_R)
  })

  # The separation the researcher reports beside the worst-case value.
  # separation_g() raises an error when the counts do not favor the
  # working theory, because then no separation reaches a threshold above
  # one. That is a real answer, not a failure, so we turn it into NA and
  # let interpret_separation() say it in words.
  sep_g <- reactive({
    co <- counts_ok()
    if (co$y_W <= co$y_R) {
      NA_real_
    } else {
      DrWrinch::separation_g(co$y_W, co$y_R, threshold = input$threshold)
    }
  })

  decomp <- reactive({
    co <- counts_ok()
    bf_decomposition(co$y_W, co$y_R)
  })

  sens_b <- reactive({
    co <- counts_ok()
    DrWrinch::sens_binomial(co$y_W, co$y_R, threshold = input$threshold)
  })

  sens_code_uw <- reactive({
    co <- counts_ok()
    DrWrinch::sens_coding(co$y_W, co$y_R, model = "uniform_weights",
                          threshold = input$threshold)
  })

  sens_code_wc <- reactive({
    co <- counts_ok()
    DrWrinch::sens_coding(co$y_W, co$y_R, model = "worst_case",
                          threshold = input$threshold)
  })

  output$result_uniform <- renderUI({
    fmt <- format_bf(bf_uw())
    tagList(
      tags$p(tags$strong("Bayes factor:"), " ", fmt$value),
      tags$p(tags$strong("Verdict (Kass and Raftery):"), " ", fmt$verdict),
      tags$p(tags$strong("Direction:"), " ", fmt$direction),
      tags$p(
        "The rival claims a share at or below one half, which is a range ",
        "rather than one share, so it gives no probability for the counts ",
        "on its own. This number holds her to every share in that range ",
        "equally, giving each the same weight. Shares near zero make the ",
        "observed counts very improbable, and averaging over them is part ",
        "of what lifts the number."
      )
    )
  })

  output$result_worst_case <- renderUI({
    fmt <- format_bf(bf_wc())
    tagList(
      tags$p(tags$strong("Bayes factor:"), " ", fmt$value),
      tags$p(tags$strong("Verdict (Kass and Raftery):"), " ", fmt$verdict),
      tags$p(tags$strong("Direction:"), " ", fmt$direction),
      tags$p(
        "This number grants the rival the one share in her range that ",
        "makes the observed counts most probable, an even split. No ",
        "weighting of her range that you could have stated before coding ",
        "would make the evidence against her look weaker, so the value is ",
        "a lower bound. It is also the value that carries an error rate: ",
        "treat ", input$threshold, " as the point where you set the rival ",
        "aside and, in a world where she is right, you are misled at most ",
        "one time in twenty."
      ),
      tags$p(tags$strong("Separation:"), " ",
             interpret_separation(sep_g(), threshold = input$threshold))
    )
  })

  output$decomposition_text <- renderUI({
    co <- counts_ok()
    n <- co$y_W + co$y_R
    tags$p(
      "Three probabilities, at each count of ", n, " observations you ",
      "might have reported. The lightest bar is the probability of the ",
      "count averaged over the shares above one half, which both Bayes ",
      "factors use as their numerator. The middle bar averages over the ",
      "shares at or below one half; dividing the first by it gives the ",
      "left-hand number above. The solid bar is the probability at a ",
      "share of exactly one half; dividing the first by it gives the ",
      "right-hand number. The two Bayes factors differ only in which of ",
      "these two bars they divide by."
    )
  })

  output$plot_decomposition <- plotly::renderPlotly({
    co <- counts_ok()
    plot_bf_decomposition(co$y_W, co$y_R)
  })

  output$tipping_text <- renderUI({
    sb <- sens_b()
    th <- input$threshold
    recoding <- sens_code_wc()$recoding

    # The worst-case column answers re-coding with separations rather
    # than a tipping point, because at counts like nine against three
    # the value was never above the threshold and re-coding cannot
    # overturn a conclusion nobody drew.
    rows <- lapply(seq_len(nrow(recoding)), function(i) {
      g <- recoding$g_star[i]
      tags$tr(
        tags$td(recoding$x[i]),
        tags$td(paste0(recoding$y_W[i], " to ", recoding$y_R[i])),
        tags$td(formatC(signif(recoding$bf[i], 3), format = "g")),
        tags$td(if (is.na(g)) "--" else format(g, nsmall = 3))
      )
    })

    tagList(
      tags$p(
        "Three questions a reader can press you on: how you coded the ",
        "evidence, how evenly your search surfaced it, and how much ",
        "weight you gave the rival before you started. Each answer below ",
        "is the value at which what you report would change."
      ),

      tags$h4("Re-coding, and the uniform-weights Bayes factor"),
      tags$p(interpret_x_star(sens_code_uw()$x_star, threshold = th)),

      tags$h4("Re-coding, and the worst-case Bayes factor"),
      tags$p(
        "Re-coding cannot overturn a conclusion you did not draw. What ",
        "it moves is the separation you report: each re-coding narrows ",
        "the margin between the counts by two, so the two theories have ",
        "to claim shares further apart before the counts reach ", th, "."
      ),
      tags$table(
        class = "table table-sm",
        tags$thead(tags$tr(
          tags$th("Re-codings"), tags$th("Counts"),
          tags$th("Worst-case Bayes factor"), tags$th("Separation")
        )),
        tags$tbody(rows)
      ),

      tags$h4("Search bias"),
      tags$p(interpret_omega_star(sb$omega_star, threshold = th)),

      tags$h4("Background cases favoring the rival"),
      tags$p(interpret_M_star(sb$M_star, threshold = th)),
      tags$p(
        class = "text-muted small",
        "A Beta(1, M + 1) prior on the whole interval from zero to one ",
        "says how much weight each theory gets as well as how weight is ",
        "spread inside each theory's range. The Bayes factor cancels the ",
        "first and rises as M grows; the posterior odds keep it and fall. ",
        "The tipping point above is in the posterior odds."
      )
    )
  })

  output$plot_omega <- plotly::renderPlotly({
    co <- counts_ok()
    plot_bf_vs_omega(
      y_W = co$y_W, y_R = co$y_R,
      threshold = input$threshold,
      omega_star = sens_b()$omega_star
    )
  })

  output$plot_M <- plotly::renderPlotly({
    co <- counts_ok()
    plot_post_odds_vs_M(
      y_W = co$y_W, y_R = co$y_R,
      threshold = input$threshold,
      M_max = 50L,
      M_star = sens_b()$M_star
    )
  })

  output$about_panel <- renderUI({
    tagList(
      tags$h4("One model, two Bayes factors"),
      tags$p(
        "You have coded your evidence into two counts: observations ",
        "supporting your working theory and observations supporting a ",
        "single rival. The model behind both numbers is one sentence: ",
        "each observation supports the working theory with probability ",
        "theta, the share of the evidence that supports it. Your working ",
        "theory claims that share is above one half; the rival claims it ",
        "is at or below one half."
      ),
      tags$p(
        "The rival's claim is a range of shares, not one share, so it ",
        "does not by itself give a probability for your counts. Turning ",
        "the range into one number takes a rule, and there are two that ",
        "no reader can call arbitrary or self-serving:"
      ),
      tags$ul(
        tags$li(
          "Average the probability of the counts over her whole range, ",
          "giving every share the same weight. This is ",
          "bf_uniform_weights()."
        ),
        tags$li(
          "Evaluate her claim at the single share that makes your counts ",
          "most probable, an even split. This is bf_worst_case()."
        )
      ),
      tags$p(
        "Both share a numerator: the probability of the counts averaged ",
        "over the shares above one half. So the two differ only in the ",
        "denominator, and the Result tab's picture shows all three ",
        "quantities at once."
      ),

      tags$h4("Running example"),
      tags$p(
        "The default counts, nine supporting the working theory and ",
        "three supporting the rival, are the paper's running example. ",
        "Averaging over the rival's range gives 20.67, just above a ",
        "threshold of 20. Granting her an even split gives 2.73, which ",
        "was never above it. The gap between the two is what averaging ",
        "over shares near zero buys, and the Sensitivity tab says how ",
        "little else the 20.67 can absorb: one re-coded observation, a ",
        "one percent search bias, or one background case favoring the ",
        "rival each take it below 20."
      ),
      tags$p(
        "The smaller number is the one that carries a guarantee. In a ",
        "world where the rival's claim holds, a researcher who sets her ",
        "aside at 20 under the worst-case Bayes factor is misled at most ",
        "one time in twenty, whether the evidence was drawn ",
        "independently or without replacement from a body of evidence of ",
        "any size. She never has to say how large that body is."
      ),

      tags$h4("Verdict scale"),
      tags$p("Verdicts use the Kass and Raftery (1995, JASA) scale:"),
      tags$ul(
        tags$li("above 1 up to 3: not worth more than a bare mention"),
        tags$li("above 3 up to 20: positive"),
        tags$li("above 20 up to 150: strong"),
        tags$li("above 150: very strong")
      ),
      tags$p(
        "Below 1 the same bins apply to the reciprocal and the direction ",
        "flips to the rival. Exactly 1 is equipoise and reads 'neither'."
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
