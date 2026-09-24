--  De_Boor — Ada 2023 educational package for Wikipedia
--  "De Boor's algorithm": evaluate B-spline curves via the triangular
--  scheme that generalizes De Casteljau (local support, knot spans).
--  Cap degree p ≤ 8; Max_Controls ≤ 32; educational Float; 1-D / 2-D / 3-D.
--  Primary source:
--  https://en.wikipedia.org/wiki/De_Boor_algorithm
--  Siblings (README): Ada-De-Casteljau, upcoming Spline interpolation,
--  Neville, Polynomial interpolation.

pragma Ada_2022;

package De_Boor
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types (educational Float)
   ---------------------------------------------------------------------------

   Max_Degree   : constant := 8;
   Max_Controls : constant := 32;
   --  Knots length = Num_Controls + Degree + 1 (indices 0 .. n+p+1).
   Max_Knots    : constant := Max_Controls + Max_Degree + 1;

   subtype Degree_Range is Natural range 0 .. Max_Degree;
   subtype Control_Count is Natural range 0 .. Max_Controls;
   subtype Control_Index is Natural range 0 .. Max_Controls - 1;
   subtype Knot_Index is Natural range 0 .. Max_Knots - 1;

   type Point_2D is record
      X, Y : Float := 0.0;
   end record;

   type Point_3D is record
      X, Y, Z : Float := 0.0;
   end record;

   --  Control polygons and knot vectors: 0-based indices.
   type Controls_1D is array (Control_Index range <>) of Float;
   type Controls_2D is array (Control_Index range <>) of Point_2D;
   type Controls_3D is array (Control_Index range <>) of Point_3D;
   type Knot_Vector is array (Knot_Index range <>) of Float;

   --  Ok             : evaluation succeeded, X in domain [t_p, t_{n+1}]
   --  Out_Of_Domain  : X outside the open/clamped parameter domain
   --  Invalid_Knots  : non-monotone / wrong length / bad multiplicities
   --  Dimension_Error: empty / too many controls, or builder arg mismatch
   --  Ill_Started    : span / local support could not be established
   type Status is
     (Ok,
      Out_Of_Domain,
      Invalid_Knots,
      Dimension_Error,
      Ill_Started);

   type Eval_Result_1D is record
      Value   : Float := 0.0;
      Stat    : Status := Dimension_Error;
      Success : Boolean := False;
   end record;

   type Eval_Result_2D is record
      Point   : Point_2D := (0.0, 0.0);
      Stat    : Status := Dimension_Error;
      Success : Boolean := False;
   end record;

   type Eval_Result_3D is record
      Point   : Point_3D := (0.0, 0.0, 0.0);
      Stat    : Status := Dimension_Error;
      Success : Boolean := False;
   end record;

   type Span_Result is record
      Index   : Natural := 0;
      Stat    : Status := Ill_Started;
      Success : Boolean := False;
   end record;

   type Example_Kind is
     (Linear_Ramp,
      Cubic_Bezier_Unit,
      Uniform_Quadratic,
      Clamped_Cubic);

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

   function Make_Point (X, Y : Float) return Point_2D
     with Global => null;

   function Make_Point (X, Y, Z : Float) return Point_3D
     with Global => null;

   ---------------------------------------------------------------------------
   -- Knot / domain helpers
   ---------------------------------------------------------------------------

   function Expected_Knot_Count
     (Num_Controls : Control_Count; Degree : Degree_Range) return Natural
     with Pre => Num_Controls >= 1,
          Global => null;
   --  Num_Controls + Degree + 1  (= n+p+2 with n = Num_Controls−1)

   function Is_Valid_Knots
     (Knots        : Knot_Vector;
      Degree       : Degree_Range;
      Num_Controls : Control_Count) return Boolean
     with Global => null;
   --  Nondecreasing; length = Expected_Knot_Count; interior mult ≤ Degree;
   --  end multiplicities ≤ Degree+1.

   function Domain_Low
     (Knots : Knot_Vector; Degree : Degree_Range) return Float
     with Pre => Knots'Length > Degree, Global => null;
   --  t_p for a standard indexing Knots(0 .. m)

   function Domain_High
     (Knots        : Knot_Vector;
      Degree       : Degree_Range;
      Num_Controls : Control_Count) return Float
     with Pre =>
       Num_Controls >= 1
       and then Knots'Length >= Num_Controls + Degree + 1,
          Global => null;
   --  t_{n+1} with n = Num_Controls−1

   function In_Domain
     (Knots        : Knot_Vector;
      Degree       : Degree_Range;
      Num_Controls : Control_Count;
      X            : Float) return Boolean
     with Global => null;

   function Find_Span
     (Knots        : Knot_Vector;
      Degree       : Degree_Range;
      Num_Controls : Control_Count;
      X            : Float) return Span_Result;
   --  Index k with X ∈ [t_k, t_{k+1}); at right endpoint returns n.

   ---------------------------------------------------------------------------
   -- De Boor evaluation
   ---------------------------------------------------------------------------

   function Evaluate
     (Controls : Controls_1D;
      Knots    : Knot_Vector;
      Degree   : Degree_Range;
      X        : Float) return Eval_Result_1D;
   --  S(x) = d_{k,p} via the optimized De Boor triangle.

   function Evaluate
     (Controls : Controls_2D;
      Knots    : Knot_Vector;
      Degree   : Degree_Range;
      X        : Float) return Eval_Result_2D;

   function Evaluate
     (Controls : Controls_3D;
      Knots    : Knot_Vector;
      Degree   : Degree_Range;
      X        : Float) return Eval_Result_3D;

   ---------------------------------------------------------------------------
   -- Builders / canonical examples
   ---------------------------------------------------------------------------

   function Make_Uniform_Clamped
     (Num_Controls : Control_Count;
      Degree       : Degree_Range;
      T_Min        : Float := 0.0;
      T_Max        : Float := 1.0) return Knot_Vector
     with Pre =>
       Num_Controls >= 1
       and then Num_Controls > Degree
       and then T_Max > T_Min,
          Global => null;
   --  Open clamped: Degree+1 copies of T_Min / T_Max; uniform interior.

   function Make_Bezier_Knots
     (Degree : Degree_Range;
      T_Min  : Float := 0.0;
      T_Max  : Float := 1.0) return Knot_Vector
     with Pre => T_Max > T_Min, Global => null;
   --  Degree+1 copies of T_Min then Degree+1 of T_Max (Bézier as B-spline).

   function Make_Linear_1D (A, B : Float) return Controls_1D
     with Global => null;

   function Make_Linear_2D (P0, P1 : Point_2D) return Controls_2D
     with Global => null;

   function Make_Linear_3D (P0, P1 : Point_3D) return Controls_3D
     with Global => null;

   function Make_Cubic_Bezier_2D
     (P0, P1, P2, P3 : Point_2D) return Controls_2D
     with Global => null;

   function Make_Cubic_Bezier_1D
     (C0, C1, C2, C3 : Float) return Controls_1D
     with Global => null;

   function Make_Cubic_Bezier_3D
     (P0, P1, P2, P3 : Point_3D) return Controls_3D
     with Global => null;

   --  Package both controls and matching clamped/Bézier knots.
   type Curve_1D is record
      Controls : Controls_1D (0 .. Max_Controls - 1) := [others => 0.0];
      Knots    : Knot_Vector (0 .. Max_Knots - 1) := [others => 0.0];
      N_Ctrl   : Control_Count := 0;
      N_Knots  : Natural := 0;
      Degree   : Degree_Range := 0;
   end record;

   type Curve_2D is record
      Controls : Controls_2D (0 .. Max_Controls - 1) :=
                   [others => (0.0, 0.0)];
      Knots    : Knot_Vector (0 .. Max_Knots - 1) := [others => 0.0];
      N_Ctrl   : Control_Count := 0;
      N_Knots  : Natural := 0;
      Degree   : Degree_Range := 0;
   end record;

   function Make_Linear_Interpolant_1D
     (A, B : Float) return Curve_1D
     with Global => null;
   --  Degree-1 clamped open on [0,1].

   function Make_Linear_Interpolant_2D
     (P0, P1 : Point_2D) return Curve_2D
     with Global => null;

   function Make_Cubic_Bezier_As_BSpline_2D
     (P0, P1, P2, P3 : Point_2D) return Curve_2D
     with Global => null;
   --  Cubic Bézier ≡ B-spline with knots [0,0,0,0,1,1,1,1].

   function Make_Uniform_Clamped_2D
     (Controls : Controls_2D;
      Degree   : Degree_Range) return Curve_2D
     with Pre =>
       Controls'Length >= 1
       and then Controls'Length <= Max_Controls
       and then Controls'Length > Degree,
          Global => null;

   function Make_Example_2D (Kind : Example_Kind) return Curve_2D
     with Global => null;
   --  Linear_Ramp        : (0,0)→(1,1), degree 1 clamped
   --  Cubic_Bezier_Unit  : unit-square cubic as B-spline
   --  Uniform_Quadratic  : 4 controls, degree 2 uniform clamped
   --  Clamped_Cubic      : 5 controls, degree 3 uniform clamped

   function Make_Example_1D (Kind : Example_Kind) return Curve_1D
     with Global => null;

   function Evaluate_Curve
     (C : Curve_1D; X : Float) return Eval_Result_1D;

   function Evaluate_Curve
     (C : Curve_2D; X : Float) return Eval_Result_2D;

end De_Boor;
