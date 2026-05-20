suppressPackageStartupMessages({
  required_packages <- c("DSSAT", "dplyr", "readr", "purrr", "tidyr")
  missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing_packages) > 0) {
    stop(
      "Missing required R package(s): ",
      paste(missing_packages, collapse = ", "),
      ". Install them before running hopf_harvest_parser.R."
    )
  }

  library("DSSAT")
  library("dplyr")
  library("readr")
  library("purrr")
  library("tidyr")
})

resolve_sativa_dir <- function() {
  script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (length(script_arg) == 0) {
    return(normalizePath(getwd(), winslash = "/", mustWork = TRUE))
  }
  normalizePath(dirname(sub("^--file=", "", script_arg[1])), winslash = "/", mustWork = TRUE)
}

normalize_dssat_date <- function(x) {
  if (inherits(x, "Date")) {
    return(x)
  }
  if (inherits(x, "POSIXt")) {
    return(as.Date(x))
  }
  x <- suppressWarnings(as.integer(x))
  out <- rep(as.Date(NA), length(x))
  keep <- !is.na(x)
  years <- ifelse((x[keep] %/% 1000) <= 30, 2000L + (x[keep] %/% 1000), 1900L + (x[keep] %/% 1000))
  out[keep] <- as.Date(sprintf("%04d-01-01", years[seq_along(years)])) + ((x[keep] %% 1000) - 1)
  out
}

hopf_biomass_columns <- function(df) {
  intersect(c("SWAD", "LWAD", "GWAD", "CWAD", "RWAD", "PWAD", "FLWAD"), names(df))
}

hopf_structure_columns <- function(df) {
  intersect(c("CHTD", "CWID", "L#SD", "G#AD", "P#AD", "GSTD", "LAID", "RDPD"), names(df))
}

hopf_classify_hmt_rows <- function(hmt_df) {
  numeric_candidates <- intersect(
    c("TRNO", "CHTD", "CWID", "SWAD", "LWAD", "GWAD", "CWAD", "RWAD", "PWAD", "FLWAD", "L#SD", "G#AD", "P#AD", "GSTD", "LAID", "RDPD"),
    names(hmt_df)
  )
  out <- hmt_df
  if (length(numeric_candidates) > 0) {
    out[numeric_candidates] <- lapply(out[numeric_candidates], function(x) suppressWarnings(as.numeric(x)))
  }

  biomass_cols <- hopf_biomass_columns(out)
  structure_cols <- hopf_structure_columns(out)
  out$Date <- normalize_dssat_date(out$DATE)
  out$non_missing_biomass <- if (length(biomass_cols) > 0) {
    rowSums(!is.na(out[, biomass_cols, drop = FALSE]))
  } else {
    0L
  }
  out$non_missing_structure <- if (length(structure_cols) > 0) {
    rowSums(!is.na(out[, structure_cols, drop = FALSE]))
  } else {
    0L
  }
  out$row_type <- dplyr::case_when(
    out$non_missing_biomass > 0 & out$non_missing_structure > 0 ~ "mixed_harvest",
    out$non_missing_biomass > 0 ~ "harvest_only",
    out$non_missing_structure > 0 ~ "standing_only",
    TRUE ~ "empty"
  )
  out
}

hopf_extract_harvest_rows <- function(hmt_df) {
  hopf_classify_hmt_rows(hmt_df) %>%
    dplyr::filter(row_type %in% c("harvest_only", "mixed_harvest")) %>%
    dplyr::select(-DATE)
}

hopf_summarise_harvests <- function(harvest_df) {
  biomass_cols <- hopf_biomass_columns(harvest_df)
  structure_cols <- hopf_structure_columns(harvest_df)
  keep_cols <- unique(c("TRNO", "Date", biomass_cols, structure_cols))

  harvest_df %>%
    dplyr::select(dplyr::all_of(keep_cols)) %>%
    dplyr::group_by(TRNO, Date) %>%
    dplyr::summarise(
      dplyr::across(
        dplyr::everything(),
        ~ if (is.numeric(.x)) mean(.x, na.rm = TRUE) else dplyr::first(.x)
      ),
      n_raw_rows = dplyr::n(),
      .groups = "drop"
    ) %>%
    dplyr::mutate(
      dplyr::across(
        dplyr::where(is.numeric),
        ~ dplyr::na_if(.x, NaN)
      )
    )
}

sativa_dir <- resolve_sativa_dir()
hemp_dir <- file.path(sativa_dir, "dssat-csm-data", "Hemp")
output_dir <- file.path(sativa_dir, "hopf_reproduction_outputs")
dir.create(output_dir, showWarnings = FALSE)

files <- c("UFCI2101.HMT", "UFCI2201.HMT", "UFJA2101.HMT", "UFJA2201.HMT")

parsed_rows <- purrr::map_dfr(files, function(file_name) {
  hmt_df <- DSSAT::read_filet(file.path(hemp_dir, file_name), na_strings = NA)
  classified <- hopf_classify_hmt_rows(hmt_df)
  classified$experiment <- tools::file_path_sans_ext(file_name)
  classified
})

harvest_rows <- parsed_rows %>%
  dplyr::filter(row_type %in% c("harvest_only", "mixed_harvest"))

harvest_summary <- purrr::map_dfr(files, function(file_name) {
  hmt_df <- DSSAT::read_filet(file.path(hemp_dir, file_name), na_strings = NA)
  harvest_df <- hopf_extract_harvest_rows(hmt_df)
  summary_df <- hopf_summarise_harvests(harvest_df)
  summary_df$experiment <- tools::file_path_sans_ext(file_name)
  summary_df
})

row_type_summary <- parsed_rows %>%
  dplyr::count(experiment, TRNO, Date, row_type, name = "n_rows")

readr::write_csv(parsed_rows, file.path(output_dir, "hopf_hmt_rows_classified.csv"))
readr::write_csv(harvest_rows, file.path(output_dir, "hopf_hmt_harvest_rows.csv"))
readr::write_csv(harvest_summary, file.path(output_dir, "hopf_hmt_harvest_summary.csv"))
readr::write_csv(row_type_summary, file.path(output_dir, "hopf_hmt_row_type_summary.csv"))

cat("Harvest parser outputs written to:", output_dir, "\n")
cat("\nRow-type counts by experiment:\n")
print(parsed_rows %>% dplyr::count(experiment, row_type))
