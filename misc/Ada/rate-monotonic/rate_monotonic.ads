with System;

package Rate_Monotonic is

   -- Representation of a real-time thread/task
   -- Assumes Deterministic deadlines exactly equal to periods (D = T)
   type Task_Record is record
      Id               : Natural;
      Computation_Time : Float; -- Worst-case execution time (C_i)
      Period           : Float; -- Interarrival time / Deadline (T_i)
      Is_ISR           : Boolean := False;
      Priority         : Natural := 0;
   end record;

   type Task_Array is array (Positive range <>) of Task_Record;

   -- =========================================================================
   -- 1. Rate-Monotonic Priority Assignment
   -- =========================================================================
   
   -- Sorts tasks by period (shortest first) and assigns static priorities.
   -- Shorter cycle duration = higher priority.
   procedure Assign_Priorities (Tasks : in out Task_Array);

   -- =========================================================================
   -- 2. Interrupt Service Routines (ISRs) Mitigation
   -- =========================================================================

   -- Mitigates mis-prioritized ISRs by shrinking their period to equal 
   -- the shortest period of any non-ISR task in the system, correcting the RMS order.
   procedure Mitigate_ISRs (Tasks : in out Task_Array);

   -- =========================================================================
   -- 3. Upper Bounds on Utilization (Schedulability Tests)
   -- =========================================================================
   
   -- Calculates total CPU Utilization: U = Sum(C_i / T_i)
   function Calculate_Utilization (Tasks : Task_Array) return Float;

   -- Liu & Layland Least Upper Bound: U <= n(2^(1/n) - 1)
   function Is_Schedulable_Liu_Layland (Tasks : Task_Array) return Boolean;

   -- Hyperbolic Bound (Bini et al): Tighter sufficient condition: Product(U_i + 1) <= 2
   function Is_Schedulable_Hyperbolic (Tasks : Task_Array) return Boolean;

   -- Harmonic Task Set Analysis: Checks if all task periods are exact 
   -- integer multiples of all shorter task periods.
   function Is_Harmonic_Task_Set (Tasks : Task_Array) return Boolean;

   -- Generalization to Harmonic Chains (Kuo & Mok): 
   -- U <= K(2^(1/K) - 1), where K is the number of harmonic task subsets.
   function Is_Schedulable_Harmonic_Chains (Tasks : Task_Array) return Boolean;

   -- Stochastic Bounds Approximation: Most randomly generated systems 
   -- are schedulable if U <= 0.88
   function Is_Schedulable_Stochastic (Tasks : Task_Array) return Boolean;

   -- =========================================================================
   -- 4. Resource Sharing (Priority Inheritance / Priority Ceiling)
   -- =========================================================================
   
   -- In standard Ada, Priority Ceiling Protocol (Highest Locker's Priority Protocol)
   -- is intrinsically implemented using Protected Objects and `pragma Priority`.
   -- To prevent deadlocks and chain blocking in a live runtime, tasks should lock 
   -- this resource, instantly elevating their priority to the ceiling.
   
   protected type Shared_Resource (Ceiling_Priority : System.Priority) is
      pragma Priority (Ceiling_Priority);
      
      entry Lock;
      procedure Unlock;
   private
      Is_Locked : Boolean := False;
   end Shared_Resource;

end Rate_Monotonic;
