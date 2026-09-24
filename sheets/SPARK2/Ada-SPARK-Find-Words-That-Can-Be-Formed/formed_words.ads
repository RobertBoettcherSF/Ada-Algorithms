pragma Ada_2022;

package Formed_Words with SPARK_Mode => On is
   subtype Length_Type is Natural range 0 .. 32;
   subtype Index is Positive range 1 .. 32;
   type Text is array (Index) of Character;

   function Can_Be_Formed
     (Available       : Text;
      Available_Length : Length_Type;
      Word             : Text;
      Word_Length      : Length_Type) return Boolean
     with Global => null;
end Formed_Words;
