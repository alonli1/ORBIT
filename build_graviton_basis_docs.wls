SetDirectory[DirectoryName[$InputFileName]];

validationData = Quiet @ Check[Get["graviton_basis_toolkit_validation_output.wl"], Missing["NotAvailable"]];

ClearAll[
  titleCell, sectionCell, subsectionCell, textCell, itemCell, codeCell,
  outputCell, pageBreakCell, exportNotebookAndPDF, validationSummaryGrid,
  basisPipelineGraphic, reducerPipelineGraphic, validationGraphic,
  functionDependencyGraphic, sectorDependencyGraphic, quotientSpaceGraphic,
  quadraticSectorGraphic, resultsTableRows
];

titleCell[text_String] := Cell[text, "Title"];
sectionCell[text_String] := Cell[text, "Section"];
subsectionCell[text_String] := Cell[text, "Subsection"];
textCell[text_String] := Cell[text, "Text"];
itemCell[text_String] := Cell[text, "Item"];
codeCell[text_String] := Cell[text, "Input"];
outputCell[expr_] := Cell[BoxData @ ToBoxes @ expr, "Output"];
pageBreakCell[] := Cell["", "PageBreak"];

resultsTableRows[data_Association] := Module[{tests},
  tests = Lookup[data, "Tests", {}];
  Prepend[
    (Lookup[#, {
        "Sector", "IBPCount", "RedefRank", "PhysicalCount",
        "DeltaBasisLength", "LagTermCount", "ReducedExpressionZeroQ"
      }] & /@ tests),
    {"Sector", "IBPCount", "RedefRank", "PhysicalCount", "DeltaBasisLength", "LagTermCount", "Reduced to 0?"}
  ]
];

validationSummaryGrid[data_] := Module[{rows},
  rows = Which[
    AssociationQ[data], resultsTableRows[data],
    True, {{"Validation output not found"}}
  ];
  Grid[
    rows,
    Frame -> All,
    Background -> {None, {None, {Lighter[Gray, 0.95]}}},
    Alignment -> Left,
    ItemStyle -> Directive[FontFamily -> "Source Sans Pro", 11]
  ]
];

basisPipelineGraphic[] := Graph[
  {
    "Ordered derivative\npartitions" -> "All contractions\n+ canonicalization",
    "All contractions\n+ canonicalization" -> "Raw scalar basis",
    "Raw scalar basis" -> "Euler operator\nfor IBP relations",
    "Euler operator\nfor IBP relations" -> "IBP quotient basis",
    "IBP quotient basis" -> "Field-redefinition\nimage in IBP basis",
    "Field-redefinition\nimage in IBP basis" -> "Physical basis"
  },
  GraphLayout -> {"LayeredDigraphEmbedding", "Orientation" -> Top},
  VertexLabels -> Placed["Name", Center],
  VertexSize -> {0.26, 0.11},
  VertexStyle -> Directive[Lighter[RGBColor[0.12, 0.45, 0.72], 0.75], EdgeForm[GrayLevel[0.7]]],
  EdgeStyle -> Directive[GrayLevel[0.45], Thickness[0.004]],
  ImageSize -> 560
];

reducerPipelineGraphic[] := Graph[
  {
    "Input Lagrangian" -> "Canonicalize\nand expand",
    "Canonicalize\nand expand" -> "Split into\n{nh, Nd} sectors",
    "Split into\n{nh, Nd} sectors" -> "Project each sector\nonto IBP basis",
    "Project each sector\nonto IBP basis" -> "Subtract field-\nredefinition image",
    "Subtract field-\nredefinition image" -> "Sum sector representatives",
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
    "Build FP image\nShiftFromRedefExpr" -> "Expand into a\nmessy scalar",
    "Expand into a\nmessy scalar" -> "ReduceLagrangian",
    "ReduceLagrangian" -> "Expected result:\n0"
  },
  GraphLayout -> {"LayeredDigraphEmbedding", "Orientation" -> Left},
  VertexLabels -> Placed["Name", Center],
  VertexSize -> {0.23, 0.1},
  VertexStyle -> Directive[Lighter[RGBColor[0.18, 0.62, 0.37], 0.76], EdgeForm[GrayLevel[0.7]]],
  EdgeStyle -> Directive[GrayLevel[0.45], Thickness[0.004]],
  ImageSize -> 520
];

functionDependencyGraphic[] := Graph[
  {
    "RunBasisComputation" -> "ComputeSectorData",
    "ComputeSectorData" -> "RawScalarBasis",
    "ComputeSectorData" -> "IBPData",
    "ComputeSectorData" -> "QuotientBasisFromRelations",
    "ComputeSectorData" -> "RedefinitionImageData",
    "RedefinitionImageData" -> "Rank2Basis",
    "RedefinitionImageData" -> "ShiftFromRedefExpr",
    "RedefinitionImageData" -> "ProjectModuloIBP",
    "ReduceLagrangian" -> "SplitTermsBySector",
    "ReduceLagrangian" -> "ReduceSectorLagrangian",
    "ReduceSectorLagrangian" -> "ComputeSectorData",
    "ReduceSectorLagrangian" -> "ProjectModuloIBP",
    "ReduceSectorLagrangian" -> "ReduceCoordinatesModuloRedef"
  },
  GraphLayout -> {"LayeredDigraphEmbedding", "Orientation" -> Top},
  VertexLabels -> Placed["Name", Center],
  VertexSize -> Medium,
  VertexStyle -> Directive[Lighter[RGBColor[0.31, 0.33, 0.55], 0.8], EdgeForm[GrayLevel[0.7]]],
  EdgeStyle -> Directive[GrayLevel[0.45], Thickness[0.003]],
  ImageSize -> 620
];

sectorDependencyGraphic[] := Graph[
  {
    "Target sector\n{nh, Nd}" -> "Raw scalar basis\nRawScalarBasis[nh, Nd]",
    "Target sector\n{nh, Nd}" -> "Redef basis\nRank2Basis[nh-1, Nd-2]",
    "Redef basis\nRank2Basis[nh-1, Nd-2]" -> "Shift images\nShiftFromRedefExpr",
    "Raw scalar basis\nRawScalarBasis[nh, Nd]" -> "IBP quotient basis",
    "Shift images\nShiftFromRedefExpr" -> "Project onto\nIBP quotient basis",
    "IBP quotient basis" -> "Project onto\nIBP quotient basis",
    "Project onto\nIBP quotient basis" -> "Physical basis"
  },
  GraphLayout -> {"LayeredDigraphEmbedding", "Orientation" -> Left},
  VertexLabels -> Placed["Name", Center],
  VertexSize -> {0.25, 0.1},
  VertexStyle -> Directive[Lighter[RGBColor[0.5, 0.22, 0.12], 0.82], EdgeForm[GrayLevel[0.7]]],
  EdgeStyle -> Directive[GrayLevel[0.45], Thickness[0.004]],
  ImageSize -> 600
];

quotientSpaceGraphic[] := Graphics[
  {
    EdgeForm[Directive[GrayLevel[0.45], Thickness[0.003]]],
    FaceForm[Lighter[RGBColor[0.15, 0.45, 0.72], 0.8]],
    Rectangle[{0, 0}, {10, 6}],
    FaceForm[Lighter[RGBColor[0.88, 0.62, 0.18], 0.75]],
    Rectangle[{1.1, 0.9}, {4.7, 2.2}],
    FaceForm[Lighter[RGBColor[0.2, 0.62, 0.37], 0.75]],
    Rectangle[{5.8, 2.8}, {8.9, 4.1}],
    Inset[Style["V_{nh,Nd}", 16, Bold], {8.5, 5.3}],
    Inset[Style["T_{nh,Nd}\n(total derivatives)", 12], {2.9, 1.55}],
    Inset[Style["R_{nh,Nd}\n(redefinition image\ninside V/T)", 12], {7.35, 3.45}],
    Inset[Style["First quotient:\nV / T", 13, Bold], {6.2, 1.2}],
    Arrow[{{4.9, 1.55}, {5.55, 1.55}}],
    Inset[Style["Then quotient by R", 12], {7.3, 1.55}]
  },
  ImageSize -> 560,
  PlotRange -> {{-0.2, 10.2}, {-0.2, 6.2}}
];

quadraticSectorGraphic[] := Graph[
  {
    "Quadratic sector\nnh = 2" -> "IBP quotient",
    "IBP quotient" -> "Keep kinetic data",
    "Interaction sector\nnh >= 3" -> "IBP quotient",
    "IBP quotient" -> "Quotient by\nredefinition image",
    "Quotient by\nredefinition image" -> "Physical basis"
  },
  GraphLayout -> {"LayeredDigraphEmbedding", "Orientation" -> Left},
  VertexLabels -> Placed["Name", Center],
  VertexSize -> {0.22, 0.1},
  VertexStyle -> Directive[Lighter[RGBColor[0.43, 0.28, 0.59], 0.82], EdgeForm[GrayLevel[0.7]]],
  EdgeStyle -> Directive[GrayLevel[0.45], Thickness[0.004]],
  ImageSize -> 560
];

exportNotebookAndPDF[base_String, cells_List] := Module[{nb},
  nb = Notebook[
    cells,
    StyleDefinitions -> "Default.nb",
    Saveable -> True,
    WindowTitle -> base,
    PageHeaders -> {{
       Cell[base, "Header"], None, None},
      {None, None, Cell[DateString[{"ISODate"}], "Header"]}
    },
    PrintingOptions -> {"PrintCellBrackets" -> False}
  ];
  Export[base <> ".nb", nb];
  Export[base <> ".pdf", nb];
];

validationWrapperCells = {
  titleCell["Graviton Basis Toolkit Validation Notebook"],
  textCell["This notebook wraps the reproducible reducer validation stored in graviton_basis_toolkit_validation.wls. It is intended as the notebook counterpart to the script-based test run."],
  outputCell[validationGraphic[]],
  sectionCell["Current Stored Results"],
  textCell["The table below is loaded from graviton_basis_toolkit_validation_output.wl, which was produced by the most recent validation run."],
  outputCell[validationSummaryGrid[validationData]],
  sectionCell["How to Re-run"],
  textCell["Evaluate the following input cell from the notebook front end or run the corresponding script directly from the kernel."],
  codeCell["Get[\"graviton_basis_toolkit_validation.wls\"]"],
  textCell["The script writes graviton_basis_toolkit_validation_output.wl and uses graviton_basis_validation_cache/ for sector caches."],
  sectionCell["What the Validation Proves"],
  itemCell["It constructs Lagrangians that are in the image of a field redefinition of the Fierz-Pauli kinetic term."],
  itemCell["It expands those images so they do not transparently look like EOM times delta h."],
  itemCell["It runs ReduceLagrangian on the expanded expressions."],
  itemCell["It checks that the reduced expression and all physical coordinates vanish."],
  sectionCell["Useful Follow-up"],
  codeCell["Get[\"graviton_basis_toolkit_validation_output.wl\"]"],
  textCell["You can inspect the returned association directly, or compare the stored image coefficients against the redefinition basis of the relevant sector."]
};

validationReportCells = {
  titleCell["Graviton Basis Toolkit Validation Report"],
  textCell["This notebook is the notebook and PDF rendering of graviton_basis_toolkit_validation_report.md. It documents the validation strategy and records the current test outcome."],
  outputCell[validationGraphic[]],
  sectionCell["Validation Strategy"],
  textCell["The reducer is tested on expressions that are guaranteed to be redundant: images of the Fierz-Pauli kinetic term under nonlinear field redefinitions. In EFT language these are EOM-proportional terms up to a total derivative."],
  itemCell["Choose a generic rank-2 redefinition from the computed RedefDeltaBasis."],
  itemCell["Map it into the target scalar sector with ShiftFromRedefExpr."],
  itemCell["Expand the result into a large scalar expression."],
  itemCell["Reduce the expression with ReduceLagrangian."],
  itemCell["Require the reduced representative to vanish exactly."],
  sectionCell["Current Results"],
  textCell["The table below comes from graviton_basis_toolkit_validation_output.wl."],
  outputCell[validationSummaryGrid[validationData]],
  subsectionCell["Interpretation"],
  textCell["The {3,2} test is a compact sanity check. The {3,4} test is the stronger one because it uses all 33 rank-2 redefinition basis elements in that sector and expands to 240 scalar terms before reduction."],
  sectionCell["Re-run Command"],
  codeCell["& 'C:\\Program Files\\Wolfram Research\\Wolfram\\14.2\\WolframKernel.exe' -script graviton_basis_toolkit_validation.wls"],
  textCell["After rerunning, inspect graviton_basis_toolkit_validation_output.wl for the updated association."],
  sectionCell["Files Produced by the Validation"],
  itemCell["graviton_basis_toolkit_validation.wls: validation script"],
  itemCell["graviton_basis_toolkit_validation_output.wl: machine-readable output"],
  itemCell["graviton_basis_validation_cache/: persistent cache used by the validation run"]
};

referenceCells = {
  titleCell["Graviton Basis Toolkit Reference"],
  textCell["This notebook is the notebook and PDF rendering of graviton_basis_toolkit_reference.md. It explains both the algorithms and how they are realized in graviton_basis_toolkit.wl."],
  outputCell[basisPipelineGraphic[]],
  sectionCell["Overall Architecture"],
  textCell["The toolkit works sector by sector in the grading {nh, Nd}, where nh is the number of graviton fields and Nd is the number of derivatives. For each sector it constructs a raw scalar basis, quotients by total derivatives using the Euler operator, and then removes the image of Fierz-Pauli field redefinitions in the interaction sectors."],
  outputCell[functionDependencyGraphic[]],
  sectionCell["Code Organization"],
  itemCell["Public API and options"],
  itemCell["xAct setup for M, eta, PD, h, dh, probe, and lam"],
  itemCell["Utilities, canonicalization, sector keys, and cache helpers"],
  itemCell["Raw scalar-basis generation from ordered derivative partitions"],
  itemCell["IBP relations via VarD and SolveConstants"],
  itemCell["Field-redefinition image via the Fierz-Pauli variation"],
  itemCell["Sector assembly, summaries, and the Lagrangian reducer API"],
  sectionCell["Canonicalization"],
  textCell["canonExpr is the core normal-form map. It expands the expression, contracts metrics, canonicalizes tensor symmetries, sorts nested PD operators, canonicalizes again, and finally collects tensor structures. The second canonicalization pass after SortCovDs is essential for eliminating fake distinctions caused by reordered commuting scalar derivatives."],
  sectionCell["Raw Basis Generation"],
  textCell["RawScalarBasis[nh, Nd] builds all ordered ways of distributing Nd derivatives across nh graviton fields, forms the corresponding monomials, applies AllContractions, and canonicalizes the results. Ordered partitions are necessary because different derivative placements become equivalent only after canonicalization, not before."],
  outputCell[sectorDependencyGraphic[]],
  sectionCell["IBP Quotient"],
  textCell["IBPData constructs a generic linear combination of the raw basis and applies the Euler-Lagrange operator VarD[h[-m,-n], PD]. A scalar density is a total derivative exactly when its Euler derivative vanishes, so solving VarD[ansatz] == 0 gives the full space of IBP relations. QuotientBasisFromRelations then removes pivot columns to produce an IBP basis."],
  sectionCell["Field-Redefinition Quotient"],
  textCell["For a target sector {nh, Nd}, the relevant redefinitions have rank-2 basis Rank2Basis[nh-1, Nd-2]. ShiftFromRedefExpr computes the linearized variation of the Fierz-Pauli Lagrangian under h -> h + lam dh and substitutes a concrete delta h. Each resulting image is projected onto the IBP basis, the independent image vectors are extracted, and their span is removed from the IBP quotient basis."],
  textCell["Quadratic sectors are intentionally not quotiented by field redefinitions. At nh < 3, linear redefinitions act directly on the kinetic operator itself, so removing those directions is not the right equivalence relation for classifying the quadratic action."],
  sectionCell["Reducer API"],
  outputCell[reducerPipelineGraphic[]],
  textCell["ReduceSectorLagrangian takes an expression and an explicit sector label, projects the expression into the IBP basis, subtracts the field-redefinition image component, and returns the remaining physical representative together with all intermediate coordinates."],
  textCell["ReduceLagrangian canonicalizes and expands the input, splits it term by term into sectors, applies ReduceSectorLagrangian to each sector, and then sums the reduced representatives."],
  sectionCell["Main Public Functions"],
  itemCell["RunBasisComputation"],
  itemCell["ComputeSectorData"],
  itemCell["RawBasisOfSector, IBPBasisOfSector, PhysicalBasisOfSector"],
  itemCell["RedefinitionRulesOfSector"],
  itemCell["ReduceSectorLagrangian, ReduceLagrangian"],
  sectionCell["Implementation Notes"],
  itemCell["Odd-derivative scalar sectors are empty in this setup and are skipped early."],
  itemCell["The cache is per intermediate object, not only per final sector summary."],
  itemCell["ProjectModuloIBP sets any remaining unsolved ansatz coefficients to zero so returned coordinates are concrete."],
  itemCell["The current automatic splitter assumes the input uses the same h, eta, and PD conventions as the toolkit itself."]
};

mathBackgroundCells = {
  titleCell["Graviton Basis Toolkit Mathematical Background"],
  textCell["This notebook is the notebook and PDF rendering of graviton_basis_toolkit_mathematical_background.md. It explains the quotient spaces and linear maps behind the toolkit, independently of the implementation details."],
  outputCell[quotientSpaceGraphic[]],
  sectionCell["Operator Spaces"],
  textCell["For each pair {nh, Nd}, the toolkit studies the finite-dimensional vector space V_{nh,Nd} of local scalar operators built from nh gravitons, Nd derivatives, and the flat metric, modulo only canonical tensor identities. The entire computation is organized sector by sector because both IBP and the field-redefinition map preserve this grading."],
  subsectionCell["Raw Spanning Set"],
  textCell["A raw spanning set is built by distributing Nd derivatives among nh gravitons in all ordered ways, forming the corresponding monomials, and contracting all indices. Canonicalization then removes duplicates. This produces an explicit spanning set of V_{nh,Nd}."],
  outputCell[basisPipelineGraphic[]],
  sectionCell["IBP as a Kernel Quotient"],
  textCell["The subspace T_{nh,Nd} of total derivatives is identified using the Euler operator. A local scalar density is a total derivative if and only if its Euler-Lagrange derivative with respect to h_{mu nu} vanishes. Therefore the IBP problem is exactly the kernel problem ker(E), where E is the Euler map from V_{nh,Nd} into a rank-2 tensor space."],
  textCell["The first quotient is therefore V_{nh,Nd} / T_{nh,Nd}. In the code this is the space represented by the IBP basis."],
  sectionCell["Field Redefinitions as an Image Quotient"],
  textCell["A local field redefinition h_{mu nu} -> h_{mu nu} + Delta h_{mu nu} changes the Fierz-Pauli action by E_FP^{mu nu} Delta h_{mu nu} plus a total derivative. This means the physically redundant directions form the image of a linear map from rank-2 tensors Delta h into the scalar IBP quotient."],
  textCell["For scalar sector {nh, Nd}, the source of this map is the rank-2 space with labels {nh-1, Nd-2}. The quadratic kinetic operator supplies the extra field and the extra two derivatives."],
  outputCell[sectorDependencyGraphic[]],
  sectionCell["Final Quotient Space"],
  textCell["The final interaction basis is the double quotient (V_{nh,Nd} / T_{nh,Nd}) / R_{nh,Nd}, where R_{nh,Nd} is the field-redefinition image inside the IBP quotient. This is the precise meaning of the toolkit's PhysicalBasis for nh >= 3."],
  sectionCell["Why Quadratic Sectors Are Different"],
  outputCell[quadraticSectorGraphic[]],
  textCell["At quadratic order, quotienting by linear field redefinitions removes directions that act directly on the kinetic operator itself, including simple rescalings. That is mathematically legitimate but usually not the desired equivalence relation for the kinetic term. The toolkit therefore keeps quadratic sectors modulo IBP only."],
  sectionCell["Relation to Gauge Invariance"],
  textCell["The toolkit does not automatically impose linearized diffeomorphism invariance. Its quotients are by total derivatives and field redefinitions, not by gauge symmetry. This is why the off-shell quadratic four-derivative space is larger than the curvature-squared gauge-invariant subspace."],
  sectionCell["Why the Validation Matters"],
  textCell["The reducer has been tested on expanded Lagrangians that are known to be of the form E_FP^{mu nu} Delta h_{mu nu}. The strongest stored test builds such an expression in sector {3,4}, expands it to 240 scalar terms, and still reduces it to exactly zero. That confirms that the implemented image quotient matches the mathematical one in a genuinely nontrivial case."],
  sectionCell["Takeaway"],
  itemCell["IBP reduction is a kernel quotient."],
  itemCell["Field-redefinition removal is an image quotient."],
  itemCell["The toolkit is a sector-wise linear algebra realization of those two facts."]
};

userGuideCells = {
  titleCell["Graviton Basis Toolkit User Guide"],
  textCell["This notebook is the notebook and PDF rendering of graviton_basis_toolkit_user_guide.md. It is the short practical guide for normal use."],
  outputCell[reducerPipelineGraphic[]],
  sectionCell["Load the Toolkit"],
  codeCell["Get[\"graviton_basis_toolkit.wl\"]"],
  sectionCell["Compute Sector Data"],
  codeCell[
"res = RunBasisComputation[
  \"MaxDimension\" -> 5,
  \"CacheDirectory\" -> FileNameJoin[{Directory[], \"basis_cache\"}],
  \"UseCache\" -> True,
  \"Verbose\" -> True
];"
  ],
  textCell["Once res exists you can inspect individual sectors."],
  codeCell[
"RawBasisOfSector[res, 3, 2]
IBPBasisOfSector[res, 3, 2]
PhysicalBasisOfSector[res, 3, 2]
RedefinitionRulesOfSector[res, 3, 2]"
  ],
  sectionCell["Reduce a Single Sector"],
  codeCell[
"red = ReduceSectorLagrangian[lag32, 3, 2,
  \"CacheDirectory\" -> FileNameJoin[{Directory[], \"basis_cache\"}],
  \"UseCache\" -> True
];

red[\"ReducedExpression\"]
red[\"PhysicalCoordinates\"]"
  ],
  sectionCell["Reduce a General Lagrangian"],
  codeCell[
"red = ReduceLagrangian[lag,
  \"CacheDirectory\" -> FileNameJoin[{Directory[], \"basis_cache\"}],
  \"UseCache\" -> True
];

red[\"ReducedExpression\"]
Keys[red[\"SectorReductions\"]]"
  ],
  sectionCell["How to Read the Counts"],
  itemCell["RawCount: size of the canonicalized raw spanning set."],
  itemCell["IBPCount: dimension after quotienting by total derivatives."],
  itemCell["RedefRank: rank of the field-redefinition image inside the IBP basis."],
  itemCell["PhysicalCount: final count after removing that image."],
  textCell["Quadratic sectors are only reduced modulo IBP; interaction sectors are reduced modulo IBP and field redefinitions."],
  sectionCell["Reproducible Validation"],
  codeCell["& 'C:\\Program Files\\Wolfram Research\\Wolfram\\14.2\\WolframKernel.exe' -script graviton_basis_toolkit_validation.wls"],
  textCell["The validation output is written to graviton_basis_toolkit_validation_output.wl and summarized in the validation report notebook and PDF."],
  sectionCell["Common Pitfalls"],
  itemCell["Use the same h, eta, and PD symbols defined by the toolkit."],
  itemCell["Do not interpret PhysicalCount as a gauge-invariant count unless you have separately imposed gauge invariance."],
  itemCell["If the basis-generation logic changes, clear or replace the cache directory before trusting old cache files."]
};

exportNotebookAndPDF["graviton_basis_toolkit_validation_wrapper", validationWrapperCells];
exportNotebookAndPDF["graviton_basis_toolkit_validation_report", validationReportCells];
exportNotebookAndPDF["graviton_basis_toolkit_reference", referenceCells];
exportNotebookAndPDF["graviton_basis_toolkit_mathematical_background", mathBackgroundCells];
exportNotebookAndPDF["graviton_basis_toolkit_user_guide", userGuideCells];

Put[
  <|
    "GeneratedOn" -> DateString[{"ISODate", " ", "Time"}],
    "Artifacts" -> {
      "graviton_basis_toolkit_validation_wrapper.nb",
      "graviton_basis_toolkit_validation_wrapper.pdf",
      "graviton_basis_toolkit_validation_report.nb",
      "graviton_basis_toolkit_validation_report.pdf",
      "graviton_basis_toolkit_reference.nb",
      "graviton_basis_toolkit_reference.pdf",
      "graviton_basis_toolkit_mathematical_background.nb",
      "graviton_basis_toolkit_mathematical_background.pdf",
      "graviton_basis_toolkit_user_guide.nb",
      "graviton_basis_toolkit_user_guide.pdf"
    }
  |>,
  "build_graviton_basis_docs_output.wl"
];
