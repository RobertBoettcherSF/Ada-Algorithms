pragma Ada_2022;
package body Kadanes_Algorithm with SPARK_Mode => On is
   function Maximum_Subarray (A : Input) return Integer is
      Current : Integer := 0;
      Best : Integer := Integer'First;
   begin
      for I in Index loop
         if Current < 0 then
            Current := Integer (A (I));
         else
            Current := Current + Integer (A (I));
         end if;
         if Current > Best then Best := Current; end if;
      end loop;
      return Best;
   end Maximum_Subarray;
end Kadanes_Algorithm;
