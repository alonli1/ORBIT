# ORBIT Fixed-EH Original-Lagrangian Pipeline Validation Report

## Executive Summary

This validation starts from the original Matchete `.mx` input and reruns the fixed-EH claim from step 0 under **Mathematica 13.3**.

Primary validator:

- `tests/validate_orbit_fixed_eh_from_original_lagrangian.wls`

Primary outputs:

- `artifacts/orbit_fixed_eh/orbit_fixed_eh_from_original_lagrangian_validation_output.wl`
- `tests/artifacts/run_logs/validate_orbit_fixed_eh_from_original_lagrangian_13_3.stdout.log`

Result:

- pass

What it proves:

- after applying the witness solution to the original EFT input, all supported reduced sectors match the fixed Einstein-Hilbert reference
- the only remaining reduced discrepancy is the quadratic four-derivative sector `{2,4}`
- that `{2,4}` discrepancy matches exactly the projected Fierz-Pauli image of the validated quadratic field redefinition

## What Was Checked

The validator performs the following pipeline:

1. Load the original `LEFT_only_uv_2_eft_6.mx` input.
2. Translate it to xAct syntax.
3. Normalize to the finite part and truncate to `d <= 6`.
4. Apply the witness substitutions
   - `Log[\[Mu]bar2/M^2] -> -3/2`
   - `LambdaRefFinal -> 0`
   - `KappaRefFinal -> 4 Sqrt[3] / M`
5. Reduce the original EFT from scratch and canonically normalize its quadratic sector.
6. Build the fixed-EH reference from scratch and apply the same witness substitution.
7. Compare the supported sectors at the reduced level.
8. Compare the remaining `{2,4}` discrepancy to the projected Fierz-Pauli image of the explicit quadratic field redefinition.

## Final Result

The final run reported:

- supported reduced sectors matched exactly
- the only remaining reduced discrepancy was `{2,4}`
- the `{2,4}` discrepancy coordinates were

```text
{9/(10*M^2), -9/(20*M^2), -3/(5*M^2), 3/(10*M^2), -3/(20*M^2)}
```

- the projected Fierz-Pauli shift coordinates were exactly the same

So the original-Lagrangian pipeline now independently confirms the core fixed-EH claim in the same reduced/IBP sense used by ORBIT itself.

## Important Nuance Found By The Audit

This step-0 validator also found an important correction to the earlier wording.

The raw full-reference first-order shift of the unreduced ORBIT reference expression does **not** reproduce the `{2,4}` discrepancy directly.

Fresh result:

- the raw full-reference shift has projected `{2,4}` coordinates `{0, 0, 0, 0, 0}`
- it also produces an extra `{1,4}` sector
- that extra `{1,4}` sector reduces to zero

Interpretation:

- the correct end-to-end statement is the reduced/IBP one
- the naive literal statement "substitute `delta h` into the full raw ORBIT reference and get the EFT discrepancy directly" is too strong and is not what the pipeline actually validates

This is a useful correction, not a failure of ORBIT.

## Files Added Or Updated

- `tests/validate_orbit_fixed_eh_from_original_lagrangian.wls`
- `artifacts/orbit_fixed_eh/orbit_fixed_eh_from_original_lagrangian_validation_output.wl`
- `tests/artifacts/orbit_fixed_eh_from_original_lagrangian_validation_report.md`
- `tests/artifacts/orbit_fixed_eh_from_original_lagrangian_validation_walkthrough.md`
- `tests/artifacts/orbit_solution_case_end_to_end_derivation.md`

## Recommended Follow-Up

- Add this validator as a documented deep-check alongside the existing solution-case validator.
- Keep the stronger raw-full-reference-shift mismatch documented, because it clarifies exactly what ORBIT proves and prevents overclaiming the result.
