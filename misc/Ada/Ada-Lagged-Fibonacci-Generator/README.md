# Lagged Fibonacci Generator in Ada 2023

## Project Overview

A **lagged Fibonacci generator** (LFG / LFib) is a classical
pseudorandom-number recurrence that generalises the Fibonacci sequence
by combining two earlier terms with lags $j<k$:

$$
X_{n}=(X_{n-j}\star X_{n-k})\bmod m
$$

The binary operation $\star$ is addition, subtraction, or bitwise XOR.
The modulus $m$ is usually a power of two ($m=2^{M}$). An LFG stores
the last $k$ words of state (a lag window); choosing $(j,k)$ so that
$x^{k}+x^{j}+1$ is primitive over $\mathrm{GF}(2)$ is required for a
full period. Additive / subtractive forms need at least one odd seed
word; the theory is sensitive to initialisation (Marsaglia; Knuth).

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation: a ring buffer of length $k$, operations
`Add` / `Subtract` / `Bitwise_Xor`, `Create` / `Reset` / `Next` /
`Next_Float` with $X/m\in[0,1)$, seed from a length-$k$ array or from
a single seed via an LCG fill, common lag pairs as constants
($(24,55)$, …, $(273,607)$), `Max_Lag=1024`, and
`Invalid_Argument` for bad lags, modulus, or seed length.

Primary source:
[Wikipedia — Lagged Fibonacci generator](https://en.wikipedia.org/wiki/Lagged_Fibonacci_generator).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with algorithm siblings

| Package / method | Idea |
| --- | --- |
| **This package** (`Ada-Lagged-Fibonacci-Generator`) | $X_{n}=(X_{n-j}\star X_{n-k})\bmod m$, $\star\in\{+,-,\mathrm{xor}\}$ |
| Linear congruential generator (sibling sheet) | $X_{n+1}=(a X_{n}+c)\bmod m$ |
| Blum Blum Shub (sibling sheet) | $X_{n+1}=X_{n}^{2}\bmod M$, $M=pq$ (CSPRNG) |

README links only — **no** package `with` of siblings. An LCG stores
one residue modulo $m$. An LFG stores a lag window of $k$ words. BBS
squares modulo a Blum integer and is intended for cryptography.

Two-tap XOR LFGs (GFSR) have well-known three-point correlations
(Marsaglia; Ziff); they must **not** be used for cryptography. Prefer
larger lags, more taps, or a different family when quality matters.

## Recurrence

The generator is specified by

- $j,k$ with $0<j<k\le\texttt{Max\_Lag}$ — the **lags**
- $\star\in\{+,-,\mathrm{xor}\}$ — the **binary operation**
- $m\ge 2$ — the **modulus**
- $X_{0},\ldots,X_{k-1}$ — the **seed window**

and the map $X_{n}=(X_{n-j}\star X_{n-k})\bmod m$ for $n\ge k$.
`Next` after `Create` returns $X_{k}$. `Next_Float` returns the same
$X_{n}$ scaled into the unit interval:

$$
U_{n}=\frac{X_{n}}{m}\in[0,1).
$$

### Operations (documented)

| `Binary_Op` | Formula | Classical name |
| --- | --- | --- |
| `Add` | $(X_{n-j}+X_{n-k})\bmod m$ | Additive LFG (ALFG) |
| `Subtract` | $(X_{n-j}-X_{n-k})\bmod m$ | Subtractive LFG |
| `Bitwise_Xor` | $(X_{n-j}\mathbin{\mathrm{xor}}X_{n-k})\bmod m$ | Two-tap GFSR |

(Ada reserves the keyword `xor`, so the enumeration uses
`Bitwise_Xor`.)

### Period sketch

For addition or subtraction the maximum period is
$(2^{k}-1)\cdot 2^{M-1}$ when $m=2^{M}$. For XOR it is $2^{k}-1$.
Achieving the bound requires the trinomial $x^{k}+x^{j}+1$ to be
primitive over $\mathrm{GF}(2)$.

### Example

With $j=1$, $k=2$, $m=16$, $\star=+$, seeds $X_{0}=1$, $X_{1}=1$:

$$
2,\;3,\;5,\;8,\;13,\;5,\;2,\;7,\;9,\;0,\;\ldots
$$

(the Fibonacci sequence modulo $16$).

## Algorithm

### Ring buffer

State is a circular buffer $B[0..k-1]$ holding the last $k$ outputs.
A write cursor $C$ points at the slot that currently stores
$X_{n-k}$ (about to be overwritten):

1. Read $X_{n-k}\leftarrow B[C]$ and
   $X_{n-j}\leftarrow B[(C+k-j)\bmod k]$.
2. Form $X_{n}=(X_{n-j}\star X_{n-k})\bmod m$.
3. Store $B[C]\leftarrow X_{n}$, advance $C\leftarrow(C+1)\bmod k$.
4. Return $X_{n}$.

### Seed fill

`Create(..., Seeds)` requires `Seeds'Length = k` and every word
$< m$. `Create(..., Seed)` fills the window with a Numerical Recipes
LCG reduced modulo $m$, then forces at least one odd word for
`Add` / `Subtract`.

### Pseudocode

```text
function Next(G):
    Xk := G.Buffer[G.Cursor]
    Xj := G.Buffer[(G.Cursor + G.K - G.J) mod G.K]
    Xn := Combine(Xj, Xk, G.Op) mod G.M
    G.Buffer[G.Cursor] := Xn
    G.Cursor := (G.Cursor + 1) mod G.K
    return Xn

function Next_Float(G):
    return Next(G) / G.M                        -- in [0, 1)
```

### Asymptotic cost

Each sample is $O(1)$ word operations. Storage is $O(k)$ for the
ring buffer ($k\le\texttt{Max\_Lag}=1024$).

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time (`Next` / `Next_Float`) | $O(1)$ |
| Time (`Create` / `Reset` array) | $O(k)$ |
| Time (`Create` / `Reset` LCG fill) | $O(k)$ |
| Auxiliary space | $O(1)$ beyond the $k$-word buffer |
| State | $k$ words in $\{0,\ldots,m-1\}$ |
| Supported $k$ | $2\le k\le 1024$ |
| Supported $m$ | $2\le m\le 2^{64}-1$ |
| Output | $X_{n}\in\{0,\ldots,m-1\}$ or $X_{n}/m\in[0,1)$ |

## Features

- **`Binary_Op`** — `Add`, `Subtract`, `Bitwise_Xor` (documented ★).
- **Ring buffer** — length $k$, cursor, `Get_Buffer_Word`.
- **`Create` / `Reset` / `Next` / `Next_Float`** — array or LCG seed.
- **Lag constants** — $(24,55)$, $(38,89)$, $(37,100)$, $(30,127)$,
  $(83,258)$, $(107,378)$, $(273,607)$; `Default_Modulus=2^{32}$.
- **`Max_Lag = 1024`** — classroom cap on $k$.
- **Modular helpers** — `Add_Mod` / `Sub_Mod` / `Xor_Mod` / `Combine`.
- **`Invalid_Argument`** — bad lags ($j\ge k$), $m<2$, seed length
  $\ne k$, seed word $\ge m$, uninitialised generator.
- **Zero-warning build** —
  `gnatmake -gnatwa -gnat2022 -Plagged_fibonacci_generator.gpr`.

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

=== 1. Invalid_Argument (bad lags / modulus / seeds) ===
  PASS: ...
...
Results:  NN PASS, 0 FAIL
```

(Exact `NN` is the current suite size; it is at least 150.)

## Testing

The test suite in `tests.adb` covers:

- `Invalid_Argument` for $j\ge k$, $m<2$, bad seed length / words,
  uninitialised generators, and modulus-$0$ helpers
- Deterministic tiny LFGs ($j=1,k=2,m=16$ Fibonacci; subtract; XOR)
- Known short sequences for $j=2,k=5$ and $j=3,k=7$
- `Reset` replay (array and single-seed); independent twins
- `Next_Float` in $[0,1)$ and $U=X/m$
- Lag-pair constants and `Lag_Pair` `Create` overloads
- `Add_Mod` / `Sub_Mod` / `Xor_Mod` / `Combine` (including wide words)
- Cursor wrap; buffer inspect after advance
- Smoke on $(24,55)$, $(38,89)$, $(30,127)$, $(83,258)$,
  $(107,378)$, $(273,607)$

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Lagged_Fibonacci_Generator is
   type Value is mod 2 ** 64;
   Max_Lag : constant Positive := 1024;
   subtype Lag_Index is Positive range 1 .. Max_Lag;

   type Binary_Op is (Add, Subtract, Bitwise_Xor);

   type Seed_Array is array (Positive range <>) of Value;

   type Lag_Pair is record
      J, K : Lag_Index;
   end record;

   Lag_24_55, Lag_38_89, Lag_37_100, Lag_30_127,
   Lag_83_258, Lag_107_378, Lag_273_607 : constant Lag_Pair;
   Default_Modulus : constant Value;  -- 2**32

   type Generator is private;
   Invalid_Argument : exception;

   function Is_Valid_Lags (J, K : Positive) return Boolean;
   function Is_Valid_Lags (Lags : Lag_Pair) return Boolean;
   function Is_Valid_Modulus (M : Value) return Boolean;

   function Create (J, K : Lag_Index; Op : Binary_Op; M : Value;
                    Seeds : Seed_Array) return Generator;
   function Create (J, K : Lag_Index; Op : Binary_Op; M : Value;
                    Seed : Value) return Generator;
   function Create (Lags : Lag_Pair; Op : Binary_Op; M : Value;
                    Seeds : Seed_Array) return Generator;
   function Create (Lags : Lag_Pair; Op : Binary_Op; M : Value;
                    Seed : Value) return Generator;

   procedure Reset (G : in out Generator; Seeds : Seed_Array);
   procedure Reset (G : in out Generator; Seed : Value);
   function Next (G : in out Generator) return Value;
   function Next_Float (G : in out Generator) return Long_Float;

   function Get_J (G : Generator) return Lag_Index;
   function Get_K (G : Generator) return Lag_Index;
   function Get_Op (G : Generator) return Binary_Op;
   function Get_Modulus (G : Generator) return Value;
   function Get_Cursor (G : Generator) return Natural;
   function Get_Buffer_Word (G : Generator; Index : Lag_Index) return Value;
   function Is_Initialised (G : Generator) return Boolean;

   function Add_Mod (X, Y, M : Value) return Value;
   function Sub_Mod (X, Y, M : Value) return Value;
   function Xor_Mod (X, Y, M : Value) return Value;
   function Combine (X, Y : Value; Op : Binary_Op; M : Value) return Value;
end Lagged_Fibonacci_Generator;
```

Raises `Invalid_Argument` when $j\ge k$, when $m<2$, when a seed
array length $\ne k$, when a seed word is $\ge m$, when an
uninitialised generator is used, or when a modular helper is called
with modulus $0$.

`Next` is a GNAT `in out` function: it mutates the ring buffer and
returns $X_{n}$. `Get_Buffer_Word` peeks without advancing.

## License

Educational reference implementation. See repository `LICENSE` if present.
