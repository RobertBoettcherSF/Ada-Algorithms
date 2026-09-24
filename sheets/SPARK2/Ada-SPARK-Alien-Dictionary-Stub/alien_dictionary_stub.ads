pragma SPARK_Mode (On);

package Alien_Dictionary_Stub is
   Word_Length : constant := 3;
   subtype Character_Position is Positive range 1 .. Word_Length;
   subtype Word_Index is Positive range 1 .. 3;
   type Word is array (Character_Position) of Character;
   type Word_Array is array (Word_Index) of Word;

   function Is_Valid (Words : Word_Array) return Boolean;
end Alien_Dictionary_Stub;
