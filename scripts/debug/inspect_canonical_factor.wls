Get["graviton_basis_toolkit.wl"];
Get["orbit_fixed_eh_comparison.wl"];

res = Get["orbit_fixed_eh_comparison_d5_free_ref_v3_result.wl"];
raw = res["RawReducedInput"];
data = kineticNormalizationDataFromReduction[
  raw,
  {
    "MaxDimension" -> 5,
    "CacheDirectory" -> If[
      DirectoryQ[FileNameJoin[{Directory[], "left_only_uv_2_eft_6_cache"}]],
      FileNameJoin[{Directory[], "left_only_uv_2_eft_6_cache"}],
      FileNameJoin[{Directory[], "orbit_fixed_eh_cache"}]
    ],
    "UseCache" -> True,
    "Verbose" -> False
  }
];

Print["CanonicalData"];
Print[InputForm[data]];

sec22 = raw["SectorReductions"][{2, 2}];
lfp22 = ReduceSectorLagrangian[LFP, 2, 2, "MaxDimension" -> 5, "UseCache" -> True, "Verbose" -> False];

inputCoords = normalizeMatcheteParameterScalars /@ sec22["PhysicalCoordinates"];
lfpCoords = lfp22["PhysicalCoordinates"];

Print["InputCoords"];
Print[InputForm[inputCoords]];
Print["LFPCoords"];
Print[InputForm[lfpCoords]];
Print["Ratios"];
Print[InputForm[Simplify[inputCoords/lfpCoords]]];
Print["DifferencesAgainstFirstRatio"];
ratio = First[Simplify[inputCoords/lfpCoords]];
Print[InputForm[Simplify[inputCoords - ratio lfpCoords]]];
