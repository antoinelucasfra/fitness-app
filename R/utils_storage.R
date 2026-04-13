#' Data storage helpers
#'
#' All data is stored as CSV files in a user-writable data directory.
#' This keeps the app portable and easy to back up.

#' @noRd
data_dir <- function() {
  d <- file.path(rappdirs::user_data_dir("fitnessapp", "fitnessapp"), "data")
  if (!dir.exists(d)) dir.create(d, recursive = TRUE, showWarnings = FALSE)
  d
}

# ── File paths ────────────────────────────────────────────────────────────────

#' @noRd
workouts_path <- function() file.path(data_dir(), "workouts.csv")

#' @noRd
bodycomp_path <- function() file.path(data_dir(), "bodycomp.csv")

#' @noRd
goals_path    <- function() file.path(data_dir(), "goals.csv")

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
  p <- workouts_path()
  if (!file.exists(p)) return(workouts_schema())
  df <- utils::read.csv(p, stringsAsFactors = FALSE, colClasses = c(date = "Date"))
  if (nrow(df) == 0) return(workouts_schema())
  df
}

#' @noRd
read_bodycomp <- function() {
  p <- bodycomp_path()
  if (!file.exists(p)) return(bodycomp_schema())
  df <- utils::read.csv(p, stringsAsFactors = FALSE, colClasses = c(date = "Date"))
  if (nrow(df) == 0) return(bodycomp_schema())
  df
}

#' @noRd
read_goals <- function() {
  p <- goals_path()
  if (!file.exists(p)) return(goals_schema())
  df <- utils::read.csv(p, stringsAsFactors = FALSE,
                        colClasses = c(created_at = "Date", target_date = "Date"))
  if (nrow(df) == 0) return(goals_schema())
  df$achieved <- as.logical(df$achieved)
  df
}

# ── Write ──────────────────────────────────────────────────────────────────────

#' @noRd
write_workouts <- function(df) {
  utils::write.csv(df, workouts_path(), row.names = FALSE)
}

#' @noRd
write_bodycomp <- function(df) {
  utils::write.csv(df, bodycomp_path(), row.names = FALSE)
}

#' @noRd
write_goals <- function(df) {
  utils::write.csv(df, goals_path(), row.names = FALSE)
}

# ── Plans (workout templates) ─────────────────────────────────────────────────

#' @noRd
plans_path <- function() file.path(data_dir(), "plans.csv")

#' @noRd
plan_exercises_path <- function() file.path(data_dir(), "plan_exercises.csv")

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
  p <- plans_path()
  if (!file.exists(p)) return(plans_schema())
  df <- utils::read.csv(p, stringsAsFactors = FALSE, colClasses = c(created_at = "Date"))
  if (nrow(df) == 0) return(plans_schema())
  df
}

#' @noRd
read_plan_exercises <- function() {
  p <- plan_exercises_path()
  if (!file.exists(p)) return(plan_exercises_schema())
  df <- utils::read.csv(p, stringsAsFactors = FALSE)
  if (nrow(df) == 0) return(plan_exercises_schema())
  df
}

#' @noRd
write_plans <- function(df) {
  utils::write.csv(df, plans_path(), row.names = FALSE)
}

#' @noRd
write_plan_exercises <- function(df) {
  utils::write.csv(df, plan_exercises_path(), row.names = FALSE)
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
