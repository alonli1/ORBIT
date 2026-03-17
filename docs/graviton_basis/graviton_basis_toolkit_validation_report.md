# Graviton Basis Toolkit Validation Report

This repository now includes a reproducible script-based validation run:

- Script: `graviton_basis_toolkit_validation.wls`
- Output file produced by the script: `graviton_basis_toolkit_validation_output.wl`
- Cache used by the script: `graviton_basis_validation_cache/`

There is not currently a front-end `.nb` notebook for the reducer validation. The persistent artifact is a Wolfram script plus a machine-readable output file. That is intentional: it can be rerun from the kernel without depending on the notebook front end.

## What the validation checks

The script tests the new `ReduceLagrangian` pipeline on Lagrangians that are known to be redundant because they are in the image of a field redefinition:

1. Build a generic rank-2 field redefinition `delta h_{mu nu}` from the computed `RedefDeltaBasis`.
2. Form its Fierz-Pauli image with `ShiftFromRedefExpr`, equivalently `EOM^{mu nu} delta h_{mu nu}` up to a total derivative.
3. Expand the resulting scalar Lagrangian so that it does not look obviously like an `EOM . delta h` term.
4. Run `ReduceLagrangian` on the expanded scalar.
5. Check that the reduced expression and all physical coordinates vanish.

## Most recent run

Validated on March 10, 2026 with two sectors:

### Sector `{3, 2}`

- `DeltaBasisLength = 4`
- `IBPCount = 14`
- `RedefRank = 4`
- `PhysicalCount = 10`
- Expanded redundant Lagrangian term count: `18`
- Result: reduced expression is exactly `0`

### Sector `{3, 4}`

- `DeltaBasisLength = 33`
- `IBPCount = 64`
- `RedefRank = 33`
- `PhysicalCount = 31`
- Expanded redundant Lagrangian term count: `240`
- Result: reduced expression is exactly `0`

The `{3, 4}` case is the stronger check. The input Lagrangian is a 240-term expanded scalar built from a generic integer combination of all 33 independent rank-2 redefinition basis elements in that sector. The reducer still returns zero, which is the expected result.

## How to rerun

From PowerShell in this directory:

```powershell
& 'C:\Program Files\Wolfram Research\Wolfram\14.2\WolframKernel.exe' -script graviton_basis_toolkit_validation.wls
```

After the run, inspect:

- `graviton_basis_toolkit_validation_output.wl`

The output file contains a Wolfram association with the exact coefficients and boolean pass/fail checks.
