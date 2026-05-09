# ORBIT Solution-Case Manual Check Walkthrough

## Purpose

This artifact is the companion to the proof-case validator. It is meant for manual inspection rather than discovery.

It writes out:

- the witness substitutions used in the validated `d <= 5` and `d <= 6` solution cases
- the supported-sector residual expressions after substitution
- the exact supported interaction-sector field redefinitions
- the explicit `d = 6` quadratic `{2,4}` higher-derivative field redefinition
- the first-order shift produced by substituting that field redefinition into the Fierz-Pauli Lagrangian
- the projected `{2,4}` image and residuals that were actually validated

## Files

Driver:

- `tests/manual_check_orbit_solution_case_field_redefinitions.wls`

Output artifact:

- `tests/artifacts/orbit_solution_case_manual_check_output.wl`

Suggested run command:

```powershell
& 'C:\Program Files\Wolfram Research\Mathematica\13.3\math.exe' -script tests\manual_check_orbit_solution_case_field_redefinitions.wls
```

## What To Inspect

### D5

Open:

- `D5["SupportedInteractionFieldRedefinitions"]`
- `D5["SupportedSectorResidualExpressions"]`
- `D5["TotalSupportedResidualExpression"]`

Expected result:

- the supported interaction-sector field redefinition is `0`
- every supported residual expression is `0`
- the total supported residual is `0`

### D6 supported sectors

Open:

- `D6["SupportedInteractionFieldRedefinitions"]`
- `D6["SupportedSectorResidualExpressions"]`
- `D6["TotalSupportedResidualExpression"]`

Expected result:

- the supported interaction-sector field redefinitions in `{3,2}` and `{4,2}` are `0`
- every supported residual expression is `0`
- the total supported residual is `0`

### D6 quadratic `{2,4}` sector

Open:

- `D6["QuadraticFourDerivative"]["FieldRedefinition"]`
- `D6["QuadraticFourDerivative"]["DirectFirstOrderShiftFromSubstitution"]`
- `D6["QuadraticFourDerivative"]["ProjectedImageExpression"]`
- `D6["QuadraticFourDerivative"]["ProjectedDifferenceExpression"]`
- `D6["QuadraticFourDerivative"]["ProjectedExpressionResidual"]`
- `D6["QuadraticFourDerivative"]["CoordinateResidual"]`
- `D6["QuadraticFourDerivative"]["CurvatureSquaredCoefficients"]`

Expected result:

- the direct first-order shift is the explicit substitution result from the Fierz-Pauli Lagrangian
- the projected image expression equals the projected difference expression
- the projected expression residual is `0`
- the coordinate residual is the zero vector
- `CurvatureSquaredCoefficients == <|"R2" -> 0, "Ricci2" -> 0|>`

## Important Note

The validated equality for the nontrivial `d = 6` quadratic sector is the equality of the projected `{2,4}` image and the projected `{2,4}` difference, together with zero curvature-squared coefficients and zero residual.

That is the correct manual object to inspect because the physics comparison is done modulo IBP and field redefinitions.
