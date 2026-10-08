pragma SPARK_Mode (On);

package body Reach_A_Number is
   function Minimum_Steps (Value : Target) return Step_Count is
      Distance : constant Natural := Natural (abs Value);
   begin
      for Candidate in Step_Count range 0 .. 20 loop
         declare
            Position : constant Natural := Candidate * (Candidate + 1) / 2;
         begin
            if Position >= Distance
              and then (Position - Distance) mod 2 = 0
            then
               return Candidate;
            end if;
         end;
      end loop;
      return Step_Count'Last;
   end Minimum_Steps;
end Reach_A_Number;
