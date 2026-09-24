pragma Ada_2022;

package body Koko_Eating_Bananas with SPARK_Mode => On is
   function Minimum_Speed
     (Piles : Pile_Array; Hours : Hour_Count) return Speed is
   begin
      for Candidate in Speed loop
         declare
            Needed : Integer := 0;
         begin
            for I in Index loop
               Needed := Needed +
                 (Integer (Piles (I)) + Candidate - 1) / Candidate;
            end loop;
            if Needed <= Integer (Hours) then
               return Candidate;
            end if;
         end;
      end loop;
      return Speed'Last;
   end Minimum_Speed;
end Koko_Eating_Bananas;
