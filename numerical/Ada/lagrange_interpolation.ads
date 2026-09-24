--  Lagrange_Interpolation — Ada 2023 educational package for Wikipedia
--  "Lagrange polynomial": evaluate the unique degree-≤n interpolating
--  polynomial through distinct points (x_i, y_i) via the classical
--  Lagrange basis Σ y_i ℓ_i(x), plus educational barycentric first /
--  second forms with precomputed weights w_i. Cap degree n ≤ 16;
--  educational Float. Optional Basis_Polynomial for teaching.
--  Primary source:
--  https://en.wikipedia.org/wiki/Lagrange_polynomial
--  Siblings (README): Ada-Neville, Ada-Polynomial-Interpolation,
--  Ada-Linear-Interpolation; upcoming Hermite / Cubic / Birkhoff.

pragma Ada_2022;

package Lagrange_Interpolation
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

   --  Barycentric weights w_i = 1 / Π_{j≠i} (x_i − x_j).
   type Weights is array (Point_Index range <>) of Float;

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

   --  Precomputed barycentric weights for repeated evaluation.
   type Weight_Result is record
      W       : Weights (0 .. Max_Degree) := [others => 0.0];
      N       : Degree_Range := 0;  -- last index; Num_Points = N + 1
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

   --  Barycentric formula flavour for Evaluate_Barycentric.
   type Barycentric_Form is
     (First_Form,   -- p(x) = ℓ(x) Σ (w_i/(x−x_i)) y_i
      Second_Form); -- p(x) = [Σ (w_i/(x−x_i)) y_i] / [Σ w_i/(x−x_i)]

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
   -- Validation / weights
   ---------------------------------------------------------------------------

   function Validate (X : Abscissae; Y : Ordinates) return Status;
   --  Dimension_Error / Too_Few_Points / Duplicate_Abscissa / Ok.

   function Build_Weights (X : Abscissae) return Weight_Result;
   --  w_i = 1 / Π_{j≠i} (x_i − x_j). Rejects duplicates / empty / over max.

   function Build_Weights (S : Sample) return Weight_Result;

   ---------------------------------------------------------------------------
   -- Classical Lagrange evaluation
   ---------------------------------------------------------------------------

   function Evaluate
     (X_Data : Abscissae;
      Y_Data : Ordinates;
      X      : Float) return Eval_Result;
   --  p(X) = Σ_i y_i ℓ_i(X), ℓ_i(X) = Π_{j≠i} (X − x_j)/(x_i − x_j).

   function Evaluate
     (S : Sample; X : Float) return Eval_Result;
   --  Convenience overload using a packed Sample.

   function Basis_Polynomial
     (X_Data : Abscissae;
      I      : Point_Index;
      X      : Float) return Eval_Result;
   --  ℓ_I(X) alone. Requires I in X_Data'Range (0-based relative index
   --  0 .. n via I relative to First). Stat Dimension_Error if I out of
   --  bounds; Duplicate_Abscissa if nodes not distinct.

   ---------------------------------------------------------------------------
   -- Barycentric forms (educational; Second_Form preferred numerically)
   ---------------------------------------------------------------------------

   function Evaluate_Barycentric
     (X_Data : Abscissae;
      Y_Data : Ordinates;
      X      : Float;
      Form   : Barycentric_Form := Second_Form) return Eval_Result;
   --  Builds weights then evaluates. At a node x = x_k returns y_k.

   function Evaluate_Barycentric
     (X_Data : Abscissae;
      Y_Data : Ordinates;
      W      : Weights;
      X      : Float;
      Form   : Barycentric_Form := Second_Form) return Eval_Result;
   --  Reuse precomputed W (same length as X_Data / Y_Data).

   function Evaluate_Barycentric
     (S    : Sample;
      X    : Float;
      Form : Barycentric_Form := Second_Form) return Eval_Result;

   ---------------------------------------------------------------------------
   -- Cross-check: classical ≡ barycentric on same data
   ---------------------------------------------------------------------------

   function Forms_Agree
     (X_Data : Abscissae;
      Y_Data : Ordinates;
      X      : Float;
      Tol    : Float := Near_Tol) return Boolean
     with Pre => Tol >= 0.0;
   --  True iff classical, barycentric first, and second succeed and pairwise Near.

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

end Lagrange_Interpolation;
