scriptDir = DirectoryName[$InputFileName];
repoRoot = NestWhile[
  DirectoryName,
  scriptDir,
  ! FileExistsQ[FileNameJoin[{#, "graviton_basis_toolkit.wl"}]] &
];
SetDirectory[repoRoot];

outputDir = FileNameJoin[{Directory[], "artifacts", "left_only_uv_2_eft_6"}];
If[! DirectoryQ[outputDir], CreateDirectory[outputDir, CreateIntermediateDirectories -> True]];
logFile = FileNameJoin[{outputDir, "LEFT_only_uv_2_eft_6_by_sector.log"}];
If[FileExistsQ[logFile], DeleteFile[logFile]];

log[msg_] := PutAppend[
  DateString[{"Year", "-", "Month", "-", "Day", " ", "Hour", ":", "Minute", ":", "Second"}] <>
    "  " <> msg,
  logFile
];

Get["graviton_basis_toolkit.wl"];

termCount[expr_] := Module[{expanded = Expand[expr]},
  Which[
    expanded === 0, 0,
    Head[expanded] === Plus, Length[List @@ expanded],
    True, 1
  ]
];

lag = Get[FileNameJoin[{outputDir, "LEFT_only_uv_2_eft_6_xact.wl"}]];
sectorTerms = SplitTermsBySector[Expand[canonExpr[lag]]];
sectorKeys = Sort[Keys[sectorTerms]];

opts = {
  "MaxDimension" -> 8,
  "CacheDirectory" -> FileNameJoin[{Directory[], "cache", "left_only_uv_2_eft_6_cache"}],
  "UseCache" -> True,
  "Verbose" -> False
};

log["Starting sector reduction for keys: " <> ToString[sectorKeys, InputForm]];

reductions = <||>;
summary = <||>;

Do[
  Module[{nh = key[[1]], Nd = key[[2]], sec, secData},
    log["Starting sector " <> ToString[key, InputForm]];
    sec = ReduceSectorLagrangian[sectorTerms[key], nh, Nd, Sequence @@ opts];
    secData = sec["SectorData"];
    reductions[key] = sec;
    summary[key] = <|
      "InputTermCount" -> termCount[sec["InputExpression"]],
      "ProjectedIBPTermCount" -> termCount[sec["ProjectedIBPExpression"]],
      "ReducedTermCount" -> termCount[sec["ReducedExpression"]],
      "RawCount" -> secData["RawCount"],
      "IBPCount" -> secData["IBPCount"],
      "RedefRank" -> secData["RedefRank"],
      "PhysicalCount" -> secData["PhysicalCount"],
      "ReducedToZeroQ" -> TrueQ[sec["ReducedExpression"] === 0]
    |>;
    Export[FileNameJoin[{outputDir, "LEFT_only_uv_2_eft_6_partial_sector_summary.wl"}], summary, "Package"];
    Export[FileNameJoin[{outputDir, "LEFT_only_uv_2_eft_6_partial_reduction.mx"}], reductions, "MX"];
    log[
      "Completed sector " <> ToString[key, InputForm] <>
      " with reduced term count " <> ToString[summary[key]["ReducedTermCount"], InputForm]
    ];
  ],
  {key, sectorKeys}
];

reducedExpr = canonExpr @ Total[Lookup[Values[reductions], "ReducedExpression", {}]];

Export[FileNameJoin[{outputDir, "LEFT_only_uv_2_eft_6_xact_reduced.wl"}], reducedExpr, "Package"];
Export[FileNameJoin[{outputDir, "LEFT_only_uv_2_eft_6_xact_reduction_summary.wl"}], <|
  "SectorKeys" -> sectorKeys,
  "SectorSummary" -> summary,
  "TotalInputTermCount" -> termCount[lag],
  "TotalReducedTermCount" -> termCount[reducedExpr]
|>, "Package"];
Export[FileNameJoin[{outputDir, "LEFT_only_uv_2_eft_6_xact_reduction.mx"}], <|
  "SectorReductions" -> reductions,
  "ReducedExpression" -> reducedExpr
|>, "MX"];

log["Completed all sector reductions."];
