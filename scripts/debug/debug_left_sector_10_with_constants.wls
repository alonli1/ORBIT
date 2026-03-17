SetDirectory[DirectoryName[$InputFileName]];

mark[file_, expr_] := Export[file, expr, "Package"];

Get["graviton_basis_toolkit.wl"];
constSyms = ToExpression /@ {"hbar", "M", "\\[Kappa]", "\\[Epsilon]", "\\[Mu]bar2"};
Scan[(Quiet @ Check[DefConstantSymbol[#], Null]) &, constSyms];
mark["debug_left_sector_10_consts_step_1_loaded.wl", "loaded"];

lag = Get["LEFT_only_uv_2_eft_6_xact.wl"];
sectorTerms = SplitTermsBySector[Expand[canonExpr[lag]]];
expr10 = sectorTerms[{1, 0}];
mark["debug_left_sector_10_consts_step_2_expr.wl", expr10];

opts = {
  "MaxDimension" -> 8,
  "CacheDirectory" -> FileNameJoin[{Directory[], "left_only_uv_2_eft_6_cache"}],
  "UseCache" -> True,
  "Verbose" -> False
};

sec = ComputeSectorData[1, 0, Sequence @@ opts];
mark["debug_left_sector_10_consts_step_3_sector_data.wl", <|
  "RawBasis" -> sec["RawBasis"],
  "IBPBasis" -> sec["IBPBasis"],
  "PhysicalBasis" -> sec["PhysicalBasis"]
|>];

ibpProj = ProjectModuloIBP[expr10, sec["IBPBasis"]];
mark["debug_left_sector_10_consts_step_4_ibp_proj.wl", ibpProj];

redefReduction = ReduceCoordinatesModuloRedef[ibpProj["Coordinates"], sec];
mark["debug_left_sector_10_consts_step_5_redef.wl", redefReduction];
