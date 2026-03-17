(* ::Package:: *)

(* ================================================================ *)
(*  Graviton operator basis toolkit                                 *)
(*  - raw scalar basis                                              *)
(*  - quotient by IBP                                               *)
(*  - quotient by Fierz-Pauli field redefinitions                   *)
(*  - sector-level caching                                          *)
(*  - optional restriction to selected sectors                      *)
(*  - summary export                                                *)
(*  - extraction of redefinitions spanning the quotient image       *)
(* ================================================================ *)

Quiet[Needs["xAct`xTras`"], PacletDataRebuild::lock];

(* xAct's Invar package flips this off during load, but the toolkit works on a
   flat-space scalar-density basis where partial derivatives on scalars should
   commute. Restoring it is necessary for the Euler-operator IBP test to
   recognize expanded total derivatives. *)
$CommuteCovDsOnScalars = True;

(* ================================================================ *)
(* 0. Public entry points / options                                 *)
(* ================================================================ *)

ClearAll[
  RunBasisComputation, ComputeSectorData, LoadOrCompute,
  ReduceSectorLagrangian, ReduceLagrangian,
  SetCacheDirectory, ClearCacheDirectory,
  ExportSummaryCSV, ExportSummaryMX,
  RawBasisOfSector, IBPBasisOfSector, PhysicalBasisOfSector,
  RedefinitionsOfSector, RedefinitionRulesOfSector,
  PrintSectorSummary, SectorSummaryTable
];

Options[RunBasisComputation] = {
  "MaxDimension" -> 5,
  "SectorList" -> Automatic,
  "CacheDirectory" -> Automatic,
  "UseCache" -> True,
  "ForceRecompute" -> False,
  "ParallelizeSectors" -> False,
  "KernelCount" -> Automatic,
  "Verbose" -> True,
  "ExportSummaryCSV" -> False,
  "SummaryCSVFile" -> Automatic,
  "ExportResultMX" -> False,
  "ResultMXFile" -> Automatic
};

Options[ReduceSectorLagrangian] = Options[RunBasisComputation];
Options[ReduceLagrangian] = Options[RunBasisComputation];

$GravitonBasisCacheDirectory = Automatic;
$GravitonBasisToolkitFile = If[
  StringQ[$InputFileName] && $InputFileName =!= "",
  $InputFileName,
  FileNameJoin[{Directory[], "graviton_basis_toolkit.wl"}]
];

SetCacheDirectory[dir_String] := ($GravitonBasisCacheDirectory = dir);
ClearCacheDirectory[] := ($GravitonBasisCacheDirectory = Automatic);

(* ================================================================ *)
(* 1. xAct setup                                                    *)
(* ================================================================ *)

Quiet @ Check[
  DefManifold[M, 4, IndexRange[{a, g}, {i, z}]],
  Null
];

Quiet @ Check[
  DefMetric[{1, 3, 0}, eta[-a, -b], PD, FlatMetric -> True,
    SymbolOfCovD -> {";", "\[PartialD]"}],
  Null
];

Quiet @ Check[
  DefTensor[h[-a, -b], M, Symmetric[{-a, -b}], PrintAs -> "h"],
  Null
];

Quiet @ Check[
  DefTensor[dh[-a, -b], M, Symmetric[{-a, -b}], PrintAs -> "\[Delta]h"],
  Null
];

Quiet @ Check[
  DefTensor[probe[-a, -b], M, Symmetric[{-a, -b}], PrintAs -> "P"],
  Null
];

(* constant substitution parameter for field redefinitions *)
Quiet @ Check[
  DefConstantSymbol[lam],
  Null
];

(* ================================================================ *)
(* 2. Utilities                                                     *)
(* ================================================================ *)

ClearAll[
  canonExpr, canonList, PivotColumns, PivotRows, LinearCombination,
  CompositionList, CacheDirectoryResolved, CacheFile,
  SaveExpr, LoadExpr, PrettyKey, LogPrint,
  SectorKeyAssociation, NormalizeSectorList,
  SafeSolveConstants, ZeroVectorQ, CoordinatesMatrixQ,
  DefaultCacheDirectory, TermSectorKey, DerivativeFreeExprQ,
  StripScalarParameterWrappers, DirectProjectToBasis,
  ReduceCoordinatesModuloRelations, ProjectToIBPUsingSectorData,
  SplitTermsBySector, ReduceCoordinatesModuloRedef,
  ParallelKernelCountResolved, EnsureParallelToolkitKernels,
  ReduceSectorLagrangianCanonicalInput
];

canonExpr[expr_] := Module[{tmp},
  tmp = ToCanonical @ ContractMetric @ Expand[expr];
  tmp = SortCovDs[tmp, PD];
  CollectTensors @ ToCanonical @ ContractMetric @ tmp
];
canonList[list_List] := DeleteDuplicates @ (canonExpr /@ list);

PivotColumns[m_?MatrixQ] := Module[{rr},
  rr = RowReduce[m];
  Cases[
    (FirstPosition[#, _?(# =!= 0 &), Nothing, {1}, Heads -> False] & /@ rr),
    {j_} :> j
  ]
];

PivotRows[m_?MatrixQ] := PivotColumns[Transpose[m]];

LinearCombination[vec_List, basis_List] /; Length[vec] == Length[basis] :=
  Total @ MapThread[Times, {vec, basis}];

CompositionList[n_Integer, k_Integer] /; n >= 0 && k >= 1 :=
  Select[Tuples[Range[0, n], k], Total[#] == n &];

DefaultCacheDirectory[] := Module[{nbdir},
  nbdir = Quiet @ Check[NotebookDirectory[], $Failed];
  If[StringQ[nbdir], nbdir, Directory[]]
];

SectorKeyAssociation[nh_Integer, Nd_Integer] := <|"nh" -> nh, "Nd" -> Nd, "D" -> nh + Nd|>;

NormalizeSectorList[Automatic, dmax_Integer] :=
  Flatten[Table[{nh, d - nh}, {d, 1, dmax}, {nh, 1, d}], 1];
NormalizeSectorList[list_List, _Integer] := DeleteDuplicates @ Select[list, MatchQ[#, {_Integer, _Integer}] &];

CacheDirectoryResolved[opts : OptionsPattern[RunBasisComputation]] := Module[{dir},
  dir = OptionValue["CacheDirectory"];
  Which[
    dir === Automatic && $GravitonBasisCacheDirectory =!= Automatic, $GravitonBasisCacheDirectory,
    dir === Automatic,
      FileNameJoin[{DefaultCacheDirectory[], "graviton_basis_cache"}],
    True, dir
  ]
];

PrettyKey[assoc_Association] := StringRiffle[
  KeyValueMap[ToString[#1] <> "_" <> ToString[#2] &, assoc],
  "__"
];

CacheFile[type_String, key_Association, opts : OptionsPattern[RunBasisComputation]] := Module[{dir},
  dir = CacheDirectoryResolved[opts];
  If[! DirectoryQ[dir], CreateDirectory[dir, CreateIntermediateDirectories -> True]];
  FileNameJoin[{dir, type <> "__" <> PrettyKey[key] <> ".m"}]
];

SaveExpr[file_String, expr_] := Put[expr, file];
LoadExpr[file_String] := Get[file];

LogPrint[msg_, opts : OptionsPattern[RunBasisComputation]] :=
  If[TrueQ[OptionValue["Verbose"]], Print[msg]];

ParallelKernelCountResolved[taskCount_Integer, opts : OptionsPattern[RunBasisComputation]] := Module[
  {requested},
  requested = OptionValue["KernelCount"];
  Which[
    taskCount <= 1, 1,
    IntegerQ[requested] && requested >= 1, Min[requested, taskCount],
    True, Max[1, Min[taskCount, $ProcessorCount - 1]]
  ]
];

EnsureParallelToolkitKernels[taskCount_Integer, opts : OptionsPattern[RunBasisComputation]] := Module[
  {targetCount, workDir, toolkitFile},
  targetCount = ParallelKernelCountResolved[taskCount, opts];
  If[targetCount <= 1, Return[{}]];
  workDir = Directory[];
  toolkitFile = $GravitonBasisToolkitFile;
  If[Length[Kernels[]] < targetCount,
    LaunchKernels[targetCount - Length[Kernels[]]]
  ];
  ParallelEvaluate[
    SetDirectory[workDir];
    If[! ValueQ[RunBasisComputation], Get[toolkitFile]];
    Null
  ];
  Kernels[]
];

LoadOrCompute[type_String, key_Association, compute_, opts : OptionsPattern[RunBasisComputation]] := Module[
  {file, useCache, force, result},
  file = CacheFile[type, key, opts];
  useCache = TrueQ[OptionValue["UseCache"]];
  force = TrueQ[OptionValue["ForceRecompute"]];

  If[useCache && FileExistsQ[file] && ! force,
    LogPrint["[cache] loading " <> type <> " : " <> PrettyKey[key], opts];
    Return[LoadExpr[file]];
  ];

  LogPrint["[compute] " <> type <> " : " <> PrettyKey[key], opts];
  result = compute[];

  If[useCache, SaveExpr[file, result]];
  result
];

SafeSolveConstants[eq_, vars_: Automatic] := Module[{sol},
  sol = Quiet[
    If[vars === Automatic, SolveConstants[eq], SolveConstants[eq, vars]],
    Solve::svars
  ];
  Which[
    sol === {}, {{}},
    ListQ[sol], sol,
    True, {{}}
  ]
];

ZeroVectorQ[v_List] := And @@ (TrueQ[# === 0] & /@ v);
CoordinatesMatrixQ[x_] := MatrixQ[x] || x === {};
DerivativeFreeExprQ[expr_] := FreeQ[expr, HoldPattern[PD[_][__]], Infinity];
StripScalarParameterWrappers[expr_] := expr /. HoldPattern[Scalar[s_]] /;
   FreeQ[s, HoldPattern[h[__] | dh[__] | probe[__] | PD[_][__]], Infinity] :> s;

DirectProjectToBasis[expr_, basis_List] := Module[
  {ans, cleanExpr, eq, sol, zvars, coeffs, hasSolutionQ, projectedExpr, residual},
  If[basis === {},
    Return[<|
      "ProjectedExpr" -> 0,
      "Coordinates" -> {},
      "Solution" -> {{}},
      "HasSolution" -> TrueQ[canonExpr[expr] === 0],
      "Residual" -> canonExpr[expr]
    |>]
  ];

  ans = MakeAnsatz[basis, ConstantPrefix -> z];
  cleanExpr = StripScalarParameterWrappers[expr];
  zvars = Table[Symbol["z" <> ToString[i]], {i, Length[basis]}];
  eq = canonExpr[ans - cleanExpr];
  sol = Quiet[SolveConstants[eq == 0, zvars], Solve::svars];
  hasSolutionQ = ListQ[sol] && sol =!= {};
  coeffs = If[hasSolutionQ,
    (zvars /. First[sol]) /. Thread[zvars -> 0],
    ConstantArray[0, Length[basis]]
  ];
  projectedExpr = canonExpr @ LinearCombination[coeffs, basis];
  residual = canonExpr[projectedExpr - cleanExpr];

  <|
    "ProjectedExpr" -> projectedExpr,
    "Coordinates" -> coeffs,
    "Solution" -> If[hasSolutionQ, sol, {}],
    "HasSolution" -> hasSolutionQ,
    "Residual" -> residual
  |>
];

ReduceCoordinatesModuloRelations[coords_List, relMat_, piv_List] := Module[{imageCoeffs, reducedCoords, quotientCoords},
  If[coords === {} || piv === {} || ! MatrixQ[relMat] || relMat === {},
    reducedCoords = coords;
    quotientCoords = coords;
    imageCoeffs = {};
    ,
    imageCoeffs = LinearSolve[Transpose[relMat[[All, piv]]], coords[[piv]]];
    reducedCoords = coords - imageCoeffs . relMat;
    quotientCoords = Delete[reducedCoords, List /@ Sort[piv]];
  ];

  <|
    "RelationCoefficients" -> imageCoeffs,
    "ReducedCoordinates" -> reducedCoords,
    "QuotientCoordinates" -> quotientCoords
  |>
];

ProjectToIBPUsingSectorData[expr_, sec_Association] := Module[{rawProj, ibpReduction},
  rawProj = DirectProjectToBasis[expr, sec["RawBasis"]];
  ibpReduction = ReduceCoordinatesModuloRelations[
    rawProj["Coordinates"],
    sec["IBPRelationMatrix"],
    sec["IBPPivots"]
  ];

  <|
    "RawProjection" -> rawProj,
    "ProjectionSucceededQ" -> TrueQ[rawProj["HasSolution"]] && TrueQ[rawProj["Residual"] === 0],
    "ProjectionResidual" -> rawProj["Residual"],
    "ProjectedExpr" -> canonExpr @ LinearCombination[
      ibpReduction["QuotientCoordinates"],
      sec["IBPBasis"]
    ],
    "Coordinates" -> ibpReduction["QuotientCoordinates"],
    "ReducedRawCoordinates" -> ibpReduction["ReducedCoordinates"],
    "IBPRelationCoefficients" -> ibpReduction["RelationCoefficients"]
  |>
];

TermSectorKey[term_] := {
  Count[term, HoldPattern[h[_, _]], Infinity],
  Count[term, HoldPattern[PD[_][__]], Infinity]
};

SplitTermsBySector[expr_] := Module[{expanded, terms},
  expanded = Expand[expr];
  terms = Which[
    expanded === 0, {},
    Head[expanded] === Plus, List @@ expanded,
    True, {expanded}
  ];
  Merge[Rule @@@ ({TermSectorKey[#], #} & /@ terms), Total]
];

ReduceCoordinatesModuloRedef[coords_List, sec_Association] := Module[
  {piv, indVecs, imageCoeffs, reducedCoords, physCoords},
  piv = sec["RedefPivots"];
  indVecs = sec["RedefIndependentVectors"];

  If[piv === {} || indVecs === {} || ! MatrixQ[indVecs],
    reducedCoords = coords;
    physCoords = coords;
    imageCoeffs = {};
    ,
    imageCoeffs = LinearSolve[Transpose[indVecs[[All, piv]]], coords[[piv]]];
    reducedCoords = coords - imageCoeffs . indVecs;
    physCoords = Delete[reducedCoords, List /@ Sort[piv]];
  ];

  <|
    "ReducedIBPCoordinates" -> reducedCoords,
    "PhysicalCoordinates" -> physCoords,
    "RedefinitionImageCoefficients" -> imageCoeffs
  |>
];

(* ================================================================ *)
(* 3. Fierz–Pauli quadratic Lagrangian                              *)
(* ================================================================ *)

ClearAll[LFP];

LFP = canonExpr[
   -1/2 PD[a] @ h[b, c] PD[-a] @ h[-b, -c]
   +    PD[a] @ h[-a, b] PD[c] @ h[-c, -b]
   -    PD[a] @ h[-a, b] PD[-b] @ h[c, -c]
   + 1/2 PD[a] @ h[b, -b] PD[-a] @ h[c, -c]
];

(* ================================================================ *)
(* 4. Raw monomials and bases                                       *)
(* ================================================================ *)

ClearAll[
  MakeFieldWithKDerivs, ScalarMonomialFromPartition,
  ProbeMonomialFromPartition, RawScalarMonomials,
  RawProbeMonomials, RawScalarBasis, Rank2Basis
];

MakeFieldWithKDerivs[tensor_Symbol, k_Integer] := Module[{mu, nu, ders, expr},
  mu = DummyIn[TangentM];
  nu = DummyIn[TangentM];
  ders = Table[DummyIn[TangentM], {k}];
  expr = tensor[mu, nu];
  Do[expr = PD[-ders[[j]]] @ expr, {j, k}];
  expr
];

ScalarMonomialFromPartition[part_List] := Times @@ (MakeFieldWithKDerivs[h, #] & /@ part);
ProbeMonomialFromPartition[part_List] := Module[{A, B},
  A = DummyIn[TangentM];
  B = DummyIn[TangentM];
  probe[A, B] Times @@ (MakeFieldWithKDerivs[h, #] & /@ part)
];

RawScalarMonomials[nh_Integer, Nd_Integer] := ScalarMonomialFromPartition /@ CompositionList[Nd, nh];
RawProbeMonomials[nh_Integer, Nd_Integer] := ProbeMonomialFromPartition /@ CompositionList[Nd, nh];

RawScalarBasis[nh_Integer, Nd_Integer, opts : OptionsPattern[RunBasisComputation]] :=
  LoadOrCompute[
    "raw_scalar_basis",
    <|"nh" -> nh, "Nd" -> Nd|>,
    Function[Null,
      If[OddQ[Nd],
        {},
        canonList @ Flatten[AllContractions /@ RawScalarMonomials[nh, Nd]]
      ]
    ],
    opts
  ];

(* rank-2 basis used for field redefinitions delta h_{uv} *)
Rank2Basis[nhRedef_Integer, NdRedef_Integer, opts : OptionsPattern[RunBasisComputation]] :=
  LoadOrCompute[
    "rank2_basis",
    <|"nhRedef" -> nhRedef, "NdRedef" -> NdRedef|>,
    Function[Null,
      Module[{probeScalars, basisExprs},
        If[nhRedef < 1 || NdRedef < 0 || OddQ[NdRedef], Return[{}]];
        probeScalars = canonList @ Flatten[AllContractions /@ RawProbeMonomials[nhRedef, NdRedef]];
        basisExprs = canonList @ (canonExpr @ VarD[probe[-u, -v], PD][#] & /@ probeScalars);
        basisExprs
      ]
    ],
    opts
  ];

(* ================================================================ *)
(* 5. IBP quotient                                                  *)
(* ================================================================ *)

ClearAll[IBPData, QuotientBasisFromRelations];

IBPData[basis_List] := Module[
  {ans, EL, sol, allc, solvedc, freec, relMat, relExprs},

  If[basis === {},
    Return[<|
      "Solution" -> {{}},
      "FreeParameters" -> {},
      "RelationMatrix" -> {},
      "RelationExpressions" -> {}
    |>]
  ];

  ans = MakeAnsatz[basis, ConstantPrefix -> c];
  EL = canonExpr @ VarD[h[-m, -n], PD][ans];
  allc = Table[Symbol["c" <> ToString[i]], {i, Length[basis]}];
  sol = SafeSolveConstants[EL == 0, allc];
  solvedc = Cases[First[sol], Rule[lhs_Symbol, _] :> lhs];

  freec = DeleteDuplicates @ Join[
    Complement[allc, solvedc],
    Cases[
      Last /@ First[sol],
      s_Symbol /; MemberQ[allc, s],
      Infinity
    ]
  ];

  relMat = If[freec === {}, {},
    Table[
      allc /. First[sol] /. Thread[freec -> UnitVector[Length[freec], j]],
      {j, Length[freec]}
    ]
  ];

  relExprs = If[relMat === {}, {}, canonExpr /@ (LinearCombination[#, basis] & /@ relMat)];

  <|
    "Solution" -> sol,
    "FreeParameters" -> freec,
    "RelationMatrix" -> relMat,
    "RelationExpressions" -> relExprs
  |>
];

QuotientBasisFromRelations[basis_List, relMat_] := Module[{pivot},
  pivot = If[MatrixQ[relMat] && relMat =!= {}, PivotColumns[relMat], {}];
  <|
    "PivotColumns" -> pivot,
    "Basis" -> Delete[basis, List /@ Sort[pivot]]
  |>
];

(* ================================================================ *)
(* 6. Field-redefinition image                                      *)
(* ================================================================ *)

ClearAll[
  ShiftFromRedefExpr, ProjectModuloIBP,
  IndependentImageRows, BasisCoordinatesFromIndependentRows,
  RedefinitionImageData
];

(* IMPORTANT:
   Expand the FP Lagrangian with h -> h + lam dh, extract the coefficient of lam,
   and only then replace dh by a concrete rank-2 tensor deltaExpr[u,v].
   lam is a DefConstantSymbol, so PD[lam] = 0 automatically. *)
ShiftFromRedefExpr[deltaExpr_] := Module[{expr},
  expr = Expand[LFP /. HoldPattern[h[x_, y_]] :> (h[x, y] + lam dh[x, y])];
  expr = Coefficient[expr, lam, 1];
  expr = expr /. HoldPattern[dh[x_, y_]] :> (deltaExpr /. {u -> x, v -> y});
  canonExpr[expr]
];

ProjectModuloIBP[expr_, basis_List] := Module[{ans, cleanExpr, eq, sol, qvars, coeffs},
  If[basis === {},
    Return[<|"ProjectedExpr" -> 0, "Coordinates" -> {}, "Solution" -> {{}}|>]
  ];

  ans = MakeAnsatz[basis, ConstantPrefix -> q];
  cleanExpr = StripScalarParameterWrappers[expr];
  qvars = Table[Symbol["q" <> ToString[i]], {i, Length[basis]}];
  eq = If[
    DerivativeFreeExprQ[ans] && DerivativeFreeExprQ[cleanExpr],
    canonExpr[ans - cleanExpr],
    canonExpr @ VarD[h[-m, -n], PD][ans - cleanExpr]
  ];
  sol = SafeSolveConstants[eq == 0, qvars];
  coeffs = (qvars /. First[sol]) /. Thread[qvars -> 0];

  <|
    "ProjectedExpr" -> canonExpr[(ans /. First[sol]) /. Thread[qvars -> 0]],
    "Coordinates" -> coeffs,
    "Solution" -> sol
  |>
];

IndependentImageRows[vecs_] := Module[{rows},
  If[! MatrixQ[vecs] || vecs === {}, Return[{}]];
  rows = PivotRows[vecs];
  rows
];

BasisCoordinatesFromIndependentRows[indVecs_?MatrixQ] := Module[{piv},
  piv = PivotColumns[indVecs];
  <|"PivotColumns" -> piv|>
];
BasisCoordinatesFromIndependentRows[{}] := <|"PivotColumns" -> {}|>;

RedefinitionImageData[nh_Integer, Nd_Integer, ibpBasis_List, opts : OptionsPattern[RunBasisComputation]] :=
  LoadOrCompute[
    "redef_image_data",
    <|"nh" -> nh, "Nd" -> Nd|>,
    Function[Null,
      Module[{nhRedef, NdRedef, deltaBasis, shifts, proj, vecs, indRows, indVecs},

        (* Keep quadratic sectors in the IBP basis. Linear field redefinitions
           act on the kinetic operator itself, so the FP-image quotient is only
           applied to interaction sectors with nh >= 3. *)
        If[nh < 3,
          Return[<|
            "DeltaBasis" -> {},
            "ShiftImages" -> {},
            "ProjectedData" -> {},
            "ImageVectors" -> {},
            "IndependentRows" -> {},
            "IndependentVectors" -> {},
            "IndependentDeltas" -> {},
            "Rank" -> 0
          |>]
        ];

        nhRedef = nh - 1;
        NdRedef = Nd - 2;

        If[nhRedef < 1 || NdRedef < 0 || ibpBasis === {},
          Return[<|
            "DeltaBasis" -> {},
            "ShiftImages" -> {},
            "ProjectedData" -> {},
            "ImageVectors" -> {},
            "IndependentRows" -> {},
            "IndependentVectors" -> {},
            "IndependentDeltas" -> {},
            "Rank" -> 0
          |>]
        ];

        deltaBasis = Rank2Basis[nhRedef, NdRedef, opts];
        shifts = ShiftFromRedefExpr /@ deltaBasis;
        proj = ProjectModuloIBP[#, ibpBasis] & /@ shifts;
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
      ]
    ],
    opts
  ];

(* ================================================================ *)
(* 7. Extract explicit redefinitions selecting the quotient image   *)
(* ================================================================ *)

ClearAll[RedefinitionRulesFromVectors];

RedefinitionRulesFromVectors[ibpBasis_List, indDeltas_List, indVecs_] := Module[
  {rules},
  If[indDeltas === {} || indVecs === {} || ! MatrixQ[indVecs],
    Return[{}]
  ];

  rules = Table[
    <|
      "Delta" -> indDeltas[[i]],
      "ImageCoordinatesInIBPBasis" -> indVecs[[i]],
      "ImageExpressionInIBPBasis" -> canonExpr @ LinearCombination[indVecs[[i]], ibpBasis]
    |>,
    {i, Length[indDeltas]}
  ];

  rules
];

(* ================================================================ *)
(* 8. Full sector computation                                       *)
(* ================================================================ *)

ClearAll[ComputeSectorData];

ComputeSectorData[nh_Integer, Nd_Integer, opts : OptionsPattern[RunBasisComputation]] :=
  LoadOrCompute[
    "sector_data",
    SectorKeyAssociation[nh, Nd],
    Function[Null,
      Module[{rawBasis, ibp, qbasis, redef, piv, physBasis, redefRules},

        rawBasis = RawScalarBasis[nh, Nd, opts];
        ibp = IBPData[rawBasis];
        qbasis = QuotientBasisFromRelations[rawBasis, ibp["RelationMatrix"]];
        redef = RedefinitionImageData[nh, Nd, qbasis["Basis"], opts];

        piv = If[MatrixQ[redef["IndependentVectors"]] && redef["IndependentVectors"] =!= {},
          PivotColumns[redef["IndependentVectors"]],
          {}
        ];

        physBasis = Delete[qbasis["Basis"], List /@ Sort[piv]];
        redefRules = RedefinitionRulesFromVectors[
          qbasis["Basis"],
          redef["IndependentDeltas"],
          redef["IndependentVectors"]
        ];

        <|
          "nh" -> nh,
          "Nd" -> Nd,
          "Dimension" -> nh + Nd,

          "RawBasis" -> rawBasis,
          "RawCount" -> Length[rawBasis],

          "IBPSolution" -> ibp["Solution"],
          "IBPFreeParameters" -> ibp["FreeParameters"],
          "IBPRelationMatrix" -> ibp["RelationMatrix"],
          "IBPRelationExpressions" -> ibp["RelationExpressions"],
          "IBPPivots" -> qbasis["PivotColumns"],
          "IBPBasis" -> qbasis["Basis"],
          "IBPCount" -> Length[qbasis["Basis"]],

          "RedefDeltaBasis" -> redef["DeltaBasis"],
          "RedefShiftImages" -> redef["ShiftImages"],
          "RedefProjectedData" -> redef["ProjectedData"],
          "RedefImageVectors" -> redef["ImageVectors"],
          "RedefIndependentRows" -> redef["IndependentRows"],
          "RedefIndependentVectors" -> redef["IndependentVectors"],
          "RedefIndependentDeltas" -> redef["IndependentDeltas"],
          "RedefRank" -> redef["Rank"],
          "RedefPivots" -> piv,
          "RedefinitionRules" -> redefRules,

          "PhysicalBasis" -> physBasis,
          "PhysicalCount" -> Length[physBasis]
        |>
      ]
    ],
    opts
  ];

(* ================================================================ *)
(* 9. Lagrangian reduction helpers                                  *)
(* ================================================================ *)

ClearAll[ReduceSectorLagrangian, ReduceLagrangian];

ReduceSectorLagrangianCanonicalInput[inputExpr_, nh_Integer, Nd_Integer, opts : OptionsPattern[RunBasisComputation]] := Module[
  {sec, ibpProj, redefReduction, reducedExpr, imageExpr},

  sec = ComputeSectorData[nh, Nd, opts];
  ibpProj = ProjectToIBPUsingSectorData[inputExpr, sec];
  redefReduction = ReduceCoordinatesModuloRedef[ibpProj["Coordinates"], sec];

  reducedExpr = canonExpr @ LinearCombination[
    redefReduction["PhysicalCoordinates"],
    sec["PhysicalBasis"]
  ];

  imageExpr = canonExpr @ LinearCombination[
    ibpProj["Coordinates"] - redefReduction["ReducedIBPCoordinates"],
    sec["IBPBasis"]
  ];

  <|
    "Sector" -> {nh, Nd},
    "InputExpression" -> inputExpr,
    "ProjectionSucceededQ" -> ibpProj["ProjectionSucceededQ"],
    "ProjectionResidual" -> ibpProj["ProjectionResidual"],
    "ProjectedIBPExpression" -> ibpProj["ProjectedExpr"],
    "ProjectedIBPCoordinates" -> ibpProj["Coordinates"],
    "ReducedIBPExpression" -> canonExpr @ LinearCombination[
      redefReduction["ReducedIBPCoordinates"],
      sec["IBPBasis"]
    ],
    "ReducedIBPCoordinates" -> redefReduction["ReducedIBPCoordinates"],
    "PhysicalBasis" -> sec["PhysicalBasis"],
    "PhysicalCoordinates" -> redefReduction["PhysicalCoordinates"],
    "RedefinitionImageExpression" -> imageExpr,
    "RedefinitionImageCoefficients" -> redefReduction["RedefinitionImageCoefficients"],
    "ReducedExpression" -> reducedExpr,
    "SectorData" -> sec
  |>
];

ReduceSectorLagrangian[expr_, nh_Integer, Nd_Integer, opts : OptionsPattern[RunBasisComputation]] := Module[
  {inputExpr},

  inputExpr = canonExpr[expr];
  ReduceSectorLagrangianCanonicalInput[inputExpr, nh, Nd, opts]
];

ReduceLagrangian[expr_, opts : OptionsPattern[RunBasisComputation]] := Module[
  {
    inputExpr, sectorTerms, sectorKeys, sectorsToReduce, sectorReductions,
    untouchedTerms, reducedExpr, kernels, localOpts
  },

  inputExpr = Expand[canonExpr[expr]];
  sectorTerms = SplitTermsBySector[inputExpr];
  sectorKeys = Sort @ Keys[sectorTerms];
  sectorsToReduce = Select[sectorKeys, MatchQ[#, {_Integer?Positive, _Integer?NonNegative}] &];

  untouchedTerms = Total @ Values @ KeySelect[
    sectorTerms,
    ! MatchQ[#, {_Integer?Positive, _Integer?NonNegative}] &
  ];

  localOpts = Join[
    FilterRules[{opts}, Options[RunBasisComputation]],
    {"ParallelizeSectors" -> False}
  ];

  sectorReductions = If[
    TrueQ[OptionValue["ParallelizeSectors"]] && Length[sectorsToReduce] > 1,
    kernels = EnsureParallelToolkitKernels[Length[sectorsToReduce], opts];
    Association @ ParallelMap[
      Function[key,
        key -> ReduceSectorLagrangianCanonicalInput[
          sectorTerms[key],
          key[[1]],
          key[[2]],
          Sequence @@ localOpts
        ]
      ],
      sectorsToReduce
    ],
    Association @ Table[
      key -> ReduceSectorLagrangianCanonicalInput[sectorTerms[key], key[[1]], key[[2]], Sequence @@ localOpts],
      {key, sectorsToReduce}
    ]
  ];

  reducedExpr = canonExpr @ (
    Total[Lookup[Values[sectorReductions], "ReducedExpression", {}]] + untouchedTerms
  );

  <|
    "InputExpression" -> inputExpr,
    "UntouchedExpression" -> untouchedTerms,
    "SectorReductions" -> sectorReductions,
    "ReducedExpression" -> reducedExpr
  |>
];

(* ================================================================ *)
(* 10. Exports and summaries                                        *)
(* ================================================================ *)

ClearAll[SectorSummaryTable, PrintSectorSummary, ExportSummaryCSV, ExportSummaryMX];

SectorSummaryTable[result_Association] := Module[{sum, keys},
  sum = result["Summary"];
  keys = Keys[sum];
  Table[
    {
      key[[1]], key[[2]],
      sum[key]["Dimension"],
      sum[key]["RawCount"],
      sum[key]["IBPCount"],
      sum[key]["RedefRank"],
      sum[key]["PhysicalCount"]
    },
    {key, keys}
  ]
];

PrintSectorSummary[result_Association] := Module[{tbl},
  tbl = SectorSummaryTable[result];
  Print @ Grid[
    Prepend[tbl, {"nh", "Nd", "D", "RawCount", "IBPCount", "RedefRank", "PhysicalCount"}],
    Frame -> All
  ];
];

ExportSummaryCSV[result_Association, file_String] := Module[{tbl},
  tbl = SectorSummaryTable[result];
  Export[file,
    Prepend[tbl, {"nh", "Nd", "D", "RawCount", "IBPCount", "RedefRank", "PhysicalCount"}],
    "CSV"
  ]
];

ExportSummaryMX[result_Association, file_String] := Export[file, result, "MX"];

(* ================================================================ *)
(* 11. Convenience accessors                                        *)
(* ================================================================ *)

ClearAll[
  RawBasisOfSector, IBPBasisOfSector, PhysicalBasisOfSector,
  RedefinitionsOfSector, RedefinitionRulesOfSector
];

RawBasisOfSector[result_Association, nh_Integer, Nd_Integer] :=
  result["SectorData"][{nh, Nd}]["RawBasis"];

IBPBasisOfSector[result_Association, nh_Integer, Nd_Integer] :=
  result["SectorData"][{nh, Nd}]["IBPBasis"];

PhysicalBasisOfSector[result_Association, nh_Integer, Nd_Integer] :=
  result["SectorData"][{nh, Nd}]["PhysicalBasis"];

RedefinitionsOfSector[result_Association, nh_Integer, Nd_Integer] :=
  result["SectorData"][{nh, Nd}]["RedefIndependentDeltas"];

RedefinitionRulesOfSector[result_Association, nh_Integer, Nd_Integer] :=
  result["SectorData"][{nh, Nd}]["RedefinitionRules"];

(* ================================================================ *)
(* 12. Master driver                                                *)
(* ================================================================ *)

RunBasisComputation[opts : OptionsPattern[]] := Module[
  {dmax, sectors, data, summary, result, csvFile, mxFile, localOpts},

  dmax = OptionValue["MaxDimension"];
  sectors = NormalizeSectorList[OptionValue["SectorList"], dmax];
  sectors = Select[sectors, #[[1]] >= 1 && #[[2]] >= 0 && Total[#] <= dmax &];
  localOpts = Join[
    FilterRules[{opts}, Options[RunBasisComputation]],
    {"ParallelizeSectors" -> False}
  ];

  data = If[
    TrueQ[OptionValue["ParallelizeSectors"]] && Length[sectors] > 1,
    EnsureParallelToolkitKernels[Length[sectors], opts];
    Association @ ParallelMap[
      Function[sec,
        With[{nh = sec[[1]], Nd = sec[[2]]},
          {nh, Nd} -> ComputeSectorData[nh, Nd, Sequence @@ localOpts]
        ]
      ],
      sectors
    ],
    Association @ Table[
      With[{nh = sec[[1]], Nd = sec[[2]]},
        {nh, Nd} -> ComputeSectorData[nh, Nd, Sequence @@ localOpts]
      ],
      {sec, sectors}
    ]
  ];

  summary = Association @ Table[
    With[{d = data[sec]},
      sec -> <|
        "Dimension" -> d["Dimension"],
        "RawCount" -> d["RawCount"],
        "IBPCount" -> d["IBPCount"],
        "RedefRank" -> d["RedefRank"],
        "PhysicalCount" -> d["PhysicalCount"]
      |>
    ],
    {sec, sectors}
  ];

  result = <|
    "MaxDimension" -> dmax,
    "SectorList" -> sectors,
    "SectorData" -> data,
    "Summary" -> summary
  |>;

  If[TrueQ[OptionValue["ExportSummaryCSV"]],
    csvFile = OptionValue["SummaryCSVFile"];
    If[csvFile === Automatic,
      csvFile = FileNameJoin[{CacheDirectoryResolved[opts], "graviton_basis_summary.csv"}]
    ];
    ExportSummaryCSV[result, csvFile];
    LogPrint["[export] summary CSV -> " <> csvFile, opts];
  ];

  If[TrueQ[OptionValue["ExportResultMX"]],
    mxFile = OptionValue["ResultMXFile"];
    If[mxFile === Automatic,
      mxFile = FileNameJoin[{CacheDirectoryResolved[opts], "graviton_basis_result.mx"}]
    ];
    ExportSummaryMX[result, mxFile];
    LogPrint["[export] result MX -> " <> mxFile, opts];
  ];

  result
];

(* ================================================================ *)
(* 13. Example usage                                                *)
(* ================================================================ *)

(***

res5 = RunBasisComputation[
  "MaxDimension" -> 5,
  "CacheDirectory" -> FileNameJoin[{NotebookDirectory[], "basis_cache"}],
  "UseCache" -> True,
  "ForceRecompute" -> False,
  "Verbose" -> True,
  "ExportSummaryCSV" -> True,
  "ExportResultMX" -> True
];

PrintSectorSummary[res5];

(* the sector relevant to dim-5 cubic derivative terms *)
phys32 = PhysicalBasisOfSector[res5, 3, 2];
phys32 // TableForm;

(* independent field redefinitions that span the quotient image *)
redef32 = RedefinitionRulesOfSector[res5, 3, 2];
redef32 // TableForm;

(* reduce a concrete lagrangian modulo IBP and field redefinitions *)
lag = RawBasisOfSector[res5, 3, 2][[1]] + 3 RawBasisOfSector[res5, 3, 2][[2]];
ReduceLagrangian[lag,
  "MaxDimension" -> 5,
  "CacheDirectory" -> FileNameJoin[{NotebookDirectory[], "basis_cache"}],
  "UseCache" -> True
]["ReducedExpression"]

(* rerun to D=6 reusing D<=5 cache *)
res6 = RunBasisComputation[
  "MaxDimension" -> 6,
  "CacheDirectory" -> FileNameJoin[{NotebookDirectory[], "basis_cache"}],
  "UseCache" -> True,
  "ForceRecompute" -> False,
  "Verbose" -> True
];

(* restrict to a single sector if desired *)
resSingle = RunBasisComputation[
  "MaxDimension" -> 8,
  "SectorList" -> {{3, 2}},
  "CacheDirectory" -> FileNameJoin[{NotebookDirectory[], "basis_cache"}],
  "UseCache" -> True
];

***)
