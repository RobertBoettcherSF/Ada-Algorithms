# Pseudorandom Number Generators — Ada 2023 (Educational Survey)

Educational, self-contained Ada 2023 **survey** package for
[Wikipedia: Pseudorandom number generator](https://en.wikipedia.org/wiki/Pseudorandom_number_generator)
(PRNG / DRBG): deterministic algorithms that, from a **seed**, produce a
long sequence whose statistical properties approximate true randomness.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Caveats

- **Survey sketches only** — not production Monte Carlo / cryptography RNGs.
- Three classical toys live **inline** in one package (no sibling `with`).
- Cryptographic use needs a **CSPRNG** (e.g. Blum Blum Shub) — not LCG,
  not this classroom LFG, not plain xorshift.
- John von Neumann’s warning still applies: arithmetical methods of
  producing “random” digits are, of course, in a state of sin.

## What a PRNG is

A PRNG is completely determined by its initial state (the **seed**). Key
classroom notions:

| Notion | Meaning |
| --- | --- |
| **Determinism** | Same seed $\Rightarrow$ same infinite sequence |
| **Period** | Smallest $p>0$ with $X_{n+p}=X_n$ for all large $n$ |
| **Uniformity** | Samples should look i.i.d. uniform on the output domain |
| **Seed** | Initial state $X_0$ (or a vector of words for multi-state engines) |

Poor generators fail statistical tests (short periods for some seeds,
serial correlation, lattice structure). Historical cautionary tale:
**RANDU**. Higher-quality families (Mersenne Twister, WELL, counter-based
RNGs) are catalogue-only here — see Wikipedia and the sibling sheets.

## What this package implements

| `Kind` | Recurrence (classroom sketch) | Notes |
| --- | --- | --- |
| **LCG** | $X_{n+1}=(a X_n+c)\bmod m$ | Numerical Recipes / glibc / Park–Miller params |
| **Lagged_Fibonacci** | $X_n=(X_{n-j}+X_{n-k})\bmod 2^{32}$ | Fixed tiny lags $j=7$, $k=10$ |
| **Xorshift** | $x\oplus\!=x\ll 13$; $\oplus\!=x\gg 7$; $\oplus\!=x\ll 17$ | Marsaglia xorshift64 toy; seed $\neq 0$ |

A unified private `Generator` stores a `Kind` and the active engine state.
`Create` / `Reset` / `Next` / `Next_Float` (values in $[0,1)$) share one API.
Helpers: `Add_Mod` / `Mul_Mod` / `Sub_Mod`, pure `LCG_Step` / `Xorshift_Step`.

## Contrast with algorithm siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Pseudorandom-Number-Generator`) | Survey: LCG + small LFG + xorshift |
| **[Ada-Linear-Congruential-Generator](https://github.com/RobertBoettcherSF/Ada-Linear-Congruential-Generator)** | Dedicated LCG + Hull–Dobell |
| **[Ada-Lagged-Fibonacci-Generator](https://github.com/RobertBoettcherSF/Ada-Lagged-Fibonacci-Generator)** | Dedicated LFG with published lag pairs |
| **[Ada-ACORN-Generator](https://github.com/RobertBoettcherSF/Ada-ACORN-Generator)** | ACORN additive congruential |
| **[Ada-Blum-Blum-Shub](https://github.com/RobertBoettcherSF/Ada-Blum-Blum-Shub)** | $X_{n+1}=X_n^2\bmod M$, $M=pq$ (CSPRNG sketch) |

README links only — **no** package `with` of siblings. Full lag tables,
Hull–Dobell proofs, ACORN order-$k$ state, and BBS modular squaring live
in those dedicated sheets.

## Linear congruential generator

$$
X_{n+1}=(a X_n+c)\bmod m
$$

with modulus $m\ge 2$, multiplier $a\not\equiv 0\pmod m$, increment $c$,
and seed $0\le X_0<m$. When $c=0$ the map is a **multiplicative** /
Lehmer generator. Built-in parameter sets (popularity, not endorsement):

- **Numerical Recipes** — $a=1664525$, $c=1013904223$, $m=2^{32}$
- **glibc / ANSI C** — $a=1103515245$, $c=12345$, $m=2^{31}$
- **Park–Miller MINSTD** — $a=16807$, $c=0$, $m=2^{31}-1$

`Next_Float` returns $X_n/m\in[0,1)$. Modular multiply uses a 128-bit
intermediate so $a\cdot X+c$ never wraps a 64-bit word before reduction.

### Tiny full-period example

With $m=9$, $a=4$, $c=1$, seed $X_0=0$:

$$
0,\;1,\;5,\;3,\;4,\;8,\;6,\;7,\;2,\;0,\;\ldots
$$

(period $9$).

## Lagged Fibonacci (classroom)

Additive two-tap sketch with fixed lags $j=7$, $k=10$ and modulus
$m=2^{32}$:

$$
X_n=(X_{n-j}+X_{n-k})\bmod m.
$$

A ring buffer of length $k$ holds the window. A single seed fills the
buffer via an internal Numerical Recipes LCG (with a forced-odd word so
an all-even state cannot collapse on a power-of-two modulus). Published
lag pairs such as $(24,55)$ belong in the dedicated LFG sibling.

## Xorshift (toy contrast)

Marsaglia’s xorshift64 triple (shifts $13$, $7$, $17$):

$$
\begin{aligned}
x &\leftarrow x\oplus (x\ll 13),\\
x &\leftarrow x\oplus (x\gg 7),\\
x &\leftarrow x\oplus (x\ll 17).
\end{aligned}
$$

Seed must be nonzero (zero is a fixed point). `Next_Float` maps
$X/2^{64}\in[0,1)$. Extremely fast; combine with a nonlinear mix in
real work (xorshift*, xoshiro, etc.) — not done here.

## Algorithm sketch

```text
function Next(G):
    case G.Kind of
      LCG:              X := (A*X + C) mod M
      Lagged_Fibonacci: X := (Buf[n-j] + Buf[n-k]) mod 2^32; write Buf
      Xorshift:         X := xorshift64(X)
    return X

function Next_Float(G):
    X := Next(G)
    if Kind in {LCG, LFG}: return X / M
    else:                  return X / 2^64
```

## Complexity

| Measure | Bound |
| --- | --- |
| Time (`Next` / `Next_Float`) | $O(1)$ word operations |
| Time (`Mul_Mod` / `Add_Mod` / `Sub_Mod`) | $O(1)$ (128-bit intermediate for mul/add) |
| Auxiliary space | $O(1)$ (LFG buffer length $k=10$) |
| LCG state | one residue in $\{0,\ldots,m-1\}$ |
| LFG state | $k$ words modulo $2^{32}$ |
| Xorshift state | one nonzero 64-bit word |

## Features

- **`Kind` enum** — `LCG`, `Lagged_Fibonacci`, `Xorshift` selecting the engine.
- **`Create` / `Create_LCG` / `Create_Lagged_Fibonacci` / `Create_Xorshift`**
- **`Reset` / `Next` / `Next_Float`** — reseed; sample; float in $[0,1)$.
- **Inspectors** — `Get_Kind`, `Get_Seed`, `Get_State`, `Get_LCG_Parameters`,
  `Is_Initialised`.
- **LCG sets** — Numerical Recipes, glibc, Park–Miller; `Reduce_LCG` /
  `Is_Valid_LCG_Parameters` / `LCG_Step`.
- **`Xorshift_Step`** — pure one-step helper.
- **Modular helpers** — `Add_Mod`, `Mul_Mod`, `Sub_Mod`.
- **`Invalid_Argument`** — bad moduli, zero xorshift seed, uninitialised
  generators, out-of-range seeds.

## Testing

The test suite in `tests.adb` covers:

- Uninitialised generators and `Invalid_Argument` edges
- `Kind` dispatch and Create aliases
- Tiny LCG full period ($m=9$, $m=8$); Park–Miller known prefix
- Numerical Recipes / glibc smoke; MCG seed $0$ fixed point
- `Reset` replay for all three engines
- `Next_Float` in $[0,1)$ and exact counter mappings
- LFG buffer state tracking; xorshift hand-computed first step
- Overflow-safe `Mul_Mod` / `Add_Mod` / `Sub_Mod`
- Cross-kind isolation and multi-engine float sweeps

## Building

- Prerequisites: GNAT supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF 13+).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

```bash
make
make test
```

## API

```ada
package Pseudorandom_Number_Generator is
   type Value is mod 2 ** 64;
   type Kind is (LCG, Lagged_Fibonacci, Xorshift);

   type LCG_Parameters is record
      A, C, M : Value;
   end record;

   Numerical_Recipes, Glibc, Park_Miller, Default_LCG : constant LCG_Parameters;
   LFG_J : constant := 7;  LFG_K : constant := 10;
   LFG_Modulus : constant Value := 2 ** 32;
   XS_A : constant := 13;  XS_B : constant := 7;  XS_C : constant := 17;

   type Generator is private;
   Invalid_Argument : exception;

   function Create (Engine : Kind; Seed : Value;
                    Params : LCG_Parameters := Default_LCG) return Generator;
   function Create_LCG (Seed : Value;
                        Params : LCG_Parameters := Default_LCG) return Generator;
   function Create_Lagged_Fibonacci (Seed : Value) return Generator;
   function Create_Xorshift (Seed : Value) return Generator;

   procedure Reset (G : in out Generator; Seed : Value);
   function Next (G : in out Generator) return Value;
   function Next_Float (G : in out Generator) return Long_Float;

   function Get_Kind (G : Generator) return Kind;
   function Get_Seed (G : Generator) return Value;
   function Get_State (G : Generator) return Value;
   function Get_LCG_Parameters (G : Generator) return LCG_Parameters;
   function Is_Initialised (G : Generator) return Boolean;

   function Is_Valid_LCG_Parameters (Params : LCG_Parameters) return Boolean;
   function Reduce_LCG (Params : LCG_Parameters) return LCG_Parameters;
   function LCG_Step (State : Value; Params : LCG_Parameters) return Value;
   function Xorshift_Step (State : Value) return Value;

   function Add_Mod (X, Y, M : Value) return Value;
   function Mul_Mod (X, Y, M : Value) return Value;
   function Sub_Mod (X, Y, M : Value) return Value;
end Pseudorandom_Number_Generator;
```

`Next` is a GNAT `in out` function: it mutates engine state and returns
the new sample. `Get_State` peeks without advancing.

## License

Educational reference implementation. See repository `LICENSE` if present.
