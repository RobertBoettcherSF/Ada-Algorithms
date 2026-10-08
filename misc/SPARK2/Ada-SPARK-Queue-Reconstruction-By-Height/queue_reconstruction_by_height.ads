pragma Ada_2022;
package Queue_Reconstruction_By_Height with SPARK_Mode => On is
   subtype Queue_Position is Natural range 0 .. 32;

   function Insert_Position (Queue_Length, People_Ahead : Queue_Position)
     return Queue_Position
     with Global => null,
          Pre => People_Ahead <= Queue_Length;
end Queue_Reconstruction_By_Height;
