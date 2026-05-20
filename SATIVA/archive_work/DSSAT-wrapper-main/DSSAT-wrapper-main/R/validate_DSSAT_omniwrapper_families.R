# Cross-family validation checks for the DSSAT omniwrapper prototype.
# This script exercises the newly validated adapter families and reports
# one explicit blocked case (CSCAS) so the current status is reproducible.

script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(script_arg) == 0) {
  stop("Unable to determine script location from commandArgs().")
}
script_path <- normalizePath(sub("^--file=", "", script_arg[1]), winslash = "/", mustWork = TRUE)
script_dir <- dirname(script_path)
source(file.path(script_dir, "DSSAT_omniwrapper.R"))

run_case <- function(label, project_file, situation, var_name, crop = NULL, module_code = NULL, dssat_path = "C:/DSSAT48") {
  cat("\n===", label, "===\n")
  model_options <- list(
    DSSAT_path = dssat_path,
    DSSAT_exe = "DSCSM048.EXE",
    project_file = project_file,
    suppress_output = TRUE
  )
  if (!is.null(crop)) {
    model_options$Crop <- crop
  }
  if (!is.null(module_code)) {
    model_options$module_code <- module_code
  }

  result <- DSSAT_omniwrapper(
    model_options = model_options,
    situation = situation,
    var = var_name
  )

  sim <- result$sim_list[[situation]]
  cat("Rows:", nrow(sim), "\n")
  cat("Columns:", paste(names(sim), collapse = ", "), "\n")
  if (nrow(sim) > 0) {
    cat("First date:", as.character(sim$Date[1]), "\n")
    cat("Last date:", as.character(sim$Date[nrow(sim)]), "\n")
  }
  cat("Error flag:", result$error, "\n")

  if (result$error || nrow(sim) == 0 || !(var_name %in% names(sim))) {
    stop("Validation failed for ", label, ".")
  }

  invisible(result)
}

run_blocked_case <- function(label, project_file, situation, crop, module_code, dssat_path = "C:/DSSAT48") {
  cat("\n===", label, "===\n")
  model_options <- list(
    DSSAT_path = dssat_path,
    DSSAT_exe = "DSCSM048.EXE",
    project_file = project_file,
    Crop = crop,
    module_code = module_code,
    suppress_output = TRUE
  )

  result <- tryCatch(
    DSSAT_omniwrapper(
      model_options = model_options,
      situation = situation,
      var = "CWAD"
    ),
    error = function(e) e
  )

  if (inherits(result, "error")) {
    cat("Blocked as expected:", conditionMessage(result), "\n")
    return(invisible(TRUE))
  }

  sim <- result$sim_list[[situation]]
  cat("Rows:", nrow(sim), "\n")
  cat("Columns:", paste(names(sim), collapse = ", "), "\n")
  cat("Error flag:", result$error, "\n")
  cat("Status: model launched but current local CSCAS setup is still not accepted as validated.\n")

  invisible(TRUE)
}

run_case(
  label = "ALOHA pineapple",
  project_file = "C:/DSSAT48/PineApple/UHKN8901.PIX",
  situation = "UHKN8901_1",
  var_name = "CWAD"
)

run_case(
  label = "AROIDS taro",
  project_file = "C:/DSSAT48/Taro/IBHK8901.TRX",
  situation = "IBHK8901_1",
  var_name = "CWAD"
)

run_case(
  label = "CANEGRO sugarcane",
  project_file = "C:/Users/chich/Downloads/DSSAT Files/DSSAT Files/dssat-csm-data/Sugarcane/ESAL1401.SCX",
  crop = "Sugarcane",
  module_code = "SCCAN048",
  situation = "ESAL1401_1",
  var_name = "LAIGD"
)

run_case(
  label = "CSYCA cassava",
  project_file = "C:/DSSAT48/Cassava/CCPA7801.CSX",
  situation = "CCPA7801_1",
  var_name = "CWAD"
)

run_case(
  label = "CASUPRO sugarcane",
  project_file = "C:/Users/chich/Downloads/DSSAT Files/DSSAT Files/dssat-csm-data/Sugarcane/ESAL1401.SCX",
  crop = "Sugarcane",
  module_code = "SCCSP048",
  situation = "ESAL1401_1",
  var_name = "LAIGD"
)

run_case(
  label = "CERES-IXIM maize",
  project_file = "C:/Users/chich/Downloads/DSSAT Files/DSSAT Files/dssat-csm-data/Maize/UFGA8201.MZX",
  crop = "Maize",
  module_code = "MZIXM048",
  situation = "UFGA8201_1",
  var_name = "CWAD"
)

run_case(
  label = "CROPSIM barley",
  project_file = "C:/Users/chich/Downloads/DSSAT Files/DSSAT Files/dssat-csm-data/Barley/IEBR8201.BAX",
  crop = "Barley",
  module_code = "CSCRP048",
  situation = "IEBR8201_1",
  var_name = "GSTD"
)

run_case(
  label = "NWHEAT teff",
  project_file = "C:/Users/chich/Downloads/DSSAT Files/DSSAT Files/dssat-csm-data/Teff/ETGA0201.TFX",
  crop = "Teff",
  module_code = "TFAPS048",
  situation = "ETGA0201_1",
  var_name = "CWAD"
)

run_case(
  label = "NWHEAT wheat",
  project_file = "C:/Users/chich/Downloads/DSSAT Files/DSSAT Files/dssat-csm-data/Wheat/KSAS8101.WHX",
  crop = "Wheat",
  module_code = "WHAPS048",
  situation = "KSAS8101_1",
  var_name = "GSTD"
)

run_case(
  label = "OILCROP sunflower",
  project_file = "C:/Users/chich/Downloads/DSSAT Files/DSSAT Files/dssat-csm-data/Sunflower/AUTA8101.SUX",
  crop = "Sunflower",
  module_code = "SUOIL048",
  situation = "AUTA8101_1",
  var_name = "CWAD"
)

run_case(
  label = "SAMUCA sugarcane",
  project_file = "C:/Users/chich/Downloads/DSSAT Files/DSSAT Files/dssat-csm-data/Sugarcane/SAPO8601.SCX",
  crop = "Sugarcane",
  module_code = "SCSAM048",
  situation = "SAPO8601_1",
  var_name = "LAIGD"
)

run_blocked_case(
  label = "CSCAS cassava (blocked)",
  project_file = "C:/Users/chich/Downloads/DSSAT Files/DSSAT Files/dssat-csm-data/Cassava/CCPA7801.CSX",
  crop = "Cassava",
  module_code = "CSCAS048",
  situation = "CCPA7801_1"
)

cat("\nCross-family omniwrapper validation completed.\n")
