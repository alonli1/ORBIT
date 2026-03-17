SetDirectory[DirectoryName[$InputFileName]];

mark[file_, expr_] := Export[file, expr, "Package"];

Get["graviton_basis_toolkit.wl"];

lag = Get["LEFT_only_uv_2_eft_6_xact.wl"];
sectorTerms = SplitTermsBySector[Expand[canonExpr[lag]]];
expr22 = sectorTerms[{2, 2}];
mark["debug_left_sector_22_step_1_expr.wl", expr22];

opts = {
  "MaxDimension" -> 8,
  "CacheDirectory" -> FileNameJoin[{Directory[], "left_only_uv_2_eft_6_cache"}],
  "UseCache" -> True,
  "Verbose" -> False
};

sec = ComputeSectorData[2, 2, Sequence @@ opts];
mark["debug_left_sector_22_step_2_sector_data.wl", <|
  "IBPBasis" -> sec["IBPBasis"],
  "PhysicalBasis" -> sec["PhysicalBasis"]
|>];

proj = ProjectModuloIBP[expr22, sec["IBPBasis"]];
mark["debug_left_sector_22_step_3_proj.wl", proj];
