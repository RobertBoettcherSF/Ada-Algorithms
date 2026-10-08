pragma Ada_2022;

package Find_First_And_Last_Position with SPARK_Mode => On is
   Length : constant := 32;
   subtype Index is Positive range 1 .. Length;
   subtype Value is Integer range 0 .. 100;
   subtype Boundary is Natural range 0 .. Length;
   type Sorted_Array is array (Index) of Value;
   type Match_Range is record
      First : Boundary;
      Last  : Boundary;
   end record;

   function Locate (Data : Sorted_Array; Target : Value) return Match_Range
     with Global => null;
end Find_First_And_Last_Position;
