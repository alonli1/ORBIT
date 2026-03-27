scriptDir = DirectoryName[$InputFileName];
repoRoot = NestWhile[
  DirectoryName,
  scriptDir,
  ! FileExistsQ[FileNameJoin[{#, "graviton_basis_toolkit.wl"}]] &
];
SetDirectory[repoRoot];

Get["graviton_basis_toolkit.wl"];
Get["orbit_fixed_eh_comparison.wl"];

dmax = 6;
inputXActFile = FileNameJoin[{"artifacts", "left_only_uv_2_eft_6", "LEFT_only_uv_2_eft_6_xact.wl"}];
cacheDir = If[
  DirectoryQ[FileNameJoin[{Directory[], "cache", "left_only_uv_2_eft_6_cache"}]],
  FileNameJoin[{Directory[], "cache", "left_only_uv_2_eft_6_cache"}],
  FileNameJoin[{Directory[], "cache", "orbit_fixed_eh_cache"}]
];
outputDir = FileNameJoin[{Directory[], "artifacts", "orbit_fixed_eh"}];
If[! DirectoryQ[outputDir], CreateDirectory[outputDir, CreateIntermediateDirectories -> True]];

checkpointFile = FileNameJoin[{outputDir, "orbit_fixed_eh_comparison_final_checkpoint_v2.wl"}];
resultFile = FileNameJoin[{outputDir, "orbit_fixed_eh_comparison_final_result.wl"}];
reportBase = FileNameJoin[{outputDir, "orbit_fixed_eh_comparison_final_report"}];
summaryFile = FileNameJoin[{outputDir, "orbit_fixed_eh_comparison_final_summary.wl"}];
crosscheckSummaryFile = FileNameJoin[{outputDir, "orbit_fixed_eh_quadratic_completion_crosscheck_summary.wl"}];
verificationSubstitutions = {
  Scalar[M] -> M,
  Scalar[\[Kappa]] -> \[Kappa],
  Scalar[\[Mu]bar2] -> \[Mu]bar2,
  Sqrt[1/(M^2*\[Kappa]^2)] -> 1/(M*\[Kappa]),
  Sqrt[1/(Scalar[M]^2*Scalar[\[Kappa]]^2)] -> 1/(M*\[Kappa]),
  Sqrt[-(1/(M^2*\[Kappa]^2*(1 + Log[\[Mu]bar2/M^2])))] -> Sqrt[2]/(M*\[Kappa]),
  Sqrt[-(1/(Scalar[M]^2*Scalar[\[Kappa]]^2*(1 + Log[\[Mu]bar2/M^2])))] -> Sqrt[2]/(M*\[Kappa]),
  Log[\[Mu]bar2/M^2] -> -3/2,
  Log[Scalar[\[Mu]bar2]/M^2] -> -3/2,
  Log[Scalar[\[Mu]bar2]/Scalar[M]^2] -> -3/2,
  LambdaRefFinal -> 0,
  KappaRefFinal -> 4 Sqrt[3]/M
};
verificationAssumptions = M > 0 && \[Kappa] > 0 && \[Mu]bar2 > 0;

log[msg_] := Print["[", DateString[{"Hour", ":", "Minute", ":", "Second"}], "] ", msg];
saveCheckpoint[tag_, data_] := Put[<|"Stage" -> tag, "Data" -> data|>, checkpointFile];
loadCheckpoint[] := If[FileExistsQ[checkpointFile], Get[checkpointFile], <|"Stage" -> "start", "Data" -> <||>|>];

sectorReductionAssociation[sectorReductions_Association] := <|
  "InputExpression" -> canonExpr @ Total[Lookup[Values[sectorReductions], "InputExpression", {}]],
  "UntouchedExpression" -> 0,
  "SectorReductions" -> Association @ KeySort[sectorReductions],
  "ReducedExpression" -> canonExpr @ Total[Lookup[Values[sectorReductions], "ReducedExpression", {}]]
|>;

trimCheckpointData[data_Association] := Module[{trimmed = data},
  trimmed = KeyDrop[trimmed, {"LegacyComparison", "TranslatedExpression", "NormalizedExpression", "ComparedInputExpression"}];
  If[KeyExistsQ[trimmed, "ReferenceData"] && AssociationQ[trimmed["ReferenceData"]],
    trimmed["ReferenceData"] = KeyDrop[trimmed["ReferenceData"], {"RawExpression", "ReferenceExpression"}]
  ];
  trimmed
];

reduceMissingSectors[label_, expr_, existing_Association] := Module[
  {sectorTerms, sectors, reductions, updated, t0, key, secResult},
  sectorTerms = KeySelect[
    SplitTermsBySector[Expand[canonExpr[expr]]],
    MatchQ[#, {_Integer?Positive, _Integer?NonNegative}] &
  ];
  sectors = Sort @ Keys[sectorTerms];
  reductions = existing;
  updated = False;

  Do[
    If[KeyExistsQ[reductions, key], Continue[]];
    log["Reducing " <> label <> " sector " <> ToString[key]];
    t0 = AbsoluteTime[];
    secResult = ReduceSectorLagrangianCanonicalInput[
      sectorTerms[key],
      key[[1]],
      key[[2]],
      "MaxDimension" -> dmax,
      "CacheDirectory" -> cacheDir,
      "UseCache" -> True,
      "Verbose" -> False
    ];
    reductions[key] = secResult;
    updated = True;
    log[
      label <> " sector " <> ToString[key] <>
      " complete in " <> ToString[NumberForm[AbsoluteTime[] - t0, {10, 1}]] <> " s; reduced terms = " <>
      ToString[expressionTermCount[secResult["ReducedExpression"]]]
    ];
    Share[];
    ClearSystemCache[];
    ,
    {key, sectors}
  ];

  <|"Reductions" -> reductions, "UpdatedQ" -> updated|>
];

scaledInputSector[key_, inputReduction_, canonicalFactor_] := Module[
  {rawSector, fieldScaleSquared},
  rawSector = sectorLookup[inputReduction["SectorReductions"], key];
  If[! AssociationQ[rawSector], Return[Missing["NotAvailable"]]];
  fieldScaleSquared = -1/canonicalFactor;
  scaleReducedSector[rawSector, fieldScaleSquared^(key[[1]]/2)]
];

buildSectorComparisons[inputReduction_, referenceReduction_, canonicalFactor_, existing_Association] := Module[
  {basisOpts, allSectors, comparisons, updated, key, inputSector, referenceSector, sectorData},
  basisOpts = {
    "MaxDimension" -> dmax,
    "CacheDirectory" -> cacheDir,
    "UseCache" -> True,
    "Verbose" -> False
  };
  allSectors = Sort @ Union[
    supportedSectorsUpTo[dmax],
    Keys[inputReduction["SectorReductions"]],
    Keys[referenceReduction["SectorReductions"]]
  ];
  comparisons = existing;
  updated = False;

  Do[
    If[KeyExistsQ[comparisons, key], Continue[]];
    log["Comparing sector " <> ToString[key]];
    inputSector = scaledInputSector[key, inputReduction, canonicalFactor];
    referenceSector = sectorLookup[referenceReduction["SectorReductions"], key];
    sectorData = Which[
      AssociationQ[inputSector], inputSector["SectorData"],
      AssociationQ[referenceSector], referenceSector["SectorData"],
      True, ComputeSectorData[key[[1]], key[[2]], Sequence @@ basisOpts]
    ];
    comparisons[key] = Append[
      sectorComparisonRecord[key, inputSector, referenceSector, sectorData],
      "SupportedQ" -> MemberQ[supportedSectorsUpTo[dmax], key]
    ];
    updated = True;
    Share[];
    ClearSystemCache[];
    ,
    {key, allSectors}
  ];

  <|"Comparisons" -> comparisons, "UpdatedQ" -> updated|>
];

buildFinalResult[referenceData_, inputReduction_, referenceReduction_, canonicalData_, sectorComparisons_, timings_Association] := Module[
  {
    supportedSectors, supportedComparisons, unsupportedComparisons,
    matchRecords, matchInfo, matchVars, supportedDifference, unsupportedDifference,
    inputSummary, referenceSummary, inputProjectionFailures, referenceProjectionFailures
  },
  supportedSectors = supportedSectorsUpTo[dmax];
  supportedComparisons = KeySelect[sectorComparisons, MemberQ[supportedSectors, #] &];
  unsupportedComparisons = KeySelect[sectorComparisons, ! MemberQ[supportedSectors, #] &];

  supportedDifference = Association @ KeyValueMap[
    Function[{key, record}, key -> record["DifferenceCoordinates"]],
    Select[supportedComparisons, ! TrueQ[#["DifferenceIsZeroQ"]] &]
  ];
  unsupportedDifference = Association @ KeyValueMap[
    Function[{key, record}, key -> record["DifferenceCoordinates"]],
    Select[unsupportedComparisons, ! TrueQ[#["DifferenceIsZeroQ"]] &]
  ];

  matchRecords = collectDifferenceEquationRecords[supportedComparisons];
  matchVars = DeleteDuplicates @ Join[
    {M, \[Mu]bar2, \[Kappa]},
    referenceSolveVariablesFrom[
      referenceData["LambdaReferenceValue"],
      referenceData["KappaReferenceValue"],
      referenceData["EHSign"]
    ]
  ];
  matchInfo = <|
    "Variables" -> DeleteDuplicates @ Join[{Lmu}, DeleteCases[matchVars, \[Mu]bar2]],
    "Equations" -> Lookup[matchRecords, "Equation", {}],
    "SolveResult" -> Missing["SkippedForRemoteStability"],
    "TranslatedSolveResult" -> "Skipped generic symbolic solve in the remote d<=6 run to avoid kernel OOM; use the stored d<=5 final branch and the sector-by-sector d<=6 equations for follow-up analysis.",
    "ReduceResult" -> Missing["SkippedForRemoteStability"],
    "TranslatedReduceResult" -> "Skipped generic symbolic solve in the remote d<=6 run to avoid kernel OOM; the full sector-by-sector equations are stored in MatchEquations.",
    "HasSolution" -> False,
    "SolveSkippedQ" -> True
  |>;

  inputSummary = Association @ KeyValueMap[
    Function[{key, sec},
      key -> <|
        "ProjectionSucceededQ" -> Lookup[sec, "ProjectionSucceededQ", Missing["NotAvailable"]],
        "InputTermCount" -> expressionTermCount[sec["InputExpression"]],
        "ProjectedIBPTermCount" -> expressionTermCount[sec["ProjectedIBPExpression"]],
        "ReducedTermCount" -> expressionTermCount[sec["ReducedExpression"]],
        "PhysicalCoordinateCount" -> Length[sec["PhysicalCoordinates"]]
      |>
    ],
    Association @ KeyValueMap[
      Function[{key, val}, key -> scaledInputSector[key, inputReduction, canonicalData["Factor"]]],
      inputReduction["SectorReductions"]
    ]
  ];

  referenceSummary = reductionSummaryFrom[referenceReduction];
  inputProjectionFailures = Keys @ Select[inputSummary, ! TrueQ[Lookup[#, "ProjectionSucceededQ", True]] &];
  referenceProjectionFailures = Keys @ Select[referenceSummary, ! TrueQ[Lookup[#, "ProjectionSucceededQ", True]] &];

  <|
    "InputSourceFile" -> inputXActFile,
    "CanonicalNormalization" -> canonicalData,
    "CanonicalKineticSign" -> -1,
    "ReferenceData" -> referenceData,
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
    "ExactMatchQ" -> False,
    "StageTimings" -> timings
  |>
];

state = loadCheckpoint[];
data = Lookup[state, "Data", <||>];
timings = Lookup[data, "StageTimings", <||>];
data["InputXActFile"] = inputXActFile;
data["MaxDimension"] = dmax;

If[! KeyExistsQ[data, "ComparedInputExpression"] && ! KeyExistsQ[data, "InputReduction"],
  log["Loading translated xAct input"];
  translatedExpr = Get[inputXActFile];
  log["Normalizing finite part"];
  normalizedExpr = NormalizeMatcheteFinitePart[translatedExpr];
  log["Truncating normalized expression to d<=6"];
  {timings["InputTruncation"], data["ComparedInputExpression"]} = AbsoluteTiming[
    selectTermsByMassDimension[normalizedExpr, dmax]
  ];
  data["StageTimings"] = timings;
  saveCheckpoint["truncated", data];
  Clear[translatedExpr, normalizedExpr];
  Share[];
  ClearSystemCache[];
];

If[! KeyExistsQ[data, "ReferenceData"],
  log["Loading cached sign-flipped EH reference"];
  {timings["ReferenceExpansion"], refFull} = AbsoluteTiming[
    ExpandFixedEHReferenceLagrangian[
      "MaxDimension" -> dmax,
      "LambdaReferenceValue" -> LambdaRefFinal,
      "KappaReferenceValue" -> KappaRefFinal,
      "EHSign" -> -1,
      "CacheDirectory" -> cacheDir,
      "UseCache" -> True,
      "Verbose" -> False
    ]
  ];
  data["ReferenceData"] = KeyDrop[refFull, {"RawExpression", "ReferenceExpression"}];
  data["ReferenceExpression"] = refFull["ReferenceExpression"];
  data["StageTimings"] = timings;
  saveCheckpoint["reference", trimCheckpointData[data]];
  Clear[refFull];
  Share[];
  ClearSystemCache[];
];

If[! KeyExistsQ[data, "InputSectorReductions"], data["InputSectorReductions"] = <||>];
If[! KeyExistsQ[data, "InputReduction"],
  log["Checking input sector reductions"];
  With[{reduced = reduceMissingSectors["input", data["ComparedInputExpression"], data["InputSectorReductions"]]},
    data["InputSectorReductions"] = reduced["Reductions"];
    If[TrueQ[reduced["UpdatedQ"]], saveCheckpoint["inputSectors", trimCheckpointData[data]]];
  ];
  log["Assembling raw input reduction"];
  {timings["InputReductionAssembly"], data["InputReduction"]} = AbsoluteTiming[
    sectorReductionAssociation[data["InputSectorReductions"]]
  ];
  data = KeyDrop[data, {"ComparedInputExpression"}];
  data["StageTimings"] = timings;
  saveCheckpoint["inputReduction", trimCheckpointData[data]];
  Share[];
  ClearSystemCache[];
];

If[! KeyExistsQ[data, "ReferenceSectorReductions"], data["ReferenceSectorReductions"] = <||>];
If[! KeyExistsQ[data, "ReferenceReduction"],
  log["Checking reference sector reductions"];
  With[{reduced = reduceMissingSectors["reference", data["ReferenceExpression"], data["ReferenceSectorReductions"]]},
    data["ReferenceSectorReductions"] = reduced["Reductions"];
    If[TrueQ[reduced["UpdatedQ"]], saveCheckpoint["referenceSectors", trimCheckpointData[data]]];
  ];
  log["Assembling raw reference reduction"];
  {timings["ReferenceReductionAssembly"], data["ReferenceReduction"]} = AbsoluteTiming[
    sectorReductionAssociation[data["ReferenceSectorReductions"]]
  ];
  data = KeyDrop[data, {"ReferenceExpression"}];
  data["StageTimings"] = timings;
  saveCheckpoint["referenceReduction", trimCheckpointData[data]];
  Share[];
  ClearSystemCache[];
];

If[! KeyExistsQ[data, "CanonicalNormalization"],
  log["Computing canonical normalization data"];
  {timings["CanonicalNormalization"], canonData} = AbsoluteTiming[
    Append[
      kineticNormalizationDataFromReduction[
        data["InputReduction"],
        {
          "MaxDimension" -> dmax,
          "CacheDirectory" -> cacheDir,
          "UseCache" -> True,
          "Verbose" -> False
        }
      ],
      "TargetQuadraticSign" -> -1
    ]
  ];
  data["CanonicalNormalization"] = canonData;
  data["StageTimings"] = timings;
  saveCheckpoint["canonical", trimCheckpointData[data]];
  Share[];
  ClearSystemCache[];
];

If[! KeyExistsQ[data, "SectorComparisons"],
  data["SectorComparisons"] = <||>;
];
log["Checking final sector comparisons"];
With[{compared = buildSectorComparisons[data["InputReduction"], data["ReferenceReduction"], Lookup[data["CanonicalNormalization"], "Factor"], data["SectorComparisons"]]},
  data["SectorComparisons"] = compared["Comparisons"];
  data["StageTimings"] = timings;
  saveCheckpoint["sectorComparisons", trimCheckpointData[data]];
];

If[
  ! KeyExistsQ[data, "FinalComparison"] ||
  ! KeyExistsQ[data["FinalComparison"], "VerificationAppliedQ"] ||
  ! KeyExistsQ[data["FinalComparison"], "QuadraticCompletion"] ||
  ! TrueQ[Lookup[data["FinalComparison"], "VerifiedSupportedMatchQ", False]],
  log["Assembling final d<=6 result"];
  {timings["FinalAssembly"], data["FinalComparison"]} = AbsoluteTiming[
    finalizeComparisonResult[
      buildFinalResult[
        data["ReferenceData"],
        data["InputReduction"],
        data["ReferenceReduction"],
        data["CanonicalNormalization"],
        data["SectorComparisons"],
        timings
      ],
      {
        "MaxDimension" -> dmax,
        "CacheDirectory" -> cacheDir,
        "UseCache" -> True,
        "Verbose" -> False
      },
      {
        "UseQuadraticCompletion" -> True,
        "VerificationSubstitutions" -> verificationSubstitutions,
        "VerificationAssumptions" -> verificationAssumptions
      }
    ]
  ];
  data["FinalComparison"] = Append[
    KeyDrop[data["FinalComparison"], "StageTimings"],
    "StageTimings" -> timings
  ];
  data["StageTimings"] = timings;
  saveCheckpoint["comparison", trimCheckpointData[data]];
  Share[];
  ClearSystemCache[];
];

result = data["FinalComparison"];
If[FileExistsQ[crosscheckSummaryFile],
  result = Append[result, "IndependentCrosscheckSummary" -> Get[crosscheckSummaryFile]];
];
Put[result, resultFile];
log["Wrote result file: " <> resultFile];

log["Building TeX report (PDF compilation disabled for remote stability)"];
{timings["ReportBuild"], data["FinalReport"]} = AbsoluteTiming[
  BuildMatcheteEHReport[
    result,
    reportBase,
    "Title" -> "Final ORBIT Comparison to Sign-Flipped Einstein-Hilbert Reference",
    "Author" -> "ORBIT",
    "CompilePDF" -> False,
    "Verbose" -> False
  ]
];
data["StageTimings"] = timings;
saveCheckpoint["report", trimCheckpointData[data]];

Put[
  <|
    "TimingSeconds" -> timings,
    "ExactMatchQ" -> result["ExactMatchQ"],
    "ExactMatchUnderSolveQ" -> Lookup[result, "ExactMatchUnderSolveQ", Missing["NotAvailable"]],
    "UnsupportedSectors" -> result["UnsupportedSectors"],
    "CanonicalKineticSign" -> result["CanonicalKineticSign"],
    "CanonicalNormalization" -> result["CanonicalNormalization"],
    "MatchEquationCount" -> Length[result["MatchEquations"]],
    "SolveSkippedQ" -> Lookup[result["MatchSolutions"], "SolveSkippedQ", False],
    "VerificationAppliedQ" -> Lookup[result, "VerificationAppliedQ", False],
    "VerifiedSupportedMatchQ" -> Lookup[result, "VerifiedSupportedMatchQ", Missing["NotAvailable"]],
    "QuadraticCompletionSummary" -> If[
      AssociationQ[Lookup[result, "QuadraticCompletion", Missing["NotAvailable"]]],
      <|
        "ResidualIsZeroQ" -> result["QuadraticCompletion"]["ResidualIsZeroQ"],
        "PureQuadraticRedefinitionQ" -> result["QuadraticCompletion"]["PureQuadraticRedefinitionQ"],
        "CurvatureCoefficients" -> result["QuadraticCompletion"]["CurvatureCoefficients"]
      |>,
      Missing["NotAvailable"]
    ],
    "ResultFile" -> resultFile,
    "Report" -> data["FinalReport"]
  |>,
  summaryFile
];

log["Final d<=6 comparison complete."];
Print[InputForm[<|
  "TimingSeconds" -> timings,
  "ExactMatchQ" -> result["ExactMatchQ"],
  "ExactMatchUnderSolveQ" -> Lookup[result, "ExactMatchUnderSolveQ", Missing["NotAvailable"]],
  "UnsupportedSectors" -> result["UnsupportedSectors"],
  "CanonicalKineticSign" -> result["CanonicalKineticSign"],
  "MatchEquationCount" -> Length[result["MatchEquations"]],
  "SolveSkippedQ" -> Lookup[result["MatchSolutions"], "SolveSkippedQ", False],
  "VerificationAppliedQ" -> Lookup[result, "VerificationAppliedQ", False],
  "VerifiedSupportedMatchQ" -> Lookup[result, "VerifiedSupportedMatchQ", Missing["NotAvailable"]],
  "QuadraticCompletionSummary" -> If[
    AssociationQ[Lookup[result, "QuadraticCompletion", Missing["NotAvailable"]]],
    <|
      "ResidualIsZeroQ" -> result["QuadraticCompletion"]["ResidualIsZeroQ"],
      "PureQuadraticRedefinitionQ" -> result["QuadraticCompletion"]["PureQuadraticRedefinitionQ"],
      "CurvatureCoefficients" -> result["QuadraticCompletion"]["CurvatureCoefficients"]
    |>,
    Missing["NotAvailable"]
  ],
  "ResultFile" -> resultFile,
  "Report" -> data["FinalReport"]
|>]];

Quit[];
