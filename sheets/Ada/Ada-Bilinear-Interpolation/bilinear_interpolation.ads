--  Bilinear_Interpolation — Ada 2023 educational package for Wikipedia
--  "Bilinear interpolation": repeated linear interpolation on a regular
--  2-D grid (or the closed four-corner formula on the unit square).
--  Also provides a linear 1-D helper for teaching. Cap N ≤ 64 per axis;
--  educational Float. Optional Resize_2D samples a new lattice via
--  bilinear evaluation.
--  Primary source:
--  https://en.wikipedia.org/wiki/Bilinear_interpolation
--  Siblings (README): Ada-Tricubic-Interpolation,
--  Ada-Nearest-Neighbor-Interpolation, Ada-Lanczos-Resampling;
--  upcoming Ada-Bicubic.

pragma Ada_2022;

package Bilinear_Interpolation
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types (educational Float)
   ---------------------------------------------------------------------------

   --  At most Max_N samples per axis (indices 0 .. N-1 with N ≤ Max_N).
   Max_N : constant := 64;

   subtype Axis_Size  is Natural range 0 .. Max_N;
   subtype Axis_Index is Natural range 0 .. Max_N - 1;

   type Grid_Values_1D is array (Axis_Index range <>) of Float;
   type Grid_Values_2D is
     array (Axis_Index range <>, Axis_Index range <>) of Float;

   --  Packed regular 1-D lattice on the integer line (unit spacing).
   type Grid_1D is record
      N      : Axis_Size := 0;
      Values : Grid_Values_1D (0 .. Max_N - 1) := [others => 0.0];
      Valid  : Boolean := False;
   end record;

   --  Packed regular 2-D lattice V(i,j); i = x-index, j = y-index.
   type Grid_2D is record
      Nx, Ny : Axis_Size := 0;
      Values : Grid_Values_2D
                 (0 .. Max_N - 1, 0 .. Max_N - 1) :=
                   [others => [others => 0.0]];
      Valid  : Boolean := False;
   end record;

   --  Ok             : evaluation / resize succeeded
   --  Out_Of_Domain  : query outside closed extent, or resize size > Max_N
   --  Too_Small_Grid : fewer than 2 samples on a required axis
   --  Ill_Started    : unset / invalid container
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
      Linear_Field,
      Checkerboard,
      Ramp);

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
   -- Validation / domain
   ---------------------------------------------------------------------------

   function Is_Valid_Grid (G : Grid_1D) return Boolean
     with Global => null;
   --  Valid flag set and 1 ≤ N ≤ Max_N.

   function Is_Valid_Grid (G : Grid_2D) return Boolean
     with Global => null;
   --  Valid flag set and 1 ≤ Nx,Ny ≤ Max_N.

   function Large_Enough_Linear (G : Grid_1D) return Boolean
     with Global => null;
   --  N ≥ 2

   function Large_Enough_Bilinear (G : Grid_2D) return Boolean
     with Global => null;
   --  Nx,Ny ≥ 2

   function In_Domain (G : Grid_1D; X : Float) return Boolean
     with Global => null;
   --  Valid and X ∈ [0, N−1].

   function In_Domain (G : Grid_2D; X, Y : Float) return Boolean
     with Global => null;
   --  Valid and (X,Y) ∈ [0,Nx−1]×[0,Ny−1].

   function Get (G : Grid_1D; I : Axis_Index) return Float
     with Pre => G.Valid and then I < G.N, Global => null;

   procedure Set
     (G : in out Grid_1D; I : Axis_Index; Value : Float)
     with Pre => G.Valid and then I < G.N;

   function Get (G : Grid_2D; I, J : Axis_Index) return Float
     with Pre =>
       G.Valid and then I < G.Nx and then J < G.Ny,
          Global => null;

   procedure Set
     (G : in out Grid_2D; I, J : Axis_Index; Value : Float)
     with Pre =>
       G.Valid and then I < G.Nx and then J < G.Ny;

   ---------------------------------------------------------------------------
   -- Evaluation
   ---------------------------------------------------------------------------

   --  Linear 1-D: lerp the two samples of the unit cell containing X.
   --  Needs N ≥ 2. Right endpoint X = N−1 uses the last cell.
   function Evaluate_Linear_1D (G : Grid_1D; X : Float) return Eval_Result;

   --  Bilinear on the unit cell containing (X,Y): lerp in x then y
   --  (equivalently the four-corner closed form). Needs Nx,Ny ≥ 2.
   function Evaluate (G : Grid_2D; X, Y : Float) return Eval_Result;

   --  Unit-square closed form with corners F00=f(0,0), F10=f(1,0),
   --  F01=f(0,1), F11=f(1,1) and local (T,U) ∈ [0,1]×[0,1]:
   --    (1−t)(1−u) F00 + t(1−u) F10 + (1−t)u F01 + t u F11
   --  Always succeeds (no grid); T,U are not clamped.
   function Evaluate_Unit_Square
     (F00, F10, F01, F11 : Float; T, U : Float) return Float
     with Global => null;

   ---------------------------------------------------------------------------
   -- Resize (bilinear sampling onto a new lattice)
   ---------------------------------------------------------------------------

   --  Map output index (i',j') to source
   --    x = i'·(Nx−1)/(New_Nx−1)  (or 0 if New_Nx=1),
   --    y = j'·(Ny−1)/(New_Ny−1)  (or 0 if New_Ny=1),
   --  then Evaluate. Identity when New_Nx=Nx and New_Ny=Ny (up to Float).
   --  New_Nx/New_Ny unconstrained so oversized requests can return
   --  Out_Of_Domain; zero sizes → Too_Small_Grid; source <2/axis → Too_Small.
   function Resize_2D
     (G      : Grid_2D;
      New_Nx : Natural;
      New_Ny : Natural) return Resize_2D_Result;

   ---------------------------------------------------------------------------
   -- Builders / sample data
   ---------------------------------------------------------------------------

   function Make_Empty_1D (N : Axis_Size) return Grid_1D
     with Pre => N >= 1 and then N <= Max_N, Global => null;

   function Make_Empty_2D (Nx, Ny : Axis_Size) return Grid_2D
     with Pre =>
       Nx >= 1 and then Ny >= 1
       and then Nx <= Max_N and then Ny <= Max_N,
          Global => null;

   function Make_Constant_1D
     (N : Axis_Size; C : Float) return Grid_1D
     with Pre => N >= 1 and then N <= Max_N, Global => null;

   function Make_Constant_2D
     (Nx, Ny : Axis_Size; C : Float) return Grid_2D
     with Pre =>
       Nx >= 1 and then Ny >= 1
       and then Nx <= Max_N and then Ny <= Max_N,
          Global => null;
   --  V(i,j) = C

   function Make_Linear_1D
     (N : Axis_Size; Y0, Y1 : Float) return Grid_1D
     with Pre => N >= 1 and then N <= Max_N, Global => null;
   --  Values(i) = lerp(Y0, Y1, i/(N−1)); N=1 → Y0.

   --  Affine field V(i,j) = A·i + B·j + C  (continuous f = A x + B y + C).
   function Make_Linear_2D
     (Nx, Ny : Axis_Size; A, B, C : Float) return Grid_2D
     with Pre =>
       Nx >= 1 and then Ny >= 1
       and then Nx <= Max_N and then Ny <= Max_N,
          Global => null;

   function Make_Checkerboard_2D
     (Nx, Ny : Axis_Size; Lo, Hi : Float) return Grid_2D
     with Pre =>
       Nx >= 1 and then Ny >= 1
       and then Nx <= Max_N and then Ny <= Max_N,
          Global => null;
   --  Values(i,j) = Hi if (i+j) even else Lo.

   function Make_Ramp_2D
     (Nx, Ny : Axis_Size) return Grid_2D
     with Pre =>
       Nx >= 1 and then Ny >= 1
       and then Nx <= Max_N and then Ny <= Max_N,
          Global => null;
   --  Values(i,j) = i + 2j   (f = x + 2y)

   function Make_Example (Kind : Example_Kind) return Grid_2D
     with Global => null;
   --  Constant_Field : 5×5 of value 7
   --  Linear_Field   : 6×6 of i + 2j + 1  (A=1,B=2,C=1)
   --  Checkerboard   : 4×4 Lo=0 Hi=1
   --  Ramp           : 5×5 of i+2j

end Bilinear_Interpolation;
