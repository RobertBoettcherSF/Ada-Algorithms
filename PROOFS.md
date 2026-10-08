# Proof index

Generated 2026-10-08 09:15 CEST.

## Proof setup

```
gnatprove FSF 16.1.0
Why3 for gnatprove version 1.8.2+git
alt-ergo: Alt-Ergo version 2.6.1
cvc5: This is cvc5 version 1.3.2 [git 86cecd8 on branch HEAD]
z3: Z3 version 4.15.4 - 64 bit
(Alire crate gnatprove=16.1.0, alr 2.1.1; GNAT 14.2.0 system, GNAT 12.2.1 Alire gnat_native)
```

* Batch (all SPARK folders): `gnatprove -P <folder gpr> --mode=silver --level=2 -j1 --output=oneline -k` - level 2 = provers cvc5,z3,altergo, `--timeout=5` s per check (wall clock), `--steps=0`, `--memlimit=1000`, per_check, counterexamples off.
* Rerun with a deterministic step budget (rows with `proof_run` = `steps=N`; replaces the batch result): `gnatprove -P <folder gpr> --mode=silver --level=2 --timeout=0 --steps=1000000 --counterexamples=off -j2 --output=oneline -k` - no wall-clock timeout, so the result does not depend on machine load.
* Rows rerun with steps (0): none

One row per algorithm folder (full data in [`PROOFS.csv`](PROOFS.csv)). Regenerate with
`python3 tools/proof_index.py --results <dir> --logs <prove-workdir>` (see `tools/audit/`).
Builds: `gnatmake -gnatwa -gnat2022` on `tests.adb` (GNAT 14 system, GNAT 12 Alire). `make test` = the folder's own Makefile (GNAT 14). Tests pass = `make test` passes, or the uniform build's test binary exits 0 with no FAIL lines.
Silver: `gnatprove --mode=silver --level=2` on the folder's own .gpr (generated where none exists).

Folders: 1802; duplicates (counted once): 3; Ada<->SPARK pairs: 101.

| Level | Folders | make test OK | Build 14 | Build 12 | Tests 14 | Tests 12 | 0 warn 14 | 0 warn 12 | Proven | Unproved | Not built/crash | Not run |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Ada | 894 | 854 | 862 | 865 | 867 | 849 | 675 | 655 | 0 | 0 | 0 | 23 |
| SPARK2 | 841 | 833 | 839 | 839 | 839 | 839 | 471 | 470 | 476 | 2 | 2 | 359 |
| SPARK4 | 64 | 61 | 62 | 62 | 62 | 62 | 62 | 32 | 25 | 1 | 0 | 36 |
| All | 1799 | 1748 | 1763 | 1766 | 1768 | 1750 | 1208 | 1157 | 501 | 3 | 2 | 418 |

| Folder | Make | B14 | B12 | T14 | T12 | W14 | W12 | Silver | Pair | Duplicate of |
|---|---|---|---|---|---|---|---|---|---|---|
| clustering/Ada/Canopy-Clustering | yes | yes | yes | yes | yes | 0 | 3 | no SPARK |  |  |
| clustering/Ada/Clustering | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| clustering/Ada/Clustering-Algorithms | yes | yes | yes | yes | yes | 0 | 1 | no SPARK |  |  |
| clustering/Ada/Complete-Linkage-Clustering | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| clustering/Ada/DBSCAN | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| clustering/Ada/FLAME-Clustering | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| clustering/Ada/Fuzzy-Clustering | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| clustering/Ada/K-Means-Clustering | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| clustering/Ada/K-Means-Plus-Plus | yes | yes | yes | yes | yes | 0 | 1 | no SPARK |  |  |
| clustering/Ada/Lloyds-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| clustering/Ada/OPTICS | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| clustering/Ada/Single-Linkage-Clustering | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| clustering/Ada/WACA-Clustering | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| clustering/Ada/Wards-Method | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| compression/Ada/Arithmetic-Coding | yes | yes | yes | yes | yes | 7 | 7 | no SPARK |  |  |
| compression/Ada/Audio-Compression | yes | yes | yes | yes | yes | 5 | 5 | no SPARK |  |  |
| compression/Ada/Berlekamp-Massey-Algorithm | yes | yes | yes | yes | yes | 16 | 16 | no SPARK |  |  |
| compression/Ada/Berlekamp-Root-Finding | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| compression/Ada/Burrows-Wheeler-Transform | yes | yes | yes | yes | yes | 4 | 4 | no SPARK |  |  |
| compression/Ada/Deflate | yes | yes | yes | yes | yes | 3 | 3 | no SPARK |  |  |
| compression/Ada/Dynamic-Markov-Compression | yes | yes | yes | yes | yes | 4 | 4 | no SPARK |  |  |
| compression/Ada/Earley-Parser | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| compression/Ada/Fast-Efficient-Lossless-Image-Compression-System | yes | yes | yes | yes | yes | 25 | 25 | no SPARK |  |  |
| compression/Ada/Fractal-Compression | yes | yes | yes | yes | yes | 36 | 37 | no SPARK |  |  |
| compression/Ada/Huffmann-Coding | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| compression/Ada/Image-Compression | yes | yes | yes | yes | yes | 7 | 7 | no SPARK |  |  |
| compression/Ada/LZ77-LZ78 | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| compression/Ada/LZWL | yes | yes | yes | yes | yes | 35 | 35 | no SPARK |  |  |
| compression/Ada/LZX | yes | yes | yes | yes | yes | 2 | 2 | no SPARK |  |  |
| compression/Ada/Peterson-Gorenstein-Zierler-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| compression/Ada/Run-Length-Encoding | yes | yes | yes | yes | yes | 5 | 5 | no SPARK | compression/SPARK2/Ada-SPARK-Run-Length-Encoding |  |
| compression/Ada/Speech-Compression | yes | yes | yes | yes | yes | 8 | 8 | no SPARK |  |  |
| compression/Ada/Verlet-Integration | yes | yes | yes | yes | yes | 2 | 2 | no SPARK |  |  |
| compression/Ada/Video-Compression | yes | yes | yes | yes | yes | 27 | 27 | no SPARK |  |  |
| compression/Ada/Wavelet-Compression | yes | yes | yes | yes | yes | 31 | 31 | no SPARK |  |  |
| compression/SPARK2/Ada-SPARK-Compress-String | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| compression/SPARK2/Ada-SPARK-Interleaving-String | yes | yes | yes | yes | yes | 10 | 10 | proven |  |  |
| compression/SPARK2/Ada-SPARK-LZ77 | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| compression/SPARK2/Ada-SPARK-Move-To-Front | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| compression/SPARK2/Ada-SPARK-Run-Length-Encoding | yes | yes | yes | yes | yes | 0 | 0 | proven | compression/Ada/Run-Length-Encoding |  |
| compression/SPARK2/Ada-SPARK-String-Compression | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| concurrency/Ada/Dekker | no | no | no | no | no | NA | NA | no SPARK |  |  |
| concurrency/Ada/Lamport-Ordering | no | yes | yes | yes | yes | 3 | 3 | no SPARK |  |  |
| concurrency/Ada/Paxos-Algorithm | yes | yes | yes | yes | yes | 5 | 5 | no SPARK |  |  |
| concurrency/Ada/Vector-Clocks | no | yes | yes | yes | yes | 8 | 8 | no SPARK |  |  |
| concurrency/Ada/lamport | no | no | no | no | no | NA | NA | no SPARK |  |  |
| concurrency/Ada/lds-scheduler | no | no | no | no | no | NA | NA | no SPARK |  |  |
| concurrency/Ada/mlfq | n/a | no | no | no | no | NA | NA | no SPARK |  |  |
| concurrency/Ada/peterson | n/a | no | no | no | no | NA | NA | no SPARK |  |  |
| concurrency/Ada/sjn | n/a | no | no | no | no | NA | NA | no SPARK |  |  |
| concurrency/SPARK2/Ada-SPARK-Course-Schedule-II | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| concurrency/SPARK2/Ada-SPARK-Course-Schedule-II-Stub | yes | yes | yes | yes | yes | 4 | 4 | proven |  |  |
| concurrency/SPARK2/Ada-SPARK-Dekkers-Algorithm | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| concurrency/SPARK2/Ada-SPARK-Lamports-Bakery-Algorithm | yes | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| concurrency/SPARK2/Ada-SPARK-Petersons-Algorithm | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| concurrency/SPARK2/Ada-SPARK-Task-Scheduler | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| concurrency/SPARK2/Ada-SPARK-Task-Scheduler-Stub | yes | yes | yes | yes | yes | 3 | 3 | proven |  |  |
| cryptography/Ada/Argon2 | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| cryptography/Ada/Asymetric-Public-Key-Encryption | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| cryptography/Ada/BLAKE | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| cryptography/Ada/Bcrypt | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| cryptography/Ada/Blowfish | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| cryptography/Ada/ChaCha20 | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| cryptography/Ada/Data-Encryption-Standard | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| cryptography/Ada/ECDSA | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| cryptography/Ada/Elliptic-Curve-Diffie-Hellman | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| cryptography/Ada/Fortuna | yes | yes | yes | yes | yes | 1 | 0 | no SPARK |  |  |
| cryptography/Ada/HMAC | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| cryptography/Ada/IDEA | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| cryptography/Ada/Lenstra-Elliptic-Curve-Factorization | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| cryptography/Ada/MD5 | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | cryptography/SPARK2/Ada-SPARK-MD5 |  |
| cryptography/Ada/NTRUEncrypt | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| cryptography/Ada/RC4 | no | no | yes | no | yes | 0 | 0 | not run |  |  |
| cryptography/Ada/RSA | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| cryptography/Ada/SHA3 | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| cryptography/Ada/Shamirs-Secret-Sharing | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| cryptography/Ada/Stochastic-Universal-Sampling | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| cryptography/Ada/Symetric-Encryption | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| cryptography/Ada/Threefish | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| cryptography/Ada/Tiny-Encryption-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| cryptography/Ada/Twofish | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| cryptography/Ada/Universal-Coding | yes | yes | yes | yes | yes | 6 | 6 | no SPARK |  |  |
| cryptography/Ada/Universal-Variable-Formulation | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| cryptography/Ada/WHIRLPOOL | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| cryptography/Ada/Yarrow-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| cryptography/SPARK2/Ada-SPARK-Level-Order-Traversal-Stub | yes | yes | yes | yes | yes | 7 | 7 | proven |  |  |
| cryptography/SPARK2/Ada-SPARK-MD5 | yes | yes | yes | yes | yes | 0 | 0 | proven | cryptography/Ada/MD5 |  |
| cryptography/SPARK2/Ada-SPARK-SHA-1 | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| geometry/Ada/Ambient-Occlusion | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| geometry/Ada/Bresenhams-Line-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| geometry/Ada/Canny-Edge-Detector | yes | yes | yes | yes | yes | 51 | 51 | no SPARK |  |  |
| geometry/Ada/Clipping | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| geometry/Ada/Closest-Pair-Problem | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| geometry/Ada/Cohen-Sutherland | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| geometry/Ada/Constructive-Solid-Geometry | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| geometry/Ada/Convex-Hull-Algorithms | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| geometry/Ada/Delaunay-Triangulation | yes | yes | yes | yes | yes | 0 | 3 | no SPARK |  |  |
| geometry/Ada/Dithering | yes | yes | yes | yes | yes | 9 | 9 | no SPARK |  |  |
| geometry/Ada/Fast-Clipping | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| geometry/Ada/Generalised-Hough-Transform | yes | no | no | yes | yes | 31 | 31 | no SPARK |  |  |
| geometry/Ada/Gift-Wrapping | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| geometry/Ada/Gouraud-Shading | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| geometry/Ada/Grabcut | yes | yes | yes | yes | yes | 1 | 1 | no SPARK |  |  |
| geometry/Ada/Graham-Scan | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| geometry/Ada/Histogram-Equalization | no | yes | yes | no | no | 17 | 17 | no SPARK |  |  |
| geometry/Ada/Hough-Transform | yes | yes | yes | yes | yes | 46 | 46 | no SPARK |  |  |
| geometry/Ada/Isosurfaces | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| geometry/Ada/Kirkpatrick-Seidel | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| geometry/Ada/Liang-Barsky | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| geometry/Ada/Line-Clipping | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| geometry/Ada/Line-Segment-Intersection | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| geometry/Ada/Marching-Cubes | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| geometry/Ada/Ordered-Dithering | yes | yes | yes | yes | yes | 20 | 20 | no SPARK |  |  |
| geometry/Ada/Phong-Shading | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| geometry/Ada/Point-In-Polygon | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | geometry/SPARK2/Ada-SPARK-Point-In-Polygon |  |
| geometry/Ada/Polygon-Triangulation | yes | yes | yes | yes | yes | 0 | 3 | no SPARK |  |  |
| geometry/Ada/Quasitriangulation | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| geometry/Ada/Quickhull | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| geometry/Ada/Radiosity | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| geometry/Ada/Ramer-Douglas-Peucker-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| geometry/Ada/Ray-Tracing | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| geometry/Ada/Riemersma-Dithering | yes | yes | yes | yes | yes | 29 | 29 | no SPARK |  |  |
| geometry/Ada/Segmentation | yes | no | no | yes | no | 41 | 41 | no SPARK |  |  |
| geometry/Ada/Shading | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| geometry/Ada/Slerp | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| geometry/Ada/Sutherland-Hodgman | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| geometry/Ada/Triangulation | yes | yes | yes | yes | yes | 0 | 3 | no SPARK |  |  |
| geometry/Ada/Vatti | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| geometry/Ada/Vincenty | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| geometry/Ada/Voronoi-Diagrams | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| geometry/Ada/Warnock-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| geometry/Ada/Watershed-Transformation | yes | no | no | yes | yes | 52 | 52 | no SPARK |  |  |
| geometry/Ada/Weiler-Atherton | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| geometry/Ada/Xiaolin-Wus-Line-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| geometry/SPARK2/Ada-SPARK-Convex-Hull-Graham | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| geometry/SPARK2/Ada-SPARK-Point-In-Polygon | yes | yes | yes | yes | yes | 0 | 0 | proven | geometry/Ada/Point-In-Polygon |  |
| graphs/Ada/Bellman-Ford-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| graphs/Ada/Boruvkas-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| graphs/Ada/Cliques | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| graphs/Ada/Coin-Graph | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| graphs/Ada/Cryptographically-Secure-Pseudo-Random-Number-Generators | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| graphs/Ada/Cryptographically-Secure-Pseudorandom-Number-Generator | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| graphs/Ada/Dijkstra-Scholten-Algorithm | yes | yes | yes | yes | yes | 1 | 1 | no SPARK |  |  |
| graphs/Ada/Dijkstras-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | graphs/SPARK4/Ada-SPARK-Dijkstras-Algorithm |  |
| graphs/Ada/Dinics-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| graphs/Ada/Edmonds-Karp-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| graphs/Ada/Elliptic-Curve-Cryptography | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| graphs/Ada/Euclidean-Minimum-Spanning-Tree | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| graphs/Ada/Floyd-Steinberg-Dithering | yes | yes | yes | yes | yes | 23 | 23 | no SPARK |  |  |
| graphs/Ada/Floyd-Warshall-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | graphs/SPARK2/Ada-SPARK-Floyd-Warshall |  |
| graphs/Ada/Floyds-Cycle-Finding-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | graphs/SPARK4/Ada-SPARK-Floyds-Cycle-Finding-Algorithm |  |
| graphs/Ada/Ford-Fulkerson-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| graphs/Ada/Hungarian-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| graphs/Ada/Hungarian-Method | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| graphs/Ada/Kosarajus-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| graphs/Ada/Kruskals-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | graphs/SPARK2/Ada-SPARK-Kruskals-Algorithm |  |
| graphs/Ada/MaxCliqueDyn | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| graphs/Ada/Minimum-Spanning-Tree | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| graphs/Ada/PageRank | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| graphs/Ada/Post-Quantum-Cryptography | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| graphs/Ada/Prims-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | graphs/SPARK2/Ada-SPARK-Prims-Algorithm |  |
| graphs/Ada/Shortest-Path-Problem | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| graphs/Ada/Tarjans-Off-Line-Lowest-Common-Ancestors | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| graphs/Ada/Tarjans-Strongly-Connected-Components | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| graphs/Ada/subgraph-isomorphism | n/a | yes | yes | yes | yes | 11 | 11 | no SPARK |  |  |
| graphs/SPARK2/Ada-SPARK-Bellman-Ford-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| graphs/SPARK2/Ada-SPARK-Clone-Graph | yes | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| graphs/SPARK2/Ada-SPARK-Clone-Graph-Stub | yes | yes | yes | yes | yes | 5 | 5 | proven |  |  |
| graphs/SPARK2/Ada-SPARK-Dijkstra-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| graphs/SPARK2/Ada-SPARK-Find-Center-Of-Star-Graph | yes | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| graphs/SPARK2/Ada-SPARK-Find-If-Path-Exists-In-Graph | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| graphs/SPARK2/Ada-SPARK-Floyd-Warshall | yes | yes | yes | yes | yes | 2 | 2 | proven | graphs/Ada/Floyd-Warshall-Algorithm |  |
| graphs/SPARK2/Ada-SPARK-Floyd-Warshall-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| graphs/SPARK2/Ada-SPARK-Is-Graph-Bipartite | yes | yes | yes | yes | yes | 3 | 3 | proven |  |  |
| graphs/SPARK2/Ada-SPARK-Kruskal-MST-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| graphs/SPARK2/Ada-SPARK-Kruskals-Algorithm | yes | yes | yes | yes | yes | 2 | 2 | proven | graphs/Ada/Kruskals-Algorithm |  |
| graphs/SPARK2/Ada-SPARK-Number-Of-Islands-DFS | yes | yes | yes | yes | yes | 6 | 6 | proven |  |  |
| graphs/SPARK2/Ada-SPARK-Prims-Algorithm | yes | yes | yes | yes | yes | 5 | 5 | proven | graphs/Ada/Prims-Algorithm |  |
| graphs/SPARK2/Ada-SPARK-Shortest-Path-In-Binary-Matrix | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| graphs/SPARK4/Ada-SPARK-Dijkstras-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | not run | graphs/Ada/Dijkstras-Algorithm |  |
| graphs/SPARK4/Ada-SPARK-Floyds-Cycle-Finding-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | not run | graphs/Ada/Floyds-Cycle-Finding-Algorithm |  |
| hashing/Ada/Geohash | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| hashing/Ada/Geometric-Hashing | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| hashing/Ada/Hash-Functions | yes | yes | yes | yes | yes | 6 | 6 | no SPARK |  |  |
| hashing/Ada/Hash-Join | yes | no | no | yes | yes | 0 | 0 | no SPARK |  |  |
| hashing/Ada/Locality-Sensitive-Hashing | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| hashing/Ada/Pearson-Hashing | yes | yes | yes | yes | yes | 18 | 18 | no SPARK | hashing/SPARK2/Ada-SPARK-Pearson-Hashing |  |
| hashing/Ada/SipHash | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| hashing/Ada/Tiger-Hash | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| hashing/Ada/Zobrist-Hashing | yes | yes | yes | yes | yes | 5 | 5 | no SPARK | hashing/SPARK2/Ada-SPARK-Zobrist-Hashing |  |
| hashing/SPARK2/Ada-SPARK-Design-HashMap | yes | yes | yes | yes | yes | 4 | 4 | proven |  |  |
| hashing/SPARK2/Ada-SPARK-Design-HashMap-Stub | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| hashing/SPARK2/Ada-SPARK-Design-HashSet | yes | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| hashing/SPARK2/Ada-SPARK-Design-HashSet-Stub | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| hashing/SPARK2/Ada-SPARK-FNV-Hash | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| hashing/SPARK2/Ada-SPARK-Pearson-Hashing | yes | yes | yes | yes | yes | 0 | 0 | proven | hashing/Ada/Pearson-Hashing |  |
| hashing/SPARK2/Ada-SPARK-Zobrist-Hashing | yes | yes | yes | yes | yes | 0 | 0 | proven | hashing/Ada/Zobrist-Hashing |  |
| logic/Ada/Chaff | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| logic/Ada/Constraint-Satisfaction | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| logic/Ada/DPLL | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| logic/Ada/DPLL-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| logic/Ada/Davis-Putnam | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| logic/Ada/Verified-Unification-Engine | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| matrices/Ada/Eigenvalue-Algorithms | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| matrices/Ada/Gaussian-Elimination | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | matrices/SPARK2/Ada-SPARK-Gaussian-Elimination |  |
| matrices/Ada/Jacobi-Eigenvalue | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| matrices/Ada/Matrix-Multiplication | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| matrices/Ada/Quantum-Singular-Value-Transformation | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| matrices/Ada/SMAWK | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| matrices/Ada/Schonhage-Strassen | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| matrices/Ada/Sparse-Matrix | yes | yes | yes | yes | yes | 0 | 8 | no SPARK |  |  |
| matrices/Ada/Strassen | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| matrices/Ada/Symbolic-Cholesky-Decomposition | yes | yes | yes | yes | yes | 24 | 24 | no SPARK |  |  |
| matrices/SPARK2/Ada-SPARK-Check-If-Matrix-Is-X-Matrix | yes | yes | yes | yes | yes | 10 | 10 | proven |  |  |
| matrices/SPARK2/Ada-SPARK-Gaussian-Elimination | yes | yes | yes | yes | yes | 4 | 4 | proven | matrices/Ada/Gaussian-Elimination |  |
| matrices/SPARK2/Ada-SPARK-Lucky-Numbers-In-A-Matrix | yes | yes | yes | yes | yes | 6 | 6 | proven |  |  |
| matrices/SPARK2/Ada-SPARK-Matrix-Cells-In-Distance-Order | yes | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| matrices/SPARK2/Ada-SPARK-Matrix-Chain-Multiplication | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| matrices/SPARK2/Ada-SPARK-Matrix-Diagonal-Sum | yes | yes | yes | yes | yes | 6 | 6 | proven |  |  |
| matrices/SPARK2/Ada-SPARK-Matrix-Multiply | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| matrices/SPARK2/Ada-SPARK-Num-Matrix-Block-Sum | yes | yes | yes | yes | yes | 5 | 5 | proven |  |  |
| matrices/SPARK2/Ada-SPARK-Reshape-The-Matrix | yes | yes | yes | yes | yes | 6 | 6 | proven |  |  |
| matrices/SPARK2/Ada-SPARK-Set-Matrix-Zeroes | yes | yes | yes | yes | yes | 10 | 10 | proven |  |  |
| matrices/SPARK2/Ada-SPARK-Spiral-Matrix | yes | yes | yes | yes | yes | 6 | 6 | proven |  |  |
| matrices/SPARK2/Ada-SPARK-Spiral-Matrix-II | yes | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| matrices/SPARK2/Ada-SPARK-The-K-Weakest-Rows-In-A-Matrix | yes | yes | yes | yes | yes | 5 | 5 | proven |  |  |
| matrices/SPARK2/Ada-SPARK-Toeplitz-Matrix | yes | yes | yes | yes | yes | 12 | 12 | proven |  |  |
| matrices/SPARK2/Ada-SPARK-Transpose-Matrix | yes | yes | yes | yes | yes | 5 | 5 | proven |  |  |
| misc/Ada/A-Law-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/AC-3 | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/ACORN-Generator | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Adaptive-Additive-Algorithm | yes | yes | yes | yes | yes | 37 | 37 | no SPARK |  |  |
| misc/Ada/Addition-Chain-Exponentiation | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Adler-32 | yes | yes | yes | yes | yes | 15 | 15 | no SPARK | misc/SPARK2/Ada-SPARK-Adler32 |  |
| misc/Ada/Aharonov-Jones-Landau-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Algorithm-X | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Algorithms-For-Calculating-Variance | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Alpha-Beta-Pruning | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Alpha-Max-Plus-Beta-Min | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Amplitude-Amplification | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Ant-Colony-Optimization | yes | yes | yes | yes | yes | 0 | 1 | no SPARK |  |  |
| misc/Ada/Approximate-Counting | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Apriori-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Association-Rule-Learning | no | yes | yes | no | no | 0 | 0 | no SPARK |  |  |
| misc/Ada/Automated-Planning-And-Scheduling | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Automatic-Train-Operation | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/B-Star | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/BCH-Codes | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/BCJR-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/BHT-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/BLAST | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Baby-Step-Giant-Step | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Backtracking | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Backward-Euler | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Backward-Induction | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Baillie-PSW | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Bankers-Algorithm | yes | yes | yes | yes | yes | 188 | 188 | no SPARK | misc/SPARK2/Ada-SPARK-Bankers-Algorithm |  |
| misc/Ada/Banzhaf-Power-Index | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Barnes-Hut | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Baum-Welch | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Bayesian-Nash-Equilibrium | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Bayesian-Statistics | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Beam-Tracing | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Bees-Algorithm | yes | yes | yes | yes | yes | 0 | 1 | no SPARK |  |  |
| misc/Ada/Beginner-Embedded-API | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/Ada/Bensons-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Bentley-Ottmann | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Berkeley-Algorithm | yes | yes | yes | yes | yes | 25 | 25 | no SPARK |  |  |
| misc/Ada/Bernstein-Varizani-Algorithm | yes | yes | yes | yes | no | 0 | 0 | no SPARK |  |  |
| misc/Ada/Best-Bin-First | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Binary-Space-Partitioning | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Binary-Splitting | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Birkhoff-von-Neumann | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Bitap-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Black-Scholes-Model | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/Ada/Blind-Deconvolution | yes | yes | yes | yes | yes | 52 | 52 | no SPARK |  |  |
| misc/Ada/Block-Nested-Loop | yes | yes | yes | yes | yes | 14 | 14 | no SPARK |  |  |
| misc/Ada/Block-Truncation-Coding | yes | yes | yes | yes | yes | 12 | 12 | no SPARK |  |  |
| misc/Ada/Blossom-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Blum-Blum-Shub | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | misc/SPARK4/Ada-SPARK-Blum-Blum-Shub |  |
| misc/Ada/Booth-Multiplication | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Bootstrap-Aggregating | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Boson-Sampling | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Boundary-Representation | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Bowyer-Watson | yes | yes | yes | yes | yes | 0 | 3 | no SPARK |  |  |
| misc/Ada/Branch-and-Bound | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Branch-and-Cut | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Bron-Kerbosch | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Buchbergers-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Buddy-Memory-Allocation | no | yes | yes | yes | yes | 2 | 2 | no SPARK | misc/SPARK2/Ada-SPARK-Buddy-Memory-Allocation |  |
| misc/Ada/Buechi-Automaton | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Bully-Algorithm | yes | yes | yes | yes | yes | 3 | 3 | no SPARK |  |  |
| misc/Ada/Buzens-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/C4.5-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/CHS-Conversion | yes | yes | yes | yes | yes | 1 | 1 | no SPARK |  |  |
| misc/Ada/Cannons-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Chaitins-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Chandra-Toueg | yes | yes | yes | yes | yes | 12 | 12 | no SPARK |  |  |
| misc/Ada/Chans-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Chase | yes | yes | yes | yes | yes | 60 | 60 | no SPARK |  |  |
| misc/Ada/Cheneys-Algorithm | no | yes | yes | yes | yes | 16 | 16 | no SPARK |  |  |
| misc/Ada/Chews-Second-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Chinese-Whispers | yes | yes | yes | yes | yes | 0 | 1 | no SPARK |  |  |
| misc/Ada/Christofides-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Code-Excited-Linear-Prediction | yes | yes | yes | yes | yes | 25 | 25 | no SPARK |  |  |
| misc/Ada/Collision-Detection | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Coloring-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Combinatorial-Auction | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Combinatorial-Optimization | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Communications-Based-Train-Control | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Computation-Of-Pi | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Computer-Vision | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Computus | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Cone-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Cone-Tracing | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Conflict-Driven-Clause-Learning | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Congruence-Of-Squares | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Connected-Component-Labeling | yes | yes | yes | yes | yes | 39 | 39 | no SPARK | misc/SPARK2/Ada-SPARK-Connected-Component-Labeling |  |
| misc/Ada/Constraint-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Contour-Lines | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Coppersmith-Winograd | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Core | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Corporate-Wars-Sim | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Correlated-Equilibrium | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Crank-Nicolson | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Cristians-Algorithm | yes | yes | yes | yes | yes | 3 | 3 | no SPARK |  |  |
| misc/Ada/Cross-Entropy-Method | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Cuthill-McKee | yes | yes | yes | yes | yes | 0 | 7 | no SPARK |  |  |
| misc/Ada/Cutting-Plane-Method | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Cyclic-Redundancy-Check | yes | yes | yes | yes | yes | 5 | 5 | no SPARK |  |  |
| misc/Ada/Cyrus-Beck | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/D-Star | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/DDA-Line-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/DSA | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Damm-Algorithm | yes | yes | yes | yes | yes | 17 | 17 | no SPARK |  |  |
| misc/Ada/Dancing-Links | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Dantzig-Wolfe-Decomposition | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Darwin-Godel-Machine | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Data-Flow-Analysis | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/De-Boor | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/De-Casteljau | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Delayed-Column-Generation | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Delivery-Mission-FSM | no | no | no | no | no | NA | NA | no SPARK |  |  |
| misc/Ada/Delivery-Safety-Supervisor | no | no | no | no | no | NA | NA | no SPARK |  |  |
| misc/Ada/Delta-Encoding | no | yes | yes | yes | yes | 21 | 21 | no SPARK | misc/SPARK2/Ada-SPARK-Delta-Encoding |  |
| misc/Ada/Demon-Method | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Description-Logic | yes | yes | yes | yes | yes | 16 | 16 | no SPARK |  |  |
| misc/Ada/Deutsch-Josza-Algorithm | yes | yes | yes | yes | yes | 9 | 9 | no SPARK |  |  |
| misc/Ada/Dice-Coefficient | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | misc/SPARK2/Ada-SPARK-Dice-Coefficient |  |
| misc/Ada/Dictionary-Coder | yes | yes | yes | yes | yes | 12 | 12 | no SPARK |  |  |
| misc/Ada/Difference-Map | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Differential-Evolution | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Diffie-Hellman-Key-Exchange | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Discrete-Event-Simulation | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Discrete-Fourier-Transformation | yes | yes | yes | yes | yes | 11 | 11 | no SPARK |  |  |
| misc/Ada/Discrete-Logarithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Division-Algorithms | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Doomsday | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Double-Dabble | yes | yes | yes | yes | yes | 9 | 9 | no SPARK |  |  |
| misc/Ada/Dynamic-Programming | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Dynamic-Time-Warping | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/EIGamal | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/ESC-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Eclat-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/EdDSA | yes | yes | yes | yes | no | 0 | 0 | no SPARK |  |  |
| misc/Ada/Edmonds-Algorithm | yes | yes | yes | yes | yes | 0 | 1 | no SPARK |  |  |
| misc/Ada/Elevator-Algorithm | n/a | no | no | no | no | NA | NA | no SPARK | misc/SPARK2/Ada-SPARK-Elevator-Algorithm |  |
| misc/Ada/Elias-Delta-Coding | yes | yes | yes | yes | yes | 2 | 2 | no SPARK |  |  |
| misc/Ada/Elias-Gamma-Coding | yes | yes | yes | yes | yes | 1 | 1 | no SPARK |  |  |
| misc/Ada/Elias-Omega-Coding | yes | yes | yes | yes | yes | 6 | 6 | no SPARK |  |  |
| misc/Ada/Ellipsoid-Method | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Elser-Difference-Map-Algorithm | yes | yes | yes | yes | yes | 9 | 9 | no SPARK |  |  |
| misc/Ada/Entropy-Coding | yes | yes | yes | yes | yes | 12 | 12 | no SPARK |  |  |
| misc/Ada/Entropy-Coding-With-Known-Entropy-Characteristics | no | no | no | no | no | 14 | 14 | no SPARK |  |  |
| misc/Ada/Error-Diffusion | yes | yes | yes | yes | yes | 19 | 19 | no SPARK |  |  |
| misc/Ada/Espresso-Heuristic-Logic-Minimizer | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Estimation-Theory | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Euclidean-Distance-Transform | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Euler-Integration | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Evolution-Strategy | yes | yes | yes | yes | yes | 0 | 1 | no SPARK |  |  |
| misc/Ada/Evolutionary-Computation | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Exact-Cover | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Exponential-Backoff | yes | yes | yes | yes | yes | 67 | 67 | no SPARK |  |  |
| misc/Ada/Exponential-Golomb-Coding | yes | yes | yes | yes | yes | 2 | 2 | no SPARK |  |  |
| misc/Ada/Exponentiating-By-Squaring | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/FP-Growth-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/False-Nearest-Neighbor | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/False-Position-Method | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Fast-Cosine-Transform-Algorithms | yes | yes | yes | yes | yes | 12 | 12 | no SPARK |  |  |
| misc/Ada/Fast-Folding-Algorithm | yes | yes | yes | yes | yes | 17 | 17 | no SPARK |  |  |
| misc/Ada/Fast-Multipole-Method | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Faugere-F4 | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Featherstone | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Feature-Detection | yes | yes | yes | yes | yes | 10 | 10 | no SPARK |  |  |
| misc/Ada/Fermat-Factorization | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Fibonacci-Coding | yes | yes | yes | yes | yes | 16 | 16 | no SPARK |  |  |
| misc/Ada/Fictitious-Play | yes | yes | yes | yes | yes | 38 | 38 | no SPARK |  |  |
| misc/Ada/Filtered-Back-Projection | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Financial-Information-Exchange | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Financial-Risk-Modeling | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/Ada/Finite-Difference-Method | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/First-Order-Logic | yes | yes | yes | yes | no | 0 | 0 | no SPARK |  |  |
| misc/Ada/Fisher-Yates-Shuffle | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | misc/SPARK2/Ada-SPARK-Fisher-Yates-Shuffle |  |
| misc/Ada/Fitness-Proportionate-Selection | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Fletchers-Checksum | yes | yes | yes | yes | yes | 13 | 13 | no SPARK |  |  |
| misc/Ada/Flood-Fill | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | misc/SPARK2/Ada-SPARK-Flood-Fill |  |
| misc/Ada/Flow-Networks | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Force-Based-Algorithms | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Fortunes-Algorithm | yes | yes | yes | yes | yes | 18 | 18 | no SPARK |  |  |
| misc/Ada/Forward-Error-Correction | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Foundations-Curriculum | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Fowler-Noll-Vo | yes | yes | yes | yes | yes | 5 | 5 | no SPARK |  |  |
| misc/Ada/Frank-Wolfe-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Freivalds | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Fuzzy-C-Means | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/GNAT-Studio-Notes | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/Ada/GPU-Work-Queue | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/Ada/GRASP | yes | yes | yes | yes | yes | 0 | 1 | no SPARK |  |  |
| misc/Ada/Gale-Shapley-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Gauss-Jordan | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Gauss-Seidel | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Gene-Expression-Programming | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/General-Problem-Solver | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Generational-Garbage-Collector | yes | yes | yes | yes | yes | 9 | 9 | no SPARK |  |  |
| misc/Ada/Genetic-Algorithms | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Gerchberg-Saxton-Algorithm | yes | yes | yes | yes | yes | 15 | 15 | no SPARK |  |  |
| misc/Ada/Gibbs-Sampling | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Gilbert-Johnson-Keerthi | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Glauber-Dynamics | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Global-Illumination | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Goertzel-Algorithm | yes | yes | yes | yes | yes | 8 | 8 | no SPARK |  |  |
| misc/Ada/Goldschmidt-Division | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Golomb-Coding | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Gospers-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Gram-Schmidt | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Gray-Code | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | misc/SPARK2/Ada-SPARK-Gray-Code |  |
| misc/Ada/Ground-State | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Grovers-Algorithm | yes | yes | yes | yes | yes | 2 | 2 | no SPARK |  |  |
| misc/Ada/GrowCut | yes | yes | yes | yes | yes | 9 | 9 | no SPARK |  |  |
| misc/Ada/HHL-Algorithm | yes | yes | yes | yes | yes | 3 | 3 | no SPARK |  |  |
| misc/Ada/Hadamard-Test | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Hadamard-Transform | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Half-Toning | yes | yes | yes | yes | yes | 25 | 25 | no SPARK |  |  |
| misc/Ada/Halleys-Method | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Hamiltonian-Simulation | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Hamming-7-4 | yes | yes | yes | yes | yes | 37 | 37 | no SPARK |  |  |
| misc/Ada/Hamming-Code | yes | yes | yes | yes | yes | 4 | 4 | no SPARK | misc/SPARK2/Ada-SPARK-Hamming-Code |  |
| misc/Ada/Hamming-Weight | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | misc/SPARK2/Ada-SPARK-Hamming-Weight |  |
| misc/Ada/Heaps-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | misc/SPARK4/Ada-SPARK-Heaps-Algorithm |  |
| misc/Ada/Hidden-Linear-Function-Problem | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Hidden-Shift-Problem | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Hidden-Subgroup-Problem | yes | yes | yes | yes | yes | 3 | 3 | no SPARK |  |  |
| misc/Ada/Hidden-Surface-Removal | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Hindley-Milner-Type-Inference-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Hindley-Milner-Type-System | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Hirschbergs-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Hopcroft-Karp-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Hopcrofts-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Hopfield-Net | yes | yes | yes | yes | no | 0 | 0 | no SPARK |  |  |
| misc/Ada/Huangs-Algorithm | yes | yes | yes | yes | yes | 2 | 2 | no SPARK |  |  |
| misc/Ada/Hybrid-Algorithms | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/ID3-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/ITP-Method | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Image-Based-Lighting | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Incremental-Encoding | yes | yes | yes | yes | yes | 12 | 12 | no SPARK |  |  |
| misc/Ada/Index-Calculus | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Inside-Out-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Integer-Factorization | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Integer-Linear-Programming | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Intersection-Algorithm | yes | yes | yes | yes | yes | 12 | 12 | no SPARK |  |  |
| misc/Ada/Inverse-Iteration | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Johnsons-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Jump-And-Walk | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/K-Nearest-Neighbours | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/K-Way-Merge | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | misc/SPARK4/Ada-SPARK-K-Way-Merge |  |
| misc/Ada/Kabsch | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Kadanes-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | misc/SPARK2/Ada-SPARK-Kadanes-Algorithm |  |
| misc/Ada/Kahan-Summation | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Kalman-Filter | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Kargers-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Karmarkars-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Karn-Algorithm | yes | yes | yes | yes | yes | 37 | 37 | no SPARK |  |  |
| misc/Ada/Key-Derivation-Function | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Key-Exchange | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Knuth-Bendix-Completion | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/Ada/Krauss-Matching-Wildcards | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Lagged-Fibonacci-Generator | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | misc/SPARK4/Ada-SPARK-Lagged-Fibonacci-Generator |  |
| misc/Ada/Laplacian-Smoothing | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Lax-Wendroff | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Lemke-Howson | yes | yes | yes | yes | yes | 95 | 95 | no SPARK | misc/SPARK4/Ada-SPARK-Lemke-Howson |  |
| misc/Ada/Lempel-Ziv-Jeff-Bonwick | yes | yes | yes | yes | yes | 12 | 12 | no SPARK |  |  |
| misc/Ada/Lempel-Ziv-Markov-Chain-Algorithm | yes | yes | yes | yes | yes | 6 | 6 | no SPARK |  |  |
| misc/Ada/Lempel-Ziv-Oberhurmer | yes | yes | yes | yes | yes | 23 | 23 | no SPARK |  |  |
| misc/Ada/Lempel-Ziv-Ross-Williams | yes | yes | yes | yes | yes | 15 | 15 | no SPARK |  |  |
| misc/Ada/Lempel-Ziv-Stac | yes | yes | yes | yes | yes | 9 | 9 | no SPARK |  |  |
| misc/Ada/Lempel-Ziv-Storer-Szymanski | yes | yes | yes | yes | yes | 9 | 9 | no SPARK |  |  |
| misc/Ada/Lempel-Ziv-Welch | yes | yes | yes | yes | yes | 7 | 7 | no SPARK |  |  |
| misc/Ada/Lenstra-Lenstra-Lovasz | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Lesk | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Level-Set-Method | yes | yes | yes | yes | yes | 4 | 4 | no SPARK |  |  |
| misc/Ada/Levinson-Recursion | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Lexical-Analysis | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Linde-Buzo-Gray | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Linde-Buzo-Gray-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Line-Drawing | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Linear-Feedback-Shift-Register | yes | yes | yes | yes | no | 0 | 0 | no SPARK |  |  |
| misc/Ada/Linear-Multistep-Methods | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Linear-Predictive-Coding | yes | yes | yes | yes | yes | 26 | 26 | no SPARK |  |  |
| misc/Ada/Linear-Programming | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/List-Scheduling | n/a | no | no | no | no | NA | NA | no SPARK |  |  |
| misc/Ada/Locomotion-Mode-Interlock | no | no | no | no | no | NA | NA | no SPARK |  |  |
| misc/Ada/Long-Division | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Longest-Increasing-Subsequence | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | misc/SPARK2/Ada-SPARK-Longest-Increasing-Subsequence |  |
| misc/Ada/Longest-Path-Problem | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Longitudinal-Redundacy-Check | yes | yes | yes | yes | yes | 8 | 8 | no SPARK |  |  |
| misc/Ada/Luhn-Algorithm | yes | yes | yes | yes | yes | 5 | 5 | no SPARK |  |  |
| misc/Ada/Luhn-Mod-N-Algorithm | yes | yes | yes | yes | yes | 12 | 12 | no SPARK |  |  |
| misc/Ada/Luleas-Algorithm | no | no | no | no | no | 5 | 5 | no SPARK |  |  |
| misc/Ada/Maekawas-Algorithm | no | yes | yes | no | no | 5 | 5 | no SPARK |  |  |
| misc/Ada/Manning-Criteria | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Marching-Squares | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Marching-Tetrahedrons | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Marching-Triangles | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Mark-Compact-Algorithm | no | yes | yes | yes | yes | 11 | 12 | no SPARK |  |  |
| misc/Ada/Mark-and-Sweep | no | yes | yes | yes | yes | 15 | 15 | no SPARK | misc/SPARK2/Ada-SPARK-Mark-And-Sweep |  |
| misc/Ada/Marr-Hildreth-Algorithm | yes | yes | yes | yes | yes | 59 | 59 | no SPARK |  |  |
| misc/Ada/Marzullos-Algorithm | yes | yes | yes | yes | yes | 24 | 24 | no SPARK |  |  |
| misc/Ada/Match-Rating-Approach | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Matching-Wildcards | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Maximum-Parsimony | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Mechanistic-Interpretability | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Median-Filtering | yes | yes | yes | yes | yes | 51 | 51 | no SPARK | misc/SPARK2/Ada-SPARK-Median-Filtering |  |
| misc/Ada/Memetic-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Memory-Channel-Model | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/Ada/Message-Authentication-Codes | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Midpoint-Circle-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Min-Conflicts | yes | yes | yes | yes | yes | 0 | 1 | no SPARK |  |  |
| misc/Ada/Minimax | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Minimum-Bounding-Box | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Minimum-Degree | yes | yes | yes | yes | yes | 0 | 5 | no SPARK |  |  |
| misc/Ada/Mirror-Descent | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Modular-Square-Root | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Montgomery-Reduction | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Moores-Algorithm | yes | yes | yes | yes | no | 0 | 0 | no SPARK |  |  |
| misc/Ada/Mu-Law-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Mullers-Method | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Multigrid-Methods | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Multiplication-Algorithms | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Multiplicative-Inverse-Algorithms | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Multiplicative-Weight-Update-Method | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Multivariate-Division-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/N-Body-Problems | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/NEF-Adaptive-OSC | no | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/NEF-Neurorobotics-Core | no | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Nagles-Algorithm | no | yes | yes | no | no | 14 | 14 | no SPARK |  |  |
| misc/Ada/Naimi-Trehel | yes | yes | yes | yes | yes | 1 | 1 | no SPARK |  |  |
| misc/Ada/Nearest-Neighbor-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Nelder-Mead | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Nested-Loop-Join | yes | no | no | yes | no | 5 | 5 | no SPARK |  |  |
| misc/Ada/Nested-Sampling | yes | yes | yes | yes | yes | 0 | 1 | no SPARK |  |  |
| misc/Ada/Nesting-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Newton-Multiplicative-Inverse | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Newtons-Method | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Newtons-Method-in-Optimization | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Nicholl-Lee-Nicholl | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Non-Local-Quantum-Computation | yes | yes | yes | yes | yes | 1 | 1 | no SPARK |  |  |
| misc/Ada/Non-Restoring-Division | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Nonblocking-Minimal-Spanning-Switch | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Nonlinear-Optimization | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Nth-Root | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Nucleolus | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Odds-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Odlyzko-Schonhage | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/One-Attribute-Rule | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Operations-Research | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Orbital-Mechanics | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/Ada/Ordered-Subset-EM | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/PBKDF2 | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/PCIe-Transfer-Model | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/Ada/Package-Merge-Algorithm | yes | yes | yes | yes | yes | 30 | 30 | no SPARK | misc/SPARK4/Ada-SPARK-Package-Merge-Algorithm |  |
| misc/Ada/Painters-Algorithm | yes | yes | yes | yes | yes | 3 | 3 | no SPARK |  |  |
| misc/Ada/Parity-Bit | yes | yes | yes | yes | yes | 8 | 8 | no SPARK |  |  |
| misc/Ada/Partial-Differential-Equation | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Particle-Swarm | yes | yes | yes | yes | yes | 0 | 1 | no SPARK |  |  |
| misc/Ada/Path-Based-Strong-Component | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Path-Tracing | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Petricks-Method | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Phonetic-Algorithms | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Photon-Mapping | no | no | yes | no | yes | 0 | 0 | not run |  |  |
| misc/Ada/Planning-Domain-Definition-Language | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Pohlig-Hellman | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Point-Set-Registration | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Poly1305 | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Polynomial-Long-Division | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Power-Iteration | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Powerset-Construction | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Prediction-By-Partial-Matching | no | no | no | no | no | 11 | 11 | no SPARK |  |  |
| misc/Ada/Program-Synthesis | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Progressive-Jackpot | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Proof-Of-Work-Algorithms | yes | yes | yes | yes | yes | 4 | 4 | no SPARK |  |  |
| misc/Ada/Prufer-Coding | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Pseudorandom-Number-Generator | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Pulmonary-Embolism-Algorithms | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Push-Relabel-Algorithm | yes | yes | yes | yes | yes | 16 | 16 | no SPARK |  |  |
| misc/Ada/QR-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Quantum-Annealing | yes | yes | yes | yes | no | 0 | 0 | no SPARK |  |  |
| misc/Ada/Quantum-Artificial-Life | no | no | yes | no | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Quantum-Counting-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Quantum-Fourier-Transform | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Quantum-Optimization-Algorithms | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Quantum-Phase-Estimation-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Queuing-Theory | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Quine-McCluskey-Algorithm | yes | yes | yes | yes | yes | 25 | 25 | no SPARK |  |  |
| misc/Ada/RANSAC | yes | yes | yes | yes | yes | 0 | 1 | no SPARK |  |  |
| misc/Ada/RIPEMD-160 | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Radial-Basis-Function-Network | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Rainflow-Counting | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Random-Restart-Hill-Climbing | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Random-Walker | yes | yes | yes | yes | yes | 54 | 54 | no SPARK |  |  |
| misc/Ada/Range-Encoding | yes | yes | yes | yes | yes | 8 | 8 | no SPARK |  |  |
| misc/Ada/Rayleigh-Quotient-Iteration | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Rayleigh-Ritz-Method | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Raymonds-Algorithm | yes | yes | yes | yes | yes | 1 | 1 | no SPARK |  |  |
| misc/Ada/Recovery-Exploiting-Semantics | yes | yes | yes | yes | yes | 6 | 6 | no SPARK |  |  |
| misc/Ada/Redundancy-Checks | yes | yes | yes | yes | yes | 10 | 10 | no SPARK |  |  |
| misc/Ada/Reed-Solomon-Error-Correction | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Reference-Counting | yes | yes | yes | yes | yes | 45 | 45 | no SPARK | misc/SPARK2/Ada-SPARK-Reference-Counting |  |
| misc/Ada/Region-Growing | yes | yes | yes | yes | yes | 34 | 34 | no SPARK |  |  |
| misc/Ada/Regret-Minimization | yes | yes | yes | yes | yes | 33 | 33 | no SPARK |  |  |
| misc/Ada/Relevance-Vector-Machine | yes | yes | yes | yes | no | 0 | 0 | no SPARK |  |  |
| misc/Ada/Replicator-Equation | yes | yes | yes | yes | yes | 52 | 52 | no SPARK |  |  |
| misc/Ada/Restoring-Division | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Rete-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Reverse-Delete-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Ricart-Agrawala-Algorithm | yes | yes | yes | yes | yes | 8 | 8 | no SPARK |  |  |
| misc/Ada/Rice-Coding | yes | yes | yes | yes | yes | 1 | 1 | no SPARK |  |  |
| misc/Ada/Richardson-Lucy-Deconvolution | yes | no | no | yes | no | 0 | 0 | no SPARK |  |  |
| misc/Ada/Ridders-Method | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Risch-Algorithm | yes | yes | yes | yes | yes | 5 | 5 | no SPARK |  |  |
| misc/Ada/Rotating-Calipers | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Rounding-Functions | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Rupperts-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Ruzzo-Tompa | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/SEQUITUR-Algorithm | yes | yes | yes | yes | yes | 4 | 4 | no SPARK |  |  |
| misc/Ada/SRT-Division | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/SSS-Star | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/SUBCLU | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Salsa20 | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Scale-Invariant-Feature-Transform | yes | yes | yes | yes | yes | 5 | 5 | no SPARK |  |  |
| misc/Ada/Scanline-Rendering | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Schensted | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Schreier-Sims | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Scoring-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Seam-Carving | yes | yes | yes | yes | yes | 19 | 19 | no SPARK |  |  |
| misc/Ada/Secret-Sharing | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Selection-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | misc/SPARK4/Ada-SPARK-Selection-Algorithm |  |
| misc/Ada/Self-Organizing-Map | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Semi-Space-Collectors | yes | yes | yes | yes | yes | 11 | 11 | no SPARK |  |  |
| misc/Ada/Sethi-Ullman-Algorithm | yes | no | no | yes | no | 0 | 0 | no SPARK |  |  |
| misc/Ada/Shannon-Fano-Coding | yes | yes | yes | yes | yes | 11 | 11 | no SPARK |  |  |
| misc/Ada/Shannon-Fano-Elias-Coding | yes | yes | yes | yes | yes | 4 | 4 | no SPARK |  |  |
| misc/Ada/Shapley-Value | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Shoelace-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Shors-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Shortest-Common-Supersequence-Problem | yes | yes | yes | yes | yes | 2 | 2 | no SPARK |  |  |
| misc/Ada/Simons-Problem | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Simulated-Annealing | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Sinkhorn-Knopp-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Slot-Machine | yes | yes | yes | yes | no | 6 | 6 | no SPARK |  |  |
| misc/Ada/Spectral-Layout | yes | yes | yes | yes | yes | 23 | 23 | no SPARK |  |  |
| misc/Ada/Speeded-Up-Robust-Features | yes | yes | yes | yes | yes | 5 | 5 | no SPARK |  |  |
| misc/Ada/Spigot-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Square-Root-Algorithms | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/State-Action-Reward-State-Action | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Steinhaus-Johnson-Trotter | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Stochastic-Tunneling | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Stones-Method | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Strongly-Connected-Components | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Structured-SVM | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Subset-Sum-Algorithm | yes | yes | yes | yes | yes | 15 | 15 | no SPARK |  |  |
| misc/Ada/Successive-Over-Relaxation | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Sukhotin | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Summed-Area-Table | yes | yes | yes | yes | yes | 14 | 14 | no SPARK |  |  |
| misc/Ada/Supervised-Learning | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Swap-Test | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Swarm-Intelligence | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Sweep-And-Prune | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/System-of-Linear-Equations | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Tarski-Kuratowski-Algorithm | yes | yes | yes | yes | yes | 15 | 15 | no SPARK |  |  |
| misc/Ada/Temporal-Difference-Learning | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Term-Rewriting | yes | yes | yes | yes | yes | 2 | 1 | no SPARK |  |  |
| misc/Ada/Texas-Medication-Algorithm-Project | yes | yes | yes | yes | yes | 1 | 1 | no SPARK |  |  |
| misc/Ada/Thomas-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Todd-Coxeter | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Tomasulo-Algorithm | yes | yes | yes | yes | yes | 17 | 17 | no SPARK |  |  |
| misc/Ada/Toom-Cook | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Top-Nodes-Algorithm | yes | yes | yes | yes | yes | 2 | 2 | no SPARK | misc/SPARK2/Ada-SPARK-Top-Nodes-Algorithm |  |
| misc/Ada/Top-Trading-Cycle | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Traffic-Light-Controller | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Traffic-Simulation | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/Ada/Transform-Coding | yes | yes | yes | yes | yes | 17 | 17 | no SPARK |  |  |
| misc/Ada/Transitive-Closure | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Trapezoidal-Rule-DE | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Travelling-Salesman-Problem | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Trial-Division | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Truncated-Binary-Encoding | yes | yes | yes | yes | yes | 6 | 6 | no SPARK |  |  |
| misc/Ada/Truncated-Binary-Exponential-Backoff | yes | yes | yes | yes | yes | 61 | 61 | no SPARK |  |  |
| misc/Ada/Truncation-Selection | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/TrustRank | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/TurboQuant | yes | yes | yes | yes | yes | 61 | 61 | no SPARK |  |  |
| misc/Ada/Ukkonens-Algorithm | yes | yes | yes | yes | yes | 7 | 7 | no SPARK |  |  |
| misc/Ada/Unary-Coding | yes | yes | yes | yes | yes | 7 | 7 | no SPARK |  |  |
| misc/Ada/Unicode-Collation-Algorithm | yes | yes | yes | yes | yes | 5 | 5 | no SPARK |  |  |
| misc/Ada/Unrestricted-Algorithm | yes | yes | yes | yes | yes | 32 | 32 | no SPARK |  |  |
| misc/Ada/VEGAS-Algorithm | yes | yes | yes | yes | yes | 16 | 16 | no SPARK |  |  |
| misc/Ada/Variational-Method | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Variational-Quantum-Eigensolver | yes | yes | yes | yes | yes | 19 | 19 | no SPARK |  |  |
| misc/Ada/Vector-Quantization | yes | yes | yes | yes | yes | 69 | 69 | no SPARK |  |  |
| misc/Ada/Vehicle-Routing-Problem | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Velvet | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Verhoeff-Algorithm | yes | yes | yes | yes | yes | 21 | 21 | no SPARK |  |  |
| misc/Ada/Vickrey-Clarke-Groves-Mechanism | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Wang-Landau | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Warnsdorffs-Rule | yes | yes | yes | yes | yes | 5 | 5 | no SPARK |  |  |
| misc/Ada/Warped-Linear-Predictive-Coding | yes | yes | yes | yes | yes | 7 | 7 | no SPARK |  |  |
| misc/Ada/Xor-Swap-Algorithm | yes | yes | yes | yes | yes | 12 | 12 | no SPARK |  |  |
| misc/Ada/Yamartino-Method | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Zellers-Congruence-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Zero-Attribute-Rule | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/Zhu-Takaoka | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| misc/Ada/arc-cache | yes | yes | yes | yes | no | 9 | 9 | no SPARK |  |  |
| misc/Ada/clock-replacement | no | no | no | no | no | NA | NA | no SPARK |  |  |
| misc/Ada/docs | n/a | no | no | no | no | NA | NA | no SPARK |  |  |
| misc/Ada/earliest-deadline | no | no | no | no | no | NA | NA | no SPARK |  |  |
| misc/Ada/fair-share | yes | yes | yes | yes | yes | 1 | 1 | no SPARK |  |  |
| misc/Ada/page-replacement-algorithms | no | yes | yes | yes | yes | 12 | 12 | no SPARK |  |  |
| misc/Ada/rate-monotonic | no | yes | yes | yes | yes | 16 | 16 | no SPARK |  |  |
| misc/Ada/round-robin | n/a | no | no | no | no | NA | NA | no SPARK |  |  |
| misc/Ada/scripts | n/a | no | no | no | no | NA | NA | no SPARK |  |  |
| misc/Ada/srt-simulation | n/a | no | no | no | no | NA | NA | no SPARK |  |  |
| misc/SPARK2/Ada-SPARK-3Sum-Closest | yes | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| misc/SPARK2/Ada-SPARK-4Sum-II | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Accounts-Merge-Lite | yes | yes | yes | yes | yes | 3 | 3 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Accounts-Merge-Stub | yes | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Add-Binary | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Add-Digits | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Add-Two-Numbers | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Add-Two-Numbers-II | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Add-Without-Plus | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Adler32 | yes | yes | yes | yes | yes | 0 | 0 | proven | misc/Ada/Adler-32 |  |
| misc/SPARK2/Ada-SPARK-Alert-Using-Same-Key-Card-Stub | yes | yes | yes | yes | yes | 4 | 4 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Alien-Dictionary-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Alien-Dictionary-Stub | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| misc/SPARK2/Ada-SPARK-All-Paths-From-Source-To-Target | yes | yes | yes | yes | yes | 3 | 3 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Argmax | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Arranging-Coins | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Array-Partition-I | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| misc/SPARK2/Ada-SPARK-As-Far-From-Land-As-Possible | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Assign-Cookies | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Asteroid-Collision | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Authentication-Manager-Stub | yes | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Available-Captures-For-Rook | yes | yes | yes | yes | yes | 5 | 5 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Bankers-Algorithm | yes | yes | yes | yes | yes | 11 | 11 | proven | misc/Ada/Bankers-Algorithm |  |
| misc/SPARK2/Ada-SPARK-Base64-Decode | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Base64-Encode | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Baseball-Game | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Basic-Calculator | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Basic-Calculator-II | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Basic-Calculator-Stub | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Beautiful-Arrangement | yes | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Beautiful-Array-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Best-Time-To-Buy-And-Sell-Stock | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Best-Time-To-Buy-And-Sell-Stock-II | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Best-Time-To-Buy-And-Sell-Stock-With-Cooldownoldown | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Binary-Number-With-Alternating-Bits | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Binary-To-Integer | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Binary-Watch | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Binomial-Coefficient | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Bitset | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Bitwise-AND-Of-Numbers-Range | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Bitwise-OR-Of-Numbers-Range | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Bitwise-ORs-Of-Subarrays-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Bitwise-XOR-Of-All-Pairings | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Boats-To-Save-People | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Bounding-Box | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Bray-Curtis | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Broken-Calculator | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Browser-History-Stub | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Buddy-Memory-Allocation | yes | yes | yes | yes | yes | 1 | 1 | proven | misc/Ada/Buddy-Memory-Allocation |  |
| misc/SPARK2/Ada-SPARK-Bulb-Switcher | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Bulb-Switcher-Stub | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Bump-Arena | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-CRC32 | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| misc/SPARK2/Ada-SPARK-CSR-Row-Sum | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Can-Place-Flowers | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Canberra-Distance | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Candy | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Capacity-To-Ship-Packages | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Car-Pooling | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Cheapest-Flights | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Cheapest-Flights-Stub | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Cheapest-Flights-Within-K-Stops | yes | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Check-If-Number-Is-A-Sum-Of-Powers-Of-Three | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Check-If-The-Sentence-Is-Pangram | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Checksum-Ones-Complement | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Cherry-Pickup-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Circular-Deque-Stub | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Circular-Queue | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Clamp | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Climbing-Stairs | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Clock-Page-Replacement | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Coin-Change | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Coin-Change-II | yes | yes | yes | yes | yes | 3 | 3 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Combination-Iterator-Stub | yes | yes | yes | yes | yes | 4 | 4 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Combination-Sum | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Combination-Sum-II | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Combination-Sum-III | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Combination-Sum-IV | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Complement-Of-Base-10 | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Complement-Of-Base-10-Integer | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Connected-Component-Labeling | yes | yes | yes | yes | yes | 0 | 0 | proven | misc/Ada/Connected-Component-Labeling |  |
| misc/SPARK2/Ada-SPARK-Container-With-Most-Water | yes | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Contains-Duplicate | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Contains-Duplicate-II | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Contiguous-Array | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Continuous-Subarray-Sum | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Convert-1D-Array-Into-2D-Array | yes | yes | yes | yes | yes | 7 | 7 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Convert-A-Number-To-Hexadecimal | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Convert-Binary-Number-In-A-Linked-List-To-Integer | yes | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Copy-List-With-Random-Pointer-Lite | yes | yes | yes | yes | yes | 4 | 4 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Corporate-Flight-Bookings | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Cosine-Distance | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Cosine-Similarity | yes | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Count-And-Say | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Count-And-Say-Stub | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Count-Odd-Numbers-In-An-Interval | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Count-Of-Smaller-Numbers-After-Self-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Count-Operations-To-Obtain-Zero | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Count-Square-Submatrices-With-All-Ones | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Count-Sub-Islands | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Count-Triplets-That-Can-Form-Two-Arrays-Of-Equal-XOR | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Counting-Bits | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Covariance | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Crawler-Log-Folder | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Create-Maximum-Number-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Critical-Connections-In-A-Network-Lite | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Daily-Temperatures | yes | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Decode-Ways | yes | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Decode-Ways-Stub | yes | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Decode-XORed-Array | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Defanging-An-IP-Address | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Degree-Of-An-Array | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Delete-And-Earn | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Delete-And-Earn-Stub | yes | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Delete-Node-In-A-Linked-List | yes | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Delete-The-Middle-Node | yes | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Delta-Encoding | yes | yes | yes | yes | yes | 0 | 0 | proven | misc/Ada/Delta-Encoding |  |
| misc/SPARK2/Ada-SPARK-Deque-Bounded | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Design-A-Leaderboard | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Design-A-Stack-With-Increment | yes | yes | yes | yes | yes | 4 | 4 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Design-A-Stack-With-Increment-Operation | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Design-An-Ordered-Stream | yes | yes | yes | yes | yes | 4 | 4 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Design-Bitset | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Design-Browser-History | yes | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Design-Circular-Deque | yes | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Design-Circular-Queue | yes | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Design-Circular-Queue-Stub | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Design-Food-Rating-System | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Design-Front-Middle-Back-Queue | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Design-Front-Middle-Back-Queue-Stub | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Design-Hit-Counter-Lite | yes | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Design-Linked-List | yes | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Design-Number-Container-System | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Design-Ordered-Stream | yes | yes | yes | yes | yes | 4 | 4 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Design-Parking-System-II | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Design-Skiplist-Lite | yes | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Design-Twitter-Lite | yes | yes | yes | yes | yes | 3 | 3 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Design-Underground-System-Lite | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Detect-Capital | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Diagonal-Traverse | yes | yes | yes | yes | yes | 7 | 7 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Dice-Coefficient | yes | yes | yes | yes | yes | 0 | 0 | proven | misc/Ada/Dice-Coefficient |  |
| misc/SPARK2/Ada-SPARK-Difference-Array | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Different-Ways-To-Add-Parentheses-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Disjoint-Set-Forest | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Distinct-Subsequences | yes | yes | yes | yes | yes | 2 | 2 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Divisor-Game | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Domino-And-Tromino-Tiling-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Dot-Product | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Dungeon-Game-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Duplicate-Zeros | yes | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Dutch-National-Flag | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Earliest-Deadline-First-Scheduling | yes | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Elevator-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | proven | misc/Ada/Elevator-Algorithm |  |
| misc/SPARK2/Ada-SPARK-Eliminate-Maximum-Number-Of-Monsters | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Encode-And-Decode-TinyURL-Stub | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Euclidean-Distance | yes | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Eval-RPN | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Evaluate-Division-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Evaluate-Division-Stub | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Evaluate-Reverse-Polish-Notation | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Excel-Sheet-Column | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Excel-Sheet-Column-Number | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Excel-Sheet-Column-Title | yes | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Exclusive-Time-Of-Functions-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Factorial | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Factorial-Trailing-Zeroes | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Fair-Candy-Swap | yes | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Fast-Pow | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Fibonacci-DP | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Fibonacci-Number | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Final-Prices-With-A-Special-Discount | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Find-All-Duplicates-In-An-Array | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Find-All-Numbers-Disappeared | yes | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Find-Common-Characters | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Find-First-And-Last-Position | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Find-K-Closest-Elements | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Find-Median-Data-Stream-Stub | yes | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Find-Median-From-Data-Stream | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Find-Peak-Element | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Find-The-City | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Find-The-City-With-Smallest-Number-Of-Neighbors | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Find-The-Difference | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Find-The-Duplicate-Number | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Find-The-Original-Array-Of-Prefix-XOR | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Find-The-Smallest-Divisor | yes | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Find-The-Town-Judge | yes | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Find-Words-That-Can-Be-Formed | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| misc/SPARK2/Ada-SPARK-First-Bad-Version | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-First-Unique-Char | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-First-Unique-Character | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Fisher-Yates-Shuffle | yes | yes | yes | yes | yes | 0 | 0 | proven | misc/Ada/Fisher-Yates-Shuffle |  |
| misc/SPARK2/Ada-SPARK-Fixed-Point-Iteration | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Fizz-Buzz | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Flatten-Nested-List-Stub | yes | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Flipping-An-Image | yes | yes | yes | yes | yes | 5 | 5 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Flood-Fill | yes | yes | yes | yes | yes | 2 | 2 | proven | misc/Ada/Flood-Fill |  |
| misc/SPARK2/Ada-SPARK-Four-Sum | yes | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Fruit-Into-Baskets | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Game-Of-Life-Step | yes | yes | yes | yes | yes | 12 | 12 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Gas-Station | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Generate-Parentheses | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Get-Maximum-In-Generated-Array | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Goat-Latin | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Gray-Code | yes | yes | yes | yes | yes | 0 | 0 | proven | misc/Ada/Gray-Code |  |
| misc/SPARK2/Ada-SPARK-Greatest-Common-Divisor | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Group-Anagrams | yes | yes | yes | yes | yes | 5 | 5 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Group-Anagrams-Stub | yes | yes | yes | yes | yes | 5 | 5 | not run |  | misc/SPARK2/Ada-SPARK-Group-Anagrams (near-identical) |
| misc/SPARK2/Ada-SPARK-Grumpy-Bookstore-Owner | yes | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Guess-Number-Higher-Or-Lower | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Hamming-Code | yes | yes | yes | yes | yes | 0 | 0 | proven | misc/Ada/Hamming-Code |  |
| misc/SPARK2/Ada-SPARK-Hamming-Weight | yes | yes | yes | yes | yes | 0 | 0 | proven | misc/Ada/Hamming-Weight |  |
| misc/SPARK2/Ada-SPARK-Hand-Of-Straights-Stub | yes | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Happy-Number | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Heap-Push-Pop | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Heaters | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Height-Checker | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Histogram-Bin | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Hit-Counter-Stub | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Horner-Scheme | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| misc/SPARK2/Ada-SPARK-House-Robber | yes | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| misc/SPARK2/Ada-SPARK-House-Robber-II | yes | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| misc/SPARK2/Ada-SPARK-House-Robber-III-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-House-Robber-III-Stub | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| misc/SPARK2/Ada-SPARK-How-Many-Numbers-Are-Smaller | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-IPO-Lite | yes | yes | yes | yes | yes | 4 | 4 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Image-Smoother | yes | yes | yes | yes | yes | 8 | 8 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Implement-Queue-Using-Stacks | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Implement-Stack-Using-Queues | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Implement-StrStr | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Insert-Delete-GetRandom-O1 | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Insert-Interval | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Int-To-Roman-Stub | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Integer-Break | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Integer-To-English-Stub | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Integer-To-Roman | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Intersection-Of-Two-Arrays | yes | yes | yes | yes | yes | 4 | 4 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Intersection-Of-Two-Arrays-II | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Intersection-Of-Two-Linked-Lists | yes | yes | yes | yes | yes | 2 | 2 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Is-Palindrome | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Is-Subsequence | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Island-Perimeter | yes | yes | yes | yes | yes | 2 | 2 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Jaccard-Index | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Jump-Game | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Jump-Game-II | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-K-Closest-Points-Stub | yes | yes | yes | yes | yes | 1 | 1 | not run |  |  |
| misc/SPARK2/Ada-SPARK-K-Closest-Points-To-Origin | yes | yes | yes | yes | yes | 3 | 3 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Kadanes-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | not run | misc/Ada/Kadanes-Algorithm |  |
| misc/SPARK2/Ada-SPARK-Keyboard-Row | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Keys-And-Rooms | yes | yes | yes | yes | yes | 3 | 3 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Knapsack-01 | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Knight-Probability-In-Chessboard-Lite | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Koko-Eating-Bananas | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Kth-Largest-Array | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Kth-Largest-Element | yes | yes | yes | yes | yes | 1 | 1 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Kth-Largest-Element-In-A-Stream | yes | yes | yes | yes | yes | 2 | 2 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Kth-Largest-Element-In-An-Array | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Kth-Largest-In-Stream-Stub | yes | yes | yes | yes | yes | 1 | 1 | not run |  |  |
| misc/SPARK2/Ada-SPARK-L1-Norm | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-L2-Norm-Squared | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-LFU-Cache-Lite | yes | yes | yes | yes | yes | 6 | 6 | not run |  |  |
| misc/SPARK2/Ada-SPARK-LFU-Cache-Stub | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-LRU-Cache-Lite | yes | yes | yes | yes | yes | 4 | 4 | not run |  |  |
| misc/SPARK2/Ada-SPARK-LRU-Cache-Stub | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Largest-Number | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Largest-Rectangle-In-Histogram | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Last-Stone-Weight | yes | yes | yes | yes | yes | 2 | 2 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Last-Stone-Weight-II | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Least-Common-Multiple | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Lemonade-Change | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Length-Of-Last-Word | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Letter-Case-Permutation | yes | yes | yes | yes | yes | 1 | 1 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Letter-Combinations-Of-A-Phone-Number | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-License-Key-Formatting | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Line-Intersection | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Line-Reflection | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Linked-List-Cycle | yes | yes | yes | yes | yes | 5 | 5 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Linked-List-Cycle-II | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Logger-Rate-Limiter-Lite | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Logger-Rate-Limiter-Stub | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Longest-Increasing-Subsequence | yes | yes | yes | yes | yes | 2 | 2 | not run | misc/Ada/Longest-Increasing-Subsequence |  |
| misc/SPARK2/Ada-SPARK-Longest-Mountain-In-Array | yes | yes | yes | yes | yes | 1 | 1 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Longest-Ones | yes | yes | yes | yes | yes | 2 | 2 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Longest-Palindromic-Subsequence | yes | yes | yes | yes | yes | 2 | 2 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Longest-Repeating-Character-Replacement | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Longest-Word-In-Dictionary | yes | yes | yes | yes | yes | 3 | 3 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Magnetic-Force-Between-Two-Balls | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Majority-Element | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Majority-Element-II | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Manacher | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Manhattan-Distance | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Map-Sum-Pairs | yes | yes | yes | yes | yes | 3 | 3 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Mark-And-Sweep | yes | yes | yes | yes | yes | 2 | 2 | not run | misc/Ada/Mark-and-Sweep |  |
| misc/SPARK2/Ada-SPARK-Matchsticks-To-Square-Lite | yes | yes | yes | yes | yes | 2 | 2 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Max-Area-Of-Island | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Max-Consecutive-Ones | yes | yes | yes | yes | yes | 3 | 3 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Max-Consecutive-Ones-II | yes | yes | yes | yes | yes | 3 | 3 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Max-Consecutive-Ones-III | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Max-Heap | yes | yes | yes | yes | yes | 1 | 1 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Max-Path-Sum-Stub | yes | yes | yes | yes | yes | 6 | 6 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Max-Points-On-A-Line-Lite | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Max-Product-Subarray | yes | yes | yes | yes | yes | 2 | 2 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Max-Stack | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Max-Stack-Stub | yes | yes | yes | yes | yes | 1 | 1 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Maximal-Rectangle | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Maximal-Square | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Maximum-Candies-Allocated-To-K-Children | yes | yes | yes | yes | yes | 1 | 1 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Maximum-Ice-Cream-Bars | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Maximum-Points-You-Can-Obtain-From-Cards | yes | yes | yes | yes | yes | 2 | 2 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Maximum-Product-Of-Word-Lengths | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Maximum-Product-Subarray | yes | yes | yes | yes | yes | 1 | 1 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Maximum-Subarray | yes | yes | yes | yes | yes | 1 | 1 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Maximum-Subarray-Circular | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Maximum-Twin-Sum-Of-A-Linked-List | yes | yes | yes | yes | yes | 3 | 3 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Maximum-Units-On-A-Truck | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Maximum-XOR-Of-Two-Numbers | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Mean-Variance | yes | yes | yes | yes | yes | 1 | 1 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Median-Filtering | yes | yes | yes | yes | yes | 0 | 0 | not run | misc/Ada/Median-Filtering |  |
| misc/SPARK2/Ada-SPARK-Median-Of-Three | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Meeting-Rooms | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Meeting-Rooms-II | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Merge-In-Between-Linked-Lists | yes | yes | yes | yes | yes | 2 | 2 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Merge-Intervals | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Middle-Of-The-Linked-List | yes | yes | yes | yes | yes | 2 | 2 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Min-Cost-Climbing-Stairs | yes | yes | yes | yes | yes | 1 | 1 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Min-Cost-Connect-Cities-Stub | yes | yes | yes | yes | yes | 2 | 2 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Min-Cost-To-Connect-All-Points | yes | yes | yes | yes | yes | 4 | 4 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Min-Heap | yes | yes | yes | yes | yes | 1 | 1 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Min-Max-Normalize | yes | yes | yes | yes | yes | 1 | 1 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Min-Stack | yes | yes | yes | yes | yes | 1 | 1 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Minimum-ASCII-Delete-Sum | yes | yes | yes | yes | yes | 2 | 2 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Minimum-Bit-Flips-To-Convert-Number | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Minimum-Cost-To-Move-Chips | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Minimum-Deletions-To-Make-Character-Frequencies-Unique | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Minimum-Number-Of-Arrows | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Minimum-Number-Of-Days-To-Make-M-Bouquets | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Minimum-Number-Of-Moves-To-Seat | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Minimum-Operations-To-Make-The-Array-Increasing | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Minimum-Path-Sum | yes | yes | yes | yes | yes | 7 | 7 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Minimum-Sum-Of-Four-Digit-Number | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Missing-Number | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Missing-Ranges-Stub | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Monotonic-Stack | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Most-Common-Word | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Move-Zeroes | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Moving-Average | yes | yes | yes | yes | yes | 1 | 1 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Moving-Average-From-Data-Stream | yes | yes | yes | yes | yes | 1 | 1 | not run |  |  |
| misc/SPARK2/Ada-SPARK-My-Calendar-Stub | yes | yes | yes | yes | yes | 1 | 1 | not run |  |  |
| misc/SPARK2/Ada-SPARK-My-Linked-List-Stub | yes | yes | yes | yes | yes | 2 | 2 | not run |  |  |
| misc/SPARK2/Ada-SPARK-N-Queens-Lite | yes | yes | yes | yes | yes | 2 | 2 | not run |  |  |
| misc/SPARK2/Ada-SPARK-N-Repeated-Element-In-Size-2N-Array | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-N-th-Tribonacci | yes | yes | yes | yes | yes | 1 | 1 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Nearest-Exit-From-Entrance-In-Maze | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Neighboring-Bitwise-XOR | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Nested-Iterator-Stub | yes | yes | yes | yes | yes | 3 | 3 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Network-Delay-Time | yes | yes | yes | yes | yes | 2 | 2 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Network-Delay-Time-Stub | yes | yes | yes | yes | yes | 1 | 1 | not run |  |  |
| misc/SPARK2/Ada-SPARK-New-21-Game-Lite | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Next-Greater-Element-I | yes | yes | yes | yes | yes | 2 | 2 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Next-Greater-Element-II | yes | yes | yes | yes | yes | 2 | 2 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Next-Greater-Node-In-Linked-List | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Next-Permutation-Stub | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Nim-Game | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Non-Decreasing-Array | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Non-Overlapping-Intervals | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Nth-Digit | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Nth-Digit-Stub | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Nth-Ugly-Number | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Number-Complement | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Number-Of-1-Bits | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Number-Of-1-Bits-In-Range | yes | yes | yes | yes | yes | 1 | 1 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Number-Of-Connected-Components | yes | yes | yes | yes | yes | 1 | 1 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Number-Of-Good-Pairs | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Number-Of-Islands | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Number-Of-Provinces | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Number-Of-Recent-Calls | yes | yes | yes | yes | yes | 2 | 2 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Number-Of-Steps-To-Reduce-A-Number | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Number-Of-Steps-To-Reduce-A-Number-In-Binary-Representation | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-One-Hot | yes | yes | yes | yes | yes | 2 | 2 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Ones-And-Zeroes | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Online-Stock-Span | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Online-Stock-Span-Stub | yes | yes | yes | yes | yes | 2 | 2 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Open-The-Lock | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Ordered-Stream-Stub | yes | yes | yes | yes | yes | 2 | 2 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Out-Of-Boundary-Paths-Lite | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Overlap-Coefficient | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-PN-Counter | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Pacific-Atlantic-Water-Flow | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Pacific-Atlantic-Water-Stub | yes | yes | yes | yes | yes | 4 | 4 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Paint-Fence-Lite | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Paint-House-Lite | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Paint-House-Stub | yes | yes | yes | yes | yes | 7 | 7 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Palindrome-Linked-List | yes | yes | yes | yes | yes | 2 | 2 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Palindrome-Number | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Palindrome-Pairs-Lite | yes | yes | yes | yes | yes | 3 | 3 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Palindrome-Partitioning | yes | yes | yes | yes | yes | 4 | 4 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Palindrome-Partitioning-II | yes | yes | yes | yes | yes | 3 | 3 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Parity-Bits | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Parking-System-Stub | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Partition-Around-Pivot | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Partition-Equal-Subset-Sum | yes | yes | yes | yes | yes | 3 | 3 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Partition-Labels | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Partition-List | no | no | no | no | no | NA | NA | no SPARK |  |  |
| misc/SPARK2/Ada-SPARK-Pascal-Triangle | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Pascal-Triangle-II | yes | yes | yes | yes | yes | 1 | 1 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Path-Sum | yes | yes | yes | yes | yes | 7 | 7 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Path-Sum-III-Lite | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Path-With-Minimum-Effort | yes | yes | yes | yes | yes | 2 | 2 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Peak-Index-In-Mountain-Array | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Pearson-Correlation | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Peeking-Iterator-Stub | yes | yes | yes | yes | yes | 2 | 2 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Permutations | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Permutations-II | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Plus-One | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Population-Count | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Pow-X-N | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Pow-X-N-Stub | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Power-Of-Four | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Power-Of-Three | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Power-Of-Two | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Powx-N | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Prefix-Sums | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Prim-MST-Lite | yes | yes | yes | yes | yes | 2 | 2 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Priority-Queue-Binary-Heap | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Product-Except-Self | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Product-Of-Array-Except-Self | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Product-Of-Numbers-Stub | yes | yes | yes | yes | yes | 2 | 2 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Projection-Area-Of-3D-Shapes | yes | yes | yes | yes | yes | 3 | 3 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Queue-Reconstruction-By-Height | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Queue-Using-Stacks | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Random-Pick-With-Weight-Lite | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Randomized-Collection | yes | yes | yes | yes | yes | 3 | 3 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Randomized-Set | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Range-Addition | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Range-Module-Stub | yes | yes | yes | yes | yes | 2 | 2 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Range-Sum-Query | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Range-Sum-Query-2D-Immutable | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Range-Sum-Query-Immutable | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Ransom-Note | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Rate-Monotonic-Scheduling | yes | yes | yes | yes | yes | 2 | 2 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Ravenscar-Job-Pool | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Reach-A-Number | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Recent-Counter | yes | yes | yes | yes | yes | 2 | 2 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Rectangle-Area | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Rectangle-Overlap | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Reduce-Array-Size-To-The-Half | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Redundant-Connection | yes | yes | yes | yes | yes | 2 | 2 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Redundant-Connection-II | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Redundant-Connection-II-Lite | yes | yes | yes | yes | yes | 3 | 3 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Reference-Counting | yes | yes | yes | yes | yes | 2 | 2 | not run | misc/Ada/Reference-Counting |  |
| misc/SPARK2/Ada-SPARK-Regular-Expression-Matching-Lite | yes | yes | yes | yes | yes | 2 | 2 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Remove-All-Adjacent-Duplicates | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Remove-All-Adjacent-Duplicates-II | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Remove-Duplicate-Letters | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Remove-Element | yes | yes | yes | yes | yes | 1 | 1 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Remove-K-Digits | yes | yes | yes | yes | yes | 2 | 2 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Remove-Linked-List-Elements | yes | yes | yes | yes | yes | 2 | 2 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Remove-Nth-Node-From-End | yes | yes | yes | yes | yes | 2 | 2 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Reorder-List | yes | yes | yes | yes | yes | 3 | 3 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Replace-Elements-With-Greatest-On-Right | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Replace-Words | yes | yes | yes | yes | yes | 3 | 3 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Reservoir-Sampling | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Restore-IP-Addresses | yes | yes | yes | yes | yes | 1 | 1 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Reverse-Bits | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Reverse-Integer | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Reverse-Linked-List | yes | yes | yes | yes | yes | 2 | 2 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Reverse-Linked-List-II | no | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Reverse-Only-Letters | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Reverse-Pairs-Lite | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Reverse-Vowels | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Reverse-Words | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Ring-Buffer | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Robot-Return-To-Origin | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Roman-To-Int | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Roman-To-Integer | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Rotate-Array | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Rotate-Image | yes | yes | yes | yes | yes | 8 | 8 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Rotate-List | no | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Rotting-Oranges | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Round-Robin-Scheduling | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Seat-Manager-Stub | yes | yes | yes | yes | yes | 2 | 2 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Seat-Reservation-Manager | yes | yes | yes | yes | yes | 2 | 2 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Self-Dividing-Numbers | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Sequence-Reconstruction-Lite | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Shift-2D-Grid | yes | yes | yes | yes | yes | 8 | 8 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Shortest-Bridge | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Shortest-Common-Supersequence-Lite | yes | yes | yes | yes | yes | 2 | 2 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Shortest-Completing-Word | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Shortest-Job-Next | yes | yes | yes | yes | yes | 2 | 2 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Shortest-Remaining-Time | yes | yes | yes | yes | yes | 2 | 2 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Shortest-Word-Distance | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Sigmoid | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Simplify-Path-Stub | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Single-Number | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Single-Number-II | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Single-Number-III | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Sliding-Window-Max | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Sliding-Window-Maximum | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Sliding-Window-Median | yes | yes | yes | yes | yes | 1 | 1 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Smallest-Integer-Divisible-By-K | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Snapshot-Array-Stub | yes | yes | yes | yes | yes | 1 | 1 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Softmin | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Soup-Servings-Lite | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Spearman-Rank-Stub | yes | yes | yes | yes | yes | 1 | 1 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Special-Array-With-X-Elements | yes | yes | yes | yes | yes | 2 | 2 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Split-Array-Largest-Sum | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Sqrt-Integer | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Sqrt-X | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Sqrtx | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Stack-Bounded | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Stack-Using-Queues-Stub | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Standard-Score | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Stock-Spanner-Stub | yes | yes | yes | yes | yes | 1 | 1 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Stream-Of-Characters-Lite | yes | yes | yes | yes | yes | 4 | 4 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Strstr-Naive | yes | yes | yes | yes | yes | 1 | 1 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Student-Attendance-Record-I | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Subarray-Sum-Equals-K | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Subarrays-With-K-Different-Integers | yes | yes | yes | yes | yes | 3 | 3 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Subsets | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Subsets-Bitmask | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Subsets-II | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Subtract-Product-Sum-Digits | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Subtract-The-Product-And-Sum | yes | yes | yes | yes | yes | 2 | 2 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Sudoku-Solver-Lite | yes | yes | yes | yes | yes | 5 | 5 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Sum-Of-Left-Leaves | yes | yes | yes | yes | yes | 6 | 6 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Sum-Of-Subarray-Minimums | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Sum-Of-Two-Integers | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Sum-Root-To-Leaf-Numbers | yes | yes | yes | yes | yes | 1 | 1 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Summary-Ranges | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Super-Ugly-Number | yes | yes | yes | yes | yes | 1 | 1 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Super-Ugly-Number-Stub | yes | yes | yes | yes | yes | 1 | 1 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Surface-Area-Of-3D-Shapes | yes | yes | yes | yes | yes | 3 | 3 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Surrounded-Regions | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Swap-Nodes-In-Pairs | no | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| misc/SPARK2/Ada-SPARK-Swapping-Nodes-In-A-Linked-List | yes | yes | yes | yes | yes | 2 | 2 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Swim-In-Rising-Water | yes | yes | yes | yes | yes | 2 | 2 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Swim-In-Rising-Water-Stub | yes | yes | yes | yes | yes | 3 | 3 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Tanimoto | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Target-Sum | yes | yes | yes | yes | yes | 4 | 4 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Target-Sum-Stub | yes | yes | yes | yes | yes | 2 | 2 | not run |  |  |
| misc/SPARK2/Ada-SPARK-The-Skyline-Problem-Lite | yes | yes | yes | yes | yes | 2 | 2 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Third-Maximum-Number | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Three-Divisors | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Three-Sum | yes | yes | yes | yes | yes | 2 | 2 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Three-Sum-Closest-Stub | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Tic-Tac-Toe-Stub | yes | yes | yes | yes | yes | 12 | 12 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Time-Based-Key-Value-Store | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Time-Map-Stub | yes | yes | yes | yes | yes | 1 | 1 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Title-To-Number | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-To-Lower-Case | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Top-K-Frequent-Elements | yes | yes | yes | yes | yes | 1 | 1 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Top-K-Frequent-Stub | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Top-K-Frequent-Words | yes | yes | yes | yes | yes | 3 | 3 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Top-Nodes-Algorithm | yes | yes | yes | yes | yes | 2 | 2 | not run | misc/Ada/Top-Nodes-Algorithm |  |
| misc/SPARK2/Ada-SPARK-Trapezoidal-Rule | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Trapping-Rain-Water | yes | yes | yes | yes | yes | 2 | 2 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Trapping-Rain-Water-II-Lite | yes | yes | yes | yes | yes | 1 | 1 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Triangle | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Triangle-Min-Path | yes | yes | yes | yes | yes | 10 | 10 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Tribonacci | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Tribonacci-Number | yes | yes | yes | yes | yes | 1 | 1 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Tweet-Counts-Stub | yes | yes | yes | yes | yes | 2 | 2 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Two-City-Scheduling | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Two-Pointers-Sum | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Two-Sum | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-UTF-8-Validation | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Ugly-Number | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Ugly-Number-II | yes | yes | yes | yes | yes | 1 | 1 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Uncommon-Words-From-Two-Sentences | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Underground-System-Stub | yes | yes | yes | yes | yes | 1 | 1 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Union-Find | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Unique-Email-Addresses | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Unique-Morse-Code-Words | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Unique-Paths | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Unique-Paths-II | yes | yes | yes | yes | yes | 7 | 7 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Valid-Anagram | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Valid-IP-Address-Stub | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Valid-Number-Stub | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Valid-Palindrome | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Valid-Palindrome-II | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Valid-Parentheses | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Valid-Square | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Valid-Sudoku-Stub | yes | yes | yes | yes | yes | 8 | 8 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Valid-Word-Abbreviation | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Validate-Stack-Sequences | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Vector-2D-Stub | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Vector-Dot-Cross | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Water-Bottles | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Wiggle-Subsequence | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Wildcard-Matching-Lite | yes | yes | yes | yes | yes | 2 | 2 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Word-Break | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Word-Break-II | yes | yes | yes | yes | yes | 5 | 5 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Word-Break-Stub | yes | yes | yes | yes | yes | 3 | 3 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Word-Ladder-II-Lite | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Word-Ladder-Lite | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Word-Ladder-Stub | yes | yes | yes | yes | yes | 1 | 1 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Word-Pattern | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-XOR-Of-Numbers-Range | yes | yes | yes | yes | yes | 1 | 1 | not run |  |  |
| misc/SPARK2/Ada-SPARK-XOR-Operation-In-An-Array | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| misc/SPARK2/Ada-SPARK-Zigzag-Iterator-Stub | yes | yes | yes | yes | yes | 3 | 3 | not run |  |  |
| misc/SPARK4/Ada-SPARK-Accumulator | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| misc/SPARK4/Ada-SPARK-Blum-Blum-Shub | yes | yes | yes | yes | yes | 0 | 0 | proven | misc/Ada/Blum-Blum-Shub |  |
| misc/SPARK4/Ada-SPARK-Heaps-Algorithm | yes | yes | yes | yes | yes | 0 | 3 | proven | misc/Ada/Heaps-Algorithm |  |
| misc/SPARK4/Ada-SPARK-K-Way-Merge | yes | yes | yes | yes | yes | 0 | 0 | proven | misc/Ada/K-Way-Merge |  |
| misc/SPARK4/Ada-SPARK-Lagged-Fibonacci-Generator | yes | yes | yes | yes | yes | 0 | 0 | proven | misc/Ada/Lagged-Fibonacci-Generator |  |
| misc/SPARK4/Ada-SPARK-Lemke-Howson | yes | yes | yes | yes | yes | 0 | 0 | not run | misc/Ada/Lemke-Howson |  |
| misc/SPARK4/Ada-SPARK-Package-Merge-Algorithm | yes | yes | yes | yes | yes | 0 | 1 | 1 unproved | misc/Ada/Package-Merge-Algorithm |  |
| misc/SPARK4/Ada-SPARK-Selection-Algorithm | yes | yes | yes | yes | yes | 0 | 4 | proven | misc/Ada/Selection-Algorithm |  |
| misc/SPARK4/Ada-SPARK-Shortest-Seek-First | n/a | no | no | no | no | NA | NA | no SPARK |  |  |
| misc/SPARK4/demo | n/a | no | no | no | no | NA | NA | skipped (no SPARK_Mode) |  |  |
| ml/Ada/AdaBoost | yes | yes | yes | yes | yes | 1 | 0 | no SPARK |  |  |
| ml/Ada/Backpropagation | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| ml/Ada/Boosting-Meta-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| ml/Ada/BrownBoost | yes | yes | yes | yes | no | 1 | 0 | no SPARK |  |  |
| ml/Ada/Expectation-Maximization | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| ml/Ada/Forward-Backward | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| ml/Ada/Hidden-Markov-Model | yes | yes | yes | yes | yes | 0 | 1 | no SPARK |  |  |
| ml/Ada/LPBoost | yes | yes | yes | yes | no | 0 | 0 | not run |  |  |
| ml/Ada/LogitBoost | yes | yes | yes | yes | yes | 115 | 115 | no SPARK |  |  |
| ml/Ada/Naive-Bayes-Classifier | yes | yes | yes | yes | no | 0 | 0 | no SPARK |  |  |
| ml/Ada/Neural-Network | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| ml/Ada/Perceptron | yes | yes | yes | yes | no | 0 | 0 | no SPARK |  |  |
| ml/Ada/Policy-Iteration | yes | yes | yes | yes | yes | 0 | 3 | no SPARK |  |  |
| ml/Ada/Pulse-Coupled-Neural-Networks | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| ml/Ada/Q-Learning | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| ml/Ada/Random-Forest | no | yes | yes | yes | no | 0 | 0 | no SPARK |  |  |
| ml/Ada/Reinforcement-Learning | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| ml/Ada/Support-Vector-Machine | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| ml/Ada/Value-Iteration | yes | yes | yes | yes | yes | 0 | 3 | no SPARK |  |  |
| ml/Ada/Viterbi | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| ml/Ada/Winnow-Algorithm | yes | yes | yes | yes | yes | 17 | 17 | no SPARK |  |  |
| ml/SPARK2/Ada-SPARK-ReLU | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| ml/SPARK2/Ada-SPARK-Softmax | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| numerical/Ada/Arnoldi | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/BBP | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/BFGS | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/BKM | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/Biconjugate-Gradient | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/Bicubic-Interpolation | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/Bilinear-Interpolation | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/Binary-GCD | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/Birkhoff-Interpolation | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/Bisection-Method | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | numerical/SPARK2/Ada-SPARK-Bisection-Method |  |
| numerical/Ada/Bluesteins-FFT-Algorithm | yes | yes | yes | yes | yes | 28 | 28 | no SPARK |  |  |
| numerical/Ada/Borwein | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/Brents-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | numerical/SPARK4/Ada-SPARK-Brents-Algorithm |  |
| numerical/Ada/Bruuns-FFT-Algorithm | yes | yes | yes | yes | yes | 21 | 21 | no SPARK |  |  |
| numerical/Ada/CORDIC | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/Cantor-Zassenhaus | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/Chakravala | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/Chudnovsky | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/Cipolla | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/Conjugate-Gradient | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/Cooley-Tukey-FFT-Algorithm | yes | yes | yes | yes | yes | 11 | 11 | no SPARK | numerical/SPARK2/Ada-SPARK-Cooley-Tukey-FFT |  |
| numerical/Ada/Cubic-Interpolation | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/Dixon | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/Euclidean-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | numerical/SPARK4/Ada-SPARK-Euclidean-Algorithm |  |
| numerical/Ada/Extended-Euclidean-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | numerical/SPARK2/Ada-SPARK-Extended-Euclidean numerical/SPARK4/Ada-SPARK-Extended-Euclidean-Algorithm |  |
| numerical/Ada/Fast-Fourier-Transform | yes | yes | yes | yes | yes | 6 | 6 | no SPARK |  |  |
| numerical/Ada/Fermat-Primality-Test | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/Furer | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/Gauss-Legendre | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/Gauss-Newton | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/General-Number-Field-Sieve | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/Gradient-Descent | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/Hermite-Interpolation | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/Hybrid-Monte-Carlo | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/Interior-Point-Method | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/Karatsuba | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/Lagrange-Interpolation | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | numerical/SPARK2/Ada-SPARK-Lagrange-Interpolation |  |
| numerical/Ada/Lanczos | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/Lanczos-Resampling | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/Levenberg-Marquardt | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/Linear-Congruential-Generator | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | numerical/SPARK4/Ada-SPARK-Linear-Congruential-Generator |  |
| numerical/Ada/Linear-Interpolation | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/Lucas-Primality-Test | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/MISER | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/Mersenne-Twister | yes | yes | yes | yes | yes | 6 | 8 | no SPARK | numerical/SPARK4/Ada-SPARK-Mersenne-Twister |  |
| numerical/Ada/Metropolis-Hastings | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/Metropolis-Light-Transport | yes | yes | yes | yes | yes | 1 | 1 | no SPARK |  |  |
| numerical/Ada/Miller-Rabin | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/Monotone-Cubic-Interpolation | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/Multivariate-Interpolation | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/Nearest-Neighbor-Interpolation | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/Neville | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/Newells-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/Newton-Raphson-Division | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/Pareto-Interpolation | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/Partial-Least-Squares | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/Pollards-Kangaroo-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/Pollards-P-1 | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/Pollards-Rho | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/Pollards-Rho-Logarithms | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/Polynomial-Interpolation | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/Primality-Test | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/Prime-Factor-FFT-Algorithm | yes | yes | yes | yes | yes | 24 | 24 | no SPARK |  |  |
| numerical/Ada/Prime-Factorization | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/Quadratic-Sieve | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/Raders-FFT-Algorithm | yes | yes | yes | yes | yes | 27 | 27 | no SPARK |  |  |
| numerical/Ada/Runge-Kutta | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/Secant-Method | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | numerical/SPARK2/Ada-SPARK-Secant-Method |  |
| numerical/Ada/Sieve-Of-Atkin | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/Sieve-Of-Eratosthenes | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | numerical/SPARK2/Ada-SPARK-Sieve-Of-Eratosthenes |  |
| numerical/Ada/Sieve-Of-Sundaram | yes | yes | yes | yes | yes | 5 | 5 | no SPARK |  |  |
| numerical/Ada/Special-Number-Field-Sieve | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/Spline-Interpolation | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/Tonelli-Shanks | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/Tricubic-Interpolation | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/Ada/Trigonometric-Interpolation | yes | yes | yes | yes | yes | 13 | 13 | no SPARK |  |  |
| numerical/Ada/Ziggurat-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| numerical/SPARK2/Ada-SPARK-Bisection-Method | yes | yes | yes | yes | yes | 0 | 0 | proven | numerical/Ada/Bisection-Method |  |
| numerical/SPARK2/Ada-SPARK-Chebyshev-Distance | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| numerical/SPARK2/Ada-SPARK-Cooley-Tukey-FFT | yes | yes | yes | yes | yes | 0 | 0 | proven | numerical/Ada/Cooley-Tukey-FFT-Algorithm |  |
| numerical/SPARK2/Ada-SPARK-Count-Primes | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| numerical/SPARK2/Ada-SPARK-Count-Primes-Stub | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| numerical/SPARK2/Ada-SPARK-Extended-Euclidean | yes | yes | yes | yes | yes | 0 | 0 | proven | numerical/Ada/Extended-Euclidean-Algorithm |  |
| numerical/SPARK2/Ada-SPARK-Lagrange-Interpolation | yes | yes | yes | yes | yes | 0 | 0 | proven | numerical/Ada/Lagrange-Interpolation |  |
| numerical/SPARK2/Ada-SPARK-Maximum-Performance-Of-A-Team-Lite | yes | yes | yes | yes | yes | 4 | 4 | proven |  |  |
| numerical/SPARK2/Ada-SPARK-Minimum-Limit-Of-Balls-In-A-Bag | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| numerical/SPARK2/Ada-SPARK-Modular-Exponentiation | yes | yes | yes | yes | yes | 0 | 2 | proven |  |  |
| numerical/SPARK2/Ada-SPARK-Newton-Raphson | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| numerical/SPARK2/Ada-SPARK-Perfect-Number | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| numerical/SPARK2/Ada-SPARK-Perfect-Squares | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| numerical/SPARK2/Ada-SPARK-Prime-Check | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| numerical/SPARK2/Ada-SPARK-Prime-Number-Of-Set-Bits | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| numerical/SPARK2/Ada-SPARK-Prime-Number-Of-Set-Bits-In-Binary-Representation | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| numerical/SPARK2/Ada-SPARK-Secant-Method | yes | yes | yes | yes | yes | 0 | 0 | proven | numerical/Ada/Secant-Method |  |
| numerical/SPARK2/Ada-SPARK-Sieve-Of-Eratosthenes | yes | yes | yes | yes | yes | 0 | 0 | proven | numerical/Ada/Sieve-Of-Eratosthenes |  |
| numerical/SPARK2/Ada-SPARK-Simpson-Rule | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| numerical/SPARK2/Ada-SPARK-Successful-Pairs-Of-Spells-And-Potions | yes | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| numerical/SPARK2/Ada-SPARK-Valid-Perfect-Square | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| numerical/SPARK2/Ada-SPARK-Walls-And-Gates | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| numerical/SPARK4/Ada-SPARK-Brents-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | not run | numerical/Ada/Brents-Algorithm |  |
| numerical/SPARK4/Ada-SPARK-Euclidean-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | not run | numerical/Ada/Euclidean-Algorithm |  |
| numerical/SPARK4/Ada-SPARK-Extended-Euclidean-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | not run | numerical/Ada/Extended-Euclidean-Algorithm |  |
| numerical/SPARK4/Ada-SPARK-Linear-Congruential-Generator | yes | yes | yes | yes | yes | 0 | 0 | not run | numerical/Ada/Linear-Congruential-Generator |  |
| numerical/SPARK4/Ada-SPARK-Mersenne-Twister | yes | yes | yes | yes | yes | 0 | 0 | not run | numerical/Ada/Mersenne-Twister |  |
| numerical/SPARK4/Ada-SPARK-Modular-Arithmetic | yes | yes | yes | yes | yes | 0 | 0 | not run |  |  |
| parsing/Ada/Canonical-LR-Parser | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| parsing/Ada/GLR-Parser | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| parsing/Ada/LALR | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| parsing/Ada/LL-Parser | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| parsing/Ada/LR-Parser | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| parsing/Ada/Operator-Precedence-Parser | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| parsing/Ada/Packrat-Parser | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| parsing/Ada/Pratt-Parser | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| parsing/Ada/Recursive-Descent-Parser | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| parsing/Ada/Shunting-Yard-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| parsing/Ada/Simple-LR-Parser | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| parsing/Ada/Simple-Precdence-Parser | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| parsing/Ada/Simplex-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| parsing/Ada/Step-Parser | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| parsing/SPARK2/Ada-SPARK-Sparse-Set | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| parsing/SPARK2/Ada-SPARK-Sparse-Vector-Dot-Stub | yes | yes | yes | yes | yes | 5 | 5 | proven |  |  |
| searching/Ada/Best-First-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| searching/Ada/Bidirectional-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| searching/Ada/Binary-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | searching/SPARK4/Ada-SPARK-Binary-Search |  |
| searching/Ada/Breadth-First-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| searching/Ada/Brute-Force-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| searching/Ada/Chien-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| searching/Ada/Depth-First-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| searching/Ada/Eytzinger-Binary-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| searching/Ada/Fibonacci-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | searching/SPARK4/Ada-SPARK-Fibonacci-Search |  |
| searching/Ada/Golden-Section-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| searching/Ada/Grid-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| searching/Ada/Harmony-Search | yes | yes | yes | yes | yes | 0 | 2 | no SPARK |  |  |
| searching/Ada/Hyperlink-Induced-Topic-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| searching/Ada/Interpolation-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | searching/SPARK4/Ada-SPARK-Interpolation-Search |  |
| searching/Ada/Introselect | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | searching/SPARK4/Ada-SPARK-Introselect |  |
| searching/Ada/Iterative-Deepening-Depth-First-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| searching/Ada/Jump-Point-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| searching/Ada/Jump-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | searching/SPARK4/Ada-SPARK-Jump-Search |  |
| searching/Ada/Lexicographic-Breadth-First-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| searching/Ada/Line-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| searching/Ada/Linear-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | searching/SPARK4/Ada-SPARK-Linear-Search |  |
| searching/Ada/Local-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| searching/Ada/Monte-Carlo-Tree-Search | yes | yes | yes | yes | yes | 0 | 1 | no SPARK |  |  |
| searching/Ada/Nearest-Neighbor-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| searching/Ada/Quantum-Walk-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| searching/Ada/Quickselect | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | searching/SPARK4/Ada-SPARK-Quickselect |  |
| searching/Ada/Random-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| searching/Ada/Substring-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| searching/Ada/Tabu-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| searching/Ada/Ternary-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | searching/SPARK4/Ada-SPARK-Ternary-Search |  |
| searching/Ada/Trigram-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | searching/SPARK2/Ada-SPARK-Trigram-Search |  |
| searching/Ada/Uniform-Binary-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| searching/Ada/Uniform-Cost-Search | yes | no | no | yes | no | 4 | 4 | no SPARK | searching/SPARK4/Ada-SPARK-Uniform-Cost-Search |  |
| searching/SPARK2/Ada-SPARK-Binary-Search-Lower-Bound | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| searching/SPARK2/Ada-SPARK-Binary-Search-Upper-Bound | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| searching/SPARK2/Ada-SPARK-Design-Add-And-Search-Words | yes | yes | yes | yes | yes | 3 | 3 | proven |  |  |
| searching/SPARK2/Ada-SPARK-Exponential-Search | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| searching/SPARK2/Ada-SPARK-Increasing-Order-Search-Tree | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| searching/SPARK2/Ada-SPARK-Insert-Into-A-Binary-Search-Tree | yes | yes | yes | yes | yes | 8 | 8 | proven |  |  |
| searching/SPARK2/Ada-SPARK-Naive-String-Search | yes | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| searching/SPARK2/Ada-SPARK-Search-2D-Matrix | yes | yes | yes | yes | yes | 4 | 4 | proven |  |  |
| searching/SPARK2/Ada-SPARK-Search-A-2D-Matrix | yes | yes | yes | yes | yes | 9 | 9 | proven |  |  |
| searching/SPARK2/Ada-SPARK-Search-A-2D-Matrix-II | yes | yes | yes | yes | yes | 9 | 9 | proven |  |  |
| searching/SPARK2/Ada-SPARK-Search-In-A-Binary-Search-Tree | yes | yes | yes | yes | yes | 9 | 9 | proven |  |  |
| searching/SPARK2/Ada-SPARK-Search-Insert-Position | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| searching/SPARK2/Ada-SPARK-Trigram-Search | yes | yes | yes | yes | yes | 0 | 0 | proven | searching/Ada/Trigram-Search |  |
| searching/SPARK2/Ada-SPARK-Trim-A-Binary-Search-Tree | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| searching/SPARK2/Ada-SPARK-Unique-Binary-Search-Trees | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| searching/SPARK2/Ada-SPARK-Unique-Binary-Search-Trees-II-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| searching/SPARK2/Ada-SPARK-Validate-Binary-Search-Tree | yes | yes | yes | yes | yes | 6 | 6 | proven |  |  |
| searching/SPARK2/Ada-SPARK-Word-Search | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| searching/SPARK2/Ada-SPARK-Word-Search-II-Lite | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| searching/SPARK4/Ada-SPARK-Binary-Search | yes | yes | yes | yes | yes | 0 | 0 | not run | searching/Ada/Binary-Search |  |
| searching/SPARK4/Ada-SPARK-Fibonacci-Search | yes | yes | yes | yes | yes | 0 | 0 | not run | searching/Ada/Fibonacci-Search |  |
| searching/SPARK4/Ada-SPARK-Interpolation-Search | yes | yes | yes | yes | yes | 0 | 0 | not run | searching/Ada/Interpolation-Search |  |
| searching/SPARK4/Ada-SPARK-Introselect | yes | yes | yes | yes | yes | 0 | 5 | not run | searching/Ada/Introselect |  |
| searching/SPARK4/Ada-SPARK-Jump-Search | yes | yes | yes | yes | yes | 0 | 0 | not run | searching/Ada/Jump-Search |  |
| searching/SPARK4/Ada-SPARK-Linear-Search | yes | yes | yes | yes | yes | 0 | 0 | not run | searching/Ada/Linear-Search |  |
| searching/SPARK4/Ada-SPARK-Quickselect | yes | yes | yes | yes | yes | 0 | 4 | not run | searching/Ada/Quickselect |  |
| searching/SPARK4/Ada-SPARK-Ternary-Search | yes | yes | yes | yes | yes | 0 | 0 | not run | searching/Ada/Ternary-Search |  |
| searching/SPARK4/Ada-SPARK-Uniform-Cost-Search | yes | yes | yes | yes | yes | 0 | 0 | not run | searching/Ada/Uniform-Cost-Search |  |
| sorting/Ada/Bitonic-Sorter | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | sorting/SPARK4/Ada-SPARK-Bitonic-Sorter |  |
| sorting/Ada/Bogosort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | sorting/SPARK4/Ada-SPARK-Bogosort |  |
| sorting/Ada/Bubble-Sort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | sorting/SPARK4/Ada-SPARK-Bubble-Sort |  |
| sorting/Ada/Bucket-Sort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | sorting/SPARK4/Ada-SPARK-Bucket-Sort |  |
| sorting/Ada/Burstsort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | sorting/SPARK4/Ada-SPARK-Burstsort |  |
| sorting/Ada/Cocktail-Shaker-Sort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | sorting/SPARK4/Ada-SPARK-Cocktail-Shaker-Sort |  |
| sorting/Ada/Comb-Sort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | sorting/SPARK4/Ada-SPARK-Comb-Sort |  |
| sorting/Ada/Counting-Sort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | sorting/SPARK4/Ada-SPARK-Counting-Sort |  |
| sorting/Ada/Cycle-Sort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | sorting/SPARK4/Ada-SPARK-Cycle-Sort |  |
| sorting/Ada/Flashsort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | sorting/SPARK2/Ada-SPARK-Flash-Sort sorting/SPARK4/Ada-SPARK-Flashsort |  |
| sorting/Ada/Gnome-Sort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | sorting/SPARK4/Ada-SPARK-Gnome-Sort |  |
| sorting/Ada/Heapsort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | sorting/SPARK2/Ada-SPARK-Heap-Sort sorting/SPARK4/Ada-SPARK-Heapsort |  |
| sorting/Ada/Insertion-Sort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | sorting/SPARK4/Ada-SPARK-Insertion-Sort |  |
| sorting/Ada/Introsort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | sorting/SPARK2/Ada-SPARK-Intro-Sort sorting/SPARK4/Ada-SPARK-Introsort |  |
| sorting/Ada/Library-Sort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | sorting/SPARK4/Ada-SPARK-Library-Sort |  |
| sorting/Ada/Merge-Sort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | sorting/SPARK4/Ada-SPARK-Merge-Sort |  |
| sorting/Ada/Odd-Even-Sort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | sorting/SPARK4/Ada-SPARK-Odd-Even-Sort |  |
| sorting/Ada/Pancake-Sorting | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | sorting/SPARK4/Ada-SPARK-Pancake-Sorting |  |
| sorting/Ada/Patience-Sorting | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | sorting/SPARK4/Ada-SPARK-Patience-Sorting |  |
| sorting/Ada/Pigeonhole-Sort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | sorting/SPARK4/Ada-SPARK-Pigeonhole-Sort |  |
| sorting/Ada/Postman-Sort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | sorting/SPARK4/Ada-SPARK-Postman-Sort |  |
| sorting/Ada/Quantum-Sort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | sorting/SPARK4/Ada-SPARK-Quantum-Sort |  |
| sorting/Ada/Quicksort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | sorting/SPARK2/Ada-SPARK-Quick-Sort sorting/SPARK4/Ada-SPARK-Quicksort |  |
| sorting/Ada/Radix-Sort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | sorting/SPARK4/Ada-SPARK-Radix-Sort |  |
| sorting/Ada/Samplesort | yes | yes | yes | yes | yes | 7 | 7 | no SPARK | sorting/SPARK4/Ada-SPARK-Samplesort |  |
| sorting/Ada/Selection-Sort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | sorting/SPARK4/Ada-SPARK-Selection-Sort |  |
| sorting/Ada/Shell-Sort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | sorting/SPARK4/Ada-SPARK-Shell-Sort |  |
| sorting/Ada/Slowsort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | sorting/SPARK4/Ada-SPARK-Slowsort |  |
| sorting/Ada/Smoothsort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | sorting/SPARK2/Ada-SPARK-Smooth-Sort sorting/SPARK4/Ada-SPARK-Smoothsort |  |
| sorting/Ada/Sort-Merge-Join | yes | no | no | yes | no | 24 | 24 | no SPARK | sorting/SPARK4/Ada-SPARK-Sort-Merge-Join |  |
| sorting/Ada/Sorted-List | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | sorting/SPARK4/Ada-SPARK-Sorted-List |  |
| sorting/Ada/Spaghetti-Sort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | sorting/SPARK4/Ada-SPARK-Spaghetti-Sort |  |
| sorting/Ada/Stooge-Sort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | sorting/SPARK4/Ada-SPARK-Stooge-Sort |  |
| sorting/Ada/Strand-Sort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | sorting/SPARK4/Ada-SPARK-Strand-Sort |  |
| sorting/Ada/Timsort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | sorting/SPARK2/Ada-SPARK-Tim-Sort sorting/SPARK4/Ada-SPARK-Timsort |  |
| sorting/Ada/Topological-Sort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | sorting/SPARK4/Ada-SPARK-Topological-Sort |  |
| sorting/Ada/Tournament-Selection | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| sorting/Ada/Tree-Sort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | sorting/SPARK4/Ada-SPARK-Tree-Sort |  |
| sorting/SPARK2/Ada-SPARK-Bitonic-Sort | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| sorting/SPARK2/Ada-SPARK-Block-Sort | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| sorting/SPARK2/Ada-SPARK-Circle-Sort | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| sorting/SPARK2/Ada-SPARK-Cocktail-Sort | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| sorting/SPARK2/Ada-SPARK-Convert-Sorted-Array-To-BST | yes | yes | yes | yes | yes | 7 | 7 | proven |  |  |
| sorting/SPARK2/Ada-SPARK-Count-Negative-Numbers-In-A-Sorted-Matrix | yes | yes | yes | yes | yes | 5 | 5 | proven |  |  |
| sorting/SPARK2/Ada-SPARK-Count-Sorted-Vowel-Strings | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| sorting/SPARK2/Ada-SPARK-Exchange-Sort | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| sorting/SPARK2/Ada-SPARK-Find-Median-Sorted-Arrays-Lite | yes | yes | yes | yes | yes | 5 | 5 | proven |  |  |
| sorting/SPARK2/Ada-SPARK-Find-Minimum-In-Rotated-Sorted-Array | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| sorting/SPARK2/Ada-SPARK-Find-Minimum-In-Rotated-Sorted-Array-II | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| sorting/SPARK2/Ada-SPARK-Flash-Sort | yes | yes | yes | yes | yes | 1 | 1 | proven | sorting/Ada/Flashsort |  |
| sorting/SPARK2/Ada-SPARK-Heap-Sort | yes | yes | yes | yes | yes | 1 | 1 | proven | sorting/Ada/Heapsort |  |
| sorting/SPARK2/Ada-SPARK-Intro-Sort | yes | yes | yes | yes | yes | 1 | 1 | proven | sorting/Ada/Introsort |  |
| sorting/SPARK2/Ada-SPARK-Kth-Smallest-Element-In-A-Sorted-Matrix | yes | yes | yes | yes | yes | 8 | 8 | proven |  |  |
| sorting/SPARK2/Ada-SPARK-Median-Of-Two-Sorted-Arrays-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| sorting/SPARK2/Ada-SPARK-Merge-K-Sorted-Lists-Stub | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| sorting/SPARK2/Ada-SPARK-Merge-Sorted-Array | yes | yes | yes | yes | yes | 4 | 4 | proven |  |  |
| sorting/SPARK2/Ada-SPARK-Merge-Sorted-Arrays | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| sorting/SPARK2/Ada-SPARK-Merge-Two-Sorted-Lists | yes | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| sorting/SPARK2/Ada-SPARK-Odd-Even-Linked-List | no | no | no | no | no | NA | NA | no SPARK |  |  |
| sorting/SPARK2/Ada-SPARK-Odd-Even-Merge-Sort | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| sorting/SPARK2/Ada-SPARK-Pancake-Sort | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| sorting/SPARK2/Ada-SPARK-Patience-Sort | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| sorting/SPARK2/Ada-SPARK-Quick-Sort | yes | yes | yes | yes | yes | 1 | 1 | proven | sorting/Ada/Quicksort |  |
| sorting/SPARK2/Ada-SPARK-Relative-Sort-Array | yes | yes | yes | yes | yes | 4 | 4 | proven |  |  |
| sorting/SPARK2/Ada-SPARK-Remove-Duplicates-From-Sorted-Array | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| sorting/SPARK2/Ada-SPARK-Remove-Duplicates-From-Sorted-Array-II | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| sorting/SPARK2/Ada-SPARK-Remove-Duplicates-From-Sorted-List | no | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| sorting/SPARK2/Ada-SPARK-Remove-Duplicates-From-Sorted-List-II | no | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| sorting/SPARK2/Ada-SPARK-Remove-Duplicates-Sorted | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| sorting/SPARK2/Ada-SPARK-Search-In-Rotated-Sorted-Array | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| sorting/SPARK2/Ada-SPARK-Search-In-Rotated-Sorted-Array-II | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| sorting/SPARK2/Ada-SPARK-Shaker-Sort | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| sorting/SPARK2/Ada-SPARK-Shortest-Unsorted-Continuous-Subarray | yes | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| sorting/SPARK2/Ada-SPARK-Smooth-Sort | yes | yes | yes | yes | yes | 1 | 1 | proven | sorting/Ada/Smoothsort |  |
| sorting/SPARK2/Ada-SPARK-Sort-An-Array | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| sorting/SPARK2/Ada-SPARK-Sort-Array-By-Parity | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| sorting/SPARK2/Ada-SPARK-Sort-Array-By-Parity-II | yes | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| sorting/SPARK2/Ada-SPARK-Sort-Characters-By-Frequency | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| sorting/SPARK2/Ada-SPARK-Sort-Colors | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| sorting/SPARK2/Ada-SPARK-Sort-Integers-By-The-Number-Of-1-Bits | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| sorting/SPARK2/Ada-SPARK-Sort-List-Lite | no | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| sorting/SPARK2/Ada-SPARK-Sorted-Array-To-BST | yes | yes | yes | yes | yes | 9 | 9 | proven |  |  |
| sorting/SPARK2/Ada-SPARK-Squares-Of-A-Sorted-Array | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| sorting/SPARK2/Ada-SPARK-Tim-Sort | yes | yes | yes | yes | yes | 1 | 1 | proven | sorting/Ada/Timsort |  |
| sorting/SPARK2/Ada-SPARK-Tim-Sort-Stub | yes | yes | yes | yes | yes | 1 | 1 | proven |  | sorting/SPARK2/Ada-SPARK-Tim-Sort (near-identical) |
| sorting/SPARK2/Ada-SPARK-Topological-Sort-Lite | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| sorting/SPARK2/Ada-SPARK-Tournament-Sort | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| sorting/SPARK2/Ada-SPARK-Two-Sum-II-Input-Array-Is-Sorted | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| sorting/SPARK2/Ada-SPARK-Wiggle-Sort | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| sorting/SPARK4/Ada-SPARK-Bitonic-Sorter | yes | yes | yes | yes | yes | 0 | 6 | not run | sorting/Ada/Bitonic-Sorter |  |
| sorting/SPARK4/Ada-SPARK-Bogosort | yes | yes | yes | yes | yes | 0 | 0 | not run | sorting/Ada/Bogosort |  |
| sorting/SPARK4/Ada-SPARK-Bubble-Sort | yes | yes | yes | yes | yes | 0 | 0 | not run | sorting/Ada/Bubble-Sort |  |
| sorting/SPARK4/Ada-SPARK-Bucket-Sort | yes | yes | yes | yes | yes | 0 | 8 | not run | sorting/Ada/Bucket-Sort |  |
| sorting/SPARK4/Ada-SPARK-Burstsort | yes | yes | yes | yes | yes | 0 | 9 | not run | sorting/Ada/Burstsort |  |
| sorting/SPARK4/Ada-SPARK-Cocktail-Shaker-Sort | yes | yes | yes | yes | yes | 0 | 0 | not run | sorting/Ada/Cocktail-Shaker-Sort |  |
| sorting/SPARK4/Ada-SPARK-Comb-Sort | yes | yes | yes | yes | yes | 0 | 2 | not run | sorting/Ada/Comb-Sort |  |
| sorting/SPARK4/Ada-SPARK-Counting-Sort | no | yes | yes | yes | yes | 0 | 6 | not run | sorting/Ada/Counting-Sort |  |
| sorting/SPARK4/Ada-SPARK-Cycle-Sort | yes | yes | yes | yes | yes | 0 | 0 | not run | sorting/Ada/Cycle-Sort |  |
| sorting/SPARK4/Ada-SPARK-Flashsort | yes | yes | yes | yes | yes | 0 | 2 | not run | sorting/Ada/Flashsort |  |
| sorting/SPARK4/Ada-SPARK-Gnome-Sort | yes | yes | yes | yes | yes | 0 | 2 | not run | sorting/Ada/Gnome-Sort |  |
| sorting/SPARK4/Ada-SPARK-Heapsort | yes | yes | yes | yes | yes | 0 | 3 | not run | sorting/Ada/Heapsort |  |
| sorting/SPARK4/Ada-SPARK-Insertion-Sort | yes | yes | yes | yes | yes | 0 | 2 | not run | sorting/Ada/Insertion-Sort |  |
| sorting/SPARK4/Ada-SPARK-Introsort | yes | yes | yes | yes | yes | 0 | 6 | not run | sorting/Ada/Introsort |  |
| sorting/SPARK4/Ada-SPARK-Library-Sort | yes | yes | yes | yes | yes | 0 | 11 | not run | sorting/Ada/Library-Sort |  |
| sorting/SPARK4/Ada-SPARK-Merge-Sort | yes | yes | yes | yes | yes | 0 | 4 | not run | sorting/Ada/Merge-Sort |  |
| sorting/SPARK4/Ada-SPARK-Odd-Even-Sort | yes | yes | yes | yes | yes | 0 | 0 | not run | sorting/Ada/Odd-Even-Sort |  |
| sorting/SPARK4/Ada-SPARK-Pancake-Sorting | yes | yes | yes | yes | yes | 0 | 0 | not run | sorting/Ada/Pancake-Sorting |  |
| sorting/SPARK4/Ada-SPARK-Patience-Sorting | yes | yes | yes | yes | yes | 0 | 0 | proven | sorting/Ada/Patience-Sorting |  |
| sorting/SPARK4/Ada-SPARK-Pigeonhole-Sort | yes | yes | yes | yes | yes | 0 | 2 | proven | sorting/Ada/Pigeonhole-Sort |  |
| sorting/SPARK4/Ada-SPARK-Postman-Sort | yes | yes | yes | yes | yes | 0 | 1 | proven | sorting/Ada/Postman-Sort |  |
| sorting/SPARK4/Ada-SPARK-Quantum-Sort | yes | yes | yes | yes | yes | 0 | 2 | proven | sorting/Ada/Quantum-Sort |  |
| sorting/SPARK4/Ada-SPARK-Quicksort | yes | yes | yes | yes | yes | 0 | 1 | proven | sorting/Ada/Quicksort |  |
| sorting/SPARK4/Ada-SPARK-Radix-Sort | yes | yes | yes | yes | yes | 0 | 6 | proven | sorting/Ada/Radix-Sort |  |
| sorting/SPARK4/Ada-SPARK-Samplesort | yes | yes | yes | yes | yes | 0 | 3 | proven | sorting/Ada/Samplesort |  |
| sorting/SPARK4/Ada-SPARK-Selection-Sort | yes | yes | yes | yes | yes | 0 | 0 | proven | sorting/Ada/Selection-Sort |  |
| sorting/SPARK4/Ada-SPARK-Shell-Sort | yes | yes | yes | yes | yes | 0 | 2 | proven | sorting/Ada/Shell-Sort |  |
| sorting/SPARK4/Ada-SPARK-Slowsort | yes | yes | yes | yes | yes | 0 | 1 | proven | sorting/Ada/Slowsort |  |
| sorting/SPARK4/Ada-SPARK-Smoothsort | yes | yes | yes | yes | yes | 0 | 2 | proven | sorting/Ada/Smoothsort |  |
| sorting/SPARK4/Ada-SPARK-Sort-Merge-Join | yes | yes | yes | yes | yes | 0 | 0 | proven | sorting/Ada/Sort-Merge-Join |  |
| sorting/SPARK4/Ada-SPARK-Sorted-List | yes | yes | yes | yes | yes | 0 | 0 | proven | sorting/Ada/Sorted-List |  |
| sorting/SPARK4/Ada-SPARK-Spaghetti-Sort | yes | yes | yes | yes | yes | 0 | 0 | proven | sorting/Ada/Spaghetti-Sort |  |
| sorting/SPARK4/Ada-SPARK-Stooge-Sort | yes | yes | yes | yes | yes | 0 | 1 | proven | sorting/Ada/Stooge-Sort |  |
| sorting/SPARK4/Ada-SPARK-Strand-Sort | yes | yes | yes | yes | yes | 0 | 8 | proven | sorting/Ada/Strand-Sort |  |
| sorting/SPARK4/Ada-SPARK-Timsort | yes | yes | yes | yes | yes | 0 | 6 | proven | sorting/Ada/Timsort |  |
| sorting/SPARK4/Ada-SPARK-Topological-Sort | yes | yes | yes | yes | yes | 0 | 0 | proven | sorting/Ada/Topological-Sort |  |
| sorting/SPARK4/Ada-SPARK-Tree-Sort | yes | yes | yes | yes | yes | 0 | 3 | proven | sorting/Ada/Tree-Sort |  |
| strings/Ada/Boyer-Moore | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | strings/SPARK2/Ada-SPARK-Boyer-Moore |  |
| strings/Ada/Boyer-Moore-Horspool | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| strings/Ada/Daitch-Mokotoff-Soundex | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| strings/Ada/Damerau-Levenshtein-Distance | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | strings/SPARK2/Ada-SPARK-Damerau-Levenshtein-Distance |  |
| strings/Ada/Double-Metaphone | yes | yes | yes | yes | yes | 0 | 1 | no SPARK |  |  |
| strings/Ada/Hamming-Distance | yes | yes | yes | yes | yes | 4 | 4 | no SPARK | strings/SPARK2/Ada-SPARK-Hamming-Distance |  |
| strings/Ada/Jaro-Winkler-Distance | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| strings/Ada/Karplus-Strong-String-Synthesis | yes | yes | yes | yes | yes | 4 | 4 | no SPARK |  |  |
| strings/Ada/Knuth-Morris-Pratt | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | strings/SPARK2/Ada-SPARK-Knuth-Morris-Pratt |  |
| strings/Ada/Levenshtein-Coding | yes | yes | yes | yes | yes | 1 | 1 | no SPARK |  |  |
| strings/Ada/Levenshtein-Distance | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| strings/Ada/Longest-Common-Subsequence | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | strings/SPARK2/Ada-SPARK-Longest-Common-Subsequence |  |
| strings/Ada/Metaphone | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| strings/Ada/NYSIIS | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| strings/Ada/Needleman-Wunsch | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| strings/Ada/Rabin-Karp | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | strings/SPARK2/Ada-SPARK-Rabin-Karp |  |
| strings/Ada/Smith-Waterman | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| strings/Ada/Soundex | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| strings/Ada/Stemming | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| strings/Ada/String-Metrics | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| strings/SPARK2/Ada-SPARK-Bounded-String-Builder | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| strings/SPARK2/Ada-SPARK-Boyer-Moore | yes | yes | yes | yes | yes | 2 | 2 | proven | strings/Ada/Boyer-Moore |  |
| strings/SPARK2/Ada-SPARK-Check-If-Two-String-Arrays-Are-Equivalent | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| strings/SPARK2/Ada-SPARK-Count-The-Number-Of-Consistent-Strings | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| strings/SPARK2/Ada-SPARK-Damerau-Levenshtein-Distance | yes | yes | yes | yes | yes | 0 | 0 | proven | strings/Ada/Damerau-Levenshtein-Distance |  |
| strings/SPARK2/Ada-SPARK-Decode-String | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| strings/SPARK2/Ada-SPARK-Decode-String-Stub | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| strings/SPARK2/Ada-SPARK-Delete-Operation-For-Two-Strings | yes | yes | yes | yes | yes | 2 | 2 | tool crash |  |  |
| strings/SPARK2/Ada-SPARK-Edit-Distance | yes | yes | yes | yes | yes | 4 | 4 | proven |  |  |
| strings/SPARK2/Ada-SPARK-Encode-And-Decode-Strings-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| strings/SPARK2/Ada-SPARK-Find-All-Anagrams-In-A-String | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| strings/SPARK2/Ada-SPARK-First-Unique-Character-In-A-String | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| strings/SPARK2/Ada-SPARK-Hamming-Distance | yes | yes | yes | yes | yes | 0 | 0 | proven | strings/Ada/Hamming-Distance |  |
| strings/SPARK2/Ada-SPARK-Isomorphic-Strings | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| strings/SPARK2/Ada-SPARK-Knuth-Morris-Pratt | yes | yes | yes | yes | yes | 0 | 0 | 1 unproved | strings/Ada/Knuth-Morris-Pratt |  |
| strings/SPARK2/Ada-SPARK-Longest-Common-Prefix | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| strings/SPARK2/Ada-SPARK-Longest-Common-Subsequence | yes | yes | yes | yes | yes | 0 | 0 | tool crash | strings/Ada/Longest-Common-Subsequence |  |
| strings/SPARK2/Ada-SPARK-Make-The-String-Great | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| strings/SPARK2/Ada-SPARK-Multiply-Strings-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| strings/SPARK2/Ada-SPARK-Multiply-Strings-Stub | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| strings/SPARK2/Ada-SPARK-Number-Of-Lines-To-Write-String | yes | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| strings/SPARK2/Ada-SPARK-One-Edit-Distance | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| strings/SPARK2/Ada-SPARK-Permutation-In-String | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| strings/SPARK2/Ada-SPARK-Rabin-Karp | yes | yes | yes | yes | yes | 0 | 0 | 1 unproved | strings/Ada/Rabin-Karp |  |
| strings/SPARK2/Ada-SPARK-Remove-All-Adjacent-Duplicates-In-String | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| strings/SPARK2/Ada-SPARK-Reorganize-String | yes | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| strings/SPARK2/Ada-SPARK-Reorganize-String-Stub | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| strings/SPARK2/Ada-SPARK-Repeated-String-Match | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| strings/SPARK2/Ada-SPARK-Reverse-String | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| strings/SPARK2/Ada-SPARK-Reverse-String-II | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| strings/SPARK2/Ada-SPARK-Reverse-Vowels-Of-A-String | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| strings/SPARK2/Ada-SPARK-Reverse-Words-In-A-String | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| strings/SPARK2/Ada-SPARK-Reverse-Words-In-A-String-III | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| strings/SPARK2/Ada-SPARK-Rotate-String | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| strings/SPARK2/Ada-SPARK-String-To-Integer-Atoi | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| strings/SPARK2/Ada-SPARK-String-To-Integer-Atoi-Stub | yes | yes | yes | yes | yes | 0 | 0 | proven |  | strings/SPARK2/Ada-SPARK-String-To-Integer-Atoi (near-identical) |
| strings/SPARK2/Ada-SPARK-Sum-Of-Digits-Of-String-After-Convert | yes | yes | yes | yes | yes | 4 | 4 | proven |  |  |
| strings/SPARK2/Ada-SPARK-Total-Hamming-Distance | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| strings/SPARK2/Ada-SPARK-Z-Algorithm | yes | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| trees/Ada/Abstract-Syntax-Tree | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| trees/Ada/Context-Tree-Weighting | yes | yes | yes | yes | yes | 5 | 5 | no SPARK |  |  |
| trees/Ada/Decision-Trees | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |
| trees/Ada/Embedded-Zerotree-Wavelet | yes | yes | yes | yes | yes | 30 | 30 | no SPARK |  |  |
| trees/Ada/Longest-Common-Substring | yes | yes | yes | yes | yes | 0 | 0 | no SPARK | trees/SPARK2/Ada-SPARK-Longest-Common-Substring |  |
| trees/Ada/Red-Black-Tree | yes | yes | yes | yes | yes | 3 | 3 | no SPARK | trees/SPARK2/Ada-SPARK-Red-Black-Tree |  |
| trees/Ada/Set-Partitioning-In-Hierarchical-Trees | yes | yes | yes | yes | yes | 40 | 40 | no SPARK |  |  |
| trees/SPARK2/Ada-SPARK-BST-Iterator-Stub | yes | yes | yes | yes | yes | 3 | 3 | proven |  |  |
| trees/SPARK2/Ada-SPARK-Balanced-Binary-Tree | yes | yes | yes | yes | yes | 6 | 6 | proven |  |  |
| trees/SPARK2/Ada-SPARK-Binary-Tree-Inorder | yes | yes | yes | yes | yes | 9 | 9 | proven |  |  |
| trees/SPARK2/Ada-SPARK-Binary-Tree-Level-Order | yes | yes | yes | yes | yes | 9 | 9 | proven |  |  |
| trees/SPARK2/Ada-SPARK-Binary-Tree-Max-Depth | yes | yes | yes | yes | yes | 7 | 7 | proven |  |  |
| trees/SPARK2/Ada-SPARK-Binary-Tree-Min-Depth | yes | yes | yes | yes | yes | 7 | 7 | proven |  |  |
| trees/SPARK2/Ada-SPARK-Binary-Tree-Paths | yes | yes | yes | yes | yes | 4 | 4 | proven |  |  |
| trees/SPARK2/Ada-SPARK-Binary-Tree-Postorder | yes | yes | yes | yes | yes | 6 | 6 | proven |  |  |
| trees/SPARK2/Ada-SPARK-Binary-Tree-Preorder | yes | yes | yes | yes | yes | 9 | 9 | proven |  |  |
| trees/SPARK2/Ada-SPARK-Binary-Tree-Right-Side-View | yes | yes | yes | yes | yes | 3 | 3 | proven |  |  |
| trees/SPARK2/Ada-SPARK-Construct-Binary-Tree-From-Inorder-And-Postorder-Lite | yes | yes | yes | yes | yes | 9 | 9 | proven |  |  |
| trees/SPARK2/Ada-SPARK-Construct-Binary-Tree-From-Preorder-And-Inorder-Lite | yes | yes | yes | yes | yes | 9 | 9 | proven |  |  |
| trees/SPARK2/Ada-SPARK-Convert-BST-To-Greater-Tree | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| trees/SPARK2/Ada-SPARK-Count-Binary-Substrings | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| trees/SPARK2/Ada-SPARK-Count-Complete-Tree-Nodes | yes | yes | yes | yes | yes | 4 | 4 | proven |  |  |
| trees/SPARK2/Ada-SPARK-Delete-Node-BST-Stub | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| trees/SPARK2/Ada-SPARK-Delete-Node-In-A-BST-Lite | yes | yes | yes | yes | yes | 8 | 8 | proven |  |  |
| trees/SPARK2/Ada-SPARK-Diameter-Of-Binary-Tree | yes | yes | yes | yes | yes | 7 | 7 | proven |  |  |
| trees/SPARK2/Ada-SPARK-Find-Mode-In-BST | yes | yes | yes | yes | yes | 4 | 4 | proven |  |  |
| trees/SPARK2/Ada-SPARK-Flatten-Binary-Tree-To-Linked-List-Lite | yes | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| trees/SPARK2/Ada-SPARK-Get-Equal-Substrings-Within-Budget | yes | yes | yes | yes | yes | 3 | 3 | proven |  |  |
| trees/SPARK2/Ada-SPARK-Implement-Trie | yes | yes | yes | yes | yes | 3 | 3 | proven |  |  |
| trees/SPARK2/Ada-SPARK-Insert-Into-BST | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| trees/SPARK2/Ada-SPARK-Invert-Binary-Tree | yes | yes | yes | yes | yes | 5 | 5 | proven |  |  |
| trees/SPARK2/Ada-SPARK-Kth-Smallest-BST-Stub | yes | yes | yes | yes | yes | 5 | 5 | proven |  |  |
| trees/SPARK2/Ada-SPARK-Leaf-Similar-Trees | yes | yes | yes | yes | yes | 3 | 3 | proven |  |  |
| trees/SPARK2/Ada-SPARK-Longest-Common-Substring | yes | yes | yes | yes | yes | 0 | 0 | proven | trees/Ada/Longest-Common-Substring |  |
| trees/SPARK2/Ada-SPARK-Longest-Palindromic-Substring | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| trees/SPARK2/Ada-SPARK-Longest-Substring-Without-Repeat | yes | yes | yes | yes | yes | 3 | 3 | proven |  |  |
| trees/SPARK2/Ada-SPARK-Longest-Substring-Without-Repeating | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| trees/SPARK2/Ada-SPARK-Lowest-Common-Ancestor-BST | yes | yes | yes | yes | yes | 4 | 4 | proven |  |  |
| trees/SPARK2/Ada-SPARK-Lowest-Common-Ancestor-Of-BST | yes | yes | yes | yes | yes | 4 | 4 | proven |  |  |
| trees/SPARK2/Ada-SPARK-Maximum-Binary-Tree | yes | yes | yes | yes | yes | 7 | 7 | proven |  |  |
| trees/SPARK2/Ada-SPARK-Maximum-Depth-Of-Binary-Tree | yes | yes | yes | yes | yes | 6 | 6 | proven |  |  |
| trees/SPARK2/Ada-SPARK-Maximum-Depth-Of-N-Ary-Tree | yes | yes | yes | yes | yes | 9 | 9 | proven |  |  |
| trees/SPARK2/Ada-SPARK-Merge-Two-Binary-Trees | yes | yes | yes | yes | yes | 4 | 4 | proven |  |  |
| trees/SPARK2/Ada-SPARK-Minimum-Depth-Of-Binary-Tree | yes | yes | yes | yes | yes | 6 | 6 | proven |  |  |
| trees/SPARK2/Ada-SPARK-Minimum-Height-Trees | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| trees/SPARK2/Ada-SPARK-Minimum-Window-Substring | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| trees/SPARK2/Ada-SPARK-N-Ary-Tree-Level-Order-Traversal | yes | yes | yes | yes | yes | 11 | 11 | proven |  |  |
| trees/SPARK2/Ada-SPARK-N-Ary-Tree-Postorder-Traversal | yes | yes | yes | yes | yes | 12 | 12 | proven |  |  |
| trees/SPARK2/Ada-SPARK-N-Ary-Tree-Preorder-Traversal | yes | yes | yes | yes | yes | 11 | 11 | proven |  |  |
| trees/SPARK2/Ada-SPARK-Number-Of-Substrings-Containing-All-Three-Characters | yes | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| trees/SPARK2/Ada-SPARK-Range-Sum-BST | yes | yes | yes | yes | yes | 5 | 5 | proven |  |  |
| trees/SPARK2/Ada-SPARK-Range-Sum-Of-BST | yes | yes | yes | yes | yes | 10 | 10 | proven |  |  |
| trees/SPARK2/Ada-SPARK-Red-Black-Tree | yes | yes | yes | yes | yes | 0 | 0 | proven | trees/Ada/Red-Black-Tree |  |
| trees/SPARK2/Ada-SPARK-Repeated-Substring-Pattern | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| trees/SPARK2/Ada-SPARK-Same-Tree | yes | yes | yes | yes | yes | 6 | 6 | proven |  |  |
| trees/SPARK2/Ada-SPARK-Subtree-Of-Another-Tree | yes | yes | yes | yes | yes | 5 | 5 | proven |  |  |
| trees/SPARK2/Ada-SPARK-Symmetric-Tree | yes | yes | yes | yes | yes | 7 | 7 | proven |  |  |
| trees/SPARK2/Ada-SPARK-Trim-BST-Stub | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| trees/SPARK2/Ada-SPARK-Two-Sum-BST-Stub | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| trees/SPARK2/Ada-SPARK-Unique-BSTs-Stub | yes | yes | yes | yes | yes | 0 | 0 | proven |  |  |
| trees/SPARK2/Ada-SPARK-Unique-Paths-With-Obstacles | yes | yes | yes | yes | yes | 2 | 2 | proven |  |  |
| trees/SPARK2/Ada-SPARK-Univalued-Binary-Tree | yes | yes | yes | yes | yes | 1 | 1 | proven |  |  |
| trees/SPARK2/Ada-SPARK-Validate-BST-Stub | yes | yes | yes | yes | yes | 7 | 7 | proven |  |  |
