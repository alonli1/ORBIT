(* ::Package:: *)

Quiet[Needs["xAct`xPert`"], PacletDataRebuild::lock];

If[! ValueQ[RunBasisComputation], Get["graviton_basis_toolkit.wl"]];
If[! ValueQ[MatcheteXActTranslator`MatcheteToXAct], Get["MatcheteXActTranslator.m"]];

ClearAll[
  LoadMatcheteToXAct, NormalizeMatcheteFinitePart, ExpandFixedEHReferenceLagrangian,
  CompareMatcheteToFixedEH, AnalyzeQuadraticFourDerivativeDifference,
  BuildMatcheteEHReport
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
AnalyzeQuadraticFourDerivativeDifference::usage =
  "AnalyzeQuadraticFourDerivativeDifference[result] analyzes the {2,4} comparison remainder in a curvature-squared basis and modulo quadratic higher-derivative field redefinitions.";
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
      "UseQuadraticCompletion" -> True,
      "VerificationSubstitutions" -> Automatic,
      "VerificationAssumptions" -> True,
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

Options[AnalyzeQuadraticFourDerivativeDifference] = DeleteDuplicatesBy[
  Join[
    {
      "Sector" -> {2, 4},
      "Substitutions" -> {},
      "UseQuadraticRedefinitions" -> True,
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
  linRicciExpr, linRicciScalarExpr, linRiemannExpr,
  curvatureSquaredProjectionData, quadraticFourDerivativeRedefinitionData,
  solveLinearVectorDecomposition,
  normalizeRuleList, resolveVerificationSubstitutions,
  exprZeroUnderVerificationQ, finalizeComparisonResult,
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

linRicciExpr[x_, y_] := Module[{c1, c2},
  c1 = DummyIn[TangentM];
  c2 = DummyIn[TangentM];
  canonExpr[
    1/2 (
      PD[-c1][PD[x][h[y, c1]]] +
      PD[-c1][PD[y][h[x, c1]]] -
      PD[x][PD[y][h[c2, -c2]]] -
      PD[-c1][PD[c1][h[x, y]]]
    )
  ]
];

linRicciScalarExpr[] := Module[{a1, b1, a2, b2},
  a1 = DummyIn[TangentM];
  b1 = DummyIn[TangentM];
  a2 = DummyIn[TangentM];
  b2 = DummyIn[TangentM];
  canonExpr[
    PD[-a1][PD[-b1][h[a1, b1]]] - PD[-a2][PD[a2][h[b2, -b2]]]
  ]
];

linRiemannExpr[x_, y_, z_, w_] := canonExpr[
  1/2 (
    PD[z][PD[y][h[x, w]]] +
    PD[w][PD[x][h[y, z]]] -
    PD[w][PD[y][h[x, z]]] -
    PD[z][PD[x][h[y, w]]]
  )
];

curvatureSquaredProjectionData[sec_Association] := Module[
  {basis, project, r2, ricci2Expr, ricci2},
  basis = sec["IBPBasis"];
  project = Function[expr, ProjectModuloIBP[canonExpr[expr], basis]];
  r2 = project[linRicciScalarExpr[] linRicciScalarExpr[]];
  ricci2Expr = Module[{a1, b1, c1, d1},
    a1 = DummyIn[TangentM];
    b1 = DummyIn[TangentM];
    c1 = DummyIn[TangentM];
    d1 = DummyIn[TangentM];
    canonExpr[
      eta[a1, c1] eta[b1, d1] linRicciExpr[-a1, -b1] linRicciExpr[-c1, -d1]
    ]
  ];
  ricci2 = project[ricci2Expr];
  <|
    "R2" -> r2,
    "Ricci2" -> ricci2,
    "Riemann2" -> Missing["NotComputed"],
    "GaussBonnet" -> Missing["NotComputed"],
    "IndependentGaugeInvariantNames" -> {"R2", "Ricci2"},
    "IndependentGaugeInvariantVectors" -> {r2["Coordinates"], ricci2["Coordinates"]}
  |>
];

quadraticFourDerivativeRedefinitionData[sec_Association, opts_List] := Module[
  {deltaBasis, shifts, proj, vecs, indRows, indVecs},
  deltaBasis = Rank2Basis[1, 2, Sequence @@ opts];
  shifts = ShiftFromRedefExpr /@ deltaBasis;
  proj = ProjectModuloIBP[#, sec["IBPBasis"]] & /@ shifts;
  vecs = proj[[All, "Coordinates"]];
  indRows = IndependentImageRows[vecs];
  indVecs = If[indRows === {}, {}, vecs[[indRows]]];
  <|
    "DeltaBasis" -> deltaBasis,
    "ShiftImages" -> shifts,
    "ProjectedData" -> proj,
    "ImageVectors" -> vecs,
    "IndependentRows" -> indRows,
    "IndependentVectors" -> indVecs,
    "IndependentDeltas" -> If[indRows === {}, {}, deltaBasis[[indRows]]],
    "Rank" -> If[MatrixQ[vecs] && vecs =!= {}, MatrixRank[vecs], 0]
  |>
];

solveLinearVectorDecomposition[targetCoords_List, basisVectors_List, prefix_String] := Module[
  {vars, eqns, sol, baseRules, freeRules, fullRules},
  If[basisVectors === {},
    Return[<|
      "HasSolution" -> ZeroVectorQ[targetCoords],
      "Variables" -> {},
      "Solution" -> {{}},
      "Rules" -> {},
      "Reconstructed" -> ConstantArray[0, Length[targetCoords]]
    |>]
  ];
  vars = Table[Symbol[prefix <> ToString[i]], {i, Length[basisVectors]}];
  eqns = Thread[Transpose[basisVectors].vars == targetCoords];
  sol = Quiet[Solve[eqns, vars], Solve::svars];
  baseRules = If[ListQ[sol] && sol =!= {}, First[sol], {}];
  freeRules = Thread[Complement[vars, First /@ baseRules] -> 0];
  fullRules = Join[baseRules /. freeRules, freeRules];
  <|
    "HasSolution" -> ListQ[sol] && sol =!= {},
    "Variables" -> vars,
    "Solution" -> sol,
    "Rules" -> fullRules,
    "Reconstructed" -> If[ListQ[sol] && sol =!= {},
      Simplify[Transpose[basisVectors].vars /. fullRules],
      ConstantArray[0, Length[targetCoords]]
    ]
  |>
];

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

normalizeRuleList[rules_] := Which[
  AssociationQ[rules], Normal[rules],
  ListQ[rules] && VectorQ[rules, MatchQ[#, _Rule | _RuleDelayed] &], rules,
  True, {}
];

resolveVerificationSubstitutions[matchInfo_Association, requested_] := Module[
  {translated, candidate},
  candidate = Which[
    requested === Automatic,
      translated = Lookup[matchInfo, "TranslatedSolveResult", {}];
      If[
        ListQ[translated] && translated =!= {} &&
          MatchQ[First[translated], {_Rule ..} | {}],
        First[translated],
        {}
      ],
    True,
      normalizeRuleList[requested]
  ];
  DeleteDuplicates[candidate]
];

exprZeroUnderVerificationQ[expr_, subs_List, assumptions_: True] := Module[{checked},
  checked = canonExpr[normalizeMatcheteParameterScalars[expr] /. subs];
  TrueQ[checked === 0] || TrueQ[FullSimplify[checked == 0, assumptions]]
];

finalizeComparisonResult[result_Association, basisOpts_List, opts_List] := Module[
  {
    useQuadraticCompletion, verificationSubs, verificationAssumptions,
    supportedComparisons, unsupportedComparisons, verifiedSupportedQ,
    verifiedUnsupportedComparisons, quadraticSector, quadraticCompletion,
    updatedUnsupportedDifference, exactMatchUnderSolveQ, verificationAppliedQ,
    finalExactQ
  },
  useQuadraticCompletion = TrueQ[Lookup[Association[opts], "UseQuadraticCompletion", True]];
  verificationSubs = resolveVerificationSubstitutions[
    Lookup[result, "MatchSolutions", <||>],
    Lookup[Association[opts], "VerificationSubstitutions", Automatic]
  ];
  verificationAssumptions = Lookup[Association[opts], "VerificationAssumptions", True];
  verificationAppliedQ = verificationSubs =!= {};
  exactMatchUnderSolveQ = TrueQ[Lookup[result, "ExactMatchQ", False]];
  quadraticSector = {2, 4};

  supportedComparisons = KeySelect[
    Lookup[result, "SectorComparison", <||>],
    MemberQ[Lookup[result, "SupportedSectors", {}], #] &
  ];
  unsupportedComparisons = KeySelect[
    Lookup[result, "SectorComparison", <||>],
    ! MemberQ[Lookup[result, "SupportedSectors", {}], #] &
  ];

  verifiedSupportedQ = If[
    verificationAppliedQ,
    And @@ (exprZeroUnderVerificationQ[#["DifferenceExpression"], verificationSubs, verificationAssumptions] & /@ Values[supportedComparisons]),
    Lookup[Lookup[result, "MatchSolutions", <||>], "HasSolution", False]
  ];

  verifiedUnsupportedComparisons = If[
    verificationAppliedQ,
    KeySelect[
      unsupportedComparisons,
      ! exprZeroUnderVerificationQ[unsupportedComparisons[#]["DifferenceExpression"], verificationSubs, verificationAssumptions] &
    ],
    KeySelect[
      unsupportedComparisons,
      ! TrueQ[unsupportedComparisons[#]["DifferenceIsZeroQ"]] &
    ]
  ];

  quadraticCompletion = Missing["NotApplied"];
  If[
    useQuadraticCompletion &&
    verificationAppliedQ &&
    KeyExistsQ[verifiedUnsupportedComparisons, quadraticSector],
    quadraticCompletion = AnalyzeQuadraticFourDerivativeDifference[
      result,
      Sequence @@ basisOpts,
      "Substitutions" -> verificationSubs,
      "Verbose" -> False
    ];
    If[
      AssociationQ[quadraticCompletion] &&
      TrueQ[quadraticCompletion["CurvatureSquaredModuloQuadraticRedefinitionsQ"]] &&
      TrueQ[quadraticCompletion["ResidualIsZeroQ"]],
      verifiedUnsupportedComparisons = KeyDrop[verifiedUnsupportedComparisons, {quadraticSector}]
    ];
  ];

  updatedUnsupportedDifference = canonExpr @ Total[
    Lookup[Values[verifiedUnsupportedComparisons], "DifferenceExpression", {}]
  ];

  finalExactQ = If[
    verificationAppliedQ,
    TrueQ[
      verifiedSupportedQ &&
      verifiedUnsupportedComparisons === <||> &&
      Lookup[result, "InputProjectionFailures", {}] === {} &&
      Lookup[result, "ReferenceProjectionFailures", {}] === {}
    ],
    exactMatchUnderSolveQ
  ];

  Join[
    result,
    <|
      "ExactMatchUnderSolveQ" -> exactMatchUnderSolveQ,
      "VerificationAppliedQ" -> verificationAppliedQ,
      "VerificationSubstitutions" -> verificationSubs,
      "VerificationAssumptions" -> verificationAssumptions,
      "VerifiedSupportedMatchQ" -> verifiedSupportedQ,
      "QuadraticCompletion" -> quadraticCompletion,
      "UnsupportedSectors" -> Keys[verifiedUnsupportedComparisons],
      "UnsupportedDifference" -> updatedUnsupportedDifference,
      "ExactMatchQ" -> finalExactQ
    |>
  ]
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
    inputSummary, referenceSummary, inputProjectionFailures, referenceProjectionFailures,
    rawResult
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

  rawResult = <|
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
  |>;

  finalizeComparisonResult[rawResult, basisOpts, allOpts]
];

AnalyzeQuadraticFourDerivativeDifference[result_Association, opts : OptionsPattern[]] := Module[
  {
    allOpts, sector, basisOpts, sec, rawExpr, expr, proj, curvatureData,
    redefData, basisVectors, decomposition, ruleAssoc, curvatureVars, redefVars,
    curvatureCoeffs, redefCoeffs, curvatureExpr, redefExpr, residualExpr
  },
  allOpts = {opts};
  sector = OptionValue["Sector"];
  If[sector =!= {2, 4},
    Return[$Failed]
  ];

  basisOpts = reductionOptionsFrom[allOpts];
  compareLog["[quadratic] loading sector data for " <> ToString[sector], allOpts];
  sec = Which[
    KeyExistsQ[Lookup[result, "SectorComparison", <||>], sector],
      Lookup[result["SectorComparison"][sector], "SectorData", Missing["NotAvailable"]],
    True,
      Missing["NotAvailable"]
  ];
  If[! AssociationQ[sec],
    sec = ComputeSectorData[sector[[1]], sector[[2]], Sequence @@ basisOpts];
  ];

  rawExpr = Which[
    KeyExistsQ[Lookup[result, "SectorComparison", <||>], sector],
      result["SectorComparison"][sector]["DifferenceExpression"],
    KeyExistsQ[Lookup[result, "UnsupportedDifference", <||>], sector],
      result["UnsupportedDifference"][sector],
    True,
      0
  ];
  compareLog["[quadratic] projecting analyzed expression to IBP basis", allOpts];
  expr = canonExpr[normalizeMatcheteParameterScalars[rawExpr] /. OptionValue["Substitutions"]];
  proj = ProjectToIBPUsingSectorData[expr, sec];
  compareLog["[quadratic] building curvature-squared basis projections", allOpts];
  curvatureData = curvatureSquaredProjectionData[sec];
  compareLog["[quadratic] building quadratic higher-derivative redefinition image", allOpts];
  redefData = If[TrueQ[OptionValue["UseQuadraticRedefinitions"]],
    quadraticFourDerivativeRedefinitionData[sec, basisOpts],
    <|"IndependentVectors" -> {}, "IndependentDeltas" -> {}, "Rank" -> 0|>
  ];

  basisVectors = Join[
    curvatureData["IndependentGaugeInvariantVectors"],
    Lookup[redefData, "IndependentVectors", {}]
  ];
  compareLog["[quadratic] solving decomposition in curvature + redefinition basis", allOpts];
  decomposition = solveLinearVectorDecomposition[proj["Coordinates"], basisVectors, "c24"];
  ruleAssoc = Association[Lookup[decomposition, "Rules", {}]];
  curvatureVars = Take[decomposition["Variables"], UpTo[Length[curvatureData["IndependentGaugeInvariantVectors"]]]];
  redefVars = Drop[decomposition["Variables"], Length[curvatureData["IndependentGaugeInvariantVectors"]]];
  curvatureCoeffs = If[decomposition["HasSolution"],
    Lookup[ruleAssoc, curvatureVars, Missing["NotAvailable"]],
    {}
  ];
  redefCoeffs = If[decomposition["HasSolution"],
    Lookup[ruleAssoc, redefVars, Missing["NotAvailable"]],
    {}
  ];
  curvatureExpr = If[decomposition["HasSolution"],
    canonExpr @ LinearCombination[curvatureCoeffs, {
      curvatureData["R2"]["ProjectedExpr"],
      curvatureData["Ricci2"]["ProjectedExpr"]
    }],
    0
  ];
  redefExpr = If[decomposition["HasSolution"] && redefCoeffs =!= {},
    canonExpr @ LinearCombination[redefCoeffs, Lookup[redefData["ProjectedData"], "ProjectedExpr", {}][[Lookup[redefData, "IndependentRows", {}]]]],
    0
  ];
  residualExpr = canonExpr[expr - curvatureExpr - redefExpr];

  <|
    "Sector" -> sector,
    "AnalyzedExpression" -> expr,
    "ProjectedData" -> proj,
    "CurvatureBasis" -> <|
      "R2Expression" -> curvatureData["R2"]["ProjectedExpr"],
      "R2Coordinates" -> curvatureData["R2"]["Coordinates"],
      "Ricci2Expression" -> curvatureData["Ricci2"]["ProjectedExpr"],
      "Ricci2Coordinates" -> curvatureData["Ricci2"]["Coordinates"],
      "Riemann2Expression" -> If[AssociationQ[curvatureData["Riemann2"]], curvatureData["Riemann2"]["ProjectedExpr"], Missing["NotComputed"]],
      "Riemann2Coordinates" -> If[AssociationQ[curvatureData["Riemann2"]], curvatureData["Riemann2"]["Coordinates"], Missing["NotComputed"]],
      "GaussBonnetExpression" -> If[AssociationQ[curvatureData["GaussBonnet"]], curvatureData["GaussBonnet"]["ProjectedExpr"], Missing["NotComputed"]],
      "GaussBonnetCoordinates" -> If[AssociationQ[curvatureData["GaussBonnet"]], curvatureData["GaussBonnet"]["Coordinates"], Missing["NotComputed"]]
    |>,
    "QuadraticRedefinitionData" -> redefData,
    "Decomposition" -> decomposition,
    "CurvatureCoefficients" -> AssociationThread[curvatureData["IndependentGaugeInvariantNames"], curvatureCoeffs],
    "QuadraticRedefinitionCoefficients" -> AssociationThread[
      Range[Length[redefCoeffs]],
      redefCoeffs
    ],
    "CurvatureExpression" -> curvatureExpr,
    "QuadraticRedefinitionExpression" -> redefExpr,
    "ResidualExpression" -> residualExpr,
    "ResidualIsZeroQ" -> TrueQ[residualExpr === 0],
    "PureQuadraticRedefinitionQ" -> TrueQ[residualExpr === 0] && And @@ (TrueQ[Simplify[# == 0]] & /@ Values[AssociationThread[curvatureData["IndependentGaugeInvariantNames"], curvatureCoeffs]]),
    "CurvatureSquaredModuloQuadraticRedefinitionsQ" -> TrueQ[residualExpr === 0]
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

findPDFLaTeX[requested_] := Module[{candidates, found},
  candidates = DeleteDuplicates @ Cases[
    {
      requested,
      FindExecutable["pdflatex"],
      Environment["PDFLATEX"],
      FileNameJoin[{$HomeDirectory, "AppData", "Local", "Programs", "MiKTeX", "miktex", "bin", "x64", "pdflatex.exe"}],
      FileNameJoin[{$HomeDirectory, "AppData", "Local", "Programs", "MiKTeX", "miktex", "bin", "pdflatex.exe"}]
    },
    s_String /; s =!= ""
  ];
  found = SelectFirst[candidates, FileExistsQ, Missing["NotFound"]];
  found
];

BuildMatcheteEHReport[result_Association, outBase_String, opts : OptionsPattern[]] := Module[
  {
    title, author, texFile, dataFile, pdfFile, inputSummaryRows, referenceSummaryRows,
    supportedRows, unsupportedList, equationsBlock, solutionBlock, validationBlock,
    crosscheckBlock,
    refData, refLambdaText, refKappaText, refSignText, kinSignText, canonFactorText, canonFactorBlock, maxDimText,
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
  refData = Lookup[result, "ReferenceData", <||>];
  refLambdaText = texEscape[ToString[InputForm[Lookup[refData, "LambdaReferenceValue", Missing["NotAvailable"]]]]];
  refKappaText = texEscape[ToString[InputForm[Lookup[refData, "KappaReferenceValue", Missing["NotAvailable"]]]]];
  refSignText = texEscape[ToString[InputForm[Lookup[refData, "EHSign", Missing["NotAvailable"]]]]];
  kinSignText = texEscape[ToString[InputForm[Lookup[result, "CanonicalKineticSign", Missing["NotAvailable"]]]]];
  canonFactorText = ToString[InputForm[Lookup[Lookup[result, "CanonicalNormalization", <||>], "Factor", Missing["NotAvailable"]]]];
  canonFactorBlock = "\\begin{verbatim}\n" <> canonFactorText <> "\n\\end{verbatim}";
  maxDimText = texEscape[ToString[InputForm[Lookup[refData, "MaxDimension", Missing["NotAvailable"]]]]];

  validationBlock = If[KeyExistsQ[result, "ValidationSummary"],
    "\\section{Validation Summary}\n\\begin{verbatim}\n" <>
      ToString[InputForm[result["ValidationSummary"]]] <>
      "\n\\end{verbatim}",
    ""
  ];
  crosscheckBlock = If[KeyExistsQ[result, "IndependentCrosscheckSummary"],
    StringRiffle[
      {
        "\\subsection{Independent quadratic cross-check}",
        "A second script verified the completed \\{2,4\\} statement directly from the saved vectors, without using the main analyzer helper.",
        "\\begin{verbatim}\n" <>
          ToString[InputForm[result["IndependentCrosscheckSummary"]]] <>
          "\n\\end{verbatim}"
      },
      "\n"
    ],
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
      "with reference coefficients $\\Lambda_{\\mathrm{ref}} = " <> refLambdaText <>
        "$, $\\kappa_{\\mathrm{ref}} = " <> refKappaText <>
        "$, and $s_{\\mathrm{EH}} = " <> refSignText <> "$.",
      "The Matchete input is normalized by setting $hbar = 1$ and discarding all terms containing negative powers of $\\epsilon$.",
      "If canonical normalization is enabled, the input quadratic sector is rescaled to the target sign $s_{\\mathrm{kin}} = " <>
        kinSignText <> "$ using an extracted symbolic factor $Z_h$. The raw factor used in the computation is:",
      canonFactorBlock,
      "\\begin{equation}",
      "\\beta^2 = \\frac{s_{\\mathrm{kin}}}{Z_h}.",
      "\\end{equation}",
      "\\section{Reference Support Through Mass Dimension " <> maxDimText <> "}",
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
      "\\section{Raw Sector-by-Sector Comparison}",
      "\\begin{longtable}{rrrr}",
      "\\toprule",
      "Sector & Input coords & Reference coords & Raw diff. zero \\\\",
      "\\midrule",
      supportedRows,
      "\\bottomrule",
      "\\end{longtable}",
      If[TrueQ[Lookup[result, "VerificationAppliedQ", False]],
        "The table above reports the unreduced symbolic comparison before the explicit verification substitutions are imposed. The exact-match conclusion below uses the verified branch together with the quadratic completion data.",
        ""
      ],
      "\\subsection{Unsupported sectors}",
      texEscape[unsupportedList],
      If[TrueQ[Lookup[result, "VerificationAppliedQ", False]],
        StringRiffle[
          {
            "\\subsection{Verification substitutions}",
            "\\begin{verbatim}\n" <>
              ToString[InputForm[Lookup[result, "VerificationSubstitutions", {}]]] <>
              "\n\\end{verbatim}",
            "\\subsection{Verified supported-sector match}",
            texEscape[ToString[InputForm[Lookup[result, "VerifiedSupportedMatchQ", Missing["NotAvailable"]]]]]
          },
          "\n"
        ],
        ""
      ],
      If[AssociationQ[Lookup[result, "QuadraticCompletion", Missing["NotAvailable"]]],
        StringRiffle[
          {
            "\\subsection{Quadratic completion}",
            "\\begin{verbatim}\n" <>
              ToString[InputForm[Lookup[result["QuadraticCompletion"], "CurvatureCoefficients", Missing["NotAvailable"]]]] <>
              "\n\\end{verbatim}",
            "\\begin{verbatim}\n" <>
              ToString[InputForm[Lookup[result["QuadraticCompletion"], "QuadraticRedefinitionCoefficients", Missing["NotAvailable"]]]] <>
              "\n\\end{verbatim}"
          },
          "\n"
        ],
        ""
      ],
      "\\subsection{Supported-sector matching equations}",
      equationsBlock,
      solutionBlock,
      "\\section{Differences}",
      "\\subsection{Supported difference}",
      "\\begin{verbatim}\n" <> ToString[InputForm[result["SupportedDifference"]]] <> "\n\\end{verbatim}",
      "\\subsection{Unsupported difference}",
      "\\begin{verbatim}\n" <> ToString[InputForm[result["UnsupportedDifference"]]] <> "\n\\end{verbatim}",
      crosscheckBlock,
      "\\section{Conclusion}",
      If[TrueQ[result["ExactMatchQ"]],
        If[TrueQ[Lookup[result, "VerificationAppliedQ", False]],
          "An exact match exists after imposing the verified matching substitutions and applying the enlarged quadratic quotient, including the completed treatment of the \\{2,4\\} sector.",
          "An exact match exists after imposing the solved Matchete-side parameter constraints and checking that no unsupported sectors remain."
        ],
        "No exact full match was established under the current fixed-reference conventions. The unsupported-sector content and/or the solved supported-sector equations obstruct equality."
      ],
      If[KeyExistsQ[result, "IndependentCrosscheckSummary"],
        "The independent saved-vector cross-check confirms that the remaining quadratic four-derivative sector is a pure quadratic field-redefinition image with vanishing curvature-squared coefficients.",
        ""
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
