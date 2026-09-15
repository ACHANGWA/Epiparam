# ---------------------------------------------------------------------------
# EpiParam: build the Bayesian models for this computer
#
# Optional. EpiParam compiles each Bayesian model the first time it is needed,
# in the background from the moment the app opens, so this script only moves
# that wait to installation time. It is worth running when EpiParam is being
# set up on a shared computer or a server, or before a training session.
#
# From a terminal, in the EpiParam folder:    Rscript precompile_models.R
# From R or RStudio, in the EpiParam folder:  source("precompile_models.R")
#
# Compiling takes roughly one to three minutes and about 3.5 GB of memory per
# model, four models in all, and needs a working C++ toolchain:
#   Windows   Rtools, from https://cran.r-project.org/bin/windows/Rtools/
#   macOS     run  xcode-select --install  in the Terminal
#   Linux     the build tools, for example  sudo apt install build-essential
#
# The compiled models are written to a per-user cache folder, which this script
# prints when it runs.
#
# Shipping the models with the app
# --------------------------------
#   Rscript precompile_models.R --bundle
#   (from R:  bundle <- TRUE; source("precompile_models.R"))
#
# also copies the models into the stan_models folder of the app. Copy that
# folder along with the app, and every computer with the same operating system,
# the same R version (major.minor, for example 4.4) and the same rstan version
# uses them straight away, with no compilation at all. Any other computer
# ignores them and compiles its own, so a mismatch never breaks the app. Run
# the command once on each kind of computer you want to cover; the file names
# say which platform and versions each model belongs to.
# ---------------------------------------------------------------------------

if (!requireNamespace("rstan", quietly = TRUE)) {
  stop("rstan is not installed. Run  install.packages(\"rstan\")  first.", call. = FALSE)
}

if (!exists("bundle")) bundle <- "--bundle" %in% commandArgs(trailingOnly = TRUE)

# the models are defined once, in the application file, between the two
# "stan helpers" markers. this script reads them from there rather than keeping
# a second copy that could drift out of step.
find_app_file <- function() {
  rmd  <- list.files(".", pattern = "[.]Rmd$", full.names = TRUE)
  keep <- vapply(rmd, function(f)
    any(grepl("^# --- stan helpers: start", readLines(f, warn = FALSE))),
    logical(1))
  rmd <- rmd[keep]
  if (!length(rmd)) {
    stop("No EpiParam application file was found in ", normalizePath("."),
         ".\nRun this script from the folder that holds the application.",
         call. = FALSE)
  }
  rmd[1]
}

load_model_definitions <- function(app_file) {
  src <- readLines(app_file, warn = FALSE)
  i0  <- grep("^# --- stan helpers: start", src)
  i1  <- grep("^# --- stan helpers: end",   src)
  if (length(i0) != 1 || length(i1) != 1 || i1 <= i0) {
    stop("The 'stan helpers' markers in ", basename(app_file),
         " are missing or out of order, so the model definitions cannot be read.",
         call. = FALSE)
  }
  block <- tempfile(fileext = ".R")
  writeLines(src[(i0 + 1):(i1 - 1)], block)
  source(block, local = FALSE)
  invisible(TRUE)
}

app_file <- find_app_file()
cat("Reading the model definitions from", basename(app_file), "\n")
load_model_definitions(app_file)

suppressPackageStartupMessages(library(rstan))

cat("Compiled models will be kept in:\n  ", stan_cache_dir(), "\n\n")

failed <- character(0)
for (m in STAN_MODELS) {
  cat("Building the", m, "model ... ")
  t0 <- Sys.time()
  # EpiParam may be compiling this model in the background right now
  if (stan_lock_busy(m)) cat("(already being compiled by EpiParam, waiting) ")
  while (stan_lock_busy(m)) Sys.sleep(2)
  stan_build(m)
  if (!is.null(stan_read_model(stan_cache_file(m), get_stan_code(m)))) {
    cat(sprintf("ready (%.0f seconds)\n",
                as.numeric(difftime(Sys.time(), t0, units = "secs"))))
    if (bundle) {
      dir.create("stan_models", showWarnings = FALSE)
      file.copy(stan_cache_file(m), stan_bundle_file(m), overwrite = TRUE)
    }
  } else if (!is.null(stan_read_model(stan_bundle_file(m), get_stan_code(m)))) {
    cat("ready (shipped with the app in stan_models)\n")
  } else {
    cat("failed\n\n")
    err <- tryCatch(readLines(stan_error_file(m), warn = FALSE),
                    error = function(e) "no message", warning = function(w) "no message")
    message(stan_build_help(m, paste(err, collapse = "\n")))
    failed <- c(failed, m)
  }
}

if (length(failed)) {
  cat("\nNot built:", paste(failed, collapse = ", "),
      "\nFix the problem reported above and run this script again.\n")
} else {
  cat("\nAll four models are ready. EpiParam will now open its Bayesian pages",
      "\nwithout stopping to compile.\n")
  if (bundle) {
    cat("\nCopies for other computers like this one are in the stan_models folder:\n  ",
        paste(basename(vapply(STAN_MODELS, stan_bundle_file, "")), collapse = "\n   "), "\n")
  }
}
