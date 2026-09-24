# Ada Verified Unification Engine

Educational **first-order syntactic unification** (Most General Unifier) with a strict
**occurs-check**, implemented in Ada 2022 and analyzed under SPARK.

This is a teaching / high-assurance sketch of the shared core behind Prolog-style
resolution and many SMT / logic-programming front ends — not a production theorem prover.

## SPARK status (Level 2)

Measured with:

```text
gnatprove -Punification_engine.gpr -u unification_engine.adb \
  --level=2 --prover=cvc5 --warnings=error --checks-as-errors=on
```

| Metric | Result |
|--------|--------|
| GNATprove level | 2 (CVC5) |
| Checks proved | **176 / 176** |
| Unproved | 0 |

The engine package is fully SPARK (`SPARK_Mode => On`). The test harness is outside
the proof set (`-u unification_engine.adb`).

> Until this bar is green, prefer “SPARK-oriented” over unqualified “verified”.
> With 176/176 at Level 2, the unification engine itself meets that Level 2 bar.

## Design

Heap `access` terms blocked SPARK analysis. The redesign uses a **bounded term store**:

* `Max_Terms = 32` bump-allocated pool (`Abstract_State => Term_Pool`)
* `Term_Id` is `0 .. Max_Terms` with `Null_Term = 0` (no access types, no `new`, no unchecked deallocation)
* Binary function nodes store `Left` / `Right` as `Term_Id`
* Variables remain `'a' .. 'z'`; `Substitution` maps `Var_Name → Term_Id`
* `Make_Variable` / `Make_Constant` / `Make_Function` are procedures (SPARK forbids functions with `In_Out` globals)
* `Occurs_Check`, `Unify`, and `Apply_Substitution` are fuel-bounded by `Max_Terms` for termination
* `Reset_Pool` / `Clear` for tests and fresh queries
* Public API carries `Pre` / `Post` / `Global`; accessors are expression functions for proof

## Usage

```bash
source /home/box/deps/spark/env.sh   # if needed for gnatprove
make test    # zero-warning build (-gnatwa -gnat2022 -gnata) + run suite
make prove   # GNATprove Level 2, CVC5, warnings/checks as errors
```

Expected test footer:

```text
===  26 passed, 0 failed ===
```

## Tests (`tests.adb`)

Twenty-six `Check` assertions covering:

* Term constructors and environment clear
* Identical / conflicting constants
* Variable–constant unification and binding conflicts
* Function trees, name/argument mismatch, recursive MGU (`f(x,A)` vs `f(B,y)`)
* Occurs-check rejection of `x = f(x, …)`
* Substitution application and chained bindings (`x→y→M`)
* Null-term edge cases and `Var_Name` range constraint

## Building

* GNAT (Ada 2022) and Make; SPARK/GNATprove for `make prove`
* Layout: `unification_engine.ads` / `.adb` / `.gpr`, `Makefile`, `tests.adb`, `README.md` (no `main.adb`)
* License: MIT

<!-- Future: adacovex badges -->
