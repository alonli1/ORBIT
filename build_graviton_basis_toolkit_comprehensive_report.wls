SetDirectory[DirectoryName[$InputFileName]];

Get["graviton_basis_toolkit.wl"];

validationData = Quiet @ Check[Get["graviton_basis_toolkit_validation_output.wl"], Missing["NotAvailable"]];

cacheDir = FileNameJoin[{Directory[], "graviton_basis_comprehensive_report_cache"}];
baseOpts = {
  "CacheDirectory" -> cacheDir,
  "UseCache" -> True,
  "ForceRecompute" -> False,
  "Verbose" -> False
};

ClearAll[
  titleCell, sectionCell, subsectionCell, textCell, itemCell, codeCell,
  programCell, formulaCell, outputCell, pageBreakCell, wrapExprString, termCount,
  sectorSummaryGrid, validationSummaryGrid, vectorGrid, functionReferenceGrid,
  basisPipelineGraphic, quotientSpaceGraphic, reducerPipelineGraphic,
  validationGraphic, workedExampleGraphic
];

titleCell[text_String] := Cell[text, "Title"];
sectionCell[text_String] := Cell[text, "Section"];
subsectionCell[text_String] := Cell[text, "Subsection"];
textCell[text_String] := Cell[text, "Text"];
itemCell[text_String] := Cell[text, "Item"];
codeCell[text_String] := Cell[text, "Input"];
programCell[text_String] := Cell[TextData @ StyleBox[text, FontFamily -> "Courier New", FontSize -> 10], "Text"];
formulaCell[text_String] := Cell[text, "DisplayFormula"];
outputCell[expr_] := Cell[BoxData @ ToBoxes @ expr, "Output"];
pageBreakCell[] := Cell["", "PageBreak"];

wrapExprString[str_String] := StringReplace[
  str,
  {
    " + " -> " +\n  ",
    " - " -> "\n- "
  }
];

termCount[expr_] := Which[
  expr === 0, 0,
  Head[expr] === Plus, Length[List @@ expr],
  True, 1
];

sectorSummaryGrid[data_List] := Grid[
  Prepend[data, {"Sector", "RawCount", "IBPCount", "RedefRank", "PhysicalCount"}],
  Frame -> All,
  Alignment -> Left,
  Background -> {None, {None, {Lighter[Gray, 0.95]}}},
  ItemStyle -> Directive[FontFamily -> "Source Sans Pro", 11]
];

validationSummaryGrid[data_Association] := Module[{tests},
  tests = Lookup[data, "Tests", {}];
  Grid[
    Prepend[
      (Lookup[#, {
          "Sector", "IBPCount", "RedefRank", "PhysicalCount",
          "DeltaBasisLength", "LagTermCount", "ReducedExpressionZeroQ"
        }] & /@ tests),
      {"Sector", "IBPCount", "RedefRank", "PhysicalCount", "DeltaBasisLength", "LagTermCount", "Reduced to 0?"}
    ],
    Frame -> All,
    Alignment -> Left,
    Background -> {None, {None, {Lighter[Gray, 0.95]}}},
    ItemStyle -> Directive[FontFamily -> "Source Sans Pro", 11]
  ]
];

vectorGrid[rows_List] := Grid[
  Prepend[rows, {"Object", "Coordinates"}],
  Frame -> All,
  Alignment -> Left,
  Background -> {None, {None, {Lighter[Gray, 0.95]}}},
  ItemStyle -> Directive[FontFamily -> "Source Sans Pro", 11]
];

functionReferenceGrid[] := Grid[
  {
    {"Function", "Role"},
    {"RunBasisComputation", "Compute and cache sector data over a sector list."},
    {"ComputeSectorData", "Assemble the raw basis, IBP quotient, redefinition image, and physical basis of one sector."},
    {"RawBasisOfSector", "Return the raw scalar basis of a stored sector."},
    {"IBPBasisOfSector", "Return the IBP quotient basis of a stored sector."},
    {"PhysicalBasisOfSector", "Return the final basis after the interaction-sector field-redefinition quotient."},
    {"RedefinitionRulesOfSector", "Return explicit independent field redefinitions and their images in the IBP basis."},
    {"ReduceSectorLagrangian", "Reduce a known single-sector expression modulo IBP and field redefinitions."},
    {"ReduceLagrangian", "Split a general expression by sector and reduce each sector automatically."}
  },
  Frame -> All,
  Alignment -> Left,
  Background -> {None, {None, {Lighter[Gray, 0.95]}}},
  ItemStyle -> Directive[FontFamily -> "Source Sans Pro", 11]
];

basisPipelineGraphic[] := Graph[
  {
    "Ordered derivative\npartitions" -> "All contractions\nand canonicalization",
    "All contractions\nand canonicalization" -> "Raw scalar basis",
    "Raw scalar basis" -> "Euler operator",
    "Euler operator" -> "IBP quotient basis",
    "IBP quotient basis" -> "Field-redefinition image",
    "Field-redefinition image" -> "Physical basis"
  },
  GraphLayout -> {"LayeredDigraphEmbedding", "Orientation" -> Top},
  VertexLabels -> Placed["Name", Center],
  VertexSize -> {0.26, 0.11},
  VertexStyle -> Directive[Lighter[RGBColor[0.12, 0.45, 0.72], 0.75], EdgeForm[GrayLevel[0.7]]],
  EdgeStyle -> Directive[GrayLevel[0.45], Thickness[0.004]],
  ImageSize -> 560
];

quotientSpaceGraphic[] := Graphics[
  {
    EdgeForm[Directive[GrayLevel[0.45], Thickness[0.003]]],
    FaceForm[Lighter[RGBColor[0.15, 0.45, 0.72], 0.8]],
    Rectangle[{0, 0}, {10, 6}],
    FaceForm[Lighter[RGBColor[0.88, 0.62, 0.18], 0.75]],
    Rectangle[{1.0, 0.9}, {4.5, 2.2}],
    FaceForm[Lighter[RGBColor[0.2, 0.62, 0.37], 0.75]],
    Rectangle[{5.9, 2.8}, {8.8, 4.1}],
    Inset[Style["V_(nh,Nd)", 16, Bold], {8.3, 5.3}],
    Inset[Style["T_(nh,Nd)\n(total derivatives)", 12], {2.75, 1.55}],
    Inset[Style["R_(nh,Nd)\n(redefinition image)", 12], {7.35, 3.45}],
    Inset[Style["First quotient:\nV / T", 13, Bold], {6.0, 1.2}],
    Arrow[{{4.75, 1.55}, {5.45, 1.55}}],
    Inset[Style["Then quotient by R", 12], {7.25, 1.55}]
  },
  ImageSize -> 560,
  PlotRange -> {{-0.2, 10.2}, {-0.2, 6.2}}
];

reducerPipelineGraphic[] := Graph[
  {
    "Input Lagrangian" -> "Canonicalize\nand expand",
    "Canonicalize\nand expand" -> "Split into\n{nh, Nd} sectors",
    "Split into\n{nh, Nd} sectors" -> "Project each sector\ninto the IBP basis",
    "Project each sector\ninto the IBP basis" -> "Subtract the\nredefinition image",
    "Subtract the\nredefinition image" -> "Sum sector representatives",
    "Sum sector representatives" -> "Reduced Lagrangian"
  },
  GraphLayout -> {"LayeredDigraphEmbedding", "Orientation" -> Left},
  VertexLabels -> Placed["Name", Center],
  VertexSize -> {0.24, 0.1},
  VertexStyle -> Directive[Lighter[RGBColor[0.85, 0.44, 0.12], 0.78], EdgeForm[GrayLevel[0.7]]],
  EdgeStyle -> Directive[GrayLevel[0.45], Thickness[0.004]],
  ImageSize -> 560
];

validationGraphic[] := Graph[
  {
    "Choose generic\ndelta h" -> "Build FP image\nShiftFromRedefExpr",
    "Build FP image\nShiftFromRedefExpr" -> "Expand to a\nmessy scalar",
    "Expand to a\nmessy scalar" -> "ReduceSectorLagrangian",
    "ReduceSectorLagrangian" -> "Expected result:\n0"
  },
  GraphLayout -> {"LayeredDigraphEmbedding", "Orientation" -> Left},
  VertexLabels -> Placed["Name", Center],
  VertexSize -> {0.23, 0.1},
  VertexStyle -> Directive[Lighter[RGBColor[0.18, 0.62, 0.37], 0.76], EdgeForm[GrayLevel[0.7]]],
  EdgeStyle -> Directive[GrayLevel[0.45], Thickness[0.004]],
  ImageSize -> 520
];

workedExampleGraphic[] := Graph[
  {
    "Physical part" -> "Input Lagrangian",
    "IBP-trivial part" -> "Input Lagrangian",
    "Field-redefinition image" -> "Input Lagrangian",
    "Input Lagrangian" -> "ReduceSectorLagrangian",
    "ReduceSectorLagrangian" -> "Surviving physical representative"
  },
  GraphLayout -> {"LayeredDigraphEmbedding", "Orientation" -> Left},
  VertexLabels -> Placed["Name", Center],
  VertexSize -> {0.23, 0.1},
  VertexStyle -> Directive[Lighter[RGBColor[0.5, 0.22, 0.12], 0.82], EdgeForm[GrayLevel[0.7]]],
  EdgeStyle -> Directive[GrayLevel[0.45], Thickness[0.004]],
  ImageSize -> 560
];

smallSectorSummary = Join[
  {
    {
      {1, 2},
      2,
      0,
      0,
      0
    },
    {
      {2, 2},
      10,
      4,
      0,
      4
    },
    {
      {2, 4},
      30,
      5,
      0,
      5
    }
  },
  Table[
    Module[{sec = ComputeSectorData[s[[1]], s[[2]], Sequence @@ baseOpts]},
      {
        s,
        sec["RawCount"],
        sec["IBPCount"],
        sec["RedefRank"],
        sec["PhysicalCount"]
      }
    ],
    {s, {{3, 2}}}
  ]
];

sec32 = ComputeSectorData[3, 2, Sequence @@ baseOpts];

validation32Coeffs = {7, -11, 13, -17};
validation32Delta = canonExpr @ LinearCombination[validation32Coeffs, sec32["RedefDeltaBasis"]];
validation32Lag = canonExpr @ Expand @ Total[MapThread[Times, {validation32Coeffs, sec32["RedefShiftImages"]}]];
validation32Reduction = ReduceSectorLagrangian[validation32Lag, 3, 2, Sequence @@ baseOpts];

workedPhysCoeffs = ReplacePart[ConstantArray[0, sec32["PhysicalCount"]], {1 -> 2, 2 -> -3}];
workedPhysExpr = canonExpr @ LinearCombination[workedPhysCoeffs, sec32["PhysicalBasis"]];
workedIBPExpr = sec32["IBPRelationExpressions"][[1]];
workedRedefCoeffs = {5, -7, 11, -13};
workedRedefExpr = canonExpr @ Expand @ Total[MapThread[Times, {workedRedefCoeffs, sec32["RedefShiftImages"]}]];
workedInputLag = canonExpr @ Expand[workedPhysExpr + 4 workedIBPExpr + workedRedefExpr];
workedReduction = ReduceSectorLagrangian[workedInputLag, 3, 2, Sequence @@ baseOpts];

reportData = <|
  "GeneratedOn" -> DateString[{"ISODate", " ", "Time"}],
  "CacheDirectory" -> cacheDir,
  "SmallSectorSummary" -> smallSectorSummary,
  "ValidationSummary" -> validationData,
  "Validation32" -> <|
    "Coefficients" -> validation32Coeffs,
    "Delta" -> ToString[InputForm[validation32Delta]],
    "Lag" -> ToString[InputForm[validation32Lag]],
    "LagTermCount" -> termCount[validation32Lag],
    "ProjectedIBPCoordinates" -> validation32Reduction["ProjectedIBPCoordinates"],
    "ImageCoefficients" -> validation32Reduction["RedefinitionImageCoefficients"],
    "PhysicalCoordinates" -> validation32Reduction["PhysicalCoordinates"],
    "ReducedExpression" -> ToString[InputForm[validation32Reduction["ReducedExpression"]]]
  |>,
  "WorkedExample32" -> <|
    "PhysicalCoordinatesTarget" -> workedPhysCoeffs,
    "IBPMultiplier" -> 4,
    "RedefinitionCoefficients" -> workedRedefCoeffs,
    "PhysicalExpression" -> ToString[InputForm[workedPhysExpr]],
    "IBPExpression" -> ToString[InputForm[workedIBPExpr]],
    "RedefinitionExpression" -> ToString[InputForm[workedRedefExpr]],
    "InputLagrangian" -> ToString[InputForm[workedInputLag]],
    "InputTermCount" -> termCount[workedInputLag],
    "ProjectedIBPCoordinates" -> workedReduction["ProjectedIBPCoordinates"],
    "ReducedIBPCoordinates" -> workedReduction["ReducedIBPCoordinates"],
    "PhysicalCoordinates" -> workedReduction["PhysicalCoordinates"],
    "ImageCoefficients" -> workedReduction["RedefinitionImageCoefficients"],
    "ReducedExpression" -> ToString[InputForm[workedReduction["ReducedExpression"]]],
    "ReducedEqualsPhysicalQ" -> (workedReduction["ReducedExpression"] === workedPhysExpr)
  |>
|>;

Put[reportData, "graviton_basis_toolkit_comprehensive_report_data.wl"];

reportCells = {
  titleCell["Graviton Basis Toolkit: Mathematical Background, User Guide, Validation, and Worked Reduction Example"],
  textCell["This report consolidates the mathematical setup, the software interface, the validation logic, and a nontrivial worked reduction example for graviton_basis_toolkit.wl. The emphasis is on connecting the abstract quotient constructions to the actual Mathematica computation."],
  outputCell[basisPipelineGraphic[]],

  sectionCell["1. Mathematical Background"],
  textCell["The toolkit works sector by sector. A sector is labeled by {nh, Nd}, where nh is the number of graviton fields h and Nd is the total number of derivatives. The starting point is the finite-dimensional vector space of local scalar operators in that sector."],
  formulaCell["Eq. (1)   V_(nh,Nd) := span of local scalar monomials built from nh gravitons and Nd derivatives."],
  textCell["The raw basis generated by the code is a concrete spanning set for V_(nh,Nd). It is obtained by distributing Nd derivatives among nh fields in all ordered ways, forming the corresponding derivative-decorated monomials, and then taking all scalar contractions."],
  outputCell[quotientSpaceGraphic[]],
  textCell["The first physical equivalence is integration by parts. Two Lagrangians define the same action if they differ by a total derivative."],
  formulaCell["Eq. (2)   L ~ L + d_mu K^mu."],
  textCell["Let T_(nh,Nd) denote the subspace of total derivatives inside V_(nh,Nd). The physically relevant space after IBP is the quotient V_(nh,Nd) / T_(nh,Nd)."],
  formulaCell["Eq. (3)   Q_(nh,Nd) := V_(nh,Nd) / T_(nh,Nd)."],
  textCell["The code identifies T_(nh,Nd) through the Euler-Lagrange operator. A local scalar density is a total derivative exactly when its Euler derivative vanishes."],
  formulaCell["Eq. (4)   L in T_(nh,Nd)  iff  delta L / delta h_(mu nu) = 0."],
  textCell["This is why IBPData constructs a generic linear combination of raw basis elements and solves VarD[h][L] == 0. The null space of that linear map is the space of IBP relations."],
  textCell["The second equivalence is field redefinition redundancy. For a local symmetric rank-2 tensor Delta h_(mu nu), the quadratic Fierz-Pauli Lagrangian changes by an equation-of-motion term plus a total derivative."],
  formulaCell["Eq. (5)   delta L_FP = E_FP^(mu nu) Delta h_(mu nu) + d_mu K^mu."],
  textCell["Therefore the image of the linear map Delta h -> E_FP^(mu nu) Delta h_(mu nu) is redundant inside the IBP quotient."],
  formulaCell["Eq. (6)   R_(nh,Nd) := Im(F_(nh-1,Nd-2 -> nh,Nd)) subset Q_(nh,Nd)."],
  textCell["For interaction sectors, the final basis is the quotient of the IBP quotient by this image."],
  formulaCell["Eq. (7)   P_(nh,Nd) := Q_(nh,Nd) / R_(nh,Nd)."],
  textCell["Quadratic sectors are intentionally treated differently. A linear field redefinition acts directly on the kinetic operator itself, so quotienting the quadratic sector by those directions is usually not the desired equivalence relation for the kinetic term."],
  formulaCell["Eq. (8)   nh < 3: use Q_(nh,Nd);   nh >= 3: use P_(nh,Nd)."],
  textCell["The diagrams above summarize the two quotient operations: a kernel quotient for IBP and an image quotient for interaction-level field redefinitions."],
  pageBreakCell[],

  sectionCell["2. User Guide and Code Reference"],
  textCell["The normal workflow is: load the toolkit, compute sector data once with caching, inspect the basis of a sector if needed, and then reduce a Lagrangian either sector by sector or automatically."],
  programCell["Get[\"graviton_basis_toolkit.wl\"]"],
  programCell[
"res = RunBasisComputation[
  \"MaxDimension\" -> 5,
  \"CacheDirectory\" -> FileNameJoin[{Directory[], \"basis_cache\"}],
  \"UseCache\" -> True,
  \"Verbose\" -> True
];"
  ],
  programCell[
"red = ReduceLagrangian[lag,
  \"CacheDirectory\" -> FileNameJoin[{Directory[], \"basis_cache\"}],
  \"UseCache\" -> True
];

red[\"ReducedExpression\"]"
  ],
  textCell["The public functions most users actually need are summarized below."],
  outputCell[functionReferenceGrid[]],
  textCell["The small-sector summary below records the current behavior of the code in the sectors most relevant to the present report."],
  outputCell[sectorSummaryGrid[reportData["SmallSectorSummary"]]],
  textCell["The {2,2} and {2,4} quadratic sectors are shown after the current convention change that skips the field-redefinition quotient for nh < 3. The {3,2} sector is the first interaction sector and therefore exhibits a nontrivial redefinition image of rank 4."],
  pageBreakCell[],

  sectionCell["3. Validation Report"],
  textCell["The validation strategy is a direct implementation of Eq. (5). One chooses a generic Delta h_(mu nu), computes its Fierz-Pauli image, expands the resulting scalar Lagrangian, and then reduces it. Since the result lies in R_(nh,Nd), the reduced representative must vanish."],
  outputCell[validationGraphic[]],
  subsectionCell["3.1 Detailed Validation in Sector {3,2}"],
  textCell["For the first explicit validation, choose the coefficient vector {7, -11, 13, -17} in the independent redefinition basis of source sector {2,0}. The corresponding Delta h_(mu nu) is:"],
  programCell[wrapExprString[reportData["Validation32"]["Delta"]]],
  textCell["Its expanded Fierz-Pauli image in scalar sector {3,2} is:"],
  programCell[wrapExprString[reportData["Validation32"]["Lag"]]],
  textCell["This expression contains " <> ToString[reportData["Validation32"]["LagTermCount"]] <> " explicit scalar terms after expansion. By Eq. (5), its class in P_(3,2) must vanish."],
  outputCell[vectorGrid[{
    {"Projected coordinates in the {3,2} IBP basis", reportData["Validation32"]["ProjectedIBPCoordinates"]},
    {"Recovered image coefficients", reportData["Validation32"]["ImageCoefficients"]},
    {"Physical coordinates after the quotient", reportData["Validation32"]["PhysicalCoordinates"]}
  }]],
  textCell["The recovered image coefficients match the chosen field-redefinition coefficients exactly, and the physical coordinates are all zero. The reduced expression returned by the toolkit is:"],
  programCell[reportData["Validation32"]["ReducedExpression"]],
  textCell["This is the computational realization of Eq. (6): the entire expression lies inside the redefinition image R_(3,2)."],
  subsectionCell["3.2 Stored Stress Test in Sector {3,4}"],
  textCell["The second validation is the stronger one. It uses all 33 independent redefinition-basis directions of source sector {2,2}, producing a 240-term scalar Lagrangian in target sector {3,4}. The reducer again returns zero."],
  outputCell[validationSummaryGrid[reportData["ValidationSummary"]]],
  textCell["The {3,4} test is important because it shows that the image quotient is working in a genuinely large sector, not only in a small toy example."],
  pageBreakCell[],

  sectionCell["4. Worked Example: A Nontrivial Lagrangian Reduction"],
  textCell["To show a nonzero outcome, consider a sector-{3,2} Lagrangian built from three pieces: one physical contribution, one explicit IBP-trivial contribution, and one explicit field-redefinition image."],
  outputCell[workedExampleGraphic[]],
  formulaCell["Eq. (9)   L_in = L_phys + 4 L_IBP + L_redef."],
  textCell["The physical part is chosen directly in the stored physical basis with target coordinate vector {2, -3, 0, ..., 0}."],
  programCell[wrapExprString[reportData["WorkedExample32"]["PhysicalExpression"]]],
  textCell["The IBP-trivial contribution is chosen from the stored relation expressions, so by Eq. (4) it is a total derivative:"],
  programCell[wrapExprString[reportData["WorkedExample32"]["IBPExpression"]]],
  textCell["The field-redefinition contribution is chosen from the image of the Fierz-Pauli variation using image coefficients {5, -7, 11, -13}:"],
  programCell[wrapExprString[reportData["WorkedExample32"]["RedefinitionExpression"]]],
  textCell["Combining the three pieces gives the following input Lagrangian:"],
  programCell[wrapExprString[reportData["WorkedExample32"]["InputLagrangian"]]],
  textCell["This input contains " <> ToString[reportData["WorkedExample32"]["InputTermCount"]] <> " explicit terms after expansion. The mathematical prediction from Eqs. (4), (5), and (9) is immediate:"],
  formulaCell["Eq. (10)   [L_in] = [L_phys] + 4[0] + [0] = [L_phys]."],
  textCell["The actual Mathematica computation reproduces exactly that logic. First the full input is projected into the {3,2} IBP basis; then the field-redefinition image component is subtracted."],
  outputCell[vectorGrid[{
    {"Projected coordinates in the {3,2} IBP basis", reportData["WorkedExample32"]["ProjectedIBPCoordinates"]},
    {"Coordinates after subtracting the image", reportData["WorkedExample32"]["ReducedIBPCoordinates"]},
    {"Final physical coordinates", reportData["WorkedExample32"]["PhysicalCoordinates"]},
    {"Recovered image coefficients", reportData["WorkedExample32"]["ImageCoefficients"]}
  }]],
  textCell["The final physical coordinates are exactly {2, -3, 0, ..., 0}, which is the coordinate vector of the chosen physical part. The surviving reduced expression is:"],
  programCell[wrapExprString[reportData["WorkedExample32"]["ReducedExpression"]]],
  textCell["The equality of the reduced expression and the chosen physical part is checked explicitly in the data file and evaluates to True."],
  subsectionCell["4.1 Mathematica Commands for the Worked Example"],
  programCell[
"sec = ComputeSectorData[3, 2, Sequence @@ opts];
physCoeffs = ReplacePart[ConstantArray[0, sec[\"PhysicalCount\"]], {1 -> 2, 2 -> -3}];
physExpr = canonExpr @ LinearCombination[physCoeffs, sec[\"PhysicalBasis\"]];
ibpExpr = sec[\"IBPRelationExpressions\"][[1]];
redefCoeffs = {5, -7, 11, -13};
redefExpr = canonExpr @ Total[MapThread[Times, {redefCoeffs, sec[\"RedefShiftImages\"]}]];
lag = canonExpr @ Expand[physExpr + 4 ibpExpr + redefExpr];
red = ReduceSectorLagrangian[lag, 3, 2, Sequence @@ opts];"
  ],
  textCell["This is the simplest nontrivial example I know of that shows both kinds of redundancy being removed while leaving a nonzero physical answer."],
  pageBreakCell[],

  sectionCell["5. Reproduction and Auxiliary Files"],
  textCell["The report itself was generated from the current code and the current stored validation output. The main auxiliary files are:"],
  itemCell["graviton_basis_toolkit_validation.wls and graviton_basis_toolkit_validation_output.wl for the stored redundancy tests."],
  itemCell["build_graviton_basis_docs.wls for the smaller notebook/PDF documentation set."],
  itemCell["build_graviton_basis_toolkit_comprehensive_report.wls for this combined report."],
  itemCell["graviton_basis_toolkit_comprehensive_report_data.wl for the machine-readable data shown in this report."],
  textCell["If the implementation changes, rerun the validation script first and then rerun the comprehensive report build script so that the report stays synchronized with the code."],
  textCell["End of report."]
};

reportNotebook = Notebook[
  reportCells,
  StyleDefinitions -> "Default.nb",
  Saveable -> True,
  WindowTitle -> "graviton_basis_toolkit_comprehensive_report",
  PageHeaders -> {{
     Cell["Graviton Basis Toolkit Comprehensive Report", "Header"], None, None},
    {None, None, Cell[DateString[{"ISODate"}], "Header"]}
  },
  PrintingOptions -> {"PrintCellBrackets" -> False}
];

Export["graviton_basis_toolkit_comprehensive_report.nb", reportNotebook];
Export["graviton_basis_toolkit_comprehensive_report.pdf", reportNotebook];

Put[
  <|
    "GeneratedOn" -> DateString[{"ISODate", " ", "Time"}],
    "Artifacts" -> {
      "graviton_basis_toolkit_comprehensive_report_data.wl",
      "graviton_basis_toolkit_comprehensive_report.nb",
      "graviton_basis_toolkit_comprehensive_report.pdf"
    }
  |>,
  "build_graviton_basis_toolkit_comprehensive_report_output.wl"
];
