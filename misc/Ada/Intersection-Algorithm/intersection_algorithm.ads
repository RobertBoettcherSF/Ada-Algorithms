-- intersection_algorithm.ads
-- Specification for the Intersection Algorithm and its foundational Marzullo variant.

package Intersection_Algorithm is

   -- Core custom types to ensure strong typing
   type Interval is record
      Center : Float;
      Radius : Float;
   end record;

   type Interval_Array is array (Positive range <>) of Interval;

   type Result_Record is record
      Success : Boolean;
      Lower   : Float;
      Upper   : Float;
   end record;

   -- Exception for handling invalid inputs
   Invalid_Data_Error : exception;

   -- Preemptive / Advanced Variant: NTP Intersection Algorithm
   -- Returns an interval that isolates valid overlapping sources 
   -- while rejecting falsetickers. Allows using center points.
   function Find_Intersection (Intervals : Interval_Array) return Result_Record;

   -- Base Variant: Marzullo's Algorithm
   -- Efficiently finds the optimum subset of overlaps, optimizing for the 
   -- largest number of agreeing intervals.
   function Marzullo_Algorithm (Intervals : Interval_Array) return Result_Record;

end Intersection_Algorithm;
