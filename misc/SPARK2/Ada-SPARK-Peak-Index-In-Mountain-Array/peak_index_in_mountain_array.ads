pragma Ada_2022;

--  Peak index in a mountain array: the values rise strictly up to one
--  peak and then fall strictly. Find the peak by halving on the slope.
package Peak_Index_In_Mountain_Array with SPARK_Mode => On is
   Length : constant := 32;
   subtype Index is Positive range 1 .. Length;
   subtype Peak_Range is Index range 2 .. Length - 1;
   subtype Value is Integer range -1000 .. 1000;
   type Value_Array is array (Index) of Value;

   --  A mountain, stated without an existential: it rises at the start,
   --  falls at the end, no two neighbours are equal and there is no
   --  valley (no element below both neighbours). So it rises strictly up
   --  to a single peak and then falls strictly.
   subtype Mountain_Array is Value_Array
     with Dynamic_Predicate =>
       Mountain_Array (1) < Mountain_Array (2)
       and then Mountain_Array (Length - 1) > Mountain_Array (Length)
       and then (for all I in 1 .. Length - 1 =>
                   Mountain_Array (I) /= Mountain_Array (I + 1))
       and then (for all I in 2 .. Length - 1 =>
                   not (Mountain_Array (I - 1) > Mountain_Array (I)
                        and Mountain_Array (I) < Mountain_Array (I + 1)));

   --  The peak is the first of the 30 candidate slopes 2 .. 31 that goes
   --  down: at most ceil (log2 30) = 5 comparisons.
   subtype Probe_Count is Natural range 0 .. 5;
   type Search_Result is record
      Position : Peak_Range;    --  index of the peak
      Probes   : Probe_Count;   --  comparisons of two neighbours
   end record;

   function Peak_Index (Input : Mountain_Array) return Search_Result
   with
     Global => null,
     Post   =>
       (for all I in 1 .. Length - 1 =>
          (if I < Peak_Index'Result.Position then Input (I) < Input (I + 1)
           else Input (I) > Input (I + 1)));
end Peak_Index_In_Mountain_Array;
