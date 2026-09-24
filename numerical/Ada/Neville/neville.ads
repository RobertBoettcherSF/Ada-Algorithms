--  Neville — Ada 2023 educational package for Wikipedia
--  "Neville's algorithm": evaluate the unique degree-≤n interpolating
--  polynomial through distinct points (x_i, y_i) via a recursive
--  tableau. Cap degree n ≤ 16; educational Float. Optional full tableau
--  and Lagrange cross-check for tiny n.
--  Primary source:
--  https://en.wikipedia.org/wiki/Neville%27s_algorithm
--  Siblings (README): Ada-Spline-Interpolation, Ada-De-Casteljau,
--  upcoming Polynomial interpolation, Pareto, etc.

pragma Ada_2022;

package Neville
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types (educational Float)
   ---------------------------------------------------------------------------

   --  Degree n means n+1 data points. Cap n ≤ Max_Degree.
   Max_Degree : constant := 16;
   Max_Points : constant := Max_Degree + 1;

   subtype Degree_Range is Natural range 0 .. Max_Degree;
   subtype Point_Count  is Natural range 0 .. Max_Points;
   subtype Point_Index  is Natural range 0 .. Max_Degree;

   --  0-based abscissae / ordinates matching x_0 .. x_n, y_0 .. y_n.
   type Abscissae is array (Point_Index range <>) of Float;
   type Ordinates is array (Point_Index range <>) of Float;

   --  Dense triangular tableau P(i,j) for 0 ≤ i ≤ j ≤ n (lower unused).
   type Tableau is
     array (Point_Index range <>, Point_Index range <>) of Float;

   --  Ok                 : evaluation succeeded
   --  Duplicate_Abscissa : some x_i ≈ x_j (i ≠ j)
   --  Too_Few_Points     : fewer than 1 point
   --  Dimension_Error    : empty / mismatched lengths / over Max_Points
   --  Ill_Started        : internal setup could not proceed
   type Status is
     (Ok,
      Duplicate_Abscissa,
      Too_Few_Points,
      Dimension_Error,
      Ill_Started);

   type Eval_Result is record
      Value   : Float := 0.0;
      Stat    : Status := Ill_Started;
      Success : Boolean := False;
   end record;

   --  Full Neville tableau for education: Table(i,j) = p_{i,j}(X) for
   --  i ≤ j; diagonal Table(i,i) = Y(i); answer = Table(0, N).
   type Tableau_Result is record
      Table   : Tableau (0 .. Max_Degree, 0 .. Max_Degree) :=
                  [others => [others => 0.0]];
      N       : Degree_Range := 0;  -- last index; Num_Points = N + 1
      Value   : Float := 0.0;       -- p_{0,N}(X)
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

   type Example_Kind is
     (Linear_Data,
      Quadratic_Sample,
      Runge_Sample,
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
   -- Validation
   ---------------------------------------------------------------------------

   function Validate (X : Abscissae; Y : Ordinates) return Status;
   --  Dimension_Error / Too_Few_Points / Duplicate_Abscissa / Ok.

   ---------------------------------------------------------------------------
   -- Neville evaluation
   ---------------------------------------------------------------------------

   function Evaluate
     (X_Data : Abscissae;
      Y_Data : Ordinates;
      X      : Float) return Eval_Result;
   --  p(X) = p_{0,n}(X) via Neville tableau (O(n²) Float ops).

   function Evaluate
     (S : Sample; X : Float) return Eval_Result;
   --  Convenience overload using a packed Sample.

   function Evaluate_Tableau
     (X_Data : Abscissae;
      Y_Data : Ordinates;
      X      : Float) return Tableau_Result;
   --  Same value plus full upper-triangular tableau for teaching.

   function Evaluate_Tableau
     (S : Sample; X : Float) return Tableau_Result;

   ---------------------------------------------------------------------------
   -- Lagrange form (oracle for small n)
   ---------------------------------------------------------------------------

   function Evaluate_Lagrange
     (X_Data : Abscissae;
      Y_Data : Ordinates;
      X      : Float) return Eval_Result;
   --  L(X) = Σ_i y_i Π_{j≠i} (X − x_j)/(x_i − x_j). Cross-check only.

   function Evaluate_Lagrange
     (S : Sample; X : Float) return Eval_Result;

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

end Neville;
