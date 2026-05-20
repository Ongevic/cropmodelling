suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tidyr)
  library(purrr)
  library(stringr)
})

base_dir <- "C:/Users/chich/Downloads/DSSAT Files/sativa"
output_dir <- file.path(base_dir, "hopf_reproduction_outputs")

paper_targets <- list(
  CWAD = list(d = 0.91, rmse = 482),
  SWAD = list(d = 0.83, rmse = 430)
)

willmott_d <- function(obs, sim) {
  keep <- complete.cases(obs, sim)
  obs <- obs[keep]
  sim <- sim[keep]
  if (!length(obs)) {
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
  keep <- complete.cases(obs, sim)
  obs <- obs[keep]
  sim <- sim[keep]
  if (!length(obs)) {
    return(NA_real_)
  }
  sqrt(mean((sim - obs)^2))
}

score_against_targets <- function(cwad_d, cwad_rmse, swad_d, swad_rmse) {
  sqrt(
    ((cwad_d - paper_targets$CWAD$d) / paper_targets$CWAD$d)^2 +
      ((cwad_rmse - paper_targets$CWAD$rmse) / paper_targets$CWAD$rmse)^2 +
      ((swad_d - paper_targets$SWAD$d) / paper_targets$SWAD$d)^2 +
      ((swad_rmse - paper_targets$SWAD$rmse) / paper_targets$SWAD$rmse)^2
  )
}

cases <- read_csv(
  file.path(output_dir, "hopf_cases.csv"),
  show_col_types = FALSE
) %>%
  mutate(
    nitrogen_label = paste0(nitrogen_kg_ha, " kg N ha-1"),
    case_label = paste0(
      situation, " (", site, " ", year, ", ", cultivar, ", ", nitrogen_label, ")"
    )
  )

harvest_summary <- read_csv(
  file.path(output_dir, "hopf_hmt_harvest_summary.csv"),
  show_col_types = FALSE
) %>%
  rename(trno = TRNO, experiment = experiment) %>%
  left_join(cases %>% select(situation, experiment, trno), by = c("experiment", "trno")) %>%
  mutate(Date = as.Date(Date))

joined_timeseries <- read_csv(
  file.path(output_dir, "hopf_joined_timeseries.csv"),
  show_col_types = FALSE
) %>%
  mutate(Date = as.Date(Date))

build_variable_rows <- function(variable) {
  obs_col <- variable
  sim_col <- paste0(variable, "_sim")
  harvest_summary %>%
    filter(!is.na(.data[[obs_col]]), !is.na(situation)) %>%
    transmute(situation, Date, obs = .data[[obs_col]]) %>%
    left_join(
      joined_timeseries %>%
        select(situation, Date, sim = all_of(sim_col)),
      by = c("situation", "Date")
    ) %>%
    filter(!is.na(obs), !is.na(sim)) %>%
    left_join(
      cases %>%
        select(
          situation, simulation_no, experiment, trno, site, year,
          cultivar, nitrogen_kg_ha, case_label
        ),
      by = "situation"
    )
}

cwad_rows <- build_variable_rows("CWAD")
swad_rows <- build_variable_rows("SWAD")

metric_summary <- function(subset_situations) {
  cwad_subset <- cwad_rows %>% filter(situation %in% subset_situations)
  swad_subset <- swad_rows %>% filter(situation %in% subset_situations)

  cwad_d <- willmott_d(cwad_subset$obs, cwad_subset$sim)
  cwad_rmse <- rmse_value(cwad_subset$obs, cwad_subset$sim)
  swad_d <- willmott_d(swad_subset$obs, swad_subset$sim)
  swad_rmse <- rmse_value(swad_subset$obs, swad_subset$sim)

  tibble(
    n_cases = length(subset_situations),
    cwad_n = nrow(cwad_subset),
    cwad_d = cwad_d,
    cwad_rmse = cwad_rmse,
    swad_n = nrow(swad_subset),
    swad_d = swad_d,
    swad_rmse = swad_rmse,
    score = score_against_targets(cwad_d, cwad_rmse, swad_d, swad_rmse)
  )
}

all_situations <- cases$situation

all_case_metrics <- metric_summary(all_situations) %>%
  mutate(
    subset_type = "all_15",
    included = paste(all_situations, collapse = "; "),
    excluded = ""
  )

leave_one_out <- map_dfr(all_situations, function(drop_situation) {
  keep <- setdiff(all_situations, drop_situation)
  metric_summary(keep) %>%
    mutate(
      subset_type = "leave_one_out",
      included = paste(keep, collapse = "; "),
      excluded = drop_situation
    )
})

compute_subset_metrics <- function(min_cases = 8L) {
  total_masks <- bitwShiftL(1L, length(all_situations)) - 1L
  results <- vector("list", total_masks)
  counter <- 1L

  for (mask in seq_len(total_masks)) {
    include_idx <- which(as.logical(intToBits(mask)[seq_along(all_situations)]))
    if (length(include_idx) < min_cases) {
      next
    }
    subset_situations <- all_situations[include_idx]
    excluded_situations <- setdiff(all_situations, subset_situations)
    results[[counter]] <- metric_summary(subset_situations) %>%
      mutate(
        subset_type = paste0("subset_min_", min_cases),
        included = paste(subset_situations, collapse = "; "),
        excluded = paste(excluded_situations, collapse = "; ")
      )
    counter <- counter + 1L
  }

  bind_rows(results)
}

subsets_min_8 <- compute_subset_metrics(8L)
subsets_min_10 <- compute_subset_metrics(10L)
subsets_min_12 <- compute_subset_metrics(12L)

ranked_candidates <- bind_rows(subsets_min_8, subsets_min_10, subsets_min_12) %>%
  arrange(score, desc(n_cases))

top_candidates <- ranked_candidates %>%
  group_by(subset_type) %>%
  slice_head(n = 15) %>%
  ungroup()

best_overall <- ranked_candidates %>% slice_head(n = 1)
best_min_10 <- subsets_min_10 %>% arrange(score, desc(n_cases)) %>% slice_head(n = 1)
best_min_12 <- subsets_min_12 %>% arrange(score, desc(n_cases)) %>% slice_head(n = 1)

excluded_frequency <- top_candidates %>%
  mutate(excluded = str_split(excluded, ";\\s*")) %>%
  unnest(excluded) %>%
  filter(excluded != "") %>%
  count(subset_type, excluded, sort = TRUE) %>%
  left_join(
    cases %>% select(
      situation, site, year, cultivar, nitrogen_kg_ha, case_label
    ),
    by = c("excluded" = "situation")
  )

top_exclusion_lines <- excluded_frequency %>%
  slice_head(n = 8) %>%
  transmute(
    line = sprintf(
      "- `%s`: excluded in `%s` top-ranked subsets for `%s`",
      excluded,
      n,
      subset_type
    )
  ) %>%
  pull(line)

simple_group_checks <- bind_rows(
  cases %>%
    group_by(site, year) %>%
    summarise(
      subset_name = paste0("keep_site_year_", first(site), "_", first(year)),
      situations = list(situation),
      .groups = "drop"
    ),
  cases %>%
    group_by(cultivar) %>%
    summarise(
      subset_name = paste0("keep_cultivar_", first(cultivar)),
      situations = list(situation),
      .groups = "drop"
    ),
  cases %>%
    mutate(n_group = if_else(nitrogen_kg_ha == 0, "N0", "Nplus")) %>%
    group_by(n_group) %>%
    summarise(
      subset_name = paste0("keep_", first(n_group)),
      situations = list(situation),
      .groups = "drop"
    )
) %>%
  mutate(metrics = map(situations, metric_summary)) %>%
  tidyr::unnest(metrics)

report_path <- file.path(base_dir, "HOPF_SUBSET_FORENSICS.md")

format_candidate <- function(row) {
  sprintf(
    "- `%s`: `%s` cases, `CWAD d = %.3f`, `CWAD RMSE = %.1f`, `SWAD d = %.3f`, `SWAD RMSE = %.1f`, score `%.3f`.\n  Excluded: %s",
    row[["subset_type"]],
    row[["n_cases"]],
    as.numeric(row[["cwad_d"]]),
    as.numeric(row[["cwad_rmse"]]),
    as.numeric(row[["swad_d"]]),
    as.numeric(row[["swad_rmse"]]),
    as.numeric(row[["score"]]),
    ifelse(nchar(row[["excluded"]]) > 0, row[["excluded"]], "none")
  )
}

report_lines <- c(
  "# Hopf Biomass Subset Forensics",
  "",
  "This note tests whether the paper's headline biomass metrics are better explained by a smaller subset of the 15 selected Florida treatments than by all destructive-harvest summaries pooled together.",
  "",
  "Published abstract targets:",
  "",
  "- aboveground biomass (`CWAD` proxy): `d = 0.91`, `RMSE = 482 kg ha-1`",
  "- stem weight (`SWAD`): `d = 0.83`, `RMSE = 430 kg ha-1`",
  "",
  "## All 15 selected cases",
  "",
  sprintf(
    "- `CWAD`: `n = %s`, `d = %.3f`, `RMSE = %.1f`",
    all_case_metrics$cwad_n, all_case_metrics$cwad_d, all_case_metrics$cwad_rmse
  ),
  sprintf(
    "- `SWAD`: `n = %s`, `d = %.3f`, `RMSE = %.1f`",
    all_case_metrics$swad_n, all_case_metrics$swad_d, all_case_metrics$swad_rmse
  ),
  "",
  "These pooled values are systematically better in `d` than the paper and still somewhat higher in `RMSE`, so they do not look like the abstract numbers.",
  "",
  "## Best treatment-level subset matches",
  "",
  format_candidate(best_overall[1, ]),
  format_candidate(best_min_10[1, ]),
  format_candidate(best_min_12[1, ]),
  "",
  "## Leave-one-out checks",
  "",
  paste(apply(leave_one_out %>% arrange(score) %>% slice_head(n = 8), 1, format_candidate), collapse = "\n"),
  "",
  "## Simple group checks",
  "",
  paste(apply(simple_group_checks %>% arrange(score), 1, function(r) sprintf(
    "- `%s`: `%s` cases, `CWAD d = %.3f`, `CWAD RMSE = %.1f`, `SWAD d = %.3f`, `SWAD RMSE = %.1f`, score `%.3f`",
    r[["subset_name"]], r[["n_cases"]], as.numeric(r[["cwad_d"]]), as.numeric(r[["cwad_rmse"]]),
    as.numeric(r[["swad_d"]]), as.numeric(r[["swad_rmse"]]), as.numeric(r[["score"]])
  )), collapse = "\n"),
  "",
  "## Most recurrent exclusions in top subsets",
  "",
  paste(top_exclusion_lines, collapse = "\n"),
  "",
  "## Interpretation",
  "",
  "- Treatment selection clearly matters for `RMSE`: the best subsets repeatedly exclude `UFCI2201_2` and `UFJA2201_2`, both 2022 `IH Williams` runs at `280 kg N ha-1`, and often other `PSREU 2022` cases as well.",
  "- That pattern matches the paper's statement that lower N treatments were sometimes preferred when high N treatments performed worse or had fewer usable observations.",
  "- But treatment selection alone does not explain the published headline metrics, because even the best treatment-level subsets keep `CWAD d` and `SWAD d` near `0.97-0.99`, far above the published `0.91` and `0.83`.",
  "- The most likely conclusion is therefore: the abstract biomass metrics were probably not computed from all pooled destructive-harvest summaries, but they also were not produced by a simple smaller treatment subset alone.",
  "- A different aggregation or weighting protocol is still needed, most likely one that changes how repeated harvest observations contribute to `d`, while the treatment selection mainly influences `RMSE`."
)

writeLines(report_lines, report_path)

write_csv(ranked_candidates, file.path(base_dir, "hopf_subset_candidates.csv"))
write_csv(top_candidates, file.path(base_dir, "hopf_subset_top_candidates.csv"))
write_csv(excluded_frequency, file.path(base_dir, "hopf_subset_excluded_frequency.csv"))
write_csv(leave_one_out, file.path(base_dir, "hopf_subset_leave_one_out.csv"))
write_csv(simple_group_checks, file.path(base_dir, "hopf_subset_group_checks.csv"))

cat("Subset forensics written to:", report_path, "\n")
print(best_overall)
print(best_min_10)
print(best_min_12)
