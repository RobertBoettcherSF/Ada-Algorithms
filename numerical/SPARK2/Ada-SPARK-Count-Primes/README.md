# Ada-SPARK-Count-Primes

Number of primes below N for N in 0 .. 1000, by the sieve of Eratosthenes (each prime I crosses out I * I, I * I + I, ... below N).

Proof (SPARK Silver, `make prove`, cvc5 level 2): no run-time error, Post `Result <= N`. The functional Post (Result = number of primes below N) is not proved yet: H167 in `tools/vv/handover.csv`, `tools/vv/contract_scan.csv`.

Tests: `tests.adb` (original: N = 0, 10, 30) and `own_checks.adb` (every N in 0 .. 1000 against own trial division, and pi (999) = 168).
