# DERIVATION AUDIT: Univariate exDQLM (Model A only)

## Scope and audit objective

This audit validates the canonical univariate Model A derivations and implementation forms.
It explicitly excludes Model B/Model C, ensembles, retrospective products, and multivariate response extensions.

Alignment source (read-only): `../exDQLM---Ensemble/main.tex`.
Model A content here is a restriction of those sections to the univariate-only setting.

## Source alignment map (Model A subset)

- `exDQLM---Ensemble/main.tex` section `Model A (baseline exDQLM with transfer function)` -> `main.tex` section `Model A hierarchy`.
- `exDQLM---Ensemble/main.tex` section `exAL augmentation used for posterior derivations` -> `main.tex` section `exAL augmentation`.
- `exDQLM---Ensemble/main.tex` section `Full conditionals (up to proportionality)` -> `main.tex` section `Full conditionals (up to proportionality)`.
- `exDQLM---Ensemble/main.tex` algorithmic notes (Gibbs/VB blocks) -> implementation forms in this file and in `scripts/lib/model_a_univ.R`.

No Model B/C sections were carried into the active manuscript.

## Symbol and shape table

| Symbol | Meaning | Domain | Univariate shape | Notes |
|---|---|---|---|---|
| `t` | time index | `{1,...,T}` | scalar index | fit interval only |
| `y_t` | observed response | `R` | scalar | baseline observation |
| `p0` | target quantile | `(0,1)` | scalar | fixed |
| `q` | DLM state dimension | positive integer | scalar | model choice |
| `m` | transfer regressor dimension | positive integer | scalar | model choice |
| `F_t` | DLM design vector | `R^q` | `(q x 1)` | used in `F_t^T theta_t` |
| `theta_t` | latent DLM state | `R^q` | `(q x 1)` | dynamic |
| `G_t` | DLM transition matrix | `R^{q x q}` | `(q x q)` | dynamic matrix |
| `W_t^theta` | DLM innovation covariance | SPD | `(q x q)` | positive definite |
| `zeta_t` | transfer latent state | `R` | scalar | ARX latent term |
| `psi_t` | transfer coefficients | `R^m` | `(m x 1)` | random walk |
| `x_t` | transfer covariates | `R^m` | `(m x 1)` | known input |
| `lambda` | scalar AR coefficient | `R` | scalar | transfer dynamics |
| `w_t^zeta` | transfer innovation variance | `(0,inf)` | scalar | positive |
| `W_t^psi` | transfer RW covariance | SPD | `(m x m)` | positive definite |
| `alpha_t` | stacked state | `R^{q+1+m}` | `((q+1+m) x 1)` | `[theta_t, zeta_t, psi_t]` |
| `sigma` | exAL scale | `(0,inf)` | scalar | source-specific in full model; single source here |
| `gamma` | exAL skew parameter | `(L,U)` | scalar | bounded by feasibility |
| `g(gamma)` | feasibility transform | `(0,1]` | scalar | `2 Phi(-|gamma|) exp(gamma^2/2)` |
| `p` | transformed asymmetry | `(0,1)` | scalar | function of `p0, gamma` |
| `A(p),B(p),C(p,gamma)` | augmentation constants | finite reals | scalars | from exAL map |
| `v_t` | latent scale variable | `(0,inf)` | scalar | one per observation |
| `s_t` | latent half-normal variable | `(0,inf)` | scalar | one per observation |
| `eta_t` | linear predictor | `R` | scalar | `Ftilde_t^T alpha_t` |
| `R_t` | pseudo-observation variance | `(0,inf)` | scalar | `sigma B v_t` |
| `a_sigma,b_sigma` | inverse-gamma hyperparameters | `(0,inf)` | scalars | prior on `sigma` |
| `m_gamma,s_gamma,nu_gamma` | t prior hyperparameters | `R x (0,inf) x (0,inf)` | scalars | truncated to `(L,U)` |

## Derivation consistency checks

### 1) exAL map and feasibility

Definitions used:

- `g(gamma) = 2 Phi(-|gamma|) exp(gamma^2 / 2)`
- `p = I(gamma < 0) + (p0 - I(gamma < 0)) / g(gamma)`
- `A = (1 - 2p)/(p(1-p))`, `B = 2/(p(1-p))`, `C = (I(gamma > 0) - p)^(-1)`

Check applied:

- `p` must stay in `(0,1)`.
- denominators `p(1-p)` and `I(gamma>0)-p` must be nonzero.

Status: enforced in code by bounds (`exal_gamma_bounds`) + explicit validation (`exal_map`).

### 2) Augmented observation equation

Used equation:

`y_t | eta_t, sigma, gamma, v_t, s_t ~ N(eta_t + C sigma |gamma| s_t + A v_t, sigma B v_t)`.

Dimensional check:

- mean terms all scalars,
- variance term scalar positive because `sigma>0`, `B>0`, `v_t>0`.

Status: passed; positivity floors used in implementation for numerical robustness.

### 3) Full conditional forms

- `q(v_t)` / Gibbs conditional uses `GIG(lambda=1/2, chi_t, psi)` with
  - `chi_t = r_t^2 / (sigma B)` where `r_t = y_t - eta_t - C sigma |gamma| s_t`
  - `psi = A^2/(sigma B) + 2/sigma`
- `q(s_t)` / Gibbs conditional is truncated normal with
  - `V_s,t = (1 + C^2 sigma gamma^2 / (B v_t))^(-1)`
  - `m_s,t = V_s,t * (C |gamma| / (B v_t)) * (y_t - eta_t - A v_t)`
- state path conditional is Gaussian under pseudo-observations
  - `y_t_tilde = y_t - C sigma |gamma| s_t - A v_t`
  - `y_t_tilde | alpha_t ~ N(Ftilde_t^T alpha_t, sigma B v_t)`

Status: algebra and scalar dimensions are consistent with the restricted Model A equations.

### 4) Sigma/Gamma block consistency

- `sigma` kernel is GIG-shaped conditional on other blocks.
- `gamma` is nonconjugate because `(A,B,C)` depend on `gamma` through `p(p0,gamma)`.

Status: implementation uses coordinate optimization (`gamma` on `(L,U)`, `log sigma` on `R`) against the same kernel form.

## Implementation-ready update blocks

### Block U1: exAL constants

Inputs:

- `p0` (scalar), `gamma` (scalar)

Operations:

- evaluate `g(gamma)`, then `p`, then `A,B,C`
- reject if `p` outside `(eps,1-eps)`

Stability:

- enforce feasibility interval for `gamma`
- guard small denominators with epsilon

Complexity:

- `O(1)` per evaluation

### Block U2: latent `v_t` moments (GIG)

Inputs:

- residual terms `r_t`, parameters `sigma, A, B`

Operations:

- compute `chi_t`, `psi`
- compute `E[v_t]` and `E[1/v_t]` from Bessel-K ratio

Stability:

- use scaled Bessel-K evaluations
- floor `chi_t`, `psi`, and returned moments

Complexity:

- `O(T)` scalar special-function evaluations

### Block U3: latent `s_t` moments (truncated normal)

Inputs:

- `y_t, eta_t, v_t, sigma, gamma, A, B, C`

Operations:

- compute `V_s,t`, `m_s,t`
- compute `E[s_t]` via truncated-normal mean formula (Mills ratio)

Stability:

- stable Mills-ratio branch for large truncation arguments
- floor variances

Complexity:

- `O(T)`

### Block U4: state update (FFBS/Kalman smoother)

Inputs:

- pseudo-observations `y_t_tilde`, variances `R_t`
- transition/design blocks for `alpha_t`

Operations:

- run Kalman filter + RTS smoother (or simulation smoother for Gibbs)

Stability:

- use solve/Cholesky in vector forms
- avoid explicit matrix inversion

Complexity:

- scalar local-level form used in code: `O(T)`
- general stacked-state form: `O(T d_state^3)`

### Block U5: `(sigma, gamma)` coordinate update

Inputs:

- current states and latent moments
- priors `(a_sigma,b_sigma,m_gamma,s_gamma,nu_gamma)`

Operations:

- optimize `gamma` in `(L,U)`
- optimize `log sigma` in bounded interval

Stability:

- optimize in transformed spaces to enforce constraints
- objective returns `-Inf` on invalid map constants

Complexity:

- `O(T * N_opt)` per coordinate block

## Validation coverage links

- Core implementation: `scripts/lib/model_a_univ.R`
- Tiny deterministic run: `scripts/run_univ_example.R`
- Validation runner: `scripts/validate/run_univ_checks.R`
- Automated tests: `tests/testthat/test-model-a.R`

## Audit conclusion

Model A derivations are internally consistent after univariate restriction, dimensionally valid, and mapped to computable update blocks.
The active repository intentionally removes Model B/C, ensemble, retrospective, and multivariate components from the canonical path.
