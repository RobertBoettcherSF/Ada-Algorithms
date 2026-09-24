pragma SPARK_Mode (On);

package Min_Cost_Connect_Cities_Stub is
   City_Count : constant := 4;
   Edge_Count : constant := 6;
   subtype City is Positive range 1 .. City_Count;
   subtype Cost_Value is Positive range 1 .. 100;
   type Edge is record
      From : City;
      To   : City;
      Cost : Cost_Value;
   end record;
   type Edge_Array is array (Positive range 1 .. Edge_Count) of Edge;

   function Minimum_Cost (Edges : Edge_Array) return Natural;
end Min_Cost_Connect_Cities_Stub;
