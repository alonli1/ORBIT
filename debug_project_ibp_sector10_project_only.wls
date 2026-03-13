SetDirectory[DirectoryName[$InputFileName]];

Get["graviton_basis_toolkit.wl"];

expr = hbar*h[a, -a];
basis = {h[a, -a]};
proj = ProjectModuloIBP[expr, basis];

Export["debug_project_ibp_sector10_project_only.wl", proj, "Package"];
