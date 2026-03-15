#' The application User-Interface
#' @param request Internal parameter for `{shiny}`.
#' @noRd
app_ui <- function(request) {
  shiny::tagList(
    golem_add_external_resources(),
    shiny::tags$head(
      shiny::tags$meta(name = "viewport",
                       content = "width=device-width, initial-scale=1.0"),
      shinyjs::useShinyjs()
    ),
    shiny::uiOutput("app_view")
  )
}

app_theme <- function() {
  bslib::bs_theme(
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
  )
}

app_login_ui <- function(configured = TRUE, auth_error = NULL) {
  login_feedback <- if (!configured) {
    bslib::card(
      full_screen = FALSE,
      class = "border-danger-subtle bg-danger-subtle text-danger-emphasis mt-3",
      bslib::card_body(
        shiny::tags$strong("Authentication is not configured."),
        shiny::tags$p(
          class = "mb-0 mt-2",
          "Set the FITNESS_APP_PASSWORD environment variable before launching the app."
        )
      )
    )
  } else if (!is.null(auth_error) && nzchar(auth_error)) {
    bslib::card(
      full_screen = FALSE,
      class = "border-danger-subtle bg-danger-subtle text-danger-emphasis mt-3",
      bslib::card_body(auth_error)
    )
  }

  bslib::page_fillable(
    theme = app_theme(),
    fillable_mobile = TRUE,
    gap = 0,
    shiny::div(
      class = "d-flex align-items-center justify-content-center",
      style = "min-height:100vh; padding:1.5rem; background:linear-gradient(180deg,#0d0d0d 0%,#16213e 100%);",
      bslib::card(
        class = "shadow-lg border-0",
        style = "width:min(100%, 420px);",
        bslib::card_header(
          shiny::div(
            class = "d-flex align-items-center gap-2",
            shiny::tags$i(class = "bi bi-shield-lock-fill"),
            shiny::tags$span(class = "fw-semibold", "fitness-app access")
          )
        ),
        bslib::card_body(
          shiny::tags$h2(class = "h4 mb-2", "Sign in"),
          shiny::tags$p(
            class = "text-body-secondary mb-4",
            "Enter the shared password to open the app."
          ),
          shiny::passwordInput("auth_password", "Password", width = "100%"),
          shiny::actionButton(
            "auth_submit",
            "Enter app",
            class = "btn btn-primary w-100"
          ),
          login_feedback
        )
      )
    )
  )
}

app_main_ui <- function() {
  bslib::page_sidebar(
    title = shiny::div(
      style = "display:flex; align-items:center; gap:0.6rem;",
      shiny::span(
        style = "font-weight:800; font-size:1.15rem; color:#e8e8e8;",
        "fitness-app"
      )
    ),
    theme = app_theme(),
    sidebar = bslib::sidebar(
      width = 230,
      style = "background:#16213e; border-right:1px solid #2a2a4a;",
      shiny::br(),
      shiny::div(
        style = "padding:0.8rem 1rem; margin-bottom:0.5rem;",
        shiny::div(
          style = "text-align:center; font-weight:700; color:#e8e8e8; font-size:0.95rem;",
          "Welcome back"
        ),
        shiny::div(
          style = "text-align:center; font-size:0.78rem; color:#8a8a9a; margin-top:2px;",
          shiny::textOutput("sidebar_streak_label", inline = TRUE)
        )
      ),
      shiny::hr(style = "border-color:#2a2a4a; margin:0.5rem 0;"),
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
      shiny::actionButton(
        "logout_btn",
        shiny::div(
          shiny::tags$i(class = "bi bi-box-arrow-right me-2"),
          "Lock app"
        ),
        class = "btn btn-outline-light w-100"
      ),
      shiny::div(
        style = "padding:0.75rem 0 0.5rem; font-size:0.75rem; color:#8a8a9a;",
        "Built by Antoine"
      )
    ),
    shiny::div(
      class = "main-content-wrap",
      style = "padding:1.5rem; background:#0d0d0d; min-height:100vh;",
      shiny::uiOutput("main_content")
    ),
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
      app_title = "fitness-app"
    ),
    # Bootstrap Icons CDN (sidebar nav icons)
    shiny::tags$link(
      rel  = "stylesheet",
      href = "https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css"
    )
  )
}
