# Ada-SPARK-Min-Cost-Climbing-Stairs

Min Cost Climbing Stairs in SPARK, 6 steps with costs 0 .. 100: start on step 1 or 2, pay every step you
stand on, move up 1 or 2 steps; the top is past the last step (the standard statement). `Compute` is a
backward two-variable dynamic programme. (An earlier version ended the climb on the last step, paying it.)

- Postcondition (functional): `Compute` equals the minimum of the ghost specification `From_Step` (the
  recursive definition) from steps 1 and 2; `From_Step`'s own postcondition bounds it, so the sum provably
  fits `Result` without capping. Proved at Silver level 2 with cvc5 (21 checks).

`make test` runs the tests (exhaustive costs over {0, 1, 2} + 5,000 random, own path enumeration, see
tests/SOURCES.txt); `make prove` runs the proof.
