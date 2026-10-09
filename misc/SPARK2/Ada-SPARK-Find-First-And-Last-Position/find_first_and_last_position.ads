pragma Ada_2022;

--  Find first and last position of Target in a sorted array: two
--  halving searches, one for the first element >= Target and one for the
--  first element > Target; the run of Target lies between them.
package Find_First_And_Last_Position with SPARK_Mode => On is
   Length : constant := 32;
   subtype Index is Positive range 1 .. Length;
   subtype Value is Integer range 0 .. 100;
   subtype Boundary is Natural range 0 .. Length;
   type Value_Array is array (Index) of Value;
   subtype Sorted_Array is Value_Array
     with Dynamic_Predicate =>
       (for all I in 1 .. Length - 1 => Sorted_Array (I) <= Sorted_Array (I + 1));

   --  Two searches over 33 boundaries: at most 2 * 6 = 12 reads.
   subtype Probe_Count is Natural range 0 .. 12;
   type Match_Range is record
      First  : Boundary;      --  0 when Target is absent
      Last   : Boundary;      --  0 when Target is absent
      Probes : Probe_Count;   --  elements of Data read
   end record;

   function Locate (Data : Sorted_Array; Target : Value) return Match_Range
   with
     Global => null,
     Post   =>
       (if Locate'Result.First = 0 then
          Locate'Result.Last = 0
          and then (for all I in Index => Data (I) /= Target)
        else
          Locate'Result.First <= Locate'Result.Last
          and then (for all I in Index =>
                      (if I < Locate'Result.First then Data (I) < Target
                       elsif I <= Locate'Result.Last then Data (I) = Target
                       else Data (I) > Target)));
end Find_First_And_Last_Position;
