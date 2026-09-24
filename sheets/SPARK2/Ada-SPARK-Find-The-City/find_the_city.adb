pragma SPARK_Mode (On);

package body Find_The_City with SPARK_Mode => On is
   subtype Count is Natural range 0 .. Capacity;

   function Find
     (Edges : Network; N : City; Threshold : Cost) return City is
      Best_City : City := 1;
      Best_Count : Count := Count'Last;
      Seen : Count;
   begin
      for Candidate in City loop
         if Candidate <= N then
            Seen := 0;
            for Other in City loop
               if Other <= N and then Other /= Candidate
                 and then Edges (Candidate, Other) > 0
                 and then Edges (Candidate, Other) <= Threshold
               then
                  Seen := 1;
               end if;
            end loop;
            if Seen <= Best_Count then
               Best_Count := Seen;
               Best_City := Candidate;
            end if;
         end if;
      end loop;
      return Best_City;
   end Find;
end Find_The_City;
