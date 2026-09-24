# Ada/SPARK LZ77

A tiny bounded LZ77 teaching baseline: the literal-only encoder returns the encoded
length. It keeps the window contract explicit (`Window_Size = 4`) while leaving the
back-reference tuple as the next exercise.

Run `make test` and `make prove` (Level 2, cvc5, warnings as errors).
