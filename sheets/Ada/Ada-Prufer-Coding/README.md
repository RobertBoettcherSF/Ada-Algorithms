# Prüfer Coding in Ada 2023

## Project Overview

A **Prüfer sequence** (also Prüfer code or Prüfer numbers) of a **labeled
tree** on $n$ vertices is a unique sequence of length $n-2$ over the
labels $\{1,\ldots,n\}$. Heinz Prüfer introduced the coding in 1918 to
prove **Cayley's formula**. Encode iteratively removes the leaf of
smallest label and records its neighbour; Decode rebuilds the unique
tree from any sequence of length $n-2$. The resulting bijection shows
that there are exactly $n^{n-2}$ labeled trees on $n$ vertices.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation: vertices indexed from $1$, an undirected labeled tree
built with `Clear` / `Add_Edge`, `Encode` → Prüfer sequence,
`Decode` / `Decode_Edges` → rebuild tree or edge list, round-trip
identity up to edge order, fixed arrays (no dynamic heap) sized to
$\mathrm{Max\_Vertices}$, and `Cayley_Count` for small-$n$ checks.
The Ada package identifier is ASCII `Prufer_Coding` (umlaut only in
prose).

Primary source:
[Wikipedia — Prüfer sequence](https://en.wikipedia.org/wiki/Pr%C3%BCfer_sequence).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with algorithm siblings

| Package / method | Idea |
| --- | --- |
| **This package** (`Ada-Prufer-Coding`) | Bijection labeled trees $\leftrightarrow$ sequences of length $n-2$ |
| Minimum spanning tree (sibling sheet) | Weighted spanning trees of general graphs (Kruskal / Prim / …) |
| Tarjan offline LCA (sibling sheet) | Lowest common ancestors on a **rooted** tree |

README links only — **no** package `with` of siblings. Prüfer coding
enumerates / samples **labeled** trees on the complete graph $K_n$;
MST packages optimize weight on a given edge set.

## Cayley's formula

The Prüfer map is a bijection between:

- labeled trees on vertices $\{1,\ldots,n\}$, and
- sequences of length $n-2$ with entries in $\{1,\ldots,n\}$.

The set of such sequences has size $n^{n-2}$, therefore:

$$
\begin{align*}
\#\{\text{labeled trees on } n \text{ vertices}\}
&= n^{n-2}.
\end{align*}
$$

Conventions used here: $\mathrm{Cayley\_Count}(0)=0$,
$\mathrm{Cayley\_Count}(1)=1$, $\mathrm{Cayley\_Count}(2)=1$. For
$3\le n\le 8$ the helper returns $n^{n-2}$ (educational overflow guard
beyond $n=8$).

A degree refinement: the number of labeled trees with specified degrees
$d_1,\ldots,d_n$ equals the multinomial

$$
\binom{n-2}{d_1-1,\,d_2-1,\,\ldots,\,d_n-1}
= \frac{(n-2)!}{(d_1-1)!(d_2-1)!\cdots(d_n-1)!},
$$

because label $i$ appears exactly $d_i-1$ times in the Prüfer sequence.

## Algorithm

### Encode (tree → sequence)

Given a labeled tree $T$ on vertices $\{1,\ldots,n\}$:

1. Repeat $n-2$ times:
   - Let $\ell$ be the leaf (degree $1$) of **smallest** label.
   - Append the unique neighbour of $\ell$ to the sequence.
   - Remove $\ell$ (and its incident edge) from $T$.
2. Stop when two vertices remain. The sequence has length $n-2$.

Vacuous cases: $n\le 1$ yields the empty sequence; $n=2$ (single edge)
also yields the empty sequence.

### Decode (sequence → tree)

Let $A=[a_1,\ldots,a_{n-2}]$ with each $a_i\in\{1,\ldots,n\}$ and
$n=|A|+2$:

1. Set $\mathrm{degree}[v]\leftarrow 1$ for every vertex; then for each
   value $a$ in $A$, increment $\mathrm{degree}[a]$.
2. For $i = 1,\ldots,n-2$: let $j$ be the least label with
   $\mathrm{degree}[j]=1$; add edge $\{j,a_i\}$; decrement both degrees.
3. Add the edge between the two remaining degree-$1$ vertices.

Every sequence maps to a unique labeled tree; Encode is its inverse.

### Pseudocode

```text
function Encode(T):                    -- T labeled tree on 1..n
    S := empty sequence
    repeat n-2 times:
        ℓ := smallest leaf of T
        append neighbour(ℓ) to S
        remove ℓ from T
    return S

function Decode(A):                    -- A = [a1..a_{n-2}], n = |A|+2
    for v in 1..n: degree[v] := 1
    for a in A: degree[a] := degree[a] + 1
    T := empty graph on 1..n
    for a in A:
        j := smallest v with degree[v] = 1
        add edge {j, a} to T
        degree[j] -= 1; degree[a] -= 1
    add edge between the two remaining degree-1 vertices
    return T
```

### Example

Wikipedia-style tree on vertices $\{1,\ldots,6\}$ with edges
$\{1,4\},\{2,4\},\{3,4\},\{4,5\},\{5,6\}$:

- Remove leaf $1$ → record $4$; remove $2$ → record $4$; remove $3$ →
  record $4$; remove $4$ → record $5$.
- Prüfer sequence $[4,4,4,5]$.
- Decode recovers the same edge set (order may differ).

### Asymptotic cost

With adjacency lists and a linear scan for the least leaf each step:

$$
O(n^{2})
$$

educational time for Encode / Decode on $n$ vertices (dominant leaf
scans). Storage is $O(n)$ in fixed arrays up to $\mathrm{Max\_Vertices}$.
Both coding and decoding can be reduced to integer radix sorting and
parallelized (advanced; not required on this sheet).

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time (`Encode`) | $O(n^{2})$ educational leaf scans |
| Time (`Decode` / `Decode_Edges`) | $O(n^{2})$ educational least-degree scans |
| Auxiliary space | $O(n)$ adjacency / degree scratch |
| Tree storage | $O(n)$ undirected edges ($n-1$ when valid) |
| Vertex indices | $1 .. N$ with $N \le \mathrm{Max\_Vertices}$ |
| Sequence length | $N-2$ for $N\ge 2$; $0$ for $N\le 1$ |
| Output | Prüfer code / edge list / rebuilt `Tree` |

## Features

- **`Clear` / `Add_Edge`** — build a labeled undirected graph on vertices $1 .. N$.
- **`Encode`** — Prüfer sequence of a tree (length $N-2$).
- **`Decode` / `Decode_Edges`** — unique tree / edge list from a sequence.
- **`Get_Edges`** — copy the current undirected edge list.
- **`Cayley_Count`** — $n^{n-2}$ for small $n$ (educational).
- **Round-trip identity** — $\mathrm{Encode}\circ\mathrm{Decode}$ and
  $\mathrm{Decode}\circ\mathrm{Encode}$ (edge order may differ).
- **Capacity / structure guards** — `Invalid_Argument` for bad ids,
  overflow, self-loops, non-trees on Encode, or illegal code labels.
- **Educational layout** — 1-based indices; fixed arrays sized to
  $\mathrm{Max\_Vertices}$.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pprufer_coding.gpr`.

## Usage

```bash
# Build test suite
make

# Run tests
make test

# Clean artifacts
make clean
```

### Expected Output

```text
Running tests...

=== 1. Empty / single / two-vertex ===
  PASS: ...
...
Results:  NN PASS, 0 FAIL
```

(Exact `NN` is the current suite size; it is at least 150.)

## Testing

The test suite in `tests.adb` covers:

- Empty / single / two-vertex trees; empty-code decode ($N=2$)
- Wikipedia example sequence $[4,4,4,5]$
- Paths and stars (hub at $1$, at $N$, and mid-hubs)
- Cayley's $n^{n-2}$ values and full enumeration for small $n$
- Round-trips on trees and on codes (`Encode`∘`Decode` /
  `Decode`∘`Encode`)
- `Decode` vs `Decode_Edges` edge-multiset agreement
- Capacity path on $\mathrm{Max\_Vertices}$; rebuild / inspectors
- `Invalid_Argument` for overflow, self-loops, non-trees, bad labels,
  and short / mis-indexed buffers

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Prufer_Coding is
   Max_Vertices : constant Positive := 1_024;
   Max_Edges    : constant Positive := Max_Vertices - 1;

   type Vertex_Id is range 1 .. Max_Vertices;

   type Edge_Record is record
      U, V : Vertex_Id;
   end record;
   type Edge_List is array (Positive range <>) of Edge_Record;
   type Code_Array is array (Positive range <>) of Vertex_Id;

   type Tree is limited private;
   Invalid_Argument : exception;

   procedure Clear (T : in out Tree; Vertex_Count : Natural);
   procedure Add_Edge (T : in out Tree; U, V : Vertex_Id);
   function Vertex_Count (T : Tree) return Natural;
   function Edge_Count (T : Tree) return Natural;
   procedure Get_Edges
     (T : Tree; Edges : out Edge_List; Edge_Count : out Natural);

   procedure Encode
     (T : Tree; Code : out Code_Array; Length : out Natural);
   procedure Decode (Code : Code_Array; T : out Tree);
   procedure Decode_Edges
     (Code       : Code_Array;
      Edges      : out Edge_List;
      Edge_Count : out Natural;
      N          : out Natural);

   function Cayley_Count (N : Natural) return Natural;
end Prufer_Coding;
```

Raises `Invalid_Argument` for vertex ids outside $1 .. N$, $N$ or edge
capacity overflow, self-loops, non-tree graphs on `Encode`, Prüfer labels
outside $1 .. (|Code|+2)$, output buffers with `First /= 1` or
insufficient `Last`, `Decode` when $|Code|+2 > \mathrm{Max\_Vertices}$,
or `Cayley_Count` with $N>8$.

The graph is **undirected**: each `Add_Edge` stores one undirected edge.
`Encode` requires a tree when $N\ge 2$ (exactly $N-1$ edges, connected,
acyclic). `Decode` of a length-$L$ sequence always yields $N=L+2$
vertices. Edge order after Decode need not match the order of `Add_Edge`
before Encode; the undirected edge **multiset** is identical.

## License

Educational reference implementation. See repository `LICENSE` if present.
