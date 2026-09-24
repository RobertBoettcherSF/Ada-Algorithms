# Geometric hashing — Ada 2023

Educational, self-contained Ada 2023 package for **geometric hashing**:
efficient recognition of a 2-D model point set inside a scene after a
**similarity** transform (translation, rotation, uniform scale). An
**offline** pass encodes every ordered basis pair; an **online** pass
votes for model hypotheses from quantized scene lookups.

See
[Wikipedia: Geometric hashing](https://en.wikipedia.org/wiki/Geometric_hashing)
(Wolfson & Rigoutsos overview).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT
(`-gnat2022`). Bounds: `Max_Points = 24`, `Max_Entries = 12288`, default
bin size $0.25$. Ordinary `Real` (`digits 15`) arithmetic — **not** a
production vision stack.

Part of the **RobertBoettcherSF** Ada algorithm series.

## Offline / online sketch

**Offline (model).** For each ordered pair of model points $(p_i, p_j)$
treated as a geometric basis, express every remaining point in the
invariant $(u,v)$ frame and store a vote keyed by the **quantized**
grid cell:

$$
\text{hash}\big(\mathrm{round}(u/b),\;\mathrm{round}(v/b)\big)
\;\mapsto\; (\textit{model id},\; i,\; j).
$$

**Online (scene).** Try candidate scene bases; look up each remaining
scene point’s quantized coords; accumulate votes for consistent
$(\textit{model}, \textit{basis})$ hypotheses. A high vote count yields
a hypothesized pose (basis correspondence).

## Similarity basis (classroom convention)

Given ordered points $A,B$:

- origin $=$ midpoint of $AB$;
- $x'$ axis toward $B$; $y'$ $=$ $90^\circ$ CCW;
- scale so $A \mapsto (-1,0)$ and $B \mapsto (+1,0)$.

Degenerate (nearly coincident) pairs are skipped. This matches the
Wikipedia 2-D similarity example (bin size $b = 0.25$ by default).

## Contrast with geometry siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Geometric-Hashing`) | Model↔scene recognition via quantized basis hashing + voting |
| **[Ada-Point-Set-Registration](https://github.com/RobertBoettcherSF/Ada-Point-Set-Registration)** | Align two clouds (Kabsch-style + ICP sketch) |
| **[Ada-RANSAC](https://github.com/RobertBoettcherSF/Ada-RANSAC)** | Robust model fitting with outliers |
| **Ada-EDT** (ahead) | Euclidean distance transform on grids |
| **Ada-Quickhull** (ahead) | Fast 2-D convex hull |

README links only — **no** package `with` of siblings.

## API sketch

| Operation | Role |
| --- | --- |
| `Make_Basis` / `To_Basis_Coords` | Similarity frame; express a point in $(u,v)$ |
| `Quantize` / `Quantize_Point` | Integer grid key from $(u,v)$ or from a point+basis |
| `Build_Table` | Offline: fill the flat open-list hash map from a model |
| `Recognize` | Online: best model id / vote count / basis pair |
| `Lookup_Count` / `Entry_Length` / `Empty_Table` | Table introspection |
| `Near` / `Near_Point` / `Dist` / `Dist2` | Educational floating comparisons |

Domain types: `Point`, `Point_Array`, `Basis`, `Basis_Pair`, `Hash_Key`,
`Table_Entry`, `Hash_Table`, `Recognition_Result`, `Real`.
Exception: `Invalid_Argument` on empty / too-small sets (`< 3` points),
capacity overflow, or non-positive bin size.

The hash table is an educational **flat open list** (linear key scan),
not a production chained hashtable.

## Build & test

```bash
make
make test
```

Requires GNAT with Ada 2022 support (`gnatmake -gnatwa -gnat2022`).

## License

Educational example code for the RobertBoettcherSF Ada algorithm series.
