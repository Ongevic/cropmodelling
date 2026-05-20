################################################################################
# SAKHA95 CALIBRATION – DSSAT v4.8 – WHAPS (N-Wheat)
# FULL WORKING SCRIPT (Yield-only via Evaluate.OUT; avoids DATE/PlantGro issues)
#
# What this fixes:
#  - No charToDate / no DATE column dependency (PlantGro.OUT is NOT used)
#  - No Zadok computation (not needed for yield calibration)
#  - Robust yield extraction from Evaluate.OUT (HWAMS/HWAHS fallback)
#  - Uses ALL TRNO from WHA observations (GMZA + SIDS)
#  - Nelder–Mead optimization via nloptr::neldermead
#  - Optional coverage penalty to prevent “cheating” on few TRNO
################################################################################

cat("\n============================================================\n")
cat("  SAKHA95 CALIBRATION – DSSAT WHAPS (N-Wheat) – FULL SCRIPT\n")
cat("============================================================\n\n")

################################################################################
# 1) PACKAGES
################################################################################
pkgs <- c("nloptr","dplyr","ggplot2","DSSAT")
for (p in pkgs) if (!require(p, quietly = TRUE, character.only = TRUE)) install.packages(p)
suppressPackageStartupMessages(library(nloptr))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(ggplot2))
suppressPackageStartupMessages(library(DSSAT))

################################################################################
# 2) PATHS (EDIT IF NEEDED)
################################################################################
WORKDIR    <- "D:/HourlyHDW/Calibrationwthfiles/DSSATWrapper"
DSSAT_PATH <- "C:/DSSAT48"
DSSAT_EXE  <- "DSCSM048.EXE"
GENO_DIR   <- file.path(DSSAT_PATH, "Genotype")

setwd(WORKDIR)
options(DSSAT.CSM = file.path(DSSAT_PATH, DSSAT_EXE))

# WHAPS genotype files
CUL_ORIG <- file.path(GENO_DIR, "WHAPS048.CUL")
ECO_FILE <- "WHAPS048.ECO"
SPE_FILE <- "WHAPS048.SPE"

# Your local wrapper file (provided by you)
WRAPPER_FILE <- file.path(WORKDIR, "DSSAT_wrapper.R")
if (!file.exists(WRAPPER_FILE)) stop("❌ Cannot find DSSAT_wrapper.R at: ", WRAPPER_FILE)
source(WRAPPER_FILE)

# Observations
WHA_GMZA <- file.path(WORKDIR, "GMZA2001.WHA")
WHA_SIDS <- file.path(WORKDIR, "SIDS2001.WHA")
if (!file.exists(WHA_GMZA)) stop("❌ Missing GMZA2001.WHA: ", WHA_GMZA)
if (!file.exists(WHA_SIDS)) stop("❌ Missing SIDS2001.WHA: ", WHA_SIDS)

# Fail fast: cultivar file
if (!file.exists(CUL_ORIG)) stop("❌ Missing cultivar file: ", CUL_ORIG)

cat("✓ WORKDIR   :", WORKDIR, "\n")
cat("✓ DSSAT.CSM :", getOption("DSSAT.CSM"), "\n")
cat("✓ WHA GMZA  :", WHA_GMZA, "\n")
cat("✓ WHA SIDS  :", WHA_SIDS, "\n\n")

################################################################################
# 3) PATCH WHAPS048.CUL HEADER (VRNAME → VAR-NAME)
################################################################################
patch_whaps_cul <- function(cul_in, cul_out) {
  x <- readLines(cul_in, warn = FALSE)
  h <- grep("^@VAR#", x)
  if (length(h) != 1) stop("❌ Could not find unique @VAR# header in: ", cul_in)
  x[h] <- gsub("\\bVRNAME\\b", "VAR-NAME", x[h])
  writeLines(x, cul_out)
  cul_out
}

CUL_PATCHED <- file.path(GENO_DIR, "WHAPS048_PATCHED.CUL")
patch_whaps_cul(CUL_ORIG, CUL_PATCHED)
cat("✓ Patched CUL:", CUL_PATCHED, "\n\n")

################################################################################
# 4) READ Sakha95 PARAMETERS FROM CUL (robust text parse)
################################################################################
read_whaps_cul <- function(cul_file, name = "Sakha95") {
  x <- readLines(cul_file, warn = FALSE)
  h <- grep("^@VAR#", x)
  if (length(h) != 1) stop("❌ No unique @VAR# header found in: ", cul_file)
  
  dat <- x[(h + 1):length(x)]
  dat <- dat[!grepl("^\\s*$|^\\s*!", dat)]
  tok <- strsplit(trimws(dat), "\\s+")
  
  idx <- which(vapply(tok, function(v) length(v) >= 13 && v[2] == name, logical(1)))
  if (length(idx) != 1) stop("❌ Cultivar name not uniquely found: ", name)
  
  v <- tok[[idx]]
  
  list(
    cultivar_code = v[1],
    ecotype_code  = v[4],
    params = c(
      VSEN  = as.numeric(v[5]),
      PPSEN = as.numeric(v[6]),
      P1    = as.numeric(v[7]),
      P5    = as.numeric(v[8]),
      PHINT = as.numeric(v[9]),
      GRNO  = as.numeric(v[10]),
      MXFIL = as.numeric(v[11]),
      STMMX = as.numeric(v[12]),
      SLAP1 = as.numeric(v[13])
    )
  )
}

sakha <- read_whaps_cul(CUL_PATCHED, "Sakha95")
init_params   <- sakha$params
cultivar_code <- sakha$cultivar_code
ecotype_code  <- sakha$ecotype_code

cat("✓ Sakha95 detected:\n")
cat("  VAR# :", cultivar_code, "\n")
cat("  ECO# :", ecotype_code, "\n")
print(init_params); cat("\n")

################################################################################
# 5) PARAMETER BOUNDS
################################################################################
lower <- c(VSEN=0.00, PPSEN=1.20, P1=380, P5=200, PHINT=85,  GRNO=20, MXFIL=1.60, STMMX=1.00, SLAP1=200)
upper <- c(VSEN=4.00, PPSEN=4.50, P1=530, P5=700, PHINT=130, GRNO=32, MXFIL=2.90, STMMX=3.00, SLAP1=400)

################################################################################
# 6) MODEL OPTIONS (WHAPS)
################################################################################
model_options <- list(
  DSSAT_path        = DSSAT_PATH,
  DSSAT_exe         = DSSAT_EXE,
  Crop              = "Wheat",
  
  cultivar_filename = basename(CUL_PATCHED),
  ecotype_filename  = ECO_FILE,
  species_filename  = SPE_FILE,
  
  cultivar          = cultivar_code,  # IMPORTANT: this must match `VAR-NAME` in CUL (Sakha95) OR code? Your wrapper uses VAR-NAME==cultivar.
  ecotype           = ecotype_code,
  
  suppress_output   = TRUE,
  
  # out_files unused in yield-only workflow, but safe to include:
  out_files         = c("PlantGro.OUT", "Evaluate.OUT", "PlantGr2.OUT")
)

################################################################################
# 7) READ OBSERVED YIELD FROM WHA (robust)
################################################################################
read_obs_wha <- function(wha) {
  x <- readLines(wha, warn = FALSE)
  h <- grep("^\\s*@TRNO\\b", x)
  if (length(h) < 1) stop("❌ Cannot find @TRNO in: ", wha)
  
  header <- strsplit(sub("^\\s*@", "", x[h[1]]), "\\s+")[[1]]
  
  dat <- x[(h[1] + 1):length(x)]
  dat <- dat[!grepl("^\\s*$|^\\s*!|^\\s*@", dat)]
  stop_idx <- which(grepl("^\\s*\\*", dat))
  if (length(stop_idx) > 0) dat <- dat[1:(stop_idx[1]-1)]
  
  tok <- strsplit(trimws(dat), "\\s+")
  tok <- tok[vapply(tok, length, integer(1)) >= length(header)]
  if (length(tok) == 0) stop("❌ No data rows under @TRNO in: ", wha)
  
  df <- as.data.frame(do.call(rbind, tok), stringsAsFactors = FALSE)
  names(df) <- header
  for (nm in names(df)) df[[nm]] <- suppressWarnings(as.numeric(df[[nm]]))
  df[df <= -99] <- NA
  
  ycol <- if ("HWAM" %in% names(df)) "HWAM" else if ("HWAH" %in% names(df)) "HWAH" else NA_character_
  if (is.na(ycol)) stop("❌ No HWAM/HWAH in: ", wha)
  
  df %>%
    select(TRNO, HWAM_obs = all_of(ycol)) %>%
    filter(!is.na(TRNO), !is.na(HWAM_obs)) %>%
    group_by(TRNO) %>%
    summarise(HWAM_obs = mean(HWAM_obs, na.rm = TRUE), .groups = "drop")
}

obs_gmza <- read_obs_wha(WHA_GMZA) %>% mutate(SITE = "GMZA")
obs_sids <- read_obs_wha(WHA_SIDS) %>% mutate(SITE = "SIDS")
obs_all  <- bind_rows(obs_gmza, obs_sids)

cat("✓ Observations:\n")
print(obs_all %>% group_by(SITE) %>% summarise(n_TRNO = n_distinct(TRNO), .groups = "drop"))
cat("\n")

################################################################################
# 8) BUILD SITUATIONS (ALL TRNO)
################################################################################
situations <- c(
  paste0("GMZA2001_", obs_gmza$TRNO),
  paste0("SIDS2001_", obs_sids$TRNO)
)
cat("✓ Total situations:", length(situations), "\n\n")

################################################################################
# 9) Yield-only DSSAT run (NO PlantGro parsing)
################################################################################
run_dssat_yield_only <- function(param_values, situations, model_options) {
  
  ini_wd <- getwd()
  on.exit(setwd(ini_wd), add = TRUE)
  
  options(DSSAT.CSM = file.path(model_options$DSSAT_path, model_options$DSSAT_exe))
  
  crop <- model_options$Crop
  project_path  <- file.path(model_options$DSSAT_path, crop)
  genotype_path <- file.path(model_options$DSSAT_path, "Genotype")
  
  ecotype_filename  <- model_options$ecotype_filename
  cultivar_filename <- model_options$cultivar_filename
  
  ecotype_path  <- if (file.exists(file.path(project_path, ecotype_filename))) project_path else genotype_path
  cultivar_path <- if (file.exists(file.path(project_path, cultivar_filename))) project_path else genotype_path
  
  ecotype  <- model_options$ecotype
  cultivar <- model_options$cultivar
  suppress_output <- if (is.null(model_options$suppress_output)) TRUE else model_options$suppress_output
  
  crop_code <- substr(model_options$ecotype_filename, 1, 2)
  
  param_names <- names(param_values)
  
  # --- ecotype ---
  eco <- DSSAT::read_eco(file.path(ecotype_path, ecotype_filename))
  eco_params <- names(eco)
  flag_eco_param <- any(param_names %in% eco_params)
  
  if (flag_eco_param) {
    file.copy(file.path(ecotype_path, ecotype_filename),
              file.path(ecotype_path, paste0(ecotype_filename, "_tmp")),
              overwrite = TRUE)
    idx <- which(eco$`ECO#` == ecotype)
    if (length(idx) == 0) warning("⚠ Ecotype not found in ECO: ", ecotype)
    eco_paramNames <- intersect(param_names, eco_params)
    for (param in eco_paramNames) eco[[param]][idx] <- param_values[param]
    attr(eco, "comments") <- NULL
    DSSAT::write_eco(eco, file.path(ecotype_path, ecotype_filename))
  }
  
  # --- cultivar ---
  cul <- DSSAT::read_cul(file.path(cultivar_path, cultivar_filename))
  cul_params <- names(cul)
  flag_cul_param <- any(param_names %in% cul_params)
  
  if (flag_cul_param) {
    file.copy(file.path(cultivar_path, cultivar_filename),
              file.path(cultivar_path, paste0(cultivar_filename, "_tmp")),
              overwrite = TRUE)
    idx <- which(cul$`VAR-NAME` == cultivar)
    if (length(idx) == 0) warning("⚠ Cultivar not found in CUL by VAR-NAME: ", cultivar)
    cul_paramNames <- intersect(param_names, cul_params)
    for (param in cul_paramNames) {
      if (is.character(cul[[param]])) {
        cul[[param]][idx] <- as.character(round(param_values[[param]], 2))
      } else {
        cul[[param]][idx] <- param_values[param]
      }
    }
    DSSAT::write_cul(cul, file.path(cultivar_path, cultivar_filename))
  }
  
  on.exit({
    if (flag_eco_param) file.rename(file.path(ecotype_path, paste0(ecotype_filename, "_tmp")),
                                    file.path(ecotype_path, ecotype_filename))
    if (flag_cul_param) file.rename(file.path(cultivar_path, paste0(cultivar_filename, "_tmp")),
                                    file.path(cultivar_path, cultivar_filename))
  }, add = TRUE)
  
  # --- run DSSAT ---
  setwd(project_path)
  
  tmp <- t(dplyr::bind_rows(sapply(situations, FUN = strsplit, "_")))
  if (ncol(tmp) < 2) stop("❌ Situation names must be Experiment_TRNO (e.g., GMZA2001_1).")
  
  experiment_files <- paste0(tmp[,1], ".", crop_code, "X")
  TRNO <- as.integer(tmp[,2])
  
  batch <- data.frame(FILEX = experiment_files, TRTNO = TRNO, RP=1, SQ=0, OP=0, CO=0)
  DSSAT::write_dssbatch(x = batch)
  DSSAT::run_dssat(suppress_output = suppress_output)
  
  if (file.exists(file.path(project_path, "ERROR.OUT"))) {
    warning("⚠ DSSAT produced ERROR.OUT. Check: ", file.path(project_path, "ERROR.OUT"))
  }
  
  invisible(TRUE)
}

################################################################################
# 10) Read simulated yield from Evaluate.OUT (robust columns)
################################################################################
read_eval_yield <- function(DSSAT_PATH, crop = "Wheat") {
  
  eval_path <- file.path(DSSAT_PATH, crop, "Evaluate.OUT")
  if (!file.exists(eval_path)) return(NULL)
  
  ev <- as.data.frame(DSSAT::read_output(eval_path))
  
  # Build EXPERIMENT
  if ("EXCODE" %in% names(ev)) {
    ev$EXPERIMENT <- substr(ev$EXCODE, 1, nchar(ev$EXCODE) - 2)  # remove crop code suffix
  } else if ("EXPERIMENT" %in% names(ev)) {
    # ok
  } else {
    stop("❌ Evaluate.OUT read, but cannot find EXCODE/EXPERIMENT column.")
  }
  
  # Find simulated yield column
  # Most common: HWAMS (simulated grain yield, kg/ha)
  # Alternative: HWAHS
  cand <- c("HWAMS","HWAHS","HWAM","HWAH")
  ycol <- cand[cand %in% names(ev)][1]
  if (is.na(ycol)) {
    stop("❌ Evaluate.OUT found, but no simulated yield column among: ",
         paste(cand, collapse = ", "), "\nColumns are:\n", paste(names(ev), collapse=", "))
  }
  
  ev %>%
    select(EXPERIMENT, TRNO, HWAM_sim = all_of(ycol)) %>%
    mutate(TRNO = as.integer(TRNO)) %>%
    filter(!is.na(TRNO), is.finite(HWAM_sim))
}

################################################################################
# 11) Objective function: RMSE + optional coverage penalty
################################################################################
rmse_all <- function(p,
                     coverage_floor = 0.85,
                     penalty_scale  = 5000,
                     debug = FALSE) {
  
  p <- as.numeric(p)
  names(p) <- names(init_params)
  
  ok <- tryCatch({
    run_dssat_yield_only(
      param_values  = p,
      situations    = situations,
      model_options = model_options
    )
    TRUE
  }, error = function(e) {
    cat("\n❌ DSSAT run failed:", conditionMessage(e), "\n")
    FALSE
  })
  if (!ok) return(1e6)
  
  sim_all <- read_eval_yield(DSSAT_PATH, crop="Wheat")
  if (is.null(sim_all) || nrow(sim_all) == 0) return(1e6)
  
  sim_all <- sim_all %>%
    mutate(
      SITE = ifelse(grepl("^GMZA", EXPERIMENT, ignore.case = TRUE), "GMZA", "SIDS")
    ) %>%
    select(SITE, TRNO, HWAM_sim) %>%
    group_by(SITE, TRNO) %>%
    summarise(HWAM_sim = max(HWAM_sim, na.rm = TRUE), .groups = "drop")
  
  df <- inner_join(obs_all, sim_all, by = c("SITE","TRNO"))
  if (nrow(df) == 0) return(1e6)
  
  rmse <- sqrt(mean((df$HWAM_sim - df$HWAM_obs)^2, na.rm = TRUE))
  
  cov_tab <- obs_all %>%
    group_by(SITE) %>%
    summarise(
      n_obs   = n_distinct(TRNO),
      n_match = sum(TRNO %in% df$TRNO[SITE == cur_group()$SITE]),
      .groups = "drop"
    ) %>%
    mutate(coverage = ifelse(n_obs > 0, n_match / n_obs, 0))
  
  overall_cov <- with(cov_tab, sum(n_match) / sum(n_obs))
  if (!is.finite(overall_cov)) overall_cov <- 0
  
  penalty <- if (overall_cov < coverage_floor) {
    penalty_scale * (coverage_floor - overall_cov) / coverage_floor
  } else 0
  
  if (debug) {
    cat("\n--- DEBUG OBJECTIVE ---\n")
    cat("RMSE:", rmse, "\n")
    cat("Coverage:", round(overall_cov, 3), "\n")
    cat("Penalty:", round(penalty, 1), "\n")
    print(cov_tab)
    cat("Joined rows:", nrow(df), "\n")
  }
  
  as.numeric(rmse + penalty)
}

################################################################################
# 12) TEST RUN (MANDATORY)
################################################################################
cat("Running test objective with initial parameters...\n")
test_obj <- rmse_all(init_params, debug = TRUE)
cat("\nTest objective =", test_obj, "\n\n")
if (!is.finite(test_obj) || test_obj > 1e5) {
  stop("❌ Test failed (objective too large). Check DSSAT Wheat/ERROR.OUT and Evaluate.OUT.")
}

################################################################################
# 13) OPTIMIZATION (Nelder–Mead)
################################################################################
cat("Starting calibration (neldermead)...\n")

param_names <- names(init_params)
x0 <- as.numeric(init_params)
lb <- as.numeric(lower[param_names])
ub <- as.numeric(upper[param_names])

eval_count <- 0
fn <- function(x) {
  eval_count <<- eval_count + 1
  val <- rmse_all(x, debug = FALSE)
  if (eval_count %% 5 == 0) cat(sprintf("\n[%03d] Obj = %.2f", eval_count, val)) else cat(".")
  if (!is.finite(val) || length(val) != 1) val <- 1e6
  val
}

start_time <- Sys.time()

res <- nloptr::neldermead(
  x0 = x0,
  fn = fn,
  lower = lb,
  upper = ub,
  control = list(maxeval = 200, xtol_rel = 1e-4)
)

end_time <- Sys.time()
elapsed <- difftime(end_time, start_time, units = "mins")

cat("\n\n============================================================\n")
cat("CALIBRATION COMPLETED\n")
cat("============================================================\n")
cat("Time (min):", round(elapsed, 2), "\n")
cat("Evaluations:", eval_count, "\n")
cat("Initial obj:", round(test_obj, 2), "\n")
cat("Final obj  :", round(res$value, 2), "\n\n")

calibrated_params <- setNames(res$par, param_names)

param_table <- data.frame(
  Parameter  = param_names,
  Initial    = as.numeric(init_params),
  Calibrated = as.numeric(calibrated_params),
  Change     = as.numeric(calibrated_params) - as.numeric(init_params),
  stringsAsFactors = FALSE
)
print(param_table, row.names = FALSE)

################################################################################
# 14) SAVE RESULTS
################################################################################
out_dir <- file.path(WORKDIR, "Sakha95_WHAPS_results")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

write.csv(param_table, file.path(out_dir, "calibrated_parameters_WHAPS.csv"), row.names = FALSE)
save(res, param_table, calibrated_params, model_options, file = file.path(out_dir, "calibration_WHAPS.RData"))

cat("\n✓ Results saved to:", out_dir, "\n\n")

################################################################################
# 15) PLOT OBS vs SIM (Evaluate.OUT)
################################################################################
plot_obs_sim <- function(p) {
  
  run_dssat_yield_only(
    param_values  = setNames(as.numeric(p), names(init_params)),
    situations    = situations,
    model_options = model_options
  )
  
  sim_all <- read_eval_yield(DSSAT_PATH, crop="Wheat") %>%
    mutate(SITE = ifelse(grepl("^GMZA", EXPERIMENT, ignore.case = TRUE), "GMZA", "SIDS")) %>%
    select(SITE, TRNO, HWAM_sim) %>%
    group_by(SITE, TRNO) %>%
    summarise(HWAM_sim = max(HWAM_sim, na.rm = TRUE), .groups="drop")
  
  df <- inner_join(obs_all, sim_all, by = c("SITE","TRNO"))
  
  ggplot(df, aes(HWAM_obs, HWAM_sim, color = SITE)) +
    geom_point(size = 3) +
    geom_abline(slope = 1, intercept = 0, linetype = 2) +
    theme_classic(base_size = 14) +
    labs(
      x = "Observed yield (kg/ha)",
      y = "Simulated yield (kg/ha)",
      title = "WHAPS calibration – Sakha95 (Evaluate.OUT)"
    )
}

print(plot_obs_sim(calibrated_params))

cat("\nNEXT STEPS:\n")
cat("1) Update WHAPS048.CUL line for Sakha95 (VAR# ", cultivar_code, ") with calibrated parameters.\n", sep="")
cat("2) Check DSSAT/Wheat/Evaluate.OUT to confirm yield column used (HWAMS/HWAHS).\n")
cat("Done.\n")

################################################################################
# END
################################################################################
