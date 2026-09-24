--  Polynomial_Interpolation — Ada 2023 educational package for Wikipedia
--  "Polynomial interpolation": survey + runnable forms of the unique
--  degree-≤n interpolant through distinct points (x_i, y_i). Implements
--  Lagrange evaluation, Newton divided differences + nested eval,
--  Neville tableau (inline), and optional monomial Vandermonde via GEPP
--  for tiny n. Cap degree n ≤ 16; educational Float. Self-contained
--  (no with of sibling packages).
--  Primary source:
--  https://en.wikipedia.org/wiki/Polynomial_interpolation
--  Siblings (README): Ada-Neville, Ada-Spline-Interpolation,
--  Ada-De-Casteljau; upcoming Pareto / Tricubic / Nearest-neighbor.

pragma Ada_2022;

package Polynomial_Interpolation
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types (educational Float)
   ---------------------------------------------------------------------------

   --  Degree n means n+1 data points. Cap n ≤ Max_Degree.
   Max_Degree : constant := 16;
   Max_Points : constant := Max_Degree + 1;

   --  Monomial / Vandermonde GEPP is only offered for tiny n (catalogue risk).
   Max_Monomial_Degree : constant := 8;

   subtype Degree_Range is Natural range 0 .. Max_Degree;
   subtype Point_Count  is Natural range 0 .. Max_Points;
   subtype Point_Index  is Natural range 0 .. Max_Degree;

   --  0-based abscissae / ordinates matching x_0 .. x_n, y_0 .. y_n.
   type Abscissae is array (Point_Index range <>) of Float;
   type Ordinates is array (Point_Index range <>) of Float;

   --  Dense triangular divided-difference / Neville tableau storage.
   type Tableau is
     array (Point_Index range <>, Point_Index range <>) of Float;

   --  Newton coefficients a_k = f[x_0,...,x_k] (diagonal of DD table).
   type Newton_Coeffs is array (Point_Index range <>) of Float;

   --  Monomial coefficients c_0 + c_1 x + ... + c_n x^n.
   type Monomial_Coeffs is array (Point_Index range <>) of Float;

   --  Ok                 : succeeded
   --  Duplicate_Abscissa : some x_i ≈ x_j (i ≠ j)
   --  Too_Few_Points     : fewer than 1 point
   --  Dimension_Error    : empty / mismatched lengths / over Max_Points
   --  Ill_Started        : internal setup could not proceed
   --  Singular           : GEPP pivot vanished (Vandermonde)
   type Status is
     (Ok,
      Duplicate_Abscissa,
      Too_Few_Points,
      Dimension_Error,
      Ill_Started,
      Singular);

   type Eval_Result is record
      Value   : Float := 0.0;
      Stat    : Status := Ill_Started;
      Success : Boolean := False;
   end record;

   --  Full divided-difference table: Table(i,k) = f[x_i,...,x_{i+k}];
   --  Coeffs(k) = Table(0,k) = a_k for Newton form. N = last index.
   type DD_Result is record
      Table   : Tableau (0 .. Max_Degree, 0 .. Max_Degree) :=
                  [others => [others => 0.0]];
      Coeffs  : Newton_Coeffs (0 .. Max_Degree) := [others => 0.0];
      N       : Degree_Range := 0;
      Stat    : Status := Ill_Started;
      Success : Boolean := False;
   end record;

   --  Full Neville tableau for education: Table(i,j) = p_{i,j}(X) for
   --  i ≤ j; diagonal Table(i,i) = Y(i); answer = Table(0, N).
   type Tableau_Result is record
      Table   : Tableau (0 .. Max_Degree, 0 .. Max_Degree) :=
                  [others => [others => 0.0]];
      N       : Degree_Range := 0;
      Value   : Float := 0.0;
      Stat    : Status := Ill_Started;
      Success : Boolean := False;
   end record;

   --  Monomial fit: Coeffs(0..N) for Σ c_k x^k.
   type Monomial_Result is record
      Coeffs  : Monomial_Coeffs (0 .. Max_Degree) := [others => 0.0];
      N       : Degree_Range := 0;
      Stat    : Status := Ill_Started;
      Success : Boolean := False;
   end record;

   --  Packed sample: valid entries are X(0 .. N), Y(0 .. N).
   type Sample is record
      X     : Abscissae (0 .. Max_Degree) := [others => 0.0];
      Y     : Ordinates (0 .. Max_Degree) := [others => 0.0];
      N     : Degree_Range := 0;
      Valid : Boolean := False;
   end record;

   --  Taxonomy of runnable forms in this survey package.
   type Method_Kind is
     (Lagrange_Form,
      Newton_Form,
      Neville_Form,
      Monomial_Vandermonde);

   type Example_Kind is
     (Linear_Data,
      Quadratic_Sample,
      Runge_Sample,
      Sine_Sample);

   Invalid_Argument : exception;

   Epsilon_Tol  : constant Float := 1.0E-6;
   Near_Tol     : constant Float := 1.0E-5;
   Distinct_Tol : constant Float := 1.0E-6;
   Pivot_Tol    : constant Float := 1.0E-12;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Float; Tol : Float := Near_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Is_Distinct
     (X : Abscissae; Tol : Float := Distinct_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;
   --  True iff all pairs |x_i − x_j| > Tol for i ≠ j.

   function Degree_Of (X : Abscissae) return Degree_Range
     with Pre => X'Length >= 1 and then X'Length <= Max_Points,
          Global => null;
   --  n = Length − 1

   function Degree_Of (Y : Ordinates) return Degree_Range
     with Pre => Y'Length >= 1 and then Y'Length <= Max_Points,
          Global => null;

   function Slice_X (S : Sample) return Abscissae
     with Pre => S.Valid, Global => null;
   --  S.X (0 .. S.N)

   function Slice_Y (S : Sample) return Ordinates
     with Pre => S.Valid, Global => null;
   --  S.Y (0 .. S.N)

   ---------------------------------------------------------------------------
   -- Validation / taxonomy
   ---------------------------------------------------------------------------

   function Validate (X : Abscissae; Y : Ordinates) return Status;
   --  Dimension_Error / Too_Few_Points / Duplicate_Abscissa / Ok.

   function Recommend (Kind : Method_Kind; N : Degree_Range) return String
     with Global => null;
   --  Short educational note; Runge / high n → prefer spline sibling.

   ---------------------------------------------------------------------------
   -- Lagrange evaluation
   ---------------------------------------------------------------------------

   function Evaluate_Lagrange
     (X_Data : Abscissae;
      Y_Data : Ordinates;
      X      : Float) return Eval_Result;
   --  L(X) = Σ_i y_i Π_{j≠i} (X − x_j)/(x_i − x_j).

   function Evaluate_Lagrange
     (S : Sample; X : Float) return Eval_Result;

   ---------------------------------------------------------------------------
   -- Newton form: divided differences + Horner-like nested eval
   ---------------------------------------------------------------------------

   function Build_Divided_Differences
     (X_Data : Abscissae; Y_Data : Ordinates) return DD_Result;
   --  Table(i,0)=y_i; Table(i,k)=(Table(i+1,k-1)-Table(i,k-1))/(x_{i+k}-x_i);
   --  Coeffs(k)=Table(0,k).

   function Build_Divided_Differences (S : Sample) return DD_Result;

   function Evaluate_Newton
     (X_Data : Abscissae;
      Coeffs : Newton_Coeffs;
      X      : Float) return Eval_Result;
   --  Nested: p = a_n; for k=n-1..0: p = a_k + (X-x_k)*p.
   --  Requires Coeffs'Length = X_Data'Length and Validate-compatible X.

   function Evaluate_Newton
     (X_Data : Abscissae;
      Y_Data : Ordinates;
      X      : Float) return Eval_Result;
   --  Build DD then nested eval.

   function Evaluate_Newton
     (S : Sample; X : Float) return Eval_Result;

   ---------------------------------------------------------------------------
   -- Neville tableau evaluation (inline; not depending on Ada-Neville)
   ---------------------------------------------------------------------------

   function Evaluate_Neville
     (X_Data : Abscissae;
      Y_Data : Ordinates;
      X      : Float) return Eval_Result;
   --  p(X)=p_{0,n}(X) via in-place column form (O(n²)).

   function Evaluate_Neville
     (S : Sample; X : Float) return Eval_Result;

   function Evaluate_Neville_Tableau
     (X_Data : Abscissae;
      Y_Data : Ordinates;
      X      : Float) return Tableau_Result;
   --  Same value plus full upper-triangular tableau for teaching.

   function Evaluate_Neville_Tableau
     (S : Sample; X : Float) return Tableau_Result;

   ---------------------------------------------------------------------------
   -- Optional monomial Vandermonde via GEPP (tiny n only)
   ---------------------------------------------------------------------------

   function Fit_Monomial
     (X_Data : Abscissae; Y_Data : Ordinates) return Monomial_Result;
   --  Solve V c = y with V_{ij}=x_i^j via GEPP. Rejects n > Max_Monomial_Degree.

   function Fit_Monomial (S : Sample) return Monomial_Result;

   function Evaluate_Monomial
     (Coeffs : Monomial_Coeffs; X : Float) return Float
     with Global => null;
   --  Horner: Σ c_k X^k (Coeffs must be 0 .. N contiguous).

   function Evaluate_Monomial
     (X_Data : Abscissae;
      Y_Data : Ordinates;
      X      : Float) return Eval_Result;
   --  Fit then Horner; Singular / Dimension_Error on failure.

   function Evaluate_Monomial
     (S : Sample; X : Float) return Eval_Result;

   ---------------------------------------------------------------------------
   -- Cross-check: Lagrange ≡ Newton ≡ Neville on same data
   ---------------------------------------------------------------------------

   function Forms_Agree
     (X_Data : Abscissae;
      Y_Data : Ordinates;
      X      : Float;
      Tol    : Float := Near_Tol) return Boolean
     with Pre => Tol >= 0.0;
   --  True iff all three main forms succeed and pairwise Near.

   function Forms_Agree
     (S : Sample; X : Float; Tol : Float := Near_Tol) return Boolean
     with Pre => Tol >= 0.0;

   ---------------------------------------------------------------------------
   -- Builders / sample data
   ---------------------------------------------------------------------------

   function Make_Linear
     (N : Point_Count; X0, X1, Y0, Y1 : Float) return Sample
     with Pre =>
       N >= 1 and then N <= Max_Points and then X1 /= X0,
          Global => null;
   --  Equally spaced x on [X0,X1]; y on the line (X0,Y0)–(X1,Y1).

   function Make_Quadratic_Sample
     (N : Point_Count; X0, X1 : Float) return Sample
     with Pre =>
       N >= 1 and then N <= Max_Points and then X1 /= X0,
          Global => null;
   --  y = x² on [X0, X1].

   function Make_Runge_Sample (N : Point_Count) return Sample
     with Pre => N >= 1 and then N <= Max_Points, Global => null;
   --  Runge: y = 1/(1+25x²) on equally spaced x ∈ [−1,1].

   function Make_Sine_Sample (N : Point_Count) return Sample
     with Pre => N >= 1 and then N <= Max_Points, Global => null;
   --  y = sin(x) on equally spaced x ∈ [0, π].

   function Make_Example
     (Kind : Example_Kind; N : Point_Count) return Sample
     with Pre => N >= 1 and then N <= Max_Points, Global => null;
   --  Dispatch to the sample builders above.

end Polynomial_Interpolation;
