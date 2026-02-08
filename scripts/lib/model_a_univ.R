exal_g <- function(gamma) {
  2 * pnorm(-abs(gamma)) * exp(gamma^2 / 2)
}

exal_gamma_bounds <- function(p0, search_upper = 12) {
  stopifnot(is.finite(p0), p0 > 0, p0 < 1)
  gfun <- exal_g

  pos_target <- p0
  neg_target <- 1 - p0

  find_root <- function(target) {
    f <- function(x) gfun(x) - target
    hi <- search_upper
    while (f(hi) > 0 && hi < 200) {
      hi <- hi * 1.5
    }
    if (f(hi) > 0) {
      stop("Failed to bracket gamma feasibility root.")
    }
    uniroot(f, lower = 0, upper = hi)$root
  }

  U <- find_root(pos_target)
  L <- -find_root(neg_target)
  c(L = L, U = U)
}

exal_map <- function(p0, gamma, eps = 1e-10) {
  g <- exal_g(gamma)
  ind_neg <- as.numeric(gamma < 0)
  ind_pos <- as.numeric(gamma > 0)
  p <- ind_neg + (p0 - ind_neg) / g

  if (!is.finite(p) || p <= eps || p >= 1 - eps) {
    stop("Invalid p(p0, gamma): outside (0,1).")
  }

  A <- (1 - 2 * p) / (p * (1 - p))
  B <- 2 / (p * (1 - p))
  denom <- ind_pos - p
  if (!is.finite(denom) || abs(denom) < eps) {
    stop("Invalid C denominator.")
  }
  C <- 1 / denom

  list(g = g, p = p, A = A, B = B, C = C)
}

safe_k_ratio <- function(nu_num, nu_den, z) {
  z <- pmax(z, 1e-12)
  kn <- besselK(z, nu = nu_num, expon.scaled = TRUE)
  kd <- besselK(z, nu = nu_den, expon.scaled = TRUE)
  ratio <- kn / kd
  ratio[!is.finite(ratio)] <- NA_real_
  ratio
}

gig_moment <- function(lambda, chi, psi, r) {
  chi <- pmax(chi, 1e-12)
  psi <- pmax(psi, 1e-12)
  delta <- sqrt(chi * psi)
  ratio <- safe_k_ratio(lambda + r, lambda, delta)
  out <- (chi / psi)^(r / 2) * ratio
  out[!is.finite(out)] <- NA_real_
  out
}

trunc_norm_pos_moments <- function(mu, var) {
  var <- pmax(var, 1e-12)
  sd <- sqrt(var)
  alpha <- -mu / sd

  tail_prob <- pnorm(alpha, lower.tail = FALSE)
  ratio <- dnorm(alpha) / pmax(tail_prob, 1e-15)
  large <- alpha > 8
  ratio[large] <- alpha[large] + 1 / pmax(alpha[large], 1e-6)

  mean <- mu + sd * ratio
  second <- var + mu^2 + sd * mu * ratio
  list(mean = mean, var = pmax(second - mean^2, 1e-12))
}

kalman_smoother_local_level <- function(y, R, W, m0 = 0, C0 = 10) {
  stopifnot(length(y) == length(R), all(is.finite(y)), all(is.finite(R)), W >= 0)
  n <- length(y)

  a <- numeric(n)
  Rpred <- numeric(n)
  m <- numeric(n)
  C <- numeric(n)

  m_prev <- m0
  C_prev <- C0

  for (t in seq_len(n)) {
    a[t] <- m_prev
    Rpred[t] <- C_prev + W
    Q <- Rpred[t] + R[t]
    K <- Rpred[t] / Q
    m[t] <- a[t] + K * (y[t] - a[t])
    C[t] <- (1 - K) * Rpred[t]
    m_prev <- m[t]
    C_prev <- C[t]
  }

  ms <- m
  Cs <- C
  if (n >= 2) {
    for (t in (n - 1):1) {
      J <- C[t] / pmax(Rpred[t + 1], 1e-12)
      ms[t] <- m[t] + J * (ms[t + 1] - a[t + 1])
      Cs[t] <- C[t] + J^2 * (Cs[t + 1] - Rpred[t + 1])
    }
  }

  list(
    pred_mean = a,
    pred_var = pmax(Rpred, 1e-12),
    filter_mean = m,
    filter_var = pmax(C, 1e-12),
    smooth_mean = ms,
    smooth_var = pmax(Cs, 1e-12)
  )
}

log_joint_sigma_gamma <- function(sigma,
                                  gamma,
                                  y,
                                  eta,
                                  Ev,
                                  Es,
                                  p0,
                                  priors) {
  if (!is.finite(sigma) || sigma <= 0 || !is.finite(gamma)) {
    return(-Inf)
  }

  map <- tryCatch(exal_map(p0, gamma), error = function(e) NULL)
  if (is.null(map)) {
    return(-Inf)
  }

  v <- pmax(Ev, 1e-10)
  s <- pmax(Es, 0)

  resid <- y - eta - map$A * v - map$C * sigma * abs(gamma) * s
  ll <- -0.5 * sum(log(sigma * map$B * v) + resid^2 / (sigma * map$B * v))

  lp_sigma <-
    (priors$a_sigma + 1) * log(priors$b_sigma) -
    lgamma(priors$a_sigma) -
    (priors$a_sigma + 1) * log(sigma) -
    priors$b_sigma / sigma

  z <- (gamma - priors$m_gamma) / priors$s_gamma
  lp_gamma <- dt(z, df = priors$nu_gamma, log = TRUE) - log(priors$s_gamma)

  ll + lp_sigma + lp_gamma
}

compute_key_terms <- function(y, eta, Ev, Es, sigma, gamma, p0) {
  map <- exal_map(p0, gamma)
  R <- sigma * map$B * pmax(Ev, 1e-10)
  resid <- y - eta - map$A * Ev - map$C * sigma * abs(gamma) * Es

  list(
    map = map,
    R = R,
    resid = resid,
    finite = all(is.finite(c(map$A, map$B, map$C, R, resid))),
    positive_R = all(R > 0)
  )
}

run_model_a_cavi <- function(y,
                             p0 = 0.4,
                             n_iter = 8,
                             seed = 20260208,
                             W = 0.05,
                             m0 = 0,
                             C0 = 5,
                             priors = list(
                               a_sigma = 2,
                               b_sigma = 2,
                               m_gamma = 0,
                               s_gamma = 1,
                               nu_gamma = 6
                             )) {
  set.seed(seed)
  y <- as.numeric(y)
  Tn <- length(y)

  bounds <- exal_gamma_bounds(p0)
  gamma <- 0
  sigma <- 1

  Ev <- rep(1, Tn)
  E1v <- rep(1, Tn)
  Es <- rep(sqrt(2 / pi), Tn)

  trace <- vector("list", n_iter)

  for (iter in seq_len(n_iter)) {
    map <- exal_map(p0, gamma)

    y_tilde <- y - map$C * sigma * abs(gamma) * Es - map$A * Ev
    R <- pmax(sigma * map$B * Ev, 1e-8)

    kfs <- kalman_smoother_local_level(y_tilde, R, W = W, m0 = m0, C0 = C0)
    eta <- kfs$smooth_mean

    r <- y - eta - map$C * sigma * abs(gamma) * Es
    chi <- pmax(r^2 / (sigma * map$B), 1e-10)
    psi <- pmax((map$A^2) / (sigma * map$B) + 2 / sigma, 1e-10)

    Ev_new <- gig_moment(lambda = 0.5, chi = chi, psi = psi, r = 1)
    E1v_new <- gig_moment(lambda = 0.5, chi = chi, psi = psi, r = -1)

    Ev_new[!is.finite(Ev_new)] <- Ev[!is.finite(Ev_new)]
    E1v_new[!is.finite(E1v_new)] <- E1v[!is.finite(E1v_new)]
    Ev <- pmax(Ev_new, 1e-8)
    E1v <- pmax(E1v_new, 1e-8)

    y_circ <- y - eta - map$A * Ev
    Vs <- 1 / (1 + (map$C^2) * sigma * gamma^2 / (map$B * Ev))
    ms <- Vs * (map$C * abs(gamma) / (map$B * Ev)) * y_circ
    tm <- trunc_norm_pos_moments(ms, Vs)
    Es <- pmax(tm$mean, 1e-8)

    g_obj <- function(g) {
      -log_joint_sigma_gamma(
        sigma = sigma,
        gamma = g,
        y = y,
        eta = eta,
        Ev = Ev,
        Es = Es,
        p0 = p0,
        priors = priors
      )
    }

    g_opt <- optimize(g_obj, interval = c(bounds["L"] + 1e-5, bounds["U"] - 1e-5))
    gamma <- g_opt$minimum

    s_obj <- function(log_sigma) {
      -log_joint_sigma_gamma(
        sigma = exp(log_sigma),
        gamma = gamma,
        y = y,
        eta = eta,
        Ev = Ev,
        Es = Es,
        p0 = p0,
        priors = priors
      )
    }

    s_opt <- optimize(s_obj, interval = log(c(1e-4, 1e3)))
    sigma <- exp(s_opt$minimum)

    terms <- compute_key_terms(y, eta, Ev, Es, sigma, gamma, p0)
    trace[[iter]] <- list(
      iter = iter,
      sigma = sigma,
      gamma = gamma,
      min_R = min(terms$R),
      finite = terms$finite
    )
  }

  list(
    y = y,
    theta_mean = eta,
    theta_var = kfs$smooth_var,
    sigma = sigma,
    gamma = gamma,
    Ev = Ev,
    E1v = E1v,
    Es = Es,
    trace = trace,
    bounds = bounds
  )
}

simulate_univ_model_a <- function(Tn = 30,
                                  p0 = 0.4,
                                  sigma = 1,
                                  gamma = 0.2,
                                  W = 0.05,
                                  theta0 = 0,
                                  seed = 123) {
  stopifnot(Tn >= 2)
  set.seed(seed)
  map <- exal_map(p0, gamma)

  theta <- numeric(Tn)
  y <- numeric(Tn)

  theta_prev <- theta0
  for (t in seq_len(Tn)) {
    theta[t] <- theta_prev + rnorm(1, sd = sqrt(W))
    v <- rexp(1, rate = 1 / sigma)
    s <- abs(rnorm(1))
    y[t] <- theta[t] +
      map$C * sigma * abs(gamma) * s +
      map$A * v +
      rnorm(1, sd = sqrt(sigma * map$B * v))
    theta_prev <- theta[t]
  }

  list(y = y, theta = theta, p0 = p0, sigma = sigma, gamma = gamma)
}

check_internal_dimensions <- function(y, eta, Ev, Es) {
  n <- length(y)
  all(length(eta) == n, length(Ev) == n, length(Es) == n)
}

static_dlm_closed_form_mean <- function(y, R, m0 = 0, C0 = 10) {
  precision <- 1 / C0 + sum(1 / R)
  mean <- (m0 / C0 + sum(y / R)) / precision
  mean
}

static_equivalence_check <- function(y, R, m0 = 0, C0 = 10, tol = 1e-8) {
  kfs <- kalman_smoother_local_level(y = y, R = R, W = 0, m0 = m0, C0 = C0)
  closed <- static_dlm_closed_form_mean(y, R, m0 = m0, C0 = C0)
  err <- abs(kfs$smooth_mean[length(y)] - closed)
  list(pass = is.finite(err) && err < tol, error = err, smoother = kfs$smooth_mean[length(y)], closed = closed)
}
