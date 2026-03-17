res = Get["orbit_fixed_eh_comparison_result.wl"];
sec = res["ReducedInput", "SectorReductions"][{2,4}];
Print["input24_reduced_zero=" <> ToString[InputForm[sec["ReducedExpression"] === 0]]];
Print["input24_phys_coords=" <> ToString[InputForm[sec["PhysicalCoordinates"]]]];
Print["input24_terms=" <> ToString[InputForm[If[sec["ReducedExpression"]===0,0,If[Head[Expand[sec["ReducedExpression"]]]===Plus,Length[List@@Expand[sec["ReducedExpression"]]],1]]]]];
Print["input24_expr=" <> ToString[InputForm[Short[sec["ReducedExpression"], 4]]]];
Quit[];
