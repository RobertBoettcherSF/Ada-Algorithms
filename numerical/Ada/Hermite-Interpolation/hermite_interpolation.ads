--  Hermite_Interpolation — Ada 2023 educational package for Wikipedia
--  "Hermite interpolation": piecewise cubic Hermite matching values y_i and
--  tangents m_i at strictly increasing knots; evaluate with basis
--  H00, H10, H01, H11. Tangents may be user-supplied or estimated by
--  finite differences (may overshoot — contrast Ada-Monotone-Cubic-
--  Interpolation / Fritsch–Carlson). Two-point endpoint matching yields
--  the unique cubic on an interval. Optional small osculatory / Newton
--  confluent sketch matches value+first derivative at several nodes
--  (global polynomial, keep n small). Cap n ≤ 32 points; educational Float.
--  Primary source:
--  https://en.wikipedia.org/wiki/Hermite_interpolation
--  Siblings (README): Ada-Monotone-Cubic-Interpolation,
--  Ada-Lagrange-Interpolation, Ada-Spline-Interpolation;
--  upcoming Cubic / Birkhoff.

pragma Ada_2022;

package Hermite_Interpolation
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types (educational Float)
   ---------------------------------------------------------------------------

   --  At most Max_Points knots (indices 0 .. N with N+1 ≤ Max_Points).
   Max_Points : constant := 32;

   --  Osculatory / Newton confluent: value + first derivative at each node
   --  → degree ≤ 2n+1. Keep small for Float stability.
   Max_Osculatory_Nodes : constant := 8;

   subtype Point_Count is Natural range 0 .. Max_Points;
   subtype Point_Index is Natural range 0 .. Max_Points - 1;
   subtype Osc_Count   is Natural range 0 .. Max_Osculatory_Nodes;
   subtype Osc_Index   is Natural range 0 .. Max_Osculatory_Nodes - 1;

   type Point is record
      X, Y : Float := 0.0;
   end record;

   --  0-based abscissae / ordinates / tangents / packed points.
   type Abscissae is array (Point_Index range <>) of Float;
   type Ordinates is array (Point_Index range <>) of Float;
   type Tangents  is array (Point_Index range <>) of Float;
   type Points    is array (Point_Index range <>) of Point;

   --  Ok                      : fit / evaluation succeeded
   --  Not_Strictly_Increasing : x_i not strictly increasing
   --  Too_Few_Points          : fewer than 2 points (or osculatory min)
   --  Out_Of_Domain           : X outside [x_0, x_n] (piecewise Evaluate)
   --  Ill_Started             : empty / invalid spline / setup failed
   --  Dimension_Error         : mismatched lengths / over Max / bad osc n
   type Status is
     (Ok,
      Not_Strictly_Increasing,
      Too_Few_Points,
      Out_Of_Domain,
      Ill_Started,
      Dimension_Error);

   type Fit_Kind is
     (User_Tangents,
      Finite_Difference,
      Two_Point);

   --  Fitted piecewise cubic Hermite: knots X(0..N), Y(0..N), M(0..N).
   type Spline is record
      Kind  : Fit_Kind := User_Tangents;
      N     : Natural := 0;  -- last index; Num_Points = N + 1
      X     : Abscissae (0 .. Max_Points - 1) := [others => 0.0];
      Y     : Ordinates (0 .. Max_Points - 1) := [others => 0.0];
      M     : Tangents  (0 .. Max_Points - 1) := [others => 0.0];
      Valid : Boolean := False;
   end record;

   type Fit_Result is record
      S       : Spline;
      Stat    : Status := Ill_Started;
      Success : Boolean := False;
   end record;

   type Eval_Result is record
      Value   : Float := 0.0;
      Stat    : Status := Ill_Started;
      Success : Boolean := False;
   end record;

   type Example_Kind is
     (Known_Cubic,
      Sine_Sample,
      Linear_Ramp);

   Invalid_Argument : exception;

   Epsilon_Tol : constant Float := 1.0E-6;
   Near_Tol    : constant Float := 1.0E-5;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Float; Tol : Float := Near_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Near (A, B : Point; Tol : Float := Near_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Make_Point (X, Y : Float) return Point
     with Global => null;

   --  Cubic Hermite basis on t ∈ [0,1]:
   --  h00 = 2t³−3t²+1, h10 = t³−2t²+t, h01 = −2t³+3t², h11 = t³−t².
   function H00 (T : Float) return Float with Global => null;
   function H10 (T : Float) return Float with Global => null;
   function H01 (T : Float) return Float with Global => null;
   function H11 (T : Float) return Float with Global => null;

   ---------------------------------------------------------------------------
   -- Validation / domain
   ---------------------------------------------------------------------------

   function Is_Strictly_Increasing (X : Abscissae) return Boolean
     with Global => null;

   function In_Domain (S : Spline; X : Float) return Boolean
     with Global => null;
   --  True iff Valid and X ∈ [S.X(0), S.X(S.N)]

   function Find_Interval (S : Spline; X : Float) return Natural
     with Pre => S.Valid and then S.N >= 1, Global => null;
   --  Largest i with S.X(i) ≤ X ≤ S.X(S.N); right endpoint → N−1.

   ---------------------------------------------------------------------------
   -- Single-interval cubic Hermite
   ---------------------------------------------------------------------------

   function Evaluate_Cubic_Interval
     (X0, Y0, M0 : Float;
      X1, Y1, M1 : Float;
      X          : Float) return Eval_Result;
   --  Unique cubic matching (Y0,M0) at X0 and (Y1,M1) at X1.
   --  Out_Of_Domain if X outside [X0,X1] (requires X1 > X0);
   --  Dimension_Error if X1 ≤ X0.

   ---------------------------------------------------------------------------
   -- Fitters (piecewise cubic Hermite)
   ---------------------------------------------------------------------------

   function Fit
     (X : Abscissae; Y : Ordinates; M : Tangents) return Fit_Result;
   --  User-supplied tangents. ≥ 2 points, equal lengths, strict ↑ X.

   function Fit (P : Points; M : Tangents) return Fit_Result;

   function Fit_FD
     (X : Abscissae; Y : Ordinates) return Fit_Result;
   --  Finite-difference tangents: m_0=δ_0, m_n=δ_{n−1},
   --  interior m_k=(δ_{k−1}+δ_k)/2. May overshoot (no FC restrict).

   function Fit_FD (P : Points) return Fit_Result;

   function Fit_Two_Point
     (X0, Y0, M0 : Float;
      X1, Y1, M1 : Float) return Fit_Result;
   --  Two-knot spline: unique cubic on [X0,X1]. Requires X1 > X0.

   ---------------------------------------------------------------------------
   -- Evaluation (piecewise)
   ---------------------------------------------------------------------------

   function Evaluate (S : Spline; X : Float) return Eval_Result;
   --  Hermite cubic on the interval containing X; OOD outside [x_0,x_n].

   ---------------------------------------------------------------------------
   -- Osculatory / Newton confluent (global; small n)
   ---------------------------------------------------------------------------

   function Evaluate_Osculatory
     (X_Data : Abscissae;
      Y_Data : Ordinates;
      M_Data : Tangents;
      X      : Float) return Eval_Result;
   --  Newton form with confluent divided differences matching y_i and
   --  y'_i = m_i at each distinct node (degree ≤ 2n+1).
   --  1 .. Max_Osculatory_Nodes points; no domain clamp (global poly).

   ---------------------------------------------------------------------------
   -- Builders / sample data
   ---------------------------------------------------------------------------

   function Make_Known_Cubic
     (N : Point_Count; X0, X1 : Float) return Fit_Result
     with Pre =>
       N >= 2 and then N <= Max_Points and then X1 > X0;
   --  Sample p(x)=x³−2x²+x on [X0,X1] with analytic p'=3x²−4x+1;
   --  Fit with user tangents (exact cubic recovered for any ≥ 2 knots).

   function Make_Sine_Sample
     (N : Point_Count; X0, X1 : Float) return Fit_Result
     with Pre =>
       N >= 2 and then N <= Max_Points and then X1 > X0;
   --  y=sin(x), m=cos(x) on equally spaced knots in [X0,X1].

   function Make_Linear_Ramp
     (N : Point_Count; X0, X1, Y0, Y1 : Float) return Fit_Result
     with Pre =>
       N >= 2 and then N <= Max_Points and then X1 > X0;
   --  Linear y; constant tangent (Y1−Y0)/(X1−X0).

   function Make_Example (Kind : Example_Kind) return Fit_Result
     with Global => null;
   --  Known_Cubic  : 5 pts of x³−2x²+x on [0,2]
   --  Sine_Sample  : 9 pts sin on [0, π]
   --  Linear_Ramp  : 6 pts y=2x+1 on [0,5]

   procedure Split_XY
     (P : Points; X : out Abscissae; Y : out Ordinates)
     with Pre =>
       P'Length >= 1
       and then X'Length = P'Length
       and then Y'Length = P'Length
       and then X'First = P'First
       and then Y'First = P'First;

end Hermite_Interpolation;
