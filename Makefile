.PHONY: test validate latex clean

test:
	Rscript tests/testthat.R

validate:
	Rscript scripts/validate/run_univ_checks.R

latex:
	bash scripts/build_latex.sh main.tex

clean:
	rm -f *.aux *.out *.toc *.bbl *.blg *.fls *.fdb_latexmk *.synctex.gz *.pdf
	rm -f logs/latex/*.log
	rm -f tmp/*
	touch logs/latex/.gitkeep tmp/.gitkeep
