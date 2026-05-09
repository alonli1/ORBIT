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

storedD6QuadraticAnalysis = Get[FileNameJoin[{Directory[], "artifacts", "orbit_fixed_eh", "orbit_fixed_eh_quadratic_completion_analysis.wl"}]];

verificationAssumptions = M > 0 && \[Kappa] > 0 && \[Mu]bar2 > 0;

normalizeScalarExpr[expr_, subs_List : {}] := normalizeMatcheteParameterScalars[expr] /. subs;

zeroExprQ[expr_, subs_List : {}, assumptions_ : True] := Module[{checked},
  checked = canonExpr[normalizeScalarExpr[expr, subs]];
  TrueQ[checked === 0] || TrueQ[FullSimplify[checked == 0, assumptions]]
];

d6BasisOpts = {
  "MaxDimension" -> 6,
  "CacheDirectory" -> If[
    DirectoryQ[FileNameJoin[{Directory[], "cache", "left_only_uv_2_eft_6_cache"}]],
    FileNameJoin[{Directory[], "cache", "left_only_uv_2_eft_6_cache"}],
    FileNameJoin[{Directory[], "cache", "orbit_fixed_eh_cache"}]
  ],
  "UseCache" -> True,
  "Verbose" -> False
};

d6QuadraticFieldRedefinition = canonExpr @ LinearCombination[
  Lookup[
    storedD6QuadraticAnalysis["QuadraticRedefinitionCoefficients"],
    Range[Length[storedD6QuadraticAnalysis["QuadraticRedefinitionData", "IndependentDeltas"]]],
    0
  ],
  storedD6QuadraticAnalysis["QuadraticRedefinitionData", "IndependentDeltas"]
];

Print["building explicit first-order shift"];
{shiftTiming, shiftExpr} = AbsoluteTiming[ShiftFromRedefExpr[d6QuadraticFieldRedefinition]];
Print["shift time=" <> ToString[shiftTiming, InputForm]];

Print["projecting to the {2,4} sector basis"];
{projectionTiming, projectedShift} = AbsoluteTiming[
  Module[{terms, normalizedShiftExpr},
    terms = If[Head[Expand[shiftExpr]] === Plus, List @@ Expand[shiftExpr], {Expand[shiftExpr]}];
    normalizedShiftExpr = Total[ReplaceDummies /@ terms];
    ProjectToIBPUsingSectorData[normalizedShiftExpr, ComputeSectorData[2, 4, Sequence @@ d6BasisOpts]]
  ]
];
Print["projection time=" <> ToString[projectionTiming, InputForm]];
Print["projection residual zero=" <> ToString[zeroExprQ[projectedShift["ProjectionResidual"], {}, verificationAssumptions], InputForm]];
Print[
  "projected shift matches quadratic redefinition expression=" <>
  ToString[
    zeroExprQ[
      projectedShift["ProjectedExpr"] - storedD6QuadraticAnalysis["QuadraticRedefinitionExpression"],
      {},
      verificationAssumptions
    ],
    InputForm
  ]
];
Print[
  "projected shift matches analyzed projected difference=" <>
  ToString[
    zeroExprQ[
      projectedShift["ProjectedExpr"] - storedD6QuadraticAnalysis["ProjectedData", "ProjectedExpr"],
      {},
      verificationAssumptions
    ],
    InputForm
  ]
];

Exit[];
