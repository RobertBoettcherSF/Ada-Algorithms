pragma Ada_2022;

package Remove_Duplicate_Letters with SPARK_Mode => On is
   subtype Length_Type is Natural range 0 .. 32;
   subtype Index is Positive range 1 .. 32;
   subtype Letter is Natural range 0 .. 25;
   type Letters is array (Index) of Letter;

   procedure Keep_First (Input : Letters; Length : Length_Type; Output : out Letters;
                         Output_Length : out Length_Type)
     with Global => null;
end Remove_Duplicate_Letters;
