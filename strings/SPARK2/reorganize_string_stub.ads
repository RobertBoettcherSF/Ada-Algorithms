pragma Ada_2022;

package Reorganize_String_Stub with SPARK_Mode => On is
   subtype Index is Positive range 1 .. 8;
   subtype Half_Index is Positive range 1 .. 4;
   type Char_Array is array (Index) of Character;

   function Reorganize (Input : Char_Array) return Char_Array
     with Global => null;
end Reorganize_String_Stub;
