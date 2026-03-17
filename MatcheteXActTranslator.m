(* ::Package:: *)

(* :Title: MatcheteXActTranslator *)
(* :Context: MatcheteXActTranslator` *)
(* :Summary: Utilities to translate expressions between Matchete and xAct xTensor syntax. *)

BeginPackage["MatcheteXActTranslator`"];

MatcheteToXAct::usage =
  "MatcheteToXAct[expr, translationRules] converts a Matchete expression to xAct xTensor syntax, automatically alternating index signs to avoid duplicate upper/lower clashes.";
XActToMatchete::usage =
  "XActToMatchete[expr, translationRules] converts an xAct xTensor expression back to Matchete syntax.";
LoadMatcheteMXExpression::usage =
  "LoadMatcheteMXExpression[file] loads a Matchete .mx dump and returns the primary expression stored in it. LoadMatcheteMXExpression[file, symbol] returns the value of the specified symbol, such as LEFT0.";
ExportMatcheteMXToXAct::usage =
  "ExportMatcheteMXToXAct[mxFile, outFile, translationRules] loads a Matchete .mx dump, translates it to xAct syntax, and writes the resulting Wolfram Language expression to outFile.";

Begin["`Private`"];

PD = xAct`xTensor`PD;
LI = xAct`xTensor`LI;

LoadMatcheteMXExpression::nosymbol =
  "Loading `1` did not introduce any new Global` symbols with stored expressions.";
LoadMatcheteMXExpression::ambiguous =
  "Loading `1` introduced multiple Global` symbols with stored expressions: `2`. Returning `3`.";
LoadMatcheteMXExpression::badsymbol =
  "Symbol `2` was not found in Global` after loading `1`.";

stripGlobalContext[name_String] := StringReplace[name, StartOfString ~~ "Global`" -> ""];
symbolSpecName[s_Symbol] := SymbolName[Unevaluated[s]];
symbolSpecName[s_String] := stripGlobalContext[s];

storedExpressionQ[name_String] := Head[ToExpression[name]] =!= Symbol;

normalizeMatcheteSymbol[s_Symbol, translationRules_] := With[{mapped = s /. translationRules},
  Replace[mapped, sym_Symbol /; Context[sym] === "Matchete`" :> Symbol[SymbolName[sym]], {0}]
];

normalizeMatcheteScalars[expr_, translationRules_] :=
  expr /. s_Symbol /; Context[s] === "Matchete`" :> normalizeMatcheteSymbol[s, translationRules];

matcheteToXActHeads = <|
  "LeviCivitaSymbol" -> "EpsilonSymbol",
  "Metric" -> "Metric",
  "KroneckerDelta" -> "Delta",
  "ChristoffelSymbol" -> "Christoffel",
  "RicciTensor" -> "Ricci",
  "RiemannTensor" -> "Riemann"
|>;

xActToMatcheteHeads = Association[Reverse /@ Normal[matcheteToXActHeads]];

translateHeads[expr_, mapping_] := expr /. {
  h_Symbol[args__] /; KeyExistsQ[mapping, SymbolName[h]] :>
    ToExpression[mapping[SymbolName[h]]] @@ (translateHeads[#, mapping] & /@ {args})
};

sanitizeIndices[idxs_] := If[MatchQ[idxs, {idx_, idx_}], {idxs[[1]], -idxs[[2]]}, idxs];

translateField[Matchete`Field[name_, type_, {}, derivsRaw_List], translationRules_] := Module[
  {idxsRaw, derivs, idxs, translatedName, base},
  derivs = First /@ derivsRaw;
  idxsRaw = If[Head[type] === Matchete`Graviton, List @@ type, {}];
  idxs = First /@ idxsRaw;
  translatedName = name /. translationRules;
  base = If[idxs === {}, translatedName[], translatedName @@ sanitizeIndices[idxs]];
  Fold[Function[{expr, idx}, PD[idx][expr]], base, derivs]
];

translateCoupling[Matchete`Coupling[name_, {}, _], translationRules_] := name /. translationRules;

lowerAllIndices[expr_] := expr /. {
  PD[i_][sub_] :> PD[-i][lowerAllIndices[sub]],
  h_Symbol[idx1_, idx2_] :> h[-idx1, -idx2]
};

sanitizeMonomial[term_] := Module[{counts, excludeHeads, fIdx, indexSubstitution},
  counts = <||>;
  excludeHeads = {Plus, Times, PD, Rational, Power};

  fIdx[idx_Symbol] := (
    counts[idx] = Lookup[counts, idx, 0] + 1;
    If[counts[idx] == 1, idx, -idx]
  );

  indexSubstitution[term1_] := term1 /. {
    PD[i_][sub_] :> PD[fIdx[i]][indexSubstitution[sub]],
    h_Symbol[inds__] /; (! MemberQ[excludeHeads, h] && And @@ (MatchQ[#, _Symbol] & /@ {inds})) :>
      h @@ (fIdx /@ {inds})
  };

  indexSubstitution[term] /. {
    h_Symbol[idx1_, idx2_]^2 :> h[idx1, idx2] h[-idx1, -idx2],
    PD[i_][sub_]^2 :> PD[i][sub] lowerAllIndices[PD[i][sub]]
  }
];

translateTermMatchete[term_, translationRules_] := Module[{expr = term},
  expr = expr //. {
    f_Matchete`Field :> translateField[f, translationRules],
    c_Matchete`Coupling :> translateCoupling[c, translationRules]
  };
  translateHeads[expr, matcheteToXActHeads]
];

MatcheteToXActInternal[expr_Plus, translationRules_] :=
  normalizeMatcheteScalars[
    Plus @@ (sanitizeMonomial[translateTermMatchete[#, translationRules]] & /@ List @@ expr),
    translationRules
  ];

MatcheteToXActInternal[expr_, translationRules_] :=
  normalizeMatcheteScalars[
    sanitizeMonomial[translateTermMatchete[expr, translationRules]],
    translationRules
  ];

MatcheteToXAct[expr_, translationRules_ : {}] :=
  MatcheteToXActInternal[Distribute[expr, Plus], translationRules];

LoadMatcheteMXExpression[file_, symbolSpec_ : Automatic] := Module[
  {before, after, created, expressionSymbols, selected},
  before = Names["Global`*"];
  Get[file];
  after = Names["Global`*"];

  If[symbolSpec =!= Automatic,
    selected = symbolSpecName[symbolSpec];
    If[! MemberQ[after, selected],
      Message[LoadMatcheteMXExpression::badsymbol, file, selected];
      Return[$Failed]
    ];
    Return[ToExpression[selected]]
  ];

  created = Complement[after, before];
  expressionSymbols = Select[created, storedExpressionQ];

  Which[
    Length[expressionSymbols] == 1,
      ToExpression[First[expressionSymbols]],
    Length[expressionSymbols] > 1,
      selected = First[expressionSymbols];
      Message[LoadMatcheteMXExpression::ambiguous, file, expressionSymbols, selected];
      ToExpression[selected],
    True,
      Message[LoadMatcheteMXExpression::nosymbol, file];
      $Failed
  ]
];

ExportMatcheteMXToXAct[mxFile_, outFile_, translationRules_ : {}, symbolSpec_ : Automatic] := Module[
  {expr, xExpr},
  expr = LoadMatcheteMXExpression[mxFile, symbolSpec];
  If[expr === $Failed, Return[$Failed]];
  xExpr = MatcheteToXAct[expr, translationRules];
  Put[xExpr, outFile];
  xExpr
];

stripMinus[x_] := x /. {-a_ -> a};

replaceCD[expr_] := expr /. {
  PD[idx_][val_] :> CD[stripMinus[idx], replaceCD[val]],
  CD[idx_][val_] :> CD[stripMinus[idx], replaceCD[val]]
};

XActToMatcheteInternal[expr_, translationRules_] := replaceCD[
  (expr /. {
      hh_[LI[order_], idx1_, idx2_] :>
        If[order == 1, (hh /. translationRules)[stripMinus[idx1], stripMinus[idx2]], 0]
    } /. {
      hh_[idx1_, idx2_] /; MatchQ[hh, Alternatives @@ (First /@ translationRules)] :>
        (hh /. translationRules)[stripMinus[idx1], stripMinus[idx2]]
    } /. translationRules)
];

XActToMatchete[expr_Plus, translationRules_ : {}] :=
  Plus @@ ((XActToMatchete[#, translationRules] &) /@ List @@ expr);

XActToMatchete[expr_, translationRules_ : {}] := Module[{converted = expr},
  converted = translateHeads[converted, xActToMatcheteHeads];
  XActToMatcheteInternal[converted, translationRules]
];

End[];
EndPackage[];
