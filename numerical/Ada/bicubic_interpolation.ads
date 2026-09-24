--  Bicubic_Interpolation — Ada 2023 educational package for Wikipedia
--  "Bicubic interpolation": locally approximate a regular 2D grid by
--     f(x,y) = sum_{i,j=0..3} a_ij x^i y^j
--  via tensor-product Catmull–Rom / Keys cubic convolution (a = −1/2)
--  along x then y. Cap N ≤ 64 per axis; educational Float. Thin bilinear
--  sibling included for comparison tests (no with of Ada-Bilinear).
--  Primary source:
--  https://en.wikipedia.org/wiki/Bicubic_interpolation
--  Siblings (README): Ada-Bilinear-Interpolation, Ada-Tricubic-Interpolation,
--  Ada-Lanczos-Resampling, Ada-Nearest-Neighbor-Interpolation;
--  upcoming Multivariate / Monotone cubic / Linear.

pragma Ada_2022;

package Bicubic_Interpolation
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types (educational Float)
   ---------------------------------------------------------------------------

   --  At most Max_N samples per axis (indices 0 .. N-1 with N ≤ Max_N).
   Max_N : constant := 64;

   subtype Axis_Size  is Natural range 0 .. Max_N;
   subtype Axis_Index is Natural range 0 .. Max_N - 1;

   --  Dense values V(i,j) on the integer lattice (i = x, j = y).
   type Grid_Values is
     array (Axis_Index range <>, Axis_Index range <>) of Float;

   --  Packed regular grid: valid entries are Values(0..Nx-1, 0..Ny-1).
   type Grid_2D is record
      Nx, Ny : Axis_Size := 0;
      Values : Grid_Values
                 (0 .. Max_N - 1, 0 .. Max_N - 1) :=
                   [others => [others => 0.0]];
      Valid  : Boolean := False;
   end record;

   --  Ok             : evaluation / resize succeeded
   --  Out_Of_Domain  : (X,Y) outside [0,Nx-1]×[0,Ny-1], or resize > Max_N
   --  Too_Small_Grid : fewer than 2 (bilinear) or 4 (bicubic) per axis
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

   type Resize_2D_Result is record
      Grid    : Grid_2D;
      Stat    : Status := Ill_Started;
      Success : Boolean := False;
   end record;

   type Example_Kind is
     (Constant_Field,
      Affine_Field,
      Checkerboard,
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

   --  Uniform Catmull–Rom / Keys cubic convolution (a = −1/2) on four
   --  consecutive samples. T ∈ [0,1] between P1 and P2.
   function Cubic_1D
     (P0, P1, P2, P3 : Float; T : Float) return Float
     with Global => null;

   ---------------------------------------------------------------------------
   -- Grid validation / domain
   ---------------------------------------------------------------------------

   function Is_Valid_Grid (G : Grid_2D) return Boolean
     with Global => null;
   --  Valid flag set and 1 ≤ Nx,Ny ≤ Max_N.

   function In_Domain (G : Grid_2D; X, Y : Float) return Boolean
     with Global => null;
   --  True iff Valid and (X,Y) ∈ [0,Nx−1]×[0,Ny−1].

   function Large_Enough_Bilinear (G : Grid_2D) return Boolean
     with Global => null;
   --  Nx,Ny ≥ 2

   function Large_Enough_Bicubic (G : Grid_2D) return Boolean
     with Global => null;
   --  Nx,Ny ≥ 4

   function Get (G : Grid_2D; I, J : Axis_Index) return Float
     with Pre =>
       G.Valid and then I < G.Nx and then J < G.Ny,
          Global => null;

   procedure Set
     (G     : in out Grid_2D;
      I, J  : Axis_Index;
      Value : Float)
     with Pre =>
       G.Valid and then I < G.Nx and then J < G.Ny;

   ---------------------------------------------------------------------------
   -- Evaluation
   ---------------------------------------------------------------------------

   function Evaluate_Bilinear
     (G : Grid_2D; X, Y : Float) return Eval_Result;
   --  Multilinear on the unit cell containing (X,Y). Needs ≥ 2 per axis.

   function Evaluate_Bicubic
     (G : Grid_2D; X, Y : Float) return Eval_Result;
   --  Tensor-product Catmull–Rom / Keys: 1-D cubic along x on each of 4
   --  lines of the 4×4 neighbourhood, then along y. Odd (value) reflection
   --  at edges so affine fields stay exact on the closed domain.
   --  Needs ≥ 4 per axis.

   ---------------------------------------------------------------------------
   -- Resize (bicubic sampling onto a new lattice)
   ---------------------------------------------------------------------------

   --  Map output index (i',j') to source
   --    x = i'·(Nx−1)/(New_Nx−1)  (or 0 if New_Nx=1),
   --    y = j'·(Ny−1)/(New_Ny−1)  (or 0 if New_Ny=1),
   --  then Evaluate_Bicubic. Identity when sizes match (up to Float).
   --  Oversized New_* → Out_Of_Domain; zero → Too_Small_Grid;
   --  source <4/axis → Too_Small_Grid.
   function Resize_2D
     (G      : Grid_2D;
      New_Nx : Natural;
      New_Ny : Natural) return Resize_2D_Result;

   ---------------------------------------------------------------------------
   -- Builders / sample data
   ---------------------------------------------------------------------------

   function Make_Empty (Nx, Ny : Axis_Size) return Grid_2D
     with Pre =>
       Nx >= 1 and then Ny >= 1
       and then Nx <= Max_N and then Ny <= Max_N,
          Global => null;
   --  Valid grid filled with zeros.

   function Make_Constant_Field
     (Nx, Ny : Axis_Size; C : Float) return Grid_2D
     with Pre =>
       Nx >= 1 and then Ny >= 1
       and then Nx <= Max_N and then Ny <= Max_N,
          Global => null;
   --  V(i,j) = C

   --  Affine field V(i,j) = A·i + B·j + C  (continuous f = A x + B y + C).
   function Make_Affine_Field
     (Nx, Ny : Axis_Size; A, B, C : Float) return Grid_2D
     with Pre =>
       Nx >= 1 and then Ny >= 1
       and then Nx <= Max_N and then Ny <= Max_N,
          Global => null;

   function Make_Checkerboard
     (Nx, Ny : Axis_Size; Lo, Hi : Float) return Grid_2D
     with Pre =>
       Nx >= 1 and then Ny >= 1
       and then Nx <= Max_N and then Ny <= Max_N,
          Global => null;
   --  Values(i,j) = Hi if (i+j) even else Lo.

   function Make_Separable_Cubic
     (Nx, Ny : Axis_Size) return Grid_2D
     with Pre =>
       Nx >= 1 and then Ny >= 1
       and then Nx <= Max_N and then Ny <= Max_N,
          Global => null;
   --  V(i,j) = i³ + j³

   function Make_Separable_Quadratic
     (Nx, Ny : Axis_Size) return Grid_2D
     with Pre =>
       Nx >= 1 and then Ny >= 1
       and then Nx <= Max_N and then Ny <= Max_N,
          Global => null;
   --  V(i,j) = i² + j²

   function Make_Example (Kind : Example_Kind) return Grid_2D
     with Global => null;
   --  Constant_Field  : 5×5 of value 7
   --  Affine_Field    : 6×6 of i + 2j + 1
   --  Checkerboard    : 4×4 Lo=0 Hi=1
   --  Separable_Cubic : 5×5 of i³+j³

end Bicubic_Interpolation;
