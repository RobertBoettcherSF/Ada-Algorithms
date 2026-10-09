# Ada-SPARK-Target-Sum

Bounded Target Sum exercise with SPARK_Mode On and inputs limited to four elements.

```sh
make test
make prove
```

## Notes (V&V sweep, 2026-10-09)

`make test` now builds with `-gnatwa -gnata` (zero warnings on GNAT 14.2.0
and 12.2.0). The saturating `Add` (cap 100) never fires: four values have at
most 2 ** 4 = 16 sign choices. Own checks: `own_checks.adb` (exhaustive
brute force), sources in `tests/SOURCES.txt`.
