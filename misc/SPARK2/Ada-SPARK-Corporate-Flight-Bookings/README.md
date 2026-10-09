# Ada-SPARK-Corporate-Flight-Bookings

Corporate flight bookings: flights 1 .. N (N up to 20,000), up to 20,000 bookings, each reserving Seats (0 .. 10,000) on every flight First .. Last. `Flight_Totals (R, N)` returns the seats reserved on each flight, with a difference array (+Seats at First, -Seats after Last) and one prefix-sum pass, O(N + bookings). The original `Booked_Seats` (sum of all bookings of a fixed 8-entry table) is kept.

Proof (SPARK, `make prove`, cvc5 level 2, 102 checks): no run-time error and the functional Post `Result (F) = Covered (R, F, R'Last)` for every flight, where the ghost `Covered` adds up the bookings whose range contains F. The proof uses ghost prefix sums and a lemma that adding S at position P adds S to every prefix from P on. The body's lemmas and invariants are not executed (run-time cost; `tools/vv/proof_escapes.csv`, runtime_only); the spec Post is.

Tests: `tests.adb` (original) and `own_checks.adb` (per-flight brute force; exhaustive up to 2 bookings on 3 flights, 500 random cases up to 300 flights / bookings, 3 cases of 5000, seed 20261009).

## Verify

```sh
make test
make prove
```
