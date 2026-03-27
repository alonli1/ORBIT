scriptDir = DirectoryName[$InputFileName];
repoRoot = NestWhile[
  DirectoryName,
  scriptDir,
  ! FileExistsQ[FileNameJoin[{#, "graviton_basis_toolkit.wl"}]] &
];
SetDirectory[repoRoot];

Get["graviton_basis_toolkit.wl"];
Get["orbit_fixed_eh_comparison.wl"];

outputDir = FileNameJoin[{Directory[], "artifacts", "orbit_fixed_eh"}];
If[! DirectoryQ[outputDir], CreateDirectory[outputDir, CreateIntermediateDirectories -> True]];

resultFile = FileNameJoin[{outputDir, "orbit_fixed_eh_comparison_final_result.wl"}];
analysisFile = FileNameJoin[{outputDir, "orbit_fixed_eh_quadratic_completion_crosscheck.wl"}];
summaryFile = FileNameJoin[{outputDir, "orbit_fixed_eh_quadratic_completion_crosscheck_summary.wl"}];
cacheDir = FileNameJoin[{Directory[], "cache", "left_only_uv_2_eft_6_cache"}];
subs = {
  Log[\[Mu]bar2/M^2] -> -3/2,
  Log[Scalar[\[Mu]bar2]/M^2] -> -3/2,
  Log[Scalar[\[Mu]bar2]/Scalar[M]^2] -> -3/2
};

linRicciExprCheck[x_, y_] := Module[{c1, c2},
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

linRicciScalarExprCheck[] := Module[{a1, b1, a2, b2},
  a1 = DummyIn[TangentM];
  b1 = DummyIn[TangentM];
  a2 = DummyIn[TangentM];
  b2 = DummyIn[TangentM];
  canonExpr[
    PD[-a1][PD[-b1][h[a1, b1]]] - PD[-a2][PD[a2][h[b2, -b2]]]
  ]
];

completeRules[vars_List, rules_List] := Join[rules, Thread[Complement[vars, First /@ rules] -> 0]];

If[! FileExistsQ[resultFile],
  Print["Missing comparison result file: " <> resultFile];
  Quit[1];
];

result = Get[resultFile];
sec = ComputeSectorData[
  2,
  4,
  "MaxDimension" -> 6,
  "CacheDirectory" -> cacheDir,
  "UseCache" -> True,
  "Verbose" -> False
];

targetExpr = canonExpr[result["SectorComparison"][{2, 4}]["DifferenceExpression"] /. subs];
targetProj = ProjectToIBPUsingSectorData[targetExpr, sec];
targetCoords = targetProj["Coordinates"];

deltaBasis = Rank2Basis[
  1,
  2,
  "MaxDimension" -> 6,
  "CacheDirectory" -> cacheDir,
  "UseCache" -> True,
  "Verbose" -> False
];
shiftImages = ShiftFromRedefExpr /@ deltaBasis;
shiftProj = ProjectToIBPUsingSectorData[#, sec] & /@ shiftImages;
shiftVecs = shiftProj[[All, "Coordinates"]];
indRows = IndependentImageRows[shiftVecs];
indVecs = shiftVecs[[indRows]];

pureVars = Array[p, Length[indVecs]];
pureEqns = Thread[Transpose[indVecs].pureVars == targetCoords];
pureSolve = Quiet[Solve[pureEqns, pureVars], Solve::svars];
pureRules = If[ListQ[pureSolve] && pureSolve =!= {}, completeRules[pureVars, First[pureSolve]], {}];
pureReconstructed = If[
  pureRules === {},
  ConstantArray[0, Length[targetCoords]],
  Simplify[FixedPoint[# /. pureRules &, Transpose[indVecs].pureVars, 2]]
];

r2Proj = ProjectModuloIBP[
  canonExpr[linRicciScalarExprCheck[] linRicciScalarExprCheck[]],
  sec["IBPBasis"]
];

ricci2Expr = Module[{a1, b1, c1, d1},
  a1 = DummyIn[TangentM];
  b1 = DummyIn[TangentM];
  c1 = DummyIn[TangentM];
  d1 = DummyIn[TangentM];
  canonExpr[
    eta[a1, c1] eta[b1, d1] linRicciExprCheck[-a1, -b1] linRicciExprCheck[-c1, -d1]
  ]
];
ricci2Proj = ProjectModuloIBP[ricci2Expr, sec["IBPBasis"]];

jointVecs = Join[{r2Proj["Coordinates"], ricci2Proj["Coordinates"]}, indVecs];
jointVars = Join[{cR2, cRicci2}, Array[q, Length[indVecs]]];
jointEqns = Thread[Transpose[jointVecs].jointVars == targetCoords];
jointSolve = Quiet[Solve[jointEqns, jointVars], Solve::svars];
jointRules = If[ListQ[jointSolve] && jointSolve =!= {}, completeRules[jointVars, First[jointSolve]], {}];
jointReconstructed = If[
  jointRules === {},
  ConstantArray[0, Length[targetCoords]],
  Simplify[FixedPoint[# /. jointRules &, Transpose[jointVecs].jointVars, 2]]
];

analysis = <|
  "TargetCoordinates" -> targetCoords,
  "IndependentRedefinitionRows" -> indRows,
  "IndependentRedefinitionVectors" -> indVecs,
  "PureRedefinitionSolve" -> pureSolve,
  "PureRedefinitionRules" -> pureRules,
  "PureRedefinitionReconstructed" -> pureReconstructed,
  "CurvatureBasisVectors" -> <|
    "R2" -> r2Proj["Coordinates"],
    "Ricci2" -> ricci2Proj["Coordinates"]
  |>,
  "JointSolve" -> jointSolve,
  "JointRules" -> jointRules,
  "JointReconstructed" -> jointReconstructed
|>;

summary = <|
  "PureRedefinitionHasSolutionQ" -> TrueQ[ListQ[pureSolve] && pureSolve =!= {}],
  "PureRedefinitionReconstructionMatchesQ" -> And @@ (TrueQ[Simplify[#]] & /@ Thread[pureReconstructed == targetCoords]),
  "JointSolveHasSolutionQ" -> TrueQ[ListQ[jointSolve] && jointSolve =!= {}],
  "JointReconstructionMatchesQ" -> And @@ (TrueQ[Simplify[#]] & /@ Thread[jointReconstructed == targetCoords]),
  "JointCurvatureCoefficients" -> <|
    "R2" -> Lookup[Association[jointRules], cR2, Missing["NotAvailable"]],
    "Ricci2" -> Lookup[Association[jointRules], cRicci2, Missing["NotAvailable"]]
  |>
|>;

Put[analysis, analysisFile];
Put[summary, summaryFile];

Print["Quadratic completion cross-check written to: " <> analysisFile];
Print["Quadratic completion cross-check summary written to: " <> summaryFile];
Print[InputForm[summary]];
