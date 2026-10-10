# GNAT 14.2.0 leak: recursive Big_Integer expression function with a separate declaration (H187 / H189 / H190)

Build each driver with assertions on, `gnatmake -gnat2022 -gnata -gnatwa <driver>.adb`, then run it. Each driver checks `Part (5, 4) = 14` 100,000 times in a `pragma Assert` and prints VmRSS.

| Form | File | GNAT 14.2.0 | GNAT 12.2.0 |
|---|---|---|---|
| separate declaration + expression-function completion | `p_sep.ads`, `./leak sep` | 20,008 kB (grows linearly, about 20 MB per 100k asserts) | 1,732 kB |
| one expression function | `p_one.ads`, `./leak one` | 4,364 kB | 1,748 kB |
| one expression function with Ghost, Pre, Subprogram_Variant (the H189 workaround form) | `p_two.ads`, `./leak_two` | 4,360 kB | does not build: GNAT BUG DETECTED, Storage_Error at the Subprogram_Variant aspect (`p_two.ads:11:88`) when a client unit calls it |

Measured 2026-10-11 by agent-NB, with 0 warnings wherever it builds.

Different-Ways-To-Add-Parentheses-Lite used the leaking form for the ghost `Partial`. Its `make test` peaked at about 3 GB on GNAT 14.2.0 (`tools/vv/h187_resources.csv`). H189 changed `Partial` to the one-expression-function form, and `make test` now runs `bin/tests` under `ulimit -v 262144`. Partial is called only inside its own package, so the GNAT 12.2.0 crash in the last row is not hit there. Both compiler issues are recorded as handover row H190 (toolchain_bug: worked around in code, open upstream).
