pragma Ada_2022;

package body Minimum_Limit_Of_Balls_In_A_Bag with SPARK_Mode => On is
   function Minimum_Limit
     (Bags : Bag_Array; Allowed : Operations) return Limit is
   begin
      --  Limit'Last needs no operation at all (no bag holds more), so it is
      --  the answer when no smaller candidate fits.
      for Candidate in Limit'First .. Limit'Last - 1 loop
         declare
            Needed : Integer := 0;
         begin
            for I in Index loop
               Needed := Needed +
                 (Integer (Bags (I)) - 1) / Candidate;
            end loop;
            if Needed <= Integer (Allowed) then
               return Candidate;
            end if;
         end;
      end loop;
      return Limit'Last;
   end Minimum_Limit;
end Minimum_Limit_Of_Balls_In_A_Bag;
