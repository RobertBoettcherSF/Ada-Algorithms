pragma Ada_2022;

package Implement_Trie with SPARK_Mode => On is
   Max_Words : constant := 8;
   Max_Length : constant := 8;
   subtype Length_Range is Natural range 0 .. Max_Length;
   subtype Position is Positive range 1 .. Max_Length;
   subtype Word_Index is Positive range 1 .. Max_Words;
   subtype Letter is Character range 'a' .. 'd';
   type Word_Chars is array (Position) of Letter;
   type Word is record
      Len : Length_Range := 0;
      Chars : Word_Chars := (others => 'a');
   end record;
   type Word_Array is array (Word_Index) of Word;
   type Trie is record
      Used : Length_Range := 0;
      Words : Word_Array := (others => (Len => 0, Chars => (others => 'a')));
   end record;
   procedure Insert (T : in out Trie; W : in Word);
   function Contains (T : Trie; W : Word) return Boolean with Global => null;
end Implement_Trie;
