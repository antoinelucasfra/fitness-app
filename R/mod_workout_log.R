#' Workout Log UI
#' @param id module id
#' @noRd
mod_workout_log_ui <- function(id) {
  ns <- shiny::NS(id)
  shiny::tagList(
    shiny::div(class = "section-title", "Log Workout"),
    shiny::div(class = "section-subtitle", "Record your training session"),

    shiny::div(class = "row g-3",
      # ── Entry form ──────────────────────────────────────────────────────
      shiny::div(class = "col-12 col-md-4",
        shiny::div(class = "panel-card",
          shiny::h5("New Session"),

          shiny::dateInput(ns("date"), "Date", value = Sys.Date(),
                           format = "dd/mm/yyyy"),

          shinyWidgets::radioGroupButtons(
            ns("type"),
            label = "Type",
            choices = c("Strength" = "strength",
                        "Cardio"   = "cardio"),
            selected = "strength",
            status = "danger",
            justified = TRUE,
            size = "sm"
          ),

          shiny::br(),

          # Strength fields
          shiny::conditionalPanel(
            condition = sprintf("input['%s'] === 'strength'", ns("type")),
            shiny::div(
              style = "display:flex; align-items:flex-end; gap:0.4rem;",
              shiny::div(style = "flex:1;",
                shiny::selectizeInput(
                  ns("exercise"),
                  "Exercise",
                  choices = c(
                    "Squat", "Deadlift", "Bench Press", "Overhead Press",
                    "Hip Thrust", "Leg Press", "Lunges", "Romanian Deadlift",
                    "Lat Pulldown", "Seated Row", "Bicep Curl", "Tricep Pushdown",
                    "Glute Kickback", "Cable Crunch", "Plank", "Other"
                  ),
                  options = list(create = TRUE),
                  width = "100%"
                )
              ),
              shiny::div(style = "padding-bottom:0.15rem;",
                shiny::actionButton(
                  ns("info_exercise"),
                  shiny::tags$i(class = "bi bi-info-circle"),
                  class = "btn btn-outline-secondary btn-sm",
                  title = "How to perform this exercise"
                )
              )
            ),
            shiny::fluidRow(
              shiny::column(4,
                shiny::numericInput(ns("sets"),    "Sets",    value = 3, min = 1, max = 20, step = 1)
              ),
              shiny::column(4,
                shiny::numericInput(ns("reps"),    "Reps",    value = 10, min = 1, max = 100, step = 1)
              ),
              shiny::column(4,
                shiny::numericInput(ns("weight"),  "kg",      value = 20, min = 0, max = 500, step = 0.5)
              )
            )
          ),

          # Cardio fields
          shiny::conditionalPanel(
            condition = sprintf("input['%s'] === 'cardio'", ns("type")),
            shiny::div(
              style = "display:flex; align-items:flex-end; gap:0.4rem;",
              shiny::div(style = "flex:1;",
                shiny::selectizeInput(
                  ns("cardio_exercise"),
                  "Activity",
                  choices = c(
                    "Running", "Treadmill", "Cycling", "Stationary Bike",
                    "Elliptical", "Rowing Machine", "Jump Rope", "Stairmaster",
                    "Swimming", "HIIT", "Other"
                  ),
                  options = list(create = TRUE),
                  width = "100%"
                )
              ),
              shiny::div(style = "padding-bottom:0.15rem;",
                shiny::actionButton(
                  ns("info_cardio"),
                  shiny::tags$i(class = "bi bi-info-circle"),
                  class = "btn btn-outline-secondary btn-sm",
                  title = "How to perform this activity"
                )
              )
            ),
            shiny::fluidRow(
              shiny::column(6,
                shiny::numericInput(ns("duration"), "Duration (min)", value = 30, min = 1, max = 300, step = 1)
              ),
              shiny::column(6,
                shiny::numericInput(ns("distance"), "Distance (km)", value = 0, min = 0, max = 200, step = 0.1)
              )
            )
          ),

          shiny::textAreaInput(ns("notes"), "Notes (optional)", placeholder = "How did it feel?", rows = 2),

          shiny::br(),
          shiny::actionButton(ns("add_btn"), "Add Exercise",
                              class = "btn btn-primary w-100", icon = NULL)
        )
      ),

      # ── Session builder ──────────────────────────────────────────────────
      shiny::div(class = "col-12 col-md-8",
        shiny::div(class = "panel-card",
          shiny::h5("Today's Session"),
          shiny::div(
            style = "display:flex; justify-content:space-between; align-items:center; margin-bottom:1rem;",
            shiny::div(
              shiny::strong("Date: ", style = "color:#8a8a9a;"),
              shiny::textOutput(ns("session_date_label"), inline = TRUE)
            ),
            shiny::div(
              shiny::actionButton(ns("save_session"), "Save Session",
                                  class = "btn btn-success btn-sm"),
              shiny::actionButton(ns("clear_session"), "Clear",
                                  class = "btn btn-outline-light btn-sm ms-2")
            )
          ),
          DT::DTOutput(ns("session_table")),
          shiny::br(),
          shiny::uiOutput(ns("session_summary"))
        ),

        shiny::div(class = "panel-card",
          shiny::h5("Full History"),
          shiny::div(class = "row g-2",
            shiny::div(class = "col-12 col-md-4",
              shiny::dateRangeInput(ns("hist_range"), "Date range",
                                   start = Sys.Date() - 30, end = Sys.Date(),
                                   format = "dd/mm/yyyy", separator = " to ")
            ),
            shiny::div(class = "col-12 col-md-3",
              shiny::selectInput(ns("hist_type"), "Type",
                                 choices = c("All", "strength", "cardio"),
                                 selected = "All")
            ),
            shiny::div(class = "col-12 col-md-5",
              shiny::br(),
                shiny::actionButton(ns("delete_selected"), "Delete Selected",
                                   class = "btn btn-outline-light btn-sm")
            )
          ),
          DT::DTOutput(ns("history_table"))
        )
      )
    )
  )
}

#' Workout Log Server
#' @param id module id
#' @param workouts_rv reactiveVal holding workouts data frame
#' @noRd
mod_workout_log_server <- function(id, workouts_rv) {
  shiny::moduleServer(id, function(input, output, session) {

    # Temporary in-session builder
    session_entries <- shiny::reactiveVal(workouts_schema())

    # Exercise info modals
    shiny::observeEvent(input$info_exercise, {
      nm <- if (!is.null(input$exercise) && nzchar(input$exercise)) input$exercise else "Squat"
      show_exercise_modal(nm, session)
    })
    shiny::observeEvent(input$info_cardio, {
      nm <- if (!is.null(input$cardio_exercise) && nzchar(input$cardio_exercise)) input$cardio_exercise else "Running"
      show_exercise_modal(nm, session)
    })

    output$session_date_label <- shiny::renderText({
      format(input$date, "%d %B %Y")
    })

    # Add exercise to session
    shiny::observeEvent(input$add_btn, {
      shiny::req(input$date)

      if (input$type == "strength") {
        shiny::req(input$exercise, input$sets, input$reps, input$weight)
        new_row <- data.frame(
          id           = new_id(),
          date         = as.Date(input$date),
          type         = "strength",
          exercise     = input$exercise,
          sets         = as.integer(input$sets),
          reps         = as.integer(input$reps),
          weight_kg    = as.numeric(input$weight),
          duration_min = NA_real_,
          distance_km  = NA_real_,
          notes        = input$notes,
          stringsAsFactors = FALSE
        )
      } else {
        shiny::req(input$cardio_exercise, input$duration)
        new_row <- data.frame(
          id           = new_id(),
          date         = as.Date(input$date),
          type         = "cardio",
          exercise     = input$cardio_exercise,
          sets         = NA_integer_,
          reps         = NA_integer_,
          weight_kg    = NA_real_,
          duration_min = as.numeric(input$duration),
          distance_km  = as.numeric(input$distance),
          notes        = input$notes,
          stringsAsFactors = FALSE
        )
      }

      session_entries(rbind(session_entries(), new_row))
    })

    # Session table (in-progress)
    output$session_table <- DT::renderDT({
      df <- session_entries()
      if (nrow(df) == 0) {
        return(data.frame(
          Type = character(), Exercise = character(), Detail = character()
        ))
      }
      detail <- ifelse(
        df$type == "strength",
        paste0(df$sets, "x", df$reps, " @ ", df$weight_kg, " kg"),
        paste0(df$duration_min, " min",
               ifelse(!is.na(df$distance_km) & df$distance_km > 0,
                      paste0(" / ", df$distance_km, " km"), ""))
      )
      display <- data.frame(
        Type     = df$type,
        Exercise = df$exercise,
        Detail   = detail,
        Notes    = ifelse(is.na(df$notes) | df$notes == "", "-", df$notes),
        stringsAsFactors = FALSE
      )
      DT::datatable(
        display,
        options = list(dom = "t", pageLength = 20, ordering = FALSE),
        rownames = FALSE,
        selection = "none"
      )
    })

    # Session summary
    output$session_summary <- shiny::renderUI({
      df <- session_entries()
      if (nrow(df) == 0) return(NULL)
      n_strength <- sum(df$type == "strength")
      n_cardio   <- sum(df$type == "cardio")
      total_vol  <- sum(df$sets * df$reps * df$weight_kg, na.rm = TRUE)
      total_dur  <- sum(df$duration_min, na.rm = TRUE)
      tags <- list()
      if (n_strength > 0)
        tags <- c(tags, list(shiny::span(class = "badge-pill badge-strength me-2",
                                        paste0(n_strength, " strength exercise(s)"))))
      if (n_cardio > 0)
        tags <- c(tags, list(shiny::span(class = "badge-pill badge-cardio me-2",
                                        paste0(n_cardio, " cardio activity(ies)"))))
      if (total_vol > 0)
        tags <- c(tags, list(shiny::span(class = "badge-pill badge-body me-2",
                                        paste0(format(round(total_vol), big.mark = ","), " kg total volume"))))
      if (total_dur > 0)
        tags <- c(tags, list(shiny::span(class = "badge-pill badge-cardio me-2",
                                        paste0(total_dur, " min"))))
      shiny::div(tags)
    })

    # Save session
    shiny::observeEvent(input$save_session, {
      df <- session_entries()
      if (nrow(df) == 0) {
        shiny::showNotification("Add at least one exercise first!", type = "warning")
        return()
      }
      all_workouts <- rbind(workouts_rv(), df)
      workouts_rv(all_workouts)
      write_workouts(all_workouts)
      session_entries(workouts_schema())
      shiny::showNotification(
        paste0("Session saved. ", nrow(df), " exercise(s) logged."),
        type = "message", duration = 4
      )
    })

    # Clear session
    shiny::observeEvent(input$clear_session, {
      session_entries(workouts_schema())
    })

    # History table
    output$history_table <- DT::renderDT({
      df <- workouts_rv()
      if (nrow(df) == 0) {
        return(data.frame(Date = character(), Type = character(),
                          Exercise = character(), Detail = character()))
      }
      df <- df[as.Date(df$date) >= input$hist_range[1] &
                 as.Date(df$date) <= input$hist_range[2], ]
      if (input$hist_type != "All")
        df <- df[df$type == input$hist_type, ]
      df <- df[order(as.Date(df$date), decreasing = TRUE), ]
      if (nrow(df) == 0) {
        return(data.frame(Date = character(), Type = character(),
                          Exercise = character(), Detail = character()))
      }
      detail <- ifelse(
        df$type == "strength",
        paste0(df$sets, "x", df$reps, " @ ", df$weight_kg, " kg"),
        paste0(df$duration_min, " min",
               ifelse(!is.na(df$distance_km) & df$distance_km > 0,
                      paste0(" / ", df$distance_km, " km"), ""))
      )
      display <- data.frame(
        Date     = format(as.Date(df$date), "%d %b %Y"),
        Type     = df$type,
        Exercise = df$exercise,
        Detail   = detail,
        Notes    = ifelse(is.na(df$notes) | df$notes == "", "-", df$notes),
        stringsAsFactors = FALSE
      )
      DT::datatable(
        display,
        options = list(pageLength = 10, dom = "ftipl"),
        rownames = FALSE,
        selection = "multiple"
      )
    })

    # Delete selected rows
    shiny::observeEvent(input$delete_selected, {
      rows <- input$history_table_rows_selected
      if (is.null(rows) || length(rows) == 0) {
        shiny::showNotification("Select rows to delete first.", type = "warning")
        return()
      }
      df <- workouts_rv()
      df_filtered <- df[
        as.Date(df$date) >= input$hist_range[1] &
          as.Date(df$date) <= input$hist_range[2], ]
      if (input$hist_type != "All")
        df_filtered <- df_filtered[df_filtered$type == input$hist_type, ]
      df_filtered <- df_filtered[order(as.Date(df_filtered$date), decreasing = TRUE), ]
      ids_to_delete <- df_filtered$id[rows]
      df_new <- df[!df$id %in% ids_to_delete, ]
      workouts_rv(df_new)
      write_workouts(df_new)
      shiny::showNotification(paste0("Deleted ", length(rows), " row(s)."),
                               type = "warning", duration = 3)
    })
  })
}
