pragma Ada_2022;

--  Find the minimum in a rotated sorted array with duplicates: Values is
--  a non-decreasing array turned left by some amount. Halve towards the
--  turn; when the two ends of the range are equal, the halving step
--  cannot tell the sides apart and the range shrinks by one instead.
package Find_Minimum_In_Rotated_Sorted_Array_II with SPARK_Mode => On is
   Length : constant := 8;
   subtype Index is Positive range 1 .. Length;
   subtype Value is Integer range -1_000 .. 1_000;
   type Value_Array is array (Index) of Value;

   --  Values never falls except into P, and if P > 1 the last element is
   --  at most the first.
   function Rotated_At (Values : Value_Array; P : Index) return Boolean is
     ((for all K in Index =>
         (if K < Length and then K /= P - 1 then Values (K) <= Values (K + 1)))
      and then (if P > 1 then Values (Length) <= Values (1)));

   subtype Rotated_Array is Value_Array
     with Dynamic_Predicate =>
       (for some P in Index => Rotated_At (Rotated_Array, P));

   --  Proved: at most N - 1 comparisons (the worst case with duplicates,
   --  e.g. all equal but one). With distinct values the equal-ends step
   --  never happens and the tests check at most floor (log2 N) + 2.
   subtype Probe_Count is Natural range 0 .. Length - 1;
   type Search_Result is record
      Position : Index;         --  where a smallest element is
      Probes   : Probe_Count;   --  comparisons of two elements
   end record;

   function Find_Minimum (Values : Rotated_Array) return Search_Result
   with
     Global => null,
     Post   => (for all I in Index => Values (Find_Minimum'Result.Position) <= Values (I));

   function Minimum (Values : Rotated_Array) return Value
   with
     Global => null,
     Post   => (for all I in Index => Minimum'Result <= Values (I))
               and then (for some I in Index => Values (I) = Minimum'Result);
end Find_Minimum_In_Rotated_Sorted_Array_II;
