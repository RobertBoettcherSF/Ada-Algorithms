--  Maximum_Parsimony — Ada 2023 educational package for Wikipedia
--  "Maximum parsimony (phylogenetics)": optimality criterion that prefers the
--  phylogenetic tree requiring the fewest character-state changes (minimum
--  homoplasy).  Fitch (1971) scores a given topology via leaf-to-root set
--  intersection/union (+1 when intersection is empty).  For ≤ Max_Taxa taxa,
--  Exhaustive_Search enumerates rooted binary topologies and returns a
--  shortest tree.  Sankoff (weighted/ordered states) is noted in the README
--  only — not implemented here.

pragma Ada_2022;

package Maximum_Parsimony
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   type Real is digits 12;

   --  Keep Max_Taxa small so (2N−3)!! rooted binary topologies finish instantly.
   Max_Taxa   : constant Positive := 6;
   Max_Sites  : constant Positive := 64;
   Max_States : constant Positive := 8;
   --  Discrete unordered alphabet: states 0 .. State_Count−1 (e.g. ACGT → 0..3).

   subtype Taxon_Count  is Natural  range 0 .. Max_Taxa;
   subtype Taxon_Index  is Positive range 1 .. Max_Taxa;
   subtype Site_Count   is Natural  range 0 .. Max_Sites;
   subtype Site_Index   is Positive range 1 .. Max_Sites;
   subtype State_Value  is Natural  range 0 .. Max_States - 1;
   subtype State_Count  is Positive range 1 .. Max_States;

   --  Total nodes in a rooted binary tree on N leaves: 2N−1.
   Max_Nodes : constant Positive := 2 * Max_Taxa - 1;
   subtype Node_Id is Natural range 0 .. Max_Nodes;
   --  0 = null / absent; leaves = 1 .. N; internals = N+1 .. 2N−1.

   --  Character_Matrix (T, S) = state of taxon T at site S.
   type Character_Matrix is array
     (Taxon_Index range <>, Site_Index range <>) of State_Value;

   type Edge is record
      Parent : Node_Id := 0;
      Child  : Node_Id := 0;
   end record;

   type Node_Record is record
      Left   : Node_Id := 0;
      Right  : Node_Id := 0;
      Parent : Node_Id := 0;
      --  For leaves, Taxon = leaf index 1 .. N; for internals Taxon = 0.
      Taxon  : Taxon_Count := 0;
   end record;

   type Node_Array is array (1 .. Max_Nodes) of Node_Record;

   --  Rooted binary tree.  Leaves 1 .. N; Root is an internal node id.
   type Tree is record
      N     : Taxon_Count := 0;
      Root  : Node_Id     := 0;
      Nodes : Node_Array  := [others => <>];
   end record;

   type Search_Result is record
      Best_Length : Natural := 0;
      Best_Tree   : Tree;
      Trees_Tried : Natural := 0;
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument  : exception;
   Capacity_Exceeded : exception;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-8;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   ---------------------------------------------------------------------------
   -- Matrix helpers
   ---------------------------------------------------------------------------

   function Taxon_Count_Of (M : Character_Matrix) return Taxon_Count
     with Global => null;
   --  Number of taxa (first dimension length).

   function Site_Count_Of (M : Character_Matrix) return Site_Count
     with Global => null;
   --  Number of sites (second dimension length).

   function Make_Matrix
     (N_Taxa  : Taxon_Count;
      N_Sites : Site_Count;
      Fill    : State_Value := 0) return Character_Matrix
     with Pre => N_Taxa >= 1 and then N_Sites >= 1, Global => null;
   --  Allocate an N_Taxa × N_Sites matrix filled with Fill.
   --  Raises Invalid_Argument if N_Taxa = 0 or N_Sites = 0;
   --  Capacity_Exceeded if beyond Max_Taxa / Max_Sites.

   procedure Set_State
     (M     : in out Character_Matrix;
      Taxon : Taxon_Index;
      Site  : Site_Index;
      Value : State_Value)
     with Global => null;
   --  M (Taxon, Site) := Value.  Raises Invalid_Argument if indices out of range.

   function Get_State
     (M     : Character_Matrix;
      Taxon : Taxon_Index;
      Site  : Site_Index) return State_Value
     with Global => null;
   --  Read M (Taxon, Site).  Raises Invalid_Argument if indices out of range.

   function Hamming_Distance
     (M : Character_Matrix; A, B : Taxon_Index) return Natural
     with Global => null;
   --  Number of sites where taxa A and B differ.

   ---------------------------------------------------------------------------
   -- Tree construction
   ---------------------------------------------------------------------------

   function Leaf_Tree (Taxon : Taxon_Index) return Tree
     with Global => null;
   --  Single-leaf tree (Root = Taxon).

   function Join (Left, Right : Tree) return Tree
     with Global => null;
   --  Rooted join: new root with children Left and Right.  Leaf labels must
   --  be disjoint and total ≤ Max_Taxa.  Raises Invalid_Argument / Capacity.

   function Triplet_Tree
     (A, B, C : Taxon_Index) return Tree
     with Pre => A /= B and then B /= C and then A /= C, Global => null;
   --  Rooted ((A,B),C) — cherry A–B sister to C.

   function Quartet_Tree
     (A, B, C, D : Taxon_Index) return Tree
     with Pre => A /= B and then A /= C and then A /= D
       and then B /= C and then B /= D and then C /= D,
          Global => null;
   --  Rooted (((A,B),C),D) — caterpillar / balanced-enough 4-taxon shape.

   function Balanced_Quartet
     (A, B, C, D : Taxon_Index) return Tree
     with Pre => A /= B and then A /= C and then A /= D
       and then B /= C and then B /= D and then C /= D,
          Global => null;
   --  Rooted ((A,B),(C,D)).

   function Is_Leaf (T : Tree; N : Node_Id) return Boolean
     with Global => null;

   function Node_Count (T : Tree) return Natural
     with Global => null;
   --  2*N − 1 for a full rooted binary tree on N leaves (0 if empty).

   ---------------------------------------------------------------------------
   -- Fitch algorithm (1971)
   ---------------------------------------------------------------------------

   function Fitch_Score_Site
     (T    : Tree;
      M    : Character_Matrix;
      Site : Site_Index;
      S    : State_Count := 4) return Natural
     with Global => null;
   --  Fitch length of one site on rooted binary tree T.
   --  At each internal node: if child state-sets intersect, take intersection
   --  (cost 0); else take union and add +1.  S = alphabet size (states 0..S-1).
   --  Raises Invalid_Argument if tree/matrix mismatch or Site out of range.

   function Fitch_Score_Tree
     (T : Tree;
      M : Character_Matrix;
      S : State_Count := 4) return Natural
     with Global => null;
   --  Sum of Fitch_Score_Site over all sites — the tree length L(T).

   ---------------------------------------------------------------------------
   -- Exhaustive search (small N)
   ---------------------------------------------------------------------------

   function Exhaustive_Search
     (M : Character_Matrix;
      S : State_Count := 4) return Search_Result
     with Global => null;
   --  Enumerate all rooted binary topologies on the taxa of M, score each
   --  with Fitch_Score_Tree, return a minimum-length tree and that length.
   --  For N ≤ 1 returns the trivial tree with length 0.
   --  Raises Capacity_Exceeded if N > Max_Taxa; Invalid_Argument if empty.

   function Most_Parsimonious
     (M : Character_Matrix;
      S : State_Count := 4) return Search_Result
     renames Exhaustive_Search;
   --  Alias for Exhaustive_Search.

   function Count_Rooted_Topologies (N : Taxon_Count) return Natural
     with Global => null;
   --  Number of rooted binary labeled topologies: (2N−3)!! for N ≥ 2;
   --  1 for N ≤ 1.  Double factorial of odd numbers: 1,3,15,105,945,…

end Maximum_Parsimony;
