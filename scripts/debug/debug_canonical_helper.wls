Get["graviton_basis_toolkit.wl"];
Get["orbit_fixed_eh_comparison.wl"];

res = Get["orbit_fixed_eh_comparison_d5_free_ref_v3_result.wl"];
raw = res["RawReducedInput"];
basisOpts = {
  "MaxDimension" -> 5,
  "CacheDirectory" -> If[
    DirectoryQ[FileNameJoin[{Directory[], "left_only_uv_2_eft_6_cache"}]],
    FileNameJoin[{Directory[], "left_only_uv_2_eft_6_cache"}],
    FileNameJoin[{Directory[], "orbit_fixed_eh_cache"}]
  ],
  "UseCache" -> True,
  "Verbose" -> False
};

sector22 = sectorLookup[raw["SectorReductions"], {2, 2}];
lfpReduction = ReduceSectorLagrangian[LFP, 2, 2, Sequence @@ basisOpts];
inputCoords = normalizeMatcheteParameterScalars /@ sector22["PhysicalCoordinates"];
lfpCoords = lfpReduction["PhysicalCoordinates"];
nz = Flatten @ Position[lfpCoords, x_ /; ! TrueQ[x === 0]];
firstIndex = First[nz];
factor = normalizeMatcheteParameterScalars @ Simplify[inputCoords[[firstIndex]]/lfpCoords[[firstIndex]]];
consistentQ = And @@ Table[
  TrueQ[Simplify[inputCoords[[i]] == factor lfpCoords[[i]]]],
  {i, nz}
];

Print["NZ"];
Print[InputForm[nz]];
Print["FirstIndex"];
Print[InputForm[firstIndex]];
Print["Factor"];
Print[InputForm[factor]];
Print["ConsistentQ"];
Print[InputForm[consistentQ]];
Print["Comparisons"];
Do[
  Print[InputForm[Simplify[inputCoords[[i]] == factor lfpCoords[[i]]]]],
  {i, nz}
];

Print["HelperResult"];
Print[InputForm[kineticNormalizationDataFromReduction[raw, basisOpts]]];
