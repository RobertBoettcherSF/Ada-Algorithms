pragma Ada_2022;
package body Move_To_Front with SPARK_Mode => On is
   procedure Move (Values : in out Table; Position : Index) is
      Saved : constant Character := Values (Position);
   begin
      for I in reverse 2 .. Position loop
         Values (I) := Values (I - 1);
      end loop;
      Values (1) := Saved;
   end Move;
end Move_To_Front;
