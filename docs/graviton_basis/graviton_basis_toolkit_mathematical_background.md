# Graviton Basis Toolkit Mathematical Background

This note explains the mathematics behind the toolkit independently of the implementation details in `graviton_basis_toolkit.wl`.

## 1. What space is being classified?

Fix two integers:

- `nh`: number of graviton fields `h_{mu nu}`
- `Nd`: total number of derivatives

Define `V_{nh,Nd}` to be the vector space of local scalar expressions built from:

- `nh` copies of the symmetric field `h_{mu nu}`,
- `Nd` partial derivatives,
- the flat metric `eta_{mu nu}`,

modulo the index symmetries of `h` and the obvious tensor identities coming from canonical index manipulations.

The toolkit works sector by sector in these spaces `V_{nh,Nd}`.

## 2. Why the sector grading matters

IBP and the field-redefinition quotient preserve the pair `{nh, Nd}`:

- Integration by parts only redistributes derivatives among the fields.
- The image of a field redefinition in the Fierz-Pauli kinetic term shifts `{nh-1, Nd-2}` rank-2 tensors into scalar operators in sector `{nh, Nd}`.

So the classification problem decomposes into independent finite-dimensional linear algebra problems on each `V_{nh,Nd}`.

## 3. Raw operators

The first step is to build a spanning set for `V_{nh,Nd}`.

One distributes the `Nd` derivatives among the `nh` graviton fields in all ordered ways:

`Nd = k_1 + ... + k_nh`

with each `k_i >= 0`.

For each ordered tuple `(k_1, ..., k_nh)`, form a monomial of the schematic type

`(d^k1 h) (d^k2 h) ... (d^knh h)`

and then contract all indices in all possible scalar ways using the flat metric.

After canonicalization, the resulting list spans `V_{nh,Nd}`. This is the raw basis in the code.

## 4. Integration by parts as a quotient

Two Lagrangians that differ by a total derivative define the same action. Therefore the physically relevant space is not `V_{nh,Nd}` itself but the quotient

`V_{nh,Nd} / T_{nh,Nd}`

where `T_{nh,Nd}` is the subspace of total derivatives.

The key fact used by the toolkit is:

A local scalar density `L` is a total derivative if and only if its Euler-Lagrange derivative with respect to the field vanishes:

`delta L / delta h_{mu nu} = 0`.

So the IBP relations are exactly the null vectors of the linear map

`E : V_{nh,Nd} -> W_{nh-1,Nd}`

defined by the Euler operator.

This is why the code builds a general linear combination of raw basis elements and solves

`VarD[h][L] = 0`.

The quotient basis modulo IBP is then any basis of the vector space

`V_{nh,Nd} / ker(E)`.

## 5. Field redefinitions as an image quotient

Now consider a field redefinition

`h_{mu nu} -> h_{mu nu} + Delta h_{mu nu}`

where `Delta h_{mu nu}` is a local symmetric rank-2 tensor built from `h` and derivatives.

At first order, the quadratic Fierz-Pauli Lagrangian changes by

`delta L_FP = E_FP^{mu nu} Delta h_{mu nu} + d_mu K^mu`

where `E_FP^{mu nu}` is the linearized equation-of-motion operator.

Therefore every operator of the form

`E_FP^{mu nu} Delta h_{mu nu}`

is redundant up to a total derivative. These operators span a subspace

`R_{nh,Nd} subset V_{nh,Nd} / T_{nh,Nd}`

inside the IBP quotient.

The final interaction-space classification is therefore

`(V_{nh,Nd} / T_{nh,Nd}) / R_{nh,Nd}`.

This is the mathematical meaning of the toolkit's `PhysicalBasis`.

## 6. Why the redefinition source sector is `{nh-1, Nd-2}`

The Fierz-Pauli kinetic operator is quadratic and carries:

- one extra graviton relative to `Delta h`,
- two extra derivatives.

So if `Delta h` lies in a rank-2 sector with:

- `nhRedef = nh - 1`
- `NdRedef = Nd - 2`

then its image in `delta L_FP` lands in scalar sector `{nh, Nd}`.

That is the origin of the shift used in the code.

## 7. Quotient geometry

The logic can be pictured as:

1. Start with the full raw operator space `V_{nh,Nd}`.
2. Mod out by total derivatives `T_{nh,Nd}`.
3. Inside the IBP quotient, identify the field-redefinition image `R_{nh,Nd}`.
4. Mod out by that image to obtain the final interaction basis.

Schematically:

`V_{nh,Nd} -> V_{nh,Nd} / T_{nh,Nd} -> (V_{nh,Nd} / T_{nh,Nd}) / R_{nh,Nd}`.

This is why the dimensions in the code are reported as:

- `RawCount`
- `IBPCount`
- `RedefRank`
- `PhysicalCount`

with

`PhysicalCount = IBPCount - RedefRank`

for interaction sectors where the image is actually quotiented.

## 8. Why quadratic sectors are special

At quadratic order, quotienting by linear field redefinitions is mathematically possible but conceptually dangerous.

The reason is that a linear rescaling

`h_{mu nu} -> h_{mu nu} + a h_{mu nu}`

changes the quadratic action by a multiple of the quadratic action itself. If one modded out by those directions, even the normalization and some of the structure of the kinetic term would be treated as redundant.

For operator-basis classification at interaction order that is fine; for the kinetic sector it is usually not the desired equivalence relation.

So the toolkit uses:

- quadratic sectors: quotient by IBP only,
- interaction sectors: quotient by IBP and field redefinitions.

## 9. Relation to gauge invariance

The toolkit does not automatically impose linearized diffeomorphism invariance.

That means the final interaction basis is a basis modulo:

- total derivatives,
- field redefinitions,

but not necessarily modulo gauge symmetry.

For example, at quadratic four-derivative order, the full IBP quotient is larger than the subspace spanned by curvature-squared invariants. The curvature-squared subspace is the gauge-invariant part of that larger space.

## 10. Why the Euler operator test works

The IBP criterion is not just a computational trick. It is the variational statement that on local functionals the Euler operator annihilates exactly the total derivatives.

So the toolkit uses the vanishing of `VarD` as an exact characterization of IBP triviality. This is why derivative canonicalization is so important: if two equivalent expressions are not put into the same normal form before `VarD` is compared, one can create fake nontrivial classes.

## 11. What the validation test proves

The strongest current validation test constructs an expression that is known mathematically to lie in the redefinition image:

`L_test = E_FP^{mu nu} Delta h_{mu nu}`

for a generic `Delta h_{mu nu}` in sector `{2,2}`, which maps into scalar sector `{3,4}`.

The test then expands `L_test` into a 240-term scalar Lagrangian and feeds it into `ReduceLagrangian`.

The fact that the reducer returns exactly zero means the implemented quotient really is removing the image of the field-redefinition map, not merely a small hand-picked subset.

## 12. Mental model

The toolkit is best understood as implementing two exact linear-algebra constructions:

1. a kernel quotient for IBP,
2. an image quotient for field redefinitions.

Everything else in the code exists to build explicit finite-dimensional matrices for those two operations.
