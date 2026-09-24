--  Sweep_And_Prune — Ada 2023 educational implementation of the
--  sweep-and-prune (sort-and-sweep) broad-phase collision detection
--  algorithm. Axis-aligned bounding boxes (AABBs) are projected onto
--  coordinate axes; endpoints are sorted and swept while an active set
--  tracks intervals currently under the sweep line. Candidate pairs are
--  those whose projections overlap on every axis, and are then handed
--  to a narrow-phase contact test (not implemented here).
--  Temporal coherence: between simulation steps objects move little, so
--  endpoint lists stay almost sorted; insertion sort (Update_Sorted)
--  updates them cheaply.
--  Based on Wikipedia "Sweep and prune", Baraff (1992), Cohen et al.
--  I-COLLIDE (1995), and Ericson, Real-Time Collision Detection.
--  Related: bounding volumes, physics engines, game physics.

pragma Ada_2022;

package Sweep_And_Prune
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   type Real is digits 12;

   --  Axis-aligned box in 2-D. Closed intervals: overlap when Max >= Min.
   type AABB_2D is record
      Min_X, Max_X : Real := 0.0;
      Min_Y, Max_Y : Real := 0.0;
   end record;

   --  Optional 3-D AABB (same closed-interval convention).
   type AABB_3D is record
      Min_X, Max_X : Real := 0.0;
      Min_Y, Max_Y : Real := 0.0;
      Min_Z, Max_Z : Real := 0.0;
   end record;

   Max_Objects : constant Positive := 256;
   Max_Pairs   : constant Positive := 32_768;
   Max_Endpoints : constant Positive := Max_Objects * 2;

   subtype Object_Id is Positive range 1 .. Max_Objects;
   subtype Object_Count is Natural range 0 .. Max_Objects;
   subtype Pair_Count is Natural range 0 .. Max_Pairs;
   subtype Endpoint_Count is Natural range 0 .. Max_Endpoints;

   type AABB_Array is array (Object_Id) of AABB_2D;
   type AABB_3D_Array is array (Object_Id) of AABB_3D;

   --  Fixed-capacity world of 2-D boxes. Valid ids are 1 .. Count.
   type World is record
      Boxes : AABB_Array := [others => (0.0, 0.0, 0.0, 0.0)];
      Count : Object_Count := 0;
   end record;

   type World_3D is record
      Boxes : AABB_3D_Array := [others => (0.0, 0.0, 0.0, 0.0, 0.0, 0.0)];
      Count : Object_Count := 0;
   end record;

   --  Unordered candidate pair with canonical A < B.
   type Pair is record
      A, B : Object_Id := 1;
   end record;

   type Pair_Array is array (1 .. Max_Pairs) of Pair;

   type Pair_List is record
      Items : Pair_Array := [others => (1, 1)];
      Count : Pair_Count := 0;
   end record;

   type Axis_2D is (Axis_X, Axis_Y);
   type Axis_3D is (Axis_X, Axis_Y, Axis_Z);

   --  Endpoint for one projection: Kind = +1 at Min (start), -1 at Max (end).
   type Endpoint is record
      Value : Real := 0.0;
      Kind  : Integer := 1;  -- +1 start, -1 end
      Id    : Object_Id := 1;
   end record;

   type Endpoint_Array is array (1 .. Max_Endpoints) of Endpoint;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument  : exception;
   Capacity_Exceeded : exception;

   ---------------------------------------------------------------------------
   -- AABB helpers
   ---------------------------------------------------------------------------

   function Is_Valid_AABB (B : AABB_2D) return Boolean
     with Inline;

   function Is_Valid_AABB (B : AABB_3D) return Boolean
     with Inline;

   function Make_AABB
     (Min_X, Max_X, Min_Y, Max_Y : Real) return AABB_2D
     with Pre => Min_X <= Max_X and then Min_Y <= Max_Y;

   function Make_AABB_3D
     (Min_X, Max_X, Min_Y, Max_Y, Min_Z, Max_Z : Real) return AABB_3D
     with Pre => Min_X <= Max_X
       and then Min_Y <= Max_Y
       and then Min_Z <= Max_Z;

   --  Closed overlap on both axes: Max_A >= Min_B and Max_B >= Min_A.
   function AABBs_Overlap (A, B : AABB_2D) return Boolean
     with Inline;

   function AABBs_Overlap (A, B : AABB_3D) return Boolean
     with Inline;

   function Projections_Overlap
     (A_Min, A_Max, B_Min, B_Max : Real) return Boolean
     with Inline;

   ---------------------------------------------------------------------------
   -- World construction
   ---------------------------------------------------------------------------

   function Empty_World return World
     with Post => Empty_World'Result.Count = 0;

   function Empty_World_3D return World_3D
     with Post => Empty_World_3D'Result.Count = 0;

   procedure Clear (W : in out World)
     with Post => W.Count = 0;

   procedure Clear (W : in out World_3D)
     with Post => W.Count = 0;

   procedure Add_Box (W : in out World; Box : AABB_2D)
     with Pre => Is_Valid_AABB (Box);

   procedure Add_Box (W : in out World_3D; Box : AABB_3D)
     with Pre => Is_Valid_AABB (Box);

   procedure Set_Box (W : in out World; Id : Object_Id; Box : AABB_2D)
     with Pre => Id <= W.Count and then Is_Valid_AABB (Box);

   procedure Set_Box (W : in out World_3D; Id : Object_Id; Box : AABB_3D)
     with Pre => Id <= W.Count and then Is_Valid_AABB (Box);

   ---------------------------------------------------------------------------
   -- Pair list helpers
   ---------------------------------------------------------------------------

   function Empty_Pair_List return Pair_List
     with Post => Empty_Pair_List'Result.Count = 0;

   procedure Clear (P : in out Pair_List)
     with Post => P.Count = 0;

   function Make_Pair (A, B : Object_Id) return Pair
     with Pre => A /= B,
          Post => Make_Pair'Result.A < Make_Pair'Result.B;

   function Contains_Pair (P : Pair_List; A, B : Object_Id) return Boolean
     with Pre => A /= B;

   procedure Append_Pair (P : in out Pair_List; A, B : Object_Id)
     with Pre => A /= B;

   --  Sort pairs by (A, B) and drop duplicates (stable educational sort).
   procedure Normalize_Pairs (P : in out Pair_List);

   function Same_Pair_Set (Left, Right : Pair_List) return Boolean;

   ---------------------------------------------------------------------------
   -- Endpoint helpers (axis projections)
   ---------------------------------------------------------------------------

   procedure Build_Endpoints
     (W     : World;
      Axis  : Axis_2D;
      Eps   : out Endpoint_Array;
      Count : out Endpoint_Count)
     with Pre => W.Count >= 0,
          Post => Count = 2 * W.Count;

   procedure Build_Endpoints
     (W     : World_3D;
      Axis  : Axis_3D;
      Eps   : out Endpoint_Array;
      Count : out Endpoint_Count)
     with Pre => W.Count >= 0,
          Post => Count = 2 * W.Count;

   --  Full sort of endpoints: Value ascending; on tie, starts (+1) before
   --  ends (-1) so touching closed intervals still count as overlapping.
   procedure Sort_Endpoints
     (Eps   : in out Endpoint_Array;
      Count : Endpoint_Count);

   --  Insertion sort for temporally coherent (almost-sorted) lists.
   procedure Update_Sorted
     (Eps   : in out Endpoint_Array;
      Count : Endpoint_Count);

   function Endpoints_Sorted
     (Eps   : Endpoint_Array;
      Count : Endpoint_Count) return Boolean;

   ---------------------------------------------------------------------------
   -- Broad-phase queries
   ---------------------------------------------------------------------------

   --  O(n^2) reference: every unordered pair with closed AABB overlap.
   function Find_Overlapping_Pairs_Brute (W : World) return Pair_List;

   function Find_Overlapping_Pairs_Brute (W : World_3D) return Pair_List;

   --  Sweep-and-prune: 1-D sweep on X, then filter by remaining axes
   --  (Y, and Z for 3-D). Equivalent to brute force on the same boxes.
   function Find_Overlapping_Pairs_SAP (W : World) return Pair_List;

   function Find_Overlapping_Pairs_SAP (W : World_3D) return Pair_List;

   --  1-D overlap pairs along one axis (for teaching / composition).
   function Find_1D_Overlap_Pairs
     (W : World; Axis : Axis_2D) return Pair_List;

end Sweep_And_Prune;
