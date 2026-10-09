pragma Ada_2022;

--  Find a peak element: an element greater than each neighbour it has
--  (the ends have one neighbour). With no two neighbours equal a peak
--  always exists; find one by halving on the slope.
package Find_Peak_Element with SPARK_Mode => On is
   Length : constant := 32;
   subtype Index is Positive range 1 .. Length;
   subtype Value is Integer range -1000 .. 1000;
   type Value_Array is array (Index) of Value;
   subtype Input_Array is Value_Array
     with Dynamic_Predicate =>
       (for all I in 1 .. Length - 1 => Input_Array (I) /= Input_Array (I + 1));

   function Is_Peak (Input : Input_Array; P : Index) return Boolean is
     ((P = 1 or else Input (P) > Input (P - 1))
      and then (P = Length or else Input (P) > Input (P + 1)));

   --  32 candidates: at most ceil (log2 32) = 5 comparisons.
   subtype Probe_Count is Natural range 0 .. 5;
   type Search_Result is record
      Position : Index;         --  a peak
      Probes   : Probe_Count;   --  comparisons of two neighbours
   end record;

   function Find_Peak (Input : Input_Array) return Search_Result
   with
     Global => null,
     Post   => Is_Peak (Input, Find_Peak'Result.Position);
end Find_Peak_Element;
