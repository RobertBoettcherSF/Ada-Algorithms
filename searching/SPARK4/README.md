# Greedy Best-First Search in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of [greedy best-first search](https://en.wikipedia.org/wiki/Best-first_search) (pure heuristic search) on a bounded unweighted / unit-cost digraph. Written in Ada 2022 and verified with SPARK (GNATprove Level 4), it expands the open vertex with smallest caller-supplied heuristic $H(v)$ toward a goal. Open-set selection is a dense $O(V)$ scan — no heap — matching the A\* / Dijkstra SPARK sibling sheets. Unreachable goals are reported via `Found : out Boolean` — no exceptions, no heap, no `Ada.Containers`.

At each step greedy BeFS expands the open vertex $n$ that minimises

$$
f(n) = h(n)
$$

where $h(n)$ estimates remaining cost from $n$ to the goal. Unlike A\* ($f=g+h$) or Dijkstra ($f=g$), the path cost from the start is **ignored**. The search is therefore **not optimal in general**: a misleadingly low $h$ on a long detour can beat a higher-$h$ short path.

$$
\text{time } O(V^{2}+E),\quad N\le\mathrm{Max\_Vertices}=32,\quad |E|\le\mathrm{Max\_Edges}=256
$$

This is the SPARK Level 4 port of the companion package [Ada-Best-First-Search](https://github.com/RobertBoettcherSF/Ada-Best-First-Search) in the RobertBoettcherSF Ada algorithm series. Closest SPARK siblings that share bounded CSR / dense-scan shape: [Ada-SPARK-A-Star](https://github.com/RobertBoettcherSF/Ada-SPARK-A-Star) (adds $g$ into $f$), [Ada-SPARK-Dijkstras-Algorithm](https://github.com/RobertBoettcherSF/Ada-SPARK-Dijkstras-Algorithm) (settles by $g$ alone). README links only — do not `with` sibling packages.

## Features
* **`Search (G, Start, Goal, Heuristic, Prev, Path, Length, Found, Nodes_Expanded)`**: Dense greedy BeFS Start→Goal. `Found` is True iff a path is returned.
* **`Reconstruct_Path`**: Recover a vertex sequence from `Prev`.
* **`Clear` / `Add_Edge` / `Vertex_Count` / `Edge_Count` / `Well_Formed`**: Static CSR mutators and queries (no edge weights).
* **`Arrays_OK` / `Heuristic_OK`**: Expression-function guards for buffers and non-negative $H$ on $1..N$.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of index / overflow errors; `Found` implies a Start→Goal path of valid length.
* **Contract Discipline**: Preconditions replace exceptions; ids outside $1..N$ or full edge capacity are `Pre` violations rather than `Invalid_Argument`.

## Deliberate simplifications vs non-SPARK sibling
* `Max_Vertices = 32`, `Max_Edges = 256` so CSR / scan VCs stay within automated SMT reach (sibling: $1000$ / $100\,000$).
* No exceptions: shape / range / capacity are `Pre`; unreachability is `Found = False`.
* **Dense $O(V)$ open-set scan** instead of the sibling's **binary-heap** priority queue ($O((V+E)\log V)$). Same selection rule (min $H$; tie-break: smaller vertex id); different data structure for proof modularity.
* `Heuristic_Value` is non-negative by construction (`0 .. Max_Heuristic`); sibling uses `Natural`.
* Static CSR (`Head` / `To` / `Next`) with prepend discipline (`Next(I) < I`) so edge-chain walks terminate. No weight array (unit-cost / unweighted).
* Single `Search` with `Nodes_Expanded` (sibling also offers `Search_With_Order` — omitted here to keep the proof surface small).
* Expansion loop capped at $\mathrm{Max\_Vertices}$ (visited-on-enqueue ⇒ each vertex at most once).
* **SPARK proves** RTE freedom and `Found` $\Rightarrow$ path shape (`Path(1)=Start`, `Path(Length)=Goal`, `Length in 1..N`). **Optimality is NOT claimed** — greedy BeFS is not optimal in general; tests illustrate guiding $H$ and a deliberate non-optimal case. Zero `pragma Annotate (GNATprove, Intentional, …)`.

## Algorithm
Dense greedy best-first ([Wikipedia — Best-first search](https://en.wikipedia.org/wiki/Best-first_search)):

1. Mark `Start` visited; open $= \{\mathrm{Start}\}$; $\mathrm{prev}(\mathrm{Start})\leftarrow 0$.
2. While open is nonempty:
   - Choose open $u$ minimising $H(u)$ (dense scan; tie-break: smaller vertex id).
   - Remove $u$ from open; count an expansion.
   - If $u=\mathrm{Goal}$, reconstruct `Prev` and succeed.
   - For each CSR edge $u\to w$ not yet visited: set $\mathrm{prev}(w)\leftarrow u$, mark $w$ visited, add $w$ to open.
3. Visited-on-enqueue prevents re-expansion loops on cyclic digraphs.

### Contrast

| Method | Evaluation |
| --- | --- |
| **Greedy best-first** (this package) | $f(n)=h(n)$ |
| Breadth-first search | fewest arcs (unit cost); no heuristic |
| Dijkstra | $f(n)=g(n)$ |
| A\* | $f(n)=g(n)+h(n)$ — best-first, not greedy |

### Example
Digraph on $\{1,2,3,4\}$ with arcs $1\to 2\to 4$ and $1\to 3\to 4$, and

$$
H(1)=3,\ H(2)=100,\ H(3)=1,\ H(4)=0.
$$

Greedy expands $1$, then prefers $3$ over $2$, then reaches $4$ along $(1,3,4)$.

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

Source the SPARK environment if needed (`source /home/box/deps/spark/env.sh`).

**Expected output:**
When you run `make test`, you will see all 64 assertions pass (`0 FAIL`). Running `make prove` reports `Success: all checks proved (180 checks).`

## Testing
* **Functional correctness**: Empty / singleton, direct edges, undirected 2-cycles, chains, diamonds, disconnected components, grids, stars, chains up to `Max_Vertices`.
* **Guiding $H$**: Preferred branch $(1,3,4)$; star expands no more under guiding $H$ than under $H\equiv 0$.
* **Non-optimality**: Misleading $H$ takes a 4-arc detour instead of a 2-arc short path.
* **Zero heuristic**: Still finds a path (ties broken by smaller vertex id).
* **Unreachable**: Disconnected components leave `Found = False`.
* **Parallel edges**, **Clear rebuild**, **`Reconstruct_Path`**.
* **Contract helpers**: `Arrays_OK` / `Heuristic_OK` / `Well_Formed`.
* **Contract discipline**: Only valid call paths are exercised (no exception handlers). Tests stay at $N\le 32$, $|E|\le 256$.

## Building
**Prerequisites:** GNAT with SPARK/GNATprove support, Ada 2022 (`-gnat2022`).

**Commands:**
* `make` — Builds the test binary.
* `make test` — Compiles and executes the test suite.
* `make prove` — Runs GNATprove at Level 4.
* `make clean` — Removes `obj/` and `bin/`.

## Proof Status
* Package spec and body use `SPARK_Mode => On` with `Pre` / `Post` / `Global => null`.
* CSR edge walk, open-set scan, and path reconstruction keep index / overflow VCs modular; the BeFS drain is a `for` loop capped at $\mathrm{Max\_Vertices}$.
* **GNATprove Level 4:** `Success: all checks proved (180 checks).`
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.
* Proved: RTE / index bounds / `Found` $\Rightarrow$ path shape. Not claimed / not proved: optimality (greedy BeFS is not optimal in general).

## API Summary
| Entity | Role |
| ------ | ---- |
| `Max_Vertices` / `Max_Edges` | Classroom capacity bounds (`32` / `256`) |
| `Heuristic_Value` | Non-negative $0..\mathrm{Max\_Heuristic}$ |
| `Graph` | Limited private static CSR record (no weights) |
| `Well_Formed` / `Clear` / `Add_Edge` | CSR invariant, wipe, insert |
| `Arrays_OK` / `Heuristic_OK` | Buffer / heuristic Pre helpers |
| `Search` | Dense greedy BeFS (`Found` ⇒ path shape) |
| `Reconstruct_Path` | Prev-tree walk → vertex sequence |

## License
MIT License — Copyright (c) 2026 Sternenfisch.
