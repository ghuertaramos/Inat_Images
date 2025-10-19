#! /usr/bin/Rscript
## Guillermo Huerta Ramos

# ---- Packages: install + load (rinat, optparse) ----
inat_packages <- c("rinat", "optparse")
package.check <- lapply(
  inat_packages,
  function(x) {
    # set a CRAN mirror if none is set (avoids interactive prompts)
    repos <- getOption("repos")
    if (is.null(repos) || is.na(repos["CRAN"]) || repos["CRAN"] == "@CRAN@") {
      options(repos = c(CRAN = "https://cloud.r-project.org"))
    }
    if (!requireNamespace(x, quietly = TRUE)) {
      install.packages(x, dependencies = TRUE)
    }
    suppressPackageStartupMessages(library(x, character.only = TRUE))
  }
)

# ---- CLI (optparse) ----
option_list <- list(
  make_option(c("-i","--input"),  type="character", default="species.csv",
              help="Path to the input CSV [default %default]"),
  make_option(c("-f","--folder"), type="character", default="images",
              help="Output folder for images [default %default]"),
  make_option(c("-o","--observations"), type="integer", default=100,
              help="Max observations to query (pre-filter) [default %default]"),
  make_option(c("-q","--quality"), type="character", default="Research",
              help="Quality grade: Research | Casual | All_Q [default %default]"),
  make_option(c("-l","--license"), type="character", default="NonCC",
              help="License filter: Wikicommons | NonCC | All_L [default %default]"),
  make_option(c("-s","--size"), type="character", default="Medium",
              help="Image size: Small | Medium | Large | Original [default %default]"),
  make_option(c("-a","--annotation"), type="character", default=NULL,
              help="term_id,value_id (e.g., 12,15)"),
  make_option(c("-y","--year"),  type="integer", default=NULL),
  make_option(c("-m","--month"), type="integer", default=NULL),
  make_option(c("-d","--day"),   type="integer", default=NULL),
  make_option(c("-b","--bounds"), type="character", default=NULL,
              help="Path to txt: lon_min,lat_min,lon_max,lat_max"),
  make_option(c("--output"), type="character", default="inat_data.csv",
              help="Output CSV path [default %default]")
)
args <- parse_args(OptionParser(option_list = option_list))

# ---- helper: resize final photo URL to requested size ----
resize_url <- function(u, size) {
  size <- tolower(size)
  # Replace the trailing size token while preserving extension
  pattern <- "(square|small|medium|large|original)\\.(jpg|jpeg)$"
  if (is.na(u) || !nzchar(u)) return(u)
  if (grepl(pattern, u, perl = TRUE)) {
    sub(pattern, paste0(size, ".\\2"), u, perl = TRUE)
  } else {
    u
  }
}

# ---- Early validation & normalization ----
quality <- tolower(trimws(args$quality))
license <- tolower(trimws(args$license))
size    <- tolower(trimws(args$size))

valid_quality <- c("research","casual","all_q")
valid_license <- c("wikicommons","noncc","all_l")
valid_size    <- c("small","medium","large","original")

if (!quality %in% valid_quality) stop("Invalid quality. Use: Research, Casual, or All_Q.")
if (!license %in% valid_license) {
  sug <- valid_license[which.min(adist(license, valid_license))]
  stop(sprintf(
    "Invalid license '%s'. Use: Wikicommons, NonCC, or All_L.%s",
    args$license,
    if (!is.na(sug)) sprintf(" Did you mean '%s'?", sug) else ""
  ))
}
if (!size %in% valid_size) stop("Invalid size. Use: Small, Medium, Large, or Original.")

# write normalized values back so the rest of the code uses the canonical forms
args$quality <- quality
args$license <- license
args$size    <- size

# optional range checks
if (is.numeric(args$observations) && (args$observations < 1 || args$observations > 10000)) {
  stop("observations (-o) must be between 1 and 10000.")
}
if (!is.null(args$month) && (args$month < 1 || args$month > 12)) stop("month (-m) must be 1..12.")
if (!is.null(args$day)   && (args$day   < 1 || args$day   > 31)) stop("day (-d) must be 1..31.")

# ---- Paths & input ----
image_folder <- args$folder
if (!dir.exists(image_folder)) dir.create(image_folder, recursive = TRUE, showWarnings = FALSE)

input_file <- args$input
if (!file.exists(input_file)) stop(sprintf("The specified input file '%s' does not exist.", input_file))

obs_df <- tryCatch(
  read.csv(input_file, header = TRUE, stringsAsFactors = FALSE, check.names = FALSE),
  error = function(e) stop("Failed to read input CSV: ", e$message)
)

# Build species vector "Genus Species"
species <- trimws(paste(obs_df$Genus, obs_df$Species))
species <- species[nzchar(species)]
species <- sub("^(\\S+\\s+\\S+).*", "\\1", species)
species <- unique(species)
if (length(species) == 0) stop("No valid 'Genus Species' rows found in input.")

# ---- Annotation (parse + validate + set ann_vec) ----
ann_vec <- NULL
if (!is.null(args$annotation)) {
  parts <- as.integer(strsplit(args$annotation, ",", fixed = TRUE)[[1]])
  if (length(parts) != 2 || anyNA(parts)) {
    stop("Annotation must be two integers like 12,15 (term_id,value_id).")
  }
  term_id <- parts[1]
  term_value_id <- parts[2]
  
  valid_annotations <- list(
    `1`  = c(2, 3, 4, 5, 6, 7, 8, 16),    # Life Stage
    `9`  = c(10, 11),                     # Sex
    `12` = c(13, 14, 15, 21),             # Plant Phenology
    `17` = c(18, 19, 20),                 # Alive or Dead
    `22` = c(23,24,25,26,27,28,29,30,31,32,35) # Evidence of Presence
  )
  if (!(as.character(term_id) %in% names(valid_annotations)) ||
      !(term_value_id %in% valid_annotations[[as.character(term_id)]])) {
    stop("Invalid term_id/value_id for annotation. Check the valid pairs.")
  }
  ann_vec <- parts  # what we actually pass to get_inat_obs()
}

# ---- Bounds (optional) ----
bounds_vec <- NULL
if (!is.null(args$bounds)) {
  if (!file.exists(args$bounds)) stop("Bounds file not found: ", args$bounds)
  b <- scan(args$bounds, what = double(), sep = ",", quiet = TRUE, strip.white = TRUE)
  if (length(b) != 4) stop("Bounds must be 'lon_min,lat_min,lon_max,lat_max' (4 numbers).")
  bounds_vec <- b
}

# ---- Fetch per species ----
inat_list <- lapply(species, function(sp) {
  message(sprintf("Fetching data for %s", sp))
  
  call_args <- list(
    taxon_name = sp,
    maxresults = as.numeric(args$observations),
    year  = args$year,
    month = args$month,
    day   = args$day,
    bounds = bounds_vec
  )
  if (!is.null(ann_vec)) call_args$annotation <- ann_vec
  
  if (args$quality == "research") {
    call_args$quality <- "research"
  } else if (args$quality == "casual") {
    call_args$quality <- "casual"
  } else if (args$quality == "all_q") {
    # do nothing → omit quality to get both grades
  } else {
    stop("Invalid quality. Use Research, Casual, or All_Q.")
  }
  
  inat_out <- tryCatch(
    do.call(get_inat_obs, call_args),
    error = function(e) { message("  WARNING: no match for ", sp); NULL }
  )
  
  Sys.sleep(2.5)  # be nice to the API
  inat_out
})

inat_data <- Filter(Negate(is.null), inat_list)
if (length(inat_data) == 0) stop("No data returned from iNaturalist for your query.")
inat_data <- do.call(rbind, inat_data)

# ---- Per-species filtering + download ----
species_found <- unique(inat_data$scientific_name)

final_inat_list <- lapply(species_found, function(sp) {
  newdata <- inat_data[inat_data$scientific_name == sp, ]
  
  # license filter
  lic <- args$license
  lic_col <- toupper(trimws(newdata$license))
  lic_col <- sub("^CC-0$", "CC0", lic_col)
  
  if (lic == "wikicommons") {
    allow <- c("CC0", "CC-BY", "CC-BY-SA")
    newdata <- newdata[lic_col %in% allow, ]
  } else if (lic == "noncc") {
    # EXCLUDE only the strict "CC" string; keep CC0 and all CC-* variants
    newdata <- newdata[lic_col != "CC", ]
  } else if (lic == "all_l") {
    # no filter
  } else {
    stop("Invalid license. Use Wikicommons, NonCC, or All_L.")
  }
  
  # drop rows without an image url
  newdata <- newdata[!is.na(newdata$image_url) & nzchar(newdata$image_url), ]
  if (nrow(newdata) == 0) return(NULL)
  
  # create species folder
  infolder <- file.path(image_folder, gsub(" ", "_", sp))
  dir.create(infolder, showWarnings = FALSE, recursive = TRUE)
  
  for (b in seq_len(nrow(newdata))) {
    user <- newdata$user_login[b]
    cc   <- newdata$license[b]
    if (is.na(cc) || cc == "") cc <- "NO_LIC" else cc <- sub("^CC-0$", "CC0", cc)
    url  <- newdata$image_url[b]
    id   <- newdata$id[b]
    
    if (is.na(url) || !nzchar(url)) {
      message("  Skipping obs ", id, " — empty image_url")
      next
    }
    
    # apply requested size
    url <- resize_url(url, args$size)
    
    file_name <- file.path(infolder, paste0(sp, "_", user, "_", cc, "_", id, ".jpeg"))
    
    ok <- TRUE
    tryCatch(
      download.file(url, file_name, mode = "wb", quiet = TRUE),
      error = function(e) { ok <<- FALSE }
    )
    if (!ok && args$size == "original") {
      url2 <- resize_url(url, "large")
      message("  original failed, retrying large: ", id)
      try(download.file(url2, file_name, mode = "wb", quiet = TRUE), silent = TRUE)
    }
  }
  
  newdata
})

final_inat_list <- Filter(Negate(is.null), final_inat_list)
if (length(final_inat_list) == 0) stop("All results were filtered out (license and/or empty image URLs).")
final_inat_data <- do.call(rbind, final_inat_list)

# ---- Write CSV ----
dir.create(dirname(args$output), recursive = TRUE, showWarnings = FALSE)
write.csv(final_inat_data, args$output, row.names = FALSE)
cat("Done. Data saved to:", args$output, "\n")
