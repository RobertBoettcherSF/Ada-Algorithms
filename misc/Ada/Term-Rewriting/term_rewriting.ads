with Ada.Strings.Unbounded;
with Ada.Containers.Indefinite_Multiway_Trees;
with Ada.Containers.Indefinite_Ordered_Maps;

package Term_Rewriting is

   type Term_Kind is (Variable_Node, Function_Node);
   type Step_Count is new Natural;
   type Argument_Index is new Positive;

   -- Internal Node Representation
   type Node_Type is record
      Kind : Term_Kind;
      Name : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   -- Required for Multiway_Trees structural equality
   function "=" (Left, Right : Node_Type) return Boolean;

   package Term_Trees is new Ada.Containers.Indefinite_Multiway_Trees
     (Element_Type => Node_Type);

   -- The Primary Abstract Data Type for Terms
   type Term is record
      AST : Term_Trees.Tree;
   end record;

   type Term_Array is array (Argument_Index range <>) of Term;

   -- Structural Equality
   function "=" (Left, Right : Term) return Boolean;

   -- Substitution mapping (Variable Name -> Term)
   package Substitution_Maps is new Ada.Containers.Indefinite_Ordered_Maps
     (Key_Type     => String,
      Element_Type => Term);

   subtype Substitution_Map is Substitution_Maps.Map;

   -- Rewriting Rules
   type Rule is private;
   type Rule_Array is array (Positive range <>) of Rule;

   -- Rewriting Strategies (Outermost = Normal Order, Innermost = Applicative Order)
   type Strategy_Type is (Innermost, Outermost);

   -- Exceptions
   Invalid_Rule_Error   : exception;
   Limit_Exceeded_Error : exception;
   Invalid_Term_Error   : exception;

   -- Term Construction API
   function Create_Variable (Name : String) return Term
     with Pre => Name'Length > 0;

   function Create_Function (Name : String; Args : Term_Array) return Term
     with Pre => Name'Length > 0;

   function Create_Constant (Name : String) return Term
     with Pre => Name'Length > 0;

   -- Rule Construction API
   -- Precondition: LHS must be a function, and variables in RHS must appear in LHS.
   function Create_Rule (Lhs : Term; Rhs : Term) return Rule;

   -- Rewriting Operations
   -- Applies at most one rewriting step based on the provided strategy.
   function Rewrite_Step
     (T        : Term;
      Rules    : Rule_Array;
      Strategy : Strategy_Type) return Term;

   -- Applies rules exhaustively until normal form is reached or Max_Steps is exceeded.
   function Normalize
     (T         : Term;
      Rules     : Rule_Array;
      Strategy  : Strategy_Type;
      Max_Steps : Step_Count) return Term
     with Pre => Max_Steps > 0;

   -- String formatting helper for visualization and testing
   function To_String (T : Term) return String;

private
   type Rule is record
      Lhs : Term;
      Rhs : Term;
   end record;

end Term_Rewriting;
