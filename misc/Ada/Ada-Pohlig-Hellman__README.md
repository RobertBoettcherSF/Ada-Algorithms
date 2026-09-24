# Pohlig–Hellman algorithm — Ada 2023

Educational, self-contained Ada 2023 package for the **Pohlig–Hellman
algorithm** (Silver–Pohlig–Hellman): solve the discrete logarithm
$\alpha^{\gamma}=\beta$ in a cyclic group of known order $n$ when $n$ is
**smooth** (factors into small primes). Factor $n$, solve a DLP in each
prime-power subgroup, and combine with the Chinese remainder theorem. See
[Wikipedia: Pohlig–Hellman algorithm](https://en.wikipedia.org/wiki/Pohlig–Hellman_algorithm).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

Sibling / related rows (README links only — **no** package `with`):

- **[Ada-Pollards-Rho-Logarithms](https://github.com/RobertBoettcherSF/Ada-Pollards-Rho-Logarithms)** —
  Pollard's rho for discrete logarithms ($O(\sqrt{n})$ expected)
- **[Ada-Extended-Euclidean-Algorithm](https://github.com/RobertBoettcherSF/Ada-Extended-Euclidean-Algorithm)** —
  Bézout / modular inverse used in CRT and inverses
- **Next (educational sketches):** **baby-step giant-step (BSGS)**,
  **index calculus**

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Word** | `U64` (`mod 2**64`) | Educational domain |
| **Helpers** | `Mul_Mod`, `Mod_Pow`, `Gcd`, `Sub_Mod`, `Modular_Inverse` | Self-contained |
| **Factor** | `Factorize_Trial` | Smooth-order trial factorization |
| **Verify** | `Verify_Discrete_Log` | $\alpha^{\gamma}\equiv\beta\pmod{m}$ |
| **PH DLP** | `Discrete_Log_Pohlig_Hellman` | Subgroup DLP + CRT |
| **Failure** | return `Order` | Documented sentinel |
| **Domain** | `Invalid_Argument` | Bad modulus / order / $\alpha,\beta$ |

## Algorithm

Given a cyclic group $G=\langle\alpha\rangle$ of order
$n=\prod_i p_i^{e_i}$ and $\beta\in G$, Pohlig–Hellman reduces the DLP to
subgroups of prime-power order.

For each prime power $p_i^{e_i}$:

$$
g_i=\alpha^{n/p_i^{e_i}},\qquad
h_i=\beta^{n/p_i^{e_i}},
$$

so $\operatorname{ord}(g_i)=p_i^{e_i}$ and $h_i\in\langle g_i\rangle$. Solve
$g_i^{x_i}=h_i$ with the prime-power subroutine, then recover $\gamma$ from

$$
\gamma\equiv x_i\pmod{p_i^{e_i}}\qquad\forall i
$$

via the Chinese remainder theorem.

### Prime-power subroutine

Write $x=d_0+d_1 p+\cdots+d_{e-1}p^{e-1}$ with digits $d_k\in\{0,\ldots,p-1\}$.
Let $\gamma=g^{p^{e-1}}$ (order $p$). For $k=0,\ldots,e-1$:

$$
h_k=\bigl(g^{-x_k}h\bigr)^{p^{e-1-k}},\qquad
\gamma^{d_k}=h_k,\qquad
x_{k+1}=x_k+p^k d_k.
$$

Each digit $d_k$ is found by exhaustive search (tiny $p$) or a classroom
BSGS-lite scan. Complexity for smooth $n$ is roughly

$$
O\Bigl(\sum_i e_i\bigl(\log n+\sqrt{p_i}\bigr)\Bigr)
$$

group operations — far better than $O(\sqrt{n})$ when all $p_i$ are small.

### Classroom examples

| Instance | Demo |
| --- | --- |
| $2^{\gamma}\equiv 5\pmod{29}$, $n=28=2^{2}\cdot 7$ | $\gamma=22$ |
| $2^{\gamma}\equiv 151\pmod{181}$, $n=180=2^{2}\cdot 3^{2}\cdot 5$ | $\gamma=123$ |
| $5^{\gamma}\equiv 8\pmod{23}$, $n=22=2\cdot 11$ | $\gamma=6$ |
| $2^{\gamma}\equiv 13\pmod{19}$, $n=18=2\cdot 3^{2}$ | $\gamma=5$ |
| $\beta=1$ | $\gamma=0$ |

## What the code actually does

### Helpers

`Mul_Mod` multiplies via `Unsigned_128`. `Mod_Pow` is binary
exponentiation. `Gcd` / `Modular_Inverse` / `Sub_Mod` support CRT and
inverses (self-contained extended Euclidean on `Long_Long_Integer`).

### Factorization

`Factorize_Trial` splits a smooth educational order into ascending
prime-power factors. `Is_Smooth_Enough` rejects primes above
`Max_Prime_Factor` (search bound).

### `Discrete_Log_Pohlig_Hellman`

Auto-factors `Order` (or accepts a precomputed `Factor_Array`), solves each
prime-power DLP, CRT-combines, and verifies. Returns
$\gamma\in\{0,\ldots,n-1\}$ or the failure sentinel $n$ (`Order`) when the
order is not smooth enough, a digit search fails, or $\beta\notin\langle\alpha\rangle$.
Raises `Invalid_Argument` for bad inputs or order above
`Max_Educational_Order`.

## API summary

| Symbol | Role |
| --- | --- |
| `U64` | `mod 2**64` word type |
| `Mul_Mod` / `Mod_Pow` | modular multiply / power |
| `Gcd` / `Sub_Mod` / `Modular_Inverse` | CRT / inverse helpers |
| `Factorize_Trial` / `Prime_Power` / `Factor_Array` | smooth-order factors |
| `Product_Of_Factors` / `Is_Smooth_Enough` | factor utilities |
| `Verify_Discrete_Log` | check $\alpha^{\log}\equiv\beta$ |
| `Discrete_Log_Pohlig_Hellman` | Pohlig–Hellman DLP (auto / precomputed factors) |
| `Invalid_Argument` | domain error |
| `Max_Educational_Order` | classroom cap on $n$ ($2\cdot 10^{6}$) |
| `Max_Prime_Factor` | largest $p$ allowed in digit search |

## Build and test

Requires GNAT with Ada 2022 support (`-gnat2022`).

```bash
make        # gnatmake -gnatwa -gnat2022 -Ppohlig_hellman.gpr
make test   # run bin/tests (≥80 PASS, zero warnings/errors)
make clean
```

`SPARK_Mode => Off`; self-contained (no sibling `with`).

## Limits and caveats

- Educational `U64` toy — **not** a cryptographic discrete-log solver.
- Requires a **smooth** order; a large prime factor returns the sentinel
  `Order` (use Pollard's rho / BSGS / index calculus siblings instead).
- Caller must supply the correct subgroup order of $\alpha$.
- Distinct from Pollard's rho for **integer factorization**.

## License

Educational sample for the RobertBoettcherSF Ada algorithm series.
