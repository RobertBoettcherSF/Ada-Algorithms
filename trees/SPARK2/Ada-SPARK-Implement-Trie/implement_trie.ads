--  PLACEHOLDER: flat word list with linear lookup; no trie nodes; see tools/vv/hidden_stub.csv
pragma Ada_2022;

package Implement_Trie with SPARK_Mode => On is
   pragma Assertion_Policy (Pre => Check);
   Max_Words : constant := 8;
   Max_Length : constant := 8;
   subtype Length_Range is Natural range 0 .. Max_Length;
   subtype Position is Positive range 1 .. Max_Length;
   subtype Word_Index is Positive range 1 .. Max_Words;
   subtype Word_Count is Natural range 0 .. Max_Words;
   subtype Letter is Character range 'a' .. 'd';
   type Word_Chars is array (Position) of Letter;
   type Word is record
      Len : Length_Range := 0;
      Chars : Word_Chars := [others => 'a'];
   end record;
   type Word_Array is array (Word_Index) of Word;
   type Trie is record
      Used : Word_Count := 0;
      Words : Word_Array := [others => (Len => 0, Chars => [others => 'a'])];
   end record;
   --  Inserting a word already present changes nothing (idempotent); a new word needs a free slot.
   procedure Insert (T : in out Trie; W : in Word)
     with Pre => T.Used < Max_Words or else Contains (T, W);
   function Contains (T : Trie; W : Word) return Boolean with Global => null;
end Implement_Trie;
