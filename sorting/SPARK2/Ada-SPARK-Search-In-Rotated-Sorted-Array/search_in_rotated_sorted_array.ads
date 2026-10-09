pragma Ada_2022;

--  Search in a rotated sorted array: Data is a strictly increasing array
--  turned left by some amount (so it rises, drops once, and rises again
--  to below its first element). Find whether Target occurs: halve to
--  find the turn, then halve inside the sorted part that can hold Target.
package Search_In_Rotated_Sorted_Array with SPARK_Mode => On is
   Length : constant := 32;
   subtype Index is Positive range 1 .. Length;
   subtype Value is Integer range 0 .. 100;
   type Data_Array is array (Index) of Value;

   --  Data rises strictly everywhere except into P (the smallest
   --  element), and if P > 1 the last element is below the first.
   function Rotated_At (Data : Data_Array; P : Index) return Boolean is
     ((for all K in Index =>
         (if K < Length and then K /= P - 1 then Data (K) < Data (K + 1)))
      and then (if P > 1 then Data (Length) < Data (1)));

   subtype Rotated_Array is Data_Array
     with Dynamic_Predicate =>
       (for some P in Index => Rotated_At (Rotated_Array, P));

   --  At most 5 to find the turn, 1 to pick the part, 6 to halve it
   --  (up to 33 insertion points) and 1 to compare the element found.
   subtype Probe_Count is Natural range 0 .. 13;
   type Search_Result is record
      Found  : Boolean;       --  some element equals Target
      Probes : Probe_Count;   --  comparisons with elements
   end record;

   function Contains (Data : Rotated_Array; Target : Value) return Search_Result
   with
     Global => null,
     Post   => Contains'Result.Found = (for some I in Index => Data (I) = Target);
end Search_In_Rotated_Sorted_Array;
