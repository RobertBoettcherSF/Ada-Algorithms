pragma Ada_2022;

package Recursive_Descent_Parser is

   -- Domain type for numeric calculations to prevent bare Integer usage
   type Value_Type is new Integer;

   -- Exceptions raised during parsing or evaluation
   Syntax_Error     : exception;
   Evaluation_Error : exception;

   -- ====================================================================
   -- VARIANT 1: Evaluator
   -- ====================================================================
   -- Parses a mathematical expression and evaluates it on the fly.
   -- Grammar strictly follows the Wikipedia example (no unary operators):
   --   expression = term { ("+" | "-") term }
   --   term       = factor { ("*" | "/") factor }
   --   factor     = "(" expression ")" | integer
   -- Raises: Syntax_Error on malformed strings, Evaluation_Error on div/0.
   function Evaluate (Expression : String) return Value_Type
     with Global => null;

   -- ====================================================================
   -- VARIANT 2: Recognizer (Predictive LL(1))
   -- ====================================================================
   -- Pure predictive recognizer without backtracking.
   -- Returns True if the expression perfectly adheres to the EBNF grammar,
   -- False otherwise. Suppresses exceptions and returns cleanly.
   function Is_Valid (Expression : String) return Boolean
     with Global => null;

   -- ====================================================================
   -- VARIANT 3: Translator (Postfix / AST Emitter)
   -- ====================================================================
   -- Translates an infix expression into Reverse Polish Notation (RPN).
   -- Demonstrates tree traversal properties of recursive descent without
   -- performing intermediate computations.
   function To_Postfix (Expression : String) return String
     with Global => null;

end Recursive_Descent_Parser;
