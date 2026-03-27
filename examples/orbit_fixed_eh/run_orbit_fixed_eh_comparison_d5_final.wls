scriptDir = DirectoryName[$InputFileName];
repoRoot = NestWhile[
  DirectoryName,
  scriptDir,
  ! FileExistsQ[FileNameJoin[{#, "orbit_fixed_eh_comparison.wl"}]] &
];
SetDirectory[repoRoot];

Get["orbit_fixed_eh_comparison.wl"];

inputMX = FileNameJoin[{Directory[], "examples", "left_only_uv_2_eft_6", "LEFT_only_uv_2_eft_6.mx"}];
cacheDir = If[
  DirectoryQ[FileNameJoin[{Directory[], "cache", "left_only_uv_2_eft_6_cache"}]],
  FileNameJoin[{Directory[], "cache", "left_only_uv_2_eft_6_cache"}],
  FileNameJoin[{Directory[], "cache", "orbit_fixed_eh_cache"}]
];
outputDir = FileNameJoin[{Directory[], "artifacts", "orbit_fixed_eh"}];
If[! DirectoryQ[outputDir], CreateDirectory[outputDir, CreateIntermediateDirectories -> True]];

result = CompareMatcheteToFixedEH[
  inputMX,
  "MaxDimension" -> 5,
  "LambdaReferenceValue" -> LambdaRefFinal,
  "KappaReferenceValue" -> KappaRefFinal,
  "EHSign" -> -1,
  "CanonicalNormalizeInput" -> True,
  "CanonicalKineticSign" -> -1,
  "CacheDirectory" -> cacheDir,
  "UseCache" -> True,
  "Verbose" -> False
];

Put[result, FileNameJoin[{outputDir, "orbit_fixed_eh_comparison_d5_final_result.wl"}]];

report = BuildMatcheteEHReport[
  result,
  FileNameJoin[{outputDir, "orbit_fixed_eh_comparison_d5_final_report"}],
  "Title" -> "Dimension-5 ORBIT Comparison to Sign-Flipped Einstein-Hilbert Reference",
  "Author" -> "ORBIT",
  "CompilePDF" -> True,
  "Verbose" -> False
];

Print["Final d<=5 comparison complete."];
Print[InputForm[<|
  "ExactMatchQ" -> result["ExactMatchQ"],
  "UnsupportedSectors" -> result["UnsupportedSectors"],
  "CanonicalKineticSign" -> result["CanonicalKineticSign"],
  "CanonicalNormalization" -> result["CanonicalNormalization"],
  "MatchSolutions" -> result["MatchSolutions"],
  "Report" -> report
|>]];

Quit[];
