# ORBIT Fixed-EH Original-Lagrangian Pipeline Validation Walkthrough

## Goal

Re-run the fixed-EH `d <= 6` claim starting from the original EFT input rather than from stored comparison artifacts.

The validator lives in:

- `tests/validate_orbit_fixed_eh_from_original_lagrangian.wls`

The stage-by-stage notebook companion lives in:

- `tests/artifacts/orbit_fixed_eh_from_original_lagrangian_stage_by_stage.nb`

The lean notebook companion lives in:

- `tests/artifacts/orbit_fixed_eh_from_original_lagrangian_minimal.nb`

The theory-versus-reduced-EFT comparison notebook lives in:

- `tests/artifacts/orbit_fixed_eh_theory_vs_reduced_eft_minimal.nb`

The corrected theory-versus-reduced-EFT comparison notebook lives in:

- `tests/artifacts/orbit_fixed_eh_theory_vs_reduced_eft_minimal_fixed.nb`

The successive-field-redefinition notebook lives in:

- `tests/artifacts/orbit_fixed_eh_successive_field_redefinitions.nb`

Both notebooks are intended for GUI use under Mathematica `13.3` and mirror the same validated pipeline. The stage-by-stage notebook is more explanatory, while the lean notebook keeps only the essential checkpoints.
The corrected theory-versus-reduced-EFT notebook now distinguishes two different steps that were easy to conflate:

- the supported interaction-sector quotient, which is what removes the supported-sector differences like `{4,2}`
- the explicit quadratic higher-derivative field redefinition, which explains the remaining `{2,4}` residual

The successive-field-redefinition notebook goes one step further and shows the explicit original-lagrangian witness-branch `{4,2}` interaction-sector field redefinition, then subtracts the `{4,2}` and `{2,4}` field-redefinition images successively from the IBP-only EFT to show which differences disappear at each step.

## Why This Exists

The earlier proof artifacts already showed that:

- the supported sectors match after the witness substitution
- the remaining `{2,4}` discrepancy is a pure higher-derivative field redefinition

But those proofs were built from comparison artifacts and sector-local reconstructions.

This validator answers the stronger practical question:

- if we start again from the original `.mx` Lagrangian, do we recover the same physics statement?

## What The Validator Actually Does

### 1. Rebuild the EFT from the original source

It loads:

- `examples/left_only_uv_2_eft_6/LEFT_only_uv_2_eft_6.mx`

Then it:

- translates to xAct
- keeps the finite part
- truncates to `d <= 6`
- applies the witness solution

### 2. Rebuild the GR reference from scratch

It builds the fixed Einstein-Hilbert reference through `d <= 6` with symbolic `KappaRefFinal` and `LambdaRefFinal`, then applies the same witness substitution.

This mirrors the actual comparison pipeline more closely than plugging in `4 Sqrt[3]/M` at construction time.

### 3. Compare the supported sectors at the reduced level

This is the key physical comparison.

The supported reduced sectors are:

- `{2,2}`
- `{3,2}`
- `{4,2}`

The validator confirms they all vanish after the witness substitution.

### 4. Isolate the remaining quadratic discrepancy

At the reduced level, the only surviving discrepancy is:

- `{2,4}`

Its projected coordinates are recorded directly in the output artifact.

### 5. Compare that discrepancy to the explicit field-redefinition image

The validator computes the projected Fierz-Pauli image of

```text
\delta h_{\mu\nu}
= -\frac{3}{20 M^2} \Box h_{\mu\nu}
  -\frac{3}{10 M^2} \eta_{\mu\nu} \partial_\alpha \partial_\beta h^{\alpha\beta}
  +\frac{3}{10 M^2} \eta_{\mu\nu} \Box h^\alpha{}_\alpha
```

and verifies that its `{2,4}` coordinates match the original-Lagrangian discrepancy exactly.

## Important Correction To The Earlier Intuition

The validator also computes the first-order shift of the full unreduced ORBIT reference representative itself.

That stronger test does **not** give the same result:

- the raw full-reference shift has zero projected `{2,4}` coordinates
- it also has an extra `{1,4}` contribution
- that `{1,4}` contribution reduces to zero

So the correct interpretation is:

- ORBIT proves the reduced/IBP statement
- it does not prove the stronger raw-expression statement by direct substitution into the full unreduced reference representative

This explains why the original sector-local proof was formulated in terms of the projected Fierz-Pauli image rather than the raw full-reference shift.

## What To Inspect

Open:

- `InputPipeline["CanonicalNormalization"]`
- `BeforeShift["SupportedReducedSectorSummary"]`
- `BeforeShift["QuadraticDifferenceProjectedCoordinates"]`
- `ReferencePipeline["FPShiftQuadraticProjectedCoordinates"]`
- `ReferencePipeline["FullShiftQuadraticProjectedCoordinates"]`
- `ReferencePipeline["FullShiftLinearFourDerivativeReducedZeroQ"]`

Expected values:

- all supported reduced sectors are zero
- the only reduced discrepancy is `{2,4}`
- the `{2,4}` discrepancy matches the projected Fierz-Pauli shift coordinates
- the raw full-reference shift does not reproduce those coordinates directly

## Bottom Line

Starting from the original Lagrangian confirms the fixed-EH claim in the correct ORBIT sense:

- supported sectors match GR after the witness substitution
- the remaining quadratic discrepancy is exactly the projected image of the validated higher-derivative field redefinition

The step-0 audit strengthens confidence in the pipeline and also sharpens the wording of what the final claim really is.
