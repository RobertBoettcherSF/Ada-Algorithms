pragma Ada_2022;

package body Capacity_To_Ship_Packages with SPARK_Mode => On is
   function Minimum_Capacity
     (Weights : Weight_Array; Days : Day_Count) return Capacity is
      Max_Weight : Weight := Weights (Index'First);
   begin
      for I in Index loop
         if Weights (I) > Max_Weight then
            Max_Weight := Weights (I);
         end if;
      end loop;

      for Candidate in Capacity loop
         if Candidate >= Max_Weight then
            declare
               Used_Days : Integer := 1;
               Load : Integer := 0;
            begin
               for I in Index loop
                  if Load + Integer (Weights (I)) > Candidate then
                     Used_Days := Used_Days + 1;
                     Load := Integer (Weights (I));
                  else
                     Load := Load + Integer (Weights (I));
                  end if;
               end loop;
               if Used_Days <= Integer (Days) then
                  return Candidate;
               end if;
            end;
         end if;
      end loop;
      return Capacity'Last;
   end Minimum_Capacity;
end Capacity_To_Ship_Packages;
