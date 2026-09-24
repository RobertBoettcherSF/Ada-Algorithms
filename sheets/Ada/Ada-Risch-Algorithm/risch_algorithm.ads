-- risch_algorithm.ads
-- Specification for the Risch Algorithm Framework in Ada
-- Implements symbolic representation and differential algebraic structures.

package Risch_Algorithm is

   -- Core mathematical expression kinds for differential algebra
   type Expr_Kind is (Val, Var, Add, Sub, Mul, Div, Pow, Exp_Func, Log_Func);
   
   type Expression_Node;
   type Expression is access Expression_Node;
   
   type Expression_Node (Kind : Expr_Kind := Val) is record
      case Kind is
         when Val => Value : Float;
         when Var => Name : Character;
         when Add | Sub | Mul | Div | Pow =>
            Left, Right : Expression;
         when Exp_Func | Log_Func =>
            Operand : Expression;
      end case;
   end record;

   -- Exceptions mapped to algorithm failure modes
   Non_Elementary_Integral : exception;
   Invalid_Expression      : exception;
   Division_By_Zero        : exception;

   -- Symbolic constructors
   function Create_Val (V : Float) return Expression;
   function Create_Var (N : Character) return Expression;
   function Create_Exp (Op : Expression) return Expression;
   function Create_Log (Op : Expression) return Expression;

   -- Overloaded operators for intuitive symbolic construction
   function "+" (L, R : Expression) return Expression;
   function "-" (L, R : Expression) return Expression;
   function "*" (L, R : Expression) return Expression;
   function "/" (L, R : Expression) return Expression;
   function "**" (L, R : Expression) return Expression; -- Fixed: Ada uses ** for exponentiation

   -- Core Risch Algorithm Variants and Sub-algorithms
   
   -- 1. Main Integration Dispatcher
   function Integrate (E : Expression; X : Character) return Expression;
   
   -- 2. Hermite Reduction for Rational Functions (Variant)
   function Hermite_Reduction (E : Expression; X : Character) return Expression;
   
   -- 3. Transcendental Extension Integration (Log/Exp)
   function Integrate_Transcendental (E : Expression; X : Character) return Expression;
   
   -- 4. Risch-Norman Heuristic Variant (Parallel Integration)
   function Risch_Norman_Integrate (E : Expression; X : Character) return Expression;
   
   -- Helper: Symbolic Differentiation (Required for Liouville's Theorem checks)
   function Derive (E : Expression; X : Character) return Expression;
   
   -- Helper: Algebraic Simplification
   function Simplify (E : Expression) return Expression;

   -- Helper: Tree comparison
   function Is_Equal (L, R : Expression) return Boolean;

end Risch_Algorithm;
