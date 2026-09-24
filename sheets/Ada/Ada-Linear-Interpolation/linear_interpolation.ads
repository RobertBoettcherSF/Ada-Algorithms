--  Linear_Interpolation — Ada 2023 educational package for Wikipedia
--  "Linear interpolation" (lerp): two-point straight-line interpolant,
--  piecewise-linear tables on sorted abscissae, optional extrapolation,
--  and inverse lerp when ordinates are strictly monotone. Cap n ≤ 64
--  points; educational Float.
--  Primary source:
--  https://en.wikipedia.org/wiki/Linear_interpolation
--  Siblings (README): Ada-Bilinear-Interpolation,
--  Ada-Monotone-Cubic-Interpolation, Ada-Spline-Interpolation;
--  upcoming Lagrange / Hermite / Cubic / Birkhoff.

pragma Ada_2022;

package Linear_Interpolation
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

   --  0-based abscissae / ordinates / packed points.
   type Abscissae is array (Point_Index range <>) of Float;
   type Ordinates is array (Point_Index range <>) of Float;
   type Points    is array (Point_Index range <>) of Point;

   --  Ok                     : fit / evaluation succeeded
   --  Duplicate_Or_Unordered : x_i not strictly increasing
   --  Too_Few_Points         : fewer than 2 points
   --  Out_Of_Domain          : query outside [x_0, x_n] (no extrapolation)
   --  Ill_Started            : empty / mismatched / over Max / invalid table
   --  Singular               : coincident abscissae (two-point) or a = b
   --                           (inverse lerp) / non-monotone Y (inverse table)
   type Status is
     (Ok,
      Duplicate_Or_Unordered,
      Too_Few_Points,
      Out_Of_Domain,
      Ill_Started,
      Singular);

   --  Fitted piecewise-linear table: knots X(0..N), Y(0..N).
   type Table is record
      N            : Natural := 0;  -- last index; Num_Points = N + 1
      X            : Abscissae (0 .. Max_Points - 1) := [others => 0.0];
      Y            : Ordinates (0 .. Max_Points - 1) := [others => 0.0];
      Extrapolate  : Boolean := False;
      Valid        : Boolean := False;
   end record;

   type Fit_Result is record
      T       : Table;
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
      Decreasing_Ramp,
      Quadratic_Sample);

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

   --  Clamped lerp: t ← clamp(t, 0, 1), then (1−t) A + t B.
   function Lerp (A, B : Float; T : Float) return Float
     with Global => null;

   --  Unclamped: L(t) = (1−t) A + t B for any t (extrapolation OK).
   function Lerp_Unclamped (A, B : Float; T : Float) return Float
     with Global => null;

   --  Inverse of Lerp_Unclamped: t = (V−A)/(B−A). Singular if A = B.
   function Inverse_Lerp (A, B, V : Float) return Eval_Result
     with Global => null;

   --  Two known points → y at x:
   --    y = y0 + (x−x0)·(y1−y0)/(x1−x0)
   --  Singular if x0 = x1. Does not clamp x (full-line extrapolation).
   function Interpolate_Two_Points
     (X0, Y0, X1, Y1, X : Float) return Eval_Result
     with Global => null;

   ---------------------------------------------------------------------------
   -- Validation / domain / monotonicity
   ---------------------------------------------------------------------------

   function Is_Strictly_Increasing (X : Abscissae) return Boolean
     with Global => null;

   --  True iff Y is strictly increasing or strictly decreasing.
   function Is_Strictly_Monotone (Y : Ordinates) return Boolean
     with Global => null;

   function Is_Strictly_Monotone (P : Points) return Boolean
     with Global => null;

   function In_Domain (T : Table; X : Float) return Boolean
     with Global => null;
   --  True iff Valid and X ∈ [T.X(0), T.X(T.N)]

   function Find_Interval (T : Table; X : Float) return Natural
     with Pre => T.Valid and then T.N >= 1, Global => null;
   --  Largest i with T.X(i) ≤ X ≤ T.X(T.N); right endpoint → N−1.
   --  Outside domain (extrapolation): returns 0 if X < X(0), N−1 if X > X(N).

   ---------------------------------------------------------------------------
   -- Fitters
   ---------------------------------------------------------------------------

   function Fit
     (X            : Abscissae;
      Y            : Ordinates;
      Extrapolate  : Boolean := False) return Fit_Result;
   --  Piecewise linear; ≥ 2 points, strictly increasing X.

   function Fit
     (P            : Points;
      Extrapolate  : Boolean := False) return Fit_Result;

   ---------------------------------------------------------------------------
   -- Evaluation
   ---------------------------------------------------------------------------

   function Evaluate (T : Table; X : Float) return Eval_Result;
   --  Piecewise lerp on the interval containing X. Outside [x0,xn]:
   --  extrapolate on the end segment if T.Extrapolate, else Out_Of_Domain.

   --  Inverse: find X such that Evaluate(T, X) ≈ Y, when Y is strictly
   --  monotone on the table. Uses the Y-interval containing the query and
   --  Inverse_Lerp on that segment. Outside Y-range: extrapolate iff
   --  T.Extrapolate, else Out_Of_Domain. Singular if Y not strictly monotone.
   function Inverse_Evaluate (T : Table; Y : Float) return Eval_Result;

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
   --  Strictly increasing y ramp (same geometry as Make_Linear_Data).

   function Make_Decreasing_Ramp
     (N : Point_Count; X0, X1, Y0, Y1 : Float) return Points
     with Pre =>
       N >= 2 and then N <= Max_Points and then X1 > X0
       and then Y1 < Y0,
          Global => null;
   --  Strictly decreasing y ramp.

   function Make_Quadratic_Sample
     (N : Point_Count; X0, X1 : Float) return Points
     with Pre =>
       N >= 2 and then N <= Max_Points and then X1 > X0,
          Global => null;
   --  y = u² on [X0,X1] with u ∈ [0,1] mapped from x (teaching sample).

   function Make_Example (Kind : Example_Kind) return Points
     with Global => null;
   --  Linear_Data       : 5 pts on y = 2x+1, x ∈ [0,4]
   --  Increasing_Ramp   : 8 pts ramp y: 0→1 on [0,1]
   --  Decreasing_Ramp   : 6 pts ramp y: 10→0 on [0,5]
   --  Quadratic_Sample  : 9 pts y = u² on [0,1]

   procedure Split_XY
     (P : Points; X : out Abscissae; Y : out Ordinates)
     with Pre =>
       P'Length >= 1
       and then X'Length = P'Length
       and then Y'Length = P'Length
       and then X'First = P'First
       and then Y'First = P'First;

end Linear_Interpolation;
