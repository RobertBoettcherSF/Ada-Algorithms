# Ada-SPARK-Sigmoid

The logistic function 1 / (1 + e ** (-x)) as a whole percentage, for
x = X_Milli / 1000 and every `Integer` X_Milli:

```ada
function Percent (X_Milli : Integer) return Probability;  --  0 .. 100
function Evaluate (X : Input) return Probability;          --  Percent (1000 X)
```

`Percent` rounds half up (a tie cannot occur: e ** x is irrational for
x /= 0, and x = 0 gives exactly 50).

## How
For x >= 0 the value comes from S, the degree-40 Taylor polynomial of
e ** x, held exactly as a fraction of `Big_Integer`s (Horner's rule):
round (100 S / (1 + S)) = (201 Num + Den) / (2 (Num + Den)) in integer
division. For x < 0 it is 100 - Percent (-x). S is below e ** x by less
than 1e-20 for 0 <= x <= ln 199 (where the rounding range ends), and no
value on the 1/1000 grid comes closer than 1.67e-5 to a rounding
boundary, so the truncation never changes a result; past ln 199, S >= 199
gives 100, as the exact value does. `Evaluate` keeps the old whole-number
interface; its range `Input` is the limit where 1000 X fits `Integer`.

## Proof (`make prove`, gnatprove level 2, cvc5)
No run-time errors (the Big_Integer fractions cannot overflow), result in
0 .. 100, at least 50 for x >= 0 and at most 50 for x < 0, exactly 50 at
x = 0, and the ghost lemma `Lemma_Symmetry`: Percent (-x) = 100 -
Percent (x). The numeric value itself cannot be stated in SPARK (there is
no e), so it is tested, not proved.

## Tests
* `make test` (tests.adb): worked values from a 60-digit decimal
  reference, both sides of the closest rounding boundaries, the ends of
  `Integer`; every X_Milli in -8000 .. 8000 against Long_Float `exp`,
  symmetry and monotonicity.
* Own checks (`gnatmake -gnata -gnatwa -gnat2022 own_checks.adb &&
  ./own_checks`): every X_Milli in -30000 .. 30000 against Long_Float
  `tanh`, all 100 rounding thresholds, 200,000 seeded random inputs.
  Sources: tests/SOURCES.txt.
