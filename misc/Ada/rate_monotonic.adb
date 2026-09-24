with System;

package body Rate_Monotonic is

   -----------------------
   -- Assign_Priorities --
   -----------------------
   procedure Assign_Priorities (Tasks : in out Task_Array) is
      Temp : Task_Record;
   begin
      -- Sort tasks by period ascending (O(N^2) Bubble sort is optimal enough 
      -- for small RTOS task set sizes).
      for I in Tasks'Range loop
         for J in I + 1 .. Tasks'Last loop
            if Tasks(J).Period < Tasks(I).Period then
               Temp     := Tasks(I);
               Tasks(I) := Tasks(J);
               Tasks(J) := Temp;
            end if;
         end loop;
      end loop;
      
      -- Assign static priorities according to Rate-Monotonic conventions.
      -- In Ada, higher integer values = higher priority.
      for I in Tasks'Range loop
         Tasks(I).Priority := Tasks'Length - (I - Tasks'First);
      end loop;
   end Assign_Priorities;

   -------------------
   -- Mitigate_ISRs --
   -------------------
   procedure Mitigate_ISRs (Tasks : in out Task_Array) is
      Min_Period  : Float := Float'Last;
      Has_Non_ISR : Boolean := False;
   begin
      -- Find the shortest period among all scheduler-controlled (non-ISR) tasks
      for I in Tasks'Range loop
         if not Tasks(I).Is_ISR and then Tasks(I).Period < Min_Period then
            Min_Period  := Tasks(I).Period;
            Has_Non_ISR := True;
         end if;
      end loop;
      
      -- If a normal task exists, cap ISR periods to this minimum rate
      if Has_Non_ISR then
         for I in Tasks'Range loop
            if Tasks(I).Is_ISR and then Tasks(I).Period > Min_Period then
               Tasks(I).Period := Min_Period;
            end if;
         end loop;
      end if;
   end Mitigate_ISRs;

   ---------------------------
   -- Calculate_Utilization --
   ---------------------------
   function Calculate_Utilization (Tasks : Task_Array) return Float is
      U : Float := 0.0;
   begin
      for I in Tasks'Range loop
         U := U + (Tasks(I).Computation_Time / Tasks(I).Period);
      end loop;
      return U;
   end Calculate_Utilization;

   --------------------------------
   -- Is_Schedulable_Liu_Layland --
   --------------------------------
   function Is_Schedulable_Liu_Layland (Tasks : Task_Array) return Boolean is
      with Ada.Numerics.Elementary_Functions;
      use Ada.Numerics.Elementary_Functions;
      
      U : constant Float := Calculate_Utilization (Tasks);
      N : constant Float := Float (Tasks'Length);
      Least_Upper_Bound : constant Float := N * ((2.0 ** (1.0 / N)) - 1.0);
   begin
      if N = 0.0 then 
         return True; 
      end if;
      
      return U <= Least_Upper_Bound;
   end Is_Schedulable_Liu_Layland;

   -------------------------------
   -- Is_Schedulable_Hyperbolic --
   -------------------------------
   function Is_Schedulable_Hyperbolic (Tasks : Task_Array) return Boolean is
      Product : Float := 1.0;
   begin
      for I in Tasks'Range loop
         Product := Product * ((Tasks(I).Computation_Time / Tasks(I).Period) + 1.0);
      end loop;
      
      -- Bini et al. prove the system is schedulable if the product is <= 2
      return Product <= 2.0;
   end Is_Schedulable_Hyperbolic;

   --------------------------
   -- Is_Harmonic_Task_Set --
   --------------------------
   function Is_Harmonic_Task_Set (Tasks : Task_Array) return Boolean is
      Epsilon : constant Float := 0.00001;
   begin
      for I in Tasks'Range loop
         for J in Tasks'Range loop
            -- Check if larger periods are exact integer multiples of shorter periods
            if Tasks(J).Period > Tasks(I).Period then
               declare
                  Ratio : constant Float := Tasks(J).Period / Tasks(I).Period;
                  Nearest_Int : constant Float := Float'Rounding (Ratio);
               begin
                  if abs (Ratio - Nearest_Int) > Epsilon then
                     return False; -- Found a non-harmonic pair
                  end if;
               end;
            end if;
         end loop;
      end loop;
      
      return True;
   end Is_Harmonic_Task_Set;

   ------------------------------------
   -- Is_Schedulable_Harmonic_Chains --
   ------------------------------------
   function Is_Schedulable_Harmonic_Chains (Tasks : Task_Array) return Boolean is
      with Ada.Numerics.Elementary_Functions;
      use Ada.Numerics.Elementary_Functions;
      
      type Float_Array is array (1 .. Tasks'Length) of Float;
      Chain_Maxes  : Float_Array := (others => 0.0);
      K            : Natural := 0;
      Epsilon      : constant Float := 0.00001;
      
      Sorted_Tasks : Task_Array := Tasks;
      U            : constant Float := Calculate_Utilization (Tasks);
      Bound        : Float;
   begin
      if Tasks'Length = 0 then
         return True;
      end if;

      -- Sorting by period establishes a baseline to group exact multiples
      Assign_Priorities (Sorted_Tasks);
      
      -- Partition tasks into 'K' harmonic subsets (chains)
      for I in Sorted_Tasks'Range loop
         declare
            Placed  : Boolean := False;
            Ratio   : Float;
            Nearest : Float;
         begin
            for C in 1 .. K loop
               Ratio   := Sorted_Tasks(I).Period / Chain_Maxes(C);
               Nearest := Float'Rounding (Ratio);
               
               if abs (Ratio - Nearest) <= Epsilon then
                  Chain_Maxes(C) := Sorted_Tasks(I).Period;
                  Placed := True;
                  exit;
               end if;
            end loop;
            
            -- If it doesn't fit into an existing harmonic chain, create a new one
            if not Placed then
               K := K + 1;
               Chain_Maxes(K) := Sorted_Tasks(I).Period;
            end if;
         end;
      end loop;
      
      -- Kuo & Mok's generalized least upper bound
      if K = 1 then
         Bound := 1.0; -- Full utilization achievable for a pure harmonic set
      else
         Bound := Float(K) * ((2.0 ** (1.0 / Float(K))) - 1.0);
      end if;
      
      return U <= Bound;
   end Is_Schedulable_Harmonic_Chains;

   -------------------------------
   -- Is_Schedulable_Stochastic --
   -------------------------------
   function Is_Schedulable_Stochastic (Tasks : Task_Array) return Boolean is
   begin
      -- Standard stochastic safety margin bound identified in the literature
      return Calculate_Utilization (Tasks) <= 0.88;
   end Is_Schedulable_Stochastic;

   ---------------------
   -- Shared_Resource --
   ---------------------
   protected body Shared_Resource is
      entry Lock when not Is_Locked is
      begin
         Is_Locked := True;
      end Lock;

      procedure Unlock is
      begin
         Is_Locked := False;
      end Unlock;
   end Shared_Resource;

end Rate_Monotonic;
