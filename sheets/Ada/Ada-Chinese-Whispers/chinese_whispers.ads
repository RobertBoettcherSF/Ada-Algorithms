--  Chinese_Whispers — Ada 2023 educational package for Wikipedia
--  "Chinese whispers (clustering method)" / Biemann–Teresniak graph
--  clustering (Chris Biemann & Sven Teresniak, 2005; Biemann 2006 NLP).
--  Hard partitioning, randomized, flat clustering on undirected weighted
--  or unweighted graphs: each node starts with a distinct class (label =
--  node id); nodes are visited in random order and adopt the neighbor
--  class with the strongest connections (sum of edge weights; unweighted
--  = count). Ties broken at random. Linear-time community detection,
--  widely used in NLP (word-sense induction, multiword expressions).
--  Named after the children's whispering game (Telephone).

pragma Ada_2022;

package Chinese_Whispers
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   --  Digits 12 for stable weight / score arithmetic.
   type Real is digits 12;

   subtype Non_Negative is Real range 0.0 .. Real'Last;

   Max_Nodes  : constant Positive := 64;
   Max_Degree : constant Positive := Max_Nodes - 1;
   --  Max undirected edges when stored once per endpoint pair.
   Max_Edges  : constant Positive := (Max_Nodes * Max_Degree) / 2;

   subtype Node_Count is Natural  range 0 .. Max_Nodes;
   subtype Node_Id    is Positive range 1 .. Max_Nodes;
   subtype Degree_Slot is Natural range 0 .. Max_Degree;

   --  Edge weight; unweighted graphs use 1.0.
   subtype Weight is Non_Negative;

   --  Cluster labels: initially each node is its own class (label = id).
   subtype Label_Id is Node_Id;

   type Label_Array is array (Node_Id range <>) of Label_Id;
   type Node_Array  is array (Node_Id range <>) of Node_Id;
   type Weight_Array is array (Positive range <>) of Weight;

   ---------------------------------------------------------------------------
   -- Graph: undirected weighted adjacency lists
   ---------------------------------------------------------------------------

   type Neighbor_List is array (1 .. Max_Degree) of Node_Id;
   type Weight_List   is array (1 .. Max_Degree) of Weight;

   type Node_Neighbors is record
      Degree : Degree_Slot := 0;
      Nodes  : Neighbor_List := [others => 1];
      Weights : Weight_List := [others => 0.0];
   end record;

   type Graph is array (Node_Id range <>) of Node_Neighbors;

   ---------------------------------------------------------------------------
   -- Parameters / result
   ---------------------------------------------------------------------------

   type Parameters is record
      Max_Iters       : Natural := 50;
      Seed            : Natural := 1;
      Relabel_Clusters : Boolean := False;
      --  When True, remap labels to contiguous 1 .. Cluster_Count after run.
   end record;

   Default_Parameters : constant Parameters := (others => <>);

   --  Indexed so empty results (First=1, Last=0) are representable.
   type Result
     (First : Positive; Last : Natural)
   is record
      Labels        : Label_Array (First .. Last);
      Iters         : Natural := 0;
      Converged     : Boolean := False;
      Cluster_Count : Natural := 0;
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument  : exception;
   Capacity_Exceeded : exception;

   ---------------------------------------------------------------------------
   -- Graph construction
   ---------------------------------------------------------------------------

   function Empty_Graph (N : Node_Count) return Graph
     with Pre => N <= Max_Nodes,
          Global => null,
          Post => Empty_Graph'Result'Length = N;
   --  N isolated nodes with ids 1 .. N (empty when N = 0).

   procedure Add_Undirected_Edge
     (G : in out Graph;
      A, B : Node_Id;
      W : Weight := 1.0)
     with Pre => A in G'Range and then B in G'Range,
          Global => null;
   --  Insert bidirectional edge A—B with weight W (or add W if present).
   --  Raises Invalid_Argument if A = B or ids out of range;
   --  Capacity_Exceeded if a neighbor list is full (degree = Max_Degree).

   function Degree (G : Graph; N : Node_Id) return Natural
     with Pre => N in G'Range,
          Global => null,
          Post => Degree'Result <= Max_Degree;
   --  Number of neighbors of N.  Raises Invalid_Argument if N out of range.

   function Edge_Weight
     (G : Graph; A, B : Node_Id) return Weight
     with Pre => A in G'Range and then B in G'Range,
          Global => null;
   --  Weight of undirected edge A—B, or 0.0 if absent.

   ---------------------------------------------------------------------------
   -- Label / score helpers
   ---------------------------------------------------------------------------

   function Init_Labels (G : Graph) return Label_Array
     with Global => null,
          Post => Init_Labels'Result'First = G'First
            and then Init_Labels'Result'Last = G'Last;
   --  Distinct class per node: Labels (N) := N for all N in G'Range.
   --  Empty graph → empty label array.

   function Neighbor_Label_Score
     (G      : Graph;
      Labels : Label_Array;
      N      : Node_Id;
      L      : Label_Id) return Weight
     with Pre => N in G'Range
       and then Labels'First = G'First
       and then Labels'Last = G'Last,
          Global => null;
   --  Sum of edge weights from N to neighbors whose current label is L.
   --  Unweighted graphs (all W = 1) → connection count to class L.

   function Cluster_Count (Labels : Label_Array) return Natural
     with Global => null;
   --  Number of distinct labels in Labels (0 if empty).

   procedure Relabel_Contiguous (Labels : in out Label_Array)
     with Global => null;
   --  Remap labels to contiguous ids 1 .. K preserving partitions
   --  (order of first appearance).  No-op on empty.

   ---------------------------------------------------------------------------
   -- Randomization (deterministic LCG for tests)
   ---------------------------------------------------------------------------

   type RNG_State is private;

   function Init_RNG (Seed : Natural) return RNG_State
     with Global => null;
   --  Seeded linear congruential generator (Park–Miller style).

   function Next_Random (State : in out RNG_State) return Natural
     with Global => null;
   --  Next raw LCG value in 0 .. Modulus−1.

   procedure Shuffle_Nodes
     (Order : in out Node_Array;
      State : in out RNG_State)
     with Global => null;
   --  Fisher–Yates shuffle of Order using State (deterministic given seed).

   function Default_Order (G : Graph) return Node_Array
     with Global => null,
          Post => Default_Order'Result'Length = G'Length;
   --  Identity permutation G'First .. G'Last (empty when G empty).

   ---------------------------------------------------------------------------
   -- Core update / driver
   ---------------------------------------------------------------------------

   procedure Update_Node_Label
     (G      : Graph;
      Labels : in out Label_Array;
      N      : Node_Id;
      State  : in out RNG_State;
      Changed : out Boolean)
     with Pre => N in G'Range
       and then Labels'First = G'First
       and then Labels'Last = G'Last,
          Global => null;
   --  Set Labels (N) to the neighbor class with maximal Neighbor_Label_Score.
   --  Ties: pick uniformly among tied labels via State.
   --  Isolated node (deg 0): keeps its label; Changed = False.
   --  Changed is True iff the label actually changed.

   function Run_Chinese_Whispers
     (G    : Graph;
      Params : Parameters := Default_Parameters) return Result
     with Global => null,
          Post => Run_Chinese_Whispers'Result.First = G'First
            and then Run_Chinese_Whispers'Result.Last = G'Last;
   --  Full algorithm: Init_Labels; for up to Max_Iters sweeps, shuffle
   --  nodes with Seed and update each; early-stop when a full sweep makes
   --  no label changes (Converged).  Optional Relabel_Clusters.

   function Run_Chinese_Whispers
     (G     : Graph;
      Order : Node_Array;
      Params : Parameters := Default_Parameters) return Result
     with Pre => Order'Length = G'Length,
          Global => null,
          Post => Run_Chinese_Whispers'Result.First = G'First
            and then Run_Chinese_Whispers'Result.Last = G'Last;
   --  Deterministic variant: use the given node permutation each sweep
   --  (no reshuffle).  Seed still used for tie-breaking.  Raises
   --  Invalid_Argument if Order is not a permutation of G'Range.

private

   --  Park–Miller minimal standard LCG: X_{n+1} = (a X_n) mod m
   --  with a = 16807, m = 2^31 − 1.  Seed 0 maps to 1.
   LCG_Modulus : constant := 2_147_483_647;  -- 2^31 - 1
   LCG_Multiplier : constant := 16_807;

   type RNG_State is record
      Value : Natural := 1;
   end record;

end Chinese_Whispers;
