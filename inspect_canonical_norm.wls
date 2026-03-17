Get["graviton_basis_toolkit.wl"];

sec22 = ComputeSectorData[2, 2, "MaxDimension" -> 5, "UseCache" -> True, "Verbose" -> False];
lfpRed = ReduceSectorLagrangian[LFP, 2, 2, "MaxDimension" -> 5, "UseCache" -> True, "Verbose" -> False];
comp = Get["orbit_fixed_eh_comparison_d5_free_ref_result.wl"];

Print["LFPPhysicalCoordinates"];
Print[InputForm[lfpRed["PhysicalCoordinates"]]];

Print["Input22PhysicalCoordinates"];
Print[InputForm[comp["ReducedInput", "SectorReductions"][{2, 2}]["PhysicalCoordinates"]]];

Print["Reference22PhysicalCoordinates"];
Print[InputForm[comp["ReducedReference", "SectorReductions"][{2, 2}]["PhysicalCoordinates"]]];

Print["Input22ReducedExpression"];
Print[InputForm[comp["ReducedInput", "SectorReductions"][{2, 2}]["ReducedExpression"]]];

Print["Reference22ReducedExpression"];
Print[InputForm[comp["ReducedReference", "SectorReductions"][{2, 2}]["ReducedExpression"]]];
