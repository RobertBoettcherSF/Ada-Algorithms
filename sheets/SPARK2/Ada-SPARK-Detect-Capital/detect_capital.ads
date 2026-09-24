pragma Ada_2022;

package Detect_Capital with SPARK_Mode => On is
   Length : constant := 6;
   subtype Index is Positive range 1 .. Length;
   type Text_Array is array (Index) of Character;

   function Is_Correct (Input : Text_Array) return Boolean
     with Global => null;
end Detect_Capital;
