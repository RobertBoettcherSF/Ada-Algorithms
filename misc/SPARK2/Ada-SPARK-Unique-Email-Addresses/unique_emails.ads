pragma Ada_2022;

package Unique_Emails with SPARK_Mode => On is
   subtype Length_Type is Natural range 0 .. 32;
   subtype Index is Positive range 1 .. 32;
   type Text is array (Index) of Character;

   procedure Normalize
     (Input         : Text;
      Length        : Length_Type;
      Output        : out Text;
      Output_Length : out Length_Type)
     with Global => null;
end Unique_Emails;
