# Prime Factorization — Ada 2023 (Educational Survey)

Educational, self-contained Ada 2023 **survey / umbrella** package for
[Wikipedia: Integer factorization](https://en.wikipedia.org/wiki/Integer_factorization)
(sheet row name **“prime factorization algorithm”**): taxonomy of special-
vs general-purpose methods plus short sketches of **trial division**,
**Fermat factorization**, and **Pollard's rho** (Floyd).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series. Sibling packages are
**independent** — this repo does **not** `with` them; it re-implements short
educational sketches. Full packages live in the siblings linked below.

## Caveats

- **Sketches only** — not production crypto factorization / RSA-breaking code.
- Domain is educational `U64` (`mod 2**64`).
- **Fermat** is efficient only when factors are **close**; use `Max_Steps`.
- **Pollard's rho** is a toy Floyd loop ($f(x)=x^{2}+C\bmod N$); may fail
  (returns $1$) on unlucky seeds / constants.
- QS, SNFS, GNFS, ECM, Pollard's $p-1$, and Shor are **catalogue-only**
  (`Is_Implemented = False`); see siblings / upcoming rows.

## Special-purpose vs general-purpose

Wikipedia splits factoring algorithms by what the runtime depends on:

| Class | Runtime depends on | This survey |
| --- | --- | --- |
| **Special-purpose** | Size / form of an unknown factor (or special $N$) | Trial; Fermat; Pollard's rho; Pollard's $p-1$ (catalogue); SNFS; ECM |
| **General-purpose** | Bit-length of $N$ only (Kraitchik / CoS family) | QS; GNFS; Default hybrid |
| **Quantum** | Polynomial in $\log N$ on a quantum computer | Shor (catalogue) |

Hardest classical instances in practice are **semiprimes** with two large
balanced primes (RSA moduli). No classical polynomial-time algorithm for
all integers is known; GNFS is the asymptotic champion for large $N$.

## What this package implements

| Area | API | Notes |
| --- | --- | --- |
| **Taxonomy** | `Method_Kind`, `Method_Name`, `Is_Special_Purpose`, `Is_General`, `Is_Implemented` | Survey glue |
| **Helpers** | `Gcd`, `Mul_Mod`, `Is_Prime_Trial`, `Floor_Sqrt` | Self-contained |
| **Trial** | `Trial_Division_Factor`, `Factorize_Trial` | Least factor + full peel |
| **Fermat** | `Fermat_Factor` | Odd $N$ near a square; e.g. $455839=599\times761$ |
| **Rho** | `Pollard_Rho_Factor` | Floyd toy; e.g. $8051=83\times97$ |
| **Default** | `Factor(N, Method)`, `Factorize` | Trial then rho hybrid |

## Formula summary

### Trial division

Try candidate divisors $2,3,5,\ldots$ up to $\lfloor\sqrt{N}\rfloor$. The
first hit is a least prime factor; peel powers and continue on the cofactor
for a complete factorization.

### Fermat factorization

For odd $N$, set $a=\lceil\sqrt{N}\rceil$ and increment $a$ until
$a^{2}-N=b^{2}$ is a perfect square. Then

$$
N=(a-b)(a+b).
$$

Fast when the factors are close (small $a-\lceil\sqrt{N}\rceil$).

### Pollard's rho (Floyd)

Iterate $x\mapsto x^{2}+c\pmod{N}$ with tortoise/hare pointers. A collision
with $\gcd(|x-y|,N)=d$ often yields a non-trivial factor $d$.

### Default hybrid

Educational practical path: strip small trial factors; if $N$ is still
composite, try Pollard's rho; fall back to deterministic trial.

## Sibling packages (README links only — no package deps)

| Sibling | Role |
| --- | --- |
| [Ada-Trial-Division](https://github.com/RobertBoettcherSF/Ada-Trial-Division) | Full trial-division factorization |
| [Ada-Quadratic-Sieve](https://github.com/RobertBoettcherSF/Ada-Quadratic-Sieve) | QS congruence-of-squares sketch |
| [Ada-Special-Number-Field-Sieve](https://github.com/RobertBoettcherSF/Ada-Special-Number-Field-Sieve) | SNFS-like CoS sketch |
| [Ada-Primality-Test](https://github.com/RobertBoettcherSF/Ada-Primality-Test) | Primality survey (trial / Fermat / MR / …) |

Catalogue / upcoming (linked when published):

- **Pollard's rho** (dedicated sibling — **next** sheet after this survey)
- **Fermat factorization** (dedicated package)
- **ECM** (Lenstra elliptic curve method)
- **GNFS** (general number field sieve)
- **[Shor’s algorithm](https://github.com/RobertBoettcherSF)** — quantum
  polynomial-time factoring (`Ada-Shors-Algorithm` elsewhere in the org)

## Upcoming (series)

Next sheet planned for the series (not in this package):

- **Pollard's rho algorithm** (full dedicated educational package)

## Public API (summary)

**Types:** `U64`, `Method_Kind`, `Prime_Power`, `Factor_List`,
`Invalid_Argument`.

**Taxonomy:** `Method_Name`, `Is_Special_Purpose`, `Is_General`,
`Is_Implemented`.

**Helpers:** `Gcd`, `Mul_Mod`, `Is_Prime_Trial`, `Floor_Sqrt`.

**Sketches:** `Trial_Division_Factor`, `Factorize_Trial`, `Fermat_Factor`,
`Pollard_Rho_Factor`, `Factor`, `Factorize`.

## Usage sketch

```ada
with Prime_Factorization; use Prime_Factorization;

procedure Demo is
   F : U64;
   L : Factor_List := Factorize (8051);
begin
   pragma Assert (Trial_Division_Factor (91) = 7);
   F := Fermat_Factor (455839);
   pragma Assert (F = 599 or else F = 761);
   F := Pollard_Rho_Factor (8051);
   pragma Assert (F = 83 or else F = 97);
   pragma Assert (L'Length = 2);
   pragma Assert (Is_Special_Purpose (Pollard_Rho));
   pragma Assert (not Is_Implemented (GNFS));
end Demo;
```

## Building

```bash
cd /workspace/ada-prime-factorization
make clean && make
```

Uses `gnatmake -gnatwa -gnat2022 -Pprime_factorization.gpr`. Expect
**zero** errors and **zero** warnings.

## Testing

```bash
make test
```

Runs `bin/tests`. Exit status $0$ and `Fail_Count = 0` (`pragma Assert`).
Expect a `Passed:` / `Failed:` summary and `ALL PASSED`.

## Layout

```
ada-prime-factorization/
├── prime_factorization.ads   # public API
├── prime_factorization.adb   # implementation
├── prime_factorization.gpr
├── tests.adb                # main test program
├── Makefile
├── README.md
└── .gitignore
```

Exactly **seven** root files (no `main.adb`). Build artifacts go under `obj/`
and `bin/` (gitignored).

## References

1. [Wikipedia: Integer factorization](https://en.wikipedia.org/wiki/Integer_factorization)
2. [Wikipedia: Trial division](https://en.wikipedia.org/wiki/Trial_division)
3. [Wikipedia: Fermat's factorization method](https://en.wikipedia.org/wiki/Fermat%27s_factorization_method)
4. [Wikipedia: Pollard's rho algorithm](https://en.wikipedia.org/wiki/Pollard%27s_rho_algorithm)
5. [Wikipedia: Quadratic sieve](https://en.wikipedia.org/wiki/Quadratic_sieve)
6. [Wikipedia: Special number field sieve](https://en.wikipedia.org/wiki/Special_number_field_sieve)
7. [Wikipedia: General number field sieve](https://en.wikipedia.org/wiki/General_number_field_sieve)
8. [Wikipedia: Lenstra elliptic-curve factorization](https://en.wikipedia.org/wiki/Lenstra_elliptic-curve_factorization)
9. [Wikipedia: Shor's algorithm](https://en.wikipedia.org/wiki/Shor%27s_algorithm)

## License

Educational / reference use.
