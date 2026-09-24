pragma Ada_2022;

package Strstr_Naive with SPARK_Mode => On is
   Text_Length : constant := 12;
   Pattern_Length : constant := 3;
   subtype Text_Index is Positive range 1 .. Text_Length;
   subtype Pattern_Index is Positive range 1 .. Pattern_Length;
   subtype Search_Result is Natural range 0 .. Text_Length;
   type Text_Array is array (Text_Index) of Character;
   type Pattern_Array is array (Pattern_Index) of Character;

   function Search (Text : Text_Array; Pattern : Pattern_Array)
     return Search_Result
     with Global => null;
end Strstr_Naive;
