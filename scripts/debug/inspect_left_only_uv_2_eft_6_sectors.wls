SetDirectory[DirectoryName[$InputFileName]];

Get["graviton_basis_toolkit.wl"];

termCount[expr_] := Module[{expanded = Expand[expr]},
  If[expanded === 0, 0, Length[List @@ expanded]]
];

lag = Get["LEFT_only_uv_2_eft_6_xact.wl"];
sectorTerms = SplitTermsBySector[Expand[canonExpr[lag]]];
sectorKeys = Sort[Keys[sectorTerms]];

sectorSummary = Association @ Table[
  key -> <|
    "TermCount" -> termCount[sectorTerms[key]]
  |>,
  {key, sectorKeys}
];

Export["LEFT_only_uv_2_eft_6_xact_sector_summary.wl", <|
  "SectorKeys" -> sectorKeys,
  "SectorSummary" -> sectorSummary
|>, "Package"];
