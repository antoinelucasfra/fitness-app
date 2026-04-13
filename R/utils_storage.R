#' Data storage helpers
#'
#' On Posit Connect (CONNECT_SERVER env var set): uses pins::board_connect()
#' for persistent storage that survives container restarts.
#' Locally: uses pins::board_folder() backed by rappdirs::user_data_dir().

#' @noRd
data_dir <- function() {
  d <- file.path(rappdirs::user_data_dir("fitnessapp", "fitnessapp"), "data")
  if (!dir.exists(d)) dir.create(d, recursive = TRUE, showWarnings = FALSE)
  d
}

#' Return the appropriate pins board based on environment.
#' @noRd
get_board <- function() {
  if (nzchar(Sys.getenv("CONNECT_SERVER"))) {
    pins::board_connect()
  } else {
    pins::board_folder(data_dir())
  }
}

#' Read a pin, returning `default` if it doesn't exist yet.
#' @noRd
pin_read_safe <- function(board, name, default) {
  if (name %in% pins::pin_list(board)) {
    pins::pin_read(board, name)
  } else {
    default
  }
}

# ── Column schemas ─────────────────────────────────────────────────────────────

workouts_schema <- function() {
  data.frame(
    id          = character(),
    date        = as.Date(character()),
    type        = character(),   # "strength" | "cardio"
    exercise    = character(),
    sets        = integer(),
    reps        = integer(),
    weight_kg   = numeric(),
    duration_min = numeric(),
    distance_km = numeric(),
    notes       = character(),
    stringsAsFactors = FALSE
  )
}

bodycomp_schema <- function() {
  data.frame(
    id          = character(),
    date        = as.Date(character()),
    weight_kg   = numeric(),
    bodyfat_pct = numeric(),
    notes       = character(),
    stringsAsFactors = FALSE
  )
}

goals_schema <- function() {
  data.frame(
    id          = character(),
    name        = character(),
    category    = character(),   # "strength" | "cardio" | "body" | "consistency"
    target      = numeric(),
    unit        = character(),
    current     = numeric(),
    created_at  = as.Date(character()),
    target_date = as.Date(character()),
    achieved    = logical(),
    stringsAsFactors = FALSE
  )
}

# ── Read ───────────────────────────────────────────────────────────────────────

#' @noRd
read_workouts <- function() {
  df <- pin_read_safe(get_board(), "workouts", workouts_schema())
  if (nrow(df) == 0) return(workouts_schema())
  df$date <- as.Date(df$date)
  df
}

#' @noRd
read_bodycomp <- function() {
  df <- pin_read_safe(get_board(), "bodycomp", bodycomp_schema())
  if (nrow(df) == 0) return(bodycomp_schema())
  df$date <- as.Date(df$date)
  df
}

#' @noRd
read_goals <- function() {
  df <- pin_read_safe(get_board(), "goals", goals_schema())
  if (nrow(df) == 0) return(goals_schema())
  df$created_at  <- as.Date(df$created_at)
  df$target_date <- as.Date(df$target_date)
  df$achieved    <- as.logical(df$achieved)
  df
}

# ── Write ──────────────────────────────────────────────────────────────────────

#' @noRd
write_workouts <- function(df) {
  pins::pin_write(get_board(), df, name = "workouts", type = "csv", versioned = FALSE)
}

#' @noRd
write_bodycomp <- function(df) {
  pins::pin_write(get_board(), df, name = "bodycomp", type = "csv", versioned = FALSE)
}

#' @noRd
write_goals <- function(df) {
  pins::pin_write(get_board(), df, name = "goals", type = "csv", versioned = FALSE)
}

# ── Plans (workout templates) ─────────────────────────────────────────────────

plans_schema <- function() {
  data.frame(
    id         = character(),
    name       = character(),
    created_at = as.Date(character()),
    stringsAsFactors = FALSE
  )
}

plan_exercises_schema <- function() {
  data.frame(
    id           = character(),
    plan_id      = character(),
    exercise     = character(),
    type         = character(),   # "strength" | "cardio"
    sets         = integer(),
    reps         = integer(),
    weight_kg    = numeric(),
    duration_min = numeric(),
    distance_km  = numeric(),
    order_idx    = integer(),
    stringsAsFactors = FALSE
  )
}

#' @noRd
read_plans <- function() {
  df <- pin_read_safe(get_board(), "plans", plans_schema())
  if (nrow(df) == 0) return(plans_schema())
  df$created_at <- as.Date(df$created_at)
  df
}

#' @noRd
read_plan_exercises <- function() {
  df <- pin_read_safe(get_board(), "plan_exercises", plan_exercises_schema())
  if (nrow(df) == 0) return(plan_exercises_schema())
  df
}

#' @noRd
write_plans <- function(df) {
  pins::pin_write(get_board(), df, name = "plans", type = "csv", versioned = FALSE)
}

#' @noRd
write_plan_exercises <- function(df) {
  pins::pin_write(get_board(), df, name = "plan_exercises", type = "csv", versioned = FALSE)
}

# ── Helpers ────────────────────────────────────────────────────────────────────

#' Generate a simple unique ID
#' @noRd
new_id <- function() {
  paste0(format(Sys.time(), "%Y%m%d%H%M%S"), sample(1000:9999, 1))
}

#' Compute current workout streak (consecutive days with at least 1 session)
#' @noRd
compute_streak <- function(workouts) {
  if (nrow(workouts) == 0) return(0L)
  dates <- sort(unique(as.Date(workouts$date)), decreasing = TRUE)
  today <- Sys.Date()
  streak <- 0L
  expected <- today
  for (d in dates) {
    d <- as.Date(d)
    if (d == expected || d == expected - 1) {
      streak <- streak + 1L
      expected <- d - 1
    } else if (d < expected - 1) {
      break
    }
  }
  streak
}

#' Motivational quotes
#' @noRd
motivation_quotes <- function() {
  list(
    list(text = "Strong is the new beautiful.", author = "Unknown"),
    list(text = "You don't have to be extreme, just consistent.", author = "Unknown"),
    list(text = "The only bad workout is the one that didn't happen.", author = "Unknown"),
    list(text = "Push yourself because no one else is going to do it for you.", author = "Unknown"),
    list(text = "Your body can stand almost anything. It's your mind you have to convince.", author = "Unknown"),
    list(text = "Success starts with self-discipline.", author = "Unknown"),
    list(text = "Fall in love with taking care of your body.", author = "Unknown"),
    list(text = "Wake up. Work out. Look hot. Kick ass.", author = "Unknown"),
    list(text = "Train hard, eat right, and believe in yourself.", author = "Unknown"),
    list(text = "A little progress each day adds up to big results.", author = "Unknown"),
    list(text = "Believe in yourself and all that you are.", author = "Christian D. Larson"),
    list(text = "The pain you feel today will be the strength you feel tomorrow.", author = "Unknown"),
    list(text = "No matter how slow you go, you are still lapping everyone on the couch.", author = "Unknown"),
    list(text = "It never gets easier, you just get stronger.", author = "Unknown"),
    list(text = "She believed she could, so she did.", author = "R.S. Grey")
  )
}

#' Pick today's quote (deterministic per day)
#' @noRd
todays_quote <- function() {
  quotes <- motivation_quotes()
  idx <- (as.integer(Sys.Date()) %% length(quotes)) + 1L
  quotes[[idx]]
}
