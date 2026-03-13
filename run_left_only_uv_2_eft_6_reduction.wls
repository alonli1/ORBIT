SetDirectory[DirectoryName[$InputFileName]];

Get["graviton_basis_toolkit.wl"];

termCount[expr_] := Module[{expanded = Expand[expr]},
  If[expanded === 0, 0, Length[List @@ expanded]]
];

lag = Get["LEFT_only_uv_2_eft_6_xact.wl"];

opts = {
  "MaxDimension" -> 8,
  "CacheDirectory" -> FileNameJoin[{Directory[], "left_only_uv_2_eft_6_cache"}],
  "UseCache" -> True,
  "Verbose" -> False
};

red = ReduceLagrangian[lag, Sequence @@ opts];

sectorKeys = Sort[Keys[red["SectorReductions"]]];
sectorSummary = Association @ Table[
  With[{sec = red["SectorReductions"][key], secData = red["SectorReductions"][key]["SectorData"]},
    key -> <|
      "InputTermCount" -> termCount[sec["InputExpression"]],
      "ProjectedIBPTermCount" -> termCount[sec["ProjectedIBPExpression"]],
      "ReducedTermCount" -> termCount[sec["ReducedExpression"]],
      "RawCount" -> secData["RawCount"],
      "IBPCount" -> secData["IBPCount"],
      "RedefRank" -> secData["RedefRank"],
      "PhysicalCount" -> secData["PhysicalCount"],
      "ReducedToZeroQ" -> TrueQ[sec["ReducedExpression"] === 0]
    |>
  ],
  {key, sectorKeys}
];

resultSummary = <|
  "SectorKeys" -> sectorKeys,
  "TotalInputTermCount" -> termCount[red["InputExpression"]],
  "TotalReducedTermCount" -> termCount[red["ReducedExpression"]],
  "UntouchedTermCount" -> termCount[red["UntouchedExpression"]],
  "SectorSummary" -> sectorSummary
|>;

Export["LEFT_only_uv_2_eft_6_xact_reduced.wl", red["ReducedExpression"], "Package"];
Export["LEFT_only_uv_2_eft_6_xact_reduction_summary.wl", resultSummary, "Package"];
Export["LEFT_only_uv_2_eft_6_xact_reduction.mx", <|"Reduction" -> red, "Summary" -> resultSummary|>, "MX"];

Print["LEFT reduction complete."];
Print["Sectors: ", sectorKeys];
Print["Total input term count: ", resultSummary["TotalInputTermCount"]];
Print["Total reduced term count: ", resultSummary["TotalReducedTermCount"]];
Print["Untouched term count: ", resultSummary["UntouchedTermCount"]];
Print["Summary file: LEFT_only_uv_2_eft_6_xact_reduction_summary.wl"];
Print["Reduced expression file: LEFT_only_uv_2_eft_6_xact_reduced.wl"];
