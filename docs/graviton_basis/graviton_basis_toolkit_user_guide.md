# Graviton Basis Toolkit User Guide

This is the short practical guide. If you want the implementation details, read `graviton_basis_toolkit_reference.md`.

## 1. Load the toolkit

```wl
Get["graviton_basis_toolkit.wl"];
```

## 2. Compute sector data

To build all sectors up to a maximum dimension:

```wl
res = RunBasisComputation[
  "MaxDimension" -> 5,
  "CacheDirectory" -> FileNameJoin[{Directory[], "basis_cache"}],
  "UseCache" -> True,
  "Verbose" -> True
];
```

Useful accessors:

```wl
RawBasisOfSector[res, 3, 2]
IBPBasisOfSector[res, 3, 2]
PhysicalBasisOfSector[res, 3, 2]
RedefinitionRulesOfSector[res, 3, 2]
```

## 3. Reduce one sector of a Lagrangian

If you already know the sector label:

```wl
red = ReduceSectorLagrangian[lag32, 3, 2,
  "CacheDirectory" -> FileNameJoin[{Directory[], "basis_cache"}],
  "UseCache" -> True
];

red["ReducedExpression"]
red["PhysicalCoordinates"]
```

Use this when the Lagrangian is known to lie entirely in one sector.

## 4. Reduce a general Lagrangian automatically

If the Lagrangian contains several sectors:

```wl
red = ReduceLagrangian[lag,
  "CacheDirectory" -> FileNameJoin[{Directory[], "basis_cache"}],
  "UseCache" -> True
];

red["ReducedExpression"]
Keys[red["SectorReductions"]]
```

The result is an association containing:

- `"ReducedExpression"`: the final representative modulo IBP and field redefinitions.
- `"SectorReductions"`: one reduction record per sector.
- `"UntouchedExpression"`: anything not identified as a standard graviton sector by the automatic splitter.

## 5. Interpreting the counts

For a sector `{nh, Nd}`:

- `RawCount`: size of the raw spanning set after tensor canonicalization.
- `IBPCount`: dimension after quotienting by total derivatives.
- `RedefRank`: dimension of the image of field redefinitions in the IBP basis.
- `PhysicalCount`: final count after removing that image.

Important convention:

- quadratic sectors (`nh < 3`) are not quotiented by field redefinitions,
- interaction sectors (`nh >= 3`) are.

## 6. Reproducible validation script

To rerun the stored reducer validation:

```powershell
wolframscript -file tests/graviton_basis_toolkit_validation.wls
```

Then inspect:

- `docs/graviton_basis/graviton_basis_toolkit_validation_output.wl`
- `graviton_basis_toolkit_validation_report.md`

## 7. Typical workflow

1. Run `RunBasisComputation` once with a cache directory.
2. Inspect the sector of interest with `IBPBasisOfSector` or `PhysicalBasisOfSector`.
3. Build a candidate Lagrangian in the same `h`, `eta`, `PD` conventions.
4. Call `ReduceSectorLagrangian` or `ReduceLagrangian`.
5. Read off the final representative and coordinates.

## 8. Common pitfalls

1. The reducer expects expressions built from the same xAct symbols defined by the toolkit.
2. The code removes IBP redundancies automatically, but it does not impose gauge invariance by itself.
3. A quadratic sector not reducing further under field redefinitions is intentional, not a bug.
4. If you change the basis-generation logic, clear or change the cache directory before trusting old cached results.
