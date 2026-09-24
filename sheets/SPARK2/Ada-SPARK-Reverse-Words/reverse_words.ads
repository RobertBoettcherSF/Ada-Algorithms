pragma Ada_2022;
package Reverse_Words with SPARK_Mode => On is
   Word_Length : constant := 8;
   Count : constant := 4;
   subtype Word_Index is Positive range 1 .. Word_Length;
   subtype Position is Positive range 1 .. Count;
   type Word is array (Word_Index) of Character;
   type Word_List is array (Position) of Word;
   function Reversed (Input : Word_List) return Word_List with Global => null;
end Reverse_Words;
