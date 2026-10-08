pragma SPARK_Mode (On);

package The_Skyline_Problem_Lite is
   Building_Count : constant := 8;
   subtype Height is Natural range 0 .. 100;
   type Building_Array is array (Positive range 1 .. Building_Count) of Height;

   function Skyline_Height (Buildings : Building_Array) return Height;
end The_Skyline_Problem_Lite;
