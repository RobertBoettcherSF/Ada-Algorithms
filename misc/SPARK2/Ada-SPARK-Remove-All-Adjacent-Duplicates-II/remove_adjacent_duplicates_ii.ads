pragma Ada_2022;

package Remove_Adjacent_Duplicates_II with SPARK_Mode => On is
   subtype Length_Type is Natural range 0 .. 32;
   subtype Index is Positive range 1 .. 32;
   type Text is array (Index) of Character;

   procedure Remove_Duplicates (Input : Text; Length : Length_Type;
                      Output : out Text; Output_Length : out Length_Type)
     with Global => null;
end Remove_Adjacent_Duplicates_II;
