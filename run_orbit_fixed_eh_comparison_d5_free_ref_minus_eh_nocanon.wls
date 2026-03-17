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
  "LambdaReferenceValue" -> LambdaRefSolve,
  "KappaReferenceValue" -> KappaRefSolve,
  "EHSign" -> -1,
  "CanonicalNormalizeInput" -> False,
  "CacheDirectory" -> cacheDir,
  "UseCache" -> True,
  "Verbose" -> False
];

Put[result, "orbit_fixed_eh_comparison_d5_free_ref_minus_eh_nocanon_result.wl"];

Print["Dimension-5 comparison with symbolic reference coefficients, EHSign=-1, and no canonical normalization complete."];
Print[InputForm[<|
  "ExactMatchQ" -> result["ExactMatchQ"],
  "UnsupportedSectors" -> result["UnsupportedSectors"],
  "MatchVariables" -> result["MatchVariables"],
  "MatchSolutions" -> result["MatchSolutions"]
|>]];

Quit[];
