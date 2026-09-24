package Marzullo is
   pragma Pure;

   -- Using Float subtype to allow seamless literal assignments in aggregates
   subtype Time_Point is Float;

   -- Represents a time interval [Start_Time, End_Time]
   type Time_Interval is record
      Start_Time : Time_Point;
      End_Time   : Time_Point;
   end record;

   -- Custom unconstrained array for inputs
   type Interval_Array is array (Positive range <>) of Time_Interval;

   -- Exceptions for robust error handling
   Invalid_Interval_Error : exception;
   Empty_Input_Error      : exception;

   -- VARIANT 1: Basic Marzullo's Algorithm
   -- Returns a single optimal intersecting interval and the max number of overlaps.
   procedure Basic_Marzullo
     (Intervals    : in Interval_Array;
      Best_Interval: out Time_Interval;
      Max_Overlaps : out Natural);

   -- VARIANT 2: Extended Marzullo's Algorithm
   -- Returns ALL optimally intersecting intervals if multiple disjoint peaks exist.
   type Result_Array is array (Positive range <>) of Time_Interval;
   
   procedure Extended_Marzullo
     (Intervals    : in Interval_Array;
      Results      : out Result_Array;
      Result_Count : out Natural;
      Max_Overlaps : out Natural);

end Marzullo;
