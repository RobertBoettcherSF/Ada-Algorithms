with Ada.Strings.Unbounded;

package Step_Parser is

   -- Strong domain types for lexer and parser metrics
   type Line_Number is new Natural;
   type Column_Number is new Natural;
   type Paren_Count is new Natural;

   -- Token classification for ISO 10303-21 clear text encoding
   type Token_Kind is
     (Tok_None,
      Tok_EOF,
      Tok_Identifier,
      Tok_Keyword,
      Tok_Entity_Ref,
      Tok_String,
      Tok_Integer,
      Tok_Real,
      Tok_Enum,
      Tok_LParen,
      Tok_RParen,
      Tok_Comma,
      Tok_Semicolon,
      Tok_Equals,
      Tok_Asterisk,
      Tok_Dollar,
      Tok_Less,
      Tok_Greater);

   -- Token representation
   type Token is record
      Kind   : Token_Kind := Tok_None;
      Lexeme : Ada.Strings.Unbounded.Unbounded_String;
      Line   : Line_Number := 0;
      Col    : Column_Number := 0;
   end record;

   -- Opaque lexer state to hide implementation details
   type Lexer_State is tagged private;

   -- Exceptions for error handling
   Syntax_Error : exception;
   Unexpected_End_Of_File : exception;

   -- Initialize the lexer with the provided STEP file content
   procedure Initialize (State : out Lexer_State; Input : String)
     with Post => State.Is_Initialized;

   function Is_Initialized (State : Lexer_State) return Boolean;

   -- Extract the next token from the input stream
   procedure Next_Token (State : in out Lexer_State; Tok : out Token)
     with Pre => State.Is_Initialized;

   -- Look ahead at the next token without consuming it
   procedure Peek_Token (State : in out Lexer_State; Tok : out Token)
     with Pre => State.Is_Initialized;

   -- Parse a single entity instance (e.g., #1 = POINT(0.0, 0.0); or HEADER_ENTITY(...);)
   procedure Parse_Entity_Instance (State : in out Lexer_State)
     with Pre => State.Is_Initialized;

   -- Variant 1: Parse the HEADER section
   procedure Parse_Header_Section (State : in out Lexer_State)
     with Pre => State.Is_Initialized;

   -- Variant 2: Parse the DATA section
   procedure Parse_Data_Section (State : in out Lexer_State)
     with Pre => State.Is_Initialized;

   -- Variant 3: Parse the ANCHOR section (Edition 3 extension)
   procedure Parse_Anchor_Section (State : in out Lexer_State)
     with Pre => State.Is_Initialized;

   -- Variant 4: Parse the REFERENCE section (Edition 3 extension)
   procedure Parse_Reference_Section (State : in out Lexer_State)
     with Pre => State.Is_Initialized;

   -- Variant 5: Parse the SIGNATURE section (Edition 3 extension)
   procedure Parse_Signature_Section (State : in out Lexer_State)
     with Pre => State.Is_Initialized;

   -- Parse the entire ISO-10303-21 Exchange Structure
   procedure Parse_Exchange_Structure (State : in out Lexer_State)
     with Pre => State.Is_Initialized;

private

   type Lexer_State is tagged record
      Input       : Ada.Strings.Unbounded.Unbounded_String;
      Cursor      : Positive := 1;
      Line        : Line_Number := 1;
      Col         : Column_Number := 1;
      Initialized : Boolean := False;
      Has_Cached  : Boolean := False;
      Cached      : Token;
   end record;

end Step_Parser;
