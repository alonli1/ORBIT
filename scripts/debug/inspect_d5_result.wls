res = Get["orbit_fixed_eh_comparison_d5_v2_result.wl"];

Print["HasSolution"];
Print[InputForm[res["MatchSolutions", "HasSolution"]]];

Print["Sector10Input"];
Print[InputForm[res["ReducedInput", "SectorReductions"][{1, 0}]["PhysicalCoordinates"]]];

Print["Sector10Reference"];
Print[InputForm[res["ReducedReference", "SectorReductions"][{1, 0}]["PhysicalCoordinates"]]];

Print["NormalizedHasPlainEpsilon"];
Print[InputForm[FreeQ[res["NormalizedExpression"], \[Epsilon]]]];

Print["NormalizedHasScalarEpsilon"];
Print[InputForm[FreeQ[res["NormalizedExpression"], Scalar[\[Epsilon]]]]];

Print["NormalizedLogs"];
Print[InputForm[DeleteDuplicates @ Cases[res["NormalizedExpression"], _Log, Infinity]]];
