# Schreier–Sims algorithm — Ada 2023

Educational, self-contained Ada 2023 package for the **Schreier–Sims algorithm**
(Schreier 1927; Sims 1970): given generators of a finite permutation group
$G\le S_n$, compute a **base and strong generating set (BSGS)**, the group
**order**, and **membership** tests by sifting through Schreier-tree
transversals. See
[Wikipedia: Schreier–Sims algorithm](https://en.wikipedia.org/wiki/Schreier–Sims_algorithm).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series
(e.g. [Ada-Image-Based-Lighting](https://github.com/RobertBoettcherSF/Ada-Image-Based-Lighting)).

Sibling / related rows (README links only — **no** package `with`):

- **Todd–Coxeter** (coset enumeration; companion educational package)
- **Next (educational sketches):** Reidemeister–Schreier rewriting

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Domain** | permutations of $\{1,\ldots,n\}$, $n\le 10$ | `Permutation.Image` |
| **Input** | `Generator_List` of bijective maps | shared degree $N$ |
| **Core** | `Build_BSGS (Generators)` | stabilizer chain + Schreier trees |
| **Order** | product of orbit sizes | $\|G\|=\prod_i\|\beta_i^{G^{(i)}}\|$ |
| **Membership** | sift through transversals | `Contains (BSGS, Perm)` |
| **Domain errors** | `Invalid_Argument` | non-bijective / degree mismatch |

## Stabilizer chain intuition

A **base** for $G\le S_n$ is a sequence $B=(\beta_1,\ldots,\beta_k)$ of points
such that the pointwise stabilizer of all base points is trivial:

$$
G^{(1)}=G,\qquad
G^{(i+1)}=\{g\in G^{(i)}: \beta_i^g=\beta_i\},\qquad
G^{(k+1)}=\{1\}.
$$

A **strong generating set** relative to $B$ is a generating set that includes
generators for every $G^{(i)}$ in this chain.

### Orbit–stabilizer and order

At each level the orbit of the base point under $G^{(i)}$ satisfies

$$
\|G^{(i)}\| = \|\beta_i^{G^{(i)}}\| \cdot \|G^{(i+1)}\|,
$$

so the full group order is the product of the orbit sizes along the chain:

$$
\|G\| = \prod_{i=1}^{k} \|\beta_i^{G^{(i)}}\|.
$$

### Schreier trees and transversals

For each level $i$, a **Schreier tree** rooted at $\beta_i$ encodes a
**transversal** $\{u_\gamma\}$ of the cosets of $G^{(i+1)}$ in $G^{(i)}$:
$\beta_i^{u_\gamma}=\gamma$ for every $\gamma$ in the orbit. Edges are labelled
by strong generators; the path from the root to $\gamma$ multiplies to $u_\gamma$.

### Schreier lemma

If $S$ generates $G^{(i)}$ and $U$ is a transversal for the stabilizer of
$\beta_i$, then the **Schreier generators**

$$
\{ u\, s\, (u')^{-1} : u\in U,\ s\in S,\ u'\in U,\ \beta_i^{us}=\beta_i^{u'} \}
$$

generate $G^{(i+1)}$. The package builds the next level from those non-identity
Schreier generators (duplicates removed).

### Membership by sifting

To test $g\in G$, sift down the chain: at level $i$ let $\gamma=\beta_i^g$; if
$\gamma$ is not in the orbit, reject; otherwise replace
$g\leftarrow g\, u_\gamma^{-1}$ so the remnant fixes $\beta_i$. Accept iff the
final remnant is the identity.

### Complexity note (classroom)

With $n\le 10$ the naive Schreier–Sims variant used here is fine for teaching:
orbit BFS is $O(n\cdot\|S\|)$ per level, and the Schreier lemma may produce up
to $O(n\cdot\|S\|)$ candidates before filtering. Sharper implementations
(Jerrum’s filter, random Schreier–Sims, nearly linear time) reduce generator
blow-up; this package keeps the classical deterministic picture.

### Classroom identities

| Group | Generators (example) | Order |
| --- | --- | --- |
| $\{1\}$ | identity on $n$ letters | $1$ |
| $C_5$ | $(1\,2\,3\,4\,5)$ | $5$ |
| $S_3$ | $(1\,2),\ (1\,2\,3)$ | $6$ |
| $V_4$ | $(1\,2)(3\,4),\ (1\,3)(2\,4)$ | $4$ |
| $D_4\le S_4$ | $(1\,2\,3\,4),\ (2\,4)$ | $8$ |
| $A_4$ | $(1\,2\,3),\ (1\,2\,4)$ | $12$ |
| $S_4$ | $(1\,2),\ (2\,3),\ (3\,4)$ | $24$ |
| $A_5$ | $(1\,2\,3),\ (1\,2\,4),\ (1\,2\,5)$ | $60$ |
| $S_5$ | adjacent transpositions | $120$ |

## API

```ada
function Identity (N : Positive) return Permutation;
function Make_Permutation (Img : Image_Array; N : Positive) return Permutation;
function Compose (A, B : Permutation) return Permutation;  -- A then B
function Inverse (G : Permutation) return Permutation;
function Is_Identity (G : Permutation) return Boolean;

function Build_BSGS (Generators : Generator_List) return BSGS;
function Order (G : BSGS) return Long_Long_Integer;
function Contains (G : BSGS; Perm : Permutation) return Boolean;
function Base_Length (G : BSGS) return Natural;
function Base_Point (G : BSGS; I : Positive) return Point;
```

Raises `Invalid_Argument` on non-bijective maps, inconsistent degrees, empty
generator lists, or out-of-range degree ($N\notin 1..\mathtt{Max\_N}$).

## Build and test

```bash
make        # gnatmake -gnatwa -gnat2022 -Pschreier_sims.gpr
make test   # prints Results: N PASS, 0 FAIL
make clean
```

## License

Educational sample for the RobertBoettcherSF Ada series. Use freely with
attribution.
