# Topological Sorting in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of [topological sorting](https://en.wikipedia.org/wiki/Topological_sorting) on a bounded directed graph. Written in Ada 2022 and verified with SPARK (GNATprove Level 4), it computes a linear order of vertices such that every directed edge $u \to v$ has $u$ before $v$, using **Kahn's algorithm** (indegree + queue) on a static Boolean adjacency matrix. Cycles are reported via `Success : out Boolean` — no exceptions, no heap, no `Ada.Containers`.

$$
\text{time } \Theta(N^2),\quad \text{extra space } O(N),\quad N \le \mathrm{Max\_Nodes} = 32
$$

A permutation $\pi$ of $\{1,\ldots,N\}$ is a topological order iff

$$
\forall\, u,v \in \{1,\ldots,N\}:\quad (u \to v) \implies \mathrm{pos}(u) < \mathrm{pos}(v).
$$

Kahn's drain succeeds iff the graph is a DAG: every node is dequeued exactly once. A leftover node means a directed cycle remains.

This is the SPARK Level 4 port of the companion package [Ada-Topological-Sort](https://github.com/RobertBoettcherSF/Ada-Topological-Sort) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling uses `Ada.Containers.Vectors` adjacency lists, raises `Invalid_Graph`, and offers a recursive DFS variant; this port trades those for a hard classroom bound (`Max_Nodes = 32`), a static $N \times N$ Boolean matrix, a bounded Head/Tail queue, and machine-checkable absence of run-time errors. README links only — do not `with` sibling packages here. Closest SPARK siblings that share bounded node / array shape: [Ada-SPARK-Floyds-Cycle-Finding-Algorithm](https://github.com/RobertBoettcherSF/Ada-SPARK-Floyds-Cycle-Finding-Algorithm), [Ada-SPARK-Cycle-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Cycle-Sort), and [Ada-SPARK-Strand-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Strand-Sort).

## Features
* **`Kahn_Sort (G, Result, Success)`**: Iterative indegree / queue topological sort. `Success` is True iff `Result` is a valid order of $1..N$.
* **`Is_Valid_Sort`**: Permutation of $1..N$ plus every live edge $u \to v$ is strictly forward. Vacuous for $N = 0$.
* **`Add_Edge` / `Clear` / `Has_Edge`**: Static-matrix mutators and a query. Edges are idempotent (Boolean).
* **`In_Bounds` / `Result_Shape`**: Expression-function guards for 1-based order buffers.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of index / overflow errors; `Success` implies `Is_Valid_Sort`.
* **Contract Discipline**: Preconditions replace exceptions; nodes outside $1..N$ are `Pre` violations rather than `Invalid_Graph`.

## Deliberate simplifications vs non-SPARK sibling
* `Max_Nodes = 32` so the $N \times N$ matrix and queue VCs stay within automated SMT reach.
* No `Ada.Containers`: adjacency is a static `Adj_Matrix` (`Boolean`), not `Vectors` lists.
* No exceptions: shape / node range are `Pre`; cycles are `Success = False`.
* Nodes fixed at $1..N$ (sibling uses a distinct `Node_ID` over all `Positive`).
* **Kahn only.** The sibling's recursive DFS (temporary / permanent marks) is omitted — recursion and path marks do not prove as cleanly at Level 4. Kahn alone is the package.
* Multi-edges collapse (Boolean cell). Self-loops are allowed and make the graph cyclic.
* `Clear` is `out` (rewrites the whole matrix). `Result` uses `Relaxed_Initialization` so SPARK can accept an unconstrained `out` buffer.
* **SPARK proves** `Post => (if Success then Is_Valid_Sort (G, Result))` by evaluating the predicate after a full drain (`Count = N`). That is the Success-semantics contract. Tests check the converse: every DAG actually returns `Success` (Kahn works) and every cyclic case returns Failure. Zero `pragma Annotate (GNATprove, Intentional, …)`.

## Algorithm
Kahn's algorithm ([Wikipedia](https://en.wikipedia.org/wiki/Topological_sorting#Kahn's_algorithm)):

1. $\mathrm{InDegree}(v) \leftarrow |\{u : \mathrm{Adj}(u,v)\}|$.
2. Enqueue every $v$ with $\mathrm{InDegree}(v) = 0$.
3. While the queue is not empty: dequeue $u$, append $u$ to $\mathrm{Result}$, and for each edge $u \to v$ decrement $\mathrm{InDegree}(v)$; if it hits $0$, enqueue $v$. Each node is offered to the queue at most once (static array + `Head` / `Tail`).
4. $\mathrm{Success}$ iff $|\mathrm{Result}| = N$ **and** `Is_Valid_Sort` holds. Otherwise a directed cycle remains.

Empty graphs ($N = 0$) succeed with a vacuous order. The matrix scan is $\Theta(N^2)$; the queue holds at most $N$ nodes.

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 101 assertions pass. Running `make prove` reports `Success: all checks proved (91 checks).`

## Testing
* **Functional correctness**: Empty / singleton, linear chains, diamonds, disconnected components, the sibling's 6-node DAG, a remapped Wikipedia 8-node figure, a length-32 chain and a transitive tournament.
* **Cycle detection**: Triangle, two-cycle, tail cycle, self-loops, cycle-plus-source, cycle at `Max_Nodes`.
* **`Is_Valid_Sort`**: Accepts both diamond orders; rejects reverse, duplicates, missing nodes, and an early sink.
* **Contract helpers**: `In_Bounds` / `Result_Shape` / `Has_Edge` / `Clear` idempotence.
* **Contract discipline**: Only valid call paths are exercised (no exception handlers). Tests stay at $N \le 32$.

## Building
**Prerequisites:** GNAT with SPARK/GNATprove support, Ada 2022 (`-gnat2022`). Source the SPARK environment if needed (`source /home/box/deps/spark/env.sh`).

**Commands:**
* `make` — Builds the test binary.
* `make test` — Compiles and executes the test suite.
* `make prove` — Runs GNATprove at Level 4.
* `make clean` — Removes `obj/` and `bin/`.

## Proof Status
* Package spec and body use `SPARK_Mode => On` with `Pre` / `Post` / `Global => null`.
* In-degree, enqueue, seed, and relax helpers keep index / overflow VCs modular; the Kahn drain is a `for` loop capped at $N$ with `Head` / `Tail` / `Result'Initialized` invariants.
* **GNATprove Level 4:** `Success: all checks proved (91 checks).`
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.

## API Summary
| Entity | Role |
| ------ | ---- |
| `Max_Nodes` | Classroom capacity bound (`32`) |
| `Node_Id` / `Node_Count` | Live nodes $1..N$, $N \in 0..32$ |
| `Graph (Num_Nodes)` | Discriminated record + static `Adj_Matrix` |
| `Has_Edge` / `Add_Edge` / `Clear` | Query, insert, wipe |
| `In_Bounds` / `Result_Shape` | 1-based order-buffer guards |
| `Is_Valid_Sort` | Permutation + forward-edge predicate |
| `Kahn_Sort` | Indegree / queue sort (`Success` ⇒ valid order) |

## License
MIT License — Copyright (c) 2026 Sternenfisch.
