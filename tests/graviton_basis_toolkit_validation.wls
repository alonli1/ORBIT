scriptDir = DirectoryName[$InputFileName];
repoRoot = NestWhile[
  DirectoryName,
  scriptDir,
  ! FileExistsQ[FileNameJoin[{#, "graviton_basis_toolkit.wl"}]] &
];
SetDirectory[repoRoot];

Get["graviton_basis_toolkit.wl"];

cacheDir = FileNameJoin[{Directory[], "cache", "graviton_basis_validation_cache"}];

baseOptions = {
  "CacheDirectory" -> cacheDir,
  "UseCache" -> True,
  "ForceRecompute" -> False,
  "Verbose" -> False
};

ClearAll[termCount, vectorZeroQ, coefficientPool, runRedundantImageTest];

termCount[expr_] := Which[
  expr === 0, 0,
  Head[expr] === Plus, Length[List @@ expr],
  True, 1
];

vectorZeroQ[list_List] := DeleteCases[list, 0] === {};

coefficientPool = {
   7, -11, 13, -17, 19, -23, 29, -31, 37, -41,
   43, -47, 53, -59, 61, -67, 71, -73, 79, -83,
   89, -97, 101, -103, 107, -109, 113, -127, 131, -137,
   139, -149, 151, -157, 163, -167, 173, -179, 181, -191,
   193, -197, 199, -211, 223, -227, 229, -233, 239, -241
};

runRedundantImageTest[{nh_Integer, Nd_Integer}, maxDimension_Integer] := Module[
  {opts, sec, coeffs, lag, reduction, sectorReduction},

  opts = Join[
    baseOptions,
    {
      "MaxDimension" -> maxDimension,
      "SectorList" -> {{nh, Nd}}
    }
  ];

  sec = ComputeSectorData[nh, Nd, Sequence @@ opts];
  coeffs = Take[coefficientPool, Length[sec["RedefDeltaBasis"]]];
  lag = Expand @ Total[MapThread[Times, {coeffs, sec["RedefShiftImages"]}]];
  reduction = ReduceLagrangian[lag, Sequence @@ opts];
  sectorReduction = reduction["SectorReductions"][{nh, Nd}];

  <|
    "Sector" -> {nh, Nd},
    "IBPCount" -> sec["IBPCount"],
    "RedefRank" -> sec["RedefRank"],
    "PhysicalCount" -> sec["PhysicalCount"],
    "DeltaBasisLength" -> Length[sec["RedefDeltaBasis"]],
    "LagTermCount" -> termCount[lag],
    "ReducedExpressionZeroQ" -> (reduction["ReducedExpression"] === 0),
    "PhysicalCoordinatesZeroQ" -> vectorZeroQ[sectorReduction["PhysicalCoordinates"]],
    "ImageCoefficientCount" -> Length[sectorReduction["RedefinitionImageCoefficients"]],
    "ImageCoefficients" -> sectorReduction["RedefinitionImageCoefficients"]
  |>
];

results = <|
  "GeneratedOn" -> DateString[{"ISODate", " ", "Time"}],
  "CacheDirectory" -> cacheDir,
  "Tests" -> {
    runRedundantImageTest[{3, 2}, 5],
    runRedundantImageTest[{3, 4}, 7]
  }
|>;

Put[results, FileNameJoin[{Directory[], "docs", "graviton_basis", "graviton_basis_toolkit_validation_output.wl"}]];

(* === Pass/fail assertions === *)

allPassed = True;
Do[
  Module[{test = results["Tests"][[i]], label, passQ},
    label = ToString[test["Sector"]];
    passQ = TrueQ[test["ReducedExpressionZeroQ"]] && TrueQ[test["PhysicalCoordinatesZeroQ"]];
    If[passQ,
      Print["PASS: sector " <> label <> " — redundant image reduces to zero."],
      Print["FAIL: sector " <> label <> " — ReducedExpressionZeroQ=" <> ToString[test["ReducedExpressionZeroQ"]]
        <> ", PhysicalCoordinatesZeroQ=" <> ToString[test["PhysicalCoordinatesZeroQ"]]];
      allPassed = False;
    ];
  ],
  {i, Length[results["Tests"]]}
];

If[allPassed,
  Print["\nAll validation tests PASSED."],
  Print["\nSome validation tests FAILED."]; Exit[1]
];

results
