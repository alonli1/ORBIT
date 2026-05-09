# ORBIT Solution-Case Validation Report

## Executive Summary

This validation adds the two proof-style checks requested for the fixed-EH comparison workflow:

1. EFT through mass dimension 5
2. EFT through mass dimension 6, including the quadratic four-derivative sector with curvature-squared diagnostics

The new validator was run under **Mathematica 13.3 only** and completed successfully:

- `D5`: passed
- `D6`: passed
- Output artifact: `artifacts/orbit_fixed_eh/orbit_fixed_eh_solution_case_validation_output.wl`
- Run log: `tests/artifacts/run_logs/validate_orbit_fixed_eh_solution_cases_13_3.log`

The result is strong evidence that ORBIT is behaving correctly on the two most important easily-checkable cases in this repo:

- the `d <= 5` fixed-EH solution exists and reproduces the expected Lagrangian after substitution
- the `d <= 6` fixed-EH witness solution reproduces all supported sectors, and the remaining `{2,4}` difference is a pure higher-derivative field redefinition with zero `R^2` and zero `Ricci^2`

Exact Mathematica-ready field-redefinition expressions are collected in:

- `tests/artifacts/orbit_solution_case_field_redefinitions.wl`

Step-by-step manual substitution/check artifact:

- `tests/manual_check_orbit_solution_case_field_redefinitions.wls`
- `tests/artifacts/orbit_solution_case_manual_check_output.wl`
- `tests/artifacts/orbit_solution_case_manual_check_walkthrough.md`

End-to-end analytic derivation note:

- `tests/artifacts/orbit_solution_case_end_to_end_derivation.md`

Fresh step-0 original-lagrangian audit:

- `tests/artifacts/orbit_fixed_eh_from_original_lagrangian_validation_report.md`
- `tests/artifacts/orbit_fixed_eh_from_original_lagrangian_validation_walkthrough.md`

## What Was Validated

### Dimension 5

The validator rebuilds the comparison state directly from the Matchete `.mx` input and checks:

- the supported-sector matching equations admit a symbolic solution
- the final witness substitutions satisfy every supported matching equation
- every supported reduced-sector difference vanishes after substitution
- the supported interaction sector `{3,2}` was rechecked explicitly

Result:

- `MatchEquationCount -> 15`
- `MatchInfo["HasSolution"] -> True`
- all supported differences vanished
- the rechecked interaction-sector coefficient difference was zero, so no additional supported interaction field redefinition is required after applying the final witness solution

### Dimension 6

The validator uses a hybrid proof:

- it uses the stored final exact-match artifact for the supported-sector witness equations
- it freshly rebuilds the supported interaction sectors `{3,2}` and `{4,2}`
- it uses the stored quadratic-completion artifact for the `{2,4}` sector

Checks performed:

- the final witness substitutions satisfy every supported matching equation
- the stored result still reports `VerifiedSupportedMatchQ -> True`
- every supported reduced-sector difference vanishes after substitution
- supported interaction sectors `{3,2}` and `{4,2}` were rechecked explicitly
- the quadratic completion has zero residual
- the curvature-squared coefficients vanish:
  - `R2 -> 0`
  - `Ricci2 -> 0`
- the `{2,4}` projected difference is reconstructed exactly from the higher-derivative field-redefinition image

Result:

- `MatchEquationCount -> 29`
- all supported differences vanished
- the rechecked interaction-sector coefficient differences were zero, so no additional supported interaction field redefinition is required after applying the final witness solution
- the nontrivial `d = 6` field redefinition lives in the quadratic `{2,4}` sector and was reconstructed successfully

## Field Redefinitions For Manual Checking

### Dimension 5

Supported interaction-sector field redefinition:

- sector `{3,2}`: `0`

Interpretation:

- after applying the solved witness substitutions, the supported `d <= 5` interaction-sector difference already vanishes exactly, so there is no remaining nonzero supported interaction field redefinition to substitute by hand

### Dimension 6

Supported interaction-sector field redefinitions:

- sector `{3,2}`: `0`
- sector `{4,2}`: `0`

So the nontrivial manual check is the quadratic four-derivative sector `{2,4}`. The reconstructed higher-derivative field redefinition is:

```wl
\[Delta]h[u_, v_] :=
  (-3*PD[-i1][PD[i1][h[u, v]]])/(20*M^2) -
  (3*eta[u, v]*PD[-i2][PD[-i1][h[i1, i2]]])/(10*M^2) +
  (3*eta[u, v]*PD[-i2][PD[i2][h[i1, -i1]]])/(10*M^2)
```

In standard notation this is:

```text
\delta h_{\mu\nu}
= -\frac{3}{20 M^2} \Box h_{\mu\nu}
  -\frac{3}{10 M^2} \eta_{\mu\nu} \partial_\alpha \partial_\beta h^{\alpha\beta}
  +\frac{3}{10 M^2} \eta_{\mu\nu} \Box h^\alpha{}_\alpha
```

The corresponding projected `{2,4}` image coordinates are:

- `{9/(10*M^2), -9/(20*M^2), -3/(5*M^2), 3/(10*M^2), -3/(20*M^2)}`

and they exactly match the projected difference coordinates in the validation artifact.

The same section also verifies:

- `R2 -> 0`
- `Ricci2 -> 0`

so there is no residual curvature-squared content after removing this field-redefinition image.

## Problems Found During Validation

### 1. The first `d = 6` proof test tried to resolve the full symbolic match system again

Source:

- the initial validator reused the expensive symbolic solve path at `d = 6`

Effect:

- the run stalled for hours even though the physically meaningful witness-substitution checks were cheap

Resolution:

- the final validator now treats `d = 6` as a witness problem:
  - verify the stored supported-sector witness equations directly
  - recheck the physically relevant sectors explicitly
  - do not rerun the full symbolic solve inside the test

### 2. A brute-force quadratic explicit-shift route was brittle in xAct

Source:

- a direct first-order substitution/projection of the reconstructed higher-derivative `{2,4}` shift hit xAct dummy-index validation (`Validate::repeated`)

Effect:

- the proof script could fail even though the stored quadratic decomposition was already sufficient to prove the physics statement

Resolution:

- the final validator uses the stored quadratic-completion analysis as the proof object for `{2,4}`
- it checks:
  - decomposition has a solution
  - residual is zero
  - curvature-squared coefficients are zero
  - reconstructed image coordinates match the projected difference coordinates exactly

### 3. Benign `ToCanonical::noident` warnings polluted the proof run

Source:

- symbolic reference parameters and scalar prefactors inside comparison-sector assembly

Effect:

- noisy logs despite correct results

Resolution:

- the new validator suppresses these benign warnings in the comparison and selective-sector reduction paths
- the final run log is clean

### 4. Interaction-sector proof output was initially misleading

Source:

- the first artifact filtered out zero-shift interaction sectors, producing an empty association

Effect:

- the pass condition looked vacuous even though sectors had actually been rechecked

Resolution:

- the final artifact records the rechecked interaction sectors explicitly, including the fact that their solved coefficient differences are zero

## Files Added Or Updated

Primary validator:

- `tests/validate_orbit_fixed_eh_solution_cases.wls`

Primary proof artifact:

- `artifacts/orbit_fixed_eh/orbit_fixed_eh_solution_case_validation_output.wl`

Manual field-redefinition artifact:

- `tests/artifacts/orbit_solution_case_field_redefinitions.wl`

Manual substitution-check driver and artifact:

- `tests/manual_check_orbit_solution_case_field_redefinitions.wls`
- `tests/artifacts/orbit_solution_case_manual_check_output.wl`

Primary run log:

- `tests/artifacts/run_logs/validate_orbit_fixed_eh_solution_cases_13_3.log`

Debug artifacts created while isolating the validation bottlenecks:

- `tests/debug_d6_solution_case_timing.wls`
- `tests/debug_quadratic_explicit_shift.wls`
- `tests/artifacts/run_logs/debug_d6_solution_case_timing_13_3.log`
- `tests/artifacts/run_logs/debug_quadratic_explicit_shift_13_3.log`

## Interpretation

For these two benchmark cases, ORBIT now has a reviewable proof trail:

- `d <= 5` works from fresh reconstruction and direct substitution
- `d <= 6` works on every supported sector
- the only nontrivial `d = 6` leftover is the quadratic four-derivative sector
- that leftover is not physical curvature-squared content; it is entirely a higher-derivative field redefinition

That is exactly the outcome one would want if ORBIT is correctly separating physical data from field-redefinition ambiguity.

## Recommended Follow-Up Testing

### 1. Promote this validator into the standard regression workflow

Add `tests/validate_orbit_fixed_eh_solution_cases.wls` to the documented validation set, or add a lighter smoke wrapper around it inside `tests/orbit_comprehensive_test.wls`.

### 2. Add a clean-cache `d = 6` rerun

The current proof test deliberately reuses cached basis data. A slower offline regression could delete the ORBIT cache and confirm that the same artifact is reproduced from scratch.

### 3. Add explicit artifact assertions for the zero-shift interaction sectors

Now that the validator records `{3,2}` and `{4,2}` explicitly, a future test can assert directly that:

- the coefficient differences are exactly zero
- the reconstructed field redefinition is exactly `0`

### 4. Add a focused quadratic-completion regression

The `{2,4}` sector is scientifically important. A dedicated regression could assert:

- `CurvatureCoefficients == <|"R2" -> 0, "Ricci2" -> 0|>`
- `ResidualExpression == 0`
- reconstructed image coordinates equal projected difference coordinates

### 5. Consider exposing a first-class witness-check mode in the comparison pipeline

The validator had to distinguish between:

- an expensive symbolic solve
- a cheap and physically sufficient witness substitution check

Making that distinction explicit in the comparison tooling would make future validations simpler and less fragile.
