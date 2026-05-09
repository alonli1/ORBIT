<|"GeneratedOn" -> "2026-04-23 00:05:20", "KernelVersion" -> 
  "13.3.0 for Microsoft Windows (64-bit) (June 3, 2023)", 
 "CacheDirectory" -> "D:\\ORBIT\\cache\\orbit_fixed_eh_cache", 
 "VerificationSubstitutions" -> {Scalar[M] -> M, 
   Scalar[\[Kappa]] -> \[Kappa], Scalar[\[Mu]bar2] -> \[Mu]bar2, 
   Sqrt[1/(M^2*\[Kappa]^2)] -> 1/(M*\[Kappa]), 
   Sqrt[1/(Scalar[M]^2*Scalar[\[Kappa]]^2)] -> 1/(M*\[Kappa]), 
   Sqrt[-(1/(M^2*\[Kappa]^2*(1 + Log[\[Mu]bar2/M^2])))] -> 
    Sqrt[2]/(M*\[Kappa]), 
   Sqrt[-(1/((1 + Log[\[Mu]bar2/M^2])*Scalar[M]^2*Scalar[\[Kappa]]^2))] -> 
    Sqrt[2]/(M*\[Kappa]), Log[\[Mu]bar2/M^2] -> -3/2, 
   Log[Scalar[\[Mu]bar2]/M^2] -> -3/2, Log[Scalar[\[Mu]bar2]/Scalar[M]^2] -> 
    -3/2, LambdaRefFinal -> 0, KappaRefFinal -> (4*Sqrt[3])/M}, 
 "VerificationAssumptions" -> M > 0 && \[Kappa] > 0 && \[Mu]bar2 > 0, 
 "AllChecksPassedQ" -> True, "StoredArtifactChecks" -> 
  <|"StoredD5ResultPresentQ" -> True, "StoredD6ResultPresentQ" -> True, 
   "StoredD5ExactMatchQ" -> True, "StoredD6ExactMatchQ" -> True, 
   "StoredD6VerifiedSupportedMatchQ" -> True, 
   "StoredD6QuadraticAnalysisPresentQ" -> True|>, 
 "D5" -> <|"BuildTimeSeconds" -> 373.5255443, "CanonicalNormalization" -> 
    <|"SucceededQ" -> True, "Reason" -> "OK", 
     "Factor" -> (M^2*\[Kappa]^2*(1 + Log[\[Mu]bar2/M^2]))/24, 
     "InputCoordinates" -> 
      {(-(M^2*\[Kappa]^2) - M^2*\[Kappa]^2*Log[\[Mu]bar2/M^2])/32 + 
        (5*(M^2*\[Kappa]^2 + M^2*\[Kappa]^2*Log[\[Mu]bar2/M^2]))/96, 
       (-2*M^2*\[Kappa]^2 - 3*M^2*\[Kappa]^2*Log[\[Mu]bar2/M^2])/24 + 
        (-2*M^2*\[Kappa]^2 - M^2*\[Kappa]^2*Log[\[Mu]bar2/M^2])/24 + 
        (M^2*\[Kappa]^2 + M^2*\[Kappa]^2*Log[\[Mu]bar2/M^2])/8, 
       (-(M^2*\[Kappa]^2) - M^2*\[Kappa]^2*Log[\[Mu]bar2/M^2])/8 + 
        (M^2*\[Kappa]^2 + M^2*\[Kappa]^2*Log[\[Mu]bar2/M^2])/6, 
       (-(M^2*\[Kappa]^2) - M^2*\[Kappa]^2*Log[\[Mu]bar2/M^2])/48}, 
     "FierzPauliCoordinates" -> {1/2, -1, 1, -1/2}, 
     "TargetQuadraticSign" -> -1|>, "MatchEquationCount" -> 15, 
   "MatchEquationsSatisfiedQ" -> True, "HasSymbolicSolutionQ" -> True, 
   "MatchInfo" -> <|"Variables" -> {Lmu, M, \[Kappa], LambdaRefFinal, 
       KappaRefFinal}, "Equations" -> 
      {Sqrt[6]*M^4*\[Kappa]*Sqrt[-(1/(M^2*\[Kappa]^2*(1 + Log[\[Mu]bar2/
                M^2])))]*(3 + 2*Log[\[Mu]bar2/M^2]) == 
        4*KappaRefFinal*LambdaRefFinal, KappaRefFinal^2*LambdaRefFinal + 
         9*M^2 + (KappaRefFinal^2*LambdaRefFinal + 6*M^2)*
          Log[\[Mu]bar2/M^2] == 0, KappaRefFinal^3*LambdaRefFinal + 
         Log[\[Mu]bar2/M^2]*(KappaRefFinal^3*LambdaRefFinal - 
           24*Sqrt[6]*M^2*\[Kappa]*Sqrt[-(1/(M^2*\[Kappa]^2*
                (1 + Log[\[Mu]bar2/M^2])))]) == 36*Sqrt[6]*M^2*\[Kappa]*
         Sqrt[-(1/(M^2*\[Kappa]^2*(1 + Log[\[Mu]bar2/M^2])))], 
       KappaRefFinal == 2*Sqrt[6]*\[Kappa]*
         Sqrt[-(1/(M^2*\[Kappa]^2*(1 + Log[\[Mu]bar2/M^2])))], 
       KappaRefFinal^4*LambdaRefFinal + 
         2*(-72 + KappaRefFinal^4*LambdaRefFinal)*Log[\[Mu]bar2/M^2] + 
         KappaRefFinal^4*LambdaRefFinal*Log[\[Mu]bar2/M^2]^2 == 216, 
       \[Kappa]*Sqrt[-(1/(M^2*\[Kappa]^2*(1 + Log[\[Mu]bar2/M^2])))]*
         (3 + 2*Log[\[Mu]bar2/M^2]) == 0, KappaRefFinal^5*LambdaRefFinal + 
         KappaRefFinal^5*LambdaRefFinal*Log[\[Mu]bar2/M^2]^2 + 
         432*Sqrt[6]*\[Kappa]*Sqrt[-(1/(M^2*\[Kappa]^2*(1 + Log[\[Mu]bar2/
                 M^2])))] + 2*Log[\[Mu]bar2/M^2]*
          (KappaRefFinal^5*LambdaRefFinal + 144*Sqrt[6]*\[Kappa]*
            Sqrt[-(1/(M^2*\[Kappa]^2*(1 + Log[\[Mu]bar2/M^2])))]) == 0, 
       KappaRefFinal^5*LambdaRefFinal + KappaRefFinal^5*LambdaRefFinal*
          Log[\[Mu]bar2/M^2]^2 + 144*Sqrt[6]*\[Kappa]*
          Sqrt[-(1/(M^2*\[Kappa]^2*(1 + Log[\[Mu]bar2/M^2])))] + 
         2*Log[\[Mu]bar2/M^2]*(KappaRefFinal^5*LambdaRefFinal + 
           48*Sqrt[6]*\[Kappa]*Sqrt[-(1/(M^2*\[Kappa]^2*(1 + 
                 Log[\[Mu]bar2/M^2])))]) == 0, 
       7*KappaRefFinal^5*LambdaRefFinal + 7*KappaRefFinal^5*LambdaRefFinal*
          Log[\[Mu]bar2/M^2]^2 + 432*Sqrt[6]*\[Kappa]*
          Sqrt[-(1/(M^2*\[Kappa]^2*(1 + Log[\[Mu]bar2/M^2])))] + 
         2*Log[\[Mu]bar2/M^2]*(7*KappaRefFinal^5*LambdaRefFinal + 
           144*Sqrt[6]*\[Kappa]*Sqrt[-(1/(M^2*\[Kappa]^2*(1 + 
                 Log[\[Mu]bar2/M^2])))]) == 0, 
       5*KappaRefFinal^5*LambdaRefFinal + 5*KappaRefFinal^5*LambdaRefFinal*
          Log[\[Mu]bar2/M^2]^2 + 144*Sqrt[6]*\[Kappa]*
          Sqrt[-(1/(M^2*\[Kappa]^2*(1 + Log[\[Mu]bar2/M^2])))] + 
         2*Log[\[Mu]bar2/M^2]*(5*KappaRefFinal^5*LambdaRefFinal + 
           48*Sqrt[6]*\[Kappa]*Sqrt[-(1/(M^2*\[Kappa]^2*(1 + 
                 Log[\[Mu]bar2/M^2])))]) == 0}, "SolveResult" -> 
      {{M -> ConditionalExpression[-(E^(3/4)*Sqrt[\[Mu]bar2]), 
          \[Kappa] > 0 && \[Mu]bar2 > 0], LambdaRefFinal -> 
         ConditionalExpression[0, \[Kappa] > 0 && \[Mu]bar2 > 0], 
        KappaRefFinal -> ConditionalExpression[
          (4*Sqrt[3]*Sqrt[\[Mu]bar2^(-1)])/E^(3/4), \[Kappa] > 0 && 
           \[Mu]bar2 > 0]}, {M -> ConditionalExpression[
          -(E^(3/4)*Sqrt[\[Mu]bar2]), \[Kappa] < 0 && \[Mu]bar2 > 0], 
        LambdaRefFinal -> ConditionalExpression[0, \[Kappa] < 0 && 
           \[Mu]bar2 > 0], KappaRefFinal -> ConditionalExpression[
          (-4*Sqrt[3]*Sqrt[\[Mu]bar2^(-1)])/E^(3/4), \[Kappa] < 0 && 
           \[Mu]bar2 > 0]}, {M -> ConditionalExpression[
          E^(3/4)*Sqrt[\[Mu]bar2], \[Kappa] > 0 && \[Mu]bar2 > 0], 
        LambdaRefFinal -> ConditionalExpression[0, \[Kappa] > 0 && 
           \[Mu]bar2 > 0], KappaRefFinal -> ConditionalExpression[
          (4*Sqrt[3]*Sqrt[\[Mu]bar2^(-1)])/E^(3/4), \[Kappa] > 0 && 
           \[Mu]bar2 > 0]}, {M -> ConditionalExpression[
          E^(3/4)*Sqrt[\[Mu]bar2], \[Kappa] < 0 && \[Mu]bar2 > 0], 
        LambdaRefFinal -> ConditionalExpression[0, \[Kappa] < 0 && 
           \[Mu]bar2 > 0], KappaRefFinal -> ConditionalExpression[
          (-4*Sqrt[3]*Sqrt[\[Mu]bar2^(-1)])/E^(3/4), \[Kappa] < 0 && 
           \[Mu]bar2 > 0]}}, "TranslatedSolveResult" -> 
      {{M -> ConditionalExpression[-(E^(3/4)*Sqrt[\[Mu]bar2]), 
          \[Kappa] > 0 && \[Mu]bar2 > 0], LambdaRefFinal -> 
         ConditionalExpression[0, \[Kappa] > 0 && \[Mu]bar2 > 0], 
        KappaRefFinal -> ConditionalExpression[
          (4*Sqrt[3]*Sqrt[\[Mu]bar2^(-1)])/E^(3/4), \[Kappa] > 0 && 
           \[Mu]bar2 > 0]}, {M -> ConditionalExpression[
          -(E^(3/4)*Sqrt[\[Mu]bar2]), \[Kappa] < 0 && \[Mu]bar2 > 0], 
        LambdaRefFinal -> ConditionalExpression[0, \[Kappa] < 0 && 
           \[Mu]bar2 > 0], KappaRefFinal -> ConditionalExpression[
          (-4*Sqrt[3]*Sqrt[\[Mu]bar2^(-1)])/E^(3/4), \[Kappa] < 0 && 
           \[Mu]bar2 > 0]}, {M -> ConditionalExpression[
          E^(3/4)*Sqrt[\[Mu]bar2], \[Kappa] > 0 && \[Mu]bar2 > 0], 
        LambdaRefFinal -> ConditionalExpression[0, \[Kappa] > 0 && 
           \[Mu]bar2 > 0], KappaRefFinal -> ConditionalExpression[
          (4*Sqrt[3]*Sqrt[\[Mu]bar2^(-1)])/E^(3/4), \[Kappa] > 0 && 
           \[Mu]bar2 > 0]}, {M -> ConditionalExpression[
          E^(3/4)*Sqrt[\[Mu]bar2], \[Kappa] < 0 && \[Mu]bar2 > 0], 
        LambdaRefFinal -> ConditionalExpression[0, \[Kappa] < 0 && 
           \[Mu]bar2 > 0], KappaRefFinal -> ConditionalExpression[
          (-4*Sqrt[3]*Sqrt[\[Mu]bar2^(-1)])/E^(3/4), \[Kappa] < 0 && 
           \[Mu]bar2 > 0]}}, "ReduceResult" -> \[Mu]bar2 > 0 && 
       ((M == E^(3/4)*Sqrt[\[Mu]bar2] && ((\[Kappa] > 0 && 
           LambdaRefFinal == 0 && KappaRefFinal == 4*Sqrt[3]*Sqrt[M^(-2)]) || 
          (\[Kappa] < 0 && LambdaRefFinal == 0 && KappaRefFinal == 
            -4*Sqrt[3]*Sqrt[M^(-2)]))) || (M == -(E^(3/4)*Sqrt[\[Mu]bar2]) && 
         ((\[Kappa] > 0 && LambdaRefFinal == 0 && KappaRefFinal == 
            4*Sqrt[3]*Sqrt[M^(-2)]) || (\[Kappa] < 0 && LambdaRefFinal == 
            0 && KappaRefFinal == -4*Sqrt[3]*Sqrt[M^(-2)])))), 
     "TranslatedReduceResult" -> \[Mu]bar2 > 0 && 
       ((M == E^(3/4)*Sqrt[\[Mu]bar2] && ((\[Kappa] > 0 && 
           LambdaRefFinal == 0 && KappaRefFinal == 4*Sqrt[3]*Sqrt[M^(-2)]) || 
          (\[Kappa] < 0 && LambdaRefFinal == 0 && KappaRefFinal == 
            -4*Sqrt[3]*Sqrt[M^(-2)]))) || (M == -(E^(3/4)*Sqrt[\[Mu]bar2]) && 
         ((\[Kappa] > 0 && LambdaRefFinal == 0 && KappaRefFinal == 
            4*Sqrt[3]*Sqrt[M^(-2)]) || (\[Kappa] < 0 && LambdaRefFinal == 
            0 && KappaRefFinal == -4*Sqrt[3]*Sqrt[M^(-2)])))), 
     "HasSolution" -> True|>, "SupportedSectorChecks" -> 
    <|{1, 0} -> <|"DifferenceZeroQ" -> True, "DifferenceCoordinatesZeroQ" -> 
        True|>, {2, 0} -> <|"DifferenceZeroQ" -> True, 
       "DifferenceCoordinatesZeroQ" -> True|>, 
     {2, 2} -> <|"DifferenceZeroQ" -> True, "DifferenceCoordinatesZeroQ" -> 
        True|>, {3, 0} -> <|"DifferenceZeroQ" -> True, 
       "DifferenceCoordinatesZeroQ" -> True|>, 
     {3, 2} -> <|"DifferenceZeroQ" -> True, "DifferenceCoordinatesZeroQ" -> 
        True|>, {4, 0} -> <|"DifferenceZeroQ" -> True, 
       "DifferenceCoordinatesZeroQ" -> True|>, 
     {5, 0} -> <|"DifferenceZeroQ" -> True, "DifferenceCoordinatesZeroQ" -> 
        True|>|>, "RedefinitionChecks" -> 
    <|{3, 2} -> <|"Sector" -> {3, 2}, "CoefficientDifference" -> 
        {0, 0, 0, 0}, "HasNonZeroCoefficientDifferenceQ" -> False, 
       "FieldRedefinition" -> 0, "ExplicitShiftExpression" -> 0, 
       "ExplicitShiftProjectionSucceededQ" -> True, 
       "ExplicitShiftProjectionResidual" -> 0, "ProjectedExplicitShift" -> 0, 
       "ProjectedIBPDifference" -> 0, "RedefinitionImageDifference" -> 0, 
       "ReducedDifference" -> 0, "ReducedDifferenceZeroQ" -> True, 
       "ProjectedDifferenceMatchesImageDifferenceQ" -> True, 
       "ExplicitShiftMatchesImageDifferenceQ" -> True, 
       "ExplicitShiftMatchesProjectedDifferenceQ" -> True, 
       "ExplicitShiftProjectionResidualZeroQ" -> True|>|>, 
   "AllSupportedDifferencesVanishQ" -> True, 
   "AllExplicitRedefinitionChecksPassQ" -> True|>, 
 "D6" -> <|"BuildTimeSeconds" -> 516.6189482, "CanonicalNormalization" -> 
    <|"SucceededQ" -> True, "Reason" -> "OK", 
     "Factor" -> (M^2*\[Kappa]^2*(1 + Log[\[Mu]bar2/M^2]))/24, 
     "InputCoordinates" -> 
      {(-(M^2*\[Kappa]^2) - M^2*\[Kappa]^2*Log[\[Mu]bar2/M^2])/32 + 
        (5*(M^2*\[Kappa]^2 + M^2*\[Kappa]^2*Log[\[Mu]bar2/M^2]))/96, 
       (-2*M^2*\[Kappa]^2 - 3*M^2*\[Kappa]^2*Log[\[Mu]bar2/M^2])/24 + 
        (-2*M^2*\[Kappa]^2 - M^2*\[Kappa]^2*Log[\[Mu]bar2/M^2])/24 + 
        (M^2*\[Kappa]^2 + M^2*\[Kappa]^2*Log[\[Mu]bar2/M^2])/8, 
       (-(M^2*\[Kappa]^2) - M^2*\[Kappa]^2*Log[\[Mu]bar2/M^2])/8 + 
        (M^2*\[Kappa]^2 + M^2*\[Kappa]^2*Log[\[Mu]bar2/M^2])/6, 
       (-(M^2*\[Kappa]^2) - M^2*\[Kappa]^2*Log[\[Mu]bar2/M^2])/48}, 
     "FierzPauliCoordinates" -> {1/2, -1, 1, -1/2}, 
     "TargetQuadraticSign" -> -1|>, "MatchEquationCount" -> 29, 
   "MatchEquationsSatisfiedQ" -> True, "StoredSupportedVerificationQ" -> 
    True, "InteractionSectorsRechecked" -> {{3, 2}, {4, 2}}, 
   "SupportedSectorChecks" -> <|{1, 0} -> <|"DifferenceZeroQ" -> True, 
       "DifferenceCoordinatesZeroQ" -> True|>, 
     {2, 0} -> <|"DifferenceZeroQ" -> True, "DifferenceCoordinatesZeroQ" -> 
        True|>, {2, 2} -> <|"DifferenceZeroQ" -> True, 
       "DifferenceCoordinatesZeroQ" -> True|>, 
     {3, 0} -> <|"DifferenceZeroQ" -> True, "DifferenceCoordinatesZeroQ" -> 
        True|>, {3, 2} -> <|"DifferenceZeroQ" -> True, 
       "DifferenceCoordinatesZeroQ" -> True|>, 
     {4, 0} -> <|"DifferenceZeroQ" -> True, "DifferenceCoordinatesZeroQ" -> 
        True|>, {4, 2} -> <|"DifferenceZeroQ" -> True, 
       "DifferenceCoordinatesZeroQ" -> True|>, 
     {5, 0} -> <|"DifferenceZeroQ" -> True, "DifferenceCoordinatesZeroQ" -> 
        True|>, {6, 0} -> <|"DifferenceZeroQ" -> True, 
       "DifferenceCoordinatesZeroQ" -> True|>|>, 
   "RedefinitionChecks" -> <|{3, 2} -> <|"Sector" -> {3, 2}, 
       "CoefficientDifference" -> {0, 0, 0, 0}, 
       "HasNonZeroCoefficientDifferenceQ" -> False, "FieldRedefinition" -> 0, 
       "ExplicitShiftExpression" -> 0, "ExplicitShiftProjectionSucceededQ" -> 
        True, "ExplicitShiftProjectionResidual" -> 0, 
       "ProjectedExplicitShift" -> 0, "ProjectedIBPDifference" -> 0, 
       "RedefinitionImageDifference" -> 0, "ReducedDifference" -> 0, 
       "ReducedDifferenceZeroQ" -> True, 
       "ProjectedDifferenceMatchesImageDifferenceQ" -> True, 
       "ExplicitShiftMatchesImageDifferenceQ" -> True, 
       "ExplicitShiftMatchesProjectedDifferenceQ" -> True, 
       "ExplicitShiftProjectionResidualZeroQ" -> True|>, 
     {4, 2} -> <|"Sector" -> {4, 2}, "CoefficientDifference" -> 
        {0, 0, 0, 0, 0, 0, 0}, "HasNonZeroCoefficientDifferenceQ" -> False, 
       "FieldRedefinition" -> 0, "ExplicitShiftExpression" -> 0, 
       "ExplicitShiftProjectionSucceededQ" -> True, 
       "ExplicitShiftProjectionResidual" -> 0, "ProjectedExplicitShift" -> 0, 
       "ProjectedIBPDifference" -> 0, "RedefinitionImageDifference" -> 0, 
       "ReducedDifference" -> 0, "ReducedDifferenceZeroQ" -> True, 
       "ProjectedDifferenceMatchesImageDifferenceQ" -> True, 
       "ExplicitShiftMatchesImageDifferenceQ" -> True, 
       "ExplicitShiftMatchesProjectedDifferenceQ" -> True, 
       "ExplicitShiftProjectionResidualZeroQ" -> True|>|>, 
   "QuadraticCompletion" -> <|"CurvatureCoefficients" -> 
      <|"R2" -> 0, "Ricci2" -> 0|>, "QuadraticRedefinitionCoefficients" -> 
      <|1 -> -3/(10*M^2), 2 -> -3/(20*M^2), 3 -> 3/(10*M^2)|>, 
     "FieldRedefinition" -> (-3*PD[-z$12011][PD[z$12011][h[u, v]]])/
        (20*M^2) - (3*eta[u, v]*PD[-z$12012][PD[-z$12011][
           h[z$12011, z$12012]]])/(10*M^2) + 
       (3*eta[u, v]*PD[-z$12012][PD[z$12012][h[z$12011, -z$12011]]])/
        (10*M^2), "ReconstructedImageCoordinates" -> 
      {9/(10*M^2), -9/(20*M^2), -3/(5*M^2), 3/(10*M^2), -3/(20*M^2)}, 
     "ProjectedDifferenceCoordinates" -> {9/(10*M^2), -9/(20*M^2), 
       -3/(5*M^2), 3/(10*M^2), -3/(20*M^2)}, 
     "ImageCoordinateReconstructionMatchesQ" -> True, 
     "QuadraticRedefinitionExpression" -> 
      (9*PD[c][PD[b][h[a, -a]]]*PD[-d][PD[d][h[-b, -c]]])/(10*M^2) - 
       (9*PD[-b][PD[b][h[a, -a]]]*PD[-d][PD[d][h[c, -c]]])/(20*M^2) - 
       (3*PD[-b][PD[-a][h[-c, -d]]]*PD[d][PD[c][h[a, b]]])/(5*M^2) + 
       (3*PD[-d][PD[-b][h[-a, -c]]]*PD[d][PD[c][h[a, b]]])/(10*M^2) - 
       (3*PD[-d][PD[-c][h[-a, -b]]]*PD[d][PD[c][h[a, b]]])/(20*M^2), 
     "ProjectedDifferenceExpression" -> 
      (9*PD[c][PD[b][h[a, -a]]]*PD[-d][PD[d][h[-b, -c]]])/(10*M^2) - 
       (9*PD[-b][PD[b][h[a, -a]]]*PD[-d][PD[d][h[c, -c]]])/(20*M^2) - 
       (3*PD[-b][PD[-a][h[-c, -d]]]*PD[d][PD[c][h[a, b]]])/(5*M^2) + 
       (3*PD[-d][PD[-b][h[-a, -c]]]*PD[d][PD[c][h[a, b]]])/(10*M^2) - 
       (3*PD[-d][PD[-c][h[-a, -b]]]*PD[d][PD[c][h[a, b]]])/(20*M^2), 
     "DecompositionHasSolutionQ" -> True, "ResidualExpression" -> 0, 
     "ResidualIsZeroQ" -> True, "PureQuadraticRedefinitionQ" -> True|>, 
   "AllSupportedDifferencesVanishQ" -> True, 
   "AllExplicitRedefinitionChecksPassQ" -> True|>|>
