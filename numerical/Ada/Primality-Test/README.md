# Primality Test — Ada 2023 (Educational Survey)

Educational, self-contained Ada 2023 **survey / umbrella** package for
[Wikipedia: Primality test](https://en.wikipedia.org/wiki/Primality_test):
algorithms that decide whether an integer $N$ is prime (or report that it is
composite / probably prime).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series. Sibling packages are
**independent** — this repo does **not** `with` them; it re-implements short
educational sketches. Full packages live in the siblings linked below.

## Caveats

- **Sketches only** — not production crypto primality / key-generation code.
- Domain is educational `U64` (`mod 2**64`).
- **Miller–Rabin** here is the **deterministic-small** set of bases
  $\{2,7,61\}$, proved sufficient for all $N\le 2^{32}$ (raises if larger).
- **AKS** here is a **tiny hybrid** (perfect-power reject + trial division)
  for $N\le 10\,000$ — **not** the full AKS polynomial congruence test.
- Lucas, Baillie–PSW, sieves, Solovay–Strassen are **catalogue-only**
  (`Is_Implemented = False`); see siblings.

## Deterministic vs probabilistic vs proving

Wikipedia distinguishes:

| Class | Meaning | This survey |
| --- | --- | --- |
| **Deterministic** | Always correct on the stated domain | Trial; MR-small; AKS-tiny; Default |
| **Probabilistic** | May call some composites “probably prime” | Fermat; (catalogue) Baillie–PSW, Solovay–Strassen |
| **Proving** | Affirmative answer proves primality (or exhaustive compositeness) | Trial; MR-small on its domain; AKS-tiny; Lucas (sibling) |
| **Compositeness test** | Witness proves composite; pass ≠ prove prime | Fermat; classical Miller–Rabin |

**Carmichael note.** Carmichael numbers (smallest $561=3\cdot 11\cdot 17$)
satisfy $a^{N-1}\equiv 1\pmod{N}$ for every $a$ **coprime** to $N$. They
**fool** the Fermat test for such bases (e.g. base $2$), but Miller–Rabin
**rejects** $561$. Prefer MR / Baillie–PSW / proving tests over bare Fermat.

## What this package implements

| Area | API | Notes |
| --- | --- | --- |
| **Taxonomy** | `Method_Kind`, `Method_Name`, `Is_Deterministic`, `Is_Probabilistic`, `Is_Proving`, `Is_Implemented` | Survey glue |
| **Helpers** | `Mul_Mod`, `Mod_Pow`, `Gcd`, `Is_Perfect_Square`, `Is_Perfect_Power` | Self-contained |
| **Trial** | `Trial_Division_Is_Prime` | Classic $\sqrt{N}$ loop |
| **Fermat** | `Fermat_Probable_Prime` | Fixed educational bases; `Rounds=1` → base $2$ |
| **Miller–Rabin** | `Miller_Rabin_Deterministic_Small` | Bases $\{2,7,61\}$ for $N\le 2^{32}$ |
| **AKS tiny** | `AKS_Is_Prime_Tiny` | Perfect-power + trial; $N\le 10\,000$ |
| **Default** | `Is_Prime_Default` | Trial for $N\le 10\,000$, else MR-small |
| **Dispatcher** | `Is_Prime(N, Method)` | Implemented methods only |

## Formula summary

### Trial division

For odd $N>3$, try odd divisors up to $\lfloor\sqrt{N}\rfloor$. If none
divide $N$, then $N$ is prime.

### Fermat (probable prime)

Pick base $a$ with $\gcd(a,N)=1$. If

$$
a^{N-1}\not\equiv 1\pmod{N},
$$

then $N$ is composite. If the congruence holds, $N$ is a **Fermat probable
prime** to base $a$ (may still be composite — Carmichael / pseudoprimes).

### Miller–Rabin (strong probable prime)

Write $N-1=2^{s}d$ with $d$ odd. For base $a$, compute $x=a^{d}\bmod N$.
Pass if $x\equiv 1$ or $x\equiv -1$, or if some squaring yields $-1$ before
the last step; otherwise $a$ is a **strong witness** that $N$ is composite.
Fixed bases $\{2,7,61\}$ make the test deterministic for all $N\le 2^{32}$.

### AKS tiny hybrid (not full AKS)

Full AKS is deterministic polynomial-time proving primality via
$(X+a)^{N}\equiv X^{N}+a\pmod{X^{r}-1,\,N}$. This survey only sketches
**step 1** (reject perfect powers) then falls back to trial division on a
tiny domain. See the Ada-AKS sibling for the real algorithm.

## Sibling packages (README links only — no package deps)

| Sibling | Role |
| --- | --- |
| [Ada-Sieve-Of-Eratosthenes](https://github.com/RobertBoettcherSF/Ada-Sieve-Of-Eratosthenes) | Classical sieve catalogue of primes |
| [Ada-Sieve-Of-Atkin](https://github.com/RobertBoettcherSF/Ada-Sieve-Of-Atkin) | Atkin sieve |
| [Ada-Miller-Rabin](https://github.com/RobertBoettcherSF/Ada-Miller-Rabin) | Full MR / deterministic-$64$-bit |
| [Ada-Lucas-Primality-Test](https://github.com/RobertBoettcherSF/Ada-Lucas-Primality-Test) | Lucas / $N-1$ proving tests |
| [Ada-Fermat-Primality-Test](https://github.com/RobertBoettcherSF/Ada-Fermat-Primality-Test) | Full Fermat package + Carmichael notes |
| [Ada-Baillie-PSW](https://github.com/RobertBoettcherSF/Ada-Baillie-PSW) | Baillie–PSW (MR base $2$ + strong Lucas) |
| [Ada-AKS-Primality-Test](https://github.com/RobertBoettcherSF/Ada-AKS-Primality-Test) | Full educational AKS |

## Upcoming (series)

Next sheet planned for the series (not in this package):

- **Odlyzko–Schönhage** (fast multipoint evaluation / prime counting related)
- Then multiplication algorithms that may already exist in the series (parent
  will check)

## Public API (summary)

**Types:** `U64`, `Method_Kind`, `Invalid_Argument`.

**Taxonomy:** `Method_Name`, `Is_Deterministic`, `Is_Probabilistic`,
`Is_Proving`, `Is_Implemented`.

**Helpers:** `Mul_Mod`, `Mod_Pow`, `Gcd`, `Is_Perfect_Square`,
`Is_Perfect_Power`.

**Sketches:** `Trial_Division_Is_Prime`, `Fermat_Probable_Prime`,
`Miller_Rabin_Deterministic_Small`, `AKS_Is_Prime_Tiny`,
`Is_Prime_Default`, `Is_Prime`.

## Usage sketch

```ada
with Primality_Test; use Primality_Test;

procedure Demo is
begin
   pragma Assert (Trial_Division_Is_Prime (97));
   pragma Assert (Fermat_Probable_Prime (561, 1));  -- fools base 2
   pragma Assert (not Miller_Rabin_Deterministic_Small (561));
   pragma Assert (Is_Prime (97, Default));
   pragma Assert (Is_Probabilistic (Fermat));
   pragma Assert (not Is_Implemented (Baillie_PSW));
end Demo;
```

## Building

```bash
cd /workspace/ada-primality-test
make clean && make
```

Uses `gnatmake -gnatwa -gnat2022 -Pprimality_test.gpr`. Expect
**zero** errors and **zero** warnings.

## Testing

```bash
make test
```

Runs `bin/tests`. Exit status $0$ and `Fail_Count = 0` (`pragma Assert`).
Expect a `Passed:` / `Failed:` summary and `ALL PASSED`.

## Layout

```
ada-primality-test/
├── primality_test.ads   # public API
├── primality_test.adb   # implementation
├── primality_test.gpr
├── tests.adb            # main test program
├── Makefile
├── README.md
└── .gitignore
```

Exactly **seven** root files (no `main.adb`). Build artifacts go under `obj/`
and `bin/` (gitignored).

## References

1. [Wikipedia: Primality test](https://en.wikipedia.org/wiki/Primality_test)
2. [Wikipedia: Fermat primality test](https://en.wikipedia.org/wiki/Fermat_primality_test)
3. [Wikipedia: Miller–Rabin primality test](https://en.wikipedia.org/wiki/Miller%E2%80%93Rabin_primality_test)
4. [Wikipedia: Baillie–PSW primality test](https://en.wikipedia.org/wiki/Baillie%E2%80%93PSW_primality_test)
5. [Wikipedia: AKS primality test](https://en.wikipedia.org/wiki/AKS_primality_test)
6. [Wikipedia: Carmichael number](https://en.wikipedia.org/wiki/Carmichael_number)
7. [Wikipedia: Sieve of Eratosthenes](https://en.wikipedia.org/wiki/Sieve_of_Eratosthenes)

## License

Educational / reference use.
