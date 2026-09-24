--  Monotone_Cubic_Interpolation — Ada 2023 educational package for Wikipedia
--  "Monotone cubic interpolation": cubic Hermite spline with tangents m_i
--  chosen by the Fritsch–Carlson method so that strictly monotone data
--  yield a monotone interpolant. Cap n ≤ 64 points; educational Float.
--  Also piecewise linear and plain (non-monotone) finite-difference Hermite
--  for comparison. Strictly increasing abscissae required.
--  Primary source:
--  https://en.wikipedia.org/wiki/Monotone_cubic_interpolation
--  Siblings (README): Ada-Spline-Interpolation, Ada-Bicubic-Interpolation;
--  upcoming Linear / Lagrange / Hermite / Cubic / Birkhoff.

pragma Ada_2022;

package Monotone_Cubic_Interpolation
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types (educational Float)
   ---------------------------------------------------------------------------

   --  At most Max_Points knots (indices 0 .. N with N+1 ≤ Max_Points).
   Max_Points : constant := 64;

   subtype Point_Count is Natural range 0 .. Max_Points;
   subtype Point_Index is Natural range 0 .. Max_Points - 1;

   type Point is record
      X, Y : Float := 0.0;
   end record;

   --  0-based abscissae / ordinates / packed points / tangents.
   type Abscissae is array (Point_Index range <>) of Float;
   type Ordinates is array (Point_Index range <>) of Float;
   type Tangents  is array (Point_Index range <>) of Float;
   type Points    is array (Point_Index range <>) of Point;

   --  Ok                      : fit / evaluation succeeded
   --  Not_Strictly_Increasing : x_i not strictly increasing
   --  Too_Few_Points          : fewer than 2 points
   --  Out_Of_Domain           : X outside [x_0, x_n]
   --  Ill_Started             : empty / mismatched / over Max / invalid spline
   type Status is
     (Ok,
      Not_Strictly_Increasing,
      Too_Few_Points,
      Out_Of_Domain,
      Ill_Started);

   type Spline_Kind is
     (Monotone_Cubic,
      Finite_Difference_Hermite,
      Linear);

   --  Fitted spline: knots X(0..N), Y(0..N), tangents M(0..N).
   type Spline is record
      Kind  : Spline_Kind := Monotone_Cubic;
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
     (Linear_Data,
      Increasing_Ramp,
      Sigmoid_Sample,
      Non_Monotone_Sample);

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

   function Lerp (A, B : Float; T : Float) return Float
     with Global => null;
   --  (1−t) A + t B

   function Make_Point (X, Y : Float) return Point
     with Global => null;

   --  Cubic Hermite basis on t ∈ [0,1]:
   --  h00 = 2t³−3t²+1, h10 = t³−2t²+t, h01 = −2t³+3t², h11 = t³−t².
   function H00 (T : Float) return Float with Global => null;
   function H10 (T : Float) return Float with Global => null;
   function H01 (T : Float) return Float with Global => null;
   function H11 (T : Float) return Float with Global => null;

   ---------------------------------------------------------------------------
   -- Validation / domain / monotonicity
   ---------------------------------------------------------------------------

   function Is_Strictly_Increasing (X : Abscissae) return Boolean
     with Global => null;

   --  True iff Y is monotone non-decreasing or monotone non-increasing.
   function Is_Monotone_Samples (Y : Ordinates) return Boolean
     with Global => null;

   function Is_Monotone_Samples (P : Points) return Boolean
     with Global => null;

   function In_Domain (S : Spline; X : Float) return Boolean
     with Global => null;
   --  True iff Valid and X ∈ [S.X(0), S.X(S.N)]

   function Find_Interval (S : Spline; X : Float) return Natural
     with Pre => S.Valid and then S.N >= 1, Global => null;
   --  Largest i with S.X(i) ≤ X ≤ S.X(S.N); right endpoint → N−1.

   ---------------------------------------------------------------------------
   -- Fitters
   ---------------------------------------------------------------------------

   function Fit
     (X : Abscissae; Y : Ordinates) return Fit_Result;
   --  Fritsch–Carlson monotone cubic Hermite. ≥ 2 points, strict ↑ X.

   function Fit (P : Points) return Fit_Result;

   function Fit_Monotone
     (X : Abscissae; Y : Ordinates) return Fit_Result;
   --  Alias of Fit (explicit name).

   function Fit_Monotone (P : Points) return Fit_Result;

   function Fit_Hermite_FD
     (X : Abscissae; Y : Ordinates) return Fit_Result;
   --  Cubic Hermite with finite-difference tangents (no FC restrict).
   --  May overshoot on monotone data; educational contrast.

   function Fit_Hermite_FD (P : Points) return Fit_Result;

   function Fit_Linear (X : Abscissae; Y : Ordinates) return Fit_Result;
   --  Piecewise linear; ≥ 2 points. Tangents unused (0).

   function Fit_Linear (P : Points) return Fit_Result;

   ---------------------------------------------------------------------------
   -- Evaluation
   ---------------------------------------------------------------------------

   function Evaluate (S : Spline; X : Float) return Eval_Result;
   --  Hermite cubic (or lerp) on the interval containing X; OOD outside.

   ---------------------------------------------------------------------------
   -- Builders / sample data
   ---------------------------------------------------------------------------

   function Make_Linear_Data
     (N : Point_Count; X0, X1, Y0, Y1 : Float) return Points
     with Pre =>
       N >= 2 and then N <= Max_Points and then X1 > X0,
          Global => null;
   --  Equally spaced x; y on the line through (X0,Y0)–(X1,Y1).

   function Make_Increasing_Ramp
     (N : Point_Count; X0, X1, Y0, Y1 : Float) return Points
     with Pre =>
       N >= 2 and then N <= Max_Points and then X1 > X0
       and then Y1 > Y0,
          Global => null;
   --  Strictly increasing y: linear ramp (same as Make_Linear_Data when
   --  Y1 > Y0); alias kept for API clarity in monotone tests.

   function Make_Sigmoid_Sample
     (N : Point_Count; X0, X1 : Float) return Points
     with Pre =>
       N >= 2 and then N <= Max_Points and then X1 > X0,
          Global => null;
   --  Strictly increasing sigmoid-ish: y = 1/(1+e^{−4(2u−1)}), u∈[0,1].

   function Make_Non_Monotone_Sample
     (N : Point_Count; X0, X1 : Float) return Points
     with Pre =>
       N >= 3 and then N <= Max_Points and then X1 > X0,
          Global => null;
   --  y = sin(2π u) on [X0,X1]; not monotone (fit still works; extrema
   --  flatten under Fritsch–Carlson).

   function Make_Example (Kind : Example_Kind) return Points
     with Global => null;
   --  Linear_Data          : 5 pts on y = 2x+1, x ∈ [0,4]
   --  Increasing_Ramp      : 8 pts ramp y: 0→1 on [0,1]
   --  Sigmoid_Sample       : 9 pts sigmoid-ish on [−2,2]
   --  Non_Monotone_Sample  : 9 pts sin wave on [0,1]

   procedure Split_XY
     (P : Points; X : out Abscissae; Y : out Ordinates)
     with Pre =>
       P'Length >= 1
       and then X'Length = P'Length
       and then Y'Length = P'Length
       and then X'First = P'First
       and then Y'First = P'First;

end Monotone_Cubic_Interpolation;
