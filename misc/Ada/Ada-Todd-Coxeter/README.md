# Todd–Coxeter algorithm (coset enumeration) — Ada 2023

Educational, self-contained Ada 2023 package for the **Todd–Coxeter algorithm**
of J. A. Todd and H. S. M. Coxeter (1936): enumerate the cosets of a finitely
generated subgroup $H$ inside a finitely presented group
$G=\langle X\mid R\rangle$ and build the permutation representation of $G$
acting on those cosets by right multiplication. See
[Wikipedia: Todd–Coxeter algorithm](https://en.wikipedia.org/wiki/Todd–Coxeter_algorithm).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series
(e.g. [Ada-Image-Based-Lighting](https://github.com/RobertBoettcherSF/Ada-Image-Based-Lighting)).

Sibling / related rows (README links only — **no** package `with`):

- **Coxeter groups / reflection presentations** (planned educational sketch)
- **Schreier–Sims** (permutation-group order; planned)
- **Next (educational sketches):** Reidemeister–Schreier rewriting

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Alphabet** | lowercase gens `'a'..'z'`; uppercase = inverse | `'A'=a^{-1}` |
| **Input** | `Presentation` + subgroup `Word_List` | relators = identity words |
| **Table** | `Coset_Table (coset, column)` | gens then inverses |
| **Core** | `Enumerate (Pres, Subgroup, Limit)` | HLT-style define / scan / coincide |
| **Result** | `Index`, `Table`, `Success` | `Index=[G:H]` when finite & in bound |
| **Failure** | `Success=False` | `Limit` exceeded before close |
| **Domain** | `Invalid_Argument` | ill-formed gens / words / Limit |

## Coset enumeration intuition

A **right coset** of $H$ in $G$ is a set $Hg=\{hg:h\in H\}$. The group $G$
acts on the set of right cosets by right multiplication:

$$
(Hg)\cdot x = Hgx\qquad(x\in G).
$$

If the **index** $[G:H]$ is finite, there are only finitely many cosets, and
the action is a permutation representation
$G\to S_{[G:H]}$. Todd–Coxeter builds that action **from a presentation**,
without knowing a concrete model of $G$:

1. Start with coset $1=H$.
2. **Define** new cosets whenever a table entry $c\cdot g$ is still unknown
   (and the living count is under `Limit`).
3. **Scan** every relator at every live coset: because a relator $r$ equals
   $1$ in $G$, the path labelled $r$ must close ($c\cdot r=c$). Filling both
   ends of a relation row yields **deductions** (forced table entries).
4. Subgroup generators fix coset $1$: $1\cdot h=1$ for each generator $h$ of
   $H$.
5. When two definitions collide ($c\cdot g$ cannot be both $c_1$ and $c_2$),
   a **coincidence** identifies $c_1=c_2$; merge the larger into the smaller
   and propagate.

When every live row is complete and no undefined entries remain, the
algorithm terminates and `Index` equals $[G:H]$.

### Coincidence

A coincidence is the discovery that two formally distinct coset numbers
name the same set. If the table already has $c\cdot g=c_1$ and a deduction
demands $c\cdot g=c_2$ with $c_1\neq c_2$, then $c_1=c_2$. The package keeps a
representative map (union–find style), merges the larger id into the
smaller, and re-checks neighbouring entries — which may cascade into further
coincidences.

### When it terminates

- If $[G:H]<\infty$, Todd–Coxeter **always** finishes in finitely many steps
  (for a fair definition strategy that eventually defines $Hg$ for every
  known coset $H$ and generator $g$).
- The number of steps is **not** bounded by any computable function of the
  index alone in the general case — this is a classroom toy with
  `Default_Max_Cosets = 256`.
- If the index is infinite (e.g. free group $\langle a,b\mid\rangle$), or
  merely larger than `Limit`, `Enumerate` returns `Success => False`.

### Classroom identities

| Presentation | $H$ | Index |
| --- | --- | --- |
| $C_n=\langle a\mid a^n\rangle$ | $\{1\}$ | $n$ |
| $C_n$ | $\langle a\rangle=G$ | $1$ |
| $C_6$ | $\langle a^2\rangle$ | $2$ |
| $S_3=\langle a,b\mid a^2,b^3,(ab)^2\rangle$ | $\{1\}$ | $6$ |
| $S_3$ | $\langle a\rangle$ | $3$ |
| $S_3$ | $\langle b\rangle$ | $2$ |
| $A_4=\langle a,b\mid a^2,b^3,(ab)^3\rangle$ | $\{1\}$ | $12$ |
| $V_4=\langle a,b\mid a^2,b^2,(ab)^2\rangle$ | $\{1\}$ | $4$ |
| $D_4=\langle a,b\mid a^4,b^2,(ab)^2\rangle$ | $\{1\}$ | $8$ |
| $Q_8=\langle a,b\mid a^4,a^2b^{-2},b^{-1}aba\rangle$ | $\{1\}$ | $8$ |

Special cases worth memorising:

- $H=G$ (subgroup generators include a generating set of $G$) $\Rightarrow$
  index $1$.
- $H=\{1\}$ (empty subgroup word list) and $G$ finite $\Rightarrow$
  index $=|G|$.

## API

```ada
function Make_Word (S : String) return Word;

function Make_Presentation
  (Gens     : String;
   Relators : Word_List) return Presentation;

function Enumerate
  (Pres     : Presentation;
   Subgroup : Word_List;
   Limit    : Positive := Default_Max_Cosets) return Result;
--  Result.Success, Result.Index = [G:H], Result.Table action

function Column_Of (Pres : Presentation; Gen : Character) return Natural;
function Action (R : Result; Coset : Positive; Col : Positive) return Coset_Id;
function Trace
  (R : Result; Pres : Presentation; Start : Positive; W : Word) return Coset_Id;
```

**Alphabet.** `Make_Presentation ("ab", …)` declares generators $a,b$. Words
may use `a`,`b`,`A`,`B` where `A=a^{-1}`, `B=b^{-1}`. Relators are words set
equal to the identity (e.g. `"aa"` for $a^2=1$, `"Baba"` for
$b^{-1}aba=1$).

**Exceptions.** `Invalid_Argument` on non-letter word characters, uppercase
or duplicate generators, undeclared letters, overlong words, or
`Limit > Default_Max_Cosets`.

**Observers.** After a successful run, `Action` / `Trace` read the compacted
coset table on live ids `1 .. Index` (coset `1` is always $H$).

## Build & test

```bash
make        # gnatmake -gnatwa -gnat2022 -Ptodd_coxeter.gpr
make test   # prints many PASS lines and: Results:  N PASS, 0 FAIL
make clean
```

Root layout (exactly seven tracked sources — **no** `main.adb`):

| File | Role |
| --- | --- |
| `todd_coxeter.ads` / `.adb` | package spec / body |
| `todd_coxeter.gpr` | GNAT project (main = `tests.adb`) |
| `tests.adb` | standalone test harness |
| `Makefile` | `all` / `test` / `clean` |
| `README.md` | this file |
| `.gitignore` | `obj/` `bin/` |

## References

- Todd, J. A.; Coxeter, H. S. M. (1936). “A practical method for enumerating
  cosets of a finite abstract group”. *Proc. Edinburgh Math. Soc.* (2) **5**:
  26–34.
- Coxeter, H. S. M.; Moser, W. O. J. (1980). *Generators and Relations for
  Discrete Groups*. Springer.
- [Wikipedia: Todd–Coxeter algorithm](https://en.wikipedia.org/wiki/Todd–Coxeter_algorithm)
