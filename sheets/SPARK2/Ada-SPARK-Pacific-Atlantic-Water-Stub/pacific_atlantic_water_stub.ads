pragma SPARK_Mode (On);

package Pacific_Atlantic_Water_Stub is
   Row_Count : constant := 3;
   Column_Count : constant := 3;
   subtype Row is Positive range 1 .. Row_Count;
   subtype Column is Positive range 1 .. Column_Count;
   subtype Height is Integer range 0 .. 100;
   type Height_Map is array (Row, Column) of Height;
   subtype Reachable_Count is Integer range 0 .. Row_Count * Column_Count;

   function Count (Heights : Height_Map) return Reachable_Count;
end Pacific_Atlantic_Water_Stub;
