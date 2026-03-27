scriptDir = DirectoryName[$InputFileName];
repoRoot = NestWhile[
  DirectoryName,
  scriptDir,
  ! FileExistsQ[FileNameJoin[{#, "orbit_fixed_eh_comparison.wl"}]] &
];
SetDirectory[repoRoot];

Get["orbit_fixed_eh_comparison.wl"];

inputMX = FileNameJoin[{"examples", "left_only_uv_2_eft_6", "LEFT_only_uv_2_eft_6.mx"}];
cacheDir = If[
  DirectoryQ[FileNameJoin[{Directory[], "cache", "left_only_uv_2_eft_6_cache"}]],
  FileNameJoin[{Directory[], "cache", "left_only_uv_2_eft_6_cache"}],
  FileNameJoin[{Directory[], "cache", "orbit_fixed_eh_cache"}]
];
outputDir = FileNameJoin[{Directory[], "artifacts", "orbit_fixed_eh", "legacy_runs"}];
If[! DirectoryQ[outputDir], CreateDirectory[outputDir, CreateIntermediateDirectories -> True]];

result = CompareMatcheteToFixedEH[
  inputMX,
  "MaxDimension" -> 5,
  "LambdaReferenceValue" -> LambdaRefSolve,
  "KappaReferenceValue" -> KappaRefSolve,
  "EHSign" -> -1,
  "CanonicalNormalizeInput" -> False,
  "CacheDirectory" -> cacheDir,
  "UseCache" -> True,
  "Verbose" -> False
];

Put[result, FileNameJoin[{outputDir, "orbit_fixed_eh_comparison_d5_free_ref_minus_eh_nocanon_result.wl"}]];

Print["Dimension-5 comparison with symbolic reference coefficients, EHSign=-1, and no canonical normalization complete."];
Print[InputForm[<|
  "ExactMatchQ" -> result["ExactMatchQ"],
  "UnsupportedSectors" -> result["UnsupportedSectors"],
  "MatchVariables" -> result["MatchVariables"],
  "MatchSolutions" -> result["MatchSolutions"]
|>]];

Quit[];
