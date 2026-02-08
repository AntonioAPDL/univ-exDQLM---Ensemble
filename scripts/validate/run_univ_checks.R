#!/usr/bin/env Rscript

source(file.path("scripts", "lib", "model_a_univ.R"))

run_check <- function(name, fn) {
  out <- tryCatch(fn(), error = function(e) list(pass = FALSE, detail = e$message))
  pass <- isTRUE(out$pass)
  detail <- if (!is.null(out$detail)) out$detail else ""
  cat(sprintf("[%s] %s %s\n", if (pass) "PASS" else "FAIL", name, detail))
  list(pass = pass, name = name, detail = detail)
}

check_map_finite <- function() {
  p0 <- 0.4
  bounds <- exal_gamma_bounds(p0)
  grid <- seq(bounds["L"] + 0.05, bounds["U"] - 0.05, length.out = 25)
  vals <- lapply(grid, function(g) exal_map(p0, g))
  ok <- all(vapply(vals, function(v) all(is.finite(c(v$g, v$p, v$A, v$B, v$C))), logical(1)))
  list(pass = ok, detail = sprintf("grid=%d", length(grid)))
}

check_end_to_end <- function() {
  sim <- simulate_univ_model_a(Tn = 20, p0 = 0.4, sigma = 1, gamma = 0.1, W = 0.02, seed = 11)
  fit <- run_model_a_cavi(y = sim$y, p0 = sim$p0, n_iter = 6, seed = 11, W = 0.02)
  finite <- all(is.finite(c(fit$sigma, fit$gamma, fit$theta_mean, fit$Ev, fit$Es)))
  dims <- check_internal_dimensions(sim$y, fit$theta_mean, fit$Ev, fit$Es)
  list(pass = finite && dims, detail = sprintf("finite=%s dims=%s", finite, dims))
}

check_static_equiv <- function() {
  set.seed(99)
  y <- rnorm(12, mean = 2, sd = 0.4)
  R <- rep(0.2, length(y))
  out <- static_equivalence_check(y = y, R = R, m0 = 0.5, C0 = 3, tol = 1e-8)
  list(pass = out$pass, detail = sprintf("abs_err=%.3e", out$error))
}

results <- list(
  run_check("exAL map finite and feasible", check_map_finite),
  run_check("tiny end-to-end univariate run", check_end_to_end),
  run_check("static DLM special-case equivalence", check_static_equiv)
)

if (!all(vapply(results, function(x) x$pass, logical(1)))) {
  quit(status = 1)
}
