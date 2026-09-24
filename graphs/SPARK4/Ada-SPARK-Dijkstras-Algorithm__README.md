# Dijkstra's Algorithm in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of [Dijkstra's algorithm](https://en.wikipedia.org/wiki/Dijkstra%27s_algorithm) (Edsger W. Dijkstra, 1959) on a bounded weighted digraph. Written in Ada 2022 and verified with SPARK (GNATprove Level 4), it finds least-cost paths from a source to a target under **non-negative** edge weights. Open-set / unsettled-set selection is a dense $O(V)$ scan — no heap — matching the A\* sibling sheet with the heuristic removed. Unreachable targets are reported via `Found : out Boolean` — no exceptions, no heap, no `Ada.Containers`.

At each step Dijkstra **settles** the unsettled vertex $u$ that minimises the tentative distance $\mathrm{dist}(u)$, then **relaxes** its outgoing edges. With non-negative weights a settled distance is final (no reopen). Path reconstruction walks the predecessor tree `Prev`.

$$
\text{time } O(V^{2}+E),\quad N\le\mathrm{Max\_Vertices}=32,\quad |E|\le\mathrm{Max\_Edges}=256
$$

This is the SPARK Level 4 port of the companion package [Ada-Dijkstras-Algorithm](https://github.com/RobertBoettcherSF/Ada-Dijkstras-Algorithm) in the RobertBoettcherSF Ada algorithm series. Closest SPARK sibling that shares bounded CSR / dense-scan shape: [Ada-SPARK-A-Star](https://github.com/RobertBoettcherSF/Ada-SPARK-A-Star) (adds a heuristic $h$; when $h\equiv 0$, A\* reduces to dense Dijkstra). README links only — do not `with` sibling packages.

## Features
* **`Search (G, Source, Target, Dist, Prev, Path, Length, Found)`**: Dense Dijkstra Source→Target. `Found` is True iff a path is returned.
* **`Reconstruct_Path`**: Recover a vertex sequence from `Prev`.
* **`Clear` / `Add_Edge` / `Vertex_Count` / `Edge_Count` / `Well_Formed`**: Static CSR mutators and queries.
* **`Arrays_OK`**: Expression-function guard for Dist / Prev / Path buffers on $1..N$.
* **`Infinity`**: Sentinel distance for unreachable vertices.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of index / overflow errors; `Found` implies `Dist(Target) < Infinity` and a Source→Target path of valid length.
* **Contract Discipline**: Preconditions replace exceptions; ids outside $1..N$ or full edge capacity are `Pre` violations rather than `Invalid_Argument`.

## Deliberate simplifications vs non-SPARK sibling
* `Max_Vertices = 32`, `Max_Edges = 256` so CSR / scan VCs stay within automated SMT reach (sibling: $1000$ / $100\,000$).
* No exceptions: shape / range / capacity are `Pre`; unreachability is `Found = False`.
* `Weight_Type` is non-negative by construction (`0 .. Max_Weight`); sibling accepts `Integer` and raises on negatives.
* Static CSR (`Head` / `To` / `Weight` / `Next`) with prepend discipline (`Next(I) < I`) so edge-chain walks terminate.
* Single `Search` with path outputs (sibling also offers `Shortest_Paths` / `Distance` convenience wrappers — omitted here to keep the proof surface small).
* Settle loop capped at $\mathrm{Max\_Vertices}$ so termination is immediate for the prover (no reopen under non-negative weights).
* **SPARK proves** RTE freedom and `Found` $\Rightarrow$ `Dist(Target) < Infinity` plus path shape (`Path(1)=Source`, `Path(Length)=Target`, `Length in 1..N`). **Full optimality of `Dist(Target)` is not proved at Level 4** — small-graph tests check it. Zero `pragma Annotate (GNATprove, Intentional, …)`.

## Algorithm
Dense Dijkstra ([Wikipedia](https://en.wikipedia.org/wiki/Dijkstra%27s_algorithm)):

1. $\mathrm{dist}(v)\leftarrow\infty$, $\mathrm{prev}(v)\leftarrow 0$; $\mathrm{dist}(s)\leftarrow 0$. Settled set empty.
2. While some unsettled vertex has finite $\mathrm{dist}$:
   - Choose unsettled $u$ minimising $\mathrm{dist}(u)$ (dense scan; tie-break: smaller vertex id).
   - Mark $u$ settled.
   - If $u=t$, stop — with non-negative weights, $\mathrm{dist}(t)$ is optimal (tests).
   - For each CSR edge $u\to w$ with weight $c$: if $w$ is unsettled, let $\mathrm{alt}=\mathrm{dist}(u)+c$; if $\mathrm{alt}<\mathrm{dist}(w)$ then update $\mathrm{dist}(w)$ and set $\mathrm{prev}(w)\leftarrow u$.
3. Negative weights are forbidden (they invalidate the settling argument — use Bellman–Ford). Heap variants achieve $O((V+E)\log V)$ / $O(E+V\log V)$; this sheet uses the dense scan for clarity and proof modularity.

### Example
Vertices $\{1,2,3,4\}$ with edges $1\xrightarrow{1}2$, $1\xrightarrow{4}3$, $2\xrightarrow{1}3$, $2\xrightarrow{5}4$, $3\xrightarrow{1}4$:

- $\mathrm{dist}(1)=0$, $\mathrm{dist}(2)=1$, $\mathrm{dist}(3)=2$, $\mathrm{dist}(4)=3$
- One shortest $1\to 4$ path is $(1,2,3,4)$ with total weight $3$

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

Source the SPARK environment if needed (`source /home/box/deps/spark/env.sh`).

**Expected output:**
When you run `make test`, you will see all 79 assertions pass (`0 FAIL`). Running `make prove` reports `Success: all checks proved (224 checks).`.

## Testing
* **Functional correctness**: Empty / singleton, direct edges, diamonds, disconnected components, layered DAGs, stars, chains up to `Max_Vertices`.
* **Classic 6-node digraph**: Distances $9$ to vertex $6$ via the optimal tree.
* **Grid**: $3\times 3$ unit grid; Manhattan distance $4$ from corner to corner.
* **Unreachable**: Disconnected components leave `Found = False`, `Dist(Target) = Infinity`.
* **Parallel / zero-weight edges**, **Clear rebuild**, **`Reconstruct_Path`**.
* **Contract helpers**: `Arrays_OK` / `Well_Formed`.
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
* Safe add, CSR edge walk, unsettled-set scan, and path reconstruction keep index / overflow VCs modular; the Dijkstra drain is a `for` loop capped at $\mathrm{Max\_Vertices}$.
* **GNATprove Level 4:** `Success: all checks proved (224 checks).`.
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.
* Proved: RTE / index bounds / `Found` $\Rightarrow$ path shape and finite `Dist(Target)`. Not proved: full optimality (tests).

## API Summary
| Entity | Role |
| ------ | ---- |
| `Max_Vertices` / `Max_Edges` | Classroom capacity bounds (`32` / `256`) |
| `Weight_Type` | Non-negative $0..\mathrm{Max\_Weight}$ |
| `Distance_Value` / `Infinity` | Path distances; unreachable sentinel |
| `Graph` | Limited private static CSR record |
| `Well_Formed` / `Clear` / `Add_Edge` | CSR invariant, wipe, insert |
| `Arrays_OK` | Buffer Pre helper |
| `Search` | Dense Dijkstra (`Found` ⇒ path shape) |
| `Reconstruct_Path` | Prev-tree walk → vertex sequence |

## License
MIT License — Copyright (c) 2026 Sternenfisch.
