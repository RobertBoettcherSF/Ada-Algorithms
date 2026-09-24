--  Simplex_Algorithm — Ada 2023 educational package for Wikipedia
--  "Simplex algorithm" (Dantzig linear programming): tableau simplex
--  with Bland's anti-cycling rule and a two-phase method for artificial
--  variables / infeasibility detection. Solves small dense LPs in
--  standard form maximize cᵀx subject to Ax ≤ b, x ≥ 0 (slack tableau)
--  or equality form with a basic feasible start.
--  Primary source:
--  https://en.wikipedia.org/wiki/Simplex_algorithm
--  Not to be confused with the Nelder–Mead "simplex" derivative-free
--  optimizer (sibling Ada-Nelder-Mead).
--  Siblings: Ada-Gauss-Newton / Ada-BFGS / Ada-Nelder-Mead (README links).

pragma Ada_2022;

package Simplex_Algorithm
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   --  Dense tableau limits (including slack / artificial columns).
   Max_Constraints : constant := 16;
   Max_Vars        : constant := 16;

   subtype Constraint_Count is Natural range 0 .. Max_Constraints;
   subtype Var_Count        is Natural range 0 .. Max_Vars;
   subtype Constraint_Index is Positive range 1 .. Max_Constraints;
   subtype Var_Index        is Positive range 1 .. Max_Vars;

   --  Dense coefficient matrix A (rows = constraints, cols = decision vars).
   type Matrix is
     array (Constraint_Index range <>, Var_Index range <>) of Real;

   --  Dense vectors for b, c, and recovered primal x.
   type Vector is array (Positive range <>) of Real;

   --  Solve status returned by Maximize / Solve.
   type Status is (Optimal, Unbounded, Infeasible);

   --  Max_Pivots : hard pivot budget (both phases combined)
   --  Tol        : numerical zero for reduced costs / ratios / Phase-I obj
   type Config is record
      Max_Pivots : Positive     := 500;
      Tol        : Positive_Real := 1.0E-10;
   end record;

   --  Dense simplex tableau storage (fixed bounds for educational size).
   type Tableau_Data is
     array (0 .. Max_Constraints, 0 .. Max_Vars) of Real;
   type Basic_Map is array (1 .. Max_Constraints) of Natural;

   --  Dense simplex tableau in canonical form:
   --    T(0, 0)       = current objective value z
   --    T(0, 1 .. N)  = reduced costs (maximize: enter when < −Tol)
   --    T(1 .. M, 0)  = RHS (basic-variable values)
   --    T(1 .. M, j)  = constraint coefficients
   --  Basic(i) is the variable index (1 .. N) basic in row i.
   --  Phase-I objective (when present) lives in row Obj_Phase1.
   type Tableau is record
      M            : Constraint_Count := 0;
      N            : Var_Count        := 0;
      N_Decision   : Var_Count        := 0;  -- original vars before slacks
      N_Slack      : Var_Count        := 0;
      N_Artificial : Var_Count        := 0;
      Obj_Phase1   : Natural          := 0;  -- 0 = unused; else row index
      T            : Tableau_Data     := [others => [others => 0.0]];
      Basic        : Basic_Map        := [others => 0];
   end record;

   type Result is record
      Stat       : Status := Infeasible;
      Objective  : Real := 0.0;
      X          : Vector (1 .. Max_Vars) := [others => 0.0];
      N_Vars     : Var_Count := 0;       -- decision variables returned
      N_Pivots   : Natural := 0;
      Success    : Boolean := False;     -- True iff Stat = Optimal
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-10;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Vec_Near
     (A, B : Vector; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => A'Length = B'Length and then Tol >= 0.0,
          Global => null;

   ---------------------------------------------------------------------------
   -- Tableau helpers (exposed for unit tests)
   ---------------------------------------------------------------------------

   function Is_Optimal
     (Tab : Tableau; Tol : Real := Epsilon_Tol) return Boolean
     with Global => null;
   --  True when no entering column exists under Bland (all reduced costs
   --  of the active objective row are ≥ −Tol). Uses row 0 unless
   --  Obj_Phase1 > 0 (Phase I).

   function Select_Entering
     (Tab : Tableau; Tol : Real := Epsilon_Tol) return Natural
     with Global => null;
   --  Bland entering: smallest column index j with reduced cost < −Tol.
   --  Returns 0 if the tableau is optimal for the active objective.

   function Select_Leaving
     (Tab       : Tableau;
      Enter_Col : Positive;
      Tol       : Real := Epsilon_Tol) return Natural
     with Pre => Enter_Col <= Max_Vars, Global => null;
   --  Min-ratio test on positive pivot column entries. Bland tie-break:
   --  among rows attaining the minimum ratio, leave the basic variable
   --  with the smallest index. Returns 0 if the ray is unbounded.

   procedure Pivot
     (Tab                     : in out Tableau;
      Leave_Row, Enter_Col    : Positive)
     with Pre => Leave_Row <= Max_Constraints
            and then Enter_Col <= Max_Vars;
   --  Classical Gauss–Jordan pivot: make T(Leave_Row, Enter_Col) = 1 and
   --  clear the rest of the column (including objective rows). Updates
   --  Basic(Leave_Row) ← Enter_Col.

   function Build_Tableau
     (A : Matrix; B, C : Vector) return Tableau
     with Pre => A'Length (1) = B'Length
            and then A'Length (2) = C'Length
            and then A'Length (1) <= Max_Constraints
            and then A'Length (2) + A'Length (1) <= Max_Vars,
          Global => null;
   --  Build a dense maximisation tableau for
   --    max cᵀx  s.t.  Ax ≤ b,  x ≥ 0
   --  by appending one slack per inequality. Negative RHS rows are
   --  multiplied by −1 (turning ≤ into ≥ form) and receive an artificial
   --  variable so Phase I can start; callers should then run Solve
   --  (two-phase). When all b_i ≥ 0 the slack basis is feasible and
   --  Phase II can start immediately.

   function Extract_Primal
     (Tab : Tableau; N_Decision : Var_Count) return Vector
     with Pre => N_Decision <= Max_Vars, Global => null;
   --  Recover non-basic = 0, basic = RHS for the first N_Decision vars.

   function Active_Obj_Row (Tab : Tableau) return Natural
     with Global => null;
   --  Phase-I row if present, otherwise 0.

   ---------------------------------------------------------------------------
   -- Drivers
   ---------------------------------------------------------------------------

   function Solve
     (Tab : in out Tableau;
      Cfg : Config := (others => <>)) return Result;
   --  Run Bland simplex on an existing tableau. If artificials / Phase-I
   --  objective are present, Phase I minimizes their sum (via maximizing
   --  the negated Phase-I row); a positive Phase-I optimum ⇒ Infeasible.
   --  Phase II then maximizes the original objective. Detects Unbounded
   --  when an entering column has no positive pivot entry.

   function Maximize
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
   --  Convenience: Build_Tableau (A, b, c) then Solve (two-phase as needed).

end Simplex_Algorithm;
