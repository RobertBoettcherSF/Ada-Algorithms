# Gale–Shapley Algorithm in Ada 2023

## Project Overview

The **Gale–Shapley algorithm** (also **deferred acceptance**,
**propose-and-reject**, or the **Boston Pool** algorithm) computes a
**stable matching** between two equal-sized bipartite sets. David Gale
and Lloyd Shapley published it in 1962 in *The American Mathematical
Monthly*; a form of the same procedure had already been used by the
National Resident Matching Program since 1952. Shapley and Alvin E. Roth
received the 2012 Nobel Memorial Prize in Economic Sciences for work
including this algorithm (Gale had died in 2008).

Given proposers $P=\{1,\ldots,n\}$ and receivers $R=\{1,\ldots,n\}$,
each participant ranks every member of the other side. A matching $M$
is **stable** when it is a bijection $P\to R$ with no **blocking pair**:
no proposer $p$ and receiver $r$ who both strictly prefer each other to
their assigned partners. Gale and Shapley proved that a stable matching
always exists and gave a deferred-acceptance procedure that finds one
in

$$
O(n^{2})
$$

time — linear in the size of the two preference matrices.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation: 1-based `Person_Id` indices, preference lists as $n\times n$
rank-ordered permutations (or incremental `Set_*_Choice`), `Solve` /
`Match` returning proposer$\to$receiver and receiver$\to$proposer mate
arrays, an `Is_Stable` checker, rank lookup / `Prefers` helpers, a
`Side` parameter so receiver-proposing is the dual of swapping sides,
fixed arrays (no dynamic heap), and `Invalid_Argument` for bad sizes,
non-permutations, and incomplete lists. Cap $n\le\mathrm{Max\_N}=128$.

Primary source:
[Wikipedia — Gale–Shapley algorithm](https://en.wikipedia.org/wiki/Gale%E2%80%93Shapley_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with matching siblings

| Package / method | Problem | Notes |
| --- | --- | --- |
| **This package** (`Ada-Gale-Shapley-Algorithm`) | **Stable** bipartite matching | Deferred acceptance; proposer-optimal |
| Hopcroft–Karp (sibling sheet) | **Cardinality** bipartite matching | Unweighted max matching; $O(E\sqrt{V})$ |
| Hungarian (sibling sheet) | Weighted bipartite **assignment** | Min-/max-cost perfect matching; dual $O(n^{3})$ |
| Blossom / Edmonds (sibling sheet) | Matching in **general** graphs | Handles odd cycles (blossoms); not bipartite-only |

README links only — **no** package `with` of siblings. Hopcroft–Karp
maximizes the *number* of matched edges; Hungarian optimizes *edge
weights* under a perfect-matching constraint; Gale–Shapley uses
*ordinal preferences* and requires **stability** (no blocking pair).
Blossom algorithms extend matching beyond bipartite graphs. The same
$n$ participants may admit many stable matchings; they form a
distributive lattice whose top and bottom elements are the two
one-sided deferred-acceptance solutions.

## Stable matching

A matching $M$ pairs each proposer with a unique receiver. Pair
$(p,r)\notin M$ **blocks** $M$ when $p$ prefers $r$ to $M(p)$ and $r$
prefers $p$ to $M^{-1}(r)$. $M$ is stable when no such pair exists. If
a blocking pair were present the two participants would leave the
assigned matching and pair with each other.

### Example (two stable matchings)

Proposers $\{1,2,3\}$, receivers $\{1,2,3\}$:

| Proposer | Preference (best $\to$ worst) | Receiver | Preference (best $\to$ worst) |
| --- | --- | --- | --- |
| $1$ | $1,2,3$ | $1$ | $2,1,3$ |
| $2$ | $2,1,3$ | $2$ | $1,2,3$ |
| $3$ | $1,2,3$ | $3$ | $1,2,3$ |

Proposer-optimal matching: $\{1\!-\!1,\,2\!-\!2,\,3\!-\!3\}$.
Receiver-optimal matching: $\{1\!-\!2,\,2\!-\!1,\,3\!-\!3\}$.
Both are stable; they are the top and bottom of the stable-matching
lattice for this instance.

## Algorithm

### Deferred acceptance

All proposers start free. While a free proposer $p$ remains, $p$
proposes to the next receiver $r$ on $p$'s list:

1. If $r$ is free, $r$ tentatively accepts.
2. If $r$ is engaged to $q$ and prefers $p$ to $q$, $r$ switches and
   $q$ becomes free.
3. Otherwise $r$ rejects $p$, and $p$ continues down the list.

Each proposer walks their list at most once, so at most $n^{2}$
proposals occur. The procedure terminates with a **perfect** matching
that is **stable**, **proposer-optimal** (every proposer is at least as
well off as in any other stable matching), and **receiver-pessimal**
(every receiver is at least as badly off as in any other stable
matching). The matching does not depend on the order in which free
proposers are selected.

Receiver-proposing is the same algorithm with the sides swapped: it
returns the receiver-optimal / proposer-pessimal stable matching.
This package exposes that dual as `Solve (Inst, Result, Receivers)`
(or `Match (Inst, Receivers)`).

### Pseudocode

```text
for each proposer p: next[p] := 1; mate_p[p] := 0
for each receiver r: mate_r[r] := 0
while some proposer p is free:
    r := p's next[p]-th choice
    next[p] := next[p] + 1
    if mate_r[r] = 0:
        engage p–r
    else if r prefers p to mate_r[r]:
        q := mate_r[r]; engage p–r; q becomes free
    else:
        r rejects p
```

### Correctness (sketch)

- **Everyone is matched.** An unmatched proposer would have proposed to
  every receiver. A receiver who has ever held a proposal remains
  matched, so no receiver is free; with $|P|=|R|$ no proposer is free
  either.
- **Stability.** If $p$ and $r$ both preferred each other to their
  final partners, $p$ would have proposed to $r$ before stopping. Then
  $r$ would only reject $p$ after receiving a still-better proposal, so
  $r$ cannot prefer $p$ to the final match.
- **Proposer-optimality.** The matching is the best stable matching
  for every proposer simultaneously (Gale–Shapley; the lattice of
  stable matchings has this matching as its maximum).

### Strategic notes

Deferred acceptance is **strategy-proof for proposers**: no proposer
(and no coalition of proposers, in the group-strategy-proof sense for
strict improvement of every member) can obtain a strictly better
stable partner by misreporting. It is **not** strategy-proof for
receivers; truncation or other misreports can help a receiver, but
only with knowledge of the others' lists.

### Asymptotic cost

$$
O(n^{2})
$$

worst case, and linear in the input size (two $n\times n$ preference
matrices). Auxiliary space is $O(n^{2})$ for the stored lists.

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time (`Solve` / `Match`) | $O(n^{2})$ |
| Time (`Is_Stable`) | $O(n^{2})$ |
| Auxiliary space | $O(n^{2})$ fixed stores |
| Order cap | $n\le\mathrm{Max\_N}=128$ |
| Indices | Proposers / receivers $1..n$ |
| Unmatched / unused mate | $0$ |
| Empty $n=0$ | Feasible; empty matching, vacuously stable |

## Features

- **`Clear` / `Set_*_Choice` / `Load_*_Prefs` / `Load`** — build an
  instance (identity lists after `Clear`; `Load` copies two matrices).
- **`Solve` / `Match`** — proposer-optimal deferred acceptance; optional
  `Side` for the receiver-proposing dual.
- **`Is_Stable` / `Is_Bijection` / `Is_Permutation`** — checkers.
- **`Proposer_Rank` / `Receiver_Rank` / `Prefers`** — rank lookup.
- **`Proposer_Choice` / `Receiver_Choice` / `Receiver_Of` /
  `Proposer_Of`** — inspectors.
- **`Is_Complete_Permutation`** — validate a preference matrix.
- **Capacity / bound guards** — `Invalid_Argument` for overflow,
  non-permutations, incomplete lists, or out-of-range ids.
- **Educational layout** — 1-based indices; fixed arrays sized to
  $\mathrm{Max\_N}$.
- **Zero-warning build** —
  `gnatmake -gnatwa -gnat2022 -Pgale_shapley_algorithm.gpr`.

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

=== 1. Empty N=0 ===
  PASS: ...
...
Results:  NN PASS, 0 FAIL
```

(Exact `NN` is the current suite size; it is at least 150.)

## Testing

The test suite in `tests.adb` covers:

- Empty $n=0$; singleton $n=1$
- Identity, reverse, cyclic, and shared-list families
- Exhaustive $n=2$ preference profiles ($2^{4}=16$)
- A classic $n=3$ instance with two distinct stable matchings
- Duality: receiver-proposing equals proposer-proposing after a side swap
- `Match` versus `Solve` overloads
- Rank lookup, `Prefers`, permutation validators
- `Is_Stable` rejection of unstable and ill-formed matchings
- `Invalid_Argument` for overflow, shape errors, non-permutations,
  incomplete lists, and out-of-range inspectors
- Brute-force proposer-optimality / receiver-pessimality on tiny $n$
- Larger $n=12,16,24,32,48$ and a $\mathrm{Max\_N}$ smoke test
- `Load` versus incremental `Set_*_Choice` agreement

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Gale_Shapley_Algorithm is
   Max_N : constant Positive := 128;

   type Person_Id is range 1 .. Max_N;
   type Pref_Matrix is array (Positive range <>, Positive range <>)
     of Natural;
   type Mate_Array is array (Positive range <>) of Natural;
   type Side is (Proposers, Receivers);

   type Matching is record
      N             : Natural := 0;
      Proposer_Mate : Mate_Array (1 .. Max_N);
      Receiver_Mate : Mate_Array (1 .. Max_N);
   end record;

   type Instance is limited private;
   Invalid_Argument : exception;

   procedure Clear (Inst : in out Instance; Size : Natural);
   procedure Set_Proposer_Choice
     (Inst : in out Instance;
      Proposer, Rank, Receiver : Person_Id);
   procedure Set_Receiver_Choice
     (Inst : in out Instance;
      Receiver, Rank, Proposer : Person_Id);
   procedure Load_Proposer_Prefs
     (Inst : in out Instance; Prefs : Pref_Matrix);
   procedure Load_Receiver_Prefs
     (Inst : in out Instance; Prefs : Pref_Matrix);
   procedure Load
     (Inst : in out Instance;
      Proposer_Prefs, Receiver_Prefs : Pref_Matrix);

   function Size (Inst : Instance) return Natural;
   function Proposer_Choice
     (Inst : Instance; Proposer, Rank : Person_Id) return Person_Id;
   function Receiver_Choice
     (Inst : Instance; Receiver, Rank : Person_Id) return Person_Id;
   function Proposer_Rank
     (Inst : Instance; Proposer, Receiver : Person_Id) return Person_Id;
   function Receiver_Rank
     (Inst : Instance; Receiver, Proposer : Person_Id) return Person_Id;
   function Prefers
     (Inst : Instance; Who : Side;
      Person, Candidate, Incumbent : Person_Id) return Boolean;
   function Is_Complete_Permutation
     (Prefs : Pref_Matrix; N : Natural) return Boolean;
   function Is_Permutation
     (A : Mate_Array; N : Natural) return Boolean;

   procedure Solve (Inst : Instance; Result : out Matching);
   procedure Solve
     (Inst : Instance; Result : out Matching; Who_Proposes : Side);
   function Match
     (Inst : Instance; Who_Proposes : Side := Proposers) return Matching;

   function Is_Bijection (Result : Matching) return Boolean;
   function Is_Stable
     (Inst : Instance; Result : Matching) return Boolean;
   function Receiver_Of
     (Result : Matching; Proposer : Person_Id) return Person_Id;
   function Proposer_Of
     (Result : Matching; Receiver : Person_Id) return Person_Id;
end Gale_Shapley_Algorithm;
```

Raises `Invalid_Argument` for $n>\mathrm{Max\_N}$, non-1-based or
non-square `Load` matrices, preference rows that are not permutations
of $1..n$, person / rank ids outside $1..n$, or rank lookup of a
partner that is not on the person's list.

`Clear` installs identity preferences (person $i$ ranks partner $k$ at
rank $k$). Empty $n=0$ is feasible and vacuously stable.
`Proposer_Mate(P)=R` and `Receiver_Mate(R)=P` are mutual mates.

## License

Educational reference implementation. See repository `LICENSE` if present.
