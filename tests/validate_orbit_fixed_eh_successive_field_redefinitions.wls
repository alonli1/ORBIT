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
outputDir = FileNameJoin[{Directory[], "artifacts", "orbit_fixed_eh"}];
If[! DirectoryQ[outputDir], CreateDirectory[outputDir, CreateIntermediateDirectories -> True]];
outputFile = FileNameJoin[{outputDir, "orbit_fixed_eh_successive_field_redefinitions_output.wl"}];

cacheDir = If[
  DirectoryQ[FileNameJoin[{Directory[], "cache", "left_only_uv_2_eft_6_cache"}]],
  FileNameJoin[{Directory[], "cache", "left_only_uv_2_eft_6_cache"}],
  FileNameJoin[{Directory[], "cache", "orbit_fixed_eh_cache"}]
];

basisOpts = {
  "MaxDimension" -> 6,
  "CacheDirectory" -> cacheDir,
  "UseCache" -> True,
  "Verbose" -> False
};

witnessSubstitutions = {
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

witnessAssumptions = M > 0 && \[Kappa] > 0 && \[Mu]bar2 > 0;
relevantSectors = {{2, 2}, {2, 4}, {3, 2}, {4, 2}};

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

normalizeScalarExpr[expr_] := normalizeMatcheteParameterScalars[expr];

removeParameterDerivatives[expr_] := FixedPoint[
  Expand[# /. parameterDerivativeRules] &,
  expr
];

zeroExprQ[expr_, assumptions_ : True] := Module[{checked},
  checked = Quiet[canonExpr[normalizeScalarExpr[expr]], ToCanonical::noident];
  TrueQ[checked === 0] || TrueQ[FullSimplify[checked == 0, assumptions]]
];

zeroVectorQWithAssumptions[list_List, assumptions_ : True] := And @@ (
  TrueQ[FullSimplify[normalizeScalarExpr[#] == 0, assumptions]] & /@ list
);

projectedExpressionFromReduction[red_Association] := canonExpr @ Total[
  Lookup[Values[red["SectorReductions"]], "ProjectedIBPExpression", {}]
];

relevantBySector[expr_] := Module[{split},
  split = SplitTermsBySector[Expand[canonExpr[expr]]];
  Association @ Table[
    sector -> If[KeyExistsQ[split, sector], split[sector], 0],
    {sector, relevantSectors}
  ]
];

simplifyDisplayExpr[expr_] := Module[{clean},
  clean = normalizeScalarExpr[expr];
  If[
    TrueQ[FullSimplify[clean == 0, witnessAssumptions]],
    0,
    FullSimplify[clean, witnessAssumptions]
  ]
];

displayBySector[expr_] := Association @ KeyValueMap[
  #1 -> simplifyDisplayExpr[#2] &,
  relevantBySector[expr]
];

firstOrderShiftFromSubstitution[deltaExpr_] := Module[{expr, shiftedDelta},
  expr = Expand[LFP /. HoldPattern[h[x_, y_]] :> (h[x, y] + lam dh[x, y])];
  expr = Coefficient[expr, lam, 1];
  expr = expr /. HoldPattern[dh[x_, y_]] :> (
    shiftedDelta = ReplaceDummies[deltaExpr /. {u -> x, v -> y}];
    shiftedDelta
  );
  expr = ReplaceDummies[expr];
  Quiet[
    canonExpr @ removeParameterDerivatives @ expr,
    ToCanonical::noident
  ]
];

quadraticFieldRedefinitionFriendly =
  (-3*PD[-i1][PD[i1][h[u, v]]])/(20*M^2) -
  (3*eta[u, v]*PD[-i2][PD[-i1][h[i1, i2]]])/(10*M^2) +
  (3*eta[u, v]*PD[-i2][PD[i2][h[i1, -i1]]])/(10*M^2);

quadraticFieldRedefinitionExpr[x_, y_] := Module[{j1, j2},
  j1 = DummyIn[TangentM];
  j2 = DummyIn[TangentM];
  canonExpr[
    (-3*PD[-j1][PD[j1][h[x, y]]])/(20*M^2) -
    (3*eta[x, y]*PD[-j2][PD[-j1][h[j1, j2]]])/(10*M^2) +
    (3*eta[x, y]*PD[-j2][PD[j2][h[j1, -j1]]])/(10*M^2)
  ]
];

Print["[step 0] loading and normalizing the original Matchete input"];
translatedInput = LoadMatcheteToXAct[inputMX];
normalizedInput = NormalizeMatcheteFinitePart[translatedInput];
truncatedInput = selectTermsByMassDimension[normalizedInput, 6];
witnessInputExpr = Quiet[
  canonExpr @ removeParameterDerivatives @ (normalizeScalarExpr[truncatedInput] /. witnessSubstitutions),
  ToCanonical::noident
];

Print["[step 1] building the witness-fixed Einstein-Hilbert reference"];
referenceData = Quiet[
  ExpandFixedEHReferenceLagrangian[
    "MaxDimension" -> 6,
    "LambdaReferenceValue" -> LambdaRefFinal,
    "KappaReferenceValue" -> KappaRefFinal,
    "EHSign" -> -1,
    "CacheDirectory" -> cacheDir,
    "UseCache" -> True,
    "Verbose" -> False
  ],
  ToCanonical::noident
];
referenceExpr = Quiet[
  canonExpr @ removeParameterDerivatives @ (normalizeScalarExpr[referenceData["ReferenceExpression"]] /. witnessSubstitutions),
  ToCanonical::noident
];

Print["[step 2] reducing the witness-fixed input and reference"];
rawInputReduction = Quiet[ReduceLagrangian[witnessInputExpr, Sequence @@ basisOpts], ToCanonical::noident];
canonicalNormalization = Append[
  kineticNormalizationDataFromReduction[rawInputReduction, basisOpts],
  "TargetQuadraticSign" -> -1
];
canonicalInputReduction = If[
  TrueQ[Lookup[canonicalNormalization, "SucceededQ", False]],
  canonicalNormalizeReduction[rawInputReduction, canonicalNormalization["Factor"], -1],
  rawInputReduction
];
referenceReduction = Quiet[ReduceLagrangian[referenceExpr, Sequence @@ basisOpts], ToCanonical::noident];

eftAfterIBPOnly = projectedExpressionFromReduction[canonicalInputReduction];
theoryAfterIBPOnly = projectedExpressionFromReduction[referenceReduction];
ibpOnlyDifference = Quiet[canonExpr[eftAfterIBPOnly - theoryAfterIBPOnly], ToCanonical::noident];

Print["[step 3] extracting the explicit {4,2} interaction-sector field redefinition"];
inputSector42 = sectorLookup[canonicalInputReduction["SectorReductions"], {4, 2}];
referenceSector42 = sectorLookup[referenceReduction["SectorReductions"], {4, 2}];
sector42Data = Which[
  AssociationQ[inputSector42], inputSector42["SectorData"],
  AssociationQ[referenceSector42], referenceSector42["SectorData"],
  True, ComputeSectorData[4, 2, Sequence @@ basisOpts]
];
coefficientDifference42 = FullSimplify[
  normalizeScalarExpr[
    If[AssociationQ[inputSector42], inputSector42["RedefinitionImageCoefficients"], {}] -
    If[AssociationQ[referenceSector42], referenceSector42["RedefinitionImageCoefficients"], {}]
  ],
  witnessAssumptions
];
fieldRedefinition42 = If[
  coefficientDifference42 === {} || sector42Data["RedefIndependentDeltas"] === {},
  0,
  canonExpr @ LinearCombination[coefficientDifference42, sector42Data["RedefIndependentDeltas"]]
];
explicitShift42 = firstOrderShiftFromSubstitution[fieldRedefinition42];
projectedShift42 = ProjectToIBPUsingSectorData[explicitShift42, sector42Data];
projectedDifference42 = Quiet[
  canonExpr[
    If[AssociationQ[inputSector42], inputSector42["ProjectedIBPExpression"], 0] -
    If[AssociationQ[referenceSector42], referenceSector42["ProjectedIBPExpression"], 0]
  ],
  ToCanonical::noident
];

Print["[step 4] extracting the explicit {2,4} quadratic field redefinition"];
inputSector24 = sectorLookup[canonicalInputReduction["SectorReductions"], {2, 4}];
referenceSector24 = sectorLookup[referenceReduction["SectorReductions"], {2, 4}];
sector24Data = Which[
  AssociationQ[inputSector24], inputSector24["SectorData"],
  AssociationQ[referenceSector24], referenceSector24["SectorData"],
  True, ComputeSectorData[2, 4, Sequence @@ basisOpts]
];
explicitShift24 = selectTermsByMassDimension[
  Quiet[
    canonExpr @ removeParameterDerivatives @ ShiftFromRedefExpr[quadraticFieldRedefinitionExpr[u, v]],
    ToCanonical::noident
  ],
  6
];
shift24Reduction = Quiet[ReduceLagrangian[explicitShift24, Sequence @@ basisOpts], ToCanonical::noident];
shift24Sector = sectorLookup[shift24Reduction["SectorReductions"], {2, 4}];
projectedShift24 = If[AssociationQ[shift24Sector], shift24Sector["ProjectedIBPExpression"], 0];
projectedShift24Coordinates = If[AssociationQ[shift24Sector], shift24Sector["ProjectedIBPCoordinates"], ConstantArray[0, Length[sector24Data["IBPBasis"]]]];
projectedDifference24 = Quiet[
  canonExpr[
    If[AssociationQ[inputSector24], inputSector24["ProjectedIBPExpression"], 0] -
    If[AssociationQ[referenceSector24], referenceSector24["ProjectedIBPExpression"], 0]
  ],
  ToCanonical::noident
];
projectedDifference24Coordinates = (
  If[AssociationQ[inputSector24], inputSector24["ProjectedIBPCoordinates"], ConstantArray[0, Length[sector24Data["IBPBasis"]]]] -
  If[AssociationQ[referenceSector24], referenceSector24["ProjectedIBPCoordinates"], ConstantArray[0, Length[sector24Data["IBPBasis"]]]]
);

Print["[step 5] applying the {4,2} and then {2,4} field redefinitions to the IBP-only EFT"];
eftAfter42Shift = Quiet[canonExpr[eftAfterIBPOnly - projectedShift42["ProjectedExpr"]], ToCanonical::noident];
differenceAfter42Shift = Quiet[canonExpr[eftAfter42Shift - theoryAfterIBPOnly], ToCanonical::noident];

eftAfter42And24Shift = Quiet[canonExpr[eftAfter42Shift - projectedShift24], ToCanonical::noident];
differenceAfter42And24Shift = Quiet[canonExpr[eftAfter42And24Shift - theoryAfterIBPOnly], ToCanonical::noident];

results = <|
  "GeneratedOn" -> DateString[{"ISODate", " ", "Time"}],
  "KernelVersion" -> System`$Version,
  "InputSource" -> inputMX,
  "WitnessSubstitutions" -> witnessSubstitutions,
  "WitnessAssumptions" -> witnessAssumptions,
  "RelevantSectors" -> relevantSectors,
  "InputPipeline" -> <|
    "CanonicalNormalization" -> canonicalNormalization
  |>,
  "BeforeAnyAdditionalFieldRedefinition" -> <|
    "EFTAfterIBPOnlyBySector" -> displayBySector[eftAfterIBPOnly],
    "TheoryAfterIBPOnlyBySector" -> displayBySector[theoryAfterIBPOnly],
    "DifferenceBySector" -> displayBySector[ibpOnlyDifference],
    "DifferenceZeroQ" -> zeroExprQ[ibpOnlyDifference, witnessAssumptions]
  |>,
  "QuarticTwoDerivativeFieldRedefinition" -> <|
    "Sector" -> {4, 2},
    "CoefficientDifference" -> coefficientDifference42,
    "FieldRedefinition" -> fieldRedefinition42,
    "IndependentDeltas" -> sector42Data["RedefIndependentDeltas"],
    "ProjectedDifference" -> projectedDifference42,
    "ProjectedDifferenceCoordinates" -> If[
      AssociationQ[inputSector42] && AssociationQ[referenceSector42],
      inputSector42["ProjectedIBPCoordinates"] - referenceSector42["ProjectedIBPCoordinates"],
      {}
    ],
    "ProjectedShiftImage" -> projectedShift42["ProjectedExpr"],
    "ProjectedShiftCoordinates" -> projectedShift42["Coordinates"],
    "ProjectedShiftMatchesDifferenceQ" -> zeroExprQ[projectedShift42["ProjectedExpr"] - projectedDifference42, witnessAssumptions],
    "ProjectedShiftResidualZeroQ" -> zeroExprQ[projectedShift42["ProjectionResidual"], witnessAssumptions]
  |>,
  "AfterQuarticTwoDerivativeFieldRedefinition" -> <|
    "ShiftedEFTBySector" -> displayBySector[eftAfter42Shift],
    "DifferenceBySector" -> displayBySector[differenceAfter42Shift],
    "DifferenceZeroQ" -> zeroExprQ[differenceAfter42Shift, witnessAssumptions]
  |>,
  "QuadraticFourDerivativeFieldRedefinition" -> <|
    "Sector" -> {2, 4},
    "FieldRedefinition" -> quadraticFieldRedefinitionFriendly,
    "ProjectedDifference" -> projectedDifference24,
    "ProjectedDifferenceCoordinates" -> projectedDifference24Coordinates,
    "ProjectedShiftImage" -> projectedShift24,
    "ProjectedShiftCoordinates" -> projectedShift24Coordinates,
    "ProjectedShiftMatchesDifferenceQ" -> zeroExprQ[projectedShift24 - projectedDifference24, witnessAssumptions],
    "CoordinateResidualZeroQ" -> zeroVectorQWithAssumptions[
      projectedDifference24Coordinates - projectedShift24Coordinates,
      witnessAssumptions
    ]
  |>,
  "AfterQuarticTwoDerivativeAndQuadraticFourDerivativeFieldRedefinitions" -> <|
    "ShiftedEFTBySector" -> displayBySector[eftAfter42And24Shift],
    "DifferenceBySector" -> displayBySector[differenceAfter42And24Shift],
    "DifferenceZeroQ" -> zeroExprQ[differenceAfter42And24Shift, witnessAssumptions]
  |>
|>;

Put[results, outputFile];

Print["Wrote validation artifact: " <> outputFile];
Print["Before-shift difference by sector: " <> ToString[results["BeforeAnyAdditionalFieldRedefinition", "DifferenceBySector"], InputForm]];
Print["After {4,2} shift difference by sector: " <> ToString[results["AfterQuarticTwoDerivativeFieldRedefinition", "DifferenceBySector"], InputForm]];
Print["After {4,2} and {2,4} shifts difference by sector: " <> ToString[results["AfterQuarticTwoDerivativeAndQuadraticFourDerivativeFieldRedefinitions", "DifferenceBySector"], InputForm]];

If[
  ! TrueQ[results["QuarticTwoDerivativeFieldRedefinition", "ProjectedShiftMatchesDifferenceQ"]] ||
  ! TrueQ[results["QuadraticFourDerivativeFieldRedefinition", "ProjectedShiftMatchesDifferenceQ"]] ||
  ! TrueQ[results["AfterQuarticTwoDerivativeAndQuadraticFourDerivativeFieldRedefinitions", "DifferenceZeroQ"]],
  Exit[1]
];

results
