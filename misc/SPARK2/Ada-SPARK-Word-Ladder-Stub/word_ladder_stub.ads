pragma SPARK_Mode (On);

package Word_Ladder_Stub is
   Word_Length : constant := 3;
   subtype Character_Position is Positive range 1 .. Word_Length;
   subtype Word_Count_Range is Positive range 1 .. 5;
   type Word is array (Character_Position) of Character;
   type Word_Array is array (Word_Count_Range) of Word;
   subtype Ladder_Length is Integer range 0 .. 10;

   function Distance (Start_Word, End_Word : Word; Dictionary : Word_Array) return Ladder_Length;
end Word_Ladder_Stub;
