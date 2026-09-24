pragma Ada_2022;

package Range_Sum_Query_Immutable with SPARK_Mode => On is
   Size : constant := 32;
   subtype Index is Positive range 1 .. Size;
   subtype Element is Integer range 0 .. 10;
   subtype Sum is Integer range 0 .. Size * Element'Last;
   type Values is array (Index) of Element;

   function Query (A : Values; Left, Right : Index) return Sum
     with Pre => Left <= Right, Global => null;
end Range_Sum_Query_Immutable;
