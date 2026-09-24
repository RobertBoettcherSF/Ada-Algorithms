with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Containers.Vectors;

--  An Ada 2023 implementation of the Earley Parser.
--  The Earley algorithm parses context-free grammars (CFG), including
--  ambiguous, left-recursive, right-recursive, and nullable rules.
package Earley_Parser is

   --  Categories of symbols in our Context-Free Grammar.
   type Symbol_Kind is (Terminal, Non_Terminal);

   --  A Symbol is either a terminal (matched against input tokens)
   --  or a non-terminal (used in grammar rules).
   type Symbol is record
      Kind : Symbol_Kind;
      Name : Unbounded_String;
   end record;

   --  Equality check for symbols (used extensively during parsing)
   function "=" (Left, Right : Symbol) return Boolean;

   --  Helper constructors for Symbols
   function Create_Terminal (Name : String) return Symbol;
   function Create_Non_Terminal (Name : String) return Symbol;

   --  Vectors to store lists of symbols (for RHS of rules and Inputs)
   package Symbol_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Symbol);
   
   subtype Symbol_List is Symbol_Vectors.Vector;

   --  A production rule: LHS -> RHS (e.g., Expr -> Expr + Term)
   type Production is record
      LHS : Symbol;
      RHS : Symbol_List;
   end record
     with Dynamic_Predicate => Production.LHS.Kind = Non_Terminal;

   package Production_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Production);
   
   subtype Production_List is Production_Vectors.Vector;

   --  A grammar consists of a designated start symbol and a set of rules.
   type Grammar is record
      Start_Symbol : Symbol;
      Rules        : Production_List;
   end record
     with Dynamic_Predicate => Grammar.Start_Symbol.Kind = Non_Terminal;

   --  An Earley Item (State) representing progress in parsing a rule.
   type Item is record
      Rule_Index : Positive; -- Index into the Grammar's Rules
      Dot        : Natural;  -- Position in the RHS (0 = start)
      Origin     : Natural;  -- Input position where this rule started
   end record;

   function "=" (Left, Right : Item) return Boolean;

   package Item_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Item);
   
   subtype Item_List is Item_Vectors.Vector;

   use type Item_Vectors.Vector;

   --  A Chart is a sequence of Item_Lists, one for each input position (0 to N).
   package Chart_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Item_List);
   
   subtype Chart is Chart_Vectors.Vector;

   --  VARIANT 1: Parse Chart Generation (Parser)
   --  Returns the full Earley chart, which implicitly encodes the parse forest.
   function Parse_Chart (G : Grammar; Input : Symbol_List) return Chart
     with Pre => Natural (G.Rules.Length) > 0;

   --  VARIANT 2: Recognizer
   --  Returns True if the Input stream is successfully parsed by the Grammar.
   function Recognize (G : Grammar; Input : Symbol_List) return Boolean
     with Pre => Natural (G.Rules.Length) > 0;

end Earley_Parser;
