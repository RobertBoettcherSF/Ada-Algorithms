pragma Assertion_Policy (Check);

package Abstract_Syntax_Tree is

   -- Custom types for strong typing
   type Value_Type is new Integer;
   type Variable_ID is range 1 .. 26; -- Represents variables 'A' through 'Z'

   -- Kinds of nodes in the AST
   type Node_Kind is (Kind_Literal, Kind_Variable, Kind_Unary_Op, Kind_Binary_Op);
   
   -- Supported operators
   type Binary_Op_Kind is (Op_Add, Op_Sub, Op_Mul, Op_Div);
   type Unary_Op_Kind is (Op_Neg);

   -- Environment maps variables to their current values
   type Environment is array (Variable_ID) of Value_Type;

   -- The AST node and its access type
   type AST_Node;
   type AST_Node_Access is access AST_Node;

   type AST_Node (Kind : Node_Kind) is record
      case Kind is
         when Kind_Literal =>
            Value : Value_Type;
         when Kind_Variable =>
            Id : Variable_ID;
         when Kind_Unary_Op =>
            U_Op    : Unary_Op_Kind;
            Operand : AST_Node_Access;
         when Kind_Binary_Op =>
            B_Op    : Binary_Op_Kind;
            Left    : AST_Node_Access;
            Right   : AST_Node_Access;
      end case;
   end record;

   -- Exception raised for runtime evaluation errors (e.g., division by zero)
   Evaluation_Error : exception;

   -----------------------------------------------------------------------------
   -- Constructors (Dynamic Tree Construction Variants)
   -----------------------------------------------------------------------------

   function Create_Literal (Value : Value_Type) return AST_Node_Access
     with Post => Create_Literal'Result /= null and then Create_Literal'Result.Kind = Kind_Literal;

   function Create_Variable (Id : Variable_ID) return AST_Node_Access
     with Post => Create_Variable'Result /= null and then Create_Variable'Result.Kind = Kind_Variable;

   function Create_Unary (Op : Unary_Op_Kind; Operand : AST_Node_Access) return AST_Node_Access
     with Pre  => Operand /= null,
          Post => Create_Unary'Result /= null and then Create_Unary'Result.Kind = Kind_Unary_Op;

   function Create_Binary (Op : Binary_Op_Kind; Left, Right : AST_Node_Access) return AST_Node_Access
     with Pre  => Left /= null and Right /= null,
          Post => Create_Binary'Result /= null and then Create_Binary'Result.Kind = Kind_Binary_Op;

   -----------------------------------------------------------------------------
   -- Operations and Traversals
   -----------------------------------------------------------------------------

   -- Evaluates the AST using an interpreter pattern
   function Evaluate (Node : AST_Node_Access; Env : Environment) return Value_Type
     with Pre => Node /= null;

   -- Stringifies the AST (unparser/code generation variant)
   function To_String (Node : AST_Node_Access) return String
     with Pre => Node /= null;

   -- Analyzes the tree structure (metrics variant)
   function Node_Count (Node : AST_Node_Access) return Positive
     with Pre => Node /= null;

   -- Computes the maximum depth of the AST
   function Tree_Depth (Node : AST_Node_Access) return Positive
     with Pre => Node /= null;

   -- Frees the memory of the AST recursively
   procedure Free_Tree (Node : in out AST_Node_Access)
     with Post => Node = null;

   -----------------------------------------------------------------------------
   -- Helper Functions
   -----------------------------------------------------------------------------

   -- Converts a character (a-z or A-Z) to a strongly typed Variable_ID
   function Char_To_Var (C : Character) return Variable_ID
     with Pre  => C in 'A' .. 'Z' or C in 'a' .. 'z',
          Global => null;

   -- Converts a Variable_ID back to its uppercase character representation
   function Var_To_Char (Id : Variable_ID) return Character
     with Global => null;

end Abstract_Syntax_Tree;
