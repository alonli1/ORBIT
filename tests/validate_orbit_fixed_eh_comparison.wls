scriptDir = DirectoryName[$InputFileName];
repoRoot = NestWhile[
  DirectoryName,
  scriptDir,
  ! FileExistsQ[FileNameJoin[{#, "orbit_fixed_eh_comparison.wl"}]] &
];
SetDirectory[repoRoot];

Get["graviton_basis_toolkit.wl"];
Get["orbit_fixed_eh_comparison.wl"];

inputMX = FileNameJoin[{Directory[], "examples", "left_only_uv_2_eft_6", "LEFT_only_uv_2_eft_6.mx"}];
cacheDir = If[
  DirectoryQ[FileNameJoin[{Directory[], "cache", "left_only_uv_2_eft_6_cache"}]],
  FileNameJoin[{Directory[], "cache", "left_only_uv_2_eft_6_cache"}],
  FileNameJoin[{Directory[], "cache", "orbit_fixed_eh_cache"}]
];
outputDir = FileNameJoin[{Directory[], "artifacts", "orbit_fixed_eh"}];
If[! DirectoryQ[outputDir], CreateDirectory[outputDir, CreateIntermediateDirectories -> True]];
checkpointFile = FileNameJoin[{outputDir, "orbit_fixed_eh_validation_checkpoint.wl"}];

saveCheckpoint[tag_, data_] := Put[<|"Stage" -> tag, "Data" -> data|>, checkpointFile];

translatedFromMX = LoadMatcheteToXAct[inputMX];
translatedBaseline = Get[FileNameJoin[{Directory[], "artifacts", "left_only_uv_2_eft_6", "LEFT_only_uv_2_eft_6_xact.wl"}]];
translationDiff = canonExpr[translatedFromMX - translatedBaseline];
translationMatchesQ = TrueQ[translationDiff === 0];
saveCheckpoint["translation", <|
  "TranslationMatchesBaselineQ" -> translationMatchesQ,
  "TranslationDifference" -> translationDiff
|>];

normalized = NormalizeMatcheteFinitePart[translatedFromMX];
noHbarQ = FreeQ[normalized, hbar, Infinity];
noPoleQ = FreeQ[
  normalized,
  HoldPattern[Power[\[Epsilon], n_ /; NumericQ[n] && n < 0]],
  Infinity
];
saveCheckpoint["normalization", <|
  "TranslationMatchesBaselineQ" -> translationMatchesQ,
  "TranslationDifference" -> translationDiff,
  "NormalizedContainsNoHbarQ" -> noHbarQ,
  "NormalizedContainsNoPoleQ" -> noPoleQ
|>];

reference = ExpandFixedEHReferenceLagrangian[
  "MaxDimension" -> 6,
  "LambdaReferenceValue" -> 1,
  "KappaReferenceValue" -> 1,
  "Verbose" -> False
];

referenceSectors = Sort @ Keys @ SplitTermsBySector[reference["ReferenceExpression"]];
saveCheckpoint["reference", <|
  "TranslationMatchesBaselineQ" -> translationMatchesQ,
  "TranslationDifference" -> translationDiff,
  "NormalizedContainsNoHbarQ" -> noHbarQ,
  "NormalizedContainsNoPoleQ" -> noPoleQ,
  "ReferenceSectors" -> referenceSectors
|>];

synthetic = CompareMatcheteToFixedEH[
  reference["ReferenceExpression"],
  "MaxDimension" -> 6,
  "LambdaReferenceValue" -> 1,
  "KappaReferenceValue" -> 1,
  "CacheDirectory" -> cacheDir,
  "UseCache" -> True,
  "Verbose" -> False
];
saveCheckpoint["synthetic", <|
  "TranslationMatchesBaselineQ" -> translationMatchesQ,
  "TranslationDifference" -> translationDiff,
  "NormalizedContainsNoHbarQ" -> noHbarQ,
  "NormalizedContainsNoPoleQ" -> noPoleQ,
  "ReferenceSectors" -> referenceSectors,
  "SyntheticExactMatchQ" -> synthetic["ExactMatchQ"],
  "SyntheticUnsupportedSectors" -> synthetic["UnsupportedSectors"],
  "SyntheticSupportedDifference" -> synthetic["SupportedDifference"]
|>];

real = CompareMatcheteToFixedEH[
  translatedFromMX,
  "MaxDimension" -> 6,
  "LambdaReferenceValue" -> 1,
  "KappaReferenceValue" -> 1,
  "CacheDirectory" -> cacheDir,
  "UseCache" -> True,
  "Verbose" -> False
];

validation = <|
  "TranslationMatchesBaselineQ" -> translationMatchesQ,
  "TranslationDifference" -> translationDiff,
  "NormalizedContainsNoHbarQ" -> noHbarQ,
  "NormalizedContainsNoPoleQ" -> noPoleQ,
  "ReferenceSectors" -> referenceSectors,
  "SyntheticExactMatchQ" -> synthetic["ExactMatchQ"],
  "SyntheticUnsupportedSectors" -> synthetic["UnsupportedSectors"],
  "SyntheticSupportedDifference" -> synthetic["SupportedDifference"],
  "RealExactMatchQ" -> real["ExactMatchQ"],
  "RealUnsupportedSectors" -> real["UnsupportedSectors"],
  "RealSupportedDifference" -> real["SupportedDifference"],
  "RealUnsupportedDifference" -> real["UnsupportedDifference"],
  "RealMatchSolutions" -> real["MatchSolutions"],
  "RealInputReductionSummary" -> real["InputReductionSummary"],
  "RealReferenceReductionSummary" -> real["ReferenceReductionSummary"]
|>;

Put[validation, FileNameJoin[{outputDir, "orbit_fixed_eh_validation_output.wl"}]];
saveCheckpoint["complete", validation];

Print["Validation complete."];
Print[InputForm[validation]];
