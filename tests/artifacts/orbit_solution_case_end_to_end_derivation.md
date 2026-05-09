# ORBIT Fixed-EH `d <= 6` End-to-End Match Derivation

## Purpose

This note gives a single reviewable argument for the strongest fixed-EH claim currently validated in ORBIT:

- after applying the specific witness solution found by the comparison pipeline, and
- after applying the specific nontrivial higher-derivative field redefinition,

the EFT truncated through ORBIT mass dimension `6` matches the fixed Einstein-Hilbert reference.

This note is meant to be read together with:

- `artifacts/orbit_fixed_eh/orbit_fixed_eh_solution_case_validation_output.wl`
- `tests/artifacts/orbit_solution_case_manual_check_output.wl`
- `artifacts/orbit_fixed_eh/orbit_fixed_eh_quadratic_completion_analysis.wl`

The goal here is not to restate every artifact mechanically. The goal is to show the full logic in one place and to manually verify the nontrivial step.

## Claim

Let

```text
L := Log[\[Mu]bar2 / M^2].
```

On the positive branch used in the validation artifacts,

```text
L = -3/2,
LambdaRefFinal = 0,
KappaRefFinal = 4 Sqrt[3] / M.
```

With those substitutions, the ORBIT-fixed-EH comparison through `d <= 6` has:

- exact agreement in every supported sector after reduction modulo IBP and field redefinitions
- one remaining nontrivial reduced discrepancy in sector `{2,4}`

and that remaining `{2,4}` discrepancy is exactly reproduced by the quadratic Fierz-Pauli field-redefinition image

```text
\delta h_{\mu\nu}
= -\frac{3}{20 M^2} \Box h_{\mu\nu}
  -\frac{3}{10 M^2} \eta_{\mu\nu} \partial_\alpha \partial_\beta h^{\alpha\beta}
  +\frac{3}{10 M^2} \eta_{\mu\nu} \Box h^\alpha{}_\alpha.
```

Therefore the EFT and GR agree through ORBIT mass dimension `6` in the reduced/IBP sense used by the comparison pipeline.

## 1. Witness Solution From The Match Equations

The `d <= 5` exact-match artifact records the following three equations among the solved system:

```text
\kappa sqrt[-1 / (M^2 \kappa^2 (1 + L))] (3 + 2 L) = 0
```

```text
KappaRefFinal = 2 Sqrt[6] \kappa sqrt[-1 / (M^2 \kappa^2 (1 + L))]
```

```text
Sqrt[6] M^4 \kappa sqrt[-1 / (M^2 \kappa^2 (1 + L))] (3 + 2 L)
= 4 KappaRefFinal LambdaRefFinal
```

Under the validation assumptions

```text
M > 0, \kappa > 0, \[Mu]bar2 > 0,
```

the square-root prefactor is nonzero, so the first equation gives immediately

```text
3 + 2 L = 0
```

and hence

```text
L = -3/2.
```

Substituting `L = -3/2` into the second equation:

```text
1 + L = -1/2
```

so

```text
sqrt[-1 / (M^2 \kappa^2 (1 + L))]
= sqrt[2 / (M^2 \kappa^2)]
= Sqrt[2] / (M \kappa).
```

Therefore

```text
KappaRefFinal
= 2 Sqrt[6] \kappa * Sqrt[2] / (M \kappa)
= 4 Sqrt[3] / M.
```

Finally, the third equation becomes

```text
0 = 4 KappaRefFinal LambdaRefFinal.
```

Since `KappaRefFinal = 4 Sqrt[3] / M` is nonzero, we get

```text
LambdaRefFinal = 0.
```

So the specific witness solution used throughout the validation is not mysterious:

```text
Log[\[Mu]bar2 / M^2] = -3/2,
LambdaRefFinal = 0,
KappaRefFinal = 4 Sqrt[3] / M.
```

## 2. What Already Matches Before Any Nontrivial Field Redefinition

After applying that witness solution, the manual-check artifact records

```text
D6["SupportedInteractionFieldRedefinitions"] = <|{3,2} -> 0, {4,2} -> 0|>
```

and

```text
D6["SupportedSectorResidualExpressions"] =
  <|{1,0} -> 0, {2,0} -> 0, {2,2} -> 0, {3,0} -> 0, {3,2} -> 0,
    {4,0} -> 0, {4,2} -> 0, {5,0} -> 0, {6,0} -> 0|>.
```

This means:

- the cosmological sectors match
- the quadratic two-derivative sector matches
- the cubic and quartic two-derivative GR sectors match
- the quintic and sextic zero-derivative sectors match

So the only remaining nonzero piece at `d <= 6` is the unsupported quadratic four-derivative sector `{2,4}`.

That is why the proof can focus entirely on that sector.

## 3. The Remaining `{2,4}` Difference

The validated projected `{2,4}` discrepancy can be written as

```text
\Delta L_{2,4}
= \frac{9}{10 M^2} B1
 - \frac{9}{20 M^2} B2
 - \frac{3}{5 M^2} B3
 + \frac{3}{10 M^2} B4
 - \frac{3}{20 M^2} B5,
```

where the five projected basis monomials are

```text
B1 := (\partial_b \partial_c h^\alpha{}_\alpha) (\partial_d \partial^d h^{bc})
```

```text
B2 := (\partial_b \partial^b h^\alpha{}_\alpha) (\partial_d \partial^d h^\beta{}_\beta)
```

```text
B3 := (\partial_a \partial_b h_{cd}) (\partial^c \partial^d h^{ab})
```

```text
B4 := (\partial_b \partial_d h_{ac}) (\partial^c \partial^d h^{ab})
```

```text
B5 := (\partial_c \partial_d h_{ab}) (\partial^c \partial^d h^{ab}).
```

In coordinate form,

```text
\Delta = (9/10, -9/20, -3/5, 3/10, -3/20) / M^2.
```

This is exactly the coordinate vector stored in the quadratic-completion artifact.

## 4. The Nontrivial Field Redefinition

The only nonzero validated field redefinition is

```text
\delta h_{\mu\nu}
= -\frac{3}{10 M^2} \eta_{\mu\nu} \partial_\alpha \partial_\beta h^{\alpha\beta}
  -\frac{3}{20 M^2} \Box h_{\mu\nu}
  +\frac{3}{10 M^2} \eta_{\mu\nu} \Box h^\alpha{}_\alpha.
```

It is convenient to split this into three basis shifts:

```text
\delta h^{(1)}_{\mu\nu} := \eta_{\mu\nu} \partial_\alpha \partial_\beta h^{\alpha\beta}
```

```text
\delta h^{(2)}_{\mu\nu} := \Box h_{\mu\nu}
```

```text
\delta h^{(3)}_{\mu\nu} := \eta_{\mu\nu} \Box h^\alpha{}_\alpha.
```

Then

```text
\delta h_{\mu\nu}
= a_1 \delta h^{(1)}_{\mu\nu}
 + a_2 \delta h^{(2)}_{\mu\nu}
 + a_3 \delta h^{(3)}_{\mu\nu}
```

with

```text
a_1 = -3 / (10 M^2),
a_2 = -3 / (20 M^2),
a_3 =  3 / (10 M^2).
```

## 5. Why This Cannot Spoil The GR Cubic Or Quartic Match

This is the key EFT-counting step.

In ORBIT's sector language, the Einstein-Hilbert reference through mass dimension `6` contains the supported sectors

```text
{1,0}, {2,0}, {2,2}, {3,0}, {3,2}, {4,0}, {4,2}, {5,0}, {6,0}.
```

The nontrivial shift `\delta h_{\mu\nu}` contains one field and two derivatives, so it lives in sector `{1,2}`.

A first-order variation of an EH sector `{n,2}` under `h -> h + \delta h` therefore lands in `{n,4}`:

- `{2,2} -> {2,4}`
- `{3,2} -> {3,4}`
- `{4,2} -> {4,4}`

But ORBIT truncates by `nh + Nd <= 6`, so:

- `{2,4}` survives
- `{3,4}` has total degree `7` and is truncated away
- `{4,4}` has total degree `8` and is truncated away

This is the decisive reason the quadratic higher-derivative shift does not ruin the ordinary GR cubic or quartic sectors:

- the sectors `{3,2}` and `{4,2}` already matched exactly before this step
- the field redefinition can only modify `{2,4}` within the `d <= 6` truncation

So the entire `d <= 6` problem really does reduce to the quadratic sector.

## 6. Manual Reconstruction Of The Quadratic Difference

The quadratic-completion artifact gives the projected image vectors of the three independent shifts above:

```text
v1 = (-2, 0, 2, 0, 0)
```

```text
v2 = ( 2,-1, 0,-2, 1)
```

```text
v3 = ( 2,-2, 0, 0, 0).
```

These are the `{B1, B2, B3, B4, B5}` coordinates of the first-order Fierz-Pauli shift produced by

- `\delta h^{(1)}`
- `\delta h^{(2)}`
- `\delta h^{(3)}`

respectively.

To prove that the remaining discrepancy is pure field-redefinition data, we solve by hand

```text
a_1 v1 + a_2 v2 + a_3 v3 = \Delta.
```

Using the third component:

```text
2 a_1 = -3 / (5 M^2)
```

so

```text
a_1 = -3 / (10 M^2).
```

Using the fourth component:

```text
-2 a_2 = 3 / (10 M^2)
```

so

```text
a_2 = -3 / (20 M^2).
```

Using the second component:

```text
-a_2 - 2 a_3 = -9 / (20 M^2).
```

Substituting `a_2 = -3 / (20 M^2)` gives

```text
3 / (20 M^2) - 2 a_3 = -9 / (20 M^2),
```

hence

```text
a_3 = 3 / (10 M^2).
```

Now check the remaining components:

First component:

```text
-2 a_1 + 2 a_2 + 2 a_3
= 6/(10 M^2) - 3/(10 M^2) + 6/(10 M^2)
= 9/(10 M^2).
```

Fifth component:

```text
a_2 = -3 / (20 M^2).
```

So all five components match exactly:

```text
a_1 v1 + a_2 v2 + a_3 v3
= (9/10, -9/20, -3/5, 3/10, -3/20) / M^2
= \Delta.
```

This is the manual confirmation of the nontrivial step:

- the leftover `{2,4}` discrepancy lies exactly in the image of a higher-derivative field redefinition
- the coefficients are exactly the ones recorded by ORBIT

No curvature-squared term is needed for this reconstruction.

## 7. Correct End-To-End Conclusion

Let

```text
L_EFT^{<=6}
```

denote the ORBIT EFT truncated to sectors with `nh + Nd <= 6`, and let

```text
L_GR^{<=6}
```

denote the fixed Einstein-Hilbert reference truncated the same way.

After inserting

```text
Log[\[Mu]bar2 / M^2] = -3/2,
LambdaRefFinal = 0,
KappaRefFinal = 4 Sqrt[3] / M,
```

the exact artifacts show that all supported reduced sectors match, and that the only remaining reduced discrepancy is the quadratic four-derivative sector:

```text
L_EFT^{<=6} - L_GR^{<=6} = \Delta L_{2,4}.
```

The manual computation above shows

```text
\Delta L_{2,4}
= \delta L_FP[\delta h]
```

for

```text
\delta h_{\mu\nu}
= -\frac{3}{20 M^2} \Box h_{\mu\nu}
  -\frac{3}{10 M^2} \eta_{\mu\nu} \partial_\alpha \partial_\beta h^{\alpha\beta}
  +\frac{3}{10 M^2} \eta_{\mu\nu} \Box h^\alpha{}_\alpha.
```

Because this shift only affects sector `{2,4}` within the `d <= 6` truncation, the correct comparison statement is:

```text
the original EFT and the fixed-EH reference agree on every supported reduced sector,
and the remaining reduced `{2,4}` discrepancy is exactly the projected Fierz-Pauli image of \delta h.
```

This is the precise sense in which the fixed-EH EFT matches GR through mass dimension `6`.

## 8. Important Correction From The Step-0 Audit

The stronger literal statement

```text
L_EFT^{<=6}(h) = L_GR^{<=6}(h + \delta h)
```

is **not** correct if `L_GR^{<=6}` is taken to mean the raw unreduced ORBIT reference representative produced by `ExpandFixedEHReferenceLagrangian`.

The fresh step-0 validator starting from the original `.mx` input shows:

- the raw full-reference first-order shift contains sectors `{1,4}` and `{2,4}`
- the extra `{1,4}` contribution reduces to zero
- the projected `{2,4}` coordinates of that raw full-reference shift are actually `{0, 0, 0, 0, 0}`

So the naive substitution into the full unreduced ORBIT reference does **not** directly produce the validated quadratic discrepancy.

What *is* correct, and what ORBIT actually proves, is the reduced/IBP statement:

- the supported sectors of the original EFT match the witness-fixed GR reference
- the remaining reduced `{2,4}` discrepancy matches the projected Fierz-Pauli image of `\delta h`

That is the correct end-to-end formulation.

## 9. What Was Checked Manually Here

Manual checks performed in this note:

- solving the witness branch from the stored match equations
- proving by sector counting that the nontrivial field redefinition cannot alter `{3,2}` or `{4,2}` within the `d <= 6` truncation
- solving the quadratic image-decomposition problem by hand and recovering the exact coefficients of `\delta h`

Artifact-backed facts used here:

- the supported-sector residuals are all zero after the witness substitution
- the projected `{2,4}` difference coordinates are the five numbers shown above
- the three independent quadratic field-redefinition image vectors are exactly `v1`, `v2`, `v3`

So this note is not a replacement for the exact Mathematica artifacts. It is the analytic bridge that explains them end to end.
