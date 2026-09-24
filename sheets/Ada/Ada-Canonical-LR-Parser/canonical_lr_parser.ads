-- canonical_lr_parser.ads
-- Specification for Canonical LR(1) Parser in Ada 2023

with Ada.Containers.Vectors;
with Ada.Containers.Ordered_Sets;
with Ada.Containers.Ordered_Maps;

package Canonical_LR_Parser is

   -- Domain types for grammar and LR(1) parser
   type Symbol_Kind is (Terminal, Nonterminal, End_Of_Input, Epsilon);
   
   subtype Symbol_Index is Natural;
   subtype Rule_Index is Positive;
   subtype State_Index is Natural;

   -- Action kinds for ACTION table
   type Action_Kind is (Shift, Reduce, Accept_Action, Error_Action);

   type Action_Type (Kind : Action_Kind := Error_Action) is record
      case Kind is
         when Shift =>
            Target_State : State_Index;
         when Reduce =>
            Production : Rule_Index;
         when Accept_Action | Error_Action =>
            null;
      end case;
   end record;

   -- Grammar production rule representation
   package Symbol_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Symbol_Index);

   type Production_Record is record
      LHS : Symbol_Index;
      RHS : Symbol_Vectors.Vector;
   end record;

   package Production_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Rule_Index,
      Element_Type => Production_Record);

   -- LR(1) Item: Production, Dot Position, Lookahead Terminal
   type LR1_Item is record
      Rule_No   : Rule_Index;
      Dot_Pos   : Natural;
      Lookahead : Symbol_Index;
   end record;

   function "<" (Left, Right : LR1_Item) return Boolean;

   package Item_Sets is new Ada.Containers.Ordered_Sets
     (Element_Type => LR1_Item);

   package Item_Set_Vectors is new Ada.Containers.Vectors
     (Index_Type   => State_Index,
      Element_Type => Item_Sets.Set,
      "="          => Item_Sets."=");

   -- Grammar definition record
   type Grammar_Definition is record
      Productions       : Production_Vectors.Vector;
      Start_Symbol      : Symbol_Index;
      Terminal_Count    : Natural;
      Nonterminal_Count : Natural;
      EOF_Symbol        : Symbol_Index;
   end record;

   -- Table keys for ACTION and GOTO tables
   type Table_Key is record
      State  : State_Index;
      Symbol : Symbol_Index;
   end record;

   function "<" (Left, Right : Table_Key) return Boolean;

   package Action_Maps is new Ada.Containers.Ordered_Maps
     (Key_Type     => Table_Key,
      Element_Type => Action_Type);

   package Goto_Maps is new Ada.Containers.Ordered_Maps
     (Key_Type     => Table_Key,
      Element_Type => State_Index);

   type Parsing_Table is record
      Actions : Action_Maps.Map;
      Gotos   : Goto_Maps.Map;
      States  : Item_Set_Vectors.Vector;
   end record;

   -- Exceptions
   Grammar_Error : exception;
   Syntax_Error  : exception;

   -- Public Subprograms

   -- Validates grammar well-formedness
   procedure Validate_Grammar (G : in Grammar_Definition)
     with Pre  => not G.Productions.Is_Empty,
          Post => True;

   -- Builds LR(1) parsing table and canonical collection of item sets
   procedure Build_Parsing_Table 
     (G     : in  Grammar_Definition;
      Table : out Parsing_Table)
     with Pre  => not G.Productions.Is_Empty;

   -- Parses a sequence of tokens using the Canonical LR(1) table
   procedure Parse
     (Table    : in  Parsing_Table;
      G        : in  Grammar_Definition;
      Tokens   : in  Symbol_Vectors.Vector;
      Accepted : out Boolean)
     with Pre  => not Tokens.Is_Empty;

   -- Helper to create a standard sample arithmetic expression grammar
   procedure Create_Expression_Grammar (G : out Grammar_Definition);

end Canonical_LR_Parser;
