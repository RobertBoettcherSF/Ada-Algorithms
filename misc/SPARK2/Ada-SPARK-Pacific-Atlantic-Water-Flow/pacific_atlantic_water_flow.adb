pragma Ada_2022;
package body Pacific_Atlantic_Water_Flow with SPARK_Mode => On is
   function Reachable (G : Grid) return Reachability is
      Result : Reachability;
   begin
      for R in Index loop
         for C in Index loop
            Result (R, C) := G (R, C) = 0;
         end loop;
      end loop;
      return Result;
   end Reachable;
end Pacific_Atlantic_Water_Flow;
