# Heap's Algorithm in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of
[Heap's algorithm](https://en.wikipedia.org/wiki/Heap%27s_algorithm) — permutation
generation by **B. R. Heap** (1963). Written in Ada 2022 and verified with SPARK
(GNATprove Level 4), it fills a static store with all

$$
n!
$$

permutations of $\{1 .. n\}$ so that consecutive permutations differ by a
**single transposition** (swap of two elements — **not** necessarily adjacent).

> **Not heapsort.** Despite the similar name, this package implements B. R.
> Heap's *permutation-generation* algorithm. It has nothing to do with the
> heap data structure or [heapsort](https://en.wikipedia.org/wiki/Heapsort).

$$
\mathrm{Max\_N} = 7,\qquad 7! = 5040 = \mathrm{Max\_Count}
$$

This is the SPARK Level 4 port of the companion package
[Ada-Heaps-Algorithm](https://github.com/RobertBoettcherSF/Ada-Heaps-Algorithm)
in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling streams
permutations via an `access procedure` Visit callback and raises
`Invalid_Argument`; this port trades those for a static `Perm_Store`,
`Pre => N in 1 .. Max_N`, and a recursive `Heap_Generate` with
`Subprogram_Variant => (Decreases => K)`. README links only — do not `with`
sibling packages here. Closest SPARK siblings for recursion / permutation
patterns: [Ada-SPARK-Bogosort](https://github.com/RobertBoettcherSF/Ada-SPARK-Bogosort),
[Ada-SPARK-Stooge-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Stooge-Sort).

## Features
* **`Generate (N, Store, Last)`**: Fill `Store` with all $N!$ permutations in
  classic recursive Heap order; `Last = Factorial (N)`.
* **`Factorial` / `Count`**: $N!$ with an explicit table ($0! .. 7!$) so Level-4
  VCs stay inside automated SMT reach.
* **`Is_Permutation` / `Row_Is_Permutation`**: Expression-function guards.
* **`Differs_By_Single_Swap`**: Detects a single (possibly non-adjacent)
  transposition — handy for tests and teaching.
* **Formal Verification**: GNATprove Level 4 — absence of index / overflow
  errors; `Heap_Generate` terminates (`Subprogram_Variant`);
  `Post => Last = Factorial (N)` and every stored row is a permutation.
* **Contract Discipline**: Preconditions replace exceptions; no `access`
  Visit callback (SPARK-hostile).

## Deliberate simplifications vs non-SPARK sibling
* No `access procedure` Visit — `Generate` writes a static `Perm_Store`
  (`1 .. Max_Count` × `1 .. Max_N`) and returns `Last`.
* No exceptions: `Pre => N in 1 .. Max_N` (sibling raises `Invalid_Argument`).
* `Max_N = 7`, `Max_Count = 5040` (same classroom bound as the sibling).
* `Factorial` is an explicit case-table expression function (avoids
  $N \cdot (N-1)! \le \mathrm{Max\_Count}$ overflow VCs from a recursive body).
* Ghost `Lemma_Fact_Step` case-splits $K! = K\cdot(K-1)!$ for $K \in 2 .. 7$.
* Capacity Pre uses subtraction form
  `Count_Before <= Max_Count - Factorial (K)` (avoids add-overflow VCs).
* **SPARK proves** `Last = N!` and that each stored row is a permutation of
  $1 .. N$. Full uniqueness / classic order / single-swap chain are
  **checked by tests**, not claimed beyond those posts.

## Algorithm
Elements are the integers $1 .. n$. Start from the identity
$(1\;2\;\ldots\;n)$. The recursive procedure on a prefix of length $k$ is:

$$
\begin{align*}
&\textbf{if } k = 1 \textbf{ then} \\
&\quad \text{store } A;\ \mathit{Last} := \mathit{Last}+1 \\
&\textbf{else} \\
&\quad \text{Heap\_Generate}(k-1) \\
&\quad \textbf{for } i = 1 .. k-1 \textbf{ do} \\
&\quad\quad \textbf{if } k \text{ is even then swap } A(i), A(k) \\
&\quad\quad \textbf{else swap } A(1), A(k) \\
&\quad\quad \text{Heap\_Generate}(k-1) \\
&\quad \textbf{end for} \\
&\textbf{end if}
\end{align*}
$$

After each block of $(k-1)!$ permutations, a single swap brings a new
arrangement of the first $k$ positions. The emitted sequence has length $n!$.

### Example ($n = 3$)

$$
\begin{align*}
&(1\;2\;3) \rightarrow (2\;1\;3) \rightarrow (3\;1\;2) \\
&\rightarrow (1\;3\;2) \rightarrow (2\;3\;1) \rightarrow (3\;2\;1)
\end{align*}
$$

Each arrow is a single swap (some adjacent, some not).

## Complexity

| Aspect | Cost | Notes |
| ------ | ---- | ----- |
| Time per permutation | $O(1)$ amortized | One swap + store |
| Full enumeration | $O(n!)$ | Plus $O(n)$ copy per visit |
| Working space | $O(n)$ stack + $O(n!)$ store | Static `Perm_Store` |

Compared with
[Steinhaus–Johnson–Trotter](https://en.wikipedia.org/wiki/Steinhaus%E2%80%93Johnson%E2%80%93Trotter_algorithm),
Heap’s swaps need not be adjacent.

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all assertions pass (0 FAIL).
Running `make prove` reports `Success: all checks proved (235 checks).`

## Testing
* **Factorial / Count** for $N = 0 .. 7$
* Exact classic Heap order for $N = 3$
* For $N = 1 .. 6$: count $= N!$, uniqueness, every row a permutation,
  consecutive pairs differ by one (possibly non-adjacent) swap
* `Generate(Max_N)` yields $5040$ permutations; single-swap chain; each row
  a permutation
* Helper predicates (`Is_Permutation`, `Differs_By_Single_Swap`,
  `Row_Is_Permutation`)
* Identity-first property for $N = 1 .. 7$
* Contract discipline: only valid call paths (no exception handlers)

## Building
**Prerequisites:** GNAT with SPARK/GNATprove support, Ada 2022 (`-gnat2022`).
Source the SPARK environment if needed (`source /home/box/deps/spark/env.sh`).

**Commands:**
* `make` — Builds the test binary.
* `make test` — Compiles and executes the test suite.
* `make prove` — Runs GNATprove at Level 4.
* `make clean` — Removes `obj/` and `bin/`.

## Proof Status
* Package spec and body use `SPARK_Mode => On` with `Pre` / `Post` /
  `Global => null`.
* Recursive `Heap_Generate` uses `Subprogram_Variant => (Decreases => K)` and
  capacity / permutation loop invariants; ghost `Lemma_Fact_Step` discharges
  the $K! = K\cdot(K-1)!$ step.
* **GNATprove Level 4:** `Success: all checks proved (235 checks).`
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)`
  suppressions.

## API Summary
| Entity | Role |
| ------ | ---- |
| `Max_N` / `Max_Count` | $7$ / $5040$ classroom bounds |
| `Permutation` | `array (Positive range <>) of Positive` |
| `Perm_Store` | `array (1 .. Max_Count, 1 .. Max_N) of Positive` |
| `Factorial` / `Count` | $N!$ |
| `Is_Permutation` | Expression guard on a vector |
| `Row_Is_Permutation` | Expression guard on a store row |
| `Generate` | Fill store; `Last = N!` |
| `Differs_By_Single_Swap` | Single transposition predicate |

```ada
package Heaps_Algorithm with SPARK_Mode => On is
   Max_N     : constant Positive := 7;
   Max_Count : constant Positive := 5_040;

   type Permutation is array (Positive range <>) of Positive;
   type Perm_Store is array (1 .. Max_Count, 1 .. Max_N) of Positive;

   function Factorial (N : Natural) return Natural
     with Pre => N <= Max_N, Post => Factorial'Result <= Max_Count;
   function Count (N : Positive) return Natural
     with Pre => N <= Max_N, Post => Count'Result = Factorial (N);

   function Is_Permutation (P : Permutation) return Boolean;
   function Row_Is_Permutation
     (Store : Perm_Store; R : Positive; N : Positive) return Boolean;

   procedure Generate
     (N : Positive; Store : out Perm_Store; Last : out Natural)
     with Pre  => N in 1 .. Max_N,
          Post => Last = Factorial (N)
                  and then (for all R in 1 .. Last =>
                              Row_Is_Permutation (Store, R, N));

   function Differs_By_Single_Swap (A, B : Permutation) return Boolean;
end Heaps_Algorithm;
```

There is **no** `main.adb`; `tests.adb` is the project main.

## Project Layout

```text
ada-spark-heaps-algorithm/
├── .gitignore
├── LICENSE                 -- MIT, Copyright 2026 Sternenfisch
├── Makefile
├── README.md
├── heaps_algorithm.ads     -- SPARK Level 4 package spec
├── heaps_algorithm.adb     -- recursive Heap into Perm_Store
├── heaps_algorithm.gpr     -- GNAT / GNATprove project
└── tests.adb               -- test main
```

## Related algorithms
* [Steinhaus–Johnson–Trotter](https://en.wikipedia.org/wiki/Steinhaus%E2%80%93Johnson%E2%80%93Trotter_algorithm)
  — full enumeration with **adjacent** swaps only.
* [Fisher–Yates shuffle](https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle)
  — random permutations, not exhaustive listing.
* [Heapsort](https://en.wikipedia.org/wiki/Heapsort) — unrelated sorting
  algorithm that uses a binary heap (different “Heap”).

## License
MIT License — Copyright (c) 2026 Sternenfisch.
Algorithm credit: B. R. Heap (1963), “Permutations by Interchanges,”
*The Computer Journal* 6(3):293–298.
