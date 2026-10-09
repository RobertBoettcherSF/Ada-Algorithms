pragma Ada_2022;

package body Find_Minimum_In_Rotated_Sorted_Array_II with SPARK_Mode => On is
   function Find_Minimum (Values : Value_Array) return Search_Result is
      Best   : Index := Index'First;
      Probes : Probe_Count := 0;
   begin
      for I in Index loop
         pragma Loop_Invariant (Probes = I - 1);
         Probes := Probes + 1;
         if Values (I) < Values (Best) then
            Best := I;
         end if;
      end loop;
      return (Position => Best, Probes => Probes);
   end Find_Minimum;

   function Minimum (Values : Value_Array) return Value is
     (Values (Find_Minimum (Values).Position));
end Find_Minimum_In_Rotated_Sorted_Array_II;
