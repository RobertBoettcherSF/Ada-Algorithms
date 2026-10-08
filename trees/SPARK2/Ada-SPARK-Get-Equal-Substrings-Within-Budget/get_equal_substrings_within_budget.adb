pragma SPARK_Mode (On);
package body Get_Equal_Substrings_Within_Budget is
   function Longest (Source : Code_Array; Target : Code_Array; Budget : Budget_Count) return Answer is
      Cost : Budget_Count;
      Difference : Budget_Count;
      Length : Answer := 0;
   begin
      for Start in Index loop
         Cost := 0;
         for Finish in Index loop
            if Finish >= Start then
               if Source (Finish) >= Target (Finish) then
                  Difference := Source (Finish) - Target (Finish);
               else
                  Difference := Target (Finish) - Source (Finish);
               end if;
               if Cost <= Budget_Count'Last - Difference then
                  Cost := Cost + Difference;
               else
                  Cost := Budget_Count'Last;
               end if;
               if Cost <= Budget then
                  if Finish - Start + 1 > Length then
                     Length := Finish - Start + 1;
                  end if;
               end if;
            end if;
         end loop;
      end loop;
      return Length;
   end Longest;
end Get_Equal_Substrings_Within_Budget;
