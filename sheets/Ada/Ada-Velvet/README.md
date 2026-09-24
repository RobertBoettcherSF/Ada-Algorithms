# Velvet (algorithm) — Ada 2023

Educational, self-contained Ada 2023 package for
[Wikipedia: Velvet (algorithm)](https://en.wikipedia.org/wiki/Velvet_(algorithm)):
**Velvet**, the short-read *de novo* genome assembler by **Daniel Zerbino** and
**Ewan Birney** (European Bioinformatics Institute; *Genome Research* 18,
2008). Velvet assembles next-generation sequencing (**NGS**) reads by
manipulating **de Bruijn graphs**: hashing $k$-mers, simplifying unbranched
paths, removing errors (tips, bubbles, low-coverage links), and emitting
**contigs**.

This repository is a **pedagogical subset** of Velvet ideas — hashing + de
Bruijn construction with multiplicities + tip clipping + coverage cutoff +
contig walk — **not** a full Zerbino/Birney reimplementation (no Tour Bus
bubble merger, no paired-end repeat resolver, no `velveth`/`velvetg` CLI).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Alphabet** | $\{\mathrm{A},\mathrm{C},\mathrm{G},\mathrm{T}\}$ | Non-ACGT $k$-mer windows skipped |
| **Nodes** | $(k-1)$-mers | Unique sequence keys |
| **Edges** | $k$-mers prefix$\to$suffix | Multiplicity = observation count |
| **RC** | Optional reverse complement | Dual-strand hashing (Velvet spirit) |
| **Tips** | Dead-end short paths | `Remove_Tips` (clipping lite) |
| **Coverage** | Edge multiplicity cutoff | `Remove_Low_Coverage` |
| **Contigs** | Unbranched path collapse | `Emit_Contigs` |

## De Bruijn assembly (math)

Given word length $k\ge 2$, each observed $k$-mer $w=w_1w_2\ldots w_k$ over
alphabet $\Sigma=\{\mathrm{A},\mathrm{C},\mathrm{G},\mathrm{T}\}$ induces a
directed edge

$$
u = w_1\ldots w_{k-1}
\quad\longrightarrow\quad
v = w_2\ldots w_k
$$

in the **de Bruijn graph** of the read set. Node set $V$ is the set of distinct
$(k-1)$-mers; edge multiplicities count how often each $k$-mer was hashed
(including optional reverse complements).

**Simplification.** Whenever a node has a unique out-arc into a node with a
unique in-arc, the path can be merged. Contig emission walks maximal
unbranched chains and spells the sequence by writing the first $(k-1)$-mer and
appending the last character of each successive node:

$$
\mathrm{contig}(v_0,v_1,\ldots,v_m)
=
\mathrm{seq}(v_0)\,
\mathrm{last}(v_1)\cdots\mathrm{last}(v_m).
$$

**Tips.** A tip is a short dead-end (in-degree $0$ or out-degree $0$) whose
path length is below a threshold (Velvet literature often uses order $2k$).
Removing tips is a simple error-correction step before contig walking.

**Low coverage.** Edges with multiplicity strictly below a user threshold are
deleted (erroneous-connection / coverage-cutoff spirit). Full Velvet also
runs **Tour Bus** (Dijkstra-like bubble detection); that is out of scope here.

**Reverse complement.** For DNA string $s$,

$$
\mathrm{RC}(s)_i = \mathrm{comp}(s_{|s|+1-i}),
\qquad
\mathrm{comp}(\mathrm{A})=\mathrm{T},\;
\mathrm{comp}(\mathrm{C})=\mathrm{G},\;
\mathrm{comp}(\mathrm{G})=\mathrm{C},\;
\mathrm{comp}(\mathrm{T})=\mathrm{A}.
$$

$\mathrm{RC}$ is an involution: $\mathrm{RC}(\mathrm{RC}(s))=s$ on ACGT strings.

## Features

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Caps | `Max_K`, `Max_Reads`, `Max_Nodes`, `Max_Edges`, … | Fixed educational limits |
| Types | `Kmer_Length`, `Graph`, `Contig_List`, `Real` | Domain model |
| Build | `Build_Graph`, `Add_Read`, `Get_K` | Hash reads into the graph |
| Errors | `Remove_Tips`, `Remove_Low_Coverage` | Tip clipping / coverage cutoff |
| Contigs | `Emit_Contigs`, `Contig_String` | Unbranched path spelling |
| Query | `Node_Count`, `Edge_Count`, `Contains_Node`, `Edge_Multiplicity` | Inspect graph |
| DNA | `Reverse_Complement`, `Is_ACGT`, `Normalize_Base` | Strand helpers |
| Misc | `Near`, `Contains_Substring` | Numerics / test helpers |

Strong typing uses domain types (`Kmer_Length`, `Node_Index`, …).
Public subprograms carry `Pre` / `Post` / `Global` where meaningful
(`SPARK_Mode => Off`).

Named exceptions: `Invalid_Argument`, `Capacity_Exceeded`.

## Educational scope

In scope:

- ACGT $k$-mer extraction and de Bruijn edge construction with multiplicities
- Optional reverse-complement hashing
- Tip clipping and low-coverage edge removal
- Contig emission by collapsing unbranched paths

Out of scope (full Velvet / related tools):

- Tour Bus bubble removal and biological-variant resolution
- Paired-end / long-insert repeat resolution
- `velveth` / `velvetg` file formats and N50 reporting
- Production-scale memory layouts (this package bounds `Max_Nodes` modestly)

## Usage

```ada
with Velvet; use Velvet;

declare
   G : Graph := Build_Graph (K => 5);
   C : Contig_List;
begin
   Add_Read (G, "ACGTACGTAC");
   Add_Read (G, "CGTACGTACG");
   Remove_Tips (G);
   Remove_Low_Coverage (G, Min_Coverage => 1);
   C := Emit_Contigs (G);
   -- Contig_String (C.Contigs (1)) recovers a path through the reference
end;
```

## Build / test

```bash
make clean && make
make test
```

Uses `gnatmake -gnatwa -gnat2022 -Pvelvet.gpr`. Main program is `tests.adb`
(no `main.adb`).

## Layout

| File | Role |
| --- | --- |
| `velvet.ads` | Package spec |
| `velvet.adb` | Package body |
| `velvet.gpr` | GNAT project (main = `tests.adb`) |
| `Makefile` | `all` / `test` / `clean` |
| `tests.adb` | Custom Check suite (`Fail_Count`, no Ada.Assertions in checks) |
| `README.md` | This document |
| `.gitignore` | `obj/`, `bin/` |

## References

- Zerbino, D. R.; Birney, E. *Velvet: Algorithms for de novo short read
  assembly using de Bruijn graphs*. Genome Research 18, 5 (2008), 821–829.
  doi:10.1101/gr.074492.107
- Pevzner, P. A.; Tang, H.; Waterman, M. S. *An Eulerian path approach to DNA
  fragment assembly*. PNAS 98, 17 (2001), 9748–9753.
- Wikipedia: [Velvet (algorithm)](https://en.wikipedia.org/wiki/Velvet_(algorithm)).
- Wikipedia: [De Bruijn graph](https://en.wikipedia.org/wiki/De_Bruijn_graph).

## License

Educational reference implementation for the RobertBoettcherSF Ada algorithm
series. Use and adapt freely for learning and research.
