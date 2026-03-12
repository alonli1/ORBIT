SetDirectory["c:\\Users\\alonlif2000\\Desktop\\ORBIT"];
nb = Notebook[{Cell["Test PDF", "Title"], Cell["Hello", "Text"]}];
Export["pdf_export_test.nb", nb];
res = Check[Export["pdf_export_test.pdf", nb], $Failed];
Put[res, "pdf_export_test.out"];
Quit[];
