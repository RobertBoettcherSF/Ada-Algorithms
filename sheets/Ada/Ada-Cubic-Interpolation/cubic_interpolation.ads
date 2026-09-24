--  Cubic_Interpolation — Ada 2023 educational survey package for Wikipedia
--  "Cubic Hermite spline" / Catmull–Rom / cubic convolution: complementary
--  cubic flavours in one package —
--    (1) Catmull–Rom / Keys cubic convolution on a uniform 1D lattice
--        (same Cubic_1D stencil as Ada-Bicubic-Interpolation's 1-D factor);
--    (2) the unique global degree-3 interpolant through four points
--        (Newton / Lagrange);
--    (3) a thin piecewise cubic Hermite with finite-difference tangents
--        (cross-link Ada-Hermite-Interpolation for the full Hermite API).
--  Cap N ≤ 64 samples; educational Float.
--  Primary source:
--  https://en.wikipedia.org/wiki/Cubic_Hermite_spline
--  Spreadsheet / topic label "Cubic interpolation" (distinct from the
--  Hermite / monotone / natural-spline siblings).
--  Siblings (README): Ada-Hermite-Interpolation,
--  Ada-Monotone-Cubic-Interpolation, Ada-Bicubic-Interpolation,
--  Ada-Spline-Interpolation; upcoming Birkhoff.

pragma Ada_2022;

package Cubic_Interpolation
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types (educational Float)
   ---------------------------------------------------------------------------

   --  At most Max_N samples (indices 0 .. N-1 with N ≤ Max_N).
   Max_N : constant := 64;

   subtype Sample_Count is Natural range 0 .. Max_N;
   subtype Sample_Index is Natural range 0 .. Max_N - 1;

   --  0-based abscissae / ordinates.
   type Abscissae is array (Sample_Index range <>) of Float;
   type Ordinates is array (Sample_Index range <>) of Float;

   --  Uniform 1D lattice: Values(0 .. N-1) live at integer sites i = 0 .. N-1.
   --  Query domain for Catmull–Rom: [0, N-1]. Needs N ≥ 4.
   type Grid_1D is record
      N      : Sample_Count := 0;
      Values : Ordinates (0 .. Max_N - 1) := [others => 0.0];
      Valid  : Boolean := False;
   end record;

   --  Sorted (strictly increasing) sample table for four-point / Hermite-FD.
   --  N is the last index; Num_Points = N + 1.
   type Sample_1D is record
      N     : Natural := 0;
      X     : Abscissae (0 .. Max_N - 1) := [others => 0.0];
      Y     : Ordinates (0 .. Max_N - 1) := [others => 0.0];
      Valid : Boolean := False;
   end record;

   --  Thin piecewise cubic Hermite with FD (or user) tangents M(0 .. N).
   type Hermite_Spline is record
      N     : Natural := 0;
      X     : Abscissae (0 .. Max_N - 1) := [others => 0.0];
      Y     : Ordinates (0 .. Max_N - 1) := [others => 0.0];
      M     : Ordinates (0 .. Max_N - 1) := [others => 0.0];
      Valid : Boolean := False;
   end record;

   --  Ok                : evaluation / fit succeeded
   --  Too_Few_Points    : fewer than 4 (CR / four-point) or 2 (Hermite)
   --  Out_Of_Domain     : query outside the closed sample domain
   --  Ill_Started       : empty / invalid / mismatched / over Max_N
   --  Duplicate_Abscissa: coincident or non-strictly-increasing x_i
   type Status is
     (Ok,
      Too_Few_Points,
      Out_Of_Domain,
      Ill_Started,
      Duplicate_Abscissa);

   type Eval_Result is record
      Value   : Float := 0.0;
      Stat    : Status := Ill_Started;
      Success : Boolean := False;
   end record;

   type Fit_Result is record
      S       : Hermite_Spline;
      Stat    : Status := Ill_Started;
      Success : Boolean := False;
   end record;

   type Example_Kind is
     (Linear_Ramp,
      Known_Cubic,
      Sine_Sample);

   Invalid_Argument : exception;

   Epsilon_Tol  : constant Float := 1.0E-6;
   Near_Tol     : constant Float := 1.0E-5;
   Distinct_Tol : constant Float := 1.0E-6;

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
   --  Same formula as Bicubic_Interpolation.Cubic_1D.
   function Cubic_1D
     (P0, P1, P2, P3 : Float; T : Float) return Float
     with Global => null;

   --  Cubic Hermite basis on t ∈ [0,1] (thin Hermite path).
   function H00 (T : Float) return Float with Global => null;
   function H10 (T : Float) return Float with Global => null;
   function H01 (T : Float) return Float with Global => null;
   function H11 (T : Float) return Float with Global => null;

   ---------------------------------------------------------------------------
   -- Validation / domain
   ---------------------------------------------------------------------------

   function Is_Valid_Grid (G : Grid_1D) return Boolean
     with Global => null;
   --  Valid and 1 ≤ N ≤ Max_N.

   function Large_Enough_Catmull_Rom (G : Grid_1D) return Boolean
     with Global => null;
   --  Valid and N ≥ 4.

   function In_Domain (G : Grid_1D; X : Float) return Boolean
     with Global => null;
   --  True iff Valid and X ∈ [0, N−1].

   function Is_Strictly_Increasing
     (X : Abscissae; Tol : Float := Distinct_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function In_Domain (S : Sample_1D; X : Float) return Boolean
     with Global => null;
   --  Valid and X ∈ [X(0), X(N)].

   function In_Domain (S : Hermite_Spline; X : Float) return Boolean
     with Global => null;

   function Get (G : Grid_1D; I : Sample_Index) return Float
     with Pre => G.Valid and then I < G.N, Global => null;

   procedure Set
     (G     : in out Grid_1D;
      I     : Sample_Index;
      Value : Float)
     with Pre => G.Valid and then I < G.N;

   ---------------------------------------------------------------------------
   -- Catmull–Rom / Keys on uniform Grid_1D
   ---------------------------------------------------------------------------

   function Evaluate_Catmull_Rom
     (G : Grid_1D; X : Float) return Eval_Result;
   --  Local 4-point Keys / Catmull–Rom stencil on the unit cell containing
   --  X. Odd (value) reflection at edges so affine samples stay exact.
   --  Needs N ≥ 4; Out_Of_Domain outside [0, N−1].

   ---------------------------------------------------------------------------
   -- Global cubic through four points (Newton form)
   ---------------------------------------------------------------------------

   function Interpolate_Four_Points
     (X0, Y0, X1, Y1, X2, Y2, X3, Y3 : Float;
      X                              : Float) return Eval_Result;
   --  Unique degree-≤3 interpolant through four distinct abscissae
   --  (Newton divided differences). Duplicate_Abscissa if any pair of
   --  x_i coincides within Distinct_Tol. No domain clamp (global poly).

   function Interpolate_Four_Points
     (X_Data : Abscissae; Y_Data : Ordinates; X : Float) return Eval_Result;
   --  Requires Length = 4 and matching bounds; else Ill_Started /
   --  Too_Few_Points / Duplicate_Abscissa.

   ---------------------------------------------------------------------------
   -- Thin piecewise cubic Hermite with FD tangents
   ---------------------------------------------------------------------------

   function Fit_FD
     (X : Abscissae; Y : Ordinates) return Fit_Result;
   --  Finite-difference tangents: m_0=δ_0, m_n=δ_{n−1},
   --  interior m_k=(δ_{k−1}+δ_k)/2. ≥ 2 points, strict ↑ X.
   --  May overshoot — see Ada-Hermite-Interpolation / Ada-Monotone-Cubic.

   function Evaluate_FD_Hermite
     (S : Hermite_Spline; X : Float) return Eval_Result;
   --  Piecewise cubic Hermite on the interval containing X.

   ---------------------------------------------------------------------------
   -- Builders / sample data
   ---------------------------------------------------------------------------

   function Make_Empty_Grid (N : Sample_Count) return Grid_1D
     with Pre => N >= 1 and then N <= Max_N, Global => null;
   --  Valid grid filled with zeros.

   function Make_Ramp_Grid
     (N : Sample_Count; Y0, Y1 : Float) return Grid_1D
     with Pre => N >= 1 and then N <= Max_N, Global => null;
   --  Values(i) = Y0 + (Y1−Y0)·i/(N−1)  (or Y0 if N=1).

   function Make_Known_Cubic_Grid
     (N : Sample_Count; X0, X1 : Float) return Grid_1D
     with Pre =>
       N >= 1 and then N <= Max_N and then X1 > X0,
          Global => null;
   --  Sample p(t)=t³−2t²+t on equally spaced t ∈ [X0,X1] mapped to
   --  lattice sites 0 .. N−1 (Values(i)=p(t_i)). For Catmull–Rom node
   --  tests use N≥4; the global four-point path uses Make_Known_Cubic_Four.

   function Make_Sine_Grid
     (N : Sample_Count; X0, X1 : Float) return Grid_1D
     with Pre =>
       N >= 1 and then N <= Max_N and then X1 > X0,
          Global => null;
   --  Values(i) = sin(t_i), t equally spaced in [X0,X1].

   --  Four sample points of p(x)=x³−2x²+x at equally spaced knots in [X0,X1].
   procedure Make_Known_Cubic_Four
     (X0, X1 : Float;
      Xs     : out Abscissae;
      Ys     : out Ordinates)
     with Pre =>
       X1 > X0
       and then Xs'Length = 4
       and then Ys'Length = 4
       and then Xs'First = Ys'First;

   function Make_Example_Grid (Kind : Example_Kind) return Grid_1D
     with Global => null;
   --  Linear_Ramp : 8 pts of y from 0 to 7 (Values(i)=i)
   --  Known_Cubic : 9 pts of t³−2t²+t on [0,2]
   --  Sine_Sample : 9 pts sin on [0, π]

   function Make_Example_FD (Kind : Example_Kind) return Fit_Result
     with Global => null;
   --  Same flavours as sorted Sample / Hermite-FD tables (strict ↑ x).

end Cubic_Interpolation;
