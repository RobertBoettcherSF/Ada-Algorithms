package Shunting_Yard is
   pragma Preelaborate;

   -- Domain definitions for the expression syntax
   type Token_Class is (Number, Operator, Func, Left_Paren, Right_Paren, Comma);
   type Associativity_Type is (Left, Right);
   type Operator_Kind is (Add, Subtract, Multiply, Divide, Power);
   type Function_Kind is (Sin, Cos, Max2); -- Max2 requires 2 arguments

   -- Strongly typed Token utilizing a variant record semantics
   type Token (Class : Token_Class := Number) is record
      case Class is
         when Number =>
            Value : Float;
         when Operator =>
            Op    : Operator_Kind;
         when Func =>
            Fun   : Function_Kind;
         when Left_Paren | Right_Paren | Comma =>
            null;
      end case;
   end record;

   type Token_Array is array (Positive range <>) of Token;

   -- Bounded queue for results to avoid dynamic allocations
   Max_Tokens : constant Positive := 1024;
   
   type Token_List is record
      Elements : Token_Array (1 .. Max_Tokens);
      Length   : Natural := 0;
   end record;

   -- AST Node Definition
   type AST_Node;
   type AST_Node_Access is access all AST_Node;
   
   type AST_Node (Class : Token_Class := Number) is record
      case Class is
         when Number =>
            Value       : Float;
         when Operator =>
            Op          : Operator_Kind;
            Left_Child  : AST_Node_Access;
            Right_Child : AST_Node_Access;
         when Func =>
            Fun         : Function_Kind;
            Arg1, Arg2  : AST_Node_Access;
         when others => 
            null;
      end case;
   end record;

   -- Exceptions for error handling and algorithmic edge cases
   Mismatched_Parentheses : exception;
   Invalid_Expression     : exception;
   Capacity_Exceeded      : exception;
   Math_Error             : exception;

   -- Operator characteristics queries
   function Precedence (Op : Operator_Kind) return Positive
     with Global => null;
     
   function Associativity (Op : Operator_Kind) return Associativity_Type
     with Global => null;

   -- Variant 1: Infix Expression to Reverse Polish Notation (Queue)
   function To_Reverse_Polish_Notation (Infix : Token_Array) return Token_List
     with Pre => Infix'Length > 0,
          Global => null;

   -- Variant 2: RPN queue to Abstract Syntax Tree representation
   function To_AST (RPN : Token_List) return AST_Node_Access
     with Pre => RPN.Length > 0,
          Global => null;

   -- Variant 3: Execute (Evaluate) a sequence in RPN directly
   function Evaluate_RPN (RPN : Token_List) return Float
     with Pre => RPN.Length > 0,
          Global => null;

   -- Variant 4: Execute (Evaluate) an Abstract Syntax Tree
   function Evaluate_AST (Node : AST_Node_Access) return Float
     with Pre => Node /= null,
          Global => null;

   -- Memory Management for AST Variant
   procedure Free_AST (Node : in out AST_Node_Access)
     with Global => null;

end Shunting_Yard;
