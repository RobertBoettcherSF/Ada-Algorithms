# Ada-SPARK-Count-Primes

Number of primes below N for N in 0 .. 10**7 (the sieve is a packed Boolean array, about 1.25 MB on the stack), by the sieve of Eratosthenes (each prime I crosses out I * I, I * I + I, ... below N).

Proof (SPARK Silver, `make prove`, cvc5 level 2): no run-time error, Post `Result <= N`. The functional Post (Result = number of primes below N) is not proved yet: H167 in `tools/vv/handover.csv`, `tools/vv/contract_scan.csv`.

Tests: `tests.adb` (original: N = 0, 10, 30) and `own_checks.adb` (every N in 0 .. 1000 against own trial division, pi (999) = 168, and the published pi (10**6) = 78,498 and pi (10**7) = 664,579).
