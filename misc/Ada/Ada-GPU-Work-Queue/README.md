# Ada-GPU-Work-Queue

Educational Ada/SPARK **Level-2** sheet: a **vendor-neutral GPU-style host
command queue** — a bounded ring buffer of stub jobs (`Compute` / `Copy`).

NVIDIA and AMD (and other vendors) each expose host-side command submission
ideas. This sheet treats those as **profiles of the same host queue idea**:
submit work, observe occupancy, complete/retire entries so slots free up.
It is **not a driver**, not an ABI, and contains **no proprietary headers or
vendor SDK code** — clean-room educational simulation only.

## API

| Operation | Role |
| --- | --- |
| `Submit` | Enqueue a job; reject when full |
| `Try_Pop` | Dequeue oldest job (kind out) |
| `Complete` | Retire oldest job (frees one slot) |
| `Occupancy` / `Is_Empty` / `Is_Full` | Observation |
| `Reset` / `Create` | Clear bounded state |

No access types, no heap. Capacity is a static constant (`8`).

## Build (no Alire)

Host **GNAT** + **gnatprove**. This repo does **not** use Alire.

```bash
make test    # -gnatwa -gnat2022 -gnata
make prove   # level 2, cvc5, --warnings=error --checks-as-errors=on
```

`make prove` sources `/home/box/deps/spark/env.sh` (or put `gnatprove` on `PATH`).

## LLM disclosure

AI assistance (LLM) was used while drafting and refining this educational sheet.
The Ada/SPARK sources, contracts, tests, and proof results were checked with
GNAT and gnatprove on the host toolchain.

## License

MIT — see [LICENSE](LICENSE).
