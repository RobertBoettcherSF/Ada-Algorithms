pragma Ada_2022;

package Repeated_Substring_Pattern with SPARK_Mode => On is
   Length : constant := 6;
   subtype Index is Positive range 1 .. Length;
   type Text_Array is array (Index) of Character;

   function Is_Repeated (Input : Text_Array) return Boolean
     with Global => null;
end Repeated_Substring_Pattern;
