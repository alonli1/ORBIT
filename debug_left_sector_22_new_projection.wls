SetDirectory[DirectoryName[$InputFileName]];

Get["graviton_basis_toolkit.wl"];

lag = Get["LEFT_only_uv_2_eft_6_xact.wl"];
sectorTerms = SplitTermsBySector[Expand[canonExpr[lag]]];
expr22 = sectorTerms[{2, 2}];

opts = {
  "MaxDimension" -> 8,
  "CacheDirectory" -> FileNameJoin[{Directory[], "left_only_uv_2_eft_6_cache"}],
  "UseCache" -> True,
  "Verbose" -> False
};

sec = ComputeSectorData[2, 2, Sequence @@ opts];
proj = ProjectToIBPUsingSectorData[expr22, sec];

Export["debug_left_sector_22_new_projection.wl", proj, "Package"];
