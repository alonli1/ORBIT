Get["orbit_fixed_eh_comparison.wl"];
res = Get["orbit_fixed_eh_comparison_result.wl"];
ms = res["MatchSolutions"];
Print["solve_head=" <> ToString[Head[ms["SolveResult"]], InputForm]];
Print["reduce_head=" <> ToString[Head[ms["ReduceResult"]], InputForm]];
Print["solve_result_short=" <> ToString[InputForm[Short[ms["SolveResult"], 3]]]];
Print["reduce_result_short=" <> ToString[InputForm[Short[ms["ReduceResult"], 3]]]];
Quit[];
