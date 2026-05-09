<|"GeneratedOn" -> "2026-04-29 00:02:15", "KernelVersion" -> 
  "13.3.0 for Microsoft Windows (64-bit) (June 3, 2023)", 
 "InputSource" -> 
  "D:\\ORBIT\\examples\\left_only_uv_2_eft_6\\LEFT_only_uv_2_eft_6.mx", 
 "WitnessSubstitutions" -> {Scalar[M] -> M, Scalar[\[Kappa]] -> \[Kappa], 
   Scalar[\[Mu]bar2] -> \[Mu]bar2, Sqrt[1/(M^2*\[Kappa]^2)] -> 
    1/(M*\[Kappa]), Sqrt[1/(Scalar[M]^2*Scalar[\[Kappa]]^2)] -> 
    1/(M*\[Kappa]), Sqrt[-(1/(M^2*\[Kappa]^2*(1 + Log[\[Mu]bar2/M^2])))] -> 
    Sqrt[2]/(M*\[Kappa]), 
   Sqrt[-(1/((1 + Log[\[Mu]bar2/M^2])*Scalar[M]^2*Scalar[\[Kappa]]^2))] -> 
    Sqrt[2]/(M*\[Kappa]), Log[\[Mu]bar2/M^2] -> -3/2, 
   Log[Scalar[\[Mu]bar2]/M^2] -> -3/2, Log[Scalar[\[Mu]bar2]/Scalar[M]^2] -> 
    -3/2, LambdaRefFinal -> 0, KappaRefFinal -> (4*Sqrt[3])/M}, 
 "WitnessAssumptions" -> M > 0 && \[Kappa] > 0 && \[Mu]bar2 > 0, 
 "RelevantSectors" -> {{2, 2}, {2, 4}, {3, 2}, {4, 2}}, 
 "InputPipeline" -> <|"CanonicalNormalization" -> <|"SucceededQ" -> True, 
     "Reason" -> "OK", "Factor" -> -1/48*(M^2*\[Kappa]^2), 
     "InputCoordinates" -> {-1/96*(M^2*\[Kappa]^2), (M^2*\[Kappa]^2)/48, 
       -1/48*(M^2*\[Kappa]^2), (M^2*\[Kappa]^2)/96}, 
     "FierzPauliCoordinates" -> {1/2, -1, 1, -1/2}, 
     "TargetQuadraticSign" -> -1|>|>, 
 "BeforeAnyAdditionalFieldRedefinition" -> 
  <|"EFTAfterIBPOnlyBySector" -> 
    <|{2, 2} -> (-(PD[b][h[a, -a]]*(PD[-b][h[c, -c]] - 2*PD[-c][h[-b, c]])) + 
        (-2*PD[-b][h[-a, -c]] + PD[-c][h[-a, -b]])*PD[c][h[a, b]])/2, 
     {2, 4} -> (18*PD[c][PD[b][h[a, -a]]]*PD[-d][PD[d][h[-b, -c]]] - 
        9*PD[-b][PD[b][h[a, -a]]]*PD[-d][PD[d][h[c, -c]]] - 
        3*(4*PD[-b][PD[-a][h[-c, -d]]] - 2*PD[-d][PD[-b][h[-a, -c]]] + 
          PD[-d][PD[-c][h[-a, -b]]])*PD[d][PD[c][h[a, b]]])/(20*M^2), 
     {3, 2} -> (Sqrt[3]*(2*h[a, b]*(-(PD[-a][h[c, d]]*PD[-b][h[-c, -d]]) + 
           PD[-a][h[c, -c]]*PD[-b][h[d, -d]] + 2*PD[-c][h[d, -d]]*
            (-2*PD[-b][h[-a, c]] + PD[c][h[-a, -b]]) - 2*PD[c][h[-a, -b]]*
            PD[-d][h[-c, d]] + 2*(2*PD[-b][h[-c, -d]] + PD[-c][h[-b, -d]] - 
             PD[-d][h[-b, -c]])*PD[d][h[-a, c]]) + 
         h[a, -a]*(-(PD[-c][h[d, -d]]*PD[c][h[b, -b]]) + 
           2*(2*PD[-b][h[b, c]] + PD[c][h[b, -b]])*PD[-d][h[-c, d]] + 
           (-6*PD[-c][h[-b, -d]] + PD[-d][h[-b, -c]])*PD[d][h[b, c]])))/M, 
     {4, 2} -> (3*(8*h[-a, c]*h[a, b]*(PD[-b][h[d, e]]*PD[-c][h[-d, -e]] + 
           PD[-d][h[e, -e]]*(-2*PD[-c][h[-b, d]] + 5*PD[d][h[-b, -c]]) + 
           2*(PD[-c][h[-b, d]] - 2*PD[d][h[-b, -c]])*PD[-e][h[-d, e]] - 
           2*(PD[-c][h[-d, -e]] - PD[-d][h[-c, -e]] + PD[-e][h[-c, -d]])*
            PD[e][h[-b, d]]) + h[a, -a]*
          (4*h[b, c]*(-(PD[-b][h[d, e]]*PD[-c][h[-d, -e]]) + 
             PD[-d][h[e, -e]]*(2*PD[-c][h[-b, d]] - 5*PD[d][h[-b, -c]]) + 
             4*PD[d][h[-b, -c]]*PD[-e][h[-d, e]] + 2*(-PD[-d][h[-c, -e]] + 
               PD[-e][h[-c, -d]])*PD[e][h[-b, d]]) + 
           h[b, -b]*(PD[d][h[c, -c]]*(5*PD[-d][h[e, -e]] - 6*PD[-e][
                 h[-d, e]]) + (2*PD[-d][h[-c, -e]] - PD[-e][h[-c, -d]])*
              PD[e][h[c, d]])) + 2*h[a, b]*
          (4*h[c, d]*(2*PD[-c][h[-a, e]]*PD[-d][h[-b, -e]] - 
             PD[-c][h[-a, -b]]*PD[-d][h[e, -e]] - 2*PD[-b][h[-a, -c]]*
              PD[-e][h[-d, e]] + 2*PD[-d][h[-c, -e]]*(-PD[-b][h[-a, e]] + 
               PD[e][h[-a, -b]]) + (2*PD[-d][h[-b, -e]] - PD[-e][h[-b, -d]])*
              PD[e][h[-a, -c]]) + h[-a, -b]*(-5*PD[-d][h[e, -e]]*
              PD[d][h[c, -c]] + 2*(-2*PD[-c][h[c, d]] + 3*PD[d][h[c, -c]])*
              PD[-e][h[-d, e]] + (2*PD[-d][h[-c, -e]] + PD[-e][h[-c, -d]])*
              PD[e][h[c, d]]))))/M^2|>, "TheoryAfterIBPOnlyBySector" -> 
    <|{2, 2} -> (-(PD[b][h[a, -a]]*(PD[-b][h[c, -c]] - 2*PD[-c][h[-b, c]])) + 
        (-2*PD[-b][h[-a, -c]] + PD[-c][h[-a, -b]])*PD[c][h[a, b]])/2, 
     {2, 4} -> 0, {3, 2} -> 
      (Sqrt[3]*(2*h[a, b]*(-(PD[-a][h[c, d]]*PD[-b][h[-c, -d]]) + 
           PD[-a][h[c, -c]]*PD[-b][h[d, -d]] + 2*PD[-c][h[d, -d]]*
            (-2*PD[-b][h[-a, c]] + PD[c][h[-a, -b]]) - 2*PD[c][h[-a, -b]]*
            PD[-d][h[-c, d]] + 2*(2*PD[-b][h[-c, -d]] + PD[-c][h[-b, -d]] - 
             PD[-d][h[-b, -c]])*PD[d][h[-a, c]]) + 
         h[a, -a]*(-(PD[-c][h[d, -d]]*PD[c][h[b, -b]]) + 
           2*(2*PD[-b][h[b, c]] + PD[c][h[b, -b]])*PD[-d][h[-c, d]] + 
           (-6*PD[-c][h[-b, -d]] + PD[-d][h[-b, -c]])*PD[d][h[b, c]])))/M, 
     {4, 2} -> (3*(8*h[-a, c]*h[a, b]*(PD[-b][h[d, e]]*PD[-c][h[-d, -e]] - 
           PD[-b][h[d, -d]]*PD[-c][h[e, -e]] - 2*PD[-d][h[e, -e]]*
            (-2*PD[-c][h[-b, d]] + PD[d][h[-b, -c]]) + 
           2*(PD[-c][h[-b, d]] + PD[d][h[-b, -c]])*PD[-e][h[-d, e]] - 
           2*(3*PD[-c][h[-d, -e]] + PD[-d][h[-c, -e]] - PD[-e][h[-c, -d]])*
            PD[e][h[-b, d]]) + 2*h[a, b]*
          (4*h[c, d]*(2*PD[-c][h[-a, e]]*PD[-d][h[-b, -e]] - 
             2*(PD[-b][h[-a, e]]*PD[-d][h[-c, -e]] + PD[-c][h[-a, -b]]*
                PD[-d][h[e, -e]] + PD[-b][h[-a, -c]]*(-PD[-d][h[e, -e]] + 
                 PD[-e][h[-d, e]])) + (4*PD[-d][h[-c, -e]] - PD[-e][
                h[-c, -d]])*PD[e][h[-a, -b]] + (-2*PD[-d][h[-b, -e]] + PD[-e][
                h[-b, -d]])*PD[e][h[-a, -c]]) + h[-a, -b]*
            (PD[-d][h[e, -e]]*PD[d][h[c, -c]] - 2*(2*PD[-c][h[c, d]] + PD[d][
                h[c, -c]])*PD[-e][h[-d, e]] + (6*PD[-d][h[-c, -e]] - PD[-e][
                h[-c, -d]])*PD[e][h[c, d]])) + h[a, -a]*
          (4*h[b, c]*(-(PD[-b][h[d, e]]*PD[-c][h[-d, -e]]) + 
             PD[-b][h[d, -d]]*PD[-c][h[e, -e]] - 4*PD[-d][h[-b, d]]*
              PD[-e][h[-c, e]] + 2*PD[d][h[-b, -c]]*(PD[-d][h[e, -e]] - 
               PD[-e][h[-d, e]]) - 4*PD[-c][h[-b, d]]*(PD[-d][h[e, -e]] + 
               PD[-e][h[-d, e]]) + 2*(4*PD[-c][h[-d, -e]] + 3*PD[-d][
                 h[-c, -e]] - PD[-e][h[-c, -d]])*PD[e][h[-b, d]]) + 
           h[b, -b]*(-(PD[-d][h[e, -e]]*PD[d][h[c, -c]]) + 
             2*(2*PD[-c][h[c, d]] + PD[d][h[c, -c]])*PD[-e][h[-d, e]] + 
             (-6*PD[-d][h[-c, -e]] + PD[-e][h[-c, -d]])*PD[e][h[c, d]]))))/
       M^2|>, "DifferenceBySector" -> <|{2, 2} -> 0, 
     {2, 4} -> (18*PD[c][PD[b][h[a, -a]]]*PD[-d][PD[d][h[-b, -c]]] - 
        9*PD[-b][PD[b][h[a, -a]]]*PD[-d][PD[d][h[c, -c]]] - 
        3*(4*PD[-b][PD[-a][h[-c, -d]]] - 2*PD[-d][PD[-b][h[-a, -c]]] + 
          PD[-d][PD[-c][h[-a, -b]]])*PD[d][PD[c][h[a, b]]])/(20*M^2), 
     {3, 2} -> 0, {4, 2} -> 
      (6*(4*h[-a, c]*h[a, b]*(PD[-b][h[d, -d]]*PD[-c][h[e, -e]] + 
           PD[-d][h[e, -e]]*(-6*PD[-c][h[-b, d]] + 7*PD[d][h[-b, -c]]) - 
           6*PD[d][h[-b, -c]]*PD[-e][h[-d, e]] + 4*(PD[-c][h[-d, -e]] + 
             PD[-d][h[-c, -e]] - PD[-e][h[-c, -d]])*PD[e][h[-b, d]]) + 
         h[a, -a]*(2*h[b, c]*(-(PD[-b][h[d, -d]]*PD[-c][h[e, -e]]) + 
             4*PD[-d][h[-b, d]]*PD[-e][h[-c, e]] + PD[-c][h[-b, d]]*
              (6*PD[-d][h[e, -e]] + 4*PD[-e][h[-d, e]]) + PD[d][h[-b, -c]]*
              (-7*PD[-d][h[e, -e]] + 6*PD[-e][h[-d, e]]) + 
             4*(-2*(PD[-c][h[-d, -e]] + PD[-d][h[-c, -e]]) + PD[-e][
                h[-c, -d]])*PD[e][h[-b, d]]) + h[b, -b]*
            (3*PD[-d][h[e, -e]]*PD[d][h[c, -c]] - 2*(PD[-c][h[c, d]] + 2*
                PD[d][h[c, -c]])*PD[-e][h[-d, e]] + (4*PD[-d][h[-c, -e]] - 
               PD[-e][h[-c, -d]])*PD[e][h[c, d]])) + 
         2*h[a, b]*(2*h[c, d]*((-2*PD[-b][h[-a, -c]] + PD[-c][h[-a, -b]])*
              PD[-d][h[e, -e]] + (-2*PD[-d][h[-c, -e]] + PD[-e][h[-c, -d]])*
              PD[e][h[-a, -b]] + 2*(2*PD[-d][h[-b, -e]] - PD[-e][h[-b, -d]])*
              PD[e][h[-a, -c]]) + h[-a, -b]*(PD[d][h[c, -c]]*
              (-3*PD[-d][h[e, -e]] + 4*PD[-e][h[-d, e]]) + 
             (-2*PD[-d][h[-c, -e]] + PD[-e][h[-c, -d]])*PD[e][h[c, d]]))))/
       M^2|>, "DifferenceZeroQ" -> False|>, 
 "QuarticTwoDerivativeFieldRedefinition" -> <|"Sector" -> {4, 2}, 
   "CoefficientDifference" -> {48/M^2, -24/M^2, -12/M^2, 6/M^2, 0, 0, 0}, 
   "FieldRedefinition" -> (48*h[u, z$223678]*h[v, z$223679]*
       h[-z$223678, -z$223679])/M^2 - (12*h[u, v]*h[-z$223678, -z$223679]*
       h[z$223678, z$223679])/M^2 - (24*h[u, z$223678]*h[v, -z$223678]*
       h[z$223679, -z$223679])/M^2 + (6*h[u, v]*h[z$223678, -z$223678]*
       h[z$223679, -z$223679])/M^2, "IndependentDeltas" -> 
    {h[u, z$223678]*h[v, z$223679]*h[-z$223678, -z$223679], 
     h[u, z$223721]*h[v, -z$223721]*h[z$223722, -z$223722], 
     h[u, v]*h[-z$223771, -z$223772]*h[z$223771, z$223772], 
     h[u, v]*h[z$223814, -z$223814]*h[z$223815, -z$223815], 
     eta[u, v]*h[-z$223857, z$223859]*h[z$223857, z$223858]*
      h[-z$223858, -z$223859], eta[u, v]*h[z$223900, -z$223900]*
      h[-z$223901, -z$223902]*h[z$223901, z$223902], 
     eta[u, v]*h[z$223943, -z$223943]*h[z$223944, -z$223944]*
      h[z$223945, -z$223945]}, "ProjectedDifference" -> 
    (24*h[-a, c]*h[a, b]*PD[-b][h[d, -d]]*PD[-c][h[e, -e]])/M^2 - 
     (12*h[a, -a]*h[b, c]*PD[-b][h[d, -d]]*PD[-c][h[e, -e]])/M^2 - 
     (48*h[a, b]*h[c, d]*PD[-b][h[-a, -c]]*PD[-d][h[e, -e]])/M^2 + 
     (24*h[a, b]*h[c, d]*PD[-c][h[-a, -b]]*PD[-d][h[e, -e]])/M^2 - 
     (144*h[-a, c]*h[a, b]*PD[-c][h[-b, d]]*PD[-d][h[e, -e]])/M^2 + 
     (72*h[a, -a]*h[b, c]*PD[-c][h[-b, d]]*PD[-d][h[e, -e]])/M^2 + 
     (168*h[-a, c]*h[a, b]*PD[-d][h[e, -e]]*PD[d][h[-b, -c]])/M^2 - 
     (84*h[a, -a]*h[b, c]*PD[-d][h[e, -e]]*PD[d][h[-b, -c]])/M^2 - 
     (36*h[-a, -b]*h[a, b]*PD[-d][h[e, -e]]*PD[d][h[c, -c]])/M^2 + 
     (18*h[a, -a]*h[b, -b]*PD[-d][h[e, -e]]*PD[d][h[c, -c]])/M^2 + 
     (48*h[a, -a]*h[b, c]*PD[-d][h[-b, d]]*PD[-e][h[-c, e]])/M^2 + 
     (48*h[a, -a]*h[b, c]*PD[-c][h[-b, d]]*PD[-e][h[-d, e]])/M^2 - 
     (12*h[a, -a]*h[b, -b]*PD[-c][h[c, d]]*PD[-e][h[-d, e]])/M^2 - 
     (144*h[-a, c]*h[a, b]*PD[d][h[-b, -c]]*PD[-e][h[-d, e]])/M^2 + 
     (72*h[a, -a]*h[b, c]*PD[d][h[-b, -c]]*PD[-e][h[-d, e]])/M^2 + 
     (48*h[-a, -b]*h[a, b]*PD[d][h[c, -c]]*PD[-e][h[-d, e]])/M^2 - 
     (24*h[a, -a]*h[b, -b]*PD[d][h[c, -c]]*PD[-e][h[-d, e]])/M^2 - 
     (48*h[a, b]*h[c, d]*PD[-d][h[-c, -e]]*PD[e][h[-a, -b]])/M^2 + 
     (24*h[a, b]*h[c, d]*PD[-e][h[-c, -d]]*PD[e][h[-a, -b]])/M^2 + 
     (96*h[a, b]*h[c, d]*PD[-d][h[-b, -e]]*PD[e][h[-a, -c]])/M^2 - 
     (48*h[a, b]*h[c, d]*PD[-e][h[-b, -d]]*PD[e][h[-a, -c]])/M^2 + 
     (96*h[-a, c]*h[a, b]*PD[-c][h[-d, -e]]*PD[e][h[-b, d]])/M^2 - 
     (96*h[a, -a]*h[b, c]*PD[-c][h[-d, -e]]*PD[e][h[-b, d]])/M^2 + 
     (96*h[-a, c]*h[a, b]*PD[-d][h[-c, -e]]*PD[e][h[-b, d]])/M^2 - 
     (96*h[a, -a]*h[b, c]*PD[-d][h[-c, -e]]*PD[e][h[-b, d]])/M^2 - 
     (96*h[-a, c]*h[a, b]*PD[-e][h[-c, -d]]*PD[e][h[-b, d]])/M^2 + 
     (48*h[a, -a]*h[b, c]*PD[-e][h[-c, -d]]*PD[e][h[-b, d]])/M^2 - 
     (24*h[-a, -b]*h[a, b]*PD[-d][h[-c, -e]]*PD[e][h[c, d]])/M^2 + 
     (24*h[a, -a]*h[b, -b]*PD[-d][h[-c, -e]]*PD[e][h[c, d]])/M^2 + 
     (12*h[-a, -b]*h[a, b]*PD[-e][h[-c, -d]]*PD[e][h[c, d]])/M^2 - 
     (6*h[a, -a]*h[b, -b]*PD[-e][h[-c, -d]]*PD[e][h[c, d]])/M^2, 
   "ProjectedDifferenceCoordinates" -> {0, 0, 24/M^2, -12/M^2, 0, 0, -48/M^2, 
     24/M^2, -144/M^2, 72/M^2, 168/M^2, -84/M^2, -36/M^2, 18/M^2, 48/M^2, 0, 
     0, 48/M^2, 0, -12/M^2, -144/M^2, 72/M^2, 48/M^2, -24/M^2, -48/M^2, 
     24/M^2, 96/M^2, -48/M^2, 96/M^2, -96/M^2, 96/M^2, -96/M^2, -96/M^2, 
     48/M^2, -24/M^2, 24/M^2, 12/M^2, -6/M^2}, "ProjectedShiftImage" -> 
    (24*h[-a, c]*h[a, b]*PD[-b][h[d, -d]]*PD[-c][h[e, -e]])/M^2 - 
     (12*h[a, -a]*h[b, c]*PD[-b][h[d, -d]]*PD[-c][h[e, -e]])/M^2 - 
     (48*h[a, b]*h[c, d]*PD[-b][h[-a, -c]]*PD[-d][h[e, -e]])/M^2 + 
     (24*h[a, b]*h[c, d]*PD[-c][h[-a, -b]]*PD[-d][h[e, -e]])/M^2 - 
     (144*h[-a, c]*h[a, b]*PD[-c][h[-b, d]]*PD[-d][h[e, -e]])/M^2 + 
     (72*h[a, -a]*h[b, c]*PD[-c][h[-b, d]]*PD[-d][h[e, -e]])/M^2 + 
     (168*h[-a, c]*h[a, b]*PD[-d][h[e, -e]]*PD[d][h[-b, -c]])/M^2 - 
     (84*h[a, -a]*h[b, c]*PD[-d][h[e, -e]]*PD[d][h[-b, -c]])/M^2 - 
     (36*h[-a, -b]*h[a, b]*PD[-d][h[e, -e]]*PD[d][h[c, -c]])/M^2 + 
     (18*h[a, -a]*h[b, -b]*PD[-d][h[e, -e]]*PD[d][h[c, -c]])/M^2 + 
     (48*h[a, -a]*h[b, c]*PD[-d][h[-b, d]]*PD[-e][h[-c, e]])/M^2 + 
     (48*h[a, -a]*h[b, c]*PD[-c][h[-b, d]]*PD[-e][h[-d, e]])/M^2 - 
     (12*h[a, -a]*h[b, -b]*PD[-c][h[c, d]]*PD[-e][h[-d, e]])/M^2 - 
     (144*h[-a, c]*h[a, b]*PD[d][h[-b, -c]]*PD[-e][h[-d, e]])/M^2 + 
     (72*h[a, -a]*h[b, c]*PD[d][h[-b, -c]]*PD[-e][h[-d, e]])/M^2 + 
     (48*h[-a, -b]*h[a, b]*PD[d][h[c, -c]]*PD[-e][h[-d, e]])/M^2 - 
     (24*h[a, -a]*h[b, -b]*PD[d][h[c, -c]]*PD[-e][h[-d, e]])/M^2 - 
     (48*h[a, b]*h[c, d]*PD[-d][h[-c, -e]]*PD[e][h[-a, -b]])/M^2 + 
     (24*h[a, b]*h[c, d]*PD[-e][h[-c, -d]]*PD[e][h[-a, -b]])/M^2 + 
     (96*h[a, b]*h[c, d]*PD[-d][h[-b, -e]]*PD[e][h[-a, -c]])/M^2 - 
     (48*h[a, b]*h[c, d]*PD[-e][h[-b, -d]]*PD[e][h[-a, -c]])/M^2 + 
     (96*h[-a, c]*h[a, b]*PD[-c][h[-d, -e]]*PD[e][h[-b, d]])/M^2 - 
     (96*h[a, -a]*h[b, c]*PD[-c][h[-d, -e]]*PD[e][h[-b, d]])/M^2 + 
     (96*h[-a, c]*h[a, b]*PD[-d][h[-c, -e]]*PD[e][h[-b, d]])/M^2 - 
     (96*h[a, -a]*h[b, c]*PD[-d][h[-c, -e]]*PD[e][h[-b, d]])/M^2 - 
     (96*h[-a, c]*h[a, b]*PD[-e][h[-c, -d]]*PD[e][h[-b, d]])/M^2 + 
     (48*h[a, -a]*h[b, c]*PD[-e][h[-c, -d]]*PD[e][h[-b, d]])/M^2 - 
     (24*h[-a, -b]*h[a, b]*PD[-d][h[-c, -e]]*PD[e][h[c, d]])/M^2 + 
     (24*h[a, -a]*h[b, -b]*PD[-d][h[-c, -e]]*PD[e][h[c, d]])/M^2 + 
     (12*h[-a, -b]*h[a, b]*PD[-e][h[-c, -d]]*PD[e][h[c, d]])/M^2 - 
     (6*h[a, -a]*h[b, -b]*PD[-e][h[-c, -d]]*PD[e][h[c, d]])/M^2, 
   "ProjectedShiftCoordinates" -> {0, 0, 24/M^2, -12/M^2, 0, 0, -48/M^2, 
     24/M^2, -144/M^2, 72/M^2, 168/M^2, -84/M^2, -36/M^2, 18/M^2, 48/M^2, 0, 
     0, 48/M^2, 0, -12/M^2, -144/M^2, 72/M^2, 48/M^2, -24/M^2, -48/M^2, 
     24/M^2, 96/M^2, -48/M^2, 96/M^2, -96/M^2, 96/M^2, -96/M^2, -96/M^2, 
     48/M^2, -24/M^2, 24/M^2, 12/M^2, -6/M^2}, 
   "ProjectedShiftMatchesDifferenceQ" -> True, 
   "ProjectedShiftResidualZeroQ" -> True|>, 
 "AfterQuarticTwoDerivativeFieldRedefinition" -> 
  <|"ShiftedEFTBySector" -> 
    <|{2, 2} -> (-(PD[b][h[a, -a]]*(PD[-b][h[c, -c]] - 2*PD[-c][h[-b, c]])) + 
        (-2*PD[-b][h[-a, -c]] + PD[-c][h[-a, -b]])*PD[c][h[a, b]])/2, 
     {2, 4} -> (18*PD[c][PD[b][h[a, -a]]]*PD[-d][PD[d][h[-b, -c]]] - 
        9*PD[-b][PD[b][h[a, -a]]]*PD[-d][PD[d][h[c, -c]]] - 
        3*(4*PD[-b][PD[-a][h[-c, -d]]] - 2*PD[-d][PD[-b][h[-a, -c]]] + 
          PD[-d][PD[-c][h[-a, -b]]])*PD[d][PD[c][h[a, b]]])/(20*M^2), 
     {3, 2} -> (Sqrt[3]*(2*h[a, b]*(-(PD[-a][h[c, d]]*PD[-b][h[-c, -d]]) + 
           PD[-a][h[c, -c]]*PD[-b][h[d, -d]] + 2*PD[-c][h[d, -d]]*
            (-2*PD[-b][h[-a, c]] + PD[c][h[-a, -b]]) - 2*PD[c][h[-a, -b]]*
            PD[-d][h[-c, d]] + 2*(2*PD[-b][h[-c, -d]] + PD[-c][h[-b, -d]] - 
             PD[-d][h[-b, -c]])*PD[d][h[-a, c]]) + 
         h[a, -a]*(-(PD[-c][h[d, -d]]*PD[c][h[b, -b]]) + 
           2*(2*PD[-b][h[b, c]] + PD[c][h[b, -b]])*PD[-d][h[-c, d]] + 
           (-6*PD[-c][h[-b, -d]] + PD[-d][h[-b, -c]])*PD[d][h[b, c]])))/M, 
     {4, 2} -> (3*(8*h[-a, c]*h[a, b]*(PD[-b][h[d, e]]*PD[-c][h[-d, -e]] - 
           PD[-b][h[d, -d]]*PD[-c][h[e, -e]] - 2*PD[-d][h[e, -e]]*
            (-2*PD[-c][h[-b, d]] + PD[d][h[-b, -c]]) + 
           2*(PD[-c][h[-b, d]] + PD[d][h[-b, -c]])*PD[-e][h[-d, e]] - 
           2*(3*PD[-c][h[-d, -e]] + PD[-d][h[-c, -e]] - PD[-e][h[-c, -d]])*
            PD[e][h[-b, d]]) + 2*h[a, b]*
          (4*h[c, d]*(2*PD[-c][h[-a, e]]*PD[-d][h[-b, -e]] - 
             2*(PD[-b][h[-a, e]]*PD[-d][h[-c, -e]] + PD[-c][h[-a, -b]]*
                PD[-d][h[e, -e]] + PD[-b][h[-a, -c]]*(-PD[-d][h[e, -e]] + 
                 PD[-e][h[-d, e]])) + (4*PD[-d][h[-c, -e]] - PD[-e][
                h[-c, -d]])*PD[e][h[-a, -b]] + (-2*PD[-d][h[-b, -e]] + PD[-e][
                h[-b, -d]])*PD[e][h[-a, -c]]) + h[-a, -b]*
            (PD[-d][h[e, -e]]*PD[d][h[c, -c]] - 2*(2*PD[-c][h[c, d]] + PD[d][
                h[c, -c]])*PD[-e][h[-d, e]] + (6*PD[-d][h[-c, -e]] - PD[-e][
                h[-c, -d]])*PD[e][h[c, d]])) + h[a, -a]*
          (4*h[b, c]*(-(PD[-b][h[d, e]]*PD[-c][h[-d, -e]]) + 
             PD[-b][h[d, -d]]*PD[-c][h[e, -e]] - 4*PD[-d][h[-b, d]]*
              PD[-e][h[-c, e]] + 2*PD[d][h[-b, -c]]*(PD[-d][h[e, -e]] - 
               PD[-e][h[-d, e]]) - 4*PD[-c][h[-b, d]]*(PD[-d][h[e, -e]] + 
               PD[-e][h[-d, e]]) + 2*(4*PD[-c][h[-d, -e]] + 3*PD[-d][
                 h[-c, -e]] - PD[-e][h[-c, -d]])*PD[e][h[-b, d]]) + 
           h[b, -b]*(-(PD[-d][h[e, -e]]*PD[d][h[c, -c]]) + 
             2*(2*PD[-c][h[c, d]] + PD[d][h[c, -c]])*PD[-e][h[-d, e]] + 
             (-6*PD[-d][h[-c, -e]] + PD[-e][h[-c, -d]])*PD[e][h[c, d]]))))/
       M^2|>, "DifferenceBySector" -> <|{2, 2} -> 0, 
     {2, 4} -> (18*PD[c][PD[b][h[a, -a]]]*PD[-d][PD[d][h[-b, -c]]] - 
        9*PD[-b][PD[b][h[a, -a]]]*PD[-d][PD[d][h[c, -c]]] - 
        3*(4*PD[-b][PD[-a][h[-c, -d]]] - 2*PD[-d][PD[-b][h[-a, -c]]] + 
          PD[-d][PD[-c][h[-a, -b]]])*PD[d][PD[c][h[a, b]]])/(20*M^2), 
     {3, 2} -> 0, {4, 2} -> 0|>, "DifferenceZeroQ" -> False|>, 
 "QuadraticFourDerivativeFieldRedefinition" -> 
  <|"Sector" -> {2, 4}, "FieldRedefinition" -> 
    (-3*PD[-i1][PD[i1][h[u, v]]])/(20*M^2) - 
     (3*eta[u, v]*PD[-i2][PD[-i1][h[i1, i2]]])/(10*M^2) + 
     (3*eta[u, v]*PD[-i2][PD[i2][h[i1, -i1]]])/(10*M^2), 
   "ProjectedDifference" -> 
    (9*PD[c][PD[b][h[a, -a]]]*PD[-d][PD[d][h[-b, -c]]])/(10*M^2) - 
     (9*PD[-b][PD[b][h[a, -a]]]*PD[-d][PD[d][h[c, -c]]])/(20*M^2) - 
     (3*PD[-b][PD[-a][h[-c, -d]]]*PD[d][PD[c][h[a, b]]])/(5*M^2) + 
     (3*PD[-d][PD[-b][h[-a, -c]]]*PD[d][PD[c][h[a, b]]])/(10*M^2) - 
     (3*PD[-d][PD[-c][h[-a, -b]]]*PD[d][PD[c][h[a, b]]])/(20*M^2), 
   "ProjectedDifferenceCoordinates" -> {9/(10*M^2), -9/(20*M^2), -3/(5*M^2), 
     3/(10*M^2), -3/(20*M^2)}, "ProjectedShiftImage" -> 
    (9*PD[c][PD[b][h[a, -a]]]*PD[-d][PD[d][h[-b, -c]]])/(10*M^2) - 
     (9*PD[-b][PD[b][h[a, -a]]]*PD[-d][PD[d][h[c, -c]]])/(20*M^2) - 
     (3*PD[-b][PD[-a][h[-c, -d]]]*PD[d][PD[c][h[a, b]]])/(5*M^2) + 
     (3*PD[-d][PD[-b][h[-a, -c]]]*PD[d][PD[c][h[a, b]]])/(10*M^2) - 
     (3*PD[-d][PD[-c][h[-a, -b]]]*PD[d][PD[c][h[a, b]]])/(20*M^2), 
   "ProjectedShiftCoordinates" -> {9/(10*M^2), -9/(20*M^2), -3/(5*M^2), 
     3/(10*M^2), -3/(20*M^2)}, "ProjectedShiftMatchesDifferenceQ" -> True, 
   "CoordinateResidualZeroQ" -> True|>, 
 "AfterQuarticTwoDerivativeAndQuadraticFourDerivativeFieldRedefinitions" -> 
  <|"ShiftedEFTBySector" -> 
    <|{2, 2} -> (-(PD[b][h[a, -a]]*(PD[-b][h[c, -c]] - 2*PD[-c][h[-b, c]])) + 
        (-2*PD[-b][h[-a, -c]] + PD[-c][h[-a, -b]])*PD[c][h[a, b]])/2, 
     {2, 4} -> 0, {3, 2} -> 
      (Sqrt[3]*(2*h[a, b]*(-(PD[-a][h[c, d]]*PD[-b][h[-c, -d]]) + 
           PD[-a][h[c, -c]]*PD[-b][h[d, -d]] + 2*PD[-c][h[d, -d]]*
            (-2*PD[-b][h[-a, c]] + PD[c][h[-a, -b]]) - 2*PD[c][h[-a, -b]]*
            PD[-d][h[-c, d]] + 2*(2*PD[-b][h[-c, -d]] + PD[-c][h[-b, -d]] - 
             PD[-d][h[-b, -c]])*PD[d][h[-a, c]]) + 
         h[a, -a]*(-(PD[-c][h[d, -d]]*PD[c][h[b, -b]]) + 
           2*(2*PD[-b][h[b, c]] + PD[c][h[b, -b]])*PD[-d][h[-c, d]] + 
           (-6*PD[-c][h[-b, -d]] + PD[-d][h[-b, -c]])*PD[d][h[b, c]])))/M, 
     {4, 2} -> (3*(8*h[-a, c]*h[a, b]*(PD[-b][h[d, e]]*PD[-c][h[-d, -e]] - 
           PD[-b][h[d, -d]]*PD[-c][h[e, -e]] - 2*PD[-d][h[e, -e]]*
            (-2*PD[-c][h[-b, d]] + PD[d][h[-b, -c]]) + 
           2*(PD[-c][h[-b, d]] + PD[d][h[-b, -c]])*PD[-e][h[-d, e]] - 
           2*(3*PD[-c][h[-d, -e]] + PD[-d][h[-c, -e]] - PD[-e][h[-c, -d]])*
            PD[e][h[-b, d]]) + 2*h[a, b]*
          (4*h[c, d]*(2*PD[-c][h[-a, e]]*PD[-d][h[-b, -e]] - 
             2*(PD[-b][h[-a, e]]*PD[-d][h[-c, -e]] + PD[-c][h[-a, -b]]*
                PD[-d][h[e, -e]] + PD[-b][h[-a, -c]]*(-PD[-d][h[e, -e]] + 
                 PD[-e][h[-d, e]])) + (4*PD[-d][h[-c, -e]] - PD[-e][
                h[-c, -d]])*PD[e][h[-a, -b]] + (-2*PD[-d][h[-b, -e]] + PD[-e][
                h[-b, -d]])*PD[e][h[-a, -c]]) + h[-a, -b]*
            (PD[-d][h[e, -e]]*PD[d][h[c, -c]] - 2*(2*PD[-c][h[c, d]] + PD[d][
                h[c, -c]])*PD[-e][h[-d, e]] + (6*PD[-d][h[-c, -e]] - PD[-e][
                h[-c, -d]])*PD[e][h[c, d]])) + h[a, -a]*
          (4*h[b, c]*(-(PD[-b][h[d, e]]*PD[-c][h[-d, -e]]) + 
             PD[-b][h[d, -d]]*PD[-c][h[e, -e]] - 4*PD[-d][h[-b, d]]*
              PD[-e][h[-c, e]] + 2*PD[d][h[-b, -c]]*(PD[-d][h[e, -e]] - 
               PD[-e][h[-d, e]]) - 4*PD[-c][h[-b, d]]*(PD[-d][h[e, -e]] + 
               PD[-e][h[-d, e]]) + 2*(4*PD[-c][h[-d, -e]] + 3*PD[-d][
                 h[-c, -e]] - PD[-e][h[-c, -d]])*PD[e][h[-b, d]]) + 
           h[b, -b]*(-(PD[-d][h[e, -e]]*PD[d][h[c, -c]]) + 
             2*(2*PD[-c][h[c, d]] + PD[d][h[c, -c]])*PD[-e][h[-d, e]] + 
             (-6*PD[-d][h[-c, -e]] + PD[-e][h[-c, -d]])*PD[e][h[c, d]]))))/
       M^2|>, "DifferenceBySector" -> <|{2, 2} -> 0, {2, 4} -> 0, 
     {3, 2} -> 0, {4, 2} -> 0|>, "DifferenceZeroQ" -> True|>|>
