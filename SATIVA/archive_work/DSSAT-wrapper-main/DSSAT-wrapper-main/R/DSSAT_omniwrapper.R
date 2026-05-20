# Registry-driven DSSAT omniwrapper prototype
# This prototype is designed to extend the original DSSAT_wrapper toward
# multiple DSSAT model families using runtime inference from installed files.

suppressPackageStartupMessages({
  required_packages <- c("DSSAT", "dplyr", "tidyr", "lubridate")
  missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing_packages) > 0) {
    stop(
      "Missing required R package(s): ",
      paste(missing_packages, collapse = ", "),
      ". Install them before sourcing DSSAT_omniwrapper.R."
    )
  }

  library("DSSAT")
  library("dplyr")
  library("tidyr")
  library("lubridate")
})

dssat_omni_family_map <- function() {
  list(
    BSCER = list(adapter = "CERES", outputs = c("PlantGro.OUT", "Evaluate.OUT")),
    CSCER = list(adapter = "CERES", outputs = c("PlantGro.OUT", "Evaluate.OUT", "PlantGr2.OUT")),
    CRGRO = list(adapter = "CROPGRO", outputs = c("PlantGro.OUT", "Evaluate.OUT")),
    MLCER = list(adapter = "CERES", outputs = c("PlantGro.OUT", "Evaluate.OUT")),
    MZCER = list(adapter = "CERES", outputs = c("PlantGro.OUT", "Evaluate.OUT")),
    MZIXM = list(adapter = "CERES", outputs = c("PlantGro.OUT", "Evaluate.OUT")),
    PTSUB = list(adapter = "SUBSTOR", outputs = c("PlantGro.OUT", "Evaluate.OUT")),
    RICER = list(adapter = "RICE", outputs = c("PlantGro.OUT", "Evaluate.OUT")),
    SCCAN = list(adapter = "SUGARCANE", outputs = c("PlantGro.OUT", "Evaluate.OUT")),
    SCCSP = list(adapter = "SUGARCANE", outputs = c("PlantGro.OUT", "Evaluate.OUT")),
    SCSAM = list(adapter = "SUGARCANE", outputs = c("PlantGro.OUT", "Evaluate.OUT")),
    SGCER = list(adapter = "CERES", outputs = c("PlantGro.OUT", "Evaluate.OUT")),
    SWCER = list(adapter = "CERES", outputs = c("PlantGro.OUT", "Evaluate.OUT")),
    PIALO = list(adapter = "ALOHA", outputs = c("PlantGro.OUT", "Evaluate.OUT")),
    TRARO = list(adapter = "AROIDS", outputs = c("PlantGro.OUT", "Evaluate.OUT")),
    TNARO = list(adapter = "AROIDS", outputs = c("PlantGro.OUT", "Evaluate.OUT")),
    TFAPS = list(adapter = "NWHEAT", outputs = c("PlantGro.OUT", "Evaluate.OUT", "PlantGr2.OUT")),
    TFCER = list(adapter = "CERES", outputs = c("PlantGro.OUT", "Evaluate.OUT")),
    WHAPS = list(adapter = "NWHEAT", outputs = c("PlantGro.OUT", "Evaluate.OUT", "PlantGr2.OUT")),
    PRFRM = list(adapter = "FORAGE", outputs = c("PlantGro.OUT", "Evaluate.OUT")),
    SUOIL = list(adapter = "OILCROP", outputs = c("PlantGro.OUT", "Evaluate.OUT")),
    CSYCA = list(adapter = "CSYCA", outputs = c("PlantGro.OUT", "Evaluate.OUT")),
    CSCAS = list(adapter = "CSCAS", outputs = c("PlantGro.OUT", "Evaluate.OUT")),
    CSCRP = list(adapter = "CROPSIM", outputs = c("PlantGro.OUT", "Evaluate.OUT"))
  )
}

dssat_read_simulation_registry <- function(dssat_path) {
  sim_file <- file.path(dssat_path, "SIMULATION.CDE")
  profile_file <- file.path(dssat_path, "DSSATPRO.V48")
  if (!file.exists(sim_file) || !file.exists(profile_file)) {
    stop("SIMULATION.CDE or DSSATPRO.V48 not found in DSSAT path.")
  }

  sim_lines <- readLines(sim_file, warn = FALSE, encoding = "UTF-8")
  profile_lines <- readLines(profile_file, warn = FALSE, encoding = "UTF-8")
  family_map <- dssat_omni_family_map()

  model_rows <- list()
  in_models <- FALSE
  for (line in sim_lines) {
    if (grepl("^\\*Simulation/Crop Models", line)) {
      in_models <- TRUE
      next
    }
    if (!in_models) {
      next
    }
    if (grepl("^\\*", line) && !grepl("^\\*Simulation/Crop Models", line)) {
      break
    }
    if (grepl("^\\s*@", line) || grepl("^\\s*!", line) || !nzchar(trimws(line))) {
      next
    }
    parts <- strsplit(trimws(line), "\\s+")[[1]]
    if (length(parts) < 3) {
      next
    }
    model_code <- parts[1]
    crop_code <- parts[2]
    description <- paste(parts[-c(1, 2)], collapse = " ")
    model_rows[[length(model_rows) + 1]] <- data.frame(
      model_code = model_code,
      crop_code = crop_code,
      description = description,
      stringsAsFactors = FALSE
    )
  }
  registry <- dplyr::bind_rows(model_rows)

  crop_dir_rows <- list()
  default_model_rows <- list()
  for (line in profile_lines) {
    dir_match <- regexec("^([A-Z0-9]{2})D\\s+C:\\s+\\\\DSSAT48\\\\(.+)$", trimws(line))
    dir_parts <- regmatches(trimws(line), dir_match)[[1]]
    if (length(dir_parts) > 0) {
      crop_dir_rows[[length(crop_dir_rows) + 1]] <- data.frame(
        crop_code = toupper(dir_parts[2]),
        crop_dir = dir_parts[3],
        stringsAsFactors = FALSE
      )
      next
    }

    mod_match <- regexec("^M([A-Z0-9]{2})\\s+C:\\s+\\\\DSSAT48\\s+DSCSM048\\.EXE\\s+([A-Z0-9]{8})$", trimws(line))
    mod_parts <- regmatches(trimws(line), mod_match)[[1]]
    if (length(mod_parts) > 0) {
      default_model_rows[[length(default_model_rows) + 1]] <- data.frame(
        crop_code = toupper(mod_parts[2]),
        default_module = toupper(mod_parts[3]),
        stringsAsFactors = FALSE
      )
    }
  }

  crop_dirs <- dplyr::bind_rows(crop_dir_rows)
  default_models <- dplyr::bind_rows(default_model_rows)

  registry <- registry %>%
    dplyr::left_join(crop_dirs, by = "crop_code") %>%
    dplyr::left_join(default_models, by = "crop_code") %>%
    dplyr::mutate(
      module_code_048 = paste0(model_code, "048"),
      adapter = vapply(
        model_code,
        function(x) if (!is.null(family_map[[x]])) family_map[[x]]$adapter else "UNKNOWN",
        character(1)
      ),
      default_outputs = lapply(
        model_code,
        function(x) if (!is.null(family_map[[x]])) family_map[[x]]$outputs else c("PlantGro.OUT", "Evaluate.OUT")
      ),
      genotype_stem = paste0(crop_code, substr(model_code, 3, 5), "048"),
      is_default_profile_module = default_module == module_code_048
    )

  registry
}

dssat_parse_experiment_header <- function(filex_path) {
  lines <- readLines(filex_path, warn = FALSE, encoding = "UTF-8")
  section <- NULL
  model_code <- NULL
  treatment_numbers <- c()
  cultivar_table <- NULL

  for (line in lines) {
    clean <- trimws(gsub("\u001a", "", line))
    if (grepl("^\\*", clean)) {
      section <- strsplit(clean, ":", fixed = TRUE)[[1]][1]
      next
    }
    if (!nzchar(clean) || grepl("^@", clean)) {
      next
    }

    if (section == "*TREATMENTS") {
      parts <- strsplit(clean, "\\s+")[[1]]
      suppressWarnings({
        num <- as.integer(parts[1])
      })
      if (!is.na(num)) {
        treatment_numbers <- c(treatment_numbers, num)
      }
    }

    if (section == "*CULTIVARS") {
      cultivar_table <- c(cultivar_table, clean)
    }

    if (section == "*SIMULATION CONTROLS" && grepl("^1\\s+GE\\s+", clean)) {
      parts <- strsplit(clean, "\\s+")[[1]]
      model_candidate <- toupper(parts[length(parts)])
      if (grepl("^[A-Z0-9]{5}$", model_candidate)) {
        model_code <- model_candidate
      }
    }
  }

  stem <- tools::file_path_sans_ext(basename(filex_path))
  ext <- tools::file_ext(filex_path)
  crop_code_from_ext <- toupper(substr(ext, 1, 2))

  list(
    model_code = model_code,
    crop_code = crop_code_from_ext,
    filea = paste0(stem, ".", crop_code_from_ext, "A"),
    filet = paste0(stem, ".", crop_code_from_ext, "T"),
    treatments = unique(treatment_numbers),
    cultivar_lines = cultivar_table
  )
}

dssat_try_match_row <- function(df, target, candidates) {
  for (col in candidates) {
    if (col %in% names(df)) {
      idx <- which(trimws(as.character(df[[col]])) == trimws(as.character(target)))
      if (length(idx) > 0) {
        return(list(index = idx[1], column = col))
      }
    }
  }
  NULL
}

dssat_get_adapter_spec <- function(model_code) {
  spec <- dssat_omni_family_map()[[model_code]]
  if (is.null(spec)) {
    spec <- list(adapter = "UNKNOWN", outputs = c("PlantGro.OUT", "Evaluate.OUT"))
  }
  spec
}

dssat_run_model <- function(run_dir, model_options) {
  exe_path <- file.path(model_options$DSSAT_path, model_options$DSSAT_exe)
  if (!file.exists(exe_path)) {
    stop("DSSAT executable not found: ", exe_path)
  }

  args <- c()
  if (!is.null(model_options$module_code_048) && nzchar(model_options$module_code_048)) {
    args <- c(args, model_options$module_code_048)
  }
  args <- c(args, "B", "DSSBatch.V48")

  stdout_target <- if (isTRUE(model_options$suppress_output)) TRUE else ""
  stderr_target <- if (isTRUE(model_options$suppress_output)) TRUE else ""

  status <- system2(
    command = exe_path,
    args = args,
    stdout = stdout_target,
    stderr = stderr_target
  )

  invisible(status)
}

dssat_parse_plantgro_fallback <- function(path) {
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  header_idx <- grep("^@YEAR\\s+DOY", lines)
  if (length(header_idx) == 0) {
    stop("No PlantGro header found in fallback parser for ", path)
  }

  blocks <- vector("list", length(header_idx))
  for (i in seq_along(header_idx)) {
    header_line_idx <- header_idx[i]
    run_start <- max(which(seq_along(lines) < header_line_idx & grepl("^\\*RUN\\s+", lines)))
    if (!is.finite(run_start)) {
      run_start <- 1
    }
    block_end <- if (i < length(header_idx)) header_idx[i + 1] - 1 else length(lines)
    run_lines <- lines[run_start:block_end]

    run_line <- run_lines[grep("^\\*RUN\\s+", run_lines)[1]]
    exp_line <- run_lines[grep("^\\s*EXPERIMENT\\s*:", run_lines)[1]]
    model_line <- run_lines[grep("^\\s*MODEL\\s*:", run_lines)[1]]
    data_lines <- run_lines[seq.int(match(lines[header_line_idx], run_lines) + 1, length(run_lines))]
    data_lines <- data_lines[grepl("^\\s*\\d", data_lines)]
    if (length(data_lines) == 0) {
      next
    }

    cols <- strsplit(sub("^@", "", trimws(lines[header_line_idx])), "\\s+")[[1]]
    block_df <- utils::read.table(
      text = paste(data_lines, collapse = "\n"),
      header = FALSE,
      fill = TRUE,
      stringsAsFactors = FALSE
    )
    names(block_df)[seq_along(cols)] <- cols
    if (ncol(block_df) > length(cols)) {
      block_df <- block_df[, seq_along(cols), drop = FALSE]
    }

    run_match <- regexec("^\\*RUN\\s+([0-9]+).+?([A-Z0-9]{8})\\s+([A-Z0-9]{8})\\s+([0-9]+)\\s*$", trimws(run_line))
    run_parts <- regmatches(trimws(run_line), run_match)[[1]]
    experiment_code <- NA_character_
    if (!is.na(exp_line) && length(exp_line) > 0) {
      experiment_code <- sub("^\\s*EXPERIMENT\\s*:\\s*([A-Z0-9]+).*$", "\\1", exp_line)
    }
    model_name <- if (!is.na(model_line) && length(model_line) > 0) {
      sub("^\\s*MODEL\\s*:\\s*([A-Z0-9]+).*$", "\\1", model_line)
    } else {
      NA_character_
    }

    block_df$RUN <- if (length(run_parts) >= 2) as.integer(run_parts[2]) else i
    block_df$TRNO <- if (length(run_parts) >= 5) as.integer(run_parts[5]) else NA_integer_
    block_df$EXPERIMENT <- experiment_code
    block_df$MODEL <- model_name

    if (all(c("YEAR", "DOY") %in% names(block_df))) {
      year_int <- suppressWarnings(as.integer(block_df$YEAR))
      doy_int <- suppressWarnings(as.integer(block_df$DOY))
      block_df$DATE <- as.Date(sprintf("%04d-%03d", year_int, doy_int), format = "%Y-%j")
    }

    blocks[[i]] <- block_df
  }

  blocks <- Filter(Negate(is.null), blocks)
  if (length(blocks) == 0) {
    stop("Fallback PlantGro parser found no data rows in ", path)
  }
  dplyr::bind_rows(blocks)
}

dssat_read_output_safe <- function(path, output_name = basename(path)) {
  tryCatch(
    as.data.frame(read_output(path)),
    error = function(e) {
      if (identical(output_name, "PlantGro.OUT")) {
        dssat_parse_plantgro_fallback(path)
      } else {
        stop(e)
      }
    }
  )
}

dssat_infer_model_options <- function(model_options) {
  if (is.null(model_options$DSSAT_path)) {
    stop("model_options$DSSAT_path is required.")
  }
  if (is.null(model_options$DSSAT_exe)) {
    model_options$DSSAT_exe <- "DSCSM048.EXE"
  }
  if (is.null(model_options$Genotype)) {
    model_options$Genotype <- "Genotype"
  }

  registry <- dssat_read_simulation_registry(model_options$DSSAT_path)
  model_options$registry <- registry

  if (!is.null(model_options$project_file)) {
    if (!file.exists(model_options$project_file)) {
      if (!is.null(model_options$Crop)) {
        maybe_path <- file.path(model_options$DSSAT_path, model_options$Crop, model_options$project_file)
        if (file.exists(maybe_path)) {
          model_options$project_file <- maybe_path
        } else {
          stop("Project file not found: ", model_options$project_file)
        }
      } else {
        stop("Project file not found: ", model_options$project_file)
      }
    }

    exp_info <- dssat_parse_experiment_header(model_options$project_file)
    model_options$crop_code <- exp_info$crop_code
    model_options$filea <- exp_info$filea
    model_options$filet <- exp_info$filet
    model_options$available_treatments <- exp_info$treatments
    if (!is.null(exp_info$model_code) && nzchar(exp_info$model_code)) {
      model_options$model_code <- exp_info$model_code
    }
    if (is.null(model_options$Crop)) {
      crop_dir_name <- basename(dirname(normalizePath(model_options$project_file, winslash = "/", mustWork = TRUE)))
      crop_row <- registry %>%
        dplyr::filter(crop_code == exp_info$crop_code, crop_dir == crop_dir_name)
      if (nrow(crop_row) == 0) {
        crop_row <- registry %>%
          dplyr::filter(crop_code == exp_info$crop_code, is_default_profile_module)
      }
      if (nrow(crop_row) == 0) {
        crop_row <- registry %>% dplyr::filter(crop_code == exp_info$crop_code)
      }
      if (nrow(crop_row) > 0 && !is.na(crop_row$crop_dir[1])) {
        model_options$Crop <- crop_row$crop_dir[1]
      }
    }
  }

  if (!is.null(model_options$module_code)) {
    model_options$model_code <- substr(toupper(model_options$module_code), 1, 5)
  }

  if (is.null(model_options$model_code)) {
    if (!is.null(model_options$crop_code)) {
      model_row <- registry %>%
        dplyr::filter(crop_code == model_options$crop_code)
      if (!is.null(model_options$Crop)) {
        model_row <- model_row %>% dplyr::filter(is.na(crop_dir) | crop_dir == model_options$Crop)
      }
      default_row <- model_row %>% dplyr::filter(is_default_profile_module)
      if (nrow(default_row) > 0) {
        model_options$model_code <- default_row$model_code[1]
      } else if (nrow(model_row) > 0) {
        model_options$model_code <- model_row$model_code[1]
      }
    }
  }

  if (is.null(model_options$model_code)) {
    if (!is.null(model_options$module_code)) {
      model_options$model_code <- substr(toupper(model_options$module_code), 1, 5)
    } else if (!is.null(model_options$ecotype_filename)) {
      crop_code <- substr(model_options$ecotype_filename, 1, 2)
      suffix <- substr(model_options$ecotype_filename, 3, 5)
      model_options$model_code <- paste0(crop_code, suffix)
      model_options$model_code <- substr(model_options$model_code, 3, 7)
    } else {
      stop("Unable to infer model code. Provide model_options$project_file or model_options$module_code.")
    }
  }

  if (is.null(model_options$Crop)) {
    crop_row <- registry %>%
      dplyr::filter(crop_code == model_options$crop_code, model_code == model_options$model_code)
    if (nrow(crop_row) == 0 && !is.null(model_options$crop_code)) {
      crop_row <- registry %>% dplyr::filter(crop_code == model_options$crop_code)
      if (nrow(crop_row) > 0 && !is.na(crop_row$crop_dir[1])) {
        model_options$Crop <- crop_row$crop_dir[1]
      }
    }
  }

  model_options$model_code <- toupper(substr(model_options$model_code, 1, 5))
  model_row <- registry %>% dplyr::filter(model_code == model_options$model_code)
  if (!is.null(model_options$crop_code)) {
    model_row <- model_row %>% dplyr::filter(crop_code == model_options$crop_code)
  }
  if (nrow(model_row) == 0) {
    stop("No registry entry found for model code: ", model_options$model_code)
  }
  if (nrow(model_row) > 1 && !is.null(model_options$crop_code)) {
    model_row <- model_row[1, , drop = FALSE]
  } else if (nrow(model_row) > 1) {
    stop("Model code maps to multiple crop codes. Supply model_options$crop_code.")
  }

  model_options$crop_code <- model_row$crop_code[1]
  model_options$module_code_048 <- model_row$module_code_048[1]
  model_options$adapter <- model_row$adapter[1]
  if (is.null(model_options$Crop) || !nzchar(model_options$Crop)) {
    model_options$Crop <- model_row$crop_dir[1]
  }
  if (is.null(model_options$out_files)) {
    model_options$out_files <- unlist(model_row$default_outputs[[1]])
  }

  genotype_stem <- model_row$genotype_stem[1]
  if (is.null(model_options$ecotype_filename)) {
    maybe_eco <- paste0(genotype_stem, ".ECO")
    if (file.exists(file.path(model_options$DSSAT_path, model_options$Genotype, maybe_eco))) {
      model_options$ecotype_filename <- maybe_eco
    }
  }
  if (is.null(model_options$cultivar_filename)) {
    maybe_cul <- paste0(genotype_stem, ".CUL")
    if (file.exists(file.path(model_options$DSSAT_path, model_options$Genotype, maybe_cul))) {
      model_options$cultivar_filename <- maybe_cul
    }
  }
  model_options$species_filename <- paste0(genotype_stem, ".SPE")
  model_options
}

dssat_add_stage_columns <- function(pgro) {
  if (!("GSTD" %in% names(pgro)) || nrow(pgro) == 0) {
    return(pgro)
  }
  zadok_df <- data.frame(Zadok = unique(floor(pgro$GSTD)))
  zadok_df$firstIndex <- match(zadok_df$Zadok, floor(pgro$GSTD))
  zadok_df$dates <- pgro$Date[zadok_df$firstIndex]
  zadok_df$julDay <- julian(
    zadok_df$dates,
    origin = as.Date(paste(lubridate::year(zadok_df$dates[1]), "01", "01", sep = "-"))
  ) + 1
  for (i in seq_len(nrow(zadok_df))) {
    pgro[[paste0("Zadok", zadok_df$Zadok[i])]] <- zadok_df$julDay[i]
  }
  pgro
}

dssat_read_outputs_generic <- function(project_path, model_options, situation_names = NULL, trt_numbers = NULL, var = NULL) {
  pgro_path <- file.path(project_path, "PlantGro.OUT")
  if (!file.exists(pgro_path)) {
    return(list(sim_list = list(), error = TRUE))
  }

  pgro_tot <- dssat_read_output_safe(pgro_path, "PlantGro.OUT") %>%
    dplyr::mutate(Date = DATE) %>%
    dplyr::select(-DATE) %>%
    dplyr::relocate(Date)

  if ("PlantGr2.OUT" %in% model_options$out_files && file.exists(file.path(project_path, "PlantGr2.OUT"))) {
    pgr2 <- dssat_read_output_safe(file.path(project_path, "PlantGr2.OUT"), "PlantGr2.OUT") %>%
      dplyr::mutate(Date = DATE) %>%
      dplyr::select(-DATE) %>%
      dplyr::relocate(Date)
    pgro_tot <- dplyr::left_join(
      pgro_tot,
      pgr2[, c("Date", "EXPERIMENT", "TRNO", setdiff(names(pgr2), names(pgro_tot)))],
      by = c("Date", "EXPERIMENT", "TRNO")
    )
  }

  if (file.exists(file.path(project_path, "Evaluate.OUT"))) {
    eval_df <- tryCatch(
      {
        dssat_read_output_safe(file.path(project_path, "Evaluate.OUT"), "Evaluate.OUT") %>%
          dplyr::mutate(EXPERIMENT = EXCODE) %>%
          dplyr::select(-EXCODE)
      },
      error = function(e) NULL
    )
    if (!is.null(eval_df)) {
      if (!("TRNO" %in% names(eval_df)) && "TN" %in% names(eval_df)) {
        eval_df <- dplyr::rename(eval_df, TRNO = TN)
      }
      eval_df$EXPERIMENT <- sapply(
        eval_df$EXPERIMENT,
        function(x) {
          if (nchar(x) > 2 && substr(x, nchar(x) - 1, nchar(x)) == model_options$crop_code) {
            substr(x, 1, nchar(x) - 2)
          } else {
            x
          }
        }
      )
      id_sim_var <- grep(pattern = "S$", names(eval_df))
      sim_var_names <- names(eval_df)[id_sim_var]
      if (length(sim_var_names) > 0 && "TRNO" %in% names(eval_df)) {
        join_cols <- c("EXPERIMENT", "TRNO")
        if ("RUN" %in% names(eval_df) && "RUN" %in% names(pgro_tot)) {
          join_cols <- c(join_cols, "RUN")
        }
        eval_df <- dplyr::select(eval_df, dplyr::all_of(c(join_cols, sim_var_names)))
        eval_df <- eval_df[!duplicated(eval_df[, join_cols, drop = FALSE]), , drop = FALSE]
        names(eval_df)[(length(join_cols) + 1):ncol(eval_df)] <- sapply(sim_var_names, function(x) substr(x, 1, nchar(x) - 1))
        pgro_tot <- dplyr::left_join(
          pgro_tot,
          eval_df[, c(join_cols, setdiff(names(eval_df), names(pgro_tot)))],
          by = join_cols
        )
      }
    }
  }

  extra_files <- setdiff(model_options$out_files, c("PlantGro.OUT", "Evaluate.OUT", "PlantGr2.OUT"))
  for (out_file in extra_files) {
    out_path <- file.path(project_path, out_file)
    if (!file.exists(out_path)) {
      next
    }
    tmp <- dssat_read_output_safe(out_path, out_file) %>%
      dplyr::mutate(Date = DATE) %>%
      dplyr::select(-DATE) %>%
      dplyr::relocate(Date)
    pgro_tot <- dplyr::left_join(
      pgro_tot,
      tmp[, c("Date", "EXPERIMENT", "TRNO", setdiff(names(tmp), names(pgro_tot)))],
      by = c("Date", "EXPERIMENT", "TRNO")
    )
  }

  if (is.null(trt_numbers)) {
    trt_numbers <- sort(unique(pgro_tot$TRNO))
  }
  if (is.null(situation_names)) {
    if ("EXPERIMENT" %in% names(pgro_tot)) {
      exp_names <- unique(pgro_tot$EXPERIMENT)
      if (length(exp_names) == 1) {
        situation_names <- paste0(exp_names, "_", trt_numbers)
      } else {
        situation_names <- as.character(seq_along(trt_numbers))
      }
    } else {
      situation_names <- as.character(trt_numbers)
    }
  }

  sim_list <- setNames(vector("list", length(trt_numbers)), situation_names)
  for (i in seq_along(trt_numbers)) {
    trno <- trt_numbers[i]
    pgro <- dplyr::filter(pgro_tot, TRNO == trno)
    if ("EXPERIMENT" %in% names(pgro_tot) && grepl("_", situation_names[i], fixed = TRUE)) {
      exp_name <- strsplit(situation_names[i], "_", fixed = TRUE)[[1]][1]
      pgro_filtered <- dplyr::filter(pgro, EXPERIMENT == exp_name)
      if (nrow(pgro_filtered) > 0) {
        pgro <- pgro_filtered
      }
    }
    pgro <- pgro[!duplicated(pgro$Date), ]
    if ("TWAD" %in% names(pgro) && !("HWAM" %in% names(pgro))) {
      pgro$HWAM <- pgro$TWAD
    }
    if ("ADAT" %in% names(pgro) && inherits(pgro$ADAT, "Date")) {
      pgro$ADAT <- julian(pgro$ADAT, origin = as.Date(paste(lubridate::year(pgro$ADAT[1]), "01", "01", sep = "-"))) + 1
    }
    pgro <- dssat_add_stage_columns(pgro)
    if (!is.null(var)) {
      pgro <- dplyr::select(pgro, c("Date", any_of(var)))
    }
    sim_list[[i]] <- pgro
  }
  attr(sim_list, "class") <- "cropr_simulation"
  list(sim_list = sim_list, error = FALSE)
}

DSSAT_omniwrapper <- function(param_values = NULL, situation = NULL, model_options, var = NULL, ...) {
  model_options <- dssat_infer_model_options(model_options)

  project_path <- file.path(model_options$DSSAT_path, model_options$Crop)
  genotype_path <- file.path(model_options$DSSAT_path, model_options$Genotype)
  if (is.null(model_options$project_file)) {
    stop("model_options$project_file is required for DSSAT_omniwrapper prototype.")
  }
  exp_full_path <- normalizePath(model_options$project_file, winslash = "/", mustWork = TRUE)
  project_source_dir <- dirname(exp_full_path)
  project_file <- basename(exp_full_path)

  flag_eco_param <- FALSE
  flag_cul_param <- FALSE
  results <- list(sim_list = list(), error = FALSE)
  ini_wd <- getwd()

  options(DSSAT.CSM = file.path(model_options$DSSAT_path, model_options$DSSAT_exe))

  ecotype_filename <- model_options$ecotype_filename
  cultivar_filename <- model_options$cultivar_filename
  ecotype_path <- genotype_path
  cultivar_path <- genotype_path
  if (!is.null(ecotype_filename) && file.exists(file.path(project_source_dir, ecotype_filename))) {
    ecotype_path <- project_source_dir
  }
  if (!is.null(cultivar_filename) && file.exists(file.path(project_source_dir, cultivar_filename))) {
    cultivar_path <- project_source_dir
  }

  cultivar_match_columns <- if (!is.null(model_options$cultivar_match_columns)) {
    model_options$cultivar_match_columns
  } else {
    switch(
      model_options$adapter,
      SUBSTOR = c("VAR#", "VAR-NAME", "VRNAME", "CNAME", "INGENO"),
      CROPGRO = c("VAR-NAME", "VAR#", "VRNAME", "CNAME", "INGENO"),
      CERES = c("VAR-NAME", "VAR#", "VRNAME", "CNAME", "INGENO"),
      RICE = c("VAR-NAME", "VAR#", "VRNAME", "CNAME", "INGENO"),
      SUGARCANE = c("VAR-NAME", "VAR#", "VRNAME", "CNAME", "INGENO"),
      AROIDS = c("VAR-NAME", "VAR#", "VRNAME", "CNAME", "INGENO"),
      ALOHA = c("VAR-NAME", "VAR#", "VRNAME", "CNAME", "INGENO"),
      c("VAR-NAME", "VAR#", "VRNAME", "CNAME", "INGENO")
    )
  }

  exp_info <- dssat_parse_experiment_header(exp_full_path)
  if (is.null(situation)) {
    trt_numbers <- exp_info$treatments
    if (length(trt_numbers) == 0) {
      trt_numbers <- 1
    }
    situation_names <- paste0(tools::file_path_sans_ext(project_file), "_", trt_numbers)
  } else {
    requested <- as.character(situation)
    trt_numbers <- vapply(
      requested,
      function(x) {
        pieces <- strsplit(x, "_", fixed = TRUE)[[1]]
        candidate <- if (length(pieces) > 1) pieces[length(pieces)] else x
        suppressWarnings(as.integer(candidate))
      },
      integer(1)
    )
    if (any(is.na(trt_numbers))) {
      stop("Could not infer treatment numbers from situation argument.")
    }
    situation_names <- requested
  }

  run_dir <- file.path(project_path, paste0("omni_run_", Sys.getpid(), "_", sample(1:10000, 1)))
  dir.create(run_dir, showWarnings = FALSE)
  if (!dir.exists(run_dir)) {
    stop("Could not create temporary run directory.")
  }
  file.copy(exp_full_path, file.path(run_dir, project_file), overwrite = TRUE)

  on.exit({
    setwd(ini_wd)
    if (flag_eco_param && file.exists(file.path(ecotype_path, paste0(ecotype_filename, "_tmp")))) {
      file.rename(file.path(ecotype_path, paste0(ecotype_filename, "_tmp")), file.path(ecotype_path, ecotype_filename))
    }
    if (flag_cul_param && file.exists(file.path(cultivar_path, paste0(cultivar_filename, "_tmp")))) {
      file.rename(file.path(cultivar_path, paste0(cultivar_filename, "_tmp")), file.path(cultivar_path, cultivar_filename))
    }
    unlink(run_dir, recursive = TRUE)
  }, add = TRUE)

  if (!is.null(param_values) && !is.null(ecotype_filename) && file.exists(file.path(ecotype_path, ecotype_filename))) {
    eco <- read_eco(file.path(ecotype_path, ecotype_filename))
    eco_params <- names(eco)
    eco_param_names <- intersect(names(param_values), eco_params)
    if (length(eco_param_names) > 0) {
      file.copy(file.path(ecotype_path, ecotype_filename), file.path(ecotype_path, paste0(ecotype_filename, "_tmp")), overwrite = TRUE)
      flag_eco_param <- TRUE
      eco_target <- dssat_try_match_row(eco, model_options$ecotype, c("ECO#", "ECO", "ECO_NAME"))
      if (is.null(eco_target)) {
        warning("Ecotype not found in ecotype file: ", model_options$ecotype)
      } else {
        for (param in eco_param_names) {
          eco[[param]][eco_target$index] <- param_values[[param]]
        }
        attr(eco, "comments") <- NULL
        write_eco(eco, file.path(ecotype_path, ecotype_filename))
      }
    }
  }

  if (!is.null(param_values) && !is.null(cultivar_filename) && file.exists(file.path(cultivar_path, cultivar_filename))) {
    cul <- read_cul(file.path(cultivar_path, cultivar_filename))
    cul_params <- names(cul)
    cul_param_names <- intersect(names(param_values), cul_params)
    if (length(cul_param_names) > 0) {
      file.copy(file.path(cultivar_path, cultivar_filename), file.path(cultivar_path, paste0(cultivar_filename, "_tmp")), overwrite = TRUE)
      flag_cul_param <- TRUE
      cultivar_target <- dssat_try_match_row(cul, model_options$cultivar, cultivar_match_columns)
      if (is.null(cultivar_target)) {
        warning("Cultivar not found in cultivar file: ", model_options$cultivar)
      } else {
        for (param in cul_param_names) {
          if (is.character(cul[[param]])) {
            cul[[param]][cultivar_target$index] <- as.character(round(param_values[[param]], digits = 2))
          } else {
            cul[[param]][cultivar_target$index] <- param_values[[param]]
          }
        }
        write_cul(cul, file.path(cultivar_path, cultivar_filename))
      }
    }
  }

  if (!is.null(ecotype_filename) && file.exists(file.path(ecotype_path, ecotype_filename))) {
    file.copy(file.path(ecotype_path, ecotype_filename), file.path(run_dir, ecotype_filename), overwrite = TRUE)
  }
  if (!is.null(cultivar_filename) && file.exists(file.path(cultivar_path, cultivar_filename))) {
    file.copy(file.path(cultivar_path, cultivar_filename), file.path(run_dir, cultivar_filename), overwrite = TRUE)
  }
  if (!is.null(model_options$species_filename)) {
    species_path <- file.path(model_options$DSSAT_path, model_options$Genotype, model_options$species_filename)
    if (file.exists(species_path)) {
      file.copy(species_path, file.path(run_dir, model_options$species_filename), overwrite = TRUE)
    }
  }
  if (!is.null(model_options$filea)) {
    filea_path <- file.path(project_source_dir, model_options$filea)
    if (file.exists(filea_path)) {
      file.copy(filea_path, file.path(run_dir, model_options$filea), overwrite = TRUE)
    }
  }
  if (!is.null(model_options$filet)) {
    filet_path <- file.path(project_source_dir, model_options$filet)
    if (file.exists(filet_path)) {
      file.copy(filet_path, file.path(run_dir, model_options$filet), overwrite = TRUE)
    }
  }

  setwd(run_dir)
  write_dssbatch(x = project_file, trtno = trt_numbers)
  dssat_run_model(
    run_dir = run_dir,
    model_options = modifyList(
      model_options,
      list(suppress_output = ifelse(is.null(model_options$suppress_output), TRUE, model_options$suppress_output))
    )
  )
  setwd(ini_wd)

  if (file.exists(file.path(run_dir, "ERROR.OUT"))) {
    results$error <- TRUE
  }

  out <- dssat_read_outputs_generic(
    project_path = run_dir,
    model_options = model_options,
    situation_names = situation_names,
    trt_numbers = trt_numbers,
    var = var
  )
  out
}

DSSAT_omni_read_obs <- function(model_options, situation, read_end_season = FALSE) {
  model_options <- dssat_infer_model_options(model_options)
  crop_code <- model_options$crop_code
  situation_df <- setNames(
    as.data.frame(t(dplyr::bind_rows(sapply(situation, FUN = strsplit, "_")))),
    c("EXPERIMENT", "TRNO")
  )
  obs_df <- NULL

  for (experiment in unique(situation_df$EXPERIMENT)) {
    filtered_situation_df <- dplyr::filter(situation_df, EXPERIMENT == experiment)
    trno <- as.integer(filtered_situation_df$TRNO)

    file_name_a <- file.path(model_options$DSSAT_path, model_options$Crop, paste0(experiment, ".", crop_code, "A"))
    file_name_t <- file.path(model_options$DSSAT_path, model_options$Crop, paste0(experiment, ".", crop_code, "T"))

    in_season_obs_df <- NULL
    if (file.exists(file_name_t)) {
      in_season_obs_df <- read_filet(file_name_t, na_strings = NA) %>%
        dplyr::mutate(Date = DATE) %>%
        dplyr::select(-DATE) %>%
        dplyr::relocate(Date) %>%
        dplyr::filter(TRNO %in% trno)
    }

    end_season_obs_df <- NULL
    if (file.exists(file_name_a) && read_end_season) {
      end_season_obs_df <- read_filea(file_name_a, na_strings = NA) %>% dplyr::filter(TRNO %in% trno)
      if ("MDAT" %in% names(end_season_obs_df)) {
        end_season_obs_df <- end_season_obs_df %>% dplyr::mutate(Date = MDAT) %>% dplyr::select(-MDAT) %>% dplyr::relocate(Date)
      } else if ("HDAT" %in% names(end_season_obs_df)) {
        end_season_obs_df <- end_season_obs_df %>% dplyr::mutate(Date = HDAT) %>% dplyr::select(-HDAT) %>% dplyr::relocate(Date)
      }
    }

    if (is.null(in_season_obs_df) && is.null(end_season_obs_df)) {
      next
    }

    obs_df_tmp <- if (is.null(end_season_obs_df)) {
      in_season_obs_df
    } else if (is.null(in_season_obs_df)) {
      end_season_obs_df
    } else {
      dplyr::full_join(in_season_obs_df, end_season_obs_df, by = c("TRNO", "Date"))
    }

    obs_df_tmp <- dplyr::mutate(obs_df_tmp, situation = paste0(experiment, "_", TRNO)) %>%
      dplyr::select(-TRNO)
    obs_df <- dplyr::bind_rows(obs_df, obs_df_tmp)
  }

  obs_list <- split(obs_df, f = obs_df$situation)
  obs_list <- lapply(obs_list, function(x) dplyr::select(x, -situation))
  obs_list[situation]
}
