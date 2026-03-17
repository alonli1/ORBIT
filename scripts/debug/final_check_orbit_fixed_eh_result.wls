res = Get["orbit_fixed_eh_comparison_result.wl"];
Print[InputForm[<|"ExactMatchQ" -> res["ExactMatchQ"], "UnsupportedSectors" -> res["UnsupportedSectors"], "HasSolution" -> res["MatchSolutions", "HasSolution"], "StageTimings" -> res["StageTimings"]|>]];
Quit[];
