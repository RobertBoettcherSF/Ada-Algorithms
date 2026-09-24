--  Birkhoff_Interpolation — Ada 2023 educational package for Wikipedia
--  "Birkhoff interpolation" (loxodromic): find a polynomial P of degree
--  < N matching selected derivative conditions P^(n_i)(x_i)=y_i. Unlike
--  Hermite, orders need not be contiguous from 0 at each node. Incidence
--  matrices may be singular; this package builds the monomial linear
--  system and solves with GEPP (cap N ≤ 9, degree ≤ 8). Regular presets:
--  Lagrange (values only), Hermite two-point value+derivative, and the
--  Wikipedia / Pólya regular lacunary pattern P'(-1), P(0), P'(1).
--  Primary source:
--  https://en.wikipedia.org/wiki/Birkhoff_interpolation
--  Siblings (README): Ada-Hermite-Interpolation, Ada-Lagrange-Interpolation,
--  Ada-Cubic-Interpolation; after this sheet: Filtered back-projection,
--  Kahan (Geometric / Level-set skipped).

pragma Ada_2022;

package Birkhoff_Interpolation
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types (educational Float)
   ---------------------------------------------------------------------------

   --  N conditions → degree < N. Cap N ≤ Max_Conditions (degree ≤ 8).
   Max_Conditions : constant := 9;
   Max_Degree     : constant := Max_Conditions - 1;

   subtype Condition_Count is Natural range 0 .. Max_Conditions;
   subtype Condition_Index is Positive range 1 .. Max_Conditions;
   subtype Coeff_Index     is Natural range 0 .. Max_Degree;
   --  Wide indices so callers may exceed Max_Conditions; Fit/Validate reject.
   subtype Sample_Index    is Natural range 0 .. 32;
   subtype Cond_Array_Index is Positive range 1 .. 64;

   --  One incidence condition: P^(Derivative_Order)(Node) = Value.
   type Condition is record
      Node             : Float := 0.0;
      Derivative_Order : Natural := 0;
      Value            : Float := 0.0;
   end record;

   type Conditions is array (Cond_Array_Index range <>) of Condition;

   --  Monomial coefficients: P(x) = c_0 + c_1 x + ... + c_{N-1} x^{N-1}.
   type Coefficients is array (Coeff_Index range <>) of Float;

   --  Convenience 0-based Float arrays for Lagrange node / value builders.
   type Abscissae is array (Sample_Index range <>) of Float;
   type Ordinates is array (Sample_Index range <>) of Float;

   --  Ok                   : unique fit / evaluation succeeded
   --  Singular             : incidence matrix singular (zero pivot; non-unique)
   --  Inconsistent         : singular row with nonzero residual / RHS
   --  Too_Many_Conditions  : more than Max_Conditions rows
   --  Ill_Started          : empty / invalid setup
   --  Dimension_Error      : length / degree / storage mismatch
   type Status is
     (Ok,
      Singular,
      Inconsistent,
      Too_Many_Conditions,
      Ill_Started,
      Dimension_Error);

   --  Fitted monomial polynomial of degree < N (N = Poly.N).
   type Polynomial is record
      Coeffs : Coefficients (0 .. Max_Degree) := [others => 0.0];
      N      : Condition_Count := 0;  -- number of coefficients (= #conditions)
      Valid  : Boolean := False;
   end record;

   type Fit_Result is record
      Poly    : Polynomial;
      Stat    : Status := Ill_Started;
      Success : Boolean := False;
   end record;

   type Eval_Result is record
      Value   : Float := 0.0;
      Stat    : Status := Ill_Started;
      Success : Boolean := False;
   end record;

   --  Packed condition list for builders / Fit overload.
   type Condition_List is record
      Data  : Conditions (1 .. Max_Conditions) :=
                [others => (Node => 0.0, Derivative_Order => 0, Value => 0.0)];
      Count : Condition_Count := 0;
      Valid : Boolean := False;
      Stat  : Status := Ill_Started;
   end record;

   type Example_Kind is
     (Lagrange_Quadratic,
      Hermite_Two_Point_Cubic,
      Birkhoff_Polya_Regular,
      Known_Cubic_Lagrange);

   Invalid_Argument : exception;

   Epsilon_Tol : constant Float := 1.0E-6;
   Near_Tol    : constant Float := 1.0E-5;
   Pivot_Tol   : constant Float := 1.0E-8;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Float; Tol : Float := Near_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Make_Condition
     (Node : Float; Derivative_Order : Natural; Value : Float)
      return Condition
     with Global => null;

   --  Entry of the monomial row for P^(D)(X) vs coeff of x^K:
   --  if K < D then 0 else (K!/(K-D)!) * X^(K-D).
   function Monomial_Derivative_Entry
     (K, D : Natural; X : Float) return Float
     with Global => null;

   ---------------------------------------------------------------------------
   -- Validation
   ---------------------------------------------------------------------------

   function Validate (C : Conditions) return Status
     with Global => null;
   --  Ill_Started if empty; Too_Many if Length > Max; else Ok.
   --  (Singularity is detected only in Fit / GEPP.)

   function Validate (L : Condition_List) return Status
     with Global => null;

   ---------------------------------------------------------------------------
   -- Fit / evaluate
   ---------------------------------------------------------------------------

   function Fit (C : Conditions) return Fit_Result;
   --  Build N×N monomial system for degree < N and solve with GEPP.
   --  Reports Singular / Inconsistent when the incidence matrix is not
   --  uniquely solvable for the given RHS.

   function Fit (L : Condition_List) return Fit_Result;

   function Evaluate (P : Polynomial; X : Float) return Eval_Result;
   --  Horner evaluation of the fitted monomial polynomial.

   function Evaluate_Derivative
     (P : Polynomial; Order : Natural; X : Float) return Eval_Result;
   --  Horner-style evaluation of P^(Order)(X); Order ≥ N → 0.

   function Matches_Condition
     (P : Polynomial; C : Condition; Tol : Float := Near_Tol) return Boolean
     with Pre => Tol >= 0.0;
   --  True iff P is Valid and |P^(C.Derivative_Order)(C.Node) − C.Value| ≤ Tol.

   function Matches_All
     (P : Polynomial; C : Conditions; Tol : Float := Near_Tol) return Boolean
     with Pre => Tol >= 0.0;

   function Matches_All
     (P : Polynomial; L : Condition_List; Tol : Float := Near_Tol)
      return Boolean
     with Pre => Tol >= 0.0;

   ---------------------------------------------------------------------------
   -- Preset builders (regular incidence patterns)
   ---------------------------------------------------------------------------

   function Make_Lagrange_Conditions
     (X : Abscissae; Y : Ordinates) return Condition_List;
   --  Value-only conditions at nodes (classical Lagrange special case of
   --  Birkhoff). Requires X'Length = Y'Length in 1 .. Max_Conditions.

   function Make_Hermite_Two_Point
     (X0, Y0, M0 : Float;
      X1, Y1, M1 : Float) return Condition_List;
   --  Contiguous Hermite at two points: value + first derivative each
   --  → 4 conditions, unique cubic when X0 ≠ X1.

   function Make_Birkhoff_Polya_Regular
     (X_Left, Y_Left_Deriv   : Float;
      X_Mid,  Y_Mid          : Float;
      X_Right, Y_Right_Deriv : Float) return Condition_List;
   --  Wikipedia regular example (always unique for three distinct nodes):
   --  P'(X_Left)=Y_Left_Deriv, P(X_Mid)=Y_Mid, P'(X_Right)=Y_Right_Deriv.
   --  Incidence matrix (orders 0,1 across three nodes):
   --    [[0,1,0],[1,0,0],[0,1,0]].

   function Make_Birkhoff_Singular_Example
     (X_Left, Y_Left        : Float;
      X_Mid,  Y_Mid_Deriv   : Float;
      X_Right, Y_Right      : Float) return Condition_List;
   --  Wikipedia singular / inconsistent pattern:
   --  P(X_Left)=Y_Left, P'(X_Mid)=Y_Mid_Deriv, P(X_Right)=Y_Right.
   --  Incidence [[1,0,0],[0,1,0],[1,0,0]] — no unique quadratic in general
   --  (e.g. P(-1)=P(1)=0, P'(0)=1 is inconsistent).

   function Make_Example (Kind : Example_Kind) return Fit_Result
     with Global => null;
   --  Lagrange_Quadratic       : y=x² at −1,0,1
   --  Hermite_Two_Point_Cubic  : known cubic value+deriv at 0 and 1
   --  Birkhoff_Polya_Regular   : P'(−1)=−2, P(0)=0, P'(1)=2 → P(x)=x²
   --  Known_Cubic_Lagrange     : p(x)=x³−2x²+x at 0,0.5,1,1.5,2

   ---------------------------------------------------------------------------
   -- Slice helpers
   ---------------------------------------------------------------------------

   function Slice (L : Condition_List) return Conditions
     with Pre => L.Valid and then L.Count >= 1;
   --  View L.Data (1 .. L.Count).

end Birkhoff_Interpolation;
