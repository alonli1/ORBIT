$LoadMainKernelXPermDiagnostic = True;
$XPermKernelDiagnosticOutputFile = FileNameJoin[{
  Directory[],
  "tests",
  "artifacts",
  "xperm_kernel_diagnostic_script_baseline_13_3.wl"
}];
Get[FileNameJoin[{Directory[], "tests", "diagnose_xperm_kernel_state.wls"}]];
Exit[];
