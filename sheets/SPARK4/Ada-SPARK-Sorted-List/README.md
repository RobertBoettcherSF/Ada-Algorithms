# Sorted List ADT in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of a **bounded sorted-list ADT** (array-backed **ordered multiset** of `Integer` values). Written in Ada 2022 and verified with SPARK (GNATprove Level 4), the list **maintains** a nondecreasing order invariant on every mutating operation: insert locates a lower bound by inline binary search, then shifts a contiguous tail; delete removes the leftmost equal key the same way. Membership is $O(\log n)$; insert and delete are $O(n)$ from the shift.

$$
\forall\, i \in \{1,\ldots,n-1\}:\quad
\mathrm{Element}(L,i) \le \mathrm{Element}(L,i+1)
$$

Primary source: [Wikipedia — Sorted list](https://en.wikipedia.org/wiki/Sorted_list) (the encyclopedia page may redirect toward sorting articles; this package implements the **sorted-list ADT**, not a standalone sorting algorithm).

This is the SPARK Level 4 port of the companion package [Ada-Sorted-List](https://github.com/RobertBoettcherSF/Ada-Sorted-List) in the RobertBoettcherSF Ada algorithm / ADT series. The non-SPARK sibling exposes `Max_N = 1024` and exceptions (`Overflow` / `Invalid_Argument`); this port trades those for a hard classroom bound (`Max_N = 64`), `Success` / `Pre` contracts, a private `Type_Invariant => Is_Sorted_Rep`, and machine-checkable absence of run-time errors. README links only — do not `with` sibling packages (binary search is inlined in the body). Closest SPARK search sibling that shares the same lower-bound idea: [Ada-SPARK-Binary-Search](https://github.com/RobertBoettcherSF/Ada-SPARK-Binary-Search).

## Features
* **`Insert (L, X, Success)`**: Ordered multiset insert via `Lower_Bound` + right shift. `Success` is `False` when full (list unchanged).
* **`Delete` / `Delete_First`**: Remove the leftmost equal key (`Success` out, or `Pre => Contains`).
* **`Contains` / `Find`**: Inline binary search; `Find` returns the 1-based leftmost index or $0$.
* **`Min` / `Max` / `Element`**: Ends and 1-based indexed access under `Pre` (no exceptions).
* **`Is_Sorted` / `Type_Invariant`**: Public sortedness view; private `Is_Sorted_Rep` as `Type_Invariant` on `List`.
* **Formal Verification**: GNATprove Level 4 — absence of index errors; insert / delete / clear preserve the sortedness invariant.

## Deliberate simplifications vs non-SPARK sibling
* `Max_N = 64` (sibling uses $1024$) so array / shift / arithmetic VCs stay within automated SMT reach.
* No exceptions: `Insert` / `Delete` use `Success : out Boolean`; `Min` / `Max` / `Element` / `Delete_First` use `Pre`.
* Private `List` with `Type_Invariant => Is_Sorted_Rep` (adjacent nondecreasing on the live prefix).
* Inline `Lower_Bound` / `Find_First_Equal` (do **not** `with` `Binary_Search`).
* Ghost lemmas (`Lemma_First_Is_Min`, `Lemma_Last_Is_Max`, `Lemma_Miss_No_Equal`) discharge extremum and miss posts from adjacent sortedness.
* **SPARK proves** sortedness preserved by `Insert` / `Delete` / `Clear` and the public contracts. Full multiset accounting beyond `Contains` after insert is checked by tests where helpful.

## Algorithm sketch

**Lower_Bound** (half-open $[lo, hi)$):

$$
\begin{align*}
&lo \leftarrow 1,\quad hi \leftarrow n+1 \\
&\mathbf{while}\ lo < hi: \\
&\quad m \leftarrow lo + \lfloor(hi-lo)/2\rfloor \\
&\quad \mathbf{if}\ L[m] < x:\ lo \leftarrow m+1 \\
&\quad \mathbf{else}:\ hi \leftarrow m \\
&\mathbf{return}\ lo
\end{align*}
$$

The midpoint form $m = lo + \lfloor(hi-lo)/2\rfloor$ avoids overflow of $(lo+hi)/2$.

**Insert.** Locate the lower bound of $x$, shift the right tail one slot toward the end, write $x$, increment length. `Success = False` when $n = \mathrm{Max\_N}$.

**Delete.** Locate the leftmost equal key, shift the right tail one slot left, decrement length. `Success = False` if $x$ is absent.

## Complexity

Let $n$ be the current length.

| Operation | Time | Notes |
| --- | --- | --- |
| `Empty` / `Clear` / `Length` / `Is_Empty` / `Is_Full` | $O(1)$ | |
| `Contains` / `Find` | $O(\log n)$ | Inline binary search |
| `Insert` | $O(n)$ | Binary search + shift |
| `Delete` / `Delete_First` | $O(n)$ | Binary search + shift |
| `Min` / `Max` / `Element` | $O(1)$ | Ends / index into sorted content |

Space is $O(\mathrm{Max\_N})$ for the backing store (fixed capacity).

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all assertions pass (`213 PASS, 0 FAIL`). Running `make prove` reports `Success: all checks proved (328 checks).`

## Testing
* **Functional correctness**: Empty / clear, reverse-order fill, middle insert, duplicates (multiset), signed domain, full capacity.
* **Search**: Hits and misses for `Contains` / `Find` (leftmost on duplicates).
* **Delete**: Front / back / middle / absent / until empty; `Delete_First` under `Pre`.
* **Full path**: `Insert` returns `Success = False` when full; delete-then-reinsert.
* **Contract helpers**: `Is_Sorted` after mutations; only valid call paths (no exception handlers).

## Building
**Prerequisites:** GNAT with SPARK/GNATprove support, Ada 2022 (`-gnat2022`). Source the SPARK environment if needed (`source /home/box/deps/spark/env.sh`).

**Commands:**
* `make` — Builds the test binary.
* `make test` — Compiles and executes the test suite.
* `make prove` — Runs GNATprove at Level 4.
* `make clean` — Removes `obj/` and `bin/`.

## Proof Status
* Package spec and body use `SPARK_Mode => On` with `Pre` / `Post` / `Global => null`.
* Private `List` carries `Type_Invariant => Is_Sorted_Rep`; `Insert` / `Delete` / `Clear` preserve it.
* `Lower_Bound` uses a `while` loop with `Loop_Invariant` / `Loop_Variant`; shift loops track copied regions.
* **GNATprove Level 4:** `Success: all checks proved (328 checks).`
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.
