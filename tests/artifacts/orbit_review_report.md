# ORBIT Package Review Report

> Comprehensive review of the `ORBIT_BUILD` branch covering physics/mathematics correctness and code/syntax correctness.

---

## Executive Summary

The ORBIT toolkit is a well-engineered Wolfram Language package for constructing and reducing local flat-space graviton operator bases. After thorough review of all source files, I find the **physics and mathematics to be correct and well-founded**. The code faithfully implements the two quotient constructions (IBP and linearized Fierz–Pauli field redefinitions) described in the documentation. There are **no critical bugs**, but I have identified several issues ranging from minor code defects to potential edge-case failures and a few physics subtleties worth flagging.

---

## Part I: Physics and Mathematics Review

### 1. Fierz–Pauli Lagrangian ✅ Correct

```wl
LFP = canonExpr[
   -1/2 PD[a]@h[b,c] PD[-a]@h[-b,-c]
   +    PD[a]@h[-a,b] PD[c]@h[-c,-b]
   -    PD[a]@h[-a,b] PD[-b]@h[c,-c]
   + 1/2 PD[a]@h[b,-b] PD[-a]@h[c,-c]
];
```

This is the standard linearized Fierz–Pauli kinetic Lagrangian for a massless spin-2 field on flat spacetime:

$$\mathcal{L}_{\text{FP}} = -\tfrac{1}{2}\partial_\alpha h_{\beta\gamma}\partial^\alpha h^{\beta\gamma} + \partial_\alpha h^{\alpha\beta}\partial_\gamma h^{\gamma}{}_\beta - \partial_\alpha h^{\alpha\beta}\partial_\beta h^\gamma{}_\gamma + \tfrac{1}{2}\partial_\alpha h^\beta{}_\beta \partial^\alpha h^\gamma{}_\gamma$$

The sign conventions and relative coefficients are correct. This produces the linearized Einstein equations of motion as its Euler–Lagrange equations.

### 2. Sector Grading ✅ Correct

The decomposition into sectors `{nh, Nd}` (number of graviton fields × number of derivatives) is mathematically exact:
- IBP preserves `{nh, Nd}` — this is correct because total derivatives redistribute derivatives but don't change the field or derivative count.
- Field redefinitions from sector `{nh-1, Nd-2}` land in `{nh, Nd}` — correct because the FP kinetic term contributes one extra `h` and two extra derivatives.

### 3. IBP Quotient via Euler Operator ✅ Correct

The criterion used — a scalar Lagrangian density is a total derivative iff its Euler–Lagrange (variational) derivative vanishes — is the correct variational identity for local functionals. The implementation:

1. Forms a generic ansatz `Sum[c_i B_i]`
2. Computes `VarD[h[-m,-n], PD][ans]`
3. Solves for `c_i` giving vanishing EL equations

This correctly identifies `ker(E)` where `E` is the Euler map, and the quotient `V / ker(E)` is the IBP quotient. **Mathematically rigorous.**

### 4. Field-Redefinition Image ✅ Correct

The implementation of `ShiftFromRedefExpr` correctly expands `L_{FP}(h + λ δh)`, extracts the `O(λ)` piece, and replaces `δh` with a concrete rank-2 tensor. This is the standard first-order variation:

$$\delta L_{\text{FP}} = E_{\text{FP}}^{\mu\nu} \delta h_{\mu\nu} + \partial_\mu K^\mu$$

The projection of these images into the IBP basis and the subsequent quotient is mathematically sound.

### 5. Quadratic Sector Treatment ✅ Correct

The code correctly skips field-redefinition quotient for `nh < 3`. The documentation explains this well: at quadratic order, linear field redefinitions act on the kinetic operator itself, which would incorrectly quotient out the normalization of the FP term. Only interaction sectors (`nh ≥ 3`) are quotiented by field redefinitions.

### 6. Raw Basis Generation ✅ Correct

- `CompositionList[Nd, nh]` generates all ordered partitions (compositions) of `Nd` derivatives among `nh` fields — correct.
- `AllContractions` from xAct generates all scalar contractions — correct.
- Odd-`Nd` sectors are correctly skipped (they produce no scalar contractions in 4D with symmetric rank-2 fields).

### 7. Rank-2 Basis via Probe Tensor ✅ Correct

Using a probe tensor `P_{AB}`, generating scalar contractions `P_{AB} × (product of h's with derivatives)`, and then differentiating `VarD[probe[-u,-v], PD]` to extract the rank-2 coefficient is the standard functional differentiation trick. **Correct.**

### 8. Linearized Curvature Expressions ✅ Correct

The linearized Ricci tensor, Ricci scalar, and Riemann tensor expressions in `orbit_fixed_eh_comparison.wl` (lines 306–336) are the standard linearized expressions on flat spacetime:

- `linRicciExpr`: $R^{(1)}_{\mu\nu} = \frac{1}{2}(\partial_\rho\partial_\mu h^\rho{}_\nu + \partial_\rho\partial_\nu h^\rho{}_\mu - \partial_\mu\partial_\nu h - \Box h_{\mu\nu})$ ✅
- `linRicciScalarExpr`: $R^{(1)} = \partial_\mu\partial_\nu h^{\mu\nu} - \Box h$ ✅
- `linRiemannExpr`: standard 4-index linearized Riemann ✅

### 9. EH Reference Expansion ✅ Correct

The Einstein–Hilbert reference Lagrangian is expanded as:

$$\mathcal{L}_{\text{ref}} = \Lambda\sqrt{-g} + s_{\text{EH}} \frac{2}{\kappa^2}\sqrt{-g}R$$

using xPert's `PerturbFlat` for the metric perturbation expansion. The cosmological piece is expanded to 6th order in κ and the EH piece to 4th order — appropriate for the targeted mass dimensions.

### 10. Canonical Normalization ✅ Correct

The kinetic normalization procedure extracts a symbolic factor from the `{2,2}` sector comparing the input to FP, then rescales each sector by `(β²)^{nh/2}` where `β² = s_kin/Z_h`. This is the correct field rescaling for canonical normalization of a graviton EFT.

> [!IMPORTANT]
> ### Physics Subtlety: Evanescent Operators
> The package works strictly in D=4. In dimensional regularization contexts, there can be evanescent operators (operators that vanish identically in D=4 but not in D=4−2ε). The package does not account for these, which is correctly noted in the README as a limitation. This is not a bug, but users matching to dimensionally-regulated calculations should be aware.

> [!NOTE]
> ### Physics Subtlety: Gauge Invariance
> The package does not impose linearized diffeomorphism invariance. The physical basis it produces is larger than the gauge-invariant subspace. This is appropriately documented and the quadratic completion analysis in `AnalyzeQuadraticFourDerivativeDifference` correctly handles the `{2,4}` sector by projecting onto the curvature-squared subspace.

---

## Part II: Code/Syntax Review

### Issue 1: `termCount` Bug in Example Scripts ⚠️ Medium

**File**: [run_left_only_uv_2_eft_6_reduction.wls](file:///d:/ORBIT/examples/left_only_uv_2_eft_6/run_left_only_uv_2_eft_6_reduction.wls#L11-L13)

```wl
termCount[expr_] := Module[{expanded = Expand[expr]},
  If[expanded === 0, 0, Length[List @@ expanded]]
];
```

When `expanded` is a single monomial (not a `Plus` head), `List @@ expanded` applies `List` to the head of that monomial (e.g., `Times`), returning its factors rather than `{monomial}`. For a single-term expression, `Length` will return the number of factors, not 1.

**Fix**: Use the same pattern as `expressionTermCount` in the comparison file:
```wl
termCount[expr_] := Which[
  expr === 0, 0,
  Head[Expand[expr]] === Plus, Length[List @@ Expand[expr]],
  True, 1
];
```

This same bug appears in [reduce_left_only_uv_2_eft_6_by_sector.wls](file:///d:/ORBIT/examples/left_only_uv_2_eft_6/reduce_left_only_uv_2_eft_6_by_sector.wls#L22-L24) (line 22–24).

> [!WARNING]
> The main package file (`graviton_basis_toolkit.wl`) does **not** have this bug — `expressionTermCount` at line 115 of `orbit_fixed_eh_comparison.wl` handles all three cases correctly. The bug is only in the example scripts.

---

### Issue 2: `ProjectModuloIBP` Derivative-Free Branch Logic 🔍 Low

**File**: [graviton_basis_toolkit.wl](file:///d:/ORBIT/graviton_basis_toolkit.wl#L511-L515)

```wl
eq = If[
  DerivativeFreeExprQ[ans] && DerivativeFreeExprQ[cleanExpr],
  canonExpr[ans - cleanExpr],
  canonExpr @ VarD[h[-m, -n], PD][ans - cleanExpr]
];
```

The derivative-free branch skips the Euler operator and instead directly matches the expression. This is correct for zero-derivative sectors (where the Euler operator reduces to simple algebraic differentiation), but there's a subtlety: in the derivative-free case, the matching is done at the Lagrangian level rather than at the EOM level, which could in principle be more restrictive. In practice, for the zero-derivative sector `{nh, 0}`, there are no IBP relations anyway (no derivatives to integrate by parts), so direct matching is equivalent. **Correct but the logic is non-obvious — a comment would help.**

---

### Issue 3: `TermSectorKey` Counts Contracted Indices ⚠️ Medium

**File**: [graviton_basis_toolkit.wl](file:///d:/ORBIT/graviton_basis_toolkit.wl#L316-L319)

```wl
TermSectorKey[term_] := {
  Count[term, HoldPattern[h[_, _]], Infinity],
  Count[term, HoldPattern[PD[_][__]], Infinity]
};
```

This counts `PD` wrappers at all levels. After canonicalization, a term like `PD[-a]@PD[-b]@h[c,d]` has two nested `PD` patterns, and the inner `PD[-b]@h[c,d]` also matches `PD[_][__]`. So the count is correct — each derivative is counted once because each `PD` wrapper appears exactly once in the tree. **However**, this relies on the assumption that the expression has been properly expanded (no `Power[PD[...], n]` structures). Since `TermSectorKey` is called on individual expanded terms from `SplitTermsBySector`, and `Expand` is called first, this should be safe in practice.

**Potential edge case**: If a user passes an unexpanded expression to `ReduceLagrangian`, `SplitTermsBySector` calls `Expand` first (line 322), which should handle this. **Not a bug in normal use, but fragile if called directly on non-expanded input.**

---

### Issue 4: `NormalizeSectorList` Generates Sectors with `Nd=0` ✅ Correct but Worth Noting

**File**: [graviton_basis_toolkit.wl](file:///d:/ORBIT/graviton_basis_toolkit.wl#L148-L149)

```wl
NormalizeSectorList[Automatic, dmax_Integer] :=
  Flatten[Table[{nh, d - nh}, {d, 1, dmax}, {nh, 1, d}], 1];
```

This generates sectors including `{d, 0}` for each `d`. Zero-derivative sectors are valid but trivial for `nh ≥ 2` since they contain only `η`-contractions of `h`'s with no derivatives. The code handles these correctly — they just produce small bases. **No issue.**

---

### Issue 5: Potential `LinearSolve` Failure in `ReduceCoordinatesModuloRelations` ⚠️ Low

**File**: [graviton_basis_toolkit.wl](file:///d:/ORBIT/graviton_basis_toolkit.wl#L282)

```wl
imageCoeffs = LinearSolve[Transpose[relMat[[All, piv]]], coords[[piv]]];
```

If `Transpose[relMat[[All, piv]]]` is singular (which shouldn't happen if `piv` are genuine pivot columns from row reduction), `LinearSolve` will fail. The code does not wrap this in error handling. In practice, since `piv` comes from `PivotColumns` of the same matrix, the submatrix at pivot columns should be invertible by construction. **Not a practical bug, but defensive programming would add a check.**

The same pattern appears at line 341 in `ReduceCoordinatesModuloRedef`.

---

### Issue 6: `lam` Variable Shadowing in `IBPData` ⚠️ Low

**File**: [graviton_basis_toolkit.wl](file:///d:/ORBIT/graviton_basis_toolkit.wl#L446)

```wl
solvedc = Cases[First[sol], Rule[lhs_Symbol, _] :> lhs];
```

The pattern variable `lhs_Symbol` is fine, but note that the constant symbol `lam` (defined at line 96 as `DefConstantSymbol[lam]`) could in principle appear in solutions if xAct leaks it. In practice, `IBPData` doesn't involve `lam` (that's only used in `ShiftFromRedefExpr`), so this is safe. **No bug.**

---

### Issue 7: `SplitTermsBySector` on Zero Input 🔍 Minor

**File**: [graviton_basis_toolkit.wl](file:///d:/ORBIT/graviton_basis_toolkit.wl#L321-L329)

When `expr = 0`, `SplitTermsBySector` returns an empty `Association` via `Merge[{}, Total]`. This is correct behavior. The downstream code in `ReduceLagrangian` handles empty sector lists correctly. **No bug.**

---

### Issue 8: `sanitizeIndices` in Matchete Translator — Limited Scope 🔍 Low

**File**: [MatcheteXActTranslator.m](file:///d:/ORBIT/MatcheteXActTranslator.m#L59)

```wl
sanitizeIndices[idxs_] := If[MatchQ[idxs, {idx_, idx_}], {idxs[[1]], -idxs[[2]]}, idxs];
```

This only handles the exact case of two identical indices. If a Matchete expression has more complex index patterns (e.g., three identical indices), this won't catch them. Given that `h_{μν}` is rank-2, this should be sufficient for the graviton case. **Not a bug for current use.**

---

### Issue 9: `storedExpressionQ` Uses `ToExpression` ⚠️ Low

**File**: [MatcheteXActTranslator.m](file:///d:/ORBIT/MatcheteXActTranslator.m#L34)

```wl
storedExpressionQ[name_String] := Head[ToExpression[name]] =!= Symbol;
```

`ToExpression` can have side effects (e.g., evaluating the symbol). A safer approach would be `Symbol[name]` followed by checking `ValueQ`. In practice, this is called on `Global`` symbol names just loaded from `.mx` files, so it's fine. **Minor code-quality concern only.**

---

### Issue 10: `XActToMatcheteInternal` Uses Hardcoded Index Stripping 🔍 Low

**File**: [MatcheteXActTranslator.m](file:///d:/ORBIT/MatcheteXActTranslator.m#L162-L177)

The `stripMinus` function strips all sign prefixes from indices, and `replaceCD` converts covariant derivatives to a `CD[idx, val]` form. The index sign handling is somewhat coarse — it strips all minus signs regardless of whether they carry geometric meaning. For the specific use case (flat-space graviton EFT where up/down is a convention), this is acceptable.

---

### Issue 11: Missing Key `"SupportedDifference"` in Validation Test ⚠️ Medium

**File**: [validate_orbit_fixed_eh_comparison.wls](file:///d:/ORBIT/tests/validate_orbit_fixed_eh_comparison.wls#L80-L104)

Lines 80 and 101 reference `synthetic["SupportedDifference"]` and `real["SupportedDifference"]`, but looking at `CompareMatcheteToFixedEH`, the key is actually `"SupportedDifference"` (line 903 of `orbit_fixed_eh_comparison.wl`). This key **does** exist in the raw result, but after `finalizeComparisonResult` runs, the result is augmented with additional keys. The `"SupportedDifference"` key comes from the raw result and should survive the `Join` in `finalizeComparisonResult`. **Should work correctly.**

However, the test stores `synthetic["SupportedDifference"]` (line 80) and `real["SupportedDifference"]` (line 104) but never actually **checks** whether they are zero. The validation test collects data but doesn't assert pass/fail conditions. This makes it a data-collection script rather than a true validation test. **Design concern, not a bug.**

---

### Issue 12: `supportedSectorsUpTo` Hardcoded Sector List ⚠️ Low

**File**: [orbit_fixed_eh_comparison.wl](file:///d:/ORBIT/orbit_fixed_eh_comparison.wl#L131-L134)

```wl
supportedSectorsUpTo[dmax_Integer] := Sort @ Join[
  Table[{nh, 0}, {nh, 1, dmax}],
  Select[{{2, 2}, {3, 2}, {4, 2}}, Total[#] <= dmax &]
];
```

This hardcodes the derivative sectors to `{2,2}, {3,2}, {4,2}` only. Higher-derivative sectors like `{2,4}`, `{3,4}`, etc., are treated as "unsupported" even though the basis toolkit can compute them. This is intentional — the EH reference action only produces terms up to mass dimension `nh + 2` for cubic/quartic vertices — but it means the comparison workflow silently skips sectors where the EFT input might have content that the EH reference doesn't.

> [!NOTE]
> This is by design: the `{2,4}` sector is specifically handled later by `AnalyzeQuadraticFourDerivativeDifference` as a special case with curvature-squared analysis.

---

### Issue 13: `ExpandFixedEHReferenceLagrangian` Parameter Passing to `CacheDirectoryResolved` ⚠️ Low

**File**: [orbit_fixed_eh_comparison.wl](file:///d:/ORBIT/orbit_fixed_eh_comparison.wl#L717-L720)

```wl
cacheDir = CacheDirectoryResolved[
  "CacheDirectory" -> OptionValue["CacheDirectory"],
  "Verbose" -> False
];
```

`CacheDirectoryResolved` uses `OptionsPattern[RunBasisComputation]`, but here it's called with an explicit `"Verbose"` option. Since `"Verbose"` is part of `Options[RunBasisComputation]`, this works. However, any other options that `CacheDirectoryResolved` might need from the parent function are not passed. In practice, only `"CacheDirectory"` is used inside `CacheDirectoryResolved`, so this is fine. **Minor robustness concern.**

---

### Issue 14: `perturbationSeries` Flat-Space Assumption ✅ Correct

**File**: [orbit_fixed_eh_comparison.wl](file:///d:/ORBIT/orbit_fixed_eh_comparison.wl#L159-L160)

```wl
perturbationSeries[expr_, order_Integer, orderParam_] :=
  Sum[PerturbFlat[expr, i] orderParam^i/Factorial[i], {i, 1, order}];
```

Uses `PerturbFlat` which is the correct xPert function for perturbation around flat space (as opposed to `Perturbation` for curved backgrounds). The factorial normalization follows the standard Taylor expansion convention for metric perturbation `g = η + κh + ...`. **Correct.**

---

### Issue 15: `compareLog` Takes `opts_List` Not `OptionsPattern` 🔍 Style

**File**: [orbit_fixed_eh_comparison.wl](file:///d:/ORBIT/orbit_fixed_eh_comparison.wl#L111)

```wl
compareLog[msg_, opts_List] := If[TrueQ[Lookup[Association[opts], "Verbose", False]], Print[msg]];
```

This takes a raw list of options rather than using `OptionsPattern`. This is a deliberate design choice to handle the `opts` that arrive as `{opts}` from the caller. It works correctly. **Style difference, not a bug.**

---

### Issue 16: Parallel Evaluation Guard Logic ✅ Correct

**File**: [graviton_basis_toolkit.wl](file:///d:/ORBIT/graviton_basis_toolkit.wl#L198-L201)

```wl
ParallelEvaluate[
  SetDirectory[workDir];
  If[! ValueQ[RunBasisComputation], Get[toolkitFile]];
  Null
];
```

The `ValueQ[RunBasisComputation]` check prevents re-loading the toolkit on kernels that already have it. This is correct. The `SetDirectory` propagates the working directory to subkernels. **Correct.**

---

### Issue 17: `$CommuteCovDsOnScalars = True` Global Side Effect ⚠️ Low

**File**: [graviton_basis_toolkit.wl](file:///d:/ORBIT/graviton_basis_toolkit.wl#L20)

Loading the toolkit sets a global xAct variable `$CommuteCovDsOnScalars = True`. This is necessary for correct operation (derivative sorting is essential for canonical forms), but it could affect other xAct computations in the same session that rely on non-commuting scalar derivatives (e.g., curved-space calculations). **Documented behavior, but worth noting for users who load the toolkit alongside curved-space xAct code.**

---

## Part III: Summary Table

| # | Category | Severity | File | Description |
|---|----------|----------|------|-------------|
| 1 | Code | ⚠️ Medium | Example scripts | `termCount` returns wrong value for single-term expressions |
| 2 | Code | 🔍 Low | `graviton_basis_toolkit.wl` | `ProjectModuloIBP` derivative-free branch needs comment |
| 3 | Code | ⚠️ Medium | `graviton_basis_toolkit.wl` | `TermSectorKey` fragile on non-expanded input |
| 5 | Code | 🔍 Low | `graviton_basis_toolkit.wl` | No error handling on `LinearSolve` at pivot columns |
| 11 | Code | ⚠️ Medium | Validation test | Test collects data but asserts no pass/fail conditions |
| 12 | Design | 🔍 Low | `orbit_fixed_eh_comparison.wl` | Hardcoded supported sectors list |
| 17 | Design | 🔍 Low | `graviton_basis_toolkit.wl` | Global `$CommuteCovDsOnScalars` side effect |

---

## Part IV: Overall Assessment

### Physics & Mathematics: ✅ Sound

The package correctly implements:
- Flat-space graviton operator basis construction in 4D
- IBP quotient via the Euler operator criterion (mathematically exact)
- Linearized Fierz–Pauli field-redefinition image quotient (correct for the stated scope)
- EH reference expansion via xPert perturbation theory
- Canonical normalization via quadratic-sector matching
- Curvature-squared projection for the `{2,4}` completion analysis

The mathematical framework is clean and the documentation (especially `graviton_basis_toolkit_mathematical_background.md`) provides an accurate and honest account of what the code does and does not do.

### Code Quality: ✅ Good with Minor Issues

The code is well-organized, extensively commented, and follows consistent conventions. The main package file (`graviton_basis_toolkit.wl`) is essentially bug-free. The issues found are:
- A real but non-critical `termCount` bug in example scripts (not in the package itself)
- Some missing defensive checks
- Validation tests that don't assert outcomes

No issues would produce **incorrect physical results** when the package is used as documented.
