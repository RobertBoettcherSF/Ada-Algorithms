# Ada-SPARK-Bankers-Algorithm

A bounded SPARK implementation of Bankers resource-allocation safety checks and guarded requests.

Run make test for executable tests and make prove for GNATprove level 2 with cvc5.

## Safety check (V&V sweep, agent A3)

`Is_Safe` is the Banker's safety algorithm: it repeatedly lets any
unfinished process whose whole remaining need fits in the free resources
finish and return its allocation (`Work_Of` = Available plus the
allocations of the finished processes, at most 20 + 4 * 20 = 100, the
range of `Work_Amount`), and answers True when every process can finish.
It used to require every process's need to fit in `Available` at the same
time, which judged states unsafe that are safe through a finishing order
(failing test first, then the fix; `make prove`: 15 checks proved).

Note: `Need` returns 0 when an allocation exceeds its maximum (as its Post
states), so such inconsistent states are not rejected; `Request` requires
Allocation <= Maximum only for the requested entry.

Tests: hand-worked cases in `tests.adb` and a reference that tries all 24
finishing orders in `own_checks.adb` (see `tests/SOURCES.txt`).
