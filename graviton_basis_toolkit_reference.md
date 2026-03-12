# Graviton Basis Toolkit Reference

This document explains the implementation in `graviton_basis_toolkit.wl` as code, not just as theory. The companion PDF files explain the operator-basis logic from the EFT side. This file explains how that logic is realized in the Wolfram/xAct code.

## Scope

The toolkit does three things:

1. Generate a raw scalar basis sector by sector.
2. Quotient that basis by integration by parts (IBP).
3. Quotient the interaction sectors by the image of linearized Fierz-Pauli field redefinitions.

It also now provides two reducer entry points:

- `ReduceSectorLagrangian[expr, nh, Nd, ...]`
- `ReduceLagrangian[expr, ...]`

These return a representative of an input Lagrangian modulo IBP and, for interaction sectors, modulo field redefinitions.

## Sector convention

The basic grading is by:

- `nh`: number of graviton fields `h`
- `Nd`: total number of derivatives `PD`

A sector is labeled by `{nh, Nd}`. The total engineering dimension tracked by the code is:

`D = nh + Nd`

Everything in the toolkit is organized sector by sector because:

- raw basis generation is finite sector by sector,
- IBP relations never mix sectors,
- the Fierz-Pauli field-redefinition image also stays inside a fixed target sector.

## File structure

`graviton_basis_toolkit.wl` is organized into these blocks:

1. Public entry points and options.
2. xAct setup.
3. Utilities and cache helpers.
4. Fierz-Pauli quadratic Lagrangian.
5. Raw monomial and basis generation.
6. IBP quotient.
7. Field-redefinition image.
8. Extraction of explicit redefinition rules.
9. Full sector assembly.
10. Lagrangian reduction helpers.
11. Summary/export helpers.
12. Convenience accessors.
13. Master driver and example usage.

## xAct setup

The code defines:

- a 4D manifold `M`,
- a flat metric `eta`,
- the partial derivative operator `PD`,
- the symmetric graviton `h[-a, -b]`,
- an auxiliary symmetric tensor `dh[-a, -b]` used while differentiating the kinetic term with respect to a field redefinition,
- a probe tensor `probe[-a, -b]` used to generate rank-2 bases,
- a constant symbol `lam` used to expand `h -> h + lam dh`.

The line

`$CommuteCovDsOnScalars = True;`

is essential. The code works in flat space on scalar-density expressions. If scalar covariant derivatives are not forced to commute, xAct may leave expanded total derivatives in a form that the Euler operator does not recognize as zero, which corrupts the IBP quotient.

## Canonicalization strategy

The function `canonExpr` is the central normal-form map:

1. expand the expression,
2. contract metrics,
3. canonicalize tensor symmetries,
4. sort nested `PD` operators,
5. canonicalize again,
6. collect tensor structures.

This second canonicalization pass after derivative sorting is important. Without it, expressions that differ only by reordering commuting scalar derivatives can survive as fake independent terms.

`canonList` just applies `canonExpr` to a list and removes duplicates.

## Ordered derivative partitions

Raw monomials are generated from ordered derivative partitions using:

`CompositionList[n, k]`

This returns all ordered `k`-tuples of nonnegative integers summing to `n`. Ordered partitions matter because the graviton fields are distinguishable before canonicalization. For example, at cubic order with two derivatives, both derivative placements

- `{0, 1, 1}`
- `{0, 0, 2}`

must be generated before xAct identifies equivalences.

## Raw scalar basis

The raw scalar-basis algorithm is:

1. Build a derivative-decorated graviton for each entry in a partition:
   `MakeFieldWithKDerivs[h, k]`.
2. Multiply the decorated fields together:
   `ScalarMonomialFromPartition`.
3. For every ordered partition of `Nd` among `nh` gravitons, generate all contractions with `AllContractions`.
4. Canonicalize and deduplicate the result.

This gives `RawScalarBasis[nh, Nd, ...]`.

Odd-derivative scalar sectors are skipped. A fully contracted scalar built only from the flat metric, symmetric gravitons, and derivatives must have an even total number of indices. Since each graviton contributes two indices, odd `Nd` sectors cannot produce scalar monomials in this setup.

## Rank-2 basis for field redefinitions

Field redefinitions require a rank-2 tensor basis rather than a scalar basis. The code constructs it by:

1. inserting a symmetric `probe[A, B]`,
2. generating all scalar probe monomials,
3. differentiating with respect to the probe:
   `VarD[probe[-u, -v], PD][probeScalar]`

The result is `Rank2Basis[nhRedef, NdRedef, ...]`, a basis of candidate `delta h_{uv}` tensors with:

- `nhRedef` graviton fields,
- `NdRedef` derivatives.

These are the possible field redefinitions whose image lands in the target scalar sector.

## IBP quotient algorithm

This is implemented by `IBPData`.

Given a raw scalar basis `B_i`, build a generic ansatz:

`ans = Sum[c_i B_i]`

Then apply the Euler-Lagrange operator with respect to the graviton:

`VarD[h[-m, -n], PD][ans]`

A scalar density is a total derivative if and only if its Euler derivative vanishes. So the code solves:

`VarD[h][ans] == 0`

for the coefficients `c_i`.

This gives the space of IBP relations. The code converts the solution into a relation matrix:

- columns correspond to raw basis elements,
- each row is one linear relation among them.

Then `QuotientBasisFromRelations` takes pivot columns of that relation matrix and deletes those pivot basis elements. The remaining basis is the quotient basis modulo IBP.

### Why `SafeSolveConstants` exists

`SolveConstants` can return:

- a list of rules,
- an empty list,
- or structurally awkward outputs on trivial equations.

`SafeSolveConstants` normalizes these cases so the rest of the code can treat the result uniformly.

### Why free parameters need special handling

For identities such as `0 == 0`, the coefficients are all unconstrained. If this is not handled carefully, the code can mistake "all coefficients are free" for "no relations exist". The current version explicitly reconstructs the free parameter set and relation matrix from the unsolved coefficients.

## Projection onto the IBP basis

`ProjectModuloIBP[expr, basis]` solves for coordinates `q_i` in:

`expr ~ Sum[q_i basis_i]`

again by demanding the Euler derivative of the difference to vanish:

`VarD[h][ans - expr] == 0`

The result includes:

- the projected expression in the IBP basis,
- its coordinate vector,
- the raw `SolveConstants` solution.

For a genuine basis, these coordinates are unique. Any unsolved `q_i` are explicitly set to zero so the returned coordinate vector is numeric/exact rather than symbolic.

## Field-redefinition image

This is implemented by `ShiftFromRedefExpr` and `RedefinitionImageData`.

### Image of one field redefinition

To compute the image of a rank-2 tensor `deltaExpr[u, v]`, the code expands:

`LFP[h + lam dh]`

extracts the coefficient linear in `lam`, and then replaces `dh` by `deltaExpr`.

This is the standard first-order variation of the quadratic Fierz-Pauli action:

`delta L = EOM^{mu nu} delta h_{mu nu} + total derivative`

So every such image is redundant in the EFT sense and must be quotiented out.

### Building the full image

For a target scalar sector `{nh, Nd}`, the relevant field redefinitions have:

- `nhRedef = nh - 1`
- `NdRedef = Nd - 2`

because the quadratic kinetic term contributes one graviton and two derivatives.

The code:

1. builds `deltaBasis = Rank2Basis[nh - 1, Nd - 2]`,
2. computes each image with `ShiftFromRedefExpr`,
3. projects each image into the IBP basis,
4. stores the resulting coordinate vectors,
5. takes independent rows of the image matrix,
6. computes the rank and pivot columns.

The surviving physical basis is obtained by deleting pivot columns from the IBP basis.

## Why quadratic sectors are treated differently

The current code intentionally skips the field-redefinition quotient for sectors with `nh < 3`.

Reason: at quadratic order, linear field redefinitions act on the kinetic operator itself. Quotienting the quadratic sector by those directions removes, among other things, simple rescalings of the Fierz-Pauli term. That is not usually the desired notion of equivalence when classifying the kinetic structure.

So:

- quadratic sectors are reduced modulo IBP only,
- interaction sectors are reduced modulo IBP and field redefinitions.

This is why `{2, 2}` now has `PhysicalCount = 4` rather than being artificially reduced further.

## Full sector assembly

`ComputeSectorData[nh, Nd, ...]` is the main per-sector routine. It computes and stores:

- raw basis and raw count,
- IBP relation data,
- IBP quotient basis and count,
- field-redefinition image data,
- independent redefinition rules,
- physical basis and physical count.

All sector data is cached on disk so repeated runs only recompute what is missing.

## Lagrangian reduction API

### `ReduceSectorLagrangian`

This is the sector-local reducer.

Input:

- a scalar expression `expr`,
- explicit sector label `{nh, Nd}`.

Algorithm:

1. canonicalize the input,
2. compute/load sector data,
3. project the input into the IBP basis,
4. subtract the field-redefinition image component,
5. return the remaining physical representative.

Returned association fields include:

- `"ProjectedIBPExpression"`
- `"ProjectedIBPCoordinates"`
- `"ReducedIBPExpression"`
- `"ReducedIBPCoordinates"`
- `"PhysicalBasis"`
- `"PhysicalCoordinates"`
- `"RedefinitionImageExpression"`
- `"RedefinitionImageCoefficients"`
- `"ReducedExpression"`

### `ReduceLagrangian`

This is the automatic multi-sector reducer.

Algorithm:

1. canonicalize and expand the input,
2. split the sum term by term into sectors using `TermSectorKey` and `SplitTermsBySector`,
3. call `ReduceSectorLagrangian` separately on each sector,
4. sum the reduced representatives,
5. return the total reduced expression together with the per-sector reductions.

This is the function to use for a general Lagrangian containing several sectors at once.

## Accessors and summaries

The file also provides:

- `RawBasisOfSector`
- `IBPBasisOfSector`
- `PhysicalBasisOfSector`
- `RedefinitionsOfSector`
- `RedefinitionRulesOfSector`
- `SectorSummaryTable`
- `PrintSectorSummary`
- `ExportSummaryCSV`
- `ExportSummaryMX`

These are convenience layers over the cached sector associations.

## Caching

Each expensive object is cached separately:

- raw scalar bases,
- rank-2 bases,
- redefinition image data,
- full sector data.

The cache key uses sector labels such as `{nh, Nd}` or the corresponding association fields. This makes partial reruns practical and allows `RunBasisComputation` and the reducer API to reuse the same intermediate data.

## Known conventions and limitations

1. The code works in flat space with the xAct/xTras setup defined in the file.
2. It classifies operators modulo IBP and Fierz-Pauli field redefinitions; it does not automatically impose gauge invariance.
3. Quadratic sectors are intentionally not quotiented by field redefinitions.
4. Odd-`Nd` scalar sectors are empty in this setup.
5. The current automatic sector splitter assumes the input is a scalar expression built from the same `h`, `eta`, and `PD` conventions used by the toolkit.

## Recommended mental model

Use the toolkit as a linear algebra machine on each sector:

- generate a raw spanning set,
- identify the IBP null space with the Euler operator,
- choose an IBP quotient basis,
- compute the field-redefinition image inside that quotient basis,
- remove that image to obtain a physical representative.

That is exactly what the implementation does.
