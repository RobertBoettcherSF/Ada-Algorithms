pragma SPARK_Mode (On);

package body Two_City_Scheduling is
   function Cheapest_Assignment
     (A1, B1, A2, B2 : Cost) return Total_Cost is
      A_First : constant Total_Cost := A1 + B2;
      B_First : constant Total_Cost := B1 + A2;
   begin
      if A_First <= B_First then
         return A_First;
      else
         return B_First;
      end if;
   end Cheapest_Assignment;
end Two_City_Scheduling;
