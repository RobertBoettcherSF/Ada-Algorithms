pragma Ada_2022;

package body Binary_Search_Lower_Bound with SPARK_Mode => On is
   --  The original first-match chain (if Input (1) >= Target then 1
   --  elsif Input (2) ...), written as a loop over the longer array and
   --  counting the elements it reads.
   function Find (Input : Input_Array; Target : Target_Value) return Search_Result is
      Probes : Probe_Count := 0;
   begin
      for I in Index loop
         pragma Loop_Invariant (Probes = I - 1);
         Probes := Probes + 1;
         if Input (I) >= Target then
            return (Position => I, Probes => Probes);
         end if;
      end loop;
      return (Position => Length + 1, Probes => Probes);
   end Find;
end Binary_Search_Lower_Bound;
