Minimal reproducer: GNAT bug box with -gnata -gnatVa (Initialize_Scalars not needed).

  gcc -c -gnat2022 -gnata -gnatVa r.adb
    GNAT 14.2.0 (GNATLS 14.2.0): GNAT BUG DETECTED, in gnat_to_gnu_entity, at ada/gcc-interface/decl.cc:464
    GNAT 12.2.0 (GNATLS 12.2.0): GNAT BUG DETECTED, in gnat_to_gnu_entity, at ada/gcc-interface/decl.cc:472
  gcc -c -gnat2022 -gnata r.adb   -> compiles cleanly on both

Trigger: X'Old (here Get (G'Old), G of a private type) inside a branch of an
if-expression in a postcondition, compiled with validity checks (-gnatVa).
Checked 2026-10-09: 'Old only in the if condition compiles; the same
condition written with "or else" compiles.

Effect on V&V: flaky.py's init pass (pragma Initialize_Scalars + -gnatVa) could
not build Ada-SPARK-Mersenne-Twister (Next's Post had this shape). Next's Post is
now written with "or else" (same meaning); the init pass builds and runs the real
code. Not part of the build (make test compiles tests.adb only; these files are
in a subdirectory outside Source_Dirs).
