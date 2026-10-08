pragma Ada_2022;

package Isomorphic_Strings with SPARK_Mode => On is
   Length : constant := 6;
   subtype Index is Positive range 1 .. Length;
   type Text_Array is array (Index) of Character;

   function Are_Isomorphic (Left : Text_Array; Right : Text_Array)
     return Boolean
     with Global => null;
end Isomorphic_Strings;
