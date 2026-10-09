pragma Ada_2022;

package body Search_2D_Matrix with SPARK_Mode => On is
   function Contains (Input : Matrix; Target : Value) return Search_Result is
      Probes : Probe_Count := 0;
   begin
      for R in Row loop
         for C in Column loop
            pragma Loop_Invariant (Probes = (R - 1) * Cols + C - 1);
            Probes := Probes + 1;
            if Input (R, C) = Target then
               return (Found => True, Probes => Probes);
            end if;
         end loop;
      end loop;
      return (Found => False, Probes => Probes);
   end Contains;
end Search_2D_Matrix;
