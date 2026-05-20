################################################################################
# SAKHA95 CALIBRATION - FINAL CORRECTED VERSION
# Key fixes:
# 1. Uses "Sakha95" (VRNAME) instead of "SK0010" (VAR-NAME)
# 2. Proper error handling
# 3. Direct nloptr optimization (bypasses CroptimizR bugs)
# 4. Works with .WHA observations only
################################################################################

cat("\n")
cat("╔═══════════════════════════════════════════════════════════════╗\n")
cat("║  SAKHA95 CALIBRATION - FINAL CORRECTED VERSION              ║\n")
cat("║  Using VRNAME instead of VAR-NAME for cultivar              ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

################################################################################
# SETUP
################################################################################

cat("Step 1: Setup...\n")

# Install/load packages
if (!require("nloptr", quietly = TRUE)) {
  install.packages("nloptr")
}
library(nloptr, quietly = TRUE)
library(dplyr, quietly = TRUE)

setwd("D:/HourlyHDW/Calibrationwthfiles/DSSATWrapper")

# Load DSSAT functions
if (file.exists("R/DSSAT_wrapper.R")) {
  source("R/DSSAT_wrapper.R", verbose = FALSE)
  source("R/read_obs.R", verbose = FALSE)
} else {
  source("DSSAT_wrapper.R", verbose = FALSE)
}

cat("✓ Setup complete\n\n")

################################################################################
# MODEL OPTIONS - KEY FIX!
################################################################################

cat("Step 2: Model options (CORRECTED)...\n")

model_options <- list(
  DSSAT_path = 'C:/DSSAT48',
  DSSAT_exe = 'DSCSM048.EXE',
  Crop = "Wheat",
  ecotype_filename = "WHCER048.ECO",
  cultivar_filename = "WHCER048.CUL",
  ecotype = "CAWH01",
  cultivar = "Sakha95",  # ← KEY FIX: Use VRNAME not VAR-NAME!
  suppress_output = TRUE
)

cat("  ⭐ Cultivar: Sakha95 (using VRNAME)\n")
cat("  ⭐ Ecotype: CAWH01\n\n")

################################################################################
# TEST WITH ONE SITUATION FIRST
################################################################################

cat("Step 3: Testing with one situation first...\n")

test_params <- c(P1V=16, P1D=74.6, P5=660, G1=47, G2=80, G3=0.8, PHINT=131)

test_result <- tryCatch({
  DSSAT_wrapper(
    param_values = test_params,
    model_options = model_options,
    situation = "GMZA2001_1"
  )
}, error = function(e) {
  cat("  ❌ Error:", as.character(e), "\n")
  return(list(error = TRUE, message = as.character(e)))
})

if (test_result$error) {
  cat("\n  ⚠ Test simulation failed!\n")
  cat("  Error:", test_result$message, "\n\n")
  
  cat("  Trying alternative: Use VAR-NAME (SK0010) directly...\n")
  
  # Try with SK0010
  model_options$cultivar <- "SK0010"
  
  test_result2 <- tryCatch({
    DSSAT_wrapper(
      param_values = test_params,
      model_options = model_options,
      situation = "GMZA2001_1"
    )
  }, error = function(e) {
    list(error = TRUE, message = as.character(e))
  })
  
  if (!test_result2$error) {
    cat("  ✓ Success with SK0010!\n\n")
    test_result <- test_result2
  } else {
    cat("  ⚠ Still failing. Trying standard DSSAT cultivar...\n")
    
    # Try with NEWTON (standard DSSAT cultivar)
    model_options$cultivar <- "NEWTON"
    model_options$ecotype <- "USWH01"
    
    test_result3 <- tryCatch({
      DSSAT_wrapper(
        param_values = test_params,
        model_options = model_options,
        situation = "GMZA2001_1"
      )
    }, error = function(e) {
      list(error = TRUE, message = as.character(e))
    })
    
    if (!test_result3$error) {
      cat("  ✓ Success with NEWTON!\n")
      cat("  ⚠ NOTE: Using NEWTON cultivar as placeholder\n")
      cat("     You'll need to update SK0010 parameters after calibration\n\n")
      test_result <- test_result3
    } else {
      cat("\n  ❌ All cultivar options failed!\n\n")
      cat("  Please check:\n")
      cat("    1. WHCER048.CUL file format\n")
      cat("    2. Cultivar and ecotype codes\n")
      cat("    3. File permissions\n\n")
      stop("Cannot proceed - cultivar recognition failed")
    }
  }
} else {
  cat("  ✓ Test successful!\n\n")
}

cat("  Using cultivar:", model_options$cultivar, "\n")
cat("  Using ecotype:", model_options$ecotype, "\n\n")

################################################################################
# LOAD OBSERVATIONS
################################################################################

cat("Step 4: Loading observations...\n")

# All 50 situations
situation_names <- c(
  paste0("GMZA2001_", 1:23),
  paste0("SIDS2001_", 1:27)
)

obs_list <- read_obs(
  model_options = model_options,
  situation = situation_names,
  read_end_season = TRUE
)

cat("  ✓ Loaded", length(obs_list), "situations\n\n")

################################################################################
# PARAMETERS
################################################################################

cat("Step 5: Parameters...\n")

param_names <- c("P1V", "P1D", "P5", "G1", "G2", "G3", "PHINT")

initial_values <- c(16, 74.6, 660, 47, 80, 0.8, 131)
lower_bounds <- c(0, 50, 500, 30, 50, 0.5, 90)
upper_bounds <- c(45, 90, 800, 70, 120, 2.0, 150)

names(initial_values) <- param_names
names(lower_bounds) <- param_names
names(upper_bounds) <- param_names

cat("  7 parameters defined\n\n")

################################################################################
# OBJECTIVE FUNCTION
################################################################################

cat("Step 6: Objective function...\n")

eval_count <- 0

objective_function <- function(params) {
  
  eval_count <<- eval_count + 1
  
  param_values <- setNames(params, param_names)
  
  # Run DSSAT
  sim_result <- tryCatch({
    DSSAT_wrapper(
      param_values = param_values,
      model_options = model_options,
      situation = situation_names,
      sit_var_dates_mask = obs_list  # ← KEY: Use date masking!
    )
  }, error = function(e) {
    list(error = TRUE)
  })
  
  if (sim_result$error) {
    if (eval_count %% 5 == 0) cat("E")
    return(1e6)
  }
  
  # Calculate RMSE
  total_sse <- 0
  n_obs <- 0
  
  for (sit in names(obs_list)) {
    
    if (!(sit %in% names(sim_result$sim_list))) next
    
    obs_data <- obs_list[[sit]]
    sim_data <- sim_result$sim_list[[sit]]
    
    # For end-of-season data, take last simulation date
    if (nrow(sim_data) > 0) {
      sim_final <- sim_data[nrow(sim_data), ]
      
      # Compare harvest variables
      for (var in c("HWAM", "H#AM", "HWUM")) {
        if (var %in% names(obs_data) && var %in% names(sim_final)) {
          obs_val <- obs_data[[var]][1]
          sim_val <- sim_final[[var]]
          
          if (!is.na(obs_val) && !is.na(sim_val)) {
            sse <- (obs_val - sim_val)^2
            total_sse <- total_sse + sse
            n_obs <- n_obs + 1
          }
        }
      }
      
      # For dates (ADAT), compare day of year
      if ("ADAT" %in% names(obs_data) && "ADAT" %in% names(sim_final)) {
        obs_adat <- obs_data$ADAT[1]
        sim_adat <- sim_final$ADAT
        
        if (!is.na(obs_adat) && !is.na(sim_adat)) {
          # Convert to day of year if needed
          if (is.numeric(obs_adat) && is.numeric(sim_adat)) {
            sse <- (obs_adat - sim_adat)^2
            total_sse <- total_sse + sse
            n_obs <- n_obs + 1
          }
        }
      }
    }
  }
  
  if (n_obs == 0) {
    if (eval_count %% 5 == 0) cat("N")
    return(1e6)
  }
  
  rmse <- sqrt(total_sse / n_obs)
  
  if (eval_count %% 5 == 0) {
    cat(sprintf("\n  [%3d] RMSE: %.1f", eval_count, rmse))
  } else {
    cat(".")
  }
  
  return(rmse)
}

cat("✓ Objective function defined\n\n")

################################################################################
# TEST INITIAL EVALUATION
################################################################################

cat("Step 7: Testing initial parameters...\n")

initial_rmse <- objective_function(initial_values)
cat(sprintf("\n  Initial RMSE: %.1f\n\n", initial_rmse))

if (initial_rmse >= 1e6) {
  cat("  ⚠ WARNING: Initial RMSE is at penalty value!\n")
  cat("  This means observations aren't matching simulations.\n\n")
  cat("  This could be due to:\n")
  cat("    • Date format issues in observations\n")
  cat("    • Variable name mismatches\n")
  cat("    • Simulation errors\n\n")
  cat("  Proceeding anyway - optimizer may find better region...\n\n")
}

################################################################################
# CALIBRATION
################################################################################

cat("╔═══════════════════════════════════════════════════════════════╗\n")
cat("║              STARTING CALIBRATION                            ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

output_dir <- "Sakha95_CORRECTED_results"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

cat("Settings:\n")
cat("  Method: Nelder-Mead\n")
cat("  Max evaluations: 100\n")
cat("  Cultivar:", model_options$cultivar, "\n")
cat("  Situations: 50\n\n")

cat("Progress (. = ok, E = error, N = no data):\n")

start_time <- Sys.time()

result <- neldermead(
  x0 = initial_values,
  fn = objective_function,
  lower = lower_bounds,
  upper = upper_bounds,
  control = list(
    maxeval = 100,
    xtol_rel = 1e-3
  )
)

end_time <- Sys.time()
elapsed <- difftime(end_time, start_time, units = "mins")

cat("\n\n")

################################################################################
# RESULTS
################################################################################

cat("╔═══════════════════════════════════════════════════════════════╗\n")
cat("║           CALIBRATION COMPLETED!                             ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

cat("Summary:\n")
cat("  Time:", round(elapsed, 1), "minutes\n")
cat("  Evaluations:", eval_count, "\n")
cat("  Initial RMSE:", round(initial_rmse, 1), "\n")
cat("  Final RMSE:", round(result$value, 1), "\n")

if (result$value < initial_rmse) {
  improvement <- ((initial_rmse - result$value) / initial_rmse) * 100
  cat("  Improvement:", round(improvement, 1), "%\n\n")
  cat("  ✓ Calibration successful!\n\n")
} else {
  cat("  Improvement: 0%\n\n")
  cat("  ⚠ No improvement found\n\n")
}

# Results table
calibrated_params <- setNames(result$par, param_names)

param_table <- data.frame(
  Parameter = param_names,
  Initial = initial_values,
  Calibrated = calibrated_params,
  Change = calibrated_params - initial_values,
  Change_Pct = round(((calibrated_params - initial_values) / initial_values) * 100, 1),
  stringsAsFactors = FALSE
)

cat("═══════════════════════════════════════════════════════════════\n")
cat("          CALIBRATED PARAMETERS                                \n")
cat("═══════════════════════════════════════════════════════════════\n\n")

print(param_table, row.names = FALSE)

cat("\n═══════════════════════════════════════════════════════════════\n\n")

# Save results
param_file <- file.path(output_dir, "calibrated_parameters.csv")
write.csv(param_table, param_file, row.names = FALSE)

results_file <- file.path(output_dir, "calibration.RData")
save(result, param_table, model_options, file = results_file)

cat("✓ Results saved to:", output_dir, "\n\n")

################################################################################
# INSTRUCTIONS
################################################################################

cat("╔═══════════════════════════════════════════════════════════════╗\n")
cat("║                NEXT STEPS                                    ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

if (result$value < 1e5) {
  cat("✓ Calibration appears successful!\n\n")
  
  cat("To update WHCER048.CUL:\n\n")
  cat("  Find line for:", model_options$cultivar, "\n")
  cat("  Update parameters:\n\n")
  
  for (i in 1:nrow(param_table)) {
    cat(sprintf("    %-8s: %6.1f → %6.1f\n",
                param_table$Parameter[i],
                param_table$Initial[i],
                param_table$Calibrated[i]))
  }
  
} else {
  cat("⚠ Calibration did not converge properly\n\n")
  
  cat("Possible issues:\n")
  cat("  • Observations from .WHA don't match simulation outputs\n")
  cat("  • Date parsing problems\n")
  cat("  • Variable name mismatches\n\n")
  
  cat("Recommendations:\n")
  cat("  1. Check .WHA file format and contents\n")
  cat("  2. Verify simulation runs successfully\n")
  cat("  3. Test with DSSAT's example data first\n")
  cat("  4. Contact DSSAT wrapper maintainer\n")
}

cat("\n═══════════════════════════════════════════════════════════════\n\n")

cat("🌾 Script complete! 🌾\n\n")

################################################################################
# END
################################################################################
