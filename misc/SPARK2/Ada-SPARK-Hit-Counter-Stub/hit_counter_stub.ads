pragma SPARK_Mode (On);

package Hit_Counter_Stub is
   Capacity : constant := 8;
   Window : constant := 300;
   subtype Hit_Index is Positive range 1 .. Capacity;
   subtype Hit_Count is Natural range 0 .. Capacity;
   subtype Timestamp is Integer range 0 .. 1000;
   type Hit_Array is array (Hit_Index) of Timestamp;

   function Count_Recent
     (Hits : Hit_Array; Count : Hit_Count; Now : Timestamp) return Hit_Count
     with Global => null;
end Hit_Counter_Stub;
