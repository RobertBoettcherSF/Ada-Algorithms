pragma Ada_2022;

package body Minimum_Number_Of_Days_To_Make_M_Bouquets with SPARK_Mode => On is
   function Minimum_Day
     (Bloom_Days : Bloom_Array; Size : Bouquet_Size) return Day is
   begin
      for Candidate in Day loop
         declare
            Run : Integer := 0;
         begin
            for I in Index loop
               if Bloom_Days (I) <= Candidate then
                  Run := Run + 1;
                  if Run >= Integer (Size) then
                     return Candidate;
                  end if;
               else
                  Run := 0;
               end if;
            end loop;
         end;
      end loop;
      return Day'Last;
   end Minimum_Day;
end Minimum_Number_Of_Days_To_Make_M_Bouquets;
