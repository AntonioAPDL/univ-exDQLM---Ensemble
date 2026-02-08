#!/usr/bin/env Rscript

source(file.path("scripts", "lib", "model_a_univ.R"))

dir.create("tmp", showWarnings = FALSE, recursive = TRUE)

sim <- simulate_univ_model_a(
  Tn = 25,
  p0 = 0.4,
  sigma = 1.1,
  gamma = 0.15,
  W = 0.03,
  seed = 20260208
)

fit <- run_model_a_cavi(
  y = sim$y,
  p0 = sim$p0,
  n_iter = 8,
  seed = 20260208,
  W = 0.03
)

summary_out <- list(
  sigma_hat = fit$sigma,
  gamma_hat = fit$gamma,
  theta_tail = tail(fit$theta_mean, 5),
  finite = all(is.finite(c(fit$sigma, fit$gamma, fit$theta_mean, fit$Ev, fit$Es)))
)

saveRDS(summary_out, file = file.path("tmp", "univ_example_summary.rds"))
cat("Wrote tmp/univ_example_summary.rds\n")
cat(sprintf("sigma_hat=%.6f gamma_hat=%.6f finite=%s\n", summary_out$sigma_hat, summary_out$gamma_hat, summary_out$finite))
