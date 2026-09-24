--  Package specification for the DPLL (Davis-Putnam-Logemann-Loveland) algorithm
--  providing standard DPLL, Pure Literal Elimination only, Unit Propagation only,
--  and configurable branching heuristic variants.

package DPLL with
   SPARK_Mode => Off
is

   --  Maximum number of variables and clauses supported
   --  Reduced bounds to 64 to prevent stack overflows (STORAGE_ERROR) 
   --  when allocating multiple unconstrained Formula records in recursive frames.
   Max_Variables : constant := 64;
   Max_Literals  : constant := 64;
   Max_Clauses   : constant := 64;

   --  Strong domain types: Indexes are subtypes of Counts to unify constraint types
   type Variable_Count is range 0 .. Max_Variables;
   subtype Variable_Id is Variable_Count range 1 .. Max_Variables;

   type Literal_Count is range 0 .. Max_Literals;
   subtype Literal_Index is Literal_Count range 1 .. Max_Literals;

   type Clause_Count is range 0 .. Max_Clauses;
   subtype Clause_Index is Clause_Count range 1 .. Max_Clauses;

   --  Enumeration for literal sign; named to avoid collision with Standard.Positive
   type Sign_Type is (Positive_Sign, Negative_Sign);

   type Literal is record
      Var  : Variable_Id;
      Sign : Sign_Type;
   end record;

   type Literal_Array is array (Literal_Index range <>) of Literal;

   type Clause (Length : Literal_Count := 0) is record
      Lits : Literal_Array (1 .. Length);
   end record;

   type Clause_Array is array (Clause_Index range <>) of Clause;

   type Formula (Num_Clauses : Clause_Count := 0; Num_Vars : Variable_Count := 0) is record
      Clauses : Clause_Array (1 .. Num_Clauses);
   end record;

   type Variable_State is (Unassigned, Assigned_True, Assigned_False);

   type Valuation is array (Variable_Id) of Variable_State;

   type Solver_Status is (Satisfiable, Unsatisfiable);

   type Solver_Result (Status : Solver_Status := Unsatisfiable) is record
      case Status is
         when Satisfiable =>
            Model : Valuation;
         when Unsatisfiable =>
            null;
      end case;
   end record;

   --  Heuristics for variable selection during DPLL branching
   type Branching_Heuristic is
     (First_Unassigned,
      Max_Occurrences,
      MOMS); -- Maximum Occurrences in clauses of Minimum Size

   --  Exceptions
   Invalid_Formula_Error : exception;

   ----------------------------------------------------------------------------
   --  Helper & Validation Subprograms
   ----------------------------------------------------------------------------

   function Make_Pos (V : Variable_Id) return Literal with
      Inline,
      Post => Make_Pos'Result.Var = V and Make_Pos'Result.Sign = Positive_Sign;

   function Make_Neg (V : Variable_Id) return Literal with
      Inline,
      Post => Make_Neg'Result.Var = V and Make_Neg'Result.Sign = Negative_Sign;

   function Negate (L : Literal) return Literal with
      Inline,
      Post => Negate'Result.Var = L.Var and
              (if L.Sign = Positive_Sign then Negate'Result.Sign = Negative_Sign
               else Negate'Result.Sign = Positive_Sign);

   function Is_Valid_Formula (F : Formula) return Boolean;

   function Evaluate_Clause (C : Clause; M : Valuation) return Variable_State;

   function Is_Model (F : Formula; M : Valuation) return Boolean with
      Pre => Is_Valid_Formula (F);

   ----------------------------------------------------------------------------
   --  DPLL Variants
   ----------------------------------------------------------------------------

   --  Standard DPLL algorithm with unit propagation, pure literal elimination,
   --  and configurable branching heuristic.
   function Solve_DPLL
     (F         : Formula;
      Heuristic : Branching_Heuristic := First_Unassigned) return Solver_Result with
      Pre  => Is_Valid_Formula (F),
      Post => (if Solve_DPLL'Result.Status = Satisfiable then Is_Model (F, Solve_DPLL'Result.Model));

   --  Variant without pure literal elimination (Unit Propagation + Branching only)
   function Solve_Without_Pure_Literal
     (F         : Formula;
      Heuristic : Branching_Heuristic := First_Unassigned) return Solver_Result with
      Pre  => Is_Valid_Formula (F),
      Post => (if Solve_Without_Pure_Literal'Result.Status = Satisfiable then
                 Is_Model (F, Solve_Without_Pure_Literal'Result.Model));

   --  Pure Unit Propagation only (returns Satisfiable if simplified to empty formula,
   --  or Unsatisfiable if a conflict is found or undetermined).
   function Unit_Propagation_Only (F : Formula) return Solver_Result with
      Pre => Is_Valid_Formula (F);

   --  Pure Literal Rule Only (eliminates pure literals repeatedly; if undetermined,
   --  returns Unsatisfiable).
   function Pure_Literal_Only (F : Formula) return Solver_Result with
      Pre => Is_Valid_Formula (F);

end DPLL;
