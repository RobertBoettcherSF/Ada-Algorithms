package Program_Synthesis is
   pragma Preelaborate;

   -- Domain types for the synthesized programs
   type Value_Type is new Integer;

   type Example is record
      Input  : Value_Type;
      Output : Value_Type;
   end record;

   type Example_Array is array (Positive range <>) of Example;

   -- Abstract Syntax Tree (AST) definition for the synthesized language
   type Node_Kind is (Var_X, Var_Out, Const_Val, Op_Add, Op_Sub, Hole);

   type AST_Node;
   type AST_Ptr is access all AST_Node;

   type AST_Node (Kind : Node_Kind := Const_Val) is record
      case Kind is
         when Var_X | Var_Out =>
            null;
         when Const_Val =>
            Value : Value_Type;
         when Op_Add | Op_Sub =>
            Left, Right : AST_Ptr;
         when Hole =>
            Hole_Id : Positive;
      end case;
   end record;

   type Hole_Values is array (Positive range <>) of Value_Type;
   Empty_Holes : constant Hole_Values (1 .. 0) := [others => 0];

   -- Exceptions
   Synthesis_Failed : exception;
   Evaluation_Error : exception;

   -- Evaluates the AST given an input X. Raises Evaluation_Error on overflow or if holes exist.
   function Evaluate (Program : AST_Ptr; X : Value_Type) return Value_Type
     with Pre => Program /= null;

   -- Evaluates the AST using a context for Hole values.
   function Evaluate_With_Holes 
     (Program : AST_Ptr; 
      X       : Value_Type; 
      Holes   : Hole_Values) return Value_Type
     with Pre => Program /= null;

   -- Returns true if the Program correctly satisfies all Input/Output examples.
   function Satisfies (Program : AST_Ptr; Examples : Example_Array) return Boolean
     with Pre => Program /= null and then Examples'Length > 0;

   -- Variant 1: Inductive Synthesis (Programming by Example / Enumerative Search)
   -- Generates programs bottom-up until it finds one that satisfies the examples.
   function Synthesize_By_Example
     (Examples   : Example_Array;
      Max_Budget : Positive) return AST_Ptr
     with Pre => Examples'Length > 0,
          Post => Synthesize_By_Example'Result /= null;

   -- Variant 2: Sketching
   -- Takes an AST with 'Hole' nodes and searches for constant values that satisfy the examples.
   function Synthesize_From_Sketch
     (Sketch    : AST_Ptr;
      Examples  : Example_Array;
      Max_Val   : Value_Type) return AST_Ptr
     with Pre => Sketch /= null and then Examples'Length > 0,
          Post => Synthesize_From_Sketch'Result /= null;

   -- Variant 3: Deductive Synthesis
   -- Solves an equation (Left_AST = Right_AST) by applying algebraic rewrite rules 
   -- to isolate 'Var_Out' on the left side, returning the synthesized right side.
   function Synthesize_Deductive (Equation_Left, Equation_Right : AST_Ptr) return AST_Ptr
     with Pre => Equation_Left /= null and then Equation_Right /= null,
          Post => Synthesize_Deductive'Result /= null;

   -- Memory Management & Utilities
   function Clone (Program : AST_Ptr) return AST_Ptr
     with Pre => Program /= null,
          Post => Clone'Result /= null;

   procedure Free (Program : in out AST_Ptr);

   function To_String (Program : AST_Ptr) return String
     with Pre => Program /= null;

end Program_Synthesis;
