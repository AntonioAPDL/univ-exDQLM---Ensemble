#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOC="${1:-main.tex}"
BASENAME="$(basename "$DOC" .tex)"
LOG_DIR="$ROOT/logs/latex"
LOG_FILE="$LOG_DIR/$BASENAME.log"

mkdir -p "$LOG_DIR"

if command -v latexmk >/dev/null 2>&1; then
  (
    cd "$ROOT"
    latexmk -pdf -interaction=nonstopmode -halt-on-error "$DOC"
  ) >"$LOG_FILE" 2>&1
else
  (
    cd "$ROOT"
    pdflatex -interaction=nonstopmode -halt-on-error "$DOC"
    pdflatex -interaction=nonstopmode -halt-on-error "$DOC"
  ) >"$LOG_FILE" 2>&1
fi

echo "LaTeX build completed: $DOC"
echo "Log: $LOG_FILE"
