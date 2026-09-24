--  Package_Merge — Ada/SPARK Level 4 educational package for the
--  package-merge algorithm: optimal length-limited Huffman code lengths
--  for positive integer symbol frequencies with a hard max code length L
--  (Wikipedia Package-merge / Larmore–Hirschberg). Static lists only;
--  Integer/Natural weights (no Float); one primary entry point.
--
--  SPARK port of Ada-Package-Merge-Algorithm: hard Max_Symbols /
--  Max_L bounds, no exceptions, In_Bounds / Can_Encode contracts
--  replace Invalid_Frequencies / Invalid_Target. Non-SPARK sibling
--  uses Float weights, four public variants (Coin_Collector,
--  Huffman_Via_Coin_Collector, Space_Efficient_Huffman,
--  Alphabetic_Length_Limited), unbounded-ish local arrays, and
--  exceptions. This port exports only Huffman_Length_Limited (space-
--  efficient package-merge lists with active pruning to 2N−2), keeps
--  Coin_Collector-style packaging private, forces First = 1, and proves
--  length bounds via a final Ensure_Length_Bounds pass (same proof role
--  as Strand_Sort's Bubble_Finish). Kraft inequality and optimality on
--  small cases are checked by tests, not claimed as Level-4 posts.
--
--  Reference: https://en.wikipedia.org/wiki/Package-merge_algorithm

package Package_Merge
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (classroom; keeps indexes / loop VCs in SMT reach)
   ---------------------------------------------------------------------------

   --  Maximum alphabet size. Sibling is unbounded aside from memory.
   Max_Symbols : constant Positive := 32;

   --  Maximum permitted code-word length L. Sibling uses caller Positive.
   Max_L : constant Positive := 16;

   --  Per-symbol frequency cap so packaged weights stay inside Natural.
   Max_Freq : constant Positive := 100_000;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   subtype Symbol_Index is Positive range 1 .. Max_Symbols;
   subtype Freq_Value is Positive range 1 .. Max_Freq;
   subtype Length_Value is Natural range 0 .. Max_L;

   type Symbol_Frequencies is array (Symbol_Index range <>) of Freq_Value;
   type Code_Lengths is array (Symbol_Index range <>) of Natural;

   ---------------------------------------------------------------------------
   -- Shape / capacity guards (expression functions — usable in contracts)
   ---------------------------------------------------------------------------

   function In_Bounds (F : Symbol_Frequencies) return Boolean is
     (F'First = 1 and then F'Last in 1 .. Max_Symbols)
   with Global => null;
   --  Shape guard: 1-based frequency vector of length 1 .. Max_Symbols.
   --  Element type Freq_Value already enforces positive frequencies.

   --  True iff an alphabet of N symbols admits some binary prefix code
   --  with every code word length at most L (Kraft: N ≤ 2^L).
   function Can_Encode (N : Natural; L : Positive) return Boolean is
     (L in 1 .. Max_L and then N <= 2 ** L)
   with
     Global => null,
     Pre    => L <= Max_L;

   ---------------------------------------------------------------------------
   -- Algorithm sketch (space-efficient package-merge)
   ---------------------------------------------------------------------------
   --  Assume In_Bounds (Frequencies), Max_Length in 1 .. Max_L, matching
   --  Lengths bounds, and Can_Encode (N, Max_Length) with N = Length.
   --  1. N = 1: Lengths (1) := 1 and return.
   --  2. Build sorted leaf list L_0 (weight = frequency).
   --  3. For Step in 1 .. Max_Length - 1:
   --       Package adjacent pairs of L_Curr into package nodes;
   --       Merge packages with L_0 by increasing weight;
   --       Prune to the lightest Max_Keep = 2N − 2 items → L_Curr.
   --  4. Traverse the first Min (Max_Keep, |L_Curr|) nodes; each leaf
   --     occurrence increments that symbol's code length.
   --  5. Ensure_Length_Bounds: clamp each Lengths (I) into 1 .. Max_Length
   --     so Level 4 discharges the length Post (correct package-merge
   --     never clamps; Kraft / optimality verified by tests).
   --  Time O(N · L) with static node / list caps. Do not `with` siblings.

   ---------------------------------------------------------------------------
   -- Length-limited Huffman (primary entry)
   ---------------------------------------------------------------------------

   procedure Huffman_Length_Limited
     (Frequencies : Symbol_Frequencies;
      Max_Length  : Positive;
      Lengths     : in out Code_Lengths)
   with
     Global => null,
     Pre    =>
       In_Bounds (Frequencies)
       and then Max_Length in 1 .. Max_L
       and then Lengths'First = Frequencies'First
       and then Lengths'Last = Frequencies'Last
       and then Can_Encode (Frequencies'Length, Max_Length),
     Post   =>
       (for all I in Lengths'Range => Lengths (I) in 1 .. Max_Length);
   --  Optimal length-limited Huffman code lengths via package-merge
   --  lists (space-efficient active pruning). Post proves each length
   --  lies in 1 .. Max_Length. Kraft / weighted path optimality on
   --  classroom cases are checked by the test suite.

end Package_Merge;
