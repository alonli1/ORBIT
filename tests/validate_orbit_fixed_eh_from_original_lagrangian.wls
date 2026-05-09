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
outputFile = FileNameJoin[{outputDir, "orbit_fixed_eh_from_original_lagrangian_validation_output.wl"}];

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

allPassed = True;

reportCheck[label_String, condition_] := If[
  TrueQ[condition],
  Print["PASS: " <> label],
  Print["FAIL: " <> label];
  allPassed = False
];

normalizeScalarExpr[expr_] := normalizeMatcheteParameterScalars[expr];

zeroExprQ[expr_, assumptions_ : True] := Module[{checked},
  checked = Quiet[canonExpr[normalizeScalarExpr[expr]], ToCanonical::noident];
  TrueQ[checked === 0] || TrueQ[FullSimplify[checked == 0, assumptions]]
];

zeroVectorQWithAssumptions[list_List, assumptions_ : True] := And @@ (
  TrueQ[FullSimplify[normalizeScalarExpr[#] == 0, assumptions]] & /@ list
);

removeParameterDerivatives[expr_] := FixedPoint[
  Expand[# /. parameterDerivativeRules] &,
  expr
];

firstOrderShiftFromExpression[expr_, deltaExprBuilder_] := Module[{shiftExpr, shiftedDelta},
  shiftExpr = Expand[expr /. HoldPattern[h[x_, y_]] :> (h[x, y] + lam dh[x, y])];
  shiftExpr = Coefficient[shiftExpr, lam, 1];
  shiftExpr = shiftExpr /. HoldPattern[dh[x_, y_]] :> (
    shiftedDelta = ReplaceDummies[deltaExprBuilder[x, y]];
    shiftedDelta
  );
  Quiet[
    canonExpr @ removeParameterDerivatives @ ReplaceDummies[shiftExpr],
    ToCanonical::noident
  ]
];

projectedSectorComparisonRecord[key_, inputSector_, referenceSector_, sectorData_] := Module[
  {basis, inputCoords, referenceCoords, differenceCoords, inputExpr, referenceExpr, differenceExpr},
  basis = sectorData["IBPBasis"];
  inputCoords = If[AssociationQ[inputSector], inputSector["ProjectedIBPCoordinates"], ConstantArray[0, Length[basis]]];
  referenceCoords = If[AssociationQ[referenceSector], referenceSector["ProjectedIBPCoordinates"], ConstantArray[0, Length[basis]]];
  differenceCoords = inputCoords - referenceCoords;
  inputExpr = If[AssociationQ[inputSector], inputSector["ProjectedIBPExpression"], 0];
  referenceExpr = If[AssociationQ[referenceSector], referenceSector["ProjectedIBPExpression"], 0];
  differenceExpr = canonExpr @ LinearCombination[differenceCoords, basis];
  <|
    "Sector" -> key,
    "InputProjectedCoordinates" -> inputCoords,
    "ReferenceProjectedCoordinates" -> referenceCoords,
    "DifferenceProjectedCoordinates" -> differenceCoords,
    "InputProjectedExpression" -> inputExpr,
    "ReferenceProjectedExpression" -> referenceExpr,
    "DifferenceProjectedExpression" -> differenceExpr,
    "DifferenceIsZeroQ" -> zeroExprQ[differenceExpr, witnessAssumptions],
    "DifferenceCoordinatesZeroQ" -> zeroVectorQWithAssumptions[differenceCoords, witnessAssumptions]
  |>
];

buildProjectedSectorComparisons[inputReduction_Association, referenceReduction_Association] := Module[
  {allSectors},
  allSectors = Sort @ Union[
    Keys[inputReduction["SectorReductions"]],
    Keys[referenceReduction["SectorReductions"]]
  ];
  Association @ Table[
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
            ComputeSectorData[sector[[1]], sector[[2]], Sequence @@ basisOpts]
        ]
      },
      key -> projectedSectorComparisonRecord[key, inputSector, referenceSector, sectorData]
    ],
    {sector, allSectors}
  ]
];

buildReducedSectorComparisons[inputReduction_Association, referenceReduction_Association] := Module[
  {allSectors},
  allSectors = Sort @ Union[
    Keys[inputReduction["SectorReductions"]],
    Keys[referenceReduction["SectorReductions"]]
  ];
  Association @ Table[
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
            ComputeSectorData[sector[[1]], sector[[2]], Sequence @@ basisOpts]
        ]
      },
      key -> Join[
        sectorComparisonRecord[key, inputSector, referenceSector, sectorData],
        <|
          "DifferenceZeroQ" -> zeroExprQ[
            sectorComparisonRecord[key, inputSector, referenceSector, sectorData]["DifferenceExpression"],
            witnessAssumptions
          ],
          "DifferenceCoordinatesZeroQ" -> zeroVectorQWithAssumptions[
            sectorComparisonRecord[key, inputSector, referenceSector, sectorData]["DifferenceCoordinates"],
            witnessAssumptions
          ]
        |>
      ]
    ],
    {sector, allSectors}
  ]
];

nonZeroProjectedSectors[comparisons_Association] := Keys @ KeySelect[
  comparisons,
  ! TrueQ[comparisons[#]["DifferenceIsZeroQ"]] &
];

nonZeroReducedSectors[comparisons_Association] := Keys @ KeySelect[
  comparisons,
  ! TrueQ[comparisons[#]["DifferenceZeroQ"]] &
];

comparisonSummary[comparisons_Association] := <|
  "Sectors" -> Keys[comparisons],
  "NonZeroProjectedDifferenceSectors" -> nonZeroProjectedSectors[comparisons],
  "AllProjectedDifferencesZeroQ" -> And @@ Lookup[Values[comparisons], "DifferenceIsZeroQ", {}],
  "AllProjectedCoordinateDifferencesZeroQ" -> And @@ Lookup[Values[comparisons], "DifferenceCoordinatesZeroQ", {}],
  "DifferenceExpressions" -> Association @ KeyValueMap[#1 -> #2["DifferenceProjectedExpression"] &, comparisons],
  "DifferenceCoordinates" -> Association @ KeyValueMap[#1 -> #2["DifferenceProjectedCoordinates"] &, comparisons]
|>;

reducedComparisonSummary[comparisons_Association] := <|
  "Sectors" -> Keys[comparisons],
  "NonZeroReducedDifferenceSectors" -> nonZeroReducedSectors[comparisons],
  "AllReducedDifferencesZeroQ" -> And @@ Lookup[Values[comparisons], "DifferenceZeroQ", {}],
  "AllReducedCoordinateDifferencesZeroQ" -> And @@ Lookup[Values[comparisons], "DifferenceCoordinatesZeroQ", {}],
  "DifferenceExpressions" -> Association @ KeyValueMap[#1 -> #2["DifferenceExpression"] &, comparisons],
  "DifferenceCoordinates" -> Association @ KeyValueMap[#1 -> #2["DifferenceCoordinates"] &, comparisons]
|>;

Print["[step 0] loading and normalizing the original Matchete input"];
{translationTime, translatedInput} = AbsoluteTiming[LoadMatcheteToXAct[inputMX]];
normalizedInput = NormalizeMatcheteFinitePart[translatedInput];
truncatedInput = selectTermsByMassDimension[normalizedInput, 6];
witnessInputExpr = Quiet[
  canonExpr @ removeParameterDerivatives @ (normalizeScalarExpr[truncatedInput] /. witnessSubstitutions),
  ToCanonical::noident
];

Print["[step 1] building the witness-fixed Einstein-Hilbert reference"];
{referenceBuildTime, referenceData} = AbsoluteTiming @ Quiet[
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

Print["[step 2] shifting the full witness-fixed reference by the validated field redefinition"];
{fullShiftTime, fullReferenceShift} = AbsoluteTiming[
  firstOrderShiftFromExpression[referenceExpr, quadraticFieldRedefinitionExpr]
];
fullReferenceShiftTruncated = selectTermsByMassDimension[fullReferenceShift, 6];
fpShiftTruncated = selectTermsByMassDimension[
  Quiet[
    canonExpr @ removeParameterDerivatives @ ShiftFromRedefExpr[quadraticFieldRedefinitionExpr[u, v]],
    ToCanonical::noident
  ],
  6
];
fullShiftMinusFPShift = Quiet[
  canonExpr[fullReferenceShiftTruncated - fpShiftTruncated],
  ToCanonical::noident
];

shiftedReferenceExpr = selectTermsByMassDimension[
  Quiet[
    canonExpr[referenceExpr + fullReferenceShiftTruncated],
    ToCanonical::noident
  ],
  6
];

Print["[step 3] reducing the witness-fixed original EFT"];
{inputReductionTime, rawInputReduction} = AbsoluteTiming[
  Quiet[ReduceLagrangian[witnessInputExpr, Sequence @@ basisOpts], ToCanonical::noident]
];
canonicalNormalization = Append[
  kineticNormalizationDataFromReduction[rawInputReduction, basisOpts],
  "TargetQuadraticSign" -> -1
];
canonicalInputReduction = If[
  TrueQ[Lookup[canonicalNormalization, "SucceededQ", False]],
  canonicalNormalizeReduction[rawInputReduction, canonicalNormalization["Factor"], -1],
  rawInputReduction
];

Print["[step 4] reducing the unshifted and shifted GR references"];
{referenceReductionTime, referenceReduction} = AbsoluteTiming[
  Quiet[ReduceLagrangian[referenceExpr, Sequence @@ basisOpts], ToCanonical::noident]
];
{fullShiftReductionTime, fullShiftReduction} = AbsoluteTiming[
  Quiet[ReduceLagrangian[fullReferenceShiftTruncated, Sequence @@ basisOpts], ToCanonical::noident]
];
{fpShiftReductionTime, fpShiftReduction} = AbsoluteTiming[
  Quiet[ReduceLagrangian[fpShiftTruncated, Sequence @@ basisOpts], ToCanonical::noident]
];
{shiftedReferenceReductionTime, shiftedReferenceReduction} = AbsoluteTiming[
  Quiet[ReduceLagrangian[shiftedReferenceExpr, Sequence @@ basisOpts], ToCanonical::noident]
];

beforeShiftComparisons = buildProjectedSectorComparisons[canonicalInputReduction, referenceReduction];
afterShiftComparisons = buildProjectedSectorComparisons[canonicalInputReduction, shiftedReferenceReduction];
beforeShiftReducedComparisons = buildReducedSectorComparisons[canonicalInputReduction, referenceReduction];

beforeShiftSummary = comparisonSummary[beforeShiftComparisons];
afterShiftSummary = comparisonSummary[afterShiftComparisons];
beforeShiftReducedSummary = reducedComparisonSummary[beforeShiftReducedComparisons];

supportedReducedComparisons = KeySelect[
  beforeShiftReducedComparisons,
  MemberQ[supportedSectorsUpTo[6], #] &
];
supportedReducedSummary = reducedComparisonSummary[supportedReducedComparisons];

quadraticDifferenceCoordinates = Lookup[beforeShiftComparisons[{2, 4}], "DifferenceProjectedCoordinates", {}];
fullShiftQuadraticCoordinates = Lookup[
  sectorLookup[fullShiftReduction["SectorReductions"], {2, 4}],
  "ProjectedIBPCoordinates",
  {}
];
fpShiftQuadraticCoordinates = Lookup[
  sectorLookup[fpShiftReduction["SectorReductions"], {2, 4}],
  "ProjectedIBPCoordinates",
  {}
];
fullShiftLinearFourDerivativeReducedZeroQ = zeroExprQ[
  Lookup[
    sectorLookup[fullShiftReduction["SectorReductions"], {1, 4}],
    "ReducedExpression",
    0
  ],
  witnessAssumptions
];

beforeShiftTotalDifference = Quiet[
  canonExpr[canonicalInputReduction["ReducedExpression"] - referenceReduction["ReducedExpression"]],
  ToCanonical::noident
];
afterShiftTotalDifference = Quiet[
  canonExpr[canonicalInputReduction["ReducedExpression"] - shiftedReferenceReduction["ReducedExpression"]],
  ToCanonical::noident
];

reportCheck["Original Matchete input translated successfully", translatedInput =!= $Failed];
reportCheck["All supported sectors from the original Lagrangian match GR after the witness substitution", TrueQ[supportedReducedSummary["AllReducedDifferencesZeroQ"]]];
reportCheck[
  "The only remaining reduced-sector discrepancy from the original Lagrangian is {2,4}",
  Sort[beforeShiftReducedSummary["NonZeroReducedDifferenceSectors"]] === {{2, 4}}
];
reportCheck[
  "The quadratic {2,4} discrepancy from the original Lagrangian matches the projected FP shift coordinates",
  zeroVectorQWithAssumptions[
    quadraticDifferenceCoordinates - fpShiftQuadraticCoordinates,
    witnessAssumptions
  ]
];
reportCheck["The extra {1,4} piece in the full-reference shift reduces to zero", fullShiftLinearFourDerivativeReducedZeroQ];
Print[
  "NOTE: The raw full-reference first-order shift does not reproduce the {2,4} discrepancy directly. " <>
  "After fresh step-0 reconstruction, its projected {2,4} coordinates are " <>
  ToString[fullShiftQuadraticCoordinates, InputForm] <>
  ", so the correct end-to-end statement is the reduced/IBP one: the original-Lagrangian discrepancy matches the projected FP shift coordinates."
];

results = <|
  "GeneratedOn" -> DateString[{"ISODate", " ", "Time"}],
  "KernelVersion" -> System`$Version,
  "InputSource" -> inputMX,
  "CacheDirectory" -> cacheDir,
  "WitnessSubstitutions" -> witnessSubstitutions,
  "WitnessAssumptions" -> witnessAssumptions,
  "QuadraticFieldRedefinition" -> quadraticFieldRedefinitionFriendly,
  "AllChecksPassedQ" -> allPassed,
  "TimingsSeconds" -> <|
    "Translation" -> translationTime,
    "ReferenceBuild" -> referenceBuildTime,
    "FullReferenceShift" -> fullShiftTime,
    "InputReduction" -> inputReductionTime,
    "ReferenceReduction" -> referenceReductionTime,
    "FullShiftReduction" -> fullShiftReductionTime,
    "FPShiftReduction" -> fpShiftReductionTime,
    "ShiftedReferenceReduction" -> shiftedReferenceReductionTime
  |>,
  "InputPipeline" -> <|
    "TranslatedExpressionTermCount" -> expressionTermCount[translatedInput],
    "NormalizedExpressionTermCount" -> expressionTermCount[normalizedInput],
    "TruncatedExpressionTermCount" -> expressionTermCount[truncatedInput],
    "WitnessExpressionTermCount" -> expressionTermCount[witnessInputExpr],
    "CanonicalNormalization" -> canonicalNormalization
  |>,
  "ReferencePipeline" -> <|
    "ReferenceData" -> referenceData,
    "ReferenceExpressionTermCount" -> expressionTermCount[referenceExpr],
    "FullReferenceShiftTermCount" -> expressionTermCount[fullReferenceShift],
    "TruncatedFullReferenceShiftTermCount" -> expressionTermCount[fullReferenceShiftTruncated],
    "ShiftedReferenceExpressionTermCount" -> expressionTermCount[shiftedReferenceExpr],
    "FullReferenceShiftSectors" -> Sort[Keys[SplitTermsBySector[Expand[fullReferenceShiftTruncated]]]],
    "TruncatedFullReferenceShiftExpression" -> fullReferenceShiftTruncated,
    "FPShiftExpression" -> fpShiftTruncated,
    "FullReferenceShiftMinusFPShift" -> fullShiftMinusFPShift,
    "FullReferenceShiftMatchesFPShiftAfterTruncationQ" -> zeroExprQ[fullShiftMinusFPShift, witnessAssumptions],
    "FullShiftQuadraticProjectedCoordinates" -> fullShiftQuadraticCoordinates,
    "FPShiftQuadraticProjectedCoordinates" -> fpShiftQuadraticCoordinates,
    "FullShiftLinearFourDerivativeReducedZeroQ" -> fullShiftLinearFourDerivativeReducedZeroQ
  |>,
  "BeforeShift" -> <|
    "SectorSummary" -> beforeShiftSummary,
    "ReducedSectorSummary" -> beforeShiftReducedSummary,
    "SupportedReducedSectorSummary" -> supportedReducedSummary,
    "QuadraticDifferenceProjectedCoordinates" -> quadraticDifferenceCoordinates,
    "TotalReducedDifference" -> beforeShiftTotalDifference,
    "TotalReducedDifferenceZeroQ" -> zeroExprQ[beforeShiftTotalDifference, witnessAssumptions]
  |>,
  "AfterShift" -> <|
    "SectorSummary" -> afterShiftSummary,
    "TotalReducedDifference" -> afterShiftTotalDifference,
    "TotalReducedDifferenceZeroQ" -> zeroExprQ[afterShiftTotalDifference, witnessAssumptions]
  |>
|>;

Put[results, outputFile];

Print["Wrote validation artifact: " <> outputFile];
Print["Before-shift nonzero projected sectors: " <> ToString[beforeShiftSummary["NonZeroProjectedDifferenceSectors"], InputForm]];
Print["Before-shift nonzero reduced sectors: " <> ToString[beforeShiftReducedSummary["NonZeroReducedDifferenceSectors"], InputForm]];
Print["Quadratic discrepancy coordinates: " <> ToString[quadraticDifferenceCoordinates, InputForm]];
Print["Full-shift {2,4} coordinates: " <> ToString[fullShiftQuadraticCoordinates, InputForm]];

If[! allPassed, Exit[1]];

results
