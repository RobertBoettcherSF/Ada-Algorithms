# Topics — Ada / SPARK sheet layout

Each topic/proof-level directory contains one folder per source algorithm
repository: `<topic>/<LEVEL>/<RepoName>/...`. Former clash-renamed files such
as `<RepoName>__<basename>` are now stored as `<RepoName>/<basename>`;
leading-dot filenames are preserved. Unprefixed files remain at the
topic/level root. Identical sha256 duplicates are skipped. Upstream package
sources are not rewritten.

Integrated harness remains under `src/` and `tests/`.

## Counts by topic × level

| Topic | Ada | SPARK1 | SPARK2 | SPARK3 | SPARK4 | Total files |
|-------|----:|-------:|-------:|-------:|-------:|------------:|
| clustering | 93 | 0 | 8 | 0 | 0 | 101 |
| compression | 143 | 0 | 45 | 8 | 0 | 196 |
| concurrency | 79 | 0 | 60 | 0 | 0 | 139 |
| cryptography | 178 | 0 | 27 | 0 | 0 | 205 |
| geometry | 314 | 0 | 20 | 0 | 0 | 334 |
| graphs | 189 | 0 | 104 | 0 | 20 | 313 |
| hashing | 71 | 0 | 55 | 0 | 0 | 126 |
| logic | 49 | 0 | 0 | 0 | 0 | 49 |
| matrices | 75 | 0 | 151 | 0 | 0 | 226 |
| misc | 3458 | 0 | 4284 | 0 | 73 | 7815 |
| ml | 140 | 0 | 20 | 0 | 0 | 160 |
| numerical | 496 | 0 | 151 | 0 | 59 | 706 |
| parsing | 93 | 0 | 21 | 0 | 0 | 114 |
| searching | 217 | 0 | 219 | 0 | 63 | 499 |
| sorting | 242 | 0 | 355 | 0 | 230 | 827 |
| strings | 135 | 0 | 293 | 8 | 0 | 436 |
| trees | 52 | 0 | 405 | 0 | 0 | 457 |
| **All** | 6024 | 0 | 6218 | 16 | 445 | **12703** |

- Clash renames: **6578**
- Identical duplicates skipped: **2470**
- Source sheet repos walked: **1838**

## Clash rename examples

- `Ada/README.md` ← conflicting; kept as `Ada-A-Law-Algorithm__README.md` (from `Ada-A-Law-Algorithm`)
- `Ada/Makefile` ← conflicting; kept as `Ada-A-Law-Algorithm__Makefile` (from `Ada-A-Law-Algorithm`)
- `Ada/tests.adb` ← conflicting; kept as `Ada-A-Law-Algorithm__tests.adb` (from `Ada-A-Law-Algorithm`)
- `Ada/README.md` ← conflicting; kept as `Ada-AC-3__README.md` (from `Ada-AC-3`)
- `Ada/.gitignore` ← conflicting; kept as `Ada-AC-3__.gitignore` (from `Ada-AC-3`)
- `Ada/Makefile` ← conflicting; kept as `Ada-AC-3__Makefile` (from `Ada-AC-3`)
- `Ada/tests.adb` ← conflicting; kept as `Ada-AC-3__tests.adb` (from `Ada-AC-3`)
- `Ada/README.md` ← conflicting; kept as `Ada-ACORN-Generator__README.md` (from `Ada-ACORN-Generator`)
- `Ada/.gitignore` ← conflicting; kept as `Ada-ACORN-Generator__.gitignore` (from `Ada-ACORN-Generator`)
- `Ada/Makefile` ← conflicting; kept as `Ada-ACORN-Generator__Makefile` (from `Ada-ACORN-Generator`)
- `Ada/tests.adb` ← conflicting; kept as `Ada-ACORN-Generator__tests.adb` (from `Ada-ACORN-Generator`)
- `Ada/README.md` ← conflicting; kept as `Ada-Abstract-Syntax-Tree__README.md` (from `Ada-Abstract-Syntax-Tree`)
- `Ada/Makefile` ← conflicting; kept as `Ada-Abstract-Syntax-Tree__Makefile` (from `Ada-Abstract-Syntax-Tree`)
- `Ada/tests.adb` ← conflicting; kept as `Ada-Abstract-Syntax-Tree__tests.adb` (from `Ada-Abstract-Syntax-Tree`)
- `Ada/README.md` ← conflicting; kept as `Ada-AdaBoost__README.md` (from `Ada-AdaBoost`)
- `Ada/Makefile` ← conflicting; kept as `Ada-AdaBoost__Makefile` (from `Ada-AdaBoost`)
- `Ada/tests.adb` ← conflicting; kept as `Ada-AdaBoost__tests.adb` (from `Ada-AdaBoost`)
- `Ada/README.md` ← conflicting; kept as `Ada-Adaptive-Additive-Algorithm__README.md` (from `Ada-Adaptive-Additive-Algorithm`)
- `Ada/Makefile` ← conflicting; kept as `Ada-Adaptive-Additive-Algorithm__Makefile` (from `Ada-Adaptive-Additive-Algorithm`)
- `Ada/tests.adb` ← conflicting; kept as `Ada-Adaptive-Additive-Algorithm__tests.adb` (from `Ada-Adaptive-Additive-Algorithm`)
