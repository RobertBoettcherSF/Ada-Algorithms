pragma Ada_2022;

package body Capacity_To_Ship_Packages with SPARK_Mode => On is
   function Minimum_Capacity_Counted
     (Weights : Weight_Array; Days : Day_Count) return Capacity_Result is
      Max_Weight : Weight := Weights (Index'First);
      Probes     : Natural := 0;
   begin
      for I in Index loop
         if Weights (I) > Max_Weight then
            Max_Weight := Weights (I);
         end if;
      end loop;

      for Candidate in Capacity loop
         pragma Loop_Invariant (Probes < Candidate);
         if Candidate >= Max_Weight then
            declare
               Used_Days : Integer := 1;
               Load : Integer := 0;
            begin
               Probes := Probes + 1;
               for I in Index loop
                  if Load + Integer (Weights (I)) > Candidate then
                     Used_Days := Used_Days + 1;
                     Load := Integer (Weights (I));
                  else
                     Load := Load + Integer (Weights (I));
                  end if;
               end loop;
               if Used_Days <= Integer (Days) then
                  return (Minimum => Candidate, Probes => Probes);
               end if;
            end;
         end if;
      end loop;
      return (Minimum => Capacity'Last, Probes => Probes);
   end Minimum_Capacity_Counted;
end Capacity_To_Ship_Packages;
