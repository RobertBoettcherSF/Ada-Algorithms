# Brent's cycle-finding algorithm — Ada 2023

Educational, self-contained Ada 2023 package for **Brent's** cycle-finding
algorithm (Richard P. Brent, 1980): detect a cycle in the orbit of an
endofunction $f$ on a finite set by **exponential search** over powers of
two, recovering the cycle length $\lambda$ first, then the tail length
$\mu$. See
[Wikipedia: Cycle detection — Brent's algorithm](https://en.wikipedia.org/wiki/Cycle_detection#Brent's_algorithm)
and
[Wikipedia: Cycle detection](https://en.wikipedia.org/wiki/Cycle_detection).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT
(`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Project overview

For any function $f$ that maps a finite set $S$ to itself and any start
$x_0\in S$, the iterated sequence

$$
x_0,\quad x_{i+1}=f(x_i)
$$

must eventually repeat. The first index that reappears forever is
$\mu$; the shortest positive period is $\lambda$:

$$
x_{\mu}=x_{\mu+\lambda},\qquad
x_i\neq x_j\text{ for }0\le i<j<\mu+\lambda.
$$

Graph-theoretically $f$ is a **functional graph** (out-degree one). The
vertices reachable from $x_0$ form a $\rho$-shaped subgraph: a path of
length $\mu$ into a cycle of $\lambda$ vertices.

This package is a classroom implementation: a successor array
`Next (1 .. N)` with values in $0..N$, Brent `Detect` / `Find_Cycle`, a
naive $O(\mu+\lambda)$-space reference, a generic black-box $f$, and
builders for pure cycles, $\rho$ graphs, lists into a sink, and the
Wikipedia figure.

## Classroom model

| Convention | Meaning |
| --- | --- |
| Live nodes | $1..N$ |
| `Null_Index` $=0$ | no successor (linked-list sentinel) |
| Total map | every `Next(I)` $\in 1..N$ — every trajectory cycles |
| List / sink | a path that reaches $0$ has **no** cycle |
| Bound | $1\le N\le\texttt{Max\_Nodes}=4096$ |
| Errors | `Invalid_Argument` for bad size, non-$1$-based maps, OOB successors / starts |

A finite total functional graph **always** has a cycle in every
component. The $0$-sentinel is the educational linked-list exception:
$0$ is not a vertex, so $f(0)$ is never taken as a self-loop.

## Algorithm (powers of two / teleporting tortoise)

Brent uses two pointers and $O(1)$ extra memory. Instead of a hare that
runs at twice the tortoise speed, the tortoise is **teleported** to the
hare whenever the hare reaches the next power of two $2^i$. Within each
power-of-two window the algorithm compares the fixed tortoise against
every subsequent hare step, counting those steps as a candidate
$\lambda$.

1. **Find $\lambda$.** Start with $\mathrm{power}=1$, $\lambda=1$,
   tortoise at $x_0$, hare at $f(x_0)$. While they differ: if
   $\mathrm{power}=\lambda$, teleport tortoise $\leftarrow$ hare,
   double $\mathrm{power}$, reset $\lambda\leftarrow 0$; then advance
   hare by $f$ and increment $\lambda$. When they match, $\lambda$ is
   the **exact** cycle length.
2. **Find $\mu$.** Reset both to $x_0$; advance the hare $\lambda$
   steps; then walk both one step at a time until they meet at
   $x_{\mu}$.

Cost is $O(\mu+\lambda)$ evaluations of $f$ and $O(1)$ extra cells.
Each step of the main loop evaluates $f$ **once** (vs three evaluations
per Floyd step). Reaching $0$ in phase 1 reports **no cycle**.

### Pseudocode

```text
function Find_Cycle(f, x0):
    power := 1
    lam   := 1
    tortoise := x0
    hare     := f(x0)
    while tortoise and hare are live and tortoise /= hare loop
        if power = lam then
            tortoise := hare          -- teleport
            power    := 2 * power
            lam      := 0
        end if
        hare := f(hare)
        lam  := lam + 1
    end loop
    if either is null then
        return No_Cycle
    end if
    meeting := hare                   -- λ already known

    tortoise := x0
    hare     := x0
    for i in 1 .. lam loop
        hare := f(hare)
    end loop
    mu := 0
    while tortoise /= hare loop
        tortoise := f(tortoise)
        hare     := f(hare)
        mu := mu + 1
    end loop
    return (meeting, tortoise, mu, lam)
```

`Detect` stops after phase 1 and **already returns $\lambda$** (Brent's
advantage over Floyd's detect-only phase). `Find_Cycle_Naive` records
first-visit indices in an $O(N)$ table (teaching contrast, not a
pointer algorithm).

## Contrast with Floyd (README only)

| Package / method | Idea |
| --- | --- |
| **This package** (`Ada-Brents-Algorithm`) | Powers-of-two teleports; finds $\lambda$ in the main loop; typically fewer $f$ evaluations |
| **Floyd's tortoise and hare** ([sibling sheet](https://github.com/RobertBoettcherSF/Ada-Floyds-Cycle-Finding-Algorithm)) | Tortoise $f$, hare $f\circ f$; then recover $\mu$ and $\lambda$ in later phases |
| **Gosper's cycle detector** (sibling topic; not the hypergeometric Gosper) | Several exponentially spaced tortoises |

README links only — **no** package `with` of Floyd (or any sibling).
Brent (1980) reports about $36\%$ fewer evaluations than Floyd on
average and speeds up Pollard's rho by about $24\%$. Both are $O(1)$
memory pointer algorithms.

## Wikipedia classroom figure

The article's running example on $S=\{0,1,2,3,4,5,6,7,8\}$ starting at
$x_0=2$ produces

$$
2,\;0,\;6,\;3,\;1,\;6,\;3,\;1,\;\ldots
$$

with cycle $6,3,1$ (so $\mu=2$, $\lambda=3$) and a second cycle $\{4\}$.
`Wikipedia_Example` stores wiki node $w$ at Ada index $w+1$:

$$
\begin{align*}
f(0)&=6,& f(1)&=6,& f(2)&=0,& f(3)&=1,\\
f(4)&=4,& f(6)&=3
\end{align*}
$$

plus a classroom fill of $\{5,7,8\}$ that preserves those two cycles.
From Ada start $3$ (wiki $2$): $\mu=2$, $\lambda=3$, $x_{\mu}=7$
(wiki $6$).

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time (`Detect` / `Find_Cycle`) | $O(\mu+\lambda)$ evaluations of $f$ |
| Auxiliary space (Brent) | $O(1)$ |
| Time / space (`Find_Cycle_Naive`) | $O(\mu+\lambda)$ / $O(N)$ |
| Time (builders) | $O(N)$ |
| Supported $N$ | $1\le N\le 4096$ |
| Output | `Has_Cycle`, meeting node, $x_{\mu}$, $\mu$, $\lambda$ |

Brent never needs more $f$ evaluations than Floyd in the worst case,
and is typically faster in practice.

## Features

- **`Successor_Map`** — `Next(I)=f(I)`; $0$ is the null sentinel.
- **`Detect`** — phase 1 (Has_Cycle, Meeting_Point, **and** $\lambda$).
- **`Find_Cycle`** — full Brent ($\mu$, $\lambda$, $x_{\mu}$, meeting).
- **Wrappers** — `Has_Cycle`, `Cycle_Length`, `Cycle_Start`,
  `Tail_Length`, `Is_On_Cycle`, `Step`, `Iterate`.
- **`Find_Cycle_Naive`** — first-visit table (tests / teaching).
- **Generic `Find_Cycle_On_Function` / `Detect_On_Function`** — black-box
  $f$ (Ada-idiomatic alternative to an access-to-function).
- **Builders** — `Pure_Cycle`, `Rho_Graph`, `Path_To_Sink`,
  `Self_Loop_Chain`, `Two_Cycles`, `Wikipedia_Example`.
- **`Invalid_Argument`** — empty / non-$1$-based / OOB maps, bad starts,
  $N>\texttt{Max\_Nodes}$, generic `Max_Steps` exceeded.
- **Zero-warning build** —
  `gnatmake -gnatwa -gnat2022 -Pbrents_algorithm.gpr`.

## Usage

```bash
# Build test suite
make

# Run tests
make test

# Clean artifacts
make clean
```

### Expected output

```text
Running tests...

=== 1. Invalid_Argument (bad maps / starts / builders) ===
  PASS: ...
...
Results:  NN PASS, 0 FAIL
```

(Exact `NN` is the current suite size; it is at least $150$ and at most
$400$.)

## Testing

The test suite in `tests.adb` covers:

- `Invalid_Argument` for empty / shifted / OOB maps, bad starts, oversized
  builders, and a generic walk that exceeds `Max_Steps`
- `Is_Valid_Map`, `Step`, `Iterate`
- Pure cycles ($\mu=0$, $\lambda=N$), self-loop chains, paths into a sink
- $\rho$ graphs (stem + cycle), including $\texttt{Tail}=0$
- Wikipedia figure ($\mu=2$, $\lambda=3$ from Ada $3$; self-loop at $5$)
- `Detect` vs `Find_Cycle` (Detect already returns $\lambda$); naive vs Brent
- Two disjoint cycles plus a sink
- Generic callback $f$ (wiki, path, $5$-cycle, timeout)
- Meeting point on the cycle; $x_{\mu}=f^{\mu}(x_0)$; $f^{\lambda}(x_{\mu})=x_{\mu}$
- Deterministic total maps $f(i)=1+(3i+5)\bmod N$
- Mixed null / cycle graphs and $N=1$ extremes
- Larger pure / $\rho$ stress cases

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT
  FSF 13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Brents_Algorithm is
   Max_Nodes  : constant Positive := 4096;
   subtype Node_Index is Natural range 0 .. Max_Nodes;
   Null_Index : constant Node_Index := 0;

   type Successor_Map is array (Positive range <>) of Natural;

   type Cycle_Result is record
      Has_Cycle     : Boolean    := False;
      Meeting_Point : Node_Index := Null_Index;
      Start_Node    : Node_Index := Null_Index;  -- x_μ
      Mu            : Natural    := 0;
      Lambda        : Natural    := 0;           -- filled by Detect
   end record;

   Invalid_Argument : exception;

   function Is_Valid_Map (Next : Successor_Map) return Boolean;
   function Step
     (Next : Successor_Map; X : Node_Index) return Node_Index;
   function Iterate
     (Next : Successor_Map; Start : Positive; Steps : Natural)
      return Node_Index;

   function Detect
     (Next : Successor_Map; Start : Positive) return Cycle_Result;
   function Find_Cycle
     (Next : Successor_Map; Start : Positive) return Cycle_Result;

   function Has_Cycle
     (Next : Successor_Map; Start : Positive) return Boolean;
   function Cycle_Length
     (Next : Successor_Map; Start : Positive) return Natural;
   function Cycle_Start
     (Next : Successor_Map; Start : Positive) return Node_Index;
   function Tail_Length
     (Next : Successor_Map; Start : Positive) return Natural;
   function Is_On_Cycle
     (Next, Node, Start_Node : ...; Lambda : Natural) return Boolean;

   function Find_Cycle_Naive
     (Next : Successor_Map; Start : Positive) return Cycle_Result;

   generic
      with function F (X : Node_Index) return Node_Index;
   function Find_Cycle_On_Function
     (Start : Node_Index; Max_Steps : Positive := Max_Nodes)
      return Cycle_Result;

   function Pure_Cycle (N : Positive) return Successor_Map;
   function Rho_Graph (Tail : Natural; Cycle : Positive)
      return Successor_Map;
   function Path_To_Sink (N : Positive) return Successor_Map;
   function Self_Loop_Chain (N : Positive) return Successor_Map;
   function Two_Cycles return Successor_Map;
   function Wikipedia_Example return Successor_Map;
end Brents_Algorithm;
```

Raises `Invalid_Argument` when $N=0$, the map is not $1$-based, $N>4096$,
a successor is $>N$, `Start` is outside $1..N$, a builder is oversized,
or a generic walk exceeds `Max_Steps`.

`Detect` fills `Has_Cycle`, `Meeting_Point`, and $\lambda$. `Find_Cycle`
also fills $x_{\mu}$ and $\mu$.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
brents_algorithm.ads
brents_algorithm.adb
brents_algorithm.gpr
tests.adb
```

## References

1. [Wikipedia: Cycle detection — Brent's algorithm](https://en.wikipedia.org/wiki/Cycle_detection#Brent's_algorithm)
2. [Wikipedia: Cycle detection](https://en.wikipedia.org/wiki/Cycle_detection)
3. Brent, R. P. (1980). An improved Monte Carlo factorization algorithm.
   *BIT* 20(2):176–184.
4. Knuth, D. E. (1969). *The Art of Computer Programming*, vol. II:
   Seminumerical Algorithms. (Floyd contrast; sibling sheet.)

## License

Educational example code for the RobertBoettcherSF Ada algorithm series.
