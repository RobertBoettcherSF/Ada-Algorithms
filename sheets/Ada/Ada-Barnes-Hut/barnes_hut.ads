--  Barnes_Hut — Ada 2023 educational Barnes–Hut tree code for the
--  two-dimensional gravitational n-body problem (quadtree, monopole /
--  center-of-mass approximation). Classic Barnes & Hut (1986) algorithm:
--  build a quadtree storing total mass and COM per node; evaluate forces
--  with multipole acceptance criterion (MAC) s/d < θ. Soft-core softening
--  ε avoids singularities. Distinct from Fast_Multipole_Method (higher-order
--  multipoles). Based on Wikipedia "Barnes–Hut simulation".

pragma Ada_2022;

package Barnes_Hut
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   Max_Bodies : constant Positive := 4_096;
   Max_Nodes  : constant Positive := 8_192;

   subtype Body_Count is Natural range 0 .. Max_Bodies;
   subtype Body_Index is Positive range 1 .. Max_Bodies;
   subtype Node_Index is Natural range 0 .. Max_Nodes;
   --  Node_Index 0 = null / unused.

   type Vec2 is record
      X, Y : Real := 0.0;
   end record;

   type Body_State is record
      Mass     : Non_Negative := 1.0;
      Pos      : Vec2 := (0.0, 0.0);
      Vel      : Vec2 := (0.0, 0.0);
   end record;

   type Body_Array  is array (Body_Index range <>) of Body_State;
   type Force_Array is array (Body_Index range <>) of Vec2;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument  : exception;
   Capacity_Exceeded : exception;
   Empty_System      : exception;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-9;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Hypot (X, Y : Real) return Non_Negative
     with Global => null;
   --  sqrt(X^2 + Y^2) without overflow for educational ranges.

   function Soft_Denom (DX, DY, Soft_Eps : Real) return Positive_Real
     with Pre => Soft_Eps >= 0.0, Global => null;
   --  (r^2 + eps^2)^{3/2} floored away from zero for force kernel.

   ---------------------------------------------------------------------------
   -- Softened gravitational pairwise force
   ---------------------------------------------------------------------------
   --  F_on_1_by_2 = G * m1 * m2 * r_vec / (r^2 + eps^2)^{3/2}
   --  where r_vec = Pos2 - Pos1 (attraction of 1 toward 2).

   function Pair_Force
     (M1, M2           : Non_Negative;
      P1, P2           : Vec2;
      G, Soft_Eps      : Non_Negative) return Vec2
     with Global => null;
   --  Softened Newtonian force on body 1 due to body 2.

   ---------------------------------------------------------------------------
   -- Well-separation / MAC (s/d < θ)
   ---------------------------------------------------------------------------

   function Accept_Node
     (Node_Size : Non_Negative;
      Dist      : Non_Negative;
      Theta     : Non_Negative) return Boolean
     with Global => null;
   --  Classic Barnes–Hut opening criterion: Size / Dist < Theta.
   --  False when Dist ~ 0 or Theta = 0 (forces full recursion / direct).

   function Well_Separated
     (Node_CX, Node_CY, Node_Size : Real;
      Body_X, Body_Y              : Real;
      Theta                       : Non_Negative) return Boolean
     with Pre => Node_Size >= 0.0, Global => null;
   --  Accept_Node using distance from body to node centre (COM).

   ---------------------------------------------------------------------------
   -- Configuration
   ---------------------------------------------------------------------------

   type BH_Config is record
      Theta         : Non_Negative  := 0.5;
      Softening     : Non_Negative  := 1.0E-3;
      G             : Non_Negative  := 1.0;
      Leaf_Capacity : Positive      := 1;
      Domain_Min_X  : Real          := 0.0;
      Domain_Min_Y  : Real          := 0.0;
      Domain_Size   : Positive_Real := 1.0;
   end record;

   function Default_Config return BH_Config
     with Global => null;

   ---------------------------------------------------------------------------
   -- Quadtree (fixed node pool; monopole = mass + COM)
   ---------------------------------------------------------------------------

   type Tree is limited private;

   procedure Clear_Tree (T : in out Tree)
     with Global => null;

   procedure Build_Tree
     (T      : in out Tree;
      Bodies : Body_Array;
      Count  : Body_Count;
      Config : BH_Config)
     with Pre => Count <= Bodies'Length, Global => null;
   --  Build adaptive quadtree; store total mass and COM per node.
   --  Raises Capacity_Exceeded if Max_Nodes exhausted.
   --  Count = 0 yields an empty root.

   function Node_Count (T : Tree) return Natural
     with Global => null;

   function Total_Mass (T : Tree) return Non_Negative
     with Global => null;
   --  Total mass stored at the root (0 if empty).

   function Root_COM (T : Tree) return Vec2
     with Global => null;
   --  Center of mass at the root (origin if empty / zero mass).

   ---------------------------------------------------------------------------
   -- Force evaluation
   ---------------------------------------------------------------------------

   function Force_Brute
     (Bodies : Body_Array;
      Count  : Body_Count;
      Target : Body_Index;
      Config : BH_Config) return Vec2
     with Pre => Count <= Bodies'Length
                 and then (Count = 0 or else Target <= Count),
          Global => null;
   --  Naive O(N) soft-core force on one body (self skipped).

   function Force_Barnes_Hut
     (T      : Tree;
      Bodies : Body_Array;
      Count  : Body_Count;
      Target : Body_Index;
      Config : BH_Config) return Vec2
     with Pre => Count <= Bodies'Length
                 and then (Count = 0 or else Target <= Count),
          Global => null;
   --  Barnes–Hut tree walk for force on one body.

   procedure Forces_All_Brute
     (Bodies : Body_Array;
      Count  : Body_Count;
      Config : BH_Config;
      Out_F  : out Force_Array)
     with Pre => Count <= Bodies'Length
                 and then Out_F'Length >= Count
                 and then Out_F'First = 1,
          Global => null;
   --  Naive O(N^2) forces for all bodies.

   procedure Forces_All_Barnes_Hut
     (T      : Tree;
      Bodies : Body_Array;
      Count  : Body_Count;
      Config : BH_Config;
      Out_F  : out Force_Array)
     with Pre => Count <= Bodies'Length
                 and then Out_F'Length >= Count
                 and then Out_F'First = 1,
          Global => null;
   --  Barnes–Hut forces for all bodies (typically O(N log N)).

   procedure Forces_All_Barnes_Hut_From_Bodies
     (Bodies : Body_Array;
      Count  : Body_Count;
      Config : BH_Config;
      Out_F  : out Force_Array)
     with Pre => Count <= Bodies'Length
                 and then Out_F'Length >= Count
                 and then Out_F'First = 1,
          Global => null;
   --  Convenience: build tree then BH forces.

   function Max_Abs_Error
     (A, B  : Force_Array;
      Count : Body_Count) return Non_Negative
     with Pre => Count <= A'Length and then Count <= B'Length
                 and then A'First = 1 and then B'First = 1,
          Global => null;
   --  Max over i of |Ax-Bx| + |Ay-By| (L1 per vector, then max).

   function Sum_Masses
     (Bodies : Body_Array; Count : Body_Count) return Non_Negative
     with Pre => Count <= Bodies'Length, Global => null;

   ---------------------------------------------------------------------------
   -- Optional: one Euler step using BH forces (educational)
   ---------------------------------------------------------------------------

   procedure Euler_Step
     (Bodies : in out Body_Array;
      Count  : Body_Count;
      Config : BH_Config;
      Dt     : Real)
     with Pre => Count <= Bodies'Length and then Dt >= 0.0,
          Global => null;
   --  a = F/m; v += a*dt; x += v*dt (semi-implicit Euler).

private

   type Child_Slots is array (0 .. 3) of Node_Index;

   type Node is record
      CX, CY   : Real := 0.0;       -- geometric centre of square
      Size     : Real := 0.0;       -- side length
      Mass     : Real := 0.0;       -- total mass in subtree
      COMX, COMY : Real := 0.0;     -- center of mass
      Children : Child_Slots := [others => 0];
      First    : Natural := 0;      -- leaf body index range into Idx
      Last     : Natural := 0;
      Is_Leaf  : Boolean := True;
      Used     : Boolean := False;
   end record;

   type Node_Array is array (1 .. Max_Nodes) of Node;

   type Index_Array is array (1 .. Max_Bodies) of Body_Index;

   type Tree is limited record
      Nodes    : Node_Array;
      Free_Top : Node_Index := 0;
      Root     : Node_Index := 0;
      Idx      : Index_Array := [others => 1];
      N_Bodies : Body_Count := 0;
      Soft_Eps : Non_Negative := 1.0E-3;
      Theta    : Non_Negative := 0.5;
      G        : Non_Negative := 1.0;
      Leaf_Cap : Positive := 1;
   end record;

end Barnes_Hut;
