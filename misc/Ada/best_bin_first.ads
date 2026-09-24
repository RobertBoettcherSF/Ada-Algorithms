--  Best_Bin_First — Ada 2023 educational package for Wikipedia
--  "Best Bin First" (Beis & Lowe style) approximate nearest-neighbor search.
--  Builds a k-d tree over a point set in R^d, then searches bins (subtree
--  cells) in increasing order of min distance from the query to the
--  axis-aligned bin boundary, using a min-priority queue; stops after at
--  most E_max leaf/bin examinations (approximate). Exact linear scan is
--  provided for tests. Educational limits: d ≤ 8, n ≤ 256.
--  Related (README): Ada-Nearest-Neighbor-Search when published later.

pragma Ada_2022;

package Best_Bin_First
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity / domain
   ---------------------------------------------------------------------------

   Max_Dim    : constant Positive := 8;
   Max_Points : constant Positive := 256;
   Max_Nodes  : constant Positive := 512;
   Max_K      : constant Positive := 8;
   Max_PQ     : constant Positive := 512;

   type Real is digits 12;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Dim_Count    is Natural  range 0 .. Max_Dim;
   subtype Dim_Index    is Positive range 1 .. Max_Dim;
   subtype Point_Count  is Natural  range 0 .. Max_Points;
   subtype Point_Index  is Positive range 1 .. Max_Points;
   subtype Node_Index   is Natural  range 0 .. Max_Nodes;
   --  0 denotes null / empty.
   subtype K_Count      is Natural  range 0 .. Max_K;
   subtype K_Index      is Positive range 1 .. Max_K;

   type Coord_Array is array (Dim_Index) of Real;

   type Point is record
      C : Coord_Array := [others => 0.0];
   end record;

   type Point_Array is array (Point_Index) of Point;

   type Point_Cloud is record
      Points : Point_Array := [others => (C => [others => 0.0])];
      Count  : Point_Count := 0;
      Dim    : Dim_Count   := 0;
   end record;

   type Config is record
      E_Max      : Positive  := 32;
      Max_Dim    : Dim_Index := 8;
      Max_Points : Positive  := 256;
   end record;

   type NN_Result is record
      Found         : Boolean      := False;
      Index         : Natural      := 0;
      Distance2     : Non_Negative := 0.0;
      Bins_Examined : Natural      := 0;
   end record;

   type Neighbor is record
      Index     : Natural      := 0;
      Distance2 : Non_Negative := 0.0;
   end record;

   type Neighbor_List is array (K_Index) of Neighbor;

   type KNN_Result is record
      Count         : K_Count       := 0;
      Items         : Neighbor_List := [others => (Index => 0, Distance2 => 0.0)];
      Bins_Examined : Natural       := 0;
   end record;

   type KD_Tree is private;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument  : exception;
   Capacity_Exceeded : exception;
   Empty_Cloud       : exception;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-8;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Near_Point
     (A, B : Point; Dim : Dim_Index; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Distance2 (A, B : Point; Dim : Dim_Index) return Non_Negative
     with Global => null;
   --  Squared Euclidean distance in the first Dim coordinates.

   function Dist2_To_AABB
     (Q : Point; Lo, Hi : Coord_Array; Dim : Dim_Index) return Non_Negative
     with Global => null;
   --  Squared min distance from Q to the axis-aligned box [Lo, Hi].

   ---------------------------------------------------------------------------
   -- Point / cloud constructors
   ---------------------------------------------------------------------------

   function Make_Point
     (Dim : Dim_Index; Coords : Coord_Array) return Point
     with Global => null;

   function Make_Cloud (Dim : Dim_Index) return Point_Cloud
     with Post => Make_Cloud'Result.Dim = Dim
                  and then Make_Cloud'Result.Count = 0,
          Global => null;

   procedure Add_Point (Cloud : in out Point_Cloud; P : Point)
     with Pre  => Cloud.Dim >= 1,
          Global => null;
   --  Raises Capacity_Exceeded when Count = Max_Points.
   --  Raises Invalid_Argument when Cloud.Dim = 0.

   function Cloud_Count (Cloud : Point_Cloud) return Point_Count
     with Global => null;

   function Cloud_Dim (Cloud : Point_Cloud) return Dim_Count
     with Global => null;

   function Default_Config (E_Max : Positive := 32) return Config
     with Global => null;

   ---------------------------------------------------------------------------
   -- k-d tree build
   ---------------------------------------------------------------------------

   function Build_Tree (Cloud : Point_Cloud) return KD_Tree
     with Global => null;
   --  Median-split k-d tree cycling axes 1 .. Dim. Empty cloud => empty tree.
   --  Raises Invalid_Argument when Dim = 0 and Count > 0.
   --  Raises Capacity_Exceeded if the node pool is exhausted (should not
   --  occur under Max_Points ≤ 256).

   function Tree_Empty (Tree : KD_Tree) return Boolean
     with Global => null;

   function Tree_Count (Tree : KD_Tree) return Point_Count
     with Global => null;

   function Tree_Dim (Tree : KD_Tree) return Dim_Count
     with Global => null;

   function Tree_Root (Tree : KD_Tree) return Node_Index
     with Global => null;

   function Node_Is_Leaf (Tree : KD_Tree; N : Node_Index) return Boolean
     with Pre => N <= Max_Nodes, Global => null;

   function Node_Point_Index (Tree : KD_Tree; N : Node_Index) return Natural
     with Pre => N <= Max_Nodes, Global => null;
   --  1-based index into the tree's point store for leaves; 0 otherwise.

   ---------------------------------------------------------------------------
   -- Exact / approximate nearest neighbor
   ---------------------------------------------------------------------------

   function Exact_NN (Cloud : Point_Cloud; Query : Point) return NN_Result
     with Global => null;
   --  Brute-force linear scan. Found=False when Count = 0.

   function Approximate_NN
     (Tree  : KD_Tree;
      Query : Point;
      E_Max : Positive) return NN_Result
     with Global => null;
   --  Best-Bin-First: expand bins by Dist2_To_AABB priority; stop after
   --  examining at most E_Max leaves (bins that hold a point).

   function Query_NN
     (Tree  : KD_Tree;
      Query : Point;
      Cfg   : Config) return NN_Result
     with Global => null;
   --  Alias of Approximate_NN using Cfg.E_Max.

   function Approximate_KNN
     (Tree  : KD_Tree;
      Query : Point;
      K     : K_Index;
      E_Max : Positive) return KNN_Result
     with Global => null;
   --  Same BBF traversal; keep the best K neighbors seen among examined
   --  leaves.

   ---------------------------------------------------------------------------
   -- Priority-queue helpers (bin heap; public for tests / pedagogy)
   ---------------------------------------------------------------------------

   type Bin_Entry is record
      Node  : Node_Index   := 0;
      Dist2 : Non_Negative := 0.0;
   end record;

   type Bin_Heap is private;

   function Empty_Heap return Bin_Heap
     with Global => null;

   function Heap_Count (H : Bin_Heap) return Natural
     with Global => null;

   procedure Heap_Push (H : in out Bin_Heap; E : Bin_Entry)
     with Global => null;
   --  Raises Capacity_Exceeded when full.

   function Heap_Peek (H : Bin_Heap) return Bin_Entry
     with Pre => Heap_Count (H) > 0, Global => null;

   procedure Heap_Pop (H : in out Bin_Heap; E : out Bin_Entry)
     with Pre => Heap_Count (H) > 0, Global => null;

private

   type KD_Node is record
      Left         : Node_Index := 0;
      Right        : Node_Index := 0;
      Split_Dim    : Dim_Index  := 1;
      Split_Val    : Real       := 0.0;
      Point_Index  : Natural    := 0;  -- leaf: 1-based into Points
      Is_Leaf      : Boolean    := False;
      Lo           : Coord_Array := [others => 0.0];
      Hi           : Coord_Array := [others => 0.0];
   end record;

   type Node_Array is array (1 .. Max_Nodes) of KD_Node;

   type Index_Array is array (Point_Index) of Point_Index;

   type KD_Tree is record
      Nodes      : Node_Array;
      Node_Count : Node_Index := 0;
      Root       : Node_Index := 0;
      Points     : Point_Array := [others => (C => [others => 0.0])];
      Count      : Point_Count := 0;
      Dim        : Dim_Count   := 0;
   end record;

   type Bin_Entry_Array is array (1 .. Max_PQ) of Bin_Entry;

   type Bin_Heap is record
      Data  : Bin_Entry_Array;
      Count : Natural := 0;
   end record;

end Best_Bin_First;
