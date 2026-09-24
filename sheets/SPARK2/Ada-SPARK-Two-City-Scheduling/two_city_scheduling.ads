pragma SPARK_Mode (On);

package Two_City_Scheduling is
   subtype Cost is Natural range 0 .. 1_000;
   subtype Total_Cost is Natural range 0 .. 2_000;

   function Cheapest_Assignment
     (A1, B1, A2, B2 : Cost) return Total_Cost
     with Global => null,
          Post => Cheapest_Assignment'Result <= Total_Cost'Last;
end Two_City_Scheduling;
