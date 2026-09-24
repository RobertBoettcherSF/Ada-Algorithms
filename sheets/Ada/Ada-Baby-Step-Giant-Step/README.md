# Baby-step giant-step (Shanks) — Ada 2023

Educational, self-contained Ada 2023 package for the **baby-step giant-step**
(BSGS) algorithm due to **Daniel Shanks**: solve the discrete logarithm
$\alpha^{\gamma}=\beta$ in a cyclic group of known order $n$ by a
meet-in-the-middle table of baby steps $\alpha^{j}$ and giant steps with
$\alpha^{-m}$, where $m=\lceil\sqrt{n}\rceil$. Time and space
$\Theta(\sqrt{n})$. See
[Wikipedia: Baby-step giant-step](https://en.wikipedia.org/wiki/Baby-step_giant-step).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

Sibling / related rows (README links only — **no** package `with`):

- **[Ada-Pohlig-Hellman](https://github.com/RobertBoettcherSF/Ada-Pohlig-Hellman)** —
  Pohlig–Hellman (smooth-order DLP; BSGS is a common prime-power subroutine)
- **[Ada-Pollards-Rho-Logarithms](https://github.com/RobertBoettcherSF/Ada-Pollards-Rho-Logarithms)** —
  Pollard's rho for discrete logarithms ($O(\sqrt{n})$ expected, low memory)
- **[Ada-Extended-Euclidean-Algorithm](https://github.com/RobertBoettcherSF/Ada-Extended-Euclidean-Algorithm)** —
  Bézout / modular inverse used for $\alpha^{-m}$
- **Next (educational sketches):** **index calculus**

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Word** | `U64` (`mod 2**64`) | Educational domain |
| **Helpers** | `Mul_Mod`, `Mod_Pow`, `Modular_Inverse` | Self-contained |
| **Sqrt** | `Floor_Sqrt`, `Ceil_Sqrt` | $m=\lceil\sqrt{n}\rceil$ |
| **Verify** | `Verify_Discrete_Log` | $\alpha^{\gamma}\equiv\beta\pmod{p}$ |
| **BSGS DLP** | `Discrete_Log_BSGS` | Baby table + giant steps |
| **Failure** | return `Order` | Documented sentinel |
| **Domain** | `Invalid_Argument` | Bad modulus / order / $\alpha,\beta$ |

## Algorithm

Given a cyclic group $G=\langle\alpha\rangle$ of order $n$ and $\beta\in G$,
write

$$
\gamma=im+j,\qquad m=\lceil\sqrt{n}\rceil,\quad 0\le j<m,\quad 0\le i<m.
$$

**Baby steps.** Precompute the table

$$
\bigl(\alpha^{j},\, j\bigr)\qquad\text{for }j=0,\ldots,m-1.
$$

This educational package uses a simple array with **linear $O(m)$ lookup**
(fine for toy sizes; a hash map would be $O(1)$ expected).

**Giant steps.** Let $y_0=\beta$ and $y_{i+1}=y_i\cdot\alpha^{-m}$. For each
$i=0,\ldots,m-1$, look up $y_i$ in the baby table. A match
$\alpha^{j}=y_i=\beta\cdot(\alpha^{-m})^{i}$ yields

$$
\gamma=im+j.
$$

Complexity is

$$
\Theta(\sqrt{n})
$$

group operations and $\Theta(\sqrt{n})$ storage. Pohlig–Hellman often calls
BSGS (or a sibling) inside each prime-power subgroup; Pollard's rho for
logarithms targets the same $O(\sqrt{n})$ time with far less memory;
index calculus is asymptotically faster in finite fields of suitable size.

### Classroom examples

| Instance | Demo |
| --- | --- |
| $2^{\gamma}\equiv 5\pmod{1019}$, $n=1018$ | $\gamma=10$ |
| $5^{\gamma}\equiv 8\pmod{23}$, $n=22$ | $\gamma=6$ |
| $2^{\gamma}\equiv 54\pmod{101}$, $n=100$ | $\gamma=8$ |
| Tiny prime fields $p\le 97$ | known exponents recovered |
| $\beta=1$ | $\gamma=0$ |
| $\beta\notin\langle\alpha\rangle$ | failure sentinel `Order` |
| Bad modulus / order / $\alpha=0$ | `Invalid_Argument` |

## What the code actually does

### Helpers

`Mul_Mod` multiplies via `Unsigned_128`. `Mod_Pow` is binary exponentiation.
`Modular_Inverse` uses a self-contained extended Euclidean algorithm on
`Long_Long_Integer`. `Floor_Sqrt` / `Ceil_Sqrt` set $m=\lceil\sqrt{n}\rceil$.

### `Discrete_Log_BSGS`

Build the baby table, invert $\alpha^{m}$, walk giant steps, linear-lookup
each $y_i$. Returns $\gamma\in\{0,\ldots,n-1\}$ or the failure sentinel $n$
(`Order`). Raises `Invalid_Argument` for bad inputs or order above
`Max_Educational_Order`.

## API summary

| Symbol | Role |
| --- | --- |
| `U64` | `mod 2**64` word type |
| `Mul_Mod` / `Mod_Pow` | modular multiply / power |
| `Modular_Inverse` | $\alpha^{-m}$ helper |
| `Floor_Sqrt` / `Ceil_Sqrt` | integer square roots |
| `Verify_Discrete_Log` | check $\alpha^{\log}\equiv\beta$ |
| `Discrete_Log_BSGS` | Shanks baby-step giant-step DLP |
| `Invalid_Argument` | domain error |
| `Max_Educational_Order` | classroom cap on $n$ ($2\cdot 10^{6}$) |

## Build and test

Requires GNAT with Ada 2022 support (`-gnat2022`).

```bash
make        # gnatmake -gnatwa -gnat2022 -Pbaby_step_giant_step.gpr
make test   # run bin/tests (≥80 PASS, zero warnings/errors)
make clean
```

`SPARK_Mode => Off`; self-contained (no sibling `with`).

## Limits and caveats

- Educational `U64` toy — **not** a cryptographic discrete-log solver.
- Table lookup is intentionally $O(m)$ linear search for clarity.
- Storage $\Theta(\sqrt{n})$; keep $n\le$ `Max_Educational_Order`.
- Related rows: **Pohlig–Hellman**, **Pollard's rho for logarithms**,
  **index calculus**.

## License

Educational sample for the RobertBoettcherSF Ada algorithm series.
