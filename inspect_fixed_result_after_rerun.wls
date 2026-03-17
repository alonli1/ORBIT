res = Get["orbit_fixed_eh_comparison_result.wl"];
summary = <|
  "ExactMatchQ" -> res["ExactMatchQ"],
  "UnsupportedSectors" -> res["UnsupportedSectors"],
  "InputProjectionFailures" -> res["InputProjectionFailures"],
  "ReferenceProjectionFailures" -> res["ReferenceProjectionFailures"],
  "MatchReduce" -> res["MatchSolutions", "TranslatedReduceResult"],
  "StageTimings" -> res["StageTimings"]
|>;
Print[InputForm[summary]];
Print["input24_zero=" <> ToString[InputForm[res["ReducedInput", "SectorReductions"][{2,4}]["ReducedExpression"] === 0]]];
Print["sector24_diff_zero=" <> ToString[InputForm[res["SectorComparison"][{2,4}]["DifferenceIsZeroQ"]]]];
Print["supported_diff_zero=" <> ToString[InputForm[res["SupportedDifference"] === 0]]];
Print["unsupported_diff_zero=" <> ToString[InputForm[res["UnsupportedDifference"] === 0]]];
Quit[];
