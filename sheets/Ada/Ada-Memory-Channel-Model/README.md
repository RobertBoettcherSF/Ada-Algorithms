# Ada-Memory-Channel-Model

Educational Ada/SPARK **Level-2** sheet: a **Micron-flavoured DRAM channel
model** using small abstract integers.

Micron (and other DRAM vendors) motivate thinking in channels, banks, and open
rows. This sheet is an **abstract educational model** — it does **not** use
real DDR timings or values from datasheets, and contains **no proprietary
Micron headers or vendor IP**.

## Behaviour

- Discriminant-scale constants: `Channel_Count`, `Bank_Count`, `Max_Row`
- `Open_Row` / `Close` per (channel, bank)
- `Read` / `Write` with simple conflict (row miss) counters
- Accumulators: `Bytes_Transferred`, `Row_Hits`, `Row_Misses`
- Bounded state only; SPARK_Mode On

## Build (no Alire)

Host **GNAT** + **gnatprove**. This repo does **not** use Alire.

```bash
make test
make prove   # level 2, cvc5, warnings/checks as errors
```

`make prove` sources `/home/box/deps/spark/env.sh` (or put `gnatprove` on `PATH`).

## LLM disclosure

AI assistance (LLM) was used while drafting and refining this educational sheet.
The Ada/SPARK sources, contracts, tests, and proof results were checked with
GNAT and gnatprove on the host toolchain.

## License

MIT — see [LICENSE](LICENSE).
