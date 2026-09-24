# Pollard's kangaroo algorithm (lambda) — Ada 2023

Educational, self-contained Ada 2023 package for **Pollard's kangaroo
algorithm** (also **Pollard's lambda algorithm**, John Pollard, 1978): solve
the discrete logarithm $G^{X}\equiv Y\pmod{P}$ when $X$ is known to lie in an
interval $[A,B]$. A **tame** kangaroo lays a trail from $G^{B}$; a **wild**
kangaroo starts at $Y$ and uses the same pseudorandom jumps until the trails
collide. Expected time is about $O(\sqrt{B-A})$. See
[Wikipedia: Pollard's kangaroo algorithm](https://en.wikipedia.org/wiki/Pollard's_kangaroo_algorithm).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

Sibling / related rows (README links only — **no** package `with`):

- **[Ada-Pollards-Rho-Logarithms](https://github.com/RobertBoettcherSF/Ada-Pollards-Rho-Logarithms)** —
  Pollard's rho for discrete logarithms ($O(\sqrt{n})$ expected, full group
  order; same 1978 paper, different collision geometry)
- **[Ada-Baby-Step-Giant-Step](https://github.com/RobertBoettcherSF/Ada-Baby-Step-Giant-Step)** —
  Shanks meet-in-the-middle $\Theta(\sqrt{n})$ with a baby-step table
- **[Ada-Pohlig-Hellman](https://github.com/RobertBoettcherSF/Ada-Pohlig-Hellman)** —
  smooth-order DLP (often calls BSGS / kangaroo / rho as a subroutine)
- **[Ada-Pollards-Rho](https://github.com/RobertBoettcherSF/Ada-Pollards-Rho)** —
  integer-factorization rho (different problem)

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Word** | `U64` (`mod 2**64`) | Educational domain |
| **Helpers** | `Mul_Mod`, `Mod_Exp`, `Floor_Sqrt` | Self-contained |
| **Verify** | `Verify_Discrete_Log` | $G^{X}\equiv Y\pmod{P}$ |
| **Solve** | `Solve_Kangaroo` / `Try_Solve_Kangaroo` | Tame + wild |
| **Result** | `Kangaroo_Result` | `Found` / `X` soft form |
| **Failure** | `Not_Found` | Hard form of miss |
| **Domain** | `Invalid_Argument` | Bad $P$, $G$, $Y$, $[A,B]$, steps |

## Algorithm (lambda / kangaroo intuition)

Suppose $G$ generates (a subgroup of) the multiplicative group modulo a prime
$P$, and $Y=G^{X}$ for some unknown $X\in[A,B]$. Pollard's picture:

1. Choose a small set $S$ of positive jump lengths with mean roughly
   $\sqrt{B-A}$, and a pseudorandom map $f$ from group elements into $S$.
2. **Tame kangaroo** (Wikipedia-faithful start): begin at
   $$
   x_{0}=G^{B}
   $$
   with travelled distance $0$. Jump by
   $$
   x_{i+1}=x_{i}\cdot G^{f(x_{i})},
   $$
   accumulating distance $d=\sum f(x_{i})$. This educational package **stores
   the full tame path** (element $\mapsto$ distance) so that a collision with
   any tame landing can be used — not only the final trap $x_{N}$.
3. **Wild kangaroo**: begin at $y_{0}=Y$ with distance $0$, and use the
   **same** $f$. When the wild kangaroo lands on a previously seen tame
   value,
   $$
   G^{B+d_{\mathrm{tame}}}=Y\cdot G^{d_{\mathrm{wild}}}=G^{X+d_{\mathrm{wild}}},
   $$
   hence
   $$
   X=B+d_{\mathrm{tame}}-d_{\mathrm{wild}}
   $$
   (checked to lie in $[A,B]$ and verified by modular exponentiation).
4. If the wild distance exceeds $B-A+d_{\mathrm{tame}}$ without a hit, the
   attempt fails (change $S$ / $f$, or raise `Not_Found`).

The Greek letter $\lambda$ is a sketch of the two paths: the short stroke is
the tame trail starting at $B$; the long stroke is the wild trail that
eventually joins it.

### Complexity and relation to Pollard's rho

Pollard gives expected running time

$$
O(\sqrt{B-A})
$$

group operations (probabilistic, assuming $f$ is pseudorandom) — a square-root
improvement over brute force $O(B-A)$. When $[A,B]$ is the full residue range
$[0,n-1]$ for group order $n$, this is the same asymptotic class as
**Pollard's rho for logarithms** and **baby-step giant-step**, but kangaroo is
specialized to **known intervals** and needs only a short trail of storage
(here: a tame hash table of size $O(\sqrt{B-A})$ for classroom instances).
Rho uses a Floyd cycle in the full group; BSGS builds an explicit baby table
of size $\Theta(\sqrt{n})$.

### Classroom examples

| Instance | Interval | Log |
| --- | --- | --- |
| $2^{X}\equiv 5\pmod{1019}$ | $[0,20]$ | $X=10$ |
| $5^{X}\equiv 8\pmod{23}$ | $[0,22]$ | $X=6$ |
| $2^{X}\equiv 54\pmod{101}$ | $[0,50]$ | $X=8$ |
| $3^{X}\equiv 13\pmod{17}$ | $[0,16]$ | $X=4$ |

## API

```ada
type U64 is mod 2 ** 64;

type Kangaroo_Result is record
   Found : Boolean := False;
   X     : U64     := 0;
end record;

function Mul_Mod (A, B, M : U64) return U64;
function Mod_Exp (Base, Exp, Modulus : U64) return U64;
function Floor_Sqrt (N : U64) return U64;
function Verify_Discrete_Log (G, Y, P, X : U64) return Boolean;

function Try_Solve_Kangaroo
  (P, G, Y, A, B : U64;
   Max_Steps     : Natural := Default_Max_Steps) return Kangaroo_Result;

function Solve_Kangaroo
  (P, G, Y, A, B : U64;
   Max_Steps     : Natural := Default_Max_Steps) return U64;
--  Raises Not_Found on miss; Invalid_Argument on bad params.
```

**Tame start:** $G^{B}$ (Wikipedia). **Wild start:** $Y$. **Jump set:** powers
of two whose mean tracks $\sqrt{B-A}$. **Educational bound:**
`B - A ≤ Max_Educational_Width` ($2\cdot 10^{6}$).

For very small intervals ($B-A\le 4096$) the implementation uses an exact
brute-force scan (same API); larger intervals exercise the tame/wild path
with a stored tame trail.

| Exception | When |
| --- | --- |
| `Invalid_Argument` | $P<2$, $G\equiv 0$, $Y\equiv 0\pmod{P}$, $A>B$, width too large, `Max_Steps = 0`, or modulus $0$ in helpers |
| `Not_Found` | `Solve_Kangaroo` exhausted steps / no verified $X$ in $[A,B]$ |

## Build and test

```bash
make
make test
```

Equivalent:

```bash
gnatmake -gnatwa -gnat2022 -Ppollards_kangaroo_algorithm.gpr
./bin/tests
```

Expect many `PASS`, `0 FAIL`, and zero `-gnatwa` warnings. Clean with
`make clean`.

## License

Educational sample code for the RobertBoettcherSF Ada algorithm series.
