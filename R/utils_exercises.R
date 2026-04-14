#' Exercise information lookup
#'
#' Data sourced from the free-exercise-db (github.com/yuhonas/free-exercise-db)
#' Images: https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/{id}/{0|1}.jpg

.exercise_db_base <- "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises"

.exercise_lookup <- list(
  "Squat" = list(
    db_id   = "Barbell_Squat",
    muscles = c("quadriceps", "glutes", "hamstrings", "lower back"),
    steps   = c(
      "Set the bar in a squat rack just below shoulder level. Step under the bar and place it across the back of your shoulders (below the neck).",
      "Lift the bar off the rack, step back and stand with feet shoulder-width apart, toes slightly out. Keep your head and chest up.",
      "Bend your knees and hips to lower until your thighs are parallel to the floor (or slightly below). Inhale as you descend.",
      "Drive through your heels to return to standing. Exhale as you rise. Repeat."
    )
  ),
  "Deadlift" = list(
    db_id   = "Barbell_Deadlift",
    muscles = c("lower back", "glutes", "hamstrings", "lats", "traps"),
    steps   = c(
      "Stand with feet hip-width apart, bar over mid-foot. Bend at the hips and knees, grip the bar at shoulder width with an overhand grip.",
      "Keep your back flat, chest up, and hips lower than your shoulders. This is the starting position.",
      "Push through the floor with your legs while simultaneously extending your hips to stand up straight. Keep the bar close to your body throughout.",
      "Lower the bar back to the floor by reversing the movement. Repeat."
    )
  ),
  "Bench Press" = list(
    db_id   = "Barbell_Bench_Press_-_Medium_Grip",
    muscles = c("chest", "shoulders", "triceps"),
    steps   = c(
      "Lie on a flat bench, grip the bar slightly wider than shoulder-width (palms facing forward). Unrack the bar and hold it directly over your chest with arms straight.",
      "Inhale and slowly lower the bar to your mid-chest in a controlled manner.",
      "Exhale and press the bar back up to the starting position, squeezing your chest at the top.",
      "Repeat for the prescribed repetitions, then re-rack the bar."
    )
  ),
  "Overhead Press" = list(
    db_id   = "Standing_Military_Press",
    muscles = c("shoulders", "triceps"),
    steps   = c(
      "Stand with feet shoulder-width apart. Hold the bar at collar-bone level with an overhand grip slightly wider than shoulder-width.",
      "Press the bar directly overhead until arms are fully extended. Keep your core tight and avoid leaning back excessively.",
      "Slowly lower the bar back to collar-bone level. Inhale on the way down, exhale on the way up.",
      "Repeat for the prescribed repetitions."
    )
  ),
  "Hip Thrust" = list(
    db_id   = "Barbell_Hip_Thrust",
    muscles = c("glutes", "hamstrings"),
    steps   = c(
      "Sit on the floor with your upper back against a bench. Roll a padded barbell over your hips.",
      "Plant your feet flat on the floor, hip-width apart. Drive through your heels, extending your hips upward until your body forms a straight line from shoulders to knees.",
      "Squeeze your glutes hard at the top, then lower your hips back toward the floor. Keep the bar stable throughout.",
      "Repeat for the prescribed repetitions."
    )
  ),
  "Leg Press" = list(
    db_id   = "Leg_Press",
    muscles = c("quadriceps", "glutes", "hamstrings"),
    steps   = c(
      "Sit on the leg press machine and place your feet on the platform at shoulder-width, toes slightly out. Release the safety handles.",
      "Lower the platform by bending your knees until they form a 90-degree angle. Inhale as you lower.",
      "Push through your heels to straighten your legs back to the starting position. Do not lock out your knees at the top.",
      "Repeat, then re-engage the safety handles when finished."
    )
  ),
  "Lunges" = list(
    db_id   = "Dumbbell_Lunges",
    muscles = c("quadriceps", "glutes", "hamstrings"),
    steps   = c(
      "Stand tall holding dumbbells at your sides (or hands on hips). Keep your torso upright.",
      "Step forward about 2 feet with your right leg and lower your body until your right thigh is parallel to the floor and your left knee nearly touches the ground. Inhale as you lower.",
      "Push through the heel of your right foot to return to the starting position. Exhale as you rise.",
      "Alternate legs for the prescribed repetitions."
    )
  ),
  "Romanian Deadlift" = list(
    db_id   = "Romanian_Deadlift",
    muscles = c("hamstrings", "glutes", "lower back"),
    steps   = c(
      "Stand holding a barbell in front of your thighs with an overhand grip at shoulder width. Feet hip-width apart, slight bend in the knees.",
      "Hinge at the hips, pushing them back while lowering the bar along your legs. Keep your back flat and chest up. Inhale as you lower.",
      "Lower until you feel a deep stretch in your hamstrings (typically mid-shin level), then drive your hips forward to return to standing. Exhale as you rise.",
      "Repeat for the prescribed repetitions."
    )
  ),
  "Lat Pulldown" = list(
    db_id   = "Wide-Grip_Lat_Pulldown",
    muscles = c("lats", "biceps", "middle back"),
    steps   = c(
      "Sit at a lat pulldown machine and secure your knees under the pads. Grab the bar with a wide overhand grip.",
      "Lean back slightly and create a slight arch in your lower back. This is the starting position.",
      "Pull the bar down to your upper chest by driving your elbows down and back. Squeeze your shoulder blades together at the bottom. Exhale.",
      "Slowly let the bar rise back to the starting position with arms fully extended. Inhale. Repeat."
    )
  ),
  "Seated Row" = list(
    db_id   = "Seated_Cable_Rows",
    muscles = c("middle back", "lats", "biceps"),
    steps   = c(
      "Sit on the cable row machine with feet on the platform, knees slightly bent. Grab the V-bar handle and straighten your torso to 90 degrees. This is the starting position.",
      "Keeping your torso still, pull the handle toward your abdomen by retracting your shoulder blades and bending your elbows. Exhale as you pull.",
      "Hold the contraction for a second, squeezing your back muscles, then slowly extend your arms back to the starting position. Inhale.",
      "Repeat for the prescribed repetitions."
    )
  ),
  "Bicep Curl" = list(
    db_id   = "Dumbbell_Bicep_Curl",
    muscles = c("biceps", "forearms"),
    steps   = c(
      "Stand upright holding a dumbbell in each hand at arm's length, palms facing forward. Keep elbows close to your torso.",
      "Curl the dumbbells upward by contracting your biceps until the dumbbells are at shoulder level. Exhale as you lift. Keep upper arms stationary.",
      "Hold the contraction briefly at the top, then slowly lower the dumbbells back to the starting position. Inhale.",
      "Repeat for the prescribed repetitions."
    )
  ),
  "Tricep Pushdown" = list(
    db_id   = "Triceps_Pushdown",
    muscles = c("triceps"),
    steps   = c(
      "Attach a bar to a high pulley. Grab with an overhand grip at shoulder-width. Stand upright with a slight forward lean, upper arms close to your body and perpendicular to the floor.",
      "Push the bar down until your arms are fully extended and the bar touches your thighs. Keep upper arms stationary. Exhale as you push down.",
      "Slowly return the bar to the starting position (forearms parallel to floor). Inhale.",
      "Repeat for the prescribed repetitions."
    )
  ),
  "Glute Kickback" = list(
    db_id   = "Glute_Kickback",
    muscles = c("glutes", "hamstrings"),
    steps   = c(
      "Start on all fours on a mat: hands under shoulders, knees under hips. Keep your back flat and core engaged.",
      "Keeping the 90-degree angle at the knee, raise your right leg back and up until your thigh is parallel to the floor. Squeeze your glute at the top. Exhale.",
      "Lower your knee back to the starting position without letting it touch the floor. Inhale.",
      "Complete all reps on one side before switching to the other leg."
    )
  ),
  "Cable Crunch" = list(
    db_id   = "Cable_Crunch",
    muscles = c("abdominals"),
    steps   = c(
      "Kneel below a high pulley with a rope attachment. Grab the rope and hold it beside your face. Hips are fixed throughout the movement.",
      "Exhale and crunch downward by rounding your spine, bringing your elbows toward your knees. Keep your hips stationary — only your torso moves.",
      "Hold the contraction for a second, then slowly return to the starting position. Inhale.",
      "Repeat for the prescribed repetitions."
    )
  ),
  "Plank" = list(
    db_id   = "Plank",
    muscles = c("abdominals", "lower back", "shoulders"),
    steps   = c(
      "Lie face down and support your body on your forearms and toes. Arms are bent directly below the shoulders.",
      "Keep your body in a straight line from head to heels — no sagging hips or raised backside. Breathe steadily.",
      "Hold the position for the prescribed duration, keeping your core braced and glutes squeezed."
    )
  ),
  "Running" = list(
    db_id   = "Running_Treadmill",
    muscles = c("quadriceps", "calves", "glutes", "hamstrings"),
    steps   = c(
      "Step onto the treadmill and set your desired speed and incline.",
      "Run with an upright posture, swinging your arms naturally. Land mid-foot and push off through your toes.",
      "Maintain a comfortable pace and consistent breathing. Adjust speed or incline as needed during the session."
    )
  ),
  "Treadmill" = list(
    db_id   = "Running_Treadmill",
    muscles = c("quadriceps", "calves", "glutes", "hamstrings"),
    steps   = c(
      "Step onto the treadmill and set your desired speed and incline.",
      "Run with an upright posture, swinging your arms naturally. Land mid-foot and push off through your toes.",
      "Maintain a comfortable pace and consistent breathing. Adjust speed or incline as needed during the session."
    )
  ),
  "Cycling" = list(
    db_id   = "Bicycling",
    muscles = c("quadriceps", "calves", "glutes", "hamstrings"),
    steps   = c(
      "Adjust the seat height so your leg is almost fully extended at the bottom of the pedal stroke.",
      "Begin pedaling at a steady cadence. Keep your back straight and grip the handlebars lightly.",
      "Maintain consistent effort throughout the session. Adjust resistance as needed."
    )
  ),
  "Stationary Bike" = list(
    db_id   = "Bicycling_Stationary",
    muscles = c("quadriceps", "calves", "glutes", "hamstrings"),
    steps   = c(
      "Sit on the bike and adjust the seat to your height so your leg is nearly straight at the bottom of the pedal stroke.",
      "Select your program or resistance level. Begin pedaling at an even cadence.",
      "Maintain an upright posture, engage your core, and breathe steadily. Increase resistance to intensify the workout."
    )
  ),
  "Elliptical" = list(
    db_id   = NULL,
    muscles = c("quadriceps", "glutes", "calves", "shoulders"),
    steps   = c(
      "Step onto the elliptical and grip the moving handles. Set resistance and incline to your preference.",
      "Push and pull the handles while driving the pedals in an elliptical motion. Keep your back straight and core tight.",
      "Maintain a smooth, continuous stride. Adjust resistance to control intensity."
    )
  ),
  "Rowing Machine" = list(
    db_id   = NULL,
    muscles = c("middle back", "lats", "biceps", "quadriceps"),
    steps   = c(
      "Sit on the rower, strap your feet in. Grab the handle with an overhand grip. Start with knees bent and arms extended (catch position).",
      "Drive through your legs first to straighten them, then lean back slightly and pull the handle to your lower ribs. Exhale.",
      "Reverse the motion: extend arms, lean forward, then bend knees to return to the catch. Inhale.",
      "Repeat at a consistent, controlled stroke rate."
    )
  ),
  "Jump Rope" = list(
    db_id   = NULL,
    muscles = c("calves", "quadriceps", "shoulders"),
    steps   = c(
      "Hold a jump rope handle in each hand with the rope behind you.",
      "Swing the rope overhead and jump over it as it passes under your feet. Land softly on the balls of your feet.",
      "Maintain a steady rhythm. Keep elbows close to your body and use your wrists to turn the rope."
    )
  ),
  "Stairmaster" = list(
    db_id   = NULL,
    muscles = c("glutes", "quadriceps", "calves", "hamstrings"),
    steps   = c(
      "Step onto the Stairmaster and select your desired speed and program.",
      "Step up continuously, placing your full foot on each step. Keep your torso upright and avoid leaning heavily on the handrails.",
      "Maintain a steady pace for the duration of your workout."
    )
  ),
  "Swimming" = list(
    db_id   = NULL,
    muscles = c("shoulders", "lats", "chest", "quadriceps"),
    steps   = c(
      "Enter the pool and choose your stroke (freestyle, breaststroke, backstroke, etc.).",
      "Coordinate arm pulls, leg kicks, and breathing to maintain efficient form.",
      "Swim at a pace that challenges you while allowing controlled breathing for the prescribed distance or time."
    )
  ),
  "HIIT" = list(
    db_id   = NULL,
    muscles = c("full body"),
    steps   = c(
      "Choose a set of high-intensity exercises (e.g. burpees, jump squats, sprints). Set a work-to-rest ratio (e.g. 40s on / 20s off).",
      "Perform each exercise at maximum effort during the work interval.",
      "Rest fully during the rest interval, then repeat the circuit for the prescribed number of rounds."
    )
  )
)

# ── Helpers ───────────────────────────────────────────────────────────────────

#' Look up exercise info by app name
#' @param name Exercise name as stored in the app
#' @return list with db_id, muscles, steps or NULL
#' @noRd
exercise_info <- function(name) {
  .exercise_lookup[[name]]
}

#' CDN URL for an exercise image from free-exercise-db
#' @param db_id Exercise DB ID
#' @param pos 0 (start position) or 1 (end position)
#' @noRd
exercise_img_url <- function(db_id, pos = 0L) {
  paste0(.exercise_db_base, "/", db_id, "/", pos, ".jpg")
}

#' Show a Shiny modal with exercise info, images, and instructions
#' @param name Exercise name (app name)
#' @param session Shiny session object
#' @noRd
show_exercise_modal <- function(name, session) {
  info <- exercise_info(name)

  if (is.null(info)) {
    shiny::showModal(shiny::modalDialog(
      title = name,
      shiny::p(style = "color:#8a8a9a;", "No detailed information available for this exercise."),
      footer = shiny::modalButton("Close"),
      easyClose = TRUE
    ), session = session)
    return(invisible(NULL))
  }

  muscle_badges <- lapply(info$muscles, function(m) {
    shiny::span(
      class = "badge me-1 mb-1",
      style = "background:#1a2a4a; color:#e94560; border:1px solid #e94560; font-size:0.75rem;",
      m
    )
  })

  steps_items <- lapply(seq_along(info$steps), function(i) {
    shiny::tags$li(
      style = "margin-bottom:0.5rem; color:#c8c8d8;",
      info$steps[[i]]
    )
  })

  img_section <- if (!is.null(info$db_id)) {
    shiny::div(
      style = "display:flex; gap:0.75rem; margin-bottom:1.25rem;",
      shiny::div(style = "flex:1; text-align:center;",
        shiny::tags$img(
          src   = exercise_img_url(info$db_id, 0L),
          style = "width:100%; border-radius:8px; border:1px solid #2a2a4a;",
          alt   = paste(name, "- start position")
        ),
        shiny::div(style = "font-size:0.72rem; color:#8a8a9a; margin-top:0.25rem;", "Start")
      ),
      shiny::div(style = "flex:1; text-align:center;",
        shiny::tags$img(
          src   = exercise_img_url(info$db_id, 1L),
          style = "width:100%; border-radius:8px; border:1px solid #2a2a4a;",
          alt   = paste(name, "- end position")
        ),
        shiny::div(style = "font-size:0.72rem; color:#8a8a9a; margin-top:0.25rem;", "End")
      )
    )
  } else NULL

  shiny::showModal(shiny::modalDialog(
    title = shiny::div(
      shiny::strong(name, style = "font-size:1.1rem;"),
      shiny::br(),
      shiny::div(style = "margin-top:0.35rem;", muscle_badges)
    ),
    img_section,
    shiny::tags$ol(style = "padding-left:1.2rem; margin:0;", steps_items),
    shiny::div(
      style = "margin-top:1rem; font-size:0.72rem; color:#8a8a9a;",
      "Source: ",
      shiny::tags$a(
        href   = "https://github.com/yuhonas/free-exercise-db",
        target = "_blank",
        style  = "color:#8a8a9a;",
        "free-exercise-db"
      )
    ),
    footer = shiny::modalButton("Close"),
    easyClose = TRUE,
    size = "m"
  ), session = session)
}
