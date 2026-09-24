pragma Ada_2022;

package Continuous_Subarray_Sum with SPARK_Mode => On is
   Size : constant := 32;
   subtype Index is Positive range 1 .. Size;
   subtype Element is Integer range 0 .. 10;
   subtype Sum is Integer range 0 .. Size * Element'Last;
   type Values is array (Index) of Element;

   function Total (A : Values) return Sum with Global => null;
end Continuous_Subarray_Sum;
