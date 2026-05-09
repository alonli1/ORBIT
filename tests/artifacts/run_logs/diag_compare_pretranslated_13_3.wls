scriptDir = DirectoryName[$InputFileName];
repoRoot = NestWhile[DirectoryName, scriptDir, ! FileExistsQ[FileNameJoin[{#, "orbit_fixed_eh_comparison.wl"}]] &];
SetDirectory[repoRoot];
Get["graviton_basis_toolkit.wl"];
Get["orbit_fixed_eh_comparison.wl"];
translated = LoadMatcheteToXAct[FileNameJoin[{Directory[], "examples", "left_only_uv_2_eft_6", "LEFT_only_uv_2_eft_6.mx"}]];
res = CompareMatcheteToFixedEH[translated, "MaxDimension" -> 1, "CanonicalNormalizeInput" -> False, "UseQuadraticCompletion" -> False, "CacheDirectory" -> FileNameJoin[{Directory[], "cache", "diag_compare_cache"}], "UseCache" -> True, "Verbose" -> False];
WriteString[$Output, ToString[AssociationQ[res], InputForm] <> "\n"];
Quit[];
