Get["graviton_basis_toolkit.wl"];
Get["orbit_fixed_eh_comparison.wl"];

inputMX = "C:\\Users\\alonlif2000\\Desktop\\xActMatcheteDictionary\\LEFT_only_uv_2_eft_6.mx";
cacheDir = If[
  DirectoryQ[FileNameJoin[{Directory[], "left_only_uv_2_eft_6_cache"}]],
  FileNameJoin[{Directory[], "left_only_uv_2_eft_6_cache"}],
  FileNameJoin[{Directory[], "orbit_fixed_eh_cache"}]
];

resultFile = "orbit_fixed_eh_comparison_final_result.wl";
reportBase = "orbit_fixed_eh_comparison_final_report";

{timing, result} = AbsoluteTiming[
  CompareMatcheteToFixedEH[
    inputMX,
    "MaxDimension" -> 6,
    "LambdaReferenceValue" -> LambdaRefFinal,
    "KappaReferenceValue" -> KappaRefFinal,
    "EHSign" -> -1,
    "CanonicalNormalizeInput" -> True,
    "CanonicalKineticSign" -> -1,
    "MatchParameters" -> {M, \[Mu]bar2, \[Kappa]},
    "CacheDirectory" -> cacheDir,
    "UseCache" -> True,
    "Verbose" -> False
  ]
];

Put[result, resultFile];

report = BuildMatcheteEHReport[
  result,
  reportBase,
  "Title" -> "Final ORBIT Comparison to Sign-Flipped Einstein-Hilbert Reference",
  "Author" -> "ORBIT",
  "CompilePDF" -> True,
  "Verbose" -> False
];

Print["Final d<=6 comparison complete."];
Print[InputForm[<|
  "TimingSeconds" -> timing,
  "ExactMatchQ" -> result["ExactMatchQ"],
  "UnsupportedSectors" -> result["UnsupportedSectors"],
  "CanonicalKineticSign" -> result["CanonicalKineticSign"],
  "CanonicalNormalization" -> result["CanonicalNormalization"],
  "MatchSolutions" -> result["MatchSolutions"],
  "Report" -> report
|>]];

Quit[];
