# ORBIT_BUILD Context

## Objective and Current Scope
- Current objective: build an ORBIT-owned workflow that translates a Matchete `.mx` dump to xAct syntax, normalizes the finite part, reduces it modulo IBP and the existing ORBIT field-redefinition quotient, constructs a fixed Einstein-Hilbert plus cosmological-constant reference through mass dimension 6, compares both in the same reduced basis, solves for Matchete-side parameter constraints, and emits a paper-style report.
- Current concrete target input: `LEFT_only_uv_2_eft_6.mx`.
- Current comparison scope: EH plus cosmological constant only. Supported sectors are `{1,0}` through `{6,0}` and `{2,2}`, `{3,2}`, `{4,2}`. All other surviving sectors must be reported as non-EH leftovers.

## Fixed Conventions and Decisions
- Branch to work on: `ORBIT_BUILD`.
- Start from the current dirty ORBIT workspace, not from a clean `main`.
- Reference-theory parameters are fixed; they are not solved for.
- Free Matchete-side parameters to solve for: `M`, `\[Mu]bar2`, `\[Kappa]`.
- Normalization rules before comparison: `hbar -> 1`, and all terms containing negative powers of `\[Epsilon]` are dropped.
- The existing ORBIT reduction convention remains unchanged: quadratic sectors are reduced modulo IBP only; interaction sectors use IBP plus the current Fierz-Pauli field-redefinition quotient.
- This file is the persistent source of truth for the ORBIT_BUILD effort and must be updated after every substantive implementation or validation milestone.

## Current Branch and Latest Relevant Commit
- Current branch: `ORBIT_BUILD`.
- Branch point / latest committed snapshot before ORBIT_BUILD changes: `2d109af` (`New run - dim 2 UV and dim 6 EFT from matchete`).
- Current working tree at branch creation: dirty, with a modified `graviton_basis_toolkit.wl` and the latest `LEFT_only_uv_2_eft_6` reduction artifacts and debug files present.

## Implemented Components and Current Status
- Existing ORBIT reducer: present in `graviton_basis_toolkit.wl`; already validated on `LEFT_only_uv_2_eft_6_xact.wl`.
- Existing translated input: `LEFT_only_uv_2_eft_6_xact.wl` already exists and reduces successfully with the current toolkit.
- Existing external translator source: `C:\Users\alonlif2000\Desktop\xActMatcheteDictionary\MatcheteXActTranslator.m`.
- ORBIT-owned comparison package: not started.
- Fixed EH reference expansion workflow: not started.
- Comparison solver and report generator: not started.

## Pending Work and Next Concrete Step
- Immediate next step: checkpoint the exact dirty workspace on `ORBIT_BUILD` so the starting state is preserved before new package work begins.
- After checkpointing: vendor the translator into ORBIT and scaffold the new public API around translation, normalization, reference construction, reduction, comparison, solving, and reporting.

## Artifact Inventory
- Existing translated input: `LEFT_only_uv_2_eft_6_xact.wl`.
- Existing reduction outputs: `LEFT_only_uv_2_eft_6_xact_reduced.wl`, `LEFT_only_uv_2_eft_6_xact_reduction_summary.wl`, `LEFT_only_uv_2_eft_6_xact_reduction.mx`.
- Existing reducer driver: `reduce_left_only_uv_2_eft_6_by_sector.wls`.
- Existing ORBIT core package: `graviton_basis_toolkit.wl`.
- Existing report source: `graviton_basis_toolkit_paper_report.tex`.

## Known Issues / Blockers
- None yet for the new ORBIT_BUILD work.
- The repository includes many debug and intermediate files from the previous reduction session; these are part of the dirty workspace being checkpointed.

## Chronological Session Log
- 2026-03-13: Created branch `ORBIT_BUILD` from the current dirty ORBIT workspace.
- 2026-03-13: Added `ORBIT_BUILD_CONTEXT.md` and recorded the fixed scope, conventions, and starting state.
