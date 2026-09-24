--  Bensons_Algorithm — Ada 2023 educational package for Wikipedia
--  "Benson's algorithm": multi-objective / vector LP outer approximation
--  of the upper image P[S]+R_+^q. This package focuses on the bi-objective
--  (q=2) case: find nondominated extreme outcomes via dichotomic weighted-
--  sum scalarizations (supported extremes) plus a simplified Benson-style
--  outer box / cut loop spirit. Embedded dense Bland two-phase tableau
--  simplex for scalarized LPs (sibling ideas; no with-clause dependency).
--  Primary source:
--  https://en.wikipedia.org/wiki/Benson%27s_algorithm
--  Siblings: Ada-Simplex-Algorithm; Ada-Cutting-Plane-Method.

pragma Ada_2022;

package Bensons_Algorithm
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   --  Educational caps: decision vars n ≤ 8, constraints m ≤ 12.
   Max_Constraints : constant := 14;  -- m ≤ 12 + Phase-I row slot
   Max_Vars        : constant := 24;  -- n + slacks + artificials
   Max_Decision    : constant := 8;
   Max_Front       : constant := 16;  -- nondominated extreme outcomes

   subtype Constraint_Count is Natural range 0 .. Max_Constraints;
   subtype Var_Count        is Natural range 0 .. Max_Vars;
   subtype Decision_Count   is Natural range 0 .. Max_Decision;
   subtype Front_Count      is Natural range 0 .. Max_Front;
   subtype Constraint_Index is Positive range 1 .. Max_Constraints;
   subtype Var_Index        is Positive range 1 .. Max_Vars;
   subtype Decision_Index   is Positive range 1 .. Max_Decision;
   subtype Front_Index      is Positive range 1 .. Max_Front;

   type Matrix is
     array (Constraint_Index range <>, Var_Index range <>) of Real;
   type Vector is array (Positive range <>) of Real;

   --  Two linear objectives (rows of P): Outcome = (P1·x, P2·x).
   type Outcome is record
      Y1 : Real := 0.0;
      Y2 : Real := 0.0;
   end record;

   type Status is
     (Optimal, Infeasible, Unbounded, Iteration_Limit, Empty_Front);

   --  Max_Pivots      : simplex pivot budget per scalarized LP
   --  Max_Dichotomy   : recursive dichotomic splits (Benson/dichotomic)
   --  Weight_Grid     : optional uniform weight samples on λ∈(0,1)
   --  Tol             : numerical zero / dominance / Near
   type Config is record
      Max_Pivots    : Positive      := 400;
      Max_Dichotomy : Positive      := 32;
      Weight_Grid   : Positive      := 11;
      Tol           : Positive_Real := 1.0E-9;
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

   --  One nondominated extreme point in outcome space (+ optional preimage).
   type Front_Point is record
      Y       : Outcome := (0.0, 0.0);
      X       : Vector (1 .. Max_Decision) := [others => 0.0];
      N_Vars  : Decision_Count := 0;
      Valid   : Boolean := False;
   end record;

   type Front_Array is array (Front_Index range <>) of Front_Point;

   type LP_Result is record
      Stat      : Status := Infeasible;
      Objective : Real := 0.0;
      X         : Vector (1 .. Max_Vars) := [others => 0.0];
      N_Vars    : Var_Count := 0;
      N_Pivots  : Natural := 0;
      Success   : Boolean := False;
   end record;

   type Result is record
      Stat         : Status := Empty_Front;
      Points       : Front_Array (1 .. Max_Front) :=
        [others => (Y => (0.0, 0.0), X => [others => 0.0],
                    N_Vars => 0, Valid => False)];
      N_Points     : Front_Count := 0;
      N_LP_Solves  : Natural := 0;
      N_Pivots     : Natural := 0;
      Success      : Boolean := False;
   end record;

   Invalid_Argument : exception;

   Epsilon_Tol : constant Real := 1.0E-9;

   ---------------------------------------------------------------------------
   -- Numeric / dominance helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Vec_Near
     (A, B : Vector; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => A'Length = B'Length and then Tol >= 0.0,
          Global => null;

   function Outcome_Near
     (A, B : Outcome; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Is_Dominated
     (Cand, Other : Outcome; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;
   --  True if Other weakly dominates Cand for minimization:
   --  Other.Y1 ≤ Cand.Y1 and Other.Y2 ≤ Cand.Y2 (within Tol) and
   --  at least one inequality is strict beyond Tol.

   function Is_Weakly_Dominated
     (Cand, Other : Outcome; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;
   --  Other.Yk ≤ Cand.Yk + Tol for both k (equality allowed).

   function Eval_Objectives
     (C1, C2 : Vector; X : Vector) return Outcome
     with Pre => C1'Length = C2'Length and then C1'Length = X'Length,
          Global => null;
   --  y = (c1ᵀx, c2ᵀx).

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
            and then A'Length (1) <= Max_Constraints - 1
            and then A'Length (2) + A'Length (1) <= Max_Vars,
          Global => null;

   function Extract_Primal
     (Tab : Tableau; N_Decision : Var_Count) return Vector
     with Pre => N_Decision <= Max_Vars, Global => null;

   function Solve_Tableau
     (Tab : in out Tableau;
      Cfg : Config := (others => <>)) return LP_Result;

   function Maximize_LP
     (A   : Matrix;
      B   : Vector;
      C   : Vector;
      Cfg : Config := (others => <>)) return LP_Result
     with Pre => A'Length (1) = B'Length
            and then A'Length (2) = C'Length
            and then A'Length (1) >= 1
            and then A'Length (2) >= 1
            and then A'Length (1) <= Max_Constraints - 1
            and then A'Length (2) <= Max_Decision
            and then A'Length (2) + A'Length (1) <= Max_Vars;
   --  Solve max cᵀx s.t. Ax ≤ b, x ≥ 0 (embedded Bland two-phase).

   function Minimize_LP
     (A   : Matrix;
      B   : Vector;
      C   : Vector;
      Cfg : Config := (others => <>)) return LP_Result
     with Pre => A'Length (1) = B'Length
            and then A'Length (2) = C'Length
            and then A'Length (1) >= 1
            and then A'Length (2) >= 1
            and then A'Length (1) <= Max_Constraints - 1
            and then A'Length (2) <= Max_Decision
            and then A'Length (2) + A'Length (1) <= Max_Vars;
   --  Solve min cᵀx s.t. Ax ≤ b, x ≥ 0 (negate objective, Maximize_LP).

   ---------------------------------------------------------------------------
   -- Scalarizations and bi-objective Benson / dichotomic solver
   ---------------------------------------------------------------------------

   function Weighted_Sum_Solve
     (A      : Matrix;
      B      : Vector;
      C1, C2 : Vector;
      Lambda : Real;
      Cfg    : Config := (others => <>)) return Front_Point
     with Pre => A'Length (1) = B'Length
            and then A'Length (2) = C1'Length
            and then C1'Length = C2'Length
            and then A'Length (1) >= 1
            and then A'Length (2) >= 1
            and then A'Length (2) <= Max_Decision
            and then A'Length (1) <= Max_Constraints - 1
            and then A'Length (2) + A'Length (1) <= Max_Vars
            and then Lambda >= 0.0
            and then Lambda <= 1.0;
   --  Minimize λ c1ᵀx + (1−λ) c2ᵀx s.t. Ax ≤ b, x ≥ 0.
   --  Returns outcome y and preimage x (Valid=False on LP failure).

   function Solve_Biobjective
     (A      : Matrix;
      B      : Vector;
      C1, C2 : Vector;
      Cfg    : Config := (others => <>)) return Result
     with Pre => A'Length (1) = B'Length
            and then A'Length (2) = C1'Length
            and then C1'Length = C2'Length
            and then A'Length (1) >= 1
            and then A'Length (2) >= 1
            and then A'Length (2) <= Max_Decision
            and then A'Length (1) <= Max_Constraints - 1
            and then A'Length (2) + A'Length (1) <= Max_Vars;
   --  Educational bi-objective Benson-style recovery of nondominated
   --  extreme outcomes of the upper image P[S]+R_+^2:
   --    1. Lexicographic anchors (min f1 then f2; min f2 then f1)
   --    2. Dichotomic weighted sums between consecutive front points
   --    3. Optional dense weight grid (Cfg.Weight_Grid) for robustness
   --    4. Filter weakly dominated / duplicate outcomes
   --  Points are sorted by increasing Y1 (then Y2).

end Bensons_Algorithm;
