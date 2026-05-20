suppressPackageStartupMessages({
  library(DSSAT)
  library(dplyr)
  library(purrr)
  library(readr)
  library(tidyr)
})

source("C:/Users/chich/Downloads/DSSAT-wrapper/R/DSSAT_omniwrapper.R")

cases <- tibble::tribble(
  ~simulation_no, ~situation, ~project_file, ~site, ~year,
  1,  "UFCI2101_1", "C:/Users/chich/Downloads/DSSAT Files/sativa/dssat-csm-data/Hemp/UFCI2101.HMX", "PSREU", 2021,
  2,  "UFCI2101_2", "C:/Users/chich/Downloads/DSSAT Files/sativa/dssat-csm-data/Hemp/UFCI2101.HMX", "PSREU", 2021,
  3,  "UFCI2101_3", "C:/Users/chich/Downloads/DSSAT Files/sativa/dssat-csm-data/Hemp/UFCI2101.HMX", "PSREU", 2021,
  4,  "UFCI2201_1", "C:/Users/chich/Downloads/DSSAT Files/sativa/dssat-csm-data/Hemp/UFCI2201.HMX", "PSREU", 2022,
  5,  "UFCI2201_2", "C:/Users/chich/Downloads/DSSAT Files/sativa/dssat-csm-data/Hemp/UFCI2201.HMX", "PSREU", 2022,
  6,  "UFCI2201_3", "C:/Users/chich/Downloads/DSSAT Files/sativa/dssat-csm-data/Hemp/UFCI2201.HMX", "PSREU", 2022,
  7,  "UFCI2201_4", "C:/Users/chich/Downloads/DSSAT Files/sativa/dssat-csm-data/Hemp/UFCI2201.HMX", "PSREU", 2022,
  8,  "UFJA2101_1", "C:/Users/chich/Downloads/DSSAT Files/sativa/dssat-csm-data/Hemp/UFJA2101.HMX", "WFREC", 2021,
  9,  "UFJA2101_2", "C:/Users/chich/Downloads/DSSAT Files/sativa/dssat-csm-data/Hemp/UFJA2101.HMX", "WFREC", 2021,
  10, "UFJA2101_3", "C:/Users/chich/Downloads/DSSAT Files/sativa/dssat-csm-data/Hemp/UFJA2101.HMX", "WFREC", 2021,
  11, "UFJA2101_4", "C:/Users/chich/Downloads/DSSAT Files/sativa/dssat-csm-data/Hemp/UFJA2101.HMX", "WFREC", 2021,
  12, "UFJA2201_1", "C:/Users/chich/Downloads/DSSAT Files/sativa/dssat-csm-data/Hemp/UFJA2201.HMX", "WFREC", 2022,
  13, "UFJA2201_2", "C:/Users/chich/Downloads/DSSAT Files/sativa/dssat-csm-data/Hemp/UFJA2201.HMX", "WFREC", 2022,
  14, "UFJA2201_3", "C:/Users/chich/Downloads/DSSAT Files/sativa/dssat-csm-data/Hemp/UFJA2201.HMX", "WFREC", 2022,
  15, "UFJA2201_4", "C:/Users/chich/Downloads/DSSAT Files/sativa/dssat-csm-data/Hemp/UFJA2201.HMX", "WFREC", 2022
)

willmott_d <- function(obs, sim) {
  keep <- complete.cases(obs, sim)
  obs <- obs[keep]
  sim <- sim[keep]
  if (!length(obs)) return(NA_real_)
  obs_mean <- mean(obs)
  denom <- sum((abs(sim - obs_mean) + abs(obs - obs_mean))^2)
  if (denom == 0) return(NA_real_)
  1 - sum((sim - obs)^2) / denom
}

rmse_value <- function(obs, sim) {
  keep <- complete.cases(obs, sim)
  obs <- obs[keep]
  sim <- sim[keep]
  if (!length(obs)) return(NA_real_)
  sqrt(mean((sim - obs)^2))
}

load_case <- function(situation, project_file) {
  model_options <- list(
    DSSAT_path = "C:/DSSAT48",
    DSSAT_exe = "DSCSM048.EXE",
    project_file = project_file,
    suppress_output = TRUE
  )
  list(
    sim = DSSAT_omniwrapper(model_options = model_options, situation = situation)$sim_list[[situation]] %>% mutate(Date = as.Date(Date)),
    obs = DSSAT_omni_read_obs(model_options = model_options, situation = situation, read_end_season = TRUE)[[1]] %>% mutate(Date = as.Date(Date))
  )
}

loaded <- purrr::pmap(cases[, c("situation", "project_file")], load_case)
names(loaded) <- cases$situation

build_rows <- function(variable, protocol = c("raw_replicates", "date_means")) {
  protocol <- match.arg(protocol)
  purrr::map2_dfr(loaded, names(loaded), function(case_obj, situation_name) {
    obs <- case_obj$obs
    sim <- case_obj$sim
    if (!(variable %in% names(obs)) || !(variable %in% names(sim))) {
      return(NULL)
    }

    if (protocol == "raw_replicates") {
      out <- obs %>%
        filter(!is.na(.data[[variable]])) %>%
        left_join(sim %>% select(Date, sim = all_of(variable)), by = "Date") %>%
        transmute(situation = situation_name, Date, obs = .data[[variable]], sim)
    } else {
      out <- obs %>%
        filter(!is.na(.data[[variable]])) %>%
        group_by(Date) %>%
        summarise(obs = mean(.data[[variable]], na.rm = TRUE), .groups = "drop") %>%
        left_join(sim %>% select(Date, sim = all_of(variable)), by = "Date") %>%
        transmute(situation = situation_name, Date, obs, sim)
    }
    out
  }) %>%
    left_join(cases %>% select(situation, simulation_no, site, year), by = "situation")
}

summarise_protocol <- function(variable, protocol) {
  rows <- build_rows(variable, protocol)
  tibble(
    variable = variable,
    protocol = protocol,
    n_pairs = sum(complete.cases(rows$obs, rows$sim)),
    d = willmott_d(rows$obs, rows$sim),
    rmse = rmse_value(rows$obs, rows$sim)
  )
}

protocol_summary <- bind_rows(
  summarise_protocol("CWAD", "raw_replicates"),
  summarise_protocol("CWAD", "date_means"),
  summarise_protocol("SWAD", "raw_replicates"),
  summarise_protocol("SWAD", "date_means")
)

by_site_year <- bind_rows(
  purrr::map_dfr(c("CWAD", "SWAD"), function(variable) {
    rows <- build_rows(variable, "date_means")
    rows %>%
      filter(is.finite(obs), is.finite(sim)) %>%
      group_by(variable = variable, site, year) %>%
      summarise(
        n_pairs = n(),
        d = willmott_d(obs, sim),
        rmse = rmse_value(obs, sim),
        .groups = "drop"
      )
  })
)

flowering_summary <- read_csv(
  "C:/Users/chich/Downloads/DSSAT Files/sativa/hopf_reproduction_outputs/hopf_flowering_summary.csv",
  show_col_types = FALSE
)

report_path <- "C:/Users/chich/Downloads/DSSAT Files/sativa/HOPF_PROTOCOL_AUDIT.md"
report_lines <- c(
  "# Hopf Protocol Audit",
  "",
  "This note compares multiple reasonable metric protocols against the published headline values in Hopf et al. (2025).",
  "",
  "Published abstract targets:",
  "",
  "- aboveground biomass: `d = 0.91`, `RMSE = 482 kg ha-1`",
  "- stem weight: `d = 0.83`, `RMSE = 430 kg ha-1`",
  "- flowering difference range: `+4 to -5 days`",
  "",
  "## Protocol comparison",
  "",
  paste(apply(protocol_summary, 1, function(r) sprintf(
    "- `%s` with `%s`: `n = %s`, `d = %.3f`, `RMSE = %.1f`",
    r[["variable"]], r[["protocol"]], r[["n_pairs"]], as.numeric(r[["d"]]), as.numeric(r[["rmse"]])
  )), collapse = "\n"),
  "",
  "## Site-year date-mean comparison",
  "",
  paste(apply(by_site_year, 1, function(r) sprintf(
    "- `%s`, `%s %s`: `n = %s`, `d = %.3f`, `RMSE = %.1f`",
    r[["variable"]], r[["site"]], r[["year"]], r[["n_pairs"]], as.numeric(r[["d"]]), as.numeric(r[["rmse"]])
  )), collapse = "\n"),
  "",
  "## Flowering-date comparison",
  "",
  sprintf(
    "- Current reproduced flowering range: `%+d` to `%+d` days",
    min(flowering_summary$flowering_diff_days, na.rm = TRUE),
    max(flowering_summary$flowering_diff_days, na.rm = TRUE)
  ),
  "",
  "## Interpretation",
  "",
  "- `date_means` produces lower RMSE and much higher `d` than the published abstract values.",
  "- `raw_replicates` lowers `d` in the expected direction, but RMSE becomes much larger than the published values.",
  "- The published protocol therefore appears to be more selective than simple pooled date means, but less noisy than raw replicate pooling.",
  "- The paper text confirms that metrics were based on `observed and simulated periodic harvests`, while some non-destructive measurements were also collected on standing plants.",
  "- That suggests the next accuracy step is to isolate the exact destructive-harvest subset used by the authors rather than pooling every compatible date-value pair.",
  "",
  "## Most likely next refinement",
  "",
  "Build a harvest-only comparison table from the raw `.HMT` observations by identifying dates where destructive biomass sampling occurred, then recompute `CWAD` and `SWAD` metrics on that restricted subset."
)

writeLines(report_lines, report_path)
readr::write_csv(protocol_summary, "C:/Users/chich/Downloads/DSSAT Files/sativa/hopf_protocol_summary.csv")
readr::write_csv(by_site_year, "C:/Users/chich/Downloads/DSSAT Files/sativa/hopf_protocol_by_site_year.csv")

cat("Protocol audit written to:", report_path, "\n")
print(protocol_summary)
