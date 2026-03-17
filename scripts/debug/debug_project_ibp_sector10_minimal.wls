SetDirectory[DirectoryName[$InputFileName]];

Get["graviton_basis_toolkit.wl"];

expr = hbar*h[a, -a];
basis = {h[a, -a]};

Export["debug_project_ibp_sector10_minimal_step_1_expr.wl", expr, "Package"];
Export["debug_project_ibp_sector10_minimal_step_2_basis.wl", basis, "Package"];

ans = MakeAnsatz[basis, ConstantPrefix -> q];
Export["debug_project_ibp_sector10_minimal_step_3_ansatz.wl", ans, "Package"];

eq = canonExpr @ VarD[h[-m, -n], PD][ans - expr];
Export["debug_project_ibp_sector10_minimal_step_4_eq.wl", eq, "Package"];

proj = ProjectModuloIBP[expr, basis];
Export["debug_project_ibp_sector10_minimal_step_5_proj.wl", proj, "Package"];
