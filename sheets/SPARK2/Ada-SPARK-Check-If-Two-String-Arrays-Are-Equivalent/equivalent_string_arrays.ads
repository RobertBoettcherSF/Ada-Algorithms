pragma Ada_2022;

package Equivalent_String_Arrays with SPARK_Mode => On is
   subtype Length_Type is Natural range 0 .. 32;
   subtype Index is Positive range 1 .. 32;
   type Text is array (Index) of Character;

   function Are_Equivalent (Left : Text; Left_Length : Length_Type;
                             Right : Text; Right_Length : Length_Type) return Boolean
     with Global => null;
end Equivalent_String_Arrays;
