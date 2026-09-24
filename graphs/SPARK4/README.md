# A* Search in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of the [A\* search algorithm](https://en.wikipedia.org/wiki/A*_search_algorithm) (Hart–Nilsson–Raphael, 1968) on a bounded weighted digraph. Written in Ada 2022 and verified with SPARK (GNATprove Level 4), it finds a least-cost path from a source to a goal guided by a caller-supplied heuristic. Open-set selection is a dense $O(V)$ scan — no heap — matching the Dijkstra sibling sheet. Unreachable goals are reported via `Found : out Boolean` — no exceptions, no heap, no `Ada.Containers`.

At each step A\* expands the open vertex $n$ that minimises

$$
f(n) = g(n) + h(n)
$$

where $g(n)$ is the cost of the best path found so far from the source to $n$, and $h(n)$ is a problem-specific estimate of the cheapest path from $n$ to the goal. When $h$ is **admissible** (never overestimates), the first time the goal is selected from the open set its $g$-score is optimal. When $h$ is **consistent** (monotone), each vertex is settled at most once. A heuristic that is **identically zero** makes selection depend on $g$ alone, so A\* reduces to dense Dijkstra on the same graph.

$$
\text{time } O(V^{2}+E),\quad N\le\mathrm{Max\_Vertices}=32,\quad |E|\le\mathrm{Max\_Edges}=256
$$

This is the SPARK Level 4 port of the companion package [Ada-A-Star](https://github.com/RobertBoettcherSF/Ada-A-Star) in the RobertBoettcherSF Ada algorithm series. There is no Ada-SPARK-Dijkstra yet — this package stands alone. README links only — do not `with` sibling packages. Closest SPARK siblings that share bounded node / array shape: [Ada-SPARK-Topological-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Topological-Sort), [Ada-SPARK-Binary-Search](https://github.com/RobertBoettcherSF/Ada-SPARK-Binary-Search), [Ada-SPARK-Floyds-Cycle-Finding-Algorithm](https://github.com/RobertBoettcherSF/Ada-SPARK-Floyds-Cycle-Finding-Algorithm).

## Features
* **`Search (G, Source, Goal, Heuristic, Dist, Prev, Path, Length, Found, Nodes_Expanded)`**: Dense A\* Source→Goal. `Found` is True iff a path is returned.
* **`Reconstruct_Path`**: Recover a vertex sequence from `Prev`.
* **`Clear` / `Add_Edge` / `Vertex_Count` / `Edge_Count` / `Well_Formed`**: Static CSR mutators and queries.
* **`Arrays_OK` / `Heuristic_OK`**: Expression-function guards for buffers and non-negative $H$ on $1..N$.
* **`Infinity`**: Sentinel distance for unreachable vertices.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of index / overflow errors; `Found` implies `Dist(Goal) < Infinity` and a Source→Goal path of valid length.
* **Contract Discipline**: Preconditions replace exceptions; ids outside $1..N$ or full edge capacity are `Pre` violations rather than `Invalid_Argument`.

## Deliberate simplifications vs non-SPARK sibling
* `Max_Vertices = 32`, `Max_Edges = 256` so CSR / scan VCs stay within automated SMT reach (sibling: $1000$ / $100\,000$).
* No exceptions: shape / range / capacity are `Pre`; unreachability is `Found = False`.
* `Weight_Type` / `Heuristic_Value` are non-negative by construction (`0 .. Max_Weight`); sibling accepts `Integer` and raises on negatives.
* Static CSR (`Head` / `To` / `Weight` / `Next`) with prepend discipline (`Next(I) < I`) so edge-chain walks terminate.
* Single `Search` with `Nodes_Expanded` (sibling also offers `Find_Path` / `Distance` convenience wrappers — omitted here to keep the proof surface small).
* Expansion loop capped at $\mathrm{Max\_Vertices}^{2}$ so termination is immediate for the prover (allows reopen on classroom graphs).
* **SPARK proves** RTE freedom and `Found` $\Rightarrow$ `Dist(Goal) < Infinity` plus path shape (`Path(1)=Source`, `Path(Length)=Goal`, `Length in 1..N`). **Full optimality of `Dist(Goal)` under admissible $H$ is not proved at Level 4** — small-graph tests check it. Zero `pragma Annotate (GNATprove, Intentional, …)`.

## Algorithm
Dense A\* ([Wikipedia](https://en.wikipedia.org/wiki/A*_search_algorithm)):

1. $\mathrm{dist}(v)\leftarrow\infty$, $\mathrm{prev}(v)\leftarrow 0$; $\mathrm{dist}(s)\leftarrow 0$. Closed set empty.
2. While some vertex with finite $\mathrm{dist}$ is not closed:
   - Choose open $u$ minimising $f(u)=\mathrm{dist}(u)+H(u)$ (dense scan; tie-break: smaller vertex id).
   - Mark $u$ closed; count an expansion.
   - If $u=t$, stop — with admissible $H$, $\mathrm{dist}(t)$ is optimal (tests).
   - For each CSR edge $u\to w$ with weight $c$: let $\mathrm{alt}=\mathrm{dist}(u)+c$; if $\mathrm{alt}<\mathrm{dist}(w)$ then update $\mathrm{dist}(w)$, set $\mathrm{prev}(w)\leftarrow u$, and **reopen** $w$ if it was closed (needed when $H$ is admissible but not consistent).
3. When $H\equiv 0$, selection is by $\mathrm{dist}$ alone $\Rightarrow$ dense Dijkstra.

### Admissibility and consistency
- **Admissible:** $H(v)\le$ true remaining cost from $v$ to $t$. Guarantees optimal path cost when the goal is selected.
- **Consistent (monotone):** $H(u)\le c(u,w)+H(w)$ for every edge. Implies admissibility (if $H(t)=0$) and that reopen never fires after settle.
- **$H\equiv 0$:** A\* ≡ dense Dijkstra (optimal for non-negative weights).

### Example
Vertices $\{1,2,3,4\}$ with edges $1\xrightarrow{1}2$, $1\xrightarrow{4}3$, $2\xrightarrow{1}3$, $2\xrightarrow{5}4$, $3\xrightarrow{1}4$, and admissible $H=(2,1,1,0)$:

- Optimal $1\to 4$ cost is $3$ along $(1,2,3,4)$
- A\* with this $H$ returns the same cost as Dijkstra ($H\equiv 0$)

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

Source the SPARK environment if needed (`source /home/box/deps/spark/env.sh`).

**Expected output:**
When you run `make test`, you will see all 90 assertions pass (`0 FAIL`). Running `make prove` reports `Success: all checks proved (234 checks).`

## Testing
* **Functional correctness**: Empty / singleton, direct edges, diamonds, disconnected components, layered DAGs, stars, chains up to `Max_Vertices`.
* **Zero heuristic ≡ Dijkstra**: Same costs on the classic 6-node digraph.
* **Grid / Manhattan**: $3\times 3$ unit grid; admissible Manhattan $H$; expands no more than $H\equiv 0$.
* **Unreachable**: Disconnected components leave `Found = False`, `Dist(Goal) = Infinity`.
* **Consistent vs inconsistent admissible**: Both return optimal cost $4$ on a 3-node graph (reopen).
* **Parallel / zero-weight edges**, **Clear rebuild**, **`Reconstruct_Path`**, **guiding $H$ expansion counts**.
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
* Safe add / f-score, CSR edge walk, open-set scan, and path reconstruction keep index / overflow VCs modular; the A\* drain is a `for` loop capped at $\mathrm{Max\_Vertices}^{2}$.
* **GNATprove Level 4:** `Success: all checks proved (234 checks).`
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.
* Proved: RTE / index bounds / `Found` $\Rightarrow$ path shape and finite `Dist(Goal)`. Not proved: full optimality (tests).

## API Summary
| Entity | Role |
| ------ | ---- |
| `Max_Vertices` / `Max_Edges` | Classroom capacity bounds (`32` / `256`) |
| `Weight_Type` / `Heuristic_Value` | Non-negative $0..\mathrm{Max\_Weight}$ |
| `Distance_Value` / `Infinity` | g-scores; unreachable sentinel |
| `Graph` | Limited private static CSR record |
| `Well_Formed` / `Clear` / `Add_Edge` | CSR invariant, wipe, insert |
| `Arrays_OK` / `Heuristic_OK` | Buffer / heuristic Pre helpers |
| `Search` | Dense A\* (`Found` ⇒ path shape) |
| `Reconstruct_Path` | Prev-tree walk → vertex sequence |

## License
MIT License — Copyright (c) 2026 Sternenfisch.
