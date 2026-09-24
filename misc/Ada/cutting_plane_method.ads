--  Cutting_Plane_Method — Ada 2023 educational package for Wikipedia
--  "Cutting-plane method": Gomory fractional cuts for pure integer LP
--  (embedded dense Bland simplex / tableau) and a Kelley sketch for
--  minimizing a max-of-affines convex piecewise-linear function via
--  supporting hyperplanes. Cap m,n ≤ 12. No with-clause dependency on
--  the sibling Ada-Simplex-Algorithm (ideas only).
--  Primary source:
--  https://en.wikipedia.org/wiki/Cutting-plane_method
--  Siblings: Ada-Simplex-Algorithm; future Branch-and-Cut.

pragma Ada_2022;

package Cutting_Plane_Method
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   Max_Constraints : constant := 12;
   Max_Vars        : constant := 12;

   subtype Constraint_Count is Natural range 0 .. Max_Constraints;
   subtype Var_Count        is Natural range 0 .. Max_Vars;
   subtype Constraint_Index is Positive range 1 .. Max_Constraints;
   subtype Var_Index        is Positive range 1 .. Max_Vars;

   type Matrix is
     array (Constraint_Index range <>, Var_Index range <>) of Real;
   type Vector is array (Positive range <>) of Real;

   type Status is (Optimal, Infeasible, Iteration_Limit, Unbounded);

   --  Max_Cuts     : outer cutting-plane iterations (Gomory / Kelley)
   --  Max_Pivots   : simplex pivot budget per LP solve
   --  Tol          : numerical zero / integer tolerance
   --  Integer_Tol  : |x − round(x)| ≤ Integer_Tol ⇒ integer
   type Config is record
      Max_Cuts    : Positive      := 40;
      Max_Pivots  : Positive      := 400;
      Tol         : Positive_Real := 1.0E-9;
      Integer_Tol : Positive_Real := 1.0E-6;
   end record;

   type Tableau_Data is
     array (0 .. Max_Constraints, 0 .. Max_Vars) of Real;
   type Basic_Map is array (1 .. Max_Constraints) of Natural;

   --  Dense maximisation tableau (same layout spirit as Ada-Simplex):
   --    T(0, 0)      = objective value z
   --    T(0, 1 .. N) = reduced costs (enter when < −Tol)
   --    T(1 .. M, 0) = RHS
   --    Basic(i)     = variable index basic in row i
   type Tableau is record
      M            : Constraint_Count := 0;
      N            : Var_Count        := 0;
      N_Decision   : Var_Count        := 0;
      N_Slack      : Var_Count        := 0;
      N_Artificial : Var_Count        := 0;
      Obj_Phase1   : Natural          := 0;
      T            : Tableau_Data     := [others => [others => 0.0]];
      Basic        : Basic_Map        := [others => 0];
   end record;

   --  Cut in ≥ form: sum_j Coeff(j) * x_j ≥ RHS  (nonbasic / all cols)
   type Cut is record
      N_Cols : Var_Count := 0;
      Coeff  : Vector (1 .. Max_Vars) := [others => 0.0];
      RHS    : Real := 0.0;
      Valid  : Boolean := False;
   end record;

   type Result is record
      Stat         : Status := Infeasible;
      Objective    : Real := 0.0;
      X            : Vector (1 .. Max_Vars) := [others => 0.0];
      N_Vars       : Var_Count := 0;
      N_Cuts       : Natural := 0;
      N_Pivots     : Natural := 0;
      Success      : Boolean := False;
   end record;

   Invalid_Argument : exception;

   Epsilon_Tol : constant Real := 1.0E-9;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Vec_Near
     (A, B : Vector; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => A'Length = B'Length and then Tol >= 0.0,
          Global => null;

   function Frac (X : Real) return Real
     with Global => null;
   --  Fractional part in [0, 1): X − Floor(X).

   function Is_Integer_Val
     (X : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Is_Integer_Vector
     (X : Vector; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   ---------------------------------------------------------------------------
   -- Embedded dense LP (Bland tableau) — helpers exposed for tests
   ---------------------------------------------------------------------------

   function Active_Obj_Row (Tab : Tableau) return Natural
     with Global => null;

   function Is_Optimal_LP
     (Tab : Tableau; Tol : Real := Epsilon_Tol) return Boolean
     with Global => null;

   function Select_Entering
     (Tab : Tableau; Tol : Real := Epsilon_Tol) return Natural
     with Global => null;

   function Select_Leaving
     (Tab       : Tableau;
      Enter_Col : Positive;
      Tol       : Real := Epsilon_Tol) return Natural
     with Pre => Enter_Col <= Max_Vars, Global => null;

   procedure Pivot
     (Tab                  : in out Tableau;
      Leave_Row, Enter_Col : Positive)
     with Pre => Leave_Row <= Max_Constraints
            and then Enter_Col <= Max_Vars;

   function Build_Tableau
     (A : Matrix; B, C : Vector) return Tableau
     with Pre => A'Length (1) = B'Length
            and then A'Length (2) = C'Length
            and then A'Length (1) <= Max_Constraints
            and then A'Length (2) + A'Length (1) <= Max_Vars,
          Global => null;

   function Extract_Primal
     (Tab : Tableau; N_Decision : Var_Count) return Vector
     with Pre => N_Decision <= Max_Vars, Global => null;

   function Solve_Tableau
     (Tab : in out Tableau;
      Cfg : Config := (others => <>)) return Result;

   function Maximize_LP
     (A   : Matrix;
      B   : Vector;
      C   : Vector;
      Cfg : Config := (others => <>)) return Result
     with Pre => A'Length (1) = B'Length
            and then A'Length (2) = C'Length
            and then A'Length (1) >= 1
            and then A'Length (2) >= 1
            and then A'Length (1) <= Max_Constraints
            and then A'Length (2) + A'Length (1) <= Max_Vars;
   --  Solve max cᵀx s.t. Ax ≤ b, x ≥ 0 (embedded Bland two-phase).

   ---------------------------------------------------------------------------
   -- Gomory fractional cut
   ---------------------------------------------------------------------------

   function First_Fractional_Row
     (Tab : Tableau; Tol : Real := Epsilon_Tol) return Natural
     with Global => null;
   --  Smallest row index whose RHS is non-integer; 0 if none.

   function Gomory_Cut_From_Row
     (Tab : Tableau;
      Row : Positive;
      Tol : Real := Epsilon_Tol) return Cut
     with Pre => Row <= Max_Constraints, Global => null;
   --  From tableau row Row: sum_j Frac(ā_j) x_j ≥ Frac(b̄)
   --  (coefficients over current columns 1 .. Tab.N). Valid=False if
   --  the row RHS is already integer within Tol.

   procedure Add_Gomory_Cut
     (Tab : in out Tableau;
      C   : Cut)
     with Pre => C.Valid;
   --  Append cut as ≤ form with a new slack (RHS becomes −Frac(b̄) < 0).

   ---------------------------------------------------------------------------
   -- ILP cutting planes (Gomory-style)
   ---------------------------------------------------------------------------

   function Solve_ILP_Cutting_Planes
     (A   : Matrix;
      B   : Vector;
      C   : Vector;
      Cfg : Config := (others => <>)) return Result
     with Pre => A'Length (1) = B'Length
            and then A'Length (2) = C'Length
            and then A'Length (1) >= 1
            and then A'Length (2) >= 1
            and then A'Length (1) <= Max_Constraints
            and then A'Length (2) + A'Length (1) <= Max_Vars;
   --  Pure-IP sketch: LP relax → Gomory cut → reoptimize until integer
   --  decision vector, infeasible, or Max_Cuts / pivot budget.

   ---------------------------------------------------------------------------
   -- Kelley cutting-plane sketch (max-of-affines convex min)
   ---------------------------------------------------------------------------

   --  Piecewise-linear convex f(x) = max_{k=1..K} (A_k · x + B_k).
   subtype Affine_Count is Natural range 0 .. Max_Constraints;
   type Affine_Matrix is
     array (Constraint_Index range <>, Var_Index range <>) of Real;
   type Affine_Bias is array (Positive range <>) of Real;

   function Eval_Max_Of_Affines
     (A_Aff : Affine_Matrix;
      B_Aff : Affine_Bias;
      X     : Vector) return Real
     with Pre => A_Aff'Length (1) = B_Aff'Length
            and then A_Aff'Length (2) = X'Length
            and then A_Aff'Length (1) >= 1,
          Global => null;

   function Subgradient_Max_Of_Affines
     (A_Aff : Affine_Matrix;
      B_Aff : Affine_Bias;
      X     : Vector) return Vector
     with Pre => A_Aff'Length (1) = B_Aff'Length
            and then A_Aff'Length (2) = X'Length
            and then A_Aff'Length (1) >= 1,
          Global => null;
   --  Gradient of an active affine (smallest index on ties).

   function Solve_Kelley
     (A_Aff : Affine_Matrix;
      B_Aff : Affine_Bias;
      X_Lo  : Vector;
      X_Hi  : Vector;
      Cfg   : Config := (others => <>)) return Result
     with Pre => A_Aff'Length (1) = B_Aff'Length
            and then A_Aff'Length (2) = X_Lo'Length
            and then X_Lo'Length = X_Hi'Length
            and then A_Aff'Length (1) >= 1
            and then A_Aff'Length (2) >= 1
            and then A_Aff'Length (2) <= Max_Vars - 1
            and then A_Aff'Length (1) + 2 * A_Aff'Length (2) + 8
                       <= Max_Constraints;
   --  Minimize f(x)=max_k (a_k·x+b_k) over box [X_Lo, X_Hi] by iteratively
   --  adding supporting cuts t ≥ a·x + β and solving an LP master in (x,t).

end Cutting_Plane_Method;
