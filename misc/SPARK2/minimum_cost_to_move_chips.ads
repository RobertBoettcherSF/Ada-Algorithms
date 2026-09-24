pragma SPARK_Mode (On);

package Minimum_Cost_To_Move_Chips is
   subtype Position is Natural range 0 .. 32;
   subtype Move_Cost is Natural range 0 .. 1;

   function Cost_To_Target
     (From, Target : Position) return Move_Cost
     with Global => null,
          Post => Cost_To_Target'Result <= Move_Cost'Last;
end Minimum_Cost_To_Move_Chips;
