
EpiParam, a web-based Shiny application that provides an interactive platform for estimating and visualizing core epidemiological parameters using community-level outbreak data.

# Installation
This application is available as a shiny application downloadable at https://github.com/ACHANGWA/Epiparam.
R was chosen as the computing platform because it is free, open source, and runs on any modern operating system so the application can be broadly available as possible.

To install and run the shiny app locally on your computer you will need to first install R, it is also suggested that you install Rstudio. For detailed instructions for installing the R and R studio, visit the respective links https://cran.r-project.org/bin/windows/base/ and   https://posit.co/download/rstudio-desktop

## R packages

The versions of every package the application was tested with are recorded in `renv.lock`, which ships with the source. Installing from the lockfile gives you that exact set, so the application keeps working as newer, incompatible versions of its dependencies are released. From the R console, in the EpiParam folder:

```r
install.packages("renv")
renv::restore(lockfile = "renv.lock")
```

That reads the lockfile and installs each package at the recorded version. It is the recommended route, and the only one that is reproducible over time.

If you would rather install the current version of everything, the direct route still works:

```r
install.packages(c("shiny", "shinyjs", "htmltools", "knitr", "flexdashboard",
                   "lubridate", "bslib", "tidyverse", "janitor", "plotly",
                   "MASS", "R0", "DT", "EpiEstim", "incidence2", "visNetwork",
                   "webshot2", "officer", "networkD3", "highcharter",
                   "fitdistrplus", "stringr", "rstan", "loo", "rmarkdown"))
```

Maintainers: after changing or updating a dependency, regenerate the lockfile on the release machine with `renv::snapshot()` so that what is recorded is what was tested.

## C++ toolchain, needed by the Bayesian windows
The two Bayesian windows fit their models with Stan, and a Stan model has to be compiled into machine code before it can be used. EpiParam compiles the models on your own computer, so you need a working C++ toolchain:

* **Windows**: install Rtools for your version of R, from https://cran.r-project.org/bin/windows/Rtools/
* **macOS**: run `xcode-select --install` in the Terminal
* **Linux**: install the build tools, for example `sudo apt install build-essential`

## How long the Bayesian models take
Once a model is compiled, a run takes a few seconds. Compiling takes one to three minutes per model and happens once per computer, so EpiParam keeps it out of the way:

* **It starts by itself when the app opens.** A separate R process compiles the models the computer does not have yet, the default model of each Bayesian window first, while you load your data. Usually the model is ready, or nearly ready, by the time you press *Run Bayesian Model*.
* **The model you ask for goes first.** If you choose a model that has not been compiled yet, it is compiled next, and the progress bar shows how long it has been going.
* **One model at a time.** Compiling a Stan model uses about 3.5 GB of memory, so models are never compiled side by side.
* **Once per computer.** Each compiled model is kept in a cache folder belonging to the user, and every later run, including after R is restarted, starts immediately.

This needs the `callr` package, which is part of `renv.lock`. Without it, the model is compiled when you first press *Run Bayesian Model*, as before. Set the environment variable `EPIPARAM_STAN_PREPARE=false` to switch off the compilation at start-up.

To do all the compiling at installation time instead, open the EpiParam folder in R and run `source("precompile_models.R")`, or from a terminal in that folder `Rscript precompile_models.R`.

## Shipping precompiled models
A compiled Stan model is a shared library that only loads on the operating system, R version and rstan version that produced it, which is why the source code does not carry one for everybody. Where the computers that will run EpiParam are set up alike (the same operating system, the same R version such as 4.4, and the same rstan version, for example after `renv::restore()`), you can build the models once and ship them with the app:

```r
bundle <- TRUE; source("precompile_models.R")
```

or `Rscript precompile_models.R --bundle` from a terminal. This writes the four models to a `stan_models` folder next to the application; copy that folder along with the app. A computer that matches uses them straight away, with no compilation at all. A computer that does not match ignores them and compiles its own, so a mismatch never breaks the app. The file names say which platform and versions each model belongs to, and the command can be run on several kinds of computer to fill the folder.

## Where the models are kept
The cache folder is the one reported by `tools::R_user_dir("EpiParam", "cache")`. Set the `EPIPARAM_STAN_CACHE` environment variable before starting R to put it somewhere else, which is useful for a shared or server installation. To rebuild the models from scratch, delete the files in that folder. EpiParam also rebuilds a model by itself whenever the Stan code in the application changes, so the models being fitted are always the ones written in `get_stan_code()`.

## Reproducible Bayesian results
The MCMC sampler starts from a fixed seed (`STAN_SEED` in the setup chunk of the application), so the same data, model and number of iterations give exactly the same estimates on every run. Run to run, without a fixed seed, the posterior medians moved by 0.02 to 0.05 days on the example data. Changing `STAN_SEED` is a quick way to check that a result does not depend on the seed. Results can differ in the last decimals between computers, because compilers round floating-point arithmetic slightly differently.

## Typeface
The application uses Jost, an open typeface (SIL Open Font License, see `fonts/OFL.txt`), and embeds it in the page, so it looks the same on Windows, macOS and Linux, with or without an internet connection. To use another typeface, change `--epiparam-font` in the style sheet at the top of the application file.

# Instructions 
Dowload the Epiparam folder with all the files to your local computer. Please note that all data files, and the `fonts` folder (and `stan_models`, if you ship precompiled models), must be kept in the same folder as the application for it to run.
After downloading the source code from this repository, to launch the application open the file called `Epiparam_Full_App_w_Bayesian 23-04-2026.Rmd` and this will open an Rstudio window. click on 'Run Document' to open the ui.R and depending on your computer this may take some time.

# Screenshots
Here are example screenshots of the application before analysis.


<img width="1917" height="977" alt="image (10)" src="https://github.com/user-attachments/assets/d0af4b24-4c95-4f6e-a69f-6b36e8864df9" />


The application has 6 modules (windows). 
# 1. Incubation Period
This window estimates the incubation period using MLE parametric models including the lognormal, weibull and gamma models.

<img width="1915" height="978" alt="image (11)" src="https://github.com/user-attachments/assets/9600e1de-1b5d-4ff5-8750-75be7241437c" />

# 2. Incubation Period (Bayesian)
This window estimates the incubation period using parametric Bayesian models. 

<img width="1911" height="981" alt="image (12)" src="https://github.com/user-attachments/assets/768cb01e-29bb-484f-b015-182a6ba2c9e4" />

# 3. Serial interval 
This window estimates the incubation period using MLE parametric models including the lognormal, weibull, gamma and normal models.

<img width="1906" height="979" alt="image (13)" src="https://github.com/user-attachments/assets/75f479e9-018e-4914-8890-645d36515748" />

# 4. Serial interval (Bayesian)
This window estimates the serial interval using parametric Bayesian models. 
<img width="1904" height="961" alt="image (14)" src="https://github.com/user-attachments/assets/4e30b30f-e548-418b-b3ec-906e6cb066c2" />

# 5. Effective reproduction number (Rt)
This window estimates the time-varying reproduction number, Rt, with the method of Cori et al. (2013) as implemented in the EpiEstim package (`estimate_R`, parametric serial interval). Incidence is counted by date of onset, and Rt is estimated over sliding windows whose length can be set in the sidebar (7 days by default).

* **Incidence data**: upload a file, or reuse the file already loaded on the Incubation Period or Serial Interval window. Any file with a date of onset for each case can be used; the column may be called `date of onset` or `date onset`, and dates may be day-month-year, year-month-day or month-day-year.
* **Serial interval**: by default the estimate made on the Serial Interval window is used, taking the distribution selected there (or, when all four are shown, the one with the lowest AIC). A mean and standard deviation can instead be entered by hand, which is useful when there are no transmission pairs to estimate it from. The method requires a mean serial interval above 1 day.
* **Outputs**: the number of cases, the mean serial interval used and the latest Rt; Rt over time with its 95% credible interval, daily incidence, the discretised serial interval actually used, and a table of estimates for every window that can be downloaded as CSV, Excel or PDF.

Reference: Cori A, Ferguson NM, Fraser C, Cauchemez S. A new framework and software to estimate time-varying reproduction numbers during epidemics. *American Journal of Epidemiology* 2013;178(9):1505-1512. https://doi.org/10.1093/aje/kwt133

# k and R0
Estimates the R0 and K values using generation of transmission pairs.
<img width="1908" height="993" alt="image (15)" src="https://github.com/user-attachments/assets/58333d18-ff2d-4b21-8c42-a3359537d783" />


