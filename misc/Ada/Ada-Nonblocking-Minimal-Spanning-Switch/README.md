# Nonblocking Minimal Spanning Switch in Ada 2023

## Project Overview

A **nonblocking minimal spanning switch** is a switching fabric that
interconnects $N$ inputs to $N$ outputs so that **any unused input can
reach any unused output**, while using as few **crosspoints** as practical.
The idea grew out of 1950s Bell System work on cheaper telephone exchanges:
a monolithic $N\times N$ **crossbar** is strictly nonblocking but costs
$N^{2}$ crosspoints; Charles Clos showed how to replace it with a
multistage network of smaller crossbars (a **Clos network**) that remains
nonblocking with fewer crosspoints for larger $N$.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational model of
that family:

| Fabric | Crosspoints | Nonblocking sense |
| --- | --- | --- |
| **Crossbar** | $N^{2}$ | **Strict** — new calls never rearrange old ones |
| **Spanning** | $2nmr + mr^{2}$ (3-stage Clos, $m=n$) | **Rearrangeable** — a new call may need `Rearrange_Connect` |

Ports are indexed from $1$. Storage uses fixed educational arrays up to
$\mathrm{Max\_N}$ (no dynamic heap). The focus is **clear semantics** and
**tiny-$N$ tests** that witness nonblocking behaviour, not industrial Clos
optimality proofs.

Primary source:
[Wikipedia — Nonblocking minimal spanning switch](https://en.wikipedia.org/wiki/Nonblocking_minimal_spanning_switch).

Clos background:
[Wikipedia — Clos network](https://en.wikipedia.org/wiki/Clos_network).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Nonblocking vs blocking

A fabric is **blocking** if there exist free input $i$ and free output $j$
such that no path $i\to j$ exists under the **current** routing of other
calls.

- **Strict-sense nonblocking** (crossbar; Clos with $m\ge 2n-1$): whenever
  $i$ and $j$ are free, a path exists **without** changing existing calls.
- **Rearrangeably nonblocking** (Clos with $m\ge n$, Slepian–Duguid): a
  path always exists after **reassigning** some existing calls to other
  middle-stage switches.
- **Wide-sense nonblocking** (not modelled here): a careful routing
  discipline avoids rearrangement without meeting the strict Clos bound.

This sheet’s `Can_Connect` / `Connect` never rearrange; `Rearrange_Connect`
may.

## Crossbar baseline

An $N\times N$ crossbar places one crosspoint at every input/output pair:

$$
C_{\mathrm{XB}}(N)=N^{2}
$$

Any injection from free inputs to free outputs is immediately realizable,
so `Can_Connect` is exactly “both ports free”.

## Clos / spanning intuition

A three-stage Clos network $C(n,m,r)$ has:

- $r$ first-stage switches of size $n\times m$
- $m$ middle-stage switches of size $r\times r$
- $r$ third-stage switches of size $m\times n$

with $N=n\cdot r$ ports (this package pads $n\cdot r\ge N$ when $N$ is not
a neat product). Crosspoint count:

$$
C_{\mathrm{Clos}}(n,m,r)=2nmr+mr^{2}
$$

Classic thresholds:

$$
\begin{align*}
m&\ge 2n-1 &&\text{strict-sense nonblocking (Clos 1953)}\\
m&\ge n &&\text{rearrangeably nonblocking (Slepian–Duguid)}
\end{align*}
$$

The educational **Spanning** fabric uses $m=n$ and chooses
$n\approx\sqrt{N}$, $r=\lceil N/n\rceil$. For moderate $N$ (e.g. $16$,
$25$) this undercuts $N^{2}$; for very small $N$ Clos can cost **more**
than a crossbar — the package still exposes the construction so tests can
compare formulas.

Middle-stage routing: input $i$ sits on first-stage switch
$\lfloor(i-1)/n\rfloor+1$; output $j$ on third-stage switch
$\lfloor(j-1)/n\rfloor+1$. A middle switch $k$ is usable when both the
first$\to$middle and middle$\to$third links are free. `Rearrange_Connect`
recomputes a full middle assignment for the updated matching by
backtracking (adequate for $\mathrm{Max\_N}$ educational sizes).

### Example ($N=4$ Spanning)

$n=m=r=2$ gives $C=2\cdot2\cdot2\cdot2+2\cdot2^{2}=24$ crosspoints
(heavier than $N^{2}=16$ — expected at tiny $N$). Identity and reverse
matchings are routable; under partial load `Can_Connect` may fail while
`Rearrange_Connect` still succeeds for any free $(i,j)$.

### Example ($N=16$ Spanning)

$n=m=r=4$ gives $C=192<256=N^{2}$ — the spanning construction wins.

## Complexity

| Measure | Bound |
| ------- | ----- |
| Crossbar crosspoints | $O(N^{2})$ |
| Spanning ($m=n$, $n\sim\sqrt{N}$) crosspoints | $O(N^{3/2})$ classically |
| `Connect` / `Can_Connect` | $O(m)$ middle scan |
| `Rearrange_Connect` (educational backtrack) | exponential worst case; fine for tiny $N$ |
| Full permutation verify (`Empty_Fabric_Is_Fully_Nonblocking`) | $\Theta(N!)$ — use $N\le 4$ |
| Port indices | $1 .. N$ with $N\le\mathrm{Max\_N}$ |
| Capacity guard | `Invalid_Argument` when $N>\mathrm{Max\_N}$ or ports invalid |

## Features

- **`Create`** — empty $N\times N$ Crossbar or Spanning fabric.
- **`Connect` / `Can_Connect`** — path without rearrange (strict on Crossbar).
- **`Rearrange_Connect`** — establish a call, rearranging middle routes if needed.
- **`Disconnect` / `Clear_Connections`** — tear down one or all calls.
- **`Is_Connected` / `Is_Output_Busy` / `Connected_Output`** — occupancy queries.
- **`Crosspoint_Count` / `Active_Connections`** — hardware tally and load.
- **`Clos_N` / `Clos_M` / `Clos_R`** — Spanning parameters ($m=n$).
- **`All_Free_Permutations_Routable_Without_Rearrange`** — tiny-$N$ strict check on free ports.
- **`Empty_Fabric_Is_Fully_Nonblocking`** — enumerate all $N!$ matchings (empty fabric).
- **Capacity / port guards** — `Invalid_Argument` for bad $N$, ports, or busy connect.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pnonblocking_minimal_spanning_switch.gpr`.

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

=== 1. Create / order / kind / empty state ===
  PASS: ...
...
Results:  NN PASS, 0 FAIL
```

(Exact `NN` is the current suite size; it is at least $150$.)

## Testing

The test suite in `tests.adb` covers:

- Create bounds; Crossbar and Spanning orders / kinds
- Crosspoint formulas vs $N^{2}$ and $2nmr+mr^{2}$ for all $N\le\mathrm{Max\_N}$
- Connect / Disconnect / Clear; busy-port rejection
- Full permutation nonblocking for empty Crossbar and Spanning at $N\le 4$
- Partial occupancy strict checks on Crossbar
- Spanning Clos parameters ($m=n$, $n\cdot r\ge N$) and large-$N$ savings
- `Rearrange_Connect` reverse matchings for $N=5..8$
- `Invalid_Argument` for bad ports, busy connects, nonempty full-verify
- Max_N identity connect/disconnect smoke

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Nonblocking_Minimal_Spanning_Switch is
   Max_N : constant Positive := 32;

   type Port_Id is range 1 .. Max_N;
   type Fabric_Kind is (Crossbar, Spanning);

   type Switch is private;
   Invalid_Argument : exception;

   procedure Create
     (S : in out Switch; N : Positive; Kind : Fabric_Kind := Crossbar);
   function Order (S : Switch) return Natural;
   function Kind_Of (S : Switch) return Fabric_Kind;
   function Crosspoint_Count (S : Switch) return Natural;
   function Active_Connections (S : Switch) return Natural;

   function Is_Connected (S : Switch; Input : Port_Id) return Boolean;
   function Is_Output_Busy (S : Switch; Output : Port_Id) return Boolean;
   function Connected_Output (S : Switch; Input : Port_Id) return Natural;
   function Can_Connect
     (S : Switch; Input, Output : Port_Id) return Boolean;

   procedure Connect
     (S : in out Switch; Input, Output : Port_Id);
   procedure Rearrange_Connect
     (S : in out Switch; Input, Output : Port_Id);
   procedure Disconnect (S : in out Switch; Input : Port_Id);
   procedure Clear_Connections (S : in out Switch);

   function Is_Strictly_Nonblocking_Fabric (S : Switch) return Boolean;
   function Clos_N (S : Switch) return Natural;
   function Clos_M (S : Switch) return Natural;
   function Clos_R (S : Switch) return Natural;

   function All_Free_Permutations_Routable_Without_Rearrange
     (S : Switch) return Boolean;
   function Empty_Fabric_Is_Fully_Nonblocking (S : Switch) return Boolean;
end Nonblocking_Minimal_Spanning_Switch;
```

Raises `Invalid_Argument` for $N>\mathrm{Max\_N}$, port ids outside
$1 .. N$, `Connect` / `Rearrange_Connect` when ports are busy or (for
`Connect`) when no unarranged path exists, `Disconnect` on a free input,
and `Empty_Fabric_Is_Fully_Nonblocking` when the fabric is nonempty or
$N=0$.

## License

Educational reference implementation. See repository `LICENSE` if present.
