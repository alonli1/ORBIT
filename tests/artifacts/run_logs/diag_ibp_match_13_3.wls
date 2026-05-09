scriptDir = DirectoryName[$InputFileName];
repoRoot = NestWhile[DirectoryName, scriptDir, ! FileExistsQ[FileNameJoin[{#, "graviton_basis_toolkit.wl"}]] &];
SetDirectory[repoRoot];
Get["graviton_basis_toolkit.wl"];
opts = {"CacheDirectory" -> FileNameJoin[{Directory[], "cache", "diag_cache"}], "UseCache" -> True, "ForceRecompute" -> False, "Verbose" -> False};
sec = ComputeSectorData[3, 2, Sequence @@ opts];
b = First[sec["PhysicalBasis"]];
canonB = canonExpr[b];
posStruct = FirstPosition[sec["IBPBasis"], canonB, Missing["NF"], {1}, Heads -> False];
WriteString[$Output, "struct=" <> ToString[posStruct, InputForm] <> "\n"];
Do[
  diff = Quiet[canonExpr[canonB - sec["IBPBasis"][[i]]]];
  If[TrueQ[diff === 0], WriteString[$Output, "canonMatch=" <> ToString[i, InputForm] <> "\n"]],
  {i, Length[sec["IBPBasis"]]}
];
Quit[];
