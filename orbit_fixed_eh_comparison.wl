(* ::Package:: *)

Quiet[Needs["xAct`xPert`"], PacletDataRebuild::lock];

If[! ValueQ[RunBasisComputation], Get["graviton_basis_toolkit.wl"]];
If[! ValueQ[MatcheteXActTranslator`MatcheteToXAct], Get["MatcheteXActTranslator.m"]];

ClearAll[
  LoadMatcheteToXAct, NormalizeMatcheteFinitePart, ExpandFixedEHReferenceLagrangian,
  CompareMatcheteToFixedEH, BuildMatcheteEHReport
];

$LoadedMatcheteToXActCache = <||>;

LoadMatcheteToXAct::usage =
  "LoadMatcheteToXAct[mxFile] loads a Matchete .mx dump and translates it to ORBIT/xAct syntax.";
NormalizeMatcheteFinitePart::usage =
  "NormalizeMatcheteFinitePart[expr] applies hbar -> 1 and drops all terms containing negative powers of \\[Epsilon].";
ExpandFixedEHReferenceLagrangian::usage =
  "ExpandFixedEHReferenceLagrangian[] builds the fixed Einstein-Hilbert plus cosmological-constant reference expansion through the requested mass dimension.";
CompareMatcheteToFixedEH::usage =
  "CompareMatcheteToFixedEH[input] translates or accepts an xAct expression, normalizes it, reduces it, compares it to the fixed EH plus cosmological reference, and solves for Matchete-side matching constraints.";
BuildMatcheteEHReport::usage =
  "BuildMatcheteEHReport[result, outBase] writes a paper-style LaTeX report, a data dump, and optionally compiles the PDF.";

Options[LoadMatcheteToXAct] = {
  "TranslationRules" -> {},
  "SymbolSpec" -> Automatic
};

Options[NormalizeMatcheteFinitePart] = {
  "HBarSymbol" -> hbar,
  "EpsilonSymbol" -> \[Epsilon]
};

Options[ExpandFixedEHReferenceLagrangian] = {
  "MaxDimension" -> 6,
  "LambdaReferenceValue" -> 1,
  "KappaReferenceValue" -> 1,
  "EHSign" -> 1,
  "CacheDirectory" -> Automatic,
  "UseCache" -> True,
  "ForceRecompute" -> False,
  "Verbose" -> True
};

Options[CompareMatcheteToFixedEH] = DeleteDuplicatesBy[
  Join[
    {
      "TranslationRules" -> {},
      "SymbolSpec" -> Automatic,
      "CanonicalNormalizeInput" -> True,
      "CanonicalKineticSign" -> Automatic,
      "LambdaReferenceValue" -> 1,
      "KappaReferenceValue" -> 1,
      "EHSign" -> 1,
      "MatchParameters" -> {M, \[Mu]bar2, \[Kappa]},
      "Verbose" -> True
    },
    Options[RunBasisComputation]
  ],
  First
];

Options[BuildMatcheteEHReport] = {
  "CompilePDF" -> True,
  "PDFLaTeXPath" -> Automatic,
  "Title" -> "Matchete vs Fixed Einstein-Hilbert Comparison",
  "Author" -> "ORBIT",
  "Verbose" -> True
};

ClearAll[
  compareLog, reductionOptionsFrom, expressionTermCount, selectTermsByMassDimension,
  supportedSectorsUpTo, ensureEHReferenceSetup, perturbationSeries,
  translateReferenceHeads, rebindReferenceIndices, referenceExprToOrbit,
  negativeEpsilonPowerQ, scalarHeadQ, normalizeMatcheteParameterScalars,
  finiteEpsilonPart, referenceSolveVariablesFrom, kineticNormalizationDataFromReduction,
  scaleReducedSector, resolveCanonicalKineticSign, canonicalNormalizeReduction, reductionSummaryFrom,
  sectorLookup,
  sectorComparisonRecord, collectDifferenceEquationRecords, solveMatchSystem,
  translateLmuSolutionRules, translateLmuReduceResult, texEscape, texExpr,
  texTableRows, findPDFLaTeX, buildMatchSolutionSummary, formatSectorKey,
  orbitBuildTimeStamp
];

compareLog[msg_, opts_List] := If[TrueQ[Lookup[Association[opts], "Verbose", False]], Print[msg]];

reductionOptionsFrom[opts_List] := FilterRules[opts, Options[RunBasisComputation]];

expressionTermCount[expr_] := Module[{expanded = Expand[expr]},
  Which[
    expanded === 0, 0,
    Head[expanded] === Plus, Length[List @@ expanded],
    True, 1
  ]
];

selectTermsByMassDimension[expr_, dmax_Integer] := Module[{sectorTerms},
  sectorTerms = SplitTermsBySector[Expand[expr]];
  canonExpr @ Total @ Values @ KeySelect[
    sectorTerms,
    MatchQ[#, {_Integer?NonNegative, _Integer?NonNegative}] && Total[#] <= dmax &
  ]
];

supportedSectorsUpTo[dmax_Integer] := Sort @ Join[
  Table[{nh, 0}, {nh, 1, dmax}],
  Select[{{2, 2}, {3, 2}, {4, 2}}, Total[#] <= dmax &]
];

ensureEHReferenceSetup[] := Module[{},
  Quiet @ Check[
    DefManifold[
      MRefEH,
      4,
      {\[Alpha], \[Beta], \[Gamma], \[Delta], \[Mu], \[Nu], \[Rho], \[Sigma], \[Tau], \[Lambda]}
    ],
    Null
  ];
  Quiet @ Check[
    DefMetric[{1, 3, 0}, gRef[-\[Alpha], -\[Beta]], CD, SymbolOfCovD -> {"|", "\[Del]"}],
    Null
  ];
  Quiet @ Check[
    DefMetricPerturbation[gRef, HEH, epsEH],
    Null
  ];
  Quiet @ Check[
    DefConstantSymbol[{KappaRefEH, LambdaRefEH}],
    Null
  ];
];

perturbationSeries[expr_, order_Integer, orderParam_] :=
  Sum[PerturbFlat[expr, i] orderParam^i/Factorial[i], {i, 1, order}];

translateReferenceHeads[expr_, kappaValue_, lambdaValue_] := expr //. {
  Sqrt[-DetgRef[]] -> 1,
  HEH[xAct`xTensor`LI[1], inds__] :> (h @@ {inds}),
  HEH[xAct`xTensor`LI[n_Integer /; n > 1], __] :> 0,
  CD[idx_][sub_] :> PD[idx][translateReferenceHeads[sub, kappaValue, lambdaValue]],
  PD[idx_][sub_] :> PD[idx][translateReferenceHeads[sub, kappaValue, lambdaValue]],
  KappaRefEH -> kappaValue,
  LambdaRefEH -> lambdaValue
};

rebindReferenceIndices[expr_] := Module[{inds, rules},
  inds = Select[
    DeleteDuplicates @ Cases[expr, x_ /; xAct`xTensor`AbstractIndexQ[x], Infinity],
    xAct`xTensor`VBundleOfIndex[#] =!= TangentM &
  ];
  If[inds === {},
    expr,
    rules = Thread[inds -> Table[DummyIn[TangentM], {Length[inds]}]];
    expr /. rules
  ]
];

referenceExprToOrbit[expr_, kappaValue_, lambdaValue_] :=
  rebindReferenceIndices @ translateReferenceHeads[expr, kappaValue, lambdaValue];

negativeEpsilonPowerQ[term_, epsSym_] := ! FreeQ[
  normalizeMatcheteParameterScalars[term],
  HoldPattern[Power[sym_, pow_ /; sym === epsSym && NumericQ[pow] && pow < 0]],
  Infinity
];

scalarHeadQ[s_Symbol] := SymbolName[Unevaluated[s]] === "Scalar";
scalarHeadQ[_] := False;

normalizeMatcheteParameterScalars[expr_] := Module[{clean},
  clean = If[ValueQ[StripScalarParameterWrappers], StripScalarParameterWrappers[expr], expr];
  clean /. {
    HoldPattern[head_[s_Symbol] /; scalarHeadQ[Unevaluated[head]] && MemberQ[{hbar, \[Epsilon], \[Mu]bar2, M, \[Kappa]}, s]] :> s
  } /. HoldPattern[Log[Scalar[\[Mu]bar2]/M^2]] :> Log[\[Mu]bar2/M^2]
];

finiteEpsilonPart[term_, epsSym_] := Module[{normTerm},
  normTerm = normalizeMatcheteParameterScalars[term];
  Quiet[
    Check[
      SeriesCoefficient[normTerm, {epsSym, 0, 0}],
      normTerm /. epsSym -> 0
    ],
    {SeriesCoefficient::esss, SeriesCoefficient::serlim, SeriesData::sdatv}
  ]
];

referenceSolveVariablesFrom[values___] := Select[
  DeleteDuplicates[{values}],
  Head[#] === Symbol &
];

kineticNormalizationDataFromReduction[inputReduction_Association, basisOpts_List] := Module[
  {sector22, lfpReduction, inputCoords, lfpCoords, nz, firstIndex, factor, consistentQ},
  sector22 = sectorLookup[inputReduction["SectorReductions"], {2, 2}];
  If[! AssociationQ[sector22],
    Return[<|"SucceededQ" -> False, "Reason" -> "NoQuadraticDerivativeSector"|>]
  ];

  lfpReduction = ReduceSectorLagrangian[LFP, 2, 2, Sequence @@ basisOpts];
  inputCoords = normalizeMatcheteParameterScalars /@ sector22["PhysicalCoordinates"];
  lfpCoords = lfpReduction["PhysicalCoordinates"];
  nz = Select[Range[Length[lfpCoords]], ! TrueQ[lfpCoords[[#]] === 0] &];

  If[nz === {},
    Return[<|"SucceededQ" -> False, "Reason" -> "ZeroFierzPauliCoordinates"|>]
  ];

  firstIndex = First[nz];
  factor = normalizeMatcheteParameterScalars @ Simplify[inputCoords[[firstIndex]]/lfpCoords[[firstIndex]]];
  consistentQ = And @@ Table[
    TrueQ[Simplify[inputCoords[[i]] == factor lfpCoords[[i]]]],
    {i, nz}
  ];

  <|
    "SucceededQ" -> consistentQ,
    "Reason" -> If[consistentQ, "OK", "QuadraticSectorNotProportionalToFierzPauli"],
    "Factor" -> factor,
    "InputCoordinates" -> inputCoords,
    "FierzPauliCoordinates" -> lfpCoords
  |>
];

scaleReducedSector[sec_Association, scale_] := Module[{scaled = Association[sec]},
  If[KeyExistsQ[scaled, "InputExpression"], scaled["InputExpression"] = canonExpr[scale scaled["InputExpression"]]];
  If[KeyExistsQ[scaled, "ProjectedIBPExpression"], scaled["ProjectedIBPExpression"] = canonExpr[scale scaled["ProjectedIBPExpression"]]];
  If[KeyExistsQ[scaled, "ProjectedIBPCoordinates"], scaled["ProjectedIBPCoordinates"] = scale scaled["ProjectedIBPCoordinates"]];
  If[KeyExistsQ[scaled, "ReducedIBPExpression"], scaled["ReducedIBPExpression"] = canonExpr[scale scaled["ReducedIBPExpression"]]];
  If[KeyExistsQ[scaled, "ReducedIBPCoordinates"], scaled["ReducedIBPCoordinates"] = scale scaled["ReducedIBPCoordinates"]];
  If[KeyExistsQ[scaled, "PhysicalCoordinates"], scaled["PhysicalCoordinates"] = scale scaled["PhysicalCoordinates"]];
  If[KeyExistsQ[scaled, "RedefinitionImageExpression"], scaled["RedefinitionImageExpression"] = canonExpr[scale scaled["RedefinitionImageExpression"]]];
  If[KeyExistsQ[scaled, "RedefinitionImageCoefficients"], scaled["RedefinitionImageCoefficients"] = scale scaled["RedefinitionImageCoefficients"]];
  If[KeyExistsQ[scaled, "ReducedExpression"], scaled["ReducedExpression"] = canonExpr[scale scaled["ReducedExpression"]]];
  scaled
];

resolveCanonicalKineticSign[requested_, _] := Module[{resolved},
  resolved = Replace[requested, Automatic :> 1];
  If[MemberQ[{1, -1}, resolved], resolved, 1]
];

canonicalNormalizeReduction[inputReduction_Association, kineticFactor_, targetQuadraticSign_: 1] := Module[
  {scaledSectors, fieldScaleSquared},
  fieldScaleSquared = targetQuadraticSign/kineticFactor;
  scaledSectors = Association @ KeyValueMap[
    Function[{key, sec},
      key -> scaleReducedSector[sec, fieldScaleSquared^(key[[1]]/2)]
    ],
    inputReduction["SectorReductions"]
  ];

  <|
    "InputExpression" -> canonExpr @ Total[Lookup[Values[scaledSectors], "InputExpression", {}]],
    "UntouchedExpression" -> Lookup[inputReduction, "UntouchedExpression", 0],
    "SectorReductions" -> scaledSectors,
    "ReducedExpression" -> canonExpr @ Total[Lookup[Values[scaledSectors], "ReducedExpression", {}]],
    "CanonicalNormalizationFactor" -> kineticFactor,
    "TargetQuadraticSign" -> targetQuadraticSign,
    "FieldScaleSquared" -> fieldScaleSquared
  |>
];

reductionSummaryFrom[reduction_Association] := Association @ KeyValueMap[
  Function[{key, sec},
    key -> <|
      "ProjectionSucceededQ" -> Lookup[sec, "ProjectionSucceededQ", Missing["NotAvailable"]],
      "InputTermCount" -> expressionTermCount[sec["InputExpression"]],
      "ProjectedIBPTermCount" -> expressionTermCount[sec["ProjectedIBPExpression"]],
      "ReducedTermCount" -> expressionTermCount[sec["ReducedExpression"]],
      "PhysicalCoordinateCount" -> Length[sec["PhysicalCoordinates"]]
    |>
  ],
  reduction["SectorReductions"]
];

sectorLookup[assoc_Association, key_] := If[KeyExistsQ[assoc, key], assoc[key], Missing["NotAvailable"]];
sectorLookup[_, _] := Missing["NotAvailable"];

sectorComparisonRecord[key_, inputReduction_, referenceReduction_, sectorData_] := Module[
  {basis, inputCoords, referenceCoords, differenceCoords, inputExpr, referenceExpr, differenceExpr},
  basis = sectorData["PhysicalBasis"];
  inputCoords = If[AssociationQ[inputReduction], inputReduction["PhysicalCoordinates"], ConstantArray[0, Length[basis]]];
  referenceCoords = If[AssociationQ[referenceReduction], referenceReduction["PhysicalCoordinates"], ConstantArray[0, Length[basis]]];
  differenceCoords = inputCoords - referenceCoords;
  inputExpr = If[AssociationQ[inputReduction], inputReduction["ReducedExpression"], 0];
  referenceExpr = If[AssociationQ[referenceReduction], referenceReduction["ReducedExpression"], 0];
  differenceExpr = canonExpr @ LinearCombination[differenceCoords, basis];
  <|
    "Sector" -> key,
    "InputCoordinates" -> inputCoords,
    "ReferenceCoordinates" -> referenceCoords,
    "DifferenceCoordinates" -> differenceCoords,
    "InputReducedExpression" -> inputExpr,
    "ReferenceReducedExpression" -> referenceExpr,
    "DifferenceExpression" -> differenceExpr,
    "DifferenceIsZeroQ" -> TrueQ[differenceExpr === 0]
  |>
];

collectDifferenceEquationRecords[sectorComparisons_Association] := Module[
  {lmu = Lmu, logRule, records},
  logRule = {
    HoldPattern[Log[\[Mu]bar2/M^2]] :> lmu,
    HoldPattern[Log[Scalar[\[Mu]bar2]/M^2]] :> lmu
  };
  records = Flatten @ KeyValueMap[
    Function[{sector, record},
      Module[{coords, local},
        coords = record["DifferenceCoordinates"];
        local = Flatten @ Table[
          Module[{expr, numerator, coeffs},
            expr = Together[Expand[normalizeMatcheteParameterScalars[coords[[i]]] /. logRule]];
            If[TrueQ[expr === 0],
              {},
              numerator = Expand[Numerator[expr]];
              If[PolynomialQ[numerator, lmu],
                coeffs = DeleteCases[CoefficientList[numerator, lmu], 0];
                Table[
                  <|
                    "Sector" -> sector,
                    "CoordinateIndex" -> i,
                    "EquationIndex" -> j,
                    "Equation" -> coeffs[[j]] == 0
                  |>,
                  {j, Length[coeffs]}
                ],
                {
                  <|
                    "Sector" -> sector,
                    "CoordinateIndex" -> i,
                    "EquationIndex" -> 1,
                    "Equation" -> numerator == 0
                  |>
                }
              ]
            ]
          ],
          {i, Length[coords]}
        ];
        local
      ]
    ],
    sectorComparisons
  ];
  DeleteDuplicatesBy[records, Lookup[#, "Equation"] &]
];

translateLmuSolutionRules[rules_List] := Module[{muRule},
  muRule = If[MemberQ[First /@ rules, Lmu],
    {\[Mu]bar2 -> Exp[Lmu /. rules] M^2},
    {}
  ];
  Join[DeleteCases[rules, Lmu -> _], muRule]
];

translateLmuReduceResult[reduceResult_] := reduceResult /. {
  Lmu -> Log[\[Mu]bar2/M^2]
};

solveMatchSystem[equationRecords_List, matchVars_List] := Module[
  {rawVars, solveVars, equations, solveResult, reduceResult, hasSolutionQ, translatedRules, reduceResolvedQ},
  rawVars = DeleteDuplicates @ Join[{Lmu}, DeleteCases[matchVars, Lmu]];
  solveVars = Select[rawVars, Head[#] === Symbol &];
  solveVars = DeleteCases[solveVars, \[Mu]bar2];
  equations = DeleteDuplicates @ DeleteCases[
    Simplify /@ (normalizeMatcheteParameterScalars /@ Lookup[equationRecords, "Equation", {}]),
    True
  ];

  If[equations === {},
    Return[<|
      "Variables" -> solveVars,
      "Equations" -> {},
      "SolveResult" -> {{}},
      "TranslatedSolveResult" -> {{}},
      "ReduceResult" -> True,
      "TranslatedReduceResult" -> True,
      "HasSolution" -> True
    |>]
  ];

  If[MemberQ[equations, False],
    Return[<|
      "Variables" -> solveVars,
      "Equations" -> equations,
      "SolveResult" -> {},
      "TranslatedSolveResult" -> {},
      "ReduceResult" -> False,
      "TranslatedReduceResult" -> False,
      "HasSolution" -> False
    |>]
  ];

  solveResult = Quiet[
    Solve[equations, solveVars, Reals],
    {Solve::svars, Solve::ifun, Solve::ratnz}
  ];

  reduceResult = Quiet[
    Reduce[equations, solveVars, Reals],
    {Reduce::ratnz, Reduce::nsmet}
  ];

  reduceResolvedQ = Head[reduceResult] =!= Reduce;
  hasSolutionQ = (ListQ[solveResult] && solveResult =!= {}) ||
    (reduceResolvedQ && reduceResult =!= False);
  translatedRules = If[ListQ[solveResult], translateLmuSolutionRules /@ solveResult, solveResult];

  <|
    "Variables" -> solveVars,
    "Equations" -> equations,
    "SolveResult" -> solveResult,
    "TranslatedSolveResult" -> translatedRules,
    "ReduceResult" -> reduceResult,
    "TranslatedReduceResult" -> translateLmuReduceResult[reduceResult],
    "HasSolution" -> hasSolutionQ
  |>
];

LoadMatcheteToXAct[inputFile_String, opts : OptionsPattern[]] := Module[
  {expr, absFile, translatedExpr},
  absFile = ExpandFileName[inputFile];
  If[
    OptionValue["SymbolSpec"] === Automatic &&
    AssociationQ[$LoadedMatcheteToXActCache] &&
    KeyExistsQ[$LoadedMatcheteToXActCache, absFile],
    Return[$LoadedMatcheteToXActCache[absFile]]
  ];
  expr = MatcheteXActTranslator`LoadMatcheteMXExpression[inputFile, OptionValue["SymbolSpec"]];
  If[expr === $Failed, Return[$Failed]];
  translatedExpr = canonExpr @ MatcheteXActTranslator`MatcheteToXAct[expr, OptionValue["TranslationRules"]];
  $LoadedMatcheteToXActCache[absFile] = translatedExpr;
  translatedExpr
];

NormalizeMatcheteFinitePart[expr_, opts : OptionsPattern[]] := Module[
  {expanded, hbarSym, epsSym, terms},
  hbarSym = OptionValue["HBarSymbol"];
  epsSym = OptionValue["EpsilonSymbol"];
  expanded = Expand[normalizeMatcheteParameterScalars[expr] /. {hbarSym -> 1, Scalar[hbarSym] -> 1}];
  terms = Which[
    expanded === 0, {},
    Head[expanded] === Plus, List @@ expanded,
    True, {expanded}
  ];
  canonExpr @ Total[finiteEpsilonPart[#, epsSym] & /@ terms]
];

ExpandFixedEHReferenceLagrangian[opts : OptionsPattern[]] := Module[
  {
    dmax, lambdaValue, kappaValue, ehSign, cosmologicalRaw, ehRaw, rawExpr, canonicalRawExpr,
    reducedExpr, cacheDir, cacheFile, useCacheQ, forceQ, safeTag, result
  },
  dmax = OptionValue["MaxDimension"];
  lambdaValue = OptionValue["LambdaReferenceValue"];
  kappaValue = OptionValue["KappaReferenceValue"];
  ehSign = OptionValue["EHSign"];
  useCacheQ = TrueQ[OptionValue["UseCache"]];
  forceQ = TrueQ[OptionValue["ForceRecompute"]];
  safeTag[x_] := StringReplace[ToString[InputForm[x]], Except[LetterCharacter | DigitCharacter] -> "_"];
  cacheDir = CacheDirectoryResolved[
    "CacheDirectory" -> OptionValue["CacheDirectory"],
    "Verbose" -> False
  ];
  cacheFile = FileNameJoin[{
    cacheDir,
    "fixed_eh_reference__D_" <> ToString[dmax] <>
      "__lam_" <> safeTag[lambdaValue] <>
      "__kap_" <> safeTag[kappaValue] <>
      "__sgn_" <> safeTag[ehSign] <> ".m"
  }];

  If[useCacheQ && FileExistsQ[cacheFile] && ! forceQ,
    compareLog["[reference] loading cached fixed EH expansion", {opts}];
    Return[Get[cacheFile]]
  ];

  compareLog["[reference] building fixed EH + cosmological expansion", {opts}];

  ensureEHReferenceSetup[];

  cosmologicalRaw = LambdaRefEH * (
    ExpandPerturbation[perturbationSeries[Sqrt[-DetgRef[]], 6, KappaRefEH]] // ToFlat // CollectTensors
  );

  ehRaw = ehSign * (2/KappaRefEH^2) * (
    ExpandPerturbation[
      perturbationSeries[Sqrt[-DetgRef[]] RicciScalarCD[], 4, KappaRefEH]
    ] // ToFlat // CollectTensors
  );

  rawExpr = referenceExprToOrbit[cosmologicalRaw + ehRaw, kappaValue, lambdaValue];
  canonicalRawExpr = Quiet[canonExpr[rawExpr], ToCanonical::cmods];
  reducedExpr = selectTermsByMassDimension[canonicalRawExpr, dmax];

  If[useCacheQ && ! DirectoryQ[cacheDir],
    CreateDirectory[cacheDir, CreateIntermediateDirectories -> True]
  ];

  result = <|
    "MaxDimension" -> dmax,
    "LambdaReferenceValue" -> lambdaValue,
    "KappaReferenceValue" -> kappaValue,
    "EHSign" -> ehSign,
    "RawExpression" -> canonicalRawExpr,
    "ReferenceExpression" -> reducedExpr
  |>;

  If[useCacheQ, Put[result, cacheFile]];
  result
];

CompareMatcheteToFixedEH[input_, opts : OptionsPattern[]] := Module[
  {
    allOpts, dmax, basisOpts, translatedExpr, normalizedExpr, referenceData,
    truncatedInputExpr, referenceExpr, inputReduction, canonicalData, comparisonInputReduction,
    referenceReduction, supportedSectors, matchVars, canonicalKineticSign,
    allSectors, sectorComparisons, supportedComparisons, unsupportedComparisons,
    matchRecords, matchInfo, supportedDifference, unsupportedDifference,
    inputSummary, referenceSummary, inputProjectionFailures, referenceProjectionFailures
  },
  allOpts = {opts};
  dmax = OptionValue["MaxDimension"];
  basisOpts = reductionOptionsFrom[allOpts];
  canonicalKineticSign = resolveCanonicalKineticSign[
    OptionValue["CanonicalKineticSign"],
    OptionValue["EHSign"]
  ];

  compareLog["[compare] preparing translated input", allOpts];

  translatedExpr = Which[
    StringQ[input] && FileExistsQ[input], LoadMatcheteToXAct[
      input,
      "TranslationRules" -> OptionValue["TranslationRules"],
      "SymbolSpec" -> OptionValue["SymbolSpec"]
    ],
    True, canonExpr[input]
  ];

  If[translatedExpr === $Failed, Return[$Failed]];

  normalizedExpr = NormalizeMatcheteFinitePart[translatedExpr];
  truncatedInputExpr = selectTermsByMassDimension[normalizedExpr, dmax];

  referenceData = ExpandFixedEHReferenceLagrangian[
      "MaxDimension" -> dmax,
      "LambdaReferenceValue" -> OptionValue["LambdaReferenceValue"],
      "KappaReferenceValue" -> OptionValue["KappaReferenceValue"],
      "EHSign" -> OptionValue["EHSign"],
      "CacheDirectory" -> OptionValue["CacheDirectory"],
      "UseCache" -> OptionValue["UseCache"],
      "ForceRecompute" -> OptionValue["ForceRecompute"],
    "Verbose" -> OptionValue["Verbose"]
  ];
  referenceExpr = referenceData["ReferenceExpression"];
  matchVars = DeleteDuplicates @ Join[
    OptionValue["MatchParameters"],
    referenceSolveVariablesFrom[
      OptionValue["LambdaReferenceValue"],
      OptionValue["KappaReferenceValue"],
      OptionValue["EHSign"]
    ]
  ];

  compareLog["[compare] reducing normalized Matchete expression", allOpts];
  inputReduction = ReduceLagrangian[truncatedInputExpr, Sequence @@ basisOpts];
  canonicalData = If[TrueQ[OptionValue["CanonicalNormalizeInput"]],
    Append[
      kineticNormalizationDataFromReduction[inputReduction, basisOpts],
      "TargetQuadraticSign" -> canonicalKineticSign
    ],
    <|"SucceededQ" -> False, "Reason" -> "Disabled", "TargetQuadraticSign" -> canonicalKineticSign|>
  ];
  comparisonInputReduction = If[TrueQ[Lookup[canonicalData, "SucceededQ", False]],
    canonicalNormalizeReduction[inputReduction, canonicalData["Factor"], canonicalKineticSign],
    inputReduction
  ];

  compareLog["[compare] reducing fixed EH reference expression", allOpts];
  referenceReduction = ReduceLagrangian[referenceExpr, Sequence @@ basisOpts];

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
            ComputeSectorData[sector[[1]], sector[[2]], Sequence @@ basisOpts]
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
  matchInfo = solveMatchSystem[matchRecords, matchVars];

  inputSummary = reductionSummaryFrom[comparisonInputReduction];
  referenceSummary = reductionSummaryFrom[referenceReduction];
  inputProjectionFailures = Keys @ Select[inputSummary, ! TrueQ[Lookup[#, "ProjectionSucceededQ", True]] &];
  referenceProjectionFailures = Keys @ Select[referenceSummary, ! TrueQ[Lookup[#, "ProjectionSucceededQ", True]] &];

  <|
    "TranslatedExpression" -> translatedExpr,
    "NormalizedExpression" -> normalizedExpr,
    "ComparedInputExpression" -> truncatedInputExpr,
    "RawReducedInput" -> inputReduction,
    "CanonicalNormalization" -> canonicalData,
    "CanonicalKineticSign" -> canonicalKineticSign,
    "ReducedInput" -> comparisonInputReduction,
    "ReferenceData" -> referenceData,
    "ReferenceExpression" -> referenceExpr,
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

texEscape[str_String] := StringReplace[
  str,
  {
    "\\" -> "\\textbackslash{}",
    "_" -> "\\_",
    "%" -> "\\%",
    "&" -> "\\&",
    "#" -> "\\#",
    "$" -> "\\$",
    "{" -> "\\{",
    "}" -> "\\}",
    "~" -> "\\textasciitilde{}",
    "^" -> "\\textasciicircum{}"
  }
];

texExpr[expr_] := texEscape[ToString[InputForm[expr]]];

formatSectorKey[key_List] := "{" <> ToString[key[[1]]] <> ", " <> ToString[key[[2]]] <> "}";

texTableRows[assoc_Association] := StringRiffle[
  KeyValueMap[
    Function[{key, row},
      StringRiffle[
        {
          formatSectorKey[key],
          ToString[row["InputTermCount"]],
          ToString[row["ProjectedIBPTermCount"]],
          ToString[row["ReducedTermCount"]],
          ToString[row["PhysicalCoordinateCount"]]
        },
        " & "
      ] <> " \\\\"
    ],
    assoc
  ],
  "\n"
];

buildMatchSolutionSummary[result_Association] := Module[{solveResult, reduceResult},
  solveResult = result["MatchSolutions", "TranslatedSolveResult"];
  reduceResult = result["MatchSolutions", "TranslatedReduceResult"];
  StringRiffle[
    {
      "\\subsection{Solved constraints}",
      If[ListQ[solveResult] && solveResult =!= {},
        "\\begin{verbatim}\n" <> ToString[InputForm[solveResult]] <> "\n\\end{verbatim}",
        "\\begin{verbatim}\n" <> ToString[InputForm[reduceResult]] <> "\n\\end{verbatim}"
      ]
    },
    "\n"
  ]
];

orbitBuildTimeStamp[] := DateString[{"Year", "-", "Month", "-", "Day", " ", "Hour", ":", "Minute", ":", "Second"}];

findPDFLaTeX[requested_] := Which[
  StringQ[requested] && FileExistsQ[requested], requested,
  StringQ[FindExecutable["pdflatex"]], FindExecutable["pdflatex"],
  FileExistsQ["C:\\Users\\alonlif2000\\AppData\\Local\\Programs\\MiKTeX\\miktex\\bin\\x64\\pdflatex.exe"],
    "C:\\Users\\alonlif2000\\AppData\\Local\\Programs\\MiKTeX\\miktex\\bin\\x64\\pdflatex.exe",
  True, Missing["NotFound"]
];

BuildMatcheteEHReport[result_Association, outBase_String, opts : OptionsPattern[]] := Module[
  {
    title, author, texFile, dataFile, pdfFile, inputSummaryRows, referenceSummaryRows,
    supportedRows, unsupportedList, equationsBlock, solutionBlock, validationBlock,
    texBody, pdfLatex, compileQ, compile1, compile2
  },
  title = OptionValue["Title"];
  author = OptionValue["Author"];
  texFile = outBase <> ".tex";
  dataFile = outBase <> "_data.wl";
  pdfFile = outBase <> ".pdf";
  compileQ = TrueQ[OptionValue["CompilePDF"]];

  Put[result, dataFile];

  inputSummaryRows = texTableRows[result["InputReductionSummary"]];
  referenceSummaryRows = texTableRows[result["ReferenceReductionSummary"]];

  supportedRows = StringRiffle[
    KeyValueMap[
      Function[{key, record},
        If[TrueQ[record["SupportedQ"]],
          StringRiffle[
            {
              formatSectorKey[key],
              ToString[Length[record["InputCoordinates"]]],
              ToString[Length[record["ReferenceCoordinates"]]],
              If[TrueQ[record["DifferenceIsZeroQ"]], "yes", "no"]
            },
            " & "
          ] <> " \\\\",
          Nothing
        ]
      ],
      result["SectorComparison"]
    ],
    "\n"
  ];

  unsupportedList = If[result["UnsupportedSectors"] === {},
    "None.",
    StringRiffle[formatSectorKey /@ result["UnsupportedSectors"], ", "]
  ];

  equationsBlock = If[result["MatchEquations"] === {},
    "No nontrivial supported-sector matching equations were generated.",
    "\\begin{verbatim}\n" <> ToString[InputForm[result["MatchEquations"]]] <> "\n\\end{verbatim}"
  ];

  solutionBlock = buildMatchSolutionSummary[result];

  validationBlock = If[KeyExistsQ[result, "ValidationSummary"],
    "\\section{Validation Summary}\n\\begin{verbatim}\n" <>
      ToString[InputForm[result["ValidationSummary"]]] <>
      "\n\\end{verbatim}",
    ""
  ];

  texBody = StringRiffle[
    {
      "\\documentclass[11pt]{article}",
      "\\usepackage[margin=1in]{geometry}",
      "\\usepackage[T1]{fontenc}",
      "\\usepackage{lmodern}",
      "\\usepackage{amsmath,amssymb,booktabs,longtable,hyperref}",
      "\\hypersetup{colorlinks=true,linkcolor=blue,urlcolor=blue,citecolor=blue}",
      "\\title{" <> texEscape[title] <> "}",
      "\\author{" <> texEscape[author] <> "}",
      "\\date{" <> texEscape[orbitBuildTimeStamp[]] <> "}",
      "\\begin{document}",
      "\\maketitle",
      "\\tableofcontents",
      "\\section{Setup and Conventions}",
      "This report compares a Matchete-derived Lagrangian to a reference action",
      "\\begin{equation}",
      "\\mathcal{L}_{\\mathrm{ref}} = \\Lambda_{\\mathrm{ref}} \\sqrt{-g} + s_{\\mathrm{EH}}\\, \\frac{2}{\\kappa_{\\mathrm{ref}}^2} \\sqrt{-g} R",
      "\\end{equation}",
      "with reference coefficients $\\Lambda_{\\mathrm{ref}} = " <> texEscape[ToString[InputForm[result["ReferenceData", "LambdaReferenceValue"]]]] <>
        "$, $\\kappa_{\\mathrm{ref}} = " <> texEscape[ToString[InputForm[result["ReferenceData", "KappaReferenceValue"]]]] <>
        "$, and $s_{\\mathrm{EH}} = " <> texEscape[ToString[InputForm[result["ReferenceData", "EHSign"]]]] <> "$.",
      "The Matchete input is normalized by setting $hbar = 1$ and discarding all terms containing negative powers of $\\epsilon$.",
      "If canonical normalization is enabled, the input quadratic sector is rescaled to the target sign $s_{\\mathrm{kin}} = " <>
        texEscape[ToString[InputForm[result["CanonicalKineticSign"]]]] <> "$ using the extracted factor",
      "\\begin{equation}",
      "Z_h = " <> texEscape[ToString[InputForm[Lookup[result["CanonicalNormalization"], "Factor", Missing["NotAvailable"]]]]) <> ", \\qquad " <>
        "\\beta^2 = \\frac{s_{\\mathrm{kin}}}{Z_h}.",
      "\\end{equation}",
      "\\section{Reference Support Through Mass Dimension " <> texEscape[ToString[InputForm[result["ReferenceData", "MaxDimension"]]]] <> "}",
      "The supported EH plus cosmological sectors are $\\{n_h, 0\\}$ together with the derivative sectors allowed by the requested mass-dimension cutoff.",
      "\\section{Reduced Matchete Input}",
      "\\begin{longtable}{rrrrr}",
      "\\toprule",
      "Sector & Input terms & IBP terms & Reduced terms & Coordinates \\\\",
      "\\midrule",
      inputSummaryRows,
      "\\bottomrule",
      "\\end{longtable}",
      "\\section{Reduced Fixed Reference}",
      "\\begin{longtable}{rrrrr}",
      "\\toprule",
      "Sector & Input terms & IBP terms & Reduced terms & Coordinates \\\\",
      "\\midrule",
      referenceSummaryRows,
      "\\bottomrule",
      "\\end{longtable}",
      "\\section{Sector-by-Sector Comparison}",
      "\\begin{longtable}{rrrr}",
      "\\toprule",
      "Sector & Input coords & Reference coords & Difference zero \\\\",
      "\\midrule",
      supportedRows,
      "\\bottomrule",
      "\\end{longtable}",
      "\\subsection{Unsupported sectors}",
      texEscape[unsupportedList],
      "\\subsection{Supported-sector matching equations}",
      equationsBlock,
      solutionBlock,
      "\\section{Differences}",
      "\\subsection{Supported difference}",
      "\\begin{verbatim}\n" <> ToString[InputForm[result["SupportedDifference"]]] <> "\n\\end{verbatim}",
      "\\subsection{Unsupported difference}",
      "\\begin{verbatim}\n" <> ToString[InputForm[result["UnsupportedDifference"]]] <> "\n\\end{verbatim}",
      "\\section{Conclusion}",
      If[TrueQ[result["ExactMatchQ"]],
        "An exact match exists after imposing the solved Matchete-side parameter constraints and checking that no unsupported sectors remain.",
        "No exact full match was established under the current fixed-reference conventions. The unsupported-sector content and/or the solved supported-sector equations obstruct equality."
      ],
      validationBlock,
      "\\end{document}"
    },
    "\n"
  ];

  Export[texFile, texBody, "String"];

  pdfLatex = findPDFLaTeX[OptionValue["PDFLaTeXPath"]];
  compile1 = Missing["NotRun"];
  compile2 = Missing["NotRun"];

  If[compileQ && StringQ[pdfLatex],
    compareLog["[report] compiling PDF with " <> pdfLatex, {opts}];
    compile1 = RunProcess[
      {pdfLatex, "-interaction=nonstopmode", "-halt-on-error", FileNameTake[texFile]},
      ProcessDirectory -> DirectoryName[ExpandFileName[texFile]]
    ];
    compile2 = RunProcess[
      {pdfLatex, "-interaction=nonstopmode", "-halt-on-error", FileNameTake[texFile]},
      ProcessDirectory -> DirectoryName[ExpandFileName[texFile]]
    ];
  ];

  <|
    "TeXFile" -> texFile,
    "DataFile" -> dataFile,
    "PDFFile" -> pdfFile,
    "PDFLaTeX" -> pdfLatex,
    "CompileFirstPass" -> compile1,
    "CompileSecondPass" -> compile2
  |>
];
