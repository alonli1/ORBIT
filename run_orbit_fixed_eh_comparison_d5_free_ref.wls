Get["graviton_basis_toolkit.wl"];
Get["orbit_fixed_eh_comparison.wl"];

inputMX = "C:\\Users\\alonlif2000\\Desktop\\xActMatcheteDictionary\\LEFT_only_uv_2_eft_6.mx";
cacheDir = If[
  DirectoryQ[FileNameJoin[{Directory[], "left_only_uv_2_eft_6_cache"}]],
  FileNameJoin[{Directory[], "left_only_uv_2_eft_6_cache"}],
  FileNameJoin[{Directory[], "orbit_fixed_eh_cache"}]
];

dmax = 5;
lambdaRefVar = LambdaRefSolve;
kappaRefVar = KappaRefSolve;
checkpointFile = "orbit_fixed_eh_comparison_d5_free_ref_v4_checkpoint.wl";
resultFile = "orbit_fixed_eh_comparison_d5_free_ref_v4_result.wl";
reportBase = "orbit_fixed_eh_comparison_d5_free_ref_v4_report";

saveCheckpoint[tag_, data_] := Put[<|"Stage" -> tag, "Data" -> data|>, checkpointFile];
loadCheckpoint[] := If[FileExistsQ[checkpointFile], Get[checkpointFile], <|"Stage" -> "start", "Data" -> <||>|>];

buildComparisonFromReductions[translatedExpr_, normalizedExpr_, referenceData_, inputReduction_, referenceReduction_, dmax_Integer] := Module[
  {
    canonicalData, comparisonInputReduction,
    supportedSectors, allSectors, sectorComparisons, supportedComparisons, unsupportedComparisons,
    matchRecords, matchInfo, matchVars, supportedDifference, unsupportedDifference,
    inputSummary, referenceSummary, inputProjectionFailures, referenceProjectionFailures
  },
  canonicalData = kineticNormalizationDataFromReduction[
    inputReduction,
    {
      "MaxDimension" -> dmax,
      "CacheDirectory" -> cacheDir,
      "UseCache" -> True,
      "Verbose" -> False
    }
  ];
  comparisonInputReduction = If[TrueQ[Lookup[canonicalData, "SucceededQ", False]],
    canonicalNormalizeReduction[inputReduction, canonicalData["Factor"]],
    inputReduction
  ];

  supportedSectors = supportedSectorsUpTo[dmax];
  allSectors = Sort @ Union[
    supportedSectors,
    Keys[comparisonInputReduction["SectorReductions"]],
    Keys[referenceReduction["SectorReductions"]]
  ];

  sectorComparisons = Association @ Table[
    With[
      {
        key = sector,
        inputSector = sectorLookup[comparisonInputReduction["SectorReductions"], sector],
        referenceSector = sectorLookup[referenceReduction["SectorReductions"], sector],
        sectorData = Which[
          AssociationQ[sectorLookup[comparisonInputReduction["SectorReductions"], sector]],
            comparisonInputReduction["SectorReductions"][sector]["SectorData"],
          AssociationQ[sectorLookup[referenceReduction["SectorReductions"], sector]],
            referenceReduction["SectorReductions"][sector]["SectorData"],
          True,
            ComputeSectorData[
              sector[[1]],
              sector[[2]],
              "MaxDimension" -> dmax,
              "CacheDirectory" -> cacheDir,
              "UseCache" -> True,
              "Verbose" -> False
            ]
        ]
      },
      key -> Append[
        sectorComparisonRecord[key, inputSector, referenceSector, sectorData],
        "SupportedQ" -> MemberQ[supportedSectors, key]
      ]
    ],
    {sector, allSectors}
  ];

  supportedComparisons = KeySelect[sectorComparisons, MemberQ[supportedSectors, #] &];
  unsupportedComparisons = KeySelect[sectorComparisons, ! MemberQ[supportedSectors, #] &];

  supportedDifference = canonExpr @ Total[Lookup[Values[supportedComparisons], "DifferenceExpression", {}]];
  unsupportedDifference = canonExpr @ Total[
    Lookup[
      Select[Values[unsupportedComparisons], ! TrueQ[#["DifferenceIsZeroQ"]] &],
      "DifferenceExpression",
      {}
    ]
  ];

  matchRecords = collectDifferenceEquationRecords[supportedComparisons];
  matchVars = DeleteDuplicates @ Join[
    {M, \[Mu]bar2, \[Kappa]},
    referenceSolveVariablesFrom[
      referenceData["LambdaReferenceValue"],
      referenceData["KappaReferenceValue"]
    ]
  ];
  matchInfo = solveMatchSystem[matchRecords, matchVars];
  inputSummary = reductionSummaryFrom[comparisonInputReduction];
  referenceSummary = reductionSummaryFrom[referenceReduction];
  inputProjectionFailures = Keys @ Select[inputSummary, ! TrueQ[Lookup[#, "ProjectionSucceededQ", True]] &];
  referenceProjectionFailures = Keys @ Select[referenceSummary, ! TrueQ[Lookup[#, "ProjectionSucceededQ", True]] &];

  <|
    "TranslatedExpression" -> translatedExpr,
    "NormalizedExpression" -> normalizedExpr,
    "RawReducedInput" -> inputReduction,
    "CanonicalNormalization" -> canonicalData,
    "ReducedInput" -> comparisonInputReduction,
    "ReferenceData" -> referenceData,
    "ReferenceExpression" -> referenceData["ReferenceExpression"],
    "ReducedReference" -> referenceReduction,
    "SupportedSectors" -> supportedSectors,
    "SectorComparison" -> sectorComparisons,
    "SupportedDifference" -> supportedDifference,
    "UnsupportedSectors" -> Keys @ Select[unsupportedComparisons, ! TrueQ[#["DifferenceIsZeroQ"]] &],
    "UnsupportedDifference" -> unsupportedDifference,
    "MatchEquationRecords" -> matchRecords,
    "MatchEquations" -> Lookup[matchRecords, "Equation", {}],
    "MatchVariables" -> matchVars,
    "MatchSolutions" -> matchInfo,
    "InputReductionSummary" -> inputSummary,
    "ReferenceReductionSummary" -> referenceSummary,
    "InputProjectionFailures" -> inputProjectionFailures,
    "ReferenceProjectionFailures" -> referenceProjectionFailures,
    "ExactMatchQ" -> TrueQ[
      unsupportedDifference === 0 &&
      matchInfo["HasSolution"] &&
      inputProjectionFailures === {} &&
      referenceProjectionFailures === {}
    ]
  |>
];

state = loadCheckpoint[];
data = Lookup[state, "Data", <||>];
data["InputMX"] = inputMX;
timings = Lookup[data, "StageTimings", <||>];

translated = Lookup[data, "TranslatedExpression", Missing["NotAvailable"]];
If[translated === Missing["NotAvailable"],
  {timings["Translation"], translated} = AbsoluteTiming[LoadMatcheteToXAct[inputMX]];
  data["TranslatedExpression"] = translated;
  data["StageTimings"] = timings;
  saveCheckpoint["translated", data];
];

normalized = Lookup[data, "NormalizedExpression", Missing["NotAvailable"]];
If[normalized === Missing["NotAvailable"],
  {timings["Normalization"], normalized} = AbsoluteTiming[NormalizeMatcheteFinitePart[translated]];
  data["NormalizedExpression"] = normalized;
  data["StageTimings"] = timings;
  saveCheckpoint["normalized", data];
];

comparedInput = Lookup[data, "ComparedInputExpression", Missing["NotAvailable"]];
If[comparedInput === Missing["NotAvailable"],
  {timings["InputTruncation"], comparedInput} = AbsoluteTiming[selectTermsByMassDimension[normalized, dmax]];
  data["ComparedInputExpression"] = comparedInput;
  data["StageTimings"] = timings;
  saveCheckpoint["truncated", data];
];

referenceData = Lookup[data, "ReferenceData", Missing["NotAvailable"]];
If[referenceData === Missing["NotAvailable"],
  {timings["ReferenceExpansion"], referenceData} = AbsoluteTiming[
    ExpandFixedEHReferenceLagrangian[
      "MaxDimension" -> dmax,
      "LambdaReferenceValue" -> lambdaRefVar,
      "KappaReferenceValue" -> kappaRefVar,
      "Verbose" -> False
    ]
  ];
  data["ReferenceData"] = referenceData;
  data["StageTimings"] = timings;
  saveCheckpoint["reference", data];
];

inputReduction = Lookup[data, "InputReduction", Missing["NotAvailable"]];
If[inputReduction === Missing["NotAvailable"],
  {timings["InputReduction"], inputReduction} = AbsoluteTiming[
    ReduceLagrangian[
      comparedInput,
      "MaxDimension" -> dmax,
      "CacheDirectory" -> cacheDir,
      "UseCache" -> True,
      "ParallelizeSectors" -> False,
      "Verbose" -> False
    ]
  ];
  data["InputReduction"] = inputReduction;
  data["StageTimings"] = timings;
  saveCheckpoint["inputReduction", data];
];

referenceReduction = Lookup[data, "ReferenceReduction", Missing["NotAvailable"]];
If[referenceReduction === Missing["NotAvailable"],
  {timings["ReferenceReduction"], referenceReduction} = AbsoluteTiming[
    ReduceLagrangian[
      referenceData["ReferenceExpression"],
      "MaxDimension" -> dmax,
      "CacheDirectory" -> cacheDir,
      "UseCache" -> True,
      "ParallelizeSectors" -> False,
      "Verbose" -> False
    ]
  ];
  data["ReferenceReduction"] = referenceReduction;
  data["StageTimings"] = timings;
  saveCheckpoint["referenceReduction", data];
];

{timings["ComparisonAssembly"], comparison} = AbsoluteTiming[
  buildComparisonFromReductions[
    translated,
    comparedInput,
    referenceData,
    inputReduction,
    referenceReduction,
    dmax
  ]
];

comparisonWithMeta = Append[comparison, "InputMX" -> inputMX];
comparisonWithMeta = Append[comparisonWithMeta, "StageTimings" -> timings];

Put[comparisonWithMeta, resultFile];
saveCheckpoint["comparison", comparisonWithMeta];

{timings["ReportBuild"], report} = AbsoluteTiming[
  BuildMatcheteEHReport[
    comparisonWithMeta,
    reportBase,
    "CompilePDF" -> False,
    "Verbose" -> False
  ]
];

comparisonWithMeta = Append[KeyDrop[comparisonWithMeta, "StageTimings"], "StageTimings" -> timings];
Put[comparisonWithMeta, resultFile];

saveCheckpoint["report", <|
  "Comparison" -> comparisonWithMeta,
  "Report" -> report
|>];

Print["Dimension-5 comparison with symbolic reference coefficients complete."];
Print[InputForm[<|
  "ExactMatchQ" -> comparisonWithMeta["ExactMatchQ"],
  "UnsupportedSectors" -> comparisonWithMeta["UnsupportedSectors"],
  "MatchVariables" -> comparisonWithMeta["MatchVariables"],
  "MatchSolutions" -> comparisonWithMeta["MatchSolutions"],
  "StageTimings" -> comparisonWithMeta["StageTimings"],
  "Report" -> report
|>]];
