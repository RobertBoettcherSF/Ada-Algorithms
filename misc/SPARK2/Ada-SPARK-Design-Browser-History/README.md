# Ada-SPARK-Design-Browser-History

A small bounded Ada/SPARK implementation with a runnable test and level-2 proof target.

## Behaviour

A bounded browser history of at most `Capacity` = 4 pages (`Page` is
1 .. 100). Pages `1 .. Length` are stored, page `Current_Index` is shown.

* `Visit (H, P)` drops every page after the shown one, appends `P` and
  shows it. Pre: `Current_Index (H) < Capacity`.
* `Back` / `Forward` move the shown position by one page. Pre: there is a
  page behind / ahead.
* `Current_Page` and `Page_At (H, I)` read the history.

Every subprogram has a `Post` that states the new `Length`,
`Current_Index` and pages, and a `Type_Invariant` keeps the shown page
inside the stored ones.

Change (agent A3, 2026-10-09): `Visit` used to require
`Current_Index = Length`, so a visit after `Back` was rejected; it now
drops the forward pages as a browser does. The dead guards in the bodies
(`if H.Size < Capacity`, `if H.Current > 0`, ...) are gone, `Page_At` is
new, and the contracts are full `Post`s instead of none.

## Tests

`make test` runs `tests.adb` (hand-worked cases) and `own_checks.adb`
(a two-stack model over 2,000 random runs; see `tests/SOURCES.txt`).
`make prove` runs gnatprove at level 2.
