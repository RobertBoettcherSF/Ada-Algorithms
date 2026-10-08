pragma Ada_2022;
package body Task_Scheduler with SPARK_Mode => On is
   function Schedule_Length (Jobs, Cooldown : Slot_Count) return Slot_Count is
   begin
      if Jobs = 0 then
         return 0;
      else
         return Jobs + (Jobs - 1) * Cooldown;
      end if;
   end Schedule_Length;
end Task_Scheduler;
