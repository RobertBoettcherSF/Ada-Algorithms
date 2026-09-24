pragma Ada_2022;
with Ada.Containers.Indefinite_Vectors;

--  Automated Theorem Proving
--
--  This package implements foundational algorithms for Propositional Logic
--  Satisfiability (SAT), a core component of Automated Theorem Proving (ATP).
--  It includes three distinct resolution and evaluation variants:
--  1. Exhaustive Truth Table evaluation.
--  2. DPLL (Davis-Putnam-Logemann-Loveland) algorithm.
--  3. DP (Davis-Putnam) Variable Elimination via Resolution.

package Automated_Theorem_Proving is

   --  Variables are represented by strictly positive integers.
   type Variable_ID is new Positive;

   --  Polarity of a literal (Positive = V, Negative = NOT V)
   type Polarity is (Positive_Pol, Negative_Pol);

   --  A Literal combines a variable and its polarity, enforcing 
   --  strong typing and inherently preventing invalid "0" literals.
   type Literal is record
      Var : Variable_ID;
      Pol : Polarity;
   end record;

   --  Constructor helpers for literals
   function Pos (V : Variable_ID) return Literal
      with Global => null, Post => Pos'Result.Pol = Positive_Pol;
      
   function Neg (V : Variable_ID) return Literal
      with Global => null, Post => Neg'Result.Pol = Negative_Pol;

   --  Negates a literal (swaps its polarity)
   function Negate (L : Literal) return Literal
      with Global => null, 
           Post => Negate'Result.Var = L.Var and then 
                   Negate'Result.Pol /= L.Pol;

   --  A clause is a disjunction (OR) of literals.
   type Clause is array (Positive range <>) of Literal;

   --  A formula in Conjunctive Normal Form (CNF) is a conjunction (AND) of clauses.
   package Formula_Vectors is new Ada.Containers.Indefinite_Vectors
     (Index_Type   => Positive,
      Element_Type => Clause);

   subtype CNF_Formula is Formula_Vectors.Vector;

   ---------------------------------------------------------------------------
   --  Algorithm Variants
   ---------------------------------------------------------------------------

   --  Variant 1: Exhaustive Truth Table evaluation.
   --  Iterates through 2^Max_Var assignments. 
   --  Precondition: Max_Var must be bounded to prevent excessive execution time.
   function Is_Satisfiable_Exhaustive (Formula : CNF_Formula; Max_Var : Variable_ID) return Boolean
      with Global => null, Pre => Natural (Max_Var) <= 24;

   --  Variant 2: DPLL (Davis-Putnam-Logemann-Loveland) algorithm.
   --  Utilizes unit propagation, pure literal elimination, and backtracking.
   function Is_Satisfiable_DPLL (Formula : CNF_Formula) return Boolean
      with Global => null;

   --  Variant 3: DP Resolution (Davis-Putnam Variable Elimination).
   --  Iteratively eliminates variables by generating resolvents, avoiding recursion.
   function Is_Satisfiable_DP_Resolution (Formula : CNF_Formula) return Boolean
      with Global => null;

   ---------------------------------------------------------------------------
   --  Helper Functions (Exposed for robust testing and modularity)
   ---------------------------------------------------------------------------

   --  Checks if a clause contains a specific literal.
   function Contains_Literal (C : Clause; L : Literal) return Boolean
      with Global => null;

   --  Checks if the formula contains an empty clause (which means it is unsatisfiable).
   function Contains_Empty_Clause (Formula : CNF_Formula) return Boolean
      with Global => null;

   --  Performs unit propagation: simplifies the formula assuming 'Unit' is True.
   function Simplify_Unit_Propagation (Formula : CNF_Formula; Unit : Literal) return CNF_Formula
      with Global => null;

   --  Performs pure literal elimination: removes all clauses containing 'Pure'.
   function Simplify_Pure_Literal (Formula : CNF_Formula; Pure : Literal) return CNF_Formula
      with Global => null;

   --  Resolves two clauses around a Pivot variable.
   function Resolve_Clauses (C1, C2 : Clause; Pivot : Variable_ID) return Clause
      with Global => null;

   --  Checks if a clause is a tautology (contains both a variable and its negation).
   function Is_Tautology (C : Clause) return Boolean
      with Global => null;

   --  Removes duplicate literals from a clause.
   function Remove_Duplicates (C : Clause) return Clause
      with Global => null;

end Automated_Theorem_Proving;
