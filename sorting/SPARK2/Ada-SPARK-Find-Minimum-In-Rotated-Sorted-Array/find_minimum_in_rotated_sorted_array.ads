pragma Ada_2022;

--  Find the minimum of a rotated sorted array: Data is a strictly
--  increasing array turned around a pivot (its tail moved to the front),
--  for example 4 5 6 7 0 1 2. Binary search finds the pivot in at most
--  log2 Length = 5 probes.
package Find_Minimum_In_Rotated_Sorted_Array with SPARK_Mode => On is
   Length : constant := 32;
   subtype Index is Positive range 1 .. Length;
   subtype Value is Integer range 0 .. 100;
   type Data_Array is array (Index) of Value;

   --  Data (P .. Length) followed by Data (1 .. P - 1) is strictly
   --  increasing: each neighbour pair increases except the one across
   --  P - 1 / P, and (if P > 1) the last element is below the first.
   function Rotated_At (Data : Data_Array; P : Index) return Boolean is
     ((for all K in Index =>
         (if K < Length and then K /= P - 1 then Data (K) < Data (K + 1)))
      and then (if P > 1 then Data (Length) < Data (1)));

   function Is_Rotated_Sorted (Data : Data_Array) return Boolean is
     (for some P in Index => Rotated_At (Data, P));

   subtype Probe_Count is Natural range 0 .. 5;
   type Search_Result is record
      Position : Index;         --  where the minimum is
      Probes   : Probe_Count;   --  comparisons made
   end record;

   function Find_Minimum (Data : Data_Array) return Search_Result
   with
     Global => null,
     Pre    => Is_Rotated_Sorted (Data),
     Post   => (for all I in Index =>
                  Data (Find_Minimum'Result.Position) <= Data (I));

   function Minimum (Data : Data_Array) return Value
   with
     Global => null,
     Pre    => Is_Rotated_Sorted (Data),
     Post   => (for all I in Index => Minimum'Result <= Data (I))
               and then (for some I in Index => Data (I) = Minimum'Result);
end Find_Minimum_In_Rotated_Sorted_Array;
