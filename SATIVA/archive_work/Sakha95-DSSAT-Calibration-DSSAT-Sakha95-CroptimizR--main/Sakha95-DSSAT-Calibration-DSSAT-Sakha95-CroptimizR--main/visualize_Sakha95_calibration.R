################################################################################
#                                                                              #
#  SAKHA95 CALIBRATION - VISUALIZATION SCRIPT                                  #
#                                                                              #
#  Purpose: Generate publication-quality plots comparing initial vs            #
#           calibrated DSSAT simulations against observed data                 #
#                                                                              #
#  Author: Calibration Team                                                    #
#  Date: January 2026                                                          #
#  Status: Production Ready                                                    #
#                                                                              #
################################################################################

cat("\n")
cat("╔═══════════════════════════════════════════════════════════════╗\n")
cat("║      SAKHA95 CALIBRATION VISUALIZATION                       ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n")
cat("\n")

# ==============================================================================
# STEP 1: SETUP AND LOAD REQUIRED PACKAGES
# ==============================================================================

cat("Step 1: Loading packages...\n")

# Check and install required packages
required_packages <- c("ggplot2", "dplyr", "tidyr", "gridExtra", "grid")

for (pkg in required_packages) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    cat("  Installing", pkg, "...\n")
    install.packages(pkg, repos = "https://cloud.r-project.org/")
    library(pkg, character.only = TRUE)
  }
}

cat("  ✓ Packages loaded\n\n")

# ==============================================================================
# STEP 2: SET PATHS AND LOAD CALIBRATION RESULTS
# ==============================================================================

cat("Step 2: Loading calibration results...\n")

# Set working directory
setwd("D:/HourlyHDW/Calibrationwthfiles/DSSATWrapper")

# Load DSSAT wrapper functions (with fallback)
if (file.exists("R/DSSAT_wrapper.R")) {
  source("R/DSSAT_wrapper.R", verbose = FALSE)
  source("R/read_obs.R", verbose = FALSE)
  cat("  ✓ Loaded DSSAT wrapper from R/ subdirectory\n")
} else if (file.exists("DSSAT_wrapper.R")) {
  source("DSSAT_wrapper.R", verbose = FALSE)
  source("read_obs.R", verbose = FALSE)
  cat("  ✓ Loaded DSSAT wrapper from current directory\n")
} else {
  stop("ERROR: Cannot find DSSAT_wrapper.R! Please check your working directory.")
}

# Load calibration results
if (!file.exists("Sakha95_CORRECTED_results/calibration.RData")) {
  stop("ERROR: Calibration results not found! Run calibrate_Sakha95_FINAL_CORRECTED.R first.")
}

load("Sakha95_CORRECTED_results/calibration.RData")

# Extract parameters
initial_params <- c(
  P1V = 16.0,
  P1D = 74.6,
  P5 = 660,
  G1 = 47.0,
  G2 = 80,
  G3 = 0.8,
  PHINT = 131.0
)

calibrated_params <- result$par
names(calibrated_params) <- names(initial_params)

cat("  Initial parameters loaded:\n")
print(round(initial_params, 2))
cat("\n  Calibrated parameters loaded:\n")
print(round(calibrated_params, 2))
cat("\n  ✓ Results loaded\n\n")

# Define model_options (should match calibration script)
model_options <- list(
  DSSAT_path = 'C:/DSSAT48',
  DSSAT_exe = 'DSCSM048.EXE',
  Crop = "Wheat",
  ecotype_filename = "WHCER048.ECO",
  cultivar_filename = "WHCER048.CUL",
  ecotype = "CAWH01",
  cultivar = "Sakha95",  # Use VRNAME (from successful calibration)
  suppress_output = TRUE
)

cat("  Model options configured (cultivar: Sakha95)\n\n")

# ==============================================================================
# STEP 3: LOAD OBSERVATIONS
# ==============================================================================

cat("Step 3: Loading observations...\n")

# Experiments
experiments <- c("GMZA2001", "SIDS2001")

# Treatment numbers (corrected based on actual .WHX files)
gmza_treatments <- 1:23
sids_treatments <- 1:27

# Build situation list
situation_names <- c(
  paste0("GMZA2001_", gmza_treatments),
  paste0("SIDS2001_", sids_treatments)
)

# Read observations (using correct function signature)
obs_list <- read_obs(
  model_options = model_options,
  situation = situation_names,
  read_end_season = TRUE  # Read .WHA files only
)

cat("  ✓ Loaded observations for", length(situation_names), "situations\n\n")

# ==============================================================================
# STEP 4: RUN SIMULATIONS WITH INITIAL PARAMETERS
# ==============================================================================

cat("Step 4: Running simulations with INITIAL parameters...\n")
cat("  This will take 10-15 minutes...\n")

# Set parameters as named vector (use directly, don't re-name)
param_values <- initial_params

# Run DSSAT for ALL situations at once (like in calibration script)
cat("  Running DSSAT...\n")
sim_initial_result <- tryCatch({
  DSSAT_wrapper(
    param_values = param_values,
    model_options = model_options,
    situation = situation_names,
    sit_var_dates_mask = obs_list
  )
}, error = function(e) {
  list(error = TRUE, message = as.character(e))
})

if (!is.null(sim_initial_result$error) && sim_initial_result$error) {
  cat("  ❌ Error:", sim_initial_result$message, "\n")
  stop("Initial simulations failed")
}

# Extract sim_list from result
sim_initial_list <- sim_initial_result$sim_list

cat("  ✓ Initial simulations complete\n")
cat("  Debug: sim_initial_list has", length(sim_initial_list), "elements\n")
if (length(sim_initial_list) > 0) {
  first_sim <- sim_initial_list[[1]]
  cat("  Debug: First simulation structure - class:", class(first_sim), "\n")
  if (is.data.frame(first_sim)) {
    cat("  Debug: First simulation has", nrow(first_sim), "rows and columns:", paste(names(first_sim)[1:min(10, ncol(first_sim))], collapse = ", "), "...\n")
  }
}
cat("\n")

# ==============================================================================
# STEP 5: RUN SIMULATIONS WITH CALIBRATED PARAMETERS
# ==============================================================================

cat("Step 5: Running simulations with CALIBRATED parameters...\n")
cat("  This will take 10-15 minutes...\n")

# Set parameters as named vector (use directly, don't re-name)
param_values <- calibrated_params

# Run DSSAT for ALL situations at once (like in calibration script)
cat("  Running DSSAT...\n")
sim_calibrated_result <- tryCatch({
  DSSAT_wrapper(
    param_values = param_values,
    model_options = model_options,
    situation = situation_names,
    sit_var_dates_mask = obs_list
  )
}, error = function(e) {
  list(error = TRUE, message = as.character(e))
})

if (!is.null(sim_calibrated_result$error) && sim_calibrated_result$error) {
  cat("  ❌ Error:", sim_calibrated_result$message, "\n")
  stop("Calibrated simulations failed")
}

# Extract sim_list from result
sim_calibrated_list <- sim_calibrated_result$sim_list

cat("  ✓ Calibrated simulations complete\n")
cat("  Debug: sim_calibrated_list has", length(sim_calibrated_list), "elements\n")
if (length(sim_calibrated_list) > 0) {
  first_sim <- sim_calibrated_list[[1]]
  cat("  Debug: First simulation structure - class:", class(first_sim), "\n")
  if (is.data.frame(first_sim)) {
    cat("  Debug: First simulation has", nrow(first_sim), "rows and columns:", paste(names(first_sim)[1:min(10, ncol(first_sim))], collapse = ", "), "...\n")
  }
}
cat("\n")

# ==============================================================================
# STEP 6: PREPARE DATA FOR PLOTTING
# ==============================================================================

cat("Step 6: Preparing data for plotting...\n")

# Combine observations into single dataframe
obs_df <- data.frame()
for (situation in names(obs_list)) {
  obs_sit <- obs_list[[situation]]
  if (!is.null(obs_sit) && nrow(obs_sit) > 0) {
    obs_sit$Situation <- situation
    obs_df <- rbind(obs_df, obs_sit)
  }
}

cat("  Observations loaded:", nrow(obs_df), "rows\n")
if (nrow(obs_df) > 0) {
  cat("  Observation columns:", paste(names(obs_df), collapse = ", "), "\n")
}

# Extract final values from simulations (for end-of-season comparison)
extract_final <- function(sim_list) {
  final_df <- data.frame()
  for (situation in names(sim_list)) {
    sim_sit <- sim_list[[situation]]
    if (!is.null(sim_sit) && nrow(sim_sit) > 0) {
      # Take last row (maturity)
      final_row <- sim_sit[nrow(sim_sit), ]
      final_row$Situation <- situation
      final_df <- rbind(final_df, final_row)
    }
  }
  return(final_df)
}

sim_initial_final <- extract_final(sim_initial_list)
sim_calibrated_final <- extract_final(sim_calibrated_list)

cat("  Initial simulations:", nrow(sim_initial_final), "final rows\n")
cat("  Calibrated simulations:", nrow(sim_calibrated_final), "final rows\n")

if (nrow(sim_initial_final) > 0) {
  cat("  Simulation columns:", paste(names(sim_initial_final)[1:min(10, ncol(sim_initial_final))], collapse = ", "), "...\n")
}

# Variables to plot
variables <- c("HWAM", "ADAT", "H#AM", "HWUM")

cat("  Checking variable availability...\n")

# Create comparison dataframes
compare_df <- data.frame()

for (var in variables) {
  # Check if variable exists in observations
  if (!(var %in% names(obs_df))) {
    cat("    ⚠ Variable", var, "not in observations, skipping\n")
    next
  }
  
  # Get observed values
  obs_var <- obs_df[, c("Situation", var)]
  names(obs_var) <- c("Situation", "Observed")
  obs_var <- obs_var[!is.na(obs_var$Observed), ]
  
  if (nrow(obs_var) == 0) {
    cat("    ⚠ Variable", var, "has no observations, skipping\n")
    next
  }
  
  # Check if variable exists in simulations
  if (!(var %in% names(sim_initial_final))) {
    cat("    ⚠ Variable", var, "not in simulations, skipping\n")
    next
  }
  
  # Get initial simulated values
  sim_init_var <- sim_initial_final[, c("Situation", var)]
  names(sim_init_var) <- c("Situation", "Initial")
  
  # Merge
  merged <- merge(obs_var, sim_init_var, by = "Situation")
  
  if (nrow(merged) == 0) {
    cat("    ⚠ Variable", var, "has no matching situations, skipping\n")
    next
  }
  
  # Get calibrated simulated values
  if (var %in% names(sim_calibrated_final)) {
    sim_cal_var <- sim_calibrated_final[, c("Situation", var)]
    names(sim_cal_var) <- c("Situation", "Calibrated")
    
    merged <- merge(merged, sim_cal_var, by = "Situation")
    
    if (nrow(merged) > 0) {
      merged$Variable <- var
      compare_df <- rbind(compare_df, merged)
      cat("    ✓ Variable", var, ":", nrow(merged), "comparison points\n")
    }
  }
}

# Parse location from situation
if (nrow(compare_df) > 0) {
  compare_df$Location <- ifelse(grepl("GMZA", compare_df$Situation), "Gemiza", "Sids")
}

cat("  ✓ Data prepared:", nrow(compare_df), "comparison points\n\n")

# If no data, stop with helpful message
if (nrow(compare_df) == 0) {
  cat("\n")
  cat("╔═══════════════════════════════════════════════════════════════╗\n")
  cat("║  WARNING: No comparison data available                      ║\n")
  cat("╚═══════════════════════════════════════════════════════════════╝\n")
  cat("\n")
  cat("Possible reasons:\n")
  cat("  1. Variable names don't match between obs and sim\n")
  cat("  2. Situation names don't match\n")
  cat("  3. No overlapping data\n")
  cat("\n")
  cat("Debug information saved to: Sakha95_CORRECTED_results/debug_info.txt\n")
  
  # Save debug info
  debug_dir <- "Sakha95_CORRECTED_results"
  if (!dir.exists(debug_dir)) dir.create(debug_dir, recursive = TRUE)
  
  sink(file.path(debug_dir, "debug_info.txt"))
  cat("=== OBSERVATIONS ===\n")
  cat("Rows:", nrow(obs_df), "\n")
  cat("Columns:", paste(names(obs_df), collapse = ", "), "\n")
  cat("Situations:", paste(head(unique(obs_df$Situation), 10), collapse = ", "), "...\n\n")
  
  cat("=== SIMULATIONS (Initial) ===\n")
  cat("Rows:", nrow(sim_initial_final), "\n")
  cat("Columns:", paste(names(sim_initial_final), collapse = ", "), "\n")
  cat("Situations:", paste(head(unique(sim_initial_final$Situation), 10), collapse = ", "), "...\n\n")
  
  cat("=== SIMULATIONS (Calibrated) ===\n")
  cat("Rows:", nrow(sim_calibrated_final), "\n")
  cat("Columns:", paste(names(sim_calibrated_final), collapse = ", "), "\n")
  cat("Situations:", paste(head(unique(sim_calibrated_final$Situation), 10), collapse = ", "), "...\n")
  sink()
  
  stop("No comparison data available. Check debug_info.txt for details.")
}

# ==============================================================================
# STEP 7: CALCULATE STATISTICS
# ==============================================================================

cat("Step 7: Calculating statistics...\n")

calculate_stats <- function(obs, sim) {
  # Remove NAs
  valid <- !is.na(obs) & !is.na(sim)
  obs <- obs[valid]
  sim <- sim[valid]
  
  if (length(obs) < 2) {
    return(data.frame(
      N = 0, RMSE = NA, nRMSE = NA, R2 = NA, 
      Bias = NA, MAE = NA, EF = NA
    ))
  }
  
  # Calculate metrics
  n <- length(obs)
  rmse <- sqrt(mean((obs - sim)^2))
  nrmse <- (rmse / mean(obs)) * 100
  ss_res <- sum((obs - sim)^2)
  ss_tot <- sum((obs - mean(obs))^2)
  r2 <- max(0, 1 - ss_res / ss_tot)
  bias <- mean(sim - obs)
  mae <- mean(abs(obs - sim))
  ef <- 1 - ss_res / ss_tot
  
  return(data.frame(
    N = n,
    RMSE = round(rmse, 1),
    nRMSE = round(nrmse, 1),
    R2 = round(r2, 3),
    Bias = round(bias, 1),
    MAE = round(mae, 1),
    EF = round(ef, 3)
  ))
}

# Calculate statistics for each variable
stats_table <- data.frame()

for (var in variables) {
  var_data <- compare_df[compare_df$Variable == var, ]
  
  # Handle case where subsetting returns NULL or has 0 rows
  if (is.null(var_data) || !is.data.frame(var_data) || nrow(var_data) == 0) next
  
  # Initial stats
  stats_init <- calculate_stats(var_data$Observed, var_data$Initial)
  stats_init$Variable <- var
  stats_init$Type <- "Initial"
  
  # Calibrated stats
  stats_cal <- calculate_stats(var_data$Observed, var_data$Calibrated)
  stats_cal$Variable <- var
  stats_cal$Type <- "Calibrated"
  
  stats_table <- rbind(stats_table, stats_init, stats_cal)
}

# Reorder columns if we have any stats
if (nrow(stats_table) > 0) {
  stats_table <- stats_table[, c("Variable", "Type", "N", "RMSE", "nRMSE", "R2", "Bias", "MAE", "EF")]
  print(stats_table)
  cat("\n  ✓ Statistics calculated\n\n")
} else {
  cat("\n  ⚠ No statistics could be calculated\n\n")
}

# ==============================================================================
# STEP 8: CREATE PLOTS
# ==============================================================================

cat("Step 8: Creating plots...\n")

# Create output directory
plot_dir <- "Sakha95_CORRECTED_results/plots"
if (!dir.exists(plot_dir)) {
  dir.create(plot_dir, recursive = TRUE)
}

# Define plot theme
theme_publication <- theme_bw() +
  theme(
    text = element_text(size = 12),
    axis.title = element_text(size = 14, face = "bold"),
    axis.text = element_text(size = 11),
    legend.title = element_text(size = 12, face = "bold"),
    legend.text = element_text(size = 11),
    strip.text = element_text(size = 12, face = "bold"),
    strip.background = element_rect(fill = "grey90"),
    panel.grid.minor = element_blank()
  )

# Variable labels and units
var_labels <- list(
  HWAM = list(label = "Grain Yield", unit = "kg/ha"),
  ADAT = list(label = "Anthesis Date", unit = "Day of Year"),
  `H#AM` = list(label = "Harvest Number", unit = "#/m²"),
  HWUM = list(label = "Unit Grain Weight", unit = "mg")
)

# ==============================================================================
# PLOT 1: SCATTER PLOTS - INITIAL VS CALIBRATED
# ==============================================================================

cat("  Creating scatter plots...\n")

plot_list <- list()

for (var in variables) {
  var_data <- compare_df[compare_df$Variable == var, ]
  
  if (nrow(var_data) == 0) next
  
  # Get stats for this variable
  stats_init <- stats_table[stats_table$Variable == var & stats_table$Type == "Initial", ]
  stats_cal <- stats_table[stats_table$Variable == var & stats_table$Type == "Calibrated", ]
  
  # Create labels
  var_info <- var_labels[[var]]
  x_label <- paste0("Observed ", var_info$label, " (", var_info$unit, ")")
  y_label <- paste0("Simulated ", var_info$label, " (", var_info$unit, ")")
  
  # Prepare data for plotting
  plot_data <- var_data %>%
    select(Observed, Initial, Calibrated, Location) %>%
    pivot_longer(cols = c(Initial, Calibrated), names_to = "Type", values_to = "Simulated")
  
  # Calculate plot limits
  all_values <- c(plot_data$Observed, plot_data$Simulated)
  plot_min <- min(all_values, na.rm = TRUE)
  plot_max <- max(all_values, na.rm = TRUE)
  plot_range <- plot_max - plot_min
  plot_min <- plot_min - 0.05 * plot_range
  plot_max <- plot_max + 0.05 * plot_range
  
  # Create plot
  p <- ggplot(plot_data, aes(x = Observed, y = Simulated, color = Location, shape = Type)) +
    geom_point(size = 3, alpha = 0.7) +
    geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "black", size = 1) +
    scale_color_manual(values = c("Gemiza" = "#E69F00", "Sids" = "#56B4E9")) +
    scale_shape_manual(values = c("Initial" = 1, "Calibrated" = 16)) +
    coord_fixed(ratio = 1, xlim = c(plot_min, plot_max), ylim = c(plot_min, plot_max)) +
    labs(
      title = paste0(var, ": Observed vs Simulated"),
      x = x_label,
      y = y_label,
      color = "Location",
      shape = "Parameters"
    ) +
    theme_publication
  
  # Add statistics annotation
  if (nrow(stats_init) > 0 && nrow(stats_cal) > 0) {
    ann_text <- paste0(
      "Initial:  R² = ", stats_init$R2, "  RMSE = ", stats_init$RMSE, "\n",
      "Calibrated:  R² = ", stats_cal$R2, "  RMSE = ", stats_cal$RMSE
    )
    
    p <- p + annotate(
      "text",
      x = plot_min + 0.05 * (plot_max - plot_min),
      y = plot_max - 0.05 * (plot_max - plot_min),
      label = ann_text,
      hjust = 0,
      vjust = 1,
      size = 3.5,
      fontface = "italic"
    )
  }
  
  plot_list[[var]] <- p
  
  # Save individual plot
  ggsave(
    filename = file.path(plot_dir, paste0(var, "_scatter.png")),
    plot = p,
    width = 8,
    height = 7,
    dpi = 300
  )
}

cat("    ✓ Saved", length(plot_list), "scatter plots\n")

# ==============================================================================
# PLOT 2: COMBINED SCATTER PLOT (ALL VARIABLES)
# ==============================================================================

cat("  Creating combined scatter plot...\n")

if (length(plot_list) >= 2) {
  # Arrange plots in grid
  n_plots <- length(plot_list)
  n_cols <- 2
  n_rows <- ceiling(n_plots / n_cols)
  
  combined_plot <- grid.arrange(grobs = plot_list, ncol = n_cols)
  
  # Save combined plot
  ggsave(
    filename = file.path(plot_dir, "ALL_VARIABLES_scatter.png"),
    plot = combined_plot,
    width = 14,
    height = 6 * n_rows,
    dpi = 300
  )
  
  cat("    ✓ Saved combined scatter plot\n")
}

# ==============================================================================
# PLOT 3: IMPROVEMENT COMPARISON (BAR PLOT)
# ==============================================================================

cat("  Creating improvement comparison plot...\n")

# Calculate improvement for each variable
improvement_df <- data.frame()

for (var in variables) {
  stats_init <- stats_table[stats_table$Variable == var & stats_table$Type == "Initial", ]
  stats_cal <- stats_table[stats_table$Variable == var & stats_table$Type == "Calibrated", ]
  
  if (nrow(stats_init) > 0 && nrow(stats_cal) > 0) {
    rmse_improvement <- ((stats_init$RMSE - stats_cal$RMSE) / stats_init$RMSE) * 100
    r2_improvement <- ((stats_cal$R2 - stats_init$R2) / (1 - stats_init$R2)) * 100
    
    improvement_df <- rbind(
      improvement_df,
      data.frame(
        Variable = var,
        Metric = "RMSE Reduction",
        Improvement = rmse_improvement
      ),
      data.frame(
        Variable = var,
        Metric = "R² Improvement",
        Improvement = r2_improvement
      )
    )
  }
}

if (nrow(improvement_df) > 0) {
  p_improvement <- ggplot(improvement_df, aes(x = Variable, y = Improvement, fill = Metric)) +
    geom_bar(stat = "identity", position = "dodge", width = 0.7) +
    geom_hline(yintercept = 0, linetype = "dashed") +
    scale_fill_manual(values = c("RMSE Reduction" = "#00BA38", "R² Improvement" = "#619CFF")) +
    labs(
      title = "Calibration Improvement by Variable",
      x = "Variable",
      y = "Improvement (%)",
      fill = "Metric"
    ) +
    theme_publication +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  
  ggsave(
    filename = file.path(plot_dir, "improvement_comparison.png"),
    plot = p_improvement,
    width = 10,
    height = 6,
    dpi = 300
  )
  
  cat("    ✓ Saved improvement comparison plot\n")
}

# ==============================================================================
# PLOT 4: RESIDUAL PLOTS
# ==============================================================================

cat("  Creating residual plots...\n")

residual_plots <- list()

for (var in variables) {
  var_data <- compare_df[compare_df$Variable == var, ]
  
  if (nrow(var_data) == 0) next
  
  # Calculate residuals
  var_data$Residual_Initial <- var_data$Initial - var_data$Observed
  var_data$Residual_Calibrated <- var_data$Calibrated - var_data$Observed
  
  # Reshape for plotting
  residual_data <- var_data %>%
    select(Observed, Residual_Initial, Residual_Calibrated, Location) %>%
    pivot_longer(
      cols = c(Residual_Initial, Residual_Calibrated),
      names_to = "Type",
      values_to = "Residual"
    ) %>%
    mutate(Type = gsub("Residual_", "", Type))
  
  # Create plot
  var_info <- var_labels[[var]]
  x_label <- paste0("Observed ", var_info$label, " (", var_info$unit, ")")
  y_label <- paste0("Residual (", var_info$unit, ")")
  
  p_resid <- ggplot(residual_data, aes(x = Observed, y = Residual, color = Location, shape = Type)) +
    geom_point(size = 3, alpha = 0.7) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "black", size = 1) +
    scale_color_manual(values = c("Gemiza" = "#E69F00", "Sids" = "#56B4E9")) +
    scale_shape_manual(values = c("Initial" = 1, "Calibrated" = 16)) +
    labs(
      title = paste0(var, ": Residual Plot"),
      x = x_label,
      y = y_label,
      color = "Location",
      shape = "Parameters"
    ) +
    theme_publication
  
  residual_plots[[var]] <- p_resid
  
  # Save individual plot
  ggsave(
    filename = file.path(plot_dir, paste0(var, "_residuals.png")),
    plot = p_resid,
    width = 8,
    height = 6,
    dpi = 300
  )
}

cat("    ✓ Saved", length(residual_plots), "residual plots\n")

# ==============================================================================
# PLOT 5: PARAMETER COMPARISON
# ==============================================================================

cat("  Creating parameter comparison plot...\n")

# Prepare parameter data
param_comparison <- data.frame(
  Parameter = names(initial_params),
  Initial = as.numeric(initial_params),
  Calibrated = as.numeric(calibrated_params)
) %>%
  mutate(
    Change_Pct = ((Calibrated - Initial) / Initial) * 100,
    Direction = ifelse(Change_Pct > 0, "Increase", "Decrease")
  )

# Create comparison plot
p_params <- ggplot(param_comparison, aes(x = Parameter)) +
  geom_segment(
    aes(xend = Parameter, y = Initial, yend = Calibrated, color = Direction),
    arrow = arrow(length = unit(0.3, "cm")),
    size = 1.5
  ) +
  geom_point(aes(y = Initial), size = 4, shape = 1, color = "black") +
  geom_point(aes(y = Calibrated), size = 4, shape = 16, color = "black") +
  scale_color_manual(values = c("Increase" = "#00BA38", "Decrease" = "#F8766D")) +
  labs(
    title = "Parameter Changes: Initial → Calibrated",
    x = "Parameter",
    y = "Value",
    color = "Change"
  ) +
  theme_publication +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave(
  filename = file.path(plot_dir, "parameter_comparison.png"),
  plot = p_params,
  width = 10,
  height = 6,
  dpi = 300
)

cat("    ✓ Saved parameter comparison plot\n")

# ==============================================================================
# STEP 9: SAVE STATISTICS TABLE
# ==============================================================================

cat("\nStep 9: Saving statistics table...\n")

# Save to CSV
write.csv(
  stats_table,
  file = file.path(plot_dir, "../statistics_summary.csv"),
  row.names = FALSE
)

# Save comparison data
write.csv(
  compare_df,
  file = file.path(plot_dir, "../simulation_comparison_data.csv"),
  row.names = FALSE
)

cat("  ✓ Statistics saved\n\n")

# ==============================================================================
# STEP 10: GENERATE SUMMARY REPORT
# ==============================================================================

cat("Step 10: Generating summary report...\n")

# Create text report
report_lines <- c(
  "╔═══════════════════════════════════════════════════════════════╗",
  "║       SAKHA95 CALIBRATION - VISUALIZATION REPORT             ║",
  "╚═══════════════════════════════════════════════════════════════╝",
  "",
  "CALIBRATION SUMMARY",
  "==================",
  "",
  "Parameters:",
  "----------"
)

for (i in seq_along(names(initial_params))) {
  param_name <- names(initial_params)[i]
  change_pct <- param_comparison$Change_Pct[i]
  report_lines <- c(
    report_lines,
    sprintf(
      "  %6s:  %7.2f → %7.2f  (%+6.1f%%)",
      param_name,
      initial_params[i],
      calibrated_params[i],
      change_pct
    )
  )
}

report_lines <- c(
  report_lines,
  "",
  "PERFORMANCE METRICS",
  "==================",
  ""
)

for (var in unique(stats_table$Variable)) {
  var_stats <- stats_table[stats_table$Variable == var, ]
  
  if (nrow(var_stats) == 2) {
    stats_init <- var_stats[var_stats$Type == "Initial", ]
    stats_cal <- var_stats[var_stats$Type == "Calibrated", ]
    
    report_lines <- c(
      report_lines,
      paste0(var, ":"),
      "-------"
    )
    
    # RMSE
    rmse_change <- ((stats_init$RMSE - stats_cal$RMSE) / stats_init$RMSE) * 100
    report_lines <- c(
      report_lines,
      sprintf("  RMSE:  %.1f → %.1f  (%.1f%% reduction)", 
              stats_init$RMSE, stats_cal$RMSE, rmse_change)
    )
    
    # R²
    r2_change <- stats_cal$R2 - stats_init$R2
    report_lines <- c(
      report_lines,
      sprintf("  R²:    %.3f → %.3f  (%+.3f)", 
              stats_init$R2, stats_cal$R2, r2_change)
    )
    
    # Bias
    report_lines <- c(
      report_lines,
      sprintf("  Bias:  %.1f → %.1f", 
              stats_init$Bias, stats_cal$Bias)
    )
    
    report_lines <- c(report_lines, "")
  }
}

report_lines <- c(
  report_lines,
  "OUTPUT FILES",
  "============",
  "",
  "Plots:",
  paste0("  ", plot_dir, "/"),
  "    - *_scatter.png (observed vs simulated)",
  "    - *_residuals.png (residual analysis)",
  "    - ALL_VARIABLES_scatter.png (combined)",
  "    - improvement_comparison.png",
  "    - parameter_comparison.png",
  "",
  "Data:",
  "  Sakha95_CORRECTED_results/",
  "    - statistics_summary.csv",
  "    - simulation_comparison_data.csv",
  "",
  "╔═══════════════════════════════════════════════════════════════╗",
  "║              VISUALIZATION COMPLETE!                         ║",
  "╚═══════════════════════════════════════════════════════════════╝"
)

# Print report to console
cat("\n")
for (line in report_lines) {
  cat(line, "\n")
}

# Save report to file
writeLines(
  report_lines,
  con = file.path(plot_dir, "../VISUALIZATION_REPORT.txt")
)

cat("\n  ✓ Report saved\n\n")

# ==============================================================================
# FINAL MESSAGE
# ==============================================================================

cat("\n")
cat("╔═══════════════════════════════════════════════════════════════╗\n")
cat("║                   ALL DONE!                                  ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n")
cat("\n")
cat("📊 Plots saved to:", plot_dir, "\n")
cat("📈 Statistics saved to: Sakha95_CORRECTED_results/statistics_summary.csv\n")
cat("📄 Report saved to: Sakha95_CORRECTED_results/VISUALIZATION_REPORT.txt\n")
cat("\n")
cat("Next steps:\n")
cat("  1. Review scatter plots for model performance\n")
cat("  2. Check residual plots for bias patterns\n")
cat("  3. Use plots in publications/presentations\n")
cat("  4. Consider validation with independent data\n")
cat("\n")
cat("🎉 Visualization complete! 🌾\n")
cat("\n")

################################################################################
#                           END OF SCRIPT                                      #
################################################################################
