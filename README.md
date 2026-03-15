# fitness-app 💪

A personal fitness tracking app with a dark, motivating design.
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

# 3. Set the shared app password
Sys.setenv(FITNESS_APP_PASSWORD = "choose-a-password")

# 4. Launch
fitnessapp::run_app()
```

App opens at `http://127.0.0.1:PORT` in your browser.

---

## Authentication

The app now requires a shared password before the main UI is shown.

- Runtime variable: `FITNESS_APP_PASSWORD`
- The password is checked per browser session
- No password is stored in the repository

If `FITNESS_APP_PASSWORD` is missing, the app stays locked and shows a configuration message instead of the dashboard.

For Posit Connect Cloud, configure `FITNESS_APP_PASSWORD` as an environment variable in the deployed app settings.

---

## CI/CD

GitHub Actions now handles both validation and deployment:

- `.github/workflows/ci.yaml` runs on pull requests to `main`, feature-branch pushes, and manual dispatches. It restores the `renv` environment and runs `devtools::check()`.
- `.github/workflows/deploy.yaml` runs on pushes to `main` and manual dispatches. It reruns the package checks, generates a deployment manifest, and publishes to the existing Posit Connect Cloud app.

### Required GitHub secret

Add this repository secret before enabling deployment:

- `POSIT_CONNECT_API_KEY`: an API key generated from your Posit Connect Cloud account

### Deployment behavior

- Production deploys target the existing Connect Cloud content ID `019c8665-051b-8cb9-da1b-d7af46a012ac`
- Only one production deployment runs at a time
- The workflow assumes the current Posit Connect Cloud target remains the production host
- Production access also requires the `FITNESS_APP_PASSWORD` environment variable to be set in Connect Cloud

Because app data is stored as local CSV files with `rappdirs::user_data_dir()`, CI/CD only automates code delivery. It does not manage server-side backups or data migration.

---

## Deploy to Posit Connect Cloud

```r
rsconnect::deployApp(
  appName     = "fitness-app",
  appTitle    = "fitness-app",
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
