# Ada-SPARK-Bounded-String-Builder

Educational Ada 2022 / SPARK sheet: a **generic** fixed-capacity string
builder that makes everyday concatenation easier **without**
`Ada.Strings.Unbounded`, access types, or heap allocation.

## Why not `Ada.Strings.Unbounded`?

| | `Unbounded_String` | This sheet |
|--|--------------------|------------|
| Storage | Heap, controlled finalization | Stack / object, fixed `Capacity` |
| Growth | Automatic | Explicit `Status` when full |
| SPARK | Harder (heap, finalization) | `SPARK_Mode => On`, Level 2 |
| Secondary stack | `To_String` returns `String` | `To_String` writes `out String` + `Last` |

When the maximum size is known (messages, paths, log lines), a bounded
builder is simpler to reason about and friendlier to SPARK.

## Generics (parametric polymorphism)

This sheet follows [Wikibooks: Ada Programming/Generics](https://en.wikibooks.org/wiki/Ada_Programming/Generics)
and **RM 12**: write the algorithm once with a `generic` formal part, then
**instantiate** per capacity.

```ada
generic
   Capacity : Positive;  -- formal object (mode in); never static
package Bounded_String_Builder with SPARK_Mode => On is
   subtype Length_Type is Natural range 0 .. Capacity;  -- OK
   -- type Mod_Index is mod Capacity;  -- ILLEGAL: formal objects are not static
   ...
end Bounded_String_Builder;

package S is new Bounded_String_Builder (Capacity => 128);
```

Contrast C++ templates in one line: Ada generics are **contractual units**
you instantiate explicitly; C++ templates are compile-time duck-typed
expansion. Same idea (reuse per size), different checking story.

Formal objects are **never static** — use subtype / array index ranges of
`Capacity`; do not use `mod Capacity` or other constructs that demand a
static expression.

## API (Pareto)

- `Clear`, `Append` (`String` / `Character`) with `Status : out Boolean`
- `Append_Integer` (no `Integer'Image`)
- `Length`, `Element`, `Max_Capacity`
- `To_String` / `Slice` → `out String` + `Last`
- `Equals`

No access, no heap, no `Unbounded_String`.

## Build & test

Requires host GNAT (Ada 2022). **No Alire.** SPARK / gnatprove for proofs.

```bash
make test    # -gnatwa -gnat2022 -gnata
make prove   # Level 2, cvc5; warnings and checks as errors
```

Tests instantiate **two** capacities (`16` and `64`) to exercise the generic.

## License

MIT — see [LICENSE](LICENSE).

## LLM usage disclosure

AI assistance was used for this project.
