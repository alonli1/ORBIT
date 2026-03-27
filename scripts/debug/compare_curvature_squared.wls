scriptDir = DirectoryName[$InputFileName];
repoRoot = NestWhile[
  DirectoryName,
  scriptDir,
  ! FileExistsQ[FileNameJoin[{#, "graviton_basis_toolkit.wl"}]] &
];
SetDirectory[repoRoot];

log = OpenWrite["compare_curvature_squared.log", PageWidth -> Infinity];
$Output = {log};
$Messages = {log};

Get["graviton_basis_toolkit.wl"];

ClearAll[linRicciExpr, linRicciScalarExpr, linRiemannExpr];

linRicciExpr[x_, y_] := canonExpr[
  1/2 (
    PD[-c][PD[x][h[y, c]]] +
    PD[-c][PD[y][h[x, c]]] -
    PD[-x][PD[-y][h[c, -c]]] -
    PD[-c][PD[c][h[x, y]]]
  )
];

linRicciScalarExpr[] := canonExpr[
  PD[-a][PD[-b][h[a, b]]] - PD[-a][PD[a][h[b, -b]]]
];

linRiemannExpr[x_, y_, z_, w_] := canonExpr[
  1/2 (
    PD[-z][PD[-y][h[x, w]]] +
    PD[-w][PD[x][h[y, z]]] -
    PD[-w][PD[-y][h[x, z]]] -
    PD[-z][PD[x][h[y, w]]]
  )
];

res = RunBasisComputation[
  "MaxDimension" -> 6,
  "SectorList" -> {{2, 4}},
  "CacheDirectory" -> FileNameJoin[{Directory[], "curv_compare_cache"}],
  "UseCache" -> False,
  "ForceRecompute" -> True,
  "Verbose" -> False
];

basis = res["SectorData"][{2, 4}]["IBPBasis"];

project[expr_] := ProjectModuloIBP[canonExpr[expr], basis];

r2 = project[linRicciScalarExpr[] linRicciScalarExpr[]];
ricci2 = project[linRicciExpr[-a, -b] linRicciExpr[a, b]];
riem2 = project[linRiemannExpr[-a, -b, -c, -d] linRiemannExpr[a, b, c, d]];
gb = canonExpr[riem2["ProjectedExpr"] - 4 ricci2["ProjectedExpr"] + r2["ProjectedExpr"]];

WriteString[log, "IBP_COUNT: " <> ToString[Length[basis], InputForm] <> "\n"];
WriteString[log, "R2_COORDS: " <> ToString[r2["Coordinates"], InputForm] <> "\n"];
WriteString[log, "RICCI2_COORDS: " <> ToString[ricci2["Coordinates"], InputForm] <> "\n"];
WriteString[log, "RIEM2_COORDS: " <> ToString[riem2["Coordinates"], InputForm] <> "\n"];
WriteString[log, "GB_COMBINATION: " <> ToString[gb, InputForm] <> "\n"];
WriteString[log, "MESSAGES: " <> ToString[$MessageList, InputForm] <> "\n"];

Close[log];
Quit[];
