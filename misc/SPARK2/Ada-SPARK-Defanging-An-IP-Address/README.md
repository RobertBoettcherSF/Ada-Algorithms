Replaces dots in a bounded IPv4 text with the safe [.] spelling.

## V&V sweep notes (agent A3)

The output used to be a 32-character `Text` like the input: once it filled
up, `Defang` silently dropped the rest of the input, and a '.' that arrived
with 30 or 31 characters written was copied without its brackets. The
output is now `Out_Text` (3 * 32 characters, enough for 32 dots), nothing
is dropped, and the Post states `Output_Length in Length .. 3 * Length`
(failing test first, then the fix; `make prove`: 13 checks proved).
Tests: hand-worked cases in `tests.adb`, a reference built with
`Ada.Strings.Unbounded` in `own_checks.adb` (see `tests/SOURCES.txt`).
