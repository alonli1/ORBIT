Get["orbit_fixed_eh_comparison.wl"];
ref = ExpandFixedEHReferenceLagrangian["MaxDimension" -> 6, "Verbose" -> False];
expr = SplitTermsBySector[ref["ReferenceExpression"]][{2,2}];
Print["expr_short=" <> ToString[InputForm[Short[expr, 4]]]];
inds = DeleteDuplicates[Cases[expr, x_ /; xAct`xTensor`AbstractIndexQ[x], Infinity]];
Print["inds=" <> ToString[InputForm[inds]]];
If[inds =!= {}, Do[Print["vbundle=" <> ToString[InputForm[xAct`xTensor`VBundleOfIndex[inds[[i]]]]]], {i, Length[inds]}]];
Quit[];
