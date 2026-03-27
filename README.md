# ORBIT

ORBIT is a Wolfram Language toolkit for constructing and reducing local flat-space graviton operator bases sector by sector, together with a comparison workflow for matching explicit EFT outputs to Einstein-Hilbert reference data.

The current implementation works with the symmetric rank-2 field `h_{\mu\nu}` in four dimensions and performs two explicit quotient operations:

1. reduction modulo integration by parts (IBP),
2. reduction modulo the image of local field redefinitions acting through the quadratic Fierz-Pauli action.

It also includes:

- direct reduction of explicit xAct/Wolfram Lagrangians,
- Matchete-to-xAct translation utilities,
- fixed Einstein-Hilbert comparison workflows,
- validation and report-generation scripts.

## Repository layout

The paper-facing repository is organized into four main roles:

- package source at the repository root:
  - `graviton_basis_toolkit.wl`
  - `orbit_fixed_eh_comparison.wl`
  - `MatcheteXActTranslator.m`
- `examples/`: concrete reproducibility entry points and example inputs
- `tests/`: validation scripts for the package workflows
- `tools/`: paper-build and research-only helper scripts that are not part of the package API
- `docs/`: package documentation and paper-facing reference material
- `artifacts/`: saved example outputs and final report products worth keeping with the paper

Key example and validation entry points:

- `examples/left_only_uv_2_eft_6/`
- `examples/orbit_fixed_eh/`
- `tests/graviton_basis_toolkit_validation.wls`
- `tests/validate_orbit_fixed_eh_comparison.wls`

Additional non-package helpers now live under:

- `tools/paper/`: report/documentation builders
- `tools/research/orbit_fixed_eh/`: legacy exploratory comparison and completion drivers

The repository intentionally ignores caches, sync state, temp folders, and most generated log/checkpoint files so the checked-in snapshot stays focused on package code plus final reproducible examples.

## Current scope

What the toolkit currently does:

- generates raw scalar graviton bases in sectors labeled by `{nh, Nd}`,
- computes the IBP quotient sector by sector,
- computes the linearized Fierz-Pauli field-redefinition image for interaction sectors,
- reduces explicit input Lagrangians modulo the implemented redundancies,
- exports summaries and cached sector data.

What it does not currently do automatically:

- impose linearized diffeomorphism invariance,
- quotient by full nonlinear field redefinitions of an interacting graviton theory,
- remove evanescent operators or other fixed-dimension identities in a dedicated way,
- work in a generic spacetime dimension without modifying the package setup.

The present code is therefore best viewed as a 4D flat-space graviton basis toolkit modulo IBP and linearized equations-of-motion redefinitions.

## Requirements

- Mathematica / Wolfram Language
- `xAct\`xTras\``

Optional, for rebuilding the paper reports:

- MiKTeX or another LaTeX distribution with `pdflatex`

## Quick start

Load the package:

```wl
Get["graviton_basis_toolkit.wl"];
```

Compute a basis summary up to some engineering dimension:

```wl
res = RunBasisComputation[
  "MaxDimension" -> 5,
  "CacheDirectory" -> FileNameJoin[{Directory[], "basis_cache"}],
  "UseCache" -> True
];

PrintSectorSummary[res];
```

Inspect a single sector:

```wl
IBPBasisOfSector[res, 3, 2]
PhysicalBasisOfSector[res, 3, 2]
RedefinitionRulesOfSector[res, 3, 2]
```

Reduce a single-sector Lagrangian:

```wl
sec = ReduceSectorLagrangian[
  lag32,
  3,
  2,
  "CacheDirectory" -> FileNameJoin[{Directory[], "basis_cache"}]
];

sec["ReducedExpression"]
sec["PhysicalCoordinates"]
```

Reduce a general Lagrangian automatically by sector:

```wl
red = ReduceLagrangian[
  lag,
  "MaxDimension" -> 7,
  "CacheDirectory" -> FileNameJoin[{Directory[], "basis_cache"}],
  "UseCache" -> True
];

red["ReducedExpression"]
```

## Implemented mathematics

The reduction pipeline is:

1. build a raw basis in each sector `{nh, Nd}`,
2. find IBP-trivial combinations using the Euler-operator criterion,
3. form an IBP basis by deleting pivot columns,
4. for `nh >= 3`, compute the image of rank-2 local redefinitions acting on the quadratic Fierz-Pauli action,
5. quotient the IBP basis by that image,
6. project explicit Lagrangians onto the resulting basis.

The current field-redefinition quotient is universal across sectors but linearized in the sense that it uses only the quadratic Fierz-Pauli action. It removes operators proportional to the linearized equations of motion, not the full nonlinear redefinition orbit of an interacting action.

## Validation

The repository includes explicit validation runs showing that disguised expressions of the form

`E_FP^{mu nu} Delta h_{mu nu}`

reduce to zero after IBP and field-redefinition removal.

Stored validation artifacts:

- `tests/graviton_basis_toolkit_validation.wls`
- `docs/graviton_basis/graviton_basis_toolkit_validation_output.wl`
- `docs/graviton_basis/graviton_basis_toolkit_validation_report.pdf`

The current report also contains a worked example in which the input Lagrangian has:

- a nonzero physical component,
- an IBP-trivial component,
- a field-redefinition-image component,

and the reducer returns only the physical representative.

## Building the paper report

The LaTeX source is:

- `docs/graviton_basis/graviton_basis_toolkit_paper_report.tex`

Compile with:

```powershell
pdflatex -interaction=nonstopmode -halt-on-error docs/graviton_basis/graviton_basis_toolkit_paper_report.tex
pdflatex -interaction=nonstopmode -halt-on-error docs/graviton_basis/graviton_basis_toolkit_paper_report.tex
```

Figure assets are generated by:

- `build_graviton_basis_toolkit_paper_assets.wls`

## Example workflows

The main example workflows are:

- LEFT example reduction:
  - `examples/left_only_uv_2_eft_6/run_left_only_uv_2_eft_6_reduction.wls`
  - `examples/left_only_uv_2_eft_6/reduce_left_only_uv_2_eft_6_by_sector.wls`
- fixed Einstein-Hilbert comparison:
  - `orbit_fixed_eh_comparison.wl`
  - `examples/orbit_fixed_eh/run_orbit_fixed_eh_comparison_final.wls`
  - `examples/orbit_fixed_eh/run_orbit_fixed_eh_comparison_d5_final.wls`
  - `artifacts/orbit_fixed_eh/`

The current paper-facing comparison outputs live under:

- `artifacts/left_only_uv_2_eft_6/`
- `artifacts/orbit_fixed_eh/`
