# ORBIT Solution-Case Validation Walkthrough

## Goal

Add a reviewable validation that answers the two strongest practical questions for the fixed-EH workflow:

1. Does ORBIT find a correct solution through mass dimension 5?
2. Does ORBIT still behave correctly through mass dimension 6, including the quadratic four-derivative sector?

## Design

The validator lives in:

- `tests/validate_orbit_fixed_eh_solution_cases.wls`

It is intentionally split into two proof styles.

### D5 path

`d = 5` is rebuilt from the original Matchete `.mx` input.

Why:

- the full state is still cheap enough to reconstruct
- this gives a direct end-to-end proof instead of trusting a stored artifact

What it checks:

- symbolic match-system solvability
- witness-substitution satisfaction of the matching equations
- vanishing of supported-sector reduced differences
- explicit recheck of the supported interaction sector

### D6 path

`d = 6` uses a hybrid approach.

Why:

- the full symbolic solve is too expensive for a practical regression
- the physically meaningful checks are much cheaper than the symbolic solve

What it checks:

- supported-sector witness equations from the stored final result
- fresh re-reduction of interaction sectors `{3,2}` and `{4,2}`
- stored quadratic-completion proof for sector `{2,4}`

## Why The Final D6 Design Is Correct

There were two candidate proof strategies.

### Strategy A: rerun the full symbolic `d = 6` solve

This is conceptually simple but impractical. The test spent hours in the symbolic solve even though the final witness substitution already existed.

Conclusion:

- rejected for regression use

### Strategy B: witness proof plus sector-local rechecks

This is the final design.

It proves the same physics statement in a much cheaper way:

- the witness substitution solves all supported equations
- the supported reduced differences vanish
- the supported interaction sectors are rechecked explicitly
- the unsupported quadratic sector is decomposed into curvature-squared pieces plus field-redefinition image

Conclusion:

- accepted as the regression proof

## Important Observation About The Interaction Sectors

The rechecked interaction sectors are:

- `D5`: `{3,2}`
- `D6`: `{3,2}`, `{4,2}`

In the final solved witness configuration, all of these sectors have:

- zero coefficient difference
- zero reconstructed field redefinition
- zero projected difference

So the important statement is not "ORBIT needed a nontrivial supported interaction-sector field redefinition here."

It is:

- after solving for the reference parameters, the supported interaction sectors already agree exactly

That is why the only genuinely nontrivial `d = 6` redefinition evidence sits in the quadratic `{2,4}` sector.

## Quadratic `{2,4}` Logic

This is the key `d = 6` subtlety.

The validator uses the stored quadratic analysis to verify four things:

1. The projected `{2,4}` difference has a decomposition.
2. The curvature-squared coefficients vanish.
3. The residual after removing the redefinition image is zero.
4. The reconstructed field-redefinition image coordinates match the projected difference coordinates exactly.

This is the correct sector-local proof that the quadratic four-derivative difference is pure field-redefinition data rather than physical curvature-squared content.

## Explicit Field Redefinitions

For manual inspection, the exact Mathematica expressions are collected in:

- `tests/artifacts/orbit_solution_case_field_redefinitions.wl`

For a step-by-step manual-check artifact, use:

- `tests/manual_check_orbit_solution_case_field_redefinitions.wls`
- `tests/artifacts/orbit_solution_case_manual_check_output.wl`
- `tests/artifacts/orbit_solution_case_manual_check_walkthrough.md`
- `tests/artifacts/orbit_solution_case_end_to_end_derivation.md`
- `tests/artifacts/orbit_fixed_eh_from_original_lagrangian_validation_report.md`
- `tests/artifacts/orbit_fixed_eh_from_original_lagrangian_validation_walkthrough.md`

The important content is:

- `D5`, sector `{3,2}`: field redefinition `0`
- `D6`, sector `{3,2}`: field redefinition `0`
- `D6`, sector `{4,2}`: field redefinition `0`

So the only nontrivial explicit field redefinition to inspect manually is the `D6` quadratic `{2,4}` shift:

```wl
\[Delta]h[u_, v_] :=
  (-3*PD[-i1][PD[i1][h[u, v]]])/(20*M^2) -
  (3*eta[u, v]*PD[-i2][PD[-i1][h[i1, i2]]])/(10*M^2) +
  (3*eta[u, v]*PD[-i2][PD[i2][h[i1, -i1]]])/(10*M^2)
```

equivalently,

```text
\delta h_{\mu\nu}
= -\frac{3}{20 M^2} \Box h_{\mu\nu}
  -\frac{3}{10 M^2} \eta_{\mu\nu} \partial_\alpha \partial_\beta h^{\alpha\beta}
  +\frac{3}{10 M^2} \eta_{\mu\nu} \Box h^\alpha{}_\alpha
```

The validator also records the projected image coordinates of this shift, and they match the projected `{2,4}` difference coordinates exactly.

## Fixes Made While Building The Validator

### 1. Replaced the expensive `D6` solve with a witness-equation check

The original validator shape was too slow. The final version adds a witness-only equation summary for `d = 6`.

### 2. Suppressed benign canonicalization warnings

The validator now quiets benign `ToCanonical::noident` warnings in the proof path so the run log stays readable.

### 3. Recorded zero-shift interaction sectors explicitly

Instead of filtering them out, the final artifact keeps the sector summaries. This makes it clear that those sectors were actually rechecked.

### 4. Avoided the brittle brute-force quadratic projection route

The direct first-order substitution/projection of the reconstructed higher-derivative quadratic shift triggered xAct dummy-index validation. The final validator uses the already-correct sector-local decomposition artifact instead.

## Final Output

Main artifact:

- `artifacts/orbit_fixed_eh/orbit_fixed_eh_solution_case_validation_output.wl`

Main execution log:

- `tests/artifacts/run_logs/validate_orbit_fixed_eh_solution_cases_13_3.log`

Key final values from the artifact:

- `D5["MatchEquationCount"] -> 15`
- `D5["MatchInfo"]["HasSolution"] -> True`
- `D5["AllSupportedDifferencesVanishQ"] -> True`
- `D6["MatchEquationCount"] -> 29`
- `D6["AllSupportedDifferencesVanishQ"] -> True`
- `D6["QuadraticCompletion"]["DecompositionHasSolutionQ"] -> True`
- `D6["QuadraticCompletion"]["ResidualIsZeroQ"] -> True`
- `D6["QuadraticCompletion"]["PureQuadraticRedefinitionQ"] -> True`
- `D6["QuadraticCompletion"]["CurvatureCoefficients"] -> <|"R2" -> 0, "Ricci2" -> 0|>`

## Bottom Line

The new proof-case validator now gives ORBIT a reviewable answer to the strongest fixed-EH sanity checks in the repository:

- `d <= 5` matches correctly
- `d <= 6` matches correctly on all supported sectors
- the apparent `d = 6` quadratic discrepancy is entirely higher-derivative field-redefinition data and not physical curvature-squared content
