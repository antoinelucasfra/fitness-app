#' Planner UI
#' @param id module id
#' @noRd
mod_planner_ui <- function(id) {
  ns <- shiny::NS(id)
  shiny::tagList(
    shiny::div(class = "section-title", "Planner"),
    shiny::div(class = "section-subtitle", "Create workout templates and run live sessions"),

    shiny::div(class = "row g-3",
      # ── Left panel: plan management ─────────────────────────────────────────
      shiny::div(class = "col-12 col-md-4",
        shiny::div(class = "panel-card",
          shiny::h5("My Plans"),

          shiny::div(
            style = "display:flex; gap:0.5rem; align-items:flex-end; margin-bottom:1rem;",
            shiny::div(style = "flex:1;",
              shiny::textInput(ns("new_plan_name"), "New plan name",
                               placeholder = "e.g. Push Day A")
            ),
            shiny::actionButton(ns("create_plan"), "Create",
                                class = "btn btn-primary btn-sm mb-0")
          ),

          shiny::uiOutput(ns("plan_list_ui"))
        ),

        shiny::div(class = "panel-card",
          shiny::h5("Add Exercise to Plan"),
          shiny::uiOutput(ns("add_exercise_target_ui")),

          shinyWidgets::radioGroupButtons(
            ns("plan_ex_type"),
            label = "Type",
            choices = c("Strength" = "strength", "Cardio" = "cardio"),
            selected = "strength",
            status = "danger",
            justified = TRUE,
            size = "sm"
          ),

          shiny::br(),

          shiny::conditionalPanel(
            condition = sprintf("input['%s'] === 'strength'", ns("plan_ex_type")),
            shiny::div(
              style = "display:flex; align-items:flex-end; gap:0.4rem;",
              shiny::div(style = "flex:1;",
                shiny::selectizeInput(
                  ns("plan_ex_exercise"),
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
                  ns("info_plan_ex"),
                  shiny::tags$i(class = "bi bi-info-circle"),
                  class = "btn btn-outline-secondary btn-sm",
                  title = "How to perform this exercise"
                )
              )
            ),
            shiny::fluidRow(
              shiny::column(4,
                shiny::numericInput(ns("plan_ex_sets"),   "Sets",   value = 3,  min = 1, max = 20,  step = 1)
              ),
              shiny::column(4,
                shiny::numericInput(ns("plan_ex_reps"),   "Reps",   value = 10, min = 1, max = 100, step = 1)
              ),
              shiny::column(4,
                shiny::numericInput(ns("plan_ex_weight"), "kg",     value = 20, min = 0, max = 500, step = 0.5)
              )
            )
          ),

          shiny::conditionalPanel(
            condition = sprintf("input['%s'] === 'cardio'", ns("plan_ex_type")),
            shiny::div(
              style = "display:flex; align-items:flex-end; gap:0.4rem;",
              shiny::div(style = "flex:1;",
                shiny::selectizeInput(
                  ns("plan_ex_cardio"),
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
                  ns("info_plan_cardio"),
                  shiny::tags$i(class = "bi bi-info-circle"),
                  class = "btn btn-outline-secondary btn-sm",
                  title = "How to perform this activity"
                )
              )
            ),
            shiny::fluidRow(
              shiny::column(6,
                shiny::numericInput(ns("plan_ex_duration"), "Duration (min)", value = 30, min = 1, max = 300, step = 1)
              ),
              shiny::column(6,
                shiny::numericInput(ns("plan_ex_distance"), "Distance (km)",  value = 0,  min = 0, max = 200, step = 0.1)
              )
            )
          ),

          shiny::actionButton(ns("add_ex_to_plan"), "Add to Plan",
                              class = "btn btn-outline-light w-100 btn-sm")
        )
      ),

      # ── Right panel: plan detail / session mode ──────────────────────────────
      shiny::div(class = "col-12 col-md-8",
        shiny::uiOutput(ns("right_panel"))
      )
    )
  )
}

#' Planner Server
#' @param id module id
#' @param workouts_rv reactiveVal holding workouts data frame
#' @noRd
mod_planner_server <- function(id, workouts_rv) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

    plans_rv         <- shiny::reactiveVal(read_plans())
    plan_exercises_rv <- shiny::reactiveVal(read_plan_exercises())

    # Currently selected plan id
    selected_plan_id <- shiny::reactiveVal(NULL)

    # Active session state: list of rows from plan_exercises + checked + actual params
    session_active   <- shiny::reactiveVal(FALSE)
    session_data     <- shiny::reactiveVal(NULL)  # data.frame with session exercise rows

    # ── Exercise info modals (add-exercise form) ───────────────────────────────
    shiny::observeEvent(input$info_plan_ex, {
      nm <- if (!is.null(input$plan_ex_exercise) && nzchar(input$plan_ex_exercise)) input$plan_ex_exercise else "Squat"
      show_exercise_modal(nm, session)
    })
    shiny::observeEvent(input$info_plan_cardio, {
      nm <- if (!is.null(input$plan_ex_cardio) && nzchar(input$plan_ex_cardio)) input$plan_ex_cardio else "Running"
      show_exercise_modal(nm, session)
    })

    # ── Create plan ────────────────────────────────────────────────────────────
    shiny::observeEvent(input$create_plan, {
      name <- trimws(input$new_plan_name)
      if (!nzchar(name)) {
        shiny::showNotification("Enter a plan name first.", type = "warning")
        return()
      }
      plans <- plans_rv()
      if (name %in% plans$name) {
        shiny::showNotification("A plan with that name already exists.", type = "warning")
        return()
      }
      new_plan <- data.frame(
        id         = new_id(),
        name       = name,
        created_at = Sys.Date(),
        stringsAsFactors = FALSE
      )
      plans <- rbind(plans, new_plan)
      plans_rv(plans)
      write_plans(plans)
      selected_plan_id(new_plan$id)
      shiny::updateTextInput(session, "new_plan_name", value = "")
      shiny::showNotification(paste0("Plan \"", name, "\" created."), type = "message", duration = 3)
    })

    # ── Plan list UI ───────────────────────────────────────────────────────────
    output$plan_list_ui <- shiny::renderUI({
      plans <- plans_rv()
      if (nrow(plans) == 0) {
        return(shiny::p(style = "color:#8a8a9a; font-size:0.85rem;", "No plans yet. Create one above."))
      }
      selected <- selected_plan_id()
      rows <- lapply(seq_len(nrow(plans)), function(i) {
        pid   <- plans$id[i]
        pname <- plans$name[i]
        is_sel <- identical(selected, pid)

        shiny::div(
          class = paste0("plan-row", if (is_sel) " plan-row--active" else ""),
          style = paste0(
            "display:flex; align-items:center; justify-content:space-between;",
            "padding:0.65rem 0.9rem; border-radius:8px; margin-bottom:0.4rem;",
            "cursor:pointer; user-select:none;",
            if (is_sel)
              "background:#1a2a4a; border:2px solid #e94560;"
            else
              "background:#1a1a2e; border:2px solid transparent;"
          ),
          onclick = paste0(
            "(function(e){",
            "if(e.target.closest('button'))return;",
            "Shiny.setInputValue('", ns(paste0("select_plan_", pid)), "',Math.random());",
            "})(event)"
          ),
          shiny::div(
            style = "display:flex; align-items:center; gap:0.65rem;",
            shiny::tags$i(
              class = if (is_sel) "bi bi-check-circle-fill" else "bi bi-circle",
              style = paste0(
                "font-size:1rem; color:",
                if (is_sel) "#e94560" else "#4a4a6a", ";"
              )
            ),
            shiny::div(
              style = paste0(
                "font-weight:600; font-size:0.9rem; color:",
                if (is_sel) "#e8e8e8" else "#a8a8b8", ";"
              ),
              pname
            )
          ),
          shiny::actionButton(
            ns(paste0("delete_plan_", pid)),
            shiny::tags$i(class = "bi bi-trash"),
            class = "btn btn-sm btn-outline-danger p-1",
            title = "Delete plan"
          )
        )
      })
      shiny::tagList(rows)
    })

    # ── Dynamic observers for plan select/delete buttons ──────────────────────
    shiny::observe({
      plans <- plans_rv()
      if (nrow(plans) == 0) return()
      lapply(plans$id, function(pid) {
        sel_id <- paste0("select_plan_", pid)
        del_id <- paste0("delete_plan_", pid)

        shiny::observeEvent(input[[sel_id]], {
          selected_plan_id(pid)
        }, ignoreInit = TRUE)

        shiny::observeEvent(input[[del_id]], {
          if (isTRUE(session_active()) && identical(selected_plan_id(), pid)) {
            shiny::showNotification("Cannot delete a plan while a session is active.", type = "warning")
            return()
          }
          plans_new <- plans_rv()
          plans_new <- plans_new[plans_new$id != pid, ]
          plans_rv(plans_new)
          write_plans(plans_new)
          pex <- plan_exercises_rv()
          pex <- pex[pex$plan_id != pid, ]
          plan_exercises_rv(pex)
          write_plan_exercises(pex)
          if (identical(selected_plan_id(), pid))
            selected_plan_id(if (nrow(plans_new) > 0) plans_new$id[1] else NULL)
          shiny::showNotification("Plan deleted.", type = "warning", duration = 3)
        }, ignoreInit = TRUE)
      })
    })

    # ── Add-to-plan target UI ──────────────────────────────────────────────────
    output$add_exercise_target_ui <- shiny::renderUI({
      plans <- plans_rv()
      if (nrow(plans) == 0) {
        return(shiny::p(style = "color:#8a8a9a; font-size:0.85rem;", "Create a plan first."))
      }
      selected <- selected_plan_id()
      choices <- stats::setNames(plans$id, plans$name)
      shiny::selectInput(
        ns("target_plan_id"),
        "Add to plan",
        choices  = choices,
        selected = selected,
        width    = "100%"
      )
    })

    # ── Add exercise to plan ───────────────────────────────────────────────────
    shiny::observeEvent(input$add_ex_to_plan, {
      pid <- input$target_plan_id
      shiny::req(pid)

      pex <- plan_exercises_rv()
      order_next <- sum(pex$plan_id == pid) + 1L

      if (input$plan_ex_type == "strength") {
        shiny::req(input$plan_ex_exercise, input$plan_ex_sets, input$plan_ex_reps, input$plan_ex_weight)
        new_ex <- data.frame(
          id           = new_id(),
          plan_id      = pid,
          exercise     = input$plan_ex_exercise,
          type         = "strength",
          sets         = as.integer(input$plan_ex_sets),
          reps         = as.integer(input$plan_ex_reps),
          weight_kg    = as.numeric(input$plan_ex_weight),
          duration_min = NA_real_,
          distance_km  = NA_real_,
          order_idx    = order_next,
          stringsAsFactors = FALSE
        )
      } else {
        shiny::req(input$plan_ex_cardio, input$plan_ex_duration)
        new_ex <- data.frame(
          id           = new_id(),
          plan_id      = pid,
          exercise     = input$plan_ex_cardio,
          type         = "cardio",
          sets         = NA_integer_,
          reps         = NA_integer_,
          weight_kg    = NA_real_,
          duration_min = as.numeric(input$plan_ex_duration),
          distance_km  = as.numeric(input$plan_ex_distance),
          order_idx    = order_next,
          stringsAsFactors = FALSE
        )
      }

      pex <- rbind(pex, new_ex)
      plan_exercises_rv(pex)
      write_plan_exercises(pex)
      shiny::showNotification(
        paste0(new_ex$exercise, " added to plan."),
        type = "message", duration = 2
      )
    })

    # ── Right panel ────────────────────────────────────────────────────────────
    output$right_panel <- shiny::renderUI({
      if (isTRUE(session_active())) {
        session_panel_ui(ns)
      } else {
        plan_detail_ui(ns, selected_plan_id(), plans_rv(), plan_exercises_rv())
      }
    })

    # ── Plan detail (exercises table + start session) ──────────────────────────
    output$plan_exercises_table <- DT::renderDT({
      pid <- selected_plan_id()
      pex <- plan_exercises_rv()
      if (is.null(pid)) return(empty_exercise_table())
      pex <- pex[pex$plan_id == pid, , drop = FALSE]
      if (nrow(pex) == 0) return(empty_exercise_table())
      pex <- pex[order(pex$order_idx), ]
      detail <- ifelse(
        pex$type == "strength",
        paste0(pex$sets, "x", pex$reps, " @ ", pex$weight_kg, " kg"),
        paste0(pex$duration_min, " min",
               ifelse(!is.na(pex$distance_km) & pex$distance_km > 0,
                      paste0(" / ", pex$distance_km, " km"), ""))
      )
      display <- data.frame(
        `#`      = seq_len(nrow(pex)),
        Type     = pex$type,
        Exercise = pex$exercise,
        Target   = detail,
        check.names = FALSE,
        stringsAsFactors = FALSE
      )
      DT::datatable(
        display,
        options  = list(dom = "t", pageLength = 30, ordering = FALSE),
        rownames = FALSE,
        selection = "multiple"
      )
    })

    shiny::observeEvent(input$delete_plan_ex, {
      pid  <- selected_plan_id()
      rows <- input$plan_exercises_table_rows_selected
      if (is.null(rows) || length(rows) == 0) {
        shiny::showNotification("Select rows to delete first.", type = "warning")
        return()
      }
      pex  <- plan_exercises_rv()
      pex_plan <- pex[pex$plan_id == pid, , drop = FALSE]
      pex_plan <- pex_plan[order(pex_plan$order_idx), ]
      ids_del  <- pex_plan$id[rows]
      pex_new  <- pex[!pex$id %in% ids_del, ]
      # Re-index order
      for (p in unique(pex_new$plan_id)) {
        idx <- which(pex_new$plan_id == p)
        pex_new$order_idx[idx] <- seq_along(idx)
      }
      plan_exercises_rv(pex_new)
      write_plan_exercises(pex_new)
      shiny::showNotification(paste0("Deleted ", length(rows), " exercise(s)."), type = "warning", duration = 3)
    })

    # ── Start session ──────────────────────────────────────────────────────────
    shiny::observeEvent(input$start_session, {
      pid <- selected_plan_id()
      pex <- plan_exercises_rv()
      pex <- pex[pex$plan_id == pid, , drop = FALSE]
      if (nrow(pex) == 0) {
        shiny::showNotification("Add exercises to the plan first.", type = "warning")
        return()
      }
      pex <- pex[order(pex$order_idx), ]
      # Build session data with actual param input ids
      sd <- pex
      sd$checked <- FALSE
      session_data(sd)
      session_active(TRUE)
    })

    # ── Session mode handlers ──────────────────────────────────────────────────
    shiny::observe({
      sd <- session_data()
      if (is.null(sd)) return()
      lapply(seq_len(nrow(sd)), function(i) {
        ex_id    <- sd$id[i]
        ex_name  <- sd$exercise[i]
        chk_id   <- paste0("chk_", ex_id)
        info_id  <- paste0("info_card_", ex_id)

        shiny::observeEvent(input[[chk_id]], {
          sd2 <- session_data()
          sd2$checked[sd2$id == ex_id] <- isTRUE(input[[chk_id]])
          session_data(sd2)
        }, ignoreInit = TRUE)

        shiny::observeEvent(input[[info_id]], {
          show_exercise_modal(ex_name, session)
        }, ignoreInit = TRUE)
      })
    })

    # ── Session progress ───────────────────────────────────────────────────────
    output$session_progress <- shiny::renderUI({
      sd <- session_data()
      if (is.null(sd)) return(NULL)
      n_done  <- sum(sd$checked)
      n_total <- nrow(sd)
      pct     <- if (n_total > 0) round(100 * n_done / n_total) else 0
      shiny::div(
        style = "margin-bottom:1rem;",
        shiny::div(
          style = "display:flex; justify-content:space-between; margin-bottom:0.3rem;",
          shiny::span(style = "color:#8a8a9a; font-size:0.85rem;",
                      paste0(n_done, " / ", n_total, " exercises done")),
          shiny::span(style = "color:#e94560; font-weight:700;", paste0(pct, "%"))
        ),
        shiny::tags$div(
          class = "progress",
          style = "height:6px; background:#2a2a4a; border-radius:3px;",
          shiny::tags$div(
            class = "progress-bar",
            style = paste0("width:", pct, "%; background:linear-gradient(90deg,#e94560,#c0392b); border-radius:3px;"),
            role = "progressbar"
          )
        )
      )
    })

    # ── Session exercise cards ─────────────────────────────────────────────────
    output$session_cards <- shiny::renderUI({
      sd <- session_data()
      if (is.null(sd)) return(NULL)

      cards <- lapply(seq_len(nrow(sd)), function(i) {
        row      <- sd[i, ]
        ex_id    <- row$id
        chk_id   <- ns(paste0("chk_", ex_id))
        is_checked <- isTRUE(row$checked)

        if (row$type == "strength") {
          detail_fields <- shiny::fluidRow(
            shiny::column(4,
              shiny::numericInput(ns(paste0("act_sets_",   ex_id)), "Sets",
                                  value = row$sets,   min = 1, max = 20,  step = 1)
            ),
            shiny::column(4,
              shiny::numericInput(ns(paste0("act_reps_",   ex_id)), "Reps",
                                  value = row$reps,   min = 1, max = 100, step = 1)
            ),
            shiny::column(4,
              shiny::numericInput(ns(paste0("act_weight_", ex_id)), "kg",
                                  value = row$weight_kg, min = 0, max = 500, step = 0.5)
            )
          )
          target_label <- paste0("Target: ", row$sets, "x", row$reps, " @ ", row$weight_kg, " kg")
        } else {
          detail_fields <- shiny::fluidRow(
            shiny::column(6,
              shiny::numericInput(ns(paste0("act_duration_", ex_id)), "Duration (min)",
                                  value = row$duration_min, min = 1, max = 300, step = 1)
            ),
            shiny::column(6,
              shiny::numericInput(ns(paste0("act_distance_", ex_id)), "Distance (km)",
                                  value = ifelse(is.na(row$distance_km), 0, row$distance_km),
                                  min = 0, max = 200, step = 0.1)
            )
          )
          target_label <- paste0("Target: ", row$duration_min, " min")
        }

        border_color <- if (is_checked) "#00d4aa" else "#2a2a4a"
        bg_color     <- if (is_checked) "rgba(0,212,170,0.06)" else "rgba(26,26,46,0.8)"
        name_color   <- if (is_checked) "#00d4aa" else "#e8e8e8"
        name_extra   <- if (is_checked) "text-decoration:line-through; opacity:0.75;" else ""

        # Hidden Shiny checkbox (tracks state; not visible)
        hidden_chk <- shiny::div(
          style = "display:none;",
          shiny::checkboxInput(chk_id, label = NULL, value = is_checked)
        )

        # Large tap-friendly check icon (replaces visible checkbox widget)
        check_icon <- shiny::tags$i(
          class = if (is_checked) "bi bi-check-circle-fill" else "bi bi-circle",
          style = paste0(
            "font-size:1.6rem; flex-shrink:0; transition:color 0.2s;",
            "color:", if (is_checked) "#00d4aa" else "#4a4a6a", ";"
          )
        )

        # JS onclick: toggle hidden checkbox; guard against button/input clicks
        toggle_js <- paste0(
          "(function(e){",
          "if(e.target.closest('button')||e.target.closest('input'))return;",
          "var $cb=$('#", chk_id, "');",
          "$cb.prop('checked',!$cb.prop('checked')).trigger('change');",
          "})(event)"
        )

        shiny::div(
          class = "session-ex-card",
          style = paste0(
            "border:2px solid ", border_color, ";background:", bg_color, ";",
            "border-radius:12px; padding:0.9rem 1rem; margin-bottom:0.75rem;",
            "transition:border-color 0.2s, background 0.2s;"
          ),
          hidden_chk,
          # ── Tappable header ──────────────────────────────────────────────
          shiny::div(
            class = "session-card-header",
            onclick = toggle_js,
            check_icon,
            shiny::div(
              style = "flex:1; min-width:0;",
              shiny::div(
                style = paste0("font-weight:700; font-size:1rem; color:", name_color, ";", name_extra),
                row$exercise
              ),
              shiny::div(
                style = "color:#8a8a9a; font-size:0.8rem; margin-top:3px;",
                shiny::tags$i(class = paste0("bi ",
                  if (row$type == "strength") "bi-lightning-fill" else "bi-heart-pulse-fill",
                  " me-1")),
                target_label
              )
            ),
            shiny::actionButton(
              ns(paste0("info_card_", ex_id)),
              shiny::tags$i(class = "bi bi-info-circle"),
              class = "btn btn-outline-secondary btn-sm p-1",
              style = "line-height:1; min-width:32px; flex-shrink:0;",
              title = paste("How to:", row$exercise)
            )
          ),
          # ── Detail inputs (editing zone — not a toggle target) ───────────
          shiny::div(
            class = "session-card-fields",
            style = paste0(
              "opacity:", if (is_checked) "1" else "0.5", ";",
              "transition:opacity 0.2s; border-top:1px solid #2a2a4a;",
              "padding-top:0.75rem; margin-top:0.25rem;"
            ),
            detail_fields
          )
        )
      })

      shiny::tagList(cards)
    })

    # ── Cancel session ─────────────────────────────────────────────────────────
    shiny::observeEvent(input$cancel_session, {
      session_active(FALSE)
      session_data(NULL)
      shiny::showNotification("Session cancelled.", type = "warning", duration = 3)
    })

    # ── Complete session ───────────────────────────────────────────────────────
    shiny::observeEvent(input$complete_session, {
      sd <- session_data()
      shiny::req(sd)

      checked_rows <- sd[sd$checked, , drop = FALSE]
      if (nrow(checked_rows) == 0) {
        shiny::showNotification("Check at least one exercise before completing the session.", type = "warning")
        return()
      }

      new_rows <- lapply(seq_len(nrow(checked_rows)), function(i) {
        row <- checked_rows[i, ]
        ex_id <- row$id

        if (row$type == "strength") {
          act_sets   <- input[[paste0("act_sets_",   ex_id)]]
          act_reps   <- input[[paste0("act_reps_",   ex_id)]]
          act_weight <- input[[paste0("act_weight_", ex_id)]]
          data.frame(
            id           = new_id(),
            date         = Sys.Date(),
            type         = "strength",
            exercise     = row$exercise,
            sets         = as.integer(if (!is.null(act_sets))   act_sets   else row$sets),
            reps         = as.integer(if (!is.null(act_reps))   act_reps   else row$reps),
            weight_kg    = as.numeric(if (!is.null(act_weight)) act_weight else row$weight_kg),
            duration_min = NA_real_,
            distance_km  = NA_real_,
            notes        = "",
            stringsAsFactors = FALSE
          )
        } else {
          act_duration <- input[[paste0("act_duration_", ex_id)]]
          act_distance <- input[[paste0("act_distance_", ex_id)]]
          data.frame(
            id           = new_id(),
            date         = Sys.Date(),
            type         = "cardio",
            exercise     = row$exercise,
            sets         = NA_integer_,
            reps         = NA_integer_,
            weight_kg    = NA_real_,
            duration_min = as.numeric(if (!is.null(act_duration)) act_duration else row$duration_min),
            distance_km  = as.numeric(if (!is.null(act_distance)) act_distance else row$distance_km),
            notes        = "",
            stringsAsFactors = FALSE
          )
        }
      })

      new_df <- do.call(rbind, new_rows)
      all_workouts <- rbind(workouts_rv(), new_df)
      workouts_rv(all_workouts)
      write_workouts(all_workouts)

      session_active(FALSE)
      session_data(NULL)

      shiny::showNotification(
        paste0("Session saved! ", nrow(new_df), " exercise(s) logged."),
        type = "message", duration = 4
      )
    })
  })
}

# ── Helper: empty exercise table ─────────────────────────────────────────────

empty_exercise_table <- function() {
  DT::datatable(
    data.frame(`#` = character(), Type = character(),
               Exercise = character(), Target = character(),
               check.names = FALSE, stringsAsFactors = FALSE),
    options  = list(dom = "t", pageLength = 30, ordering = FALSE),
    rownames = FALSE,
    selection = "multiple"
  )
}

# ── Helper: plan detail panel UI ─────────────────────────────────────────────

plan_detail_ui <- function(ns, selected_plan_id, plans, plan_exercises) {
  if (is.null(selected_plan_id) || nrow(plans) == 0) {
    return(shiny::div(class = "panel-card",
      shiny::p(style = "color:#8a8a9a;", "Select or create a plan on the left.")
    ))
  }
  plan_name <- plans$name[plans$id == selected_plan_id]
  if (length(plan_name) == 0) plan_name <- "Unknown plan"

  pex <- plan_exercises[plan_exercises$plan_id == selected_plan_id, , drop = FALSE]
  n_ex <- nrow(pex)

  shiny::div(class = "panel-card",
    shiny::div(
      style = "display:flex; justify-content:space-between; align-items:center; margin-bottom:1rem;",
      shiny::div(
        shiny::h5(plan_name, style = "margin:0;"),
        shiny::span(style = "color:#8a8a9a; font-size:0.82rem;",
                    paste0(n_ex, " exercise(s)"))
      ),
      shiny::div(
        shiny::actionButton(
          ns("delete_plan_ex"),
          shiny::tagList(shiny::tags$i(class = "bi bi-trash me-1"), "Delete selected"),
          class = "btn btn-outline-danger btn-sm me-2"
        ),
        shiny::actionButton(
          ns("start_session"),
          shiny::tagList(shiny::tags$i(class = "bi bi-play-fill me-1"), "Start Session"),
          class = "btn btn-success btn-sm",
          disabled = if (n_ex == 0) "disabled" else NULL
        )
      )
    ),
    DT::DTOutput(ns("plan_exercises_table"))
  )
}

# ── Helper: session panel UI ─────────────────────────────────────────────────

session_panel_ui <- function(ns) {
  shiny::div(class = "panel-card",
    shiny::div(
      style = "display:flex; justify-content:space-between; align-items:center; margin-bottom:0.5rem;",
      shiny::h5(shiny::tags$i(class = "bi bi-lightning-fill me-2", style = "color:#e94560;"),
                "Session in progress", style = "margin:0;"),
      shiny::div(
        shiny::actionButton(
          ns("cancel_session"),
          shiny::tagList(shiny::tags$i(class = "bi bi-x-circle me-1"), "Cancel"),
          class = "btn btn-outline-secondary btn-sm me-2"
        ),
        shiny::actionButton(
          ns("complete_session"),
          shiny::tagList(shiny::tags$i(class = "bi bi-check-circle-fill me-1"), "Complete Session"),
          class = "btn btn-success btn-sm"
        )
      )
    ),
    shiny::uiOutput(ns("session_progress")),
    shiny::uiOutput(ns("session_cards"))
  )
}
