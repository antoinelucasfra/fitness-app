#' The application server-side
#' @param input,output,session Internal parameters for {shiny}.
#' @noRd
app_server <- function(input, output, session) {

  # ── Reactive data stores ─────────────────────────────────────────────────
  workouts_rv <- shiny::reactiveVal(read_workouts())
  bodycomp_rv <- shiny::reactiveVal(read_bodycomp())
  goals_rv    <- shiny::reactiveVal(read_goals())

  # ── Sidebar streak label ─────────────────────────────────────────────────
  output$sidebar_streak_label <- shiny::renderText({
    streak <- compute_streak(workouts_rv())
    if (streak == 0) {
      "Start your streak today! 🔥"
    } else if (streak == 1) {
      "1 day streak 🔥"
    } else {
      paste0(streak, " day streak 🔥🔥")
    }
  })

  # ── Navigation state ──────────────────────────────────────────────────────
  current_tab <- shiny::reactiveVal("dashboard")

  nav_btn_style_active  <- "background:linear-gradient(135deg,#e94560,#c0392b);color:#fff;border:none;border-radius:8px;padding:0.55rem 1rem;font-weight:600;width:100%;text-align:left;box-shadow:0 4px 15px rgba(233,69,96,0.4);"
  nav_btn_style_default <- "background:transparent;color:#8a8a9a;border:none;border-radius:8px;padding:0.55rem 1rem;width:100%;text-align:left;"

  update_nav_styles <- function(active) {
    tabs <- c("dashboard", "log", "progress", "goals")
    for (t in tabs) {
      # Desktop sidebar button styles
      shinyjs::runjs(sprintf(
        "document.getElementById('%s').style.cssText = '%s';",
        paste0("nav_", t),
        if (t == active) nav_btn_style_active else nav_btn_style_default
      ))
      # Mobile bottom nav active class
      shinyjs::runjs(sprintf(
        "(function(){ var el = document.getElementById('%s'); if(el){ if('%s'==='%s'){ el.classList.add('mob-active'); } else { el.classList.remove('mob-active'); } } })();",
        paste0("mob_nav_", t), t, active
      ))
    }
  }

  shiny::observeEvent(input$nav_dashboard, { current_tab("dashboard"); update_nav_styles("dashboard") })
  shiny::observeEvent(input$nav_log,       { current_tab("log");       update_nav_styles("log") })
  shiny::observeEvent(input$nav_progress,  { current_tab("progress");  update_nav_styles("progress") })
  shiny::observeEvent(input$nav_goals,     { current_tab("goals");     update_nav_styles("goals") })

  # ── Main content router ───────────────────────────────────────────────────
  output$main_content <- shiny::renderUI({
    switch(current_tab(),
      dashboard = mod_dashboard_ui("dashboard"),
      log       = mod_workout_log_ui("log"),
      progress  = mod_progress_ui("progress"),
      goals     = mod_goals_ui("goals")
    )
  })

  # ── Module servers ────────────────────────────────────────────────────────
  mod_dashboard_server("dashboard", workouts = workouts_rv, goals = goals_rv)
  mod_workout_log_server("log", workouts_rv = workouts_rv)
  mod_progress_server("progress", workouts_rv = workouts_rv, bodycomp_rv = bodycomp_rv)
  mod_goals_server("goals", goals_rv = goals_rv, workouts = workouts_rv)
}
