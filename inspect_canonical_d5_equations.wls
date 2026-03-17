Get["graviton_basis_toolkit.wl"];
Get["orbit_fixed_eh_comparison.wl"];

res = Get["orbit_fixed_eh_comparison_d5_free_ref_v3_result.wl"];

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

rawInput = res["RawReducedInput"];
referenceReduction = res["ReducedReference"];
canonicalData = kineticNormalizationDataFromReduction[rawInput, basisOpts];
canonicalInput = canonicalNormalizeReduction[rawInput, canonicalData["Factor"]];
supportedSectors = supportedSectorsUpTo[5];

sectorComparisons = Association @ Table[
  sector -> Append[
    sectorComparisonRecord[
      sector,
      sectorLookup[canonicalInput["SectorReductions"], sector],
      sectorLookup[referenceReduction["SectorReductions"], sector],
      Which[
        AssociationQ[sectorLookup[canonicalInput["SectorReductions"], sector]],
          canonicalInput["SectorReductions"][sector]["SectorData"],
        AssociationQ[sectorLookup[referenceReduction["SectorReductions"], sector]],
          referenceReduction["SectorReductions"][sector]["SectorData"],
        True,
          ComputeSectorData[sector[[1]], sector[[2]], Sequence @@ basisOpts]
      ]
    ],
    "SupportedQ" -> True
  ],
  {sector, supportedSectors}
];

eqRecords = collectDifferenceEquationRecords[sectorComparisons];

Print["CanonicalFactor"];
Print[InputForm[canonicalData["Factor"]]];

Print["CanonicalSucceededQ"];
Print[InputForm[canonicalData["SucceededQ"]]];

Print["Sector10DifferenceCoordinates"];
Print[InputForm[sectorComparisons[{1, 0}]["DifferenceCoordinates"]]];

Print["Sector22DifferenceCoordinates"];
Print[InputForm[sectorComparisons[{2, 2}]["DifferenceCoordinates"]]];

Print["Sector32DifferenceCoordinates"];
Print[InputForm[sectorComparisons[{3, 2}]["DifferenceCoordinates"]]];

Print["Equations"];
Print[InputForm[Lookup[eqRecords, "Equation"]]];

Quit[];
