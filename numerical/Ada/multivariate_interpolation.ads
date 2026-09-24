--  Multivariate_Interpolation — Ada 2023 educational survey package for
--  Wikipedia "Multivariate interpolation": taxonomy of regular-grid and
--  scattered methods in 2-D / 3-D, with runnable sketches for nearest-
--  neighbor (2-D grid), bilinear, bicubic (Keys / Catmull–Rom), thin
--  trilinear, and inverse-distance weighting on scattered 2-D clouds.
--  Catalogue-only: Tricubic, Lanczos, Kriging, Natural_Neighbor,
--  Radial_Basis, Spline_Tensor, Barnes (see sibling packages / README).
--  Cap N ≤ 32 per axis (grids), ≤ 64 scattered sites; educational Float.
--  Self-contained — no with of sibling Ada-* packages.
--  Primary source:
--  https://en.wikipedia.org/wiki/Multivariate_interpolation

pragma Ada_2022;

package Multivariate_Interpolation
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   --  At most Max_N samples per regular-grid axis (indices 0 .. N-1).
   Max_N : constant := 32;

   subtype Axis_Size  is Natural range 0 .. Max_N;
   subtype Axis_Index is Natural range 0 .. Max_N - 1;

   --  At most Max_Sites scattered samples for educational IDW.
   Max_Sites : constant := 64;

   subtype Site_Count is Natural range 0 .. Max_Sites;
   subtype Site_Index is Natural range 0 .. Max_Sites - 1;

   type Grid_Values_2D is
     array (Axis_Index range <>, Axis_Index range <>) of Float;

   type Grid_Values_3D is
     array (Axis_Index range <>,
            Axis_Index range <>,
            Axis_Index range <>) of Float;

   --  Packed regular 2-D lattice V(i,j); i = x-index, j = y-index.
   type Grid_2D is record
      Nx, Ny : Axis_Size := 0;
      Values : Grid_Values_2D
                 (0 .. Max_N - 1, 0 .. Max_N - 1) :=
                   [others => [others => 0.0]];
      Valid  : Boolean := False;
   end record;

   --  Packed regular 3-D lattice V(i,j,k).
   type Grid_3D is record
      Nx, Ny, Nz : Axis_Size := 0;
      Values     : Grid_Values_3D
                     (0 .. Max_N - 1, 0 .. Max_N - 1, 0 .. Max_N - 1) :=
                       [others => [others => [others => 0.0]]];
      Valid      : Boolean := False;
   end record;

   type Site_2D is record
      X, Y : Float := 0.0;
   end record;

   type Sites_2D is array (Site_Index range <>) of Site_2D;
   type Samples  is array (Site_Index range <>) of Float;

   --  Packed scattered 2-D cloud (valid entries 0 .. Count-1).
   type Scattered_2D is record
      Count  : Site_Count := 0;
      Sites  : Sites_2D (0 .. Max_Sites - 1) :=
                 [others => (X => 0.0, Y => 0.0)];
      Values : Samples (0 .. Max_Sites - 1) := [others => 0.0];
      Valid  : Boolean := False;
   end record;

   --  Ok               : evaluation succeeded
   --  Out_Of_Domain    : query outside closed grid extent
   --  Too_Small_Grid   : fewer samples than the method requires
   --  Empty            : no sites / zero-size grid
   --  Ill_Started      : unset / invalid container
   --  Not_Implemented  : catalogue-only Method_Kind
   type Status is
     (Ok,
      Out_Of_Domain,
      Too_Small_Grid,
      Empty,
      Ill_Started,
      Not_Implemented);

   type Eval_Result is record
      Value   : Float := 0.0;
      Stat    : Status := Ill_Started;
      Success : Boolean := False;
   end record;

   Invalid_Argument : exception;

   Epsilon_Tol : constant Float := 1.0E-6;
   Near_Tol    : constant Float := 1.0E-5;
   Default_IDW_Power : constant Float := 2.0;

   ---------------------------------------------------------------------------
   -- Method taxonomy
   ---------------------------------------------------------------------------

   type Method_Kind is
     (Nearest_Neighbor,
      Bilinear,
      Bicubic,
      Trilinear,
      Tricubic,
      Lanczos,
      Inverse_Distance,
      Kriging,
      Natural_Neighbor,
      Radial_Basis,
      Spline_Tensor,
      Barnes);
   --  Runnable sketches: Nearest_Neighbor (2-D grid), Bilinear, Bicubic,
   --  Trilinear (thin), Inverse_Distance (scattered 2-D IDW).
   --  Catalogue-only: Tricubic, Lanczos, Kriging, Natural_Neighbor,
   --  Radial_Basis, Spline_Tensor, Barnes.

   type Data_Layout is (Regular_Grid, Scattered);

   type Space_Dim is range 2 .. 3;

   --  Desired continuity of the interpolant (educational heuristic).
   type Smoothness is
     (Piecewise_Constant,  --  jumps OK (nearest)
      C0_Continuous,       --  continuous values (bilinear / trilinear / IDW)
      C1_Smooth);          --  prefer C¹-ish local cubics / Lanczos / tricubic

   type Method_Info is record
      Kind            : Method_Kind;
      Dim_Min         : Space_Dim;
      Dim_Max         : Space_Dim;
      For_Scattered   : Boolean;
      For_Regular     : Boolean;
      Runnable_Sketch : Boolean;
      Smooth          : Smoothness;
   end record;

   type Example_Kind is
     (Constant_Field,
      Affine_Field,
      Checkerboard);

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Float; Tol : Float := Near_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Lerp (A, B : Float; T : Float) return Float
     with Global => null;
   --  (1−t) A + t B

   --  Uniform Catmull–Rom / Keys cubic convolution (a = −1/2) on four
   --  consecutive samples. T ∈ [0,1] between P1 and P2.
   function Cubic_1D
     (P0, P1, P2, P3 : Float; T : Float) return Float
     with Global => null;

   --  Round-to-nearest index on 0 .. Last; ties (exact *.5) → lower index.
   function Round_Index (X : Float; Last : Natural) return Natural
     with Global => null;

   ---------------------------------------------------------------------------
   -- Grid / cloud validation
   ---------------------------------------------------------------------------

   function Is_Valid_Grid (G : Grid_2D) return Boolean
     with Global => null;

   function Is_Valid_Grid (G : Grid_3D) return Boolean
     with Global => null;

   function Is_Valid_Scattered (S : Scattered_2D) return Boolean
     with Global => null;

   function In_Domain (G : Grid_2D; X, Y : Float) return Boolean
     with Global => null;
   --  Valid and (X,Y) ∈ [0,Nx−1]×[0,Ny−1].

   function In_Domain (G : Grid_3D; X, Y, Z : Float) return Boolean
     with Global => null;

   function Large_Enough_Bilinear (G : Grid_2D) return Boolean
     with Global => null;
   --  Nx,Ny ≥ 2

   function Large_Enough_Bicubic (G : Grid_2D) return Boolean
     with Global => null;
   --  Nx,Ny ≥ 4

   function Large_Enough_Trilinear (G : Grid_3D) return Boolean
     with Global => null;
   --  Nx,Ny,Nz ≥ 2

   function Get (G : Grid_2D; I, J : Axis_Index) return Float
     with Pre =>
       G.Valid and then I < G.Nx and then J < G.Ny,
          Global => null;

   procedure Set
     (G : in out Grid_2D; I, J : Axis_Index; Value : Float)
     with Pre =>
       G.Valid and then I < G.Nx and then J < G.Ny;

   function Get (G : Grid_3D; I, J, K : Axis_Index) return Float
     with Pre =>
       G.Valid
       and then I < G.Nx
       and then J < G.Ny
       and then K < G.Nz,
          Global => null;

   procedure Set
     (G       : in out Grid_3D;
      I, J, K : Axis_Index;
      Value   : Float)
     with Pre =>
       G.Valid
       and then I < G.Nx
       and then J < G.Ny
       and then K < G.Nz;

   ---------------------------------------------------------------------------
   -- Taxonomy queries / recommendation
   ---------------------------------------------------------------------------

   function Method_Count return Positive
     with Global => null;

   function Method_Name (M : Method_Kind) return String
     with Global => null;

   function Supports_Runnable (M : Method_Kind) return Boolean
     with Global => null;
   --  True for Nearest_Neighbor, Bilinear, Bicubic, Trilinear,
   --  Inverse_Distance.

   function Describe (M : Method_Kind) return String
     with Global => null;

   function Classify_Method (M : Method_Kind) return Method_Info
     with Global => null;

   function Recommend_Method
     (Layout : Data_Layout;
      Dim    : Space_Dim;
      Want   : Smoothness := C0_Continuous) return Method_Kind
     with Global => null;
   --  Educational heuristic (not a production chooser):
   --    Scattered + Piecewise_Constant → Nearest_Neighbor
   --    Scattered + else               → Inverse_Distance
   --    Regular 2-D + Piecewise_Constant → Nearest_Neighbor
   --    Regular 2-D + C0               → Bilinear
   --    Regular 2-D + C1               → Bicubic
   --    Regular 3-D + Piecewise_Constant → Nearest_Neighbor
   --    Regular 3-D + C0               → Trilinear
   --    Regular 3-D + C1               → Tricubic (catalogue; see sibling)

   ---------------------------------------------------------------------------
   -- Runnable evaluation sketches
   ---------------------------------------------------------------------------

   function Evaluate_Nearest_2D
     (G : Grid_2D; X, Y : Float) return Eval_Result;
   --  Round (X,Y) to nearest lattice index; ties → lower index.
   --  Needs ≥ 1 sample per used axis.

   function Evaluate_Bilinear
     (G : Grid_2D; X, Y : Float) return Eval_Result;
   --  Multilinear on the unit cell containing (X,Y). Needs ≥ 2 per axis.

   function Evaluate_Bicubic
     (G : Grid_2D; X, Y : Float) return Eval_Result;
   --  Tensor-product Catmull–Rom / Keys: cubic along x on each of 4 lines,
   --  then along y. Odd (value) reflection at edges so affine fields stay
   --  exact on the closed domain. Needs ≥ 4 per axis.

   function Evaluate_Trilinear
     (G : Grid_3D; X, Y, Z : Float) return Eval_Result;
   --  Thin multilinear on the unit cell. Needs ≥ 2 per axis.

   --  Inverse-distance weighting on a scattered 2-D cloud:
   --    û(x) = Σ w_i v_i / Σ w_i,  w_i = 1 / d_i^P  (d_i = Euclidean).
   --  Exact hit (d ≈ 0) returns that site's value. Power P > 0.
   function Evaluate_IDW
     (S : Scattered_2D; X, Y : Float; Power : Float := Default_IDW_Power)
      return Eval_Result
     with Pre => Power > 0.0;

   --  Dispatch by Method_Kind; catalogue kinds → Not_Implemented.
   function Evaluate
     (Kind : Method_Kind;
      G    : Grid_2D;
      X, Y : Float) return Eval_Result;
   --  Nearest_Neighbor / Bilinear / Bicubic only; others Not_Implemented.

   ---------------------------------------------------------------------------
   -- Builders / sample data
   ---------------------------------------------------------------------------

   function Make_Empty_2D (Nx, Ny : Axis_Size) return Grid_2D
     with Pre =>
       Nx >= 1 and then Ny >= 1
       and then Nx <= Max_N and then Ny <= Max_N,
          Global => null;

   function Make_Empty_3D (Nx, Ny, Nz : Axis_Size) return Grid_3D
     with Pre =>
       Nx >= 1 and then Ny >= 1 and then Nz >= 1
       and then Nx <= Max_N and then Ny <= Max_N and then Nz <= Max_N,
          Global => null;

   function Make_Constant_2D
     (Nx, Ny : Axis_Size; C : Float) return Grid_2D
     with Pre =>
       Nx >= 1 and then Ny >= 1
       and then Nx <= Max_N and then Ny <= Max_N,
          Global => null;
   --  V(i,j) = C

   function Make_Constant_3D
     (Nx, Ny, Nz : Axis_Size; C : Float) return Grid_3D
     with Pre =>
       Nx >= 1 and then Ny >= 1 and then Nz >= 1
       and then Nx <= Max_N and then Ny <= Max_N and then Nz <= Max_N,
          Global => null;

   --  Affine field V(i,j) = A·i + B·j + C  (continuous f = A x + B y + C).
   function Make_Affine_2D
     (Nx, Ny : Axis_Size; A, B, C : Float) return Grid_2D
     with Pre =>
       Nx >= 1 and then Ny >= 1
       and then Nx <= Max_N and then Ny <= Max_N,
          Global => null;

   --  Affine field V(i,j,k) = A·i + B·j + C·k + D.
   function Make_Affine_3D
     (Nx, Ny, Nz : Axis_Size; A, B, C, D : Float) return Grid_3D
     with Pre =>
       Nx >= 1 and then Ny >= 1 and then Nz >= 1
       and then Nx <= Max_N and then Ny <= Max_N and then Nz <= Max_N,
          Global => null;

   function Make_Checkerboard_2D
     (Nx, Ny : Axis_Size; Lo, Hi : Float) return Grid_2D
     with Pre =>
       Nx >= 1 and then Ny >= 1
       and then Nx <= Max_N and then Ny <= Max_N,
          Global => null;
   --  Values(i,j) = Hi if (i+j) even else Lo.

   function Make_Example (Kind : Example_Kind) return Grid_2D
     with Global => null;
   --  Constant_Field : 5×5 of value 7
   --  Affine_Field   : 6×6 of i + 2j + 1
   --  Checkerboard   : 4×4 Lo=0 Hi=1

   function Make_Empty_Scattered (Count : Site_Count) return Scattered_2D
     with Pre => Count >= 1 and then Count <= Max_Sites, Global => null;

   --  Four corners of the unit square with values F00,F10,F01,F11.
   function Make_Unit_Square_Cloud
     (F00, F10, F01, F11 : Float) return Scattered_2D
     with Global => null;

   function Make_Scattered_From_Grid (G : Grid_2D) return Scattered_2D
     with Pre =>
       G.Valid
       and then G.Nx >= 1
       and then G.Ny >= 1
       and then Natural (G.Nx) * Natural (G.Ny) <= Max_Sites,
          Global => null;
   --  Flatten lattice sites (i,j) → (Float(i), Float(j)).

end Multivariate_Interpolation;
