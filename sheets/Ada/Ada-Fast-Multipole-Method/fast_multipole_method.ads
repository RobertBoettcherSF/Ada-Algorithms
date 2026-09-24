--  Fast_Multipole_Method — Ada 2023 educational hierarchical multipole
--  method for the 2-D logarithmic (Laplace / Coulomb) n-body potential.
--  Kernel: Phi_i = sum_j q_j * log(1 / r_soft), r_soft = sqrt(r^2 + eps^2).
--  Implements a quadtree, particle-to-multipole (P2M), multipole-to-multipole
--  (M2M) shift, Barnes–Hut-style multipole acceptance (MAC), multipole-to-
--  particle (M2P) far-field evaluation, and direct near-field summation.
--  Multipoles are complex Greengard–Rokhlin moments of order up to P
--  (not monopole-only Barnes–Hut). Full M2L/L2L Greengard pipeline is not
--  required; complexity is typically O(N log N) for fixed accuracy.
--  Based on Wikipedia "Fast multipole method", Greengard & Rokhlin (1987),
--  and Rokhlin (1985). Related: Barnes–Hut, multipole expansion, n-body.

pragma Ada_2022;

package Fast_Multipole_Method
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   Max_Particles : constant Positive := 4_096;
   Max_Order     : constant Positive := 8;
   Max_Nodes     : constant Positive := 8_192;

   subtype Particle_Count is Natural range 0 .. Max_Particles;
   subtype Particle_Index is Positive range 1 .. Max_Particles;
   subtype Order_Value    is Positive range 1 .. Max_Order;
   subtype Node_Index     is Natural range 0 .. Max_Nodes;
   --  Node_Index 0 = null / unused.

   type Particle is record
      X, Y, Q : Real := 0.0;
   end record;

   type Particle_Array is array (Particle_Index range <>) of Particle;
   type Real_Array     is array (Particle_Index range <>) of Real;

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

   function Soft_Radius (DX, DY, Soft_Eps : Real) return Positive_Real
     with Pre => Soft_Eps >= 0.0, Global => null;
   --  sqrt(DX^2 + DY^2 + Soft_Eps^2), floored away from zero.

   function Log_Kernel (R : Positive_Real) return Real
     with Global => null;
   --  log(1/R) = -log(R).

   ---------------------------------------------------------------------------
   -- Well-separation / MAC
   ---------------------------------------------------------------------------

   function Well_Separated
     (CX1, CY1, Size1 : Real;
      CX2, CY2, Size2 : Real;
      Theta           : Positive_Real) return Boolean
     with Pre => Size1 >= 0.0 and then Size2 >= 0.0 and then Theta > 0.0,
          Global => null;
   --  Multipole acceptance: max(Size1, Size2) / dist < Theta
   --  (Barnes–Hut-style MAC using box side lengths). False if dist ~ 0.

   ---------------------------------------------------------------------------
   -- Complex multipole moments (Greengard–Rokhlin 2-D log kernel)
   ---------------------------------------------------------------------------
   --  About expansion centre z_c, with relative source positions z_j:
   --    a_0 = sum q_j
   --    a_k = - sum_j q_j * z_j^k / k    (k = 1 .. P)
   --  Potential at relative target z (|z| large):
   --    Phi ≈ a_0 * log(1/|z|) - Re( sum_{k=1}^P a_k / z^k )
   --  (real part of -Greengard complex log expansion).

   type Multipole is private;

   function Zero_Multipole return Multipole
     with Global => null;

   function Monopole_Of (M : Multipole) return Real
     with Global => null;

   function Moment_Re (M : Multipole; K : Order_Value) return Real
     with Global => null;

   function Moment_Im (M : Multipole; K : Order_Value) return Real
     with Global => null;

   procedure P2M
     (M      : in out Multipole;
      Parts  : Particle_Array;
      First  : Particle_Index;
      Last   : Particle_Count;
      CX, CY : Real;
      P      : Order_Value)
     with Pre => Last = 0
                  or else (First <= Last
                           and then Last <= Parts'Last
                           and then First >= Parts'First),
          Global => null;
   --  Accumulate multipole of particles First .. Last about (CX, CY).
   --  Last = 0 means empty contribution (no-op beyond ensuring M stays).

   procedure M2M
     (Parent           : in out Multipole;
      Child            : Multipole;
      DX, DY           : Real;
      P                : Order_Value)
     with Global => null;
   --  Shift Child (expanded about child centre) by vector (DX, DY) =
   --  child_centre - parent_centre into Parent (additively).

   function Evaluate_Multipole
     (M      : Multipole;
      TX, TY : Real;
      CX, CY : Real;
      P      : Order_Value) return Real
     with Global => null;
   --  M2P: far-field potential at (TX, TY) from multipole about (CX, CY).

   ---------------------------------------------------------------------------
   -- Configuration
   ---------------------------------------------------------------------------

   type FMM_Config is record
      P              : Order_Value   := 4;
      Leaf_Capacity  : Positive      := 8;
      Theta          : Positive_Real := 0.5;
      Soft_Eps       : Non_Negative  := 1.0E-4;
      Domain_Min_X   : Real          := 0.0;
      Domain_Min_Y   : Real          := 0.0;
      Domain_Size    : Positive_Real := 1.0;
   end record;

   function Default_Config return FMM_Config
     with Global => null;

   ---------------------------------------------------------------------------
   -- Quadtree (fixed node pool)
   ---------------------------------------------------------------------------

   type Tree is limited private;

   procedure Clear_Tree (T : in out Tree)
     with Global => null;

   procedure Build_Tree
     (T      : in out Tree;
      Parts  : Particle_Array;
      Count  : Particle_Count;
      Config : FMM_Config)
     with Pre => Count <= Parts'Length, Global => null;
   --  Build adaptive quadtree over Config domain; form upward multipoles.
   --  Raises Capacity_Exceeded if Max_Nodes or particle slots exhausted.
   --  Count = 0 yields an empty root multipole.

   function Node_Count (T : Tree) return Natural
     with Global => null;

   function Root_Monopole (T : Tree) return Real
     with Global => null;
   --  Total charge stored in the root multipole (0 if empty tree).

   ---------------------------------------------------------------------------
   -- Potential evaluation
   ---------------------------------------------------------------------------

   procedure Compute_Potentials_Brute
     (Parts  : Particle_Array;
      Count  : Particle_Count;
      Soft_Eps : Non_Negative;
      Out_Phi  : out Real_Array)
     with Pre => Count <= Parts'Length
                 and then Out_Phi'Length >= Count
                 and then Out_Phi'First = 1,
          Global => null;
   --  Naive O(N^2) soft-core log potentials. Out_Phi(i) for i in 1 .. Count.
   --  Self-interaction omitted (soft core still used between distinct pairs).

   procedure Compute_Potentials_FMM
     (T        : Tree;
      Parts    : Particle_Array;
      Count    : Particle_Count;
      Config   : FMM_Config;
      Out_Phi  : out Real_Array)
     with Pre => Count <= Parts'Length
                 and then Out_Phi'Length >= Count
                 and then Out_Phi'First = 1,
          Global => null;
   --  Hierarchical multipole evaluation (MAC + M2P + direct near field).

   function Max_Abs_Error (A, B : Real_Array; Count : Particle_Count) return Non_Negative
     with Pre => Count <= A'Length and then Count <= B'Length
                 and then A'First = 1 and then B'First = 1,
          Global => null;

   function Total_Charge (Parts : Particle_Array; Count : Particle_Count) return Real
     with Pre => Count <= Parts'Length, Global => null;

   --  Convenience: build tree then FMM potentials in one call.
   procedure Compute_Potentials_FMM_From_Particles
     (Parts    : Particle_Array;
      Count    : Particle_Count;
      Config   : FMM_Config;
      Out_Phi  : out Real_Array)
     with Pre => Count <= Parts'Length
                 and then Out_Phi'Length >= Count
                 and then Out_Phi'First = 1,
          Global => null;

private

   type Complex is record
      Re, Im : Real := 0.0;
   end record;

   type Moment_Array is array (Order_Value) of Complex;

   type Multipole is record
      A0 : Real := 0.0;
      A  : Moment_Array := [others => (0.0, 0.0)];
   end record;

   type Child_Slots is array (0 .. 3) of Node_Index;

   type Node is record
      CX, CY   : Real := 0.0;
      Size     : Real := 0.0;  -- side length of square
      Mom      : Multipole := (A0 => 0.0, A => [others => (0.0, 0.0)]);
      Children : Child_Slots := [others => 0];
      --  Leaf particle indices into the Build_Tree Parts array (1-based).
      First    : Natural := 0;
      Last     : Natural := 0;
      Is_Leaf  : Boolean := True;
      Used     : Boolean := False;
   end record;

   type Node_Array is array (1 .. Max_Nodes) of Node;

   --  Particle index list for leaves (permutation into caller Parts).
   type Index_Array is array (1 .. Max_Particles) of Particle_Index;

   type Tree is limited record
      Nodes     : Node_Array;
      Free_Top  : Node_Index := 0;
      Root      : Node_Index := 0;
      Idx       : Index_Array := [others => 1];
      N_Parts   : Particle_Count := 0;
      P         : Order_Value := 4;
      Soft_Eps  : Non_Negative := 1.0E-4;
      Theta     : Positive_Real := 0.5;
      Leaf_Cap  : Positive := 8;
   end record;

end Fast_Multipole_Method;
