scriptDir = DirectoryName[$InputFileName];
repoRoot = NestWhile[
  DirectoryName,
  scriptDir,
  ! FileExistsQ[FileNameJoin[{#, "orbit_fixed_eh_comparison.wl"}]] &
];
SetDirectory[repoRoot];

If[! StringStartsQ[System`$Version, "13.3"],
  Print["FAIL: This validation must run under Mathematica 13.3. Current kernel: " <> System`$Version];
  Exit[2]
];

Get["graviton_basis_toolkit.wl"];
Get["orbit_fixed_eh_comparison.wl"];

inputMX = FileNameJoin[{Directory[], "examples", "left_only_uv_2_eft_6", "LEFT_only_uv_2_eft_6.mx"}];
inputXActFile = FileNameJoin[{Directory[], "artifacts", "left_only_uv_2_eft_6", "LEFT_only_uv_2_eft_6_xact.wl"}];
storedD5ResultFile = FileNameJoin[{Directory[], "artifacts", "orbit_fixed_eh", "orbit_fixed_eh_comparison_d5_final_result.wl"}];
storedD6ResultFile = FileNameJoin[{Directory[], "artifacts", "orbit_fixed_eh", "orbit_fixed_eh_comparison_final_result.wl"}];
storedD6QuadraticAnalysisFile = FileNameJoin[{Directory[], "artifacts", "orbit_fixed_eh", "orbit_fixed_eh_quadratic_completion_analysis.wl"}];

cacheDir = If[
  DirectoryQ[FileNameJoin[{Directory[], "cache", "left_only_uv_2_eft_6_cache"}]],
  FileNameJoin[{Directory[], "cache", "left_only_uv_2_eft_6_cache"}],
  FileNameJoin[{Directory[], "cache", "orbit_fixed_eh_cache"}]
];

outputDir = FileNameJoin[{Directory[], "artifacts", "orbit_fixed_eh"}];
If[! DirectoryQ[outputDir], CreateDirectory[outputDir, CreateIntermediateDirectories -> True]];
outputFile = FileNameJoin[{outputDir, "orbit_fixed_eh_solution_case_validation_output.wl"}];

verificationSubstitutions = {
  Scalar[M] -> M,
  Scalar[\[Kappa]] -> \[Kappa],
  Scalar[\[Mu]bar2] -> \[Mu]bar2,
  Sqrt[1/(M^2*\[Kappa]^2)] -> 1/(M*\[Kappa]),
  Sqrt[1/(Scalar[M]^2*Scalar[\[Kappa]]^2)] -> 1/(M*\[Kappa]),
  Sqrt[-(1/(M^2*\[Kappa]^2*(1 + Log[\[Mu]bar2/M^2])))] -> Sqrt[2]/(M*\[Kappa]),
  Sqrt[-(1/((1 + Log[\[Mu]bar2/M^2])*Scalar[M]^2*Scalar[\[Kappa]]^2))] -> Sqrt[2]/(M*\[Kappa]),
  Log[\[Mu]bar2/M^2] -> -3/2,
  Log[Scalar[\[Mu]bar2]/M^2] -> -3/2,
  Log[Scalar[\[Mu]bar2]/Scalar[M]^2] -> -3/2,
  LambdaRefFinal -> 0,
  KappaRefFinal -> (4*Sqrt[3])/M
};

verificationAssumptions = M > 0 && \[Kappa] > 0 && \[Mu]bar2 > 0;

allPassed = True;

reportCheck[label_String, condition_] := If[
  TrueQ[condition],
  Print["PASS: " <> label],
  Print["FAIL: " <> label];
  allPassed = False
];

normalizeScalarExpr[expr_, subs_List : {}] := normalizeMatcheteParameterScalars[expr] /. subs;

zeroExprQ[expr_, subs_List : {}, assumptions_ : True] := Module[{checked},
  checked = canonExpr[normalizeScalarExpr[expr, subs]];
  TrueQ[checked === 0] || TrueQ[FullSimplify[checked == 0, assumptions]]
];

zeroScalarQ[expr_, assumptions_ : True] := TrueQ[FullSimplify[normalizeMatcheteParameterScalars[expr] == 0, assumptions]];

zeroVectorQWithAssumptions[list_List, assumptions_ : True] := And @@ (zeroScalarQ[#, assumptions] & /@ list);

nonZeroVectorQWithAssumptions[list_List, assumptions_ : True] := AnyTrue[
  list,
  ! zeroScalarQ[#, assumptions] &
];

wrapSectorComparison[state_Association, key_, inputSector_, referenceSector_, sectorData_] := Quiet[
  key -> Join[
    sectorComparisonRecord[key, inputSector, referenceSector, sectorData],
    <|
      "SupportedQ" -> MemberQ[state["SupportedSectors"], key],
      "SectorData" -> sectorData
    |>
  ],
  ToCanonical::noident
];

buildComparisonState[input_, dmax_Integer, referenceExprBuilderOpts_List, canonicalKineticSign_Integer] := Module[
  {
    basisOpts, translatedExpr, normalizedExpr, truncatedInputExpr, referenceData,
    referenceExpr, rawInputReduction, canonicalData, reducedInput,
    reducedReference, supportedSectors, allSectors, sectorComparisons
  },

  basisOpts = {
    "MaxDimension" -> dmax,
    "CacheDirectory" -> cacheDir,
    "UseCache" -> True,
    "Verbose" -> False
  };

  translatedExpr = Which[
    StringQ[input] && FileExistsQ[input], LoadMatcheteToXAct[input],
    True, Quiet[canonExpr[input], ToCanonical::noident]
  ];

  normalizedExpr = NormalizeMatcheteFinitePart[translatedExpr];
  truncatedInputExpr = selectTermsByMassDimension[normalizedExpr, dmax];

  referenceData = Quiet[
    ExpandFixedEHReferenceLagrangian[
      Sequence @@ referenceExprBuilderOpts,
      "MaxDimension" -> dmax,
      "CacheDirectory" -> cacheDir,
      "UseCache" -> True,
      "Verbose" -> False
    ],
    ToCanonical::noident
  ];
  referenceExpr = referenceData["ReferenceExpression"];

  rawInputReduction = Quiet[
    ReduceLagrangian[truncatedInputExpr, Sequence @@ basisOpts],
    ToCanonical::noident
  ];
  canonicalData = Append[
    kineticNormalizationDataFromReduction[rawInputReduction, basisOpts],
    "TargetQuadraticSign" -> canonicalKineticSign
  ];
  reducedInput = If[
    TrueQ[Lookup[canonicalData, "SucceededQ", False]],
    canonicalNormalizeReduction[rawInputReduction, canonicalData["Factor"], canonicalKineticSign],
    rawInputReduction
  ];
  reducedReference = Quiet[
    ReduceLagrangian[referenceExpr, Sequence @@ basisOpts],
    ToCanonical::noident
  ];

  supportedSectors = supportedSectorsUpTo[dmax];
  allSectors = Sort @ Union[
    supportedSectors,
    Keys[reducedInput["SectorReductions"]],
    Keys[reducedReference["SectorReductions"]]
  ];

  sectorComparisons = <|
    "SupportedSectors" -> supportedSectors
  |>;
  sectorComparisons = Association @ Table[
    With[
      {
        key = sector,
        inputSector = sectorLookup[reducedInput["SectorReductions"], sector],
        referenceSector = sectorLookup[reducedReference["SectorReductions"], sector],
        sectorData = Which[
          AssociationQ[sectorLookup[reducedInput["SectorReductions"], sector]],
            reducedInput["SectorReductions"][sector]["SectorData"],
          AssociationQ[sectorLookup[reducedReference["SectorReductions"], sector]],
            reducedReference["SectorReductions"][sector]["SectorData"],
          True,
            ComputeSectorData[sector[[1]], sector[[2]], Sequence @@ basisOpts]
        ]
      },
      wrapSectorComparison[
        <|"SupportedSectors" -> supportedSectors|>,
        key,
        inputSector,
        referenceSector,
        sectorData
      ]
    ],
    {sector, allSectors}
  ];

  <|
    "MaxDimension" -> dmax,
    "BasisOptions" -> basisOpts,
    "TranslatedExpression" -> translatedExpr,
    "NormalizedExpression" -> normalizedExpr,
    "ComparedInputExpression" -> truncatedInputExpr,
    "ReferenceData" -> referenceData,
    "ReferenceExpression" -> referenceExpr,
    "CanonicalNormalization" -> canonicalData,
    "RawInputReduction" -> rawInputReduction,
    "ReducedInput" -> reducedInput,
    "ReducedReference" -> reducedReference,
    "SupportedSectors" -> supportedSectors,
    "SectorComparison" -> sectorComparisons
  |>
];

buildSelectiveSectorReductions[inputExpr_, sectors_List, basisOpts_List] := Module[{sectorTerms},
  sectorTerms = SplitTermsBySector[Expand[Quiet[canonExpr[inputExpr], ToCanonical::noident]]];
  Association @ Table[
    key -> Quiet[
      ReduceSectorLagrangianCanonicalInput[
        Lookup[sectorTerms, key, 0],
        key[[1]],
        key[[2]],
        Sequence @@ basisOpts
      ],
      ToCanonical::noident
    ],
    {key, sectors}
  ]
];

canonicalizeSelectiveSectorReductions[sectorReductions_Association, canonicalFactor_, targetQuadraticSign_Integer] := Module[
  {fieldScaleSquared},
  fieldScaleSquared = targetQuadraticSign/canonicalFactor;
  Association @ KeyValueMap[
    Function[{key, sec},
      key -> scaleReducedSector[sec, fieldScaleSquared^(key[[1]]/2)]
    ],
    sectorReductions
  ]
];

firstOrderShiftFromSubstitution[deltaExpr_] := Module[{expr, shiftedDelta},
  expr = Expand[LFP /. HoldPattern[h[x_, y_]] :> (h[x, y] + lam dh[x, y])];
  expr = Coefficient[expr, lam, 1];
  expr = expr /. HoldPattern[dh[x_, y_]] :> (
    shiftedDelta = ReplaceDummies[deltaExpr /. {u -> x, v -> y}];
    shiftedDelta
  );
  expr = ReplaceDummies[expr];
  canonExpr[expr]
];

supportedSectorChecks[state_Association, subs_List, assumptions_] := Association @ KeyValueMap[
  Function[{key, record},
    If[TrueQ[record["SupportedQ"]],
      key -> <|
        "DifferenceZeroQ" -> zeroExprQ[record["DifferenceExpression"], subs, assumptions],
        "DifferenceCoordinatesZeroQ" -> zeroVectorQWithAssumptions[
          normalizeScalarExpr[#, subs] & /@ record["DifferenceCoordinates"],
          assumptions
        ]
      |>,
      Nothing
    ]
  ],
  state["SectorComparison"]
];

redefinitionDifferenceSummary[state_Association, sectorKey_, subs_List, assumptions_] := Module[
  {
    inputSector, referenceSector, sec, coefficientDifference, fieldRedefinition,
    explicitShift, projectedShift, projectedDifference, imageDifference, reducedDifference
  },

  inputSector = state["ReducedInput", "SectorReductions"][sectorKey];
  referenceSector = state["ReducedReference", "SectorReductions"][sectorKey];
  sec = inputSector["SectorData"];

  coefficientDifference = FullSimplify[
    normalizeScalarExpr[
      inputSector["RedefinitionImageCoefficients"] - referenceSector["RedefinitionImageCoefficients"],
      subs
    ],
    assumptions
  ];

  fieldRedefinition = If[
    coefficientDifference === {} || sec["RedefIndependentDeltas"] === {},
    0,
    canonExpr @ LinearCombination[coefficientDifference, sec["RedefIndependentDeltas"]]
  ];

  explicitShift = firstOrderShiftFromSubstitution[fieldRedefinition];
  projectedShift = ProjectToIBPUsingSectorData[explicitShift, sec];
  projectedDifference = canonExpr @ normalizeScalarExpr[
    inputSector["ProjectedIBPExpression"] - referenceSector["ProjectedIBPExpression"],
    subs
  ];
  imageDifference = canonExpr @ normalizeScalarExpr[
    inputSector["RedefinitionImageExpression"] - referenceSector["RedefinitionImageExpression"],
    subs
  ];
  reducedDifference = canonExpr @ normalizeScalarExpr[
    inputSector["ReducedExpression"] - referenceSector["ReducedExpression"],
    subs
  ];

  <|
    "Sector" -> sectorKey,
    "CoefficientDifference" -> coefficientDifference,
    "HasNonZeroCoefficientDifferenceQ" -> nonZeroVectorQWithAssumptions[coefficientDifference, assumptions],
    "FieldRedefinition" -> fieldRedefinition,
    "ExplicitShiftExpression" -> explicitShift,
    "ExplicitShiftProjectionSucceededQ" -> TrueQ[projectedShift["ProjectionSucceededQ"]],
    "ExplicitShiftProjectionResidual" -> projectedShift["ProjectionResidual"],
    "ProjectedExplicitShift" -> projectedShift["ProjectedExpr"],
    "ProjectedIBPDifference" -> projectedDifference,
    "RedefinitionImageDifference" -> imageDifference,
    "ReducedDifference" -> reducedDifference,
    "ReducedDifferenceZeroQ" -> zeroExprQ[reducedDifference, {}, assumptions],
    "ProjectedDifferenceMatchesImageDifferenceQ" -> zeroExprQ[projectedDifference - imageDifference, {}, assumptions],
    "ExplicitShiftMatchesImageDifferenceQ" -> zeroExprQ[projectedShift["ProjectedExpr"] - imageDifference, {}, assumptions],
    "ExplicitShiftMatchesProjectedDifferenceQ" -> zeroExprQ[projectedShift["ProjectedExpr"] - projectedDifference, {}, assumptions],
    "ExplicitShiftProjectionResidualZeroQ" -> zeroExprQ[projectedShift["ProjectionResidual"], {}, assumptions]
  |>
];

interactionRedefinitionChecks[state_Association, subs_List, assumptions_] := Module[
  {candidateSectors, summaries},
  candidateSectors = Select[
    Sort @ Intersection[
      Keys[state["ReducedInput", "SectorReductions"]],
      Keys[state["ReducedReference", "SectorReductions"]]
    ],
    #[[1]] >= 3 && #[[2]] >= 2 && MemberQ[state["SupportedSectors"], #] &
  ];
  summaries = Association @ Table[
    sector -> redefinitionDifferenceSummary[state, sector, subs, assumptions],
    {sector, candidateSectors}
  ];
  summaries
];

matchEquationSatisfactionSummary[state_Association, matchVariables_List, subs_List, assumptions_] := Module[
  {supportedComparisons, records, equations, satisfiedQ},
  supportedComparisons = KeySelect[state["SectorComparison"], MemberQ[state["SupportedSectors"], #] &];
  records = collectDifferenceEquationRecords[supportedComparisons];
  equations = Lookup[records, "Equation", {}];
  satisfiedQ = And @@ (TrueQ[FullSimplify[normalizeScalarExpr[#, subs], assumptions]] & /@ equations);
  <|
    "EquationCount" -> Length[equations],
    "EquationsSatisfiedQ" -> satisfiedQ,
    "MatchRecords" -> records,
    "MatchInfo" -> solveMatchSystem[records, matchVariables]
  |>
];

matchEquationWitnessSummary[state_Association, subs_List, assumptions_] := Module[
  {supportedComparisons, records, equations, satisfiedQ},
  supportedComparisons = KeySelect[state["SectorComparison"], MemberQ[state["SupportedSectors"], #] &];
  records = collectDifferenceEquationRecords[supportedComparisons];
  equations = Lookup[records, "Equation", {}];
  satisfiedQ = And @@ (TrueQ[FullSimplify[normalizeScalarExpr[#, subs], assumptions]] & /@ equations);
  <|
    "EquationCount" -> Length[equations],
    "EquationsSatisfiedQ" -> satisfiedQ,
    "MatchRecords" -> records,
    "WitnessSubstitutions" -> subs
  |>
];

Print["[D5] building comparison state from the Matchete MX input"];
{d5BuildTime, d5State} = AbsoluteTiming @ buildComparisonState[
  inputMX,
  5,
  {
    "LambdaReferenceValue" -> LambdaRefFinal,
    "KappaReferenceValue" -> KappaRefFinal,
    "EHSign" -> -1
  },
  -1
];

Print["[D5] evaluating exact-match equations and explicit redefinitions"];
d5MatchSummary = matchEquationSatisfactionSummary[
  d5State,
  DeleteDuplicates @ Join[
    {M, \[Mu]bar2, \[Kappa]},
    referenceSolveVariablesFrom[LambdaRefFinal, KappaRefFinal, -1]
  ],
  verificationSubstitutions,
  verificationAssumptions
];
d5SupportedChecks = supportedSectorChecks[d5State, verificationSubstitutions, verificationAssumptions];
d5RedefinitionChecks = interactionRedefinitionChecks[d5State, verificationSubstitutions, verificationAssumptions];

storedD5Result = If[FileExistsQ[storedD5ResultFile], Get[storedD5ResultFile], Missing["NotAvailable"]];
storedD6Result = If[FileExistsQ[storedD6ResultFile], Get[storedD6ResultFile], Missing["NotAvailable"]];
storedD6QuadraticAnalysis = If[FileExistsQ[storedD6QuadraticAnalysisFile], Get[storedD6QuadraticAnalysisFile], Missing["NotAvailable"]];

reportCheck["D5 match system has a symbolic solution", TrueQ[d5MatchSummary["MatchInfo", "HasSolution"]]];
reportCheck["D5 final substitutions satisfy every supported-sector matching equation", TrueQ[d5MatchSummary["EquationsSatisfiedQ"]]];
reportCheck[
  "D5 supported-sector differences vanish after substitution",
  And @@ Lookup[Values[d5SupportedChecks], "DifferenceZeroQ", {}]
];
reportCheck[
  "D5 supported-sector coordinates vanish after substitution",
  And @@ Lookup[Values[d5SupportedChecks], "DifferenceCoordinatesZeroQ", {}]
];
reportCheck[
  "D5 explicit field redefinition reconstruction passes in every nontrivial interaction sector",
  And @@ Join[
    Lookup[Values[d5RedefinitionChecks], "ReducedDifferenceZeroQ", {}],
    Lookup[Values[d5RedefinitionChecks], "ProjectedDifferenceMatchesImageDifferenceQ", {}],
    Lookup[Values[d5RedefinitionChecks], "ExplicitShiftMatchesImageDifferenceQ", {}],
    Lookup[Values[d5RedefinitionChecks], "ExplicitShiftMatchesProjectedDifferenceQ", {}],
    Lookup[Values[d5RedefinitionChecks], "ExplicitShiftProjectionResidualZeroQ", {}]
  ]
];

Print["[D6] rebuilding only the supported interaction sectors needed for explicit field-redefinition checks"];
d6BasisOpts = {
  "MaxDimension" -> 6,
  "CacheDirectory" -> cacheDir,
  "UseCache" -> True,
  "Verbose" -> False
};
d6InteractionSectors = {{3, 2}, {4, 2}};
{d6BuildTime, d6State} = AbsoluteTiming @ Module[
  {
    translatedExpr, normalizedExpr, truncatedInputExpr, referenceExpr,
    rawInputSectorReductions, canonicalizedInputSectorReductions,
    referenceSectorReductions, sectorComparisons
  },
  translatedExpr = Get[inputXActFile];
  normalizedExpr = NormalizeMatcheteFinitePart[translatedExpr];
  truncatedInputExpr = selectTermsByMassDimension[normalizedExpr, 6];
  referenceExpr = Quiet[
    ExpandFixedEHReferenceLagrangian[
      "MaxDimension" -> 6,
      "LambdaReferenceValue" -> LambdaRefFinal,
      "KappaReferenceValue" -> KappaRefFinal,
      "EHSign" -> -1,
      "CacheDirectory" -> cacheDir,
      "UseCache" -> True,
      "Verbose" -> False
    ]["ReferenceExpression"],
    ToCanonical::noident
  ];
  rawInputSectorReductions = buildSelectiveSectorReductions[truncatedInputExpr, d6InteractionSectors, d6BasisOpts];
  canonicalizedInputSectorReductions = canonicalizeSelectiveSectorReductions[
    rawInputSectorReductions,
    storedD6Result["CanonicalNormalization", "Factor"],
    storedD6Result["CanonicalKineticSign"]
  ];
  referenceSectorReductions = buildSelectiveSectorReductions[referenceExpr, d6InteractionSectors, d6BasisOpts];
  sectorComparisons = Association @ Table[
    With[
      {
        key = sector,
        inputSector = canonicalizedInputSectorReductions[sector],
        referenceSector = referenceSectorReductions[sector],
        sectorData = canonicalizedInputSectorReductions[sector]["SectorData"]
      },
      wrapSectorComparison[
        <|"SupportedSectors" -> storedD6Result["SupportedSectors"]|>,
        key,
        inputSector,
        referenceSector,
        sectorData
      ]
    ],
    {sector, d6InteractionSectors}
  ];
  <|
    "BasisOptions" -> d6BasisOpts,
    "CanonicalNormalization" -> storedD6Result["CanonicalNormalization"],
    "SupportedSectors" -> storedD6Result["SupportedSectors"],
    "ReducedInput" -> <|"SectorReductions" -> canonicalizedInputSectorReductions|>,
    "ReducedReference" -> <|"SectorReductions" -> referenceSectorReductions|>,
    "SectorComparison" -> sectorComparisons
  |>
];

Print["[D6] checking supported-sector equations, interaction redefinitions, and quadratic completion"];
d6MatchSummary = matchEquationWitnessSummary[
  storedD6Result,
  verificationSubstitutions,
  verificationAssumptions
];
d6SupportedChecks = supportedSectorChecks[storedD6Result, verificationSubstitutions, verificationAssumptions];
d6RedefinitionChecks = interactionRedefinitionChecks[d6State, verificationSubstitutions, verificationAssumptions];
d6QuadraticCompletion = storedD6QuadraticAnalysis;

d6QuadraticFieldRedefinition = If[
  AssociationQ[d6QuadraticCompletion] &&
    AssociationQ[Lookup[d6QuadraticCompletion, "QuadraticRedefinitionData", Missing["NotAvailable"]]],
  canonExpr @ LinearCombination[
    Lookup[
      d6QuadraticCompletion["QuadraticRedefinitionCoefficients"],
      Range[Length[d6QuadraticCompletion["QuadraticRedefinitionData", "IndependentDeltas"]]],
      0
    ],
    d6QuadraticCompletion["QuadraticRedefinitionData", "IndependentDeltas"]
  ],
  0
];

d6QuadraticImageCoefficients = If[
  AssociationQ[d6QuadraticCompletion] &&
    AssociationQ[Lookup[d6QuadraticCompletion, "QuadraticRedefinitionCoefficients", Missing["NotAvailable"]]],
  Lookup[
    d6QuadraticCompletion["QuadraticRedefinitionCoefficients"],
    Range[Length[d6QuadraticCompletion["QuadraticRedefinitionData", "IndependentVectors"]]],
    0
  ],
  {}
];

d6QuadraticReconstructedCoordinates = If[
  AssociationQ[d6QuadraticCompletion] &&
    ListQ[Lookup[d6QuadraticCompletion["QuadraticRedefinitionData"], "IndependentVectors", Missing["NotAvailable"]]],
  Total[MapThread[#1*#2 &, {d6QuadraticImageCoefficients, d6QuadraticCompletion["QuadraticRedefinitionData", "IndependentVectors"]}]],
  {}
];

reportCheck["D6 witness substitutions satisfy every supported-sector matching equation", TrueQ[d6MatchSummary["EquationsSatisfiedQ"]]];
reportCheck["D6 stored supported-sector verification reports success", TrueQ[Lookup[storedD6Result, "VerifiedSupportedMatchQ", False]]];
reportCheck[
  "D6 supported-sector differences vanish after substitution",
  And @@ Lookup[Values[d6SupportedChecks], "DifferenceZeroQ", {}]
];
reportCheck[
  "D6 supported-sector coordinates vanish after substitution",
  And @@ Lookup[Values[d6SupportedChecks], "DifferenceCoordinatesZeroQ", {}]
];
reportCheck[
  "D6 explicit interaction-sector field redefinitions pass in every nontrivial supported interaction sector",
  And @@ Join[
    Lookup[Values[d6RedefinitionChecks], "ReducedDifferenceZeroQ", {}],
    Lookup[Values[d6RedefinitionChecks], "ProjectedDifferenceMatchesImageDifferenceQ", {}],
    Lookup[Values[d6RedefinitionChecks], "ExplicitShiftMatchesImageDifferenceQ", {}],
    Lookup[Values[d6RedefinitionChecks], "ExplicitShiftMatchesProjectedDifferenceQ", {}],
    Lookup[Values[d6RedefinitionChecks], "ExplicitShiftProjectionResidualZeroQ", {}]
  ]
];
reportCheck["D6 quadratic completion leaves zero residual", TrueQ[Lookup[d6QuadraticCompletion, "ResidualIsZeroQ", False]]];
reportCheck[
  "D6 quadratic completion has zero curvature-squared coefficients",
  AssociationQ[Lookup[d6QuadraticCompletion, "CurvatureCoefficients", Missing["NotAvailable"]]] &&
    zeroVectorQWithAssumptions[Values[d6QuadraticCompletion["CurvatureCoefficients"]], verificationAssumptions]
];
reportCheck[
  "D6 quadratic difference lies entirely in the higher-derivative field-redefinition image",
  TrueQ[Lookup[d6QuadraticCompletion["Decomposition"], "HasSolution", False]] &&
    zeroVectorQWithAssumptions[
      d6QuadraticReconstructedCoordinates - d6QuadraticCompletion["ProjectedData", "Coordinates"],
      verificationAssumptions
    ]
];

storedArtifactChecks = <|
  "StoredD5ResultPresentQ" -> FileExistsQ[storedD5ResultFile],
  "StoredD6ResultPresentQ" -> FileExistsQ[storedD6ResultFile],
  "StoredD5ExactMatchQ" -> If[AssociationQ[storedD5Result], TrueQ[storedD5Result["ExactMatchQ"]], Missing["NotAvailable"]],
  "StoredD6ExactMatchQ" -> If[AssociationQ[storedD6Result], TrueQ[storedD6Result["ExactMatchQ"]], Missing["NotAvailable"]],
  "StoredD6VerifiedSupportedMatchQ" -> If[
    AssociationQ[storedD6Result],
    TrueQ[storedD6Result["VerifiedSupportedMatchQ"]],
    Missing["NotAvailable"]
  ],
  "StoredD6QuadraticAnalysisPresentQ" -> FileExistsQ[storedD6QuadraticAnalysisFile]
|>;

results = <|
  "GeneratedOn" -> DateString[{"ISODate", " ", "Time"}],
  "KernelVersion" -> System`$Version,
  "CacheDirectory" -> cacheDir,
  "VerificationSubstitutions" -> verificationSubstitutions,
  "VerificationAssumptions" -> verificationAssumptions,
  "AllChecksPassedQ" -> allPassed,
  "StoredArtifactChecks" -> storedArtifactChecks,
  "D5" -> <|
    "BuildTimeSeconds" -> d5BuildTime,
    "CanonicalNormalization" -> d5State["CanonicalNormalization"],
    "MatchEquationCount" -> d5MatchSummary["EquationCount"],
    "MatchEquationsSatisfiedQ" -> d5MatchSummary["EquationsSatisfiedQ"],
    "HasSymbolicSolutionQ" -> Lookup[d5MatchSummary["MatchInfo"], "HasSolution", Missing["NotAvailable"]],
    "MatchInfo" -> d5MatchSummary["MatchInfo"],
    "SupportedSectorChecks" -> d5SupportedChecks,
    "RedefinitionChecks" -> d5RedefinitionChecks,
    "AllSupportedDifferencesVanishQ" -> And @@ Lookup[Values[d5SupportedChecks], "DifferenceZeroQ", {}],
    "AllExplicitRedefinitionChecksPassQ" -> And @@ Join[
      Lookup[Values[d5RedefinitionChecks], "ReducedDifferenceZeroQ", {}],
      Lookup[Values[d5RedefinitionChecks], "ProjectedDifferenceMatchesImageDifferenceQ", {}],
      Lookup[Values[d5RedefinitionChecks], "ExplicitShiftMatchesImageDifferenceQ", {}],
      Lookup[Values[d5RedefinitionChecks], "ExplicitShiftMatchesProjectedDifferenceQ", {}],
      Lookup[Values[d5RedefinitionChecks], "ExplicitShiftProjectionResidualZeroQ", {}]
    ]
  |>,
  "D6" -> <|
    "BuildTimeSeconds" -> d6BuildTime,
    "CanonicalNormalization" -> d6State["CanonicalNormalization"],
    "MatchEquationCount" -> d6MatchSummary["EquationCount"],
    "MatchEquationsSatisfiedQ" -> d6MatchSummary["EquationsSatisfiedQ"],
    "StoredSupportedVerificationQ" -> Lookup[storedD6Result, "VerifiedSupportedMatchQ", Missing["NotAvailable"]],
    "InteractionSectorsRechecked" -> d6InteractionSectors,
    "SupportedSectorChecks" -> d6SupportedChecks,
    "RedefinitionChecks" -> d6RedefinitionChecks,
    "QuadraticCompletion" -> <|
      "CurvatureCoefficients" -> Lookup[d6QuadraticCompletion, "CurvatureCoefficients", Missing["NotAvailable"]],
      "QuadraticRedefinitionCoefficients" -> Lookup[d6QuadraticCompletion, "QuadraticRedefinitionCoefficients", Missing["NotAvailable"]],
      "FieldRedefinition" -> d6QuadraticFieldRedefinition,
      "ReconstructedImageCoordinates" -> d6QuadraticReconstructedCoordinates,
      "ProjectedDifferenceCoordinates" -> Lookup[d6QuadraticCompletion["ProjectedData"], "Coordinates", Missing["NotAvailable"]],
      "ImageCoordinateReconstructionMatchesQ" -> zeroVectorQWithAssumptions[
        d6QuadraticReconstructedCoordinates - Lookup[d6QuadraticCompletion["ProjectedData"], "Coordinates", {}],
        verificationAssumptions
      ],
      "QuadraticRedefinitionExpression" -> Lookup[d6QuadraticCompletion, "QuadraticRedefinitionExpression", Missing["NotAvailable"]],
      "ProjectedDifferenceExpression" -> Lookup[d6QuadraticCompletion["ProjectedData"], "ProjectedExpr", Missing["NotAvailable"]],
      "DecompositionHasSolutionQ" -> Lookup[d6QuadraticCompletion["Decomposition"], "HasSolution", Missing["NotAvailable"]],
      "ResidualExpression" -> Lookup[d6QuadraticCompletion, "ResidualExpression", Missing["NotAvailable"]],
      "ResidualIsZeroQ" -> Lookup[d6QuadraticCompletion, "ResidualIsZeroQ", Missing["NotAvailable"]],
      "PureQuadraticRedefinitionQ" -> Lookup[d6QuadraticCompletion, "PureQuadraticRedefinitionQ", Missing["NotAvailable"]]
    |>,
    "AllSupportedDifferencesVanishQ" -> And @@ Lookup[Values[d6SupportedChecks], "DifferenceZeroQ", {}],
    "AllExplicitRedefinitionChecksPassQ" -> And @@ Join[
      Lookup[Values[d6RedefinitionChecks], "ReducedDifferenceZeroQ", {}],
      Lookup[Values[d6RedefinitionChecks], "ProjectedDifferenceMatchesImageDifferenceQ", {}],
      Lookup[Values[d6RedefinitionChecks], "ExplicitShiftMatchesImageDifferenceQ", {}],
      Lookup[Values[d6RedefinitionChecks], "ExplicitShiftMatchesProjectedDifferenceQ", {}],
      Lookup[Values[d6RedefinitionChecks], "ExplicitShiftProjectionResidualZeroQ", {}]
    ]
  |>
|>;

Put[results, outputFile];
Print["Wrote validation artifact: " <> outputFile];

If[allPassed,
  Print["All solution-case validation tests PASSED."],
  Print["Some solution-case validation tests FAILED."];
  If[! TrueQ[$OrbitEmbeddedValidationMode],
    Exit[1]
  ]
];

results
