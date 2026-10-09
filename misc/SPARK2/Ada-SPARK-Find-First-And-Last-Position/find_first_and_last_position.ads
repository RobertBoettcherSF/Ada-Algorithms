pragma Ada_2022;

package Find_First_And_Last_Position with SPARK_Mode => On is
   Length : constant := 32;
   subtype Index is Positive range 1 .. Length;
   subtype Value is Integer range 0 .. 100;
   subtype Boundary is Natural range 0 .. Length;
   type Value_Array is array (Index) of Value;
   subtype Sorted_Array is Value_Array
     with Dynamic_Predicate =>
       (for all I in 1 .. Length - 1 => Sorted_Array (I) <= Sorted_Array (I + 1));

   subtype Probe_Count is Natural range 0 .. Length;
   type Match_Range is record
      First  : Boundary;
      Last   : Boundary;
      Probes : Probe_Count;   --  elements of Data read
   end record;

   function Locate (Data : Sorted_Array; Target : Value) return Match_Range
     with Global => null;
end Find_First_And_Last_Position;
