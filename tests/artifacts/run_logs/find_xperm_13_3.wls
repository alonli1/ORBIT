Print["KernelVersion=", $Version];
Needs["xAct`xPerm`"];
Print["xPermFindFile=", FindFile["xAct`xPerm`"]];
Print["xPermContextPathHasxAct=", MemberQ[$ContextPath, "xAct`xPerm`"]];
If[NameQ["xAct`xPerm`xperm"] , Print["xpermSymbolPresent=True"], Print["xpermSymbolPresent=False"]];
If[NameQ["xAct`xPerm`Private`xpermPath"], Print["xpermPathSymbolPresent=True"], Print["xpermPathSymbolPresent=False"]];
If[NameQ["xAct`xPerm`Private`xpermProcess"], Print["xpermProcessSymbolPresent=True"], Print["xpermProcessSymbolPresent=False"]];
Exit[];
