# ACORN Generator in Ada 2023

## Project Overview

An **ACORN** (**A**dditive **C**ongruential **R**andom **N**umber) generator
is an order-$k$ family of pseudorandom number generators introduced by
R.S. Wikramaratna (1989). State is a vector $Y^{(0)},\ldots,Y^{(k)}$;
each step performs an additive sweep

$$
Y_{n}^{(m)}=\bigl(Y_{n}^{(m-1)}+Y_{n-1}^{(m)}\bigr)\bmod M
\qquad(m=1,\ldots,k)
$$

and returns $Y_{n}^{(k)}$ (or $Y_{n}^{(k)}/M\in[0,1)$). The seed-stream
component $Y^{(0)}$ is held fixed. Integer arithmetic with a large
modulus $M$ (commonly a power of two) makes the sequence reproducible
across platforms; ACORN was designed for geostatistical / geophysical
Monte Carlo and later shown to pass the TestU01 suite for suitable
$(k,M)$.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation: a limited-style private `Generator` holding order $k$,
modulus $M$, and state $Y[0..k]$, `Create` / `Reset` from a
length-$(k+1)$ seed array or from a single seed via an LCG fill,
`Next` / `Next_Float`, inspectors, overflow-safe `Add_Mod`,
`Default_Modulus=2^{32}`, `Max_Order=64`, and `Invalid_Argument` for
bad order, modulus, or seeds.

Primary source:
[Wikipedia — ACORN (PRNG)](https://en.wikipedia.org/wiki/ACORN_(PRNG)).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with algorithm siblings

| Package / method | Idea |
| --- | --- |
| **This package** (`Ada-ACORN-Generator`) | order-$k$ additive sweep $Y^{(m)}\leftarrow(Y^{(m)}+Y^{(m-1)})\bmod M$ |
| Linear congruential generator (sibling sheet) | $X_{n+1}=(a X_{n}+c)\bmod m$ |
| Lagged Fibonacci generator (sibling sheet) | $X_{n}=(X_{n-j}\star X_{n-k})\bmod m$, $\star\in\{+,-,\mathrm{xor}\}$ |
| Blum Blum Shub (sibling sheet) | $X_{n+1}=X_{n}^{2}\bmod M$, $M=pq$ (CSPRNG) |

README links only — **no** package `with` of siblings. An LCG stores
one residue. An LFG stores a lag window of $k$ words. ACORN stores
$k+1$ words and advances them with a triangular additive recurrence
(equivalent to a special multiple recursive / matrix generator). BBS
squares modulo a Blum integer and is intended for cryptography.

ACORN in its present form has **not** been shown suitable for
cryptography. Prefer a CSPRNG when adversarial robustness matters.

## Recurrence

The generator is specified by

- $k$ with $1\le k\le\texttt{Max\_Order}$ — the **order**
- $M\ge 2$ — the **modulus**
- $Y_{0},\ldots,Y_{k}$ with each $Y_{i}\in\{0,\ldots,M-1\}$ — the **state**

At each call to `Next`, for $i=1,\ldots,k$ in place:

$$
Y_{i}\leftarrow(Y_{i}+Y_{i-1})\bmod M
$$

while $Y_{0}$ is left unchanged. The returned variate is $Y_{k}$.
`Next_Float` returns the same value scaled into the unit interval:

$$
U=\frac{Y_{k}}{M}\in[0,1).
$$

### Seed fill

`Create(Order, M, Seeds)` requires `Seeds'Length = Order + 1` and every
word $< M$. `Create(Order, M, Seed)` fills $Y[0..k]$ with a Numerical
Recipes LCG reduced modulo $M$, then forces $Y[0]$ odd when $M$ is even
(literature preference: avoid the all-even invariant subspace).

### Example

With $k=2$, $M=16$, seeds $Y=[1,0,0]$:

$$
1,\;3,\;6,\;10,\;15,\;5,\;\ldots
$$

($Y_{0}$ stays $1$; each step adds the previous component into the next.)

## Algorithm

### Additive sweep

1. Require the generator to be initialised ($k\ge 1$, $M\ge 2$).
2. For $i=1..k$: $Y[i]\leftarrow(Y[i]+Y[i-1])\bmod M$ using a
   128-bit intermediate (`Add_Mod`).
3. Return $Y[k]$.

### Pseudocode

```text
function Next(G):
    for i in 1 .. G.Order loop
        G.Y[i] := (G.Y[i] + G.Y[i-1]) mod G.M
    end loop
    return G.Y[G.Order]

function Next_Float(G):
    return Next(G) / G.M                        -- in [0, 1)
```

### Asymptotic cost

Each sample is $O(k)$ word additions. Storage is $O(k)$ for the state
vector ($k\le\texttt{Max\_Order}=64$).

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time (`Next` / `Next_Float`) | $O(k)$ |
| Time (`Create` / `Reset` array) | $O(k)$ |
| Time (`Create` / `Reset` LCG fill) | $O(k)$ |
| Time (`Add_Mod`) | $O(1)$ widening arithmetic |
| Auxiliary space | $O(1)$ beyond the $(k+1)$-word buffer |
| State | $k+1$ words in $\{0,\ldots,M-1\}$ |
| Supported $k$ | $1\le k\le 64$ |
| Supported $M$ | $2\le M\le 2^{64}-1$ |
| Output | $Y_{k}\in\{0,\ldots,M-1\}$ or $Y_{k}/M\in[0,1)$ |

## Features

- **`Generator`** — order $k$, modulus $M$, state $Y[0..k]$.
- **`Create` / `Reset`** — length-$(k+1)$ seed array, or single-seed
  LCG fill (odd $Y[0]$ forced when $M$ even).
- **`Next` / `Next_Float`** — additive sweep; float in $[0,1)$.
- **Inspectors** — `Order_Of`, `Modulus_Of`, `Get_State`, `Get_Y`,
  `Is_Initialised`.
- **`Add_Mod`** — overflow-safe $(X+Y)\bmod M$ via 128-bit intermediate.
- **`Default_Modulus`** / **`Max_Order`** — $2^{32}$ and $64$.
- **`Invalid_Argument`** — $M<2$, bad seed length, seed $\ge M$,
  uninitialised use, `Add_Mod` with $M=0$, `Get_Y` out of range.
- **Zero-warning build** —
  `gnatmake -gnatwa -gnat2022 -Pacorn_generator.gpr`.

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

=== 1. Invalid_Argument (bad modulus / seeds / length) ===
  PASS: ...
...
Results:  NN PASS, 0 FAIL
```

(Exact `NN` is the current suite size; it is at least 150.)

## Testing

The test suite in `tests.adb` covers:

- `Invalid_Argument` for $M<2$, bad seed length, seed $\ge M$,
  uninitialised generators, and $M=0$ helpers
- Deterministic tiny ACORNs ($k=1$ counter; $k=2$ hand sequence;
  $k=3$ binomial-like from zero upper state)
- `Reset` array / LCG-fill replay; independent generators
- `Next_Float` in $[0,1)$ and $U=Y_{k}/M$ on small moduli
- `Add_Mod` identities and overflow-safe cases
- Inspectors; $Y_{0}$ fixed across advances; range checks
- `Default_Modulus` / `Max_Order` Create smoke
- Power-of-two moduli; varied order / modulus batches

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Acorn_Generator is
   type Value is mod 2 ** 64;

   Max_Order : constant Positive := 64;
   subtype Order_Type is Positive range 1 .. Max_Order;
   Default_Modulus : constant Value := 2 ** 32;

   type State_Array is array (Natural range <>) of Value;
   type Generator is private;
   Invalid_Argument : exception;

   function Is_Valid_Order (K : Positive) return Boolean;
   function Is_Valid_Modulus (M : Value) return Boolean;

   function Create
     (Order : Order_Type; M : Value; Seeds : State_Array)
      return Generator;
   function Create
     (Order : Order_Type; M : Value; Seed : Value)
      return Generator;
   procedure Reset (G : in out Generator; Seeds : State_Array);
   procedure Reset (G : in out Generator; Seed : Value);

   function Next (G : in out Generator) return Value;
   function Next_Float (G : in out Generator) return Long_Float;

   function Order_Of (G : Generator) return Order_Type;
   function Modulus_Of (G : Generator) return Value;
   function Get_State (G : Generator) return State_Array;
   function Get_Y (G : Generator; Index : Natural) return Value;
   function Is_Initialised (G : Generator) return Boolean;

   function Add_Mod (X, Y, M : Value) return Value;
end Acorn_Generator;
```

Raises `Invalid_Argument` when $M<2$, when a seed array length is not
$k+1$, when any seed word is $\ge M$, when an uninitialised generator
is used, when `Get_Y` is called with `Index > Order`, or when
`Add_Mod` is called with modulus $0$.

`Next` is a GNAT `in out` function: it mutates $Y[1..k]$ and returns
$Y_{k}$. `Get_State` / `Get_Y` peek without advancing. Seed arrays are
indexed from $0$ through $k$ (length $k+1$).

## License

Educational reference implementation. See repository `LICENSE` if present.
