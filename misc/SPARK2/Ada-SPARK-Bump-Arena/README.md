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

### Proof note: the tree walks end (agent A3, 2026-10-09)

Nodes are allocated in id order and a new node is only linked below an
older one, so every `Left` / `Right` link points to a later live slot.
`Tree` carries this as a `Type_Invariant` (`Links_Forward`). With it,
`Contains` and `Insert` walk with `while` / `loop` plus
`Loop_Variant (Increases => Cur)`, and SPARK proves that `Insert` always
links the new node. Before, both walks were `for Step in 1 .. Capacity`
loops and `Insert` ended with an unproved fallback `Ok := True` after the
loop (it could have reported success without linking the node). That
path was unreachable, so no test can observe the change; the proof is
the evidence. gnatprove 16.1.0 level 4 and silver: all checks proved
(108 checks).

## Build (no Alire)

Host **GNAT** + **gnatprove**. This repo does **not** use Alire.

```bash
make test    # -gnatwa -gnat2022 -gnata, zero warnings
make prove   # level 2, cvc5, --warnings=error --checks-as-errors=on
```

`make prove` needs `gnatprove` on `PATH` (e.g. via Alire: `alr get gnatprove`).

## LLM disclosure

AI assistance (LLM) was used while drafting and refining this educational sheet.
The Ada/SPARK sources, contracts, tests, and proof results were checked with
GNAT and gnatprove on the host toolchain.

## License

MIT — see [LICENSE](LICENSE).
