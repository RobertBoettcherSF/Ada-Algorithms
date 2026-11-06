# Folder catalog

Written by `make proof-index` (tools/vv/run_proof_index.py); do not edit by hand. Generated from [`PROOFS.csv`](PROOFS.csv): one row per folder, duplicates counted once (a row with `duplicate_of` set is omitted, the same rule as the README). Every count below is computed from those rows. Silver is the `silver` text; Training-ready is `training_ready`; Stub is `stub`; Needs implementation is `implement_next`; Open findings is `open_findings`. The topic index sums Open findings.

## Topic index

| Topic | Folders | Ada | SPARK2 | SPARK3 | SPARK4 | Training-ready | Stub | Needs implementation | Open findings |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| [clustering](#clustering) | 16 | 15 | 1 | 0 | 0 | 1 | 0 | 0 | 0 |
| [compression](#compression) | 30 | 22 | 7 | 1 | 0 | 2 | 0 | 0 | 0 |
| [concurrency](#concurrency) | 17 | 9 | 8 | 0 | 0 | 0 | 2 | 2 | 0 |
| [cryptography](#cryptography) | 33 | 29 | 4 | 0 | 0 | 0 | 3 | 3 | 0 |
| [geometry](#geometry) | 50 | 47 | 3 | 0 | 0 | 1 | 0 | 0 | 0 |
| [graphs](#graphs) | 48 | 30 | 15 | 0 | 3 | 2 | 3 | 3 | 0 |
| [hashing](#hashing) | 18 | 10 | 8 | 0 | 0 | 0 | 2 | 2 | 0 |
| [logic](#logic) | 7 | 7 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| [matrices](#matrices) | 27 | 11 | 16 | 0 | 0 | 2 | 0 | 0 | 0 |
| [misc](#misc) | 1122 | 511 | 600 | 0 | 11 | 76 | 89 | 89 | 0 |
| [ml](#ml) | 25 | 22 | 3 | 0 | 0 | 0 | 0 | 0 | 0 |
| [numerical](#numerical) | 108 | 78 | 23 | 0 | 7 | 2 | 1 | 1 | 0 |
| [parsing](#parsing) | 18 | 15 | 3 | 0 | 0 | 0 | 1 | 1 | 0 |
| [searching](#searching) | 64 | 34 | 20 | 0 | 10 | 0 | 3 | 3 | 0 |
| [sorting](#sorting) | 129 | 39 | 52 | 0 | 38 | 3 | 12 | 12 | 0 |
| [strings](#strings) | 61 | 21 | 39 | 1 | 0 | 2 | 3 | 3 | 0 |
| [trees](#trees) | 65 | 8 | 57 | 0 | 0 | 0 | 9 | 9 | 0 |
| All | 1838 | 908 | 859 | 2 | 69 | 91 | 128 | 128 | 0 |

Silver (duplicates counted once): proven 931, no SPARK 882, not built 11, tool crash 8, timeout 3, 25 unproved 1, 8 unproved 1, skipped (no SPARK_Mode) 1.

## Training-ready

**91 folders** with `training_ready` = yes (duplicates counted once).

| folder path | Silver | Training-ready | Stub | Needs implementation | Open findings |
|---|---|---|---|---|---|
| [clustering/SPARK2/K-Means-Step](clustering/SPARK2/K-Means-Step) | proven | yes |  |  |  |
| [compression/SPARK2/Ada-SPARK-Interleaving-String](compression/SPARK2/Ada-SPARK-Interleaving-String) | proven | yes |  |  |  |
| [compression/SPARK2/Burrows-Wheeler-Transform](compression/SPARK2/Burrows-Wheeler-Transform) | proven | yes |  |  |  |
| [geometry/SPARK2/Ada-SPARK-Point-In-Polygon](geometry/SPARK2/Ada-SPARK-Point-In-Polygon) | proven | yes |  |  |  |
| [graphs/SPARK2/Ada-SPARK-Find-If-Path-Exists-In-Graph](graphs/SPARK2/Ada-SPARK-Find-If-Path-Exists-In-Graph) | proven | yes |  |  |  |
| [graphs/SPARK2/Ada-SPARK-Number-Of-Islands-DFS](graphs/SPARK2/Ada-SPARK-Number-Of-Islands-DFS) | proven | yes |  |  |  |
| [matrices/SPARK2/Ada-SPARK-Gaussian-Elimination](matrices/SPARK2/Ada-SPARK-Gaussian-Elimination) | proven | yes |  |  |  |
| [matrices/SPARK2/Ada-SPARK-Num-Matrix-Block-Sum](matrices/SPARK2/Ada-SPARK-Num-Matrix-Block-Sum) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Add-Binary](misc/SPARK2/Ada-SPARK-Add-Binary) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Add-Without-Plus](misc/SPARK2/Ada-SPARK-Add-Without-Plus) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Beautiful-Arrangement](misc/SPARK2/Ada-SPARK-Beautiful-Arrangement) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Best-Time-To-Buy-And-Sell-Stock](misc/SPARK2/Ada-SPARK-Best-Time-To-Buy-And-Sell-Stock) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Broken-Calculator](misc/SPARK2/Ada-SPARK-Broken-Calculator) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Bulb-Switcher](misc/SPARK2/Ada-SPARK-Bulb-Switcher) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Bump-Arena](misc/SPARK2/Ada-SPARK-Bump-Arena) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Capacity-To-Ship-Packages](misc/SPARK2/Ada-SPARK-Capacity-To-Ship-Packages) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Car-Pooling](misc/SPARK2/Ada-SPARK-Car-Pooling) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Circular-Queue](misc/SPARK2/Ada-SPARK-Circular-Queue) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Combination-Sum-II](misc/SPARK2/Ada-SPARK-Combination-Sum-II) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Combination-Sum-III](misc/SPARK2/Ada-SPARK-Combination-Sum-III) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Combination-Sum-IV](misc/SPARK2/Ada-SPARK-Combination-Sum-IV) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Container-With-Most-Water](misc/SPARK2/Ada-SPARK-Container-With-Most-Water) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Cosine-Distance](misc/SPARK2/Ada-SPARK-Cosine-Distance) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Count-Odd-Numbers-In-An-Interval](misc/SPARK2/Ada-SPARK-Count-Odd-Numbers-In-An-Interval) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Count-Of-Smaller-Numbers-After-Self-Lite](misc/SPARK2/Ada-SPARK-Count-Of-Smaller-Numbers-After-Self-Lite) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Count-Operations-To-Obtain-Zero](misc/SPARK2/Ada-SPARK-Count-Operations-To-Obtain-Zero) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Covariance](misc/SPARK2/Ada-SPARK-Covariance) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Decode-Ways](misc/SPARK2/Ada-SPARK-Decode-Ways) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Defanging-An-IP-Address](misc/SPARK2/Ada-SPARK-Defanging-An-IP-Address) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Degree-Of-An-Array](misc/SPARK2/Ada-SPARK-Degree-Of-An-Array) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Delete-And-Earn](misc/SPARK2/Ada-SPARK-Delete-And-Earn) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Deque-Bounded](misc/SPARK2/Ada-SPARK-Deque-Bounded) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Design-A-Stack-With-Increment-Operation](misc/SPARK2/Ada-SPARK-Design-A-Stack-With-Increment-Operation) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Design-Underground-System-Lite](misc/SPARK2/Ada-SPARK-Design-Underground-System-Lite) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Different-Ways-To-Add-Parentheses-Lite](misc/SPARK2/Ada-SPARK-Different-Ways-To-Add-Parentheses-Lite) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Domino-And-Tromino-Tiling-Lite](misc/SPARK2/Ada-SPARK-Domino-And-Tromino-Tiling-Lite) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Dutch-National-Flag](misc/SPARK2/Ada-SPARK-Dutch-National-Flag) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Fast-Pow](misc/SPARK2/Ada-SPARK-Fast-Pow) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Find-Median-From-Data-Stream](misc/SPARK2/Ada-SPARK-Find-Median-From-Data-Stream) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-First-Unique-Character](misc/SPARK2/Ada-SPARK-First-Unique-Character) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Gray-Code](misc/SPARK2/Ada-SPARK-Gray-Code) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Group-Anagrams](misc/SPARK2/Ada-SPARK-Group-Anagrams) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-House-Robber-II](misc/SPARK2/Ada-SPARK-House-Robber-II) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-House-Robber-III-Lite](misc/SPARK2/Ada-SPARK-House-Robber-III-Lite) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Image-Smoother](misc/SPARK2/Ada-SPARK-Image-Smoother) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-LFU-Cache-Lite](misc/SPARK2/Ada-SPARK-LFU-Cache-Lite) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Largest-Rectangle-In-Histogram](misc/SPARK2/Ada-SPARK-Largest-Rectangle-In-Histogram) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Longest-Ones](misc/SPARK2/Ada-SPARK-Longest-Ones) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Longest-Word-In-Dictionary](misc/SPARK2/Ada-SPARK-Longest-Word-In-Dictionary) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Majority-Element](misc/SPARK2/Ada-SPARK-Majority-Element) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Maximum-Points-You-Can-Obtain-From-Cards](misc/SPARK2/Ada-SPARK-Maximum-Points-You-Can-Obtain-From-Cards) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Maximum-Product-Subarray](misc/SPARK2/Ada-SPARK-Maximum-Product-Subarray) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Maximum-Subarray](misc/SPARK2/Ada-SPARK-Maximum-Subarray) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Mean-Variance](misc/SPARK2/Ada-SPARK-Mean-Variance) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Median-Filtering](misc/SPARK2/Ada-SPARK-Median-Filtering) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Minimum-Path-Sum](misc/SPARK2/Ada-SPARK-Minimum-Path-Sum) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Missing-Number](misc/SPARK2/Ada-SPARK-Missing-Number) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Nth-Digit-Stub](misc/SPARK2/Ada-SPARK-Nth-Digit-Stub) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-PN-Counter](misc/SPARK2/Ada-SPARK-PN-Counter) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Paint-Fence-Lite](misc/SPARK2/Ada-SPARK-Paint-Fence-Lite) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Palindrome-Partitioning](misc/SPARK2/Ada-SPARK-Palindrome-Partitioning) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Partition-Around-Pivot](misc/SPARK2/Ada-SPARK-Partition-Around-Pivot) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Permutations-II](misc/SPARK2/Ada-SPARK-Permutations-II) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Pow-X-N](misc/SPARK2/Ada-SPARK-Pow-X-N) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Product-Of-Array-Except-Self](misc/SPARK2/Ada-SPARK-Product-Of-Array-Except-Self) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Reach-A-Number](misc/SPARK2/Ada-SPARK-Reach-A-Number) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Reverse-Linked-List-II](misc/SPARK2/Ada-SPARK-Reverse-Linked-List-II) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Roman-To-Int](misc/SPARK2/Ada-SPARK-Roman-To-Int) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Rotate-List](misc/SPARK2/Ada-SPARK-Rotate-List) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Shortest-Word-Distance](misc/SPARK2/Ada-SPARK-Shortest-Word-Distance) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Special-Array-With-X-Elements](misc/SPARK2/Ada-SPARK-Special-Array-With-X-Elements) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Sqrt-Integer](misc/SPARK2/Ada-SPARK-Sqrt-Integer) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Sqrt-X](misc/SPARK2/Ada-SPARK-Sqrt-X) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Stack-Bounded](misc/SPARK2/Ada-SPARK-Stack-Bounded) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Subsets](misc/SPARK2/Ada-SPARK-Subsets) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Subsets-II](misc/SPARK2/Ada-SPARK-Subsets-II) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Sum-Of-Subarray-Minimums](misc/SPARK2/Ada-SPARK-Sum-Of-Subarray-Minimums) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Swap-Nodes-In-Pairs](misc/SPARK2/Ada-SPARK-Swap-Nodes-In-Pairs) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Tanimoto](misc/SPARK2/Ada-SPARK-Tanimoto) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Third-Maximum-Number](misc/SPARK2/Ada-SPARK-Third-Maximum-Number) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Top-K-Frequent-Words](misc/SPARK2/Ada-SPARK-Top-K-Frequent-Words) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Trapping-Rain-Water](misc/SPARK2/Ada-SPARK-Trapping-Rain-Water) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Ugly-Number-II](misc/SPARK2/Ada-SPARK-Ugly-Number-II) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Unique-Paths-II](misc/SPARK2/Ada-SPARK-Unique-Paths-II) | proven | yes |  |  |  |
| [numerical/SPARK4/Ada-SPARK-Extended-Euclidean-Algorithm](numerical/SPARK4/Ada-SPARK-Extended-Euclidean-Algorithm) | proven | yes |  |  |  |
| [numerical/SPARK4/Binary-Gcd](numerical/SPARK4/Binary-Gcd) | proven | yes |  |  |  |
| [sorting/SPARK2/Ada-SPARK-Cocktail-Sort](sorting/SPARK2/Ada-SPARK-Cocktail-Sort) | proven | yes |  |  |  |
| [sorting/SPARK2/Ada-SPARK-Merge-Sorted-Arrays](sorting/SPARK2/Ada-SPARK-Merge-Sorted-Arrays) | proven | yes |  |  |  |
| [sorting/SPARK2/Ada-SPARK-Wiggle-Sort](sorting/SPARK2/Ada-SPARK-Wiggle-Sort) | proven | yes |  |  |  |
| [strings/SPARK2/Ada-SPARK-Bounded-String-Builder](strings/SPARK2/Ada-SPARK-Bounded-String-Builder) | proven | yes |  |  |  |
| [strings/SPARK2/Ada-SPARK-Hamming-Distance](strings/SPARK2/Ada-SPARK-Hamming-Distance) | proven | yes |  |  |  |

## clustering

**16 folders.**

### clustering/Ada

**15 folders.**

| folder path | Silver | Training-ready | Stub | Needs implementation | Open findings |
|---|---|---|---|---|---|
| [clustering/Ada/Average-Linkage-Clustering](clustering/Ada/Average-Linkage-Clustering) | no SPARK |  |  |  |  |
| [clustering/Ada/Canopy-Clustering](clustering/Ada/Canopy-Clustering) | no SPARK |  |  |  |  |
| [clustering/Ada/Clustering](clustering/Ada/Clustering) | no SPARK |  |  |  |  |
| [clustering/Ada/Clustering-Algorithms](clustering/Ada/Clustering-Algorithms) | no SPARK |  |  |  |  |
| [clustering/Ada/Complete-Linkage-Clustering](clustering/Ada/Complete-Linkage-Clustering) | no SPARK |  |  |  |  |
| [clustering/Ada/DBSCAN](clustering/Ada/DBSCAN) | no SPARK |  |  |  |  |
| [clustering/Ada/FLAME-Clustering](clustering/Ada/FLAME-Clustering) | no SPARK |  |  |  |  |
| [clustering/Ada/Fuzzy-Clustering](clustering/Ada/Fuzzy-Clustering) | no SPARK |  |  |  |  |
| [clustering/Ada/K-Means-Clustering](clustering/Ada/K-Means-Clustering) | no SPARK |  |  |  |  |
| [clustering/Ada/K-Means-Plus-Plus](clustering/Ada/K-Means-Plus-Plus) | no SPARK |  |  |  |  |
| [clustering/Ada/Lloyds-Algorithm](clustering/Ada/Lloyds-Algorithm) | no SPARK |  |  |  |  |
| [clustering/Ada/OPTICS](clustering/Ada/OPTICS) | no SPARK |  |  |  |  |
| [clustering/Ada/Single-Linkage-Clustering](clustering/Ada/Single-Linkage-Clustering) | no SPARK |  |  |  |  |
| [clustering/Ada/WACA-Clustering](clustering/Ada/WACA-Clustering) | no SPARK |  |  |  |  |
| [clustering/Ada/Wards-Method](clustering/Ada/Wards-Method) | no SPARK |  |  |  |  |

### clustering/SPARK2

**1 folder.**

| folder path | Silver | Training-ready | Stub | Needs implementation | Open findings |
|---|---|---|---|---|---|
| [clustering/SPARK2/K-Means-Step](clustering/SPARK2/K-Means-Step) | proven | yes |  |  |  |

## compression

**30 folders.**

### compression/Ada

**22 folders.**

| folder path | Silver | Training-ready | Stub | Needs implementation | Open findings |
|---|---|---|---|---|---|
| [compression/Ada/Adaptive-Huffman](compression/Ada/Adaptive-Huffman) | no SPARK |  |  |  |  |
| [compression/Ada/Arithmetic-Coding](compression/Ada/Arithmetic-Coding) | no SPARK |  |  |  |  |
| [compression/Ada/Audio-Compression](compression/Ada/Audio-Compression) | no SPARK |  |  |  |  |
| [compression/Ada/Berlekamp-Massey-Algorithm](compression/Ada/Berlekamp-Massey-Algorithm) | no SPARK |  |  |  |  |
| [compression/Ada/Berlekamp-Root-Finding](compression/Ada/Berlekamp-Root-Finding) | no SPARK |  |  |  |  |
| [compression/Ada/Burrows-Wheeler-Transform](compression/Ada/Burrows-Wheeler-Transform) | no SPARK |  |  |  |  |
| [compression/Ada/Deflate](compression/Ada/Deflate) | no SPARK |  |  |  |  |
| [compression/Ada/Dynamic-Markov-Compression](compression/Ada/Dynamic-Markov-Compression) | no SPARK |  |  |  |  |
| [compression/Ada/Earley-Parser](compression/Ada/Earley-Parser) | no SPARK |  |  |  |  |
| [compression/Ada/Fast-Efficient-Lossless-Image-Compression-System](compression/Ada/Fast-Efficient-Lossless-Image-Compression-System) | no SPARK |  |  |  |  |
| [compression/Ada/Fractal-Compression](compression/Ada/Fractal-Compression) | no SPARK |  |  |  |  |
| [compression/Ada/Huffmann-Coding](compression/Ada/Huffmann-Coding) | no SPARK |  |  |  |  |
| [compression/Ada/Image-Compression](compression/Ada/Image-Compression) | no SPARK |  |  |  |  |
| [compression/Ada/LZ77-LZ78](compression/Ada/LZ77-LZ78) | no SPARK |  |  |  |  |
| [compression/Ada/LZWL](compression/Ada/LZWL) | no SPARK |  |  |  |  |
| [compression/Ada/LZX](compression/Ada/LZX) | no SPARK |  |  |  |  |
| [compression/Ada/Peterson-Gorenstein-Zierler-Algorithm](compression/Ada/Peterson-Gorenstein-Zierler-Algorithm) | not built |  |  |  |  |
| [compression/Ada/Run-Length-Encoding](compression/Ada/Run-Length-Encoding) | no SPARK |  |  |  |  |
| [compression/Ada/Speech-Compression](compression/Ada/Speech-Compression) | no SPARK |  |  |  |  |
| [compression/Ada/Verlet-Integration](compression/Ada/Verlet-Integration) | no SPARK |  |  |  |  |
| [compression/Ada/Video-Compression](compression/Ada/Video-Compression) | no SPARK |  |  |  |  |
| [compression/Ada/Wavelet-Compression](compression/Ada/Wavelet-Compression) | no SPARK |  |  |  |  |

### compression/SPARK2

**7 folders.**

| folder path | Silver | Training-ready | Stub | Needs implementation | Open findings |
|---|---|---|---|---|---|
| [compression/SPARK2/Ada-SPARK-Compress-String](compression/SPARK2/Ada-SPARK-Compress-String) | proven |  |  |  |  |
| [compression/SPARK2/Ada-SPARK-Interleaving-String](compression/SPARK2/Ada-SPARK-Interleaving-String) | proven | yes |  |  |  |
| [compression/SPARK2/Ada-SPARK-LZ77](compression/SPARK2/Ada-SPARK-LZ77) | proven |  |  |  |  |
| [compression/SPARK2/Ada-SPARK-Move-To-Front](compression/SPARK2/Ada-SPARK-Move-To-Front) | proven |  |  |  |  |
| [compression/SPARK2/Ada-SPARK-Run-Length-Encoding](compression/SPARK2/Ada-SPARK-Run-Length-Encoding) | proven |  |  |  |  |
| [compression/SPARK2/Ada-SPARK-String-Compression](compression/SPARK2/Ada-SPARK-String-Compression) | proven |  |  |  |  |
| [compression/SPARK2/Burrows-Wheeler-Transform](compression/SPARK2/Burrows-Wheeler-Transform) | proven | yes |  |  |  |

### compression/SPARK3

**1 folder.**

| folder path | Silver | Training-ready | Stub | Needs implementation | Open findings |
|---|---|---|---|---|---|
| [compression/SPARK3/Huffman-Coding](compression/SPARK3/Huffman-Coding) | proven |  |  |  |  |

## concurrency

**17 folders.**

### concurrency/Ada

**9 folders.**

| folder path | Silver | Training-ready | Stub | Needs implementation | Open findings |
|---|---|---|---|---|---|
| [concurrency/Ada/Dekker](concurrency/Ada/Dekker) | no SPARK |  |  |  |  |
| [concurrency/Ada/Lamport-Ordering](concurrency/Ada/Lamport-Ordering) | no SPARK |  |  |  |  |
| [concurrency/Ada/Paxos-Algorithm](concurrency/Ada/Paxos-Algorithm) | no SPARK |  |  |  |  |
| [concurrency/Ada/Vector-Clocks](concurrency/Ada/Vector-Clocks) | no SPARK |  |  |  |  |
| [concurrency/Ada/lamport](concurrency/Ada/lamport) | no SPARK |  |  |  |  |
| [concurrency/Ada/lds-scheduler](concurrency/Ada/lds-scheduler) | no SPARK |  |  |  |  |
| [concurrency/Ada/mlfq](concurrency/Ada/mlfq) | no SPARK |  |  |  |  |
| [concurrency/Ada/peterson](concurrency/Ada/peterson) | no SPARK |  |  |  |  |
| [concurrency/Ada/sjn](concurrency/Ada/sjn) | no SPARK |  |  |  |  |

### concurrency/SPARK2

**8 folders.**

| folder path | Silver | Training-ready | Stub | Needs implementation | Open findings |
|---|---|---|---|---|---|
| [concurrency/SPARK2/Ada-SPARK-Course-Schedule-II](concurrency/SPARK2/Ada-SPARK-Course-Schedule-II) | proven |  | yes | yes |  |
| [concurrency/SPARK2/Ada-SPARK-Course-Schedule-II-Stub](concurrency/SPARK2/Ada-SPARK-Course-Schedule-II-Stub) | proven |  | yes | yes |  |
| [concurrency/SPARK2/Ada-SPARK-Dekkers-Algorithm](concurrency/SPARK2/Ada-SPARK-Dekkers-Algorithm) | proven |  |  |  |  |
| [concurrency/SPARK2/Ada-SPARK-Lamports-Bakery-Algorithm](concurrency/SPARK2/Ada-SPARK-Lamports-Bakery-Algorithm) | proven |  |  |  |  |
| [concurrency/SPARK2/Ada-SPARK-Petersons-Algorithm](concurrency/SPARK2/Ada-SPARK-Petersons-Algorithm) | proven |  |  |  |  |
| [concurrency/SPARK2/Ada-SPARK-Task-Scheduler](concurrency/SPARK2/Ada-SPARK-Task-Scheduler) | proven |  |  |  |  |
| [concurrency/SPARK2/Ada-SPARK-Task-Scheduler-Stub](concurrency/SPARK2/Ada-SPARK-Task-Scheduler-Stub) | proven |  |  |  |  |
| [concurrency/SPARK2/Course-Schedule](concurrency/SPARK2/Course-Schedule) | proven |  |  |  |  |

## cryptography

**33 folders.**

### cryptography/Ada

**29 folders.**

| folder path | Silver | Training-ready | Stub | Needs implementation | Open findings |
|---|---|---|---|---|---|
| [cryptography/Ada/Aes](cryptography/Ada/Aes) | no SPARK |  |  |  |  |
| [cryptography/Ada/Argon2](cryptography/Ada/Argon2) | no SPARK |  |  |  |  |
| [cryptography/Ada/Asymetric-Public-Key-Encryption](cryptography/Ada/Asymetric-Public-Key-Encryption) | no SPARK |  |  |  |  |
| [cryptography/Ada/BLAKE](cryptography/Ada/BLAKE) | no SPARK |  |  |  |  |
| [cryptography/Ada/Bcrypt](cryptography/Ada/Bcrypt) | no SPARK |  |  |  |  |
| [cryptography/Ada/Blowfish](cryptography/Ada/Blowfish) | no SPARK |  |  |  |  |
| [cryptography/Ada/ChaCha20](cryptography/Ada/ChaCha20) | no SPARK |  |  |  |  |
| [cryptography/Ada/Data-Encryption-Standard](cryptography/Ada/Data-Encryption-Standard) | no SPARK |  |  |  |  |
| [cryptography/Ada/ECDSA](cryptography/Ada/ECDSA) | no SPARK |  |  |  |  |
| [cryptography/Ada/Elliptic-Curve-Diffie-Hellman](cryptography/Ada/Elliptic-Curve-Diffie-Hellman) | no SPARK |  |  |  |  |
| [cryptography/Ada/Fortuna](cryptography/Ada/Fortuna) | no SPARK |  |  |  |  |
| [cryptography/Ada/HMAC](cryptography/Ada/HMAC) | no SPARK |  |  |  |  |
| [cryptography/Ada/IDEA](cryptography/Ada/IDEA) | no SPARK |  |  |  |  |
| [cryptography/Ada/Lenstra-Elliptic-Curve-Factorization](cryptography/Ada/Lenstra-Elliptic-Curve-Factorization) | no SPARK |  |  |  |  |
| [cryptography/Ada/MD5](cryptography/Ada/MD5) | no SPARK |  |  |  |  |
| [cryptography/Ada/NTRUEncrypt](cryptography/Ada/NTRUEncrypt) | not built |  |  |  |  |
| [cryptography/Ada/RC4](cryptography/Ada/RC4) | not built |  |  |  |  |
| [cryptography/Ada/RSA](cryptography/Ada/RSA) | no SPARK |  |  |  |  |
| [cryptography/Ada/SHA3](cryptography/Ada/SHA3) | no SPARK |  |  |  |  |
| [cryptography/Ada/Shamirs-Secret-Sharing](cryptography/Ada/Shamirs-Secret-Sharing) | no SPARK |  |  |  |  |
| [cryptography/Ada/Stochastic-Universal-Sampling](cryptography/Ada/Stochastic-Universal-Sampling) | no SPARK |  |  |  |  |
| [cryptography/Ada/Symetric-Encryption](cryptography/Ada/Symetric-Encryption) | no SPARK |  |  |  |  |
| [cryptography/Ada/Threefish](cryptography/Ada/Threefish) | no SPARK |  |  |  |  |
| [cryptography/Ada/Tiny-Encryption-Algorithm](cryptography/Ada/Tiny-Encryption-Algorithm) | no SPARK |  |  |  |  |
| [cryptography/Ada/Twofish](cryptography/Ada/Twofish) | no SPARK |  |  |  |  |
| [cryptography/Ada/Universal-Coding](cryptography/Ada/Universal-Coding) | no SPARK |  |  |  |  |
| [cryptography/Ada/Universal-Variable-Formulation](cryptography/Ada/Universal-Variable-Formulation) | no SPARK |  |  |  |  |
| [cryptography/Ada/WHIRLPOOL](cryptography/Ada/WHIRLPOOL) | no SPARK |  |  |  |  |
| [cryptography/Ada/Yarrow-Algorithm](cryptography/Ada/Yarrow-Algorithm) | no SPARK |  |  |  |  |

### cryptography/SPARK2

**4 folders.**

| folder path | Silver | Training-ready | Stub | Needs implementation | Open findings |
|---|---|---|---|---|---|
| [cryptography/SPARK2/Ada-SPARK-Level-Order-Traversal-Stub](cryptography/SPARK2/Ada-SPARK-Level-Order-Traversal-Stub) | proven |  | yes | yes |  |
| [cryptography/SPARK2/Ada-SPARK-MD5](cryptography/SPARK2/Ada-SPARK-MD5) | proven |  | yes | yes |  |
| [cryptography/SPARK2/Ada-SPARK-SHA-1](cryptography/SPARK2/Ada-SPARK-SHA-1) | proven |  | yes | yes |  |
| [cryptography/SPARK2/Bit-Reversal](cryptography/SPARK2/Bit-Reversal) | proven |  |  |  |  |

## geometry

**50 folders.**

### geometry/Ada

**47 folders.**

| folder path | Silver | Training-ready | Stub | Needs implementation | Open findings |
|---|---|---|---|---|---|
| [geometry/Ada/Adaptive-Histogram-Equalization](geometry/Ada/Adaptive-Histogram-Equalization) | no SPARK |  |  |  |  |
| [geometry/Ada/Ambient-Occlusion](geometry/Ada/Ambient-Occlusion) | no SPARK |  |  |  |  |
| [geometry/Ada/Bresenhams-Line-Algorithm](geometry/Ada/Bresenhams-Line-Algorithm) | 25 unproved |  |  |  |  |
| [geometry/Ada/Canny-Edge-Detector](geometry/Ada/Canny-Edge-Detector) | no SPARK |  |  |  |  |
| [geometry/Ada/Clipping](geometry/Ada/Clipping) | no SPARK |  |  |  |  |
| [geometry/Ada/Closest-Pair-Problem](geometry/Ada/Closest-Pair-Problem) | no SPARK |  |  |  |  |
| [geometry/Ada/Cohen-Sutherland](geometry/Ada/Cohen-Sutherland) | no SPARK |  |  |  |  |
| [geometry/Ada/Constructive-Solid-Geometry](geometry/Ada/Constructive-Solid-Geometry) | no SPARK |  |  |  |  |
| [geometry/Ada/Convex-Hull-Algorithms](geometry/Ada/Convex-Hull-Algorithms) | no SPARK |  |  |  |  |
| [geometry/Ada/Delaunay-Triangulation](geometry/Ada/Delaunay-Triangulation) | no SPARK |  |  |  |  |
| [geometry/Ada/Dithering](geometry/Ada/Dithering) | no SPARK |  |  |  |  |
| [geometry/Ada/Fast-Clipping](geometry/Ada/Fast-Clipping) | no SPARK |  |  |  |  |
| [geometry/Ada/Generalised-Hough-Transform](geometry/Ada/Generalised-Hough-Transform) | no SPARK |  |  |  |  |
| [geometry/Ada/Gift-Wrapping](geometry/Ada/Gift-Wrapping) | no SPARK |  |  |  |  |
| [geometry/Ada/Gouraud-Shading](geometry/Ada/Gouraud-Shading) | no SPARK |  |  |  |  |
| [geometry/Ada/Grabcut](geometry/Ada/Grabcut) | no SPARK |  |  |  |  |
| [geometry/Ada/Graham-Scan](geometry/Ada/Graham-Scan) | no SPARK |  |  |  |  |
| [geometry/Ada/Histogram-Equalization](geometry/Ada/Histogram-Equalization) | no SPARK |  |  |  |  |
| [geometry/Ada/Hough-Transform](geometry/Ada/Hough-Transform) | no SPARK |  |  |  |  |
| [geometry/Ada/Isosurfaces](geometry/Ada/Isosurfaces) | no SPARK |  |  |  |  |
| [geometry/Ada/Kirkpatrick-Seidel](geometry/Ada/Kirkpatrick-Seidel) | no SPARK |  |  |  |  |
| [geometry/Ada/Liang-Barsky](geometry/Ada/Liang-Barsky) | no SPARK |  |  |  |  |
| [geometry/Ada/Line-Clipping](geometry/Ada/Line-Clipping) | no SPARK |  |  |  |  |
| [geometry/Ada/Line-Segment-Intersection](geometry/Ada/Line-Segment-Intersection) | no SPARK |  |  |  |  |
| [geometry/Ada/Marching-Cubes](geometry/Ada/Marching-Cubes) | no SPARK |  |  |  |  |
| [geometry/Ada/Ordered-Dithering](geometry/Ada/Ordered-Dithering) | no SPARK |  |  |  |  |
| [geometry/Ada/Phong-Shading](geometry/Ada/Phong-Shading) | timeout |  |  |  |  |
| [geometry/Ada/Point-In-Polygon](geometry/Ada/Point-In-Polygon) | no SPARK |  |  |  |  |
| [geometry/Ada/Polygon-Triangulation](geometry/Ada/Polygon-Triangulation) | no SPARK |  |  |  |  |
| [geometry/Ada/Quasitriangulation](geometry/Ada/Quasitriangulation) | no SPARK |  |  |  |  |
| [geometry/Ada/Quickhull](geometry/Ada/Quickhull) | no SPARK |  |  |  |  |
| [geometry/Ada/Radiosity](geometry/Ada/Radiosity) | no SPARK |  |  |  |  |
| [geometry/Ada/Ramer-Douglas-Peucker-Algorithm](geometry/Ada/Ramer-Douglas-Peucker-Algorithm) | no SPARK |  |  |  |  |
| [geometry/Ada/Ray-Tracing](geometry/Ada/Ray-Tracing) | no SPARK |  |  |  |  |
| [geometry/Ada/Riemersma-Dithering](geometry/Ada/Riemersma-Dithering) | no SPARK |  |  |  |  |
| [geometry/Ada/Segmentation](geometry/Ada/Segmentation) | no SPARK |  |  |  |  |
| [geometry/Ada/Shading](geometry/Ada/Shading) | not built |  |  |  |  |
| [geometry/Ada/Slerp](geometry/Ada/Slerp) | no SPARK |  |  |  |  |
| [geometry/Ada/Sutherland-Hodgman](geometry/Ada/Sutherland-Hodgman) | no SPARK |  |  |  |  |
| [geometry/Ada/Triangulation](geometry/Ada/Triangulation) | no SPARK |  |  |  |  |
| [geometry/Ada/Vatti](geometry/Ada/Vatti) | no SPARK |  |  |  |  |
| [geometry/Ada/Vincenty](geometry/Ada/Vincenty) | no SPARK |  |  |  |  |
| [geometry/Ada/Voronoi-Diagrams](geometry/Ada/Voronoi-Diagrams) | no SPARK |  |  |  |  |
| [geometry/Ada/Warnock-Algorithm](geometry/Ada/Warnock-Algorithm) | no SPARK |  |  |  |  |
| [geometry/Ada/Watershed-Transformation](geometry/Ada/Watershed-Transformation) | no SPARK |  |  |  |  |
| [geometry/Ada/Weiler-Atherton](geometry/Ada/Weiler-Atherton) | no SPARK |  |  |  |  |
| [geometry/Ada/Xiaolin-Wus-Line-Algorithm](geometry/Ada/Xiaolin-Wus-Line-Algorithm) | no SPARK |  |  |  |  |

### geometry/SPARK2

**3 folders.**

| folder path | Silver | Training-ready | Stub | Needs implementation | Open findings |
|---|---|---|---|---|---|
| [geometry/SPARK2/Ada-SPARK-Convex-Hull-Graham](geometry/SPARK2/Ada-SPARK-Convex-Hull-Graham) | proven |  |  |  |  |
| [geometry/SPARK2/Ada-SPARK-Point-In-Polygon](geometry/SPARK2/Ada-SPARK-Point-In-Polygon) | proven | yes |  |  |  |
| [geometry/SPARK2/Closest-Pair-Brute](geometry/SPARK2/Closest-Pair-Brute) | tool crash |  |  |  |  |

## graphs

**48 folders.**

### graphs/Ada

**30 folders.**

| folder path | Silver | Training-ready | Stub | Needs implementation | Open findings |
|---|---|---|---|---|---|
| [graphs/Ada/A-Star](graphs/Ada/A-Star) | no SPARK |  |  |  |  |
| [graphs/Ada/Bellman-Ford-Algorithm](graphs/Ada/Bellman-Ford-Algorithm) | no SPARK |  |  |  |  |
| [graphs/Ada/Boruvkas-Algorithm](graphs/Ada/Boruvkas-Algorithm) | no SPARK |  |  |  |  |
| [graphs/Ada/Cliques](graphs/Ada/Cliques) | no SPARK |  |  |  |  |
| [graphs/Ada/Coin-Graph](graphs/Ada/Coin-Graph) | no SPARK |  |  |  |  |
| [graphs/Ada/Cryptographically-Secure-Pseudo-Random-Number-Generators](graphs/Ada/Cryptographically-Secure-Pseudo-Random-Number-Generators) | no SPARK |  |  |  |  |
| [graphs/Ada/Cryptographically-Secure-Pseudorandom-Number-Generator](graphs/Ada/Cryptographically-Secure-Pseudorandom-Number-Generator) | no SPARK |  |  |  |  |
| [graphs/Ada/Dijkstra-Scholten-Algorithm](graphs/Ada/Dijkstra-Scholten-Algorithm) | no SPARK |  |  |  |  |
| [graphs/Ada/Dijkstras-Algorithm](graphs/Ada/Dijkstras-Algorithm) | no SPARK |  |  |  |  |
| [graphs/Ada/Dinics-Algorithm](graphs/Ada/Dinics-Algorithm) | no SPARK |  |  |  |  |
| [graphs/Ada/Edmonds-Karp-Algorithm](graphs/Ada/Edmonds-Karp-Algorithm) | no SPARK |  |  |  |  |
| [graphs/Ada/Elliptic-Curve-Cryptography](graphs/Ada/Elliptic-Curve-Cryptography) | no SPARK |  |  |  |  |
| [graphs/Ada/Euclidean-Minimum-Spanning-Tree](graphs/Ada/Euclidean-Minimum-Spanning-Tree) | no SPARK |  |  |  |  |
| [graphs/Ada/Floyd-Steinberg-Dithering](graphs/Ada/Floyd-Steinberg-Dithering) | no SPARK |  |  |  |  |
| [graphs/Ada/Floyd-Warshall-Algorithm](graphs/Ada/Floyd-Warshall-Algorithm) | no SPARK |  |  |  |  |
| [graphs/Ada/Floyds-Cycle-Finding-Algorithm](graphs/Ada/Floyds-Cycle-Finding-Algorithm) | no SPARK |  |  |  |  |
| [graphs/Ada/Ford-Fulkerson-Algorithm](graphs/Ada/Ford-Fulkerson-Algorithm) | no SPARK |  |  |  |  |
| [graphs/Ada/Hungarian-Algorithm](graphs/Ada/Hungarian-Algorithm) | no SPARK |  |  |  |  |
| [graphs/Ada/Hungarian-Method](graphs/Ada/Hungarian-Method) | no SPARK |  |  |  |  |
| [graphs/Ada/Kosarajus-Algorithm](graphs/Ada/Kosarajus-Algorithm) | no SPARK |  |  |  |  |
| [graphs/Ada/Kruskals-Algorithm](graphs/Ada/Kruskals-Algorithm) | no SPARK |  |  |  |  |
| [graphs/Ada/MaxCliqueDyn](graphs/Ada/MaxCliqueDyn) | no SPARK |  |  |  |  |
| [graphs/Ada/Minimum-Spanning-Tree](graphs/Ada/Minimum-Spanning-Tree) | no SPARK |  |  |  |  |
| [graphs/Ada/PageRank](graphs/Ada/PageRank) | no SPARK |  |  |  |  |
| [graphs/Ada/Post-Quantum-Cryptography](graphs/Ada/Post-Quantum-Cryptography) | no SPARK |  |  |  |  |
| [graphs/Ada/Prims-Algorithm](graphs/Ada/Prims-Algorithm) | no SPARK |  |  |  |  |
| [graphs/Ada/Shortest-Path-Problem](graphs/Ada/Shortest-Path-Problem) | no SPARK |  |  |  |  |
| [graphs/Ada/Tarjans-Off-Line-Lowest-Common-Ancestors](graphs/Ada/Tarjans-Off-Line-Lowest-Common-Ancestors) | no SPARK |  |  |  |  |
| [graphs/Ada/Tarjans-Strongly-Connected-Components](graphs/Ada/Tarjans-Strongly-Connected-Components) | no SPARK |  |  |  |  |
| [graphs/Ada/subgraph-isomorphism](graphs/Ada/subgraph-isomorphism) | no SPARK |  |  |  |  |

### graphs/SPARK2

**15 folders.**

| folder path | Silver | Training-ready | Stub | Needs implementation | Open findings |
|---|---|---|---|---|---|
| [graphs/SPARK2/Ada-SPARK-Bellman-Ford-Lite](graphs/SPARK2/Ada-SPARK-Bellman-Ford-Lite) | proven |  |  |  |  |
| [graphs/SPARK2/Ada-SPARK-Clone-Graph](graphs/SPARK2/Ada-SPARK-Clone-Graph) | proven |  |  |  |  |
| [graphs/SPARK2/Ada-SPARK-Clone-Graph-Stub](graphs/SPARK2/Ada-SPARK-Clone-Graph-Stub) | proven |  | yes | yes |  |
| [graphs/SPARK2/Ada-SPARK-Dijkstra-Lite](graphs/SPARK2/Ada-SPARK-Dijkstra-Lite) | proven |  |  |  |  |
| [graphs/SPARK2/Ada-SPARK-Find-Center-Of-Star-Graph](graphs/SPARK2/Ada-SPARK-Find-Center-Of-Star-Graph) | proven |  |  |  |  |
| [graphs/SPARK2/Ada-SPARK-Find-If-Path-Exists-In-Graph](graphs/SPARK2/Ada-SPARK-Find-If-Path-Exists-In-Graph) | proven | yes |  |  |  |
| [graphs/SPARK2/Ada-SPARK-Floyd-Warshall](graphs/SPARK2/Ada-SPARK-Floyd-Warshall) | proven |  |  |  |  |
| [graphs/SPARK2/Ada-SPARK-Floyd-Warshall-Lite](graphs/SPARK2/Ada-SPARK-Floyd-Warshall-Lite) | proven |  |  |  |  |
| [graphs/SPARK2/Ada-SPARK-Is-Graph-Bipartite](graphs/SPARK2/Ada-SPARK-Is-Graph-Bipartite) | proven |  |  |  |  |
| [graphs/SPARK2/Ada-SPARK-Kruskal-MST-Lite](graphs/SPARK2/Ada-SPARK-Kruskal-MST-Lite) | proven |  | yes | yes |  |
| [graphs/SPARK2/Ada-SPARK-Kruskals-Algorithm](graphs/SPARK2/Ada-SPARK-Kruskals-Algorithm) | proven |  |  |  |  |
| [graphs/SPARK2/Ada-SPARK-Number-Of-Islands-DFS](graphs/SPARK2/Ada-SPARK-Number-Of-Islands-DFS) | proven | yes |  |  |  |
| [graphs/SPARK2/Ada-SPARK-Prims-Algorithm](graphs/SPARK2/Ada-SPARK-Prims-Algorithm) | proven |  |  |  |  |
| [graphs/SPARK2/Ada-SPARK-Shortest-Path-In-Binary-Matrix](graphs/SPARK2/Ada-SPARK-Shortest-Path-In-Binary-Matrix) | proven |  | yes | yes |  |
| [graphs/SPARK2/Bellman-Ford-Algorithm](graphs/SPARK2/Bellman-Ford-Algorithm) | proven |  |  |  |  |

### graphs/SPARK4

**3 folders.**

| folder path | Silver | Training-ready | Stub | Needs implementation | Open findings |
|---|---|---|---|---|---|
| [graphs/SPARK4/A-Star](graphs/SPARK4/A-Star) | proven |  |  |  |  |
| [graphs/SPARK4/Ada-SPARK-Dijkstras-Algorithm](graphs/SPARK4/Ada-SPARK-Dijkstras-Algorithm) | proven |  |  |  |  |
| [graphs/SPARK4/Ada-SPARK-Floyds-Cycle-Finding-Algorithm](graphs/SPARK4/Ada-SPARK-Floyds-Cycle-Finding-Algorithm) | proven |  |  |  |  |

## hashing

**18 folders.**

### hashing/Ada

**10 folders.**

| folder path | Silver | Training-ready | Stub | Needs implementation | Open findings |
|---|---|---|---|---|---|
| [hashing/Ada/Bloom-Filter](hashing/Ada/Bloom-Filter) | no SPARK |  |  |  |  |
| [hashing/Ada/Geohash](hashing/Ada/Geohash) | no SPARK |  |  |  |  |
| [hashing/Ada/Geometric-Hashing](hashing/Ada/Geometric-Hashing) | no SPARK |  |  |  |  |
| [hashing/Ada/Hash-Functions](hashing/Ada/Hash-Functions) | no SPARK |  |  |  |  |
| [hashing/Ada/Hash-Join](hashing/Ada/Hash-Join) | no SPARK |  |  |  |  |
| [hashing/Ada/Locality-Sensitive-Hashing](hashing/Ada/Locality-Sensitive-Hashing) | no SPARK |  |  |  |  |
| [hashing/Ada/Pearson-Hashing](hashing/Ada/Pearson-Hashing) | no SPARK |  |  |  |  |
| [hashing/Ada/SipHash](hashing/Ada/SipHash) | not built |  |  |  |  |
| [hashing/Ada/Tiger-Hash](hashing/Ada/Tiger-Hash) | no SPARK |  |  |  |  |
| [hashing/Ada/Zobrist-Hashing](hashing/Ada/Zobrist-Hashing) | no SPARK |  |  |  |  |

### hashing/SPARK2

**8 folders.**

| folder path | Silver | Training-ready | Stub | Needs implementation | Open findings |
|---|---|---|---|---|---|
| [hashing/SPARK2/Ada-SPARK-Design-HashMap](hashing/SPARK2/Ada-SPARK-Design-HashMap) | proven |  |  |  |  |
| [hashing/SPARK2/Ada-SPARK-Design-HashMap-Stub](hashing/SPARK2/Ada-SPARK-Design-HashMap-Stub) | proven |  | yes | yes |  |
| [hashing/SPARK2/Ada-SPARK-Design-HashSet](hashing/SPARK2/Ada-SPARK-Design-HashSet) | proven |  |  |  |  |
| [hashing/SPARK2/Ada-SPARK-Design-HashSet-Stub](hashing/SPARK2/Ada-SPARK-Design-HashSet-Stub) | proven |  | yes | yes |  |
| [hashing/SPARK2/Ada-SPARK-FNV-Hash](hashing/SPARK2/Ada-SPARK-FNV-Hash) | proven |  |  |  |  |
| [hashing/SPARK2/Ada-SPARK-Pearson-Hashing](hashing/SPARK2/Ada-SPARK-Pearson-Hashing) | proven |  |  |  |  |
| [hashing/SPARK2/Ada-SPARK-Zobrist-Hashing](hashing/SPARK2/Ada-SPARK-Zobrist-Hashing) | proven |  |  |  |  |
| [hashing/SPARK2/Bloom-Filter](hashing/SPARK2/Bloom-Filter) | proven |  |  |  |  |

## logic

**7 folders.**

### logic/Ada

**7 folders.**

| folder path | Silver | Training-ready | Stub | Needs implementation | Open findings |
|---|---|---|---|---|---|
| [logic/Ada/Automated-Theorem-Proving](logic/Ada/Automated-Theorem-Proving) | no SPARK |  |  |  |  |
| [logic/Ada/Chaff](logic/Ada/Chaff) | no SPARK |  |  |  |  |
| [logic/Ada/Constraint-Satisfaction](logic/Ada/Constraint-Satisfaction) | no SPARK |  |  |  |  |
| [logic/Ada/DPLL](logic/Ada/DPLL) | proven |  |  |  |  |
| [logic/Ada/DPLL-Algorithm](logic/Ada/DPLL-Algorithm) | no SPARK |  |  |  |  |
| [logic/Ada/Davis-Putnam](logic/Ada/Davis-Putnam) | no SPARK |  |  |  |  |
| [logic/Ada/Verified-Unification-Engine](logic/Ada/Verified-Unification-Engine) | proven |  |  |  |  |

## matrices

**27 folders.**

### matrices/Ada

**11 folders.**

| folder path | Silver | Training-ready | Stub | Needs implementation | Open findings |
|---|---|---|---|---|---|
| [matrices/Ada/Chain-Matrix-Multiplication](matrices/Ada/Chain-Matrix-Multiplication) | no SPARK |  |  |  |  |
| [matrices/Ada/Eigenvalue-Algorithms](matrices/Ada/Eigenvalue-Algorithms) | no SPARK |  |  |  |  |
| [matrices/Ada/Gaussian-Elimination](matrices/Ada/Gaussian-Elimination) | no SPARK |  |  |  |  |
| [matrices/Ada/Jacobi-Eigenvalue](matrices/Ada/Jacobi-Eigenvalue) | no SPARK |  |  |  |  |
| [matrices/Ada/Matrix-Multiplication](matrices/Ada/Matrix-Multiplication) | no SPARK |  |  |  |  |
| [matrices/Ada/Quantum-Singular-Value-Transformation](matrices/Ada/Quantum-Singular-Value-Transformation) | no SPARK |  |  |  |  |
| [matrices/Ada/SMAWK](matrices/Ada/SMAWK) | no SPARK |  |  |  |  |
| [matrices/Ada/Schonhage-Strassen](matrices/Ada/Schonhage-Strassen) | no SPARK |  |  |  |  |
| [matrices/Ada/Sparse-Matrix](matrices/Ada/Sparse-Matrix) | no SPARK |  |  |  |  |
| [matrices/Ada/Strassen](matrices/Ada/Strassen) | no SPARK |  |  |  |  |
| [matrices/Ada/Symbolic-Cholesky-Decomposition](matrices/Ada/Symbolic-Cholesky-Decomposition) | no SPARK |  |  |  |  |

### matrices/SPARK2

**16 folders.**

| folder path | Silver | Training-ready | Stub | Needs implementation | Open findings |
|---|---|---|---|---|---|
| [matrices/SPARK2/Ada-SPARK-Check-If-Matrix-Is-X-Matrix](matrices/SPARK2/Ada-SPARK-Check-If-Matrix-Is-X-Matrix) | proven |  |  |  |  |
| [matrices/SPARK2/Ada-SPARK-Gaussian-Elimination](matrices/SPARK2/Ada-SPARK-Gaussian-Elimination) | proven | yes |  |  |  |
| [matrices/SPARK2/Ada-SPARK-Lucky-Numbers-In-A-Matrix](matrices/SPARK2/Ada-SPARK-Lucky-Numbers-In-A-Matrix) | proven |  |  |  |  |
| [matrices/SPARK2/Ada-SPARK-Matrix-Cells-In-Distance-Order](matrices/SPARK2/Ada-SPARK-Matrix-Cells-In-Distance-Order) | proven |  |  |  |  |
| [matrices/SPARK2/Ada-SPARK-Matrix-Chain-Multiplication](matrices/SPARK2/Ada-SPARK-Matrix-Chain-Multiplication) | proven |  |  |  |  |
| [matrices/SPARK2/Ada-SPARK-Matrix-Diagonal-Sum](matrices/SPARK2/Ada-SPARK-Matrix-Diagonal-Sum) | proven |  |  |  |  |
| [matrices/SPARK2/Ada-SPARK-Matrix-Multiply](matrices/SPARK2/Ada-SPARK-Matrix-Multiply) | proven |  |  |  |  |
| [matrices/SPARK2/Ada-SPARK-Num-Matrix-Block-Sum](matrices/SPARK2/Ada-SPARK-Num-Matrix-Block-Sum) | proven | yes |  |  |  |
| [matrices/SPARK2/Ada-SPARK-Reshape-The-Matrix](matrices/SPARK2/Ada-SPARK-Reshape-The-Matrix) | proven |  |  |  |  |
| [matrices/SPARK2/Ada-SPARK-Set-Matrix-Zeroes](matrices/SPARK2/Ada-SPARK-Set-Matrix-Zeroes) | proven |  |  |  |  |
| [matrices/SPARK2/Ada-SPARK-Spiral-Matrix](matrices/SPARK2/Ada-SPARK-Spiral-Matrix) | proven |  |  |  |  |
| [matrices/SPARK2/Ada-SPARK-Spiral-Matrix-II](matrices/SPARK2/Ada-SPARK-Spiral-Matrix-II) | proven |  |  |  |  |
| [matrices/SPARK2/Ada-SPARK-The-K-Weakest-Rows-In-A-Matrix](matrices/SPARK2/Ada-SPARK-The-K-Weakest-Rows-In-A-Matrix) | proven |  |  |  |  |
| [matrices/SPARK2/Ada-SPARK-Toeplitz-Matrix](matrices/SPARK2/Ada-SPARK-Toeplitz-Matrix) | proven |  |  |  |  |
| [matrices/SPARK2/Ada-SPARK-Transpose-Matrix](matrices/SPARK2/Ada-SPARK-Transpose-Matrix) | proven |  |  |  |  |
| [matrices/SPARK2/Matrix-01](matrices/SPARK2/Matrix-01) | proven |  |  |  |  |

## misc

**1122 folders.**

### misc/Ada

**511 folders.**

| folder path | Silver | Training-ready | Stub | Needs implementation | Open findings |
|---|---|---|---|---|---|
| [misc/Ada/A-Law-Algorithm](misc/Ada/A-Law-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/AC-3](misc/Ada/AC-3) | no SPARK |  |  |  |  |
| [misc/Ada/ACORN-Generator](misc/Ada/ACORN-Generator) | no SPARK |  |  |  |  |
| [misc/Ada/Adaptive-Additive-Algorithm](misc/Ada/Adaptive-Additive-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Addition-Chain-Exponentiation](misc/Ada/Addition-Chain-Exponentiation) | no SPARK |  |  |  |  |
| [misc/Ada/Adler-32](misc/Ada/Adler-32) | no SPARK |  |  |  |  |
| [misc/Ada/Aharonov-Jones-Landau-Algorithm](misc/Ada/Aharonov-Jones-Landau-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Algorithm-X](misc/Ada/Algorithm-X) | no SPARK |  |  |  |  |
| [misc/Ada/Algorithms-For-Calculating-Variance](misc/Ada/Algorithms-For-Calculating-Variance) | no SPARK |  |  |  |  |
| [misc/Ada/Alpha-Beta-Pruning](misc/Ada/Alpha-Beta-Pruning) | no SPARK |  |  |  |  |
| [misc/Ada/Alpha-Max-Plus-Beta-Min](misc/Ada/Alpha-Max-Plus-Beta-Min) | no SPARK |  |  |  |  |
| [misc/Ada/Amplitude-Amplification](misc/Ada/Amplitude-Amplification) | no SPARK |  |  |  |  |
| [misc/Ada/Ant-Colony-Optimization](misc/Ada/Ant-Colony-Optimization) | no SPARK |  |  |  |  |
| [misc/Ada/Approximate-Counting](misc/Ada/Approximate-Counting) | no SPARK |  |  |  |  |
| [misc/Ada/Apriori-Algorithm](misc/Ada/Apriori-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Association-Rule-Learning](misc/Ada/Association-Rule-Learning) | no SPARK |  |  |  |  |
| [misc/Ada/Automated-Planning-And-Scheduling](misc/Ada/Automated-Planning-And-Scheduling) | no SPARK |  |  |  |  |
| [misc/Ada/Automatic-Train-Operation](misc/Ada/Automatic-Train-Operation) | no SPARK |  |  |  |  |
| [misc/Ada/B-Star](misc/Ada/B-Star) | no SPARK |  |  |  |  |
| [misc/Ada/BCH-Codes](misc/Ada/BCH-Codes) | no SPARK |  |  |  |  |
| [misc/Ada/BCJR-Algorithm](misc/Ada/BCJR-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/BHT-Algorithm](misc/Ada/BHT-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/BLAST](misc/Ada/BLAST) | no SPARK |  |  |  |  |
| [misc/Ada/Baby-Step-Giant-Step](misc/Ada/Baby-Step-Giant-Step) | no SPARK |  |  |  |  |
| [misc/Ada/Backtracking](misc/Ada/Backtracking) | no SPARK |  |  |  |  |
| [misc/Ada/Backward-Euler](misc/Ada/Backward-Euler) | no SPARK |  |  |  |  |
| [misc/Ada/Backward-Induction](misc/Ada/Backward-Induction) | no SPARK |  |  |  |  |
| [misc/Ada/Baillie-PSW](misc/Ada/Baillie-PSW) | no SPARK |  |  |  |  |
| [misc/Ada/Bankers-Algorithm](misc/Ada/Bankers-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Banzhaf-Power-Index](misc/Ada/Banzhaf-Power-Index) | no SPARK |  |  |  |  |
| [misc/Ada/Barnes-Hut](misc/Ada/Barnes-Hut) | no SPARK |  |  |  |  |
| [misc/Ada/Baum-Welch](misc/Ada/Baum-Welch) | no SPARK |  |  |  |  |
| [misc/Ada/Bayesian-Nash-Equilibrium](misc/Ada/Bayesian-Nash-Equilibrium) | no SPARK |  |  |  |  |
| [misc/Ada/Bayesian-Statistics](misc/Ada/Bayesian-Statistics) | no SPARK |  |  |  |  |
| [misc/Ada/Beam-Tracing](misc/Ada/Beam-Tracing) | no SPARK |  |  |  |  |
| [misc/Ada/Bees-Algorithm](misc/Ada/Bees-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Beginner-Embedded-API](misc/Ada/Beginner-Embedded-API) | proven |  |  |  |  |
| [misc/Ada/Bensons-Algorithm](misc/Ada/Bensons-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Bentley-Ottmann](misc/Ada/Bentley-Ottmann) | no SPARK |  |  |  |  |
| [misc/Ada/Berkeley-Algorithm](misc/Ada/Berkeley-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Bernstein-Varizani-Algorithm](misc/Ada/Bernstein-Varizani-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Best-Bin-First](misc/Ada/Best-Bin-First) | no SPARK |  |  |  |  |
| [misc/Ada/Binary-Space-Partitioning](misc/Ada/Binary-Space-Partitioning) | no SPARK |  |  |  |  |
| [misc/Ada/Binary-Splitting](misc/Ada/Binary-Splitting) | no SPARK |  |  |  |  |
| [misc/Ada/Birkhoff-von-Neumann](misc/Ada/Birkhoff-von-Neumann) | no SPARK |  |  |  |  |
| [misc/Ada/Bitap-Algorithm](misc/Ada/Bitap-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Black-Scholes-Model](misc/Ada/Black-Scholes-Model) | not built |  |  |  |  |
| [misc/Ada/Blind-Deconvolution](misc/Ada/Blind-Deconvolution) | no SPARK |  |  |  |  |
| [misc/Ada/Block-Nested-Loop](misc/Ada/Block-Nested-Loop) | no SPARK |  |  |  |  |
| [misc/Ada/Block-Truncation-Coding](misc/Ada/Block-Truncation-Coding) | no SPARK |  |  |  |  |
| [misc/Ada/Blossom-Algorithm](misc/Ada/Blossom-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Blum-Blum-Shub](misc/Ada/Blum-Blum-Shub) | no SPARK |  |  |  |  |
| [misc/Ada/Booth-Multiplication](misc/Ada/Booth-Multiplication) | no SPARK |  |  |  |  |
| [misc/Ada/Bootstrap-Aggregating](misc/Ada/Bootstrap-Aggregating) | no SPARK |  |  |  |  |
| [misc/Ada/Boson-Sampling](misc/Ada/Boson-Sampling) | no SPARK |  |  |  |  |
| [misc/Ada/Boundary-Representation](misc/Ada/Boundary-Representation) | no SPARK |  |  |  |  |
| [misc/Ada/Bowyer-Watson](misc/Ada/Bowyer-Watson) | no SPARK |  |  |  |  |
| [misc/Ada/Branch-and-Bound](misc/Ada/Branch-and-Bound) | no SPARK |  |  |  |  |
| [misc/Ada/Branch-and-Cut](misc/Ada/Branch-and-Cut) | no SPARK |  |  |  |  |
| [misc/Ada/Bron-Kerbosch](misc/Ada/Bron-Kerbosch) | no SPARK |  |  |  |  |
| [misc/Ada/Buchbergers-Algorithm](misc/Ada/Buchbergers-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Buddy-Memory-Allocation](misc/Ada/Buddy-Memory-Allocation) | no SPARK |  |  |  |  |
| [misc/Ada/Buechi-Automaton](misc/Ada/Buechi-Automaton) | no SPARK |  |  |  |  |
| [misc/Ada/Bully-Algorithm](misc/Ada/Bully-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Buzens-Algorithm](misc/Ada/Buzens-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/C4.5-Algorithm](misc/Ada/C4.5-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/CHS-Conversion](misc/Ada/CHS-Conversion) | no SPARK |  |  |  |  |
| [misc/Ada/Cannons-Algorithm](misc/Ada/Cannons-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Chaitins-Algorithm](misc/Ada/Chaitins-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Chandra-Toueg](misc/Ada/Chandra-Toueg) | no SPARK |  |  |  |  |
| [misc/Ada/Chans-Algorithm](misc/Ada/Chans-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Chase](misc/Ada/Chase) | no SPARK |  |  |  |  |
| [misc/Ada/Cheneys-Algorithm](misc/Ada/Cheneys-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Chews-Second-Algorithm](misc/Ada/Chews-Second-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Chinese-Whispers](misc/Ada/Chinese-Whispers) | no SPARK |  |  |  |  |
| [misc/Ada/Christofides-Algorithm](misc/Ada/Christofides-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Code-Excited-Linear-Prediction](misc/Ada/Code-Excited-Linear-Prediction) | no SPARK |  |  |  |  |
| [misc/Ada/Collision-Detection](misc/Ada/Collision-Detection) | no SPARK |  |  |  |  |
| [misc/Ada/Coloring-Algorithm](misc/Ada/Coloring-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Combinatorial-Auction](misc/Ada/Combinatorial-Auction) | no SPARK |  |  |  |  |
| [misc/Ada/Combinatorial-Optimization](misc/Ada/Combinatorial-Optimization) | no SPARK |  |  |  |  |
| [misc/Ada/Communications-Based-Train-Control](misc/Ada/Communications-Based-Train-Control) | no SPARK |  |  |  |  |
| [misc/Ada/Computation-Of-Pi](misc/Ada/Computation-Of-Pi) | no SPARK |  |  |  |  |
| [misc/Ada/Computer-Vision](misc/Ada/Computer-Vision) | no SPARK |  |  |  |  |
| [misc/Ada/Computus](misc/Ada/Computus) | no SPARK |  |  |  |  |
| [misc/Ada/Cone-Algorithm](misc/Ada/Cone-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Cone-Tracing](misc/Ada/Cone-Tracing) | no SPARK |  |  |  |  |
| [misc/Ada/Conflict-Driven-Clause-Learning](misc/Ada/Conflict-Driven-Clause-Learning) | no SPARK |  |  |  |  |
| [misc/Ada/Congruence-Of-Squares](misc/Ada/Congruence-Of-Squares) | no SPARK |  |  |  |  |
| [misc/Ada/Connected-Component-Labeling](misc/Ada/Connected-Component-Labeling) | no SPARK |  |  |  |  |
| [misc/Ada/Constraint-Algorithm](misc/Ada/Constraint-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Contour-Lines](misc/Ada/Contour-Lines) | no SPARK |  |  |  |  |
| [misc/Ada/Coppersmith-Winograd](misc/Ada/Coppersmith-Winograd) | no SPARK |  |  |  |  |
| [misc/Ada/Core](misc/Ada/Core) | no SPARK |  |  |  |  |
| [misc/Ada/Corporate-Wars-Sim](misc/Ada/Corporate-Wars-Sim) | no SPARK |  |  |  |  |
| [misc/Ada/Correlated-Equilibrium](misc/Ada/Correlated-Equilibrium) | no SPARK |  |  |  |  |
| [misc/Ada/Crank-Nicolson](misc/Ada/Crank-Nicolson) | no SPARK |  |  |  |  |
| [misc/Ada/Cristians-Algorithm](misc/Ada/Cristians-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Cross-Entropy-Method](misc/Ada/Cross-Entropy-Method) | no SPARK |  |  |  |  |
| [misc/Ada/Cuthill-McKee](misc/Ada/Cuthill-McKee) | no SPARK |  |  |  |  |
| [misc/Ada/Cutting-Plane-Method](misc/Ada/Cutting-Plane-Method) | no SPARK |  |  |  |  |
| [misc/Ada/Cyclic-Redundancy-Check](misc/Ada/Cyclic-Redundancy-Check) | no SPARK |  |  |  |  |
| [misc/Ada/Cyrus-Beck](misc/Ada/Cyrus-Beck) | no SPARK |  |  |  |  |
| [misc/Ada/D-Star](misc/Ada/D-Star) | no SPARK |  |  |  |  |
| [misc/Ada/DDA-Line-Algorithm](misc/Ada/DDA-Line-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/DSA](misc/Ada/DSA) | no SPARK |  |  |  |  |
| [misc/Ada/Damm-Algorithm](misc/Ada/Damm-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Dancing-Links](misc/Ada/Dancing-Links) | no SPARK |  |  |  |  |
| [misc/Ada/Dantzig-Wolfe-Decomposition](misc/Ada/Dantzig-Wolfe-Decomposition) | no SPARK |  |  |  |  |
| [misc/Ada/Darwin-Godel-Machine](misc/Ada/Darwin-Godel-Machine) | no SPARK |  |  |  |  |
| [misc/Ada/Data-Flow-Analysis](misc/Ada/Data-Flow-Analysis) | no SPARK |  |  |  |  |
| [misc/Ada/De-Boor](misc/Ada/De-Boor) | no SPARK |  |  |  |  |
| [misc/Ada/De-Casteljau](misc/Ada/De-Casteljau) | no SPARK |  |  |  |  |
| [misc/Ada/Delayed-Column-Generation](misc/Ada/Delayed-Column-Generation) | no SPARK |  |  |  |  |
| [misc/Ada/Delivery-Mission-FSM](misc/Ada/Delivery-Mission-FSM) | proven |  |  |  |  |
| [misc/Ada/Delivery-Safety-Supervisor](misc/Ada/Delivery-Safety-Supervisor) | 8 unproved |  |  |  |  |
| [misc/Ada/Delta-Encoding](misc/Ada/Delta-Encoding) | no SPARK |  |  |  |  |
| [misc/Ada/Demon-Method](misc/Ada/Demon-Method) | no SPARK |  |  |  |  |
| [misc/Ada/Description-Logic](misc/Ada/Description-Logic) | no SPARK |  |  |  |  |
| [misc/Ada/Deutsch-Josza-Algorithm](misc/Ada/Deutsch-Josza-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Dice-Coefficient](misc/Ada/Dice-Coefficient) | no SPARK |  |  |  |  |
| [misc/Ada/Dictionary-Coder](misc/Ada/Dictionary-Coder) | no SPARK |  |  |  |  |
| [misc/Ada/Difference-Map](misc/Ada/Difference-Map) | no SPARK |  |  |  |  |
| [misc/Ada/Differential-Evolution](misc/Ada/Differential-Evolution) | no SPARK |  |  |  |  |
| [misc/Ada/Diffie-Hellman-Key-Exchange](misc/Ada/Diffie-Hellman-Key-Exchange) | no SPARK |  |  |  |  |
| [misc/Ada/Discrete-Event-Simulation](misc/Ada/Discrete-Event-Simulation) | no SPARK |  |  |  |  |
| [misc/Ada/Discrete-Fourier-Transformation](misc/Ada/Discrete-Fourier-Transformation) | no SPARK |  |  |  |  |
| [misc/Ada/Discrete-Logarithm](misc/Ada/Discrete-Logarithm) | no SPARK |  |  |  |  |
| [misc/Ada/Division-Algorithms](misc/Ada/Division-Algorithms) | no SPARK |  |  |  |  |
| [misc/Ada/Doomsday](misc/Ada/Doomsday) | no SPARK |  |  |  |  |
| [misc/Ada/Double-Dabble](misc/Ada/Double-Dabble) | no SPARK |  |  |  |  |
| [misc/Ada/Dynamic-Programming](misc/Ada/Dynamic-Programming) | no SPARK |  |  |  |  |
| [misc/Ada/Dynamic-Time-Warping](misc/Ada/Dynamic-Time-Warping) | no SPARK |  |  |  |  |
| [misc/Ada/EIGamal](misc/Ada/EIGamal) | no SPARK |  |  |  |  |
| [misc/Ada/ESC-Algorithm](misc/Ada/ESC-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Eclat-Algorithm](misc/Ada/Eclat-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/EdDSA](misc/Ada/EdDSA) | no SPARK |  |  |  |  |
| [misc/Ada/Edmonds-Algorithm](misc/Ada/Edmonds-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Elevator-Algorithm](misc/Ada/Elevator-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Elias-Delta-Coding](misc/Ada/Elias-Delta-Coding) | no SPARK |  |  |  |  |
| [misc/Ada/Elias-Gamma-Coding](misc/Ada/Elias-Gamma-Coding) | no SPARK |  |  |  |  |
| [misc/Ada/Elias-Omega-Coding](misc/Ada/Elias-Omega-Coding) | no SPARK |  |  |  |  |
| [misc/Ada/Ellipsoid-Method](misc/Ada/Ellipsoid-Method) | no SPARK |  |  |  |  |
| [misc/Ada/Elser-Difference-Map-Algorithm](misc/Ada/Elser-Difference-Map-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Entropy-Coding](misc/Ada/Entropy-Coding) | no SPARK |  |  |  |  |
| [misc/Ada/Entropy-Coding-With-Known-Entropy-Characteristics](misc/Ada/Entropy-Coding-With-Known-Entropy-Characteristics) | no SPARK |  |  |  |  |
| [misc/Ada/Error-Diffusion](misc/Ada/Error-Diffusion) | no SPARK |  |  |  |  |
| [misc/Ada/Espresso-Heuristic-Logic-Minimizer](misc/Ada/Espresso-Heuristic-Logic-Minimizer) | no SPARK |  |  |  |  |
| [misc/Ada/Estimation-Theory](misc/Ada/Estimation-Theory) | no SPARK |  |  |  |  |
| [misc/Ada/Euclidean-Distance-Transform](misc/Ada/Euclidean-Distance-Transform) | no SPARK |  |  |  |  |
| [misc/Ada/Euler-Integration](misc/Ada/Euler-Integration) | no SPARK |  |  |  |  |
| [misc/Ada/Evolution-Strategy](misc/Ada/Evolution-Strategy) | no SPARK |  |  |  |  |
| [misc/Ada/Evolutionary-Computation](misc/Ada/Evolutionary-Computation) | no SPARK |  |  |  |  |
| [misc/Ada/Exact-Cover](misc/Ada/Exact-Cover) | no SPARK |  |  |  |  |
| [misc/Ada/Exponential-Backoff](misc/Ada/Exponential-Backoff) | no SPARK |  |  |  |  |
| [misc/Ada/Exponential-Golomb-Coding](misc/Ada/Exponential-Golomb-Coding) | no SPARK |  |  |  |  |
| [misc/Ada/Exponentiating-By-Squaring](misc/Ada/Exponentiating-By-Squaring) | no SPARK |  |  |  |  |
| [misc/Ada/FP-Growth-Algorithm](misc/Ada/FP-Growth-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/False-Nearest-Neighbor](misc/Ada/False-Nearest-Neighbor) | no SPARK |  |  |  |  |
| [misc/Ada/False-Position-Method](misc/Ada/False-Position-Method) | no SPARK |  |  |  |  |
| [misc/Ada/Fast-Cosine-Transform-Algorithms](misc/Ada/Fast-Cosine-Transform-Algorithms) | no SPARK |  |  |  |  |
| [misc/Ada/Fast-Folding-Algorithm](misc/Ada/Fast-Folding-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Fast-Multipole-Method](misc/Ada/Fast-Multipole-Method) | no SPARK |  |  |  |  |
| [misc/Ada/Faugere-F4](misc/Ada/Faugere-F4) | no SPARK |  |  |  |  |
| [misc/Ada/Featherstone](misc/Ada/Featherstone) | no SPARK |  |  |  |  |
| [misc/Ada/Feature-Detection](misc/Ada/Feature-Detection) | no SPARK |  |  |  |  |
| [misc/Ada/Fermat-Factorization](misc/Ada/Fermat-Factorization) | no SPARK |  |  |  |  |
| [misc/Ada/Fibonacci-Coding](misc/Ada/Fibonacci-Coding) | no SPARK |  |  |  |  |
| [misc/Ada/Fictitious-Play](misc/Ada/Fictitious-Play) | no SPARK |  |  |  |  |
| [misc/Ada/Filtered-Back-Projection](misc/Ada/Filtered-Back-Projection) | no SPARK |  |  |  |  |
| [misc/Ada/Financial-Information-Exchange](misc/Ada/Financial-Information-Exchange) | no SPARK |  |  |  |  |
| [misc/Ada/Financial-Risk-Modeling](misc/Ada/Financial-Risk-Modeling) | not built |  |  |  |  |
| [misc/Ada/Finite-Difference-Method](misc/Ada/Finite-Difference-Method) | no SPARK |  |  |  |  |
| [misc/Ada/First-Order-Logic](misc/Ada/First-Order-Logic) | no SPARK |  |  |  |  |
| [misc/Ada/Fisher-Yates-Shuffle](misc/Ada/Fisher-Yates-Shuffle) | no SPARK |  |  |  |  |
| [misc/Ada/Fitness-Proportionate-Selection](misc/Ada/Fitness-Proportionate-Selection) | no SPARK |  |  |  |  |
| [misc/Ada/Fletchers-Checksum](misc/Ada/Fletchers-Checksum) | no SPARK |  |  |  |  |
| [misc/Ada/Flood-Fill](misc/Ada/Flood-Fill) | no SPARK |  |  |  |  |
| [misc/Ada/Flow-Networks](misc/Ada/Flow-Networks) | no SPARK |  |  |  |  |
| [misc/Ada/Force-Based-Algorithms](misc/Ada/Force-Based-Algorithms) | no SPARK |  |  |  |  |
| [misc/Ada/Fortunes-Algorithm](misc/Ada/Fortunes-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Forward-Error-Correction](misc/Ada/Forward-Error-Correction) | no SPARK |  |  |  |  |
| [misc/Ada/Foundations-Curriculum](misc/Ada/Foundations-Curriculum) | no SPARK |  |  |  |  |
| [misc/Ada/Fowler-Noll-Vo](misc/Ada/Fowler-Noll-Vo) | no SPARK |  |  |  |  |
| [misc/Ada/Frank-Wolfe-Algorithm](misc/Ada/Frank-Wolfe-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Freivalds](misc/Ada/Freivalds) | no SPARK |  |  |  |  |
| [misc/Ada/Fuzzy-C-Means](misc/Ada/Fuzzy-C-Means) | no SPARK |  |  |  |  |
| [misc/Ada/GNAT-Studio-Notes](misc/Ada/GNAT-Studio-Notes) | proven |  |  |  |  |
| [misc/Ada/GPU-Work-Queue](misc/Ada/GPU-Work-Queue) | proven |  |  |  |  |
| [misc/Ada/GRASP](misc/Ada/GRASP) | no SPARK |  |  |  |  |
| [misc/Ada/Gale-Shapley-Algorithm](misc/Ada/Gale-Shapley-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Gauss-Jordan](misc/Ada/Gauss-Jordan) | no SPARK |  |  |  |  |
| [misc/Ada/Gauss-Seidel](misc/Ada/Gauss-Seidel) | no SPARK |  |  |  |  |
| [misc/Ada/Gene-Expression-Programming](misc/Ada/Gene-Expression-Programming) | no SPARK |  |  |  |  |
| [misc/Ada/General-Problem-Solver](misc/Ada/General-Problem-Solver) | no SPARK |  |  |  |  |
| [misc/Ada/Generational-Garbage-Collector](misc/Ada/Generational-Garbage-Collector) | no SPARK |  |  |  |  |
| [misc/Ada/Genetic-Algorithms](misc/Ada/Genetic-Algorithms) | no SPARK |  |  |  |  |
| [misc/Ada/Gerchberg-Saxton-Algorithm](misc/Ada/Gerchberg-Saxton-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Gibbs-Sampling](misc/Ada/Gibbs-Sampling) | no SPARK |  |  |  |  |
| [misc/Ada/Gilbert-Johnson-Keerthi](misc/Ada/Gilbert-Johnson-Keerthi) | no SPARK |  |  |  |  |
| [misc/Ada/Glauber-Dynamics](misc/Ada/Glauber-Dynamics) | no SPARK |  |  |  |  |
| [misc/Ada/Global-Illumination](misc/Ada/Global-Illumination) | no SPARK |  |  |  |  |
| [misc/Ada/Goertzel-Algorithm](misc/Ada/Goertzel-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Goldschmidt-Division](misc/Ada/Goldschmidt-Division) | no SPARK |  |  |  |  |
| [misc/Ada/Golomb-Coding](misc/Ada/Golomb-Coding) | no SPARK |  |  |  |  |
| [misc/Ada/Gospers-Algorithm](misc/Ada/Gospers-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Gram-Schmidt](misc/Ada/Gram-Schmidt) | no SPARK |  |  |  |  |
| [misc/Ada/Gray-Code](misc/Ada/Gray-Code) | no SPARK |  |  |  |  |
| [misc/Ada/Ground-State](misc/Ada/Ground-State) | no SPARK |  |  |  |  |
| [misc/Ada/Grovers-Algorithm](misc/Ada/Grovers-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/GrowCut](misc/Ada/GrowCut) | no SPARK |  |  |  |  |
| [misc/Ada/HHL-Algorithm](misc/Ada/HHL-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Hadamard-Test](misc/Ada/Hadamard-Test) | no SPARK |  |  |  |  |
| [misc/Ada/Hadamard-Transform](misc/Ada/Hadamard-Transform) | no SPARK |  |  |  |  |
| [misc/Ada/Half-Toning](misc/Ada/Half-Toning) | no SPARK |  |  |  |  |
| [misc/Ada/Halleys-Method](misc/Ada/Halleys-Method) | no SPARK |  |  |  |  |
| [misc/Ada/Hamiltonian-Simulation](misc/Ada/Hamiltonian-Simulation) | no SPARK |  |  |  |  |
| [misc/Ada/Hamming-7-4](misc/Ada/Hamming-7-4) | no SPARK |  |  |  |  |
| [misc/Ada/Hamming-Code](misc/Ada/Hamming-Code) | no SPARK |  |  |  |  |
| [misc/Ada/Hamming-Weight](misc/Ada/Hamming-Weight) | no SPARK |  |  |  |  |
| [misc/Ada/Heaps-Algorithm](misc/Ada/Heaps-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Hidden-Linear-Function-Problem](misc/Ada/Hidden-Linear-Function-Problem) | no SPARK |  |  |  |  |
| [misc/Ada/Hidden-Shift-Problem](misc/Ada/Hidden-Shift-Problem) | no SPARK |  |  |  |  |
| [misc/Ada/Hidden-Subgroup-Problem](misc/Ada/Hidden-Subgroup-Problem) | no SPARK |  |  |  |  |
| [misc/Ada/Hidden-Surface-Removal](misc/Ada/Hidden-Surface-Removal) | no SPARK |  |  |  |  |
| [misc/Ada/Hindley-Milner-Type-Inference-Algorithm](misc/Ada/Hindley-Milner-Type-Inference-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Hindley-Milner-Type-System](misc/Ada/Hindley-Milner-Type-System) | no SPARK |  |  |  |  |
| [misc/Ada/Hirschbergs-Algorithm](misc/Ada/Hirschbergs-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Hopcroft-Karp-Algorithm](misc/Ada/Hopcroft-Karp-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Hopcrofts-Algorithm](misc/Ada/Hopcrofts-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Hopfield-Net](misc/Ada/Hopfield-Net) | no SPARK |  |  |  |  |
| [misc/Ada/Huangs-Algorithm](misc/Ada/Huangs-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Hybrid-Algorithms](misc/Ada/Hybrid-Algorithms) | no SPARK |  |  |  |  |
| [misc/Ada/ID3-Algorithm](misc/Ada/ID3-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/ITP-Method](misc/Ada/ITP-Method) | no SPARK |  |  |  |  |
| [misc/Ada/Image-Based-Lighting](misc/Ada/Image-Based-Lighting) | no SPARK |  |  |  |  |
| [misc/Ada/Incremental-Encoding](misc/Ada/Incremental-Encoding) | no SPARK |  |  |  |  |
| [misc/Ada/Index-Calculus](misc/Ada/Index-Calculus) | no SPARK |  |  |  |  |
| [misc/Ada/Inside-Out-Algorithm](misc/Ada/Inside-Out-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Integer-Factorization](misc/Ada/Integer-Factorization) | no SPARK |  |  |  |  |
| [misc/Ada/Integer-Linear-Programming](misc/Ada/Integer-Linear-Programming) | no SPARK |  |  |  |  |
| [misc/Ada/Intersection-Algorithm](misc/Ada/Intersection-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Inverse-Iteration](misc/Ada/Inverse-Iteration) | no SPARK |  |  |  |  |
| [misc/Ada/Johnsons-Algorithm](misc/Ada/Johnsons-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Jump-And-Walk](misc/Ada/Jump-And-Walk) | no SPARK |  |  |  |  |
| [misc/Ada/K-Nearest-Neighbours](misc/Ada/K-Nearest-Neighbours) | no SPARK |  |  |  |  |
| [misc/Ada/K-Way-Merge](misc/Ada/K-Way-Merge) | no SPARK |  |  |  |  |
| [misc/Ada/Kabsch](misc/Ada/Kabsch) | no SPARK |  |  |  |  |
| [misc/Ada/Kadanes-Algorithm](misc/Ada/Kadanes-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Kahan-Summation](misc/Ada/Kahan-Summation) | no SPARK |  |  |  |  |
| [misc/Ada/Kalman-Filter](misc/Ada/Kalman-Filter) | no SPARK |  |  |  |  |
| [misc/Ada/Kargers-Algorithm](misc/Ada/Kargers-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Karmarkars-Algorithm](misc/Ada/Karmarkars-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Karn-Algorithm](misc/Ada/Karn-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Key-Derivation-Function](misc/Ada/Key-Derivation-Function) | no SPARK |  |  |  |  |
| [misc/Ada/Key-Exchange](misc/Ada/Key-Exchange) | no SPARK |  |  |  |  |
| [misc/Ada/Knuth-Bendix-Completion](misc/Ada/Knuth-Bendix-Completion) | proven |  |  |  |  |
| [misc/Ada/Krauss-Matching-Wildcards](misc/Ada/Krauss-Matching-Wildcards) | no SPARK |  |  |  |  |
| [misc/Ada/Lagged-Fibonacci-Generator](misc/Ada/Lagged-Fibonacci-Generator) | no SPARK |  |  |  |  |
| [misc/Ada/Laplacian-Smoothing](misc/Ada/Laplacian-Smoothing) | no SPARK |  |  |  |  |
| [misc/Ada/Lax-Wendroff](misc/Ada/Lax-Wendroff) | no SPARK |  |  |  |  |
| [misc/Ada/Lemke-Howson](misc/Ada/Lemke-Howson) | no SPARK |  |  |  |  |
| [misc/Ada/Lempel-Ziv-Jeff-Bonwick](misc/Ada/Lempel-Ziv-Jeff-Bonwick) | no SPARK |  |  |  |  |
| [misc/Ada/Lempel-Ziv-Markov-Chain-Algorithm](misc/Ada/Lempel-Ziv-Markov-Chain-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Lempel-Ziv-Oberhurmer](misc/Ada/Lempel-Ziv-Oberhurmer) | no SPARK |  |  |  |  |
| [misc/Ada/Lempel-Ziv-Ross-Williams](misc/Ada/Lempel-Ziv-Ross-Williams) | no SPARK |  |  |  |  |
| [misc/Ada/Lempel-Ziv-Stac](misc/Ada/Lempel-Ziv-Stac) | no SPARK |  |  |  |  |
| [misc/Ada/Lempel-Ziv-Storer-Szymanski](misc/Ada/Lempel-Ziv-Storer-Szymanski) | no SPARK |  |  |  |  |
| [misc/Ada/Lempel-Ziv-Welch](misc/Ada/Lempel-Ziv-Welch) | no SPARK |  |  |  |  |
| [misc/Ada/Lenstra-Lenstra-Lovasz](misc/Ada/Lenstra-Lenstra-Lovasz) | no SPARK |  |  |  |  |
| [misc/Ada/Lesk](misc/Ada/Lesk) | no SPARK |  |  |  |  |
| [misc/Ada/Level-Set-Method](misc/Ada/Level-Set-Method) | no SPARK |  |  |  |  |
| [misc/Ada/Levinson-Recursion](misc/Ada/Levinson-Recursion) | no SPARK |  |  |  |  |
| [misc/Ada/Lexical-Analysis](misc/Ada/Lexical-Analysis) | no SPARK |  |  |  |  |
| [misc/Ada/Linde-Buzo-Gray](misc/Ada/Linde-Buzo-Gray) | no SPARK |  |  |  |  |
| [misc/Ada/Linde-Buzo-Gray-Algorithm](misc/Ada/Linde-Buzo-Gray-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Line-Drawing](misc/Ada/Line-Drawing) | no SPARK |  |  |  |  |
| [misc/Ada/Linear-Feedback-Shift-Register](misc/Ada/Linear-Feedback-Shift-Register) | no SPARK |  |  |  |  |
| [misc/Ada/Linear-Multistep-Methods](misc/Ada/Linear-Multistep-Methods) | no SPARK |  |  |  |  |
| [misc/Ada/Linear-Predictive-Coding](misc/Ada/Linear-Predictive-Coding) | no SPARK |  |  |  |  |
| [misc/Ada/Linear-Programming](misc/Ada/Linear-Programming) | no SPARK |  |  |  |  |
| [misc/Ada/List-Scheduling](misc/Ada/List-Scheduling) | no SPARK |  |  |  |  |
| [misc/Ada/Locomotion-Mode-Interlock](misc/Ada/Locomotion-Mode-Interlock) | proven |  |  |  |  |
| [misc/Ada/Long-Division](misc/Ada/Long-Division) | no SPARK |  |  |  |  |
| [misc/Ada/Longest-Increasing-Subsequence](misc/Ada/Longest-Increasing-Subsequence) | no SPARK |  |  |  |  |
| [misc/Ada/Longest-Path-Problem](misc/Ada/Longest-Path-Problem) | no SPARK |  |  |  |  |
| [misc/Ada/Longitudinal-Redundacy-Check](misc/Ada/Longitudinal-Redundacy-Check) | no SPARK |  |  |  |  |
| [misc/Ada/Luhn-Algorithm](misc/Ada/Luhn-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Luhn-Mod-N-Algorithm](misc/Ada/Luhn-Mod-N-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Luleas-Algorithm](misc/Ada/Luleas-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Maekawas-Algorithm](misc/Ada/Maekawas-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Manning-Criteria](misc/Ada/Manning-Criteria) | no SPARK |  |  |  |  |
| [misc/Ada/Marching-Squares](misc/Ada/Marching-Squares) | no SPARK |  |  |  |  |
| [misc/Ada/Marching-Tetrahedrons](misc/Ada/Marching-Tetrahedrons) | no SPARK |  |  |  |  |
| [misc/Ada/Marching-Triangles](misc/Ada/Marching-Triangles) | no SPARK |  |  |  |  |
| [misc/Ada/Mark-Compact-Algorithm](misc/Ada/Mark-Compact-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Mark-and-Sweep](misc/Ada/Mark-and-Sweep) | no SPARK |  |  |  |  |
| [misc/Ada/Marr-Hildreth-Algorithm](misc/Ada/Marr-Hildreth-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Marzullos-Algorithm](misc/Ada/Marzullos-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Match-Rating-Approach](misc/Ada/Match-Rating-Approach) | no SPARK |  |  |  |  |
| [misc/Ada/Matching-Wildcards](misc/Ada/Matching-Wildcards) | no SPARK |  |  |  |  |
| [misc/Ada/Maximum-Parsimony](misc/Ada/Maximum-Parsimony) | no SPARK |  |  |  |  |
| [misc/Ada/Mechanistic-Interpretability](misc/Ada/Mechanistic-Interpretability) | no SPARK |  |  |  |  |
| [misc/Ada/Median-Filtering](misc/Ada/Median-Filtering) | no SPARK |  |  |  |  |
| [misc/Ada/Memetic-Algorithm](misc/Ada/Memetic-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Memory-Channel-Model](misc/Ada/Memory-Channel-Model) | proven |  |  |  |  |
| [misc/Ada/Message-Authentication-Codes](misc/Ada/Message-Authentication-Codes) | no SPARK |  |  |  |  |
| [misc/Ada/Midpoint-Circle-Algorithm](misc/Ada/Midpoint-Circle-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Min-Conflicts](misc/Ada/Min-Conflicts) | no SPARK |  |  |  |  |
| [misc/Ada/Minimax](misc/Ada/Minimax) | no SPARK |  |  |  |  |
| [misc/Ada/Minimum-Bounding-Box](misc/Ada/Minimum-Bounding-Box) | no SPARK |  |  |  |  |
| [misc/Ada/Minimum-Degree](misc/Ada/Minimum-Degree) | no SPARK |  |  |  |  |
| [misc/Ada/Mirror-Descent](misc/Ada/Mirror-Descent) | no SPARK |  |  |  |  |
| [misc/Ada/Modular-Square-Root](misc/Ada/Modular-Square-Root) | no SPARK |  |  |  |  |
| [misc/Ada/Montgomery-Reduction](misc/Ada/Montgomery-Reduction) | no SPARK |  |  |  |  |
| [misc/Ada/Moores-Algorithm](misc/Ada/Moores-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Mu-Law-Algorithm](misc/Ada/Mu-Law-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Mullers-Method](misc/Ada/Mullers-Method) | no SPARK |  |  |  |  |
| [misc/Ada/Multigrid-Methods](misc/Ada/Multigrid-Methods) | no SPARK |  |  |  |  |
| [misc/Ada/Multiplication-Algorithms](misc/Ada/Multiplication-Algorithms) | no SPARK |  |  |  |  |
| [misc/Ada/Multiplicative-Inverse-Algorithms](misc/Ada/Multiplicative-Inverse-Algorithms) | no SPARK |  |  |  |  |
| [misc/Ada/Multiplicative-Weight-Update-Method](misc/Ada/Multiplicative-Weight-Update-Method) | no SPARK |  |  |  |  |
| [misc/Ada/Multivariate-Division-Algorithm](misc/Ada/Multivariate-Division-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/N-Body-Problems](misc/Ada/N-Body-Problems) | no SPARK |  |  |  |  |
| [misc/Ada/NEF-Adaptive-OSC](misc/Ada/NEF-Adaptive-OSC) | no SPARK |  |  |  |  |
| [misc/Ada/NEF-Neurorobotics-Core](misc/Ada/NEF-Neurorobotics-Core) | no SPARK |  |  |  |  |
| [misc/Ada/Nagles-Algorithm](misc/Ada/Nagles-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Naimi-Trehel](misc/Ada/Naimi-Trehel) | no SPARK |  |  |  |  |
| [misc/Ada/Nearest-Neighbor-Algorithm](misc/Ada/Nearest-Neighbor-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Nelder-Mead](misc/Ada/Nelder-Mead) | no SPARK |  |  |  |  |
| [misc/Ada/Nested-Loop-Join](misc/Ada/Nested-Loop-Join) | no SPARK |  |  |  |  |
| [misc/Ada/Nested-Sampling](misc/Ada/Nested-Sampling) | no SPARK |  |  |  |  |
| [misc/Ada/Nesting-Algorithm](misc/Ada/Nesting-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Newton-Multiplicative-Inverse](misc/Ada/Newton-Multiplicative-Inverse) | no SPARK |  |  |  |  |
| [misc/Ada/Newtons-Method](misc/Ada/Newtons-Method) | no SPARK |  |  |  |  |
| [misc/Ada/Newtons-Method-in-Optimization](misc/Ada/Newtons-Method-in-Optimization) | no SPARK |  |  |  |  |
| [misc/Ada/Nicholl-Lee-Nicholl](misc/Ada/Nicholl-Lee-Nicholl) | no SPARK |  |  |  |  |
| [misc/Ada/Non-Local-Quantum-Computation](misc/Ada/Non-Local-Quantum-Computation) | no SPARK |  |  |  |  |
| [misc/Ada/Non-Restoring-Division](misc/Ada/Non-Restoring-Division) | no SPARK |  |  |  |  |
| [misc/Ada/Nonblocking-Minimal-Spanning-Switch](misc/Ada/Nonblocking-Minimal-Spanning-Switch) | no SPARK |  |  |  |  |
| [misc/Ada/Nonlinear-Optimization](misc/Ada/Nonlinear-Optimization) | no SPARK |  |  |  |  |
| [misc/Ada/Nth-Root](misc/Ada/Nth-Root) | no SPARK |  |  |  |  |
| [misc/Ada/Nucleolus](misc/Ada/Nucleolus) | no SPARK |  |  |  |  |
| [misc/Ada/Odds-Algorithm](misc/Ada/Odds-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Odlyzko-Schonhage](misc/Ada/Odlyzko-Schonhage) | no SPARK |  |  |  |  |
| [misc/Ada/One-Attribute-Rule](misc/Ada/One-Attribute-Rule) | no SPARK |  |  |  |  |
| [misc/Ada/Operations-Research](misc/Ada/Operations-Research) | no SPARK |  |  |  |  |
| [misc/Ada/Orbital-Mechanics](misc/Ada/Orbital-Mechanics) | timeout |  |  |  |  |
| [misc/Ada/Ordered-Subset-EM](misc/Ada/Ordered-Subset-EM) | no SPARK |  |  |  |  |
| [misc/Ada/PBKDF2](misc/Ada/PBKDF2) | no SPARK |  |  |  |  |
| [misc/Ada/PCIe-Transfer-Model](misc/Ada/PCIe-Transfer-Model) | proven |  |  |  |  |
| [misc/Ada/Package-Merge-Algorithm](misc/Ada/Package-Merge-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Painters-Algorithm](misc/Ada/Painters-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Parity-Bit](misc/Ada/Parity-Bit) | no SPARK |  |  |  |  |
| [misc/Ada/Partial-Differential-Equation](misc/Ada/Partial-Differential-Equation) | no SPARK |  |  |  |  |
| [misc/Ada/Particle-Swarm](misc/Ada/Particle-Swarm) | no SPARK |  |  |  |  |
| [misc/Ada/Path-Based-Strong-Component](misc/Ada/Path-Based-Strong-Component) | no SPARK |  |  |  |  |
| [misc/Ada/Path-Tracing](misc/Ada/Path-Tracing) | no SPARK |  |  |  |  |
| [misc/Ada/Petricks-Method](misc/Ada/Petricks-Method) | no SPARK |  |  |  |  |
| [misc/Ada/Phonetic-Algorithms](misc/Ada/Phonetic-Algorithms) | no SPARK |  |  |  |  |
| [misc/Ada/Photon-Mapping](misc/Ada/Photon-Mapping) | not built |  |  |  |  |
| [misc/Ada/Planning-Domain-Definition-Language](misc/Ada/Planning-Domain-Definition-Language) | no SPARK |  |  |  |  |
| [misc/Ada/Pohlig-Hellman](misc/Ada/Pohlig-Hellman) | no SPARK |  |  |  |  |
| [misc/Ada/Point-Set-Registration](misc/Ada/Point-Set-Registration) | no SPARK |  |  |  |  |
| [misc/Ada/Poly1305](misc/Ada/Poly1305) | no SPARK |  |  |  |  |
| [misc/Ada/Polynomial-Long-Division](misc/Ada/Polynomial-Long-Division) | no SPARK |  |  |  |  |
| [misc/Ada/Power-Iteration](misc/Ada/Power-Iteration) | no SPARK |  |  |  |  |
| [misc/Ada/Powerset-Construction](misc/Ada/Powerset-Construction) | no SPARK |  |  |  |  |
| [misc/Ada/Prediction-By-Partial-Matching](misc/Ada/Prediction-By-Partial-Matching) | no SPARK |  |  |  |  |
| [misc/Ada/Program-Synthesis](misc/Ada/Program-Synthesis) | no SPARK |  |  |  |  |
| [misc/Ada/Progressive-Jackpot](misc/Ada/Progressive-Jackpot) | no SPARK |  |  |  |  |
| [misc/Ada/Proof-Of-Work-Algorithms](misc/Ada/Proof-Of-Work-Algorithms) | no SPARK |  |  |  |  |
| [misc/Ada/Prufer-Coding](misc/Ada/Prufer-Coding) | no SPARK |  |  |  |  |
| [misc/Ada/Pseudorandom-Number-Generator](misc/Ada/Pseudorandom-Number-Generator) | no SPARK |  |  |  |  |
| [misc/Ada/Pulmonary-Embolism-Algorithms](misc/Ada/Pulmonary-Embolism-Algorithms) | no SPARK |  |  |  |  |
| [misc/Ada/Push-Relabel-Algorithm](misc/Ada/Push-Relabel-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/QR-Algorithm](misc/Ada/QR-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Quantum-Annealing](misc/Ada/Quantum-Annealing) | no SPARK |  |  |  |  |
| [misc/Ada/Quantum-Artificial-Life](misc/Ada/Quantum-Artificial-Life) | no SPARK |  |  |  |  |
| [misc/Ada/Quantum-Counting-Algorithm](misc/Ada/Quantum-Counting-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Quantum-Fourier-Transform](misc/Ada/Quantum-Fourier-Transform) | no SPARK |  |  |  |  |
| [misc/Ada/Quantum-Optimization-Algorithms](misc/Ada/Quantum-Optimization-Algorithms) | no SPARK |  |  |  |  |
| [misc/Ada/Quantum-Phase-Estimation-Algorithm](misc/Ada/Quantum-Phase-Estimation-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Queuing-Theory](misc/Ada/Queuing-Theory) | no SPARK |  |  |  |  |
| [misc/Ada/Quine-McCluskey-Algorithm](misc/Ada/Quine-McCluskey-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/RANSAC](misc/Ada/RANSAC) | no SPARK |  |  |  |  |
| [misc/Ada/RIPEMD-160](misc/Ada/RIPEMD-160) | no SPARK |  |  |  |  |
| [misc/Ada/Radial-Basis-Function-Network](misc/Ada/Radial-Basis-Function-Network) | no SPARK |  |  |  |  |
| [misc/Ada/Rainflow-Counting](misc/Ada/Rainflow-Counting) | no SPARK |  |  |  |  |
| [misc/Ada/Random-Restart-Hill-Climbing](misc/Ada/Random-Restart-Hill-Climbing) | no SPARK |  |  |  |  |
| [misc/Ada/Random-Walker](misc/Ada/Random-Walker) | no SPARK |  |  |  |  |
| [misc/Ada/Range-Encoding](misc/Ada/Range-Encoding) | no SPARK |  |  |  |  |
| [misc/Ada/Rayleigh-Quotient-Iteration](misc/Ada/Rayleigh-Quotient-Iteration) | no SPARK |  |  |  |  |
| [misc/Ada/Rayleigh-Ritz-Method](misc/Ada/Rayleigh-Ritz-Method) | no SPARK |  |  |  |  |
| [misc/Ada/Raymonds-Algorithm](misc/Ada/Raymonds-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Recovery-Exploiting-Semantics](misc/Ada/Recovery-Exploiting-Semantics) | no SPARK |  |  |  |  |
| [misc/Ada/Redundancy-Checks](misc/Ada/Redundancy-Checks) | no SPARK |  |  |  |  |
| [misc/Ada/Reed-Solomon-Error-Correction](misc/Ada/Reed-Solomon-Error-Correction) | no SPARK |  |  |  |  |
| [misc/Ada/Reference-Counting](misc/Ada/Reference-Counting) | no SPARK |  |  |  |  |
| [misc/Ada/Region-Growing](misc/Ada/Region-Growing) | no SPARK |  |  |  |  |
| [misc/Ada/Regret-Minimization](misc/Ada/Regret-Minimization) | no SPARK |  |  |  |  |
| [misc/Ada/Relevance-Vector-Machine](misc/Ada/Relevance-Vector-Machine) | no SPARK |  |  |  |  |
| [misc/Ada/Replicator-Equation](misc/Ada/Replicator-Equation) | no SPARK |  |  |  |  |
| [misc/Ada/Restoring-Division](misc/Ada/Restoring-Division) | no SPARK |  |  |  |  |
| [misc/Ada/Rete-Algorithm](misc/Ada/Rete-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Reverse-Delete-Algorithm](misc/Ada/Reverse-Delete-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Ricart-Agrawala-Algorithm](misc/Ada/Ricart-Agrawala-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Rice-Coding](misc/Ada/Rice-Coding) | no SPARK |  |  |  |  |
| [misc/Ada/Richardson-Lucy-Deconvolution](misc/Ada/Richardson-Lucy-Deconvolution) | no SPARK |  |  |  |  |
| [misc/Ada/Ridders-Method](misc/Ada/Ridders-Method) | no SPARK |  |  |  |  |
| [misc/Ada/Risch-Algorithm](misc/Ada/Risch-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Rotating-Calipers](misc/Ada/Rotating-Calipers) | no SPARK |  |  |  |  |
| [misc/Ada/Rounding-Functions](misc/Ada/Rounding-Functions) | no SPARK |  |  |  |  |
| [misc/Ada/Rupperts-Algorithm](misc/Ada/Rupperts-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Ruzzo-Tompa](misc/Ada/Ruzzo-Tompa) | no SPARK |  |  |  |  |
| [misc/Ada/SEQUITUR-Algorithm](misc/Ada/SEQUITUR-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/SRT-Division](misc/Ada/SRT-Division) | no SPARK |  |  |  |  |
| [misc/Ada/SSS-Star](misc/Ada/SSS-Star) | no SPARK |  |  |  |  |
| [misc/Ada/SUBCLU](misc/Ada/SUBCLU) | no SPARK |  |  |  |  |
| [misc/Ada/Salsa20](misc/Ada/Salsa20) | no SPARK |  |  |  |  |
| [misc/Ada/Scale-Invariant-Feature-Transform](misc/Ada/Scale-Invariant-Feature-Transform) | no SPARK |  |  |  |  |
| [misc/Ada/Scanline-Rendering](misc/Ada/Scanline-Rendering) | no SPARK |  |  |  |  |
| [misc/Ada/Schensted](misc/Ada/Schensted) | no SPARK |  |  |  |  |
| [misc/Ada/Schreier-Sims](misc/Ada/Schreier-Sims) | no SPARK |  |  |  |  |
| [misc/Ada/Scoring-Algorithm](misc/Ada/Scoring-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Seam-Carving](misc/Ada/Seam-Carving) | no SPARK |  |  |  |  |
| [misc/Ada/Secret-Sharing](misc/Ada/Secret-Sharing) | no SPARK |  |  |  |  |
| [misc/Ada/Selection-Algorithm](misc/Ada/Selection-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Self-Organizing-Map](misc/Ada/Self-Organizing-Map) | no SPARK |  |  |  |  |
| [misc/Ada/Semi-Space-Collectors](misc/Ada/Semi-Space-Collectors) | no SPARK |  |  |  |  |
| [misc/Ada/Sethi-Ullman-Algorithm](misc/Ada/Sethi-Ullman-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Shannon-Fano-Coding](misc/Ada/Shannon-Fano-Coding) | no SPARK |  |  |  |  |
| [misc/Ada/Shannon-Fano-Elias-Coding](misc/Ada/Shannon-Fano-Elias-Coding) | no SPARK |  |  |  |  |
| [misc/Ada/Shapley-Value](misc/Ada/Shapley-Value) | no SPARK |  |  |  |  |
| [misc/Ada/Shoelace-Algorithm](misc/Ada/Shoelace-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Shors-Algorithm](misc/Ada/Shors-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Shortest-Common-Supersequence-Problem](misc/Ada/Shortest-Common-Supersequence-Problem) | no SPARK |  |  |  |  |
| [misc/Ada/Simons-Problem](misc/Ada/Simons-Problem) | no SPARK |  |  |  |  |
| [misc/Ada/Simulated-Annealing](misc/Ada/Simulated-Annealing) | no SPARK |  |  |  |  |
| [misc/Ada/Sinkhorn-Knopp-Algorithm](misc/Ada/Sinkhorn-Knopp-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Slot-Machine](misc/Ada/Slot-Machine) | no SPARK |  |  |  |  |
| [misc/Ada/Spectral-Layout](misc/Ada/Spectral-Layout) | no SPARK |  |  |  |  |
| [misc/Ada/Speeded-Up-Robust-Features](misc/Ada/Speeded-Up-Robust-Features) | no SPARK |  |  |  |  |
| [misc/Ada/Spigot-Algorithm](misc/Ada/Spigot-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Square-Root-Algorithms](misc/Ada/Square-Root-Algorithms) | no SPARK |  |  |  |  |
| [misc/Ada/State-Action-Reward-State-Action](misc/Ada/State-Action-Reward-State-Action) | no SPARK |  |  |  |  |
| [misc/Ada/Steinhaus-Johnson-Trotter](misc/Ada/Steinhaus-Johnson-Trotter) | no SPARK |  |  |  |  |
| [misc/Ada/Stochastic-Tunneling](misc/Ada/Stochastic-Tunneling) | no SPARK |  |  |  |  |
| [misc/Ada/Stones-Method](misc/Ada/Stones-Method) | no SPARK |  |  |  |  |
| [misc/Ada/Strongly-Connected-Components](misc/Ada/Strongly-Connected-Components) | no SPARK |  |  |  |  |
| [misc/Ada/Structured-SVM](misc/Ada/Structured-SVM) | no SPARK |  |  |  |  |
| [misc/Ada/Subset-Sum-Algorithm](misc/Ada/Subset-Sum-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Successive-Over-Relaxation](misc/Ada/Successive-Over-Relaxation) | no SPARK |  |  |  |  |
| [misc/Ada/Sukhotin](misc/Ada/Sukhotin) | no SPARK |  |  |  |  |
| [misc/Ada/Summed-Area-Table](misc/Ada/Summed-Area-Table) | no SPARK |  |  |  |  |
| [misc/Ada/Supervised-Learning](misc/Ada/Supervised-Learning) | no SPARK |  |  |  |  |
| [misc/Ada/Swap-Test](misc/Ada/Swap-Test) | no SPARK |  |  |  |  |
| [misc/Ada/Swarm-Intelligence](misc/Ada/Swarm-Intelligence) | no SPARK |  |  |  |  |
| [misc/Ada/Sweep-And-Prune](misc/Ada/Sweep-And-Prune) | no SPARK |  |  |  |  |
| [misc/Ada/System-of-Linear-Equations](misc/Ada/System-of-Linear-Equations) | no SPARK |  |  |  |  |
| [misc/Ada/Tarski-Kuratowski-Algorithm](misc/Ada/Tarski-Kuratowski-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Temporal-Difference-Learning](misc/Ada/Temporal-Difference-Learning) | no SPARK |  |  |  |  |
| [misc/Ada/Term-Rewriting](misc/Ada/Term-Rewriting) | no SPARK |  |  |  |  |
| [misc/Ada/Texas-Medication-Algorithm-Project](misc/Ada/Texas-Medication-Algorithm-Project) | no SPARK |  |  |  |  |
| [misc/Ada/Thomas-Algorithm](misc/Ada/Thomas-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Todd-Coxeter](misc/Ada/Todd-Coxeter) | no SPARK |  |  |  |  |
| [misc/Ada/Tomasulo-Algorithm](misc/Ada/Tomasulo-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Toom-Cook](misc/Ada/Toom-Cook) | no SPARK |  |  |  |  |
| [misc/Ada/Top-Nodes-Algorithm](misc/Ada/Top-Nodes-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Top-Trading-Cycle](misc/Ada/Top-Trading-Cycle) | no SPARK |  |  |  |  |
| [misc/Ada/Traffic-Light-Controller](misc/Ada/Traffic-Light-Controller) | no SPARK |  |  |  |  |
| [misc/Ada/Traffic-Simulation](misc/Ada/Traffic-Simulation) | not built |  |  |  |  |
| [misc/Ada/Transform-Coding](misc/Ada/Transform-Coding) | no SPARK |  |  |  |  |
| [misc/Ada/Transitive-Closure](misc/Ada/Transitive-Closure) | no SPARK |  |  |  |  |
| [misc/Ada/Trapezoidal-Rule-DE](misc/Ada/Trapezoidal-Rule-DE) | no SPARK |  |  |  |  |
| [misc/Ada/Travelling-Salesman-Problem](misc/Ada/Travelling-Salesman-Problem) | no SPARK |  |  |  |  |
| [misc/Ada/Trial-Division](misc/Ada/Trial-Division) | no SPARK |  |  |  |  |
| [misc/Ada/Truncated-Binary-Encoding](misc/Ada/Truncated-Binary-Encoding) | no SPARK |  |  |  |  |
| [misc/Ada/Truncated-Binary-Exponential-Backoff](misc/Ada/Truncated-Binary-Exponential-Backoff) | no SPARK |  |  |  |  |
| [misc/Ada/Truncation-Selection](misc/Ada/Truncation-Selection) | no SPARK |  |  |  |  |
| [misc/Ada/TrustRank](misc/Ada/TrustRank) | no SPARK |  |  |  |  |
| [misc/Ada/TurboQuant](misc/Ada/TurboQuant) | no SPARK |  |  |  |  |
| [misc/Ada/Ukkonens-Algorithm](misc/Ada/Ukkonens-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Unary-Coding](misc/Ada/Unary-Coding) | no SPARK |  |  |  |  |
| [misc/Ada/Unicode-Collation-Algorithm](misc/Ada/Unicode-Collation-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Unrestricted-Algorithm](misc/Ada/Unrestricted-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/VEGAS-Algorithm](misc/Ada/VEGAS-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Variational-Method](misc/Ada/Variational-Method) | no SPARK |  |  |  |  |
| [misc/Ada/Variational-Quantum-Eigensolver](misc/Ada/Variational-Quantum-Eigensolver) | no SPARK |  |  |  |  |
| [misc/Ada/Vector-Quantization](misc/Ada/Vector-Quantization) | no SPARK |  |  |  |  |
| [misc/Ada/Vehicle-Routing-Problem](misc/Ada/Vehicle-Routing-Problem) | no SPARK |  |  |  |  |
| [misc/Ada/Velvet](misc/Ada/Velvet) | no SPARK |  |  |  |  |
| [misc/Ada/Verhoeff-Algorithm](misc/Ada/Verhoeff-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Vickrey-Clarke-Groves-Mechanism](misc/Ada/Vickrey-Clarke-Groves-Mechanism) | no SPARK |  |  |  |  |
| [misc/Ada/Wang-Landau](misc/Ada/Wang-Landau) | no SPARK |  |  |  |  |
| [misc/Ada/Warnsdorffs-Rule](misc/Ada/Warnsdorffs-Rule) | no SPARK |  |  |  |  |
| [misc/Ada/Warped-Linear-Predictive-Coding](misc/Ada/Warped-Linear-Predictive-Coding) | no SPARK |  |  |  |  |
| [misc/Ada/Xor-Swap-Algorithm](misc/Ada/Xor-Swap-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Yamartino-Method](misc/Ada/Yamartino-Method) | no SPARK |  |  |  |  |
| [misc/Ada/Zellers-Congruence-Algorithm](misc/Ada/Zellers-Congruence-Algorithm) | no SPARK |  |  |  |  |
| [misc/Ada/Zero-Attribute-Rule](misc/Ada/Zero-Attribute-Rule) | no SPARK |  |  |  |  |
| [misc/Ada/Zhu-Takaoka](misc/Ada/Zhu-Takaoka) | no SPARK |  |  |  |  |
| [misc/Ada/arc-cache](misc/Ada/arc-cache) | no SPARK |  |  |  |  |
| [misc/Ada/docs](misc/Ada/docs) | no SPARK |  |  |  |  |
| [misc/Ada/earliest-deadline](misc/Ada/earliest-deadline) | no SPARK |  |  |  |  |
| [misc/Ada/fair-share](misc/Ada/fair-share) | no SPARK |  |  |  |  |
| [misc/Ada/page-replacement-algorithms](misc/Ada/page-replacement-algorithms) | no SPARK |  |  |  |  |
| [misc/Ada/rate-monotonic](misc/Ada/rate-monotonic) | no SPARK |  |  |  |  |
| [misc/Ada/round-robin](misc/Ada/round-robin) | no SPARK |  |  |  |  |
| [misc/Ada/scripts](misc/Ada/scripts) | no SPARK |  |  |  |  |
| [misc/Ada/srt-simulation](misc/Ada/srt-simulation) | no SPARK |  |  |  |  |

### misc/SPARK2

**600 folders.**

| folder path | Silver | Training-ready | Stub | Needs implementation | Open findings |
|---|---|---|---|---|---|
| [misc/SPARK2/Ada-SPARK-3Sum-Closest](misc/SPARK2/Ada-SPARK-3Sum-Closest) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-4Sum-II](misc/SPARK2/Ada-SPARK-4Sum-II) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Accounts-Merge-Lite](misc/SPARK2/Ada-SPARK-Accounts-Merge-Lite) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Accounts-Merge-Stub](misc/SPARK2/Ada-SPARK-Accounts-Merge-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Add-Binary](misc/SPARK2/Ada-SPARK-Add-Binary) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Add-Digits](misc/SPARK2/Ada-SPARK-Add-Digits) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Add-Two-Numbers](misc/SPARK2/Ada-SPARK-Add-Two-Numbers) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Add-Two-Numbers-II](misc/SPARK2/Ada-SPARK-Add-Two-Numbers-II) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Add-Without-Plus](misc/SPARK2/Ada-SPARK-Add-Without-Plus) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Adler32](misc/SPARK2/Ada-SPARK-Adler32) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Alert-Using-Same-Key-Card-Stub](misc/SPARK2/Ada-SPARK-Alert-Using-Same-Key-Card-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Alien-Dictionary-Lite](misc/SPARK2/Ada-SPARK-Alien-Dictionary-Lite) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Alien-Dictionary-Stub](misc/SPARK2/Ada-SPARK-Alien-Dictionary-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-All-Paths-From-Source-To-Target](misc/SPARK2/Ada-SPARK-All-Paths-From-Source-To-Target) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Argmax](misc/SPARK2/Ada-SPARK-Argmax) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Arranging-Coins](misc/SPARK2/Ada-SPARK-Arranging-Coins) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Array-Partition-I](misc/SPARK2/Ada-SPARK-Array-Partition-I) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-As-Far-From-Land-As-Possible](misc/SPARK2/Ada-SPARK-As-Far-From-Land-As-Possible) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Assign-Cookies](misc/SPARK2/Ada-SPARK-Assign-Cookies) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Asteroid-Collision](misc/SPARK2/Ada-SPARK-Asteroid-Collision) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Authentication-Manager-Stub](misc/SPARK2/Ada-SPARK-Authentication-Manager-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Available-Captures-For-Rook](misc/SPARK2/Ada-SPARK-Available-Captures-For-Rook) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Bankers-Algorithm](misc/SPARK2/Ada-SPARK-Bankers-Algorithm) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Base64-Decode](misc/SPARK2/Ada-SPARK-Base64-Decode) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Base64-Encode](misc/SPARK2/Ada-SPARK-Base64-Encode) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Baseball-Game](misc/SPARK2/Ada-SPARK-Baseball-Game) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Basic-Calculator](misc/SPARK2/Ada-SPARK-Basic-Calculator) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Basic-Calculator-II](misc/SPARK2/Ada-SPARK-Basic-Calculator-II) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Basic-Calculator-Stub](misc/SPARK2/Ada-SPARK-Basic-Calculator-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Beautiful-Arrangement](misc/SPARK2/Ada-SPARK-Beautiful-Arrangement) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Beautiful-Array-Lite](misc/SPARK2/Ada-SPARK-Beautiful-Array-Lite) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Best-Time-To-Buy-And-Sell-Stock](misc/SPARK2/Ada-SPARK-Best-Time-To-Buy-And-Sell-Stock) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Best-Time-To-Buy-And-Sell-Stock-II](misc/SPARK2/Ada-SPARK-Best-Time-To-Buy-And-Sell-Stock-II) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Best-Time-To-Buy-And-Sell-Stock-With-Cooldownoldown](misc/SPARK2/Ada-SPARK-Best-Time-To-Buy-And-Sell-Stock-With-Cooldownoldown) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Binary-Number-With-Alternating-Bits](misc/SPARK2/Ada-SPARK-Binary-Number-With-Alternating-Bits) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Binary-To-Integer](misc/SPARK2/Ada-SPARK-Binary-To-Integer) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Binary-Watch](misc/SPARK2/Ada-SPARK-Binary-Watch) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Binomial-Coefficient](misc/SPARK2/Ada-SPARK-Binomial-Coefficient) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Bitset](misc/SPARK2/Ada-SPARK-Bitset) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Bitwise-AND-Of-Numbers-Range](misc/SPARK2/Ada-SPARK-Bitwise-AND-Of-Numbers-Range) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Bitwise-OR-Of-Numbers-Range](misc/SPARK2/Ada-SPARK-Bitwise-OR-Of-Numbers-Range) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Bitwise-ORs-Of-Subarrays-Lite](misc/SPARK2/Ada-SPARK-Bitwise-ORs-Of-Subarrays-Lite) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Bitwise-XOR-Of-All-Pairings](misc/SPARK2/Ada-SPARK-Bitwise-XOR-Of-All-Pairings) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Boats-To-Save-People](misc/SPARK2/Ada-SPARK-Boats-To-Save-People) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Bounding-Box](misc/SPARK2/Ada-SPARK-Bounding-Box) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Bray-Curtis](misc/SPARK2/Ada-SPARK-Bray-Curtis) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Broken-Calculator](misc/SPARK2/Ada-SPARK-Broken-Calculator) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Browser-History-Stub](misc/SPARK2/Ada-SPARK-Browser-History-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Buddy-Memory-Allocation](misc/SPARK2/Ada-SPARK-Buddy-Memory-Allocation) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Bulb-Switcher](misc/SPARK2/Ada-SPARK-Bulb-Switcher) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Bulb-Switcher-Stub](misc/SPARK2/Ada-SPARK-Bulb-Switcher-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Bump-Arena](misc/SPARK2/Ada-SPARK-Bump-Arena) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-CRC32](misc/SPARK2/Ada-SPARK-CRC32) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-CSR-Row-Sum](misc/SPARK2/Ada-SPARK-CSR-Row-Sum) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Can-Place-Flowers](misc/SPARK2/Ada-SPARK-Can-Place-Flowers) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Canberra-Distance](misc/SPARK2/Ada-SPARK-Canberra-Distance) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Candy](misc/SPARK2/Ada-SPARK-Candy) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Capacity-To-Ship-Packages](misc/SPARK2/Ada-SPARK-Capacity-To-Ship-Packages) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Car-Pooling](misc/SPARK2/Ada-SPARK-Car-Pooling) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Cheapest-Flights](misc/SPARK2/Ada-SPARK-Cheapest-Flights) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Cheapest-Flights-Stub](misc/SPARK2/Ada-SPARK-Cheapest-Flights-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Cheapest-Flights-Within-K-Stops](misc/SPARK2/Ada-SPARK-Cheapest-Flights-Within-K-Stops) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Check-If-Number-Is-A-Sum-Of-Powers-Of-Three](misc/SPARK2/Ada-SPARK-Check-If-Number-Is-A-Sum-Of-Powers-Of-Three) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Check-If-The-Sentence-Is-Pangram](misc/SPARK2/Ada-SPARK-Check-If-The-Sentence-Is-Pangram) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Checksum-Ones-Complement](misc/SPARK2/Ada-SPARK-Checksum-Ones-Complement) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Cherry-Pickup-Lite](misc/SPARK2/Ada-SPARK-Cherry-Pickup-Lite) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Circular-Deque-Stub](misc/SPARK2/Ada-SPARK-Circular-Deque-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Circular-Queue](misc/SPARK2/Ada-SPARK-Circular-Queue) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Clamp](misc/SPARK2/Ada-SPARK-Clamp) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Climbing-Stairs](misc/SPARK2/Ada-SPARK-Climbing-Stairs) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Clock-Page-Replacement](misc/SPARK2/Ada-SPARK-Clock-Page-Replacement) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Coin-Change](misc/SPARK2/Ada-SPARK-Coin-Change) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Coin-Change-II](misc/SPARK2/Ada-SPARK-Coin-Change-II) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Combination-Iterator-Stub](misc/SPARK2/Ada-SPARK-Combination-Iterator-Stub) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Combination-Sum](misc/SPARK2/Ada-SPARK-Combination-Sum) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Combination-Sum-II](misc/SPARK2/Ada-SPARK-Combination-Sum-II) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Combination-Sum-III](misc/SPARK2/Ada-SPARK-Combination-Sum-III) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Combination-Sum-IV](misc/SPARK2/Ada-SPARK-Combination-Sum-IV) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Complement-Of-Base-10](misc/SPARK2/Ada-SPARK-Complement-Of-Base-10) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Complement-Of-Base-10-Integer](misc/SPARK2/Ada-SPARK-Complement-Of-Base-10-Integer) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Connected-Component-Labeling](misc/SPARK2/Ada-SPARK-Connected-Component-Labeling) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Container-With-Most-Water](misc/SPARK2/Ada-SPARK-Container-With-Most-Water) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Contains-Duplicate](misc/SPARK2/Ada-SPARK-Contains-Duplicate) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Contains-Duplicate-II](misc/SPARK2/Ada-SPARK-Contains-Duplicate-II) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Contiguous-Array](misc/SPARK2/Ada-SPARK-Contiguous-Array) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Continuous-Subarray-Sum](misc/SPARK2/Ada-SPARK-Continuous-Subarray-Sum) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Convert-1D-Array-Into-2D-Array](misc/SPARK2/Ada-SPARK-Convert-1D-Array-Into-2D-Array) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Convert-A-Number-To-Hexadecimal](misc/SPARK2/Ada-SPARK-Convert-A-Number-To-Hexadecimal) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Convert-Binary-Number-In-A-Linked-List-To-Integer](misc/SPARK2/Ada-SPARK-Convert-Binary-Number-In-A-Linked-List-To-Integer) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Copy-List-With-Random-Pointer-Lite](misc/SPARK2/Ada-SPARK-Copy-List-With-Random-Pointer-Lite) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Corporate-Flight-Bookings](misc/SPARK2/Ada-SPARK-Corporate-Flight-Bookings) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Cosine-Distance](misc/SPARK2/Ada-SPARK-Cosine-Distance) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Cosine-Similarity](misc/SPARK2/Ada-SPARK-Cosine-Similarity) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Count-And-Say](misc/SPARK2/Ada-SPARK-Count-And-Say) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Count-And-Say-Stub](misc/SPARK2/Ada-SPARK-Count-And-Say-Stub) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Count-Odd-Numbers-In-An-Interval](misc/SPARK2/Ada-SPARK-Count-Odd-Numbers-In-An-Interval) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Count-Of-Smaller-Numbers-After-Self-Lite](misc/SPARK2/Ada-SPARK-Count-Of-Smaller-Numbers-After-Self-Lite) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Count-Operations-To-Obtain-Zero](misc/SPARK2/Ada-SPARK-Count-Operations-To-Obtain-Zero) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Count-Square-Submatrices-With-All-Ones](misc/SPARK2/Ada-SPARK-Count-Square-Submatrices-With-All-Ones) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Count-Sub-Islands](misc/SPARK2/Ada-SPARK-Count-Sub-Islands) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Count-Triplets-That-Can-Form-Two-Arrays-Of-Equal-XOR](misc/SPARK2/Ada-SPARK-Count-Triplets-That-Can-Form-Two-Arrays-Of-Equal-XOR) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Counting-Bits](misc/SPARK2/Ada-SPARK-Counting-Bits) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Covariance](misc/SPARK2/Ada-SPARK-Covariance) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Crawler-Log-Folder](misc/SPARK2/Ada-SPARK-Crawler-Log-Folder) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Create-Maximum-Number-Lite](misc/SPARK2/Ada-SPARK-Create-Maximum-Number-Lite) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Critical-Connections-In-A-Network-Lite](misc/SPARK2/Ada-SPARK-Critical-Connections-In-A-Network-Lite) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Daily-Temperatures](misc/SPARK2/Ada-SPARK-Daily-Temperatures) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Decode-Ways](misc/SPARK2/Ada-SPARK-Decode-Ways) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Decode-Ways-Stub](misc/SPARK2/Ada-SPARK-Decode-Ways-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Decode-XORed-Array](misc/SPARK2/Ada-SPARK-Decode-XORed-Array) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Defanging-An-IP-Address](misc/SPARK2/Ada-SPARK-Defanging-An-IP-Address) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Degree-Of-An-Array](misc/SPARK2/Ada-SPARK-Degree-Of-An-Array) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Delete-And-Earn](misc/SPARK2/Ada-SPARK-Delete-And-Earn) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Delete-And-Earn-Stub](misc/SPARK2/Ada-SPARK-Delete-And-Earn-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Delete-Node-In-A-Linked-List](misc/SPARK2/Ada-SPARK-Delete-Node-In-A-Linked-List) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Delete-The-Middle-Node](misc/SPARK2/Ada-SPARK-Delete-The-Middle-Node) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Delta-Encoding](misc/SPARK2/Ada-SPARK-Delta-Encoding) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Deque-Bounded](misc/SPARK2/Ada-SPARK-Deque-Bounded) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Design-A-Leaderboard](misc/SPARK2/Ada-SPARK-Design-A-Leaderboard) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Design-A-Stack-With-Increment](misc/SPARK2/Ada-SPARK-Design-A-Stack-With-Increment) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Design-A-Stack-With-Increment-Operation](misc/SPARK2/Ada-SPARK-Design-A-Stack-With-Increment-Operation) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Design-An-Ordered-Stream](misc/SPARK2/Ada-SPARK-Design-An-Ordered-Stream) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Design-Bitset](misc/SPARK2/Ada-SPARK-Design-Bitset) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Design-Browser-History](misc/SPARK2/Ada-SPARK-Design-Browser-History) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Design-Circular-Deque](misc/SPARK2/Ada-SPARK-Design-Circular-Deque) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Design-Circular-Queue](misc/SPARK2/Ada-SPARK-Design-Circular-Queue) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Design-Circular-Queue-Stub](misc/SPARK2/Ada-SPARK-Design-Circular-Queue-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Design-Food-Rating-System](misc/SPARK2/Ada-SPARK-Design-Food-Rating-System) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Design-Front-Middle-Back-Queue](misc/SPARK2/Ada-SPARK-Design-Front-Middle-Back-Queue) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Design-Front-Middle-Back-Queue-Stub](misc/SPARK2/Ada-SPARK-Design-Front-Middle-Back-Queue-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Design-Hit-Counter-Lite](misc/SPARK2/Ada-SPARK-Design-Hit-Counter-Lite) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Design-Linked-List](misc/SPARK2/Ada-SPARK-Design-Linked-List) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Design-Number-Container-System](misc/SPARK2/Ada-SPARK-Design-Number-Container-System) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Design-Ordered-Stream](misc/SPARK2/Ada-SPARK-Design-Ordered-Stream) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Design-Parking-System-II](misc/SPARK2/Ada-SPARK-Design-Parking-System-II) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Design-Skiplist-Lite](misc/SPARK2/Ada-SPARK-Design-Skiplist-Lite) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Design-Twitter-Lite](misc/SPARK2/Ada-SPARK-Design-Twitter-Lite) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Design-Underground-System-Lite](misc/SPARK2/Ada-SPARK-Design-Underground-System-Lite) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Detect-Capital](misc/SPARK2/Ada-SPARK-Detect-Capital) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Diagonal-Traverse](misc/SPARK2/Ada-SPARK-Diagonal-Traverse) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Dice-Coefficient](misc/SPARK2/Ada-SPARK-Dice-Coefficient) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Difference-Array](misc/SPARK2/Ada-SPARK-Difference-Array) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Different-Ways-To-Add-Parentheses-Lite](misc/SPARK2/Ada-SPARK-Different-Ways-To-Add-Parentheses-Lite) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Disjoint-Set-Forest](misc/SPARK2/Ada-SPARK-Disjoint-Set-Forest) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Distinct-Subsequences](misc/SPARK2/Ada-SPARK-Distinct-Subsequences) | tool crash |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Divisor-Game](misc/SPARK2/Ada-SPARK-Divisor-Game) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Domino-And-Tromino-Tiling-Lite](misc/SPARK2/Ada-SPARK-Domino-And-Tromino-Tiling-Lite) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Dot-Product](misc/SPARK2/Ada-SPARK-Dot-Product) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Dungeon-Game-Lite](misc/SPARK2/Ada-SPARK-Dungeon-Game-Lite) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Duplicate-Zeros](misc/SPARK2/Ada-SPARK-Duplicate-Zeros) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Dutch-National-Flag](misc/SPARK2/Ada-SPARK-Dutch-National-Flag) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Earliest-Deadline-First-Scheduling](misc/SPARK2/Ada-SPARK-Earliest-Deadline-First-Scheduling) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Elevator-Algorithm](misc/SPARK2/Ada-SPARK-Elevator-Algorithm) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Eliminate-Maximum-Number-Of-Monsters](misc/SPARK2/Ada-SPARK-Eliminate-Maximum-Number-Of-Monsters) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Encode-And-Decode-TinyURL-Stub](misc/SPARK2/Ada-SPARK-Encode-And-Decode-TinyURL-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Euclidean-Distance](misc/SPARK2/Ada-SPARK-Euclidean-Distance) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Eval-RPN](misc/SPARK2/Ada-SPARK-Eval-RPN) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Evaluate-Division-Lite](misc/SPARK2/Ada-SPARK-Evaluate-Division-Lite) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Evaluate-Division-Stub](misc/SPARK2/Ada-SPARK-Evaluate-Division-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Evaluate-Reverse-Polish-Notation](misc/SPARK2/Ada-SPARK-Evaluate-Reverse-Polish-Notation) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Excel-Sheet-Column](misc/SPARK2/Ada-SPARK-Excel-Sheet-Column) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Excel-Sheet-Column-Number](misc/SPARK2/Ada-SPARK-Excel-Sheet-Column-Number) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Excel-Sheet-Column-Title](misc/SPARK2/Ada-SPARK-Excel-Sheet-Column-Title) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Exclusive-Time-Of-Functions-Lite](misc/SPARK2/Ada-SPARK-Exclusive-Time-Of-Functions-Lite) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Factorial](misc/SPARK2/Ada-SPARK-Factorial) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Factorial-Trailing-Zeroes](misc/SPARK2/Ada-SPARK-Factorial-Trailing-Zeroes) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Fair-Candy-Swap](misc/SPARK2/Ada-SPARK-Fair-Candy-Swap) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Fast-Pow](misc/SPARK2/Ada-SPARK-Fast-Pow) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Fibonacci-DP](misc/SPARK2/Ada-SPARK-Fibonacci-DP) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Fibonacci-Number](misc/SPARK2/Ada-SPARK-Fibonacci-Number) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Final-Prices-With-A-Special-Discount](misc/SPARK2/Ada-SPARK-Final-Prices-With-A-Special-Discount) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Find-All-Duplicates-In-An-Array](misc/SPARK2/Ada-SPARK-Find-All-Duplicates-In-An-Array) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Find-All-Numbers-Disappeared](misc/SPARK2/Ada-SPARK-Find-All-Numbers-Disappeared) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Find-Common-Characters](misc/SPARK2/Ada-SPARK-Find-Common-Characters) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Find-First-And-Last-Position](misc/SPARK2/Ada-SPARK-Find-First-And-Last-Position) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Find-K-Closest-Elements](misc/SPARK2/Ada-SPARK-Find-K-Closest-Elements) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Find-Median-Data-Stream-Stub](misc/SPARK2/Ada-SPARK-Find-Median-Data-Stream-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Find-Median-From-Data-Stream](misc/SPARK2/Ada-SPARK-Find-Median-From-Data-Stream) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Find-Peak-Element](misc/SPARK2/Ada-SPARK-Find-Peak-Element) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Find-The-City](misc/SPARK2/Ada-SPARK-Find-The-City) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Find-The-City-With-Smallest-Number-Of-Neighbors](misc/SPARK2/Ada-SPARK-Find-The-City-With-Smallest-Number-Of-Neighbors) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Find-The-Difference](misc/SPARK2/Ada-SPARK-Find-The-Difference) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Find-The-Duplicate-Number](misc/SPARK2/Ada-SPARK-Find-The-Duplicate-Number) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Find-The-Original-Array-Of-Prefix-XOR](misc/SPARK2/Ada-SPARK-Find-The-Original-Array-Of-Prefix-XOR) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Find-The-Smallest-Divisor](misc/SPARK2/Ada-SPARK-Find-The-Smallest-Divisor) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Find-The-Town-Judge](misc/SPARK2/Ada-SPARK-Find-The-Town-Judge) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Find-Words-That-Can-Be-Formed](misc/SPARK2/Ada-SPARK-Find-Words-That-Can-Be-Formed) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-First-Bad-Version](misc/SPARK2/Ada-SPARK-First-Bad-Version) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-First-Unique-Char](misc/SPARK2/Ada-SPARK-First-Unique-Char) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-First-Unique-Character](misc/SPARK2/Ada-SPARK-First-Unique-Character) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Fisher-Yates-Shuffle](misc/SPARK2/Ada-SPARK-Fisher-Yates-Shuffle) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Fixed-Point-Iteration](misc/SPARK2/Ada-SPARK-Fixed-Point-Iteration) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Fizz-Buzz](misc/SPARK2/Ada-SPARK-Fizz-Buzz) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Flatten-Nested-List-Stub](misc/SPARK2/Ada-SPARK-Flatten-Nested-List-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Flipping-An-Image](misc/SPARK2/Ada-SPARK-Flipping-An-Image) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Flood-Fill](misc/SPARK2/Ada-SPARK-Flood-Fill) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Four-Sum](misc/SPARK2/Ada-SPARK-Four-Sum) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Fruit-Into-Baskets](misc/SPARK2/Ada-SPARK-Fruit-Into-Baskets) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Game-Of-Life-Step](misc/SPARK2/Ada-SPARK-Game-Of-Life-Step) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Gas-Station](misc/SPARK2/Ada-SPARK-Gas-Station) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Generate-Parentheses](misc/SPARK2/Ada-SPARK-Generate-Parentheses) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Get-Maximum-In-Generated-Array](misc/SPARK2/Ada-SPARK-Get-Maximum-In-Generated-Array) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Goat-Latin](misc/SPARK2/Ada-SPARK-Goat-Latin) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Gray-Code](misc/SPARK2/Ada-SPARK-Gray-Code) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Greatest-Common-Divisor](misc/SPARK2/Ada-SPARK-Greatest-Common-Divisor) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Group-Anagrams](misc/SPARK2/Ada-SPARK-Group-Anagrams) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Group-Anagrams-Stub](misc/SPARK2/Ada-SPARK-Group-Anagrams-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Grumpy-Bookstore-Owner](misc/SPARK2/Ada-SPARK-Grumpy-Bookstore-Owner) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Guess-Number-Higher-Or-Lower](misc/SPARK2/Ada-SPARK-Guess-Number-Higher-Or-Lower) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Hamming-Code](misc/SPARK2/Ada-SPARK-Hamming-Code) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Hamming-Weight](misc/SPARK2/Ada-SPARK-Hamming-Weight) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Hand-Of-Straights-Stub](misc/SPARK2/Ada-SPARK-Hand-Of-Straights-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Happy-Number](misc/SPARK2/Ada-SPARK-Happy-Number) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Heap-Push-Pop](misc/SPARK2/Ada-SPARK-Heap-Push-Pop) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Heaters](misc/SPARK2/Ada-SPARK-Heaters) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Height-Checker](misc/SPARK2/Ada-SPARK-Height-Checker) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Histogram-Bin](misc/SPARK2/Ada-SPARK-Histogram-Bin) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Hit-Counter-Stub](misc/SPARK2/Ada-SPARK-Hit-Counter-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Horner-Scheme](misc/SPARK2/Ada-SPARK-Horner-Scheme) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-House-Robber](misc/SPARK2/Ada-SPARK-House-Robber) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-House-Robber-II](misc/SPARK2/Ada-SPARK-House-Robber-II) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-House-Robber-III-Lite](misc/SPARK2/Ada-SPARK-House-Robber-III-Lite) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-House-Robber-III-Stub](misc/SPARK2/Ada-SPARK-House-Robber-III-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-How-Many-Numbers-Are-Smaller](misc/SPARK2/Ada-SPARK-How-Many-Numbers-Are-Smaller) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-IPO-Lite](misc/SPARK2/Ada-SPARK-IPO-Lite) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Image-Smoother](misc/SPARK2/Ada-SPARK-Image-Smoother) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Implement-Queue-Using-Stacks](misc/SPARK2/Ada-SPARK-Implement-Queue-Using-Stacks) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Implement-Stack-Using-Queues](misc/SPARK2/Ada-SPARK-Implement-Stack-Using-Queues) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Implement-StrStr](misc/SPARK2/Ada-SPARK-Implement-StrStr) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Insert-Delete-GetRandom-O1](misc/SPARK2/Ada-SPARK-Insert-Delete-GetRandom-O1) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Insert-Interval](misc/SPARK2/Ada-SPARK-Insert-Interval) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Int-To-Roman-Stub](misc/SPARK2/Ada-SPARK-Int-To-Roman-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Integer-Break](misc/SPARK2/Ada-SPARK-Integer-Break) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Integer-To-English-Stub](misc/SPARK2/Ada-SPARK-Integer-To-English-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Integer-To-Roman](misc/SPARK2/Ada-SPARK-Integer-To-Roman) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Intersection-Of-Two-Arrays](misc/SPARK2/Ada-SPARK-Intersection-Of-Two-Arrays) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Intersection-Of-Two-Arrays-II](misc/SPARK2/Ada-SPARK-Intersection-Of-Two-Arrays-II) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Intersection-Of-Two-Linked-Lists](misc/SPARK2/Ada-SPARK-Intersection-Of-Two-Linked-Lists) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Is-Palindrome](misc/SPARK2/Ada-SPARK-Is-Palindrome) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Is-Subsequence](misc/SPARK2/Ada-SPARK-Is-Subsequence) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Island-Perimeter](misc/SPARK2/Ada-SPARK-Island-Perimeter) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Jaccard-Index](misc/SPARK2/Ada-SPARK-Jaccard-Index) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Jump-Game](misc/SPARK2/Ada-SPARK-Jump-Game) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Jump-Game-II](misc/SPARK2/Ada-SPARK-Jump-Game-II) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-K-Closest-Points-Stub](misc/SPARK2/Ada-SPARK-K-Closest-Points-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-K-Closest-Points-To-Origin](misc/SPARK2/Ada-SPARK-K-Closest-Points-To-Origin) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Kadanes-Algorithm](misc/SPARK2/Ada-SPARK-Kadanes-Algorithm) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Keyboard-Row](misc/SPARK2/Ada-SPARK-Keyboard-Row) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Keys-And-Rooms](misc/SPARK2/Ada-SPARK-Keys-And-Rooms) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Knapsack-01](misc/SPARK2/Ada-SPARK-Knapsack-01) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Knight-Probability-In-Chessboard-Lite](misc/SPARK2/Ada-SPARK-Knight-Probability-In-Chessboard-Lite) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Koko-Eating-Bananas](misc/SPARK2/Ada-SPARK-Koko-Eating-Bananas) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Kth-Largest-Array](misc/SPARK2/Ada-SPARK-Kth-Largest-Array) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Kth-Largest-Element](misc/SPARK2/Ada-SPARK-Kth-Largest-Element) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Kth-Largest-Element-In-A-Stream](misc/SPARK2/Ada-SPARK-Kth-Largest-Element-In-A-Stream) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Kth-Largest-Element-In-An-Array](misc/SPARK2/Ada-SPARK-Kth-Largest-Element-In-An-Array) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Kth-Largest-In-Stream-Stub](misc/SPARK2/Ada-SPARK-Kth-Largest-In-Stream-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-L1-Norm](misc/SPARK2/Ada-SPARK-L1-Norm) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-L2-Norm-Squared](misc/SPARK2/Ada-SPARK-L2-Norm-Squared) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-LFU-Cache-Lite](misc/SPARK2/Ada-SPARK-LFU-Cache-Lite) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-LFU-Cache-Stub](misc/SPARK2/Ada-SPARK-LFU-Cache-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-LRU-Cache-Lite](misc/SPARK2/Ada-SPARK-LRU-Cache-Lite) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-LRU-Cache-Stub](misc/SPARK2/Ada-SPARK-LRU-Cache-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Largest-Number](misc/SPARK2/Ada-SPARK-Largest-Number) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Largest-Rectangle-In-Histogram](misc/SPARK2/Ada-SPARK-Largest-Rectangle-In-Histogram) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Last-Stone-Weight](misc/SPARK2/Ada-SPARK-Last-Stone-Weight) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Last-Stone-Weight-II](misc/SPARK2/Ada-SPARK-Last-Stone-Weight-II) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Least-Common-Multiple](misc/SPARK2/Ada-SPARK-Least-Common-Multiple) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Lemonade-Change](misc/SPARK2/Ada-SPARK-Lemonade-Change) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Length-Of-Last-Word](misc/SPARK2/Ada-SPARK-Length-Of-Last-Word) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Letter-Case-Permutation](misc/SPARK2/Ada-SPARK-Letter-Case-Permutation) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Letter-Combinations-Of-A-Phone-Number](misc/SPARK2/Ada-SPARK-Letter-Combinations-Of-A-Phone-Number) | timeout |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-License-Key-Formatting](misc/SPARK2/Ada-SPARK-License-Key-Formatting) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Line-Intersection](misc/SPARK2/Ada-SPARK-Line-Intersection) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Line-Reflection](misc/SPARK2/Ada-SPARK-Line-Reflection) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Linked-List-Cycle](misc/SPARK2/Ada-SPARK-Linked-List-Cycle) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Linked-List-Cycle-II](misc/SPARK2/Ada-SPARK-Linked-List-Cycle-II) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Logger-Rate-Limiter-Lite](misc/SPARK2/Ada-SPARK-Logger-Rate-Limiter-Lite) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Logger-Rate-Limiter-Stub](misc/SPARK2/Ada-SPARK-Logger-Rate-Limiter-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Longest-Increasing-Subsequence](misc/SPARK2/Ada-SPARK-Longest-Increasing-Subsequence) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Longest-Mountain-In-Array](misc/SPARK2/Ada-SPARK-Longest-Mountain-In-Array) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Longest-Ones](misc/SPARK2/Ada-SPARK-Longest-Ones) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Longest-Palindromic-Subsequence](misc/SPARK2/Ada-SPARK-Longest-Palindromic-Subsequence) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Longest-Repeating-Character-Replacement](misc/SPARK2/Ada-SPARK-Longest-Repeating-Character-Replacement) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Longest-Word-In-Dictionary](misc/SPARK2/Ada-SPARK-Longest-Word-In-Dictionary) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Magnetic-Force-Between-Two-Balls](misc/SPARK2/Ada-SPARK-Magnetic-Force-Between-Two-Balls) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Majority-Element](misc/SPARK2/Ada-SPARK-Majority-Element) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Majority-Element-II](misc/SPARK2/Ada-SPARK-Majority-Element-II) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Manacher](misc/SPARK2/Ada-SPARK-Manacher) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Manhattan-Distance](misc/SPARK2/Ada-SPARK-Manhattan-Distance) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Map-Sum-Pairs](misc/SPARK2/Ada-SPARK-Map-Sum-Pairs) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Mark-And-Sweep](misc/SPARK2/Ada-SPARK-Mark-And-Sweep) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Matchsticks-To-Square-Lite](misc/SPARK2/Ada-SPARK-Matchsticks-To-Square-Lite) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Max-Area-Of-Island](misc/SPARK2/Ada-SPARK-Max-Area-Of-Island) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Max-Consecutive-Ones](misc/SPARK2/Ada-SPARK-Max-Consecutive-Ones) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Max-Consecutive-Ones-II](misc/SPARK2/Ada-SPARK-Max-Consecutive-Ones-II) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Max-Consecutive-Ones-III](misc/SPARK2/Ada-SPARK-Max-Consecutive-Ones-III) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Max-Heap](misc/SPARK2/Ada-SPARK-Max-Heap) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Max-Path-Sum-Stub](misc/SPARK2/Ada-SPARK-Max-Path-Sum-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Max-Points-On-A-Line-Lite](misc/SPARK2/Ada-SPARK-Max-Points-On-A-Line-Lite) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Max-Product-Subarray](misc/SPARK2/Ada-SPARK-Max-Product-Subarray) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Max-Stack](misc/SPARK2/Ada-SPARK-Max-Stack) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Max-Stack-Stub](misc/SPARK2/Ada-SPARK-Max-Stack-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Maximal-Rectangle](misc/SPARK2/Ada-SPARK-Maximal-Rectangle) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Maximal-Square](misc/SPARK2/Ada-SPARK-Maximal-Square) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Maximum-Candies-Allocated-To-K-Children](misc/SPARK2/Ada-SPARK-Maximum-Candies-Allocated-To-K-Children) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Maximum-Ice-Cream-Bars](misc/SPARK2/Ada-SPARK-Maximum-Ice-Cream-Bars) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Maximum-Points-You-Can-Obtain-From-Cards](misc/SPARK2/Ada-SPARK-Maximum-Points-You-Can-Obtain-From-Cards) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Maximum-Product-Of-Word-Lengths](misc/SPARK2/Ada-SPARK-Maximum-Product-Of-Word-Lengths) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Maximum-Product-Subarray](misc/SPARK2/Ada-SPARK-Maximum-Product-Subarray) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Maximum-Subarray](misc/SPARK2/Ada-SPARK-Maximum-Subarray) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Maximum-Subarray-Circular](misc/SPARK2/Ada-SPARK-Maximum-Subarray-Circular) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Maximum-Twin-Sum-Of-A-Linked-List](misc/SPARK2/Ada-SPARK-Maximum-Twin-Sum-Of-A-Linked-List) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Maximum-Units-On-A-Truck](misc/SPARK2/Ada-SPARK-Maximum-Units-On-A-Truck) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Maximum-XOR-Of-Two-Numbers](misc/SPARK2/Ada-SPARK-Maximum-XOR-Of-Two-Numbers) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Mean-Variance](misc/SPARK2/Ada-SPARK-Mean-Variance) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Median-Filtering](misc/SPARK2/Ada-SPARK-Median-Filtering) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Median-Of-Three](misc/SPARK2/Ada-SPARK-Median-Of-Three) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Meeting-Rooms](misc/SPARK2/Ada-SPARK-Meeting-Rooms) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Meeting-Rooms-II](misc/SPARK2/Ada-SPARK-Meeting-Rooms-II) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Merge-In-Between-Linked-Lists](misc/SPARK2/Ada-SPARK-Merge-In-Between-Linked-Lists) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Merge-Intervals](misc/SPARK2/Ada-SPARK-Merge-Intervals) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Middle-Of-The-Linked-List](misc/SPARK2/Ada-SPARK-Middle-Of-The-Linked-List) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Min-Cost-Climbing-Stairs](misc/SPARK2/Ada-SPARK-Min-Cost-Climbing-Stairs) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Min-Cost-Connect-Cities-Stub](misc/SPARK2/Ada-SPARK-Min-Cost-Connect-Cities-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Min-Cost-To-Connect-All-Points](misc/SPARK2/Ada-SPARK-Min-Cost-To-Connect-All-Points) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Min-Heap](misc/SPARK2/Ada-SPARK-Min-Heap) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Min-Max-Normalize](misc/SPARK2/Ada-SPARK-Min-Max-Normalize) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Min-Stack](misc/SPARK2/Ada-SPARK-Min-Stack) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Minimum-ASCII-Delete-Sum](misc/SPARK2/Ada-SPARK-Minimum-ASCII-Delete-Sum) | tool crash |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Minimum-Bit-Flips-To-Convert-Number](misc/SPARK2/Ada-SPARK-Minimum-Bit-Flips-To-Convert-Number) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Minimum-Cost-To-Move-Chips](misc/SPARK2/Ada-SPARK-Minimum-Cost-To-Move-Chips) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Minimum-Deletions-To-Make-Character-Frequencies-Unique](misc/SPARK2/Ada-SPARK-Minimum-Deletions-To-Make-Character-Frequencies-Unique) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Minimum-Number-Of-Arrows](misc/SPARK2/Ada-SPARK-Minimum-Number-Of-Arrows) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Minimum-Number-Of-Days-To-Make-M-Bouquets](misc/SPARK2/Ada-SPARK-Minimum-Number-Of-Days-To-Make-M-Bouquets) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Minimum-Number-Of-Moves-To-Seat](misc/SPARK2/Ada-SPARK-Minimum-Number-Of-Moves-To-Seat) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Minimum-Operations-To-Make-The-Array-Increasing](misc/SPARK2/Ada-SPARK-Minimum-Operations-To-Make-The-Array-Increasing) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Minimum-Path-Sum](misc/SPARK2/Ada-SPARK-Minimum-Path-Sum) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Minimum-Sum-Of-Four-Digit-Number](misc/SPARK2/Ada-SPARK-Minimum-Sum-Of-Four-Digit-Number) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Missing-Number](misc/SPARK2/Ada-SPARK-Missing-Number) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Missing-Ranges-Stub](misc/SPARK2/Ada-SPARK-Missing-Ranges-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Monotonic-Stack](misc/SPARK2/Ada-SPARK-Monotonic-Stack) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Most-Common-Word](misc/SPARK2/Ada-SPARK-Most-Common-Word) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Move-Zeroes](misc/SPARK2/Ada-SPARK-Move-Zeroes) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Moving-Average](misc/SPARK2/Ada-SPARK-Moving-Average) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Moving-Average-From-Data-Stream](misc/SPARK2/Ada-SPARK-Moving-Average-From-Data-Stream) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-My-Calendar-Stub](misc/SPARK2/Ada-SPARK-My-Calendar-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-My-Linked-List-Stub](misc/SPARK2/Ada-SPARK-My-Linked-List-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-N-Queens-Lite](misc/SPARK2/Ada-SPARK-N-Queens-Lite) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-N-Repeated-Element-In-Size-2N-Array](misc/SPARK2/Ada-SPARK-N-Repeated-Element-In-Size-2N-Array) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-N-th-Tribonacci](misc/SPARK2/Ada-SPARK-N-th-Tribonacci) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Nearest-Exit-From-Entrance-In-Maze](misc/SPARK2/Ada-SPARK-Nearest-Exit-From-Entrance-In-Maze) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Neighboring-Bitwise-XOR](misc/SPARK2/Ada-SPARK-Neighboring-Bitwise-XOR) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Nested-Iterator-Stub](misc/SPARK2/Ada-SPARK-Nested-Iterator-Stub) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Network-Delay-Time](misc/SPARK2/Ada-SPARK-Network-Delay-Time) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Network-Delay-Time-Stub](misc/SPARK2/Ada-SPARK-Network-Delay-Time-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-New-21-Game-Lite](misc/SPARK2/Ada-SPARK-New-21-Game-Lite) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Next-Greater-Element-I](misc/SPARK2/Ada-SPARK-Next-Greater-Element-I) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Next-Greater-Element-II](misc/SPARK2/Ada-SPARK-Next-Greater-Element-II) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Next-Greater-Node-In-Linked-List](misc/SPARK2/Ada-SPARK-Next-Greater-Node-In-Linked-List) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Next-Permutation-Stub](misc/SPARK2/Ada-SPARK-Next-Permutation-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Nim-Game](misc/SPARK2/Ada-SPARK-Nim-Game) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Non-Decreasing-Array](misc/SPARK2/Ada-SPARK-Non-Decreasing-Array) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Non-Overlapping-Intervals](misc/SPARK2/Ada-SPARK-Non-Overlapping-Intervals) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Nth-Digit](misc/SPARK2/Ada-SPARK-Nth-Digit) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Nth-Digit-Stub](misc/SPARK2/Ada-SPARK-Nth-Digit-Stub) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Nth-Ugly-Number](misc/SPARK2/Ada-SPARK-Nth-Ugly-Number) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Number-Complement](misc/SPARK2/Ada-SPARK-Number-Complement) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Number-Of-1-Bits](misc/SPARK2/Ada-SPARK-Number-Of-1-Bits) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Number-Of-1-Bits-In-Range](misc/SPARK2/Ada-SPARK-Number-Of-1-Bits-In-Range) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Number-Of-Connected-Components](misc/SPARK2/Ada-SPARK-Number-Of-Connected-Components) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Number-Of-Good-Pairs](misc/SPARK2/Ada-SPARK-Number-Of-Good-Pairs) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Number-Of-Islands](misc/SPARK2/Ada-SPARK-Number-Of-Islands) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Number-Of-Provinces](misc/SPARK2/Ada-SPARK-Number-Of-Provinces) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Number-Of-Recent-Calls](misc/SPARK2/Ada-SPARK-Number-Of-Recent-Calls) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Number-Of-Steps-To-Reduce-A-Number](misc/SPARK2/Ada-SPARK-Number-Of-Steps-To-Reduce-A-Number) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Number-Of-Steps-To-Reduce-A-Number-In-Binary-Representation](misc/SPARK2/Ada-SPARK-Number-Of-Steps-To-Reduce-A-Number-In-Binary-Representation) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-One-Hot](misc/SPARK2/Ada-SPARK-One-Hot) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Ones-And-Zeroes](misc/SPARK2/Ada-SPARK-Ones-And-Zeroes) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Online-Stock-Span](misc/SPARK2/Ada-SPARK-Online-Stock-Span) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Online-Stock-Span-Stub](misc/SPARK2/Ada-SPARK-Online-Stock-Span-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Open-The-Lock](misc/SPARK2/Ada-SPARK-Open-The-Lock) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Ordered-Stream-Stub](misc/SPARK2/Ada-SPARK-Ordered-Stream-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Out-Of-Boundary-Paths-Lite](misc/SPARK2/Ada-SPARK-Out-Of-Boundary-Paths-Lite) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Overlap-Coefficient](misc/SPARK2/Ada-SPARK-Overlap-Coefficient) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-PN-Counter](misc/SPARK2/Ada-SPARK-PN-Counter) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Pacific-Atlantic-Water-Flow](misc/SPARK2/Ada-SPARK-Pacific-Atlantic-Water-Flow) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Pacific-Atlantic-Water-Stub](misc/SPARK2/Ada-SPARK-Pacific-Atlantic-Water-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Paint-Fence-Lite](misc/SPARK2/Ada-SPARK-Paint-Fence-Lite) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Paint-House-Lite](misc/SPARK2/Ada-SPARK-Paint-House-Lite) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Paint-House-Stub](misc/SPARK2/Ada-SPARK-Paint-House-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Palindrome-Linked-List](misc/SPARK2/Ada-SPARK-Palindrome-Linked-List) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Palindrome-Number](misc/SPARK2/Ada-SPARK-Palindrome-Number) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Palindrome-Pairs-Lite](misc/SPARK2/Ada-SPARK-Palindrome-Pairs-Lite) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Palindrome-Partitioning](misc/SPARK2/Ada-SPARK-Palindrome-Partitioning) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Palindrome-Partitioning-II](misc/SPARK2/Ada-SPARK-Palindrome-Partitioning-II) | tool crash |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Parity-Bits](misc/SPARK2/Ada-SPARK-Parity-Bits) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Parking-System-Stub](misc/SPARK2/Ada-SPARK-Parking-System-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Partition-Around-Pivot](misc/SPARK2/Ada-SPARK-Partition-Around-Pivot) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Partition-Equal-Subset-Sum](misc/SPARK2/Ada-SPARK-Partition-Equal-Subset-Sum) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Partition-Labels](misc/SPARK2/Ada-SPARK-Partition-Labels) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Partition-List](misc/SPARK2/Ada-SPARK-Partition-List) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Pascal-Triangle](misc/SPARK2/Ada-SPARK-Pascal-Triangle) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Pascal-Triangle-II](misc/SPARK2/Ada-SPARK-Pascal-Triangle-II) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Path-Sum](misc/SPARK2/Ada-SPARK-Path-Sum) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Path-Sum-III-Lite](misc/SPARK2/Ada-SPARK-Path-Sum-III-Lite) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Path-With-Minimum-Effort](misc/SPARK2/Ada-SPARK-Path-With-Minimum-Effort) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Peak-Index-In-Mountain-Array](misc/SPARK2/Ada-SPARK-Peak-Index-In-Mountain-Array) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Pearson-Correlation](misc/SPARK2/Ada-SPARK-Pearson-Correlation) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Peeking-Iterator-Stub](misc/SPARK2/Ada-SPARK-Peeking-Iterator-Stub) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Permutations](misc/SPARK2/Ada-SPARK-Permutations) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Permutations-II](misc/SPARK2/Ada-SPARK-Permutations-II) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Plus-One](misc/SPARK2/Ada-SPARK-Plus-One) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Population-Count](misc/SPARK2/Ada-SPARK-Population-Count) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Pow-X-N](misc/SPARK2/Ada-SPARK-Pow-X-N) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Pow-X-N-Stub](misc/SPARK2/Ada-SPARK-Pow-X-N-Stub) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Power-Of-Four](misc/SPARK2/Ada-SPARK-Power-Of-Four) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Power-Of-Three](misc/SPARK2/Ada-SPARK-Power-Of-Three) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Power-Of-Two](misc/SPARK2/Ada-SPARK-Power-Of-Two) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Powx-N](misc/SPARK2/Ada-SPARK-Powx-N) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Prefix-Sums](misc/SPARK2/Ada-SPARK-Prefix-Sums) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Prim-MST-Lite](misc/SPARK2/Ada-SPARK-Prim-MST-Lite) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Priority-Queue-Binary-Heap](misc/SPARK2/Ada-SPARK-Priority-Queue-Binary-Heap) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Product-Except-Self](misc/SPARK2/Ada-SPARK-Product-Except-Self) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Product-Of-Array-Except-Self](misc/SPARK2/Ada-SPARK-Product-Of-Array-Except-Self) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Product-Of-Numbers-Stub](misc/SPARK2/Ada-SPARK-Product-Of-Numbers-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Projection-Area-Of-3D-Shapes](misc/SPARK2/Ada-SPARK-Projection-Area-Of-3D-Shapes) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Queue-Reconstruction-By-Height](misc/SPARK2/Ada-SPARK-Queue-Reconstruction-By-Height) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Queue-Using-Stacks](misc/SPARK2/Ada-SPARK-Queue-Using-Stacks) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Random-Pick-With-Weight-Lite](misc/SPARK2/Ada-SPARK-Random-Pick-With-Weight-Lite) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Randomized-Collection](misc/SPARK2/Ada-SPARK-Randomized-Collection) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Randomized-Set](misc/SPARK2/Ada-SPARK-Randomized-Set) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Range-Addition](misc/SPARK2/Ada-SPARK-Range-Addition) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Range-Module-Stub](misc/SPARK2/Ada-SPARK-Range-Module-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Range-Sum-Query](misc/SPARK2/Ada-SPARK-Range-Sum-Query) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Range-Sum-Query-2D-Immutable](misc/SPARK2/Ada-SPARK-Range-Sum-Query-2D-Immutable) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Range-Sum-Query-Immutable](misc/SPARK2/Ada-SPARK-Range-Sum-Query-Immutable) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Ransom-Note](misc/SPARK2/Ada-SPARK-Ransom-Note) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Rate-Monotonic-Scheduling](misc/SPARK2/Ada-SPARK-Rate-Monotonic-Scheduling) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Ravenscar-Job-Pool](misc/SPARK2/Ada-SPARK-Ravenscar-Job-Pool) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Reach-A-Number](misc/SPARK2/Ada-SPARK-Reach-A-Number) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Recent-Counter](misc/SPARK2/Ada-SPARK-Recent-Counter) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Rectangle-Area](misc/SPARK2/Ada-SPARK-Rectangle-Area) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Rectangle-Overlap](misc/SPARK2/Ada-SPARK-Rectangle-Overlap) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Reduce-Array-Size-To-The-Half](misc/SPARK2/Ada-SPARK-Reduce-Array-Size-To-The-Half) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Redundant-Connection](misc/SPARK2/Ada-SPARK-Redundant-Connection) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Redundant-Connection-II](misc/SPARK2/Ada-SPARK-Redundant-Connection-II) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Redundant-Connection-II-Lite](misc/SPARK2/Ada-SPARK-Redundant-Connection-II-Lite) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Reference-Counting](misc/SPARK2/Ada-SPARK-Reference-Counting) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Regular-Expression-Matching-Lite](misc/SPARK2/Ada-SPARK-Regular-Expression-Matching-Lite) | tool crash |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Remove-All-Adjacent-Duplicates](misc/SPARK2/Ada-SPARK-Remove-All-Adjacent-Duplicates) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Remove-All-Adjacent-Duplicates-II](misc/SPARK2/Ada-SPARK-Remove-All-Adjacent-Duplicates-II) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Remove-Duplicate-Letters](misc/SPARK2/Ada-SPARK-Remove-Duplicate-Letters) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Remove-Element](misc/SPARK2/Ada-SPARK-Remove-Element) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Remove-K-Digits](misc/SPARK2/Ada-SPARK-Remove-K-Digits) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Remove-Linked-List-Elements](misc/SPARK2/Ada-SPARK-Remove-Linked-List-Elements) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Remove-Nth-Node-From-End](misc/SPARK2/Ada-SPARK-Remove-Nth-Node-From-End) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Reorder-List](misc/SPARK2/Ada-SPARK-Reorder-List) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Replace-Elements-With-Greatest-On-Right](misc/SPARK2/Ada-SPARK-Replace-Elements-With-Greatest-On-Right) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Replace-Words](misc/SPARK2/Ada-SPARK-Replace-Words) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Reservoir-Sampling](misc/SPARK2/Ada-SPARK-Reservoir-Sampling) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Restore-IP-Addresses](misc/SPARK2/Ada-SPARK-Restore-IP-Addresses) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Reverse-Bits](misc/SPARK2/Ada-SPARK-Reverse-Bits) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Reverse-Integer](misc/SPARK2/Ada-SPARK-Reverse-Integer) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Reverse-Linked-List](misc/SPARK2/Ada-SPARK-Reverse-Linked-List) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Reverse-Linked-List-II](misc/SPARK2/Ada-SPARK-Reverse-Linked-List-II) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Reverse-Only-Letters](misc/SPARK2/Ada-SPARK-Reverse-Only-Letters) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Reverse-Pairs-Lite](misc/SPARK2/Ada-SPARK-Reverse-Pairs-Lite) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Reverse-Vowels](misc/SPARK2/Ada-SPARK-Reverse-Vowels) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Reverse-Words](misc/SPARK2/Ada-SPARK-Reverse-Words) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Ring-Buffer](misc/SPARK2/Ada-SPARK-Ring-Buffer) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Robot-Return-To-Origin](misc/SPARK2/Ada-SPARK-Robot-Return-To-Origin) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Roman-To-Int](misc/SPARK2/Ada-SPARK-Roman-To-Int) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Roman-To-Integer](misc/SPARK2/Ada-SPARK-Roman-To-Integer) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Rotate-Array](misc/SPARK2/Ada-SPARK-Rotate-Array) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Rotate-Image](misc/SPARK2/Ada-SPARK-Rotate-Image) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Rotate-List](misc/SPARK2/Ada-SPARK-Rotate-List) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Rotting-Oranges](misc/SPARK2/Ada-SPARK-Rotting-Oranges) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Round-Robin-Scheduling](misc/SPARK2/Ada-SPARK-Round-Robin-Scheduling) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Seat-Manager-Stub](misc/SPARK2/Ada-SPARK-Seat-Manager-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Seat-Reservation-Manager](misc/SPARK2/Ada-SPARK-Seat-Reservation-Manager) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Self-Dividing-Numbers](misc/SPARK2/Ada-SPARK-Self-Dividing-Numbers) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Sequence-Reconstruction-Lite](misc/SPARK2/Ada-SPARK-Sequence-Reconstruction-Lite) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Shift-2D-Grid](misc/SPARK2/Ada-SPARK-Shift-2D-Grid) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Shortest-Bridge](misc/SPARK2/Ada-SPARK-Shortest-Bridge) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Shortest-Common-Supersequence-Lite](misc/SPARK2/Ada-SPARK-Shortest-Common-Supersequence-Lite) | tool crash |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Shortest-Completing-Word](misc/SPARK2/Ada-SPARK-Shortest-Completing-Word) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Shortest-Job-Next](misc/SPARK2/Ada-SPARK-Shortest-Job-Next) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Shortest-Remaining-Time](misc/SPARK2/Ada-SPARK-Shortest-Remaining-Time) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Shortest-Word-Distance](misc/SPARK2/Ada-SPARK-Shortest-Word-Distance) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Sigmoid](misc/SPARK2/Ada-SPARK-Sigmoid) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Simplify-Path-Stub](misc/SPARK2/Ada-SPARK-Simplify-Path-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Single-Number](misc/SPARK2/Ada-SPARK-Single-Number) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Single-Number-II](misc/SPARK2/Ada-SPARK-Single-Number-II) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Single-Number-III](misc/SPARK2/Ada-SPARK-Single-Number-III) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Sliding-Window-Max](misc/SPARK2/Ada-SPARK-Sliding-Window-Max) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Sliding-Window-Maximum](misc/SPARK2/Ada-SPARK-Sliding-Window-Maximum) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Sliding-Window-Median](misc/SPARK2/Ada-SPARK-Sliding-Window-Median) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Smallest-Integer-Divisible-By-K](misc/SPARK2/Ada-SPARK-Smallest-Integer-Divisible-By-K) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Snapshot-Array-Stub](misc/SPARK2/Ada-SPARK-Snapshot-Array-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Softmin](misc/SPARK2/Ada-SPARK-Softmin) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Soup-Servings-Lite](misc/SPARK2/Ada-SPARK-Soup-Servings-Lite) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Spearman-Rank-Stub](misc/SPARK2/Ada-SPARK-Spearman-Rank-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Special-Array-With-X-Elements](misc/SPARK2/Ada-SPARK-Special-Array-With-X-Elements) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Split-Array-Largest-Sum](misc/SPARK2/Ada-SPARK-Split-Array-Largest-Sum) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Sqrt-Integer](misc/SPARK2/Ada-SPARK-Sqrt-Integer) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Sqrt-X](misc/SPARK2/Ada-SPARK-Sqrt-X) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Sqrtx](misc/SPARK2/Ada-SPARK-Sqrtx) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Stack-Bounded](misc/SPARK2/Ada-SPARK-Stack-Bounded) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Stack-Using-Queues-Stub](misc/SPARK2/Ada-SPARK-Stack-Using-Queues-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Standard-Score](misc/SPARK2/Ada-SPARK-Standard-Score) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Stock-Spanner-Stub](misc/SPARK2/Ada-SPARK-Stock-Spanner-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Stream-Of-Characters-Lite](misc/SPARK2/Ada-SPARK-Stream-Of-Characters-Lite) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Strstr-Naive](misc/SPARK2/Ada-SPARK-Strstr-Naive) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Student-Attendance-Record-I](misc/SPARK2/Ada-SPARK-Student-Attendance-Record-I) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Subarray-Sum-Equals-K](misc/SPARK2/Ada-SPARK-Subarray-Sum-Equals-K) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Subarrays-With-K-Different-Integers](misc/SPARK2/Ada-SPARK-Subarrays-With-K-Different-Integers) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Subsets](misc/SPARK2/Ada-SPARK-Subsets) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Subsets-Bitmask](misc/SPARK2/Ada-SPARK-Subsets-Bitmask) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Subsets-II](misc/SPARK2/Ada-SPARK-Subsets-II) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Subtract-Product-Sum-Digits](misc/SPARK2/Ada-SPARK-Subtract-Product-Sum-Digits) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Subtract-The-Product-And-Sum](misc/SPARK2/Ada-SPARK-Subtract-The-Product-And-Sum) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Sudoku-Solver-Lite](misc/SPARK2/Ada-SPARK-Sudoku-Solver-Lite) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Sum-Of-Left-Leaves](misc/SPARK2/Ada-SPARK-Sum-Of-Left-Leaves) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Sum-Of-Subarray-Minimums](misc/SPARK2/Ada-SPARK-Sum-Of-Subarray-Minimums) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Sum-Of-Two-Integers](misc/SPARK2/Ada-SPARK-Sum-Of-Two-Integers) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Sum-Root-To-Leaf-Numbers](misc/SPARK2/Ada-SPARK-Sum-Root-To-Leaf-Numbers) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Summary-Ranges](misc/SPARK2/Ada-SPARK-Summary-Ranges) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Super-Ugly-Number](misc/SPARK2/Ada-SPARK-Super-Ugly-Number) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Super-Ugly-Number-Stub](misc/SPARK2/Ada-SPARK-Super-Ugly-Number-Stub) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Surface-Area-Of-3D-Shapes](misc/SPARK2/Ada-SPARK-Surface-Area-Of-3D-Shapes) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Surrounded-Regions](misc/SPARK2/Ada-SPARK-Surrounded-Regions) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Swap-Nodes-In-Pairs](misc/SPARK2/Ada-SPARK-Swap-Nodes-In-Pairs) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Swapping-Nodes-In-A-Linked-List](misc/SPARK2/Ada-SPARK-Swapping-Nodes-In-A-Linked-List) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Swim-In-Rising-Water](misc/SPARK2/Ada-SPARK-Swim-In-Rising-Water) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Swim-In-Rising-Water-Stub](misc/SPARK2/Ada-SPARK-Swim-In-Rising-Water-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Tanimoto](misc/SPARK2/Ada-SPARK-Tanimoto) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Target-Sum](misc/SPARK2/Ada-SPARK-Target-Sum) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Target-Sum-Stub](misc/SPARK2/Ada-SPARK-Target-Sum-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-The-Skyline-Problem-Lite](misc/SPARK2/Ada-SPARK-The-Skyline-Problem-Lite) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Third-Maximum-Number](misc/SPARK2/Ada-SPARK-Third-Maximum-Number) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Three-Divisors](misc/SPARK2/Ada-SPARK-Three-Divisors) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Three-Sum](misc/SPARK2/Ada-SPARK-Three-Sum) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Three-Sum-Closest-Stub](misc/SPARK2/Ada-SPARK-Three-Sum-Closest-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Tic-Tac-Toe-Stub](misc/SPARK2/Ada-SPARK-Tic-Tac-Toe-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Time-Based-Key-Value-Store](misc/SPARK2/Ada-SPARK-Time-Based-Key-Value-Store) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Time-Map-Stub](misc/SPARK2/Ada-SPARK-Time-Map-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Title-To-Number](misc/SPARK2/Ada-SPARK-Title-To-Number) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-To-Lower-Case](misc/SPARK2/Ada-SPARK-To-Lower-Case) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Top-K-Frequent-Elements](misc/SPARK2/Ada-SPARK-Top-K-Frequent-Elements) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Top-K-Frequent-Stub](misc/SPARK2/Ada-SPARK-Top-K-Frequent-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Top-K-Frequent-Words](misc/SPARK2/Ada-SPARK-Top-K-Frequent-Words) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Top-Nodes-Algorithm](misc/SPARK2/Ada-SPARK-Top-Nodes-Algorithm) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Trapezoidal-Rule](misc/SPARK2/Ada-SPARK-Trapezoidal-Rule) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Trapping-Rain-Water](misc/SPARK2/Ada-SPARK-Trapping-Rain-Water) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Trapping-Rain-Water-II-Lite](misc/SPARK2/Ada-SPARK-Trapping-Rain-Water-II-Lite) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Triangle](misc/SPARK2/Ada-SPARK-Triangle) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Triangle-Min-Path](misc/SPARK2/Ada-SPARK-Triangle-Min-Path) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Tribonacci](misc/SPARK2/Ada-SPARK-Tribonacci) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Tribonacci-Number](misc/SPARK2/Ada-SPARK-Tribonacci-Number) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Tweet-Counts-Stub](misc/SPARK2/Ada-SPARK-Tweet-Counts-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Two-City-Scheduling](misc/SPARK2/Ada-SPARK-Two-City-Scheduling) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Two-Pointers-Sum](misc/SPARK2/Ada-SPARK-Two-Pointers-Sum) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Two-Sum](misc/SPARK2/Ada-SPARK-Two-Sum) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-UTF-8-Validation](misc/SPARK2/Ada-SPARK-UTF-8-Validation) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Ugly-Number](misc/SPARK2/Ada-SPARK-Ugly-Number) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Ugly-Number-II](misc/SPARK2/Ada-SPARK-Ugly-Number-II) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Uncommon-Words-From-Two-Sentences](misc/SPARK2/Ada-SPARK-Uncommon-Words-From-Two-Sentences) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Underground-System-Stub](misc/SPARK2/Ada-SPARK-Underground-System-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Union-Find](misc/SPARK2/Ada-SPARK-Union-Find) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Unique-Email-Addresses](misc/SPARK2/Ada-SPARK-Unique-Email-Addresses) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Unique-Morse-Code-Words](misc/SPARK2/Ada-SPARK-Unique-Morse-Code-Words) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Unique-Paths](misc/SPARK2/Ada-SPARK-Unique-Paths) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Unique-Paths-II](misc/SPARK2/Ada-SPARK-Unique-Paths-II) | proven | yes |  |  |  |
| [misc/SPARK2/Ada-SPARK-Valid-Anagram](misc/SPARK2/Ada-SPARK-Valid-Anagram) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Valid-IP-Address-Stub](misc/SPARK2/Ada-SPARK-Valid-IP-Address-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Valid-Number-Stub](misc/SPARK2/Ada-SPARK-Valid-Number-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Valid-Palindrome](misc/SPARK2/Ada-SPARK-Valid-Palindrome) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Valid-Palindrome-II](misc/SPARK2/Ada-SPARK-Valid-Palindrome-II) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Valid-Parentheses](misc/SPARK2/Ada-SPARK-Valid-Parentheses) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Valid-Square](misc/SPARK2/Ada-SPARK-Valid-Square) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Valid-Sudoku-Stub](misc/SPARK2/Ada-SPARK-Valid-Sudoku-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Valid-Word-Abbreviation](misc/SPARK2/Ada-SPARK-Valid-Word-Abbreviation) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Validate-Stack-Sequences](misc/SPARK2/Ada-SPARK-Validate-Stack-Sequences) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Vector-2D-Stub](misc/SPARK2/Ada-SPARK-Vector-2D-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Vector-Dot-Cross](misc/SPARK2/Ada-SPARK-Vector-Dot-Cross) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Water-Bottles](misc/SPARK2/Ada-SPARK-Water-Bottles) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Wiggle-Subsequence](misc/SPARK2/Ada-SPARK-Wiggle-Subsequence) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Wildcard-Matching-Lite](misc/SPARK2/Ada-SPARK-Wildcard-Matching-Lite) | tool crash |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Word-Break](misc/SPARK2/Ada-SPARK-Word-Break) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Word-Break-II](misc/SPARK2/Ada-SPARK-Word-Break-II) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Word-Break-Stub](misc/SPARK2/Ada-SPARK-Word-Break-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Word-Ladder-II-Lite](misc/SPARK2/Ada-SPARK-Word-Ladder-II-Lite) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Word-Ladder-Lite](misc/SPARK2/Ada-SPARK-Word-Ladder-Lite) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Word-Ladder-Stub](misc/SPARK2/Ada-SPARK-Word-Ladder-Stub) | proven |  | yes | yes |  |
| [misc/SPARK2/Ada-SPARK-Word-Pattern](misc/SPARK2/Ada-SPARK-Word-Pattern) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-XOR-Of-Numbers-Range](misc/SPARK2/Ada-SPARK-XOR-Of-Numbers-Range) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-XOR-Operation-In-An-Array](misc/SPARK2/Ada-SPARK-XOR-Operation-In-An-Array) | proven |  |  |  |  |
| [misc/SPARK2/Ada-SPARK-Zigzag-Iterator-Stub](misc/SPARK2/Ada-SPARK-Zigzag-Iterator-Stub) | proven |  |  |  |  |
| [misc/SPARK2/Pattern-132](misc/SPARK2/Pattern-132) | proven |  |  |  |  |

### misc/SPARK4

**11 folders.**

| folder path | Silver | Training-ready | Stub | Needs implementation | Open findings |
|---|---|---|---|---|---|
| [misc/SPARK4/Acorn-Generator](misc/SPARK4/Acorn-Generator) | proven |  |  |  |  |
| [misc/SPARK4/Ada-SPARK-Accumulator](misc/SPARK4/Ada-SPARK-Accumulator) | proven |  |  |  |  |
| [misc/SPARK4/Ada-SPARK-Blum-Blum-Shub](misc/SPARK4/Ada-SPARK-Blum-Blum-Shub) | proven |  |  |  |  |
| [misc/SPARK4/Ada-SPARK-Heaps-Algorithm](misc/SPARK4/Ada-SPARK-Heaps-Algorithm) | proven |  |  |  |  |
| [misc/SPARK4/Ada-SPARK-K-Way-Merge](misc/SPARK4/Ada-SPARK-K-Way-Merge) | proven |  |  |  |  |
| [misc/SPARK4/Ada-SPARK-Lagged-Fibonacci-Generator](misc/SPARK4/Ada-SPARK-Lagged-Fibonacci-Generator) | proven |  |  |  |  |
| [misc/SPARK4/Ada-SPARK-Lemke-Howson](misc/SPARK4/Ada-SPARK-Lemke-Howson) | proven |  |  |  |  |
| [misc/SPARK4/Ada-SPARK-Package-Merge-Algorithm](misc/SPARK4/Ada-SPARK-Package-Merge-Algorithm) | proven |  |  |  |  |
| [misc/SPARK4/Ada-SPARK-Selection-Algorithm](misc/SPARK4/Ada-SPARK-Selection-Algorithm) | proven |  |  |  |  |
| [misc/SPARK4/Ada-SPARK-Shortest-Seek-First](misc/SPARK4/Ada-SPARK-Shortest-Seek-First) | no SPARK |  |  |  |  |
| [misc/SPARK4/demo](misc/SPARK4/demo) | skipped (no SPARK_Mode) |  |  |  |  |

## ml

**25 folders.**

### ml/Ada

**22 folders.**

| folder path | Silver | Training-ready | Stub | Needs implementation | Open findings |
|---|---|---|---|---|---|
| [ml/Ada/AdaBoost](ml/Ada/AdaBoost) | no SPARK |  |  |  |  |
| [ml/Ada/Alopex](ml/Ada/Alopex) | no SPARK |  |  |  |  |
| [ml/Ada/Backpropagation](ml/Ada/Backpropagation) | proven |  |  |  |  |
| [ml/Ada/Boosting-Meta-Algorithm](ml/Ada/Boosting-Meta-Algorithm) | no SPARK |  |  |  |  |
| [ml/Ada/BrownBoost](ml/Ada/BrownBoost) | no SPARK |  |  |  |  |
| [ml/Ada/Expectation-Maximization](ml/Ada/Expectation-Maximization) | no SPARK |  |  |  |  |
| [ml/Ada/Forward-Backward](ml/Ada/Forward-Backward) | no SPARK |  |  |  |  |
| [ml/Ada/Hidden-Markov-Model](ml/Ada/Hidden-Markov-Model) | no SPARK |  |  |  |  |
| [ml/Ada/LPBoost](ml/Ada/LPBoost) | proven |  |  |  |  |
| [ml/Ada/LogitBoost](ml/Ada/LogitBoost) | no SPARK |  |  |  |  |
| [ml/Ada/Naive-Bayes-Classifier](ml/Ada/Naive-Bayes-Classifier) | no SPARK |  |  |  |  |
| [ml/Ada/Neural-Network](ml/Ada/Neural-Network) | no SPARK |  |  |  |  |
| [ml/Ada/Perceptron](ml/Ada/Perceptron) | no SPARK |  |  |  |  |
| [ml/Ada/Policy-Iteration](ml/Ada/Policy-Iteration) | no SPARK |  |  |  |  |
| [ml/Ada/Pulse-Coupled-Neural-Networks](ml/Ada/Pulse-Coupled-Neural-Networks) | no SPARK |  |  |  |  |
| [ml/Ada/Q-Learning](ml/Ada/Q-Learning) | not built |  |  |  |  |
| [ml/Ada/Random-Forest](ml/Ada/Random-Forest) | no SPARK |  |  |  |  |
| [ml/Ada/Reinforcement-Learning](ml/Ada/Reinforcement-Learning) | no SPARK |  |  |  |  |
| [ml/Ada/Support-Vector-Machine](ml/Ada/Support-Vector-Machine) | no SPARK |  |  |  |  |
| [ml/Ada/Value-Iteration](ml/Ada/Value-Iteration) | no SPARK |  |  |  |  |
| [ml/Ada/Viterbi](ml/Ada/Viterbi) | no SPARK |  |  |  |  |
| [ml/Ada/Winnow-Algorithm](ml/Ada/Winnow-Algorithm) | no SPARK |  |  |  |  |

### ml/SPARK2

**3 folders.**

| folder path | Silver | Training-ready | Stub | Needs implementation | Open findings |
|---|---|---|---|---|---|
| [ml/SPARK2/Ada-SPARK-ReLU](ml/SPARK2/Ada-SPARK-ReLU) | proven |  |  |  |  |
| [ml/SPARK2/Ada-SPARK-Softmax](ml/SPARK2/Ada-SPARK-Softmax) | proven |  |  |  |  |
| [ml/SPARK2/Linear-Regression](ml/SPARK2/Linear-Regression) | proven |  |  |  |  |

## numerical

**108 folders.**

### numerical/Ada

**78 folders.**

| folder path | Silver | Training-ready | Stub | Needs implementation | Open findings |
|---|---|---|---|---|---|
| [numerical/Ada/Aks-Primality-Test](numerical/Ada/Aks-Primality-Test) | no SPARK |  |  |  |  |
| [numerical/Ada/Arnoldi](numerical/Ada/Arnoldi) | no SPARK |  |  |  |  |
| [numerical/Ada/BBP](numerical/Ada/BBP) | no SPARK |  |  |  |  |
| [numerical/Ada/BFGS](numerical/Ada/BFGS) | no SPARK |  |  |  |  |
| [numerical/Ada/BKM](numerical/Ada/BKM) | no SPARK |  |  |  |  |
| [numerical/Ada/Biconjugate-Gradient](numerical/Ada/Biconjugate-Gradient) | no SPARK |  |  |  |  |
| [numerical/Ada/Bicubic-Interpolation](numerical/Ada/Bicubic-Interpolation) | no SPARK |  |  |  |  |
| [numerical/Ada/Bilinear-Interpolation](numerical/Ada/Bilinear-Interpolation) | no SPARK |  |  |  |  |
| [numerical/Ada/Binary-GCD](numerical/Ada/Binary-GCD) | no SPARK |  |  |  |  |
| [numerical/Ada/Birkhoff-Interpolation](numerical/Ada/Birkhoff-Interpolation) | no SPARK |  |  |  |  |
| [numerical/Ada/Bisection-Method](numerical/Ada/Bisection-Method) | no SPARK |  |  |  |  |
| [numerical/Ada/Bluesteins-FFT-Algorithm](numerical/Ada/Bluesteins-FFT-Algorithm) | no SPARK |  |  |  |  |
| [numerical/Ada/Borwein](numerical/Ada/Borwein) | no SPARK |  |  |  |  |
| [numerical/Ada/Brents-Algorithm](numerical/Ada/Brents-Algorithm) | no SPARK |  |  |  |  |
| [numerical/Ada/Bruuns-FFT-Algorithm](numerical/Ada/Bruuns-FFT-Algorithm) | no SPARK |  |  |  |  |
| [numerical/Ada/CORDIC](numerical/Ada/CORDIC) | no SPARK |  |  |  |  |
| [numerical/Ada/Cantor-Zassenhaus](numerical/Ada/Cantor-Zassenhaus) | no SPARK |  |  |  |  |
| [numerical/Ada/Chakravala](numerical/Ada/Chakravala) | no SPARK |  |  |  |  |
| [numerical/Ada/Chudnovsky](numerical/Ada/Chudnovsky) | no SPARK |  |  |  |  |
| [numerical/Ada/Cipolla](numerical/Ada/Cipolla) | no SPARK |  |  |  |  |
| [numerical/Ada/Conjugate-Gradient](numerical/Ada/Conjugate-Gradient) | no SPARK |  |  |  |  |
| [numerical/Ada/Cooley-Tukey-FFT-Algorithm](numerical/Ada/Cooley-Tukey-FFT-Algorithm) | no SPARK |  |  |  |  |
| [numerical/Ada/Cubic-Interpolation](numerical/Ada/Cubic-Interpolation) | no SPARK |  |  |  |  |
| [numerical/Ada/Dixon](numerical/Ada/Dixon) | no SPARK |  |  |  |  |
| [numerical/Ada/Euclidean-Algorithm](numerical/Ada/Euclidean-Algorithm) | no SPARK |  |  |  |  |
| [numerical/Ada/Extended-Euclidean-Algorithm](numerical/Ada/Extended-Euclidean-Algorithm) | no SPARK |  |  |  |  |
| [numerical/Ada/Fast-Fourier-Transform](numerical/Ada/Fast-Fourier-Transform) | no SPARK |  |  |  |  |
| [numerical/Ada/Fermat-Primality-Test](numerical/Ada/Fermat-Primality-Test) | no SPARK |  |  |  |  |
| [numerical/Ada/Furer](numerical/Ada/Furer) | no SPARK |  |  |  |  |
| [numerical/Ada/Gauss-Legendre](numerical/Ada/Gauss-Legendre) | no SPARK |  |  |  |  |
| [numerical/Ada/Gauss-Newton](numerical/Ada/Gauss-Newton) | no SPARK |  |  |  |  |
| [numerical/Ada/General-Number-Field-Sieve](numerical/Ada/General-Number-Field-Sieve) | no SPARK |  |  |  |  |
| [numerical/Ada/Gradient-Descent](numerical/Ada/Gradient-Descent) | not built |  |  |  |  |
| [numerical/Ada/Hermite-Interpolation](numerical/Ada/Hermite-Interpolation) | no SPARK |  |  |  |  |
| [numerical/Ada/Hybrid-Monte-Carlo](numerical/Ada/Hybrid-Monte-Carlo) | no SPARK |  |  |  |  |
| [numerical/Ada/Interior-Point-Method](numerical/Ada/Interior-Point-Method) | no SPARK |  |  |  |  |
| [numerical/Ada/Karatsuba](numerical/Ada/Karatsuba) | no SPARK |  |  |  |  |
| [numerical/Ada/Lagrange-Interpolation](numerical/Ada/Lagrange-Interpolation) | no SPARK |  |  |  |  |
| [numerical/Ada/Lanczos](numerical/Ada/Lanczos) | no SPARK |  |  |  |  |
| [numerical/Ada/Lanczos-Resampling](numerical/Ada/Lanczos-Resampling) | no SPARK |  |  |  |  |
| [numerical/Ada/Levenberg-Marquardt](numerical/Ada/Levenberg-Marquardt) | no SPARK |  |  |  |  |
| [numerical/Ada/Linear-Congruential-Generator](numerical/Ada/Linear-Congruential-Generator) | no SPARK |  |  |  |  |
| [numerical/Ada/Linear-Interpolation](numerical/Ada/Linear-Interpolation) | no SPARK |  |  |  |  |
| [numerical/Ada/Lucas-Primality-Test](numerical/Ada/Lucas-Primality-Test) | no SPARK |  |  |  |  |
| [numerical/Ada/MISER](numerical/Ada/MISER) | no SPARK |  |  |  |  |
| [numerical/Ada/Mersenne-Twister](numerical/Ada/Mersenne-Twister) | no SPARK |  |  |  |  |
| [numerical/Ada/Metropolis-Hastings](numerical/Ada/Metropolis-Hastings) | no SPARK |  |  |  |  |
| [numerical/Ada/Metropolis-Light-Transport](numerical/Ada/Metropolis-Light-Transport) | no SPARK |  |  |  |  |
| [numerical/Ada/Miller-Rabin](numerical/Ada/Miller-Rabin) | no SPARK |  |  |  |  |
| [numerical/Ada/Monotone-Cubic-Interpolation](numerical/Ada/Monotone-Cubic-Interpolation) | no SPARK |  |  |  |  |
| [numerical/Ada/Multivariate-Interpolation](numerical/Ada/Multivariate-Interpolation) | no SPARK |  |  |  |  |
| [numerical/Ada/Nearest-Neighbor-Interpolation](numerical/Ada/Nearest-Neighbor-Interpolation) | no SPARK |  |  |  |  |
| [numerical/Ada/Neville](numerical/Ada/Neville) | no SPARK |  |  |  |  |
| [numerical/Ada/Newells-Algorithm](numerical/Ada/Newells-Algorithm) | no SPARK |  |  |  |  |
| [numerical/Ada/Newton-Raphson-Division](numerical/Ada/Newton-Raphson-Division) | no SPARK |  |  |  |  |
| [numerical/Ada/Pareto-Interpolation](numerical/Ada/Pareto-Interpolation) | no SPARK |  |  |  |  |
| [numerical/Ada/Partial-Least-Squares](numerical/Ada/Partial-Least-Squares) | no SPARK |  |  |  |  |
| [numerical/Ada/Pollards-Kangaroo-Algorithm](numerical/Ada/Pollards-Kangaroo-Algorithm) | no SPARK |  |  |  |  |
| [numerical/Ada/Pollards-P-1](numerical/Ada/Pollards-P-1) | no SPARK |  |  |  |  |
| [numerical/Ada/Pollards-Rho](numerical/Ada/Pollards-Rho) | no SPARK |  |  |  |  |
| [numerical/Ada/Pollards-Rho-Logarithms](numerical/Ada/Pollards-Rho-Logarithms) | no SPARK |  |  |  |  |
| [numerical/Ada/Polynomial-Interpolation](numerical/Ada/Polynomial-Interpolation) | no SPARK |  |  |  |  |
| [numerical/Ada/Primality-Test](numerical/Ada/Primality-Test) | no SPARK |  |  |  |  |
| [numerical/Ada/Prime-Factor-FFT-Algorithm](numerical/Ada/Prime-Factor-FFT-Algorithm) | no SPARK |  |  |  |  |
| [numerical/Ada/Prime-Factorization](numerical/Ada/Prime-Factorization) | no SPARK |  |  |  |  |
| [numerical/Ada/Quadratic-Sieve](numerical/Ada/Quadratic-Sieve) | no SPARK |  |  |  |  |
| [numerical/Ada/Raders-FFT-Algorithm](numerical/Ada/Raders-FFT-Algorithm) | no SPARK |  |  |  |  |
| [numerical/Ada/Runge-Kutta](numerical/Ada/Runge-Kutta) | no SPARK |  |  |  |  |
| [numerical/Ada/Secant-Method](numerical/Ada/Secant-Method) | no SPARK |  |  |  |  |
| [numerical/Ada/Sieve-Of-Atkin](numerical/Ada/Sieve-Of-Atkin) | no SPARK |  |  |  |  |
| [numerical/Ada/Sieve-Of-Eratosthenes](numerical/Ada/Sieve-Of-Eratosthenes) | no SPARK |  |  |  |  |
| [numerical/Ada/Sieve-Of-Sundaram](numerical/Ada/Sieve-Of-Sundaram) | no SPARK |  |  |  |  |
| [numerical/Ada/Special-Number-Field-Sieve](numerical/Ada/Special-Number-Field-Sieve) | no SPARK |  |  |  |  |
| [numerical/Ada/Spline-Interpolation](numerical/Ada/Spline-Interpolation) | no SPARK |  |  |  |  |
| [numerical/Ada/Tonelli-Shanks](numerical/Ada/Tonelli-Shanks) | no SPARK |  |  |  |  |
| [numerical/Ada/Tricubic-Interpolation](numerical/Ada/Tricubic-Interpolation) | no SPARK |  |  |  |  |
| [numerical/Ada/Trigonometric-Interpolation](numerical/Ada/Trigonometric-Interpolation) | no SPARK |  |  |  |  |
| [numerical/Ada/Ziggurat-Algorithm](numerical/Ada/Ziggurat-Algorithm) | no SPARK |  |  |  |  |

### numerical/SPARK2

**23 folders.**

| folder path | Silver | Training-ready | Stub | Needs implementation | Open findings |
|---|---|---|---|---|---|
| [numerical/SPARK2/Ada-SPARK-Bisection-Method](numerical/SPARK2/Ada-SPARK-Bisection-Method) | proven |  |  |  |  |
| [numerical/SPARK2/Ada-SPARK-Chebyshev-Distance](numerical/SPARK2/Ada-SPARK-Chebyshev-Distance) | proven |  |  |  |  |
| [numerical/SPARK2/Ada-SPARK-Cooley-Tukey-FFT](numerical/SPARK2/Ada-SPARK-Cooley-Tukey-FFT) | proven |  |  |  |  |
| [numerical/SPARK2/Ada-SPARK-Count-Primes](numerical/SPARK2/Ada-SPARK-Count-Primes) | proven |  |  |  |  |
| [numerical/SPARK2/Ada-SPARK-Count-Primes-Stub](numerical/SPARK2/Ada-SPARK-Count-Primes-Stub) | proven |  | yes | yes |  |
| [numerical/SPARK2/Ada-SPARK-Extended-Euclidean](numerical/SPARK2/Ada-SPARK-Extended-Euclidean) | proven |  |  |  |  |
| [numerical/SPARK2/Ada-SPARK-Lagrange-Interpolation](numerical/SPARK2/Ada-SPARK-Lagrange-Interpolation) | proven |  |  |  |  |
| [numerical/SPARK2/Ada-SPARK-Maximum-Performance-Of-A-Team-Lite](numerical/SPARK2/Ada-SPARK-Maximum-Performance-Of-A-Team-Lite) | proven |  |  |  |  |
| [numerical/SPARK2/Ada-SPARK-Minimum-Limit-Of-Balls-In-A-Bag](numerical/SPARK2/Ada-SPARK-Minimum-Limit-Of-Balls-In-A-Bag) | proven |  |  |  |  |
| [numerical/SPARK2/Ada-SPARK-Modular-Exponentiation](numerical/SPARK2/Ada-SPARK-Modular-Exponentiation) | proven |  |  |  |  |
| [numerical/SPARK2/Ada-SPARK-Newton-Raphson](numerical/SPARK2/Ada-SPARK-Newton-Raphson) | proven |  |  |  |  |
| [numerical/SPARK2/Ada-SPARK-Perfect-Number](numerical/SPARK2/Ada-SPARK-Perfect-Number) | proven |  |  |  |  |
| [numerical/SPARK2/Ada-SPARK-Perfect-Squares](numerical/SPARK2/Ada-SPARK-Perfect-Squares) | proven |  |  |  |  |
| [numerical/SPARK2/Ada-SPARK-Prime-Check](numerical/SPARK2/Ada-SPARK-Prime-Check) | proven |  |  |  |  |
| [numerical/SPARK2/Ada-SPARK-Prime-Number-Of-Set-Bits](numerical/SPARK2/Ada-SPARK-Prime-Number-Of-Set-Bits) | proven |  |  |  |  |
| [numerical/SPARK2/Ada-SPARK-Prime-Number-Of-Set-Bits-In-Binary-Representation](numerical/SPARK2/Ada-SPARK-Prime-Number-Of-Set-Bits-In-Binary-Representation) | proven |  |  |  |  |
| [numerical/SPARK2/Ada-SPARK-Secant-Method](numerical/SPARK2/Ada-SPARK-Secant-Method) | proven |  |  |  |  |
| [numerical/SPARK2/Ada-SPARK-Sieve-Of-Eratosthenes](numerical/SPARK2/Ada-SPARK-Sieve-Of-Eratosthenes) | proven |  |  |  |  |
| [numerical/SPARK2/Ada-SPARK-Simpson-Rule](numerical/SPARK2/Ada-SPARK-Simpson-Rule) | proven |  |  |  |  |
| [numerical/SPARK2/Ada-SPARK-Successful-Pairs-Of-Spells-And-Potions](numerical/SPARK2/Ada-SPARK-Successful-Pairs-Of-Spells-And-Potions) | proven |  |  |  |  |
| [numerical/SPARK2/Ada-SPARK-Valid-Perfect-Square](numerical/SPARK2/Ada-SPARK-Valid-Perfect-Square) | proven |  |  |  |  |
| [numerical/SPARK2/Ada-SPARK-Walls-And-Gates](numerical/SPARK2/Ada-SPARK-Walls-And-Gates) | proven |  |  |  |  |
| [numerical/SPARK2/Babylonian-Sqrt](numerical/SPARK2/Babylonian-Sqrt) | proven |  |  |  |  |

### numerical/SPARK4

**7 folders.**

| folder path | Silver | Training-ready | Stub | Needs implementation | Open findings |
|---|---|---|---|---|---|
| [numerical/SPARK4/Ada-SPARK-Brents-Algorithm](numerical/SPARK4/Ada-SPARK-Brents-Algorithm) | proven |  |  |  |  |
| [numerical/SPARK4/Ada-SPARK-Euclidean-Algorithm](numerical/SPARK4/Ada-SPARK-Euclidean-Algorithm) | proven |  |  |  |  |
| [numerical/SPARK4/Ada-SPARK-Extended-Euclidean-Algorithm](numerical/SPARK4/Ada-SPARK-Extended-Euclidean-Algorithm) | proven | yes |  |  |  |
| [numerical/SPARK4/Ada-SPARK-Linear-Congruential-Generator](numerical/SPARK4/Ada-SPARK-Linear-Congruential-Generator) | proven |  |  |  |  |
| [numerical/SPARK4/Ada-SPARK-Mersenne-Twister](numerical/SPARK4/Ada-SPARK-Mersenne-Twister) | proven |  |  |  |  |
| [numerical/SPARK4/Ada-SPARK-Modular-Arithmetic](numerical/SPARK4/Ada-SPARK-Modular-Arithmetic) | proven |  |  |  |  |
| [numerical/SPARK4/Binary-Gcd](numerical/SPARK4/Binary-Gcd) | proven | yes |  |  |  |

## parsing

**18 folders.**

### parsing/Ada

**15 folders.**

| folder path | Silver | Training-ready | Stub | Needs implementation | Open findings |
|---|---|---|---|---|---|
| [parsing/Ada/Canonical-LR-Parser](parsing/Ada/Canonical-LR-Parser) | no SPARK |  |  |  |  |
| [parsing/Ada/Cyk-Algorithm](parsing/Ada/Cyk-Algorithm) | no SPARK |  |  |  |  |
| [parsing/Ada/GLR-Parser](parsing/Ada/GLR-Parser) | no SPARK |  |  |  |  |
| [parsing/Ada/LALR](parsing/Ada/LALR) | no SPARK |  |  |  |  |
| [parsing/Ada/LL-Parser](parsing/Ada/LL-Parser) | no SPARK |  |  |  |  |
| [parsing/Ada/LR-Parser](parsing/Ada/LR-Parser) | no SPARK |  |  |  |  |
| [parsing/Ada/Operator-Precedence-Parser](parsing/Ada/Operator-Precedence-Parser) | no SPARK |  |  |  |  |
| [parsing/Ada/Packrat-Parser](parsing/Ada/Packrat-Parser) | no SPARK |  |  |  |  |
| [parsing/Ada/Pratt-Parser](parsing/Ada/Pratt-Parser) | no SPARK |  |  |  |  |
| [parsing/Ada/Recursive-Descent-Parser](parsing/Ada/Recursive-Descent-Parser) | no SPARK |  |  |  |  |
| [parsing/Ada/Shunting-Yard-Algorithm](parsing/Ada/Shunting-Yard-Algorithm) | no SPARK |  |  |  |  |
| [parsing/Ada/Simple-LR-Parser](parsing/Ada/Simple-LR-Parser) | no SPARK |  |  |  |  |
| [parsing/Ada/Simple-Precdence-Parser](parsing/Ada/Simple-Precdence-Parser) | no SPARK |  |  |  |  |
| [parsing/Ada/Simplex-Algorithm](parsing/Ada/Simplex-Algorithm) | no SPARK |  |  |  |  |
| [parsing/Ada/Step-Parser](parsing/Ada/Step-Parser) | no SPARK |  |  |  |  |

### parsing/SPARK2

**3 folders.**

| folder path | Silver | Training-ready | Stub | Needs implementation | Open findings |
|---|---|---|---|---|---|
| [parsing/SPARK2/Ada-SPARK-Sparse-Set](parsing/SPARK2/Ada-SPARK-Sparse-Set) | proven |  |  |  |  |
| [parsing/SPARK2/Ada-SPARK-Sparse-Vector-Dot-Stub](parsing/SPARK2/Ada-SPARK-Sparse-Vector-Dot-Stub) | proven |  | yes | yes |  |
| [parsing/SPARK2/Sparse-Dot](parsing/SPARK2/Sparse-Dot) | proven |  |  |  |  |

## searching

**64 folders.**

### searching/Ada

**34 folders.**

| folder path | Silver | Training-ready | Stub | Needs implementation | Open findings |
|---|---|---|---|---|---|
| [searching/Ada/Beam-Search](searching/Ada/Beam-Search) | no SPARK |  |  |  |  |
| [searching/Ada/Best-First-Search](searching/Ada/Best-First-Search) | no SPARK |  |  |  |  |
| [searching/Ada/Bidirectional-Search](searching/Ada/Bidirectional-Search) | no SPARK |  |  |  |  |
| [searching/Ada/Binary-Search](searching/Ada/Binary-Search) | no SPARK |  |  |  |  |
| [searching/Ada/Breadth-First-Search](searching/Ada/Breadth-First-Search) | no SPARK |  |  |  |  |
| [searching/Ada/Brute-Force-Search](searching/Ada/Brute-Force-Search) | no SPARK |  |  |  |  |
| [searching/Ada/Chien-Search](searching/Ada/Chien-Search) | no SPARK |  |  |  |  |
| [searching/Ada/Depth-First-Search](searching/Ada/Depth-First-Search) | no SPARK |  |  |  |  |
| [searching/Ada/Eytzinger-Binary-Search](searching/Ada/Eytzinger-Binary-Search) | no SPARK |  |  |  |  |
| [searching/Ada/Fibonacci-Search](searching/Ada/Fibonacci-Search) | no SPARK |  |  |  |  |
| [searching/Ada/Golden-Section-Search](searching/Ada/Golden-Section-Search) | no SPARK |  |  |  |  |
| [searching/Ada/Grid-Search](searching/Ada/Grid-Search) | no SPARK |  |  |  |  |
| [searching/Ada/Harmony-Search](searching/Ada/Harmony-Search) | no SPARK |  |  |  |  |
| [searching/Ada/Hyperlink-Induced-Topic-Search](searching/Ada/Hyperlink-Induced-Topic-Search) | no SPARK |  |  |  |  |
| [searching/Ada/Interpolation-Search](searching/Ada/Interpolation-Search) | no SPARK |  |  |  |  |
| [searching/Ada/Introselect](searching/Ada/Introselect) | no SPARK |  |  |  |  |
| [searching/Ada/Iterative-Deepening-Depth-First-Search](searching/Ada/Iterative-Deepening-Depth-First-Search) | no SPARK |  |  |  |  |
| [searching/Ada/Jump-Point-Search](searching/Ada/Jump-Point-Search) | no SPARK |  |  |  |  |
| [searching/Ada/Jump-Search](searching/Ada/Jump-Search) | no SPARK |  |  |  |  |
| [searching/Ada/Lexicographic-Breadth-First-Search](searching/Ada/Lexicographic-Breadth-First-Search) | no SPARK |  |  |  |  |
| [searching/Ada/Line-Search](searching/Ada/Line-Search) | no SPARK |  |  |  |  |
| [searching/Ada/Linear-Search](searching/Ada/Linear-Search) | no SPARK |  |  |  |  |
| [searching/Ada/Local-Search](searching/Ada/Local-Search) | no SPARK |  |  |  |  |
| [searching/Ada/Monte-Carlo-Tree-Search](searching/Ada/Monte-Carlo-Tree-Search) | no SPARK |  |  |  |  |
| [searching/Ada/Nearest-Neighbor-Search](searching/Ada/Nearest-Neighbor-Search) | no SPARK |  |  |  |  |
| [searching/Ada/Quantum-Walk-Search](searching/Ada/Quantum-Walk-Search) | no SPARK |  |  |  |  |
| [searching/Ada/Quickselect](searching/Ada/Quickselect) | no SPARK |  |  |  |  |
| [searching/Ada/Random-Search](searching/Ada/Random-Search) | no SPARK |  |  |  |  |
| [searching/Ada/Substring-Search](searching/Ada/Substring-Search) | no SPARK |  |  |  |  |
| [searching/Ada/Tabu-Search](searching/Ada/Tabu-Search) | no SPARK |  |  |  |  |
| [searching/Ada/Ternary-Search](searching/Ada/Ternary-Search) | no SPARK |  |  |  |  |
| [searching/Ada/Trigram-Search](searching/Ada/Trigram-Search) | no SPARK |  |  |  |  |
| [searching/Ada/Uniform-Binary-Search](searching/Ada/Uniform-Binary-Search) | no SPARK |  |  |  |  |
| [searching/Ada/Uniform-Cost-Search](searching/Ada/Uniform-Cost-Search) | no SPARK |  |  |  |  |

### searching/SPARK2

**20 folders.**

| folder path | Silver | Training-ready | Stub | Needs implementation | Open findings |
|---|---|---|---|---|---|
| [searching/SPARK2/Ada-SPARK-Binary-Search-Lower-Bound](searching/SPARK2/Ada-SPARK-Binary-Search-Lower-Bound) | proven |  |  |  |  |
| [searching/SPARK2/Ada-SPARK-Binary-Search-Upper-Bound](searching/SPARK2/Ada-SPARK-Binary-Search-Upper-Bound) | proven |  | yes | yes |  |
| [searching/SPARK2/Ada-SPARK-Design-Add-And-Search-Words](searching/SPARK2/Ada-SPARK-Design-Add-And-Search-Words) | proven |  |  |  |  |
| [searching/SPARK2/Ada-SPARK-Exponential-Search](searching/SPARK2/Ada-SPARK-Exponential-Search) | proven |  |  |  |  |
| [searching/SPARK2/Ada-SPARK-Increasing-Order-Search-Tree](searching/SPARK2/Ada-SPARK-Increasing-Order-Search-Tree) | proven |  |  |  |  |
| [searching/SPARK2/Ada-SPARK-Insert-Into-A-Binary-Search-Tree](searching/SPARK2/Ada-SPARK-Insert-Into-A-Binary-Search-Tree) | proven |  |  |  |  |
| [searching/SPARK2/Ada-SPARK-Naive-String-Search](searching/SPARK2/Ada-SPARK-Naive-String-Search) | proven |  |  |  |  |
| [searching/SPARK2/Ada-SPARK-Search-2D-Matrix](searching/SPARK2/Ada-SPARK-Search-2D-Matrix) | proven |  |  |  |  |
| [searching/SPARK2/Ada-SPARK-Search-A-2D-Matrix](searching/SPARK2/Ada-SPARK-Search-A-2D-Matrix) | proven |  |  |  |  |
| [searching/SPARK2/Ada-SPARK-Search-A-2D-Matrix-II](searching/SPARK2/Ada-SPARK-Search-A-2D-Matrix-II) | proven |  |  |  |  |
| [searching/SPARK2/Ada-SPARK-Search-In-A-Binary-Search-Tree](searching/SPARK2/Ada-SPARK-Search-In-A-Binary-Search-Tree) | proven |  |  |  |  |
| [searching/SPARK2/Ada-SPARK-Search-Insert-Position](searching/SPARK2/Ada-SPARK-Search-Insert-Position) | proven |  |  |  |  |
| [searching/SPARK2/Ada-SPARK-Trigram-Search](searching/SPARK2/Ada-SPARK-Trigram-Search) | proven |  |  |  |  |
| [searching/SPARK2/Ada-SPARK-Trim-A-Binary-Search-Tree](searching/SPARK2/Ada-SPARK-Trim-A-Binary-Search-Tree) | proven |  |  |  |  |
| [searching/SPARK2/Ada-SPARK-Unique-Binary-Search-Trees](searching/SPARK2/Ada-SPARK-Unique-Binary-Search-Trees) | proven |  |  |  |  |
| [searching/SPARK2/Ada-SPARK-Unique-Binary-Search-Trees-II-Lite](searching/SPARK2/Ada-SPARK-Unique-Binary-Search-Trees-II-Lite) | proven |  | yes | yes |  |
| [searching/SPARK2/Ada-SPARK-Validate-Binary-Search-Tree](searching/SPARK2/Ada-SPARK-Validate-Binary-Search-Tree) | proven |  |  |  |  |
| [searching/SPARK2/Ada-SPARK-Word-Search](searching/SPARK2/Ada-SPARK-Word-Search) | proven |  | yes | yes |  |
| [searching/SPARK2/Ada-SPARK-Word-Search-II-Lite](searching/SPARK2/Ada-SPARK-Word-Search-II-Lite) | proven |  |  |  |  |
| [searching/SPARK2/Bst-Insert-Search](searching/SPARK2/Bst-Insert-Search) | proven |  |  |  |  |

### searching/SPARK4

**10 folders.**

| folder path | Silver | Training-ready | Stub | Needs implementation | Open findings |
|---|---|---|---|---|---|
| [searching/SPARK4/Ada-SPARK-Binary-Search](searching/SPARK4/Ada-SPARK-Binary-Search) | proven |  |  |  |  |
| [searching/SPARK4/Ada-SPARK-Fibonacci-Search](searching/SPARK4/Ada-SPARK-Fibonacci-Search) | proven |  |  |  |  |
| [searching/SPARK4/Ada-SPARK-Interpolation-Search](searching/SPARK4/Ada-SPARK-Interpolation-Search) | proven |  |  |  |  |
| [searching/SPARK4/Ada-SPARK-Introselect](searching/SPARK4/Ada-SPARK-Introselect) | proven |  |  |  |  |
| [searching/SPARK4/Ada-SPARK-Jump-Search](searching/SPARK4/Ada-SPARK-Jump-Search) | proven |  |  |  |  |
| [searching/SPARK4/Ada-SPARK-Linear-Search](searching/SPARK4/Ada-SPARK-Linear-Search) | proven |  |  |  |  |
| [searching/SPARK4/Ada-SPARK-Quickselect](searching/SPARK4/Ada-SPARK-Quickselect) | proven |  |  |  |  |
| [searching/SPARK4/Ada-SPARK-Ternary-Search](searching/SPARK4/Ada-SPARK-Ternary-Search) | proven |  |  |  |  |
| [searching/SPARK4/Ada-SPARK-Uniform-Cost-Search](searching/SPARK4/Ada-SPARK-Uniform-Cost-Search) | proven |  |  |  |  |
| [searching/SPARK4/Best-First-Search](searching/SPARK4/Best-First-Search) | proven |  |  |  |  |

## sorting

**129 folders.**

### sorting/Ada

**39 folders.**

| folder path | Silver | Training-ready | Stub | Needs implementation | Open findings |
|---|---|---|---|---|---|
| [sorting/Ada/Bead-Sort](sorting/Ada/Bead-Sort) | no SPARK |  |  |  |  |
| [sorting/Ada/Bitonic-Sorter](sorting/Ada/Bitonic-Sorter) | no SPARK |  |  |  |  |
| [sorting/Ada/Bogosort](sorting/Ada/Bogosort) | no SPARK |  |  |  |  |
| [sorting/Ada/Bubble-Sort](sorting/Ada/Bubble-Sort) | no SPARK |  |  |  |  |
| [sorting/Ada/Bucket-Sort](sorting/Ada/Bucket-Sort) | no SPARK |  |  |  |  |
| [sorting/Ada/Burstsort](sorting/Ada/Burstsort) | no SPARK |  |  |  |  |
| [sorting/Ada/Cocktail-Shaker-Sort](sorting/Ada/Cocktail-Shaker-Sort) | no SPARK |  |  |  |  |
| [sorting/Ada/Comb-Sort](sorting/Ada/Comb-Sort) | no SPARK |  |  |  |  |
| [sorting/Ada/Counting-Sort](sorting/Ada/Counting-Sort) | no SPARK |  |  |  |  |
| [sorting/Ada/Cycle-Sort](sorting/Ada/Cycle-Sort) | no SPARK |  |  |  |  |
| [sorting/Ada/Flashsort](sorting/Ada/Flashsort) | no SPARK |  |  |  |  |
| [sorting/Ada/Gnome-Sort](sorting/Ada/Gnome-Sort) | no SPARK |  |  |  |  |
| [sorting/Ada/Heapsort](sorting/Ada/Heapsort) | no SPARK |  |  |  |  |
| [sorting/Ada/Insertion-Sort](sorting/Ada/Insertion-Sort) | no SPARK |  |  |  |  |
| [sorting/Ada/Introsort](sorting/Ada/Introsort) | no SPARK |  |  |  |  |
| [sorting/Ada/Library-Sort](sorting/Ada/Library-Sort) | no SPARK |  |  |  |  |
| [sorting/Ada/Merge-Sort](sorting/Ada/Merge-Sort) | no SPARK |  |  |  |  |
| [sorting/Ada/Odd-Even-Sort](sorting/Ada/Odd-Even-Sort) | no SPARK |  |  |  |  |
| [sorting/Ada/Pancake-Sorting](sorting/Ada/Pancake-Sorting) | no SPARK |  |  |  |  |
| [sorting/Ada/Patience-Sorting](sorting/Ada/Patience-Sorting) | no SPARK |  |  |  |  |
| [sorting/Ada/Pigeonhole-Sort](sorting/Ada/Pigeonhole-Sort) | no SPARK |  |  |  |  |
| [sorting/Ada/Postman-Sort](sorting/Ada/Postman-Sort) | no SPARK |  |  |  |  |
| [sorting/Ada/Quantum-Sort](sorting/Ada/Quantum-Sort) | no SPARK |  |  |  |  |
| [sorting/Ada/Quicksort](sorting/Ada/Quicksort) | no SPARK |  |  |  |  |
| [sorting/Ada/Radix-Sort](sorting/Ada/Radix-Sort) | no SPARK |  |  |  |  |
| [sorting/Ada/Samplesort](sorting/Ada/Samplesort) | no SPARK |  |  |  |  |
| [sorting/Ada/Selection-Sort](sorting/Ada/Selection-Sort) | no SPARK |  |  |  |  |
| [sorting/Ada/Shell-Sort](sorting/Ada/Shell-Sort) | no SPARK |  |  |  |  |
| [sorting/Ada/Slowsort](sorting/Ada/Slowsort) | no SPARK |  |  |  |  |
| [sorting/Ada/Smoothsort](sorting/Ada/Smoothsort) | no SPARK |  |  |  |  |
| [sorting/Ada/Sort-Merge-Join](sorting/Ada/Sort-Merge-Join) | no SPARK |  |  |  |  |
| [sorting/Ada/Sorted-List](sorting/Ada/Sorted-List) | no SPARK |  |  |  |  |
| [sorting/Ada/Spaghetti-Sort](sorting/Ada/Spaghetti-Sort) | no SPARK |  |  |  |  |
| [sorting/Ada/Stooge-Sort](sorting/Ada/Stooge-Sort) | no SPARK |  |  |  |  |
| [sorting/Ada/Strand-Sort](sorting/Ada/Strand-Sort) | no SPARK |  |  |  |  |
| [sorting/Ada/Timsort](sorting/Ada/Timsort) | no SPARK |  |  |  |  |
| [sorting/Ada/Topological-Sort](sorting/Ada/Topological-Sort) | no SPARK |  |  |  |  |
| [sorting/Ada/Tournament-Selection](sorting/Ada/Tournament-Selection) | no SPARK |  |  |  |  |
| [sorting/Ada/Tree-Sort](sorting/Ada/Tree-Sort) | no SPARK |  |  |  |  |

### sorting/SPARK2

**52 folders.**

| folder path | Silver | Training-ready | Stub | Needs implementation | Open findings |
|---|---|---|---|---|---|
| [sorting/SPARK2/Ada-SPARK-Bitonic-Sort](sorting/SPARK2/Ada-SPARK-Bitonic-Sort) | proven |  |  |  |  |
| [sorting/SPARK2/Ada-SPARK-Block-Sort](sorting/SPARK2/Ada-SPARK-Block-Sort) | proven |  | yes | yes |  |
| [sorting/SPARK2/Ada-SPARK-Circle-Sort](sorting/SPARK2/Ada-SPARK-Circle-Sort) | proven |  |  |  |  |
| [sorting/SPARK2/Ada-SPARK-Cocktail-Sort](sorting/SPARK2/Ada-SPARK-Cocktail-Sort) | proven | yes |  |  |  |
| [sorting/SPARK2/Ada-SPARK-Convert-Sorted-Array-To-BST](sorting/SPARK2/Ada-SPARK-Convert-Sorted-Array-To-BST) | proven |  | yes | yes |  |
| [sorting/SPARK2/Ada-SPARK-Count-Negative-Numbers-In-A-Sorted-Matrix](sorting/SPARK2/Ada-SPARK-Count-Negative-Numbers-In-A-Sorted-Matrix) | proven |  |  |  |  |
| [sorting/SPARK2/Ada-SPARK-Count-Sorted-Vowel-Strings](sorting/SPARK2/Ada-SPARK-Count-Sorted-Vowel-Strings) | proven |  |  |  |  |
| [sorting/SPARK2/Ada-SPARK-Exchange-Sort](sorting/SPARK2/Ada-SPARK-Exchange-Sort) | proven |  | yes | yes |  |
| [sorting/SPARK2/Ada-SPARK-Find-Median-Sorted-Arrays-Lite](sorting/SPARK2/Ada-SPARK-Find-Median-Sorted-Arrays-Lite) | proven |  |  |  |  |
| [sorting/SPARK2/Ada-SPARK-Find-Minimum-In-Rotated-Sorted-Array](sorting/SPARK2/Ada-SPARK-Find-Minimum-In-Rotated-Sorted-Array) | proven |  |  |  |  |
| [sorting/SPARK2/Ada-SPARK-Find-Minimum-In-Rotated-Sorted-Array-II](sorting/SPARK2/Ada-SPARK-Find-Minimum-In-Rotated-Sorted-Array-II) | proven |  |  |  |  |
| [sorting/SPARK2/Ada-SPARK-Flash-Sort](sorting/SPARK2/Ada-SPARK-Flash-Sort) | proven |  |  |  |  |
| [sorting/SPARK2/Ada-SPARK-Heap-Sort](sorting/SPARK2/Ada-SPARK-Heap-Sort) | proven |  | yes | yes |  |
| [sorting/SPARK2/Ada-SPARK-Intro-Sort](sorting/SPARK2/Ada-SPARK-Intro-Sort) | proven |  | yes | yes |  |
| [sorting/SPARK2/Ada-SPARK-Kth-Smallest-Element-In-A-Sorted-Matrix](sorting/SPARK2/Ada-SPARK-Kth-Smallest-Element-In-A-Sorted-Matrix) | proven |  |  |  |  |
| [sorting/SPARK2/Ada-SPARK-Median-Of-Two-Sorted-Arrays-Lite](sorting/SPARK2/Ada-SPARK-Median-Of-Two-Sorted-Arrays-Lite) | proven |  |  |  |  |
| [sorting/SPARK2/Ada-SPARK-Merge-K-Sorted-Lists-Stub](sorting/SPARK2/Ada-SPARK-Merge-K-Sorted-Lists-Stub) | proven |  | yes | yes |  |
| [sorting/SPARK2/Ada-SPARK-Merge-Sorted-Array](sorting/SPARK2/Ada-SPARK-Merge-Sorted-Array) | proven |  |  |  |  |
| [sorting/SPARK2/Ada-SPARK-Merge-Sorted-Arrays](sorting/SPARK2/Ada-SPARK-Merge-Sorted-Arrays) | proven | yes |  |  |  |
| [sorting/SPARK2/Ada-SPARK-Merge-Two-Sorted-Lists](sorting/SPARK2/Ada-SPARK-Merge-Two-Sorted-Lists) | proven |  |  |  |  |
| [sorting/SPARK2/Ada-SPARK-Odd-Even-Linked-List](sorting/SPARK2/Ada-SPARK-Odd-Even-Linked-List) | proven |  |  |  |  |
| [sorting/SPARK2/Ada-SPARK-Odd-Even-Merge-Sort](sorting/SPARK2/Ada-SPARK-Odd-Even-Merge-Sort) | proven |  |  |  |  |
| [sorting/SPARK2/Ada-SPARK-Pancake-Sort](sorting/SPARK2/Ada-SPARK-Pancake-Sort) | proven |  | yes | yes |  |
| [sorting/SPARK2/Ada-SPARK-Patience-Sort](sorting/SPARK2/Ada-SPARK-Patience-Sort) | proven |  |  |  |  |
| [sorting/SPARK2/Ada-SPARK-Quick-Sort](sorting/SPARK2/Ada-SPARK-Quick-Sort) | proven |  |  |  |  |
| [sorting/SPARK2/Ada-SPARK-Relative-Sort-Array](sorting/SPARK2/Ada-SPARK-Relative-Sort-Array) | proven |  |  |  |  |
| [sorting/SPARK2/Ada-SPARK-Remove-Duplicates-From-Sorted-Array](sorting/SPARK2/Ada-SPARK-Remove-Duplicates-From-Sorted-Array) | proven |  |  |  |  |
| [sorting/SPARK2/Ada-SPARK-Remove-Duplicates-From-Sorted-Array-II](sorting/SPARK2/Ada-SPARK-Remove-Duplicates-From-Sorted-Array-II) | proven |  |  |  |  |
| [sorting/SPARK2/Ada-SPARK-Remove-Duplicates-From-Sorted-List](sorting/SPARK2/Ada-SPARK-Remove-Duplicates-From-Sorted-List) | proven |  |  |  |  |
| [sorting/SPARK2/Ada-SPARK-Remove-Duplicates-From-Sorted-List-II](sorting/SPARK2/Ada-SPARK-Remove-Duplicates-From-Sorted-List-II) | proven |  |  |  |  |
| [sorting/SPARK2/Ada-SPARK-Remove-Duplicates-Sorted](sorting/SPARK2/Ada-SPARK-Remove-Duplicates-Sorted) | proven |  |  |  |  |
| [sorting/SPARK2/Ada-SPARK-Search-In-Rotated-Sorted-Array](sorting/SPARK2/Ada-SPARK-Search-In-Rotated-Sorted-Array) | proven |  |  |  |  |
| [sorting/SPARK2/Ada-SPARK-Search-In-Rotated-Sorted-Array-II](sorting/SPARK2/Ada-SPARK-Search-In-Rotated-Sorted-Array-II) | proven |  |  |  |  |
| [sorting/SPARK2/Ada-SPARK-Shaker-Sort](sorting/SPARK2/Ada-SPARK-Shaker-Sort) | proven |  | yes | yes |  |
| [sorting/SPARK2/Ada-SPARK-Shortest-Unsorted-Continuous-Subarray](sorting/SPARK2/Ada-SPARK-Shortest-Unsorted-Continuous-Subarray) | proven |  |  |  |  |
| [sorting/SPARK2/Ada-SPARK-Smooth-Sort](sorting/SPARK2/Ada-SPARK-Smooth-Sort) | proven |  | yes | yes |  |
| [sorting/SPARK2/Ada-SPARK-Sort-An-Array](sorting/SPARK2/Ada-SPARK-Sort-An-Array) | proven |  |  |  |  |
| [sorting/SPARK2/Ada-SPARK-Sort-Array-By-Parity](sorting/SPARK2/Ada-SPARK-Sort-Array-By-Parity) | proven |  |  |  |  |
| [sorting/SPARK2/Ada-SPARK-Sort-Array-By-Parity-II](sorting/SPARK2/Ada-SPARK-Sort-Array-By-Parity-II) | proven |  |  |  |  |
| [sorting/SPARK2/Ada-SPARK-Sort-Characters-By-Frequency](sorting/SPARK2/Ada-SPARK-Sort-Characters-By-Frequency) | proven |  |  |  |  |
| [sorting/SPARK2/Ada-SPARK-Sort-Colors](sorting/SPARK2/Ada-SPARK-Sort-Colors) | proven |  |  |  |  |
| [sorting/SPARK2/Ada-SPARK-Sort-Integers-By-The-Number-Of-1-Bits](sorting/SPARK2/Ada-SPARK-Sort-Integers-By-The-Number-Of-1-Bits) | proven |  |  |  |  |
| [sorting/SPARK2/Ada-SPARK-Sort-List-Lite](sorting/SPARK2/Ada-SPARK-Sort-List-Lite) | proven |  |  |  |  |
| [sorting/SPARK2/Ada-SPARK-Sorted-Array-To-BST](sorting/SPARK2/Ada-SPARK-Sorted-Array-To-BST) | proven |  |  |  |  |
| [sorting/SPARK2/Ada-SPARK-Squares-Of-A-Sorted-Array](sorting/SPARK2/Ada-SPARK-Squares-Of-A-Sorted-Array) | proven |  |  |  |  |
| [sorting/SPARK2/Ada-SPARK-Tim-Sort](sorting/SPARK2/Ada-SPARK-Tim-Sort) | proven |  |  |  |  |
| [sorting/SPARK2/Ada-SPARK-Tim-Sort-Stub](sorting/SPARK2/Ada-SPARK-Tim-Sort-Stub) | proven |  |  |  |  |
| [sorting/SPARK2/Ada-SPARK-Topological-Sort-Lite](sorting/SPARK2/Ada-SPARK-Topological-Sort-Lite) | proven |  | yes | yes |  |
| [sorting/SPARK2/Ada-SPARK-Tournament-Sort](sorting/SPARK2/Ada-SPARK-Tournament-Sort) | proven |  | yes | yes |  |
| [sorting/SPARK2/Ada-SPARK-Two-Sum-II-Input-Array-Is-Sorted](sorting/SPARK2/Ada-SPARK-Two-Sum-II-Input-Array-Is-Sorted) | proven |  |  |  |  |
| [sorting/SPARK2/Ada-SPARK-Wiggle-Sort](sorting/SPARK2/Ada-SPARK-Wiggle-Sort) | proven | yes |  |  |  |
| [sorting/SPARK2/Binary-Insertion-Sort](sorting/SPARK2/Binary-Insertion-Sort) | proven |  | yes | yes |  |

### sorting/SPARK4

**38 folders.**

| folder path | Silver | Training-ready | Stub | Needs implementation | Open findings |
|---|---|---|---|---|---|
| [sorting/SPARK4/Ada-SPARK-Bitonic-Sorter](sorting/SPARK4/Ada-SPARK-Bitonic-Sorter) | proven |  |  |  |  |
| [sorting/SPARK4/Ada-SPARK-Bogosort](sorting/SPARK4/Ada-SPARK-Bogosort) | proven |  |  |  |  |
| [sorting/SPARK4/Ada-SPARK-Bubble-Sort](sorting/SPARK4/Ada-SPARK-Bubble-Sort) | proven |  |  |  |  |
| [sorting/SPARK4/Ada-SPARK-Bucket-Sort](sorting/SPARK4/Ada-SPARK-Bucket-Sort) | proven |  |  |  |  |
| [sorting/SPARK4/Ada-SPARK-Burstsort](sorting/SPARK4/Ada-SPARK-Burstsort) | proven |  |  |  |  |
| [sorting/SPARK4/Ada-SPARK-Cocktail-Shaker-Sort](sorting/SPARK4/Ada-SPARK-Cocktail-Shaker-Sort) | proven |  |  |  |  |
| [sorting/SPARK4/Ada-SPARK-Comb-Sort](sorting/SPARK4/Ada-SPARK-Comb-Sort) | proven |  |  |  |  |
| [sorting/SPARK4/Ada-SPARK-Counting-Sort](sorting/SPARK4/Ada-SPARK-Counting-Sort) | proven |  |  |  |  |
| [sorting/SPARK4/Ada-SPARK-Cycle-Sort](sorting/SPARK4/Ada-SPARK-Cycle-Sort) | proven |  |  |  |  |
| [sorting/SPARK4/Ada-SPARK-Flashsort](sorting/SPARK4/Ada-SPARK-Flashsort) | proven |  |  |  |  |
| [sorting/SPARK4/Ada-SPARK-Gnome-Sort](sorting/SPARK4/Ada-SPARK-Gnome-Sort) | proven |  |  |  |  |
| [sorting/SPARK4/Ada-SPARK-Heapsort](sorting/SPARK4/Ada-SPARK-Heapsort) | proven |  |  |  |  |
| [sorting/SPARK4/Ada-SPARK-Insertion-Sort](sorting/SPARK4/Ada-SPARK-Insertion-Sort) | proven |  |  |  |  |
| [sorting/SPARK4/Ada-SPARK-Introsort](sorting/SPARK4/Ada-SPARK-Introsort) | proven |  |  |  |  |
| [sorting/SPARK4/Ada-SPARK-Library-Sort](sorting/SPARK4/Ada-SPARK-Library-Sort) | proven |  |  |  |  |
| [sorting/SPARK4/Ada-SPARK-Merge-Sort](sorting/SPARK4/Ada-SPARK-Merge-Sort) | proven |  |  |  |  |
| [sorting/SPARK4/Ada-SPARK-Odd-Even-Sort](sorting/SPARK4/Ada-SPARK-Odd-Even-Sort) | proven |  |  |  |  |
| [sorting/SPARK4/Ada-SPARK-Pancake-Sorting](sorting/SPARK4/Ada-SPARK-Pancake-Sorting) | proven |  |  |  |  |
| [sorting/SPARK4/Ada-SPARK-Patience-Sorting](sorting/SPARK4/Ada-SPARK-Patience-Sorting) | proven |  |  |  |  |
| [sorting/SPARK4/Ada-SPARK-Pigeonhole-Sort](sorting/SPARK4/Ada-SPARK-Pigeonhole-Sort) | proven |  |  |  |  |
| [sorting/SPARK4/Ada-SPARK-Postman-Sort](sorting/SPARK4/Ada-SPARK-Postman-Sort) | proven |  |  |  |  |
| [sorting/SPARK4/Ada-SPARK-Quantum-Sort](sorting/SPARK4/Ada-SPARK-Quantum-Sort) | proven |  |  |  |  |
| [sorting/SPARK4/Ada-SPARK-Quicksort](sorting/SPARK4/Ada-SPARK-Quicksort) | proven |  |  |  |  |
| [sorting/SPARK4/Ada-SPARK-Radix-Sort](sorting/SPARK4/Ada-SPARK-Radix-Sort) | proven |  |  |  |  |
| [sorting/SPARK4/Ada-SPARK-Samplesort](sorting/SPARK4/Ada-SPARK-Samplesort) | proven |  |  |  |  |
| [sorting/SPARK4/Ada-SPARK-Selection-Sort](sorting/SPARK4/Ada-SPARK-Selection-Sort) | proven |  |  |  |  |
| [sorting/SPARK4/Ada-SPARK-Shell-Sort](sorting/SPARK4/Ada-SPARK-Shell-Sort) | proven |  |  |  |  |
| [sorting/SPARK4/Ada-SPARK-Slowsort](sorting/SPARK4/Ada-SPARK-Slowsort) | proven |  |  |  |  |
| [sorting/SPARK4/Ada-SPARK-Smoothsort](sorting/SPARK4/Ada-SPARK-Smoothsort) | proven |  |  |  |  |
| [sorting/SPARK4/Ada-SPARK-Sort-Merge-Join](sorting/SPARK4/Ada-SPARK-Sort-Merge-Join) | proven |  |  |  |  |
| [sorting/SPARK4/Ada-SPARK-Sorted-List](sorting/SPARK4/Ada-SPARK-Sorted-List) | proven |  |  |  |  |
| [sorting/SPARK4/Ada-SPARK-Spaghetti-Sort](sorting/SPARK4/Ada-SPARK-Spaghetti-Sort) | proven |  |  |  |  |
| [sorting/SPARK4/Ada-SPARK-Stooge-Sort](sorting/SPARK4/Ada-SPARK-Stooge-Sort) | proven |  |  |  |  |
| [sorting/SPARK4/Ada-SPARK-Strand-Sort](sorting/SPARK4/Ada-SPARK-Strand-Sort) | proven |  |  |  |  |
| [sorting/SPARK4/Ada-SPARK-Timsort](sorting/SPARK4/Ada-SPARK-Timsort) | proven |  |  |  |  |
| [sorting/SPARK4/Ada-SPARK-Topological-Sort](sorting/SPARK4/Ada-SPARK-Topological-Sort) | proven |  |  |  |  |
| [sorting/SPARK4/Ada-SPARK-Tree-Sort](sorting/SPARK4/Ada-SPARK-Tree-Sort) | proven |  |  |  |  |
| [sorting/SPARK4/Bead-Sort](sorting/SPARK4/Bead-Sort) | proven |  |  |  |  |

## strings

**61 folders.**

### strings/Ada

**21 folders.**

| folder path | Silver | Training-ready | Stub | Needs implementation | Open findings |
|---|---|---|---|---|---|
| [strings/Ada/Aho-Corasick](strings/Ada/Aho-Corasick) | no SPARK |  |  |  |  |
| [strings/Ada/Boyer-Moore](strings/Ada/Boyer-Moore) | no SPARK |  |  |  |  |
| [strings/Ada/Boyer-Moore-Horspool](strings/Ada/Boyer-Moore-Horspool) | no SPARK |  |  |  |  |
| [strings/Ada/Daitch-Mokotoff-Soundex](strings/Ada/Daitch-Mokotoff-Soundex) | no SPARK |  |  |  |  |
| [strings/Ada/Damerau-Levenshtein-Distance](strings/Ada/Damerau-Levenshtein-Distance) | no SPARK |  |  |  |  |
| [strings/Ada/Double-Metaphone](strings/Ada/Double-Metaphone) | no SPARK |  |  |  |  |
| [strings/Ada/Hamming-Distance](strings/Ada/Hamming-Distance) | no SPARK |  |  |  |  |
| [strings/Ada/Jaro-Winkler-Distance](strings/Ada/Jaro-Winkler-Distance) | no SPARK |  |  |  |  |
| [strings/Ada/Karplus-Strong-String-Synthesis](strings/Ada/Karplus-Strong-String-Synthesis) | no SPARK |  |  |  |  |
| [strings/Ada/Knuth-Morris-Pratt](strings/Ada/Knuth-Morris-Pratt) | no SPARK |  |  |  |  |
| [strings/Ada/Levenshtein-Coding](strings/Ada/Levenshtein-Coding) | no SPARK |  |  |  |  |
| [strings/Ada/Levenshtein-Distance](strings/Ada/Levenshtein-Distance) | no SPARK |  |  |  |  |
| [strings/Ada/Longest-Common-Subsequence](strings/Ada/Longest-Common-Subsequence) | no SPARK |  |  |  |  |
| [strings/Ada/Metaphone](strings/Ada/Metaphone) | no SPARK |  |  |  |  |
| [strings/Ada/NYSIIS](strings/Ada/NYSIIS) | no SPARK |  |  |  |  |
| [strings/Ada/Needleman-Wunsch](strings/Ada/Needleman-Wunsch) | no SPARK |  |  |  |  |
| [strings/Ada/Rabin-Karp](strings/Ada/Rabin-Karp) | no SPARK |  |  |  |  |
| [strings/Ada/Smith-Waterman](strings/Ada/Smith-Waterman) | no SPARK |  |  |  |  |
| [strings/Ada/Soundex](strings/Ada/Soundex) | no SPARK |  |  |  |  |
| [strings/Ada/Stemming](strings/Ada/Stemming) | no SPARK |  |  |  |  |
| [strings/Ada/String-Metrics](strings/Ada/String-Metrics) | no SPARK |  |  |  |  |

### strings/SPARK2

**39 folders.**

| folder path | Silver | Training-ready | Stub | Needs implementation | Open findings |
|---|---|---|---|---|---|
| [strings/SPARK2/Ada-SPARK-Bounded-String-Builder](strings/SPARK2/Ada-SPARK-Bounded-String-Builder) | proven | yes |  |  |  |
| [strings/SPARK2/Ada-SPARK-Boyer-Moore](strings/SPARK2/Ada-SPARK-Boyer-Moore) | proven |  |  |  |  |
| [strings/SPARK2/Ada-SPARK-Check-If-Two-String-Arrays-Are-Equivalent](strings/SPARK2/Ada-SPARK-Check-If-Two-String-Arrays-Are-Equivalent) | proven |  |  |  |  |
| [strings/SPARK2/Ada-SPARK-Count-The-Number-Of-Consistent-Strings](strings/SPARK2/Ada-SPARK-Count-The-Number-Of-Consistent-Strings) | proven |  | yes | yes |  |
| [strings/SPARK2/Ada-SPARK-Damerau-Levenshtein-Distance](strings/SPARK2/Ada-SPARK-Damerau-Levenshtein-Distance) | proven |  |  |  |  |
| [strings/SPARK2/Ada-SPARK-Decode-String](strings/SPARK2/Ada-SPARK-Decode-String) | proven |  |  |  |  |
| [strings/SPARK2/Ada-SPARK-Decode-String-Stub](strings/SPARK2/Ada-SPARK-Decode-String-Stub) | proven |  | yes | yes |  |
| [strings/SPARK2/Ada-SPARK-Delete-Operation-For-Two-Strings](strings/SPARK2/Ada-SPARK-Delete-Operation-For-Two-Strings) | tool crash |  |  |  |  |
| [strings/SPARK2/Ada-SPARK-Edit-Distance](strings/SPARK2/Ada-SPARK-Edit-Distance) | proven |  |  |  |  |
| [strings/SPARK2/Ada-SPARK-Encode-And-Decode-Strings-Lite](strings/SPARK2/Ada-SPARK-Encode-And-Decode-Strings-Lite) | proven |  |  |  |  |
| [strings/SPARK2/Ada-SPARK-Find-All-Anagrams-In-A-String](strings/SPARK2/Ada-SPARK-Find-All-Anagrams-In-A-String) | proven |  |  |  |  |
| [strings/SPARK2/Ada-SPARK-First-Unique-Character-In-A-String](strings/SPARK2/Ada-SPARK-First-Unique-Character-In-A-String) | proven |  |  |  |  |
| [strings/SPARK2/Ada-SPARK-Hamming-Distance](strings/SPARK2/Ada-SPARK-Hamming-Distance) | proven | yes |  |  |  |
| [strings/SPARK2/Ada-SPARK-Isomorphic-Strings](strings/SPARK2/Ada-SPARK-Isomorphic-Strings) | proven |  |  |  |  |
| [strings/SPARK2/Ada-SPARK-Knuth-Morris-Pratt](strings/SPARK2/Ada-SPARK-Knuth-Morris-Pratt) | proven |  |  |  |  |
| [strings/SPARK2/Ada-SPARK-Longest-Common-Prefix](strings/SPARK2/Ada-SPARK-Longest-Common-Prefix) | proven |  |  |  |  |
| [strings/SPARK2/Ada-SPARK-Longest-Common-Subsequence](strings/SPARK2/Ada-SPARK-Longest-Common-Subsequence) | proven |  |  |  |  |
| [strings/SPARK2/Ada-SPARK-Make-The-String-Great](strings/SPARK2/Ada-SPARK-Make-The-String-Great) | proven |  |  |  |  |
| [strings/SPARK2/Ada-SPARK-Multiply-Strings-Lite](strings/SPARK2/Ada-SPARK-Multiply-Strings-Lite) | proven |  |  |  |  |
| [strings/SPARK2/Ada-SPARK-Multiply-Strings-Stub](strings/SPARK2/Ada-SPARK-Multiply-Strings-Stub) | proven |  |  |  |  |
| [strings/SPARK2/Ada-SPARK-Number-Of-Lines-To-Write-String](strings/SPARK2/Ada-SPARK-Number-Of-Lines-To-Write-String) | proven |  |  |  |  |
| [strings/SPARK2/Ada-SPARK-One-Edit-Distance](strings/SPARK2/Ada-SPARK-One-Edit-Distance) | proven |  |  |  |  |
| [strings/SPARK2/Ada-SPARK-Permutation-In-String](strings/SPARK2/Ada-SPARK-Permutation-In-String) | proven |  |  |  |  |
| [strings/SPARK2/Ada-SPARK-Rabin-Karp](strings/SPARK2/Ada-SPARK-Rabin-Karp) | proven |  |  |  |  |
| [strings/SPARK2/Ada-SPARK-Remove-All-Adjacent-Duplicates-In-String](strings/SPARK2/Ada-SPARK-Remove-All-Adjacent-Duplicates-In-String) | proven |  |  |  |  |
| [strings/SPARK2/Ada-SPARK-Reorganize-String](strings/SPARK2/Ada-SPARK-Reorganize-String) | proven |  |  |  |  |
| [strings/SPARK2/Ada-SPARK-Reorganize-String-Stub](strings/SPARK2/Ada-SPARK-Reorganize-String-Stub) | proven |  | yes | yes |  |
| [strings/SPARK2/Ada-SPARK-Repeated-String-Match](strings/SPARK2/Ada-SPARK-Repeated-String-Match) | proven |  |  |  |  |
| [strings/SPARK2/Ada-SPARK-Reverse-String](strings/SPARK2/Ada-SPARK-Reverse-String) | proven |  |  |  |  |
| [strings/SPARK2/Ada-SPARK-Reverse-String-II](strings/SPARK2/Ada-SPARK-Reverse-String-II) | proven |  |  |  |  |
| [strings/SPARK2/Ada-SPARK-Reverse-Vowels-Of-A-String](strings/SPARK2/Ada-SPARK-Reverse-Vowels-Of-A-String) | proven |  |  |  |  |
| [strings/SPARK2/Ada-SPARK-Reverse-Words-In-A-String](strings/SPARK2/Ada-SPARK-Reverse-Words-In-A-String) | proven |  |  |  |  |
| [strings/SPARK2/Ada-SPARK-Reverse-Words-In-A-String-III](strings/SPARK2/Ada-SPARK-Reverse-Words-In-A-String-III) | proven |  |  |  |  |
| [strings/SPARK2/Ada-SPARK-Rotate-String](strings/SPARK2/Ada-SPARK-Rotate-String) | proven |  |  |  |  |
| [strings/SPARK2/Ada-SPARK-String-To-Integer-Atoi](strings/SPARK2/Ada-SPARK-String-To-Integer-Atoi) | proven |  |  |  |  |
| [strings/SPARK2/Ada-SPARK-Sum-Of-Digits-Of-String-After-Convert](strings/SPARK2/Ada-SPARK-Sum-Of-Digits-Of-String-After-Convert) | proven |  |  |  |  |
| [strings/SPARK2/Ada-SPARK-Total-Hamming-Distance](strings/SPARK2/Ada-SPARK-Total-Hamming-Distance) | proven |  |  |  |  |
| [strings/SPARK2/Ada-SPARK-Z-Algorithm](strings/SPARK2/Ada-SPARK-Z-Algorithm) | proven |  |  |  |  |
| [strings/SPARK2/Add-Strings](strings/SPARK2/Add-Strings) | proven |  |  |  |  |

### strings/SPARK3

**1 folder.**

| folder path | Silver | Training-ready | Stub | Needs implementation | Open findings |
|---|---|---|---|---|---|
| [strings/SPARK3/Levenshtein-Distance](strings/SPARK3/Levenshtein-Distance) | proven |  |  |  |  |

## trees

**65 folders.**

### trees/Ada

**8 folders.**

| folder path | Silver | Training-ready | Stub | Needs implementation | Open findings |
|---|---|---|---|---|---|
| [trees/Ada/Abstract-Interpretation](trees/Ada/Abstract-Interpretation) | no SPARK |  |  |  |  |
| [trees/Ada/Abstract-Syntax-Tree](trees/Ada/Abstract-Syntax-Tree) | no SPARK |  |  |  |  |
| [trees/Ada/Context-Tree-Weighting](trees/Ada/Context-Tree-Weighting) | no SPARK |  |  |  |  |
| [trees/Ada/Decision-Trees](trees/Ada/Decision-Trees) | no SPARK |  |  |  |  |
| [trees/Ada/Embedded-Zerotree-Wavelet](trees/Ada/Embedded-Zerotree-Wavelet) | no SPARK |  |  |  |  |
| [trees/Ada/Longest-Common-Substring](trees/Ada/Longest-Common-Substring) | no SPARK |  |  |  |  |
| [trees/Ada/Red-Black-Tree](trees/Ada/Red-Black-Tree) | no SPARK |  |  |  |  |
| [trees/Ada/Set-Partitioning-In-Hierarchical-Trees](trees/Ada/Set-Partitioning-In-Hierarchical-Trees) | no SPARK |  |  |  |  |

### trees/SPARK2

**57 folders.**

| folder path | Silver | Training-ready | Stub | Needs implementation | Open findings |
|---|---|---|---|---|---|
| [trees/SPARK2/Ada-SPARK-BST-Iterator-Stub](trees/SPARK2/Ada-SPARK-BST-Iterator-Stub) | proven |  |  |  |  |
| [trees/SPARK2/Ada-SPARK-Balanced-Binary-Tree](trees/SPARK2/Ada-SPARK-Balanced-Binary-Tree) | proven |  |  |  |  |
| [trees/SPARK2/Ada-SPARK-Binary-Tree-Inorder](trees/SPARK2/Ada-SPARK-Binary-Tree-Inorder) | proven |  |  |  |  |
| [trees/SPARK2/Ada-SPARK-Binary-Tree-Level-Order](trees/SPARK2/Ada-SPARK-Binary-Tree-Level-Order) | proven |  |  |  |  |
| [trees/SPARK2/Ada-SPARK-Binary-Tree-Max-Depth](trees/SPARK2/Ada-SPARK-Binary-Tree-Max-Depth) | proven |  |  |  |  |
| [trees/SPARK2/Ada-SPARK-Binary-Tree-Min-Depth](trees/SPARK2/Ada-SPARK-Binary-Tree-Min-Depth) | proven |  |  |  |  |
| [trees/SPARK2/Ada-SPARK-Binary-Tree-Paths](trees/SPARK2/Ada-SPARK-Binary-Tree-Paths) | proven |  |  |  |  |
| [trees/SPARK2/Ada-SPARK-Binary-Tree-Postorder](trees/SPARK2/Ada-SPARK-Binary-Tree-Postorder) | proven |  |  |  |  |
| [trees/SPARK2/Ada-SPARK-Binary-Tree-Preorder](trees/SPARK2/Ada-SPARK-Binary-Tree-Preorder) | proven |  |  |  |  |
| [trees/SPARK2/Ada-SPARK-Binary-Tree-Right-Side-View](trees/SPARK2/Ada-SPARK-Binary-Tree-Right-Side-View) | proven |  | yes | yes |  |
| [trees/SPARK2/Ada-SPARK-Construct-Binary-Tree-From-Inorder-And-Postorder-Lite](trees/SPARK2/Ada-SPARK-Construct-Binary-Tree-From-Inorder-And-Postorder-Lite) | proven |  |  |  |  |
| [trees/SPARK2/Ada-SPARK-Construct-Binary-Tree-From-Preorder-And-Inorder-Lite](trees/SPARK2/Ada-SPARK-Construct-Binary-Tree-From-Preorder-And-Inorder-Lite) | proven |  |  |  |  |
| [trees/SPARK2/Ada-SPARK-Convert-BST-To-Greater-Tree](trees/SPARK2/Ada-SPARK-Convert-BST-To-Greater-Tree) | proven |  |  |  |  |
| [trees/SPARK2/Ada-SPARK-Count-Binary-Substrings](trees/SPARK2/Ada-SPARK-Count-Binary-Substrings) | proven |  |  |  |  |
| [trees/SPARK2/Ada-SPARK-Count-Complete-Tree-Nodes](trees/SPARK2/Ada-SPARK-Count-Complete-Tree-Nodes) | proven |  |  |  |  |
| [trees/SPARK2/Ada-SPARK-Delete-Node-BST-Stub](trees/SPARK2/Ada-SPARK-Delete-Node-BST-Stub) | proven |  | yes | yes |  |
| [trees/SPARK2/Ada-SPARK-Delete-Node-In-A-BST-Lite](trees/SPARK2/Ada-SPARK-Delete-Node-In-A-BST-Lite) | proven |  |  |  |  |
| [trees/SPARK2/Ada-SPARK-Diameter-Of-Binary-Tree](trees/SPARK2/Ada-SPARK-Diameter-Of-Binary-Tree) | proven |  |  |  |  |
| [trees/SPARK2/Ada-SPARK-Find-Mode-In-BST](trees/SPARK2/Ada-SPARK-Find-Mode-In-BST) | proven |  |  |  |  |
| [trees/SPARK2/Ada-SPARK-Flatten-Binary-Tree-To-Linked-List-Lite](trees/SPARK2/Ada-SPARK-Flatten-Binary-Tree-To-Linked-List-Lite) | proven |  | yes | yes |  |
| [trees/SPARK2/Ada-SPARK-Get-Equal-Substrings-Within-Budget](trees/SPARK2/Ada-SPARK-Get-Equal-Substrings-Within-Budget) | proven |  |  |  |  |
| [trees/SPARK2/Ada-SPARK-Implement-Trie](trees/SPARK2/Ada-SPARK-Implement-Trie) | proven |  | yes | yes |  |
| [trees/SPARK2/Ada-SPARK-Insert-Into-BST](trees/SPARK2/Ada-SPARK-Insert-Into-BST) | proven |  |  |  |  |
| [trees/SPARK2/Ada-SPARK-Invert-Binary-Tree](trees/SPARK2/Ada-SPARK-Invert-Binary-Tree) | proven |  |  |  |  |
| [trees/SPARK2/Ada-SPARK-Kth-Smallest-BST-Stub](trees/SPARK2/Ada-SPARK-Kth-Smallest-BST-Stub) | proven |  | yes | yes |  |
| [trees/SPARK2/Ada-SPARK-Leaf-Similar-Trees](trees/SPARK2/Ada-SPARK-Leaf-Similar-Trees) | proven |  |  |  |  |
| [trees/SPARK2/Ada-SPARK-Longest-Common-Substring](trees/SPARK2/Ada-SPARK-Longest-Common-Substring) | proven |  |  |  |  |
| [trees/SPARK2/Ada-SPARK-Longest-Palindromic-Substring](trees/SPARK2/Ada-SPARK-Longest-Palindromic-Substring) | proven |  |  |  |  |
| [trees/SPARK2/Ada-SPARK-Longest-Substring-Without-Repeat](trees/SPARK2/Ada-SPARK-Longest-Substring-Without-Repeat) | proven |  |  |  |  |
| [trees/SPARK2/Ada-SPARK-Longest-Substring-Without-Repeating](trees/SPARK2/Ada-SPARK-Longest-Substring-Without-Repeating) | proven |  |  |  |  |
| [trees/SPARK2/Ada-SPARK-Lowest-Common-Ancestor-BST](trees/SPARK2/Ada-SPARK-Lowest-Common-Ancestor-BST) | proven |  |  |  |  |
| [trees/SPARK2/Ada-SPARK-Lowest-Common-Ancestor-Of-BST](trees/SPARK2/Ada-SPARK-Lowest-Common-Ancestor-Of-BST) | proven |  |  |  |  |
| [trees/SPARK2/Ada-SPARK-Maximum-Binary-Tree](trees/SPARK2/Ada-SPARK-Maximum-Binary-Tree) | proven |  |  |  |  |
| [trees/SPARK2/Ada-SPARK-Maximum-Depth-Of-Binary-Tree](trees/SPARK2/Ada-SPARK-Maximum-Depth-Of-Binary-Tree) | proven |  |  |  |  |
| [trees/SPARK2/Ada-SPARK-Maximum-Depth-Of-N-Ary-Tree](trees/SPARK2/Ada-SPARK-Maximum-Depth-Of-N-Ary-Tree) | proven |  |  |  |  |
| [trees/SPARK2/Ada-SPARK-Merge-Two-Binary-Trees](trees/SPARK2/Ada-SPARK-Merge-Two-Binary-Trees) | proven |  |  |  |  |
| [trees/SPARK2/Ada-SPARK-Minimum-Depth-Of-Binary-Tree](trees/SPARK2/Ada-SPARK-Minimum-Depth-Of-Binary-Tree) | proven |  |  |  |  |
| [trees/SPARK2/Ada-SPARK-Minimum-Height-Trees](trees/SPARK2/Ada-SPARK-Minimum-Height-Trees) | proven |  |  |  |  |
| [trees/SPARK2/Ada-SPARK-Minimum-Window-Substring](trees/SPARK2/Ada-SPARK-Minimum-Window-Substring) | proven |  |  |  |  |
| [trees/SPARK2/Ada-SPARK-N-Ary-Tree-Level-Order-Traversal](trees/SPARK2/Ada-SPARK-N-Ary-Tree-Level-Order-Traversal) | proven |  |  |  |  |
| [trees/SPARK2/Ada-SPARK-N-Ary-Tree-Postorder-Traversal](trees/SPARK2/Ada-SPARK-N-Ary-Tree-Postorder-Traversal) | proven |  |  |  |  |
| [trees/SPARK2/Ada-SPARK-N-Ary-Tree-Preorder-Traversal](trees/SPARK2/Ada-SPARK-N-Ary-Tree-Preorder-Traversal) | proven |  |  |  |  |
| [trees/SPARK2/Ada-SPARK-Number-Of-Substrings-Containing-All-Three-Characters](trees/SPARK2/Ada-SPARK-Number-Of-Substrings-Containing-All-Three-Characters) | proven |  |  |  |  |
| [trees/SPARK2/Ada-SPARK-Range-Sum-BST](trees/SPARK2/Ada-SPARK-Range-Sum-BST) | proven |  |  |  |  |
| [trees/SPARK2/Ada-SPARK-Range-Sum-Of-BST](trees/SPARK2/Ada-SPARK-Range-Sum-Of-BST) | proven |  |  |  |  |
| [trees/SPARK2/Ada-SPARK-Red-Black-Tree](trees/SPARK2/Ada-SPARK-Red-Black-Tree) | proven |  | yes | yes |  |
| [trees/SPARK2/Ada-SPARK-Repeated-Substring-Pattern](trees/SPARK2/Ada-SPARK-Repeated-Substring-Pattern) | proven |  |  |  |  |
| [trees/SPARK2/Ada-SPARK-Same-Tree](trees/SPARK2/Ada-SPARK-Same-Tree) | proven |  |  |  |  |
| [trees/SPARK2/Ada-SPARK-Subtree-Of-Another-Tree](trees/SPARK2/Ada-SPARK-Subtree-Of-Another-Tree) | proven |  |  |  |  |
| [trees/SPARK2/Ada-SPARK-Symmetric-Tree](trees/SPARK2/Ada-SPARK-Symmetric-Tree) | proven |  |  |  |  |
| [trees/SPARK2/Ada-SPARK-Trim-BST-Stub](trees/SPARK2/Ada-SPARK-Trim-BST-Stub) | proven |  | yes | yes |  |
| [trees/SPARK2/Ada-SPARK-Two-Sum-BST-Stub](trees/SPARK2/Ada-SPARK-Two-Sum-BST-Stub) | proven |  | yes | yes |  |
| [trees/SPARK2/Ada-SPARK-Unique-BSTs-Stub](trees/SPARK2/Ada-SPARK-Unique-BSTs-Stub) | proven |  |  |  |  |
| [trees/SPARK2/Ada-SPARK-Unique-Paths-With-Obstacles](trees/SPARK2/Ada-SPARK-Unique-Paths-With-Obstacles) | proven |  |  |  |  |
| [trees/SPARK2/Ada-SPARK-Univalued-Binary-Tree](trees/SPARK2/Ada-SPARK-Univalued-Binary-Tree) | proven |  |  |  |  |
| [trees/SPARK2/Ada-SPARK-Validate-BST-Stub](trees/SPARK2/Ada-SPARK-Validate-BST-Stub) | proven |  | yes | yes |  |
| [trees/SPARK2/Average-Of-Levels-In-Binary-Tree](trees/SPARK2/Average-Of-Levels-In-Binary-Tree) | proven |  |  |  |  |
