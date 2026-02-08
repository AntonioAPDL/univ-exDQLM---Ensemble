# Derivation Parity Audit (2026-02-08)

## Scope
This audit compares derivation rigor/clarity/detail across:
- `/data/muscat_data/jaguir26/exDQLM---Ensemble`
- `/data/muscat_data/jaguir26/NDLM---Ensemble`
- `/data/muscat_data/jaguir26/univ-exDQLM---Ensemble`

Parity means same documentation quality bar (rigor, computability, explicitness), not identical formulas when models differ.

## Phase 0: Entrypoints, Build Commands, Baseline Builds

| Repo | Main derivation TeX entrypoint | Build command used | Baseline build | PDF output | Log path |
|---|---|---|---|---|---|
| `exDQLM---Ensemble` | `main.tex` | `pdflatex -interaction=nonstopmode -halt-on-error main.tex` (run twice; no canonical Makefile/script present) | PASS | `main.pdf` | `main.log` |
| `NDLM---Ensemble` | `docs/derivations/main.tex` | `make compile` | PASS | `docs/derivations/main.pdf` | `docs/derivations/main.log` |
| `univ-exDQLM---Ensemble` | `main.tex` | `make latex` | PASS | `main.pdf` | `logs/latex/main.log` |

## Phase 1: Section Maps (Current State)

### exDQLM---Ensemble (`main.tex`)
1. `\section{Notation and dimensions}`
2. `\section{Model A (baseline exDQLM with transfer function)}`
3. `\section{Model B (add J retrospective products via discrepancy states)}`
4. `\section{Model C (forecast period: ensemble forecasts; transfer omitted)}`
5. `\section{exAL augmentation used for posterior derivations}`
6. `\section{Augmented joint posterior (generic block)}`
7. `\section{Full conditionals (up to proportionality)}`
8. `\subsection{Full conditional of v_t (GIG)}`
9. `\subsection{Full conditional of s_t (truncated Normal)}`
10. `\subsection{Joint full conditional of the state path (Gaussian; FFBS)}`
11. `\subsection{Full conditional of sigma (GIG)}`
12. `\subsection{Full conditional of gamma (non-conjugate; target density)}`
13. `\subsection{Joint posterior kernel for (sigma,gamma) for one source}`
14. `\section{Inverse-Wishart / Wishart full conditionals (matrix blocks)}`
15. `\subsection{Evolution covariance W (inverse-Wishart conjugacy)}`
16. `\subsection{Observation covariance / precision (generic Gaussian block)}`
17. `\section{Source-wise application (baseline + forecasters)}`
18. `\section{Algorithms: Gibbs/MH and Mean-Field VB (CAVI)}`
19. `\subsection{Unified per-source indexing and pseudo-observations}`
20. `\subsection{Gibbs/MH sampler (one sweep)}`
21. `\subsection{Mean-field VB (CAVI): updates and required expectations}`
22. `\subsubsection*{CAVI step 1..5}`
23. `\subsection{Closed-form expectations needed in VB}`
24. `\subsubsection*{GIG moments / TN moments / Gaussian moments / derived moments}`
25. `\subsection{State update (trans-dimensional Gaussian block): FFBS for MCMC and RTS smoothing for VB}`
26. `\subsubsection*{Gaussian form / MCMC FFBS / VB smoother}`
27. `\subsection{Laplace--Delta approximation for q(sigma,gamma) and ELBO contributions}`
28. `\subsubsection*{target / transform / Laplace / Delta / ELBO terms}`
29. `\section{Full ELBO for the complete mean-field approximation}`
30. `\subsection{Unified indexing / ELBO decomposition / state block / IW blocks / entropy blocks / nonconjugate block}`

### NDLM---Ensemble (`docs/derivations/main.tex` + `docs/derivations/sections/*.tex`)
1. `\section{Notation and Model Specification}`
2. `\subsection{Indexing, Support, and Dimensions}`
3. `\subsection{Model A: Baseline Historical Gaussian NDLM}`
4. `\subsection{Model B: Historical Retrospective Products with Discrepancies}`
5. `\subsection{Model C: Forecast Ensemble Likelihood (Gaussian)}`
6. `\subsection{Observation List Representation (Computable Form)}`
7. `\subsection{Prior Block}`
8. `\section{Full Joint Density and Posterior Factorization}`
9. `\subsection{Model A Joint / Model B Joint / Model C Joint / Posterior Kernel}`
10. `\section{Conditional State Posterior: Kalman Filter and FFBS}`
11. `\subsection{Unified Linear-Gaussian Form}`
12. `\subsection{Sequential Kalman Assimilation at Fixed Time}`
13. `\subsection{FFBS Simulation Smoother}`
14. `\subsection{Computability Constraints}`
15. `\section{Full Conditionals for Static Parameters}`
16. `\subsection{Observation Variances: Inverse-Gamma}`
17. `\subsection{Evolution Covariances: Inverse-Wishart}`
18. `\subsection{Transfer Coefficient: Conjugate Gaussian Update}`
19. `\section{Blocked MCMC Algorithm}`
20. `\subsection{Diagnostics Required for Correctness}`
21. `\section{Mean-Field Variational Bayes (CAVI)}`
22. `\subsection{Factorization}`
23. `\subsection{State Factor}`
24. `\subsection{Variance Factors}`
25. `\subsection{Evolution Covariance Factors}`
26. `\subsection{Transfer Coefficient Factor}`
27. `\subsection{Expectations Required Each Iteration}`
28. `\section{ELBO Decomposition}`
29. `\subsection{Definition}`
30. `\subsection{Additive Blocks}`
31. `\subsection{Convergence Criterion}`
32. `\section{Computational Notes and Validation Checklist}`
33. `\subsection{Observation Interface / Numerical Stability Rules / Reduction Checks / Required Unit-Level Validations}`
34. `\section{Posterior Predictive Distributions}`
35. `\subsection{Conditional Predictive / One-Step Predictive / MCMC Predictive / VB Predictive}`
36. `\section{Sufficient-Statistic Assimilation for Replicated Observations}`
37. `\subsection{Replicate Aggregation / Kalman Update / Variance Update / Forecast Synthesis}`

### univ-exDQLM---Ensemble (`main.tex`)
1. `\section{Scope and notation}`
2. `\section{Model A hierarchy and stacked DLM form}`
3. `\section{exAL augmentation}`
4. `\section{Conditionally Gaussian pseudo-observation form}`
5. `\section{Complete augmented joint model (Model A)}`
6. `\section{Inference by MCMC}`
7. `\subsection{Full conditional blocks}`
8. `\subsection{Conditional update for latent v}`
9. `\subsection{Conditional update for latent s}`
10. `\subsection{Conditional update for alpha path by FFBS}`
11. `\subsection{Conditional update for sigma}`
12. `\subsection{Metropolis--Hastings update for gamma}`
13. `\subsection{Gibbs/MH algorithm in pseudocode}`
14. `\section{Mean-field variational Bayes and CAVI}`
15. `\subsection{Factorization and CAVI schedule}`
16. `\subsection{CAVI update for state factor q(alpha)}`
17. `\subsection{CAVI update for q(v_t)}`
18. `\subsection{CAVI update for q(s_t)}`
19. `\subsection{CAVI update for q(sigma,gamma)}`
20. `\subsection{Closed-form expectations used by CAVI}`
21. `\section{Laplace--Delta approximation for q(sigma,gamma)}`
22. `\subsection{Transformed coordinates / Target log-density / Gradient and Hessian / Gaussian approximation and delta moments}`
23. `\section{Evidence lower bound (ELBO)}`
24. `\subsection{Full decomposition / Computable block expressions / Monotonicity check}`
25. `\section{Planned validations (to implement later)}`
26. `\section{Audit statement}`

## Phase 2: Style Decisions Applied
1. `\phiN{·}` and `\PhiN{·}` are one-argument macros for standard normal pdf/cdf where used.
2. GIG parameterization is stated explicitly as
   `x^{\lambda-1}\exp\{-(\chi/x+\psi x)/2\}` in exAL documents.
3. Constrained-parameter blocks (MH/Laplace) use explicit transformed coordinates and Jacobians.
4. Key algorithms now cite exact equation labels for kernels and moments.

## Phase 3: Implemented Fixes + Build Verification

### exDQLM---Ensemble
- Branch: `fix/derivation-parity-2026-02-08`
- Commits:
  - `6bbf9d0` `docs: normalize normal pdf/cdf macros and scope wording`
  - `380abbf` `docs: add computable complete log-joint block for augmented exAL`
  - `64a3c38` `docs: add ELBO monotonicity note and explicit audit closure`
  - `2e4d2c4` `docs: add explicit planned-validation checklist for derivation blocks`
- Build checks after each commit: `pdflatex -interaction=nonstopmode -halt-on-error main.tex` (twice), then log scan on `main.log`.
- Status: PASS.

### NDLM---Ensemble
- Branch: `fix/derivation-parity-2026-02-08`
- Commits:
  - `934ba2f` `docs: add computable complete log-joint expressions for Models A-C`
  - `157b0ab` `docs: link NDLM MCMC sweep directly to conditional equations`
  - `6a41bbb` `docs: make NDLM CAVI derivations explicit and computable`
  - `e2c65b5` `docs: expand NDLM ELBO blocks and add explicit audit closure`
- Build checks after each commit: `make compile`, then log scan on `docs/derivations/main.log`.
- Status: PASS.

### univ-exDQLM---Ensemble
- Branch: `audit/derivation-parity-2026-02-08`
- Change in this audit cycle: parity audit document only (no TeX derivation edits).
- Baseline build retained: `make latex` PASS.

## Updated Parity Matrix (Post-Fix)
Legend: `P` = Present, `M` = Missing, `N/A` = Different-model not applicable.

| Item | exDQLM---Ensemble | NDLM---Ensemble | univ-exDQLM---Ensemble | Notes |
|---|---:|---:|---:|---|
| A) Scope + naming + exclusions | P | P | P | Explicit scope notes now present in all three derivation docs. |
| B) Full hierarchy + dimensions + priors | P | P | P | Present in all. |
| C) Augmentation + mapping/functions/domains | P | N/A | P | NDLM is Gaussian by design. |
| D1) Joint factorization | P | P | P | Present in all. |
| D2) Computable complete log-joint | P | P | P | Added explicit computable log-joint blocks in exDQLM and NDLM. |
| E1) Full conditionals / MH kernels named | P | P | P | Present in all. |
| E2) Explicit FFBS/Kalman recursions | P | P | P | Present in all. |
| E3) One-sweep MCMC pseudocode + practical notes | P | P | P | NDLM now equation-linked with explicit intermediates. |
| F1) VB factorization + generic CAVI rule | P | P | P | NDLM now states the generic CAVI rule explicitly. |
| F2) Coordinate updates derived from CAVI rule | P | P | P | NDLM factors now tied directly to the CAVI kernel. |
| F3) No circular q(v), q(s), etc. | P | P | P | No circular factor definitions detected. |
| F4) Required closed-form expectations listed | P | P | P | NDLM now includes explicit IG/IW/Gaussian moment formulas. |
| G1) Laplace/Laplace–Delta: transforms + target + Jacobian | P | N/A | P | NDLM does not use Laplace in the Gaussian setup. |
| G2) Laplace gradient/Hessian strategy + delta moments | P | N/A | P | exDQLM and univ docs provide transform/curvature + delta computation flow. |
| H1) ELBO full decomposition | P | P | P | Present in all. |
| H2) ELBO computable block expressions | P | P | P | NDLM expanded to include prior and entropy blocks explicitly. |
| H3) Monotonicity/convergence note | P | P | P | Explicit monotonicity/convergence language now visible in all. |
| I1) Planned validations checklist (doc-level) | P | P | P | exDQLM now has an explicit planned-validation checklist. |
| I2) Explicit audit statement | P | P | P | Added explicit audit closures in exDQLM and NDLM. |
| J1) Macro sanity for normal pdf/cdf notation | P | N/A | P | exDQLM normalized to one-argument `\phiN`/`\PhiN` macros. |
| J2) GIG parameterization stated once and reused | P | N/A | P | Consistent where GIG appears. |
| J3) Symbol consistency (no silent mismatches) | P | P | P | No unresolved notation conflicts found in the audited blocks. |

## Remaining Differences (Model-Driven, Not Gaps)
- NDLM remains Gaussian and therefore correctly omits exAL augmentation, GIG latent variables, and Laplace--Delta blocks.
- exDQLM and univ-exDQLM keep exAL-specific latent augmentation and nonconjugate `(sigma, gamma)` handling.

## Phase 5 Summary
- Phase 0 (entrypoints/build commands): **Complete**.
- Phase 1 (section maps + pre-edit parity matrix): **Complete**.
- Phase 2 (style decisions): **Applied**.
- Phase 3 (repo-by-repo derivation upgrades): **Applied with compile checks**.
- Phase 4 content policy (derive, do not hand-wave): **Enforced in edited blocks**.
- Phase 5 PR packaging: **Pending push/PR creation in this run context**.
