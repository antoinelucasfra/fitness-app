# How to Deploy — fitness-app

## Current method: Posit Connect Cloud (rsconnect)

**Prerequisites:** `rsconnect` account already configured for `connect.posit.cloud`.

```r
rsconnect::deployApp(
  appName  = "fitness-app",
  appTitle = "fitness-app",
  appFiles = c("R/", "inst/", "NAMESPACE", "DESCRIPTION", "app.R", "renv.lock"),
  appId    = rsconnect::deployments(".")$appID,
  lint     = FALSE,
  forceUpdate = TRUE
)
```

Live URL: `https://connect.posit.cloud/antoinelucasfra/content/019c8665-051b-8cb9-da1b-d7af46a012ac`

**Data persistence:** handled automatically via `pins::board_connect()` — no manual API key needed, Connect injects `CONNECT_API_KEY` + `CONNECT_SERVER` at runtime.

---

## First-time setup (one-off)

```r
# 1. Register your Connect account
rsconnect::setAccountInfo(
  name   = "antoinelucasfra",
  server = "connect.posit.cloud"
  # follow prompts for token/secret
)

# 2. Update manifest (for Git-backed deploys)
rsconnect::writeManifest()
```

---

## Other deployment options

### Git-backed deployment (Posit Connect)
Push to GitHub → Connect auto-deploys on each commit.
Requires a `manifest.json` at repo root (`rsconnect::writeManifest()`), then link the repo in Connect dashboard under **Info → Git**.
