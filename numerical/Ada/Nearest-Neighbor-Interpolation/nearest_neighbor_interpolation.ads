--  Nearest_Neighbor_Interpolation — Ada 2023 educational package for
--  Wikipedia "Nearest-neighbor interpolation": piecewise-constant
--  interpolant that returns the sample whose site is closest to the
--  query (Euclidean; optional Manhattan for teaching). Covers scattered
--  1-D/2-D clouds (brute-force nearest, n ≤ 256) and regular-grid
--  round-to-nearest indexing in 1-D/2-D/3-D (texture-style sampling).
--  Tie-break: lower index / lexicographic (i, then j, then k).
--  Primary source:
--  https://en.wikipedia.org/wiki/Nearest-neighbor_interpolation
--  Siblings (README): Ada-Tricubic-Interpolation, Ada-Spline-Interpolation,
--  upcoming Lanczos resampling.

pragma Ada_2022;

package Nearest_Neighbor_Interpolation
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types (educational Float)
   ---------------------------------------------------------------------------

   --  At most Max_Sites scattered samples (indices 0 .. Count-1).
   Max_Sites : constant := 256;

   subtype Site_Count is Natural range 0 .. Max_Sites;
   subtype Site_Index is Natural range 0 .. Max_Sites - 1;

   --  At most Max_N samples per regular-grid axis.
   Max_N : constant := 64;

   subtype Axis_Size  is Natural range 0 .. Max_N;
   subtype Axis_Index is Natural range 0 .. Max_N - 1;

   type Site_1D is record
      X : Float := 0.0;
   end record;

   type Site_2D is record
      X, Y : Float := 0.0;
   end record;

   type Site_3D is record
      X, Y, Z : Float := 0.0;
   end record;

   type Sites_1D is array (Site_Index range <>) of Site_1D;
   type Sites_2D is array (Site_Index range <>) of Site_2D;
   type Samples  is array (Site_Index range <>) of Float;

   --  Packed scattered clouds (valid entries 0 .. Count-1).
   type Scattered_1D is record
      Count  : Site_Count := 0;
      Sites  : Sites_1D (0 .. Max_Sites - 1) := [others => (X => 0.0)];
      Values : Samples (0 .. Max_Sites - 1) := [others => 0.0];
      Valid  : Boolean := False;
   end record;

   type Scattered_2D is record
      Count  : Site_Count := 0;
      Sites  : Sites_2D (0 .. Max_Sites - 1) :=
                 [others => (X => 0.0, Y => 0.0)];
      Values : Samples (0 .. Max_Sites - 1) := [others => 0.0];
      Valid  : Boolean := False;
   end record;

   --  Regular grids on the integer lattice (unit spacing).
   type Grid_Values_1D is array (Axis_Index range <>) of Float;
   type Grid_Values_2D is
     array (Axis_Index range <>, Axis_Index range <>) of Float;
   type Grid_Values_3D is
     array (Axis_Index range <>,
            Axis_Index range <>,
            Axis_Index range <>) of Float;

   type Grid_1D is record
      N      : Axis_Size := 0;
      Values : Grid_Values_1D (0 .. Max_N - 1) := [others => 0.0];
      Valid  : Boolean := False;
   end record;

   type Grid_2D is record
      Nx, Ny : Axis_Size := 0;
      Values : Grid_Values_2D
                 (0 .. Max_N - 1, 0 .. Max_N - 1) :=
                   [others => [others => 0.0]];
      Valid  : Boolean := False;
   end record;

   type Grid_3D is record
      Nx, Ny, Nz : Axis_Size := 0;
      Values     : Grid_Values_3D
                     (0 .. Max_N - 1, 0 .. Max_N - 1, 0 .. Max_N - 1) :=
                       [others => [others => [others => 0.0]]];
      Valid      : Boolean := False;
   end record;

   --  Ok            : evaluation / nearest lookup succeeded
   --  Empty         : no sites / zero-size grid
   --  Out_Of_Domain : query outside the closed grid extent
   --  Ill_Started   : invalid / unset container
   type Status is
     (Ok,
      Empty,
      Out_Of_Domain,
      Ill_Started);

   type Distance_Kind is (Euclidean, Manhattan);

   type Eval_Result is record
      Value   : Float := 0.0;
      Index   : Natural := 0;  -- winning site / 1-D index
      I, J, K : Natural := 0;  -- grid multi-index (unused dims stay 0)
      Dist    : Float := 0.0;  -- distance to chosen site (scattered)
      Stat    : Status := Ill_Started;
      Success : Boolean := False;
   end record;

   type Nearest_Result is record
      Index   : Natural := 0;
      Dist    : Float := 0.0;
      Stat    : Status := Ill_Started;
      Success : Boolean := False;
   end record;

   Invalid_Argument : exception;

   Epsilon_Tol : constant Float := 1.0E-6;
   Near_Tol    : constant Float := 1.0E-5;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Float; Tol : Float := Near_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Near (A, B : Site_1D; Tol : Float := Near_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Near (A, B : Site_2D; Tol : Float := Near_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Dist
     (A, B : Site_1D; Kind : Distance_Kind := Euclidean) return Float
     with Global => null;

   function Dist
     (A, B : Site_2D; Kind : Distance_Kind := Euclidean) return Float
     with Global => null;

   function Dist
     (A, B : Site_3D; Kind : Distance_Kind := Euclidean) return Float
     with Global => null;

   function Make_Site_1D (X : Float) return Site_1D
     with Global => null;

   function Make_Site_2D (X, Y : Float) return Site_2D
     with Global => null;

   function Make_Site_3D (X, Y, Z : Float) return Site_3D
     with Global => null;

   ---------------------------------------------------------------------------
   -- Round-to-nearest index (ties → lower index)
   ---------------------------------------------------------------------------

   --  Map continuous X on a unit lattice to nearest integer index in
   --  0 .. Last. Exact midpoints (*.5) prefer the lower index.
   function Round_Index (X : Float; Last : Natural) return Natural
     with Pre => Last < Max_N, Global => null;

   ---------------------------------------------------------------------------
   -- Validation / domain
   ---------------------------------------------------------------------------

   function Is_Valid_Scattered (S : Scattered_1D) return Boolean
     with Global => null;

   function Is_Valid_Scattered (S : Scattered_2D) return Boolean
     with Global => null;

   function Is_Valid_Grid (G : Grid_1D) return Boolean
     with Global => null;

   function Is_Valid_Grid (G : Grid_2D) return Boolean
     with Global => null;

   function Is_Valid_Grid (G : Grid_3D) return Boolean
     with Global => null;

   function In_Domain (G : Grid_1D; X : Float) return Boolean
     with Global => null;
   --  Valid and X ∈ [0, N−1]

   function In_Domain (G : Grid_2D; X, Y : Float) return Boolean
     with Global => null;
   --  Valid and (X,Y) ∈ [0,Nx−1]×[0,Ny−1]

   function In_Domain (G : Grid_3D; X, Y, Z : Float) return Boolean
     with Global => null;
   --  Valid and (X,Y,Z) ∈ [0,Nx−1]×[0,Ny−1]×[0,Nz−1]

   ---------------------------------------------------------------------------
   -- Nearest-index helpers (scattered, brute-force)
   ---------------------------------------------------------------------------

   function Nearest_Index
     (S    : Scattered_1D;
      Q    : Site_1D;
      Kind : Distance_Kind := Euclidean) return Nearest_Result;
   --  Brute-force; ties → lowest index. Empty / Ill_Started on bad S.

   function Nearest_Index
     (S    : Scattered_2D;
      Q    : Site_2D;
      Kind : Distance_Kind := Euclidean) return Nearest_Result;

   ---------------------------------------------------------------------------
   -- Evaluation — scattered
   ---------------------------------------------------------------------------

   function Evaluate_Scattered
     (S    : Scattered_1D;
      X    : Float;
      Kind : Distance_Kind := Euclidean) return Eval_Result;
   --  Piecewise-constant: value at nearest site (1-D).

   function Evaluate_Scattered
     (S    : Scattered_2D;
      X, Y : Float;
      Kind : Distance_Kind := Euclidean) return Eval_Result;
   --  Piecewise-constant: value at nearest site (2-D Voronoi cell).

   ---------------------------------------------------------------------------
   -- Evaluation — regular grid (texture-style round-to-nearest)
   ---------------------------------------------------------------------------

   function Evaluate_Grid_1D (G : Grid_1D; X : Float) return Eval_Result;
   --  Round X to nearest index; Out_Of_Domain outside [0, N−1].

   function Evaluate_Grid_2D
     (G : Grid_2D; X, Y : Float) return Eval_Result;
   --  Independent round per axis; ties → lower index per axis.

   function Evaluate_Grid_3D
     (G : Grid_3D; X, Y, Z : Float) return Eval_Result;

   ---------------------------------------------------------------------------
   -- Grid accessors
   ---------------------------------------------------------------------------

   function Get (G : Grid_1D; I : Axis_Index) return Float
     with Pre => G.Valid and then I < G.N, Global => null;

   function Get (G : Grid_2D; I, J : Axis_Index) return Float
     with Pre =>
       G.Valid and then I < G.Nx and then J < G.Ny,
          Global => null;

   function Get (G : Grid_3D; I, J, K : Axis_Index) return Float
     with Pre =>
       G.Valid
       and then I < G.Nx
       and then J < G.Ny
       and then K < G.Nz,
          Global => null;

   procedure Set
     (G : in out Grid_1D; I : Axis_Index; Value : Float)
     with Pre => G.Valid and then I < G.N;

   procedure Set
     (G : in out Grid_2D; I, J : Axis_Index; Value : Float)
     with Pre =>
       G.Valid and then I < G.Nx and then J < G.Ny;

   procedure Set
     (G : in out Grid_3D; I, J, K : Axis_Index; Value : Float)
     with Pre =>
       G.Valid
       and then I < G.Nx
       and then J < G.Ny
       and then K < G.Nz;

   ---------------------------------------------------------------------------
   -- Builders / sample data
   ---------------------------------------------------------------------------

   function Make_Linear_1D
     (N : Axis_Size; Y0, Y1 : Float) return Grid_1D
     with Pre => N >= 1 and then N <= Max_N, Global => null;
   --  Values(i) = lerp(Y0, Y1, i/(N−1)); N=1 → Y0.

   function Make_Checkerboard_2D
     (Nx, Ny : Axis_Size; Lo, Hi : Float) return Grid_2D
     with Pre =>
       Nx >= 1 and then Ny >= 1
       and then Nx <= Max_N and then Ny <= Max_N,
          Global => null;
   --  Values(i,j) = Hi if (i+j) even else Lo.

   function Make_Ramp_3D
     (Nx, Ny, Nz : Axis_Size) return Grid_3D
     with Pre =>
       Nx >= 1 and then Ny >= 1 and then Nz >= 1
       and then Nx <= Max_N and then Ny <= Max_N and then Nz <= Max_N,
          Global => null;
   --  Values(i,j,k) = i + 2j + 3k

   function Make_Scattered_1D_Linear
     (Count : Site_Count; X0, X1, Y0, Y1 : Float) return Scattered_1D
     with Pre =>
       Count >= 1 and then Count <= Max_Sites and then X1 >= X0,
          Global => null;
   --  Equally spaced sites on [X0,X1]; values on the line (X0,Y0)–(X1,Y1).

   function Make_Scattered_Cloud_2D
     (Count : Site_Count) return Scattered_2D
     with Pre => Count >= 1 and then Count <= Max_Sites, Global => null;
   --  Deterministic educational cloud: site k at
   --  (cos(2πk/Count), sin(2πk/Count)) with value Float(k).

   function Make_Empty_Scattered_1D return Scattered_1D
     with Global => null;

   function Make_Empty_Scattered_2D return Scattered_2D
     with Global => null;

   function Make_Empty_Grid_1D (N : Axis_Size) return Grid_1D
     with Pre => N >= 1 and then N <= Max_N, Global => null;

   function Make_Empty_Grid_2D (Nx, Ny : Axis_Size) return Grid_2D
     with Pre =>
       Nx >= 1 and then Ny >= 1
       and then Nx <= Max_N and then Ny <= Max_N,
          Global => null;

   function Make_Empty_Grid_3D (Nx, Ny, Nz : Axis_Size) return Grid_3D
     with Pre =>
       Nx >= 1 and then Ny >= 1 and then Nz >= 1
       and then Nx <= Max_N and then Ny <= Max_N and then Nz <= Max_N,
          Global => null;

   --  Canonical educational examples.
   function Make_Example_Grid_1D return Grid_1D
     with Global => null;
   --  Linear_1D: 5 samples from 0 to 8

   function Make_Example_Grid_2D return Grid_2D
     with Global => null;
   --  Checkerboard 4×4, Lo=0, Hi=1

   function Make_Example_Scattered_2D return Scattered_2D
     with Global => null;
   --  8-point unit-circle cloud

   function Make_Example_Grid_3D return Grid_3D
     with Global => null;
   --  Ramp 4×4×4

end Nearest_Neighbor_Interpolation;
