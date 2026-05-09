(* ================================================================ *)
(*  ORBIT Comprehensive Test Suite                                   *)
(*  Tests every computation stage from input to output.              *)
(*  Run: wolframscript -file tests/orbit_comprehensive_test.wls      *)
(* ================================================================ *)

(* ================================================================ *)
(*  0. Setup and test harness                                        *)
(* ================================================================ *)

scriptDir = DirectoryName[$InputFileName];
repoRoot = NestWhile[
  DirectoryName,
  scriptDir,
  ! FileExistsQ[FileNameJoin[{#, "graviton_basis_toolkit.wl"}]] &
];
SetDirectory[repoRoot];

$testCacheDir = FileNameJoin[{
  Directory[], "cache",
  "orbit_test_cache_" <> ToString[$ProcessID]
}];

$testOpts = {
  "CacheDirectory" -> $testCacheDir,
  "UseCache" -> True,
  "ForceRecompute" -> False,
  "Verbose" -> False
};

Print["Loading graviton_basis_toolkit.wl ..."];
Get["graviton_basis_toolkit.wl"];
Print["Loading orbit_fixed_eh_comparison.wl ..."];
Get["orbit_fixed_eh_comparison.wl"];

(* xAct routines and SolveConstants can require deep recursion
   for large tensor expressions. Increase from default 1024. *)
$RecursionLimit = 4096;

Print["Toolkit loaded. Starting tests.\n"];

(* --- Test harness --- *)

$testCount = 0;
$failCount = 0;
$passCount = 0;
$skipCount = 0;
$failures = {};
$testLog = {};  (* collects all output lines for file export *)

testLog[msg_String] := (
  AppendTo[$testLog, msg];
  Print[msg]
);

assert[label_String, condition_] := (
  $testCount++;
  If[TrueQ[condition],
    $passCount++;
    testLog["  PASS: " <> label],
    (* else *)
    $failCount++;
    AppendTo[$failures, label];
    testLog["  FAIL: " <> label]
  ]
);

skip[label_String, reason_String] := (
  $testCount++;
  $skipCount++;
  testLog["  SKIP: " <> label <> " (" <> reason <> ")"]
);

(* ================================================================ *)
(*  Stage 1: Utility functions                                       *)
(* ================================================================ *)

testLog["\n=== Stage 1: Utility Functions ==="];

(* Test 1.1 — CompositionList against binomial formula *)
assert["1.1a CompositionList[0,1]",
  CompositionList[0, 1] === {{0}}
];
assert["1.1b CompositionList[2,2]",
  Sort[CompositionList[2, 2]] === Sort[{{0,2},{1,1},{2,0}}]
];
Block[{allOK = True},
  Do[
    If[Length[CompositionList[n, k]] =!= Binomial[n + k - 1, k - 1],
      allOK = False
    ],
    {n, 0, 6}, {k, 1, 5}
  ];
  assert["1.1c CompositionList length = Binomial[n+k-1,k-1] for 0<=n<=6, 1<=k<=5", allOK]
];

(* Test 1.2 — PivotColumns and PivotRows *)
assert["1.2a PivotColumns identity 3x3",
  PivotColumns[IdentityMatrix[3]] === {1, 2, 3}
];
assert["1.2b PivotColumns {{1,0,1},{0,1,1}}",
  PivotColumns[{{1, 0, 1}, {0, 1, 1}}] === {1, 2}
];
assert["1.2c PivotColumns rank-1 {{1,2,3},{2,4,6}}",
  PivotColumns[{{1, 2, 3}, {2, 4, 6}}] === {1}
];
assert["1.2d PivotRows == PivotColumns[Transpose]",
  Module[{m = {{1, 0, 1}, {0, 1, 1}}},
    PivotRows[m] === PivotColumns[Transpose[m]]
  ]
];

(* Test 1.3 — LinearCombination *)
assert["1.3a LinearCombination unit vector",
  LinearCombination[{1, 0, 0}, {a, b, c}] === a
];
assert["1.3b LinearCombination general",
  Expand[LinearCombination[{2, -1, 3}, {x, y, z}]] === Expand[2 x - y + 3 z]
];

(* Test 1.4 — NormalizeSectorList *)
assert["1.4a NormalizeSectorList Automatic d=3",
  Sort[NormalizeSectorList[Automatic, 3]] ===
    Sort[{{1,0},{1,1},{2,0},{1,2},{2,1},{3,0}}]
];
assert["1.4b NormalizeSectorList dedup",
  Sort[NormalizeSectorList[{{3,2},{3,2},{1,0}}, 99]] ===
    Sort[{{3,2},{1,0}}]
];

(* Test 1.5 — ZeroVectorQ *)
assert["1.5a ZeroVectorQ all zeros", ZeroVectorQ[{0, 0, 0}]];
assert["1.5b ZeroVectorQ non-zero", ! ZeroVectorQ[{0, 1, 0}]];
assert["1.5c ZeroVectorQ empty", ZeroVectorQ[{}]];

(* Test 1.6 — SplitTermsBySector *)
assert["1.6a SplitTermsBySector[0] empty",
  SplitTermsBySector[0] === <||>
];
(* Use the trace h^a_a (sector {1,0}) + LFP (sector {2,2}) as a valid
   two-sector scalar expression. Raw DummyIn calls would leave
   uncontracted indices causing Validate::inhom. *)
Block[{twoSectorExpr, sectors},
  twoSectorExpr = canonExpr[h[a, -a] + LFP];
  sectors = SplitTermsBySector[twoSectorExpr];
  assert["1.6b SplitTermsBySector multi-sector has >=1 key",
    Length[Keys[sectors]] >= 1
  ];
  assert["1.6c SplitTermsBySector has exactly 2 sector keys",
    Length[Keys[sectors]] == 2
  ]
];

(* Test 1.7 — PrettyKey *)
assert["1.7 PrettyKey",
  PrettyKey[<|"nh" -> 3, "Nd" -> 2|>] === "nh_3__Nd_2"
];

(* Test 1.8 — SafeSolveConstants *)
Block[{result},
  result = SafeSolveConstants[0 == 0];
  assert["1.8a SafeSolveConstants trivial returns {{}}",
    MatchQ[result, {{___}}]
  ]
];

(* ================================================================ *)
(*  Stage 2: Raw basis generation                                    *)
(* ================================================================ *)

testLog["\n=== Stage 2: Raw Basis Generation ==="];

(* Test 2.1 — Odd-derivative sectors are empty *)
assert["2.1a RawScalarBasis[2,1] empty",
  RawScalarBasis[2, 1, Sequence @@ $testOpts] === {}
];
assert["2.1b RawScalarBasis[3,3] empty",
  RawScalarBasis[3, 3, Sequence @@ $testOpts] === {}
];
assert["2.1c RawScalarBasis[1,1] empty",
  RawScalarBasis[1, 1, Sequence @@ $testOpts] === {}
];

(* Test 2.2 — Basis elements are canonical and deduplicated *)
Block[{raw22, raw32},
  raw22 = RawScalarBasis[2, 2, Sequence @@ $testOpts];
  raw32 = RawScalarBasis[3, 2, Sequence @@ $testOpts];
  assert["2.2a {2,2} basis elements canonical",
    And @@ (canonExpr[#] === # & /@ raw22)
  ];
  assert["2.2b {2,2} no hidden duplicates",
    Length[canonList[raw22]] == Length[raw22]
  ];
  assert["2.2c {3,2} basis elements canonical",
    And @@ (canonExpr[#] === # & /@ raw32)
  ];
  assert["2.2d {3,2} no hidden duplicates",
    Length[canonList[raw32]] == Length[raw32]
  ];
];

(* Test 2.3 — Independent raw count verification *)
Block[{raw22A, raw22B},
  raw22A = RawScalarBasis[2, 2, Sequence @@ $testOpts];
  raw22B = canonList @ Flatten[
    AllContractions /@ (ScalarMonomialFromPartition /@ CompositionList[2, 2])
  ];
  assert["2.3 Independent raw count {2,2} matches",
    Length[raw22A] == Length[raw22B]
  ]
];

(* Test 2.4 — Rank2Basis odd-derivative sectors are empty *)
assert["2.4a Rank2Basis[1,1] empty",
  Rank2Basis[1, 1, Sequence @@ $testOpts] === {}
];
assert["2.4b Rank2Basis[2,1] empty",
  Rank2Basis[2, 1, Sequence @@ $testOpts] === {}
];

(* ================================================================ *)
(*  Stage 3: IBP quotient                                            *)
(* ================================================================ *)

testLog["\n=== Stage 3: IBP Quotient ==="];

(* Test 3.1 — Independent IBP count for {2,2} *)
Block[{raw, ans, el, allVars, sol, freeVars, ibpCountIndep, ibpCountToolkit, sec},
  raw = RawScalarBasis[2, 2, Sequence @@ $testOpts];
  ans = MakeAnsatz[raw, ConstantPrefix -> t];
  allVars = Table[Symbol["t" <> ToString[i]], {i, Length[raw]}];
  el = canonExpr @ VarD[h[-m, -n], PD][ans];
  sol = Quiet[SolveConstants[el == 0, allVars], Solve::svars];
  freeVars = If[ListQ[sol] && sol =!= {},
    Length[Complement[
      allVars,
      Cases[First[sol], Rule[lhs_Symbol, _] :> lhs]
    ]],
    0
  ];
  ibpCountIndep = Length[raw] - freeVars;
  sec = ComputeSectorData[2, 2, Sequence @@ $testOpts];
  ibpCountToolkit = sec["IBPCount"];
  assert["3.1 Independent IBP count {2,2} matches toolkit",
    ibpCountIndep == ibpCountToolkit
  ]
];

(* Test 3.2 — IBP relations are total derivatives *)
Block[{sec, raw, relMat, allZero},
  sec = ComputeSectorData[2, 2, Sequence @@ $testOpts];
  raw = sec["RawBasis"];
  relMat = sec["IBPRelationMatrix"];
  allZero = If[relMat === {} || ! MatrixQ[relMat], True,
    And @@ Table[
      Module[{L = canonExpr @ LinearCombination[relMat[[j]], raw]},
        canonExpr[VarD[h[-m, -n], PD][L]] === 0
      ],
      {j, Length[relMat]}
    ]
  ];
  assert["3.2 IBP relations in {2,2} are total derivatives", allZero]
];

(* Test 3.3 — IBP basis elements are independent modulo IBP *)
Block[{sec, ibpBasis, ans2, allVars2, el2, sol2, solvedVars},
  sec = ComputeSectorData[2, 2, Sequence @@ $testOpts];
  ibpBasis = sec["IBPBasis"];
  If[ibpBasis === {},
    skip["3.3 IBP basis independence {2,2}", "empty IBP basis"],
    ans2 = MakeAnsatz[ibpBasis, ConstantPrefix -> w];
    allVars2 = Table[Symbol["w" <> ToString[i]], {i, Length[ibpBasis]}];
    el2 = canonExpr @ VarD[h[-m, -n], PD][ans2];
    sol2 = Quiet[SolveConstants[el2 == 0, allVars2], Solve::svars];
    solvedVars = If[ListQ[sol2] && sol2 =!= {},
      Cases[First[sol2], Rule[lhs_Symbol, rhs_] /; rhs === 0 :> lhs],
      {}
    ];
    assert["3.3 IBP basis elements in {2,2} are independent (no further IBP relations)",
      (* All variables should be forced to zero *)
      Length[solvedVars] == Length[allVars2] ||
      (* Or there is no nontrivial solution *)
      (ListQ[sol2] && sol2 =!= {} &&
       And @@ ((# === 0 &) /@ (allVars2 /. First[sol2])))
    ]
  ]
];

(* Test 3.4 — Empty basis gives empty IBP data *)
Block[{ibpEmpty},
  ibpEmpty = IBPData[{}];
  assert["3.4 IBPData[{}] has empty relations",
    ibpEmpty["RelationMatrix"] === {} && ibpEmpty["FreeParameters"] === {}
  ]
];

(* Test 3.5 — Sector {1,2}: all operators are total derivatives *)
Block[{sec12},
  sec12 = ComputeSectorData[1, 2, Sequence @@ $testOpts];
  assert["3.5 Sector {1,2} has IBPCount=0 (all total derivatives)",
    sec12["IBPCount"] == 0
  ]
];

(* ================================================================ *)
(*  Stage 4: Field-redefinition image                                *)
(* ================================================================ *)

testLog["\n=== Stage 4: Field-Redefinition Image ==="];

(* Test 4.1 — Fierz-Pauli Lagrangian properties *)
assert["4.1a LFP is nonzero", LFP =!= 0];
assert["4.1b LFP is canonical", canonExpr[LFP] === LFP];
Block[{fpSectors},
  fpSectors = Keys[SplitTermsBySector[LFP]];
  assert["4.1c LFP lies in sector {2,2}",
    fpSectors === {{2, 2}}
  ]
];

(* Test 4.2 — ShiftFromRedefExpr produces correct sector *)
Block[{deltas20, shifts, sectorKeys},
  deltas20 = Rank2Basis[2, 0, Sequence @@ $testOpts];
  If[deltas20 === {},
    skip["4.2 ShiftFromRedefExpr sector check", "empty Rank2Basis[2,0]"],
    shifts = ShiftFromRedefExpr /@ deltas20;
    sectorKeys = DeleteDuplicates @ Flatten[
      Keys[SplitTermsBySector[#]] & /@ shifts, 1
    ];
    assert["4.2 Shift images from Rank2Basis[2,0] land in {3,2}",
      sectorKeys === {{3, 2}}
    ]
  ]
];

(* Test 4.3a — Redundant-image reduction to zero: sector {3,2} *)
Block[{sec32, coeffs, lag, reduction, sectorReduction},
  sec32 = ComputeSectorData[3, 2, Sequence @@ $testOpts];
  If[sec32["RedefRank"] == 0,
    skip["4.3a Redundant image {3,2} to zero", "no redef in {3,2}"],
    coeffs = Take[{7, -11, 13, -17, 19, -23, 29, -31}, Length[sec32["RedefDeltaBasis"]]];
    lag = Expand @ Total[MapThread[Times, {coeffs, sec32["RedefShiftImages"]}]];
    reduction = ReduceLagrangian[lag, Sequence @@ $testOpts];
    assert["4.3a Redundant image {3,2} reduces to zero",
      reduction["ReducedExpression"] === 0
    ]
  ]
];

(* Test 4.3b — Redundant-image reduction to zero: sector {3,4} *)
Block[{sec34, coeffs, lag, reduction},
  sec34 = ComputeSectorData[3, 4, Sequence @@ Join[$testOpts, {"MaxDimension" -> 7}]];
  If[sec34["RedefRank"] == 0,
    skip["4.3b Redundant image {3,4} to zero", "no redef in {3,4}"],
    coeffs = Take[
      {7, -11, 13, -17, 19, -23, 29, -31, 37, -41, 43, -47, 53, -59, 61, -67,
       71, -73, 79, -83, 89, -97, 101, -103, 107, -109, 113, -127, 131, -137,
       139, -149, 151, -157, 163, -167, 173, -179, 181, -191},
      Length[sec34["RedefDeltaBasis"]]
    ];
    lag = Expand @ Total[MapThread[Times, {coeffs, sec34["RedefShiftImages"]}]];
    reduction = ReduceLagrangian[lag,
      Sequence @@ Join[$testOpts, {"MaxDimension" -> 7}]
    ];
    assert["4.3b Redundant image {3,4} reduces to zero",
      reduction["ReducedExpression"] === 0
    ]
  ]
];

(* Test 4.4 — Quadratic sectors have zero RedefRank *)
Block[{sec20, sec22, sec10},
  sec20 = ComputeSectorData[2, 0, Sequence @@ $testOpts];
  sec22 = ComputeSectorData[2, 2, Sequence @@ $testOpts];
  sec10 = ComputeSectorData[1, 0, Sequence @@ $testOpts];
  assert["4.4a {2,0} RedefRank=0", sec20["RedefRank"] == 0];
  assert["4.4b {2,2} RedefRank=0", sec22["RedefRank"] == 0];
  assert["4.4c {1,0} RedefRank=0", sec10["RedefRank"] == 0];
];

(* Test 4.5 — PhysicalCount = IBPCount - RedefRank for interaction sectors *)
Block[{res5, allOK = True},
  res5 = RunBasisComputation[
    "MaxDimension" -> 5,
    Sequence @@ $testOpts
  ];
  Do[
    Module[{sec = res5["SectorData"][key]},
      If[key[[1]] >= 3 && sec["PhysicalCount"] =!= sec["IBPCount"] - sec["RedefRank"],
        allOK = False
      ]
    ],
    {key, res5["SectorList"]}
  ];
  assert["4.5 PhysicalCount = IBPCount - RedefRank for all nh>=3 sectors (D<=5)", allOK]
];

(* Test 4.6 — Independent redef rank verification for {3,2} *)
Block[{sec32, deltas, shifts, ibpBasis, projCoords, indepRank},
  sec32 = ComputeSectorData[3, 2, Sequence @@ $testOpts];
  deltas = Rank2Basis[2, 0, Sequence @@ $testOpts];
  If[deltas === {},
    skip["4.6 Independent redef rank {3,2}", "empty delta basis"],
    ibpBasis = sec32["IBPBasis"];
    shifts = ShiftFromRedefExpr /@ deltas;
    (* Must use ProjectModuloIBP, not DirectProjectToBasis, because
       shift images contain total-derivative parts that only cancel
       under the Euler operator. *)
    projCoords = Table[
      ProjectModuloIBP[shifts[[i]], ibpBasis]["Coordinates"],
      {i, Length[shifts]}
    ];
    If[MatrixQ[projCoords],
      indepRank = MatrixRank[projCoords];
      assert["4.6 Independent redef rank {3,2} matches toolkit",
        indepRank == sec32["RedefRank"]
      ],
      assert["4.6 Independent redef rank {3,2} — projection failed", False]
    ]
  ]
];

(* ================================================================ *)
(*  Stage 5: Full sector assembly                                    *)
(* ================================================================ *)

testLog["\n=== Stage 5: Full Sector Assembly ==="];

(* Test 5.1 — Internal consistency for D<=5 *)
Block[{res5, allOK = True},
  res5 = RunBasisComputation["MaxDimension" -> 5, Sequence @@ $testOpts];
  Do[
    Module[{sec = res5["SectorData"][key]},
      If[Length[sec["RawBasis"]] =!= sec["RawCount"], allOK = False];
      If[Length[sec["IBPBasis"]] =!= sec["IBPCount"], allOK = False];
      If[Length[sec["PhysicalBasis"]] =!= sec["PhysicalCount"], allOK = False];
      If[sec["Dimension"] =!= sec["nh"] + sec["Nd"], allOK = False];
      If[key[[1]] >= 3 && sec["PhysicalCount"] =!= sec["IBPCount"] - sec["RedefRank"],
        allOK = False
      ];
      If[key[[1]] < 3 && sec["PhysicalCount"] =!= sec["IBPCount"],
        allOK = False
      ];
    ],
    {key, res5["SectorList"]}
  ];
  assert["5.1 Internal consistency for all sectors D<=5", allOK]
];

(* Test 5.2 — Cross-verify {2,4} against curvature-squared count *)
Block[{sec24, curvData},
  sec24 = ComputeSectorData[2, 4, Sequence @@ Join[$testOpts, {"MaxDimension" -> 6}]];
  assert["5.2a {2,4} IBPCount >= 2 (must contain curvature-squared subspace)",
    sec24["IBPCount"] >= 2
  ];
  curvData = curvatureSquaredProjectionData[sec24];
  Block[{r2coords, ricci2coords, curvRank},
    r2coords = curvData["R2"]["Coordinates"];
    ricci2coords = curvData["Ricci2"]["Coordinates"];
    curvRank = If[MatrixQ[{r2coords, ricci2coords}],
      MatrixRank[{r2coords, ricci2coords}],
      0
    ];
    assert["5.2b Curvature-squared subspace in {2,4} has rank 2 (Gauss-Bonnet in 4D)",
      curvRank == 2
    ]
  ]
];

(* Test 5.3 — Sector data keys are complete *)
Block[{sec, requiredKeys, allPresent},
  sec = ComputeSectorData[3, 2, Sequence @@ $testOpts];
  requiredKeys = {
    "nh", "Nd", "Dimension",
    "RawBasis", "RawCount",
    "IBPBasis", "IBPCount", "IBPPivots", "IBPRelationMatrix",
    "RedefRank", "RedefPivots",
    "PhysicalBasis", "PhysicalCount",
    "RedefinitionRules"
  };
  allPresent = And @@ (KeyExistsQ[sec, #] & /@ requiredKeys);
  assert["5.3 Sector data has all required keys", allPresent]
];

(* Test 5.4 — Caching round-trip *)
Block[{sec1, sec2},
  sec1 = ComputeSectorData[2, 2, Sequence @@ $testOpts];
  (* Force reload from cache *)
  sec2 = ComputeSectorData[2, 2, Sequence @@ $testOpts];
  assert["5.4 Cache round-trip: counts match",
    sec1["RawCount"] == sec2["RawCount"] &&
    sec1["IBPCount"] == sec2["IBPCount"] &&
    sec1["PhysicalCount"] == sec2["PhysicalCount"] &&
    sec1["RedefRank"] == sec2["RedefRank"]
  ]
];

(* ================================================================ *)
(*  Stage 6: Lagrangian reduction                                    *)
(* ================================================================ *)

testLog["\n=== Stage 6: Lagrangian Reduction ==="];

(* Test 6.1 — Physical basis element is a fixed point
   The quadratic Fierz-Pauli Lagrangian should be a fixed point of sector reduction. *)
Block[{red, red2},
  red = CheckAbort[
    TimeConstrained[
      ReduceSectorLagrangian[LFP, 2, 2, Sequence @@ $testOpts],
      60,
      $TimedOut
    ],
    $Aborted
  ];
  assert["6.1a ReduceSectorLagrangian completes on LFP",
    AssociationQ[red] && red =!= $TimedOut
  ];
  If[AssociationQ[red],
    red2 = ReduceSectorLagrangian[red["ReducedExpression"], 2, 2, Sequence @@ $testOpts];
    assert["6.1b Reduced LFP representative is idempotent",
      canonExpr[red2["ReducedExpression"] - red["ReducedExpression"]] === 0
    ];
    assert["6.1c LFP projection residual is zero",
      TrueQ[red["ProjectionResidual"] === 0]
    ];
    assert["6.1d LFP physical coordinates are nonzero",
      ! ZeroVectorQ[red["PhysicalCoordinates"]]
    ]
  ]
];

(* Test 6.1d — Diagnose ReduceSectorLagrangian recursion on physical basis element.

(* Test 6.2 — Zero input reduces to zero *)
*)

(* Test 6.2: Zero input reduces to zero *)
Block[{red},
  red = ReduceSectorLagrangian[0, 3, 2, Sequence @@ $testOpts];
  assert["6.2 Zero input reduces to zero",
    red["ReducedExpression"] === 0
  ]
];

(* Test 6.3 — IBP-trivial expression reduces to zero *)
Block[{sec, relExprs, relExpr, red},
  sec = ComputeSectorData[3, 2, Sequence @@ $testOpts];
  relExprs = sec["IBPRelationExpressions"];
  If[relExprs === {},
    skip["6.3 IBP-trivial reduces to zero {3,2}", "no IBP relations"],
    relExpr = First[relExprs];
    red = ReduceSectorLagrangian[relExpr, 3, 2, Sequence @@ $testOpts];
    assert["6.3 IBP-trivial expression {3,2} reduces to zero",
      red["ReducedExpression"] === 0
    ]
  ]
];

(* Test 6.4 — Mixed expression decomposes correctly (worked example from paper) *)
Block[{sec, phys, ibpRels, redefShifts, c1 = 2, c2 = -3, c3 = 4, c4 = 5,
       physPart, ibpPart, redefPart, inputLag, red},
  sec = ComputeSectorData[3, 2, Sequence @@ $testOpts];
  phys = sec["PhysicalBasis"];
  ibpRels = sec["IBPRelationExpressions"];
  redefShifts = sec["RedefShiftImages"];
  If[Length[phys] < 2 || ibpRels === {} || redefShifts === {},
    skip["6.4 Mixed expression decomposition", "insufficient basis data"],
    physPart = canonExpr[c1 * phys[[1]] + c2 * phys[[2]]];
    ibpPart = canonExpr[c3 * First[ibpRels]];
    redefPart = canonExpr[c4 * First[redefShifts]];
    inputLag = canonExpr[physPart + ibpPart + redefPart];
    red = ReduceSectorLagrangian[inputLag, 3, 2, Sequence @@ $testOpts];
    assert["6.4 Mixed expression: reduced == physical part only",
      canonExpr[red["ReducedExpression"] - physPart] === 0
    ]
  ]
];

(* Test 6.5 — ReduceLagrangian multi-sector split *)
Block[{sec10, sec22, sec32, expr10, expr22, expr32, totalLag, red, keys},
  sec10 = ComputeSectorData[1, 0, Sequence @@ $testOpts];
  sec22 = ComputeSectorData[2, 2, Sequence @@ $testOpts];
  sec32 = ComputeSectorData[3, 2, Sequence @@ $testOpts];
  If[sec10["PhysicalBasis"] === {} || sec22["PhysicalBasis"] === {} || sec32["PhysicalBasis"] === {},
    skip["6.5 Multi-sector split", "empty physical basis in some sector"],
    expr10 = First[sec10["PhysicalBasis"]];
    expr22 = First[sec22["PhysicalBasis"]];
    expr32 = First[sec32["PhysicalBasis"]];
    totalLag = canonExpr[3 expr10 + 5 expr22 + 7 expr32];
    red = ReduceLagrangian[totalLag, Sequence @@ $testOpts];
    keys = Sort[Keys[red["SectorReductions"]]];
    assert["6.5a Multi-sector split has expected keys",
      MemberQ[keys, {1, 0}] && MemberQ[keys, {2, 2}] && MemberQ[keys, {3, 2}]
    ];
    assert["6.5b Multi-sector reduced expression reconstructs input",
      canonExpr[red["ReducedExpression"] - totalLag] === 0
    ]
  ]
];

(* Test 6.6 — Idempotency *)
Block[{sec, phys, inputLag, red1, red2},
  sec = ComputeSectorData[3, 2, Sequence @@ $testOpts];
  phys = sec["PhysicalBasis"];
  If[Length[phys] < 2,
    skip["6.6 Idempotency", "insufficient physical basis"],
    inputLag = canonExpr[7 phys[[1]] - 3 phys[[2]]];
    red1 = ReduceLagrangian[inputLag, Sequence @@ $testOpts]["ReducedExpression"];
    red2 = ReduceLagrangian[red1, Sequence @@ $testOpts]["ReducedExpression"];
    assert["6.6 Idempotency: Reduce(Reduce(L)) == Reduce(L)",
      canonExpr[red2 - red1] === 0
    ]
  ]
];

(* Test 6.7 — Projection residual is zero for valid sector expr *)
Block[{sec, phys, lag, red},
  sec = ComputeSectorData[3, 2, Sequence @@ $testOpts];
  phys = sec["PhysicalBasis"];
  If[phys === {},
    skip["6.7 Projection residual", "empty physical basis"],
    lag = First[phys];
    red = ReduceSectorLagrangian[lag, 3, 2, Sequence @@ $testOpts];
    assert["6.7 Projection residual is zero for valid sector expression",
      TrueQ[red["ProjectionResidual"] === 0]
    ]
  ]
];

(* ================================================================ *)
(*  Stage 7: Matchete-xAct Translator                                *)
(* ================================================================ *)

testLog["\n=== Stage 7: Matchete-xAct Translator ==="];

(* Test 7.1 — sanitizeIndices *)
Block[{result1, result2},
  result1 = MatcheteXActTranslator`Private`sanitizeIndices[{a, a}];
  result2 = MatcheteXActTranslator`Private`sanitizeIndices[{a, b}];
  assert["7.1a sanitizeIndices[{a,a}] -> {a,-a}",
    result1 === {a, -a}
  ];
  assert["7.1b sanitizeIndices[{a,b}] unchanged",
    result2 === {a, b}
  ]
];

(* Test 7.2 — stripMinus *)
Block[{s1, s2},
  s1 = MatcheteXActTranslator`Private`stripMinus[-a];
  s2 = MatcheteXActTranslator`Private`stripMinus[a];
  assert["7.2a stripMinus[-a] = a", s1 === a];
  assert["7.2b stripMinus[a] = a", s2 === a];
];

(* Tests 7.3-7.5: Matchete MX file-dependent tests *)
Block[{mxFile, baselineFile},
  mxFile = FileNameJoin[{Directory[], "examples", "left_only_uv_2_eft_6", "LEFT_only_uv_2_eft_6.mx"}];
  baselineFile = FileNameJoin[{Directory[], "artifacts", "left_only_uv_2_eft_6", "LEFT_only_uv_2_eft_6_xact.wl"}];

  If[! FileExistsQ[mxFile],
    skip["7.3 LoadMatcheteMXExpression", "MX file not found"];
    skip["7.4 NormalizeMatcheteFinitePart", "MX file not found"];
    skip["7.5 Translation matches baseline", "MX file not found"],
    (* else: MX file exists *)
    Block[{translated, normalized},
      (* hbar warnings are now suppressed at the source in LoadMatcheteToXAct *)
      translated = LoadMatcheteToXAct[mxFile];
      assert["7.3 LoadMatcheteMXExpression succeeds",
        translated =!= $Failed && translated =!= 0
      ];

      If[translated =!= $Failed,
        normalized = NormalizeMatcheteFinitePart[translated];
        assert["7.4a Normalized has no hbar",
          FreeQ[normalized, hbar, Infinity]
        ];
        assert["7.4b Normalized has no negative epsilon powers",
          FreeQ[normalized,
            HoldPattern[Power[\[Epsilon], n_ /; NumericQ[n] && n < 0]],
            Infinity
          ]
        ];
        assert["7.4c Normalized is nonzero",
          normalized =!= 0
        ],
        skip["7.4 NormalizeMatcheteFinitePart", "translation failed"]
      ];

      If[FileExistsQ[baselineFile] && translated =!= $Failed,
        Block[{baseline, diff},
          baseline = Get[baselineFile];
          diff = Quiet[canonExpr[translated - baseline], ToCanonical::noident];
          assert["7.5 Translation matches stored baseline",
            diff === 0
          ]
        ],
        skip["7.5 Translation matches baseline",
          If[! FileExistsQ[baselineFile], "baseline file not found", "translation failed"]
        ]
      ]
    ]
  ]
];

(* ================================================================ *)
(*  Stage 8: EH Comparison Workflow                                  *)
(* ================================================================ *)

testLog["\n=== Stage 8: EH Comparison Workflow ==="];

(* Test 8.1 — ExpandFixedEHReferenceLagrangian basic properties *)
Block[{ref},
  ref = ExpandFixedEHReferenceLagrangian[
    "MaxDimension" -> 4,
    "LambdaReferenceValue" -> 1,
    "KappaReferenceValue" -> 1,
    "CacheDirectory" -> $testCacheDir,
    "UseCache" -> True,
    "Verbose" -> False
  ];
  assert["8.1a Reference expression is nonzero",
    ref["ReferenceExpression"] =!= 0
  ];
  Block[{sectors = Sort @ Keys @ SplitTermsBySector[ref["ReferenceExpression"]]},
    assert["8.1b Reference contains {1,0} sector",
      MemberQ[sectors, {1, 0}]
    ];
    assert["8.1c Reference contains {2,0} sector",
      MemberQ[sectors, {2, 0}]
    ];
    assert["8.1d Reference contains {2,2} sector",
      MemberQ[sectors, {2, 2}]
    ]
  ]
];

(* Test 8.2 — Reference self-comparison (synthetic test) *)
Block[{ref, synthetic},
  ref = ExpandFixedEHReferenceLagrangian[
    "MaxDimension" -> 5,
    "LambdaReferenceValue" -> 1,
    "KappaReferenceValue" -> 1,
    "CacheDirectory" -> $testCacheDir,
    "UseCache" -> True,
    "Verbose" -> False
  ];
  synthetic = CompareMatcheteToFixedEH[
    ref["ReferenceExpression"],
    "MaxDimension" -> 5,
    "LambdaReferenceValue" -> 1,
    "KappaReferenceValue" -> 1,
    "CacheDirectory" -> $testCacheDir,
    "UseCache" -> True,
    "Verbose" -> False
  ];
  assert["8.2 Reference self-comparison: ExactMatchQ",
    TrueQ[synthetic["ExactMatchQ"]]
  ]
];

(* Test 8.3 — Curvature-squared projections are linearly independent *)
(* Test 8.3: Curvature-squared projections are linearly independent *)
Block[{sec24, curvData, r2c, ricci2c, rank},
  sec24 = ComputeSectorData[2, 4, Sequence @@ Join[$testOpts, {"MaxDimension" -> 6}]];
  curvData = curvatureSquaredProjectionData[sec24];
  r2c = curvData["R2"]["Coordinates"];
  ricci2c = curvData["Ricci2"]["Coordinates"];
  rank = If[MatrixQ[{r2c, ricci2c}], MatrixRank[{r2c, ricci2c}], 0];
  assert["8.3 R^2 and R_{μν}R^{μν} are linearly independent in {2,4} IBP basis",
    rank == 2
  ]
];

(* Test 8.4 — Canonical normalization factor extraction *)
Block[{alpha = 7/3, scaledFP, red, kinData, basisOpts},
  basisOpts = Join[$testOpts, {"MaxDimension" -> 5}];
  scaledFP = canonExpr[alpha * LFP];
  red = ReduceLagrangian[scaledFP, Sequence @@ basisOpts];
  kinData = kineticNormalizationDataFromReduction[red, basisOpts];
  assert["8.4a Canonical normalization succeeds",
    TrueQ[kinData["SucceededQ"]]
  ];
  assert["8.4b Extracted factor equals scaling",
    TrueQ[Simplify[kinData["Factor"] == alpha]]
  ]
];

(* Test 8.5 — AnalyzeQuadraticFourDerivativeDifference on curvature input *)
Block[{sec24, curvData, r2Expr, ricci2Expr, c1 = 5, c2 = -3,
       testExpr, fakeResult, analysis},
  sec24 = ComputeSectorData[2, 4, Sequence @@ Join[$testOpts, {"MaxDimension" -> 6}]];
  curvData = curvatureSquaredProjectionData[sec24];
  r2Expr = curvData["R2"]["ProjectedExpr"];
  ricci2Expr = curvData["Ricci2"]["ProjectedExpr"];
  testExpr = canonExpr[c1 * r2Expr + c2 * ricci2Expr];

  (* Build a minimal fake result Association that AnalyzeQuadraticFourDerivativeDifference expects *)
  fakeResult = <|
    "SectorComparison" -> <|
      {2, 4} -> <|
        "DifferenceExpression" -> testExpr,
        "SectorData" -> sec24
      |>
    |>,
    "SupportedSectors" -> {{2, 2}},
    "UnsupportedDifference" -> <||>
  |>;

  analysis = AnalyzeQuadraticFourDerivativeDifference[
    fakeResult,
    "MaxDimension" -> 6,
    "CacheDirectory" -> $testCacheDir,
    "UseCache" -> True,
    "Verbose" -> False,
    "Substitutions" -> {},
    "UseQuadraticRedefinitions" -> False
  ];
  assert["8.5a Curvature-squared analysis: residual is zero",
    TrueQ[analysis["ResidualIsZeroQ"]]
  ];
  Block[{curvCoeffs, extractedR2, extractedRicci2},
    curvCoeffs = analysis["CurvatureCoefficients"];
    If[AssociationQ[curvCoeffs],
      extractedR2 = Lookup[curvCoeffs, "R2", Missing["NotFound"]];
      extractedRicci2 = Lookup[curvCoeffs, "Ricci2", Missing["NotFound"]];
      assert["8.5b Extracted R^2 coefficient matches input",
        TrueQ[Simplify[extractedR2 == c1]]
      ];
      assert["8.5c Extracted Ricci^2 coefficient matches input",
        TrueQ[Simplify[extractedRicci2 == c2]]
      ],
      assert["8.5b Curvature coefficients extraction", False]
    ]
  ]
];

(* ================================================================ *)
(*  Stage 9: Solution-Case Proof Validation                         *)
(* ================================================================ *)

testLog["\n=== Stage 9: Solution-Case Proof Validation ==="];

Block[{
  kernel13Path,
  validationScript,
  validationOutput,
  validationLogDir,
  validationLogFile,
  validationCommand,
  validationExitCode,
  artifact,
  curvatureCoeffs
},
  kernel13Path = "C:\\Program Files\\Wolfram Research\\Mathematica\\13.3\\math.exe";
  validationScript = FileNameJoin[{repoRoot, "tests", "validate_orbit_fixed_eh_solution_cases.wls"}];
  validationOutput = FileNameJoin[{repoRoot, "artifacts", "orbit_fixed_eh", "orbit_fixed_eh_solution_case_validation_output.wl"}];
  validationLogDir = FileNameJoin[{repoRoot, "tests", "artifacts", "run_logs"}];
  validationLogFile = FileNameJoin[{validationLogDir, "validate_orbit_fixed_eh_solution_cases_from_comprehensive_13_3.log"}];

  assert["9.1a Mathematica 13.3 kernel is available for solution-case proof validation",
    FileExistsQ[kernel13Path]
  ];

  If[FileExistsQ[kernel13Path],
    (
      If[! DirectoryQ[validationLogDir],
        CreateDirectory[validationLogDir, CreateIntermediateDirectories -> True]
      ];
      If[FileExistsQ[validationOutput], DeleteFile[validationOutput]];
      If[FileExistsQ[validationLogFile], DeleteFile[validationLogFile]];
      validationCommand =
        "powershell -NoProfile -Command " <>
        "\"& '" <> kernel13Path <> "' -script '" <> validationScript <>
        "' *> '" <> validationLogFile <> "'\"";
      testLog["  INFO: launching solution-case validator in a fresh Mathematica 13.3 kernel"];
      validationExitCode = TimeConstrained[
        Run[validationCommand],
        7200,
        -1
      ];

      assert["9.1b Solution-case validator exits successfully under 13.3",
        IntegerQ[validationExitCode] && validationExitCode == 0
      ];
      assert["9.1c Solution-case validator writes its output artifact",
        FileExistsQ[validationOutput]
      ];

      If[FileExistsQ[validationOutput],
        artifact = Get[validationOutput];
        assert["9.1d Solution-case artifact is an Association",
          AssociationQ[artifact]
        ];
        If[AssociationQ[artifact],
          assert["9.1e Solution-case validator reports Mathematica 13.3",
            StringStartsQ[Lookup[artifact, "KernelVersion", ""], "13.3"]
          ];
          assert["9.1f Solution-case validator reports all checks passed",
            TrueQ[Lookup[artifact, "AllChecksPassedQ", False]]
          ];
          assert["9.1g D5 proof case has a symbolic solution",
            TrueQ[Lookup[artifact["D5"], "HasSymbolicSolutionQ", False]]
          ];
          assert["9.1h D5 proof case has vanishing supported differences",
            TrueQ[Lookup[artifact["D5"], "AllSupportedDifferencesVanishQ", False]]
          ];
          assert["9.1i D6 proof case satisfies all witness equations",
            TrueQ[Lookup[artifact["D6"], "MatchEquationsSatisfiedQ", False]]
          ];
          assert["9.1j D6 proof case preserves stored supported-sector verification",
            TrueQ[Lookup[artifact["D6"], "StoredSupportedVerificationQ", False]]
          ];
          assert["9.1k D6 quadratic completion leaves zero residual",
            TrueQ[Lookup[artifact["D6", "QuadraticCompletion"], "ResidualIsZeroQ", False]]
          ];
          curvatureCoeffs = Lookup[artifact["D6", "QuadraticCompletion"], "CurvatureCoefficients", <||>];
          assert["9.1l D6 quadratic completion removes curvature-squared content",
            AssociationQ[curvatureCoeffs] &&
              Lookup[curvatureCoeffs, "R2", 1] === 0 &&
              Lookup[curvatureCoeffs, "Ricci2", 1] === 0
          ];
          assert["9.1m D6 quadratic image reconstruction matches the projected difference",
            TrueQ[Lookup[artifact["D6", "QuadraticCompletion"], "ImageCoordinateReconstructionMatchesQ", False]]
          ]
        ]
      ]
    )
  ]
];

(* ================================================================ *)
(*  Cleanup and summary                                              *)
(* ================================================================ *)

Print["\n=== Cleanup ==="];

If[DirectoryQ[$testCacheDir],
  Print["Removing test cache: " <> $testCacheDir];
  DeleteDirectory[$testCacheDir, DeleteContents -> True]
];

(* --- Build summary lines --- *)
summaryLines = {
  "",
  "========================================",
  "=== RESULTS ===",
  "========================================",
  ToString[$passCount] <> " passed, " <>
    ToString[$failCount] <> " failed, " <>
    ToString[$skipCount] <> " skipped out of " <>
    ToString[$testCount]
};

If[$failCount > 0,
  AppendTo[summaryLines, ""];
  AppendTo[summaryLines, "FAILURES:"];
  Do[AppendTo[summaryLines, "  - " <> f], {f, $failures}];
  AppendTo[summaryLines, ""];
  AppendTo[summaryLines, "Test suite FAILED."],
  AppendTo[summaryLines, ""];
  AppendTo[summaryLines, "All tests passed."]
];

(* Print summary to console *)
Print /@ summaryLines;

(* --- Export full log to file --- *)
$testLog = Join[$testLog, summaryLines];
Block[{logFile, logContent},
  logFile = FileNameJoin[{repoRoot, "tests", "orbit_test_results.txt"}];
  logContent = StringJoin[
    "ORBIT Comprehensive Test Results\n",
    "Generated: " <> DateString[{"ISODate", " ", "Time"}] <> "\n",
    "================================================\n\n",
    StringRiffle[$testLog, "\n"],
    "\n"
  ];
  Export[logFile, logContent, "Text"];
  Print["\nResults exported to: " <> logFile]
];

If[$failCount > 0, Exit[1]];
