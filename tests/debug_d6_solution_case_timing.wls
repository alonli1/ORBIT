scriptDir = DirectoryName[$InputFileName];
repoRoot = NestWhile[
  DirectoryName,
  scriptDir,
  ! FileExistsQ[FileNameJoin[{#, "orbit_fixed_eh_comparison.wl"}]] &
];
SetDirectory[repoRoot];

If[! StringStartsQ[$Version, "13.3"],
  Print["FAIL: This timing probe must run under Mathematica 13.3. Current kernel: " <> $Version];
  Exit[2]
];

Get["graviton_basis_toolkit.wl"];
Get["orbit_fixed_eh_comparison.wl"];

storedD6Result = Get[FileNameJoin[{Directory[], "artifacts", "orbit_fixed_eh", "orbit_fixed_eh_comparison_final_result.wl"}]];
storedD6QuadraticAnalysis = Get[FileNameJoin[{Directory[], "artifacts", "orbit_fixed_eh", "orbit_fixed_eh_quadratic_completion_analysis.wl"}]];

inputXActFile = FileNameJoin[{Directory[], "artifacts", "left_only_uv_2_eft_6", "LEFT_only_uv_2_eft_6_xact.wl"}];
cacheDir = If[
  DirectoryQ[FileNameJoin[{Directory[], "cache", "left_only_uv_2_eft_6_cache"}]],
  FileNameJoin[{Directory[], "cache", "left_only_uv_2_eft_6_cache"}],
  FileNameJoin[{Directory[], "cache", "orbit_fixed_eh_cache"}]
];

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

normalizeScalarExpr[expr_, subs_List : {}] := normalizeMatcheteParameterScalars[expr] /. subs;

zeroExprQ[expr_, subs_List : {}, assumptions_ : True] := Module[{checked},
  checked = canonExpr[normalizeScalarExpr[expr, subs]];
  TrueQ[checked === 0] || TrueQ[FullSimplify[checked == 0, assumptions]]
];

zeroScalarQ[expr_, assumptions_ : True] := TrueQ[FullSimplify[normalizeMatcheteParameterScalars[expr] == 0, assumptions]];

zeroVectorQWithAssumptions[list_List, assumptions_ : True] := And @@ (zeroScalarQ[#, assumptions] & /@ list);

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

wrapSectorComparison[state_Association, key_, inputSector_, referenceSector_, sectorData_] := key -> Join[
  sectorComparisonRecord[key, inputSector, referenceSector, sectorData],
  <|
    "SupportedQ" -> MemberQ[state["SupportedSectors"], key],
    "SectorData" -> sectorData
  |>
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
    "HasNonZeroCoefficientDifferenceQ" -> AnyTrue[coefficientDifference, ! zeroScalarQ[#, assumptions] &],
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

Print["Stored Match HasSolution: " <> ToString[Lookup[storedD6Result["MatchSolutions"], "HasSolution", Missing["NotAvailable"]], InputForm]];
Print["Stored VerifiedSupportedMatchQ: " <> ToString[Lookup[storedD6Result, "VerifiedSupportedMatchQ", Missing["NotAvailable"]], InputForm]];

Do[
  Module[{record, coordTiming, coordResult, exprTiming, exprResult},
    record = storedD6Result["SectorComparison"][sector];
    {coordTiming, coordResult} = AbsoluteTiming[
      zeroVectorQWithAssumptions[
        normalizeScalarExpr[#, verificationSubstitutions] & /@ record["DifferenceCoordinates"],
        verificationAssumptions
      ]
    ];
    Print[
      "coords " <> ToString[sector, InputForm] <>
      " time=" <> ToString[coordTiming, InputForm] <>
      " result=" <> ToString[coordResult, InputForm]
    ];
    {exprTiming, exprResult} = AbsoluteTiming[
      zeroExprQ[record["DifferenceExpression"], verificationSubstitutions, verificationAssumptions]
    ];
    Print[
      "expr   " <> ToString[sector, InputForm] <>
      " time=" <> ToString[exprTiming, InputForm] <>
      " result=" <> ToString[exprResult, InputForm]
    ];
  ],
  {sector, storedD6Result["SupportedSectors"]}
];

Print["rebuilding selective D6 interaction sectors"];
d6BasisOpts = {
  "MaxDimension" -> 6,
  "CacheDirectory" -> cacheDir,
  "UseCache" -> True,
  "Verbose" -> False
};
d6InteractionSectors = {{3, 2}, {4, 2}};
{d6BuildTiming, d6State} = AbsoluteTiming @ Module[
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
Print["selective build time=" <> ToString[d6BuildTiming, InputForm]];

Do[
  Module[{timing, summary},
    {timing, summary} = AbsoluteTiming[
      redefinitionDifferenceSummary[d6State, sector, verificationSubstitutions, verificationAssumptions]
    ];
    Print[
      "redef " <> ToString[sector, InputForm] <>
      " time=" <> ToString[timing, InputForm] <>
      " ok=" <> ToString[
        And[
          summary["ReducedDifferenceZeroQ"],
          summary["ProjectedDifferenceMatchesImageDifferenceQ"],
          summary["ExplicitShiftMatchesImageDifferenceQ"],
          summary["ExplicitShiftMatchesProjectedDifferenceQ"],
          summary["ExplicitShiftProjectionResidualZeroQ"]
        ],
        InputForm
      ]
    ];
  ],
  {sector, d6InteractionSectors}
];

d6QuadraticFieldRedefinition = canonExpr @ LinearCombination[
  Lookup[
    storedD6QuadraticAnalysis["QuadraticRedefinitionCoefficients"],
    Range[Length[storedD6QuadraticAnalysis["QuadraticRedefinitionData", "IndependentDeltas"]]],
    0
  ],
  storedD6QuadraticAnalysis["QuadraticRedefinitionData", "IndependentDeltas"]
];

{quadraticShiftTiming, d6QuadraticProjectedShift} = AbsoluteTiming[
  ProjectToIBPUsingSectorData[
    firstOrderShiftFromSubstitution[d6QuadraticFieldRedefinition],
    ComputeSectorData[2, 4, Sequence @@ d6BasisOpts]
  ]
];
Print["quadratic projected shift time=" <> ToString[quadraticShiftTiming, InputForm]];
Print[
  "quadratic checks ok=" <> ToString[
    And[
      zeroExprQ[d6QuadraticProjectedShift["ProjectionResidual"], {}, verificationAssumptions],
      zeroExprQ[
        d6QuadraticProjectedShift["ProjectedExpr"] - storedD6QuadraticAnalysis["QuadraticRedefinitionExpression"],
        {},
        verificationAssumptions
      ],
      zeroExprQ[
        d6QuadraticProjectedShift["ProjectedExpr"] - storedD6QuadraticAnalysis["ProjectedData", "ProjectedExpr"],
        {},
        verificationAssumptions
      ]
    ],
    InputForm
  ]
];

Exit[];
