scriptDir = DirectoryName[$InputFileName];
repoRoot = NestWhile[DirectoryName, scriptDir, ! FileExistsQ[FileNameJoin[{#, "graviton_basis_toolkit.wl"}]] &];
SetDirectory[repoRoot];
Get["graviton_basis_toolkit.wl"];
opts = {"CacheDirectory" -> FileNameJoin[{Directory[], "cache", "diag_cache"}], "UseCache" -> True, "ForceRecompute" -> False, "Verbose" -> False};
red = ReduceSectorLagrangian[LFP, 2, 2, Sequence @@ opts];
WriteString[$Output, ToString[AssociationQ[red], InputForm] <> "\n"];
If[AssociationQ[red], WriteString[$Output, ToString[red["ProjectionResidual"] === 0, InputForm] <> "\n"]];
Quit[];
