scriptDir = DirectoryName[$InputFileName];
repoRoot = NestWhile[
  DirectoryName,
  scriptDir,
  ! FileExistsQ[FileNameJoin[{#, "README.md"}]] &
];
SetDirectory[repoRoot];

If[! StringStartsQ[System`$Version, "13.3"],
  Print["WARNING: This diagnostic was designed for Mathematica 13.3. Current kernel: " <> System`$Version]
];

loadMainKernelXPermQ = TrueQ @ If[ValueQ[$LoadMainKernelXPermDiagnostic], $LoadMainKernelXPermDiagnostic, False];

outputFile = If[
  ValueQ[$XPermKernelDiagnosticOutputFile] && StringQ[$XPermKernelDiagnosticOutputFile],
  $XPermKernelDiagnosticOutputFile,
  FileNameJoin[{repoRoot, "tests", "artifacts", "xperm_kernel_diagnostic_output.wl"}]
];

If[! DirectoryQ[DirectoryName[outputFile]],
  CreateDirectory[DirectoryName[outputFile], CreateIntermediateDirectories -> True]
];

normalizeJSONResult[raw_String] := Module[{trimmed, parsed},
  trimmed = StringTrim[raw];
  If[trimmed === "", Return[{}]];
  parsed = Quiet @ Check[ImportString[trimmed, "RawJSON"], $Failed];
  Which[
    parsed === $Failed, <|"Raw" -> trimmed|>,
    AssociationQ[parsed], {parsed},
    ListQ[parsed], parsed,
    True, {parsed}
  ]
];

getXPermProcessSnapshot[] := Module[{raw},
  raw = Quiet @ Check[
    RunProcess[
      {
        "cmd",
        "/c",
        "tasklist /FI \"IMAGENAME eq xperm.win64\" /FO CSV /NH"
      },
      "StandardOutput"
    ],
    ""
  ];
  Module[{trimmed, rows},
    trimmed = StringTrim[raw];
    If[
      trimmed === "" ||
      StringContainsQ[trimmed, "No tasks are running"],
      {},
      rows = Quiet @ Check[ImportString[trimmed, "CSV"], {}];
      Cases[
        rows,
        {name_String, pid_String, sessionName_String, sessionNum_String, memUsage_String} :>
          <|
            "ImageName" -> name,
            "ProcessId" -> pid,
            "SessionName" -> sessionName,
            "SessionNumber" -> sessionNum,
            "MemUsage" -> memUsage
          |>
      ]
    ]
  ]
];

kernelInfoAssociation[] := <|
  "KernelID" -> Quiet @ Check[$KernelID, Missing["NotAvailable"]],
  "ProcessID" -> $ProcessID,
  "FrontEndPresentQ" -> MatchQ[$FrontEnd, _LinkObject],
  "XPermLoadedQ" -> MemberQ[$Packages, "xAct`xPerm`"],
  "XPermConnectionAvailableQ" -> If[
    NameQ["xAct`xPerm`$xpermQ"],
    Quiet @ Check[ToExpression["xAct`xPerm`$xpermQ"], Missing["Unavailable"]],
    Missing["NotLoaded"]
  ],
  "XPermLinkHead" -> If[
    NameQ["xAct`xPerm`$xpermLink"],
    Quiet @ Check[Head[ToExpression["xAct`xPerm`$xpermLink"]], Missing["Unavailable"]],
    Missing["NotLoaded"]
  ]
|>;

subkernelInfoAssociation[] := If[
  Length[Kernels[]] == 0,
  {},
  Quiet @ Check[
    ParallelEvaluate[
      <|
        "KernelID" -> Quiet @ Check[$KernelID, Missing["NotAvailable"]],
        "ProcessID" -> $ProcessID,
        "XPermLoadedQ" -> MemberQ[$Packages, "xAct`xPerm`"],
        "XPermConnectionAvailableQ" -> If[
          NameQ["xAct`xPerm`$xpermQ"],
          Quiet @ Check[ToExpression["xAct`xPerm`$xpermQ"], Missing["Unavailable"]],
          Missing["NotLoaded"]
        ],
        "XPermLinkHead" -> If[
          NameQ["xAct`xPerm`$xpermLink"],
          Quiet @ Check[Head[ToExpression["xAct`xPerm`$xpermLink"]], Missing["Unavailable"]],
          Missing["NotLoaded"]
        ]
      |>
    ],
    Missing["ParallelEvaluateFailed"]
  ]
];

loadedKernelCount[main_Association, sub_] := Boole[TrueQ[main["XPermLoadedQ"]]] + Count[sub, _Association?(TrueQ[#["XPermLoadedQ"]] &)];

summaryTextFrom[data_Association] := Module[
  {
    subkernelCount, subkernelsWithXPerm, xpermProcessCount, likelyExplanation
  },
  subkernelCount = Length @ Replace[data["SubkernelInfo"], _Missing -> {}];
  subkernelsWithXPerm = Count[Replace[data["SubkernelInfo"], _Missing -> {}], _Association?(TrueQ[#["XPermLoadedQ"]] &)];
  xpermProcessCount = Length @ data["XPermProcessesAfter"];
  likelyExplanation = Which[
    xpermProcessCount == 0 && ! TrueQ[data["MainKernelInfoAfter"]["XPermLoadedQ"]] && subkernelsWithXPerm == 0,
      "xPerm is not currently loaded in the main kernel or any active subkernel.",
    xpermProcessCount == 0 &&
      (TrueQ[data["MainKernelInfoAfter"]["XPermLoadedQ"]] || subkernelsWithXPerm > 0),
      "xPerm is loaded in one or more kernels, but the in-kernel OS process probe returned zero. In that case the per-kernel xPerm-loaded flags are the authoritative part of this diagnostic.",
    xpermProcessCount <= loadedKernelCount[data["MainKernelInfoAfter"], Replace[data["SubkernelInfo"], _Missing -> {}]] &&
      loadedKernelCount[data["MainKernelInfoAfter"], Replace[data["SubkernelInfo"], _Missing -> {}]] > 1,
      "Multiple xperm windows are consistent with xPerm being loaded in multiple kernels/subkernels.",
    xpermProcessCount > loadedKernelCount[data["MainKernelInfoAfter"], Replace[data["SubkernelInfo"], _Missing -> {}]],
      "There are more xperm processes than kernels currently reporting xPerm. That suggests stale xperm processes or reconnects after dead links.",
    xpermProcessCount == 1 && subkernelCount == 0,
      "Single-kernel state: one Mathematica kernel is using one xperm process.",
    True,
      "Mixed state: inspect the per-kernel details to see which kernels have xPerm loaded."
  ];
  {
    "KernelVersion: " <> ToString[data["KernelVersion"], InputForm],
    "FrontEndPresentQ: " <> ToString[data["MainKernelInfoAfter"]["FrontEndPresentQ"], InputForm],
    "ProcessorCount: " <> ToString[data["ProcessorCount"], InputForm],
    "ActiveSubkernelCount: " <> ToString[subkernelCount, InputForm],
    "MainKernelXPermLoadedQ: " <> ToString[data["MainKernelInfoAfter"]["XPermLoadedQ"], InputForm],
    "SubkernelsWithXPermLoadedQ: " <> ToString[subkernelsWithXPerm, InputForm],
    "XPermProcessCount: " <> ToString[xpermProcessCount, InputForm],
    "LikelyExplanation: " <> likelyExplanation,
    "Artifact: " <> outputFile
  }
];

preProcesses = getXPermProcessSnapshot[];
mainBefore = kernelInfoAssociation[];

If[loadMainKernelXPermQ && ! TrueQ[mainBefore["XPermLoadedQ"]],
  Needs["xAct`xPerm`"];
  Pause[1];
];

mainAfter = kernelInfoAssociation[];
subInfo = subkernelInfoAssociation[];
postProcesses = getXPermProcessSnapshot[];

results = <|
  "GeneratedOn" -> DateString[{"ISODate", " ", "Time"}],
  "KernelVersion" -> System`$Version,
  "ProcessorCount" -> System`$ProcessorCount,
  "LoadMainKernelXPermDiagnosticQ" -> loadMainKernelXPermQ,
  "MainKernelInfoBefore" -> mainBefore,
  "MainKernelInfoAfter" -> mainAfter,
  "SubkernelInfo" -> subInfo,
  "XPermProcessesBefore" -> preProcesses,
  "XPermProcessesAfter" -> postProcesses
|>;

results = Append[results, "SummaryLines" -> summaryTextFrom[results]];

Put[results, outputFile];
Scan[Print, results["SummaryLines"]];

results
