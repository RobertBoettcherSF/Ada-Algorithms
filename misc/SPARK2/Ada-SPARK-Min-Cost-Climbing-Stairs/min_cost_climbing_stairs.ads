pragma SPARK_Mode (On);

package Min_Cost_Climbing_Stairs is
   Cost_Count : constant := 6;
   subtype Index is Positive range 1 .. Cost_Count;
   subtype Cost is Integer range 0 .. 100;
   subtype Result is Integer range 0 .. 600;
   type Cost_Array is array (Index) of Cost;

   --  Specification (ghost): cheapest way from standing on step From to the top, which is past step
   --  Cost_Count; every step stood on is paid, each move goes up 1 or 2 steps.
   function From_Step (Costs : Cost_Array; From : Positive) return Result
     with Ghost, Pre => From <= Cost_Count + 2,
          Post => From_Step'Result <= 100 * (Cost_Count + 1 - Integer'Min (From, Cost_Count + 1)),
          Subprogram_Variant => (Increases => From);
   function From_Step (Costs : Cost_Array; From : Positive) return Result is
     (if From > Cost_Count then 0
      else Costs (From) + Integer'Min (From_Step (Costs, From + 1), From_Step (Costs, From + 2)));

   --  Start on step 1 or 2; the cheapest total to get past the last step.
   function Compute (Costs : Cost_Array) return Result
     with Post => Compute'Result = Integer'Min (From_Step (Costs, 1), From_Step (Costs, 2));
end Min_Cost_Climbing_Stairs;
