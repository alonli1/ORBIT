scriptDir = DirectoryName[$InputFileName];
repoRoot = NestWhile[
  DirectoryName,
  scriptDir,
  ! FileExistsQ[FileNameJoin[{#, "graviton_basis_toolkit.wl"}]] &
];
SetDirectory[repoRoot];

Get["graviton_basis_toolkit.wl"];
Get["orbit_fixed_eh_comparison.wl"];

outputDir = FileNameJoin[{Directory[], "artifacts", "orbit_fixed_eh"}];
If[! DirectoryQ[outputDir], CreateDirectory[outputDir, CreateIntermediateDirectories -> True]];

resultFile = FileNameJoin[{outputDir, "orbit_fixed_eh_comparison_final_result.wl"}];
analysisFile = FileNameJoin[{outputDir, "orbit_fixed_eh_quadratic_completion_analysis.wl"}];
summaryFile = FileNameJoin[{outputDir, "orbit_fixed_eh_quadratic_completion_summary.wl"}];

If[! FileExistsQ[resultFile],
  Print["Missing comparison result file: " <> resultFile];
  Quit[1];
];

finalResult = Get[resultFile];
Print["Loaded final comparison result."];

analysis = AnalyzeQuadraticFourDerivativeDifference[
  finalResult,
  "MaxDimension" -> 6,
  "CacheDirectory" -> FileNameJoin[{Directory[], "cache", "left_only_uv_2_eft_6_cache"}],
  "UseCache" -> True,
  "Verbose" -> True,
  "Substitutions" -> {
    Log[\[Mu]bar2/M^2] -> -3/2
  }
];
Print["Quadratic analysis complete."];

summary = <|
  "Sector" -> analysis["Sector"],
  "ResidualIsZeroQ" -> analysis["ResidualIsZeroQ"],
  "CurvatureSquaredModuloQuadraticRedefinitionsQ" -> analysis["CurvatureSquaredModuloQuadraticRedefinitionsQ"],
  "PureQuadraticRedefinitionQ" -> analysis["PureQuadraticRedefinitionQ"],
  "CurvatureCoefficients" -> analysis["CurvatureCoefficients"],
  "QuadraticRedefinitionRank" -> analysis["QuadraticRedefinitionData"]["Rank"],
  "GaussBonnetCoordinates" -> analysis["CurvatureBasis"]["GaussBonnetCoordinates"]
|>;

Put[analysis, analysisFile];
Put[summary, summaryFile];

Print["Quadratic completion analysis written to: " <> analysisFile];
Print["Quadratic completion summary written to: " <> summaryFile];
Print["ResidualIsZeroQ -> " <> ToString[summary["ResidualIsZeroQ"], InputForm]];
Print["CurvatureSquaredModuloQuadraticRedefinitionsQ -> " <> ToString[summary["CurvatureSquaredModuloQuadraticRedefinitionsQ"], InputForm]];
Print["PureQuadraticRedefinitionQ -> " <> ToString[summary["PureQuadraticRedefinitionQ"], InputForm]];
