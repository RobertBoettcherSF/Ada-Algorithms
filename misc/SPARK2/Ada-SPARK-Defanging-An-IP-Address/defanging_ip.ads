pragma Ada_2022;
package Defanging_IP with SPARK_Mode => On is
   subtype Length_Type is Natural range 0 .. 32;
   subtype Index is Positive range 1 .. 32;
   type Text is array (Index) of Character;
   --  Every '.' becomes the three characters "[.]", so the output can be up
   --  to three times as long as the input; it is never truncated.
   subtype Out_Length_Type is Natural range 0 .. 3 * 32;
   subtype Out_Index is Positive range 1 .. 3 * 32;
   type Out_Text is array (Out_Index) of Character;
   procedure Defang (Input : Text; Length : Length_Type;
                      Output : out Out_Text; Output_Length : out Out_Length_Type)
     with Global => null,
          Post   => Output_Length in Length .. 3 * Length;
end Defanging_IP;
