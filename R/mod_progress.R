#' Progress Charts UI
#' @param id module id
#' @noRd
mod_progress_ui <- function(id) {
  ns <- shiny::NS(id)
  shiny::tagList(
    shiny::div(class = "section-title", "Progress"),
    shiny::div(class = "section-subtitle", "Track how far you've come"),

    shiny::tabsetPanel(
      type = "pills",
      id   = ns("progress_tabs"),

      # Strength tab
      shiny::tabPanel(
        title = "Strength",
        shiny::br(),
        shiny::div(class = "row g-3",
          shiny::div(class = "col-12 col-md-4",
            shiny::div(class = "panel-card",
              shiny::h5("Exercise"),
              shiny::selectInput(ns("strength_exercise"), NULL,
                                 choices = c("(log a workout first)"),
                                 width = "100%"),
              shiny::selectInput(ns("strength_metric"), "Show",
                                 choices = c("Max Weight (kg)" = "max_weight",
                                             "Total Volume (sets x reps x kg)" = "total_volume",
                                             "Max Reps" = "max_reps"),
                                 selected = "max_weight",
                                 width = "100%"),
              shiny::br(),
              shiny::uiOutput(ns("strength_pr_box"))
            )
          ),
          shiny::div(class = "col-12 col-md-8",
            shiny::div(class = "panel-card",
              shiny::h5("Progress Over Time"),
              plotly::plotlyOutput(ns("strength_chart"), height = "320px")
            )
          )
        ),
        shiny::div(class = "row g-3",
          shiny::div(class = "col-12",
            shiny::div(class = "panel-card",
              shiny::h5("Personal Records"),
              DT::DTOutput(ns("pr_table"))
            )
          )
        )
      ),

      # Cardio tab
      shiny::tabPanel(
        title = "Cardio",
        shiny::br(),
        shiny::div(class = "row g-3",
          shiny::div(class = "col-12 col-md-4",
            shiny::div(class = "panel-card",
              shiny::h5("Activity"),
              shiny::selectInput(ns("cardio_exercise"), NULL,
                                 choices = c("(log a workout first)"),
                                 width = "100%"),
              shiny::selectInput(ns("cardio_metric"), "Show",
                                 choices = c("Duration (min)"     = "duration",
                                             "Distance (km)"      = "distance",
                                             "Pace (min/km)"      = "pace"),
                                 selected = "duration",
                                 width = "100%"),
              shiny::br(),
              shiny::uiOutput(ns("cardio_stat_box"))
            )
          ),
          shiny::div(class = "col-12 col-md-8",
            shiny::div(class = "panel-card",
              shiny::h5("Progress Over Time"),
              plotly::plotlyOutput(ns("cardio_chart"), height = "320px")
            )
          )
        )
      ),

      # Body composition tab
      shiny::tabPanel(
        title = "Body",
        shiny::br(),
        shiny::div(class = "row g-3",
          shiny::div(class = "col-12 col-md-4",
            shiny::div(class = "panel-card",
              shiny::h5("Log Measurement"),
              shiny::dateInput(ns("body_date"), "Date", value = Sys.Date(),
                               format = "dd/mm/yyyy"),
              shiny::numericInput(ns("body_weight"), "Weight (kg)", value = 60,
                                  min = 30, max = 250, step = 0.1),
              shiny::numericInput(ns("body_fat"), "Body Fat % (optional)",
                                  value = NA, min = 0, max = 60, step = 0.1),
              shiny::textInput(ns("body_notes"), "Notes", placeholder = "Optional"),
              shiny::br(),
                shiny::actionButton(ns("add_body_btn"), "Log Measurement",
                                  class = "btn btn-primary w-100"),
              shiny::br(), shiny::br(),
              shiny::uiOutput(ns("body_stat_box"))
            )
          ),
          shiny::div(class = "col-12 col-md-8",
            shiny::div(class = "panel-card",
              shiny::h5("Weight & Body Fat Over Time"),
              plotly::plotlyOutput(ns("body_chart"), height = "340px")
            )
          )
        ),
        shiny::div(class = "row g-3",
          shiny::div(class = "col-12",
            shiny::div(class = "panel-card",
              shiny::h5("History"),
              DT::DTOutput(ns("body_table"))
            )
          )
        )
      ),

      # Volume / frequency tab
      shiny::tabPanel(
        title = "Overview",
        shiny::br(),
        shiny::div(class = "row g-3",
          shiny::div(class = "col-12 col-md-6",
            shiny::div(class = "panel-card",
              shiny::h5("Sessions per Week"),
              plotly::plotlyOutput(ns("freq_chart"), height = "260px")
            )
          ),
          shiny::div(class = "col-12 col-md-6",
            shiny::div(class = "panel-card",
              shiny::h5("Exercise Distribution"),
              plotly::plotlyOutput(ns("dist_chart"), height = "260px")
            )
          )
        )
      )
    )
  )
}

#' Progress Charts Server
#' @noRd
mod_progress_server <- function(id, workouts_rv, bodycomp_rv) {
  shiny::moduleServer(id, function(input, output, session) {

    # Strength

    strength_data <- shiny::reactive({
      df <- workouts_rv()
      df[df$type == "strength" & !is.na(df$weight_kg), ]
    })

    shiny::observe({
      df <- strength_data()
      exercises <- if (nrow(df) == 0) c("(log a workout first)") else sort(unique(df$exercise))
      shiny::updateSelectInput(session, "strength_exercise", choices = exercises)
    })

    output$strength_chart <- plotly::renderPlotly({
      df <- strength_data()
      shiny::req(nrow(df) > 0, input$strength_exercise != "(log a workout first)")
      df <- df[df$exercise == input$strength_exercise, ]
      df$date <- as.Date(df$date)

      y_col <- switch(input$strength_metric,
        max_weight   = tapply(df$weight_kg, df$date, max),
        total_volume = tapply(df$sets * df$reps * df$weight_kg, df$date, sum),
        max_reps     = tapply(df$reps, df$date, max)
      )
      dates <- as.Date(names(y_col))

      y_label <- switch(input$strength_metric,
        max_weight   = "Max Weight (kg)",
        total_volume = "Total Volume (kg)",
        max_reps     = "Max Reps"
      )

      plotly::plot_ly(
        x = dates, y = as.numeric(y_col),
        type = "scatter", mode = "lines+markers",
        line    = list(color = "#e94560", width = 2.5),
        marker  = list(color = "#e94560", size = 8,
                       line = list(color = "#fff", width = 1.5)),
        hovertemplate = paste0("%{x|%d %b %Y}<br>", y_label, ": %{y}<extra></extra>")
      ) |>
        plotly::layout(
          paper_bgcolor = "rgba(0,0,0,0)",
          plot_bgcolor  = "rgba(0,0,0,0)",
          xaxis = list(title = "", showgrid = FALSE,
                       tickfont = list(color = "#8a8a9a"),
                       linecolor = "#2a2a4a"),
          yaxis = list(title = y_label, showgrid = TRUE,
                       gridcolor = "#2a2a4a",
                       tickfont = list(color = "#8a8a9a"),
                       titlefont = list(color = "#8a8a9a")),
          font   = list(color = "#e8e8e8"),
          margin = list(l = 50, r = 20, t = 10, b = 40)
        )
    })

    output$strength_pr_box <- shiny::renderUI({
      df <- strength_data()
      if (nrow(df) == 0 || input$strength_exercise == "(log a workout first)") return(NULL)
      df <- df[df$exercise == input$strength_exercise, ]
      pr <- max(df$weight_kg, na.rm = TRUE)
      first_date <- min(as.Date(df$date))
      n_sessions <- length(unique(as.Date(df$date)))
        shiny::div(
          shiny::div(class = "stat-card",
          shiny::span(class = "stat-icon", shiny::tags$i(class = "bi bi-trophy-fill")),
          shiny::div(class = "stat-value", paste0(pr, " kg")),
          shiny::div(class = "stat-label", "Personal Record"),
          shiny::br(),
          shiny::tags$small(style = "color:#8a8a9a;",
            paste0("Since ", format(first_date, "%d %b %Y"),
                   " | ", n_sessions, " sessions"))
        )
      )
    })

    output$pr_table <- DT::renderDT({
      df <- strength_data()
      if (nrow(df) == 0) return(data.frame(Exercise = character(), PR_kg = character(),
                                            MaxReps = character(), Sessions = character()))
      prs <- dplyr::group_by(df, exercise) |>
        dplyr::summarise(
          PR_kg    = max(weight_kg, na.rm = TRUE),
          Max_Reps = max(reps, na.rm = TRUE),
          Sessions = dplyr::n_distinct(date),
          .groups  = "drop"
        ) |>
        dplyr::arrange(dplyr::desc(PR_kg))
      names(prs) <- c("Exercise", "PR (kg)", "Max Reps", "Sessions")
      DT::datatable(prs, options = list(dom = "ft", pageLength = 15, ordering = TRUE),
                    rownames = FALSE, selection = "none")
    })

    # Cardio

    cardio_data <- shiny::reactive({
      df <- workouts_rv()
      df[df$type == "cardio", ]
    })

    shiny::observe({
      df <- cardio_data()
      exercises <- if (nrow(df) == 0) c("(log a workout first)") else sort(unique(df$exercise))
      shiny::updateSelectInput(session, "cardio_exercise", choices = exercises)
    })

    output$cardio_chart <- plotly::renderPlotly({
      df <- cardio_data()
      shiny::req(nrow(df) > 0, input$cardio_exercise != "(log a workout first)")
      df <- df[df$exercise == input$cardio_exercise, ]
      df$date <- as.Date(df$date)

      if (input$cardio_metric == "duration") {
        y_vals  <- tapply(df$duration_min, df$date, sum, na.rm = TRUE)
        y_label <- "Duration (min)"
      } else if (input$cardio_metric == "distance") {
        df2    <- df[!is.na(df$distance_km) & df$distance_km > 0, ]
        if (nrow(df2) == 0) {
          y_vals  <- tapply(df$duration_min, df$date, sum, na.rm = TRUE)
          y_label <- "Duration (min)"
        } else {
          y_vals  <- tapply(df2$distance_km, df2$date, sum, na.rm = TRUE)
          y_label <- "Distance (km)"
        }
      } else {
        # pace = min/km
        df2 <- df[!is.na(df$distance_km) & df$distance_km > 0, ]
        if (nrow(df2) == 0) {
          y_vals  <- tapply(df$duration_min, df$date, sum, na.rm = TRUE)
          y_label <- "Duration (min)"
        } else {
          df2$pace <- df2$duration_min / df2$distance_km
          y_vals   <- tapply(df2$pace, df2$date, mean, na.rm = TRUE)
          y_label  <- "Pace (min/km)"
        }
      }

      dates <- as.Date(names(y_vals))

      plotly::plot_ly(
        x = dates, y = as.numeric(y_vals),
        type = "bar",
        marker = list(
          color = "rgba(0,212,170,0.7)",
          line  = list(color = "#00d4aa", width = 1)
        ),
        hovertemplate = paste0("%{x|%d %b %Y}<br>", y_label, ": %{y:.1f}<extra></extra>")
      ) |>
        plotly::layout(
          paper_bgcolor = "rgba(0,0,0,0)",
          plot_bgcolor  = "rgba(0,0,0,0)",
          xaxis = list(title = "", showgrid = FALSE, tickfont = list(color = "#8a8a9a")),
          yaxis = list(title = y_label, gridcolor = "#2a2a4a",
                       tickfont = list(color = "#8a8a9a"),
                       titlefont = list(color = "#8a8a9a")),
          font   = list(color = "#e8e8e8"),
          margin = list(l = 60, r = 20, t = 10, b = 40)
        )
    })

    output$cardio_stat_box <- shiny::renderUI({
      df <- cardio_data()
      if (nrow(df) == 0 || input$cardio_exercise == "(log a workout first)") return(NULL)
      df <- df[df$exercise == input$cardio_exercise, ]
      total_dur  <- sum(df$duration_min, na.rm = TRUE)
      total_dist <- sum(df$distance_km, na.rm = TRUE)
      n_sessions <- nrow(df)
      shiny::div(
        shiny::div(class = "stat-card",
          shiny::span(class = "stat-icon", shiny::tags$i(class = "bi bi-heart-pulse-fill")),
          shiny::div(class = "stat-value", paste0(round(total_dur), " min")),
          shiny::div(class = "stat-label", "Total Time"),
          if (total_dist > 0)
            shiny::div(style = "color:#00d4aa; font-size:0.9rem; margin-top:0.3rem;",
                       paste0(round(total_dist, 1), " km total"))
          else NULL,
          shiny::br(),
          shiny::tags$small(style = "color:#8a8a9a;", paste0(n_sessions, " sessions"))
        )
      )
    })

    # Body composition

    shiny::observeEvent(input$add_body_btn, {
      shiny::req(input$body_date, input$body_weight)
      new_row <- data.frame(
        id          = new_id(),
        date        = as.Date(input$body_date),
        weight_kg   = as.numeric(input$body_weight),
        bodyfat_pct = as.numeric(input$body_fat),
        notes       = input$body_notes,
        stringsAsFactors = FALSE
      )
      all_body <- rbind(bodycomp_rv(), new_row)
      bodycomp_rv(all_body)
      write_bodycomp(all_body)
      shiny::showNotification("Measurement saved.", type = "message", duration = 3)
    })

    output$body_chart <- plotly::renderPlotly({
      df <- bodycomp_rv()
      if (nrow(df) == 0) {
        return(
          plotly::plot_ly(type = "scatter", mode = "lines") |>
            plotly::layout(
              paper_bgcolor = "rgba(0,0,0,0)",
              plot_bgcolor  = "rgba(0,0,0,0)",
              annotations = list(list(
                text = "No measurements yet - log your first one!",
                showarrow = FALSE,
                font = list(color = "#8a8a9a", size = 14),
                xref = "paper", yref = "paper", x = 0.5, y = 0.5
              ))
            )
        )
      }
      df <- df[order(as.Date(df$date)), ]
      has_fat <- !all(is.na(df$bodyfat_pct))

      p <- plotly::plot_ly()
      p <- plotly::add_trace(p,
        x = as.Date(df$date), y = df$weight_kg,
        name = "Weight (kg)", type = "scatter", mode = "lines+markers",
        line   = list(color = "#e94560", width = 2.5),
        marker = list(color = "#e94560", size = 7,
                      line = list(color = "#fff", width = 1.5)),
        yaxis  = "y",
        hovertemplate = "%{x|%d %b %Y}<br>Weight: %{y} kg<extra></extra>"
      )
      if (has_fat) {
        df_fat <- df[!is.na(df$bodyfat_pct), ]
        p <- plotly::add_trace(p,
          x = as.Date(df_fat$date), y = df_fat$bodyfat_pct,
          name = "Body Fat (%)", type = "scatter", mode = "lines+markers",
          line   = list(color = "#f5a623", width = 2, dash = "dot"),
          marker = list(color = "#f5a623", size = 7),
          yaxis  = "y2",
          hovertemplate = "%{x|%d %b %Y}<br>Body Fat: %{y:.1f}%<extra></extra>"
        )
      }
      layout_args <- list(
        paper_bgcolor = "rgba(0,0,0,0)",
        plot_bgcolor  = "rgba(0,0,0,0)",
        legend = list(
          orientation = "h", x = 0, y = 1.1,
          font = list(color = "#e8e8e8")
        ),
        xaxis = list(title = "", showgrid = FALSE, tickfont = list(color = "#8a8a9a")),
        yaxis = list(title = "Weight (kg)", gridcolor = "#2a2a4a",
                     tickfont = list(color = "#8a8a9a"),
                     titlefont = list(color = "#8a8a9a")),
        font   = list(color = "#e8e8e8"),
        margin = list(l = 55, r = 55, t = 30, b = 40)
      )
      if (has_fat) {
        layout_args$yaxis2 <- list(
          title      = "Body Fat (%)",
          overlaying = "y",
          side       = "right",
          showgrid   = FALSE,
          tickfont   = list(color = "#f5a623"),
          titlefont  = list(color = "#f5a623")
        )
      }
      do.call(plotly::layout, c(list(p), layout_args))
    })

    output$body_stat_box <- shiny::renderUI({
      df <- bodycomp_rv()
      if (nrow(df) == 0) return(NULL)
      df   <- df[order(as.Date(df$date)), ]
      last <- df[nrow(df), ]
      first_weight <- df$weight_kg[1]
      diff <- round(last$weight_kg - first_weight, 1)
      diff_txt <- if (diff == 0) "no change" else if (diff > 0) paste0("+", diff, " kg") else paste0(diff, " kg")
      shiny::div(
        shiny::div(class = "stat-card",
          shiny::span(class = "stat-icon", shiny::tags$i(class = "bi bi-speedometer2")),
          shiny::div(class = "stat-value", paste0(last$weight_kg, " kg")),
          shiny::div(class = "stat-label", "Current Weight"),
          shiny::br(),
          shiny::tags$small(style = "color:#8a8a9a;", paste0("Since start: ", diff_txt))
        )
      )
    })

    output$body_table <- DT::renderDT({
      df <- bodycomp_rv()
      if (nrow(df) == 0) return(data.frame(Date = character(), Weight_kg = numeric(), BodyFat_pct = numeric()))
      df <- df[order(as.Date(df$date), decreasing = TRUE), ]
      display <- data.frame(
        Date        = format(as.Date(df$date), "%d %b %Y"),
        `Weight (kg)` = df$weight_kg,
        `Body Fat (%)` = ifelse(is.na(df$bodyfat_pct), "-", as.character(df$bodyfat_pct)),
        Notes       = ifelse(is.na(df$notes) | df$notes == "", "-", df$notes),
        stringsAsFactors = FALSE,
        check.names = FALSE
      )
      DT::datatable(display, options = list(dom = "ft", pageLength = 10),
                    rownames = FALSE, selection = "none")
    })

    # Frequency / overview

    output$freq_chart <- plotly::renderPlotly({
      df <- workouts_rv()
      if (nrow(df) == 0) {
        return(
          plotly::plot_ly(type = "bar") |>
            plotly::layout(
              paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(0,0,0,0)",
              annotations = list(list(
                text = "No data yet", showarrow = FALSE,
                font = list(color = "#8a8a9a", size = 14),
                xref = "paper", yref = "paper", x = 0.5, y = 0.5
              ))
            )
        )
      }
      df$week <- format(as.Date(df$date), "%Y-W%V")
      agg <- as.data.frame(table(week = df$week))
      agg <- agg[order(agg$week), ]
      plotly::plot_ly(
        agg, x = ~week, y = ~Freq, type = "bar",
        marker = list(
          color = "rgba(233,69,96,0.7)",
          line  = list(color = "#e94560", width = 1)
        ),
        hovertemplate = "%{x}<br>Sessions: %{y}<extra></extra>"
      ) |>
        plotly::layout(
          paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(0,0,0,0)",
          xaxis = list(title = "Week", showgrid = FALSE,
                       tickfont = list(color = "#8a8a9a", size = 10),
                       tickangle = -45),
          yaxis = list(title = "Sessions", gridcolor = "#2a2a4a",
                       tickfont = list(color = "#8a8a9a")),
          font   = list(color = "#e8e8e8"),
          margin = list(l = 50, r = 20, t = 10, b = 60)
        )
    })

    output$dist_chart <- plotly::renderPlotly({
      df <- workouts_rv()
      if (nrow(df) == 0) {
        return(
          plotly::plot_ly(type = "pie") |>
            plotly::layout(
              paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(0,0,0,0)",
              annotations = list(list(
                text = "No data yet", showarrow = FALSE,
                font = list(color = "#8a8a9a", size = 14),
                xref = "paper", yref = "paper", x = 0.5, y = 0.5
              ))
            )
        )
      }
      counts <- sort(table(df$exercise), decreasing = TRUE)
      top_n  <- utils::head(counts, 8)
      plotly::plot_ly(
        labels = names(top_n),
        values = as.numeric(top_n),
        type   = "pie",
        hole   = 0.45,
        marker = list(colors = c("#e94560","#0f3460","#f5a623","#00d4aa",
                                 "#7b2d8b","#2980b9","#e67e22","#1abc9c")),
        textfont = list(color = "#fff"),
        hovertemplate = "%{label}: %{value} sets<extra></extra>"
      ) |>
        plotly::layout(
          paper_bgcolor = "rgba(0,0,0,0)",
          legend = list(font = list(color = "#e8e8e8"), orientation = "v",
                        x = 1, y = 0.5),
          margin = list(l = 10, r = 120, t = 10, b = 10),
          font   = list(color = "#e8e8e8")
        )
    })
  })
}
