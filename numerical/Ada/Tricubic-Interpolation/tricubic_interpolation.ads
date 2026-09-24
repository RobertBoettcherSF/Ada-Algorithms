--  Tricubic_Interpolation — Ada 2023 educational package for Wikipedia
--  "Tricubic interpolation": locally approximate a regular 3D grid by
--     f(x,y,z) = sum_{i,j,k=0..3} a_ijk x^i y^j z^k
--  via tensor-product Catmull–Rom (cubic Hermite with centered finite-
--  difference tangents) along x, then y, then z. Cap N ≤ 16 per axis;
--  educational Float. Trilinear provided as a simpler sibling baseline.
--  Primary source:
--  https://en.wikipedia.org/wiki/Tricubic_interpolation
--  Siblings (README): Ada-Spline-Interpolation, Ada-Polynomial-Interpolation,
--  upcoming Nearest-neighbor, Lanczos resampling.

pragma Ada_2022;

package Tricubic_Interpolation
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types (educational Float)
   ---------------------------------------------------------------------------

   --  At most Max_N samples per axis (indices 0 .. N-1 with N ≤ Max_N).
   Max_N : constant := 16;

   subtype Axis_Size  is Natural range 0 .. Max_N;
   subtype Axis_Index is Natural range 0 .. Max_N - 1;

   --  Dense values V(i,j,k) on the integer lattice.
   type Grid_Values is
     array (Axis_Index range <>,
            Axis_Index range <>,
            Axis_Index range <>) of Float;

   --  Packed regular grid: valid entries are Values(0..Nx-1, 0..Ny-1, 0..Nz-1).
   type Grid_3D is record
      Nx, Ny, Nz : Axis_Size := 0;
      Values     : Grid_Values
                     (0 .. Max_N - 1, 0 .. Max_N - 1, 0 .. Max_N - 1) :=
                       [others => [others => [others => 0.0]]];
      Valid      : Boolean := False;
   end record;

   --  Ok             : evaluation succeeded
   --  Out_Of_Domain  : (X,Y,Z) outside [0,Nx-1]×[0,Ny-1]×[0,Nz-1]
   --  Too_Small_Grid : fewer than 2 (trilinear) or 4 (tricubic) per axis
   --  Ill_Started    : internal setup could not proceed / invalid grid
   type Status is
     (Ok,
      Out_Of_Domain,
      Too_Small_Grid,
      Ill_Started);

   type Eval_Result is record
      Value   : Float := 0.0;
      Stat    : Status := Ill_Started;
      Success : Boolean := False;
   end record;

   type Example_Kind is
     (Constant_Field,
      Linear_Field,
      Separable_Quadratic,
      Separable_Cubic);

   Invalid_Argument : exception;

   Epsilon_Tol : constant Float := 1.0E-6;
   Near_Tol    : constant Float := 1.0E-5;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Float; Tol : Float := Near_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Lerp (A, B : Float; T : Float) return Float
     with Global => null;
   --  (1−t) A + t B

   ---------------------------------------------------------------------------
   -- Grid validation / domain
   ---------------------------------------------------------------------------

   function Is_Valid_Grid (G : Grid_3D) return Boolean
     with Global => null;
   --  Valid flag set and 1 ≤ Nx,Ny,Nz ≤ Max_N.

   function In_Domain (G : Grid_3D; X, Y, Z : Float) return Boolean
     with Global => null;
   --  True iff Valid and (X,Y,Z) ∈ [0,Nx−1]×[0,Ny−1]×[0,Nz−1].

   function Large_Enough_Trilinear (G : Grid_3D) return Boolean
     with Global => null;
   --  Nx,Ny,Nz ≥ 2

   function Large_Enough_Tricubic (G : Grid_3D) return Boolean
     with Global => null;
   --  Nx,Ny,Nz ≥ 4

   function Get (G : Grid_3D; I, J, K : Axis_Index) return Float
     with Pre =>
       G.Valid
       and then I < G.Nx
       and then J < G.Ny
       and then K < G.Nz,
          Global => null;

   procedure Set
     (G     : in out Grid_3D;
      I, J, K : Axis_Index;
      Value : Float)
     with Pre =>
       G.Valid
       and then I < G.Nx
       and then J < G.Ny
       and then K < G.Nz;

   ---------------------------------------------------------------------------
   -- Evaluation
   ---------------------------------------------------------------------------

   function Evaluate_Trilinear
     (G : Grid_3D; X, Y, Z : Float) return Eval_Result;
   --  Multilinear on the unit cell containing (X,Y,Z). Needs ≥ 2 per axis.

   function Evaluate_Tricubic
     (G : Grid_3D; X, Y, Z : Float) return Eval_Result;
   --  Tensor-product Catmull–Rom: 1-D cubic along x on each of 4×4 lines,
   --  then along y, then along z. Mirror-extrapolated stencil at faces so
   --  linear fields stay exact on the closed domain. Needs ≥ 4 per axis.

   ---------------------------------------------------------------------------
   -- Builders / sample data
   ---------------------------------------------------------------------------

   function Make_Empty (Nx, Ny, Nz : Axis_Size) return Grid_3D
     with Pre =>
       Nx >= 1 and then Ny >= 1 and then Nz >= 1
       and then Nx <= Max_N and then Ny <= Max_N and then Nz <= Max_N,
          Global => null;
   --  Valid grid filled with zeros.

   function Make_Constant_Field
     (Nx, Ny, Nz : Axis_Size; C : Float) return Grid_3D
     with Pre =>
       Nx >= 1 and then Ny >= 1 and then Nz >= 1
       and then Nx <= Max_N and then Ny <= Max_N and then Nz <= Max_N,
          Global => null;
   --  V(i,j,k) = C

   function Make_Linear_Field
     (Nx, Ny, Nz : Axis_Size) return Grid_3D
     with Pre =>
       Nx >= 1 and then Ny >= 1 and then Nz >= 1
       and then Nx <= Max_N and then Ny <= Max_N and then Nz <= Max_N,
          Global => null;
   --  V(i,j,k) = i + 2j + 3k  (continuous f = x + 2y + 3z)

   function Make_Separable_Quadratic
     (Nx, Ny, Nz : Axis_Size) return Grid_3D
     with Pre =>
       Nx >= 1 and then Ny >= 1 and then Nz >= 1
       and then Nx <= Max_N and then Ny <= Max_N and then Nz <= Max_N,
          Global => null;
   --  V(i,j,k) = i² + j² + k²

   function Make_Separable_Cubic
     (Nx, Ny, Nz : Axis_Size) return Grid_3D
     with Pre =>
       Nx >= 1 and then Ny >= 1 and then Nz >= 1
       and then Nx <= Max_N and then Ny <= Max_N and then Nz <= Max_N,
          Global => null;
   --  V(i,j,k) = i³ + j³ + k³

   function Make_Example (Kind : Example_Kind) return Grid_3D
     with Global => null;
   --  Constant_Field      : 5×5×5 of value 7
   --  Linear_Field        : 6×6×6 of i+2j+3k
   --  Separable_Quadratic : 5×5×5 of i²+j²+k²
   --  Separable_Cubic     : 5×5×5 of i³+j³+k³

end Tricubic_Interpolation;
