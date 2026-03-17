Get["orbit_fixed_eh_comparison.wl"];
ref = ExpandFixedEHReferenceLagrangian["MaxDimension" -> 6, "Verbose" -> False];
expr = ref["ReferenceExpression"];
sectors = SplitTermsBySector[expr];
Print["sector_keys=" <> ToString[Keys[sectors], InputForm]];
Do[
  secExpr = Lookup[sectors, key, 0];
  sec = ReduceSectorLagrangian[secExpr, key[[1]], key[[2]], "CacheDirectory" -> "left_only_uv_2_eft_6_cache", "UseCache" -> True, "Verbose" -> False, "MaxDimension" -> 6];
  Print["sector=" <> ToString[key, InputForm]];
  Print["projection_ok=" <> ToString[InputForm[sec["ProjectionSucceededQ"]]]];
  Print["proj_residual_zero=" <> ToString[InputForm[sec["ProjectionResidual"] === 0]]];
  Print["proj_terms=" <> ToString[If[sec["ProjectedIBPExpression"] === 0, 0, If[Head[Expand[sec["ProjectedIBPExpression"]]] === Plus, Length[List @@ Expand[sec["ProjectedIBPExpression"]]], 1]], InputForm]];
  Print["reduced_zero=" <> ToString[InputForm[sec["ReducedExpression"] === 0]]];
, {key, {{1,2}, {2,2}, {3,2}, {4,2}}}];
Quit[];
