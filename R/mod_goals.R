#' Goals Module UI
#' @param id module id
#' @noRd
mod_goals_ui <- function(id) {
  ns <- shiny::NS(id)
  shiny::tagList(
    shiny::div(class = "section-title", "🎯 Goals"),
    shiny::div(class = "section-subtitle", "Set targets and smash them"),

    shiny::div(class = "row g-3",
      # ── Add goal form ──────────────────────────────────────────────────────
      shiny::div(class = "col-12 col-md-4",
        shiny::div(class = "panel-card",
          shiny::h5("New Goal"),

          shiny::textInput(ns("goal_name"), "Goal Name",
                           placeholder = "e.g. Deadlift 80kg"),
          shiny::selectInput(ns("goal_category"), "Category",
                             choices = c(
                               "Strength" = "strength",
                               "Cardio"   = "cardio",
                               "Body"     = "body",
                               "Consistency" = "consistency"
                             ),
                             selected = "strength"),
          shiny::div(class = "row g-2",
            shiny::div(class = "col-6",
              shiny::numericInput(ns("goal_target"), "Target",
                                  value = 100, min = 0, step = 0.1)
            ),
            shiny::div(class = "col-6",
              shiny::textInput(ns("goal_unit"), "Unit",
                               placeholder = "kg / km / %")
            )
          ),
          shiny::numericInput(ns("goal_current"), "Current value",
                              value = 0, min = 0, step = 0.1),
          shiny::dateInput(ns("goal_target_date"), "Target Date",
                           value  = Sys.Date() + 60,
                           format = "dd/mm/yyyy"),
          shiny::br(),
          shiny::actionButton(ns("add_goal"), "➕ Add Goal",
                              class = "btn btn-primary w-100")
        )
      ),

      # ── Active goals ───────────────────────────────────────────────────────
      shiny::div(class = "col-12 col-md-8",
        shiny::div(class = "panel-card",
          shiny::h5("Active Goals"),
          shiny::uiOutput(ns("goals_list"))
        ),
        shiny::div(class = "panel-card",
          shiny::h5("🏆 Achieved Goals"),
          shiny::uiOutput(ns("achieved_list"))
        )
      )
    ),

    # ── Update / edit a goal ──────────────────────────────────────────────
    shiny::div(class = "row g-3",
      shiny::div(class = "col-12",
        shiny::div(class = "panel-card",
          shiny::h5("✏\ufe0f Update Progress"),
          shiny::div(class = "row g-2 goals-update-row",
            shiny::div(class = "col-12 col-md-4",
              shiny::selectInput(ns("update_goal_id"), "Select Goal",
                                 choices = c("(no goals yet)"), width = "100%")
            ),
            shiny::div(class = "col-12 col-md-3",
              shiny::numericInput(ns("update_value"), "New Current Value",
                                  value = 0, min = 0, step = 0.1)
            ),
            shiny::div(class = "col-6 col-md-2 goals-btn-row",
              shiny::br(),
              shiny::actionButton(ns("update_goal"), "💾 Update",
                                  class = "btn btn-success")
            ),
            shiny::div(class = "col-6 col-md-3 goals-btn-row",
              shiny::br(),
              shiny::actionButton(ns("delete_goal"), "🗑 Delete Goal",
                                  class = "btn btn-outline-light")
            )
          )
        )
      )
    )
  )
}

#' Goals Server
#' @param id module id
#' @param goals_rv reactiveVal holding goals data frame
#' @param workouts reactive — used to auto-compute consistency
#' @noRd
mod_goals_server <- function(id, goals_rv, workouts) {
  shiny::moduleServer(id, function(input, output, session) {

    # Populate update selector
    shiny::observe({
      df <- goals_rv()
      active <- df[!df$achieved, ]
      if (nrow(active) == 0) {
        shiny::updateSelectInput(session, "update_goal_id",
                                 choices = c("(no active goals)"))
      } else {
        choices <- stats::setNames(active$id, active$name)
        shiny::updateSelectInput(session, "update_goal_id", choices = choices)
      }
    })

    # Add goal
    shiny::observeEvent(input$add_goal, {
      shiny::req(input$goal_name, input$goal_target)
      target  <- as.numeric(input$goal_target)
      current <- as.numeric(input$goal_current)
      new_goal <- data.frame(
        id          = new_id(),
        name        = input$goal_name,
        category    = input$goal_category,
        target      = target,
        unit        = input$goal_unit,
        current     = current,
        created_at  = Sys.Date(),
        target_date = as.Date(input$goal_target_date),
        achieved    = current >= target,
        stringsAsFactors = FALSE
      )
      df <- rbind(goals_rv(), new_goal)
      goals_rv(df)
      write_goals(df)
      shiny::showNotification(paste0("🎯 Goal added: ", input$goal_name),
                               type = "message", duration = 3)
    })

    # Update goal progress
    shiny::observeEvent(input$update_goal, {
      shiny::req(input$update_goal_id)
      df  <- goals_rv()
      idx <- which(df$id == input$update_goal_id)
      if (length(idx) == 0) return()
      df$current[idx]  <- as.numeric(input$update_value)
      df$achieved[idx] <- df$current[idx] >= df$target[idx]
      goals_rv(df)
      write_goals(df)
      if (df$achieved[idx]) {
        shiny::showNotification(
          paste0("🏆 GOAL ACHIEVED: ", df$name[idx], "! Amazing work Florence!"),
          type = "message", duration = 6
        )
      } else {
        pct <- round(100 * df$current[idx] / df$target[idx])
        shiny::showNotification(
          paste0("\u2705 Updated. ", pct, "% of the way there!"),
          type = "message", duration = 3
        )
      }
    })

    # Delete goal
    shiny::observeEvent(input$delete_goal, {
      shiny::req(input$update_goal_id)
      df  <- goals_rv()
      idx <- which(df$id == input$update_goal_id)
      if (length(idx) == 0) return()
      name <- df$name[idx]
      df <- df[-idx, ]
      goals_rv(df)
      write_goals(df)
      shiny::showNotification(paste0("Deleted goal: ", name), type = "warning", duration = 3)
    })

    # Render active goals
    output$goals_list <- shiny::renderUI({
      df <- goals_rv()
      active <- df[!df$achieved, ]
      if (nrow(active) == 0) {
        return(shiny::p(style = "color:#8a8a9a;font-size:0.88rem;",
                        "No active goals yet. Add one on the left! 🎯"))
      }
      items <- lapply(seq_len(nrow(active)), function(i) {
        g   <- active[i, ]
        pct <- min(100, round(100 * g$current / g$target))
        days_left <- as.numeric(as.Date(g$target_date) - Sys.Date())
        days_txt  <- if (days_left < 0) "\u26a0 Overdue" else paste0(days_left, " days left")
        cat_badge <- switch(g$category,
          strength    = "badge-strength",
          cardio      = "badge-cardio",
          body        = "badge-body",
          consistency = "badge-body",
          "badge-strength"
        )
        shiny::div(class = "goal-item",
          shiny::div(
            style = "display:flex; justify-content:space-between; align-items:center; margin-bottom:0.5rem;",
            shiny::div(
              shiny::div(class = "goal-name", g$name),
              shiny::span(class = paste("badge-pill", cat_badge, "me-2"), g$category)
            ),
            shiny::div(
              shiny::span(class = "goal-pct", paste0(pct, "%")),
              shiny::br(),
              shiny::small(style = "color:#8a8a9a;", days_txt)
            )
          ),
          shiny::div(
            style = "display:flex; align-items:center; gap:0.8rem;",
            shiny::div(style = "flex:1;",
              shiny::tags$div(class = "progress",
                shiny::tags$div(
                  class = "progress-bar",
                  style = paste0("width:", pct, "%"),
                  role  = "progressbar"
                )
              )
            ),
            shiny::small(style = "color:#8a8a9a; white-space:nowrap;",
                         paste0(g$current, " / ", g$target, " ", g$unit))
          )
        )
      })
      shiny::tagList(items)
    })

    # Render achieved goals
    output$achieved_list <- shiny::renderUI({
      df <- goals_rv()
      done <- df[df$achieved, ]
      if (nrow(done) == 0) {
        return(shiny::p(style = "color:#8a8a9a;font-size:0.88rem;",
                        "Keep going — your first achievement is coming! 💪"))
      }
      items <- lapply(seq_len(nrow(done)), function(i) {
        g <- done[i, ]
        shiny::div(class = "goal-item completed",
          style = "display:flex; justify-content:space-between; align-items:center;",
          shiny::div(
            shiny::div(class = "goal-name", g$name),
            shiny::small(style = "color:#8a8a9a;",
                         paste0(g$current, " / ", g$target, " ", g$unit))
          ),
          shiny::div(
            shiny::span(class = "badge-pill", style = "background:rgba(0,212,170,0.2);color:#00d4aa;",
                         "🏆 Achieved!")
          )
        )
      })
      shiny::tagList(items)
    })
  })
}
