pragma Ada_2022;

package String_Compression with SPARK_Mode => On is
   subtype Length_Type is Natural range 0 .. 32;
   subtype Index is Positive range 1 .. 32;
   type Text is array (Index) of Character;
   type Run_Counts is array (Index) of Length_Type;

   procedure Compress (Input : Text; Length : Length_Type; Output : out Text;
                       Counts : out Run_Counts; Output_Length : out Length_Type)
     with Global => null;
end String_Compression;
