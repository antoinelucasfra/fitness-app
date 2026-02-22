#' The application User-Interface
#' @param request Internal parameter for `{shiny}`.
#' @noRd
app_ui <- function(request) {
  shiny::tagList(
    # ── Head ────────────────────────────────────────────────────────────────
    golem_add_external_resources(),
    shiny::tags$head(
      shiny::tags$meta(name = "viewport",
                       content = "width=device-width, initial-scale=1.0"),
      shinyjs::useShinyjs()
    ),

    # ── App shell ───────────────────────────────────────────────────────────
    bslib::page_sidebar(
      title = shiny::div(
        style = "display:flex; align-items:center; gap:0.6rem;",
        shiny::span(style = "font-size:1.4rem;", "💪"),
        shiny::span(
          style = "font-weight:800; font-size:1.15rem; color:#e8e8e8;",
          "FLO FIT"
        )
      ),
      theme = bslib::bs_theme(
        version      = 5,
        bg           = "#0d0d0d",
        fg           = "#e8e8e8",
        primary      = "#e94560",
        secondary    = "#0f3460",
        success      = "#00d4aa",
        warning      = "#f5a623",
        info         = "#2980b9",
        base_font    = bslib::font_google("Inter"),
        heading_font = bslib::font_google("Inter"),
        bootswatch   = NULL
      ),

      # ── Sidebar ────────────────────────────────────────────────────────────
      sidebar = bslib::sidebar(
        width = 230,
        style = "background:#16213e; border-right:1px solid #2a2a4a;",
        shiny::br(),
        # User greeting
        shiny::div(
          style = "padding:0.8rem 1rem; margin-bottom:0.5rem;",
          shiny::div(
            style = "font-size:1.6rem; text-align:center;", "🌸"
          ),
          shiny::div(
            style = "text-align:center; font-weight:700; color:#e8e8e8; font-size:0.95rem;",
            "Hey Florence!"
          ),
          shiny::div(
            style = "text-align:center; font-size:0.78rem; color:#8a8a9a; margin-top:2px;",
            shiny::textOutput("sidebar_streak_label", inline = TRUE)
          )
        ),
        shiny::hr(style = "border-color:#2a2a4a; margin:0.5rem 0;"),
        # Navigation pills
        shiny::div(
          class = "d-grid gap-1",
          style = "padding:0 0.3rem;",
          shiny::actionButton(
            "nav_dashboard",
            shiny::div(
              shiny::tags$i(class = "bi bi-house-fill me-2"),
              "Dashboard"
            ),
            class = "btn btn-nav text-start nav-pill-btn active-nav",
            style = "background:linear-gradient(135deg,#e94560,#c0392b);color:#fff;border:none;border-radius:8px;padding:0.55rem 1rem;font-weight:600;width:100%;text-align:left;"
          ),
          shiny::actionButton(
            "nav_log",
            shiny::div(
              shiny::tags$i(class = "bi bi-pencil-square me-2"),
              "Log Workout"
            ),
            class = "btn btn-nav text-start",
            style = "background:transparent;color:#8a8a9a;border:none;border-radius:8px;padding:0.55rem 1rem;width:100%;text-align:left;"
          ),
          shiny::actionButton(
            "nav_progress",
            shiny::div(
              shiny::tags$i(class = "bi bi-graph-up-arrow me-2"),
              "Progress"
            ),
            class = "btn btn-nav text-start",
            style = "background:transparent;color:#8a8a9a;border:none;border-radius:8px;padding:0.55rem 1rem;width:100%;text-align:left;"
          ),
          shiny::actionButton(
            "nav_goals",
            shiny::div(
              shiny::tags$i(class = "bi bi-trophy-fill me-2"),
              "Goals"
            ),
            class = "btn btn-nav text-start",
            style = "background:transparent;color:#8a8a9a;border:none;border-radius:8px;padding:0.55rem 1rem;width:100%;text-align:left;"
          )
        ),
        shiny::hr(style = "border-color:#2a2a4a; margin:0.5rem 0;"),
        shiny::div(
          style = "padding:0.5rem 1rem; font-size:0.75rem; color:#8a8a9a;",
          "Built with ♥ by Antoine"
        )
      ),

      # ── Main panel ──────────────────────────────────────────────────────────
      shiny::div(
        class = "main-content-wrap",
        style = "padding: 1.5rem; background:#0d0d0d; min-height:100vh;",
        shiny::uiOutput("main_content")
      )
    ),

    # ── Mobile bottom nav bar ───────────────────────────────────────────────
    shiny::tags$nav(
      class = "mobile-bottom-nav",
      shiny::tags$button(
        id      = "mob_nav_dashboard",
        class   = "mob-nav-btn mob-active",
        onclick = "Shiny.setInputValue('nav_dashboard', Math.random());",
        shiny::tags$i(class = "bi bi-house-fill")
      ),
      shiny::tags$button(
        id      = "mob_nav_log",
        class   = "mob-nav-btn",
        onclick = "Shiny.setInputValue('nav_log', Math.random());",
        shiny::tags$i(class = "bi bi-pencil-square")
      ),
      shiny::tags$button(
        id      = "mob_nav_progress",
        class   = "mob-nav-btn",
        onclick = "Shiny.setInputValue('nav_progress', Math.random());",
        shiny::tags$i(class = "bi bi-graph-up-arrow")
      ),
      shiny::tags$button(
        id      = "mob_nav_goals",
        class   = "mob-nav-btn",
        onclick = "Shiny.setInputValue('nav_goals', Math.random());",
        shiny::tags$i(class = "bi bi-trophy-fill")
      )
    )
  )
}

#' Add external Resources to the Application
#' @importFrom golem add_resource_path favicon bundle_resources
#' @noRd
golem_add_external_resources <- function() {
  golem::add_resource_path("www", app_sys("app/www"))
  shiny::tags$head(
    golem::favicon(),
    golem::bundle_resources(
      path      = app_sys("app/www"),
      app_title = "Flo Fit"
    ),
    # Bootstrap Icons CDN (sidebar nav icons)
    shiny::tags$link(
      rel  = "stylesheet",
      href = "https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css"
    )
  )
}
