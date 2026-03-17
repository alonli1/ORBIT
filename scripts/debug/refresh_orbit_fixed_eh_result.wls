Get["graviton_basis_toolkit.wl"];
Get["orbit_fixed_eh_comparison.wl"];
cacheDir = If[DirectoryQ[FileNameJoin[{Directory[], "left_only_uv_2_eft_6_cache"}]], FileNameJoin[{Directory[], "left_only_uv_2_eft_6_cache"}], FileNameJoin[{Directory[], "orbit_fixed_eh_cache"}]];
inputMX = "C:\\Users\\alonlif2000\\Desktop\\xActMatcheteDictionary\\LEFT_only_uv_2_eft_6.mx";
resultFile = "orbit_fixed_eh_comparison_result.wl";
reportBase = "orbit_fixed_eh_comparison_report";
old = Get[resultFile];
translated = old["TranslatedExpression"];
normalized = old["NormalizedExpression"];
referenceData = old["ReferenceData"];
inputReduction = old["ReducedInput"];
referenceReduction = old["ReducedReference"];
timings = Lookup[old, "StageTimings", <||>];

buildComparisonFromReductions[translatedExpr_, normalizedExpr_, referenceData_, inputReduction_, referenceReduction_, dmax_Integer] := Module[
  {
    supportedSectors, allSectors, sectorComparisons, supportedComparisons, unsupportedComparisons,
    matchRecords, matchInfo, supportedDifference, unsupportedDifference,
    inputSummary, referenceSummary, inputProjectionFailures, referenceProjectionFailures
  },
  supportedSectors = supportedSectorsUpTo[dmax];
  allSectors = Sort @ Union[
    supportedSectors,
    Keys[inputReduction["SectorReductions"]],
    Keys[referenceReduction["SectorReductions"]]
  ];
  sectorComparisons = Association @ Table[
    With[
      {
        key = sector,
        inputSector = sectorLookup[inputReduction["SectorReductions"], sector],
        referenceSector = sectorLookup[referenceReduction["SectorReductions"], sector],
        sectorData = Which[
          AssociationQ[sectorLookup[inputReduction["SectorReductions"], sector]],
            inputReduction["SectorReductions"][sector]["SectorData"],
          AssociationQ[sectorLookup[referenceReduction["SectorReductions"], sector]],
            referenceReduction["SectorReductions"][sector]["SectorData"],
          True,
            ComputeSectorData[sector[[1]], sector[[2]], "MaxDimension" -> dmax, "CacheDirectory" -> cacheDir, "UseCache" -> True, "Verbose" -> False]
        ]
      },
      key -> Append[sectorComparisonRecord[key, inputSector, referenceSector, sectorData], "SupportedQ" -> MemberQ[supportedSectors, key]]
    ],
    {sector, allSectors}
  ];
  supportedComparisons = KeySelect[sectorComparisons, MemberQ[supportedSectors, #] &];
  unsupportedComparisons = KeySelect[sectorComparisons, ! MemberQ[supportedSectors, #] &];
  supportedDifference = canonExpr @ Total[Lookup[Values[supportedComparisons], "DifferenceExpression", {}]];
  unsupportedDifference = canonExpr @ Total[Lookup[Select[Values[unsupportedComparisons], ! TrueQ[# ["DifferenceIsZeroQ"]] &], "DifferenceExpression", {}]];
  matchRecords = collectDifferenceEquationRecords[supportedComparisons];
  matchInfo = solveMatchSystem[matchRecords, {M, \[Mu]bar2, \[Kappa]}];
  inputSummary = reductionSummaryFrom[inputReduction];
  referenceSummary = reductionSummaryFrom[referenceReduction];
  inputProjectionFailures = Keys @ Select[inputSummary, ! TrueQ[Lookup[#, "ProjectionSucceededQ", True]] &];
  referenceProjectionFailures = Keys @ Select[referenceSummary, ! TrueQ[Lookup[#, "ProjectionSucceededQ", True]] &];
  <|
    "TranslatedExpression" -> translatedExpr,
    "NormalizedExpression" -> normalizedExpr,
    "ReducedInput" -> inputReduction,
    "ReferenceData" -> referenceData,
    "ReferenceExpression" -> referenceData["ReferenceExpression"],
    "ReducedReference" -> referenceReduction,
    "SupportedSectors" -> supportedSectors,
    "SectorComparison" -> sectorComparisons,
    "SupportedDifference" -> supportedDifference,
    "UnsupportedSectors" -> Keys @ Select[unsupportedComparisons, ! TrueQ[# ["DifferenceIsZeroQ"]] &],
    "UnsupportedDifference" -> unsupportedDifference,
    "MatchEquationRecords" -> matchRecords,
    "MatchEquations" -> Lookup[matchRecords, "Equation", {}],
    "MatchSolutions" -> matchInfo,
    "InputReductionSummary" -> inputSummary,
    "ReferenceReductionSummary" -> referenceSummary,
    "InputProjectionFailures" -> inputProjectionFailures,
    "ReferenceProjectionFailures" -> referenceProjectionFailures,
    "ExactMatchQ" -> TrueQ[unsupportedDifference === 0 && matchInfo["HasSolution"] && inputProjectionFailures === {} && referenceProjectionFailures === {}]
  |>
];

comparison = buildComparisonFromReductions[translated, normalized, referenceData, inputReduction, referenceReduction, 6];
validationSummary = If[FileExistsQ["orbit_fixed_eh_validation_output.wl"], Get["orbit_fixed_eh_validation_output.wl"], Missing["NotAvailable"]];
comparisonWithMeta = Append[comparison, "InputMX" -> inputMX];
comparisonWithMeta = Append[comparisonWithMeta, "ValidationSummary" -> validationSummary];
comparisonWithMeta = Append[comparisonWithMeta, "StageTimings" -> timings];
Put[comparisonWithMeta, resultFile];
report = BuildMatcheteEHReport[comparisonWithMeta, reportBase, "CompilePDF" -> False, "Verbose" -> False];
Print[InputForm[<|"ExactMatchQ" -> comparisonWithMeta["ExactMatchQ"], "UnsupportedSectors" -> comparisonWithMeta["UnsupportedSectors"], "HasSolution" -> comparisonWithMeta["MatchSolutions", "HasSolution"], "Report" -> report|>]];
Quit[];
