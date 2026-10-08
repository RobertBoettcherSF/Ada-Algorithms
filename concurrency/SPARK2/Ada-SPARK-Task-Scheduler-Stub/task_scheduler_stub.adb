pragma Ada_2022;

package body Task_Scheduler_Stub with SPARK_Mode => On is
   function Shortest_First (Tasks : Task_Array) return Schedule_Array is
      Order : Schedule_Array := (1 => 1, 2 => 2, 3 => 3, 4 => 4, 5 => 5, 6 => 6);
      Minimum : Task_Index;
      Temporary : Task_Index;
   begin
      for I in Task_Index loop
         Minimum := I;
         for J in Task_Index range I .. Task_Index'Last loop
            if Tasks (Order (J)) < Tasks (Order (Minimum)) then
               Minimum := J;
            end if;
         end loop;
         Temporary := Order (I);
         Order (I) := Order (Minimum);
         Order (Minimum) := Temporary;
      end loop;
      return Order;
   end Shortest_First;
end Task_Scheduler_Stub;
