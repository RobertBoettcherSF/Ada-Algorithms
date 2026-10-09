# Ada-SPARK-Clock-Page-Replacement

A bounded SPARK Clock second-chance page replacement model.

Run make test for executable tests and make prove for GNATprove level 2 with cvc5.

## V&V sweep notes (agent A3)

- The fault counter used to saturate at 100 (`Fault_Count_Type` was
  0 .. 100 and the increment was skipped at the top), so a long run
  under-reported faults. It now counts every fault; `Access_Page` has the
  precondition `S.Faults < Fault_Count_Type'Last` instead of a silent clamp
  (failing test first, then the fix).
- Tests: a hand-worked clock trace in `tests.adb` and a FIFO second-chance
  model in `own_checks.adb` (see `tests/SOURCES.txt`).
