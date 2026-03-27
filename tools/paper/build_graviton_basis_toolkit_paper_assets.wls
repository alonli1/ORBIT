scriptDir = DirectoryName[$InputFileName];
repoRoot = NestWhile[
  DirectoryName,
  scriptDir,
  ! FileExistsQ[FileNameJoin[{#, "graviton_basis_toolkit.wl"}]] &
];
SetDirectory[repoRoot];

outputDir = FileNameJoin[{repoRoot, "docs", "graviton_basis"}];
assetsDir = FileNameJoin[{outputDir, "paper_assets"}];
If[! DirectoryQ[assetsDir], CreateDirectory[assetsDir]];

ClearAll[
  basisPipelineGraphic, quotientSpaceGraphic, reducerPipelineGraphic,
  validationGraphic, workedExampleGraphic
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
  ImageSize -> 900
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
    Inset[Style["V_(nh,Nd)", 24, Bold], {8.3, 5.3}],
    Inset[Style["T_(nh,Nd)\n(total derivatives)", 17], {2.75, 1.55}],
    Inset[Style["R_(nh,Nd)\n(redefinition image)", 17], {7.35, 3.45}],
    Inset[Style["First quotient:\nV / T", 18, Bold], {6.0, 1.2}],
    Arrow[{{4.75, 1.55}, {5.45, 1.55}}],
    Inset[Style["Then quotient by R", 17], {7.25, 1.55}]
  },
  ImageSize -> 900,
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
  ImageSize -> 900
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
  ImageSize -> 900
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
  ImageSize -> 900
];

Export[FileNameJoin[{assetsDir, "basis_pipeline.pdf"}], basisPipelineGraphic[]];
Export[FileNameJoin[{assetsDir, "quotient_space.pdf"}], quotientSpaceGraphic[]];
Export[FileNameJoin[{assetsDir, "reducer_pipeline.pdf"}], reducerPipelineGraphic[]];
Export[FileNameJoin[{assetsDir, "validation_pipeline.pdf"}], validationGraphic[]];
Export[FileNameJoin[{assetsDir, "worked_example_pipeline.pdf"}], workedExampleGraphic[]];

Put[
  <|
    "GeneratedOn" -> DateString[{"ISODate", " ", "Time"}],
    "AssetsDirectory" -> assetsDir,
    "Assets" -> {
      "basis_pipeline.pdf",
      "quotient_space.pdf",
      "reducer_pipeline.pdf",
      "validation_pipeline.pdf",
      "worked_example_pipeline.pdf"
    }
  |>,
  FileNameJoin[{outputDir, "build_graviton_basis_toolkit_paper_assets_output.wl"}]
];
