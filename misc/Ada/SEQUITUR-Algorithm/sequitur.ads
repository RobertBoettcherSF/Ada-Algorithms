-- sequitur.ads
package Sequitur is
   -- A symbol can be a Terminal (char) or a Non-Terminal (pointer to a Rule)
   type Symbol_Kind is (Terminal, Non_Terminal);
   
   type Rule_Record;
   type Rule_Access is access all Rule_Record;
   
   type Symbol_Node;
   type Symbol_Access is access all Symbol_Node;
   
   type Symbol_Node is record
      Kind   : Symbol_Kind;
      Value  : Character;        -- Used if Terminal
      Rule   : Rule_Access;      -- Used if Non_Terminal
      Next   : Symbol_Access;
      Prev   : Symbol_Access;
      Parent : Rule_Access;      -- Back-link to parent rule
   end record;
   
   type Rule_Record is record
      Id    : Integer;
      Head  : Symbol_Access;
      Tail  : Symbol_Access;
      Count : Integer := 0;      -- Usage counter
   end record;

   -- Public API
   procedure Compress (Input : String);
   procedure Print_Grammar;
   
   -- Helper to reset for testing
   procedure Reset_Grammar;
end Sequitur;
