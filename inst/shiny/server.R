# server.R -- reactive graph for the one-model app.
#
# Two Bayes factors come from one model and share a numerator. The
# reactives are named for which rule they use on the rival's range of
# shares: bf_uw() averages over the whole range under uniform weights,
# bf_wc() takes the rival's most favorable share, one half when the
# counts favor the working theory. The paper's rule sets the rival aside,
# at least provisionally, when the first is at least threshold_uniform
# (20) and the second is above threshold_worst (1). Every reactive calls
# the package directly, so every number the app shows is the number the
# paper reports, not a re-derivation.

function(input, output, session) {

  # counts_ok() short-circuits with a validate() message when the
  # inputs are not two non-negative whole numbers. Everything reads its
  # counts from here, so the message appears once rather than in
  # diverging copies.
  counts_ok <- reactive({
    validate_counts(input$y_W, input$y_R)
    list(y_W = as.integer(input$y_W), y_R = as.integer(input$y_R))
  })

  # Both thresholds must be positive numbers before anything that uses
  # them runs; a blank box would otherwise reach the package as NA.
  thresholds <- reactive({
    shiny::validate(
      shiny::need(is.numeric(input$threshold_uniform) &&
                    isTRUE(input$threshold_uniform > 0),
                  "Enter a positive threshold for the uniform-weights Bayes factor."),
      shiny::need(is.numeric(input$threshold_worst) &&
                    isTRUE(input$threshold_worst > 0),
                  "Enter a positive threshold for the worst-case Bayes factor.")
    )
    list(uniform = input$threshold_uniform, worst = input$threshold_worst)
  })

  bf_uw <- reactive({
    co <- counts_ok()
    DrWrinch::bf_uniform_weights(co$y_W, co$y_R)
  })

  bf_wc <- reactive({
    co <- counts_ok()
    DrWrinch::bf_worst_case(co$y_W, co$y_R)
  })

  decomp <- reactive({
    co <- counts_ok()
    bf_decomposition(co$y_W, co$y_R)
  })

  sens_b <- reactive({
    co <- counts_ok()
    th <- thresholds()
    DrWrinch::sens_bias(co$y_W, co$y_R,
                        threshold_uniform = th$uniform,
                        threshold_worst = th$worst)
  })

  sens_code <- reactive({
    co <- counts_ok()
    th <- thresholds()
    DrWrinch::sens_coding(co$y_W, co$y_R,
                          threshold_uniform = th$uniform,
                          threshold_worst = th$worst)
  })

  output$rule_text <- renderUI({
    th <- thresholds()
    tags$p(interpret_rule(bf_uw(), bf_wc(),
                          threshold_uniform = th$uniform,
                          threshold_worst = th$worst))
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
        "on its own. This number gives every share in that range the same ",
        "weight. Shares near zero make the observed counts very ",
        "improbable, and averaging over them is part of what lifts the ",
        "number."
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
        "This number evaluates the rival at the share in its range that ",
        "makes the observed counts most probable, an even split whenever ",
        "the counts favor the working theory. No weights on the rival's ",
        "shares give a smaller Bayes factor, so a value above 1 means no ",
        "such weights make the counts more probable under the rival than ",
        "under the working theory."
      )
    )
  })

  output$decomposition_text <- renderUI({
    co <- counts_ok()
    n <- co$y_W + co$y_R
    tags$p(
      "Three probabilities, at each count of ", n, " observations that ",
      "might have been reported. The lightest bar is the probability of ",
      "the count averaged over the shares above one half, which both ",
      "Bayes factors use as their numerator. The middle bar averages over ",
      "the shares at or below one half; dividing the first by it gives ",
      "the left-hand number above. The solid bar is the probability at a ",
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
    th <- thresholds()
    tagList(
      tags$p(
        "A reader can press on how the evidence was coded and on how ",
        "evenly the search found it. Each answer below is how far that ",
        "concern would have to go before a researcher following the rule ",
        "would no longer set the rival aside."
      ),
      tags$h4("Coding"),
      tags$p(interpret_coding(sens_code(), threshold_uniform = th$uniform,
                              threshold_worst = th$worst)),
      tags$h4("Search bias"),
      tags$p(interpret_bias(sens_b(), threshold_uniform = th$uniform,
                            threshold_worst = th$worst)),
      tags$p(
        class = "text-muted small",
        "The picture shows both Bayes factors as the assumed bias grows, ",
        "each with its own threshold. The dotted line marks the bias at ",
        "which the rule stops setting the rival aside."
      )
    )
  })

  output$plot_omega <- plotly::renderPlotly({
    co <- counts_ok()
    th <- thresholds()
    plot_bf_vs_omega(
      y_W = co$y_W, y_R = co$y_R,
      threshold_uniform = th$uniform,
      threshold_worst = th$worst,
      omega_star = sens_b()$omega_star
    )
  })

  output$about_panel <- renderUI({
    tagList(
      tags$h4("One model, two Bayes factors"),
      tags$p(
        "The evidence is coded into two counts: observations supporting ",
        "a working theory and observations supporting a single rival. The ",
        "model behind both numbers is one sentence: each observation ",
        "supports the working theory with probability theta, the share of ",
        "the evidence that supports it. The working theory claims that ",
        "share is above one half; the rival claims it is at or below one ",
        "half."
      ),
      tags$p(
        "Each claim is a range of shares, not one share, so neither gives ",
        "a probability for the counts on its own. Both Bayes factors ",
        "average over the working theory's shares with equal weights. ",
        "They differ in the rival:"
      ),
      tags$ul(
        tags$li(
          "bf_uniform_weights() averages over the rival's whole range ",
          "with the same equal weights."
        ),
        tags$li(
          "bf_worst_case() evaluates the rival at the share that makes the ",
          "counts most probable, which gives the smallest Bayes factor any ",
          "weights on the rival's shares can give."
        )
      ),

      tags$h4("The rule"),
      tags$p(
        "The paper's rule sets the rival aside, at least provisionally, ",
        "when the uniform-weights Bayes factor is 20 or more and the ",
        "worst-case Bayes factor is above 1. With even prior odds, a Bayes ",
        "factor of 20 puts the posterior probability of the rival at no ",
        "more than 1/21. A worst-case value above 1 means no weights on ",
        "the rival's shares make the counts more probable under the rival."
      ),

      tags$h4("Running example"),
      tags$p(
        "The default counts, nine supporting the working theory and three ",
        "supporting the rival, are the paper's running example. The ",
        "uniform-weights Bayes factor is 20.67 and the worst-case Bayes ",
        "factor is 2.73, so the rule sets the rival aside. The Sensitivity ",
        "tab says how little that decision can absorb: one re-coded ",
        "observation, or a search about one percent more likely to find ",
        "pro-working-theory evidence, would change it."
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
