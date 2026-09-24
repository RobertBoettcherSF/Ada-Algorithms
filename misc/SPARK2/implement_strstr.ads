pragma Ada_2022;
package Implement_StrStr with SPARK_Mode => On is
   Haystack_Length : constant := 16;
   Needle_Length : constant := 4;
   subtype Hay_Index is Positive range 1 .. Haystack_Length;
   subtype Needle_Index is Positive range 1 .. Needle_Length;
   subtype Result_Index is Natural range 0 .. Haystack_Length;
   type Haystack is array (Hay_Index) of Character;
   type Needle is array (Needle_Index) of Character;
   function Find (Hay : Haystack; Need : Needle) return Result_Index with Global => null;
end Implement_StrStr;
