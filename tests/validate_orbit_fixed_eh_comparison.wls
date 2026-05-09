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
translationDiff = Quiet[canonExpr[translatedFromMX - translatedBaseline], ToCanonical::noident];
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
  "CacheDirectory" -> cacheDir,
  "UseCache" -> True,
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
  inputMX,
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
  "RealComparisonSucceededQ" -> AssociationQ[real],
  "RealExactMatchQ" -> If[AssociationQ[real], real["ExactMatchQ"], $Failed],
  "RealUnsupportedSectors" -> If[AssociationQ[real], real["UnsupportedSectors"], $Failed],
  "RealSupportedDifference" -> If[AssociationQ[real], real["SupportedDifference"], $Failed],
  "RealUnsupportedDifference" -> If[AssociationQ[real], real["UnsupportedDifference"], $Failed],
  "RealMatchSolutions" -> If[AssociationQ[real], real["MatchSolutions"], $Failed],
  "RealInputReductionSummary" -> If[AssociationQ[real], real["InputReductionSummary"], $Failed],
  "RealReferenceReductionSummary" -> If[AssociationQ[real], real["ReferenceReductionSummary"], $Failed]
|>;

Put[validation, FileNameJoin[{outputDir, "orbit_fixed_eh_validation_output.wl"}]];
saveCheckpoint["complete", validation];

allPassed = True;

reportCheck[label_String, condition_] := If[
  TrueQ[condition],
  Print["PASS: " <> label],
  Print["FAIL: " <> label];
  allPassed = False
];

reportCheck["translation matches stored baseline", translationMatchesQ];
reportCheck["normalized expression contains no hbar", noHbarQ];
reportCheck["normalized expression contains no epsilon poles", noPoleQ];
reportCheck["synthetic reference self-comparison is exact", TrueQ[synthetic["ExactMatchQ"]]];
reportCheck["real comparison returns an Association", AssociationQ[real]];

If[AssociationQ[real],
  reportCheck["real comparison exposes ExactMatchQ", KeyExistsQ[real, "ExactMatchQ"]];
  reportCheck["real comparison exposes MatchSolutions", KeyExistsQ[real, "MatchSolutions"]]
];

Print["Validation complete."];
Print[InputForm[validation]];

If[! allPassed, Exit[1]];
