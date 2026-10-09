pragma Ada_2022;

package body Task_Scheduler_Stub with SPARK_Mode => On is
   --  Insertion sort of the task indices by (duration, index): task I is
   --  inserted into the already ordered tasks Tasks'First .. I - 1, moving
   --  every task it runs before one slot to the right.
   function Shortest_First (Tasks : Task_Array) return Schedule_Array is
      Order : Schedule_Array (Tasks'Range) := [others => Task_Index'First];
      K     : Integer;
   begin
      for I in Tasks'Range loop
         pragma Loop_Invariant
           (for all M in Tasks'First .. I - 1 => Order (M) in Tasks'First .. I - 1);
         pragma Loop_Invariant
           (for all M in Tasks'First .. I - 2 => Before (Tasks, Order (M), Order (M + 1)));
         K := I;
         while K > Tasks'First and then Before (Tasks, I, Order (K - 1)) loop
            pragma Loop_Invariant (K in Tasks'First + 1 .. I);
            pragma Loop_Invariant
              (for all M in Tasks'First .. I =>
                 (if M /= K then Order (M) in Tasks'First .. I - 1));
            pragma Loop_Invariant
              (for all M in Tasks'First .. K - 2 => Before (Tasks, Order (M), Order (M + 1)));
            pragma Loop_Invariant
              (for all M in K + 1 .. I - 1 => Before (Tasks, Order (M), Order (M + 1)));
            pragma Loop_Invariant
              (if K < I then Before (Tasks, Order (K - 1), Order (K + 1)));
            pragma Loop_Invariant
              (for all M in K + 1 .. I => Before (Tasks, I, Order (M)));
            pragma Loop_Variant (Decreases => K);
            Order (K) := Order (K - 1);
            K := K - 1;
         end loop;
         --  Every placed task has a smaller index than I, so not running
         --  before it means running after it.
         pragma Assert (if K > Tasks'First then Before (Tasks, Order (K - 1), I));
         Order (K) := I;
      end loop;
      return Order;
   end Shortest_First;
end Task_Scheduler_Stub;
