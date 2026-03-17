Get["graviton_basis_toolkit.wl"];
Get["orbit_fixed_eh_comparison.wl"];
cacheDir = If[DirectoryQ[FileNameJoin[{Directory[], "left_only_uv_2_eft_6_cache"}]], FileNameJoin[{Directory[], "left_only_uv_2_eft_6_cache"}], FileNameJoin[{Directory[], "orbit_fixed_eh_cache"}]];
ref = ExpandFixedEHReferenceLagrangian["MaxDimension" -> 6, "LambdaReferenceValue" -> 1, "KappaReferenceValue" -> 1, "Verbose" -> False]["ReferenceExpression"];
{tSeq, seq} = AbsoluteTiming[ReduceLagrangian[ref, "MaxDimension" -> 6, "CacheDirectory" -> cacheDir, "UseCache" -> True, "ParallelizeSectors" -> False, "Verbose" -> False]];
{tPar, par} = AbsoluteTiming[ReduceLagrangian[ref, "MaxDimension" -> 6, "CacheDirectory" -> cacheDir, "UseCache" -> True, "ParallelizeSectors" -> True, "KernelCount" -> 4, "Verbose" -> False]];
Print[InputForm[<|"Sequential" -> tSeq, "Parallel4" -> tPar, "SameReducedQ" -> (seq["ReducedExpression"] === par["ReducedExpression"]), "SameKeysQ" -> (Keys[seq["SectorReductions"]] === Keys[par["SectorReductions"]])|>]];
Quit[];
