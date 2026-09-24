pragma Ada_2022;

package Robot_Origin with SPARK_Mode => On is
   subtype Length_Type is Natural range 0 .. 32;
   subtype Index is Positive range 1 .. 32;
   type Text is array (Index) of Character;

   function Returns_To_Origin (Moves : Text; Length : Length_Type) return Boolean
     with Global => null;
end Robot_Origin;
