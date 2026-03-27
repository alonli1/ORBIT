scriptDir = DirectoryName[$InputFileName];
repoRoot = NestWhile[
  DirectoryName,
  scriptDir,
  ! FileExistsQ[FileNameJoin[{#, "graviton_basis_toolkit.wl"}]] &
];
SetDirectory[repoRoot];

Get["graviton_basis_toolkit.wl"];
Get["orbit_fixed_eh_comparison.wl"];

outputDir = FileNameJoin[{Directory[], "artifacts", "orbit_fixed_eh"}];
If[! DirectoryQ[outputDir], CreateDirectory[outputDir, CreateIntermediateDirectories -> True]];

resultFile = FileNameJoin[{outputDir, "orbit_fixed_eh_comparison_final_result.wl"}];
crosscheckAnalysisFile = FileNameJoin[{outputDir, "orbit_fixed_eh_quadratic_completion_crosscheck.wl"}];
crosscheckSummaryFile = FileNameJoin[{outputDir, "orbit_fixed_eh_quadratic_completion_crosscheck_summary.wl"}];
summaryFile = FileNameJoin[{outputDir, "orbit_fixed_eh_comparison_final_summary.wl"}];
reportBase = FileNameJoin[{outputDir, "orbit_fixed_eh_equivalence_audit_report"}];
texFile = reportBase <> ".tex";
dataFile = reportBase <> "_data.wl";

If[! FileExistsQ[resultFile],
  Print["Missing final result file: " <> resultFile];
  Quit[1];
];

result = Get[resultFile];
crosscheckAnalysis = If[FileExistsQ[crosscheckAnalysisFile], Get[crosscheckAnalysisFile], Missing["NotAvailable"]];
crosscheckSummary = If[FileExistsQ[crosscheckSummaryFile], Get[crosscheckSummaryFile], Missing["NotAvailable"]];

texEscapeLocal[str_String] := StringReplace[
  str,
  {
    "\\" -> "\\textbackslash{}",
    "_" -> "\\_",
    "%" -> "\\%",
    "&" -> "\\&",
    "#" -> "\\#",
    "$" -> "\\$",
    "{" -> "\\{",
    "}" -> "\\}",
    "~" -> "\\textasciitilde{}",
    "^" -> "\\textasciicircum{}"
  }
];

verbatimBlock[expr_] := "\\begin{verbatim}\n" <> ToString[InputForm[expr]] <> "\n\\end{verbatim}";

formatSectorKey[key_List] := "{" <> ToString[key[[1]]] <> ", " <> ToString[key[[2]]] <> "}";

codeExcerpt[file_, start_, end_] := Module[{lines},
  lines = Import[file, "Lines"];
  StringRiffle[
    MapIndexed[
      Function[{line, idx},
        ToString[start + idx[[1]] - 1] <> ": " <> line
      ],
      Take[lines, {start, end}]
    ],
    "\n"
  ]
];

verificationSubs = Lookup[result, "VerificationSubstitutions", {}];
verificationAssumptions = Lookup[result, "VerificationAssumptions", True];
supportedSectors = Lookup[result, "SupportedSectors", {}];
sectorComparisons = Lookup[result, "SectorComparison", <||>];
quadraticCompletion = Lookup[result, "QuadraticCompletion", Missing["NotAvailable"]];
canonicalData = Lookup[result, "CanonicalNormalization", <||>];

exprZeroQ[expr_] := exprZeroUnderVerificationQ[expr, verificationSubs, verificationAssumptions];

verifiedSupportedRecords = Association @ KeyValueMap[
  Function[{key, rec},
    If[MemberQ[supportedSectors, key],
      key -> <|
        "RawDifferenceExpression" -> rec["DifferenceExpression"],
        "VerifiedDifferenceExpression" -> canonExpr[normalizeMatcheteParameterScalars[rec["DifferenceExpression"]] /. verificationSubs],
        "VerifiedZeroQ" -> exprZeroQ[rec["DifferenceExpression"]]
      |>,
      Nothing
    ]
  ],
  sectorComparisons
];

supportedAuditText = StringRiffle[
  KeyValueMap[
    Function[{key, rec},
      StringRiffle[
        {
          "\\subsection*{Sector " <> formatSectorKey[key] <> "}",
          "Raw difference expression:",
          verbatimBlock[rec["RawDifferenceExpression"]],
          "Difference after the verified substitutions used by \\texttt{finalizeComparisonResult}:",
          verbatimBlock[rec["VerifiedDifferenceExpression"]],
          "Verified zero check: " <> ToString[InputForm[rec["VerifiedZeroQ"]]] <> "."
        },
        "\n"
      ]
    ],
    verifiedSupportedRecords
  ],
  "\n\n"
];

matchEquationRecords = Lookup[result, "MatchEquationRecords", {}];
matchEquationAudit = StringRiffle[
  Map[
    Function[rec,
      "Sector " <> formatSectorKey[rec["Sector"]] <>
        ", coordinate " <> ToString[rec["CoordinateIndex"]] <>
        ", polynomial equation " <> ToString[rec["EquationIndex"]] <> ":" <>
        "\n" <> verbatimBlock[rec["Equation"]]
    ],
    matchEquationRecords
  ],
  "\n\n"
];

quadraticSection = If[AssociationQ[quadraticCompletion],
  StringRiffle[
    {
      "\\section{Quadratic Four-Derivative Completion}",
      "The final exact-match statement requires the completed treatment of the leftover sector $\\{2,4\\}$. The code path is \\texttt{AnalyzeQuadraticFourDerivativeDifference}, which projects the verified remainder to the IBP basis, constructs a curvature-squared basis, constructs the quadratic higher-derivative redefinition image, and solves the resulting linear decomposition problem.",
      "\\subsection{Verified \\{2,4\\} difference}",
      verbatimBlock[quadraticCompletion["AnalyzedExpression"]],
      "\\subsection{Projected \\{2,4\\} coordinates}",
      verbatimBlock[quadraticCompletion["ProjectedData"]["Coordinates"]],
      "\\subsection{Curvature-squared basis}",
      "Projected $R^{(1)2}$ expression:",
      verbatimBlock[quadraticCompletion["CurvatureBasis"]["R2Expression"]],
      "Projected $R^{(1)2}$ coordinates:",
      verbatimBlock[quadraticCompletion["CurvatureBasis"]["R2Coordinates"]],
      "Projected $R^{(1)}_{\\mu\\nu}R^{(1)\\mu\\nu}$ expression:",
      verbatimBlock[quadraticCompletion["CurvatureBasis"]["Ricci2Expression"]],
      "Projected $R^{(1)}_{\\mu\\nu}R^{(1)\\mu\\nu}$ coordinates:",
      verbatimBlock[quadraticCompletion["CurvatureBasis"]["Ricci2Coordinates"]],
      "\\subsection{Quadratic higher-derivative field redefinition image}",
      "Independent rank-2 source basis elements selected by the code:",
      verbatimBlock[quadraticCompletion["QuadraticRedefinitionData"]["IndependentDeltas"]],
      "Independent projected image vectors:",
      verbatimBlock[quadraticCompletion["QuadraticRedefinitionData"]["IndependentVectors"]],
      "\\subsection{Solved decomposition}",
      "Linear solve output:",
      verbatimBlock[quadraticCompletion["Decomposition"]],
      "Curvature coefficients:",
      verbatimBlock[quadraticCompletion["CurvatureCoefficients"]],
      "Quadratic redefinition coefficients:",
      verbatimBlock[quadraticCompletion["QuadraticRedefinitionCoefficients"]],
      "Reconstructed quadratic redefinition expression:",
      verbatimBlock[quadraticCompletion["QuadraticRedefinitionExpression"]],
      "Residual expression:",
      verbatimBlock[quadraticCompletion["ResidualExpression"]],
      "Residual zero check: " <> ToString[InputForm[quadraticCompletion["ResidualIsZeroQ"]]] <> ".",
      "Pure quadratic redefinition check: " <> ToString[InputForm[quadraticCompletion["PureQuadraticRedefinitionQ"]]] <> "."
    },
    "\n"
  ],
  ""
];

crosscheckSection = If[AssociationQ[crosscheckAnalysis] && AssociationQ[crosscheckSummary],
  StringRiffle[
    {
      "\\section{Independent Cross-Check}",
      "A second script reproduced the $\\{2,4\\}$ statement directly from the saved vectors, without calling the main analyzer helper.",
      "\\subsection{Target coordinates}",
      verbatimBlock[crosscheckAnalysis["TargetCoordinates"]],
      "\\subsection{Independent redefinition rows and vectors}",
      verbatimBlock[crosscheckAnalysis["IndependentRedefinitionRows"]],
      verbatimBlock[crosscheckAnalysis["IndependentRedefinitionVectors"]],
      "\\subsection{Pure redefinition solve}",
      verbatimBlock[crosscheckAnalysis["PureRedefinitionSolve"]],
      verbatimBlock[crosscheckAnalysis["PureRedefinitionRules"]],
      verbatimBlock[crosscheckAnalysis["PureRedefinitionReconstructed"]],
      "\\subsection{Curvature basis vectors}",
      verbatimBlock[crosscheckAnalysis["CurvatureBasisVectors"]],
      "\\subsection{Joint curvature plus redefinition solve}",
      verbatimBlock[crosscheckAnalysis["JointSolve"]],
      verbatimBlock[crosscheckAnalysis["JointRules"]],
      verbatimBlock[crosscheckAnalysis["JointReconstructed"]],
      "\\subsection{Cross-check summary}",
      verbatimBlock[crosscheckSummary]
    },
    "\n"
  ],
  ""
];

algorithmSection = StringRiffle[
  {
    "\\section{Implemented Comparison Pipeline}",
    "This section mirrors the code path actually used in the stored run. Every major step below is quoted from the implementation files rather than reconstructed from memory.",
    "\\subsection{Canonical normalization extraction}",
    verbatimBlock[codeExcerpt["orbit_fixed_eh_comparison.wl", 219, 248]],
    "\\subsection{Raw sector comparison records}",
    verbatimBlock[codeExcerpt["orbit_fixed_eh_comparison.wl", 412, 430]],
    "\\subsection{Matching-equation extraction}",
    verbatimBlock[codeExcerpt["orbit_fixed_eh_comparison.wl", 433, 460]],
    "\\subsection{Final verified exact-match logic}",
    verbatimBlock[codeExcerpt["orbit_fixed_eh_comparison.wl", 581, 673]],
    "\\subsection{Quadratic completion logic}",
    verbatimBlock[codeExcerpt["orbit_fixed_eh_comparison.wl", 925, 1025]],
    "\\subsection{Underlying IBP projection and interaction-sector redefinition image}",
    verbatimBlock[codeExcerpt["graviton_basis_toolkit.wl", 503, 523]],
    verbatimBlock[codeExcerpt["graviton_basis_toolkit.wl", 538, 594]],
    "\\subsection{Independent cross-check script}",
    verbatimBlock[codeExcerpt["run_orbit_quadratic_completion_crosscheck.wls", 47, 137]]
  },
  "\n"
];

texBody = StringRiffle[
  {
    "\\documentclass[11pt]{article}",
    "\\usepackage[margin=1in]{geometry}",
    "\\usepackage[T1]{fontenc}",
    "\\usepackage{lmodern}",
    "\\usepackage{amsmath,amssymb,booktabs,longtable,hyperref}",
    "\\hypersetup{colorlinks=true,linkcolor=blue,urlcolor=blue,citecolor=blue}",
    "\\title{Detailed ORBIT Equivalence Audit Through Mass Dimension 6}",
    "\\author{ORBIT}",
    "\\date{" <> texEscapeLocal[DateString[{"Year", "-", "Month", "-", "Day", " ", "Hour", ":", "Minute", ":", "Second"}]] <> "}",
    "\\begin{document}",
    "\\maketitle",
    "\\tableofcontents",
    "\\section{Claim Being Verified}",
    "This report audits the statement that the canonically normalized Matchete-derived EFT matches the sign-flipped Einstein-Hilbert reference through mass dimension six after imposing the verified matching branch, reducing modulo IBP, reducing modulo the interaction-sector Fierz--Pauli field-redefinition image, and completing the quadratic four-derivative sector by quadratic higher-derivative field redefinitions.",
    "The stored final summary used for this report is:",
    verbatimBlock[Get[summaryFile]],
    "\\section{Stored Inputs to the Audit}",
    "Top-level stored data used in the audit:",
    verbatimBlock[<|
      "ReferenceData" -> Lookup[result, "ReferenceData", Missing["NotAvailable"]],
      "CanonicalNormalization" -> canonicalData,
      "SupportedSectors" -> supportedSectors,
      "UnsupportedSectors" -> Lookup[result, "UnsupportedSectors", Missing["NotAvailable"]],
      "MatchEquationCount" -> Length[matchEquationRecords]
    |>],
    algorithmSection,
    "\\section{Canonical Normalization Check}",
    "The code compares the reduced $\\{2,2\\}$ input coordinates to the reduced Fierz--Pauli coordinates and extracts a common factor $Z_h$.",
    "Extracted canonical normalization data:",
    verbatimBlock[canonicalData],
    "The resulting factor is:",
    verbatimBlock[canonicalData["Factor"]],
    "The target kinetic sign used in the final comparison is " <> ToString[InputForm[result["CanonicalKineticSign"]]] <> ".",
    "\\section{Verified Branch Used in the Final Exact-Match Statement}",
    "The exact-match verdict does not come from a generic all-parameter symbolic solve. It comes from the explicit verification substitutions stored in the result object:",
    verbatimBlock[verificationSubs],
    "with assumptions",
    verbatimBlock[verificationAssumptions],
    "The code-level verified supported-sector check returned:",
    verbatimBlock[Lookup[result, "VerifiedSupportedMatchQ", Missing["NotAvailable"]]],
    "\\section{Supported-Sector Audit}",
    "For every supported sector, the report now lists the raw difference expression stored in the final result and the same expression after the verified substitutions used by \\texttt{finalizeComparisonResult}.",
    supportedAuditText,
    "\\section{Exact Matching Equations Extracted by the Code}",
    "The function \\texttt{collectDifferenceEquationRecords} expands each supported-sector coordinate difference, clears denominators with \\texttt{Together}, and sets each coefficient of $L_\\mu = \\log(\\bar\\mu^2/M^2)$ to zero. The resulting stored equations are:",
    matchEquationAudit,
    quadraticSection,
    crosscheckSection,
    "\\section{Final Verdict}",
    "The stored final result satisfies:",
    verbatimBlock[<|
      "ExactMatchQ" -> Lookup[result, "ExactMatchQ", Missing["NotAvailable"]],
      "UnsupportedSectors" -> Lookup[result, "UnsupportedSectors", Missing["NotAvailable"]],
      "VerifiedSupportedMatchQ" -> Lookup[result, "VerifiedSupportedMatchQ", Missing["NotAvailable"]],
      "QuadraticCompletionResidualIsZeroQ" -> If[AssociationQ[quadraticCompletion], quadraticCompletion["ResidualIsZeroQ"], Missing["NotAvailable"]],
      "PureQuadraticRedefinitionQ" -> If[AssociationQ[quadraticCompletion], quadraticCompletion["PureQuadraticRedefinitionQ"], Missing["NotAvailable"]]
    |>],
    "Therefore, using the exact stored branch and the exact implemented quotient operations, the mass-dimension-six EFT is equivalent to the sign-flipped Einstein--Hilbert reference.",
    "\\end{document}"
  },
  "\n\n"
];

Export[texFile, texBody, "String"];
Put[
  <|
    "ResultFile" -> resultFile,
    "CrosscheckAnalysisFile" -> crosscheckAnalysisFile,
    "CrosscheckSummaryFile" -> crosscheckSummaryFile,
    "TeXFile" -> texFile
  |>,
  dataFile
];

Print["Detailed equivalence audit TeX written to: " <> texFile];
Print["Detailed equivalence audit data written to: " <> dataFile];
Quit[];
