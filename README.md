# univ-exDQLM---Ensemble

Canonical univariate-only exDQLM repository.

## Scope

This repository contains only **Model A** (univariate exAL likelihood with DLM dynamics).
It intentionally excludes:

- ensemble members / forecast synthesis,
- retrospective Model B pipelines,
- multivariate response extensions,
- Model C and any retrospective framework.

## Structure

- `main.tex`: canonical univariate manuscript (Model A only)
- `docs/DERIVATION_AUDIT.md`: derivation and computability audit
- `scripts/lib/model_a_univ.R`: univariate Model A reference implementation
- `scripts/run_univ_example.R`: deterministic tiny end-to-end run
- `scripts/validate/run_univ_checks.R`: validation checks
- `tests/testthat/`: automated tests
- `scripts/build_latex.sh`: deterministic LaTeX build wrapper

## Reproducible commands

```bash
make test
make validate
make latex
bash scripts/latex_gate.sh
```

## Overleaf integration

- Overleaf should pull from the `main` branch of this repository.
- The manuscript entrypoint is `main.tex`.
- Build locally with `make latex` (or `scripts/build_latex.sh main.tex`) and use the log at `logs/latex/main.log` for diagnostics.

## Notes

- Build logs are written to `logs/latex/`.
- Validation outputs from the tiny run are written to `tmp/`.
