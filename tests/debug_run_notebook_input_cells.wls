scriptDir = DirectoryName[$InputFileName];
repoRoot = NestWhile[
  DirectoryName,
  scriptDir,
  ! FileExistsQ[FileNameJoin[{#, "orbit_fixed_eh_comparison.wl"}]] &
];
SetDirectory[repoRoot];

If[! StringStartsQ[System`$Version, "13.3"],
  Print["FAIL: This debug runner must use Mathematica 13.3. Current kernel: " <> System`$Version];
  Exit[2]
];

normalizeNotebookPath[path_String] := If[
  StringMatchQ[path, (LetterCharacter ..) ~~ ":" ~~ __] || StringStartsQ[path, "\\"],
  path,
  FileNameJoin[{repoRoot, path}]
];

notebookPath = Which[
  Length[$ScriptCommandLine] >= 2, normalizeNotebookPath[$ScriptCommandLine[[2]]],
  StringLength[Environment["ORBIT_NOTEBOOK_TO_RUN"]] > 0, normalizeNotebookPath[Environment["ORBIT_NOTEBOOK_TO_RUN"]],
  True, Missing["NotebookPathNotProvided"]
];

If[notebookPath === Missing["NotebookPathNotProvided"],
  Print["FAIL: Provide notebook path either as a script argument or in ORBIT_NOTEBOOK_TO_RUN."];
  Exit[2]
];

If[! FileExistsQ[notebookPath],
  Print["FAIL: Notebook not found: " <> notebookPath];
  Exit[2]
];

nbExpr = Get[notebookPath];
inputCells = Cases[nbExpr, Cell[s_String, "Input", ___] :> s, Infinity];

Print["Notebook: " <> notebookPath];
Print["Input cell count: " <> ToString[Length[inputCells]]];

Begin["NotebookDebug`"];
allPassed = True;
results = {};
End[];

MapIndexed[
  With[{cellText = #1, cellIndex = #2[[1]]},
    Module[{held, result, status = "PASS", timing},
      Print["--- Running input cell " <> ToString[cellIndex] <> " ---"];
      {timing, result} = AbsoluteTiming @ Check[
        held = ToExpression["(" <> cellText <> ")", InputForm, HoldComplete];
        ReleaseHold[held],
        status = "FAIL";
        NotebookDebug`allPassed = False;
        $Failed
      ];
      If[! StringQ[status], status = "PASS"];
      AppendTo[
        NotebookDebug`results,
        <|
          "CellIndex" -> cellIndex,
          "Status" -> status,
          "TimingSeconds" -> timing,
          "Result" -> result
        |>
      ];
      Print["Status: " <> status];
      Print["TimingSeconds: " <> ToString[timing, InputForm]];
      Print["Result: " <> ToString[result, InputForm]];
    ]
  ] &,
  inputCells
];

Print["=== Summary ==="];
Print["AllPassedQ: " <> ToString[NotebookDebug`allPassed, InputForm]];
Print["ResultsAssociation: " <> ToString[NotebookDebug`results, InputForm]];

If[! TrueQ[NotebookDebug`allPassed], Exit[1]];
