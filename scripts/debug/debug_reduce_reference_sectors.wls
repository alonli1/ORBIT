Get["orbit_fixed_eh_comparison.wl"];
ref = ExpandFixedEHReferenceLagrangian["MaxDimension" -> 6, "Verbose" -> False];
expr = ref["ReferenceExpression"];
Do[
  secExpr = Lookup[SplitTermsBySector[expr], key, 0];
  red = ReduceSectorLagrangian[secExpr, key[[1]], key[[2]], "CacheDirectory" -> "left_only_uv_2_eft_6_cache", "UseCache" -> True, "Verbose" -> False, "MaxDimension" -> 6];
  Print["sector=" <> ToString[key, InputForm]];
  Print["projection_ok=" <> ToString[InputForm[red["ProjectionSucceededQ"]]]];
  Print["proj_residual_zero=" <> ToString[InputForm[red["ProjectionResidual"] === 0]]];
  Print["reduced_zero=" <> ToString[InputForm[red["ReducedExpression"] === 0]]];
  Print["phys_coords=" <> ToString[InputForm[red["PhysicalCoordinates"]]]];
, {key, {{1,2}, {2,2}, {3,2}, {4,2}}}];
Quit[];
