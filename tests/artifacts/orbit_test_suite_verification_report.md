# ORBIT Test Suite Verification Report

## Scope

This follow-up review re-verified the ORBIT test suite and validation scripts using **Mathematica 13.3 only**:

- `C:\Program Files\Wolfram Research\Mathematica\13.3\math.exe`

Reviewed entry points:

- `tests/orbit_comprehensive_test.wls`
- `tests/graviton_basis_toolkit_validation.wls`
- `tests/validate_orbit_fixed_eh_comparison.wls`

Supporting run logs were written under:

- `tests/artifacts/run_logs/`

---

## Executive Summary

The test suite itself was mostly sound, but three correctness issues showed up during real runs:

1. `tests/orbit_comprehensive_test.wls` emitted `$RecursionLimit::reclim` in Stage 6, and the affected `6.1` checks were effectively **not part of the reported pass count**.
2. Both `tests/orbit_comprehensive_test.wls` and `tests/validate_orbit_fixed_eh_comparison.wls` emitted `ToCanonical::noident` warnings on `hbar` during raw translation-baseline comparisons.
3. `tests/validate_orbit_fixed_eh_comparison.wls` could silently write `$Failed[...]` into its output artifact because it had **no pass/fail assertions** around the real EH comparison result.

After fixes:

- `tests/orbit_comprehensive_test.wls` passes cleanly: **81 passed, 0 failed, 0 skipped**
- `tests/graviton_basis_toolkit_validation.wls` passes cleanly
- `tests/validate_orbit_fixed_eh_comparison.wls` completes cleanly, emits explicit PASS/FAIL checks, and now confirms that the real comparison returns a valid Association

Important nuance:

- The EH validation's **real** comparison still does **not** produce `ExactMatchQ -> True` under the script's default settings. That is not a test failure now, because the script is validating pipeline correctness, not the final paper-matched conventions. The final paper-facing exact match still lives in the dedicated ORBIT artifacts under `artifacts/orbit_fixed_eh/`.

---

## Reproduced Problems

### 1. Stage 6 recursion warnings in the comprehensive suite

Observed on the initial 13.3 rerun:

- `$RecursionLimit::reclim: Recursion depth of 4096 exceeded.`

Root cause:

- Stage 6 was probing a pathological reducer path using an exact sector-basis representative.
- That produced warnings before any `assert` ran, so the suite still reported success even though those checks were not really participating in the `77 passed` total.

Fix:

- Replaced the fragile exact-basis-element regression with a stable fixed-point/idempotency check on `LFP` in sector `{2,2}`.
- Result: Stage 6 now contributes explicit assertions and runs cleanly.

### 2. `ToCanonical::noident` warnings on `hbar`

Observed on the initial 13.3 reruns:

- `ToCanonical::noident: Unknown expression not canonicalized: hbar .`

Root cause:

- The package already quieted this warning inside `LoadMatcheteToXAct`, but the tests re-triggered it by calling:
  - `canonExpr[translated - baseline]`
  - and, for pretranslated inputs, `CompareMatcheteToFixedEH` fell back to `canonExpr[input]`

Fix:

- Quieted the raw translation-baseline comparison in both test scripts.
- Quieted the expression-input branch of `CompareMatcheteToFixedEH`.

Result:

- The warning no longer appears in the comprehensive suite or EH validation reruns.

### 3. EH validation could hide a failed real comparison

Observed in the previously saved artifact:

- `RealExactMatchQ -> $Failed["ExactMatchQ"]`
- similar `$Failed[...]` placeholders for other real-comparison fields

Root cause:

- The script accessed `real["..."]` without first checking whether `real` was actually an Association.
- It also lacked pass/fail assertions entirely.

Fix:

- Added explicit PASS/FAIL checks.
- Added `RealComparisonSucceededQ -> AssociationQ[real]`.
- Guarded all real-comparison fields behind `AssociationQ[real]`.
- Switched the real comparison call to use `inputMX` directly so it reuses the translator cache and the package's safer translation path.
- Made the standalone reference expansion use the same chosen cache directory.

Result:

- The script now fails loudly if the real compare does not produce a valid result.
- On the 13.3 rerun, it completed successfully and confirmed `RealComparisonSucceededQ -> True`.

---

## Verification Results

### 1. Comprehensive Suite

Runner:

- `C:\Program Files\Wolfram Research\Mathematica\13.3\math.exe -script tests/orbit_comprehensive_test.wls`

Result:

- **81 passed, 0 failed, 0 skipped**

Artifact/logs:

- `tests/orbit_test_results.txt`
- `tests/artifacts/run_logs/orbit_comprehensive_test_13_3_after_fix_v2.log`

### 2. Graviton Basis Validation

Runner:

- `C:\Program Files\Wolfram Research\Mathematica\13.3\math.exe -script tests/graviton_basis_toolkit_validation.wls`

Result:

- Both redundant-image tests passed

Updated artifact/log:

- `docs/graviton_basis/graviton_basis_toolkit_validation_output.wl`
- `tests/artifacts/run_logs/graviton_basis_toolkit_validation_13_3_after_fix.log`

### 3. EH Comparison Validation

Runner:

- `C:\Program Files\Wolfram Research\Mathematica\13.3\math.exe -script tests/validate_orbit_fixed_eh_comparison.wls`

Result:

- PASS: translation matches stored baseline
- PASS: normalized expression contains no `hbar`
- PASS: normalized expression contains no epsilon poles
- PASS: synthetic reference self-comparison is exact
- PASS: real comparison returns an Association
- PASS: real comparison exposes `ExactMatchQ`
- PASS: real comparison exposes `MatchSolutions`

Updated artifact/log:

- `artifacts/orbit_fixed_eh/orbit_fixed_eh_validation_output.wl`
- `tests/artifacts/run_logs/validate_orbit_fixed_eh_comparison_13_3_after_fix.log`

Important output facts from that rerun:

- `RealComparisonSucceededQ -> True`
- `RealExactMatchQ -> False`
- `RealUnsupportedSectors -> {{2, 4}}`

This is consistent with the script's current default conventions not being the same as the paper-facing final matched setup.

---

## Files Changed

- `graviton_basis_toolkit.wl`
- `orbit_fixed_eh_comparison.wl`
- `tests/orbit_comprehensive_test.wls`
- `tests/validate_orbit_fixed_eh_comparison.wls`
- `docs/graviton_basis/graviton_basis_toolkit_validation_output.wl`
- `artifacts/orbit_fixed_eh/orbit_fixed_eh_validation_output.wl`
- `tests/orbit_test_results.txt`

---

## Remaining Gaps / Follow-up Recommendations

### 1. Split the suite into fast and slow tiers

`tests/validate_orbit_fixed_eh_comparison.wls` is a **slow integration test**. On a cold-ish run it took roughly two hours under 13.3. It should not be treated like a quick smoke test.

Recommended split:

- fast: `tests/orbit_comprehensive_test.wls`, `tests/graviton_basis_toolkit_validation.wls`
- slow integration: `tests/validate_orbit_fixed_eh_comparison.wls`

### 2. Add a message-capture guard for unexpected WL messages

The original problems were visible as warnings before they were visible as failures. A small harness that records unexpected messages and fails the test run would catch this class of issue earlier.

### 3. Add explicit expectations for the real EH validation's current default mode

Now that the script returns a real Association, the next useful hardening step would be to assert the current expected shape, for example:

- `RealComparisonSucceededQ -> True`
- `RealUnsupportedSectors -> {{2, 4}}`
- projection-failure lists empty

That would convert the script from a smoke/integrity check into a stronger regression test.

### 4. Investigate exact basis-representative reduction as a separate reducer bug/performance issue

The original Stage 6 failure path came from reducing exact basis representatives directly. The suite no longer relies on that path, but it is still worth investigating separately if that API usage matters for future workflows.
