SetDirectory[DirectoryName[$InputFileName]];

mark[file_, expr_] := Export[file, expr, "Package"];

Get["graviton_basis_toolkit.wl"];
mark["debug_left_sector_10_step_1_loaded.wl", "loaded"];

lag = Get["LEFT_only_uv_2_eft_6_xact.wl"];
mark["debug_left_sector_10_step_2_lag_loaded.wl", "lag loaded"];

sectorTerms = SplitTermsBySector[Expand[canonExpr[lag]]];
expr10 = sectorTerms[{1, 0}];
mark["debug_left_sector_10_step_3_expr.wl", expr10];

opts = {
  "MaxDimension" -> 8,
  "CacheDirectory" -> FileNameJoin[{Directory[], "left_only_uv_2_eft_6_cache"}],
  "UseCache" -> True,
  "Verbose" -> False
};

sec = ComputeSectorData[1, 0, Sequence @@ opts];
mark["debug_left_sector_10_step_4_sector_data.wl", <|
  "RawBasis" -> sec["RawBasis"],
  "IBPBasis" -> sec["IBPBasis"],
  "PhysicalBasis" -> sec["PhysicalBasis"]
|>];

ibpProj = ProjectModuloIBP[expr10, sec["IBPBasis"]];
mark["debug_left_sector_10_step_5_ibp_proj.wl", ibpProj];

redefReduction = ReduceCoordinatesModuloRedef[ibpProj["Coordinates"], sec];
mark["debug_left_sector_10_step_6_redef.wl", redefReduction];

reducedExpr = canonExpr @ LinearCombination[
  redefReduction["PhysicalCoordinates"],
  sec["PhysicalBasis"]
];
mark["debug_left_sector_10_step_7_reduced_expr.wl", reducedExpr];
