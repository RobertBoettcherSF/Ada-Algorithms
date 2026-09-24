--  De_Casteljau — Ada 2023 educational package for Wikipedia
--  "De Casteljau's algorithm": evaluate / subdivide Bézier curves via
--  recursive linear interpolation of control points (Bernstein form).
--  Cap degree n ≤ 16; educational Float; 1-D / 2-D / 3-D.
--  Primary source:
--  https://en.wikipedia.org/wiki/De_Casteljau%27s_algorithm
--  Siblings (README): upcoming De Boor, Spline interpolation, Neville,
--  Polynomial interpolation.

pragma Ada_2022;

package De_Casteljau
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types (educational Float)
   ---------------------------------------------------------------------------

   --  Degree n means n+1 control points. Cap n ≤ Max_Degree.
   Max_Degree   : constant := 16;
   Max_Controls : constant := Max_Degree + 1;

   subtype Degree_Range is Natural range 0 .. Max_Degree;
   subtype Control_Count is Natural range 0 .. Max_Controls;
   subtype Control_Index is Natural range 0 .. Max_Degree;

   type Point_2D is record
      X, Y : Float := 0.0;
   end record;

   type Point_3D is record
      X, Y, Z : Float := 0.0;
   end record;

   --  Control polygons: 0-based indices matching P_0 .. P_n.
   type Controls_1D is array (Control_Index range <>) of Float;
   type Controls_2D is array (Control_Index range <>) of Point_2D;
   type Controls_3D is array (Control_Index range <>) of Point_3D;

   --  Ok            : evaluation / split succeeded (t typically in [0,1])
   --  Extrapolated  : succeeded but t was outside [0,1]
   --  Empty         : fewer than 1 control point
   --  Degree_Too_High : more than Max_Controls points
   --  Dimension_Error : mismatched lengths / bad builder args
   type Status is
     (Ok,
      Extrapolated,
      Empty,
      Degree_Too_High,
      Dimension_Error);

   type Eval_Result_1D is record
      Value   : Float := 0.0;
      Stat    : Status := Empty;
      Success : Boolean := False;
   end record;

   type Eval_Result_2D is record
      Point   : Point_2D := (0.0, 0.0);
      Stat    : Status := Empty;
      Success : Boolean := False;
   end record;

   type Eval_Result_3D is record
      Point   : Point_3D := (0.0, 0.0, 0.0);
      Stat    : Status := Empty;
      Success : Boolean := False;
   end record;

   --  Left / Right hold degree-n control polygons after split at t.
   --  Valid entries are Left (0 .. Degree) and Right (0 .. Degree).
   type Split_Result_1D is record
      Left    : Controls_1D (0 .. Max_Degree) := [others => 0.0];
      Right   : Controls_1D (0 .. Max_Degree) := [others => 0.0];
      Degree  : Degree_Range := 0;
      Stat    : Status := Empty;
      Success : Boolean := False;
   end record;

   type Split_Result_2D is record
      Left    : Controls_2D (0 .. Max_Degree) := [others => (0.0, 0.0)];
      Right   : Controls_2D (0 .. Max_Degree) := [others => (0.0, 0.0)];
      Degree  : Degree_Range := 0;
      Stat    : Status := Empty;
      Success : Boolean := False;
   end record;

   type Split_Result_3D is record
      Left    : Controls_3D (0 .. Max_Degree) :=
                  [others => (0.0, 0.0, 0.0)];
      Right   : Controls_3D (0 .. Max_Degree) :=
                  [others => (0.0, 0.0, 0.0)];
      Degree  : Degree_Range := 0;
      Stat    : Status := Empty;
      Success : Boolean := False;
   end record;

   type Example_Kind is
     (Line_Segment,
      Quadratic_Arch,
      Cubic_Unit_Square,
      Cubic_S_Curve);

   Invalid_Argument : exception;

   Epsilon_Tol : constant Float := 1.0E-6;
   Near_Tol    : constant Float := 1.0E-5;

   ---------------------------------------------------------------------------
   -- Numeric / geometry helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Float; Tol : Float := Near_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Near
     (A, B : Point_2D; Tol : Float := Near_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Near
     (A, B : Point_3D; Tol : Float := Near_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Dist (A, B : Point_2D) return Float
     with Global => null;

   function Dist (A, B : Point_3D) return Float
     with Global => null;

   function Lerp (A, B : Float; T : Float) return Float
     with Global => null;
   --  (1−t) A + t B

   function Lerp (A, B : Point_2D; T : Float) return Point_2D
     with Global => null;

   function Lerp (A, B : Point_3D; T : Float) return Point_3D
     with Global => null;

   function Add (A, B : Point_2D) return Point_2D
     with Global => null;

   function Sub (A, B : Point_2D) return Point_2D
     with Global => null;

   function Scale (A : Point_2D; S : Float) return Point_2D
     with Global => null;

   function Add (A, B : Point_3D) return Point_3D
     with Global => null;

   function Sub (A, B : Point_3D) return Point_3D
     with Global => null;

   function Scale (A : Point_3D; S : Float) return Point_3D
     with Global => null;

   function Degree_Of (C : Controls_1D) return Degree_Range
     with Pre => C'Length >= 1 and then C'Length <= Max_Controls,
          Global => null;

   function Degree_Of (C : Controls_2D) return Degree_Range
     with Pre => C'Length >= 1 and then C'Length <= Max_Controls,
          Global => null;

   function Degree_Of (C : Controls_3D) return Degree_Range
     with Pre => C'Length >= 1 and then C'Length <= Max_Controls,
          Global => null;

   function In_Unit_Interval (T : Float) return Boolean
     with Global => null;
   --  True iff T ∈ [0, 1]

   ---------------------------------------------------------------------------
   -- Bernstein basis (optional direct evaluation for tiny degrees)
   ---------------------------------------------------------------------------

   function Binomial (N, K : Natural) return Float
     with Pre => K <= N and then N <= Max_Degree, Global => null;
   --  C(N, K) as Float (exact for N ≤ 16 in Float mantissa).

   function Bernstein (I, N : Natural; T : Float) return Float
     with Pre => I <= N and then N <= Max_Degree, Global => null;
   --  b_{i,n}(t) = C(n,i) (1−t)^{n−i} t^i

   function Evaluate_Bernstein
     (Controls : Controls_1D; T : Float) return Eval_Result_1D;
   --  Direct ∑ P_i b_{i,n}(t). For cross-check vs De Casteljau.

   function Evaluate_Bernstein
     (Controls : Controls_2D; T : Float) return Eval_Result_2D;

   function Evaluate_Bernstein
     (Controls : Controls_3D; T : Float) return Eval_Result_3D;

   ---------------------------------------------------------------------------
   -- De Casteljau evaluation
   ---------------------------------------------------------------------------

   function Evaluate
     (Controls : Controls_1D; T : Float) return Eval_Result_1D;
   --  B(t) = P_0^{(n)} via the De Casteljau pyramid.

   function Evaluate
     (Controls : Controls_2D; T : Float) return Eval_Result_2D;

   function Evaluate
     (Controls : Controls_3D; T : Float) return Eval_Result_3D;

   ---------------------------------------------------------------------------
   -- Subdivision (split) at parameter t
   ---------------------------------------------------------------------------

   function Split
     (Controls : Controls_1D; T : Float) return Split_Result_1D;
   --  Left  = (P_0^{(0)}, P_0^{(1)}, …, P_0^{(n)})
   --  Right = (P_0^{(n)}, P_1^{(n−1)}, …, P_n^{(0)})

   function Split
     (Controls : Controls_2D; T : Float) return Split_Result_2D;

   function Split
     (Controls : Controls_3D; T : Float) return Split_Result_3D;

   ---------------------------------------------------------------------------
   -- Builders / canonical examples
   ---------------------------------------------------------------------------

   function Make_Point (X, Y : Float) return Point_2D
     with Global => null;

   function Make_Point (X, Y, Z : Float) return Point_3D
     with Global => null;

   function Make_Line_1D (A, B : Float) return Controls_1D
     with Global => null;
   --  Degree-1: P_0=A, P_1=B

   function Make_Line_2D (P0, P1 : Point_2D) return Controls_2D
     with Global => null;

   function Make_Line_3D (P0, P1 : Point_3D) return Controls_3D
     with Global => null;

   function Make_Quadratic_2D
     (P0, P1, P2 : Point_2D) return Controls_2D
     with Global => null;

   function Make_Cubic_2D
     (P0, P1, P2, P3 : Point_2D) return Controls_2D
     with Global => null;

   function Make_Cubic_3D
     (P0, P1, P2, P3 : Point_3D) return Controls_3D
     with Global => null;

   function Make_Example_2D (Kind : Example_Kind) return Controls_2D
     with Global => null;
   --  Line_Segment      : (0,0) → (1,0)
   --  Quadratic_Arch    : (0,0), (0.5,1), (1,0)
   --  Cubic_Unit_Square : (0,0), (0,1), (1,1), (1,0)
   --  Cubic_S_Curve     : (0,0), (1,0), (0,1), (1,1)

   function Make_Example_1D (Kind : Example_Kind) return Controls_1D
     with Global => null;
   --  Scalar analogues (X coords of the 2-D examples, or simple ramps).

end De_Casteljau;
