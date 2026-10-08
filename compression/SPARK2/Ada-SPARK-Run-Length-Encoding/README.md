# Run-length encoding

A bounded SPARK implementation of the run-counting pass used by run-length encoders.

`Number_Of_Runs` returns 0 for the empty input (`Run_Count` starts at 0) and otherwise a count in $1 .. n$ for an input of length $n$; the postcondition states both and is proved at Silver level 2.
