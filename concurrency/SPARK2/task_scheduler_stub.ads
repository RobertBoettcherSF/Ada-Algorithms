pragma Ada_2022;

package Task_Scheduler_Stub with SPARK_Mode => On is
   subtype Task_Index is Positive range 1 .. 6;
   subtype Duration is Positive range 1 .. 20;
   type Task_Array is array (Task_Index) of Duration;
   type Schedule_Array is array (Task_Index) of Task_Index;

   function Shortest_First (Tasks : Task_Array) return Schedule_Array
     with Global => null;
end Task_Scheduler_Stub;
