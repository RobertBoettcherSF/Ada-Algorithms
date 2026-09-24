pragma Ada_2022;

package Reverse_String with SPARK_Mode => On is
   Length : constant := 6;
   subtype Index is Positive range 1 .. Length;
   type Text_Array is array (Index) of Character;

   function Reverse_Text (Input : Text_Array) return Text_Array
     with Global => null;
end Reverse_String;
