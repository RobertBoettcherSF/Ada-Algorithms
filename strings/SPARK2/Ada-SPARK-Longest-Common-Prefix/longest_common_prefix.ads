pragma Ada_2022;

package Longest_Common_Prefix with SPARK_Mode => On is
   Length : constant := 8;
   subtype Index is Natural range 0 .. Length;
   subtype Text_Index is Positive range 1 .. Length;
   type Text_Array is array (Text_Index) of Character;
   type Text_Set is array (Positive range 1 .. 3) of Text_Array;

   function Prefix_Length (Input : Text_Set) return Index
     with Global => null;
end Longest_Common_Prefix;
