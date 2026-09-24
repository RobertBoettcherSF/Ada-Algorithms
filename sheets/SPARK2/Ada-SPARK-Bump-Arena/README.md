# Ada-SPARK-Bump-Arena

Educational Ada/SPARK **Level-2** sheet: a **bounded bump / mark-release arena** that
allocates by **indices** (`Node_Id`), plus a tiny **binary-search tree** client that
never touches the heap.

## Why an index arena?

High-integrity Ada often avoids unconstrained heap use. AdaCore’s High-Integrity
guide §3.2 (*Allocators*) explains how `new` and `Ada.Unchecked_Deallocation` map to
`__gnat_malloc` / `__gnat_free`, and how restrictions such as `No_Allocators` and
`No_Unchecked_Deallocation` shut that path down:

https://docs.adacore.com/gnathie_ug-docs/html/gnathie_ug/gnathie_ug/using_gnat_pro_features_relevant_to_high_integrity.html#allocators-and-the-high-integrity-profiles

This sheet takes the other road used in many SPARK examples:

| Heap (`new` / `Unchecked_Deallocation`) | Index bump arena |
| --- | --- |
| Access types, ownership, possible leaks | Plain `Natural` indices (`0` = null) |
| Needs a storage pool / RTS malloc | Fixed array of node slots |
| Harder to bound for proof | Capacity is a static constant |
| Deallocate any object | **Reset** all, or **Release** to a LIFO **Mark** |

Related community discussion on resource allocation / deallocation:

https://forum.ada-lang.io/t/understanding-resource-allocation-de-allocation/4386

## Packages

- **`Bump_Arena`** — fixed capacity (16 slots), `Allocate_Node`, `Reset`,
  `Get_Mark` / `Release` (LIFO). No access types, no `Unchecked_Deallocation`,
  no `Root_Storage_Pool`.
- **`Index_Tree`** — node record with `Left` / `Right : Node_Id`; `Insert` /
  `Contains`; every new node comes from the embedded arena.

## Build (no Alire)

Host **GNAT** + **gnatprove**. This repo does **not** use Alire.

```bash
make test    # -gnatwa -gnat2022 -gnata, zero warnings
make prove   # level 2, cvc5, --warnings=error --checks-as-errors=on
```

`make prove` sources `/home/box/deps/spark/env.sh` (or put `gnatprove` on `PATH`).

## LLM disclosure

AI assistance (LLM) was used while drafting and refining this educational sheet.
The Ada/SPARK sources, contracts, tests, and proof results were checked with
GNAT and gnatprove on the host toolchain.

## License

MIT — see [LICENSE](LICENSE).
