--------------------------------------------------------------------------------
-- Package: Simple_LR_Parser
-- Description: Implementation of a Simple LR (SLR) parser in Ada 2023.
--              Provides lexical tokenization, SLR parsing (standard and traced),
--              and static grammar conflict checking based on FOLLOW sets.
--------------------------------------------------------------------------------

with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;

package Simple_LR_Parser is

   -- Domain types for tokens and grammar symbols
   type Token_Kind is
     (Tok_Id,
      Tok_Plus,
      Tok_Star,
      Tok_L_Paren,
      Tok_R_Paren,
      Tok_Eof);

   type State_ID is range 0 .. 15;
   type Rule_ID is range 0 .. 6;

   type Action_Type is (Act_Shift, Act_Reduce, Act_Accept, Act_Error);

   type Parse_Action is record
      Kind  : Action_Type;
      Value : Integer; -- Target state for shift, rule ID for reduce
   end record;

   type Token_Rec is record
      Kind   : Token_Kind;
      Lexeme : Ada.Strings.Unbounded.Unbounded_String;
      Value  : Integer; -- Numeric value or identifier ID for evaluation
   end record;

   package Token_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Token_Rec);

   subtype Token_Sequence is Token_Vectors.Vector;

   type Parse_Result is record
      Success      : Boolean;
      Steps_Count  : Natural;
      Result_Value : Integer;
   end record;

   -- Exceptions for error handling
   Parse_Error            : exception;
   Invalid_Token_Error    : exception;
   Grammar_Conflict_Error : exception;

   -- Public subprograms

   -- Tokenizes an input string into a sequence of tokens
   function Tokenize (Text : String) return Token_Sequence;

   -- Standard SLR non-preemptive parser
   function Parse (Input : Token_Sequence) return Parse_Result
     with Pre => not Input.Is_Empty;

   -- Variant: SLR parser with step-by-step trace output buffer
   procedure Parse_With_Trace
     (Input        : Token_Sequence;
      Result       : out Parse_Result;
      Trace_Buffer : out Ada.Strings.Unbounded.Unbounded_String)
     with Pre => not Input.Is_Empty;

   -- Static analysis variant: verifies SLR table and FOLLOW set conflict status
   function Has_Conflicts return Boolean;

end Simple_LR_Parser;
