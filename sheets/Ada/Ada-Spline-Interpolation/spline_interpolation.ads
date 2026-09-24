--  Spline_Interpolation — Ada 2023 educational package for Wikipedia
--  "Spline interpolation": classic natural cubic spline through points
--  (x_i, y_i) with strictly increasing x; Thomas solve for second
--  derivatives M_i; piecewise cubic evaluation. Cap n ≤ 32 points;
--  educational Float. Optional clamped cubic, linear / quadratic baselines.
--  Primary source:
--  https://en.wikipedia.org/wiki/Spline_interpolation
--  Siblings (README): Ada-De-Boor, Ada-De-Casteljau, upcoming Neville,
--  Polynomial interpolation.

pragma Ada_2022;

package Spline_Interpolation
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types (educational Float)
   ---------------------------------------------------------------------------

   --  At most Max_Points knots (indices 0 .. N with N+1 ≤ Max_Points).
   Max_Points : constant := 32;

   subtype Point_Count is Natural range 0 .. Max_Points;
   subtype Point_Index is Natural range 0 .. Max_Points - 1;

   type Point is record
      X, Y : Float := 0.0;
   end record;

   --  0-based abscissae / ordinates / packed points.
   type Abscissae is array (Point_Index range <>) of Float;
   type Ordinates is array (Point_Index range <>) of Float;
   type Points    is array (Point_Index range <>) of Point;

   --  Ok                      : fit / evaluation succeeded
   --  Not_Strictly_Increasing : x_i not strictly increasing
   --  Too_Few_Points          : fewer than required for the kind
   --  Dimension_Error         : empty / mismatched lengths / over Max
   --  Singular                : Thomas pivot vanished (ill-conditioned)
   --  Ill_Started             : internal setup could not proceed
   --  Out_Of_Domain           : X outside [x_0, x_n]
   type Status is
     (Ok,
      Not_Strictly_Increasing,
      Too_Few_Points,
      Dimension_Error,
      Singular,
      Ill_Started,
      Out_Of_Domain);

   type Spline_Kind is
     (Natural_Cubic,
      Clamped_Cubic,
      Linear,
      Quadratic);

   --  Fitted spline: knots X(0..N), Y(0..N), second derivatives M(0..N)
   --  for cubics (unused / zero for linear). Clamped stores YP0, YPN.
   type Spline is record
      Kind  : Spline_Kind := Natural_Cubic;
      N     : Natural := 0;  -- last index; Num_Points = N + 1
      X     : Abscissae (0 .. Max_Points - 1) := [others => 0.0];
      Y     : Ordinates (0 .. Max_Points - 1) := [others => 0.0];
      M     : Ordinates (0 .. Max_Points - 1) := [others => 0.0];
      YP0   : Float := 0.0;  -- clamped left end derivative
      YPN   : Float := 0.0;  -- clamped right end derivative
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
      Quadratic_Sample,
      Sine_Sample,
      Uneven_Cubic);

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
   -- Thomas algorithm (self-contained tridiagonal solver)
   ---------------------------------------------------------------------------

   --  Solve a_i x_{i-1} + b_i x_i + c_i x_{i+1} = d_i for i = 1 .. M,
   --  with a_1 and c_M unused (set 0). Arrays indexed 1 .. M.
   --  On success writes solution into X(1 .. M); Stat = Ok / Singular.
   procedure Thomas
     (A, B, C, D : in     Ordinates;
      X          :    out Ordinates;
      Stat       :    out Status)
     with Pre =>
       A'First = 1 and then B'First = 1 and then C'First = 1
       and then D'First = 1 and then X'First = 1
       and then A'Last = B'Last and then B'Last = C'Last
       and then C'Last = D'Last and then D'Last = X'Last
       and then A'Last >= 1
       and then A'Last <= Max_Points;

   ---------------------------------------------------------------------------
   -- Fitters
   ---------------------------------------------------------------------------

   function Fit_Natural_Cubic
     (X : Abscissae; Y : Ordinates) return Fit_Result;
   --  Natural: M_0 = M_n = 0. Needs ≥ 2 points, strictly increasing X.

   function Fit_Natural_Cubic (P : Points) return Fit_Result;

   function Fit_Clamped_Cubic
     (X          : Abscissae;
      Y          : Ordinates;
      Left_Deriv : Float;
      Right_Deriv : Float) return Fit_Result;
   --  Clamped: S'(x_0)=Left_Deriv, S'(x_n)=Right_Deriv. ≥ 2 points.

   function Fit_Clamped_Cubic
     (P           : Points;
      Left_Deriv  : Float;
      Right_Deriv : Float) return Fit_Result;

   function Fit_Linear (X : Abscissae; Y : Ordinates) return Fit_Result;
   --  Piecewise linear; ≥ 2 points.

   function Fit_Linear (P : Points) return Fit_Result;

   function Fit_Quadratic (X : Abscissae; Y : Ordinates) return Fit_Result;
   --  Local quadratic on triples; educational baseline; ≥ 3 points.

   function Fit_Quadratic (P : Points) return Fit_Result;

   ---------------------------------------------------------------------------
   -- Evaluation
   ---------------------------------------------------------------------------

   function Evaluate (S : Spline; X : Float) return Eval_Result;
   --  Piecewise form on the interval containing X; Out_Of_Domain outside.

   ---------------------------------------------------------------------------
   -- Builders / sample data
   ---------------------------------------------------------------------------

   function Make_Linear_Data
     (N : Point_Count; X0, X1, Y0, Y1 : Float) return Points
     with Pre =>
       N >= 2 and then N <= Max_Points and then X1 > X0,
          Global => null;
   --  Equally spaced x; y on the line through (X0,Y0)–(X1,Y1).

   function Make_Quadratic_Sample
     (N : Point_Count; X0, X1 : Float) return Points
     with Pre =>
       N >= 2 and then N <= Max_Points and then X1 > X0,
          Global => null;
   --  y = x² on [X0, X1].

   function Make_Sine_Sample
     (N : Point_Count; X0, X1 : Float) return Points
     with Pre =>
       N >= 2 and then N <= Max_Points and then X1 > X0,
          Global => null;
   --  y = sin(x) on [X0, X1].

   function Make_Example (Kind : Example_Kind) return Points
     with Global => null;
   --  Linear_Data       : 5 pts on y = 2x + 1, x ∈ [0,4]
   --  Quadratic_Sample  : 6 pts y = x² on [−1,1]
   --  Sine_Sample       : 8 pts y = sin(x) on [0, π]
   --  Uneven_Cubic      : 5 uneven knots with cubic-looking y

   procedure Split_XY
     (P : Points; X : out Abscissae; Y : out Ordinates)
     with Pre =>
       P'Length >= 1
       and then X'Length = P'Length
       and then Y'Length = P'Length
       and then X'First = P'First
       and then Y'First = P'First;

end Spline_Interpolation;
