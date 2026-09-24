# Division Algorithms — Ada 2023 (Educational Survey)

Educational, self-contained Ada 2023 **survey / umbrella** package for
[Wikipedia: Division algorithm](https://en.wikipedia.org/wiki/Division_algorithm):
given numerator $N$ and denominator $D$, compute quotient and/or remainder
of Euclidean division

$$
N/D=(Q,R),
$$

with $N=Q\cdot D+R$.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series. Sibling packages are
**independent** — this repo does **not** `with` them; it re-implements short
educational sketches. Full packages live in the siblings linked below.

## Caveats

- **Sketches only** — not production ALU / FPU division hardware.
- Restoring / non-restoring use a fixed educational width (`Operand_Bits = 8`).
- Schoolbook long division is base-$10$ `Digit_Vector` for **non-negatives**.
- Newton–Raphson / Goldschmidt are educational `Long_Float` cores.
- **SRT** is catalogued (`SRT_Catalogue`) but **not** implemented here — see
  the sibling SRT package (no PD-plot reimplementation).

## Slow vs fast

Division algorithms fall into two main Wikipedia categories:

| Class | Idea | Methods (this survey) | Digits per step |
| --- | --- | --- | --- |
| **Slow** | One quotient digit per iteration | Schoolbook / long, restoring, non-restoring; SRT (sibling) | $\approx 1$ |
| **Fast** | Start near $Q$; refine multiplicatively | Newton–Raphson, Goldschmidt | roughly **doubles** |
| **Oracle** | Language operators | Ada `/` and `rem`; `Long_Float` `/` | n/a |

Slow recurrence (restoring family):

$$
R\leftarrow 2R+n_i,\qquad
\text{trial }R-D,\quad
q_i\in\{0,1\}\text{ (restore if negative)}.
$$

Fast Newton reciprocal then multiply:

$$
X\leftarrow X(2-DX),\qquad Q=N\cdot X.
$$

Fast Goldschmidt scale both streams:

$$
F_i=2-D_i,\qquad N\leftarrow N F_i,\qquad D\leftarrow D F_i
\quad(D\to 1,\ N\to Q).
$$

## What this package implements

| Area | API | Notes |
| --- | --- | --- |
| **Taxonomy** | `Method_Kind`, `Method_Name`, `Is_Slow`, `Is_Fast`, `Is_Implemented` | Survey glue; SRT catalogue-only |
| **Digit_Vector** | `From_Natural`, `To_Natural`, `To_String`, `Compare`, … | Base $10$, `Max_Limbs = 18` |
| **Schoolbook** | `Divide_Long`, `Divide_Schoolbook` | Non-negative long division |
| **Restoring** | `Divide_Restoring`, `Divide_Restoring_Unsigned` | Radix-$2$, digits $\{0,1\}$ |
| **Non-restoring** | `Divide_Non_Restoring`, `Divide_Non_Restoring_Unsigned` | Digits $\{-1,+1\}$ + correction |
| **Newton–Raphson** | `Divide_NR`, `Divide_NR_Detail` | Reciprocal then $Q=N\cdot X$ |
| **Goldschmidt** | `Divide_Goldschmidt`, `Divide_Goldschmidt_Detail` | Parallel-friendly $N,D$ scales |
| **Oracle** | `Divide_Oracle`, `Exact_Quotient` | Ada `/`/`rem`; Float `/` |
| **Dispatcher** | `Divide(N,D,Method)` | Integer methods only |

Unified `Division_Result` for integer sketches; `Float_Division_Result` for
fast Float methods. `Invalid_Argument` on $D=0$ (and related domain errors).
Methods agree with the oracle on tested domains.

## Formula summary

### Euclidean identity

$$
N=Q\cdot D+R,\qquad
|R|<|D|\ \text{(or }R=0\text{)}.
$$

Ada truncating semantics: $Q$ toward zero; when $R\neq 0$, $R$ has the same
sign as $N$ (`rem`).

### Schoolbook (base $10$)

Bring down the next dividend digit into a partial remainder $P$; choose the
largest digit $q\in\{0,\ldots,9\}$ with $q\cdot D\le P$; subtract; repeat.

### Restoring (radix $2$)

For each bit of $N$ (MSB first): shift, trial-subtract $D$; if the trial is
negative, **restore** and emit $q_i=0$; else keep the difference and emit
$q_i=1$.

### Non-restoring (radix $2$)

No restore: according to the sign of $R$, add or subtract $D$ after the
shift, emitting $q_i\in\{-1,+1\}$. Final correction if $R<0$.

### Newton–Raphson

Find $X\approx 1/D$ by Newton on $f(X)=1/X-D$:

$$
X_{i+1}=X_i(2-D X_i),\qquad \varepsilon_{i+1}\approx\varepsilon_i^{2},
$$

then $Q=N\cdot X$.

### Goldschmidt

Normalize $|D|$ into $(\tfrac12,1]$, then iterate $F_i=2-D_i$ on both $N$
and $D$ until $D\to 1$; the scaled numerator is $Q$. Same quadratic rate as
NR; presentation keeps two multiplies that can run in parallel in hardware.

## Sibling packages (README links only — no package deps)

| Sibling | Role |
| --- | --- |
| [Ada-Long-Division](https://github.com/RobertBoettcherSF/Ada-Long-Division) | Full pencil-and-paper decimal long division |
| [Ada-Restoring-Division](https://github.com/RobertBoettcherSF/Ada-Restoring-Division) | Fixed-width restoring teaching package |
| [Ada-Non-Restoring-Division](https://github.com/RobertBoettcherSF/Ada-Non-Restoring-Division) | Fixed-width non-restoring teaching package |
| [Ada-SRT-Division](https://github.com/RobertBoettcherSF/Ada-SRT-Division) | Radix-$2$ SRT, redundant digits $\{-1,0,1\}$ |
| [Ada-Newton-Raphson-Division](https://github.com/RobertBoettcherSF/Ada-Newton-Raphson-Division) | Full NR reciprocal divide |
| [Ada-Goldschmidt-Division](https://github.com/RobertBoettcherSF/Ada-Goldschmidt-Division) | Full Goldschmidt Float package |
| [Ada-Newton-Multiplicative-Inverse](https://github.com/RobertBoettcherSF/Ada-Newton-Multiplicative-Inverse) | Reciprocal Newton (related) |

## Upcoming (series)

Related constant / series work planned for the series (not in this package):

- **Gauss–Legendre** (AGM $\pi$)
- **Chudnovsky** ($\pi$ series)
- **Borwein** (Borwein $\pi$ algorithms)
- **BBP** (Bailey–Borwein–Plouffe digit-extraction)

## Public API (summary)

**Types:** `Method_Kind`, `Division_Result`, `Digit_Vector`,
`Digit_Division_Result`, `Float_Division_Result`, `Float_Status`,
`Quotient_Bit_Array`, `Signed_Digit_Array`, `Invalid_Argument`.

**Taxonomy:** `Method_Name`, `Is_Slow`, `Is_Fast`, `Is_Implemented`.

**Schoolbook:** `Divide_Long`, `Divide_Schoolbook`, `From_Natural`,
`To_Natural`, `To_String`, `Zero`, `One`, `Compare`, `Is_Zero`, `Length`.

**Bit recurrence:** `Divide_Restoring`, `Divide_Restoring_Unsigned`,
`Divide_Non_Restoring`, `Divide_Non_Restoring_Unsigned`.

**Fast Float:** `Divide_NR`, `Divide_NR_Detail`, `Divide_Goldschmidt`,
`Divide_Goldschmidt_Detail`, `Near`, `Rel_Error`.

**Oracle / dispatch:** `Divide_Oracle`, `Exact_Quotient`,
`Divide(N,D,Method)`.

## Usage sketch

```ada
with Division_Algorithms; use Division_Algorithms;

procedure Demo is
   I : Division_Result;
   F : Float_Division_Result;
begin
   I := Divide_Schoolbook (1234, 56);
   --  I.Quotient = 22, I.Remainder = 2

   I := Divide_Restoring (100, 7);
   I := Divide_Non_Restoring (-100, 7);

   F := Divide_NR_Detail (15.0, 3.0);
   --  F.Quotient ≈ 5, F.Status = Converged

   pragma Assert (Near (Divide_Goldschmidt (15.0, 3.0), 5.0));
   pragma Assert (Is_Slow (Restoring) and then Is_Fast (Goldschmidt));
end Demo;
```

## Building

```bash
cd /workspace/ada-division-algorithms
make clean && make
```

Uses `gnatmake -gnatwa -gnat2022 -Pdivision_algorithms.gpr`. Expect
**zero** errors and **zero** warnings.

## Testing

```bash
make test
```

Runs `bin/tests`. Exit status $0$ and `Fail_Count = 0` (`pragma Assert`).
Expect a `Passed:` / `Failed:` summary and `ALL PASSED`.

## Layout

```
ada-division-algorithms/
├── division_algorithms.ads   # public API
├── division_algorithms.adb   # implementation
├── division_algorithms.gpr
├── tests.adb                 # main test program
├── Makefile
├── README.md
└── .gitignore
```

Exactly **seven** root files (no `main.adb`). Build artifacts go under `obj/`
and `bin/` (gitignored).

## References

1. [Wikipedia: Division algorithm](https://en.wikipedia.org/wiki/Division_algorithm)
2. [Wikipedia: Long division](https://en.wikipedia.org/wiki/Long_division)
3. [Wikipedia: Restoring division](https://en.wikipedia.org/wiki/Restoring_division)
4. [Wikipedia: Non-restoring division](https://en.wikipedia.org/wiki/Non-restoring_division)
5. [Wikipedia: SRT division](https://en.wikipedia.org/wiki/SRT_division)
6. [Wikipedia: Division algorithm — Newton–Raphson](https://en.wikipedia.org/wiki/Division_algorithm#Newton%E2%80%93Raphson_division)
7. [Wikipedia: Goldschmidt division](https://en.wikipedia.org/wiki/Goldschmidt_division)

## License

Educational / reference use.
