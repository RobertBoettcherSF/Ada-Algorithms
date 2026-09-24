pragma Ada_2022;

package Range_Addition with SPARK_Mode => On is
   Size : constant := 32;
   subtype Index is Positive range 1 .. Size;
   subtype Element is Integer range 0 .. 10;
   subtype Amount is Integer range 0 .. 10;
   subtype Sum is Integer range 0 .. Size * (Element'Last + Amount'Last);
   type Values is array (Index) of Element;

   function Updated_Total
     (A : Values; Left, Right : Index; Increment : Amount) return Sum
     with Pre => Left <= Right, Global => null;
end Range_Addition;
