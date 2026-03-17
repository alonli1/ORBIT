# ORBIT_BUILD Context

## Objective and Current Scope
- Current objective: build an ORBIT-owned workflow that translates a Matchete `.mx` dump to xAct syntax, normalizes the finite part, reduces it modulo IBP and the existing ORBIT field-redefinition quotient, constructs a fixed Einstein-Hilbert plus cosmological-constant reference through mass dimension 6, compares both in the same reduced basis, solves for Matchete-side parameter constraints, and emits a paper-style report.
- Current concrete target input: `LEFT_only_uv_2_eft_6.mx`.
- Current comparison scope: EH plus cosmological constant only. Supported sectors are `{1,0}` through `{6,0}` and `{2,2}`, `{3,2}`, `{4,2}`. All other surviving sectors must be reported as non-EH leftovers.

## Fixed Conventions and Decisions
- Branch to work on: `ORBIT_BUILD`.
- Start from the current dirty ORBIT workspace, not from a clean `main`.
- The canonical kinetic sign is now an explicit user-facing comparison convention. It is controlled by `CanonicalKineticSign`; it is no longer inferred from `EHSign`.
- Free Matchete-side parameters to solve for: `M`, `\[Mu]bar2`, `\[Kappa]`.
- Normalization rules before comparison: `hbar -> 1`, and all terms containing negative powers of `\[Epsilon]` are dropped.
- The existing ORBIT reduction convention remains unchanged: quadratic sectors are reduced modulo IBP only; interaction sectors use IBP plus the current Fierz-Pauli field-redefinition quotient.
- This file is the persistent source of truth for the ORBIT_BUILD effort and must be updated after every substantive implementation or validation milestone.

## Current Branch and Latest Relevant Commit
- Current branch: `ORBIT_BUILD`.
- Latest committed milestones:
  - `f61216b` (`Ignore transient vendor and cache folders`)
  - `1071099` (`Finalize ORBIT_BUILD d5 comparison and reporting`)
- Branch point / latest committed snapshot before ORBIT_BUILD changes: `2d109af` (`New run - dim 2 UV and dim 6 EFT from matchete`).
- Current working tree status: repository reorganization in progress; files have been grouped into `docs/`, `artifacts/`, `cache/`, and `scripts/debug/` and still need to be staged as renames/moves.

## Implemented Components and Current Status
- The canonical-normalization layer now supports an explicit user-selected kinetic target sign through `CanonicalKineticSign`. `Automatic` now defaults to `+1`; it no longer silently follows `EHSign`.
- Final lightweight comparison milestone completed at `dmax = 5` using
  - `EHSign -> -1`,
  - `CanonicalNormalizeInput -> True`,
  - `CanonicalKineticSign -> -1`,
  - symbolic `LambdaRefFinal` and `KappaRefFinal`.
- The saved final `d <= 5` result is now
  - `ExactMatchQ -> True`,
  - `UnsupportedSectors -> {}`,
  - `HasSolution -> True`.
- The saved solution branches reduce to the invariant conditions
  - `\[Mu]bar2 > 0`,
  - `M^2 = E^(3/2) \[Mu]bar2`,
  - `LambdaRefFinal = 0`,
  - `KappaRefFinal^2 = 48 / M^2`,
  - `Sign[KappaRefFinal] = Sign[\[Kappa]]`.
- A clean final paper-style report for the `d <= 5` stopping point has been written manually from the saved result and compiled successfully to PDF.
- The fixed-reference builder and comparison API now support an explicit `EHSign` option. The reference action is
  `\Lambda_ref Sqrt[-g] + EHSign * (2/\kappa_ref^2) Sqrt[-g] R`, and the reference cache key now includes this sign.
- Dimension-5 comparison with symbolic `\Lambda_ref`, symbolic `\kappa_ref`, and `EHSign -> -1` has now been checked in two modes:
  - without canonical normalization: exact supported-sector match (`ExactMatchQ -> True`, `UnsupportedSectors -> {}`) with solution branch `\Lambda_ref -> 0`, `\log(\[Mu]bar2/M^2) -> -3/2`, `M^2 \kappa^2 -> 48`, and `\kappa_ref -> \kappa`;
  - with the current ORBIT canonical-normalization step enabled: still no exact match, because the normalization sends the quadratic sector to `+L_FP` while the `EHSign -> -1` reference has quadratic sector `-L_FP`.
- The xAct metric signature is now explicit mostly-minus in both the ORBIT core setup and the reference setup: `DefMetric[{1,3,0}, ...]`.
- Canonical-normalization check for the Matchete input has been performed explicitly in the `{2,2}` sector. The quadratic derivative term is
  `Z_h L_FP` with `Z_h = M^2 \[Kappa]^2 (1 + Log[\[Mu]bar2/M^2]) / 24`.
- This means the correct canonical field rescaling is `h -> h / Sqrt[Z_h]` before comparing higher-point sectors under the convention `g = \[Eta] + \[Kappa] h`.
- The generic automatic factor-extraction helper has now been fixed. The remaining issue is solver complexity: once the canonical rescaling is included, the full symbolic `Solve` path becomes very slow.
- Analytical consequence of canonical normalization under the explicit mostly-minus / `g = \[Eta] + \[Kappa] h` convention: the rescaled equations imply `Log[\[Mu]bar2/M^2] = -3/2` and `\Lambda_ref = 0`, so `Z_h = - M^2 \[Kappa]^2 / 48`. Therefore the Matchete kinetic term has the wrong sign for a real canonically normalized spin-2 field; a real canonical normalization does not exist in this branch.
- Dimension-5 comparison with symbolic reference coefficients: implemented and run. The solver now includes `\Lambda_ref` and `\kappa_ref` as solve variables when they are passed symbolically. Current `dmax = 5` result with symbolic `LambdaRefSolve` and `KappaRefSolve` is still `ExactMatchQ -> False`, `UnsupportedSectors -> {}`, `HasSolution -> False`.
- Symbolic-reference implication from the `d=5` equations: the system drives `\Lambda_ref -> 0` and `\log(\[Mu]bar2/M^2) -> -3/2`, but then the quadratic derivative equations require `M^2 \kappa^2 = -48`, so no real solution exists.
- Dimension-5 fixed-EH comparison: rerun after correcting input truncation and finite-part extraction. Current `dmax = 5` result is a genuine mismatch with no unsupported sectors and no parameter solution: `ExactMatchQ -> False`, `UnsupportedSectors -> {}`, `HasSolution -> False`.
- Comparison/normalization fixes added after the first `d=5` attempt:
  - the compared Matchete input is now truncated to the requested mass dimension before reduction;
  - Matchete scalar wrappers on `hbar`, `\[Epsilon]`, `\[Mu]bar2`, `M`, and `\[Kappa]` are normalized consistently in the comparison layer;
  - the finite part is now extracted as the `\[Epsilon]^0` coefficient term-by-term, instead of trying to identify pole terms structurally.
- Fixed-EH comparison workflow: now runs end-to-end and produces a corrected result object, LaTeX report source, report data dump, and compiled PDF. The current comparison does not match fixed `EH + \[CapitalLambda]`.
- Comparison bug fixed: sector keys like `{2,4}` were previously fetched with `Lookup`, which treated list-valued keys incorrectly and zeroed out real sector differences. The comparison now uses key-safe association access and correctly reports unsupported sectors.
- Reducer speedups implemented:
  - `ReduceLagrangian` no longer re-canonicalizes each sector expression after the whole input has already been canonicalized and split.
  - `ExpandFixedEHReferenceLagrangian` now caches the fixed reference expansion on disk.
  - the comparison driver now checkpoints staged outputs and records per-stage timings.
- Parallel sector reduction was tested through Mathematica subkernels but is not being used in the production run. On this machine, xAct/xPerm became unstable under concurrent kernel use and produced invalid-permutation / dead-link failures.
- ORBIT-owned translator package: `MatcheteXActTranslator.m` added to the repo by vendoring the tested translator logic from `xActMatcheteDictionary`.
- ORBIT-owned comparison package: `orbit_fixed_eh_comparison.wl` added. Public functions implemented: `LoadMatcheteToXAct`, `NormalizeMatcheteFinitePart`, `ExpandFixedEHReferenceLagrangian`, `CompareMatcheteToFixedEH`, `BuildMatcheteEHReport`.
- Fixed EH reference expansion workflow: partially implemented and debugged. The xPert reference setup now works on a dedicated reference manifold and currently produces the expected main sectors `{1,0}`, `{1,2}`, `{2,0}`, `{2,2}`, `{3,0}`, `{3,2}`, `{4,0}`, `{4,2}`, `{5,0}`, `{6,0}` before reduction.
- Validation script: `validate_orbit_fixed_eh_comparison.wls` added. It now checkpoints intermediate results to `orbit_fixed_eh_validation_checkpoint.wl` so a crash does not lose all progress.
- Existing ORBIT reducer: present in `graviton_basis_toolkit.wl`; already validated on `LEFT_only_uv_2_eft_6_xact.wl`.
- Existing translated input: `LEFT_only_uv_2_eft_6_xact.wl` already exists and reduces successfully with the current toolkit.
- Existing external translator source: `C:\Users\alonlif2000\Desktop\xActMatcheteDictionary\MatcheteXActTranslator.m`.
- Comparison solver and report generator: implemented and validated end-to-end for the current fixed-EH run, with one caveat: `Solve` / `Reduce` do not currently solve the supported-sector matching system in closed form.

## Pending Work and Next Concrete Step
- The main remaining deferred task is the full `d <= 6` rerun in the final chosen convention. It was intentionally not executed in this pass because the symbolic runtime and RAM cost are too high for a routine iteration.
- Immediate housekeeping step: finish staging the repository reorganization and commit the new grouped layout.

## Artifact Inventory
- Root source/package entry points:
  - `graviton_basis_toolkit.wl`
  - `orbit_fixed_eh_comparison.wl`
  - `MatcheteXActTranslator.m`
  - `README.md`
  - `ORBIT_BUILD_CONTEXT.md`
- Root build/run drivers:
  - `run_orbit_fixed_eh_comparison*.wls`
  - `run_left_only_uv_2_eft_6_reduction.wls`
  - `reduce_left_only_uv_2_eft_6_by_sector.wls`
  - `build_graviton_basis_*.wls`
  - `build_ai_physics_research_presentation.*`
- Documentation tree:
  - `docs/reference/`
  - `docs/graviton_basis/`
  - `docs/presentations/`
- Saved run artifacts:
  - `artifacts/orbit_fixed_eh/`
  - `artifacts/left_only_uv_2_eft_6/`
  - `artifacts/debug/`
- Cached Mathematica/xAct data:
  - `cache/`
- Scratch/debug scripts:
  - `scripts/debug/`

## Known Issues / Blockers
- The original ambiguity between `EHSign` and the canonical kinetic sign is now resolved in code, but older intermediate artifacts from before that change remain in the workspace.
- After canonical normalization, the symbolic solve becomes the bottleneck. The equations themselves are manageable analytically, but the current generic `Solve` path can stall for a long time.
- The full `d <= 6` comparison in the final chosen convention has not yet been rerun, so the status of the `{2,4}` obstruction under the final sign conventions remains deferred.
- Mathematica subkernel parallelization is not reliable here for xAct-heavy sector reductions; test runs produced `xPerm` invalid-permutation or dead-link failures under concurrent kernel use.
- The fixed-EH comparison report currently includes very long verbatim equation / expression blocks, so the PDF has several large overfull boxes even though it compiles successfully.
- The validation summary file still contains stale `$Failed[...]` placeholders for the real-run fields from an earlier interrupted validation path; the comparison PDF therefore needs a cleanup pass if it is meant to be polished.
- `ToCanonical::noident` warnings still appear on scalar symbols like `hbar` and `\[Kappa]` in some driver/report paths. They are non-fatal but noisy.
- The repository still includes many debug and intermediate files, but they are now grouped under `artifacts/debug/` and `scripts/debug/` instead of being mixed into the root.

## Chronological Session Log
- 2026-03-17: Reorganized the repository layout. Generated reports and notebooks were moved under `docs/`, saved run outputs under `artifacts/`, caches under `cache/`, and scratch scripts under `scripts/debug/`.
- 2026-03-17: Changed `CanonicalKineticSign` so it is a true explicit user-controlled convention. `Automatic` now defaults to `+1` instead of inheriting `EHSign`.
- 2026-03-17: Ran the final lightweight stopping-point comparison at `d <= 5` with `EHSign -> -1` and `CanonicalKineticSign -> -1`. The saved result now gives `ExactMatchQ -> True`, `UnsupportedSectors -> {}`, and `HasSolution -> True`.
- 2026-03-17: Extracted the stable solved constraints from `orbit_fixed_eh_comparison_d5_final_result.wl` and wrote a clean final paper-style report directly from those saved artifacts.
- 2026-03-17: Compiled `orbit_fixed_eh_comparison_d5_final_report.pdf`. The expensive `d <= 6` rerun was intentionally deferred.
- 2026-03-15: Added an explicit `EHSign` option to the fixed-reference builder, comparison API, reference cache key, and report text in `orbit_fixed_eh_comparison.wl`.
- 2026-03-15: Reran the dimension-5 symbolic-reference comparison with `EHSign -> -1` and no canonical normalization. This now gives an exact supported-sector match with `\Lambda_ref = 0`, `\log(\[Mu]bar2/M^2) = -3/2`, `M^2 \kappa^2 = 48`, and `\kappa_ref = \kappa`.
- 2026-03-15: Reran the same `EHSign -> -1` branch with canonical normalization enabled. It still fails, because the current ORBIT canonical step always normalizes the quadratic sector to `+L_FP`, whereas the sign-flipped EH reference has quadratic sector `-L_FP`.
- 2026-03-14: Made the metric signature explicit as mostly-minus in the ORBIT and reference xAct setups.
- 2026-03-14: Verified directly that the Matchete `{2,2}` sector is exactly proportional to the toolkit Fierz-Pauli kinetic term, with proportionality factor `Z_h = M^2 \[Kappa]^2 (1 + Log[\[Mu]bar2/M^2]) / 24`. This identifies the required canonical field rescaling.
- 2026-03-14: Fixed the canonical-normalization extractor bug. The next full rerun with canonical normalization reached the checkpoint stage but then bogged down in the symbolic solve.
- 2026-03-14: Solved the canonically normalized `d=5` conditions analytically instead: the zero-derivative sectors force `Log[\[Mu]bar2/M^2] = -3/2` and `\Lambda_ref = 0`, which in turn makes the kinetic normalization factor negative, `Z_h = - M^2 \[Kappa]^2 / 48`. So there is no real canonical normalization of the Matchete kinetic term in this branch.
- 2026-03-14: Extended the solver so symbolic reference coefficients are included automatically in the solve-variable list when `LambdaReferenceValue` / `KappaReferenceValue` are passed as symbols.
- 2026-03-14: Ran the `d=5` comparison with symbolic `LambdaRefSolve` and `KappaRefSolve`. The result remained a mismatch with no real solution. Inspecting the equations shows that the system forces a vanishing reference cosmological constant and `Log[\[Mu]bar2/M^2] = -3/2`, but then demands `M^2 \kappa^2 = -48`, which rules out a real match.
- 2026-03-14: Investigated the user concern about fixed reference coefficients by restricting the comparison to mass dimension 5. The first `d=5` attempt exposed two additional bugs: the input was not truncated to the requested mass dimension before reduction, and the finite-part normalization was not handling Matchete `Scalar[...]` wrappers robustly.
- 2026-03-14: Fixed the `d=5` issues by truncating the compared input before reduction, normalizing wrapped scalar parameters consistently, and replacing the pole-filter heuristic with explicit extraction of the `\[Epsilon]^0` coefficient term by term.
- 2026-03-14: Reran the dimension-5 comparison and obtained the corrected result: `ExactMatchQ -> False`, `UnsupportedSectors -> {}`, `HasSolution -> False`. The mismatch therefore already exists within the supported sectors below dimension 6.
- 2026-03-14: Identified the main comparison bug: `Lookup` was being used on association keys of the form `{nh, Nd}`, which silently misread sector data such as `{2,4}` and produced a false exact-match result.
- 2026-03-14: Fixed the comparison key lookup, reran the full fixed-EH comparison, and confirmed the corrected outcome: `ExactMatchQ -> False`, `UnsupportedSectors -> {{2,4}}`, no projection failures, and no solved supported-sector parameter constraints.
- 2026-03-14: Added stable performance improvements: removed redundant sector canonicalization inside `ReduceLagrangian`, added disk caching for the fixed EH reference expansion, and recorded per-stage timings in the driver output.
- 2026-03-14: Measured the current staged run timings: translation `310.4 s`, normalization `306.5 s`, reference expansion `1466.9 s`, input reduction `1608.5 s`, reference reduction `675.8 s`, comparison assembly `546.6 s`, report build `0.46 s`.
- 2026-03-14: Tested Mathematica subkernel parallelization for sector reduction; it was not stable with xAct/xPerm on this machine, so the production driver was returned to the optimized sequential path.
- 2026-03-14: Refreshed the final comparison result from the saved reductions after fixing solver-status handling, and compiled `orbit_fixed_eh_comparison_report.pdf`.
- 2026-03-13: Created checkpoint commit `e44b9bf` on `ORBIT_BUILD`.
- 2026-03-13: Added `MatcheteXActTranslator.m` to ORBIT.
- 2026-03-13: Added `orbit_fixed_eh_comparison.wl` with translation, normalization, fixed-reference expansion, comparison, solving, and report generation APIs.
- 2026-03-13: Added `validate_orbit_fixed_eh_comparison.wls` and then updated it to write intermediate checkpoints and reuse the existing `left_only_uv_2_eft_6_cache`.
- 2026-03-13: Fixed the xPert reference setup by moving it onto a dedicated reference manifold and recursively translating `CD`/`HEH` structures into the ORBIT `h`/`PD` basis.
- 2026-03-13: First full validation run was interrupted by a system crash before completion.
- 2026-03-13: Created branch `ORBIT_BUILD` from the current dirty ORBIT workspace.
- 2026-03-13: Added `ORBIT_BUILD_CONTEXT.md` and recorded the fixed scope, conventions, and starting state.
