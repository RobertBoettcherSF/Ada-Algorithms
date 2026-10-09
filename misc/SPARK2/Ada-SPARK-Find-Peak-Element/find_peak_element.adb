pragma Ada_2022;

package body Find_Peak_Element with SPARK_Mode => On is
   function Find_Peak (Input : Input_Array) return Search_Result is
      Best   : Index := Index'First;
      Probes : Probe_Count := 0;
   begin
      for I in Index range Index'Succ (Index'First) .. Index'Last loop
         pragma Loop_Invariant (Probes = I - 2);
         Probes := Probes + 1;
         if Input (I) > Input (Best) then
            Best := I;
         end if;
      end loop;
      return (Position => Best, Probes => Probes);
   end Find_Peak;
end Find_Peak_Element;
