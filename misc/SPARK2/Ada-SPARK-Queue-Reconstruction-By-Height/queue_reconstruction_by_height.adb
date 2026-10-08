pragma Ada_2022;
package body Queue_Reconstruction_By_Height with SPARK_Mode => On is
   function Insert_Position (Queue_Length, People_Ahead : Queue_Position)
     return Queue_Position is
   begin
      if People_Ahead = Queue_Length then
         return Queue_Length;
      else
         return People_Ahead;
      end if;
   end Insert_Position;
end Queue_Reconstruction_By_Height;
