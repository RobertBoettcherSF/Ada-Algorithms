# Ada-SPARK-Maximum-Ice-Cream-Bars

A bounded uniform-price affordability kernel in SPARK: the shop has 32 bars, all
at `Unit_Price`; `Bars_Bought` returns how many can be bought with `Budget`,
that is min (32, Budget / Unit_Price). The cap is the stock of 32 bars (in the
standard problem at most n bars can be bought), not an overflow guard; the
postcondition states the formula.

`make test` runs the tests; `make prove` runs the level-2 proof.
