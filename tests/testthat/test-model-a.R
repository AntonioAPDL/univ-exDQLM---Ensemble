source(file.path("..", "..", "scripts", "lib", "model_a_univ.R"))

test_that("exAL mapping is finite on feasible interior", {
  p0 <- 0.4
  bounds <- exal_gamma_bounds(p0)
  grid <- seq(bounds["L"] + 0.05, bounds["U"] - 0.05, length.out = 20)
  for (g in grid) {
    m <- exal_map(p0, g)
    expect_true(all(is.finite(c(m$g, m$p, m$A, m$B, m$C))))
    expect_true(m$p > 0 && m$p < 1)
    expect_true(m$B > 0)
  }
})

test_that("univariate update loop stays finite and dimensionally aligned", {
  sim <- simulate_univ_model_a(Tn = 16, p0 = 0.4, sigma = 1, gamma = 0.12, W = 0.03, seed = 12)
  fit <- run_model_a_cavi(y = sim$y, p0 = sim$p0, n_iter = 5, seed = 12, W = 0.03)

  expect_true(check_internal_dimensions(sim$y, fit$theta_mean, fit$Ev, fit$Es))
  expect_true(all(is.finite(c(fit$sigma, fit$gamma, fit$theta_mean, fit$Ev, fit$Es))))
})

test_that("static model special case matches closed-form posterior mean", {
  set.seed(123)
  y <- rnorm(15, mean = 1.5, sd = 0.5)
  R <- rep(0.25, length(y))
  out <- static_equivalence_check(y = y, R = R, m0 = 0.2, C0 = 2.5, tol = 1e-8)
  expect_true(out$pass)
})
