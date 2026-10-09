# Ada-SPARK-Shortest-Word-Distance

Bounded minimum distance between two token markers in a text buffer of at most 32 characters.

## Notes (V&V sweep, 2026-10-09)

`First` and `Second` are two different words (characters); with
`First = Second` the procedure never records a `Second` position and
returns 32. A real distance is at most 31, so 32 means "not found". Own
checks: `own_checks.adb`, sources in `tests/SOURCES.txt`.
