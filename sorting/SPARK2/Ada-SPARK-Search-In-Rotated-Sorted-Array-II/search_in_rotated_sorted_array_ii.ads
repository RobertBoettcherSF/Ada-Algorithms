pragma Ada_2022;

--  Search in a rotated sorted array with duplicates: Data is a
--  non-decreasing array turned left by some amount. Find the turn by
--  halving (shrinking by one when the ends of the range are equal), then
--  halve inside the sorted part that can hold Target.
package Search_In_Rotated_Sorted_Array_II with SPARK_Mode => On is
   Length : constant := 32;
   subtype Index is Positive range 1 .. Length;
   subtype Value is Integer range 0 .. 100;
   type Data_Array is array (Index) of Value;

   --  Data never falls except into P, and if P > 1 the last element is
   --  at most the first.
   function Rotated_At (Data : Data_Array; P : Index) return Boolean is
     ((for all K in Index =>
         (if K < Length and then K /= P - 1 then Data (K) <= Data (K + 1)))
      and then (if P > 1 then Data (Length) <= Data (1)));

   subtype Rotated_Array is Data_Array
     with Dynamic_Predicate =>
       (for some P in Index => Rotated_At (Rotated_Array, P));

   --  Proved: at most N - 1 comparisons to find the turn (the worst case
   --  with duplicates), 1 to pick the part, 6 to halve it and 1 for the
   --  element found. With distinct values the equal-ends step never
   --  happens and the tests check at most 2 * (floor (log2 N) + 2).
   subtype Probe_Count is Natural range 0 .. Length - 1 + 8;
   type Search_Result is record
      Found  : Boolean;       --  some element equals Target
      Probes : Probe_Count;   --  comparisons with elements
   end record;

   function Contains (Data : Rotated_Array; Target : Value) return Search_Result
   with
     Global => null,
     Post   => Contains'Result.Found = (for some I in Index => Data (I) = Target);
end Search_In_Rotated_Sorted_Array_II;
