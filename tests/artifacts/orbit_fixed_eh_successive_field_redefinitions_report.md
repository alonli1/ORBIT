# ORBIT Fixed-EH Successive Field Redefinitions Report

## Goal

Show, for the original-lagrangian `d <= 6` witness branch on Mathematica `13.3`:

- the explicit `{4,2}` interaction-sector field redefinition that removes the quartic two-derivative IBP-level difference
- the explicit `{2,4}` quadratic higher-derivative field redefinition
- what happens when those two field-redefinition images are subtracted successively from the IBP-only EFT

## Artifacts

- validator: `tests/validate_orbit_fixed_eh_successive_field_redefinitions.wls`
- output: `artifacts/orbit_fixed_eh/orbit_fixed_eh_successive_field_redefinitions_output.wl`
- run log: `tests/artifacts/run_logs/validate_orbit_fixed_eh_successive_field_redefinitions_13_3.stdout.log`
- notebook: `tests/artifacts/orbit_fixed_eh_successive_field_redefinitions.nb`

## Result

Before any additional field redefinition, the IBP-only EFT differs from the theory in exactly the displayed sectors:

- `{2,4}` nonzero
- `{4,2}` nonzero

The extracted `{4,2}` interaction-sector field redefinition is nonzero. Its coefficient vector in the original-lagrangian witness branch is:

```wl
{48/M^2, -24/M^2, -12/M^2, 6/M^2, 0, 0, 0}
```

against the seven cached independent `{3,0}` rank-2 generators of the `{4,2}` Fierz-Pauli image.

After subtracting the corresponding `{4,2}` projected image from the IBP-only EFT:

- `{4,2}` disappears
- `{2,4}` remains

After then subtracting the explicit `{2,4}` projected image:

- `{2,2} -> 0`
- `{2,4} -> 0`
- `{3,2} -> 0`
- `{4,2} -> 0`

So, at the displayed `d <= 6` IBP-projected level, the successive `{4,2}` then `{2,4}` field-redefinition images remove the remaining differences completely.

## Important Interpretation

The `{4,2}` step here is the explicit original-lagrangian witness-branch field redefinition extracted from the interaction-sector quotient data. It is not the same thing as the standalone quadratic `{2,4}` higher-derivative shift.

The final check is therefore:

1. remove the quartic two-derivative interaction-sector image
2. remove the quadratic four-derivative image
3. compare again to the IBP-projected theory representative

That staged check now exists both as a script artifact and as a runnable notebook.
