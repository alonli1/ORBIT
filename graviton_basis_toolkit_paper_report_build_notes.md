# Graviton Basis Toolkit Paper Report Build Notes

This workspace now contains a paper-style LaTeX source:

- `graviton_basis_toolkit_paper_report.tex`

and the figure assets it references:

- `paper_assets/basis_pipeline.pdf`
- `paper_assets/quotient_space.pdf`
- `paper_assets/reducer_pipeline.pdf`
- `paper_assets/validation_pipeline.pdf`
- `paper_assets/worked_example_pipeline.pdf`

It also relies on the computed data already present in:

- `graviton_basis_toolkit_comprehensive_report_data.wl`
- `graviton_basis_toolkit_validation_output.wl`

## Current environment status

MiKTeX is now installed on this machine and the report has been compiled successfully to:

- `graviton_basis_toolkit_paper_report.pdf`

## Compile command used here

From this directory, the report was compiled by running `pdflatex` twice:

```powershell
pdflatex graviton_basis_toolkit_paper_report.tex
pdflatex graviton_basis_toolkit_paper_report.tex
```

The second `pdflatex` pass is needed for the table of contents and references.

## Note on `latexmk`

MiKTeX's `latexmk` is installed, but on this machine it requires a local `perl` installation.
So the reliable path at the moment is direct `pdflatex` runs rather than `latexmk`.
