pragma Ada_2022;

package Reverse_Only_Letters with SPARK_Mode => On is
   subtype Length_Type is Natural range 0 .. 32;
   subtype Index is Positive range 1 .. 32;
   type Text is array (Index) of Character;

   procedure Reverse_Letters
     (Input         : Text;
      Length        : Length_Type;
      Output        : out Text)
     with Global => null;
end Reverse_Only_Letters;
