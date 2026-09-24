pragma Ada_2022;
package Task_Scheduler with SPARK_Mode => On is
   subtype Slot_Count is Natural range 0 .. 32;

   function Schedule_Length (Jobs, Cooldown : Slot_Count) return Slot_Count
     with Global => null,
          Pre => Jobs = 0
                 or else Jobs + (Jobs - 1) * Cooldown <= Slot_Count'Last;
end Task_Scheduler;
