# Linear Congruential Generator in Ada 2023

## Project Overview

A **linear congruential generator** (LCG) is a classical
pseudorandom-number recurrence

$$
X_{n+1}=(a X_{n}+c)\bmod m
$$

with integer parameters $m$ (modulus), $a$ (multiplier), $c$
(increment) and seed $X_{0}$. When $c=0$ the recurrence is a
**multiplicative congruential generator** (MCG / Lehmer RNG). The
method is one of the oldest PRNGs (Lehmer 1951; Thomson and Rotenberg
1958): cheap, easy to analyse, and extremely sensitive to the choice
of $(a,c,m)$.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation: a `Parameters` record $(A,C,M)$, a `Generator` holding
state $X_{n}$ and the last seed, `Create` / `Reset` / `Next` /
`Next_Float` with $X/m\in[0,1)$, well-known library parameter sets as
constants, overflow-safe modular multiply via a 128-bit intermediate,
and optional **Hull–Dobell** full-period checks. `Invalid_Argument` is raised for $m=0$ and other illegal parameters
($m=1$, $a\equiv 0\pmod m$, seed $\ge m$). Published multipliers
may exceed $m$; they are reduced modulo $m$.

Primary source:
[Wikipedia — Linear congruential generator](https://en.wikipedia.org/wiki/Linear_congruential_generator).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with algorithm siblings

| Package / method | Idea |
| --- | --- |
| **This package** (`Ada-Linear-Congruential-Generator`) | $X_{n+1}=(a X_{n}+c)\bmod m$ |
| Lagged Fibonacci generator (sibling sheet) | $X_{n}=X_{n-j}\pm X_{n-k}\pmod{2^{w}}$ (or XOR) |
| Blum Blum Shub (sibling sheet) | $X_{n+1}=X_{n}^{2}\bmod M$, $M=pq$ (CSPRNG) |
| Mersenne Twister (sibling sheet) | twisted GFSR, period $2^{19937}-1$ |

README links only — **no** package `with` of siblings. An LCG stores
one residue modulo $m$. An LFG stores a lag window; BBS squares modulo
a Blum integer and is intended for cryptography; the Mersenne Twister
is a linear recurrence over $\mathrm{GF}(2)$ with a much larger state.

LCGs must **not** be used for cryptography. The low-order bits of a
power-of-two-modulus LCG have a short period (Marsaglia); prefer the
high bits, or a different family, when quality matters.

## Recurrence

The generator is specified by integers

- $m$, $0<m$ — the **modulus**
- $a$, $0<a<m$ — the **multiplier**
- $c$, $0\le c<m$ — the **increment**
- $X_{0}$, $0\le X_{0}<m$ — the **seed**

and the map $X_{n+1}=(a X_{n}+c)\bmod m$. This package requires the
slightly stricter classroom bounds $m\ge 2$ (so $a$ can be nonzero and
strictly less than $m$). `Next` after `Create(P, X_0)` returns $X_{1}$.
`Next_Float` returns the same $X_{n}$ scaled into the unit interval:

$$
U_{n}=\frac{X_{n}}{m}\in[0,1).
$$

### Hull–Dobell full period

When $c\neq 0$, the period equals $m$ for **every** seed if and only if

1. $\gcd(c,m)=1$,
2. $a-1$ is divisible by every prime factor of $m$,
3. $a-1$ is divisible by $4$ whenever $m$ is divisible by $4$.

These are the **Hull–Dobell** conditions, exposed as
`Increment_Coprime`, `Multiplier_Condition`, `Four_Condition`, and
`Hull_Dobell_Satisfied`. An MCG ($c=0$) never has period $m$ for
$m>1$ (the state $0$ is a fixed point). A common full-period recipe
for $m=2^{k}$ is $a\equiv 5\pmod{8}$ and $c$ odd.

### Example

With $m=9$, $a=4$, $c=1$, seed $X_{0}=0$:

$$
0,\;1,\;5,\;3,\;4,\;8,\;6,\;7,\;2,\;0,\;\ldots
$$

The three Hull–Dobell tests hold, and the period is $9$. The nearby
choice $a=2$ (still $c=1$, $m=9$) fails condition (2) and has period
$6$ only.

## Algorithm

### Advance

Given valid $(a,c,m)$ and state $X$:

1. Form the double-width product $a\cdot X$ (128-bit intermediate).
2. Add $c$ and reduce modulo $m$.
3. Store and return the new residue.

No 64-bit wrap of $a\cdot X+c$ is allowed to happen *before* the
reduction: that would silently change the modulus. Helpers `Mul_Mod`
and `Add_Mod` expose the same overflow-safe arithmetic.

### Pseudocode

```text
function Next(G):
    G.State := (G.A * G.State + G.C) mod G.M    -- 128-bit intermediate
    return G.State

function Next_Float(G):
    return Next(G) / G.M                        -- in [0, 1)
```

### Asymptotic cost

Each sample is $O(1)$ word operations (one widening multiply, one
add, one remainder). Trial division for `Prime_Factors_Divide` /
Hull–Dobell is $O(\sqrt{m})$ and is not on the sampling path.
Storage is $O(1)$: one `Parameters` triple plus state and seed.

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time (`Next` / `Next_Float` / `Step`) | $O(1)$ widening arithmetic |
| Time (`Mul_Mod` / `Add_Mod`) | $O(1)$ |
| Time (`Gcd`) | $O(\log m)$ |
| Time (Hull–Dobell / `Prime_Factors_Divide`) | $O(\sqrt{m})$ trial division |
| Auxiliary space | $O(1)$ |
| State | one residue in $\{0,\ldots,m-1\}$ |
| Supported $m$ | $2\le m\le 2^{64}-1$ |
| Output | $X_{n}\in\{0,\ldots,m-1\}$ or $X_{n}/m\in[0,1)$ |

## Features

- **`Parameters` / `Generator`** — $A,C,M$ and state / seed types.
- **`Create` / `Reset` / `Reduce`** — install parameters and $X_{0}$.
- **`Next` / `Next_Float` / `Step`** — recurrence; float in $[0,1)$.
- **Built-in sets** — Numerical Recipes, glibc / ANSI C, Borland C,
  Delphi, Microsoft Visual C / Visual Basic, Park–Miller /
  `minstd_rand`, RANDU, `java.util.Random`, VMS `MTH$RANDOM`, ZX81.
- **Hull–Dobell helpers** — the three conditions and their
  conjunction; `Gcd` / `Are_Coprime` / `Prime_Factors_Divide`.
- **Overflow-safe modular mul** — 128-bit intermediate (`Mul_Mod`).
- **`Invalid_Argument`** — $m=0$, $m=1$, $a\equiv 0\pmod m$,
  seed or state $\ge m$.
- **Zero-warning build** —
  `gnatmake -gnatwa -gnat2022 -Plinear_congruential_generator.gpr`.

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

=== 1. Invalid_Argument (M = 0 / bad params / bad seed) ===
  PASS: ...
...
Results:  NN PASS, 0 FAIL
```

(Exact `NN` is the current suite size; it is at least 150.)

## Testing

The test suite in `tests.adb` covers:

- `Invalid_Argument` for $m=0$, $m=1$, $a \equiv 0 \pmod m$,
  seed / state $\ge m$, uninitialised generators, and $M=0$ helpers
- Deterministic tiny LCGs ($m=9$ full period; $m=8$; counter / Weyl)
- Known short sequences: Park–Miller, glibc, Numerical Recipes,
  Borland, Delphi, MSVC, Visual Basic, Java, RANDU, ZX81
- `Reset` replay; independent generators; `Step` $\equiv$ `Next`
- `Next_Float` in $[0,1)$ and $U=X/m$ on small moduli
- Hull–Dobell true / false cases and the three component tests
- `Gcd` / `Are_Coprime` / `Prime_Factors_Divide` / `Add_Mod` /
  `Mul_Mod` (including products that overflow 32- and 64-bit words)
- Built-in parameter-set validity; MCG seed $0$ stays $0$
- Full-period family $m=16$, $a=5$, odd $c$

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Linear_Congruential_Generator is
   type Value is mod 2 ** 64;

   type Parameters is record
      A, C, M : Value;     -- multiplier, increment, modulus
   end record;

   type Generator is private;
   Invalid_Argument : exception;

   Numerical_Recipes, Glibc, ANSI_C, Borland_C, Borland_Delphi,
   Microsoft_Visual_C, Microsoft_Visual_Basic, Park_Miller,
   MINSTD_Rand, RANDU, Java_Util_Random, VMS_MTH_Random, ZX81
     : constant Parameters;

   function Is_Valid_Parameters (Params : Parameters) return Boolean;
   function Reduce (Params : Parameters) return Parameters;
   function Create (Params : Parameters; Seed : Value) return Generator;
   procedure Reset (G : in out Generator; Seed : Value);
   function Next (G : in out Generator) return Value;
   function Next_Float (G : in out Generator) return Long_Float;
   function Step (State : Value; Params : Parameters) return Value;

   function Get_Parameters (G : Generator) return Parameters;
   function Get_State (G : Generator) return Value;
   function Get_Seed (G : Generator) return Value;

   function Add_Mod (X, Y, M : Value) return Value;
   function Mul_Mod (X, Y, M : Value) return Value;
   function Gcd (X, Y : Value) return Value;
   function Are_Coprime (X, Y : Value) return Boolean;

   function Prime_Factors_Divide (D, M : Value) return Boolean;
   function Increment_Coprime (Params : Parameters) return Boolean;
   function Multiplier_Condition (Params : Parameters) return Boolean;
   function Four_Condition (Params : Parameters) return Boolean;
   function Hull_Dobell_Satisfied (Params : Parameters) return Boolean;
end Linear_Congruential_Generator;
```

Raises `Invalid_Argument` when $m=0$ or $m=1$, when
$a\equiv 0\pmod m$, when a seed or state is $\ge m$, or when
`Add_Mod` / `Mul_Mod` / `Prime_Factors_Divide` is called with
modulus $0$. Hull–Dobell helpers raise on invalid `Parameters`.
Published $a$ or $c$ may exceed $m$ (they are reduced).

`Next` is a GNAT `in out` function: it mutates $X_{n}$ and returns
$X_{n+1}$. `Get_State` peeks without advancing.

## License

Educational reference implementation. See repository `LICENSE` if present.
