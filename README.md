# Flo Fit 💪

A personal fitness tracking app built for Florence — dark, moody, and motivating.
Log workouts, track strength & cardio progress, set goals, and celebrate streaks.

**Live app:** https://connect.posit.cloud/antoinelucasfra/content/019c8665-051b-8cb9-da1b-d7af46a012ac

---

## Features

| | |
|---|---|
| 🔥 **Dashboard** | Streak counter, motivational quote, activity heatmap, achievement badges |
| 📝 **Workout Log** | Session builder for strength (sets × reps × kg) and cardio (duration, distance) |
| 📈 **Progress** | Strength PRs, cardio trends, body composition charts, weekly volume overview |
| 🎯 **Goals** | Set targets with deadlines, track progress bars, celebrate achievements |

Mobile-first responsive design — works on phone, tablet and desktop.

---

## Tech stack

| Layer | Package |
|---|---|
| App framework | [`golem`](https://thinkr-open.github.io/golem/) + `shiny` |
| UI / theme | `bslib` (Bootstrap 5, dark theme) + custom CSS |
| Charts | `plotly` |
| Tables | `DT` |
| Dependency management | `renv` |
| Data persistence | Local CSV via `rappdirs::user_data_dir()` |

---

## Run locally

```r
# 1. Restore R dependencies (first time only)
renv::restore()

# 2. Install the package
devtools::install()

# 3. Launch
fitnessapp::run_app()
```

App opens at `http://127.0.0.1:PORT` in your browser.

---

## Deploy to Posit Connect Cloud

```r
rsconnect::deployApp(
  appName     = "flo-fit",
  appTitle    = "Flo Fit",
  account     = "antoinelucasfra",
  server      = "connect.posit.cloud",
  lint        = FALSE,
  forceUpdate = TRUE
)
```

---

## Project structure

```
fitness-app/
├── R/
│   ├── app_ui.R          # Main UI shell + bottom nav bar
│   ├── app_server.R      # Navigation state + module wiring
│   ├── mod_dashboard.R   # Dashboard module
│   ├── mod_workout_log.R # Workout logging module
│   ├── mod_progress.R    # Progress charts module
│   ├── mod_goals.R       # Goals module
│   └── utils_storage.R   # CSV read/write helpers, streak, quotes
├── inst/app/www/
│   └── custom.css        # Dark theme + mobile responsive styles
├── app.R                 # Posit Connect entry point
├── DESCRIPTION
└── renv.lock
```

---

## Data storage

All data is stored as CSV files on the host machine:

```
rappdirs::user_data_dir("fitnessapp")/
├── workouts.csv
├── bodycomp.csv
└── goals.csv
```

No database or external service required. Data persists between sessions.

---

*Built with ♥ by Antoine*
