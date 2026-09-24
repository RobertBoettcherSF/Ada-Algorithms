# Discrete logarithm — Ada 2023

Educational, self-contained Ada 2023 **survey** of the **discrete logarithm
problem** (DLP): given a cyclic group $G=\langle\alpha\rangle$ of order $n$
and $\beta\in G$, find $\gamma$ such that

$$
\alpha^{\gamma}=\beta.
$$

No efficient classical algorithm is known in general; hardness of carefully
chosen instances underlies Diffie–Hellman, ElGamal, DSA, and elliptic-curve
cryptography. See
[Wikipedia: Discrete logarithm](https://en.wikipedia.org/wiki/Discrete_logarithm).

This package is a **classroom sketch** on `U64`: trial multiplication,
baby-step giant-step (Shanks), a minimal Pohlig–Hellman-style path for
smooth order (trial factor + CRT), and a `Discrete_Log` driver with
documented educational bounds. It is **not** a cryptographic DLP solver.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

Sibling / related rows (README links only — **no** package `with`):

- **[Ada-Baby-Step-Giant-Step](https://github.com/RobertBoettcherSF/Ada-Baby-Step-Giant-Step)** —
  dedicated Shanks BSGS ($\Theta(\sqrt{n})$ time and space)
- **[Ada-Pohlig-Hellman](https://github.com/RobertBoettcherSF/Ada-Pohlig-Hellman)** —
  full Pohlig–Hellman for smooth order (prime-power digits + CRT)
- **[Ada-Pollards-Rho-Logarithms](https://github.com/RobertBoettcherSF/Ada-Pollards-Rho-Logarithms)** —
  Pollard's rho for discrete logarithms ($O(\sqrt{n})$ expected, low memory)
- **[Ada-Index-Calculus](https://github.com/RobertBoettcherSF/Ada-Index-Calculus)** —
  index calculus sketch for tiny prime fields
- Catalogue / upcoming: Pollard's kangaroo / lambda, NFS-DL, Shor (quantum)

Empty GitHub repo:
[Ada-Discrete-Logarithm](https://github.com/RobertBoettcherSF/Ada-Discrete-Logarithm).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Word** | `U64` (`mod 2**64`) | Educational domain |
| **Helpers** | `Mul_Mod`, `Mod_Pow`, `Gcd`, `Modular_Inverse` | Self-contained |
| **Sqrt** | `Floor_Sqrt`, `Ceil_Sqrt` | $m=\lceil\sqrt{n}\rceil$ |
| **Verify** | `Verify_Discrete_Log` | $\alpha^{\gamma}\equiv\beta\pmod{p}$ |
| **Trial** | `Discrete_Log_Trial` | Exhaustive search $O(n)$ |
| **BSGS** | `Discrete_Log_BSGS` | Shanks meet-in-the-middle |
| **PH** | `Discrete_Log_Pohlig_Hellman` | Minimal smooth-order sketch |
| **Driver** | `Discrete_Log` | Trial if $n\le$ `Max_Trial_Order`, else BSGS |
| **Failure** | return `Order` | Documented sentinel |
| **Domain** | `Invalid_Argument` | Bad modulus / order / $\alpha,\beta$ |

## Hardness and cryptography

Discrete exponentiation (modular powering) is easy; the inverse — discrete
log — is believed hard in black-box groups and in carefully chosen
multiplicative groups / elliptic curves. Classical generic algorithms need
roughly $\Omega(\sqrt{n})$ group operations; subexponential index-calculus /
NFS methods exist for some finite fields, and Shor's algorithm solves DLP in
polynomial time on a sufficiently large quantum computer.

Crypto systems that rest on DLP-style assumptions include:

- Diffie–Hellman key exchange
- ElGamal encryption
- Digital Signature Algorithm (DSA) / ECDSA
- Elliptic-curve Diffie–Hellman (ECDH)

Classroom takeaway: keep educational orders tiny (`Max_Educational_Order`);
real cryptography uses 256-bit (or larger) group orders where these sketches
are infeasible.

## Algorithms in this survey

### 1. Trial multiplication

Walk $\mathrm{Cur}:=1$, $\mathrm{Cur}:=\mathrm{Cur}\cdot\alpha$ for
$\gamma=0,\ldots,n-1$. Practical only for tiny $n$ (driver uses trial when
$n\le$ `Max_Trial_Order` $=256$).

### 2. Baby-step giant-step (Shanks)

Write $\gamma=im+j$ with $m=\lceil\sqrt{n}\rceil$. Precompute baby table
$(\alpha^{j},j)$ and walk giant steps $y_i=\beta\cdot(\alpha^{-m})^{i}$.
Complexity $\Theta(\sqrt{n})$ time and space. Full sibling package:
**Ada-Baby-Step-Giant-Step**.

### 3. Minimal Pohlig–Hellman-style path

When $n=\prod p_i^{e_i}$ is smooth (every $p_i\le$ `Max_Prime_Factor`),
factor $n$, solve a tiny exhaustive DLP in each prime-power subgroup, and
combine with CRT. Orders that are not smooth enough return the failure
sentinel. Full sibling: **Ada-Pohlig-Hellman**.

### 4. Driver `Discrete_Log`

$$
\begin{cases}
\text{trial} & \text{if }n\le\texttt{Max\_Trial\_Order},\\
\text{BSGS} & \text{otherwise (and }n\le\texttt{Max\_Educational\_Order}).
\end{cases}
$$

Documented educational max order: `Max_Educational_Order` $=2\cdot 10^{6}$.

### Classroom examples

| Instance | Demo |
| --- | --- |
| $2^{\gamma}\equiv 5\pmod{1019}$, $n=1018$ | $\gamma=10$ |
| $5^{\gamma}\equiv 8\pmod{23}$, $n=22$ | $\gamma=6$ |
| $2^{\gamma}\equiv 54\pmod{101}$, $n=100$ | $\gamma=8$ |
| Smooth $n=12,16,18,22,30$ via PH | known exponents recovered |
| $\beta=1$ | $\gamma=0$ |
| $\beta\notin\langle\alpha\rangle$ | failure sentinel `Order` |
| Bad modulus / order / $\alpha=0$ | `Invalid_Argument` |

## What the code actually does

### Helpers

`Mul_Mod` multiplies via `Unsigned_128`. `Mod_Pow` is binary exponentiation.
`Gcd` is Euclidean. `Modular_Inverse` uses a self-contained extended
Euclidean algorithm on `Long_Long_Integer`. `Floor_Sqrt` / `Ceil_Sqrt` set
BSGS $m=\lceil\sqrt{n}\rceil$. `Factorize_Trial` supports the PH path.

### Solvers

`Discrete_Log_Trial` exhausts the cyclic orbit. `Discrete_Log_BSGS` builds a
linear-lookup baby table and walks giant steps. `Discrete_Log_Pohlig_Hellman`
factors the order, lifts $p$-adic digits exhaustively, and CRT-combines.
`Discrete_Log` dispatches trial vs BSGS by `Max_Trial_Order`.

All solvers return $\gamma\in\{0,\ldots,n-1\}$ or the failure sentinel $n$
(`Order`), and raise `Invalid_Argument` for bad inputs / oversized order.

## API summary

| Symbol | Role |
| --- | --- |
| `U64` | `mod 2**64` word type |
| `Mul_Mod` / `Mod_Pow` / `Gcd` | modular arithmetic helpers |
| `Modular_Inverse` | $\alpha^{-m}$ / CRT helper |
| `Floor_Sqrt` / `Ceil_Sqrt` | integer square roots |
| `Verify_Discrete_Log` | check $\alpha^{\log}\equiv\beta$ |
| `Factorize_Trial` | smooth-order trial factorization |
| `Discrete_Log_Trial` | exhaustive DLP |
| `Discrete_Log_BSGS` | Shanks BSGS sketch |
| `Discrete_Log_Pohlig_Hellman` | minimal smooth-order PH |
| `Discrete_Log` | driver (trial / BSGS) |
| `Invalid_Argument` | domain error |
| `Max_Educational_Order` | classroom cap on $n$ ($2\cdot 10^{6}$) |
| `Max_Trial_Order` | driver trial threshold ($256$) |

## Build and test

Requires GNAT with Ada 2022 support (`-gnat2022`).

```bash
make        # gnatmake -gnatwa -gnat2022 -Pdiscrete_logarithm.gpr
make test   # run bin/tests (≥100 PASS, zero warnings/errors)
make clean
```

`SPARK_Mode => Off`; self-contained (no sibling `with`).

## Limits and caveats

- Educational `U64` toy — **not** a cryptographic discrete-log solver.
- BSGS table lookup is intentionally $O(m)$ linear search for clarity.
- PH path refuses primes larger than `Max_Prime_Factor` (sentinel).
- Related rows: **BSGS**, **Pohlig–Hellman**, **Pollard's rho for
  logarithms**, **index calculus**.

## License

Educational sample for the RobertBoettcherSF Ada algorithm series.
