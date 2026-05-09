<|
  "D5" -> <|
    "SupportedInteractionFieldRedefinitions" -> <|
      {3, 2} -> 0
    |>,
    "ManualCheckSummary" -> "After applying the solved witness substitutions, the supported d<=5 interaction-sector difference already vanishes exactly."
  |>,
  "D6" -> <|
    "SupportedInteractionFieldRedefinitions" -> <|
      {3, 2} -> 0,
      {4, 2} -> 0
    |>,
    "QuadraticFourDerivativeFieldRedefinition" ->
      (-3*PD[-i1][PD[i1][h[u, v]]])/(20*M^2) -
      (3*eta[u, v]*PD[-i2][PD[-i1][h[i1, i2]]])/(10*M^2) +
      (3*eta[u, v]*PD[-i2][PD[i2][h[i1, -i1]]])/(10*M^2),
    "QuadraticFourDerivativeImageCoordinates" ->
      {9/(10*M^2), -9/(20*M^2), -3/(5*M^2), 3/(10*M^2), -3/(20*M^2)},
    "QuadraticFourDerivativeProjectedDifferenceCoordinates" ->
      {9/(10*M^2), -9/(20*M^2), -3/(5*M^2), 3/(10*M^2), -3/(20*M^2)},
    "CurvatureSquaredCoefficients" -> <|
      "R2" -> 0,
      "Ricci2" -> 0
    |>,
    "ManualCheckSummary" -> "The supported interaction-sector differences vanish exactly. The only nontrivial d<=6 field redefinition is the quadratic {2,4} higher-derivative shift shown above."
  |>
|>
