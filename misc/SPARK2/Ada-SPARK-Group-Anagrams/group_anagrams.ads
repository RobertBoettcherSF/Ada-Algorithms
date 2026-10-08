pragma Ada_2022;

package Group_Anagrams with SPARK_Mode => On is
   Word_Length : constant := 5;
   Word_Count : constant := 3;
   subtype Position is Positive range 1 .. Word_Length;
   subtype Word_Index is Positive range 1 .. Word_Count;
   subtype Label is Positive range 1 .. Word_Count;
   type Word is array (Position) of Character;
   type Word_Set is array (Word_Index) of Word;
   type Labels is array (Word_Index) of Label;

   function Group (Input : Word_Set) return Labels with Global => null;
end Group_Anagrams;
