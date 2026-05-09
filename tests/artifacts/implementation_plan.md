# ORBIT Comprehensive Testing Plan (v2)

## Goal

Create a test suite that validates **every computation stage** in the ORBIT toolkit from input to output. Each stage is tested independently so that if a failure occurs, it is immediately localizable.

All tests will be collected in a single file: `tests/orbit_comprehensive_test.wls`

---

## Key Principle: Independent Verification

> [!IMPORTANT]
> We do **not** trust any single computation method as ground truth. Instead, each critical quantity is verified by at least one of:
> 1. **Independent xAct computation** — recompute the same result using different code paths
> 2. **Mathematical identity** — verify relationships that must hold by construction (e.g. `PhysicalCount = IBPCount - RedefRank`)
> 3. **Known analytic results** — gauge-invariant operator counts from the literature (e.g., 2 independent curvature-squared invariants mod IBP in 4D for sector {2,4})
> 4. **Redundancy tests** — expressions known to be zero must reduce to zero

---

## Stage 1: Utility Functions

Pure-function tests with known inputs and expected outputs. No xAct tensor operations needed.

### Test 1.1 — `CompositionList` against known combinatorial formula
- Verify: `Length[CompositionList[n, k]] == Binomial[n+k-1, k-1]` for all `(n,k)` with `0 ≤ n ≤ 6`, `1 ≤ k ≤ 5`
- Spot checks: `CompositionList[0, 1]` → `{{0}}`, `CompositionList[2, 2]` → `{{0,2},{1,1},{2,0}}`

### Test 1.2 — `PivotColumns` and `PivotRows`
- Identity matrix → pivot columns = `{1, 2, ..., n}`
- `{{1,0,1},{0,1,1}}` → pivot columns = `{1, 2}`
- `{{1,2,3},{2,4,6}}` → pivot columns = `{1}` (rank 1)
- Zero matrix → `{}`
- Verify: `PivotRows[m] == PivotColumns[Transpose[m]]` on several test matrices

### Test 1.3 — `LinearCombination`
- `LinearCombination[{1, 0, 0}, {a, b, c}]` → `a`
- `LinearCombination[{2, -1, 3}, {x, y, z}]` → `2x - y + 3z`

### Test 1.4 — `NormalizeSectorList`
- `NormalizeSectorList[Automatic, 3]` produces `{{1,0},{1,1},{2,0},{1,2},{2,1},{3,0}}`
- `NormalizeSectorList[{{3,2},{3,2},{1,0}}, 99]` removes duplicates → `{{3,2},{1,0}}`

### Test 1.5 — `ZeroVectorQ`
- `ZeroVectorQ[{0, 0, 0}]` → `True`
- `ZeroVectorQ[{0, 1, 0}]` → `False`
- `ZeroVectorQ[{}]` → `True`

### Test 1.6 — `SplitTermsBySector`
- `SplitTermsBySector[0]` → empty Association
- Construct a known two-sector expression and verify it splits into exactly 2 keys

### Test 1.7 — `PrettyKey`
- `PrettyKey[<|"nh" -> 3, "Nd" -> 2|>]` → `"nh_3__Nd_2"`

### Test 1.8 — `SafeSolveConstants`
- `SafeSolveConstants[0 == 0]` should return `{{}}` (not `{}`)
- Result is always a list of lists

---

## Stage 2: Raw Basis Generation

### Test 2.1 — Odd-derivative sectors are empty
- `RawScalarBasis[2, 1]` → `{}`
- `RawScalarBasis[3, 3]` → `{}`
- `RawScalarBasis[1, 1]` → `{}`

### Test 2.2 — Basis elements are canonical and deduplicated
- For sectors `{2,2}` and `{3,2}`:
  - Each element `b` satisfies `canonExpr[b] === b`
  - `Length[canonList[basis]] == Length[basis]` (no hidden duplicates)

### Test 2.3 — Raw basis elements are true scalars
- For each element in `RawScalarBasis[2, 2]` and `RawScalarBasis[3, 2]`:
  - `FreeQ[expr, h[__]] || satisfies full contraction` — verify no free indices remain after construction
  - Simpler check: `VarD[probe[-u,-v], PD][expr] === 0` for a probe tensor (scalar has no rank-2 content)

### Test 2.4 — Independent raw count verification via direct contraction counting
- Independently count `RawCount` by:
  1. For each composition in `CompositionList[Nd, nh]`, build the monomial with `ScalarMonomialFromPartition`
  2. Flatten `AllContractions` and count independent canonical forms
- Verify: this independent count matches `Length[RawScalarBasis[nh, Nd]]`
- **Test on {2,2} and {3,2}**

### Test 2.5 — `Rank2Basis` odd-derivative sectors are empty
- `Rank2Basis[1, 1]` → `{}`
- `Rank2Basis[2, 1]` → `{}`

---

## Stage 3: IBP Quotient

### Test 3.1 — Independent IBP count via direct Euler operator kernel
This is the critical independent verification. For sectors `{2,2}` and `{3,2}`:
1. Get the raw basis: `raw = RawScalarBasis[nh, Nd]`
2. **Independent method**: For each raw basis element `O_i`, compute the Euler-Lagrange derivative `VarD[h[-m,-n], PD][O_i]` and express it as a matrix of tensor equations. The dimension of the kernel of this map = number of IBP relations = `RawCount - IBPCount`.
3. Specifically: build `ans = MakeAnsatz[raw, ConstantPrefix -> t]`, solve `VarD[h[-m,-n], PD][ans] == 0` using `SolveConstants` directly (not through `IBPData`), count free parameters.
4. Verify: `IBPCount == RawCount - numberOfFreeParameters`

### Test 3.2 — IBP relation expressions are total derivatives (Euler operator test)
- For each relation vector `r` in `IBPRelationMatrix`:
  - Form `L = LinearCombination[r, rawBasis]`
  - Verify `canonExpr[VarD[h[-m,-n], PD][L]] === 0`
- **Test on {2,2} and {3,2}**

### Test 3.3 — IBP basis elements are linearly independent modulo IBP
- Form `ans2 = MakeAnsatz[ibpBasis, ConstantPrefix -> t]`
- Solve `VarD[h[-m,-n], PD][ans2] == 0`
- Verify: the only solution is `t_i = 0` for all `i` (no further IBP relations among basis elements)
- **Test on {2,2}**

### Test 3.4 — Empty basis gives empty IBP data
- `IBPData[{}]` → `RelationMatrix` = `{}`, `FreeParameters` = `{}`

### Test 3.5 — Known analytic result: sector {1,2}
- `{1,2}` has RawCount > 0 but IBPCount = 0
- All raw operators in this sector are total derivatives
- Verify: every raw basis element has vanishing Euler derivative (independently)

---

## Stage 4: Field-Redefinition Image

### Test 4.1 — Fierz–Pauli Lagrangian properties
- `LFP` is not zero
- `LFP` lies in sector `{2, 2}`: all terms have `TermSectorKey == {2, 2}`
- `canonExpr[LFP] === LFP` (already canonical)

### Test 4.2 — `ShiftFromRedefExpr` produces correct sector
- For `deltaExpr` in `Rank2Basis[2, 0]`, verify each shift image term has `TermSectorKey == {3, 2}`
- For `deltaExpr` in `Rank2Basis[1, 0]`, verify each shift image term has `TermSectorKey == {2, 2}`

### Test 4.3 — Redundant-image reduction to zero (key physics test)
Construct `L_test = Sum[c_i * ShiftFromRedefExpr[delta_i]]` with generic non-zero `c_i` (prime numbers), then verify:
- `ReduceSectorLagrangian[L_test, nh, Nd]["ReducedExpression"] === 0`
- `PhysicalCoordinates` are all zero
- **Test on {3,2} sector** with `Rank2Basis[2, 0]` images
- **Test on {3,4} sector** with `Rank2Basis[2, 2]` images

### Test 4.4 — Quadratic sectors have zero RedefRank
- `ComputeSectorData[2, 0]["RedefRank"] == 0`
- `ComputeSectorData[2, 2]["RedefRank"] == 0`
- `ComputeSectorData[1, 0]["RedefRank"] == 0`

### Test 4.5 — Dimension formula: `PhysicalCount = IBPCount - RedefRank`
- Verify for all computed sectors with `nh >= 3` (where redefs are applied)

### Test 4.6 — Independent redef rank verification
- For sector `{3,2}`:
  1. Get `deltaBasis = Rank2Basis[2, 0]`
  2. Compute shifts independently: `shifts = ShiftFromRedefExpr /@ deltaBasis`
  3. Project each shift to IBP basis independently using `DirectProjectToBasis`
  4. Collect coordinate vectors, compute `MatrixRank`
  5. Verify this matches `sec["RedefRank"]`

---

## Stage 5: Full Sector Assembly (`ComputeSectorData`)

### Test 5.1 — Internal consistency for D ≤ 5
Compute `RunBasisComputation["MaxDimension" -> 5]` and for every sector verify:
- `Length[sec["RawBasis"]] == sec["RawCount"]`
- `Length[sec["IBPBasis"]] == sec["IBPCount"]`
- `Length[sec["PhysicalBasis"]] == sec["PhysicalCount"]`
- `sec["PhysicalCount"] == sec["IBPCount"] - sec["RedefRank"]` (for `nh >= 3`)
- `sec["PhysicalCount"] == sec["IBPCount"]` (for `nh < 3`, no redef quotient)
- `sec["Dimension"] == sec["nh"] + sec["Nd"]`

### Test 5.2 — Cross-verify {2,4} sector against known gauge-invariant count
- In the `{2,4}` sector, the gauge-invariant (linearized diffeomorphism-invariant) subspace is spanned by `R^2` and `R_{μν}R^{μν}` (two independent operators after using the 4D Gauss–Bonnet relation).
- The IBP quotient should be **larger** than 2 (since it includes gauge-variant operators)
- Verify: `IBPCount >= 2` and the curvature-squared projections from `curvatureSquaredProjectionData` have rank 2 inside the IBP basis

### Test 5.3 — Sector data keys are complete
- Every sector Association must contain all expected keys:
  `"nh", "Nd", "Dimension", "RawBasis", "RawCount", "IBPBasis", "IBPCount", "IBPPivots", "IBPRelationMatrix", "RedefRank", "RedefPivots", "PhysicalBasis", "PhysicalCount", "RedefinitionRules"`

### Test 5.4 — Caching round-trip
- Compute a sector with caching enabled
- Reload from cache (call `LoadOrCompute` with same key)
- All numerical fields match the original

---

## Stage 6: Lagrangian Reduction

### Test 6.1 — Physical basis element is a fixed point of reduction
- Pick physical basis element `b` from sector `{3,2}`
- `ReduceSectorLagrangian[b, 3, 2]` returns:
  - `ReducedExpression` canonically equal to `b`
  - `PhysicalCoordinates` = corresponding unit vector
  - `ProjectionSucceededQ` = True

### Test 6.2 — Zero input reduces to zero
- `ReduceSectorLagrangian[0, 3, 2]["ReducedExpression"] === 0`

### Test 6.3 — IBP-trivial expression reduces to zero
- Take a relation expression from `IBPRelationExpressions` in sector `{3,2}`
- `ReduceSectorLagrangian[relExpr, 3, 2]["ReducedExpression"] === 0`

### Test 6.4 — Redef-image expression reduces to zero
(Same as Test 4.3 but through the Lagrangian API)

### Test 6.5 — Mixed expression decomposes correctly
- Construct: `L = c1*phys + c2*ibpTrivial + c3*redefImage` with known `c1, c2, c3`
- Verify: `ReducedExpression == canonExpr[c1*phys]`
- This is the **worked example** test from the paper report

### Test 6.6 — `ReduceLagrangian` multi-sector split
- Construct `L = expr_{1,0} + expr_{2,2} + expr_{3,2}` from known physical basis elements
- `ReduceLagrangian[L]` should:
  - Have sector keys `{1,0}`, `{2,2}`, `{3,2}` in `SectorReductions`
  - Reconstruct each component correctly

### Test 6.7 — Idempotency
- For a test Lagrangian `L`:
  - `red1 = ReduceLagrangian[L]["ReducedExpression"]`
  - `red2 = ReduceLagrangian[red1]["ReducedExpression"]`
  - Verify: `canonExpr[red2 - red1] === 0`

### Test 6.8 — Projection residual is zero for valid sector expressions
- For any expression that genuinely lies in the sector's span:
  - `ProjectionSucceededQ` should be True
  - `ProjectionResidual` should be 0

---

## Stage 7: Matchete–xAct Translator

> Tests in this stage run only if the `.mx` file exists. Otherwise they are skipped with a warning.

### Test 7.1 — `sanitizeIndices` correctness
- `sanitizeIndices[{a, a}]` → `{a, -a}`
- `sanitizeIndices[{a, b}]` → `{a, b}` (unchanged)

### Test 7.2 — `stripMinus`
- `stripMinus[-a]` → `a`
- `stripMinus[a]` → `a`

### Test 7.3 — `LoadMatcheteMXExpression` round-trip (if `.mx` file exists)
- Load the expression
- Verify it is not `$Failed`
- Verify no Matchete-context symbols remain in the translated output

### Test 7.4 — `NormalizeMatcheteFinitePart` properties (if `.mx` file exists)
- Normalized expression has no `hbar` symbols
- Normalized expression has no negative powers of `ε`
- Normalized expression is nonzero

### Test 7.5 — Translation matches stored baseline (if baseline exists)
- Load the `.mx`, translate, compare to stored `LEFT_only_uv_2_eft_6_xact.wl`
- Difference should be zero

---

## Stage 8: EH Comparison Workflow

### Test 8.1 — `ExpandFixedEHReferenceLagrangian` basic properties
- Output has key `"ReferenceExpression"` which is nonzero
- Sector breakdown contains `{1,0}`, `{2,0}`, `{2,2}` (at D≤4 minimum)

### Test 8.2 — Reference self-comparison (synthetic test)
- `CompareMatcheteToFixedEH[referenceExpr, ...]` comparing the reference to itself
- Should yield `ExactMatchQ → True`
- This is the strongest end-to-end test: if the full pipeline works on the reference itself, the reduction + comparison + solving machinery is consistent

### Test 8.3 — Linearized curvature squared projections
- `linRicciScalarExpr[]^2` and `R_{μν}R^{μν}` projected to IBP basis in `{2,4}` should have:
  - Non-zero coordinates
  - Two linearly independent coordinate vectors (verifies the curvature-squared basis is 2D as expected from Gauss–Bonnet in 4D)

### Test 8.4 — Canonical normalization factor extraction
- Take `α * LFP` for a known rational `α`
- Reduce it, then call `kineticNormalizationDataFromReduction`
- Verify `Factor → α` and `SucceededQ → True`

### Test 8.5 — `AnalyzeQuadraticFourDerivativeDifference` on known curvature-squared input
- Construct `c1 * R^{(1)2} + c2 * R_{μν}R^{μν}` in sector `{2,4}` for known rational `c1`, `c2`
- Project to the IBP basis
- Run the analyzer
- Verify: `CurvatureCoefficients` returns values consistent with `c1`, `c2`
- Verify: `ResidualIsZeroQ → True`

---

## Implementation Details

### Test Harness

```wl
$testCount = 0;
$failCount = 0;
$passCount = 0;
$skipCount = 0;
$failures = {};

assert[label_String, condition_] := (
  $testCount++;
  If[TrueQ[condition],
    $passCount++;
    Print["  PASS: " <> label],
    $failCount++;
    AppendTo[$failures, label];
    Print["  FAIL: " <> label]
  ]
);

skip[label_String, reason_String] := (
  $testCount++;
  $skipCount++;
  Print["  SKIP: " <> label <> " (" <> reason <> ")"]
);

(* At bottom *)
Print["\n=== RESULTS ==="];
Print[ToString[$passCount] <> " passed, " <> ToString[$failCount] <> " failed, " <> ToString[$skipCount] <> " skipped out of " <> ToString[$testCount]];
If[$failCount > 0,
  Print["FAILURES:"];
  Print["  - " <> # & /@ $failures];
  Exit[1],
  Print["All tests passed."]
];
```

### Test Options

```wl
$testCacheDir = FileNameJoin[{Directory[], "cache", "orbit_test_cache_" <> ToString[$ProcessID]}];
$testOpts = {
  "CacheDirectory" -> $testCacheDir,
  "UseCache" -> True,
  "ForceRecompute" -> False,
  "Verbose" -> False
};
```

### Cleanup

Temporary cache is deleted on completion.

---

## Proposed Changes

### [NEW] [orbit_comprehensive_test.wls](file:///d:/ORBIT/tests/orbit_comprehensive_test.wls)

Single comprehensive test script implementing all 8 stages (~45 individual test assertions).

---

## Verification Plan

### Automated Tests
- Run `wolframscript -file tests/orbit_comprehensive_test.wls` from the repo root
- Exit code 0 = all pass, exit code 1 = failures
- All PASS/FAIL/SKIP results printed to stdout

### Independent Verification Strategy

The test avoids circular trust by using these independently computed cross-checks:

| What is verified | How it is independently verified |
|---|---|
| Raw basis count | Recompute from `CompositionList → ScalarMonomialFromPartition → AllContractions → canonList` bypassing `RawScalarBasis` |
| IBP count | Independently solve `VarD[h[-m,-n], PD][MakeAnsatz[raw]] == 0` with `SolveConstants` directly, count free params |
| Redef rank | Independently project shift images with `DirectProjectToBasis`, collect vectors, compute `MatrixRank` |
| Curvature-squared count in {2,4} | Analytically known to be 2 in 4D (from Gauss–Bonnet: 3 curvature squares minus 1 GB relation) |
| Reduction correctness | Redundant-image-to-zero test (constructed expressions known to be zero by Eq. of Motion identity) |
| IBP relations validity | Each relation expression independently verified via `VarD == 0` |
| Full pipeline | Reference self-comparison returns `ExactMatchQ → True` |
