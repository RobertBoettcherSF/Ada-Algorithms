# Implementation candidates

Written by `make proof-index` (tools/proof_index.py); do not edit by hand. Every folder with `stub` = yes in PROOFS.csv carries `implement_next` = yes: it is a candidate for a full implementation of the named algorithm, which comes before the SPARK Silver (level 2) work on it. Signals: the folder name ends in `-Stub` (and it is not listed in `tools/generalised_stubs.txt`), its README calls it a stub (`tools/readme_stubs.txt`), or the hidden-stub scan found that the code lacks the core step (`tools/vv/hidden_stub.csv`). The core-step notes are in `tools/implement_notes.txt`.

**132 candidate folders** (131 with duplicates counted once, the README count).

## concurrency (2)

| Folder | Signal | Full algorithm needs (core step) |
|---|---|---|
| concurrency/SPARK2/Ada-SPARK-Course-Schedule-II | README wording: "Ada-SPARK-Course-Schedule-II  Bounded course-order stub for up to 16 courses" | Kahn's in-degree queue (or DFS post-order) over an arbitrary prerequisite graph, reporting cycles |
| concurrency/SPARK2/Ada-SPARK-Course-Schedule-II-Stub | -Stub name | Kahn's in-degree queue (or DFS post-order) over an arbitrary prerequisite graph, reporting cycles |

## cryptography (3)

| Folder | Signal | Full algorithm needs (core step) |
|---|---|---|
| cryptography/SPARK2/Ada-SPARK-Level-Order-Traversal-Stub | -Stub name | queue-based BFS over a tree of any shape, emitting one list per level |
| cryptography/SPARK2/Ada-SPARK-MD5 | README wording: "MD5 block and digest helpers  A bounded SPARK teaching stub for MD5 sizing: the fixed digest size and the one- or two-block padding boundary are fully verified" | full padding of any message length and the 64-step compression over every 512-bit block |
| cryptography/SPARK2/Ada-SPARK-SHA-1 | README wording: "SHA-1 block and digest helpers  A bounded SPARK teaching stub for SHA-1 sizing: the fixed digest size and the one- or two-block padding boundary are fully verif" | full padding of any message length, the 80-word message schedule and the compression over every block |

## graphs (3)

| Folder | Signal | Full algorithm needs (core step) |
|---|---|---|
| graphs/SPARK2/Ada-SPARK-Clone-Graph-Stub | -Stub name | visited map from original to copy while traversing a graph of any size (BFS/DFS) |
| graphs/SPARK2/Ada-SPARK-Kruskal-MST-Lite | hidden-stub scan: hidden stub: sums every edge cost; no edge selection or union-find, so no spanning tree | sort edges by weight and add them through union-find, skipping edges that close a cycle |
| graphs/SPARK2/Ada-SPARK-Shortest-Path-In-Binary-Matrix | README wording: "Ada-SPARK-Shortest-Path-In-Binary-Matrix  Shortest path in an 8x8 binary matrix (bounded SPARK stub)" | 8-direction BFS over an N x N grid of any size, with distance labels |

## hashing (2)

| Folder | Signal | Full algorithm needs (core step) |
|---|---|---|
| hashing/SPARK2/Ada-SPARK-Design-HashMap-Stub | -Stub name | hashing into buckets with collision chains or probing and resizing, for any key range |
| hashing/SPARK2/Ada-SPARK-Design-HashSet-Stub | -Stub name | hashing into buckets with collision handling for arbitrary keys |

## misc (89)

| Folder | Signal | Full algorithm needs (core step) |
|---|---|---|
| misc/SPARK2/Ada-SPARK-Accounts-Merge-Stub | -Stub name | union-find over e-mail addresses, then group and sort the e-mails per root |
| misc/SPARK2/Ada-SPARK-Alert-Using-Same-Key-Card-Stub | -Stub name | group times per name, sort them and slide a one-hour window to find three uses |
| misc/SPARK2/Ada-SPARK-Alien-Dictionary-Stub | -Stub name | derive letter order from adjacent word pairs, then topological sort with cycle and prefix checks |
| misc/SPARK2/Ada-SPARK-Assign-Cookies | README wording: "Ada-SPARK-Assign-Cookies  Small bounded SPARK stub for the Assign Cookies problem" | sort greed factors and cookie sizes, then match greedily with two pointers |
| misc/SPARK2/Ada-SPARK-Authentication-Manager-Stub | -Stub name | token map with expiry times; renew only unexpired tokens and count live ones at a time |
| misc/SPARK2/Ada-SPARK-Basic-Calculator-Stub | -Stub name | parse +, -, parentheses and multi-digit numbers with a sign stack |
| misc/SPARK2/Ada-SPARK-Browser-History-Stub | -Stub name | a back/forward history with truncation of forward entries on visit |
| misc/SPARK2/Ada-SPARK-Buddy-Memory-Allocation | README wording: "Ada-SPARK-Buddy-Memory-Allocation  A bounded SPARK buddy allocation stub with bounded block metadata" | split power-of-two blocks on allocation and merge free buddies on release |
| misc/SPARK2/Ada-SPARK-Bulb-Switcher-Stub | -Stub name | toggle model or the perfect-square count floor(sqrt(n)) for any n |
| misc/SPARK2/Ada-SPARK-Candy | README wording: "Ada-SPARK-Candy  Small bounded SPARK stub for the Candy problem" | two passes (left-to-right, right-to-left) so higher-rated children get more candy |
| misc/SPARK2/Ada-SPARK-Cheapest-Flights-Stub | -Stub name | Bellman-Ford limited to K+1 edge relaxations (or BFS by stops) over any flight list |
| misc/SPARK2/Ada-SPARK-Circular-Deque-Stub | -Stub name | ring buffer with head and tail indices wrapping at capacity, insertion and removal at both ends |
| misc/SPARK2/Ada-SPARK-Count-Sub-Islands | README wording: "Count Sub Islands (bounded SPARK stub)  An 8x8 bounded overlap count that keeps the proof surface small" | flood fill the islands of grid 2 and check every cell is land in grid 1 |
| misc/SPARK2/Ada-SPARK-Decode-Ways-Stub | -Stub name | DP over prefixes counting valid one- and two-digit codes, including zeros |
| misc/SPARK2/Ada-SPARK-Delete-And-Earn-Stub | -Stub name | bucket the values, then house-robber DP over adjacent values |
| misc/SPARK2/Ada-SPARK-Design-Circular-Queue-Stub | -Stub name | ring buffer with front and rear indices, enqueue and dequeue wrapping at capacity |
| misc/SPARK2/Ada-SPARK-Design-Front-Middle-Back-Queue-Stub | -Stub name | two balanced deques supporting push and pop at front, middle and back |
| misc/SPARK2/Ada-SPARK-Encode-And-Decode-TinyURL-Stub | -Stub name | bijective code generation with a map in both directions |
| misc/SPARK2/Ada-SPARK-Evaluate-Division-Stub | -Stub name | weighted graph of ratios, answering queries by BFS/DFS or weighted union-find |
| misc/SPARK2/Ada-SPARK-Find-Common-Characters | README wording: "Ada-SPARK-Find-Common-Characters  A bounded SPARK stub for detecting a common lowercase character code" | per-letter minimum counts across all words |
| misc/SPARK2/Ada-SPARK-Find-Median-Data-Stream-Stub | -Stub name | two heaps (max-heap low half, min-heap high half) rebalanced on every insert |
| misc/SPARK2/Ada-SPARK-Fixed-Point-Iteration | hidden-stub scan: hidden stub: one hard-wired map x -> (x + Target) / 2 run for 10 steps; no general function and no convergence test | iterate x := g(x) until |x(n+1) - x(n)| < tolerance or the iteration limit, for a user-supplied g |
| misc/SPARK2/Ada-SPARK-Flatten-Nested-List-Stub | -Stub name | stack-based iteration over arbitrarily nested lists |
| misc/SPARK2/Ada-SPARK-Gas-Station | README wording: "Ada-SPARK-Gas-Station  Small bounded SPARK stub for the Gas Station problem" | one pass tracking total and current surplus, resetting the start index when the surplus drops below zero |
| misc/SPARK2/Ada-SPARK-Get-Maximum-In-Generated-Array | README wording: "Ada-SPARK-Get-Maximum-In-Generated-Array  Bounded generated-array dynamic programming stub (n <= 16), with executable tests and level-2 SPARK proof" | build nums from the even/odd recurrence for any n and take the maximum |
| misc/SPARK2/Ada-SPARK-Group-Anagrams-Stub | -Stub name | group words by a canonical key (sorted letters or letter counts) |
| misc/SPARK2/Ada-SPARK-Hand-Of-Straights-Stub | -Stub name | sorted counts; repeatedly take the smallest card and remove a run of W consecutive values |
| misc/SPARK2/Ada-SPARK-Heap-Push-Pop | hidden-stub scan: hidden stub: unsorted array with linear minimum search and a full re-sort; no heap property or sift | sift-up and sift-down on an array heap of any size |
| misc/SPARK2/Ada-SPARK-Hit-Counter-Stub | -Stub name | queue or circular buckets of timestamps, dropping hits older than 300 s |
| misc/SPARK2/Ada-SPARK-House-Robber-III-Stub | -Stub name | tree DP returning (rob, skip) pairs from each subtree |
| misc/SPARK2/Ada-SPARK-How-Many-Numbers-Are-Smaller | README wording: "Ada-SPARK-How-Many-Numbers-Are-Smaller  A bounded SPARK stub for counting entries below a pivot" | counting sort or prefix counts giving, for each element, the number of smaller ones |
| misc/SPARK2/Ada-SPARK-Insert-Interval | README wording: "Ada-SPARK-Insert-Interval  Small bounded SPARK stub for the Insert Interval problem" | merge the new interval into a sorted, disjoint interval list |
| misc/SPARK2/Ada-SPARK-Int-To-Roman-Stub | -Stub name | greedy subtraction over the value table including the subtractive pairs, for 1 .. 3999 |
| misc/SPARK2/Ada-SPARK-Integer-To-English-Stub | -Stub name | chunk into thousands groups and spell hundreds/tens/ones with scale words |
| misc/SPARK2/Ada-SPARK-Intersection-Of-Two-Arrays-II | README wording: "Ada-SPARK-Intersection-Of-Two-Arrays-II  A bounded SPARK stub for detecting a shared value in two arrays" | count map (or sort plus two pointers) keeping multiplicities |
| misc/SPARK2/Ada-SPARK-Is-Subsequence | README wording: "Ada-SPARK-Is-Subsequence  Small bounded subsequence stub (source length at most one, target length at most 16), with executable tests and level-2 SPARK proo" | two-pointer scan over strings of any length |
| misc/SPARK2/Ada-SPARK-Jump-Game-II | README wording: "Ada-SPARK-Jump-Game-II  Small bounded SPARK stub for the Jump Game II problem" | greedy BFS layers: track the farthest reach and count jumps at layer ends |
| misc/SPARK2/Ada-SPARK-K-Closest-Points-Stub | -Stub name | select k by distance using a heap or quickselect for any k and n |
| misc/SPARK2/Ada-SPARK-Kth-Largest-In-Stream-Stub | -Stub name | min-heap of size k updated on every add |
| misc/SPARK2/Ada-SPARK-LFU-Cache-Stub | -Stub name | frequency buckets with recency order, evicting the least frequent (ties to least recent) in O(1) |
| misc/SPARK2/Ada-SPARK-LRU-Cache-Stub | -Stub name | hash map plus doubly linked recency list, evicting the least recently used |
| misc/SPARK2/Ada-SPARK-Logger-Rate-Limiter-Stub | -Stub name | map from message to last print time, allowing a print after 10 s |
| misc/SPARK2/Ada-SPARK-Max-Area-Of-Island | README wording: "Max Area of Island (bounded SPARK stub)  An 8x8 bounded occupied-cell area baseline, with executable tests and Level 2 CVC5 proof" | flood fill each island of a grid of any size and keep the largest area |
| misc/SPARK2/Ada-SPARK-Max-Path-Sum-Stub | -Stub name | tree DP: best downward path per node, and global best through the node |
| misc/SPARK2/Ada-SPARK-Max-Stack-Stub | -Stub name | stack plus ordered structure (or max stack) supporting popMax |
| misc/SPARK2/Ada-SPARK-Merge-Intervals | README wording: "Ada-SPARK-Merge-Intervals  Small bounded SPARK stub for the Merge Intervals problem" | sort by start and merge overlapping intervals |
| misc/SPARK2/Ada-SPARK-Min-Cost-Connect-Cities-Stub | -Stub name | minimum spanning tree (Kruskal/Prim) over all given connections, with a not-connected result |
| misc/SPARK2/Ada-SPARK-Missing-Ranges-Stub | -Stub name | scan the sorted array between lower and upper, emitting gaps |
| misc/SPARK2/Ada-SPARK-My-Calendar-Stub | -Stub name | ordered set of booked intervals with an overlap check on insert |
| misc/SPARK2/Ada-SPARK-My-Linked-List-Stub | -Stub name | dynamic singly linked list with index-based get/add/delete for any length |
| misc/SPARK2/Ada-SPARK-N-Repeated-Element-In-Size-2N-Array | README wording: "Ada-SPARK-N-Repeated-Element-In-Size-2N-Array  A bounded SPARK stub for recognizing a repeated value in a 2N-sized array" | find the element repeated n times (set or a distance-3 window) for any n |
| misc/SPARK2/Ada-SPARK-Network-Delay-Time-Stub | -Stub name | Dijkstra from the source over the weighted edges; maximum distance or -1 |
| misc/SPARK2/Ada-SPARK-Next-Permutation-Stub | -Stub name | find the rightmost ascent, swap with the next larger element, reverse the suffix |
| misc/SPARK2/Ada-SPARK-Non-Overlapping-Intervals | README wording: "Ada-SPARK-Non-Overlapping-Intervals  Small bounded SPARK stub for the Non Overlapping Intervals problem" | sort by end and greedily keep compatible intervals; count removals |
| misc/SPARK2/Ada-SPARK-Number-Of-Good-Pairs | README wording: "Ada-SPARK-Number-Of-Good-Pairs  A bounded SPARK stub for counting equal-value pairs" | count equal-value pairs via frequency counts, n*(n-1)/2 per value |
| misc/SPARK2/Ada-SPARK-Number-Of-Islands | README wording: "Number of Islands (bounded SPARK stub)  A small 8x8, fully bounded baseline that counts occupied cells" | flood fill (DFS/BFS or union-find) counting connected land regions in any grid |
| misc/SPARK2/Ada-SPARK-Online-Stock-Span-Stub | -Stub name | monotonic stack of (price, span) pairs |
| misc/SPARK2/Ada-SPARK-Ordered-Stream-Stub | -Stub name | array with a pointer emitting the maximal consecutive chunk after each insert |
| misc/SPARK2/Ada-SPARK-Pacific-Atlantic-Water-Flow | README wording: "Pacific Atlantic Water Flow (bounded SPARK stub)  An 8x8 reachability baseline using a bounded height sweep" | reverse BFS/DFS from both ocean borders over heights; intersect the reachable sets |
| misc/SPARK2/Ada-SPARK-Pacific-Atlantic-Water-Stub | -Stub name | reverse BFS/DFS from both ocean borders over heights; intersect the reachable sets |
| misc/SPARK2/Ada-SPARK-Paint-House-Lite | README wording: "Ada-SPARK-Paint-House-Lite  One-house, three-color bounded paint-cost stub, with executable tests and level-2 SPARK proof" | DP over houses keeping the minimum cost for each final colour |
| misc/SPARK2/Ada-SPARK-Paint-House-Stub | -Stub name | DP over houses keeping the minimum cost for each final colour |
| misc/SPARK2/Ada-SPARK-Parking-System-Stub | -Stub name | counters per car size with capacity checks |
| misc/SPARK2/Ada-SPARK-Product-Of-Numbers-Stub | -Stub name | prefix products reset at zeros, answering the product of the last k numbers |
| misc/SPARK2/Ada-SPARK-Range-Module-Stub | -Stub name | ordered disjoint interval set with add, remove and query that split and merge intervals |
| misc/SPARK2/Ada-SPARK-Remove-K-Digits | README wording: "Ada-SPARK-Remove-K-Digits  A bounded SPARK digit-buffer stub that removes K trailing digits without allocation" | monotonic increasing stack removing k digits, then strip leading zeros |
| misc/SPARK2/Ada-SPARK-Seat-Manager-Stub | -Stub name | min-heap of free seat numbers |
| misc/SPARK2/Ada-SPARK-Simplify-Path-Stub | -Stub name | split on '/', a stack handling '.', '..' and empty segments |
| misc/SPARK2/Ada-SPARK-Snapshot-Array-Stub | -Stub name | per-index list of (snap_id, value) with binary search on get |
| misc/SPARK2/Ada-SPARK-Spearman-Rank-Stub | -Stub name | rank both samples (average ranks for ties) and take the Pearson correlation of the ranks |
| misc/SPARK2/Ada-SPARK-Stack-Using-Queues-Stub | -Stub name | queue rotation so the last pushed element is at the front |
| misc/SPARK2/Ada-SPARK-Stock-Spanner-Stub | -Stub name | monotonic stack of (price, span) pairs |
| misc/SPARK2/Ada-SPARK-Surrounded-Regions | README wording: "Surrounded Regions (bounded SPARK stub)  An 8x8 bounded interior-capture pass" | flood fill 'O' regions connected to the border, then flip the rest |
| misc/SPARK2/Ada-SPARK-Swim-In-Rising-Water-Stub | -Stub name | Dijkstra/min-heap (or binary search plus BFS) minimising the maximum elevation along a path |
| misc/SPARK2/Ada-SPARK-Target-Sum-Stub | -Stub name | subset-sum DP counting sign assignments that reach the target |
| misc/SPARK2/Ada-SPARK-Three-Sum-Closest-Stub | -Stub name | sort plus two pointers for each anchor, tracking the closest sum |
| misc/SPARK2/Ada-SPARK-Tic-Tac-Toe-Stub | -Stub name | row, column and diagonal counters per player for an n x n board |
| misc/SPARK2/Ada-SPARK-Time-Map-Stub | -Stub name | per-key timestamped values with binary search for the latest timestamp <= t |
| misc/SPARK2/Ada-SPARK-Top-K-Frequent-Stub | -Stub name | frequency count, then bucket sort or heap selection of the top k |
| misc/SPARK2/Ada-SPARK-Tweet-Counts-Stub | -Stub name | per-tweet timestamp lists bucketed into minute/hour/day intervals |
| misc/SPARK2/Ada-SPARK-Uncommon-Words-From-Two-Sentences | README wording: "Ada-SPARK-Uncommon-Words-From-Two-Sentences  A bounded SPARK stub for detecting a word present only on the left" | count words over both sentences and return those occurring exactly once |
| misc/SPARK2/Ada-SPARK-Underground-System-Stub | -Stub name | check-in map and per-route (total time, count) averages |
| misc/SPARK2/Ada-SPARK-Unique-Morse-Code-Words | README wording: "Ada-SPARK-Unique-Morse-Code-Words  A bounded SPARK stub for checking that encoded word values are unique" | translate each word to Morse and count distinct encodings |
| misc/SPARK2/Ada-SPARK-Valid-IP-Address-Stub | -Stub name | full IPv4 (no leading zeros, 0 .. 255) and IPv6 (8 groups of 1 .. 4 hex digits) validation |
| misc/SPARK2/Ada-SPARK-Valid-Number-Stub | -Stub name | finite-state parse of sign, digits, decimal point and exponent |
| misc/SPARK2/Ada-SPARK-Valid-Sudoku-Stub | -Stub name | row, column and 3x3 box seen-sets over the filled cells |
| misc/SPARK2/Ada-SPARK-Vector-2D-Stub | -Stub name | iterator flattening a ragged 2-D vector, skipping empty rows |
| misc/SPARK2/Ada-SPARK-Word-Break-Stub | -Stub name | DP over prefixes with dictionary lookups for any dictionary |
| misc/SPARK2/Ada-SPARK-Word-Ladder-Stub | -Stub name | BFS over one-letter transformations using wildcard buckets |

## numerical (1)

| Folder | Signal | Full algorithm needs (core step) |
|---|---|---|
| numerical/SPARK2/Ada-SPARK-Count-Primes-Stub | -Stub name | sieve of Eratosthenes up to any n |

## parsing (1)

| Folder | Signal | Full algorithm needs (core step) |
|---|---|---|
| parsing/SPARK2/Ada-SPARK-Sparse-Vector-Dot-Stub | -Stub name | store the non-zero (index, value) pairs and merge two of them for the dot product |

## searching (3)

| Folder | Signal | Full algorithm needs (core step) |
|---|---|---|
| searching/SPARK2/Ada-SPARK-Binary-Search-Upper-Bound | hidden-stub scan: hidden stub: unrolled linear scan of six fixed positions; no halving | binary search for the first index whose element is greater than the key, on any sorted array |
| searching/SPARK2/Ada-SPARK-Unique-Binary-Search-Trees-II-Lite | hidden-stub scan: hidden stub: Root_Choices (N) returns N; no trees generated | recursive construction of all structurally unique BSTs over 1 .. n |
| searching/SPARK2/Ada-SPARK-Word-Search | README wording: "Word Search (bounded SPARK stub)  An 8x8 bounded board search for the first word character" | DFS with backtracking over the grid, marking visited cells |

## sorting (15)

| Folder | Signal | Full algorithm needs (core step) |
|---|---|---|
| sorting/SPARK2/Ada-SPARK-Block-Sort | hidden-stub scan: hidden stub: body is the generic one-directional adjacent compare-exchange passes (bubble sort); the named sort is not implemented | block merge sort (WikiSort-style): in-place merges with buffer blocks |
| sorting/SPARK2/Ada-SPARK-Convert-Sorted-Array-To-BST | README wording: "hidden stub: Build always fills the same 7 fixed slots from A (4) / A (2) / A (6) / ... (Sorted_Array is exactly 7 elements); no midpoint recursion, so no gener" | take the middle element as the root and build both halves the same way, for any length; prove the in-order walk is the input and the height is minimal |
| sorting/SPARK2/Ada-SPARK-Exchange-Sort | README wording: "Ada-SPARK-Exchange-Sort  A small bounded Ada/SPARK sorting stub" | compare every pair (i, j > i) and swap when out of order, for any length |
| sorting/SPARK2/Ada-SPARK-Flash-Sort | README wording: "Ada-SPARK-Flash-Sort  A small bounded Ada/SPARK sorting stub" | classify into m classes by linear interpolation, permute in cycles, then insertion sort |
| sorting/SPARK2/Ada-SPARK-Heap-Sort | hidden-stub scan: hidden stub: body is the generic one-directional adjacent compare-exchange passes (bubble sort); the named sort is not implemented | build a max-heap in place, then repeatedly swap the root to the end and sift down |
| sorting/SPARK2/Ada-SPARK-Intro-Sort | hidden-stub scan: hidden stub: body is the generic one-directional adjacent compare-exchange passes (bubble sort); the named sort is not implemented | quicksort with a 2*log2(n) depth limit falling back to heapsort, insertion sort for small parts |
| sorting/SPARK2/Ada-SPARK-Merge-K-Sorted-Lists-Stub | -Stub name | min-heap (or divide and conquer) merge of k sorted lists of any length |
| sorting/SPARK2/Ada-SPARK-Pancake-Sort | hidden-stub scan: hidden stub: body is the generic one-directional adjacent compare-exchange passes (bubble sort); the named sort is not implemented | repeatedly flip the maximum to the front, then to its final position |
| sorting/SPARK2/Ada-SPARK-Patience-Sort | README wording: "Ada-SPARK-Patience-Sort  A small bounded Ada/SPARK sorting stub" | deal into piles by binary search on pile tops, then k-way merge the piles |
| sorting/SPARK2/Ada-SPARK-Quick-Sort | hidden-stub scan: hidden stub: body is the generic one-directional adjacent compare-exchange passes (bubble sort); the named sort is not implemented | partition around a pivot and recurse on both sides, for any length |
| sorting/SPARK2/Ada-SPARK-Shaker-Sort | hidden-stub scan: hidden stub: body is the generic one-directional adjacent compare-exchange passes (bubble sort); the named sort is not implemented | alternating forward and backward bubble passes with shrinking bounds |
| sorting/SPARK2/Ada-SPARK-Smooth-Sort | README wording: "Ada-SPARK-Smooth-Sort  A small bounded Ada/SPARK sorting stub" | Leonardo-heap construction and dismantling |
| sorting/SPARK2/Ada-SPARK-Topological-Sort-Lite | README wording: "hidden stub: only validates a given order; does not compute one (README says validator)" | Kahn's algorithm or DFS order over any DAG, detecting cycles |
| sorting/SPARK2/Ada-SPARK-Tournament-Sort | hidden-stub scan: hidden stub: body is the generic one-directional adjacent compare-exchange passes (bubble sort); the named sort is not implemented | winner tree: repeatedly output the winner and replay its path |
| sorting/SPARK2/Binary-Insertion-Sort | hidden-stub scan: hidden stub: body is the generic one-directional adjacent compare-exchange passes (bubble sort); the named sort is not implemented | binary search for each insertion point, then shift, for any length |

## strings (4)

| Folder | Signal | Full algorithm needs (core step) |
|---|---|---|
| strings/SPARK2/Ada-SPARK-Count-The-Number-Of-Consistent-Strings | README wording: "Ada-SPARK-Count-The-Number-Of-Consistent-Strings  A bounded SPARK stub for counting symbols within an allowed range" | allowed-letter set and a check of every word against it |
| strings/SPARK2/Ada-SPARK-Decode-String-Stub | -Stub name | stack of (count, partial string) handling nested k[...] encodings |
| strings/SPARK2/Ada-SPARK-Reorganize-String-Stub | -Stub name | max-heap by count, placing the two most frequent letters alternately (or report impossible) |
| strings/SPARK2/Ada-SPARK-String-To-Integer-Atoi-Stub | -Stub name | skip whitespace, read the sign and digits, clamp to the integer range at the first overflow |

## trees (9)

| Folder | Signal | Full algorithm needs (core step) |
|---|---|---|
| trees/SPARK2/Ada-SPARK-Binary-Tree-Right-Side-View | hidden-stub scan: hidden stub: returns fixed positions 1, 3, 7, 15 of a complete tree; no traversal (absent nodes not handled) | level-order traversal taking the last node of each level |
| trees/SPARK2/Ada-SPARK-Delete-Node-BST-Stub | -Stub name | BST deletion with the leaf, one-child and two-children (in-order successor) cases |
| trees/SPARK2/Ada-SPARK-Flatten-Binary-Tree-To-Linked-List-Lite | hidden-stub scan: hidden stub: a hard-coded index permutation for one complete-tree shape; no traversal | pre-order rewiring of right pointers in place (Morris-style or recursive) |
| trees/SPARK2/Ada-SPARK-Implement-Trie | hidden-stub scan: hidden stub: flat word list with linear lookup; no trie nodes or child links | child map per node with end-of-word marks; insert, search and startsWith over any alphabet |
| trees/SPARK2/Ada-SPARK-Kth-Smallest-BST-Stub | -Stub name | in-order traversal counting to k |
| trees/SPARK2/Ada-SPARK-Red-Black-Tree | README wording: "Ada/SPARK Red-Black Tree  A deliberately tiny bounded teaching stub: the color enum and a checked rotation index are the first verified building blocks for a re" | insertion with recolouring and rotations (and deletion fix-up) keeping the red-black invariants |
| trees/SPARK2/Ada-SPARK-Trim-BST-Stub | -Stub name | recursive trimming that keeps the BST property within [low, high] |
| trees/SPARK2/Ada-SPARK-Two-Sum-BST-Stub | -Stub name | in-order iterator from both ends (or a hash set) over a BST of any size |
| trees/SPARK2/Ada-SPARK-Validate-BST-Stub | -Stub name | recursive bounds check (or in-order strictly increasing) over any tree |
