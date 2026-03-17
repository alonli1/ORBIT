# ORBIT

ORBIT is a Wolfram Language toolkit for constructing and reducing local flat-space graviton operator bases sector by sector.

The current implementation works with the symmetric rank-2 field `h_{\mu\nu}` in four dimensions and performs two explicit quotient operations:

1. reduction modulo integration by parts (IBP),
2. reduction modulo the image of local field redefinitions acting through the quadratic Fierz-Pauli action.

It also includes:

- direct reduction of explicit xAct/Wolfram Lagrangians,
- Matchete-to-xAct translation utilities,
- fixed Einstein-Hilbert comparison workflows,
- validation and report-generation scripts,
- paper-style documentation and saved run artifacts.

## Repository layout

The repository is now organized by role:

- `graviton_basis_toolkit.wl`: main ORBIT basis/reduction package
- `orbit_fixed_eh_comparison.wl`: Matchete-to-EH comparison package
- `MatcheteXActTranslator.m`: translator used for `.mx` -> xAct conversion
- `docs/`: papers, notebooks, guides, and presentation material
- `artifacts/`: saved results, reports, logs, and intermediate outputs from concrete runs
- `cache/`: tracked Mathematica/xAct cache data used to make reruns reproducible
- `scripts/debug/`: scratch analysis and debugging scripts
- repository root: primary package entry points and main build/run scripts

Subdirectories of note:

- `docs/reference/`: external/background reference material
- `docs/graviton_basis/`: ORBIT basis-toolkit manuals, reports, and generated paper assets
- `docs/presentations/`: slide decks
- `artifacts/orbit_fixed_eh/`: EH-matching outputs and reports
- `artifacts/left_only_uv_2_eft_6/`: translated/reduced Matchete input artifacts
- `artifacts/debug/`: exported debug expressions and one-off investigation outputs

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

- `graviton_basis_toolkit_validation.wls`
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

## Fixed-EH comparison workflow

The ORBIT_BUILD branch adds a Matchete/EH comparison pipeline built around:

- `orbit_fixed_eh_comparison.wl`
- `run_orbit_fixed_eh_comparison*.wls`
- `artifacts/orbit_fixed_eh/`

The current finalized stopping point is the `d <= 5` comparison report:

- `artifacts/orbit_fixed_eh/orbit_fixed_eh_comparison_d5_final_result.wl`
- `artifacts/orbit_fixed_eh/orbit_fixed_eh_comparison_d5_final_report.pdf`

## Notes on the current git snapshot

The repository intentionally tracks generated documentation, saved run outputs, and cache files in addition to the main source. That keeps the current reports and comparison results reproducible from the checked-in snapshot.
