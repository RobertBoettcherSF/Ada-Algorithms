pragma Ada_2022;

package Task_Scheduler_Stub with SPARK_Mode => On is
   Max_Tasks : constant := 10_000;
   subtype Task_Index is Positive range 1 .. Max_Tasks;
   subtype Duration is Positive range 1 .. 20;
   type Task_Array is array (Task_Index range <>) of Duration;
   type Schedule_Array is array (Task_Index range <>) of Task_Index;

   --  Task A runs before task B: shorter first, equal durations by index.
   function Before (Tasks : Task_Array; A, B : Task_Index) return Boolean is
     (Tasks (A) < Tasks (B) or else (Tasks (A) = Tasks (B) and then A < B))
     with Pre => A in Tasks'Range and then B in Tasks'Range;

   --  Non-preemptive shortest-job-first order: Result (I) is the task that
   --  runs I-th. Each slot names a task and consecutive slots are strictly
   --  in Before order, so every task appears exactly once.
   function Shortest_First (Tasks : Task_Array) return Schedule_Array
     with Global => null,
          Post   => Shortest_First'Result'First = Tasks'First
                    and then Shortest_First'Result'Last = Tasks'Last
                    and then (for all I in Tasks'Range =>
                                Shortest_First'Result (I) in Tasks'Range)
                    and then (for all I in Tasks'Range =>
                                (if I < Tasks'Last then
                                   Before (Tasks, Shortest_First'Result (I),
                                           Shortest_First'Result (I + 1))));
end Task_Scheduler_Stub;
