pragma Ada_2022;

package Reverse_Words_In_A_String_III with SPARK_Mode => On is
   subtype Length_Type is Natural range 0 .. 32;
   subtype Index is Positive range 1 .. 32;
   type Text is array (Index) of Character;

   procedure Reverse_Words (Input : Text; Length : Length_Type;
                      Output : out Text; Output_Length : out Length_Type)
     with Global => null;
end Reverse_Words_In_A_String_III;
