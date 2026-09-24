pragma Ada_2022;

package body Move_Zeroes with SPARK_Mode => On is
   function Move (Input : Input_Array) return Input_Array is
      Result : Input_Array := [others => 0];
      Position : Move_Zeroes.Position := 1;
   begin
      for I in Index loop
         if Input (I) /= 0 then
            Result (Index (Position)) := Input (I);
            Position := Position + 1;
         end if;
      end loop;
      return Result;
   end Move;
end Move_Zeroes;
