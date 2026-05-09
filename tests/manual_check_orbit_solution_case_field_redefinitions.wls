scriptDir = DirectoryName[$InputFileName];
repoRoot = NestWhile[
  DirectoryName,
  scriptDir,
  ! FileExistsQ[FileNameJoin[{#, "orbit_fixed_eh_comparison.wl"}]] &
];
SetDirectory[repoRoot];

If[! StringStartsQ[$Version, "13.3"],
  Print["FAIL: This manual-check script must run under Mathematica 13.3. Current kernel: " <> $Version];
  Exit[2]
];

Get["graviton_basis_toolkit.wl"];
Get["orbit_fixed_eh_comparison.wl"];

storedD5ResultFile = FileNameJoin[{Directory[], "artifacts", "orbit_fixed_eh", "orbit_fixed_eh_comparison_d5_final_result.wl"}];
storedD6ResultFile = FileNameJoin[{Directory[], "artifacts", "orbit_fixed_eh", "orbit_fixed_eh_comparison_final_result.wl"}];
storedD6QuadraticAnalysisFile = FileNameJoin[{Directory[], "artifacts", "orbit_fixed_eh", "orbit_fixed_eh_quadratic_completion_analysis.wl"}];
fieldRedefinitionsFile = FileNameJoin[{Directory[], "tests", "artifacts", "orbit_solution_case_field_redefinitions.wl"}];

outputDir = FileNameJoin[{Directory[], "tests", "artifacts"}];
If[! DirectoryQ[outputDir], CreateDirectory[outputDir, CreateIntermediateDirectories -> True]];
outputFile = FileNameJoin[{outputDir, "orbit_solution_case_manual_check_output.wl"}];

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

zeroVectorQWithAssumptions[list_List, assumptions_ : True] := And @@ (
  TrueQ[FullSimplify[normalizeMatcheteParameterScalars[#] == 0, assumptions]] & /@ list
);

parameterDerivativeRules = {
  HoldPattern[PD[_][M]] :> 0,
  HoldPattern[PD[_][\[Kappa]]] :> 0,
  HoldPattern[PD[_][\[Mu]bar2]] :> 0,
  HoldPattern[PD[_][LambdaRefFinal]] :> 0,
  HoldPattern[PD[_][KappaRefFinal]] :> 0,
  HoldPattern[PD[_][Scalar[M]]] :> 0,
  HoldPattern[PD[_][Scalar[\[Kappa]]]] :> 0,
  HoldPattern[PD[_][Scalar[\[Mu]bar2]]] :> 0
};

removeParameterDerivatives[expr_] := FixedPoint[
  Expand[# /. parameterDerivativeRules] &,
  expr
];

supportedSectorResidualExpressions[result_Association, subs_List] := Association @ KeyValueMap[
  Function[{sector, record},
    If[TrueQ[Lookup[record, "SupportedQ", False]],
      sector -> canonExpr[normalizeScalarExpr[record["DifferenceExpression"], subs]],
      Nothing
    ]
  ],
  result["SectorComparison"]
];

supportedSectorResidualCoordinates[result_Association, subs_List] := Association @ KeyValueMap[
  Function[{sector, record},
    If[TrueQ[Lookup[record, "SupportedQ", False]],
      sector -> (
        FullSimplify[normalizeScalarExpr[#, subs], verificationAssumptions] & /@
          Lookup[record, "DifferenceCoordinates", {}]
      ),
      Nothing
    ]
  ],
  result["SectorComparison"]
];

totalResidualExpression[sectorResiduals_Association] := If[
  sectorResiduals === <||>,
  0,
  canonExpr @ Total[Values[sectorResiduals]]
];

storedD5Result = Get[storedD5ResultFile];
storedD6Result = Get[storedD6ResultFile];
storedD6QuadraticAnalysis = Get[storedD6QuadraticAnalysisFile];
fieldRedefinitions = Get[fieldRedefinitionsFile];

d5ResidualExpressions = supportedSectorResidualExpressions[storedD5Result, verificationSubstitutions];
d5ResidualCoordinates = supportedSectorResidualCoordinates[storedD5Result, verificationSubstitutions];
d5TotalResidual = totalResidualExpression[d5ResidualExpressions];

d6ResidualExpressions = supportedSectorResidualExpressions[storedD6Result, verificationSubstitutions];
d6ResidualCoordinates = supportedSectorResidualCoordinates[storedD6Result, verificationSubstitutions];
d6TotalResidual = totalResidualExpression[d6ResidualExpressions];

d6QuadraticFieldRedefinitionFriendly = fieldRedefinitions["D6", "QuadraticFourDerivativeFieldRedefinition"];
d6QuadraticFieldRedefinition = canonExpr @ LinearCombination[
  Lookup[
    storedD6QuadraticAnalysis["QuadraticRedefinitionCoefficients"],
    Range[Length[storedD6QuadraticAnalysis["QuadraticRedefinitionData", "IndependentDeltas"]]],
    0
  ],
  storedD6QuadraticAnalysis["QuadraticRedefinitionData", "IndependentDeltas"]
];
d6QuadraticDirectShift = Quiet[
  canonExpr @ removeParameterDerivatives @ ShiftFromRedefExpr[d6QuadraticFieldRedefinition],
  ToCanonical::noident
];
d6QuadraticDirectShiftSectors = SplitTermsBySector[Expand[d6QuadraticDirectShift]];
d6QuadraticImageCoefficients = Lookup[
  storedD6QuadraticAnalysis["QuadraticRedefinitionCoefficients"],
  Range[Length[storedD6QuadraticAnalysis["QuadraticRedefinitionData", "IndependentVectors"]]],
  0
];
d6QuadraticReconstructedCoordinates = Total[
  MapThread[
    #1 * #2 &,
    {d6QuadraticImageCoefficients, storedD6QuadraticAnalysis["QuadraticRedefinitionData", "IndependentVectors"]}
  ]
];
d6QuadraticProjectedCoordinates = storedD6QuadraticAnalysis["ProjectedData", "Coordinates"];
d6QuadraticCoordinateResidual = d6QuadraticReconstructedCoordinates - d6QuadraticProjectedCoordinates;
d6QuadraticExpressionResidual = canonExpr[
  storedD6QuadraticAnalysis["QuadraticRedefinitionExpression"] -
  storedD6QuadraticAnalysis["ProjectedData", "ProjectedExpr"]
];

results = <|
  "GeneratedOn" -> DateString[{"ISODate", " ", "Time"}],
  "KernelVersion" -> System`$Version,
  "VerificationSubstitutions" -> verificationSubstitutions,
  "VerificationAssumptions" -> verificationAssumptions,
  "D5" -> <|
    "WitnessSubstitutions" -> verificationSubstitutions,
    "SupportedInteractionFieldRedefinitions" -> fieldRedefinitions["D5", "SupportedInteractionFieldRedefinitions"],
    "SupportedSectorResidualExpressions" -> d5ResidualExpressions,
    "SupportedSectorResidualCoordinates" -> d5ResidualCoordinates,
    "TotalSupportedResidualExpression" -> d5TotalResidual,
    "TotalSupportedResidualZeroQ" -> zeroExprQ[d5TotalResidual, {}, verificationAssumptions]
  |>,
  "D6" -> <|
    "WitnessSubstitutions" -> verificationSubstitutions,
    "SupportedInteractionFieldRedefinitions" -> fieldRedefinitions["D6", "SupportedInteractionFieldRedefinitions"],
    "SupportedSectorResidualExpressions" -> d6ResidualExpressions,
    "SupportedSectorResidualCoordinates" -> d6ResidualCoordinates,
    "TotalSupportedResidualExpression" -> d6TotalResidual,
    "TotalSupportedResidualZeroQ" -> zeroExprQ[d6TotalResidual, {}, verificationAssumptions],
    "QuadraticFourDerivative" -> <|
      "FieldRedefinitionFriendly" -> d6QuadraticFieldRedefinitionFriendly,
      "FieldRedefinitionXAct" -> d6QuadraticFieldRedefinition,
      "DirectFirstOrderShiftFromSubstitution" -> d6QuadraticDirectShift,
      "DirectShiftSectors" -> Keys[d6QuadraticDirectShiftSectors],
      "ProjectedImageExpression" -> storedD6QuadraticAnalysis["QuadraticRedefinitionExpression"],
      "ProjectedDifferenceExpression" -> storedD6QuadraticAnalysis["ProjectedData", "ProjectedExpr"],
      "ProjectedExpressionResidual" -> d6QuadraticExpressionResidual,
      "ProjectedExpressionResidualZeroQ" -> zeroExprQ[d6QuadraticExpressionResidual, {}, verificationAssumptions],
      "ReconstructedImageCoordinates" -> d6QuadraticReconstructedCoordinates,
      "ProjectedDifferenceCoordinates" -> d6QuadraticProjectedCoordinates,
      "CoordinateResidual" -> d6QuadraticCoordinateResidual,
      "CoordinateResidualZeroQ" -> zeroVectorQWithAssumptions[d6QuadraticCoordinateResidual, verificationAssumptions],
      "CurvatureSquaredCoefficients" -> storedD6QuadraticAnalysis["CurvatureCoefficients"],
      "ResidualExpression" -> storedD6QuadraticAnalysis["ResidualExpression"],
      "ResidualExpressionZeroQ" -> zeroExprQ[storedD6QuadraticAnalysis["ResidualExpression"], {}, verificationAssumptions]
    |>
  |>
|>;

Put[results, outputFile];

Print["Wrote manual-check artifact: " <> outputFile];
Print["D5 total supported residual zero: " <> ToString[results["D5", "TotalSupportedResidualZeroQ"], InputForm]];
Print["D6 total supported residual zero: " <> ToString[results["D6", "TotalSupportedResidualZeroQ"], InputForm]];
Print["D6 projected {2,4} image residual zero: " <> ToString[results["D6", "QuadraticFourDerivative", "ProjectedExpressionResidualZeroQ"], InputForm]];
Print["D6 projected {2,4} coordinate residual zero: " <> ToString[results["D6", "QuadraticFourDerivative", "CoordinateResidualZeroQ"], InputForm]];
Print["D6 quadratic residual expression zero: " <> ToString[results["D6", "QuadraticFourDerivative", "ResidualExpressionZeroQ"], InputForm]];

If[
  ! TrueQ[results["D5", "TotalSupportedResidualZeroQ"]] ||
  ! TrueQ[results["D6", "TotalSupportedResidualZeroQ"]] ||
  ! TrueQ[results["D6", "QuadraticFourDerivative", "ProjectedExpressionResidualZeroQ"]] ||
  ! TrueQ[results["D6", "QuadraticFourDerivative", "CoordinateResidualZeroQ"]] ||
  ! TrueQ[results["D6", "QuadraticFourDerivative", "ResidualExpressionZeroQ"]],
  Exit[1]
];

results
