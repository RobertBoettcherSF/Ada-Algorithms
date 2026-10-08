# Folders marked stub = yes by make proof-index although the name does not end in -Stub:
# first those whose README calls them a stub (bounded kernel or placeholder,
# not the named algorithm) although the name does not end in -Stub.
# make proof-index marks them stub = yes. One folder per line, then a tab and the README wording.
concurrency/SPARK2/Ada-SPARK-Course-Schedule-II	Ada-SPARK-Course-Schedule-II  Bounded course-order stub for up to 16 courses
cryptography/SPARK2/Ada-SPARK-MD5	MD5 block and digest helpers  A bounded SPARK teaching stub for MD5 sizing: the fixed digest size and the one- or two-block padding boundary are fully verified
cryptography/SPARK2/Ada-SPARK-SHA-1	SHA-1 block and digest helpers  A bounded SPARK teaching stub for SHA-1 sizing: the fixed digest size and the one- or two-block padding boundary are fully verif
graphs/SPARK2/Ada-SPARK-Shortest-Path-In-Binary-Matrix	Ada-SPARK-Shortest-Path-In-Binary-Matrix  Shortest path in an 8x8 binary matrix (bounded SPARK stub)
misc/SPARK2/Ada-SPARK-Assign-Cookies	Ada-SPARK-Assign-Cookies  Small bounded SPARK stub for the Assign Cookies problem
misc/SPARK2/Ada-SPARK-Buddy-Memory-Allocation	Ada-SPARK-Buddy-Memory-Allocation  A bounded SPARK buddy allocation stub with bounded block metadata
misc/SPARK2/Ada-SPARK-Candy	Ada-SPARK-Candy  Small bounded SPARK stub for the Candy problem
misc/SPARK2/Ada-SPARK-Count-Sub-Islands	Count Sub Islands (bounded SPARK stub)  An 8x8 bounded overlap count that keeps the proof surface small
misc/SPARK2/Ada-SPARK-Find-Common-Characters	Ada-SPARK-Find-Common-Characters  A bounded SPARK stub for detecting a common lowercase character code
misc/SPARK2/Ada-SPARK-Gas-Station	Ada-SPARK-Gas-Station  Small bounded SPARK stub for the Gas Station problem
misc/SPARK2/Ada-SPARK-Get-Maximum-In-Generated-Array	Ada-SPARK-Get-Maximum-In-Generated-Array  Bounded generated-array dynamic programming stub (n <= 16), with executable tests and level-2 SPARK proof
misc/SPARK2/Ada-SPARK-How-Many-Numbers-Are-Smaller	Ada-SPARK-How-Many-Numbers-Are-Smaller  A bounded SPARK stub for counting entries below a pivot
misc/SPARK2/Ada-SPARK-Insert-Interval	Ada-SPARK-Insert-Interval  Small bounded SPARK stub for the Insert Interval problem
misc/SPARK2/Ada-SPARK-Intersection-Of-Two-Arrays-II	Ada-SPARK-Intersection-Of-Two-Arrays-II  A bounded SPARK stub for detecting a shared value in two arrays
misc/SPARK2/Ada-SPARK-Is-Subsequence	Ada-SPARK-Is-Subsequence  Small bounded subsequence stub (source length at most one, target length at most 16), with executable tests and level-2 SPARK proo
misc/SPARK2/Ada-SPARK-Jump-Game-II	Ada-SPARK-Jump-Game-II  Small bounded SPARK stub for the Jump Game II problem
misc/SPARK2/Ada-SPARK-Max-Area-Of-Island	Max Area of Island (bounded SPARK stub)  An 8x8 bounded occupied-cell area baseline, with executable tests and Level 2 CVC5 proof
misc/SPARK2/Ada-SPARK-Merge-Intervals	Ada-SPARK-Merge-Intervals  Small bounded SPARK stub for the Merge Intervals problem
misc/SPARK2/Ada-SPARK-N-Repeated-Element-In-Size-2N-Array	Ada-SPARK-N-Repeated-Element-In-Size-2N-Array  A bounded SPARK stub for recognizing a repeated value in a 2N-sized array
misc/SPARK2/Ada-SPARK-Non-Overlapping-Intervals	Ada-SPARK-Non-Overlapping-Intervals  Small bounded SPARK stub for the Non Overlapping Intervals problem
misc/SPARK2/Ada-SPARK-Number-Of-Good-Pairs	Ada-SPARK-Number-Of-Good-Pairs  A bounded SPARK stub for counting equal-value pairs
misc/SPARK2/Ada-SPARK-Number-Of-Islands	Number of Islands (bounded SPARK stub)  A small 8x8, fully bounded baseline that counts occupied cells
misc/SPARK2/Ada-SPARK-Pacific-Atlantic-Water-Flow	Pacific Atlantic Water Flow (bounded SPARK stub)  An 8x8 reachability baseline using a bounded height sweep
misc/SPARK2/Ada-SPARK-Paint-House-Lite	Ada-SPARK-Paint-House-Lite  One-house, three-color bounded paint-cost stub, with executable tests and level-2 SPARK proof
misc/SPARK2/Ada-SPARK-Remove-K-Digits	Ada-SPARK-Remove-K-Digits  A bounded SPARK digit-buffer stub that removes K trailing digits without allocation
misc/SPARK2/Ada-SPARK-Surrounded-Regions	Surrounded Regions (bounded SPARK stub)  An 8x8 bounded interior-capture pass
misc/SPARK2/Ada-SPARK-Uncommon-Words-From-Two-Sentences	Ada-SPARK-Uncommon-Words-From-Two-Sentences  A bounded SPARK stub for detecting a word present only on the left
misc/SPARK2/Ada-SPARK-Unique-Morse-Code-Words	Ada-SPARK-Unique-Morse-Code-Words  A bounded SPARK stub for checking that encoded word values are unique
searching/SPARK2/Ada-SPARK-Word-Search	Word Search (bounded SPARK stub)  An 8x8 bounded board search for the first word character
sorting/SPARK2/Ada-SPARK-Bitonic-Sort	Ada-SPARK-Bitonic-Sort  A small bounded Ada/SPARK sorting stub
sorting/SPARK2/Ada-SPARK-Circle-Sort	Ada-SPARK-Circle-Sort  A small bounded Ada/SPARK sorting stub
sorting/SPARK2/Ada-SPARK-Exchange-Sort	Ada-SPARK-Exchange-Sort  A small bounded Ada/SPARK sorting stub
sorting/SPARK2/Ada-SPARK-Flash-Sort	Ada-SPARK-Flash-Sort  A small bounded Ada/SPARK sorting stub
sorting/SPARK2/Ada-SPARK-Odd-Even-Merge-Sort	Ada-SPARK-Odd-Even-Merge-Sort  A small bounded Ada/SPARK sorting stub
sorting/SPARK2/Ada-SPARK-Patience-Sort	Ada-SPARK-Patience-Sort  A small bounded Ada/SPARK sorting stub
sorting/SPARK2/Ada-SPARK-Smooth-Sort	Ada-SPARK-Smooth-Sort  A small bounded Ada/SPARK sorting stub
sorting/SPARK2/Ada-SPARK-Tim-Sort	Ada-SPARK-Tim-Sort  A small bounded Ada/SPARK sorting stub
strings/SPARK2/Ada-SPARK-Count-The-Number-Of-Consistent-Strings	Ada-SPARK-Count-The-Number-Of-Consistent-Strings  A bounded SPARK stub for counting symbols within an allowed range
trees/SPARK2/Ada-SPARK-Red-Black-Tree	Ada/SPARK Red-Black Tree  A deliberately tiny bounded teaching stub: the color enum and a checked rotation index are the first verified building blocks for a re
# Hidden stubs confirmed by hand (tools/vv/hidden_stub.csv): the code lacks the core step of the named algorithm.
graphs/SPARK2/Ada-SPARK-Kruskal-MST-Lite	hidden stub: sums every edge cost; no edge selection or union-find, so no spanning tree
misc/SPARK2/Ada-SPARK-Heap-Push-Pop	hidden stub: unsorted array with linear minimum search and a full re-sort; no heap property or sift
searching/SPARK2/Ada-SPARK-Binary-Search-Upper-Bound	hidden stub: unrolled linear scan of six fixed positions; no halving
searching/SPARK2/Ada-SPARK-Unique-Binary-Search-Trees	hidden stub: returns a constant table of Catalan numbers; nothing computed
searching/SPARK2/Ada-SPARK-Unique-Binary-Search-Trees-II-Lite	hidden stub: Root_Choices (N) returns N; no trees generated
sorting/SPARK2/Ada-SPARK-Block-Sort	hidden stub: body is the generic one-directional adjacent compare-exchange passes (bubble sort); the named sort is not implemented
sorting/SPARK2/Ada-SPARK-Heap-Sort	hidden stub: body is the generic one-directional adjacent compare-exchange passes (bubble sort); the named sort is not implemented
sorting/SPARK2/Ada-SPARK-Intro-Sort	hidden stub: body is the generic one-directional adjacent compare-exchange passes (bubble sort); the named sort is not implemented
sorting/SPARK2/Ada-SPARK-Pancake-Sort	hidden stub: body is the generic one-directional adjacent compare-exchange passes (bubble sort); the named sort is not implemented
sorting/SPARK2/Ada-SPARK-Quick-Sort	hidden stub: body is the generic one-directional adjacent compare-exchange passes (bubble sort); the named sort is not implemented
sorting/SPARK2/Ada-SPARK-Shaker-Sort	hidden stub: body is the generic one-directional adjacent compare-exchange passes (bubble sort); the named sort is not implemented
sorting/SPARK2/Ada-SPARK-Topological-Sort-Lite	hidden stub: only validates a given order; does not compute one (README says validator)
sorting/SPARK2/Ada-SPARK-Tournament-Sort	hidden stub: body is the generic one-directional adjacent compare-exchange passes (bubble sort); the named sort is not implemented
sorting/SPARK2/Binary-Insertion-Sort	hidden stub: body is the generic one-directional adjacent compare-exchange passes (bubble sort); the named sort is not implemented
trees/SPARK2/Ada-SPARK-Implement-Trie	hidden stub: flat word list with linear lookup; no trie nodes or child links
trees/SPARK2/Ada-SPARK-Binary-Tree-Right-Side-View	hidden stub: returns fixed positions 1, 3, 7, 15 of a complete tree; no traversal (absent nodes not handled)
trees/SPARK2/Ada-SPARK-Flatten-Binary-Tree-To-Linked-List-Lite	hidden stub: a hard-coded index permutation for one complete-tree shape; no traversal
misc/SPARK2/Ada-SPARK-Fixed-Point-Iteration	hidden stub: one hard-wired map x -> (x + Target) / 2 run for 10 steps; no general function and no convergence test
