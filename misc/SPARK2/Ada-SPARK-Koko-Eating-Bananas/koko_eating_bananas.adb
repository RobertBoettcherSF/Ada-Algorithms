pragma Ada_2022;

package body Koko_Eating_Bananas with SPARK_Mode => On is
   function Minimum_Speed
     (Piles : Pile_Array; Hours : Hour_Count) return Speed_Result is
      Probes : Probe_Count := 0;
   begin
      for Candidate in Speed loop
         pragma Loop_Invariant (Probes = Candidate - 1);
         Probes := Probes + 1;
         declare
            Needed : Integer := 0;
         begin
            for I in Index loop
               Needed := Needed +
                 (Integer (Piles (I)) + Candidate - 1) / Candidate;
            end loop;
            if Needed <= Integer (Hours) then
               return (Minimum => Candidate, Probes => Probes);
            end if;
         end;
      end loop;
      return (Minimum => Speed'Last, Probes => Probes);
   end Minimum_Speed;
end Koko_Eating_Bananas;
