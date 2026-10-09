pragma SPARK_Mode (On);

package body Sqrtx is

   subtype Bound is Natural range 0 .. Root'Last + 1;

   --  Largest Hi - Lo after K candidates squared: 101, then ceilings of
   --  halves.
   function Width (K : Probe_Count) return Positive is
     (case K is
        when 0 => 101, when 1 => 51, when 2 => 26, when 3 => 13,
        when 4 => 7, when 5 => 4, when 6 => 2, when 7 => 1)
   with Ghost;

   function Integer_Square_Root (Value : Input) return Root_Result is
      Lo     : Root := 0;               --  Lo * Lo <= Value < Hi * Hi
      Hi     : Bound := Root'Last + 1;
      Mid    : Root;
      Probes : Probe_Count := 0;
   begin
      while Hi - Lo > 1 loop
         pragma Loop_Invariant (Lo < Hi);
         pragma Loop_Invariant (Lo * Lo <= Value);
         pragma Loop_Invariant (Value < Hi * Hi);
         pragma Loop_Invariant (Hi - Lo <= Width (Probes));
         pragma Loop_Variant (Decreases => Hi - Lo);
         Mid := Lo + (Hi - Lo) / 2;
         Probes := Probes + 1;
         if Mid * Mid <= Value then
            Lo := Mid;
         else
            Hi := Mid;
         end if;
      end loop;
      return (Value => Lo, Probes => Probes);
   end Integer_Square_Root;
end Sqrtx;
