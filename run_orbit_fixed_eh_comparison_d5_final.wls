Get["orbit_fixed_eh_comparison.wl"];

inputMX = "C:\\Users\\alonlif2000\\Desktop\\xActMatcheteDictionary\\LEFT_only_uv_2_eft_6.mx";
cacheDir = If[
  DirectoryQ[FileNameJoin[{Directory[], "left_only_uv_2_eft_6_cache"}]],
  FileNameJoin[{Directory[], "left_only_uv_2_eft_6_cache"}],
  FileNameJoin[{Directory[], "orbit_fixed_eh_cache"}]
];

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

Put[result, "orbit_fixed_eh_comparison_d5_final_result.wl"];

report = BuildMatcheteEHReport[
  result,
  "orbit_fixed_eh_comparison_d5_final_report",
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
