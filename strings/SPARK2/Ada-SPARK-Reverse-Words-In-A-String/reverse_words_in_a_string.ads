pragma Ada_2022;

package Reverse_Words_In_A_String with SPARK_Mode => On is
   Length : constant := 11;
   subtype Index is Positive range 1 .. Length;
   type Text_Array is array (Index) of Character;

   function Reverse_Words (Input : Text_Array) return Text_Array
     with Global => null;
end Reverse_Words_In_A_String;
