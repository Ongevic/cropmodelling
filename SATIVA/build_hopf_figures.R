suppressPackageStartupMessages({
  required_packages <- c("dplyr", "ggplot2", "readr", "tidyr", "scales")
  missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing_packages) > 0) {
    stop(
      "Missing required R package(s): ",
      paste(missing_packages, collapse = ", "),
      ". Install them before running build_hopf_figures.R."
    )
  }

  library("dplyr")
  library("ggplot2")
  library("readr")
  library("tidyr")
  library("scales")
})

resolve_sativa_dir <- function() {
  script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (length(script_arg) == 0) {
    return(normalizePath(getwd(), winslash = "/", mustWork = TRUE))
  }
  normalizePath(dirname(sub("^--file=", "", script_arg[1])), winslash = "/", mustWork = TRUE)
}

sativa_dir <- resolve_sativa_dir()
repro_dir <- file.path(sativa_dir, "hopf_reproduction_outputs")
figure_dir <- file.path(sativa_dir, "hopf_reproduction_figures")
dir.create(figure_dir, showWarnings = FALSE)

joined <- readr::read_csv(file.path(repro_dir, "hopf_joined_timeseries.csv"), show_col_types = FALSE)
metrics <- readr::read_csv(file.path(repro_dir, "hopf_metrics_overall.csv"), show_col_types = FALSE)
flowering <- readr::read_csv(file.path(repro_dir, "hopf_flowering_summary.csv"), show_col_types = FALSE) %>%
  dplyr::mutate(
    obs_flowering_date = as.Date(obs_flowering_date),
    sim_flowering_date = as.Date(sim_flowering_date),
    cultivar = factor(cultivar, levels = unique(cultivar)),
    situation = factor(situation, levels = unique(situation[order(simulation_no)])),
    obs_doy = as.integer(strftime(obs_flowering_date, "%j")),
    sim_doy = as.integer(strftime(sim_flowering_date, "%j"))
  )

palette <- c(
  navy = "#19345E",
  teal = "#117A8B",
  gold = "#D69227",
  clay = "#B55239",
  sage = "#6D8A5A",
  ink = "#1F2937",
  fog = "#EEF2F7"
)

theme_hopf <- function() {
  ggplot2::theme_minimal(base_size = 13) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", size = 18, colour = palette[["navy"]]),
      plot.subtitle = ggplot2::element_text(size = 11, colour = palette[["ink"]]),
      axis.title = ggplot2::element_text(face = "bold", colour = palette[["ink"]]),
      axis.text = ggplot2::element_text(colour = palette[["ink"]]),
      strip.text = ggplot2::element_text(face = "bold", colour = palette[["navy"]]),
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major.x = ggplot2::element_blank(),
      legend.position = "bottom",
      legend.title = ggplot2::element_text(face = "bold"),
      plot.background = ggplot2::element_rect(fill = "white", colour = NA)
    )
}

scatter_vars <- c("CWAD", "SWAD", "GWAD", "CHTD")
scatter_long <- joined %>%
  dplyr::select(
    simulation_no, situation, experiment, site, year, cultivar, nitrogen_kg_ha,
    tidyselect::matches("^(CWAD|SWAD|GWAD|CHTD)_(sim|obs)$")
  ) %>%
  tidyr::pivot_longer(
    cols = tidyselect::matches("_(sim|obs)$"),
    names_to = c("variable", ".value"),
    names_pattern = "^(.*)_(sim|obs)$"
  ) %>%
  dplyr::filter(variable %in% scatter_vars, is.finite(obs), is.finite(sim))

scatter_plot <- ggplot(scatter_long, aes(x = obs, y = sim, colour = cultivar)) +
  geom_point(alpha = 0.72, size = 2.1) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = palette[["ink"]]) +
  facet_wrap(~ variable, scales = "free", ncol = 2) +
  scale_colour_manual(values = c("IH Williams" = palette[["navy"]], "NWG 2730" = palette[["gold"]])) +
  labs(
    title = "Observed vs Simulated Hopf Hemp Measurements",
    subtitle = "Matched observation dates across the 15 Florida calibration and evaluation cases",
    x = "Observed",
    y = "Simulated",
    colour = "Cultivar"
  ) +
  theme_hopf()

ggsave(
  filename = file.path(figure_dir, "hopf_observed_vs_simulated.png"),
  plot = scatter_plot,
  width = 12,
  height = 9,
  dpi = 300
)

metrics_plot <- metrics %>%
  dplyr::mutate(
    variable = factor(variable, levels = variable[order(d)]),
    label = paste0("d=", number(d, accuracy = 0.001), "\nRMSE=", number(rmse, accuracy = 0.1))
  ) %>%
  ggplot(aes(x = d, y = variable, fill = rmse)) +
  geom_col(width = 0.75) +
  geom_text(aes(label = label), hjust = -0.05, size = 3.3, colour = palette[["ink"]]) +
  scale_fill_gradient(low = palette[["teal"]], high = palette[["clay"]]) +
  scale_x_continuous(limits = c(0, 1.18), expand = expansion(mult = c(0, 0.02))) +
  labs(
    title = "Overall Metric Snapshot",
    subtitle = "Willmott's d and RMSE from the first-pass Hopf reproduction",
    x = "Willmott's d",
    y = NULL,
    fill = "RMSE"
  ) +
  theme_hopf()

ggsave(
  filename = file.path(figure_dir, "hopf_metric_snapshot.png"),
  plot = metrics_plot,
  width = 11,
  height = 6.5,
  dpi = 300
)

flowering_plot <- flowering %>%
  dplyr::mutate(
    label = paste0(ifelse(flowering_diff_days > 0, "+", ""), flowering_diff_days, " d"),
    cultivar_site = paste(cultivar, site, sep = " | ")
  ) %>%
  ggplot(aes(y = stats::reorder(situation, -simulation_no))) +
  geom_segment(
    aes(x = obs_doy, xend = sim_doy, yend = stats::reorder(situation, -simulation_no), colour = cultivar),
    linewidth = 1.3,
    alpha = 0.9
  ) +
  geom_point(aes(x = obs_doy), shape = 21, fill = "white", colour = palette[["ink"]], size = 3, stroke = 1.1) +
  geom_point(aes(x = sim_doy, fill = cultivar), shape = 21, colour = "white", size = 3.4, stroke = 0.6) +
  geom_text(aes(x = pmax(obs_doy, sim_doy) + 1.5, label = label), hjust = 0, size = 3.2, colour = palette[["ink"]]) +
  scale_colour_manual(values = c("IH Williams" = palette[["navy"]], "NWG 2730" = palette[["gold"]])) +
  scale_fill_manual(values = c("IH Williams" = palette[["navy"]], "NWG 2730" = palette[["gold"]])) +
  scale_x_continuous(
    breaks = c(145, 152, 159, 166, 173, 180, 187, 194),
    labels = c("May 25", "Jun 01", "Jun 08", "Jun 15", "Jun 22", "Jun 29", "Jul 06", "Jul 13"),
    expand = expansion(mult = c(0.01, 0.12))
  ) +
  labs(
    title = "Flowering Date Agreement by Paper Case",
    subtitle = "Observed anthesis from `.HMA` versus simulated flowering dates on a within-season scale",
    x = "Day of season",
    y = "Situation",
    colour = "Cultivar",
    fill = "Cultivar"
  ) +
  theme_hopf()

ggsave(
  filename = file.path(figure_dir, "hopf_flowering_alignment.png"),
  plot = flowering_plot,
  width = 13,
  height = 8,
  dpi = 300
)

cwad_timeseries <- joined %>%
  dplyr::select(
    Date, simulation_no, situation, experiment, site, year, cultivar, nitrogen_kg_ha,
    CWAD_sim, CWAD_obs
  ) %>%
  dplyr::filter(is.finite(CWAD_sim) | is.finite(CWAD_obs)) %>%
  tidyr::pivot_longer(
    cols = c(CWAD_sim, CWAD_obs),
    names_to = "series",
    values_to = "CWAD"
  ) %>%
  dplyr::mutate(
    series = dplyr::recode(series, CWAD_sim = "Simulated", CWAD_obs = "Observed"),
    facet_label = paste0("Case ", simulation_no, " | ", experiment, " | ", cultivar, " | N=", nitrogen_kg_ha)
  )

cwad_plot <- ggplot() +
  geom_line(
    data = dplyr::filter(cwad_timeseries, series == "Simulated"),
    aes(x = Date, y = CWAD, colour = series, group = situation),
    linewidth = 0.9
  ) +
  geom_point(
    data = dplyr::filter(cwad_timeseries, series == "Observed"),
    aes(x = Date, y = CWAD, colour = series),
    size = 1.8,
    alpha = 0.85
  ) +
  facet_wrap(~ facet_label, scales = "free_x", ncol = 3) +
  scale_colour_manual(values = c("Observed" = palette[["clay"]], "Simulated" = palette[["teal"]])) +
  labs(
    title = "Aboveground Biomass Trajectories Across the 15 Hopf Cases",
    subtitle = "Observed points from `.HMT` and simulated curves from the wrapper rerun",
    x = "Date",
    y = "CWAD",
    colour = "Series"
  ) +
  theme_hopf()

ggsave(
  filename = file.path(figure_dir, "hopf_cwad_timeseries.png"),
  plot = cwad_plot,
  width = 15,
  height = 11,
  dpi = 300
)

cat("Hopf figure files written to:", figure_dir, "\n")
