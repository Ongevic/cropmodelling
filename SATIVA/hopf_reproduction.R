suppressPackageStartupMessages({
  required_packages <- c("DSSAT", "dplyr", "tidyr", "readr", "lubridate", "purrr")
  missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing_packages) > 0) {
    stop(
      "Missing required R package(s): ",
      paste(missing_packages, collapse = ", "),
      ". Install them before running hopf_reproduction.R."
    )
  }

  library("DSSAT")
  library("dplyr")
  library("tidyr")
  library("readr")
  library("lubridate")
  library("purrr")
})

resolve_wrapper_repo <- function() {
  env_path <- Sys.getenv("DSSAT_WRAPPER_REPO", unset = "")
  candidates <- c(
    env_path,
    "C:/Users/chich/Downloads/DSSAT-wrapper"
  )
  for (candidate in candidates) {
    if (nzchar(candidate) && file.exists(file.path(candidate, "R", "DSSAT_omniwrapper.R"))) {
      return(normalizePath(candidate, winslash = "/", mustWork = TRUE))
    }
  }
  stop("Could not locate DSSAT-wrapper. Set the DSSAT_WRAPPER_REPO environment variable.")
}

resolve_sativa_dir <- function() {
  script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (length(script_arg) == 0) {
    return(normalizePath(getwd(), winslash = "/", mustWork = TRUE))
  }
  normalizePath(dirname(sub("^--file=", "", script_arg[1])), winslash = "/", mustWork = TRUE)
}

yyddd_to_date <- function(x) {
  x <- suppressWarnings(as.integer(x))
  out <- rep(as.Date(NA), length(x))
  keep <- !is.na(x)
  years <- ifelse((x[keep] %/% 1000) <= 30, 2000L + (x[keep] %/% 1000), 1900L + (x[keep] %/% 1000))
  out[keep] <- lubridate::make_date(years, 1, 1) + lubridate::days((x[keep] %% 1000) - 1)
  out
}

normalize_dssat_date <- function(x) {
  if (inherits(x, "Date")) {
    return(x)
  }
  if (inherits(x, "POSIXt")) {
    return(as.Date(x))
  }
  yyddd_to_date(x)
}

willmott_d <- function(obs, sim) {
  keep <- stats::complete.cases(obs, sim)
  obs <- obs[keep]
  sim <- sim[keep]
  if (length(obs) == 0) {
    return(NA_real_)
  }
  obs_mean <- mean(obs)
  denom <- sum((abs(sim - obs_mean) + abs(obs - obs_mean))^2)
  if (denom == 0) {
    return(NA_real_)
  }
  1 - sum((sim - obs)^2) / denom
}

rmse_value <- function(obs, sim) {
  keep <- stats::complete.cases(obs, sim)
  obs <- obs[keep]
  sim <- sim[keep]
  if (length(obs) == 0) {
    return(NA_real_)
  }
  sqrt(mean((sim - obs)^2))
}

extract_sim_flowering_date <- function(sim_df) {
  if (!("Date" %in% names(sim_df))) {
    return(as.Date(NA))
  }

  if ("ADAP" %in% names(sim_df)) {
    adap <- unique(stats::na.omit(sim_df$ADAP))
    if (length(adap) > 0) {
      idx <- which(sim_df$DAP == adap[1])
      if (length(idx) > 0) {
        return(sim_df$Date[idx[1]])
      }
      return(min(sim_df$Date, na.rm = TRUE) + adap[1])
    }
  }

  as.Date(NA)
}

average_obs_by_date <- function(obs_df) {
  numeric_cols <- names(obs_df)[vapply(obs_df, is.numeric, logical(1))]
  obs_df %>%
    dplyr::group_by(Date) %>%
    dplyr::summarise(
      dplyr::across(dplyr::all_of(numeric_cols), ~ mean(.x, na.rm = TRUE)),
      .groups = "drop"
    ) %>%
    dplyr::mutate(dplyr::across(dplyr::all_of(numeric_cols), ~ dplyr::na_if(.x, NaN)))
}

sativa_dir <- resolve_sativa_dir()
wrapper_repo <- resolve_wrapper_repo()
dssat_csm_data <- file.path(sativa_dir, "dssat-csm-data")
output_dir <- file.path(sativa_dir, "hopf_reproduction_outputs")
dir.create(output_dir, showWarnings = FALSE)

source(file.path(wrapper_repo, "R", "DSSAT_omniwrapper.R"))

paper_cases <- tibble::tribble(
  ~simulation_no, ~experiment, ~trno, ~site,  ~year, ~cultivar,                ~nitrogen_kg_ha, ~planting_date,        ~density_plants_m2,
  1,              "UFCI2101",  1L,    "PSREU", 2021, "IH Williams",             280,             "2021-05-05",          53.8,
  2,              "UFCI2101",  2L,    "PSREU", 2021, "NWG 2730",                  0,             "2021-05-05",          64.0,
  3,              "UFCI2101",  3L,    "PSREU", 2021, "NWG 2730",                280,             "2021-05-05",          60.5,
  4,              "UFCI2201",  1L,    "PSREU", 2022, "IH Williams",               0,             "2022-05-04",          50.7,
  5,              "UFCI2201",  2L,    "PSREU", 2022, "IH Williams",             280,             "2022-05-04",          40.8,
  6,              "UFCI2201",  3L,    "PSREU", 2022, "NWG 2730",                  0,             "2022-05-04",          30.5,
  7,              "UFCI2201",  4L,    "PSREU", 2022, "NWG 2730",                168,             "2022-05-04",          40.5,
  8,              "UFJA2101",  1L,    "WFREC", 2021, "IH Williams",               0,             "2021-05-26",          66.8,
  9,              "UFJA2101",  2L,    "WFREC", 2021, "IH Williams",             224,             "2021-05-26",          68.6,
  10,             "UFJA2101",  3L,    "WFREC", 2021, "NWG 2730",                  0,             "2021-05-26",          71.5,
  11,             "UFJA2101",  4L,    "WFREC", 2021, "NWG 2730",                112,             "2021-05-26",          71.5,
  12,             "UFJA2201",  1L,    "WFREC", 2022, "IH Williams",               0,             "2022-05-13",          99.9,
  13,             "UFJA2201",  2L,    "WFREC", 2022, "IH Williams",             280,             "2022-05-13",          71.9,
  14,             "UFJA2201",  3L,    "WFREC", 2022, "NWG 2730",                  0,             "2022-05-13",          69.8,
  15,             "UFJA2201",  4L,    "WFREC", 2022, "NWG 2730",                280,             "2022-05-13",          82.8
) %>%
  dplyr::mutate(
    project_file = file.path(dssat_csm_data, "Hemp", paste0(experiment, ".HMX")),
    situation = paste0(experiment, "_", trno),
    planting_date = as.Date(planting_date)
  )

read_case <- function(case_row) {
  model_options <- list(
    DSSAT_path = "C:/DSSAT48",
    DSSAT_exe = "DSCSM048.EXE",
    project_file = case_row$project_file,
    suppress_output = TRUE
  )

  sim_result <- DSSAT_omniwrapper(
    model_options = model_options,
    situation = case_row$situation
  )
  obs_result <- DSSAT_omni_read_obs(
    model_options = model_options,
    situation = case_row$situation,
    read_end_season = TRUE
  )

  raw_obs_df <- obs_result[[case_row$situation]]
  sim_df <- sim_result$sim_list[[case_row$situation]] %>%
    dplyr::mutate(Date = as.Date(Date))
  obs_df <- average_obs_by_date(raw_obs_df)
  obs_df$Date <- normalize_dssat_date(obs_df$Date)
  if ("ADAT" %in% names(obs_df)) {
    obs_df$ADAT <- normalize_dssat_date(obs_df$ADAT)
  }

  obs_flowering_date <- as.Date(NA)
  if ("ADAT" %in% names(raw_obs_df)) {
    raw_adat <- unique(stats::na.omit(normalize_dssat_date(raw_obs_df$ADAT)))
    if (length(raw_adat) > 0) {
      obs_flowering_date <- as.Date(raw_adat[1])
    }
  }

  list(sim = sim_df, obs = obs_df, obs_flowering_date = obs_flowering_date)
}

case_results <- purrr::map(
  split(paper_cases, seq_len(nrow(paper_cases))),
  read_case
)

names(case_results) <- paper_cases$situation

comparison_vars <- c("CWAD", "SWAD", "GWAD", "CHTD", "CWID", "L#SD", "GSTD", "PWAD", "RDPD", "RWAD")

joined_timeseries <- purrr::map2_dfr(
  case_results,
  paper_cases$situation,
  function(case_result, situation_name) {
    sim_df <- case_result$sim
    obs_df <- case_result$obs
    common_vars <- intersect(intersect(names(sim_df), names(obs_df)), comparison_vars)
    if (length(common_vars) == 0) {
      return(NULL)
    }

    joined <- dplyr::full_join(
      dplyr::select(sim_df, Date, dplyr::all_of(common_vars)),
      dplyr::select(obs_df, Date, dplyr::all_of(common_vars)),
      by = "Date",
      suffix = c("_sim", "_obs")
    )

    joined$situation <- situation_name
    joined
  }
) %>%
  dplyr::left_join(dplyr::select(paper_cases, simulation_no, situation, experiment, trno, site, year, cultivar, nitrogen_kg_ha, density_plants_m2), by = "situation")

per_case_metrics <- purrr::map2_dfr(
  case_results,
  seq_len(nrow(paper_cases)),
  function(case_result, idx) {
    case_row <- paper_cases[idx, ]
    sim_df <- case_result$sim
    obs_df <- case_result$obs
    common_vars <- intersect(intersect(names(sim_df), names(obs_df)), comparison_vars)

    metrics <- purrr::map_dfr(common_vars, function(var_name) {
      joined <- dplyr::full_join(
        dplyr::select(sim_df, Date, sim = dplyr::all_of(var_name)),
        dplyr::select(obs_df, Date, obs = dplyr::all_of(var_name)),
        by = "Date"
      ) %>%
        dplyr::filter(stats::complete.cases(obs, sim))

      tibble::tibble(
        simulation_no = case_row$simulation_no,
        situation = case_row$situation,
        experiment = case_row$experiment,
        variable = var_name,
        n_pairs = nrow(joined),
        d = willmott_d(joined$obs, joined$sim),
        rmse = rmse_value(joined$obs, joined$sim),
        obs_mean = if (nrow(joined) > 0) mean(joined$obs) else NA_real_,
        sim_mean = if (nrow(joined) > 0) mean(joined$sim) else NA_real_
      )
    })

    obs_anthesis_date <- case_result$obs_flowering_date
    sim_anthesis_date <- extract_sim_flowering_date(sim_df)

    metrics$obs_flowering_date <- obs_anthesis_date
    metrics$sim_flowering_date <- sim_anthesis_date
    metrics$flowering_diff_days <- as.numeric(sim_anthesis_date - obs_anthesis_date)
    metrics
  }
)

overall_metrics <- joined_timeseries %>%
  tidyr::pivot_longer(
    cols = tidyselect::matches("_(sim|obs)$"),
    names_to = c("variable", ".value"),
    names_pattern = "^(.*)_(sim|obs)$"
  ) %>%
  dplyr::filter(stats::complete.cases(obs, sim)) %>%
  dplyr::group_by(variable) %>%
  dplyr::summarise(
    n_pairs = dplyr::n(),
    d = willmott_d(obs, sim),
    rmse = rmse_value(obs, sim),
    obs_mean = mean(obs),
    sim_mean = mean(sim),
    .groups = "drop"
  )

flowering_summary <- per_case_metrics %>%
  dplyr::distinct(
    simulation_no,
    situation,
    experiment,
    obs_flowering_date,
    sim_flowering_date,
    flowering_diff_days
  ) %>%
  dplyr::left_join(
    dplyr::select(paper_cases, simulation_no, site, year, cultivar, nitrogen_kg_ha),
    by = "simulation_no"
  )

readr::write_csv(paper_cases, file.path(output_dir, "hopf_cases.csv"))
readr::write_csv(joined_timeseries, file.path(output_dir, "hopf_joined_timeseries.csv"))
readr::write_csv(per_case_metrics, file.path(output_dir, "hopf_metrics_by_case.csv"))
readr::write_csv(overall_metrics, file.path(output_dir, "hopf_metrics_overall.csv"))
readr::write_csv(flowering_summary, file.path(output_dir, "hopf_flowering_summary.csv"))

cat("Hopf reproduction files written to:", output_dir, "\n")
cat("Overall metrics:\n")
print(overall_metrics)
cat("\nFlowering summary:\n")
print(flowering_summary)
