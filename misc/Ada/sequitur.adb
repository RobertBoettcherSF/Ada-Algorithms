-- sequitur.adb
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Unchecked_Deallocation;

package body Sequitur is
   -- Global state for the grammar
   Start_Rule : Rule_Access := new Rule_Record'(Id => 0, Head => null, Tail => null, Count => 1);
   Rule_Counter : Integer := 1;

   procedure Free is new Ada.Unchecked_Deallocation(Symbol_Node, Symbol_Access);

   procedure Reset_Grammar is
   begin
      -- Simplified reset for tests
      Start_Rule.Head := null;
      Start_Rule.Tail := null;
      Rule_Counter := 1;
   end Reset_Grammar;

   -- Adds a character to the current sequence
   procedure Add_Symbol (Val : Character) is
      New_Sym : Symbol_Access := new Symbol_Node'(Kind => Terminal, Value => Val, Rule => null, Next => null, Prev => Start_Rule.Tail, Parent => Start_Rule);
   begin
      if Start_Rule.Head = null then
         Start_Rule.Head := New_Sym;
         Start_Rule.Tail := New_Sym;
      else
         Start_Rule.Tail.Next := New_Sym;
         Start_Rule.Tail := New_Sym;
      end if;
      -- Note: Real implementation would check digrams here.
      -- This implementation serves as the architectural skeleton.
   end Add_Symbol;

   procedure Compress (Input : String) is
   begin
      Reset_Grammar;
      for C of Input loop
         Add_Symbol(C);
      end loop;
   end Compress;

   procedure Print_Grammar is
      Curr : Symbol_Access := Start_Rule.Head;
   begin
      Put("S -> ");
      while Curr /= null loop
         Put(Curr.Value);
         Curr := Curr.Next;
      end loop;
      New_Line;
   end Print_Grammar;

end Sequitur;
