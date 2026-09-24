pragma Ada_2022;
package Naive_String_Search with SPARK_Mode => On is
   Text_Length : constant := 16;
   Pattern_Length : constant := 4;
   subtype Text_Index is Positive range 1 .. Text_Length;
   subtype Pattern_Index is Positive range 1 .. Pattern_Length;
   subtype Search_Result is Natural range 0 .. Text_Length;
   type Text_Array is array (Text_Index) of Character;
   type Pattern_Array is array (Pattern_Index) of Character;

   function Search (Text : Text_Array; Pattern : Pattern_Array)
      return Search_Result;
end Naive_String_Search;
