pragma Ada_2022;

package body Split_Array_Largest_Sum with SPARK_Mode => On is
   function Largest_Sum
     (Input : Input_Array; Parts : Part_Count) return Limit is
      Max_Element : Element := Input (Index'First);
   begin
      for I in Index loop
         if Input (I) > Max_Element then
            Max_Element := Input (I);
         end if;
      end loop;

      for Candidate in Limit loop
         if Candidate >= Max_Element then
            declare
               Used_Parts : Integer := 1;
               Load : Integer := 0;
            begin
               for I in Index loop
                  if Load + Integer (Input (I)) > Candidate then
                     Used_Parts := Used_Parts + 1;
                     Load := Integer (Input (I));
                  else
                     Load := Load + Integer (Input (I));
                  end if;
               end loop;
               if Used_Parts <= Integer (Parts) then
                  return Candidate;
               end if;
            end;
         end if;
      end loop;
      return Limit'Last;
   end Largest_Sum;
end Split_Array_Largest_Sum;
