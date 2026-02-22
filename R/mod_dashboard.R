#' Dashboard UI
#' @param id module id
#' @noRd
mod_dashboard_ui <- function(id) {
  ns <- shiny::NS(id)
  shiny::tagList(
    shiny::div(class = "section-title", "🔥 Florence's Fitness Hub"),
    shiny::div(class = "section-subtitle", shiny::textOutput(ns("today_date"))),

    # Motivational banner
    shiny::div(
      class = "motivation-banner",
      shiny::div(class = "quote-text", shiny::textOutput(ns("quote_text"))),
      shiny::div(class = "quote-author", shiny::textOutput(ns("quote_author")))
    ),

    # Top stat cards row
    shiny::fluidRow(
      shiny::column(3,
        shiny::div(class = "stat-card",
          shiny::span(class = "stat-icon", "🏋️‍♀️"),
          shiny::div(class = "stat-value", shiny::textOutput(ns("total_sessions"))),
          shiny::div(class = "stat-label", "Total Sessions")
        )
      ),
      shiny::column(3,
        shiny::div(class = "stat-card",
          shiny::span(class = "stat-icon", "🔥"),
          shiny::div(class = "stat-value", shiny::textOutput(ns("streak"))),
          shiny::div(class = "stat-label", "Day Streak")
        )
      ),
      shiny::column(3,
        shiny::div(class = "stat-card",
          shiny::span(class = "stat-icon", "🏃‍♀️"),
          shiny::div(class = "stat-value", shiny::textOutput(ns("this_week"))),
          shiny::div(class = "stat-label", "This Week")
        )
      ),
      shiny::column(3,
        shiny::div(class = "stat-card",
          shiny::span(class = "stat-icon", "🎯"),
          shiny::div(class = "stat-value", shiny::textOutput(ns("goals_done"))),
          shiny::div(class = "stat-label", "Goals Achieved")
        )
      )
    ),

    shiny::br(),

    shiny::fluidRow(
      # Recent workouts
      shiny::column(7,
        shiny::div(class = "panel-card",
          shiny::h5("⏱ Recent Workouts"),
          DT::DTOutput(ns("recent_table"))
        )
      ),
      # Weekly calendar / heatmap
      shiny::column(5,
        shiny::div(class = "panel-card",
          shiny::h5("📅 Last 4 Weeks"),
          plotly::plotlyOutput(ns("heatmap"), height = "220px")
        ),
        shiny::div(class = "panel-card", style = "margin-top:0;",
          shiny::h5("🏆 Achievements"),
          shiny::uiOutput(ns("badges"))
        )
      )
    )
  )
}

#' Dashboard Server
#' @param id module id
#' @param workouts reactive — data frame of workouts
#' @param goals    reactive — data frame of goals
#' @noRd
mod_dashboard_server <- function(id, workouts, goals) {
  shiny::moduleServer(id, function(input, output, session) {

    output$today_date <- shiny::renderText({
      format(Sys.Date(), "%A, %d %B %Y")
    })

    # Quote
    q <- todays_quote()
    output$quote_text   <- shiny::renderText(q$text)
    output$quote_author <- shiny::renderText(paste0("\u2014 ", q$author))

    # Stats
    output$total_sessions <- shiny::renderText({
      nrow(workouts())
    })

    output$streak <- shiny::renderText({
      compute_streak(workouts())
    })

    output$this_week <- shiny::renderText({
      df <- workouts()
      if (nrow(df) == 0) return("0")
      sum(as.Date(df$date) >= (Sys.Date() - 6))
    })

    output$goals_done <- shiny::renderText({
      df <- goals()
      if (nrow(df) == 0) return("0")
      sum(df$achieved, na.rm = TRUE)
    })

    # Recent workouts table
    output$recent_table <- DT::renderDT({
      df <- workouts()
      if (nrow(df) == 0) {
        return(data.frame(
          Date = character(), Type = character(),
          Exercise = character(), Detail = character()
        ))
      }
      df <- df[order(as.Date(df$date), decreasing = TRUE), ]
      df <- utils::head(df, 8)
      detail <- ifelse(
        df$type == "strength",
        paste0(df$sets, "x", df$reps, " @ ", df$weight_kg, " kg"),
        paste0(df$duration_min, " min", ifelse(!is.na(df$distance_km) & df$distance_km > 0,
                                               paste0(" / ", df$distance_km, " km"), ""))
      )
      display <- data.frame(
        Date     = format(as.Date(df$date), "%d %b %Y"),
        Type     = df$type,
        Exercise = df$exercise,
        Detail   = detail,
        stringsAsFactors = FALSE
      )
      DT::datatable(
        display,
        options = list(dom = "t", pageLength = 8, ordering = FALSE),
        rownames = FALSE,
        selection = "none"
      )
    })

    # Heatmap — last 28 days
    output$heatmap <- plotly::renderPlotly({
      df <- workouts()
      today <- Sys.Date()
      days  <- seq(today - 27, today, by = "day")
      counts <- data.frame(date = days, n = 0L)
      if (nrow(df) > 0) {
        agg <- as.data.frame(table(as.Date(df$date)))
        names(agg) <- c("date", "n")
        agg$date <- as.Date(agg$date)
        counts$n <- vapply(counts$date, function(d) {
          idx <- which(agg$date == d)
          if (length(idx) == 0) 0L else as.integer(agg$n[idx])
        }, integer(1))
      }
      counts$week  <- as.integer(format(counts$date, "%U"))
      counts$dow   <- factor(weekdays(counts$date, abbreviate = TRUE),
                             levels = c("Mon","Tue","Wed","Thu","Fri","Sat","Sun"))
      # normalize week to 0-3
      counts$week_rel <- counts$week - min(counts$week)

      plotly::plot_ly(
        counts,
        x = ~week_rel,
        y = ~dow,
        z = ~n,
        type = "heatmap",
        colorscale = list(
          c(0, "#1a1a2e"),
          c(0.5, "#0f3460"),
          c(1, "#e94560")
        ),
        showscale = FALSE,
        hovertemplate = "%{y} W+%{x}: %{z} session(s)<extra></extra>"
      ) |>
        plotly::layout(
          paper_bgcolor = "rgba(0,0,0,0)",
          plot_bgcolor  = "rgba(0,0,0,0)",
          xaxis = list(
            showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE,
            title = "Week"
          ),
          yaxis = list(
            showgrid = FALSE, zeroline = FALSE,
            tickfont = list(color = "#8a8a9a", size = 11),
            title = ""
          ),
          margin = list(l = 40, r = 10, t = 10, b = 10),
          font = list(color = "#e8e8e8")
        )
    })

    # Badges
    output$badges <- shiny::renderUI({
      df <- workouts()
      streak <- compute_streak(df)
      total  <- nrow(df)
      wk     <- if (nrow(df) > 0) sum(as.Date(df$date) >= (Sys.Date() - 6)) else 0

      badges <- list()

      if (total >= 1)
        badges <- c(badges, list(shiny::span(class = "badge-pill badge-strength me-1 mb-1", "💪 First Workout!")))
      if (total >= 10)
        badges <- c(badges, list(shiny::span(class = "badge-pill badge-strength me-1 mb-1", "🔥 10 Sessions")))
      if (total >= 25)
        badges <- c(badges, list(shiny::span(class = "badge-pill badge-strength me-1 mb-1", "⭐ 25 Sessions")))
      if (total >= 50)
        badges <- c(badges, list(shiny::span(class = "badge-pill badge-strength me-1 mb-1", "🏆 50 Sessions")))
      if (streak >= 3)
        badges <- c(badges, list(shiny::span(class = "badge-pill badge-cardio me-1 mb-1", "🔥 3-Day Streak")))
      if (streak >= 7)
        badges <- c(badges, list(shiny::span(class = "badge-pill badge-cardio me-1 mb-1", "🔥🔥 7-Day Streak")))
      if (streak >= 14)
        badges <- c(badges, list(shiny::span(class = "badge-pill badge-body me-1 mb-1", "🌟 2-Week Streak")))
      if (wk >= 5)
        badges <- c(badges, list(shiny::span(class = "badge-pill badge-body me-1 mb-1", "💥 5x This Week")))

      if (length(badges) == 0) {
        shiny::p(style = "color:#8a8a9a;font-size:0.88rem;",
                 "Log your first workout to unlock badges! 🎖")
      } else {
        shiny::div(badges)
      }
    })
  })
}
