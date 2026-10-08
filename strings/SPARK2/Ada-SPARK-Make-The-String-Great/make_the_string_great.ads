pragma Ada_2022;

package Make_The_String_Great with SPARK_Mode => On is
   subtype Length_Type is Natural range 0 .. 32;
   subtype Index is Positive range 1 .. 32;
   type Text is array (Index) of Character;

   procedure Make_Great (Input : Text; Length : Length_Type;
                      Output : out Text; Output_Length : out Length_Type)
     with Global => null;
end Make_The_String_Great;
