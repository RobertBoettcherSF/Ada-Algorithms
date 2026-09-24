pragma Ada_2022;

with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package Simple_Precedence_Parser is

   -- Represents the Wirth-Weber precedence relations between symbols
   type Precedence_Relation is (None, Takes, Equal, Yields);
   -- Takes  (<) : The left symbol yields precedence to the right, starting a handle.
   -- Equal  (=) : Both symbols have the same precedence, forming a handle together.
   -- Yields (>) : The left symbol takes precedence, meaning the handle is complete.

   -- A grammar symbol (terminals and non-terminals alike in simple precedence)
   subtype Symbol is Character;
   
   -- Special symbol indicating the start/end of the input string and stack base
   End_Marker : constant Symbol := '$';

   -- The precedence matrix defines relations between any two symbols
   type Relation_Matrix is array (Symbol, Symbol) of Precedence_Relation;

   -- A production rule mapping a Left-Hand Side (LHS) to a Right-Hand Side (RHS)
   type Production is record
      LHS : Symbol;
      RHS : Unbounded_String;
   end record;

   type Production_Array is array (Positive range <>) of Production;

   -- The Parser state containing grammar and relation matrix.
   -- Discriminated record allows static allocation without heap or pointers.
   type Parser (Max_Prods : Natural) is tagged private;

   -- Instantiates a Parser for a given grammar and matrix
   function Create_Parser
     (Start_Symbol : Symbol;
      Prods        : Production_Array;
      Matrix       : Relation_Matrix) return Parser
     with Pre => Start_Symbol /= End_Marker,
          Global => null;

   -- Validates if a grammar meets the uniqueness property of Simple Precedence
   -- (No two rules can share the exact same RHS)
   function Is_Valid_Simple_Precedence_Grammar
     (Prods : Production_Array) return Boolean
     with Global => null;

   -- Standard parsing algorithm. Returns True if the input string is 
   -- accepted by the grammar, False otherwise. Highly optimized, no allocations.
   function Parse
     (P     : Parser;
      Input : String) return Boolean
     with Global => null;

   -- Diagnostic variant of the parsing algorithm. Outputs a step-by-step
   -- trace of shift and reduce actions to the Trace parameter.
   function Parse_With_Trace
     (P     : Parser;
      Input : String;
      Trace : out Unbounded_String) return Boolean
     with Global => null;

   Parse_Error   : exception;
   Grammar_Error : exception;

private
   
   type Parser (Max_Prods : Natural) is tagged record
      Start_Symbol : Symbol;
      Prods        : Production_Array (1 .. Max_Prods);
      Matrix       : Relation_Matrix;
   end record;

end Simple_Precedence_Parser;
